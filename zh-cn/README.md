
# Linux 内核文档（中文版）

v 0.01

在内核源码的 `Documentation/` 目录下有大量高质量的内核文档，并且已经有部分翻译成了中文并保存在 `Documentation/zh_CN/` 下。

不过目前中文翻译进度几乎停滞，还有很大一部分还没有来得及翻译。而且早期用于中文翻译的网站如今也无法访问。

该项目用于重启中文翻译工作，并确保项目的可持续性，特别做如下规划：

* 所有翻译工作转到 [Github](https://www.github.com) 来协同，可以通过 Github Pull Request 来完成评审。
* 所有翻译结果用 [GitBook](http://www.gitbook.com) 来展示，并方便转换为如下格式（pdf, mobi, epub, html 等）。
* 所有翻译后的文档格式统一为 GitBook 支持的 [Markdown 格式](http://help.gitbook.com/format/markdown.html)。
* 为了专注于翻译本身，所有翻译结果暂时不考虑 Upstream 到内核主线。
* 优先把 `Documentation/zh_CN/` 下的中文文档转换为 Markdown 格式。
* 在翻译新文章时，请先把英文原文转为 Markdown 格式并存到 `en/` 下，之后再翻译为中文存到 `zh-cn/`。
* 目录结构尽量遵循 `Documentation/` 的原有方式。
* 基于目前最新的 longterm 版本 **3.18** 内核代码下的 [Documentation/](https://git.kernel.org/cgit/linux/kernel/git/stable/linux-stable.git/tree/Documentation?id=refs/tags/v3.18.20) 进行翻译和更新。

## 简介

-   代码仓库：<https://github.com/tinyclub/linux-doc>
-   在线阅读：<http://tinylab.gitbooks.io/linux-doc>
-   项目首页：<http://www.tinylab.org/linux-doc>
-   实验云台：<http://tinylab.cloud:6080>

## 参与翻译

请参考[译者须知](doc/README.md)。

### 安装

以 Ubuntu 为例：

    $ sudo aptitude install -y retext git nodejs npm
    $ sudo ln -fs /usr/bin/nodejs /usr/bin/node
    $ sudo aptitude install -y calibre fonts-arphic-gbsn00lp
    $ sudo npm install gitbook-cli -g

### 下载

    $ git clone https://github.com/tinyclub/open-c-book.git
    $ cd open-c-book/

### 编译

    $ gitbook build  // 编译成网页
    $ gitbook pdf    // 编译成 pdf

### 纠错

欢迎大家指出不足，如有任何疑问，请邮件联系 wuzhangjin at gmail dot com 或者直接修复并提交 Pull Request。

### 版权

本书采用 GPL v2 协议发布。

### 关注我们

-   [新浪微博](http://weibo.com/tinylaborg)

   [<img src="pic/tinylab-sina.jpg" width="150"/>](http://weibo.com/tinylaborg)

-   微信公众号

   <img src="pic/tinylab-weixin.jpg" width="150"/>


### 更多原创开源书籍

* [C 语言编程透视](http://tinylab.gitbooks.io/cbook/)
* [Shell 编程范例](http://tinylab.gitbooks.io/shellbook/)
* [嵌入式 Linux 知识库(eLinux.org 中文版)](http://tinylab.gitbooks.io/elinux/)

### 贡献者
<hr>
