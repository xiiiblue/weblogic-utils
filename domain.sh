#!/bin/sh
# Program:
#   远程停启指定主机的AdminServer
#   需先配置SSH：主控机上执行 ssh-keygen -t rsa生成pubkey，添加到受控主机的~/.ssh/authorized_keys授权
#   adminlist配置示例：
#     域名称       AdminServer名称   IP             端口 Console用户  密码       启动脚本
#     ProxyDom     AdminServer       132.77.138.155 6001 weblogic     web123321  /ngbss1/webapp/domains/ProxyDom/start.sh     /ngbss1/webapp/domains/ProxyDom/stop.sh   
#     AcctManmDom  AdminServer       132.77.138.155 6401 weblogic     web123321  /ngbss1/webapp/domains/AcctManmDom/start.sh  /ngbss1/webapp/domains/AcctManmDom/stop.sh
#     CustServDom  AdminServer       132.77.138.155 6501 weblogic     web123321  /ngbss1/webapp/domains/CustServDom/start.sh  /ngbss1/webapp/domains/CustServDom/stop.sh
#   使用domain.sh help获取帮助
# History:
#   2012/01/14  BlueXIII  创建

#设置初始变量
basedir=$(cd "$(dirname "$0")"; pwd)
adminlist="${basedir}/adminservers.lst"
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
  echo "功能：远程停启指定主机的AdminServer"
  echo "用法："
  echo "domain.sh start ProxyDom  //启动一个Domain的AdminServer"
  echo "domain.sh stop  ProxyDom  //停止一个Domain的AdminServer"
  echo "domain.sh startall        //启动所有Domain的AdminServer"
  echo "domain.sh stopall         //停止所有Domain的AdminServer"
  echo "AdminServer清单详见：${adminlist}"
  echo "Domain清单:"
  cat ${adminlist}|awk '{print $1}'
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
      checkdomain
      sshexecute $domainip $startscript
    elif [ "${action}" = "stop" ]
    then
      checkdomain
      sshexecute $domainip $stopscript
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

#函数：入参2-domain检测，并取得停启脚本路径
function checkdomain
{
  DEBUG echo "======开始checkdomain()======"
  if [ "$var2" = "" ]
  then
    echo "错误：请输入Domain名称，清单详见${adminlist}"
    exit 1
  else
    domainname="$var2"
    export domainname
    domainstr=`cat ${adminlist}|awk '{if($1==ENVIRON["domainname"]){print $1" "$2" "$3" "$4" "$5" "$6" "$7" "$8}}'`  #取得domainstr
    if [ "domainstr" = "" ]
    then
      echo "错误：Domain名称不正确，清单详见${adminlist}"
      help
      exit 1
    else
      domainip=`echo $domainstr|awk '{print $3}'`
      startscript=`echo $domainstr|awk '{print $7}'`
      stopscript=`echo $domainstr|awk '{print $8}'`
      DEBUG echo "domainip=${domainip}"
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
    DEBUG echo "======开始sshexecute():  ssh ${sship} '${sshscript}'======"
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
  for domainstr in $(sed '/^$/d' $adminlist)
  do
    DEBUG echo "domainstr=${nodestr}"
    domainip=`echo $domainstr|awk '{print $3}'`
    startscript=`echo $domainstr|awk '{print $7}'`
    stopscript=`echo $domainstr|awk '{print $8}'`
    DEBUG echo "domainip=${domainip}"
    DEBUG echo "startscript=${startscript}"
    DEBUG echo "stopscript=${stopscript}"

    if [ ${sshaction} == "start" ]
    then
      sshexecute $domainip $startscript
    elif [ ${sshaction} == "stop" ]
    then
      sshexecute $domainip $stopscript
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