> 原文：Documentation/input/multi-touch-protocol.txt<br />
> 翻译：[@wengpingbo](https://github.com/wengpingbo)<br />
> 校订：[@NULL](#NULL)<br />

# 多点触控协议

Copyright (C) 2009-2010 Henrik Rydberg <rydberg@euromail.se>

## 介绍

为了充分利用多指触控和多用户设备，我们需要一种能够上报多点接触的数据的方法，例如物体直接和设备表面接触。这个文档描述了一种多点触控协议，它允许内核驱动上报任意数量的触摸点数据。

这个协议根据硬件的能力，可以分为两种。对于不区分触摸点的设备（Type A），该协议描述了怎样把所有触点的原始数据传送给接收者。对于能够跟踪可辨别的触点的设备（Type B），该协议描述了怎样把独立的触点更新数据通过事件通道上报上去。

## 协议用法

触点的数据是通过独立的 `ABS_MT` 事件顺序送出。只有 `ABS_MT` 事件才会被识别为触点数据的一部分。目前，这些事件会被单点触控应用忽略掉，所以多点触控协议可以在已存驱动中得单点触控协议之上实现。

对于 TYPE A 的设备驱动来说，触摸数据是通过在数据包最后调用 `input_mt_sync()` 来分割的。这会生成一个 `SYN_MT_REPORT` 事件，从而通知接收者接受当前触摸数据，并准备下一次接收。

对于 TYPE B 的设备驱动来说，触摸数据的分割是通过在每一个数据包之前调用 `input_mt_slot()`，该函数带有一个 slot 参数。这会生成一个 `ABS_MT_SLOT` 事件，通知接收者准备接受指定通道的更新。

所有驱动都是通过调用 `input_sync()` 函数来标记多点触摸传输的结束。这会通知接收者处理在上一次 `EV_SYN`/`SYN_REPORT` 事件之前累计的事件，并准备接收一批新的事件 / 数据包。

无状态的 TYPE A 协议和有状态的 TYPE B 协议之间主要的差别在于对可分辨的触摸点的使用，来减少传送给用户空间的数据总量。TYPE B 协议要求使用 `ABS_MT_TRACKING_ID`，通过硬件提供，或者通过原始数据计算出来 \[5\]。

对于 TYPE A 的设备，内核驱动应该为当前还在设备上的所有触摸点生成一个随机的枚举（**注：**编号？？）。数据包在事件流上出现的顺序并不重要。事件过滤和手指跟踪是留给用户空间去做 \[3\]。

对于 TYPE B 的设备，内核驱动需要把每一个可分辨的触摸点和一个通道联系在一起，并且使用该通道来传送该触摸点的变动。触摸点的创建，替换和消除可以通过修改相应通道的 `ABS_MT_TRACKING_ID` 来实现。一个非负数的 TRACKING_ID 代表一个触摸点，-1 代表一个不使用的通道。一个新的 TRACKING_ID 代表一个新的触摸点，而一个不出现的 TRACKING_ID 代表触摸点已经移除了。由于是增量传递，接收端会保留每一个触控点的全部状态属性。当接受到一个 MT 事件后，只需要更新当前通道特定的属性。

有一些设备能够分辨亦或跟踪多个可以上报给驱动的触摸点（**注：**这里原文是 more contacts than they can report to the driver，但语义不通。这里根据上下文把 than 改为 that 来翻译）。该类型设备的驱动应该把硬件上报的每一个触摸点都和一个 Type B 的通道相关联。当区分出和一个通道相关联的触摸点改变时（**原文：**identity of the contact associated with a slot changes），驱动应该通过改变它的 `ABS_MT_TRACKING_ID` 来关闭该通道。若硬件上报有新增的触摸点（**注：**？？），驱动应该使用 `BTN_TOOL_*TAP` 事件来通知用户空间当前硬件上跟踪的触摸点总数。当调用 `input_mt_report_pointer_emulation()` 时，驱动应该明确的发送 `BTN_TOOL_*TAP` 事件，并且把 `use_count` 置为 false。驱动最多只能创建硬件支持的最大触摸点数的通道。用户态程序可以通过发现最大支持的 `BTN_TOOL_*TAP` 事件比 `ABS_MT_SLOT` 轴上报的 Type B 通道的总数大，来检测出这种情况。（**注：**？？）

`ABS_MT_SLOT` 轴的最小值必须为 0。

## Type A 协议示例

这是 Type A 协议设备下双指触摸所需要的最少事件序列：

```
ABS_MT_POSITION_X x[0]
ABS_MT_POSITION_Y y[0]
SYN_MT_REPORT
ABS_MT_POSITION_X x[1]
ABS_MT_POSITION_Y y[1]
SYN_MT_REPORT
SYN_REPORT
```
移动其中一个手指产生的事件序列跟上面基本一致；在每个同步事件 `SYN_REPORT` 之间，将会发送所有触摸点的裸数据。

这是抬起第一个触摸点所产生的事件序列：

```
ABS_MT_POSITION_X x[1]
ABS_MT_POSITION_Y y[1]
SYN_MT_REPORT
SYN_REPORT
```
这是抬起第二个触摸点所产生的事件序列：

```
SYN_MT_REPORT
SYN_REPORT
```
如果驱动除了上报 `ABS_MT` 事件之外，还上报了 `BTN_TOUCH` 和 `ABS_PRESSURE` 中的一种，则最后的 `SYN_MT_REPORT` 事件可能会被忽略掉。此外，`SYN_REPORT` 事件也会被 INPUT 核心系统丢掉，导致触点清除事件（**注：**zero-contact event）无法到达上层。

## Type B 协议示例

这是 Type B 协议设备下两指触摸产生的最少事件序列：

```
ABS_MT_SLOT 0
ABS_MT_TRACKING_ID 45
ABS_MT_POSITION_X x[0]
ABS_MT_POSITION_Y y[0]
ABS_MT_SLOT 1
ABS_MT_TRACKING_ID 46
ABS_MT_POSITION_X x[1]
ABS_MT_POSITION_Y y[1]
SYN_REPORT
```
这是 ID 为 45 的触点在 X 轴方向移动时产生的事件序列：

```
ABS_MT_SLOT 0
ABS_MT_POSITION_X x[0]
SYN_REPORT
```
这是通道 0 上得触点抬起后产生的事件序列：

```
ABS_MT_TRACKING_ID -1
SYN_REPORT
```
当前通道已经是 0 了，所以 `ABS_MT_SLOT` 事件被忽略掉了。这个消息的意思是移除通道 0 和触点 45 之间的联系，因此会清除触点 45，并释放通道 0，其他触点就能重复使用。

最后，是第二个触点抬起时产生的事件序列：

```
ABS_MT_SLOT 1
ABS_MT_TRACKING_ID -1
SYN_REPORT
```

## 事件的用法

`ABS_MT` 系列事件都带有不同的属性。这些事件分为几类，允许部分实现。最小集合包括 `ABS_MT_POSITION_X` 和 `ABS_MT_POSITION_Y`，用来跟踪多个触点。如果设备支持这个特性，`ABS_MT_TOUCH_MAJOR` 和 `ABS_MT_WIDTH_MAJOR` 可以分别用于表示触点真实接触面积的宽度和触点本身的宽度。

`TOUCH` 和 `WIDTH` 参数有一个几何上得解释；想象一下有一个人把一个手指按压在玻璃面板上。你将会看到两个区域，一个是内部手指真正触摸在玻璃面板上的区域，另外一个是手指外围形成的一个区域。真实的触摸区域（a）的中心坐标用 `ABS_MT_POSITION_X/Y` 表示，而手指外围区域（b）的中心坐标用 `ABS_MT_TOOL_X/Y` 表示。真实触摸区域的直径用 `ABS_MT_TOUCH_MAJOR` 指定，手指的直径是 `ABS_MT_WIDTH_MAJOR` 指定。现在想象一下这个人用力按压玻璃面板，通常，真实触摸的区域将会增加，`ABS_MT_TOUCH_MAJOR` / `ABS_MT_WIDTH_MAJOR` 的比例也会随着压力的增大而增大，但总是比 1 小。对于能感知压力的设备，`ABS_MT_PRESSURE` 可以用于上报设备上的压力值。支持悬浮操作的设备可以用 `ABS_MT_DISTANCE` 来表示当前触摸距离面板表面的距离。


```
      Linux MT                               Win8
         __________                     _______________________
        /          \                   |                       |
       /            \                  |                       |
      /     ____     \                 |                       |
     /     /    \     \                |                       |
     \     \  a  \     \               |       a               |
      \     \____/      \              |                       |
       \                 \             |                       |
        \        b        \            |           b           |
         \                 \           |                       |
          \                 \          |                       |
           \                 \         |                       |
            \                /         |                       |
             \              /          |                       |
              \            /           |                       |
               \__________/            |_______________________|
```

除了 `MAJOR` 参数外，触摸和手指的椭圆形状也可以通过添加 `MINOR` 参数来表示，这样 `MAJOR` 和 `MINOR` 就分别代表椭圆的长短轴。椭圆形触摸的方向可以通过 `ORIENTATION` 参数来表示，手指形成的椭圆形朝向是由向量 （a - b）决定。

对于 Type A 的设备来说，未来的标准中，触摸形状可能用 `ABS_MT_BLOB_ID`。

`ABS_MT_TOOL_TYPE` 用于指定触摸工具是手指，触摸笔或者其他工具。最后，`ABS_MT_TRACKING_ID` 事件可以用来跟踪不同事件下相同的触点 \[5\]。

在 Type B 协议中，`ABS_MT_TOOL_TYPE` 和 `ABS_MT_TRACKING_ID` 事件是在 INPUT 核心中处理的；驱动应该使用 `input_mt_report_slot_state()`。

## 事件的含义

- `ABS_MT_TOUCH_MAJOR`

	触点长轴的长度。该长度应该和屏幕尺寸单位一致。若屏幕有 X * Y 的分辨率，则 `ABS_MT_TOUCH_MAJOR` 最大的长度为对角线 - `sqrt(X^2 + Y^2)`。

- `ABS_MT_TOUCH_MINOR`

	触点短轴的长度，屏幕尺寸单位。若触点形状是圆形，该事件可以忽略 \[4\]。

- `ABS_MT_WIDTH_MAJOR`

	触点工具长轴的长度，屏幕尺寸单位。这应该理解为触点工具本身的大小。这里假设触点的方向和触点工具的方向是相同的 \[4\]。

- `ABS_MT_WIDTH_MINOR`

	触点工具短轴的长度，屏幕尺寸单位。若触点工具的形状是圆形，则忽略该事件 \[4\]。

这里可以利用上面四个事件来获取额外的触点信息。比如，可以用 `ABS_MT_TOUCH_MAJOR` / `ABS_MT_WIDTH_MAJOR` 比例来表示触摸压力的大小。手指和手掌都有不同的宽度特征，可以用来做区分。

- `ABS_MT_PRESSURE`

	当前触摸区域的压力，任意单位。可以用于基于压力的设备，取代 `TOUCH` 和 `WIDTH`，或者用于任何带有空间压力分布感应信号的设备。

- `ABS_MT_DISTANCE`

	触点和屏幕表面之间的距离，屏幕尺寸单位。0 距离意味着触点和屏幕是接触的。一个正数意味着触点是悬浮在屏幕之上的。

- `ABS_MT_ORIENTATION`

	触点椭圆外形的方向。该值应该描述触点中心顺时针一周中的 1/4 的方位。带符号数值的范围是随意的。但是，当触点椭圆外形和表面 Y 轴对齐时，应该返回 0 值。当椭圆外形向左转变时，应该返回负值，向右转变时，应该返回正值。当完全和 X 轴对齐时，应该返回范围最大值。
	
	触点椭圆外形默认是对称的。对于那些能够检测 360 度方向的设备，上报的值一定要超过范围最大值，来显示大于一周的 1/4。对于一个颠倒的手指，应该返回 `max * 2`。
	
	当触摸区域是圆形时，方位是可以忽略的，或者内核驱动获取不到该信息。如果设备只能识别两个轴，不能分辨出介于两者之间的值，内核驱动可以部分支持该事件。在这种情况下，`ABS_MT_ORIENTATION` 的范围应该为 \[0, 1\] \[4\]。

- `ABS_MT_POSITION_X`

	触点椭圆外形中心点 X 轴坐标值

- `ABS_MT_POSITION_Y`

	触点椭圆外形中心点 Y 轴坐标值

- `ABS_MT_TOOL_X`

	触摸工具中心点的 X 轴坐标值。若设备无法分辨触摸点和触摸工具自身时，该事件可以忽略。

- `ABS_MT_TOOL_Y`

	触摸工具中心点的 Y 轴坐标值。若设备无法分辨触摸点和触摸工具自身时，该事件可以忽略。

这 4 个位置值可以用于分割触点位置和触摸工具位置。若两者都有，工具轴是指向触点的。否者，工具轴和触点轴是对齐的。

- `ABS_MT_TOOL_TYPE`

	触摸工具的类型。许多内核驱动无法分辨触摸工具的类型，例如是手指或者触摸笔。在这种情况下，这个事件应该被忽略掉。这个协议当前支持 `MT_TOOL_FINGER` 和 `MT_TOOL_PEN` 两者类型 \[2\]。对于类型 B 的设备，这个事件是由 INPUT 子系统核心处理。驱动应该使用 `input_mt_report_slot_state()` 函数。

- `ABS_MT_BLOB_ID`

	`BLOB_ID` 把多个包组合成一个任意形状的触点。顺序的坐标点形成一个多边形，定义了触点的形状。这是一个类型 A 设备上的匿名分组，应该和 trackingID 区分开。大部分类型 A 设备没有 ‘BLOB’ 能力，所以驱动可以安全的忽略这个事件。

- `ABS_MT_TRACKING_ID`

	`TRACKING_ID` 标示一个触点的整个生命周期 \[5\]。`TRACKING_ID` 的数值范围应该足够大，从而保证一段时间类的每一个触点标示都是唯一的。对于类型 B 设备来说，这个事件是由 INPUT 子系统核心处理，驱动应该使用 `input_mt_report_slot_state()` 函数。

## 事件计算

由于不同硬件的差异，不可避免的会导致有一些设备比其他设备更适合多指触控协议。为了简化和统一，这个章节列举了一些特定事件的计算。

对于上报长方形触点的设备，带符号的方向是获取不到的。假定 X 和 Y 是长方形触点两边的长度，下面是一个简单的公式获取最多的信息：

```
ABS_MT_TOUCH_MAJOR := max(X, Y)
ABS_MT_TOUCH_MINOR := min(X, Y)
ABS_MT_ORIENTATION := bool(X > Y)
```

`ABS_MT_ORIENTATION` 的方向应该是 \[0, 1\]，来显示该设备能够区分手指和 Y 轴对齐 (0) 和手指和 X 轴对齐 (1)。

对于带有 T 和 C 坐标的 Win8 设备，坐标映射为：

```
ABS_MT_POSITION_X := T_X
ABS_MT_POSITION_Y := T_Y
ABS_MT_TOOL_X := C_X
ABS_MT_TOOL_X := C_Y
```
不幸的是，这没有足够的信息来指出触点椭圆外形和触摸工具椭圆外形的参数，所以只能去估计。这有一个简单的方案，和之前的用法兼容：

```
ABS_MT_TOUCH_MAJOR := min(X, Y)
ABS_MT_TOUCH_MINOR := <not used>
ABS_MT_ORIENTATION := <not used>
ABS_MT_WIDTH_MAJOR := min(X, Y) + distance(T, C)
ABS_MT_WIDTH_MINOR := min(X, Y)
```

原理：我们不知道触点椭圆外形的方向，所以只能假定是圆形。触摸工具椭圆外形应该和向量 (T - C) 对齐，所以直径应该增加 (T - C) 向量的长度。最后，假定触点直径是等于工具的厚度的，这样我们就有了以上公式。

## 手指跟踪

手指的跟踪流程，例如给每一个表面上的触点分配一个独立 trackingID，是一个欧几里德二分图匹配问题。在每一个事件同步时，实际的触点集合和前一个同步时的触点集合是匹配的。完整的实现可以在 \[3\] 找到。

## 手势

在一个实际的创建手势事件的应用中， TOUCH 和 WIDTH 参数可以用于估算手指触摸的压力或者区分拇指和其他手指。加上额外的 MINOR 参数，我们也可以区分滑动的手指和点击的手指，若再加上 ORIENTATION，我们还可以检测手指的转动。

## 笔记

为了和现有的应用保持兼容，在一个手指数据包里，上报的数据一定不能识别为单一触摸事件。

对于类型 A 设备来说，由于随后相同事件类型的事件指向不同的手指，所有的触摸数据都会跳过 INPUT 过滤。

类型 A 协议的使用范例见 bcm5974 驱动。对于类型 B 协议的使用范例，见 hid-egalax 驱动。

* [1] 同样, (`TOOL_X` - `POSITION_X`) 的差值可以用于模型倾斜
* [2] 该列表可以被扩展
* [3] mtdev 项目主页： http://bitmath.org/code/mtdev/
* [4] 看 [事件计算] 小节
* [5] 看 [手指跟踪] 小节
