#!/bin/sh
# Program:
#   测试端口是否开放
#   使用test.sh help获取帮助
# History:
#   2012/01/13  BlueXIII  创建

#设置初始变量
basedir=$(cd "$(dirname "$0")"; pwd)
managedlist="${basedir}/managedservers.lst"
adminlist="${basedir}/adminservers.lst"
nodelist="${basedir}/nodemanagers.lst"
DEBUG=false

#DEBUG开关
DEBUG()
{
  if [ "$DEBUG" = "true" ]
  then
    $@
  fi
}
     
#函数：打印帮助信息
function help
{
  DEBUG echo "======开始help()======"
  echo "功能：端口测试"
  echo "用法："
  echo "port.sh node     //测试nodemanager端口"
  echo "port.sh admin    //测试nodemanager端口"
  echo "port.sh server   //测试nodemanager端口"
}

#开始执行
var1=$1
IFS_old=$IFS
IFS=$'\n'
if [ "$var1" = "" ]
then
  echo "错误：请输入动作名称！"
  help
  exit 1
else
  action="$var1"
  DEBUG echo "action=${action}"
  if [ "${action}" = "help" ]
  then
    help
    exit 0
  elif [ "${action}" = "node" ]
  then
    for server in $(sed '/^$/d' $nodelist)
    do
      servername=`echo $server|awk '{print $1}'`
      serverip=`echo $server|awk '{print $1}'`
      serverport=`echo $server|awk '{print $2}'`
      testing=$(nc -z $serverip $serverport)
      if [ "$testing" != "" ]; then
    	  echo "$domainname $serverip:$serverport PASSED"
    	else
    	  echo "$domainname $serverip:$serverport FAILED"
      fi
    done
  elif [ "${action}" = "admin" ]
  then
    for server in $(sed '/^$/d' ${adminlist})
    do
      domainname=`echo $server|awk '{print $1}'`
      servername=`echo $server|awk '{print $2}'`
      serverip=`echo $server|awk '{print $3}'`
      serverport=`echo $server|awk '{print $4}'`
      testing=$(nc -z $serverip $serverport)
      if [ "$testing" != "" ]; then
    	  echo "$domainname	$servername	$serverip:$serverport	PASSED"
    	else
    	  echo "$domainname	$servername	$serverip:$serverport	FAILED"
      fi
    done  elif [ "${action}" = "server" ]
  then
    for server in $(sed '/^$/d' ${managedlist})
    do
      domainname=`echo $server|awk '{print $1}'`
      servername=`echo $server|awk '{print $2}'`
      serverip=`echo $server|awk '{print $3}'`
      serverport=`echo $server|awk '{print $4}'`
      testing=$(nc -z $serverip $serverport)
      if [ "$testing" != "" ]; then
    	  echo "$domainname	$servername	$serverip:$serverport	PASSED"
    	else
    	  echo "$domainname	$servername	$serverip:$serverport	FAILED"
      fi
    done
  fi
fi
IFS=$IFS_old
echo "Done"
exit 0            









