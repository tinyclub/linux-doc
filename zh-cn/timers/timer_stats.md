> 原文: [Documentation/timers/timer_stats.txt](https://www.kernel.org/doc/Documentation/timers/timer_stats.txt)<br/>
> 翻译: [@hduffddybz](https://github.com/hduffddybz)<br/>
> 校订: [@lzufalcon](https://github.com/lzufalcon)<br/>

# `timer_stats` - 定时器使用信息

`timer_stats` 是个调试工具，它使得内核和用户态开发者可以查看 Linux 系统中的定时器使用信息。
如果使能了该配置但是并没有使用，运行开销接近于 0 ，数据结构开销也相对小。
即使在采集的时候使能了数据采集，所有用到的锁都是 per-CPU（译注：避免了 spinlock），并且查找做了哈希处理优化的。

`timer_stats` 应被内核和用户态空间开发者使用，以便来确认他们的代码没有过度使用定时器。
这能帮助避免非必要的唤醒，进而优化功耗。

可以通过 “Kernel hacking” 配置部分的 `CONFIG_TIMER_STATS` 来使能 `timer_stats`。

`timer_stats` 收集 Linux 系统中某个采样周期内的定时事件信息:

- 初始化定时器的任务（进程）的进程描述符
- 初始化定时器的进程名
- 用于初始化定时器的函数
- 与定时器相关的回调函数
- 事件数（回调数）

`timer_stats` 在 `/proc` 下面添加一个条目: `/proc/timer_stats`

该条目用来控制统计功能并且读出采样信息。

`timer_stats` 功能在启动时是未被激活的。

为激活一个采样周期：

    # echo 1 >/proc/timer_stats

停止一个采样周期：

    # echo 0 >/proc/timer_stats

统计信息可以这样被取出:

    # cat /proc/timer_stats

当采样被使能时，每一次从 `/proc/timer_stats` 的输出会看到新更新的统计数据
 一旦采样被禁用时，采样信息会保持直到新的采样周期启动。 这就允许多次读出。

`/proc/timer_stats` 的样本输出样例:


```
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
第四列用户初始化定时器的函数，括号内表示在定时器到期时执行的回调函数。

    Thomas, Ingo 

在 `/proc/timer_stats` 中增加标志位 D 来表示 “可延期的定时器“。这样一个定时器例子如下：


      10D,     1 swapper          queue_delayed_work_on (delayed_work_timer_fn)
