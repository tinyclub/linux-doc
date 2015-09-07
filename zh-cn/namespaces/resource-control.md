> 原文: Documentation/namespaces/resource-control.txt
> 
> 翻译: [@choleraehyq](https://github.com/choleraehyq)
> 
> 校订: []()

在内核中，有许多这样的资源：它们或者没有独立的限制额度，或者在一个进程集合被允许切换用户 ID 时限制额度会失效。

因为不信任用户或用户程序而在内核开启用户命名空间功能之后，这个问题会变得更加严重。
 
因此我们建议，启用了用户命名空间功能的内核应当同时启用内存控制组功能。另外我们还建议，用户空间应当设置内存控制组来限制那些不可信的用户所能使用的内存大小。

内存控制组可以通过安装 `libcgroup` 来设置。在大多数发行版上，可以通过编辑 `/etc/cgrules.conf` ,
 `/etc/cgconfig.conf` 以及配置 `libpam-cgroup` 来安装 `libcgroup` 。
