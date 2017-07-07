#!/bin/bash

##########################
##         made by roman         ##
##      version 2.2_ftp ver      ##
##########################

hostipaddr=127.0.0.1
#主机IP地址（用以生成文件名）
node=101
#节点号（用以生成文件名）
logsdirectory=/opt/logs
#log文件所在路径
workdirectory=/opt/work
#工作文件保存路径
ftpipaddr=127.0.0.1
#ftp的ip地址
ftpusername=guest
#ftp用户名
ftppassword=123456
#ftp密码
ftpdirectory=/opt/xmls
#上传到ftp的路径
ftpkeydirectory=/opt/xmls/keys
#上传失败的key文件在ftp服务器上的路径
logsready=0
#标记变量

function makexmls()
{
    logsname=`basename $1 .log`
    echo "<?xml version=\"1.0\" encoding=\"UTF-8\"?><BOSS_AUDIT xmlns:xsi=\"http://www.w3.org/2001/XMLSchema-instance\" xsi:noNamespaceSchemaLocation=\"审计文件格式.xsd\">" > $workdirectory/xmls/$logsname.xml
    cat $1 >>  $workdirectory/xmls/$logsname.xml
    echo "</BOSS_AUDIT>" >>  $workdirectory/xmls/$logsname.xml
    zip -j $workdirectory/xmls/$logsname.zip $workdirectory/xmls/$logsname.xml
    rm $workdirectory/xmls/$logsname.xml
    md5sum $workdirectory/xmls/$logsname.zip|cut -d " " -f 1 > $workdirectory/xmls/$logsname.key
}
#生成xml以及zip和md5文件的功能模块

ftp -n<<!
open $ftpipaddr
user $ftpusername $ftppassword
binary
cd $ftpkeydirectory
lcd $workdirectory/faileds
prompt
mget *$hostipaddr*.key
mdelete *$hostipaddr*.key
close
bye
!
#获取上传失败的key

for f in $(find $workdirectory/faileds/*.key -type f); do if [ `expr $(basename $f|cut -b 9-10) \* 60 \+ $(basename $f|cut -b 11-12) \+ 45` -ge `expr $(date "+%H") \* 60 \+ $(date "+%M")` ]; then cp $workdirectory/backuplogs/`basename $f .key`.log $workdirectory/logs; logsready=1; fi; done
for l in $(find $logsdirectory/*/bossLog.* -type f); do if [ -s $1 ]; then mv $l $workdirectory/logs/`date "+%Y%m%d%H%M%S"`$((`date "+%N"`/1000000))"_"$hostipaddr"_"$node.log; logsready=1; else rm -f $1; fi; done
if [ "$logsready" = 0 ]; then exit; fi
#检测是否存在log文件，不存在则推出脚本

for m in $(find $workdirectory/logs/*.log -type f); do
        makexmls $m
done
#搜寻并将log目录下的所有log文件转化为xml格式

ftp -n<<!
open $ftpipaddr
user $ftpusername $ftppassword
binary
cd $ftpdirectory
lcd $workdirectory/xmls
prompt
mput *
close
bye
!
#将转化好的文件上传至ftp服务器上

mv $workdirectory/logs/* $workdirectory/backuplogs
#将本次log文件归档

rm -f $workdirectory/faileds/*
rm -f $workdirectory/xmls/*
#清理临时文件夹

