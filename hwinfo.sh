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
echo "-------------------------Ready To Collect------------------------"

#Check the components
chk_lspci(){
    lspci=`whereis lspci | awk -F ":" '{print $2}'`
    if [ ${#lspci} -eq 0 ];then
        echo -e "${RED} [FAILED] lspci is not ready. trying to install....${PLAIN}"
        install_lspci
    else
        echo -e "${GREEN} [OK] lspci is ready.${PLAIN}"
    fi
}

chk_dmi(){
    dmi=`whereis dmidecode | awk -F ":" '{print $2}'`
    if [ ${#dmi} -eq 0 ];then
        echo -e "${RED} [FAILED] dmidecode is not ready. trying to install....${PLAIN}"
        install_dmi
    else
        echo -e "${GREEN} [OK] dmidecode is ready.${PLAIN}"
    fi
}

chk_smctl(){
    smctl=`whereis smartctl | awk -F ":" '{print $2}'`
    if [ ${#smctl} -eq 0 ];then
        echo -e "${RED} [FAILED] smartctl is not ready. trying to install....${PLAIN}"
        install_smctl
    else
        echo -e "${GREEN} [OK] smartctl is ready.${PLAIN}"
    fi
}

#Install components
install_lspci(){
    yum install pciutils -y -q
    if [ $? -eq 0 ];then
        echo -e "${GREEN} [OK] lspci is ready.${PLAIN}"
    else
        echo -e "${RED} [FAILED] lspci installation failed, please try to install manually.${PLAIN}"
        exit 1
    fi
}

install_dmi(){
    yum install dmidecode -y -q
    if [ $? -eq 0 ];then
        echo -e "${GREEN} [OK] dmidecode is ready.${PLAIN}"
    else
        echo -e "${RED} [FAILED] dmidecode installation failed, please try to install manually.${PLAIN}"
        exit 1
    fi
}

install_smctl(){
    yum install smartmontools -y -q
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

    echo "---------------------------System INFO---------------------------"
    echo -e "${GREEN}System Manufacturer${PLAIN}: ${SYSmaf}"
    echo -e "${GREEN}System Model Name${PLAIN}  : ${SYSmod}"
    echo -e "${GREEN}Serial Number${PLAIN}      : ${SYSsn}"
    echo -e "${GREEN}Hostname${PLAIN}           : ${SYSnm}"
    echo -e "${GREEN}System release${PLAIN}     : ${SYSos}"
    echo -e "${GREEN}Kernel release${PLAIN}     : ${SYSkn}"
    echo -e "${GREEN}IP Address${PLAIN}         : ${SYSip}"
}

#CPU Information collection
getCPUinf(){
    #CPU Model Name (无法兼容CPU混插情况，待增加判断)
    CPUnm=`cat /proc/cpuinfo | grep "model name" | uniq |awk -F': ' '{print $2}'`
    #Physical CPU Count
    CPUcut=`cat /proc/cpuinfo| grep "physical id"| sort| uniq| wc -l`
    #Cores Count (Per CPU)
    CPUcore=`cat /proc/cpuinfo | grep "core id" | sort | uniq | wc -l`
    #Threads Count
    CPUproc=`cat /proc/cpuinfo| grep "processor"| wc -l`

    echo "-----------------------------CPU INFO----------------------------"
    echo -e "${GREEN}CPU Model Name${PLAIN}     : ${CPUnm}"
    echo -e "${GREEN}Physical CPU Count${PLAIN} : ${CPUcut}"
    echo -e "${GREEN}Cores (Per CPU)${PLAIN}    : ${CPUcore}"
    echo -e "${GREEN}Threads Count${PLAIN}      : ${CPUproc}"
}

#Memory Information collection
getMEMinf(){
    #Memory Total Size 
    MEMtotal=`dmidecode -t 17 | grep  "Size:" | grep -v "No Module Installed" | awk '{sum+=$2}END{print sum,$3}'`
    #Memory Slot Count
    MEMsltcut=`dmidecode|grep -P -A5 "Memory\s+Device"|grep "Size"|grep -v "Range"|wc -l`
    #Uesd Memory Slot Count
    MEMsltuse=`dmidecode -t 17 | grep "Size:" | grep -v "No Module Installed"|wc -l`
    #Memory Slot Type
    MEMtype=`dmidecode -t 17 | grep "Type:" | uniq |awk -F': ' '{print $2}'`
    #Memory Size (Per Slot)
    slotsize=0
    for i in `dmidecode -t 17 | grep  "Size:" | grep -v "Installed" |awk -F': ' '{print $2}'|sed 's/[ ][ ]*//g'`
    do
        MEMsize[$slotsize]=$i
        ((slotsize++))
    done
    #Memory Speed (Per Slot,Standard Memory Speed , not Clock Speed)
    slotspd=0
    for s in `dmidecode -t 17 | grep "Speed:" |grep -v "Unknown"|grep -v "Clock Speed:"|awk -F': ' '{print $2}'|sed 's/[ ][ ]*//g'`
    do
        MEMspd[$slotspd]=$s
        ((slotspd++))
    done

    echo "---------------------------Memory INFO---------------------------"
    echo -e "${GREEN}Memory Type${PLAIN}        : ${MEMtype}"    
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

#DISK Information collection
getDISKinf(){
    #If RAID
    megaraid=`smartctl --scan | grep megaraid_disk | wc -l`
    if [ ${megaraid} -eq 0 ];then
        isRaid="false"
        DISKlist=`smartctl --scan | grep -v "megaraid,*" |awk -F ' ' '{print $1}'`
    else
        isRaid="true"
        DISKlist=`smartctl --scan | grep "megaraid,*" |awk -F ' ' '{print $3}'`
    fi

    echo "---------------------------DISK INFO-------------------------"
    dslot=0
    if [ ${isRaid} == "true" ];then
        for d in "${DISKlist[@]}"
        do
            DISKsize[$dslot]=`smartctl -i -d $d /dev/sda | grep "User Capacity:" | grep -o '\[.*\]' | sed 's/[][]*//g'`
            DISKmd[$dslot]=`smartctl -i -d $d /dev/sda |grep "Product:" | awk -F': ' '{print $2}'|sed 's/[ ][ ]*//g'`
            DISKtype[$dslot]=`smartctl -i -d $d /dev/sda |grep "Form Factor:" | awk -F': ' '{print $2}'|sed 's/[ ][ ]*//g'`
            ((dslot++))
        done
    else
        for d in "${DISKlist[@]}"
        do
            DISKsize[$dslot]=`smartctl -i $d | grep "User Capacity:" | grep -o '\[.*\]' | sed 's/[][]*//g'`
            DISKmd[$dslot]=`smartctl -i $d |grep "Product:" | awk -F':' '{print $2}'|sed 's/[ ][ ]*//g'`
            DISKtype[$dslot]=`smartctl -i $d |grep "Form Factor:" | awk -F': ' '{print $2}'|sed 's/[ ][ ]*//g'`
            ((dslot++))
        done
    fi

    m2=0
    while [ $m2 -lt $dslot ]
    do
        echo -e "${GREEN}DISK$m2 Size${PLAIN} : ${DISKsize[$m2]}"
        echo -e "${GREEN}DISK$m2 Model Name${PLAIN} : ${DISKmd[$m2]}"
        echo -e "${GREEN}DISK$m2 Type${PLAIN} : ${DISKtype[$m2]}"
        ((m2++))
    done
    #Disk Count (SATA , SAS or NVMe Device)
}

#Ethernet Device Information collection
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

    echo "--------------------------EthDeivce INFO-------------------------"
    echo -e "${GREEN}Eth Device Count${PLAIN}   : ${ETHcut}"
    m1=0
    while [ $m1 -lt $ethslot ]
    do
        echo -e "${GREEN}Device$m1 Model Name${PLAIN} : ${ETHnm[$m1]}"
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
    getDISKinf
}

showData

echo "-----------------------------------------------------------------"
echo -e "${RED}All done. Exit.${PLAIN}"