cd /zbbak/cebip 
if [ -f /zbbak/cebip/dir.list ]
then
while read LINE
do
mkdir -p $LINE
done </zbbak/cebip/dir.list
echo "Ŀ¼�����ɹ�!"
else
echo "/zbbak/cebip/dir.list�ļ�������,Ŀ¼����ʧ��!"
fi
