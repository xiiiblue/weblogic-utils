#!/bin/sh
# Program:
#   wlst脚本方式远程启停被管server
#   adminlist配置示例：
#     域名称       AdminServer名   ServerIP       端口  Console用户  Console密码
#     ProxyDom     AdminServer     132.77.138.155 6001  weblogic     web123321
#     AcctManmDom  AdminServer     132.77.138.155 6401  weblogic     web123321
#   managedlist配置示例：
#     域名称      被管Server名   被管ServerIP    端口
#     ProxyDom    proxy_t_11     132.77.138.143  8001
#     ProxyDom    proxy_t_12     132.77.138.143  8002
#   使用server.sh help获取帮助
#   需先使用storeUserConfig('./secure/6001conf.secure', './secure/6001key.secure')生成key
# History:
#   2012/01/13  BlueXIII  创建
#   2012/01/14  BlueXIII  使用key替代明文密码

#设置初始变量
basedir=$(cd "$(dirname "$0")"; pwd)
managedlist="${basedir}/managedservers.lst"
adminlist="${basedir}/adminservers.lst"
DEBUG=false
TEST=false

#导入环境变量
. /bea/weblogic/wlserver_10.3/server/bin/setWLSEnv.sh>/dev/null
PATH=$PATH:$WL_HOME/server/bin:$WL_HOME/common/bin

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
  echo "功能：wlst脚本方式远程启停被管server"
  echo "用法："
  echo "server.sh start proxy_t_13   //启动一个被管server"
  echo "server.sh stop  proxy_t_13   //停止一个被管server"
  echo "server.sh startdom ProxyDom  //启动一个domain的所有被管server"
  echo "server.sh stopdom  ProxyDom  //停止一个domain的所有被管server"
  echo "server.sh startall           //启动所有domian的所有被管server"
  echo "server.sh stopall            //停止所有domian的所有被管server"
  echo "被管Server清单详见：${managedlist}"
  echo "Domain清单详见：${adminlist}"
  echo "Server清单:"
  cat ${managedlist}|awk '{print $2"    "$1}'
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

#函数：入参1-action检测
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
    pyname="server_${action}" #拼Jython脚本文件名
    DEBUG echo "action=${action}"
    DEBUG echo "pyname=${pyname}"

    if [ "${action}" = "help" ]
    then
      help
      exit 0
    elif [ "${action}" = "start" ]
    then
      checkservername
    elif [ "${action}" = "stop" ]
    then
      checkservername
    elif [ "${action}" = "startdom" ]
    then
      checkdomainname
    elif [ "${action}" = "stopdom" ]
    then
      checkdomainname
    elif [ "${action}" = "startall" ]
    then
      DEBUG
    elif [ "${action}" = "stopall" ]
    then
      DEBUG
    else
      echo "错误：请输入正确的动作名称！"
      help
      exit 1
    fi
    pyname="${pyname}.py"  #拼Jython脚本文件名
    echo "pyname=${pyname}"
  fi
}

#函数：入参2-servername检测，并取得serverstr&domainstr
function checkservername
{
  DEBUG echo "======开始checkservername()======"
  if [ "$var2" = "" ]
  then
    echo "错误：请输入server名称，清单详见${managedlist}"
    exit 1
  else
    servername="$var2"
    pyname="${pyname}_${servername}"  #拼Jython脚本文件名
    export servername
    serverstr=`cat ${managedlist}|awk '{if($2==ENVIRON["servername"]){print $1" "$2" "$3" "$4}}'`  #取得serverstr
    if [ "$serverstr" = "" ]
    then
      echo "错误：server名称不正确，清单详见${managedlist}"
      help
      exit 1
    else
      domainname=`echo $serverstr|awk '{print $1}'`
      export domainname
      domainstr=`cat ${adminlist}|awk '{if($1==ENVIRON["domainname"]){print $1" "$2" "$3" "$4" "$5" "$6}}'`  #取得domainstr
      if [ "$domainstr" = "" ]
      then
        echo "错误：domain名称获取不到，有可能${managedlist}或${adminlist}设置错误！"
        help
        exit 1
      fi
    fi
  fi
}

#函数：入参2-domainname检测，并取得domainstr
function checkdomainname
{
  DEBUG echo "======开始checkdomainname()======"
  if [ "$var2" = "" ]
  then
    echo "错误：请输入domain名称，清单详见${adminlist}"
    exit 1
  else
    domainname="$var2"
    export domainname
    domainstr=`cat ${adminlist}|awk '{if($1==ENVIRON["domainname"]){print $1" "$2" "$3" "$4" "$5" "$6}}'`  #取得domainstr
    if [ "$domainstr" = "" ]
    then
      echo "错误：domain名称不正确，清单详见${managedlist}"
      help
      exit 1
    fi
    pyname="${pyname}_${domainname}"  #拼Jython脚本文件名
  fi
}

function genjython
{
  DEBUG echo "======开始genjython()======"
  domainip=`echo $domainstr|awk '{print $3}'`
  domainport=`echo $domainstr|awk '{print $4}'`
  userID=`echo $domainstr|awk '{print $5}'`;userID="username='${userID}',"
  password=`echo $domainstr|awk '{print $6}'`;password="password='${password}',"
  ADMIN_URL="t3://${domainip}:${domainport}"
  
  DEBUG echo "domainname=${domainname}"
  DEBUG echo "domainstr=${domainstr}"
  DEBUG echo "domainip=${domainip}"
  DEBUG echo "domainport=${domainport}"
  DEBUG echo "userID=${userID}"
  DEBUG echo "password=${password}"
  DEBUG echo "ADMIN_URL=${ADMIN_URL}"
  if [ "${action}" = "start" ]
  then
    DEBUG echo "======开始genjython():start======"
    #echo "connect(${userID} ${password} url='${ADMIN_URL}')" >"${pyname}"  #生成Jython
    echo "connect(userConfigFile='./secure/${domainport}conf.secure', userKeyFile='./secure/${domainport}key.secure',url='${ADMIN_URL}')" >"${pyname}"  #生成Jython(使用key登录)
    echo "start('${servername}','Server', block='false')" >>"${pyname}"  #生成Jython
    echo "exit()" >>"${pyname}"  #生成Jython
  elif [ "${action}" = "stop" ]
  then
    DEBUG echo "======开始genjython():stop======"
    #echo "connect(${userID} ${password} url='${ADMIN_URL}')" >"${pyname}"  #生成Jython
    echo "connect(userConfigFile='./secure/${domainport}conf.secure', userKeyFile='./secure/${domainport}key.secure',url='${ADMIN_URL}')" >"${pyname}"  #生成Jython(使用key登录)
    echo "shutdown('${servername}','Server', 'true', 1000, 'true' block='false')" >>"${pyname}"  #生成Jython
    echo "exit()" >>"${pyname}"  #生成Jython
  elif [ "${action}" = "startdom" ]
  then
    DEBUG echo "======开始genjython():startdom======"
    IFS_old=$IFS
    IFS=$'\n'
    export domainname
    #echo "connect(${userID} ${password} url='${ADMIN_URL}')" >"${pyname}"  #生成Jython
    echo "connect(userConfigFile='./secure/${domainport}conf.secure', userKeyFile='./secure/${domainport}key.secure',url='${ADMIN_URL}')" >"${pyname}"  #生成Jython(使用key登录)
    for serverstr in `cat ${managedlist}|awk '{if($1==ENVIRON["domainname"]){print $1" "$2" "$3" "$4" "$5" "$6}}'`
    do
      DEBUG echo "serverstr=${serverstr}"
      servername=`echo $serverstr|awk '{print $2}'`
      echo "start('${servername}','Server', block='false')" >>"${pyname}"  #生成Jython
    done
    echo "exit()" >>"${pyname}"   #生成Jython
    IFS=$IFS_old
  elif [ "${action}" = "stopdom" ]
  then
    DEBUG echo "======开始genjython():stopdom======"
    IFS_old=$IFS
    IFS=$'\n'
    export domainname
    #echo "connect(${userID} ${password} url='${ADMIN_URL}')" >"${pyname}"  #生成Jython
    echo "connect(userConfigFile='./secure/${domainport}conf.secure', userKeyFile='./secure/${domainport}key.secure',url='${ADMIN_URL}')" >"${pyname}"  #生成Jython(使用key登录)
    for serverstr in `cat ${managedlist}|awk '{if($1==ENVIRON["domainname"]){print $1" "$2" "$3" "$4" "$5" "$6}}'`
    do
      DEBUG echo "serverstr=${serverstr}"
      servername=`echo $serverstr|awk '{print $2}'`
        echo "shutdown('${servername}','Server', 'true', 1000, 'true' block='false')" >>"${pyname}"  #生成Jython
    done
    echo "exit()" >>"${pyname}"  #生成Jython
    IFS=$IFS_old
  elif [ "${action}" = "startall" ]
  then
    DEBUG echo "======开始genjython():startall======"
    IFS_old=$IFS
    IFS=$'\n'
    >"${pyname}"
    for domainstr in $(sed '/^$/d' ${adminlist})  #取得domainstr
    do
      DEBUG echo "domainstr=${domainstr}"
      domainname=`echo $domainstr|awk '{print $1}'`
      domainip=`echo $domainstr|awk '{print $3}'`
      domainport=`echo $domainstr|awk '{print $4}'`
      userID=`echo $domainstr|awk '{print $5}'`;userID="username='${userID}',"
      password=`echo $domainstr|awk '{print $6}'`;password="password='${password}',"
      ADMIN_URL="t3://${domainip}:${domainport}"
      #echo "connect(${userID} ${password} url='${ADMIN_URL}')" >>"${pyname}"  #生成Jython
      echo "connect(userConfigFile='./secure/${domainport}conf.secure', userKeyFile='./secure/${domainport}key.secure',url='${ADMIN_URL}')">>"${pyname}"  #生成Jython(使用key登录)
      export domainname
      for serverstr in `cat ${managedlist}|awk '{if($1==ENVIRON["domainname"]){print $1" "$2" "$3" "$4" "$5" "$6}}'`
      do
        DEBUG echo "serverstr=${serverstr}"
        servername=`echo $serverstr|awk '{print $2}'`
          echo "start('${servername}','Server', block='false')" >>"${pyname}"  #生成Jython
      done
      echo "exit()" >>"${pyname}"  #生成Jython
    done
    IFS=$IFS_old
  elif [ "${action}" = "stopall" ]
  then
    DEBUG echo "======开始genjython():stopall======"
    IFS_old=$IFS
    IFS=$'\n'
    >"${pyname}"
    for domainstr in $(sed '/^$/d' ${adminlist})  #取得domainstr
    do
      DEBUG echo "domainstr=${domainstr}"
      domainname=`echo $domainstr|awk '{print $1}'`
      domainip=`echo $domainstr|awk '{print $3}'`
      domainport=`echo $domainstr|awk '{print $4}'`
      userID=`echo $domainstr|awk '{print $5}'`;userID="username='${userID}',"
      password=`echo $domainstr|awk '{print $6}'`;password="password='${password}',"
      ADMIN_URL="t3://${domainip}:${domainport}"
      #echo "connect(${userID} ${password} url='${ADMIN_URL}')" >>"${pyname}"  #生成Jython
      echo "connect(userConfigFile='./secure/${domainport}conf.secure', userKeyFile='./secure/${domainport}key.secure',url='${ADMIN_URL}')">>"${pyname}"  #生成Jython(使用key登录)
      export domainname
      for serverstr in `cat ${managedlist}|awk '{if($1==ENVIRON["domainname"]){print $1" "$2" "$3" "$4" "$5" "$6}}'`
      do
        DEBUG echo "serverstr=${serverstr}"
        servername=`echo $serverstr|awk '{print $2}'`
          echo "shutdown('${servername}','Server', 'true', 1000, 'true' block='false')" >>"${pyname}"  #生成Jython
      done
      echo "exit()" >>"${pyname}"  #生成Jython
    done
    IFS=$IFS_old
  else
    echo "错误：请输入正确的动作名称！"
    help
    exit 1
  fi
}


#开始入参检测
varnum="$#"
var1="$1"
var2="$2"
DEBUG echo "入参个数="$varnum
DEBUG echo "入参1="$var1
DEBUG echo "入参2="$var2
checkvarnum
checkaction

#生成Jython脚本
genjython

#执行Jython脚本
if [ "$TEST" != "true" ]
then
  ${JAVA_HOME}/bin/java ${JAVA_OPTIONS} weblogic.WLST ${pyname}  2>&1 
  rm -rf ${pyname}
else
  echo "测试模式，不实际执行脚本"
fi

echo "Done"
exit 0