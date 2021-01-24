#!/bin/bash
#centos7初始化脚本 v1.2.2
# @Author: Aliao  
# @Repository: https://github.com/vod-ka   
# @Date: 2021-01-18 23:30:08  
# @Last Modified by:   Aliao  
# @Last Modified time: 2021-01-20 16:18:11

#颜色
Green(){
    echo -e "\033[32;01m$1\033[0m"
}

Red(){
    echo -e "\033[31;01m$1\033[0m"
}

Blue(){
    echo -e "\033[34;01m$1\033[0m"
}

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
sname=$(sed -n '2p' $INFO)
hostnamectl set-hostname $sname
sed -i "1s/127.0.0.1   /127.0.0.1   $sname /g" /etc/hosts
hostname
Green "----------------------------------------设置主机名成功"
#设置时区
timedatectl set-timezone Asia/Shanghai
Green "----------------------------------------设置时区为：中国上海"
#关闭SElinux
sed -i '7s/enforcing/disabled/g' /etc/selinux/config
sed -n '7p' /etc/selinux/config
Green "----------------------------------------关闭SElinux成功"
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
Green "---------------------------------------防火墙添加端口和服务成功"
systemctl enable firewalld > /dev/null
Green "---------------------------------------设置防火墙开机自启动成功"
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
Green "---------------------------------------设置ssh密钥验证登陆成功"
#修改网卡ip
wkm=$(sed -n '3p' $INFO)
lj=$(find /etc -name ifcfg-$wkm)
IPDZ=$(sed -n '4p' $INFO)
ZWYM=$(sed -n '5p' $INFO)
WGDZ=$(sed -n '6p' $INFO)
DNSDZ=$(sed -n '7p' $INFO)
#查找是否已经存在静态ip配置信息，如果存在则把它删掉
sed -i '/BOOTPROTO/s/dhcp/static/g' $lj
sed -i '/ONBOOT/s/no/yes/g' $lj
sed -i '/IPADDR/d' $lj
sed -i '/NETMASK/d' $lj
sed -i '/GATEWAY/d' $lj
sed -i '/DNS1/d' $lj
#写入静态ip配置信息
echo "IPADDR=$IPDZ" >> $lj
echo "NETMASK=$ZWYM" >> $lj
echo "GATEWAY=$WGDZ" >> $lj
echo "DNS1=$DNSDZ" >> $lj
#检验配置结果
cat $lj
Green "--------------------------------------配置网卡信息成功"
#重启网卡
systemctl restart network
#删除垃圾文件
rm -rf /root/key*
rm -rf $INFO
#重启服务器
reboot