#¸üÐÂSEQUENCE
TodayDate=`date +'%u'`
sqlplus -s pbcebdb/pbcebdb <<!
drop sequence PBJOURNO;
@seq_$TodayDate.sql;
exit 
!
