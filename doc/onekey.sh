#!/bin/bash
# @Author: Aliao  
# @Repository: https://github.com/vod-ka   
# @Date: 2021-01-24 12:02:43  
# @Last Modified by:   Aliao  
# @Last Modified time: 2021-01-24 12:02:43  

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
    #cd /etc/yum.repos.d/ || exit 0
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
