#!/bin/sh
# Program:
#   wlst�ű���ʽ��ر���server״̬
#   adminlist����ʾ����
#     ������       AdminServer��   ServerIP       �˿�  Console�û�  Console����
#     ProxyDom     AdminServer     132.77.138.155 6001  weblogic     web123321
#     AcctManmDom  AdminServer     132.77.138.155 6401  weblogic     web123321
#   managedlist����ʾ����
#     ������      ����Server��   ����ServerIP    �˿�
#     ProxyDom    proxy_t_11     132.77.138.143  8001
#     ProxyDom    proxy_t_12     132.77.138.143  8002
#   ʹ��state.sh help��ȡ����
#   ����ʹ��storeUserConfig('./secure/6001conf.secure', './secure/6001key.secure')����key
# History:
#   2012/01/13  BlueXIII  ����
#   2012/01/14  BlueXIII  ʹ��key�����������

#���ó�ʼ����
basedir=$(cd "$(dirname "$0")"; pwd)
managedlist="${basedir}/managedservers.lst"
adminlist="${basedir}/adminservers.lst"
DEBUG=false
TEST=false

#���뻷������
. /bea/weblogic/wlserver_10.3/server/bin/setWLSEnv.sh>/dev/null
PATH=$PATH:$WL_HOME/server/bin:$WL_HOME/common/bin

#DEBUG����
DEBUG()
{
  if [ "$DEBUG" = "true" ]
  then
    $@
  fi
}

#��������ӡ������Ϣ
function help
{
  DEBUG echo "======��ʼhelp()======"
  echo "���ܣ�wlst�ű���ʽ��ر���server״̬"
  echo "�÷���"
  echo "state.sh server proxy_t_13   //�鿴һ������server"
  echo "state.sh domain ProxyDom     //�鿴һ��domain�����б���server"
  echo "state.sh all                 //�鿴����domian�����б���server"
  echo "����Server�嵥�����${managedlist}"
  echo "Domain�嵥�����${adminlist}"
  echo "Domain�嵥:"
  cat ${adminlist}|awk '{print $1}'
}

#��������θ������
function checkvarnum
{
  DEBUG echo "======��ʼcheckvarnum()======"
  if [ $varnum -eq 0 -o $varnum -gt 2 ]
  then
    echo "������θ�������ȷ��"
    help
    exit 1
  fi
}

#���������1-action���
function checkaction
{
  DEBUG echo "======��ʼcheckaction()======"
  if [ "${var1}" = "" ]
  then
    echo "���������붯�����ƣ�"
    help
    exit 1
  else
    action="$var1"
    pyname="state_${action}" #ƴJython�ű��ļ���
    DEBUG echo "action=${action}"
    DEBUG echo "pyname=${pyname}"

    if [ "${action}" = "help" ]
    then
      help
      exit 0
    elif [ "${action}" = "server" ]
    then
      checkservername
    elif [ "${action}" = "domain" ]
    then
      checkdomainname
    elif [ "${action}" = "all" ]
    then
      DEBUG
    else
      echo "������������ȷ�Ķ������ƣ�"
      help
      exit 1
    fi
    pyname="${pyname}.py"  #ƴJython�ű��ļ���
    DEBUG echo "pyname=${pyname}"
  fi
}

#���������2-servername��⣬��ȡ��serverstr&domainstr
function checkservername
{
  DEBUG echo "======��ʼcheckservername()======"
  if [ "$var2" = "" ]
  then
    echo "����������server���ƣ��嵥���${managedlist}"
    exit 1
  else
    servername="$var2"
    pyname="${pyname}_${servername}"  #ƴJython�ű��ļ���
    export servername
    serverstr=`cat ${managedlist}|awk '{if($2==ENVIRON["servername"]){print $1" "$2" "$3" "$4}}'`  #ȡ��serverstr
    if [ "$serverstr" = "" ]
    then
      echo "����server���Ʋ���ȷ���嵥���${managedlist}"
      help
      exit 1
    else
      domainname=`echo $serverstr|awk '{print $1}'`
      export domainname
      domainstr=`cat ${adminlist}|awk '{if($1==ENVIRON["domainname"]){print $1" "$2" "$3" "$4" "$5" "$6}}'`  #ȡ��domainstr
      if [ "$domainstr" = "" ]
      then
        echo "����domain���ƻ�ȡ�������п���${managedlist}��${adminlist}���ô���"
        help
        exit 1
      fi
    fi
  fi
}

#���������2-domainname��⣬��ȡ��domainstr
function checkdomainname
{
  DEBUG echo "======��ʼcheckdomainname()======"
  if [ "$var2" = "" ]
  then
    echo "����������domain���ƣ��嵥���${adminlist}"
    exit 1
  else
    domainname="$var2"
    export domainname
    domainstr=`cat ${adminlist}|awk '{if($1==ENVIRON["domainname"]){print $1" "$2" "$3" "$4" "$5" "$6}}'`  #ȡ��domainstr
    if [ "$domainstr" = "" ]
    then
      echo "����domain���Ʋ���ȷ���嵥���${managedlist}"
      help
      exit 1
    fi
    pyname="${pyname}_${domainname}"  #ƴJython�ű��ļ���
  fi
}

function genjython
{
  DEBUG echo "======��ʼgenjython()======"
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
  if [ "${action}" = "server" ]
  then
    DEBUG echo "======��ʼgenjython():server======"
    #echo "connect(${userID} ${password} url='${ADMIN_URL}')" >"${pyname}"  #����Jython
    echo "connect(userConfigFile='./secure/${domainport}conf.secure', userKeyFile='./secure/${domainport}key.secure',url='${ADMIN_URL}')" >"${pyname}"  #����Jython(ʹ��key��¼)
    echo "state('${servername}','Server')" >>"${pyname}"  #����Jython
    echo "exit()" >>"${pyname}"  #����Jython
  elif [ "${action}" = "domain" ]
  then
    DEBUG echo "======��ʼgenjython():domain======"
    IFS_old=$IFS
    IFS=$'\n'
    export domainname
    #echo "connect(${userID} ${password} url='${ADMIN_URL}')" >"${pyname}"  #����Jython
    echo "connect(userConfigFile='./secure/${domainport}conf.secure', userKeyFile='./secure/${domainport}key.secure',url='${ADMIN_URL}')" >"${pyname}"  #����Jython(ʹ��key��¼)
    for serverstr in `cat ${managedlist}|awk '{if($1==ENVIRON["domainname"]){print $1" "$2" "$3" "$4" "$5" "$6}}'`
    do
      DEBUG echo "serverstr=${serverstr}"
      servername=`echo $serverstr|awk '{print $2}'`
      echo "state('${servername}','Server')" >>"${pyname}"  #����Jython
    done
    echo "exit()" >>"${pyname}"   #����Jython
    IFS=$IFS_old
  elif [ "${action}" = "all" ]
  then
    DEBUG echo "======��ʼgenjython():all======"
    IFS_old=$IFS
    IFS=$'\n'
    >"${pyname}"
    for domainstr in $(sed '/^$/d' ${adminlist})  #ȡ��domainstr
    do
      DEBUG echo "domainstr=${domainstr}"
      domainname=`echo $domainstr|awk '{print $1}'`
      domainip=`echo $domainstr|awk '{print $3}'`
      domainport=`echo $domainstr|awk '{print $4}'`
      userID=`echo $domainstr|awk '{print $5}'`;userID="username='${userID}',"
      password=`echo $domainstr|awk '{print $6}'`;password="password='${password}',"
      ADMIN_URL="t3://${domainip}:${domainport}"
      #echo "connect(${userID} ${password} url='${ADMIN_URL}')" >>"${pyname}"  #����Jython
      echo "connect(userConfigFile='./secure/${domainport}conf.secure', userKeyFile='./secure/${domainport}key.secure',url='${ADMIN_URL}')">>"${pyname}"  #����Jython(ʹ��key��¼)
      export domainname
      for serverstr in `cat ${managedlist}|awk '{if($1==ENVIRON["domainname"]){print $1" "$2" "$3" "$4" "$5" "$6}}'`
      do
        DEBUG echo "serverstr=${serverstr}"
        servername=`echo $serverstr|awk '{print $2}'`
          echo "state('${servername}','Server')" >>"${pyname}"  #����Jython
      done
      echo "disconnect()" >>"${pyname}"  #����Jython
    done
    echo "exit()" >>"${pyname}"  #����Jython
    IFS=$IFS_old
    else
    echo "������������ȷ�Ķ������ƣ�"
    help
    exit 1
  fi
}

#��ʼ��μ��
varnum="$#"
var1="$1"
var2="$2"
DEBUG echo "��θ���="$varnum
DEBUG echo "���1="$var1
DEBUG echo "���2="$var2
checkvarnum
checkaction

#����Jython�ű�
genjython

#ִ��Jython�ű�
if [ "$TEST" != "true" ]
then
  ${JAVA_HOME}/bin/java ${JAVA_OPTIONS} weblogic.WLST ${pyname}|grep "Current state"   2>&1 
  rm -rf ${pyname}
else
  echo "����ģʽ����ʵ��ִ�нű�"
fi

echo "Done"
exit 0