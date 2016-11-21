#!/bin/sh
# Program:
# 远程清理nodemanagers.lst中指定主机的webapp用户所有java进程
# 需先配置SSH：主控机上执行 ssh-keygen -t rsa生成pubkey，添加到受控主机的~/.ssh/authorized_keys授权
# History:
# 2012/01/12  BlueXIII  创建

echo -n "危险：确定要杀掉所有主机的webapp用户的进程吗？(如确定，请输入\"yes\")"
read yesorno
if [ $yesorno = "yes" ]
then
  echo -n "请再次确认!(如确定，请输入\"yes\")"
  read yesorno
  if [ $yesorno = "yes" ]
  then
    basedir=$PWD
    for host in $(cat $basedir/nodemanagers.lst|awk '{print $1}')
    do
      echo "Killing "$host"..."
      #ssh $host "ps -ef|grep $LOGNAME|grep java|grep -v grep|awk '{print "kill -9 "$2}'|sh"
    done
    exit 0
  fi
else
  echo "Exit"
  exit 1
fi