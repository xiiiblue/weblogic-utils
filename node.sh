#!/bin/sh
# Program:
#   远程停启指定主机的nodemanager
#   需先配置SSH：主控机上执行 ssh-keygen -t rsa生成pubkey，添加到受控主机的~/.ssh/authorized_keys授权
#   nodelist配置示例：
#     主机           端口  启动脚本                    停止脚本
#     132.77.138.143 5566  /ngbss/webapp/startnode.sh  /ngbss/webapp/stopnode.sh
#     132.77.138.144 5566  /ngbss/webapp/startnode.sh  /ngbss/webapp/stopnode.sh
#     132.77.138.145 5566  /ngbss/webapp/startnode.sh  /ngbss/webapp/stopnode.sh
#   使用node.sh help获取帮助
# History:
#   2012/01/14  BlueXIII  创建


#设置初始变量
basedir=$(cd "$(dirname "$0")"; pwd)
nodelist="${basedir}/nodemanagers.lst"
DEBUG=false
TEST=false

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
  echo "功能：远程停启指定主机的nodemanager"
  echo "用法："
  echo "node.sh start 132.77.138.143  //启动一个nodemanager"
  echo "node.sh stop  132.77.138.143  //停止一个nodemanager"
  echo "node.sh startall              //启动所有nodemanager"
  echo "node.sh stopall               //停止所有nodemanager"
  echo "nodemanager清单详见：${nodelist}"
  echo "主机清单:"
  cat ${nodelist}|awk '{print $1}'
}

#函数：入参个数检测
function checkvarnum
{
  DEBUG echo "======开始checkvarnum()======"
  if [ $varnum -eq 0 -o $varnum -gt 2 ]
  then
    echo "错误：入参个数不正确！"
    help
    exit 1
  fi
}


#函数：入参1-action检测，并执行启停脚本
function checkaction
{
  DEBUG echo "======开始checkaction()======"
  if [ "${var1}" = "" ]
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
    elif [ "${action}" = "start" ]
    then
      checknodeip
      sshexecute $nodeip $startscript
    elif [ "${action}" = "stop" ]
    then
      checknodeip
      sshexecute $nodeip $stopscript
    elif [ "${action}" = "startall" ]
    then
      sshexcuteall "start"
    elif [ "${action}" = "stopall" ]
    then
      sshexcuteall "stop"
    else
      echo "错误：请输入正确的动作名称！"
      help
      exit 1
    fi
  fi
}

#函数：入参2-nodeip检测，并取得停启脚本路径
function checknodeip
{
  DEBUG echo "======开始checkservername()======"
  if [ "$var2" = "" ]
  then
    echo "错误：请输入IP，清单详见${nodelist}"
    exit 1
  else
    nodeip="$var2"
    export nodeip
    nodestr=`cat ${nodelist}|awk '{if($1==ENVIRON["nodeip"]){print $1" "$2" "$3" "$4}}'`  #取得nodestr
    if [ "nodestr" = "" ]
    then
      echo "错误：IP不正确，清单详见${nodelist}"
      help
      exit 1
    else
      nodeport=`echo $nodestr|awk '{print $2}'`
      startscript=`echo $nodestr|awk '{print $3}'`
      stopscript=`echo $nodestr|awk '{print $4}'`
      DEBUG echo "nodeip=${nodeip}"
      DEBUG echo "nodeport=${nodeport}"
      DEBUG echo "startscript=${startscript}"
      DEBUG echo "stopscript=${stopscript}"
    fi
  fi
}


#函数：执行远程停止脚本
function sshexecute
{
  DEBUG echo "======开始sshexecute()======"
  sship=$1
  sshscript=$2
  DEBUG echo "sship=${sship}"
  DEBUG echo "sshscript=${sshscript}"
  echo "Executing ${sship}:${sshscript} ..."
  if [ "$TEST" != "true" ]
  then
    ssh ${sship} "${sshscript}"
  else
    echo "测试模式，不实际执行脚本"
  fi
}

#函数：批量执行远程停止脚本
function sshexcuteall
{
  DEBUG echo "======开始sshexcuteall()======"
  sshaction=$1
  DEBUG echo "sshaction=${sshaction}"
  basedir=$PWD
  IFS_old=$IFS
  IFS=$'\n'
  for nodestr in $(sed '/^$/d' $nodelist)
  do
    DEBUG echo "nodestr=${nodestr}"
    nodeip=`echo $nodestr|awk '{print $1}'`
    nodeport=`echo $nodestr|awk '{print $2}'`
    startscript=`echo $nodestr|awk '{print $3}'`
    stopscript=`echo $nodestr|awk '{print $4}'`
    if [ ${sshaction} == "start" ]
    then
      sshexecute $nodeip $startscript
    elif [ ${sshaction} == "stop" ]
    then
      sshexecute $nodeip $stopscript
    else
      echo "错误：未知异常"
      exit 1
    fi
  done
  IFS=$IFS_old
}


#开始执行
varnum="$#"
var1="$1"
var2="$2"
DEBUG echo "入参个数="$varnum
DEBUG echo "入参1="$var1
DEBUG echo "入参2="$var2
checkvarnum
checkaction
echo "Done"
exit 0