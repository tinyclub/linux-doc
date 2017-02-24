> 翻译:[@hduffddybz](https://github.com/hduffddybz)
> 校订:[]()
# `timer_stats` - 定时器使用信息
------------------------------------

`timer_stats` 是个调试工具使得在 Linux 系统中的定时器使用信息对内核态和用户态开发者可见。
如果使能了该配置但是并没有使用，运行开销接近于 0 ，数据结构开销也相对小。
即使启用了收集运行时的每个锁定是每个 CPU 相关的，并且查找是散列的。

`timer_stats` 应被内核和用户态空间开发者使用来确认他们的代码没有过度使用定时器。
这能帮助避免非必要的唤醒，优化功耗。

可以通过 “Kernel hacking” 配置部分的 `CONFIG_TIMER_STATS` 来使能 `timer_stats`。

`timer_stats` 收集 Linux 系统中一段采样时间触发的定时器事件的信息:

- 初始化定时器的任务（进程）的进程描述符
- 初始化定时器的进程名
- 定时器被初始化的函数
- 与定时器相关的回调函数
- 事件数（回调数）

`timer_stats` 在 `/proc: /proc/timer_stats` 下面添加一个条目

该条目用来控制统计功能并且读出采样信息。

`timer_stats` 功能在启动的时候是未被激活的。

为激活一个样本周期：
># `"echo 1 >/proc/timer_stats"`

停止一个采样周期：
># `"echo 0 >/proc/timer_stats"`

统计信息可以被取出:
># `"cat /proc/timer_stats"`

当采样被使能时，每一次从 `/proc/timer_stats` 的输出会看到新更新的数据
 一旦采样被禁用时，采样信息会保持直到新的采样周期启动。 这允许多个读出。

`/proc/timer_stats` 的样本输出值:

```c
Timerstats sample period: 3.888770 s
  12,     0 swapper          hrtimer_stop_sched_tick (hrtimer_sched_tick)
  15,     1 swapper          hcd_submit_urb (rh_timer_func)
   4,   959 kedac            schedule_timeout (process_timeout)
   1,     0 swapper          page_writeback_init (wb_timer_fn)
  28,     0 swapper          hrtimer_stop_sched_tick (hrtimer_sched_tick)
  22,  2948 IRQ 4            tty_flip_buffer_push (delayed_work_timer_fn)
   3,  3100 bash             schedule_timeout (process_timeout)
   1,     1 swapper          queue_delayed_work_on (delayed_work_timer_fn)
   1,     1 swapper          queue_delayed_work_on (delayed_work_timer_fn)
   1,     1 swapper          neigh_table_init_no_netlink (neigh_periodic_timer)
   1,  2292 ip               __netdev_watchdog_up (dev_watchdog)
   1,    23 events/1         do_cache_clean (delayed_work_timer_fn)
90 total events, 30.0 events/sec
```

第一列是事件数， 第二列是进程描述符， 第三列是进程的名字。
 第四列初始化定时器的函数，括号里表示当定时器到期时的回调函数。

    Thomas, Ingo 

在 `/proc/timer_stats` 中增加标志位来表示 “可延期的定时器“。可延期的定时器会
出现如下：
```c
 `10D,     1 swapper          queue_delayed_work_on (delayed_work_timer_fn`
```
