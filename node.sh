#!/bin/sh
# Program:
#   Զ��ͣ��ָ��������nodemanager
#   ��������SSH�����ػ���ִ�� ssh-keygen -t rsa����pubkey����ӵ��ܿ�������~/.ssh/authorized_keys��Ȩ
#   nodelist����ʾ����
#     ����           �˿�  �����ű�                    ֹͣ�ű�
#     132.77.138.143 5566  /ngbss/webapp/startnode.sh  /ngbss/webapp/stopnode.sh
#     132.77.138.144 5566  /ngbss/webapp/startnode.sh  /ngbss/webapp/stopnode.sh
#     132.77.138.145 5566  /ngbss/webapp/startnode.sh  /ngbss/webapp/stopnode.sh
#   ʹ��node.sh help��ȡ����
# History:
#   2012/01/14  BlueXIII  ����


#���ó�ʼ����
basedir=$(cd "$(dirname "$0")"; pwd)
nodelist="${basedir}/nodemanagers.lst"
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
  echo "���ܣ�Զ��ͣ��ָ��������nodemanager"
  echo "�÷���"
  echo "node.sh start 132.77.138.143  //����һ��nodemanager"
  echo "node.sh stop  132.77.138.143  //ֹͣһ��nodemanager"
  echo "node.sh startall              //��������nodemanager"
  echo "node.sh stopall               //ֹͣ����nodemanager"
  echo "nodemanager�嵥�����${nodelist}"
  echo "�����嵥:"
  cat ${nodelist}|awk '{print $1}'
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
      echo "������������ȷ�Ķ������ƣ�"
      help
      exit 1
    fi
  fi
}

#���������2-nodeip��⣬��ȡ��ͣ���ű�·��
function checknodeip
{
  DEBUG echo "======��ʼcheckservername()======"
  if [ "$var2" = "" ]
  then
    echo "����������IP���嵥���${nodelist}"
    exit 1
  else
    nodeip="$var2"
    export nodeip
    nodestr=`cat ${nodelist}|awk '{if($1==ENVIRON["nodeip"]){print $1" "$2" "$3" "$4}}'`  #ȡ��nodestr
    if [ "nodestr" = "" ]
    then
      echo "����IP����ȷ���嵥���${nodelist}"
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