#!/usr/bin/perl -w
# Program name: IOSTAT PARSER for hpux
# Purpose: From the Oracle(OSW) Tools, IOstat does not support generate gif of disk io, so this script is used to generate the disk gif, simple by this script.
# Author: Milo Luo 
#
# Date          Modifier      Comments
# ------------- ------------- -----------------------------------------------------
# Nov.08 2013   Milo Luo      Initialize the script.
# Nov.15 2013   Milo Luo      Replace variables with hard code on disks.
# Nov.16 2013   Milo Luo      Add the configure file.
# Nov.17 2013   Milo Luo      Add auto-plotted trend lines.
# Nov.18 2013   Milo Luo      Add handling to config file start with '#' and spaces before contents.
# Nov.25 2013   Milo Luo      Add range selected and optimize the structure of  script
#
#
#

use strict;
use diagnostics;
use Excel::Writer::XLSX;
use Excel::Writer::XLSX::Utility;
use feature qw(switch);

############ Variables using handling iostat file and excel file ##################
# line contents
my $line = "";

# Define the disks you care about on iostat file.
my %mydisk;

# time lines
my $minus ="";

# if it's the init step or not
my $init_flag = 0;

# begin column
my $col=0;

# Define 2nd row as real iostat data write to , because row #1 will always be time lines
my $rows = 2;

# Iostat file row count
my $cnt = 0;

#######################################
# Define range flag
## 0 -- no start point
## 1 -- in
## 2 -- out
#######################################

my $range_flag = 0;
my $begin_range = 'ALL DATA'; 
my $end_range = 'ALL DATA';

################################# END ##############################################



############################ Read config file ######################################
# Define the config file 
my $conf="config.cfg";

# Read configure file to get which disks you care about
open(FH1,"< $conf") or die "Can NOT open configure file: $conf !";

# Read the configure file  
while ($line = <FH1>) {
	next if ($line =~ m/^\s*$/);
	next if ($line =~ m/^#$/);
	#if ((split(/\s+/,$line))[1] =~ m/disk/) {
	if ($line =~ m/^\s+disk/) {
		$mydisk{(split(/\s+/,$line))[1]} = 0;
	}elsif ($line =~ m/^disk/) {
		$mydisk{(split(/\s+/,$line))[0]} = 0;
	}

} 

# Close File Header
close(FH1);
################################## END #############################################



######################### Get diskname & size ######################################
# Aquired the hash size and diskname
my $size += scalar keys %mydisk;
my @diskname = keys %mydisk;

################################# End ##############################################


################### Read iostat file from command line ############################
# Define the iostat data filename in HPUX
my $fname=$ARGV[0];
################################# END #############################################


$line = "";
$cnt = 0;

print "\n########################\n";
print " Program Menu "; 
print "\n########################\n";
print "1. Generate all range gaph of current iostat file.\n";
print "2. Generate specify range gaph of current iostat file.\n";
print "Choice: ";

# Get customer input
chomp(my $choice=<STDIN>);

print "\nYour Choice: [$choice] \n";
# Identified disks
print "\n**********************\n";
print "Recongize disk(s): \n";
print "**********************\n";

for ($cnt=0;$cnt < $size; $cnt += 1) {
    print "$diskname[$cnt] \n";
}
print "**********************\n\n";

# Get User handle way
given($choice){
    when(1) { }
    when(2) { 
        print "\nPlease input the begin date format: (Nov 11 20:00)\n"; 
        # Remove the last new line chraracter
        chomp ($begin_range=<STDIN>);

        print "Please input the end date format: (Nov 11 20:00)\n"; 
        # Remove the last new line chraracter
        chomp ($end_range=<STDIN>);

        # Formatted range value
        $begin_range = ucfirst $begin_range;
        $end_range = ucfirst $end_range;

        # Open the iostat file for check the begin date range 
        open(IOFILE, "< $fname") or die("Can't Open iostat file $fname !");
	
        my @match_begin = grep /^zzz.*$begin_range.*/, <IOFILE>;
        my $begin_cnt = @match_begin;
        close(IOFILE);
        
        # Open the iostat file for check the ending date range 
        open(IOFILE, "< $fname") or die("Can't Open iostat file $fname !");
        my @match_end = grep /^zzz.*$end_range.*/, <IOFILE>;
        my $end_cnt = @match_end;
        close(IOFILE);

        # Check about the occurance of the begin and ending range 
        # if both ranges are not identical
        if ($begin_cnt != 1 && $end_cnt != 1) {
	
            # print begin flag matching lines
            print "\n++++++++++++++++++++++++++++++++++++++++++\n";
            print "Error ocurr!\n";
            print "++++++++++++++++++++++++++++++++++++++++++\n";
            print "==> Begin count: $begin_cnt\n";
	        print "Begin flag matching those lines:\n";
	        print @match_begin;

	        print "\n++++++++++++++++++++++++++++++++++++++++++\n";
	        # print end flag matching lines
	        print "==> End count: $end_cnt\n";
	        print "End flag matching those lines:\n";
	        print @match_end;

	        exit -1;

        # if begin range are not identical
        }elsif ($begin_cnt != 1) {

	        # print begin flag matching lines
	        print "++++++++++++++++++++++++++++++++++++++++++\n";
	        print "Error ocurr!\n";
	        print "++++++++++++++++++++++++++++++++++++++++++\n";
	        print "==> Begin count: $begin_cnt\n";
	        print "Begin flag matching those lines:\n";
	        print @match_begin;
	        exit -2;

        # if ending range are not identical
        }elsif ($end_cnt != 1) {

	        # print end flag matching lines
	        print "\n++++++++++++++++++++++++++++++++++++++++++\n";
	        print "Error ocurr!\n";
	        print "++++++++++++++++++++++++++++++++++++++++++\n";
	        print "==> End count: $end_cnt\n";
	        print "End flag matching those lines:\n";
	        print @match_end;
	        exit -3;

        }else{
            print "Ranges seems to be ok!!!\n";	
            print "Match begin line: ", @match_begin;	
            print "Match end line:   ", @match_end;	
            print "\nStarting Analyzing...\n";
            }
       }	
       default { print "\nInput error!\n"; }
}


####################### Open Excel to load data #####################################
# Open a Excel (xlsx format) for resultset, make sure this file is not opening.
my $Excel =  Excel::Writer::XLSX->new('test_grep.xlsx');
my $Sheet =  $Excel-> add_worksheet();
################################## End #############################################

# Open the iostat file to fill data
open(IOFILE, "< $fname") or die("Can't Open iostat file $fname !");

# Begin fill data
print "Starting fill data into excel!\n";
while ($line = <IOFILE>) { 
        $cnt += 1;
		#print "Processing $cnt lines.\n";
		next if ($line =~ m/^\s*$/);

        # Set flag for begin and end 
		if ($choice == 1 || ($line =~ m/^zzz.*$begin_range.*$/ && $range_flag == 0) ){
            $range_flag = 1;
        }elsif($line =~ m/^zzz.*$end_range.*$/ && $range_flag == 1 && $choice == 2){
            # Determine if stop lookup iostat file immediate
            $range_flag = 2;
            last;
        }
		
		if ($line =~ m/\d{2}:\d{2}:\d{2}/ && $init_flag == 0 && $range_flag > 0){
			# Initialize the disk names
			for ($rows=1; $rows<= $size; $rows++) {
   				$Sheet->write($rows,$col,$diskname[$rows-1]);
			}
			$col += 1;
			$init_flag=1;
			$minus = (split(/\s+/,$line))[4];
		}
		elsif ($line =~ m/\d{2}:\d{2}:\d{2}/ && $init_flag == 1 && $range_flag > 0){
			# First flush the former result
   			$Sheet->write(0,$col,$minus);
			#print "$minus\n";

			for ($rows=1; $rows<= $size; $rows++) {
   				$Sheet->write($rows,$col,$mydisk{$diskname[$rows-1]});
			}
			$col += 1;
			$minus = (split(/\s+/,$line))[4];
		}
		elsif ($line =~ m/disk/) {
			# store a group of values
			if ( exists($mydisk{(split(/\s+/,$line))[1]}) ) {
				$mydisk{(split(/\s+/,$line))[1]} = (split(/\s+/,$line))[2];
			}
			
		}


}	

# last flush
$Sheet->write(0,$col,$minus);
for ($rows=1; $rows<= $size; $rows++) {
  		$Sheet->write($rows,$col,$mydisk{$diskname[$rows-1]});
}

# Close the iostat file
close(IOFILE);


######################## Plotted the graph ###################################

# Add a chart object
my $chart = $Excel -> add_chart( type  => 'line', embedded => 1);
my $colname = xl_col_to_name($col);
#print "\n","column name is ", $colname, "\n";
print "Starting plot the graph!\n";

# Add a chart title and some axis labels.
$chart -> set_title ( name => 'Results of iostat analysis on hpux' );
$chart -> set_x_axis( name => 'Time Lines' );
$chart -> set_y_axis( name => 'Kilobytes Per Second(bps)' );

# Set an Excel chart style. Colors with white outline and shadow.
#$chart -> add_series( values => '=Sheet1!$B$2:$E$2', trendline => {type => 'linear'} );
$chart -> set_style( 2 );
for ($rows=1; $rows<= $size; $rows++) {
		#$chart -> add_series( name => 'disk1', categories => 'Sheet1!$A$1:$ASC$1', values => '=Sheet1!$B$2:$ASC$2' );
		my $tmp_rl=$rows+1;
		$chart -> add_series( name => $diskname[$rows-1], categories => 'Sheet1!$B$1:$'.$colname.'$'.$rows, values => '=Sheet1!$B'.'$'.$tmp_rl.':$'.$colname.'$'.$tmp_rl );
		#print $diskname[$rows-1],"\n";
}

# Insert the chart into the worksheet (with an offset).
#$worksheet->insert_chart( 'D2', $chart, 25, 10 );
$Sheet ->insert_chart( 'D'.($size+5), $chart,0,0,1.8,1.5 );
# clean up after ourselves
$Excel -> close();

print "Complet the Mission!\n";
	
###################### End Program ##################################
