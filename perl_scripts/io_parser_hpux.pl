#!/usr/bin/perl -w
# Purpose: From the Oracle(OSW) Tools, IOstat does not support generate gif of disk io, so this script is used to generate the disk gif, simple by this script.
# Author: Milo Luo 
# Date: Nov. 8 2013
#
# Date          Modifier      Comments
# ------------- ------------- -----------------------------------------------------
# Nov.08 2013   Milo Luo      Initialize the script.
# Nov.15 2013   Milo Luo      Replace variables with hard code on disks.
#
#
#


use strict;
use Win32::OLE qw(in with);
use Win32::OLE::Const 'Microsoft Excel';

$Win32::OLE::Warn = 3;    # die on errors...

# Define the iostat data filename in HPUX
my $fname=$ARGV[0];

# Define the config file 
my $conffile="H:/data/excel_research/config.cfg";

# Define the disks you care about on iostat file.
my %mydisk;

# Red configure file to get which disks you care about
if (open(FH1,"< $conffile") or die "Can NOT open configure file: $conffile !")
{
	# Read the configure file  
	while (my $line = <FH1>) {
		if ((split(/\s+/,$line))[1] =~ m/disk/) {
			$mydisk{(split(/\s+/,$line))[1]} = 0;
		}	
	
	} 

	# Close File Header
	close(FH1);
}

# Iostat file row count
my $cnt = 0;

# line contents
my $line = "";

# time lines
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

# Aquired the hash size and diskname
my $size += scalar keys %mydisk;
my @diskname = keys %mydisk;

# Define 2nd row as real iostat data write to , because row #1 will always be time lines
my $rows = 2;

# Open the iostat file and begin read and filter data
if (open(FH2, "< $fname") )
{

	# Begin fill data
	while ($line = <FH2>) { 
	        $cnt += 1;
		print "Processing $cnt lines.\n";
		if ($line =~ m/\d{2}:\d{2}:\d{2}/ && $init_flag == 0){

			for ($rows=2; $rows<= $size+1; $rows++) {
   				$Sheet->Cells($rows,$col)->{'Value'}=$diskname[$rows-2];
			}
			$col += 1;
			$init_flag=1;
			$minus = (split(/\s+/,$line))[4];
		}
		elsif ($line =~ m/\d{2}:\d{2}:\d{2}/ && $init_flag == 1){
			# First flush the former result
   			$Sheet->Cells(1,$col)->{'Value'}="$minus";

			for ($rows=2; $rows<= $size+1; $rows++) {
				$Sheet->Cells($rows,$col)->{'Value'}="$mydisk{$diskname[$rows-2]}";
			}
			$col += 1;
			$minus = (split(/\s+/,$line))[4];
		}
		elsif ($line =~ m/disk/) {
			if ( exists($mydisk{(split(/\s+/,$line))[1]}) ) {
				$mydisk{(split(/\s+/,$line))[1]} = (split(/\s+/,$line))[2];
				
			}
			
		}
		else {
	        			 	
		}

	}	
	$Sheet->Cells(1,$col)->{'Value'}="$minus";

	for ($rows=2; $rows<= $size+1; $rows++) {
		$Sheet->Cells($rows,$col)->{'Value'}="$mydisk{$diskname[$rows-2]}";
	}
	close(FH2);
        # clean up after ourselves
	$Book -> Save;
        $Book->Close;
}
else
{
	printf("File doesn't exist!!!!");
	close(FH2);
        # clean up after ourselves
        $Book->Close;
	exit -2;
}
