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
#
#


use strict;
#use  diagnostics;
#use Win32::OLE qw(in with);
#use Win32::OLE::Const 'Microsoft Excel';
#$Win32::OLE::Warn = 3;    # die on errors...
use Excel::Writer::XLSX;
use Excel::Writer::XLSX::Utility;


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
################################# END ##############################################



################### Read iostat file from command line #############################
# Define the iostat data filename in HPUX
my $fname=$ARGV[0];
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
################################## END ##############################################



######################### Get diskname & size #######################################
# Aquired the hash size and diskname
my $size += scalar keys %mydisk;
my @diskname = keys %mydisk;

# Identified disks
print "\n**********************\n";
print "Recongize disk(s): \n";
print "**********************\n";

for ($cnt=0;$cnt < $size; $cnt += 1) {
      print "$diskname[$cnt] \n";
}
################################# End ###############################################




####################### Open Excel to load data #####################################
# Open a Excel (xlsx format) for resultset, make sure this file is not opening.
my $Excel =  Excel::Writer::XLSX->new('iostat_result1.xlsx');
my $Sheet =  $Excel-> add_worksheet();
################################## End ##############################################




############################ Read iostat file and load bps into xlsx file, then plot it ########################################

# Open the iostat file and begin read and load data
if ( open(FH2, "< $fname") )
{
	$line = "";
	$cnt = 0;

	######################## Load bps data from iostat into xlsx file ###################################
	
	# Begin fill data
	while ($line = <FH2>) { 
	        $cnt += 1;
		#print "Processing $cnt lines.\n";
		next if ($line =~ m/^\s*$/);
		
		if ($line =~ m/\d{2}:\d{2}:\d{2}/ && $init_flag == 0){
			# Initialize the disk names
			for ($rows=1; $rows<= $size; $rows++) {
   				$Sheet->write($rows,$col,$diskname[$rows-1]);
			}
			$col += 1;
			$init_flag=1;
			$minus = (split(/\s+/,$line))[4];
		}
		elsif ($line =~ m/\d{2}:\d{2}:\d{2}/ && $init_flag == 1){
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

	######################## Plotted the graph ###################################

	# Add a chart object
	my $chart = $Excel -> add_chart( type  => 'line', embedded => 1);
	my $colname = xl_col_to_name($col);
	#print "\n","column name is ", $colname, "\n";

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
	close(FH2);

        # clean up after ourselves
	$Excel -> close();
}
else
{
	printf("File doesn't exist!!!!");
	close(FH2);
        # clean up after ourselves
	$Excel ->close();
	exit -2;
}

############################### End Program ########################################


