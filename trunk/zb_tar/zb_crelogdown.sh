cd /zbbak/cebip 
if [ -f /zbbak/cebip/dir.list ]
then
while read LINE
do
mkdir -p $LINE
done </zbbak/cebip/dir.list
echo "目录创建成功!"
else
echo "/zbbak/cebip/dir.list文件不存在,目录创建失败!"
fi
