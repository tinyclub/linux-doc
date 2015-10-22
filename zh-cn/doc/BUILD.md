
# 如何构建 GitBook

## 安装

    $ sudo aptitude install -y retext git nodejs npm
    $ sudo ln -fs /usr/bin/nodejs /usr/bin/node
    $ sudo aptitude install -y calibre fonts-arphic-gbsn00lp
    $ npm config set registry https://registry.npm.taobao.org
    $ sudo npm install gitbook-cli -g

## 下载

    $ git clone https://github.com/tinyclub/linux-doc.git && cd linux-doc/

## 构建 GitBook

    $ gitbook build // make
    $ gitbook pdf   // make pdf
