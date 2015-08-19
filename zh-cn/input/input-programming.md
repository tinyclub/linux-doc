> 原文：Documentation/input/input-programming.txt<br />
> 翻译：[@wengpingbo](https://github.com/wengpingbo)<br />
> 校订：@NULL<br />

# INPUT 驱动编程

##1. 创建一个 INPUT 设备驱动

###1.0 最简单的例子

这有一个非常简单的 INPUT 设备驱动例子。这个设备只有一个按钮，该按钮能通过 BUTTON_PORT 端口来访问。当按下或者释放时，设备会产生一个 BUTTON_IRQ 中断。驱动代码看上去像这样：

```
#include <linux/input.h>
#include <linux/module.h>
#include <linux/init.h>

#include <asm/irq.h>
#include <asm/io.h>

static struct input_dev *button_dev;

static irqreturn_t button_interrupt(int irq, void *dummy)
{
	input_report_key(button_dev, BTN_0, inb(BUTTON_PORT) & 1);
	input_sync(button_dev);
	return IRQ_HANDLED;
}

static int __init button_init(void)
{
	int error;

	if (request_irq(BUTTON_IRQ, button_interrupt, 0, "button", NULL)) {
                printk(KERN_ERR "button.c: Can't allocate irq %d\n", button_irq);
                return -EBUSY;
        }

	button_dev = input_allocate_device();
	if (!button_dev) {
		printk(KERN_ERR "button.c: Not enough memory\n");
		error = -ENOMEM;
		goto err_free_irq;
	}

	button_dev->evbit[0] = BIT_MASK(EV_KEY);
	button_dev->keybit[BIT_WORD(BTN_0)] = BIT_MASK(BTN_0);

	error = input_register_device(button_dev);
	if (error) {
		printk(KERN_ERR "button.c: Failed to register device\n");
		goto err_free_dev;
	}

	return 0;

 err_free_dev:
	input_free_device(button_dev);
 err_free_irq:
	free_irq(BUTTON_IRQ, button_interrupt);
	return error;
}

static void __exit button_exit(void)
{
        input_unregister_device(button_dev);
	free_irq(BUTTON_IRQ, button_interrupt);
}

module_init(button_init);
module_exit(button_exit);
```

###1.1 这个例子做了什么

首先，它包含了 `<linux/input.h>` 头文件，这是 INPUT 子系统的接口。该头文件提供了所有需要的定义。

初始化函数（_init）会在模块加载或者内核启动过程中调用，它分配必要的资源（它同时也应该检测相应设备是否存在）。

然后它通过 `inpput_allocate_device()` 分配一个新的 INPUT 设备结构体，并且设定相应位字段。设备驱动通过这个结构体告诉 INPUT 系统的其他模块：该设备是什么，它产生或者接受什么事件。我们的设备只能够产生 EV_KEY 类型事件，所以也只能有一个 BTN_0 事件编码。因此，我们只需要设置这两个位。我们可以使用下面两种形式来设置

	set_bit(EV_KEY, button_dev.evbit);
	set_bit(BTN_0, button_dev.keybit);

但是若不止一个位，第一种方法更简单一点。

然后示例驱动通过如下调用注册该 INPUT 设备结构体

	input_register_device(&button_dev);

这会把 button_dev 架构体加入 INPUT 驱动链表里，然后调用设备处理模块 _connect 函数，来告诉他们一个新 INPUT 设备出现了。`input_register_device()` 调用可能会导致进程睡眠，因此不能在中断上下文或者自旋锁上下文调用。

在使用过程中，这个驱动唯一使用的函数是

	button_interrupt()

该函数会在每一次按钮中断到来时，检测它的状态，并通过 `input report_key()` 调用把该事件上报给 INPUT 系统。这里不需要在中断处理函数中检测是否上报了两个相同的值（例如，连续两次按下），因为 `input_report_*` 函数会检测这些。

然后这有一个

	input_sync()

调用来告诉接收这个事件的模块：我们已经发送了一个完整的事件。在只有一个按钮情况下，这看上去并不是很重要。但是对于那些像鼠标移动事件来说，这种调用就非常重要了。因为你不想单独处理 X 和 Y 值，这会导致异常的鼠标移动。

###1.2 dev->open() and dev->close()

假设该驱动需要不断轮询设备，因为它没有中断信号。但是长时间轮询代价很大，或者该设备占用了关键资源（例如，中断），不能长久占用。它可以利用 close 回调函数来暂停轮询，或者释放中断，利用 open 回调函数再次恢复轮询，注册中断。为了达到这样的效果，我们可以在驱动中加入如下代码：

```
static int button_open(struct input_dev *dev)
{
	if (request_irq(BUTTON_IRQ, button_interrupt, 0, "button", NULL)) {
                printk(KERN_ERR "button.c: Can't allocate irq %d\n", button_irq);
                return -EBUSY;
        }

        return 0;
}

static void button_close(struct input_dev *dev)
{
        free_irq(IRQ_AMIGA_VERTB, button_interrupt);
}

static int __init button_init(void)
{
	...
	button_dev->open = button_open;
	button_dev->close = button_close;
	...
}
```

这里要注意的是 INPUT 系统核心会跟踪当前使用该设备的用户数，并且保证 `dev->open()` 只会在第一个用户连接该设备时调用，`dev->close()` 只会在最后一个用户断开连接时调用。对这两个回调函数的调用都是串行化的。（**注：**互斥？？）

`open()` 回调函数应该在成功时返回 0，错误时返回负值。`close()` 回调函数总是成功的（返回类型为 void）。

###1.3 基本事件类型

最简单的事件类型是 EV_KEY，用于按键和按钮。它通过如下调用上报给 INPUT 系统：

	input_report_key(struct input_dev *dev, int code, int value)

查看 `linux/input.h` 文件获取 `code` 所有可能的取值（0 ~ KEY_MAX）。`value` 被翻译为真实的值，例如非零值是按键被按下，零值代表按键被释放。INPUT 系统只会在当前值不同于上一次报的值时，才会生成事件。

除了 EV_KEY，这还有两种事件类型：EV_REL 和 EV_ABS。它们用于设备产生的相对值和绝对值。相对值就像鼠标在 X 轴移动那样。因为它没有绝对的坐标系统做参照，只能上报相对于上一个位置的相对值。绝对值用于那些有绝对坐标系统做参照的设备，像游戏杆和数字转换器。

让设备上报 EV_REL 类型事件，跟上报 EV_KEY 类型事件一样简单，只需要设置相应的位，然后调用

	input_report_rel(struct input_dev *dev, int code, int value)

函数。这里只会对非零值才会生成事件。

但是 EV_ABS 事件有一点特殊。在调用 `input_register_device` 之前，你必须在 input_dev 结构体中为该设备的每一个绝对类型的轴填充一些区域。如果按钮设备有一个 ABS_X 轴，我们需要做如下设置：

	button_dev.absmin[ABS_X] = 0;
	button_dev.absmax[ABS_X] = 255;
	button_dev.absfuzz[ABS_X] = 4;
	button_dev.absflat[ABS_X] = 8;

或者，我们可以简单调用：

	input_set_abs_params(button_dev, ABS_X, 0, 255, 4, 8);

这种设定适合游戏杆的 X axis，最小值为 0，最大值为 255（游戏杆**必须**能够达到这个范围内的数值，偶尔超出这个范围也是没问题的，但是这个范围内的数值得能上报），数据的噪声为 +/- 4，点大小距中心位置为 8（**原文：**with a center flat position of size 8）。

如果你不需要 absfuzz 和 absflat，你可以把它们设为 0，这意味着报的值是非常精准的，并且每次都是在点的中心位置。

###1.4 BITS_TO_LONGS(), BIT_WORD(), BIT_MASK()

这 3 个在 `bitops.h` 中的宏简化一些位计算：

* BITS_TO_LONGS(x) - 返回 x 位在 long 类型数组中的长度
* BIT_WORD(x)	 - 返回第 x 位在 long 类型数组中得位置
* BIT_MASK(x)	 - 返回第 x 位在 long 中的位置掩码

###1.5 id* 和 name 字段

`dev->name` 必须在 INPUT 设备注册之前在驱动中设置。name 字段包含一个用户友好的设备名字，就像 “Generic button device” 一样。

id* 字段包含总线 ID（PCI，USB），以及该设备的 PID 和 VID。总线 ID 是在 `input.h` 文件中定义的。设备的 PID 和 VID 是在 `pci_ids.h`，`usb_ids.h` 和、等类似的头文件中定义的。这些字段应该在注册之前由设备驱动设置。

idtype 字段能够用于存储 INPUT 设备驱动的特殊信息。（**注：**最新的内核代码中已经没有该字段）

id 和 name 字段能够通过 evdev 接口传递给上层应用。

###1.6 keycode，keycodemax 和 keycodesize 字段

有很多按键映射的 INPUT 设备应该使用这三个字段。 keycode 是一个数组，用于映射从扫码（scancode）到 INPUT 系统的按键码（keycode）。keycodemax 应该包含该数组的大小，而 keycodesize 则是数组里每一项的大小（字节数）。

用户空间程序可以通过对应的 evdev 接口，使用 EVIOCGKEYCODE 和 EVIOCSKEYCODE ioctl 操作来查询和修改当前扫码到按键码的映射关系。当一个设备填充了前面提到的三个字段，其驱动应该基于内核默认的实现，设置和查询按键码映射。

###1.7 dev->getkeycode() and dev->setkeycode()

`getkeycode()` 和 `setkeycode()` 回调函数允许驱动覆盖 INPUT 核心提供的默认 `keycode/keycodesize/keycodemax` 映射机制，实现稀疏的按键映射。

###1.8 按键自动重复

按键自动重复比较简单。它是在 `input.c` 模块中处理的。硬件自动重复并没有被使用，因为并不是所有的设备都有这个功能，而且该功能不是很稳定（Toshiba 笔记本上得键盘）。要使能设备的自动重复功能，只需设置 `dev->evbit` 中的 EV_REP。INPUT 系统会处理所有的工作。

###1.9 特殊事件类型，处理事件输出

到目前为止，特殊事件类型有：

* EV_LED - 用于键盘灯
* EV_SND - 用于键盘蜂鸣器

（**注：**EV_LED 和 EV_SND 并不只是局限于键盘，对于其他设备的 LED 和 声音输出，也是可以使用的）

（**注：**在最新的内核代码里，除了这两个，还有 EV_FF，EV_FF_STATUS，和 EV_PWR，具体见 event-codes.txt）

他们和普通的按键事件非常类似，但是他们的方向是相反的 - 从系统到 INPUT 设备驱动。如果你的 INPUT 设备驱动能够处理这些事件，驱动中必须设置 evbit 中相应的位，和回调函数：

```
	button_dev->event = button_event;

int button_event(struct input_dev *dev, unsigned int type, unsigned int code, int value);
{
	if (type == EV_SND && code == SND_BELL) {
		outb(value, BUTTON_BELL);
		return 0;
	}
	return -1;
}
```
这个回调函数能够在中断上下文或者中断下半部中调用（尽管没有这个规则），因此这个回调函数里不能睡下去，也不能消耗过长的时间。
