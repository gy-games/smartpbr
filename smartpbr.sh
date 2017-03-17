#!/bin/bash
show(){
echo "┌──────────────────────────────────────────────────────────────────────┐"
echo "│                              SMARTPBR                                │"
echo "├──────────────────────────────────────────────────────────────────────┤"
echo "│SMARTPBR IS A SHELL SCRIPT THAT HELP OPS SETUP POLICY BASED ROUTING S-│"
echo "│RVICE EASIER                                                          │"
echo "│                                                                      │"
echo "│                         VERSION : 0.0.3                              │"
echo "│                                                                      │"
echo "│   !NOTICE:IF THIS IS YOUR FIRST TIME USE THIS SCRIPT,INIT IT FIRST   │"
echo "│                                                                      │"
echo "│SCRIPT INCLUDE:                                                       │"
echo "│  smartpbr-0.0.1  INSTALL /usr/local/smartpbr  CONFIG /etc/smartpbr   │"
echo "│                                                                      │"
echo "│QUICK USE                                                             │"
echo "│  /etc/init.d/smartpbr #interactive                                   │"
echo "│                                                                      │"
echo "│                                                 PoweredBy GyyxOpTeam │"
echo "└──────────────────────────────────────────────────────────────────────┘"
}
WORKDIR="/usr/local/smartpbr"

initpbr(){
  ls $WORKDIR/config/line | grep -E "(.*).config" | awk -F "." '{print $1}' | while read PBRNAME
  do
    WANDEV=`cat $WORKDIR/config/line/$PBRNAME.config | awk -F = '/WANDEV/{printf $2}'`
    WANGW=`cat $WORKDIR/config/line/$PBRNAME.config | awk -F = '/GATEWAY/{printf $2}'`
    CHECKPBRNAME=`cat /etc/iproute2/rt_tables | grep -w $PBRNAME`
    if [ -n "$CHECKPBRNAME" ];then
      UPDATE="UPDATE"
      PBRNUM=`cat /etc/iproute2/rt_tables | grep -w $PBRNAME |awk {'print $1'}`
    else
      UPDATE="NEW"
      PBRNUM=$((`cat /etc/iproute2/rt_tables | grep -B 1 unspec | head -n 1 |awk {'print $1'}`-1))
    fi
    if [ $UPDATE == "NEW" ];then
      sed -i "/unspec/i$PBRNUM    $PBRNAME" /etc/iproute2/rt_tables
    fi
    ip route flush table $PBRNAME
    cat $WORKDIR/config/route.config | while read line
    do
      if [[ $line =~ "via" ]];then
        #echo ip route add $line table $PBRNAME 
        ip route add $line table $PBRNAME
      else
        #echo ip route add $line via $WANGW dev $WANDEV table $PBRNAME
        ip route add $line via $WANGW dev $WANDEV table $PBRNAME
      fi
    done
  done
  echo "ROUTE TABLE INIT FINISH!"
  exit 
}

changeline(){
  echo "CHANGING LINE.."
  iptables-save > /etc/sysconfig/iptables
  ip rule show | grep -v -E -w "local|main|default" | awk '{print $3" table "$5" "$6}' | while read line
  do
    ip rule del from $line
    cat /etc/sysconfig/iptables |  grep -nE "`echo $line | awk '{print $1 " -j SNAT --to-source"'}`" | awk -F ':' '{print $1}' | while read PREDELLINE
    do
      sed -i "$PREDELLINE,$PREDELLINE d" /etc/sysconfig/iptables
    done
  done
  cat $WORKDIR/config/rule.config  | while read line
  do
    ip rule add from ` echo $line | awk '{print $1" "$2" "$3}'`
    WANIP=`cat $WORKDIR/config/line/\`echo $line | awk '{print $3}'\`.config | grep -w \`echo $line | awk '{print $5}'\` | awk -F "=" '{print $2}'`
    ADDIPT=`echo -A POSTROUTING -s \`echo $line | awk '{print $1}'\` -j SNAT --to-source $WANIP`
    sed -i "$((`cat /etc/sysconfig/iptables | wc -l`-1)) i $ADDIPT" /etc/sysconfig/iptables
  done
  iptables-restore /etc/sysconfig/iptables
  echo "ROUTING TABLE CHANGE FINISH!"
  exit
}

#------------------------main------------------------------
while :
  do
   if [ "$1" == '' ];then
    basepath=$(cd `dirname $0`; pwd)
    if [[ $basepath != $WORKDIR ]] && [[ $basepath != "/etc/init.d" ]];then
      echo ""
      echo "YOU ARE NOT INSTALL IT YET,PLEASE RUN ./smartpbr.sh install FIRST"
      echo ""
      exit
    fi
    show
    read -p "PLEASE CHOICE YOUR FUNCTION(1:ROUTE SETTING , 2:CHANGE RULE):" FUN
    if [[ $FUN == "1" ]];then
      echo "                   VERFIY YOUR CONFIGRATION                  "
      echo ""
      ls $WORKDIR/config/line | grep -E "(.*).config" | awk -F "." '{print $1}' | while read line
      do
        WANDEV=`cat $WORKDIR/config/line/$line.config | awk -F = '/WANDEV/{printf $2}'`
        WANGW=`cat $WORKDIR/config/line/$line.config | awk -F = '/GATEWAY/{printf $2}'`
        CHECKPBRNAME=`cat /etc/iproute2/rt_tables | grep -w $line`
        if [ -n "$CHECKPBRNAME" ];then
          UPDATE="UPDATE"
        else
          UPDATE="NEW"
        fi
        echo "   ROUTE:$line STATUS:$UPDATE DEV:$WANDEV GW:$WANGW"
      done
      echo ""
      echo "                         ROUTING                           "
      cat $WORKDIR/config/route.config | while read line
      do
        if [[ $line =~ "via" ]];then
          echo "    $line"
        else
          echo "    $line via DEFAULGW dev DEFAULTDEV"
        fi
      done
      echo "                                                           "
      read -p "PLEASE VIRFY YOUR CONFIG?( y/n ):" BEGIN
      if [[ $BEGIN != "y" ]];then
        exit
      fi
      initpbr
    elif [[ $FUN == "2" ]];then
      clear all
      NOWRULE=`ip rule show | grep -v -E -w "local|main|default" | awk '{print $3" table "$5" "$6}'`
      echo $NOWRULE > $WORKDIR/config/.rule.config
      echo ""
      echo "                                        VERFIY YOUR CONFIGRATION                                       "
      echo "┌─────────────────────────────────────────────────────┬──────────────────────────────────────────────────────┐"
      echo "│                     ONLINE RULE                     │                         NEW RULE                     │"
      echo "├─────────────────────────────────────────────────────┼──────────────────────────────────────────────────────┤"
      NOWRULENUM=`echo $NOWRULE | wc -l`
      NEWRULENUM=`cat $WORKDIR/config/rule.config | wc -l`
      if [ $NOWRULENUM -gt $NEWRULENUM ];then
        CNT=$NOWRULENUM
      else
        CNT=$NEWRULENUM
      fi
      for((i=1;i<=$CNT;i++))
        do
          #RNUM=$((48-`sed -n "$i p" $WORKDIR/config/.rule.config | wc -c`))
          #LNUM=$((47-`sed -n "$i p" $WORKDIR/config/rule.config | wc -c`))
          line=`sed -n "$i p" $WORKDIR/config/rule.config`
          OLIP=`iptables -t nat -nvL |grep "SNAT"|grep "\`echo $line | awk '{print $1}'\`" | awk '{print $10}' | awk -F ":" '{print $2}'`
          WANIP=`cat $WORKDIR/config/line/\`echo $line | awk '{print $3}'\`.config | grep -w \`echo $line | awk '{print $5}'\` | awk -F "=" '{print $2}'`
          RNUM=$((48-`echo $OLIP | wc -c`-`sed -n "$i p" $WORKDIR/config/.rule.config  | wc -c`))
          LNUM=$((47-`sed -n "$i p" $WORKDIR/config/rule.config | wc -c`))
          echo "│" `for((j=0;j<$RNUM;j++))do printf ":"; done` `sed -n "$i p" $WORKDIR/config/.rule.config` "ip" `echo $OLIP`  "│" `sed -n "$i p" $WORKDIR/config/rule.config|awk '{print $1" "$2" "$3" "$4" " }'` `echo $WANIP` `for((j=0;j<$LNUM;j++))do printf ":"; done` "│"
        done
      echo "└─────────────────────────────────────────────────────┴──────────────────────────────────────────────────────┘" 
      echo ""
      read -p "PLEASE VIRFY YOUR CONFIG?( y/n ):" BEGIN
      if [[ $BEGIN != "y" ]];then
        exit
      fi
      changeline
    else
       echo "[FAIL]Param Error! PLEASE TRY AGAINE!"
    fi
   elif [ $1 == "install" ];then
      rm -rf $WORKDIR
      rm -rf /etc/init.d/smartpbr
      rm -rf /etc/smartpbr
      mkdir -p $WORKDIR
      cp -R ./* $WORKDIR
      ln -s $WORKDIR/smartpbr.sh /etc/init.d/smartpbr
      ln -s $WORKDIR/config /etc/smartpbr
      sed -i '/net.ipv4.ip_forward/ s/\(.*= \).*/\11/' /etc/sysctl.conf
      #echo "net.ipv4.neigh.default.gc_thresh1 = 512" >> /etc/sysctl.conf
      #echo "net.ipv4.neigh.default.gc_thresh2 = 2048" >> /etc/sysctl.conf
      #echo "net.ipv4.neigh.default.gc_thresh3 = 4096" >> /etc/sysctl.conf
      #echo "net.ipv4.neigh.eth0.base_reachable_time = 60" >> /etc/sysctl.conf
      #echo "net.ipv4.neigh.default.gc_stale_time = 120" >> /etc/sysctl.conf
      echo "                                                             "
      echo "                   SMARTPBR INIT SUCCESS                     "
      echo "                                                             "
      echo "          PLEASE RUN  /etc/init.d/smartpbr TO USE            "
      echo "                                                             "
      exit 
   else
      echo "[FAIL]Param Error! PLEASE TRY AGAINE!"
  fi 
  done
