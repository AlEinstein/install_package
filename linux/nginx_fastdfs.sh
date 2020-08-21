#!/bin/bash
## https://me.csdn.net/qq262593421

## 启动和关闭fdfs
## /usr/bin/fdfs_trackerd  /etc/fdfs/tracker.conf  restart
## /usr/bin/fdfs_storaged  /etc/fdfs/storage.conf  restart
## /usr/local/nginx/sbin/nginx -s reload
## /usr/bin/fdfs_test /etc/fdfs/client.conf upload /usr/local/software/1001.png

## 安装libfastcommon公共c库
rm -rf /usr/local/fast /usr/local/nginx* /usr/bin/fdfs* /etc/fdfs
mkdir -p /usr/local/fast
tar zxvf /usr/local/software/libfastcommon-1.0.38.tar.gz -C /usr/local/fast/
cd /usr/local/fast/libfastcommon-1.0.38/ && ./make.sh && ./make.sh install

## 创建软链接
ln -s /usr/lib64/libfastcommon.so /usr/local/lib/libfastcommon.so
ln -s /usr/lib64/libfastcommon.so /usr/lib/libfastcommon.so
ln -s /usr/lib64/libfdfsclient.so /usr/local/lib/libfdfsclient.so
ln -s /usr/lib64/libfdfsclient.so /usr/lib/libfdfsclient.so

## fastDFS编译和安装
tar zxvf /usr/local/software/fastdfs-5.11.tar.gz -C /usr/local/fast/
cd /usr/local/fast/fastdfs-5.11 && ./make.sh && ./make.sh install

##配置tracker目录
cp /etc/fdfs/tracker.conf.sample /etc/fdfs/tracker.conf
cat /etc/fdfs/tracker.conf | grep base_path
sed -i "s/base_path=\/home\/yuqing\/fastdfs/base_path=\/fastdfs\/tracker/g" /etc/fdfs/tracker.conf
mkdir -p /fastdfs/tracker
## 修改之后为
## base_path=/fastdfs/tracker
#配置防火墙，打开tracker使用的端口22122
firewall-cmd --list-ports
firewall-cmd --zone=public --add-port=22122/tcp --permanent
firewall-cmd --reload
##启动tracker
/usr/bin/fdfs_trackerd /etc/fdfs/tracker.conf
ps -ef | grep fdfs
##设置开机自启
echo "/usr/bin/fdfs_trackerd /etc/fdfs/tracker.conf" >> /etc/rc.d/rc.local
cat /etc/rc.d/rc.local

##配置fastdfs存储
cp /etc/fdfs/storage.conf.sample /etc/fdfs/storage.conf
cat /etc/fdfs/storage.conf | grep base_path=
cat /etc/fdfs/storage.conf | grep store_path0=
cat /etc/fdfs/storage.conf | grep tracker_server=
cat /etc/fdfs/storage.conf | grep http.server_port=
sed -i "s/base_path=\/home\/yuqing\/fastdfs/base_path=\/fastdfs\/storage/g" /etc/fdfs/storage.conf
sed -i "s/store_path0=\/home\/yuqing\/fastdfs/store_path0=\/fastdfs\/storage/g" /etc/fdfs/storage.conf
sed -i "s/tracker_server=192.168.209.121:22122/tracker_server=192.168.0.130:22122/g" /etc/fdfs/storage.conf
sed -i "s/http.server_port=8888/http.server_port=8083/g" /etc/fdfs/storage.conf
mkdir -p /fastdfs/storage
## 修改之后为
## base_path=/fastdfs/storage
## store_path0=/fastdfs/storage
## tracker_server=192.168.0.130:22122
## http.server_port=8083

#配置防火墙,允许外界访问storage的默认端口23000
firewall-cmd --zone=public --add-port=23000/tcp --permanent
firewall-cmd --reload
firewall-cmd --list-ports

## 启动storage
/usr/bin/fdfs_storaged /etc/fdfs/storage.conf
ps -ef | grep fdfs
## 设置storage开机自启动
echo "/usr/bin/fdfs_storaged /etc/fdfs/storage.conf" >> /etc/rc.d/rc.local
cat /etc/rc.d/rc.local
chmod +x /etc/rc.d/rc.local

## 配置client.conf文件
cp /etc/fdfs/client.conf.sample /etc/fdfs/client.conf
cat /etc/fdfs/client.conf | grep base_path=
cat /etc/fdfs/client.conf | grep tracker_server=
cat /etc/fdfs/client.conf | grep http.tracker_server_port=
sed -i "s/base_path=\/home\/yuqing\/fastdfs/base_path=\/fastdfs\/tracker/g" /etc/fdfs/client.conf
sed -i "s/tracker_server=192.168.0.197:22122/tracker_server=192.168.0.130:22122/g" /etc/fdfs/client.conf
sed -i "s/http.tracker_server_port=80/http.tracker_server_port=8083/g" /etc/fdfs/client.conf
## 修改之后为
## base_path=/fastdfs/tracker
## tracker_server=192.168.0.130:22122
## http.tracker_server_port=8083

## 测试图片上传（FastDFS安装成功可通过/usr/bin/fdfs_test测试上传、下载等操作）
/usr/bin/fdfs_test /etc/fdfs/client.conf upload /usr/local/software/1001.png


## FastDFS与Nginx结合
cd /usr/local/software/ && tar -zxvf fastdfs-nginx-module_v1.16.tar.gz -C /usr/local/fast/ 
## 修改conf配置文件（把文件的第四行配置中的/usr/local/都改为/usr/，共两处）
cp /usr/local/fast/fastdfs-nginx-module/src/config /usr/local/fast/fastdfs-nginx-module/src/config.template
sed -i "s#CORE_INCS=\"\$CORE_INCS /usr/local/include/fastdfs /usr/local/include/fastcommon/\"#CORE_INCS=\"\$CORE_INCS /usr/include/fastdfs /usr/include/fastcommon/\"#g" /usr/local/fast/fastdfs-nginx-module/src/config
cat /usr/local/fast/fastdfs-nginx-module/src/config | grep CORE_INCS
## 修改之后
CORE_INCS="$CORE_INCS /usr/include/fastdfs /usr/include/fastcommon/"

## Nginx编译添加fastdfs模块
tar zxvf /usr/local/software/nginx-1.6.2.tar.gz -C /usr/local/
cd /usr/local/nginx-1.6.2 && ./configure --add-module=/usr/local/fast/fastdfs-nginx-module/src/ && make && make install

## 复制fastdfs-nginx-module中的配置文件,到/etc/fdfs目录中
cp /usr/local/fast/fastdfs-nginx-module/src/mod_fastdfs.conf /etc/fdfs/
cat /etc/fdfs/mod_fastdfs.conf | grep connect_timeout
cat /etc/fdfs/mod_fastdfs.conf | grep tracker_server
cat /etc/fdfs/mod_fastdfs.conf | grep url_have_group_name
cat /etc/fdfs/mod_fastdfs.conf | grep store_path0
sed -i "s#connect_timeout=2#connect_timeout=10#g" /etc/fdfs/mod_fastdfs.conf
sed -i "s#tracker_server=tracker:22122#tracker_server=192.168.0.130:22122#g" /etc/fdfs/mod_fastdfs.conf
sed -i "s#url_have_group_name = false#url_have_group_name = true#g" /etc/fdfs/mod_fastdfs.conf
sed -i "s#store_path0=/home/yuqing/fastdfs#store_path0=/fastdfs/storage#g" /etc/fdfs/mod_fastdfs.conf
## 修改之后
## connect_timeout=10
## tracker_server=192.168.0.130:22122
## url_have_group_name = true
## store_path0=/fastdfs/storage

##  复制FastDFS里的2个文件，到/etc/fdfs目录中
cd /usr/local/fast/fastdfs-5.11/conf/ && cp http.conf mime.types /etc/fdfs/
ln -s /fastdfs/storage/data/ /fastdfs/storage/data/M00

## 修改Nginx配置文件
cat /usr/local/nginx/conf/nginx.conf | grep localhost
sed -i "s#80;#8083;#g" /usr/local/nginx/conf/nginx.conf
sed -i "s#localhost#192.168.0.130#g" /usr/local/nginx/conf/nginx.conf
sed -i "43,46c location ~/group([0-9])/M00 {\n\t\tngx_fastdfs_module;\n\t}\n" /usr/local/nginx/conf/nginx.conf
cat -n /usr/local/nginx/conf/nginx.conf | head -n 61
## 在Nginx的logs目录下创建nginx.pid文件
touch /usr/local/nginx/logs/nginx.pid
echo "/usr/local/nginx/sbin/nginx" >> /etc/rc.d/rc.local
cat /etc/rc.d/rc.local

## 防火墙开启端口
firewall-cmd --add-port=8083/tcp --permanent
firewall-cmd --reload
firewall-cmd --list-ports

## 重新上传图片，浏览器访问
/usr/local/nginx/sbin/nginx 
/usr/bin/fdfs_test /etc/fdfs/client.conf upload /usr/local/software/1001.png