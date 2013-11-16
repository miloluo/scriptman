#!/usr/bin/perl -w
use strict;
use Win32::OLE qw(in with);
use Win32::OLE::Const 'Microsoft Excel';

$Win32::OLE::Warn = 3;          # die on errors...

# Define the iostat data filename in HPUX
my $fname="test2_iostat_13.11.05.1300.dat";
my %mydisk = (
	"disk3" => 0,
	"disk5" => 0,
	"disk19" => 0,
	"disk20" => 0,
	"disk21" => 0,
	"disk24" => 0,
	"disk25" => 0
);


my $cnt = 0;
my $line = "";
my $minus ="";

print keys %mydisk;

# Open the iostat file and begin read and filter data
if (open(FH, "< $fname") )
{
	while ($line = <FH>) { 
	        $cnt += 1;
		if ($line =~ m/^\n$/){
			# First flush the former result
			print "####################\n";
			print $minus,"\n" ;
			print "$mydisk{'disk3'}\n";
			print "$mydisk{'disk5'}\n";
			print "$mydisk{'disk19'}\n";
			print "$mydisk{'disk20'}\n";
			print "$mydisk{'disk21'}\n";
			print "$mydisk{'disk24'}\n";
			print "$mydisk{'disk25'}\n";
			# Then clear a flag	
		}
		elsif ($line =~ m/\d{2}:\d{2}:\d{2}/){
			$minus = (split(/\s+/,$line))[4];
		}
		elsif ($line =~ m/disk/) {
			my @str2 = split(/\s+/,$line);	
			#print  $str2[1],"-> ",$str2[2],"\n";
			$mydisk{$str2[1]} = $str2[2];
			
		}
		else {
	        			 	
		}

	}	
	close(FH);
}
else
{
	printf("File doesn't exist!!!!");
	close(FH);
	exit -2;
}

