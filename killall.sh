#!/bin/sh
# Program:
# Զ������nodemanagers.lst��ָ��������webapp�û�����java����
# ��������SSH�����ػ���ִ�� ssh-keygen -t rsa����pubkey����ӵ��ܿ�������~/.ssh/authorized_keys��Ȩ
# History:
# 2012/01/12  BlueXIII  ����

echo -n "Σ�գ�ȷ��Ҫɱ������������webapp�û��Ľ�����(��ȷ����������\"yes\")"
read yesorno
if [ $yesorno = "yes" ]
then
  echo -n "���ٴ�ȷ��!(��ȷ����������\"yes\")"
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