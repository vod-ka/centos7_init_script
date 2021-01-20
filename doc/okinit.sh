#!/bin/bash
#centos7初始化脚本1.1.9
# @Author: Aliao  
# @Repository: https://github.com/vod-ka   
# @Date: 2021-01-18 23:30:08  
# @Last Modified by:   Aliao  
# @Last Modified time: 2021-01-20 16:18:11
#更新yum源(阿里云的源)
mv -f /etc/yum.repos.d/CentOS-Base.repo /etc/yum.repos.d/CentOS-Base.repo.backup
cd /etc/yum.repos.d/
curl -O http://mirrors.aliyun.com/repo/Centos-7.repo
mv -f Centos-7.repo CentOS-Base.repo
yum clean all
yum makecache
#yum更新软件
yum update -y
#安装网络对时
yum install -y ntp ntpdate
systemctl start ntpd
ntpdate ntp3.aliyun.com > /dev/null
systemctl enable ntpd > /dev/null
#安装EPEL源
yum install -y epel-release
yum clean all
yum makecache
#安装常用软件包
yum install -y wget curl vim screen zip unzip net-tools psmisc bash-completion iftop htop httpd vsftpd
#修改主机名
INFO=/root/info.txt
SNAME=$(sed -n '2p' $INFO)
hostnamectl set-hostname $SNAME
sed -i "1s/127.0.0.1   /127.0.0.1   $SNAME /g" /etc/hosts
hostname
echo -e "----------------------------------------\n设置主机名成功\n------------------------------------------"
#设置时区
timedatectl set-timezone Asia/Shanghai
echo -e "----------------------------------------\n设置时区为：中国上海\n-------------------------------------"
#关闭SElinux
sed -i '7s/enforcing/disabled/g' /etc/selinux/config
sed -n '7p' /etc/selinux/config
echo -e "-----------------------------------------\n关闭SElinux成功\n------------------------------------------"
#防火墙设置
systemctl start firewalld
firewall-cmd --zone=public --add-service=http --permanent > /dev/null
firewall-cmd --zone=public --add-service=https --permanent > /dev/null
firewall-cmd --zone=public --add-service=ftp --permanent > /dev/null
firewall-cmd --zone=public --add-port=20/tcp --permanent > /dev/null
firewall-cmd --zone=public --add-port=21/tcp --permanent > /dev/null
firewall-cmd --zone=public --add-port=80/tcp --permanent > /dev/null
firewall-cmd --zone=public --add-port=443/tcp --permanent > /dev/null
firewall-cmd --reload > /dev/null
firewall-cmd --list-all
echo -e "-----------------------------------------\n防火墙添加端口和服务成功\n----------------------------------"
systemctl enable firewalld > /dev/null
echo -e "-----------------------------------------\n设置防火墙开机自启动成功\n-----------------------------------"
#修改ssh密钥登陆
KLJ="/root/.ssh"
SLJ="/etc/ssh/sshd_config"
KEY="/root/key.zip"
mkdir $KLJ
cd /root
unzip $KEY > /dev/null
cp /root/key/* $KLJ
cat $KLJ/id_rsa.pub >> $KLJ/authorized_keys
chmod 600 $KLJ/authorized_keys
sed -i '43s/#Pubkey/Pubkey/g' $SLJ
sed -i '65s/yes/no/g' $SLJ
sed -n '43p;47p;65p' $SLJ
systemctl restart sshd
echo -e "--------------------------------\n设置ssh密钥验证登陆成功\n--------------------------------------"
#修改网卡ip
WKM=$(sed -n '3p' $INFO)
LJ=$(find /etc -name ifcfg-$WKM)
IPDZ=$(sed -n '4p' $INFO)
ZWYM=$(sed -n '5p' $INFO)
WGDZ=$(sed -n '6p' $INFO)
DNSDZ=$(sed -n '7p' $INFO)
#查找是否已经存在静态ip配置信息，如果存在则把它删掉
sed -i '/BOOTPROTO/s/dhcp/static/g' $LJ
sed -i '/ONBOOT/s/no/yes/g' $LJ
sed -i '/IPADDR/d' $LJ
sed -i '/NETMASK/d' $LJ
sed -i '/GATEWAY/d' $LJ
sed -i '/DNS1/d' $LJ
#写入静态ip配置信息
echo "IPADDR=$IPDZ" >> $LJ
echo "NETMASK=$ZWYM" >> $LJ
echo "GATEWAY=$WGDZ" >> $LJ
echo "DNS1=$DNSDZ" >> $LJ
#检验配置结果
cat $LJ
echo -e "-------------------------------\n配置网卡信息成功\n----------------------------------------------"
#重启网卡
systemctl restart network
#删除垃圾文件
rm -rf /root/key*
rm -rf $INFO
#重启服务器
reboot