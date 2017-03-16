# SMARTPBR #
## 介绍 ##
SmartPBR为一个帮助运维人员快速自动化安装策略路由服务，主要企业使用LINUX网关策略路由组网环境。

##功能 ##

 - 新增路由线路
 - 切换策略

## 包含组件 ##
    smartpbr-x.x.x          安装目录        /usr/local/smartpbr        配置文件    /etc/smartpbr
    
## 常用命令 ##

    ./smartpbr install    #安装smartpbr
    /etc/init.d/smartpbr  #交互交互式脚本

## 已测试编译环境 ##

    Red Hat Enterprise Linux Server release 6.4 (Santiago)
    

若特殊情况下需要手动安装，请按照以下规范进行安装

安装包内容：

    smartvpn_x.x.x
    │ smartpbr.sh                    #自动化脚本
    │
    └─config                         #配置文件夹
           line                      #线路文件夹
               └─x.config              #线路配置文件
           route.config                #路由配置文件
           rule.config                 #策略配置文件

## 手动操作 ##

1、添加dxt路由

    vim /etc/iproute2/rt_tables
    252	dxt

2、初始化dxt路由表

    ip route flush table dxt
    #dxt为新增加的路由表

3、增加访问网关的路由(否则自己无法访问网关)

    ip route add 192.168.8.0/24 via 192.168.8.253 dev eth1 table dxt
    #192.168.8.0/24:代表自己的网段,192.168.8.253为网关地址,eth1 代表出网卡,dxt代表路由表

4、增加默认路由

    ip route add default via 124.192.224.33 dev eth0 table dxt
    #Default:代表默认路由,124.192.224.33代表网关,eth0代表出网卡,dxt代表路由表

5、增加策略路由

    ip rule add from 192.168.8.0/24 table dxt
    #192.168.8.253代表网管IP,dxt代表路由表

6、切换SNAT

    iptables -t nat -I POSTROUTING -s 192.168.8.0/24 -j SNAT --to-source 124.192.224.55 
