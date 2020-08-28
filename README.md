```
╔╗   ╔╗  ╔═╗
║╚╦╦╦╬╬═╦╣═╬═╗
║║║║║║║║║║╔╣╬║
╚╩╩══╩╩╩═╩╝╚═╝
```

### hwInfo 服务器硬件配置采集脚本
* 系统信息：系统厂商、型号、序列号、Hostname、操作系统版本、内核版本、ip地址(仅支持上海机房ip识别)
* CPU信息：CPU型号(含主频)、物理CPU数量、每CPU核心数量、总线程数量
* 内存信息：内存总容量、内存插槽总数、已用内存插槽数量、插槽类型、遍历各插槽内存容量&频率
* 硬盘信息：硬盘总数量、遍历各硬盘型号&容量&尺寸规格
* 网卡信息：网卡总数量、遍历各网卡型号

#### [Release] V1.0
* 增加硬盘RAID识别，RAID下获取物理磁盘信息
* 修复SATA磁盘无法获取型号问题
* 兼容RHEL、CentOS、Ubuntu、中标麒麟、银河麒麟、UOS操作系统
* 修复部分机型内存类型识别异常问题

#### 已知问题
* 1.ARM CPU无法获取型号、物理CPU数量、核心数量信息
* 2.无法识别NVMe硬盘信息
* 3.无法兼容CPU混插平台
* 4.硬盘未挂载时无法获取容量信息，需根据型号手动匹配
* 5.Intel傲腾内存无法识别类型
* 6.使用转接卡或转接架的硬盘无法识别尺寸大小

#### 环境依赖
python2.7
webpy
mysql

##### 数据库字段说明

| 字段名           | 数据类型     | 注释                   |
| ---------------- | ------------ | ---------------------- |
| id               | int          | id                     |
| sys_manufacturer | varchar(100) | 服务器厂商             |
| sys_model        | varchar(100) | 服务器型号             |
| sys_sn           | varchar(100) | 系统序列号             |
| sys_hostname     | varchar(100) | Hostname               |
| sys_os           | varchar(100) | 操作系统               |
| sys_kernel       | varchar(100) | 内核版本               |
| sys_ip           | varchar(100) | 内网ip（上海机房地址） |
| cpu_model        | varchar(100) | CPU型号                |
| cpu_number       | varchar(100) | CPU数量                |
| cpu_cores        | varchar(100) | 每CPU核心数            |
| cpu_threads      | varchar(100) | 线程总数               |
| mem_type         | varchar(100) | 内存类型               |
| mem_size_total   | varchar(100) | 内存总量               |
| mem_slot_count   | varchar(100) | 内存插槽计数           |
| mem_uesd_slot    | varchar(100) | 已用内存插槽计数       |
| mem_item         | longtext     | 内存明细               |
| disk_count       | varchar(100) | 硬盘计数               |
| disk_item        | longtext     | 硬盘明细               |
| eth_device_count | varchar(100) | 网卡计数               |
| eth_device_item  | longtext     | 网卡明细               |
| datetime         | datetime     | 信息收集时间戳         |
