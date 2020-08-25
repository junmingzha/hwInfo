#!/bin/bash
#Server Hardware Information Collector
#For RHEL/CentOS/Ubuntu
#Author   : xinchen.luan@transwarp.io
#Date     : 08/04/2020

if [ $UID != 0 ]; then
    echo "Error: You must be root to run this script!"
    return
fi

#Output formatting
GREEN='\033[0;32m'
RED='\033[0;31m'
PLAIN='\033[0m'
echo "-------------------------Ready To Collect------------------------"

#Get the OS-Version
getOSinf(){
    [ -f /etc/os-release ] && awk -F'[= "]' '/PRETTY_NAME/{print $3,$4,$5}' /etc/os-release && return
    [ -f /etc/redhat-release ] && awk '{print ($1,$3~/^[0-9]/?$3:$4)}' /etc/redhat-release && return
    [ -f /etc/lsb-release ] && awk -F'[="]+' '/DESCRIPTION/{print $2}' /etc/lsb-release && return
}

#Check the environment
chk_env(){
    soft=`whereis $1 | awk -F ":" '{print $2}'`
    if [ ${#soft} -eq 0 ];then
        echo -e "${RED} [FAILED] $1 is not ready. trying to install....${PLAIN}"
        install_env $2
    else
        echo -e "${GREEN} [OK] $1 is ready.${PLAIN}"
    fi
}

#Install the environment
install_env(){
    case $( getOSinf ) in
    CentOS*|Redhat*|NeoKylin*)
        yum install $1 -y -q
        ;;
    Ubuntu*|UOS*|Kylin*)
        apt-get install -y $1 > /dev/null
        ;;
    *)
        echo -e "${RED} [FAILED] Unknown System! $1 installation failed, please try to install manually.${PLAIN}"
        return
    esac
    if [ $? -eq 0 ];then
        echo -e "${GREEN} [OK] $1 is ready.${PLAIN}"
    else
        echo -e "${RED} [FAILED] $1 installation failed, please try to install manually.${PLAIN}"
        return
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
    SYSos=$( getOSinf )
    #Kernel Version
    SYSkn=`uname -r`
    #System IP Address
    SYSip=`ip addr | grep 'state UP' -A2 | grep '172.[12]6' | head -n 1 | awk '{print $2}' | cut -f1 -d '/'`
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
}

getMEMinf(){
    #Memory Total Size 
    MEMtotal=`dmidecode -t 17 | grep  "Size:" | grep -v "No Module Installed" | awk '{sum+=$2}END{print sum,$3}'`
    #Memory Slot Count
    MEMsltcut=`dmidecode|grep -P -A5 "Memory\s+Device"|grep "Size"|grep -v "Range"|wc -l`
    #Uesd Memory Slot Count
    MEMsltuse=`dmidecode -t 17 | grep "Size:" | grep -v "No Module Installed"|wc -l`
    #Memory Slot Type
    MEMtype=`dmidecode -t 17 | grep "Type:" | grep -v "Unknown" |uniq |awk -F': ' '{print $2}'`
    #Memory Size (Per Slot)
    #Initialize the memory slot variable "slotsize" for MemorySize
    slotsize=0
    for msize in `dmidecode -t 17 | grep  "Size:" | grep -v "Installed" |awk -F': ' '{print $2}'|sed 's/[ ][ ]*//g'`
    do
        MEMsize[$slotsize]=$msize
        ((slotsize++))
    done
    #Memory Speed (Per Slot,Standard Memory Speed , not Clock Speed)
    #Initialize the memory slot variable "slotspd" for MemorySpeed
    slotspd=0
    for mspd in `dmidecode -t 17 | grep "Speed:" |grep -v "Unknown"|grep -v "Clock Speed:"|awk -F': ' '{print $2}'|sed 's/[ ][ ]*//g'`
    do
        MEMspd[$slotspd]=$mspd
        ((slotspd++))
    done
}

#DISK Information collection (Cannot support NVME devices)
getDISKinf(){
    #If RAID
    megaraid=`smartctl --scan | grep megaraid_disk | wc -l`
    if [ ${megaraid} -eq 0 ];then
        smartctl="smartctl -i"
        DISKlist=$(smartctl --scan | grep -v "megaraid,*" |awk -F ' ' '{print $1}')
        DISKcut=$(smartctl --scan | grep -v "megaraid,*" |awk -F ' ' '{print $1}'|wc -l)
        dev=""
    else
        smartctl="smartctl -i -d"
        DISKlist=$(smartctl --scan | grep "megaraid,*" |awk -F ' ' '{print $3}')
        DISKcut=$(smartctl --scan | grep "megaraid,*" |awk -F ' ' '{print $1}'|wc -l)
        dev="/dev/sda"
    fi
    #Get Disk Information
    dslot=0
    for disk in `echo $DISKlist`
    do
        DISKsize[$dslot]=`$smartctl $disk $dev | grep "User Capacity:" | grep -o '\[.*\]' | sed 's/[][]*//g'`
        DISKmd[$dslot]=`$smartctl $disk $dev |grep "Product:" | awk -F': ' '{print $2}'|sed 's/[ ][ ]*//g'`
        DISKtype[$dslot]=`$smartctl $disk $dev |grep "Form Factor:" | awk -F': ' '{print $2}'|sed 's/[ ][ ]*//g'`
        ((dslot++))
    done
}

getETHinf(){
    #Ethernet Device Count
    ETHcut=`lspci |grep -i ethernet |wc -l`
    #Ethernet Device Model Name
    ethslot=0
    for eth in `lspci |grep -i ethernet |awk -F': ' '{print $2}'|sed 's/[ ][ ]*/_/g'`
    do
        ETHnm[$ethslot]=$eth
        ((ethslot++))
    done
}

MEMitem(){
    m=0
    while [ $m -lt $slotsize ]
    do
        echo -e "Slot$m Size         : ${MEMsize[$m]}"
        echo -e "Slot$m Speed        : ${MEMspd[$m]}"
        ((m++))
    done
}

ETHitem(){
    m1=0
    while [ $m1 -lt $ethslot ]
    do
        echo -e "Device$m1 Model Name : ${ETHnm[$m1]}"
        ((m1++))
    done
}

DISKitem(){
    m2=0
    while [ $m2 -lt $dslot ]
    do
        echo -e "DISK$m2 Model Name   : ${DISKmd[$m2]}"
        echo -e "DISK$m2 Size         : ${DISKsize[$m2]}"
        echo -e "DISK$m2 Type         : ${DISKtype[$m2]}"
        ((m2++))
    done
}

getALLinf(){
    chk_env lspci pciutils
    chk_env dmidecode dmidecode
    chk_env smartctl smartmontools
    getSYSinf
    getCPUinf
    getMEMinf
    getETHinf
    getDISKinf
}

showData(){
    echo "---------------------------System INFO---------------------------"
    echo -e "${GREEN}System Manufacturer${PLAIN}: ${SYSmaf}"
    echo -e "${GREEN}System Model Name${PLAIN}  : ${SYSmod}"
    echo -e "${GREEN}Serial Number${PLAIN}      : ${SYSsn}"
    echo -e "${GREEN}Hostname${PLAIN}           : ${SYSnm}"
    echo -e "${GREEN}System release${PLAIN}     : ${SYSos}"
    echo -e "${GREEN}Kernel release${PLAIN}     : ${SYSkn}"
    echo -e "${GREEN}IP Address${PLAIN}         : ${SYSip}"
    echo "-----------------------------CPU INFO----------------------------"
    echo -e "${GREEN}CPU Model Name${PLAIN}     : ${CPUnm}"
    echo -e "${GREEN}Physical CPU Count${PLAIN} : ${CPUcut}"
    echo -e "${GREEN}Cores (Per CPU)${PLAIN}    : ${CPUcore}"
    echo -e "${GREEN}Threads Count${PLAIN}      : ${CPUproc}"
    echo "---------------------------Memory INFO---------------------------"
    echo -e "${GREEN}Memory Type${PLAIN}        : ${MEMtype}"    
    echo -e "${GREEN}Memory Total Size${PLAIN}  : ${MEMtotal}"
    echo -e "${GREEN}Memory Slot Count${PLAIN}  : ${MEMsltcut}"
    echo -e "${GREEN}Uesd Slot Count${PLAIN}    : ${MEMsltuse}"
    MEMitem
    echo "---------------------------DISK INFO-----------------------------"
    echo -e "${GREEN}DISK Count${PLAIN}         : ${DISKcut}"
    DISKitem
    echo "--------------------------EthDeivce INFO-------------------------"
    echo -e "${GREEN}Eth Device Count${PLAIN}   : ${ETHcut}"
    ETHitem
    echo "-------------------------------END-------------------------------"
}

syncData(){
    mem_item=$( MEMitem )
    disk_item=$( DISKitem )
    eth_item=$( ETHitem )
    curl http://172.16.2.33:8080/hwinfo -X POST -d "sys_maf=${SYSmaf}&sys_mod=${SYSmod}&sys_sn=${SYSsn}&sys_nm=${SYSnm}&sys_os=${SYSos}&sys_kn=${SYSkn}&sys_ip=${SYSip}&cpu_mod=${CPUnm}&cpu_num=${CPUcut}&cpu_core=${CPUcore}&cpu_thr=${CPUproc}&mem_type=${MEMtype}&mem_size=${MEMtotal}&mem_slot=${MEMsltcut}&mem_used=${MEMsltuse}&mem_item=${mem_item}&disk_count=${DISKcut}&disk_item=${disk_item}&eth_count=${ETHcut}&eth_item=${eth_item}"
    return 1
}

getALLinf
showData
#syncData
echo -e "${RED}All done. Exit.${PLAIN}"