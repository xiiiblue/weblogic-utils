#!/bin/sh
# Program:
#   Զ��ͣ��ָ��������AdminServer
#   ��������SSH�����ػ���ִ�� ssh-keygen -t rsa����pubkey����ӵ��ܿ�������~/.ssh/authorized_keys��Ȩ
#   adminlist����ʾ����
#     ������       AdminServer����   IP             �˿� Console�û�  ����       �����ű�
#     ProxyDom     AdminServer       132.77.138.155 6001 weblogic     web123321  /ngbss1/webapp/domains/ProxyDom/start.sh     /ngbss1/webapp/domains/ProxyDom/stop.sh   
#     AcctManmDom  AdminServer       132.77.138.155 6401 weblogic     web123321  /ngbss1/webapp/domains/AcctManmDom/start.sh  /ngbss1/webapp/domains/AcctManmDom/stop.sh
#     CustServDom  AdminServer       132.77.138.155 6501 weblogic     web123321  /ngbss1/webapp/domains/CustServDom/start.sh  /ngbss1/webapp/domains/CustServDom/stop.sh
#   ʹ��domain.sh help��ȡ����
# History:
#   2012/01/14  BlueXIII  ����

#���ó�ʼ����
basedir=$(cd "$(dirname "$0")"; pwd)
adminlist="${basedir}/adminservers.lst"
DEBUG=false
TEST=false

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
  echo "���ܣ�Զ��ͣ��ָ��������AdminServer"
  echo "�÷���"
  echo "domain.sh start ProxyDom  //����һ��Domain��AdminServer"
  echo "domain.sh stop  ProxyDom  //ֹͣһ��Domain��AdminServer"
  echo "domain.sh startall        //��������Domain��AdminServer"
  echo "domain.sh stopall         //ֹͣ����Domain��AdminServer"
  echo "AdminServer�嵥�����${adminlist}"
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

#���������1-action��⣬��ִ����ͣ�ű�
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
      echo "������������ȷ�Ķ������ƣ�"
      help
      exit 1
    fi
  fi
}

#���������2-domain��⣬��ȡ��ͣ���ű�·��
function checkdomain
{
  DEBUG echo "======��ʼcheckdomain()======"
  if [ "$var2" = "" ]
  then
    echo "����������Domain���ƣ��嵥���${adminlist}"
    exit 1
  else
    domainname="$var2"
    export domainname
    domainstr=`cat ${adminlist}|awk '{if($1==ENVIRON["domainname"]){print $1" "$2" "$3" "$4" "$5" "$6" "$7" "$8}}'`  #ȡ��domainstr
    if [ "domainstr" = "" ]
    then
      echo "����Domain���Ʋ���ȷ���嵥���${adminlist}"
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


#������ִ��Զ��ֹͣ�ű�
function sshexecute
{
  DEBUG echo "======��ʼsshexecute()======"
  sship=$1
  sshscript=$2
  DEBUG echo "sship=${sship}"
  DEBUG echo "sshscript=${sshscript}"
  echo "Executing ${sship}:${sshscript} ..."
  if [ "$TEST" != "true" ]
  then
    DEBUG echo "======��ʼsshexecute():  ssh ${sship} '${sshscript}'======"
    ssh ${sship} "${sshscript}"
  else
    echo "����ģʽ����ʵ��ִ�нű�"
  fi
}

#����������ִ��Զ��ֹͣ�ű�
function sshexcuteall
{
  DEBUG echo "======��ʼsshexcuteall()======"
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
      echo "����δ֪�쳣"
      exit 1
    fi
  done
  IFS=$IFS_old
}


#��ʼִ��
varnum="$#"
var1="$1"
var2="$2"
DEBUG echo "��θ���="$varnum
DEBUG echo "���1="$var1
DEBUG echo "���2="$var2
checkvarnum
checkaction
echo "Done"
exit 0