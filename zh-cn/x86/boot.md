原文: Documentation/x86/boot.txt
翻译：@Andor
校订：

#x86 启动协议 #

在x86平台上，linux内核使用一个非常复杂的启动协议。这个演变部分是由于历史原因，以及在linux内核早期，为了使内核镜像成为一个自启动镜像而使用的那些算法，还有造成了复杂的计算机内存模型，再加上由于对计算机工业的期望的改变，造成了作为主流实模式操作系统Dos的消亡。

现存的Linux/86版本的启动协议：

**Old kernels**:    
>只支持zImage/Image了。许多非常早期的内核甚至都不支持命令行。

**Protocol 2.00**:	
>(内核版本 1.3.73) 增加了对bzImage和initrd的支持，作为一个正式的bootloader和kernel之间交流的方式。setup.S被设定为可重定位，尽管传统的setup区域仍然假定可写入。

**Protocol 2.01**:	
>(Kernel 1.3.76) 增加了一个堆溢出警告。

**Protocol 2.02**:	
>(Kernel 2.4.0-test3-pre3) 增加新命令行协议。把传统内存上限调低。setup区域不可以写入，这样做是针对使用EBDA（extended Bios Data Area）或者32位的BIOS入口更加安全(下边讲到原因)。zImage被废弃了，但是仍然是支持的。
>

**Protocol 2.03**:	
>(Kernel 2.4.18-pre1) 明确的使尽可能高initrd地址对bootloader可见。

**Protocol 2.04**:	
>(Kernel 2.6.14) 扩展了 syssize 字段到4个字节大小.

**Protocol 2.05**:	
>(Kernel 2.6.20) 使保护模式的内核可重定位。引入relocatable\_kernel和kernel\_alignment域。

**Protocol 2.06**:	
>(Kernel 2.6.22) 加入包含引导命令行的大小的字段。

**Protocol 2.07**:	
>(Kernel 2.6.24) 增加了半虚拟化引导协议。引入hardware\_subarch和hardware\_subarch\_data，并且在load\_flags中引入KEEP\_SEGMENTS标签。

**Protocol 2.08**:	
>(Kernel 2.6.26) 增加了crc32校验，并且对elf格式开始支持。引入payload\_offset和payload\_length字段以帮助定位所述有效载荷(指elf载荷--payload)。

**Protocol 2.09**:	
>(Kernel 2.6.26) 在单链表setup\_data结构体中增加一个64位物理指针。

**Protocol 2.10**:	
>(Kernel 2.6.31) 在协议中增加一个除了kernel\_alignment区域以外的非严格，增加了新的init\_size和pref\_address字段。增加了扩展的引导装载程序的ID。

**Protocol 2.11**:	
>(Kernel 3.6) 增加了一个字段用来记录EFI切换协议的入口点偏移量。

Protocol 2.12:	
>(Kernel 3.8) 在结构体boot\_params中增加了xloadflags和一些扩展字段，用来在64位系统中加载bzImage和ramdisk。

## 内存布局 -- MEMORY LAYOUT##
传统的针对内核加载器的内存映射，用来加载Image或者zImage内核，通常如下：

			|			        	 | 
	0A0000	+------------------------+ 
			|  Reserved for BIOS	 |	Do not use.  Reserved for BIOS EBDA。 
	09A000	+------------------------+ 
			|  Command line		 	 |
			|  Stack/heap		 	 |	For use by the kernel real-mode code。 
	098000	+------------------------+ 
			|  Kernel setup		 	 |	The kernel real-mode code。
	090200	+------------------------+ 
			|  Kernel boot sector	 |	The kernel legacy boot sector。 
	090000	+------------------------+ 
			|  Protected-mode kernel |	The bulk of the kernel image。
	010000	+------------------------+ 
			|  Boot loader		 	 |	<- Boot sector entry point 0000:7C00 
	001000	+------------------------+ 
			|  Reserved for MBR/BIOS | 
	000800	+------------------------+ 
			|  Typically used by MBR | 
	000600	+------------------------+ 
			|  BIOS use only	 	 | 
	000000	+------------------------+

当使用bzImage的时候，保护模式的内核被重定位到0x100000("high memory"),实模式内核块(boot sector, setup,和stack/heap)被重定位到0x10000和低端内存之间的任何区域。不幸的是，在协议2.00和2.010x，高于0x90000的内存范围仍然是由内核使用（内部使用）; 2.02协议解决了这个问题。

为了保证“memory ceiling”--在低端内存区域被bootloader所染指的内存上限--尽可能的低，因为一些新的BIOS已经开始分配一些相当大数量的内存，称为EBDA，靠近低内存的顶部。引导装载程序应该使用“int 12h”的BIOS调用来验证有多少低内存可用。

不幸的是，如果int 12h报告，存储器的量太低时，通常boot loader仅仅报告一个错误给用户，其他什么都不做。所以，boot loader应被设计为占用尽可能少的内存空间。对于的zImage或老的bzImage内核，这就需要写进0x90000段，boot loader应该确保不使用超过0x9A000的内存地址;太多的BIOS不遵守这个规则了。

对于一个现代化的bzImage内核启动协议，即版本>=2.02，内存布局建议如下：
	
			~                        ~ 
			|  Protected-mode kernel | 
	100000  +------------------------+ 
			|  I/O memory hole	 	 | 
	0A0000	+------------------------+ 
			|  Reserved for BIOS	 |	Leave as much as possible unused
			~                        ~
			|  Command line		 	 |	(Can also be below the X+10000 mark) 
	X+10000	+------------------------+ 
			|  Stack/heap		 	 |	For use by the kernel real-mode code。 
	X+08000	+------------------------+ 
			|  Kernel setup		 	 |	The kernel real-mode code。
			|  Kernel boot sector	 |	The kernel legacy boot sector。 
	X       +------------------------+ 
			|  Boot loader		 	 |	<- Boot sector entry point 0000:7C00 
	001000	+------------------------+ 
			|  Reserved for MBR/BIOS | 
	000800	+------------------------+ 
			|  Typically used by MBR | 
	000600	+------------------------+ 
			|  BIOS use only	 	 | 
	000000	+------------------------+

这里的地址X是尽可能的低的地址，低到boot loader能容忍的最低限度。

## 实模式内核头 -- THE REAL-MODE KERNEL HEADER##

在接下来的文本中，以及涉及到内核引导序列的任何地方，“扇区”指的是512字节。它是独立于底层介质的实际扇区大小。

装载Linux内核的第一步应该是加载实模式代码（boot sector和setup的代码），然后检查在偏移0x01f1处的头。实模式代码可以总额高达32K，虽然引导加载程序可能只加载前两个扇区（1K），然后检查启动扇区的大小。

代码头如下：

	Offset	Proto	Name			Meaning 
	/Size
	01F1/1	ALL(1	setup_sects		The size of the setup in sectors 
	01F2/2	ALL		root_flags		If set, the root is mounted readonly 
	01F4/4	2.04+(2	syssize			The size of the 32-bit code in 16-byte paras 
	01F8/2	ALL		ram_size		DO NOT USE - for bootsect.S use only 
	01FA/2	ALL		vid_mode		Video mode control 
	01FC/2	ALL		root_dev		Default root device number 
	01FE/2	ALL		boot_flag		0xAA55 magic number 
	0200/2	2.00+	jump			Jump instruction 
	0202/4	2.00+	header			Magic signature "HdrS" 
	0206/2	2.00+	version			Boot protocol version supported 
	0208/4	2.00+	realmode_swtch	Boot loader hook (see below) 
	020C/2	2.00+	start_sys_seg	The load-low segment (0x1000) (obsolete) 
	020E/2	2.00+	kernel_version	Pointer to kernel version string 
	0210/1	2.00+	type_of_loader	Boot loader identifier 
	0211/1	2.00+	loadflags		Boot protocol option flags 
	0212/2	2.00+	setup_move_size	Move to high memory size (used with hooks) 
	0214/4	2.00+	code32_start	Boot loader hook (see below) 
	0218/4	2.00+	ramdisk_image	initrd load address (set by boot loader) 
	021C/4	2.00+	ramdisk_size	initrd size (set by boot loader) 
	0220/4	2.00+	bootsect_kludge	DO NOT USE - for bootsect.S use only 
	0224/2	2.01+	heap_end_ptr	Free memory after setup end 
	0226/1	2.02+(3 ext_loader_ver	Extended boot loader version 
	0227/1	2.02+(3	ext_loader_type	Extended boot loader ID 
	0228/4	2.02+	cmd_line_ptr	32-bit pointer to the kernel command line 
	022C/4	2.03+	initrd_addr_max	Highest legal initrd address 
	0230/4	2.05+	kernel_alignment Physical addr alignment required for kernel 
	0234/1	2.05+	relocatable_kernel Whether kernel is relocatable or not 
	0235/1	2.10+	min_alignment	Minimum alignment, as a power of two 
	0236/2	2.12+	xloadflags		Boot protocol option flags 
	0238/4	2.06+	cmdline_size	Maximum size of the kernel command line 
	023C/4	2.07+	hardware_subarch Hardware subarchitecture 
	0240/8	2.07+	hardware_subarch_data Subarchitecture-specific data 
	0248/4	2.08+	payload_offset	Offset of kernel payload 
	024C/4	2.08+	payload_length	Length of kernel payload 
	0250/8	2.09+	setup_data	64-bit physical pointer to linked list of struct setup_data 
	0258/8	2.10+	pref_address	Preferred loading address 
	0260/4	2.10+	init_size	Linear memory required during initialization 
	0264/4	2.11+	handover_offset	Offset of handover entry point

（1）为了向后兼容，如果setup\_sects字段包含0，它真正的值是4。

（2）为了兼容2.04引导协议，syssize上两个字节字段不可用，这意味着一个bzImage的核的尺寸不能确定。

（3）忽略，但可安全设置，为引导协议2.02-2.09。

如果"HdrS"(0x5326448)幻数并没有在0x202偏移处找到，那么这个启动协议版本就是一个"旧版本"。加载一个老的内核版本，下面的参数应该被设置：

	Image type = zImage initrd not supported
	Real-mode kernel must be located at 0x90000。

否则，“version”字段包含协议版本，例如协议版本2.01那么该字段就等于0x0201。当在头设置了字段，你必须确保被使用的版本是该字段设置的值。

## 头字段详细分析 -- DETAILS OF HEADER FIELDS##

对于每一个字段，有些是从内核到bootloader（“read”），有些的信息被bootloader填充（“write”），其他一些被bootloader读并且修改（“modify“）。

所有通用boot loader应该写的字段都会被标记的（强制性的）。那些要把内核加载在一个非标准的地址的boot loader，应填写相应的boot loader字段标记（reloc）;其他的boot loader可以忽略这些字段。

所有字段的字节顺序为little endian（这毕竟是86的）。

	Field name:		setup_sects 
	Type:			read 
	Offset/size:	0x1f1/1 
	Protocol:		ALL

上述字段是512字节扇区中的安装程序代码的大小。如果该字段为0，真正的值是4，实模式代码由引导扇区（总有一个512字节扇区）加上setup代码。

	Field name:	 	root_flags 
	Type:		 	modify (optional) 
	Offset/size:	0x1f2/2 
	Protocol:	 	ALL

如果该字段为非零，root默认为只读。该领域已被弃用;使用命令行上的“ro”或“rw”选项来代替。

	Field name:		syssize 
	Type:			read 
	Offset/size:	0x1f4/4 (protocol 2.04+) 0x1f4/2 (protocol ALL) 
	Protocol:		2.04+

上述是保护模式的代码的大小，以16字节的段为单位。对于早于2.04版本的协议这一字段只有两个字节大小的，如果LOAD\_HIGH标志被置位，那么该内核的大小的值是无效的。

	Field name:		ram_size 
	Type:			kernel internal 
	Offset/size:	0x1f8/2 
	Protocol:		ALL

这个值已经非常陈旧了。

Field name:	vid\_mode 
Type:		modify (obligatory) 
Offset/size:	0x1fa/2

请看"SPECIAL COMMAND LINE OPTIONS"章节。

	Field name:		root_dev 
	Type:			modify (optional) 
	Offset/size:	0x1fc/2 
	Protocol:		ALL

默认的root设备的设备数量。该字段已被弃用，被"root="命令行选项代替。

	Field name:		boot_flag 
	Type:			read 
	Offset/size:	0x1fe/2 
	Protocol:		ALL

包含0xAA55。这是linux中最古老的一个幻数。

	Field name:		jump 
	Type:			read 
	Offset/size:	0x200/2 
	Protocol:		2.00+

包含一个x86跳转指令，在0xEB后跟一个带符号偏移量字节数是0x202。这可以被用于确定头的大小。

	Field name:		header 
	Type:			read 
	Offset/size:	0x202/4 
	Protocol:		2.00+

包含幻数"HdrS"(0x53726448)。

	Field name:		version 
	Type:			read 
	Offset/size:	0x206/2 
	Protocol:		2.00+

包含引导协议版本，在（major << 8）+ minor，例如：0x0204的版本2.04，0x0a11一个假的版本，表示10.17。

	Field name:		realmode_swtch 
	Type:			modify (optional) 
	Offset/size:	0x208/4 
	Protocol:		2.00+

boot loader的hook，请看下面的ADVANCED BOOT LOADER HOOKS章节。

	Field name:		start_sys_seg 
	Type:			read 
	Offset/size:	0x20c/2 
	Protocol:		2.00+

加载低段(0x1000),弃用。

	Field name:		kernel_version 
	Type:			read 
	Offset/size:	0x20e/2 
	Protocol:		2.00+

如果设置为非零值，包含一个指向一个NULL结尾的人类可读的内核版本号字符串。这可以用来显示内核版本给用户。此值应小于（为0x200\* setup\_sects）。

例如，如果这个值被设置为0x1c00，内核版本号码字符串可以在内核文件偏移0x1e00找到。只有当“setup\_sects”字段包含值15或更高的情况下，该值才是一个有效值，如：

	0x1c00  < 15\*0x200 (= 0x1e00) but 
	0x1c00 >= 14\*0x200 (= 0x1c00)
	0x1c00 >> 9 = 14

所以setup\_sects最小值是15。

	Field name:		type_of_loader 
	Type:			write (obligatory) 
	Offset/size:	0x210/1 
	Protocol:		2.00+

如果boot loader有一个分配的标识（见下表），例如0xTV，其中T是一个bootloader的标识符，V是一个版本号。如果不指派，就是0xFF的。

对于上述引导加载程序的ID，如果T=0xD，那么就给这个字段赋值为T=0xE，将扩展ID的值减去0x10赋给ext\_loader\_type字段。同样，ext\_loader_ver字段可用于提供超过4个位的bootloader版本。

例如：T = 0x15, V = 0x234,就输入如下

	type_of_loader  <- 0xE4 
	ext_loader_type <- 0x05
	ext_loader_ver  <- 0x23

已分配的引导加载程序id(16进制)：

	0  LILO			(0x00 reserved for pre-2.00 bootloader) 
	1  Loadlin 
	2  bootsect-loader	(0x20, all other values reserved) 
	3  Syslinux 
	4  Etherboot/gPXE/iPXE 
	5  ELILO 
	7  GRUB 
	8  U-Boot 
	9  Xen
	A  Gujin
	B  Qemu
	C  Arcturus Networks uCbootloader
	D  kexec-tools
	E  Extended		(see ext_loader_type)
	F  Special		(0xFF = undefined) 
	10  Reserved 
	11  Minimal Linux Bootloader <http://sebastian-plotz.blogspot.de> 
	12  OVMF UEFI virtualization stack

如果你需要分配一个新的bootloader的id，那么请联系<hpa@zytor.com>。

	Field name:		loadflags 
	Type:			modify (obligatory) 
	Offset/size:	0x211/1 
	Protocol:		2.00+

这个字段是一个位掩码。

	Bit 0 (read):	LOADED_HIGH
		- 如果 0, 保护模式的代码被加载在 0x10000。
		- 如果 1, 保护模式的代码被加载在 0x100000。
    Bit 5 (write): QUIET_FLAG
		- 如果 0, 打印启动前期信息。
		- 如果 1, 禁止打印前期的消息。这就要求内核（解压缩工具和早期内核）不编写直接访问显示硬件的早期消息。
	Bit 6 (write): KEEP_SEGMENTS 
		Protocol: 2.07+
		- 如果 0, 重新加载32位入口点段寄存器。
		- 如果 1, 不重新加载32位入口点段寄存器。假定％cs％的ds％ss％es都设置为平坦段并且基址是0（或相当于其环境来说是0）。
	Bit 7 (write): CAN_USE_HEAP 
	如果该位设置为1，表示在heap_end_ptr输入的值是有效的。如果该字段被清空，许多setup代码的功能将被禁用。

--

	Field name:		setup_move_size 
	Type:			modify (obligatory) 
	Offset/size:	0x212/2 
	Protocol:		2.00-2.01

当使用协议2.00或2.01，如果实模式内核没有加载在0x90000，它将在接下来的加载步骤中被移动带该地址。如果你想要添加更多的数据到实模式内核（如内核命令行）就填写该字段。

单位是字节，起始于引导扇区头。

当协议是2.02或更高，或者如果实模式代码加载在 0x90000 此字段可以被忽略。

	Field name:		code32_start 
	Type:			modify (optional, reloc) 
	Offset/size:	0x214/4 
	Protocol:		2.00+

该地址跳转到保护模式。此地址默认为内核的加载地址，并且可以被引导装载程序用来确定合适的装载地址。

修改该参数用来达到以下两个目的：

1. 作为 boot loader 的 hook（见下面的高级 BOOT LOADER HOOKS 章节。）

2. 如果一个 bootloader 没有安装hook，加载了一个可以重定位内核在一个非标准地址，那么必须修改该字段指向这个加载地址。

	Field name:	ramdisk_image 
	Type:		write (obligatory) 
	Offset/size:	0x218/4 
	Protocol:	2.00+

初始化 ramfs 或者 ramdisk 的 32 位线性地址。如果没有初始化ramfs或者ramdisk，那么赋值为0.

	Field name:		ramdisk_size 
	Type:			write (obligatory) 
	Offset/size:	0x21c/4 
	Protocol:		2.00+

初始 ramdisk 或 ramfs 的大小。如果没有初始 ramdisk/ramfs，清零。

	Field name:		bootsect_kludge 
	Type:			kernel internal 
	Offset/size:	0x220/4 
	Protocol:		2.00+

该字段已经弃用。

	Field name:		heap_end_ptr 
	Type:			write (obligatory) 
	Offset/size:	0x224/2 
	Protocol:		2.01+

此字段为实模式代码到setup的堆栈尾部的偏移减去 0x0200 之后的值。

	Field name:		ext_loader_ver 
	Type:			write (optional) 
	Offset/size:	0x226/1 
	Protocol:		2.02+

这个字段被用作版本号字段 type\_of\_loader 的扩展。总的版本号被认为是（type\_of\_loader＆为0x0F）+（ext\_loader\_ver<<4）。

使用本字段的是特定的 boot loader 。如果没有输入，它是零。

之前的 2.6.31 内核不识别这个字段，协议版本为 2.02 或更高版本已经支持。

	Field name:		ext_loader_type 
	Type:			write (obligatory if (type_of_loader & 0xf0) == 0xe0) 
	Offset/size:	0x227/1 
	Protocol:		2.02+

这个字段被用作类型数目作为 type\_of\_loader 字段的扩展。如果 type\_of\_loader 类型值为0xE，则实际类型是（ext\_loader\_type+0×10）。

如果type\_of\_loader类型值非0xE，这个字段被忽略。

2.6.31 内核启动协议不识别该字段，协议版本为2.02或更高版本支持该字段。

	Field name:		cmd_line_ptr 
	Type:			write (obligatory) 
	Offset/size:	0x228/4 
	Protocol:		2.02+

此字段设置为内核命令行的线性地址。内核命令行可以被加载在 0xA0000 到 setup heap 之间的任何地方;它不必设在与自身同一64K实模式段代码中。
即使你的引导装载程序不支持命令行，也请填写该字段，在这种情况下，你可以指向一个空字符串（更好的是指向字符串“auto”。）如果该字段置零，内核假设你的引导装载程序不支持2.02+协议。

	Field name:		initrd_addr_max 
	Type:			read 
	Offset/size:	0x22c/4 
	Protocol:		2.03+

最大地址值被初始化 ramdisk/ramfs 内容占用。对2.02或者之前版本的启动协议，这个字段不会出现，并且最大地址是 0x37FFFFFF。(这个地址被定义为字节编码最大的安全地址，所以如果你的 ramdisk 真正大小是 131072 字节，并且这个字段是 0x37FFFFFF,你可以设置你的 ramdisk 地址在 0x37FE0000).
	
	Field name:		kernel_alignment 
	Type:			read/modify (reloc) 
	Offset/size:	0x230/4 
	Protocol:		2.05+ (read), 2.10+ (modify)

内核需要对齐（如果 relocatable\_kernel 被设置了）。一个可重定位内核如果被加载在一个不兼容的对齐方式中，那么在初始化期间会重新调整该值。

从协议版本 2.10 开始，这个值反映了内核首选的对齐方式以获得最佳性能;加载器有可能修改该字段，以允许一个较小的对齐方式。见 min\_alignment 及以下 pref\_address 字段。

	Field name:		relocatable_kernel 
	Type:			read (reloc) 
	Offset/size:	0x234/1 
	Protocol:		2.05+

如果该字段为非零，内核保护模式的一部分代码可以被加载在满足 kernel\_alignment 字段的任何地址。装载后，启动引导器必须设置code32\_start字段指向被加载代码，或指向 boot loader 的 hook。

	Field name:		min_alignment 
	Type:			read (reloc) 
	Offset/size:	0x235/1 
	Protocol:		2.10+

如果该字段非零，则需要 2 的幂最小对齐方式，若不是优先选项，由内核引导。
如果 boot loader 使用这个字段，它应更新 kernel\_alignment 字段对应到所需的对齐单元;

典型：

	kernel_alignment = 1 << min_alignment

内核对齐方式如果严重不对，会对性能带来极大的损失。因此，一个加载器应该尝试每个2次幂的值，从kernel\_alignment到这个对齐值。

	Field name:     xloadflags 
	Type:           read 
	Offset/size:    0x236/2 
	Protocol:       2.12+

这个字段是位域。

	Bit 0 (read):	XLF_KERNEL_64
		- 如果 1, 这个内核具有传统的64位入口地址在 0x200.
  	Bit 1 (read): XLF\_CAN\_BE\_LOADED\_ABOVE\_4G
        - 如果 1, kernel/boot_params/cmdline/ramdisk 可以超过 4G.
  	Bit 2 (read):	XLF\_EFI\_HANDOVER\_32
		- 如果 1, 内核支持在特定handover_offset的32位入口点。
  	Bit 3 (read): XLF\_EFI\_HANDOVER\_64
		- 如果 1, 内核支持在handover_offset+0x200的64位入口点。
  	Bit 4 (read): XLF\_EFI\_KEXEC
		- 如果 1, 内核支持kexec的EFI启动与EFI运行时。

--

	Field name:	cmdline_size 
	Type:		read 
	Offset/size:	0x238/4 
	Protocol:	2.06+

命令行的最大大小减去截止字符串。这意味着，命令行可以包含至多 cmdline\_size 字符。随着协议版本 2.05 和更早的版本，最大大小为255。

	Field name:	hardware_subarch 
	Type:		write (optional, defaults to x86/PC) 
	Offset/size:	0x23c/4 
	Protocol:	2.07+

在一个半虚拟化环境中，底层的硬件体系如中断处理，页表的处理，访问过程控制寄存器之间有很多不同。

该字段允许引导装载程序告知内核我们是在一下这些环境中：

  	0x00000000	The default x86/PC environment 
	0x00000001	lguest 
	0x00000002	Xen 
	0x00000003	Moorestown MID 
	0x00000004	CE4100 TV Platform

Field name:	    hardware\_subarch\_data 
Type:		    write (subarch-dependent) 
Offset/size:	0x240/8 
Protocol:	    2.07+

一个指向特定于硬件的子体系数据， 该字段当前未使用默认的 x86/PC 环境，请不要修改。
	
	Field name:		payload_offset 
	Type:			read 
	Offset/size:	0x248/4 
	Protocol:		2.08+

如果不为零则此字段包含从保护模式的开头代码到有效负载的偏移量。

该有效载荷可被压缩。压缩和非压缩数据格式应使用标准的幻数。目前支持的压缩格式为 gzip 的（幻数为 1F 8B 或 1F 9E），bzip2 压缩（幻数 42 5A），LZMA （幻数 5D 00），XZ （幻数 FD 37），LZ4 （幻数 02 21）。目前未压缩的有效载荷是始终是 ELF （幻数 7F454C46）。

	Field name:		payload_length 
	Type:			read 
	Offset/size:	0x24c/4 
	Protocol:		2.08+

有效载荷的长度。

	Field name:		setup_data 
	Type:			write (special) 
	Offset/size:	0x250/8 
	Protocol:		2.09+

64位物理指针指向以NULL为终止的 setup\_data 结构体单链表。这是用来定义传递机制的更有扩展性的引导参数。结构 setup\_data 的定义是如下：

	struct setup_data 
	{ 
		u64 next;
		u32 type;
		u32 len;
		u8  data[0]; 
	};

这里，next 参数是 64 位物理指针的链表中下一个节点，最后一个节点的下一个字段是 0; type 被用于识别数据的内容; len 为数据字段的长度; data 保存真正的数据。

该列表可以在启动过程中的若干地点修改。因此，当修改该列表时，一定要考虑那里的链表已经包含条目的情况。

	Field name:		pref_address 
	Type:			read (reloc) 
	Offset/size:	0x258/8 
	Protocol:		2.10+

如果此字段为非零值，代表了内核中的首选加载地址。一个可重定位引导程序应该尝试加载内核在这个地址。

	Field name:		init_size 
	Type:			read 
	Offset/size:	0x260/4

该字段表示线性连续内存的数量，该地址起始于内核运行时开始地址，该地址是内核在可以检查映射内存的之前使用的。这个跟内核启动需要的内存总量不一样，但是它可以被用来重定位内核加载器来帮助选择一个安全的可加载地址。

内核运行时开始地址由下列算法决定：

	if(relocatable_kernel)
		runtime_start = align_up(load_address, kernel_alignment)
	else
		runtime_start = pref_address

	Field name:		handover_offset 
	Type:			read 
	Offset/size:	0x264/4

该字段表示的是从内核镜像开始到 EFI 切换协议入口点的偏移。如果启动加载器使用 EFI 切换协议来启动内核，应该跳转到该偏移。

详细请查看 EFI HANDOVER PROTOCOL 章节。

## 镜像检测 -- THE IMAGE CHECKSUM ##

在启动协议版本 2.08 之前，CRC-32使用多项式特征值0x04c11DB7和一个初始化余数 0xFFFFFFFF 来计算整个文件。校验和添加到该文件尾部。因此包含有 CRC 的文件中从校验码一直到syssize字段中指定的上限都是填充 0.

## 内核命令行 -- THE KERNEL COMMAND LINE ##

内核命令行已经变成一种 boot loader 跟 kernel 之间交流的重要方式。许多选项同样也关系到 boot loader 自身， 查看 "special command line options" 了解详情。

内核命令行是以 null 为结尾的字符串。最大长度由 cmdline\_size 定义。在 2.06 协议之前，最大字符数是 255 。一个字符串如果超过这个长度会被自动截断。

如果启动协议版本是 2.02 或之后的，内核命令行的地址是通过 cmd\_line\_ptr 给出（见上文）。这个地址可以是 setup heap 到 0xA0000 之间的任何值。

如果协议版本不是 2.02 或者更高，内核命令行通过以下协议来键入：

	在 0x0020 (word)偏移处, "cmd_line_magic", 输入幻数 0xA33F.
		
	在 0x0022 (word)偏移处, "cmd_line_offset", 输入内核命令行偏移 (相对于实模式的开始处).
		
	内核命令行 *必须* 在 setup_move_size 参数设定的内存区域之内, 所以你需要调整这个字段.

## 实模式代码内存布局 -- MEMORY LAYOUT OF THE REAL-MODE CODE ##

实模式代码需要构建在堆栈的基础上，就像分配给内核命令行的一样。这需要在实模式可访问内存的兆字节的底部。

现代的计算机通常都有一个可变大小的 EBDA ，这点需要强烈关注。这就使得使用尽量少的内存成为可能。

不幸的是，在下列情况下的 0x90000 内存段必须使用：

	- 当加载一个 zImage 镜像的时候 ((loadflags & 0x01) == 0).
	- 当加载一个 2.01 或者之前的内核时候.

	->	对 2.00 和 2.01 引导协议，实模式代码可以在另一地址被加载，
		但它是在内部迁移到 0x90000。对 "旧" 协议，实模式代码必须在 0x90000 加载。

当加载在 0x90000 ,要避免使用高于 0x9a000 以上的内存。

对于 2.02 以及高于这个版本的启动协议，命令行不需要放置在相同的 64K 段，跟实模式 setup 代码一样。因此，它允许给栈/堆完整 64K 段和命令行放置在该地址之上。

内核命令行不应该被放置在低于实模式的代码地址，也不应该被放置在高地址。

## 简单的启动配置 -- SAMPLE BOOT CONFIGURATION ##

作为一个简单的配置，假设以下是实模式代码段：

当加载到低于0x90000,使用全部段：

	0x0000-0x7fff	Real mode kernel 
	0x8000-0xdfff	Stack and heap 
	0xe000-0xffff	Kernel command line

当加载到0x90000或者协议版本是2.01或者之前的：

	0x0000-0x7fff	Real mode kernel 
	0x8000-0x97ff	Stack and heap 
	0x9800-0x9fff	Kernel command line

如上的boot loader应该键入如下的头字段：

	unsigned long base_ptr;	/* base address for real-mode segment */
	if ( setup_sects == 0 ) 
	{ 
		setup_sects = 4; 
	}
	if ( protocol >= 0x0200 ) 
	{ 
		type_of_loader = <type code>;
		if ( loading_initrd ) 
		{ 
			ramdisk_image = <initrd_address>;
			ramdisk_size = <initrd_size>; 
		}
		if ( protocol >= 0x0202 && loadflags & 0x01 ) 
			heap_end = 0xe000; 
		else 
			heap_end = 0x9800;
		if ( protocol >= 0x0201 ) 
		{ 
			heap_end_ptr = heap_end - 0x200;
			loadflags |= 0x80; /* CAN_USE_HEAP */ 
		}
		if ( protocol >= 0x0202 ) 
		{ 
			cmd_line_ptr = base_ptr + heap_end;
			strcpy(cmd_line_ptr, cmdline); 
		} 
		else 
		{ 
			cmd_line_magic	= 0xA33F;
			cmd_line_offset = heap_end;
			setup_move_size = heap_end + strlen(cmdline)+1;
			strcpy(base_ptr+cmd_line_offset, cmdline); 
		} 
	} 
	else 
	{ 
		/* Very old kernel */
		heap_end = 0x9800;
		cmd_line_magic	= 0xA33F;
		cmd_line_offset = heap_end;
		/* A very old kernel MUST have its real-mode code loaded at 0x90000 */
		if ( base_ptr != 0x90000 ) 
		{ 
			/* Copy the real-mode kernel */
			memcpy(0x90000, base_ptr, (setup_sects+1)*512);
			base_ptr = 0x90000;		 /* Relocated */ 
		}
		strcpy(0x90000+cmd_line_offset, cmdline);
		/* It is recommended to clear memory up to the 32K mark */
		memset(0x90000 + (setup_sects+1)*512, 0, (64-(setup_sects+1))*512); 
	}

## 加载内核剩下的部分 -- LOADING THE REST OF THE KERNEL ##

32位（非实模式）内核开始于内核文件的(setup\_sects+1)\*512偏移处（再次提醒，如果setup\_sects == 0, 真实值是4）。该内核文件如果是 Image/zImage 的话，应该被加载在 0x10000,如果是 bzImage 那么应该被加载在 0x100000。

如果内核文件是 bzImage，启动协议 >= 2.00 的话并且 loadflags 的 0x01 位(LOAD\_HIGH字段)被设置：

	is_bzImage = (protocol >= 0x0200) && (loadflags & 0x01);
	load_address = is_bzImage ? 0x100000 : 0x1000;

注：Image/zImage 内核大小可达512k，并且有可能使用整个的 0x1000-0x9000 的内存空间。在这种条件下，加载这些内核文件的实模式部分到0x90000是非常有必要的。bzImage内核则灵活性更高。

## 特殊命令行选项 -- SPECIAL COMMAND LINE OPTIONS ##
如果 boot loader 的命令行选项是由用户提供，用户可能期望下面的命令行选项能够很好的工作。这些选项，即使有一些已经对内核来说没有意义了，仍然没有从内核命令行中被删除。Boot loader 的创建者已经在 Documentation/kernel-paramenters.txt 文件中登记了那些需要额外设置的命令行选项，如果你需要新增的话，请查看该文档，避免冲突。

	vga=<mode> 
		这里的<mode>是一个整数值（用C语言表示的话，十进制、八进制或者十六进制都可以），
		或者是一下字符串中的一个: "normal" (代表 0xFFFF), "ext"（代表 0xFFFE）, "ask"
		(代表 0xFFFD).这些值应该通过 vid_mode 字段来设置，被内核在命令解析之前使用。
	mem=<size> 
		<size> 是一个整数值，可选项如下(大小写不敏感) K,M,G,T,P 或者 E(代表<<10, <<20
		,<<30,<<40,<<50或者<<60).这个字段指明了内存的上限。这个参数可能会影响 initrd
		的加载地址，因为 initrd 通常应该被加载在内存的上限处。注：该字段是内核和 bootloader
		都有的选项。
	initrd=<file> 
		被加载的 initrd 文件。该文件是显式的被 bootloader 依赖的，有一些 boot loader（例如
 		LILO）并没有这个选项。

此外，某些 boot loader 增加了一些用户指定的命令行选项：

	BOOT_IMAGE=<file> 
		被加载的启动镜像。再次声明，<file>是被 bootloader 显式依赖的。
	auto 
		内核被加载过程不需要用户显式的干预。

如果这些选项已经添加到 boot loader 中，强烈推荐这些选项放置在开头部分，位于用户指定字段或者配置指定字段命令行之前。否则，会产生如下困惑："init=/bin/sh" 被 "auto" 字段扰乱了。

## 运行内核 -- RUNNING THE KERNEL ##
跳转到内核入口之后就表示内核开始运行了，这个入口通常被放置在内核的实模式段偏移0x20处。这就是说，如果你把实模式内核代码加载到0x90000,那么内核入口点是0x9020:0000.

在入口点，ds = es = ss，这几个段描述符应该指向实模式代码的开始处(如果是代码被加载在 0x90000，那么该值为 0x9000),sp 应该被设置为一个合适的值，通常指向 heap 的顶部，并且中断被关闭了。甚至，为了防止内核 bug，推荐将 boot loader 设置如下fs = gs = ds = es = ss。

举个例子：

	/* Note: in the case of the "old" kernel protocol, 
	base_ptr must be == 0x90000 at this point; see the previous sample code */
	
	seg = base_ptr >> 4;
	
	cli();	/* Enter with interrupts disabled! */
	
	/* Set up the real-mode kernel stack */
	_SS = seg;
	_SP = heap_end;
	_DS = _ES = _FS = _GS = seg;
	jmp_far(seg+0x20, 0);	/* Run the kernel */

如果你是从软盘启动，那么推荐在内核启动之前关闭软驱马达，因为内核启动之后中断就关闭了，这样马达就无法关闭了，特别是如果加载的内核中将软驱作为一个按需加载模块的话，就会更麻烦了。

## 高级boot loader hooks -- ADVANCED BOOT LOADER HOOKS ##
如果 boot loader 运行在一个特别不友好的环境中(例如 LOADLIN，该工具运行在 DOS 中)它可能遵循以下标准内存分配需求。这个 boot loader 可能使用以下 hook，如果设置了，会被内核在合适的时机触发。使用这些hook也许就是一个完全的最后一招了！

重要：所有的 hook 都必须行使保护 %esp, %ebp, %esi 和 %edi 的权利。

	realmode_swtch: 
		16 位实模式子程序，进入保护模式之前调用。默认程序禁用 NMI，你的程序也应该这样做。
  	code32\_start: 
		在过渡到保护模式后迅速“跳转”到的一个 32 位平坦模式程序，这时内核还没有被解压缩。没有
		段，除了 CS，被保证设置（现代的内核做的，但旧的没有这么做）;你应该自己将它们设置为
		BOOT_DS（0x18）。

## 32位启动协议 -- 32-bit BOOT PROTOCOL ##

对于那些较新的 BIOS 来说，例如 EFI， LinuxBIOS， 等等，哦，还有kexec，16 位的基于传统 BIOS 的内核 setup 代码可以不使用了，所以一个 32 位的协议被提上日程了。

在 32 位的启动协议中，加载linux内核的第一步应该是设置启动参数(boot\_params结构体，传统称呼是"zero page")。分配给boot\_params的内存应该被初始化为0.然后内核偏移0x01f1处的setup header应该被加载到boot\_params中，并且加以检测。setup header 结尾地址可以通过以下计算的到：

	0x0202 + 0x0201 的字节值

除了读/修改/写 setup header 中的结构 boot\_params 的作为 16 位引导协议，引导加载程序还应该填写结构体 boot\_params 中在 zero-page.txt 描述的附加字段。

设置结构体 boot\_params 后，boot loader 可以用 16 位引导协议同样的方式装载32/64位内核。

在 32 位引导协议中，内核在跳转到 32 位的内核入口点后开始，也就是加载 32/64 位内核的开始地址。

在该入口点，CPU必须已经处于32位的保护模式，并且禁用了页表；一个必须加载了\_\_BOOT\_CS(0x10)和\_\_BOOT\_DS(0x18)段描述符的GDT；这两项必须是4G的平坦段；\_\_BOOT\_CS必须有xr权限，\_\_BOOT\_DS必须有wr权限.CS必须被设置为\_\_BOOT\_CS, DS、ES、SS必须被设置为\_\_BOOT\_DS;中断必须被禁用；%esi必须被设置为boot\_params结构体的基址；%ebp,%edi和%ebx设为0.

## 64位启动协议 -- 64-bit BOOT PROTOCOL ##
对于机使用 64 位 CPU 和 64 位内核的机器，我们可以使用 64 位引导程序，所以我们需要一个 64 位引导协议。

在 64 位的启动协议中，加载linux内核的第一步应该是设置启动参数(boot\_params结构体，传统称呼是"zero page")。分配给 boot\_params 的内存可以在任何地方，但是应该被初始化为 0.然后内核偏移 0x01f1 处的 setup header 应该被加载到 boot\_params 中，并且检测。setup header 结尾地址可以通过以下计算的到：

	0x0202 + 0x0201的字节值

除了读/修改/写 setup header 中的结构 boot\_params 的作为 16 位引导协议，引导加载程序还应该填写结构体 boot\_params 中在 zero-page.txt 描述的附加字段。

设置结构体 boot\_params 后，引导加载程序可以用 16 位引导协议同样的方式装载 64 位内核，但是与 32 位不同的是，内核可以被加载到高于 4G 的地址。

在 64 位引导协议，内核在跳转到 64 位的内核入口点后开始，这是加载 64 位内核的地址加上 0x200。

在该入口点，CPU必须已经处于64位的保护模式，并且开启了分页；通过 setup\_header.init\_size 设置了从加载内核的开始地址、 0页的地址还有命令行缓存地址的映射范围；一个必须加载了\_\_BOOT\_CS(0x10)和\_\_BOOT\_DS(0x18)段描述符的GDT；这两项必须是4G的平坦段；\_\_BOOT\_CS必须有xr权限，\_\_BOOT\_DS必须有 wr 权限。CS 必须被设置为\_\_BOOT\_CS, DS、ES、SS必须被设置为\_\_BOOT\_DS;中断必须被禁用；%rsi必须被设置为 boot\_params 结构体的基址。

## EFI切换协议 -- EFI HANDOVER PROTOCOL ##
该协议允许 boot loader 推迟初始化到EFI启动桩。boot loader 需要从启动镜像加载 kernel/initrd(s) ,然后跳转到 EFI 切换协议的切入点，该入口点是 HDR-> handover\_offset 表示的从startup\_{32,64} 开始计算的偏移量。

该切换入口点函数原型看起来是这样的：

	efi_main(void *handle, efi_system_table_t *table, struct boot_params *bp)

'handle' 是由 EFI 固件传递到引导加载程序的 EFI 镜像处理句柄，'table'是 EFI 系统表 - 这是在 UEFI 规范第2.3节所述的“切换状态”的前两个参数。 'BP' 是 boot loader 分配的启动 params。

boot loader\*必须\*填写 bp 中的字段，

	o hdr.code32_start o hdr.cmd_line_ptr
    o hdr.cmdline_size
    o hdr.ramdisk_image (if applicable)
    o hdr.ramdisk_size  (if applicable)

其他字段都设置为 0.






