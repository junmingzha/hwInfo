#!/bin/bash
#Linux Server Hardware Configuration Collector
#Created by xinchen.luan
#Date:08/04/2020
if [ $UID != 0 ]; then
    echo "Error: You must be root to run this script!"
    exit 1
fi

GREEN='\033[0;32m'
RED='\033[0;31m'
PLAIN='\033[0m'

chk_lspci(){
    lspci=`whereis lspci | awk -F ":" '{print $2}'`
    if [ ${#lspci} -eq 0 ];then
        install_lspci
    else
        echo -e "${GREEN} [OK] lspci is ready.${PLAIN}"
    fi
}

    
chk_dmi(){
    dmi=`whereis dmidecode | awk -F ":" '{print $2}'`
    if [ ${#dmi} -eq 0 ];then
        install_dmi
    else
        echo -e "${GREEN} [OK] dmidecode is ready.${PLAIN}"
    fi
}

install_lspci(){
    yum install pciutils -y
    if [ $? -eq 0 ];then
        echo -e "${GREEN} [OK] lspci is ready.${PLAIN}"
    else
        echo -e "${RED} [FAILED] lspci installation failed, please install manually.${PLAIN}"
        exit 1
    fi
}

install_dmi(){
    yum install pciutils -y
    if [ $? -eq 0 ];then
        echo -e "${GREEN} [OK] dmidecode is ready.${PLAIN}"
    else
        echo -e "${RED} [FAILED] dmidecode installation failed, please install manually.${PLAIN}"
        exit 1
    fi
}


getSYSinf(){
    SYSmaf=`dmidecode |grep -A16 "System Information$" |grep "Manufacturer"|head -n 1 |awk -F': ' '{print $2}'`
    SYSmod=`dmidecode |grep -A16 "System Information$" |grep "Product Name"|head -n 1|awk -F': ' '{print $2}'`
    SYSsn=`dmidecode |grep -A16 "System Information$" |grep "Serial Number"|head -n 1|awk -F': ' '{print $2}'`
    SYSnm=`hostname -f`
    SYSos=`cat /etc/system-release`
    SYSkn=`uname -r`
    SYSip=`ip addr | grep 'state UP' -A2 | grep '172.[12]6' | head -n 1 | awk '{print $2}' | cut -f1 -d '/'`
    
    echo $SYSmaf
    echo $SYSmod
    echo $SYSsn
    echo $SYSnm
    echo $SYSos
    echo $SYSkn
    echo $SYSip
}

getCPUinf(){
    CPUnm=`cat /proc/cpuinfo | grep "model name" | uniq |awk -F': ' '{print $2}'`
    CPUcut=`cat /proc/cpuinfo| grep "physical id"| sort| uniq| wc -l`
    CPUcore=`cat /proc/cpuinfo | grep "core id" | sort | uniq | wc -l`
    CPUproc=`cat /proc/cpuinfo| grep "processor"| wc -l`
    CPUhz=
}

getMEMinf(){
    MEMtotal=`dmidecode -t memory | grep  Size: | grep -v "No Module Installed" | awk '{sum+=$2}END{print sum,$3}'`
    MEMsltcut=`dmidecode|grep -P -A5 "Memory\s+Device"|grep Size|grep -v Range|wc -l`
    MEMsltuse=`dmidecode -t memory | grep Size | grep -v "No Module Installed"|wc -l`
    MEMhz=`dmidecode -t memory | grep "Speed:" |grep -v "Unknown"`
}

getDISKinf(){
    DISKcut=`fdisk -l |grep 'Disk /dev/sd*' |awk -F , '{print $1}' | sed 's/Disk identifier.*//g' | sed '/^$/d'|wc -l`
    DISKsltc=
    DISKsz=
}

getETHinf(){
    ETHcut=`lspci |grep -i ethernet |wc -l`
    ETHmod=`lspci |grep -i ethernet |awk -F': ' '{print $2}'`
    ETHsp=
}

chk_lspci
chk_dmi
getSYSinf