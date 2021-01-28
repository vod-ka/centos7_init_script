#!/bin/bash
# @Author: Aliao  
# @Repository: https://github.com/vod-ka   
# @Date: 2021-01-24 12:02:43  
# @Last Modified by:   Aliao  
# @Last Modified time: 2021-01-24 12:02:43  

info="$HOME/info.txt"
sname=$(sed -n '2p' "$info")
klj="$HOME/.ssh"
slj="/etc/ssh/sshd_config"
skey="$HOME/key.zip"
wkm=$(sed -n '3p' "$info")
lj=$(find /etc -name "ifcfg-$wkm")
ipdz=$(sed -n '4p' "$info")
zwym=$(sed -n '5p' "$info")
wgdz=$(sed -n '6p' "$info")
dnsdz=$(sed -n '7p' "$info")

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

#更新yum源
SourceUpdate(){
    mv -f /etc/yum.repos.d/CentOS-Base.repo /etc/yum.repos.d/CentOS-Base.repo.backup
    cd /etc/yum.repos.d/ || exit 0
    curl -O http://mirrors.aliyun.com/repo/Centos-7.repo
    mv -f Centos-7.repo CentOS-Base.repo
    yum clean all
    yum makecache
}

#yum更新
YumUpdate(){
    yum update -y
}

#安装网络对时
NetworkTime(){
    yum install -y ntp ntpdate
    systemctl start ntpd
    systemctl enable ntpd > /dev/null
    ntpdate ntp3.aliyun.com > /dev/null
}

#设置时区
TimeZone(){
    timedatectl set-timezone Asia/Shanghai
}

#安装EPEL源
EPEL(){
    yum install -y epel-release
    yum clean all
    yum makecache
}

#安装常用软件包
InstallApp(){
    yum install -y wget curl vim screen zip unzip net-tools psmisc bash-completion iftop htop
}

#修改主机名
Rename(){
    hostnamectl set-hostname "$sname"
    sed -i "1s/127.0.0.1   /127.0.0.1   $sname /g" /etc/hosts
    hostname
    Green "----------------------------------------设置主机名成功"
}

#关闭SElinux
StopSElinux(){
    sed -i '7s/enforcing/disabled/g' /etc/selinux/config
    sed -n '7p' /etc/selinux/config
    Green "----------------------------------------关闭SElinux成功"
}

#设置防火墙
Firewall(){
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
}

#修改ssh密钥登陆
SSH(){
    mkdir "$klj"
    unzip "$skey" -d  "$klj"
    cat "$klj/id_rsa.pub" >> "$klj/authorized_keys"
    chmod 600 "$klj/authorized_keys"
    sed -i '43s/#Pubkey/Pubkey/g' $slj
    sed -i '65s/yes/no/g' $slj
    sed -n '43p;47p;65p' $slj
    systemctl restart sshd
    Green "---------------------------------------设置ssh密钥验证登陆成功"
}

#修改网卡ip
Ipconfig(){
    #查找是否已经存在静态ip配置信息，如果存在则把它删掉
    sed -i '/BOOTPROTO/s/dhcp/static/g' "$lj"
    sed -i '/ONBOOT/s/no/yes/g' "$lj" 
    sed -i '/IPADDR/d' "$lj"
    sed -i '/NETMASK/d' "$lj"
    sed -i '/GATEWAY/d' "$lj"
    sed -i '/DNS1/d' "$lj"
    #写入静态ip配置信息
    echo -e "IPADDR=$ipdz\nNETMASK=$zwym\nGATEWAY=$wgdz\nDNS1=$dnsdz" >> "$lj"
    #检验配置结果
    cat "$lj"
    Green "--------------------------------------配置网卡信息成功"
    #重启网卡
    systemctl restart network
}

#安装Git
GitInstall(){
    #卸载旧版
    yum remove github
    #编译安装
    yum install -y wget gcc gcc-c++ zlib-devel perl-ExtUtils-MakeMaker asciidoc xmlto openssl-devel
    wget https://mirrors.edge.kernel.org/pub/software/scm/git/git-2.29.2.tar.xz
    tar -xvJf git-2.29.2.tar.xz
    cd "$HOME/git-2.29.2" || exit 0
    ./configure --prefix=/usr/local/git
    make && make install
    echo "export PATH=$PATH:/usr/local/git/bin" >> /etc/bashrc
    source /etc/bashrc
    git --version
}

#清楚垃圾
Rm-all(){
    rm -rf "$HOME/key*"
    rm -rf "$info"
    find / -name onekey.sh -exec rm -rf {} \;
    rm -rf "$HOME/git*"
}

#main
SourceUpdate
YumUpdate
TimeZone
EPEL
NetworkTime
InstallApp
StopSElinux
Firewall
Rename
SSH
Ipconfig
GitInstall
Rm-all
#重启计算机
reboot
