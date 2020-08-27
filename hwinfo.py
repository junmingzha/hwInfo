import web
import datetime

urls = (
    '/', 'index',
    '/hwinfo','hwinfo_db',
    '/hwinfo.sh','hwinfo_sh'
)

db = web.database(  dbn='mysql',
                    host='127.0.0.1',
                    port=3306,
                    db='hwinfo',
                    user='root',
                    pw='Warp1234',
                    driver='mysql.connector',
                    auth_plugin='mysql_native_password')

class index:
    def GET(self):
        return "Hello, world!"

class hwinfo_db:
    def POST(self):
        i = web.input()
        dt = datetime.datetime.now().strftime('%Y-%m-%d %H:%M:%S')
        n = db.insert(  'hwinfo_main',
                        sys_manufacturer = i.sys_maf,
                        sys_model = i.sys_mod,
                        sys_sn = i.sys_sn,
                        sys_hostname = i.sys_nm,
                        sys_os = i.sys_os,
                        sys_kernel = i.sys_kn,
                        sys_ip = i.sys_ip,
                        cpu_model = i.cpu_mod,
                        cpu_number = i.cpu_num,
                        cpu_cores = i.cpu_core,
                        cpu_threads = i.cpu_thr,
                        mem_type = i.mem_type,
                        mem_size_total = i.mem_size,
                        mem_slot_count = i.mem_slot,
                        mem_uesd_slot = i.mem_used,
                        mem_item = i.mem_item,
                        disk_count = i.disk_count,
                        disk_item = i.disk_item,
                        eth_device_count = i.eth_count,
                        eth_device_item = i.eth_item,
                        datetime = dt)


class hwinfo_sh:
    def GET(self):
        f=open('/root/hwinfo/hwinfo.sh','r')
        data=f.read()
        f.close
        return data

if __name__ == "__main__":
    app = web.application(urls, globals())
    app.run()