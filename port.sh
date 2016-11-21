#!/bin/sh
# Program:
#   ���Զ˿��Ƿ񿪷�
#   ʹ��test.sh help��ȡ����
# History:
#   2012/01/13  BlueXIII  ����

#���ó�ʼ����
basedir=$(cd "$(dirname "$0")"; pwd)
managedlist="${basedir}/managedservers.lst"
adminlist="${basedir}/adminservers.lst"
nodelist="${basedir}/nodemanagers.lst"
DEBUG=false

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
  echo "���ܣ��˿ڲ���"
  echo "�÷���"
  echo "port.sh node     //����nodemanager�˿�"
  echo "port.sh admin    //����nodemanager�˿�"
  echo "port.sh server   //����nodemanager�˿�"
}

#��ʼִ��
var1=$1
IFS_old=$IFS
IFS=$'\n'
if [ "$var1" = "" ]
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









