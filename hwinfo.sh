#!/bin/bash
#Server Hardware Configuration Collector
#For RHEL/CentOS
#Author   : xinchen.luan@transwarp.io
#Date     : 08/04/2020

if [ $UID != 0 ]; then
    echo "Error: You must be root to run this script!"
    exit 1
fi

#Output formatting
GREEN='\033[0;32m'
RED='\033[0;31m'
PLAIN='\033[0m'
echo  "-------------------Ready To Collect-------------------"

#Check the components
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

chk_smctl(){
    smctl=`whereis smartctl | awk -F ":" '{print $2}'`
    if [ ${#smctl} -eq 0 ];then
        echo -e "${RED} [Failed] smartctl is not ready!${PLAIN}"
    else
        echo -e "${GREEN} [OK] dmidecode is ready.${PLAIN}"
    fi
}

#Install components
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

install_smctl(){
    yum install smartmontools -y
    if [ $? -eq 0 ];then
        echo -e "${GREEN} [OK] smartctl is ready.${PLAIN}"
    else
        echo -e "${RED} [FAILED] smartctl installation failed, please try to install manually.${PLAIN}"
        exit 1
    fi
}

#System Information collection
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

    echo "------------------------------------------------------"
    echo -e "${GREEN}System Manufacturer${PLAIN}: ${SYSmaf}"
    echo -e "${GREEN}System Model Name${PLAIN}  : ${SYSmod}"
    echo -e "${GREEN}Serial Number${PLAIN}      : ${SYSsn}"
    echo -e "${GREEN}Host name${PLAIN}          : ${SYSnm}"
    echo -e "${GREEN}System release${PLAIN}     : ${SYSos}"
    echo -e "${GREEN}Kernel release${PLAIN}     : ${SYSkn}"
    echo -e "${GREEN}IP Address${PLAIN}         : ${SYSip}"
}

getCPUinf(){
    #CPU Model Name
    CPUnm=`cat /proc/cpuinfo | grep "model name" | uniq |awk -F': ' '{print $2}'`
    #Physical CPU Count
    CPUcut=`cat /proc/cpuinfo| grep "physical id"| sort| uniq| wc -l`
    #Cores Count (Per CPU)
    CPUcore=`cat /proc/cpuinfo | grep "core id" | sort | uniq | wc -l`
    #Threads Count
    CPUproc=`cat /proc/cpuinfo| grep "processor"| wc -l`

    echo "------------------------------------------------------"
    echo -e "${GREEN}CPU Model Name${PLAIN}     : ${CPUnm}"
    echo -e "${GREEN}Physical CPU Count${PLAIN} : ${CPUcut}"
    echo -e "${GREEN}CPU Cores Count${PLAIN}    : ${CPUcore}"
    echo -e "${GREEN}Threads Count${PLAIN}      : ${CPUproc}"
}

getMEMinf(){
    #Memory Total Size 
    MEMtotal=`dmidecode -t memory | grep  Size: | grep -v "No Module Installed" | awk '{sum+=$2}END{print sum,$3}'`
    #Memory Slot Count
    MEMsltcut=`dmidecode|grep -P -A5 "Memory\s+Device"|grep Size|grep -v Range|wc -l`
    #Uesd Memory Slot Count
    MEMsltuse=`dmidecode -t memory | grep Size | grep -v "No Module Installed"|wc -l`
    #Memory Size (Per Slot)
    slotsize=0
    for i in `dmidecode -t memory | grep  Size: | grep -v "Installed" |awk -F': ' '{print $2}'|sed 's/[ ][ ]*//g'`
    do
        MEMsize[$slotsize]=$i
        ((slotsize++))
    done
    #Memory Speed (Per Slot,Standard Memory Speed , not Clock Speed)
    slotspd=0
    for s in `dmidecode -t memory | grep "Speed:" |grep -v "Unknown"|grep -v "Clock Speed:"|awk -F': ' '{print $2}'|sed 's/[ ][ ]*//g'`
    do
        MEMspd[$slotspd]=$s
        ((slotspd++))
    done

    echo "------------------------------------------------------"
    echo -e "${GREEN}Memory Total Size${PLAIN}  : ${MEMtotal}"
    echo -e "${GREEN}Memory Slot Count${PLAIN}  : ${MEMsltcut}"
    echo -e "${GREEN}Uesd Slot Count${PLAIN}    : ${MEMsltuse}"

    #Echo Memory Size & Speed
    m=0
    while [ $m -lt $slotsize ]
    do
        echo -e "${GREEN}Slot$m Size${PLAIN}         : ${MEMsize[$m]}"
        echo -e "${GREEN}Slot$m Speed${PLAIN}        : ${MEMspd[$m]}"
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
    #Ethernet Device Count
    ETHcut=`lspci |grep -i ethernet |wc -l`
    #Ethernet Device Model Name
    ethslot=0
    for e in `lspci |grep -i ethernet |awk -F': ' '{print $2}'|sed 's/[ ][ ]*/_/g'`
    do
        ETHnm[$ethslot]=$e
        ((ethslot++))
    done

    echo "------------------------------------------------------"
    echo -e "${GREEN}Eth Device Count${PLAIN}   : ${ETHcut}"
    m1=0
    while [ $m1 -lt $ethslot ]
    do
        echo -e "${GREEN}Device$m1 Model ${PLAIN}  : ${ETHnm[$m1]}"
        ((m1++))
    done
}


showData(){
    chk_lspci
    chk_dmi
    chk_smctl
    getSYSinf
    getCPUinf
    getMEMinf
    getETHinf
}

showData