#!/bin/bash
#Server Hardware Configuration Collector
#For RHEL7/CentOS7
#Created by xinchen.luan
#Date:08/04/2020
if [ $UID != 0 ]; then
    echo "Error: You must be root to run this script!"
    exit 1
fi

#Format STo
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
        echo -e "${RED} [FAILED] lspci installation failed, please try to install manually.${PLAIN}"
        exit 1
    fi
}

install_dmi(){
    yum install pciutils -y
    if [ $? -eq 0 ];then
        echo -e "${GREEN} [OK] dmidecode is ready.${PLAIN}"
    else
        echo -e "${RED} [FAILED] dmidecode installation failed, please try to install manually.${PLAIN}"
        exit 1
    fi
}

getSYSinf(){
    #System Manufacturer
    SYSmaf=`dmidecode |grep -A16 "System Information$" |grep "Manufacturer"|head -n 1 |awk -F': ' '{print $2}'`
    #System Model Name
    SYSmod=`dmidecode |grep -A16 "System Information$" |grep "Product Name"|head -n 1|awk -F': ' '{print $2}'`
    #System Serial Number (by product,not node)
    SYSsn=`dmidecode |grep -A16 "System Information$" |grep "Serial Number"|head -n 1|awk -F': ' '{print $2}'`
    #Hostname
    SYSnm=`hostname -f`
    #OS Version
    SYSos=`cat /etc/system-release`
    #Kernel Version
    SYSkn=`uname -r`
    #System IP Address
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
    #CPU Model Name
    CPUnm=`cat /proc/cpuinfo | grep "model name" | uniq |awk -F': ' '{print $2}'`
    #CPUs Count
    CPUcut=`cat /proc/cpuinfo| grep "physical id"| sort| uniq| wc -l`
    #Cores Count (Per CPU)
    CPUcore=`cat /proc/cpuinfo | grep "core id" | sort | uniq | wc -l`
    #Threads Count
    CPUproc=`cat /proc/cpuinfo| grep "processor"| wc -l`

    echo $CPUcore
    echo $CPUcut
    echo $CPUnm
    echo $CPUproc
}

getMEMinf(){
    #Memory Total Size 
    MEMtotal=`dmidecode -t memory | grep  Size: | grep -v "No Module Installed" | awk '{sum+=$2}END{print sum,$3}'`
    #Memory Slot Count
    MEMsltcut=`dmidecode|grep -P -A5 "Memory\s+Device"|grep Size|grep -v Range|wc -l`
    #Uesd Memory Slot Count
    MEMsltuse=`dmidecode -t memory | grep Size | grep -v "No Module Installed"|wc -l`
    #Memory Speed (Standard Memory Speed , not Clock Speed)
    MEMhz=`dmidecode -t memory | grep "Speed:" |grep -v "Unknown"|grep -v "Clock Speed:"|awk -F': ' '{print $2}'|sed 's/[ ][ ]*//g'`

    #Memory Size (Per Slot)
    slotsize=0
    for i in `dmidecode -t memory | grep  Size: | grep -v "Installed" |awk -F': ' '{print $2}'|sed 's/[ ][ ]*//g'`
    do
        MEMsize[$slotsize]=$i
        ((slotsize++))
    done

    #Memory Speed (Per Slot)
    slotspd=0
    for s in `dmidecode -t memory | grep "Speed:" |grep -v "Unknown"|grep -v "Clock Speed:"|awk -F': ' '{print $2}'|sed 's/[ ][ ]*//g'`
    do
        MEMspd[$slotspd]=$s
        ((slotspd++))
    done

    echo $MEMtotal
    echo $MEMsltcut
    echo $MEMsltuse
    echo $MEMhz

    #Echo Memory Size & Speed
    m=0
    while [ $m -lt $m1 ]
    do
        echo "Slot$m Size: ${MEMsize[$m]}"
        echo "Slot$m Speed: ${MEMspd[$m]}"
        ((m++))
    done
}

getDISKinf(){
    #Disk Count (SATA , SAS or NVMe Device)
    DISKcut=`fdisk -l |grep 'Disk /dev/sd*' |awk -F , '{print $1}' | sed 's/Disk identifier.*//g' | sed '/^$/d'|wc -l`
    DISKsltc=
    DISKsz=

    echo $DISKcut
}

getETHinf(){
    ETHcut=`lspci |grep -i ethernet |wc -l`
    ETHmod=`lspci |grep -i ethernet |awk -F': ' '{print $2}'`
    ETHsp=

    echo $ETHcut
    echo $ETHmod
}

chk_lspci
chk_dmi
getSYSinf
