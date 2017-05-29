
# Linux Documentation 翻译小组用户手册

## 报名参与

欢迎关注[泰晓科技](http://tinylab.org)的[新浪微博](http://weibo.com/tinylaborg)，私信报名参加该翻译项目。

## 翻译过程

* 注册并登录 github fork [代码仓库](https://github.com/tinyclub/linux-doc)

* 可选：注册 gitbook.com，在 gitbook.com 建立书籍并绑定到 github.com 刚 fork 的仓库。

* Clone 代码仓库

        git clone https://github.com/tinyclub/linux-doc.git

* 在 `Documentation/` 目录下选择自己想翻译或者想更新的文章（请检查 `zh-cn/` 下是否已经翻译好）

* 指定自己 fork 的远程代码仓库（用于后面发 Pull Request），以 Github 帐号：`lzufalcon` 为例（请替换为自己的帐号，下同；之后 `my-linux-doc` 就指向自己的 linux-doc 仓库）：

        git remote add my-linux-doc git@github.com:lzufalcon/linux-doc.git

* 基于自己计划翻译的内容创建分支， 以 `Documentation/CodingStyle` 为例，可以基于远程最新的 master 分支创建 `codingstyle` 分支：

        git fetch --all
        git checkout codingstyle tinyclub/master

* 参照 [Markdown 语法](http://help.gitbook.com/format/markdown.html)，把存到 `en/` 下并转为 Markdown 格式（后缀为 `.md`），以 `CodingStyle` 为例：

        cp Documentation/CodingStyle en/CodingStyle.md

    * 转换时可以适当用 `pandoc` 之类辅助，但是不可全信

                pandoc -t markdown --atx-headers Documentation/CodingStyle > en/CodingStyle.md

    * 转换完成后可以编译查看效果，如果 ok 就提交并发送 Pull Request，步骤见后面。

                make; make read

    * 如果原来有后缀，也一律改为 `.md`，不保留原来后缀。

* 把 `en/` 下的英文原稿同步到 `zh-cn/` 下，并把两个目录下的原稿一起提交为一笔 Git 修改记录。

    * *注*：请不要直接翻译 `en/` 下的内容，只翻译 `zh-cn/` 下的即可。


* 可选：翻译前请参照如下安装 `gitbook` 环境，以 Ubuntu 为例

        $ sudo aptitude install -y retext git nodejs npm
        $ sudo ln -fs /usr/bin/nodejs /usr/bin/node
        $ sudo aptitude install -y calibre fonts-arphic-gbsn00lp
        $ npm config set registry https://registry.npm.taobao.org
        $ sudo npm install gitbook-cli -g

    *注*：`calibre` 提供 `ebook-converter`，用于生成 pdf 等格式。


* 开始翻译

    * 翻译时可以用 gitbook.com 的在线编辑工具
    * 也可以用本地的工具，如 vim 编辑
    * 也可下载 GitBook Editor，界面类似在线编辑工具

* 翻译时

    * 请尽量遵守英文原稿的格式
    * 请规范使用 [Markdown 语法][markdown]
    * 中英文混排时，英文和数字短语前后须加空格，以便获得更好的视觉感受
    * 代码片段上下须加空行，代码片段可以用 \`\`\` 前后括起来，请参考 [Markdown][markdown] `Code and Syntax Highlighting` 一节。
    * --target 和 --host 之类的命令或者参数最好用标示符 \` 括起来。效果如：`--target` 和 `--host`
    * 全篇要统一用中文标点符号，全部用全角。
    * 碰到专业名词，特定缩写，不需要翻译。
    * 翻译后，只保留翻译后的中文译文，英文内容请移除。
    * 每翻译完一个段落请务必通读
        * 确保用词没有歧义，整段衔接流畅，如有必要请调整/添加必要的衔接词汇
        * 并对照英文原文确保没有漏掉原文任何需要表达的含义，不要刻意漏掉部分自己感觉模糊的词汇
    * 如果有部分段落或者词汇理解模糊，请优先在协作群讨论或者借助第三方翻译工具协助，推荐 bing.com, iciba.com
    * 请在文件头注明如下信息（校订请列出所有提供了反馈并被采纳的同学，翻译和校订以 `@lzufalcon` 为例），可以在 `zh-cn/doc/PLAN.md` 的最后找到大家的 github 地址：

	> 原文：[Documentation/CodingStyle](http://www.kernel.org/doc/Documentation/CodingStyle)<br/>
	> 翻译：[@lzufalcon](https://github.com/lzufalcon)<br/>
	> 校订：[@lzufalcon](https://github.com/lzufalcon)<br/>

    * 新同学参与 Review 而且其 Feedbacks 被采纳后请把其 Github ID 以及链接追加到校订者名单，多人请用逗号分开。
    * 重构文章内目录（**注**：对管理员有效，各位译者请忽略）

                export PATH=$PATH:/path/to/linux-doc/tools
                build-toc.sh xxx.md

    * 提交到 Git 仓库
        * 请统一使用如下 Subject 和 Message，全部使用英文，其中 n = 1,2,3,4...，根据 Review 次数追加

                    zh: Translate xxx.md (Vn)

                    V1: Fix up ...
                    V2: ...
                    V3: ...

* 可选：翻译后预览和编译

    * 在本地编写可用 `Retext` 工具 预览，也可用 `pandoc` 转为 html（**注**：`pandoc` 转换结果跟 `gitbook` 略有差异）

                pandoc -f markdown -t html xxx.markdown > xxx.html

    * 编译可选方案

        * 本地编译

                make && make pdf 或者 gitbook build && gitbook pdf

        * 直接提交到 github，会自动触发 gitbook.com 构建，以 `codingstyle` 分支为例（`my-linux-doc` 指向自己的 `linux-doc` 仓库）：

                git push my-linux-doc codingstyle

        * 添加 Travis-CI 自动构建支持
            * 登录 <https://travis-ci.org/>
            * 绑定 github 帐号并添加上述 fork 过来的 linux-doc 项目
            * 进入 Settings，打开所有选项（本书已添加 [.travis.yml](../.travis.yml)）

* 编译通过后可重新整理代码仓库

    * 针对某个文件，确保一个文件一条变更，可通过 `git rebase -i commit_id^` 来合并翻译过程中针对某个文件所有未提交变更。
    * 创建 upstream 分支，更新远程仓库，`rebase` 到最新仓库，并修复所有冲突

<!-- -->
        git checkout -b codingstyle_upstream codingstyle
        git fetch --all
        git rebase --onto tinyclub/master --root
        git push my-linux-doc codingstyle_upstream


* 之后，通过 Github 发送 Pull Request：本地选 `codingstyle_upstream`，远程选 `master`，也即是说要把自己仓库中的 `codingstyle_upstream` 合并到远程的 `master`

* 评审人员收到后会分配人员评审

* 根据评审人员反馈重新修改，并创建新分支用于进一步的评审，例如（记得追加 `Vn` 后缀，例如 V1，V2，而不是直接覆盖原来的分支，方便备份）：

        git checkout -b codingstyle_upstream_v1 codingstyle_upstream

        // 处理来自校订人员的各种反馈

        git fetch --all
        git rebase --onto tinyclub/master --root
        git push my-linux-doc codingstyle_upstream_v1

* 重复上述 Pull Request 步骤，直到被 Merge 到主线

[markdown]:http://help.gitbook.com/format/markdown.html
