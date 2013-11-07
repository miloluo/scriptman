#!/usr/bin/perl -w
# Purpose: From the Oracle(OSW) Tools, IOstat does not support generate gif of disk io, so this script is used to generate the disk gif, simple by this script.
# Author: Milo Luo 
# Date: Nov. 8 2013
#
# Date          Modifier      Comments
# ------------- ------------- -----------------------------------------------------
#
#
#
#
#
#
use strict;
use Win32::OLE qw(in with);
use Win32::OLE::Const 'Microsoft Excel';

$Win32::OLE::Warn = 3;    # die on errors...

# Define the iostat data filename in HPUX
#my $fname="test2_iostat_13.11.05.1300.dat";
#my $fname="test2_iostat_13.11.05.1400.dat";
#my $fname="test2_iostat_13.11.05.1200.dat";
my $fname=$ARGV[0];

my %mydisk = (
	"disk3"  => 0,
	"disk5"  => 0,
	"disk19" => 0,
	"disk20" => 0,
	"disk21" => 0,
	"disk24" => 0,
	"disk25" => 0
);


my $cnt = 0;

# line contents
my $line = "";
my $minus ="";

# if it's the init step or not
my $init_flag = 0;

# begin column
my $col=1;

# get already active Excel application or open new
my $Excel = Win32::OLE->GetActiveObject('Excel.Application')
    	|| Win32::OLE->new('Excel.Application', 'Quit');  

# open Excel file
my $Book = $Excel->Workbooks->Open("h:/data/excel_research/test1.xls"); 
my $Sheet = $Book->Worksheets(1);


# Open the iostat file and begin read and filter data
if (open(FH, "< $fname") )
{

	# Begin fill data
	while ($line = <FH>) { 
	        $cnt += 1;
		print "Processing $cnt lines.\n";
		if ($line =~ m/\d{2}:\d{2}:\d{2}/ && $init_flag == 0){

			### init the colmun title
   			$Sheet->Cells(2,$col)->{'Value'}="disk3";
   			$Sheet->Cells(3,$col)->{'Value'}="disk5";
   			$Sheet->Cells(4,$col)->{'Value'}="disk19";
   			$Sheet->Cells(5,$col)->{'Value'}="disk20";
   			$Sheet->Cells(6,$col)->{'Value'}="disk21";
   			$Sheet->Cells(7,$col)->{'Value'}="disk24";
   			$Sheet->Cells(8,$col)->{'Value'}="disk25";
			$col += 1;
			$init_flag=1;
			$minus = (split(/\s+/,$line))[4];
		}
		elsif ($line =~ m/\d{2}:\d{2}:\d{2}/ && $init_flag == 1){
			# First flush the former result
   			$Sheet->Cells(1,$col)->{'Value'}="$minus";
   			$Sheet->Cells(2,$col)->{'Value'}="$mydisk{'disk3'}";
   			$Sheet->Cells(3,$col)->{'Value'}="$mydisk{'disk5'}";
   			$Sheet->Cells(4,$col)->{'Value'}="$mydisk{'disk19'}";
   			$Sheet->Cells(5,$col)->{'Value'}="$mydisk{'disk20'}";
   			$Sheet->Cells(6,$col)->{'Value'}="$mydisk{'disk21'}";
   			$Sheet->Cells(7,$col)->{'Value'}="$mydisk{'disk24'}";
   			$Sheet->Cells(8,$col)->{'Value'}="$mydisk{'disk25'}";
			$col += 1;
			$minus = (split(/\s+/,$line))[4];
		}
		elsif ($line =~ m/disk/) {
			$mydisk{(split(/\s+/,$line))[1]} = (split(/\s+/,$line))[2];
			
		}
		else {
	        			 	
		}

	}	
	$Sheet->Cells(1,$col)->{'Value'}="$minus";
	$Sheet->Cells(2,$col)->{'Value'}="$mydisk{'disk3'}";
	$Sheet->Cells(3,$col)->{'Value'}="$mydisk{'disk5'}";
	$Sheet->Cells(4,$col)->{'Value'}="$mydisk{'disk19'}";
	$Sheet->Cells(5,$col)->{'Value'}="$mydisk{'disk20'}";
	$Sheet->Cells(6,$col)->{'Value'}="$mydisk{'disk21'}";
	$Sheet->Cells(7,$col)->{'Value'}="$mydisk{'disk24'}";
	$Sheet->Cells(8,$col)->{'Value'}="$mydisk{'disk25'}";
	close(FH);
        # clean up after ourselves
	$Book -> Save;
        $Book->Close;
}
else
{
	printf("File doesn't exist!!!!");
	close(FH);
        # clean up after ourselves
        $Book->Close;
	exit -2;
}
