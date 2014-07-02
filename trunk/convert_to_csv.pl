#####################################################################
# Use this script you can translate the specific file into csv file.#
#####################################################################
# Author: Milo Luo
# Create: 2014.02.12
# Maintain log:
# Date       Modifier             Comments
# ---------- -------------------  ---------------------------------------------------
# 2014.02.12 Milo Luo             Init script
# 2014.02.14 Milo Luo             Improve auto detect current log;
#                                 Change generated csv file name rule;
#                                 Change the match target data rule;
#
#
#!/usr/bin/perl -w
use strict;
use Cwd;
use Data::Dumper qw(Dumper);
#use  diagnostic



#####################read current .txt files#####################


#my $curdir = "F:/项目/客户/x_新疆建行/服务/2014_02_10_业务用户表的统计/table_monitor/sqlldr1";
my $curdir = getcwd;

print "$curdir\n";

opendir(DIR, $curdir) or die $!;
my @dots 
     = grep { 
         /.txt$/             # Begins with a period
  && -f "$curdir/$_"   # and is a file
} readdir(DIR);

# Loop through the array printing out the filenames

print "=============================\n";
print "Handle file list: \n";
print "=============================\n";
foreach my $file (@dots) {
  #####################read the file and output the csv##################
#=pod1
  open(FH1,"< $file") or die "Can NOT open file: $file !";
  my @format_name = split /[._]/, $file;
  my $csvfile = $format_name[1]."_".substr($format_name[2],4,8)."_".$format_name[0].".".$format_name[4];
  #print "$csvfile\n";
  $csvfile =~ s/.txt$/.csv/g;
  #$csvfile =~ s/.txt$/.csv/g;
  #print $format_name[1],"_",substr($format_name[2],4,8),"_",$format_name[0],".",$format_name[4];

  open(CSV,">> $csvfile") or die "Can NOT open file: $csvfile !";
  print $file,"  has convered to   ",$csvfile, " !\n";

  my $split_cnt=0;

  # Read the configure file  
=cut
=pod
  while (my $line = <FH1>) {
	next if ($line =~ m/^\s+$/);
	if ( $split_cnt==0 && $line =~ m/^----/) {
        $split_cnt=1;
	}
    elsif ( $split_cnt==2 && $line =~ m/rows selected./ ) {
        $split_cnt=3;
    }
    elsif ( $split_cnt==1 && $line =~ m/^----/){
        $split_cnt=2;
    }
    elsif ( $split_cnt==2) {
        $line =~ s/\s+/,/g;
        $line =~ s/,$//g;
        print CSV $line,"\n";
    }

 } 
=cut
  # Match the first "SQL> SELECT " OR " SQL> select ", then "----"
  while (my $line = <FH1>) {
	next if ($line =~ m/^\s+$/);
	if ( $split_cnt==0 && $line =~ m/^SQL> select / || $line =~ m/^SQL> SELECT /) {
        $split_cnt=1;
	}
    elsif( $split_cnt == 1 && $line =~ m/----/){
        $split_cnt=2
    
    }
    elsif ( $split_cnt==2 && $line =~ m/rows selected./ ) {
        $split_cnt=3;
    }
    elsif ( $split_cnt==2) {
        $line =~ s/\s+/,/g;
        $line =~ s/,$//g;
        print CSV $line,"\n";
    }

 } 
close(FH1);
close(CSV);


}
print "=============================\n";

closedir(DIR);

