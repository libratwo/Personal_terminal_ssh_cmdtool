# Personal_terminal_ssh_cmdtool

## introduce
a ssh cmd tool that intergration of:
* ssh-client
* sqlite3   `(store server data)`
* msys2/mintty    `(or other linux terminal)`
* sshpass   `a tool can pass the passwd independently`

> 暂时没有参数, 所有命令集成到了脚本内部, 所以兼容性需要自己调整
> 我暂时在win上操作, 便利性当然比不上xshell, securecrt
> 主要实现了:
> > server管理
> > 快速接入
> > 首次连接免确定ssh_key (ssh 参数)
> > 编码支持  (mintty 参数, 其它终端利用Profile方式类似)
> > 服务器常用的退格键 -> `^H` (mintty 参数)
> > `服务器和本地不同主题 (mintty 参数)
> > `利用mintty新建快捷键直接clone当前窗口连接`

## 为什么使用mintty做编码支持 不用 luit
* > linux平台xterm默认自动调用luit实现本地客户端和服务器的编码转换
  > 但是在加入sshpass后我的msys2平台出现乱码
* 通过调用mintty新开窗口, 后续可以直接克隆此连接, 比较方便


## Use
1. 重命名脚本为隐藏文件名(eg. .ssh_cmdtool.sh)
2. 放入个人tereminal HOME目录
3. 在shell的rc文件中source
4. 主要操作指令dssh/dsftp/lssh
    * 第一次: lssh init 1
    * 添加 lssh add/upd/del
    * dssh/dsftp 输出server列表
        * -f 参数输出详细server信息
    * dssh <id>   dssh <alias> 两种调用方式


![dssh.png](dssh)
