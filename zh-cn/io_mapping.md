> 原文：Documentation/io_mapping.txt<br /> 
> 翻译：[@silenttung](https://github.com/dongfu8107)<br /> 
> 校订：[@NULL](#NULL)<br /> 

 `linux/io-mapping.h`中的 `io_mapping`函数提供了一个有效映射 `I/O`设备到 `CPU` 一小段地址
的抽象方法。这个函数最初的用法是用来支持32位处理器上 `aperture` 较大的显卡，
在 `32` 位处理器中不能用 `ioremap_wc` 静态映射整个 `aperture` 到 `CPU` ，因为 `ioremap_wc` 
映射会消耗大量的内核地址空间。

在驱动初始化过程中要映射的对象使用以下方法

```
    struct io_mapping *io_mapping_create_wc(unsigned long base,
                        unsigned long size)

	 'base' 是被映射区域的总线地址， ‘size’ 指示被映射区域有多大。二者都以字节
	为单位。

	 _wc variant 提供的映射方法只与 io_mapping_map_atomic_wc 或者 io_mapping_map_wc 一起使用。
```

使用这些映射对象，独立页面是否自动被映射取决于所需要的调度环境。当然， 原子映射更加有效:

```
    void *io_mapping_map_atomic_wc(struct io_mapping *mapping,
                       unsigned long offset)

    'offset'是在所定义映射区域的偏移量。访问在创建函数所指定区域外的地址会
    造成不可知的结果。使用非页对齐的偏移量会造成不可知的结果。返回值指向 `CPU`
    地址空间的一个页面。

	这个 _wc varint 返回页面的一个 write-combining 映射，并且只能被
	io_mapping_create_wc 所创建的映射使用。

	注意当保持这个页面被映射时该任务可能不会休眠。
```

```
	void io_mapping_unmap_atomic(void *vaddr)

	'vaddr'必须是最后 io_mapping_map_atomic_wc 调用返回的值。这个函数取消映射
	特定的页面且允许任务再次休眠。
```

如果需要在持有锁时休眠，可以使用非原子 `variant`，尽管这些函数会明显更慢一些。

```
    void *io_mapping_map_wc(struct io_mapping *mapping,
                unsigned long offset)

	这个函数与 io_mapping_map_atomic_wc 功能相同，除了该函数允许任务持有锁时
	休眠。
```

```
	void io_mapping_unmap(void *vaddr)

	这个函数与 io_mapping_unmap_atomic 功能基本相同，不同点在于它用来 io_mapping_map_wc
	所映射的页面解除映射时使用。
```

当驱动退出时，`io_mapping`对象必须被释放：

```
	void io_mapping_free(struct io_mapping *mapping)
```

当前实现方式：
	
这些函数最初的实现使用已有的映射机制，只是提供一个抽象层并没有新功能。

在 `64` 位处理器中，`io_mapping_create_wc` 全部调用 `ioremap_wc`， 对资源创建一个永久
的内核可见映射。 `map_atomic` 和 `map` 函数在 `ioremap_wc` 返回的虚拟地址的基地址上增加
所请求的偏移量。

在定义了 `HIGHMEM` 的 `32` 位处理器中，`io_mapping_map_atomic_wc` 使用 `kmap_atomic_pfn`
以原子方式映射所请求的页面。`kmap_atomic_pfn` 并不是真的被设备页面所使用，但它
提供为这种用法提供了一个有效的映射。

在没有定义 `HIGHMEM` 的 `32` 位处理器中，`io_mapping_map_atomic_wc` 和 `io_mapping_map_wc`
都使用 `ioremap_wc`，一个极度低效的函数用作 `IPI` 通知所有处理器有新的映射产生。这
造成了重大的性能损失。
