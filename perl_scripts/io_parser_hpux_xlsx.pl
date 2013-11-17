#!/usr/bin/perl -w
# Purpose: From the Oracle(OSW) Tools, IOstat does not support generate gif of disk io, so this script is used to generate the disk gif, simple by this script.
# Author: Milo Luo 
# Date: Nov. 8 2013
#
# Date          Modifier      Comments
# ------------- ------------- -----------------------------------------------------
# Nov.08 2013   Milo Luo      Initialize the script.
# Nov.15 2013   Milo Luo      Replace variables with hard code on disks.
# Nov.16 2013   Milo Luo      Add the configure file.
# Nov.17 2013   Milo Luo      Add auto-plotted trend lines.
#
#


use strict;
#use  diagnostics;
use Win32::OLE qw(in with);
use Win32::OLE::Const 'Microsoft Excel';
use Excel::Writer::XLSX;
use Excel::Writer::XLSX::Utility;

$Win32::OLE::Warn = 3;    # die on errors...

# Define the iostat data filename in HPUX
my $fname=$ARGV[0];

# Define the config file 
my $conf="H:/data/excel_research/config.cfg";

# line contents
my $line = "";

# Define the disks you care about on iostat file.
my %mydisk;

# Read configure file to get which disks you care about
open(FH1,"< $conf") or die "Can NOT open configure file: $conf !";

# Read the configure file  
while ($line = <FH1>) {
	next if ($line =~ m/^\s*$/);
	if ((split(/\s+/,$line))[1] =~ m/disk/) {
		$mydisk{(split(/\s+/,$line))[1]} = 0;
	}

} 

# Close File Header
close(FH1);

# Iostat file row count
my $cnt = 0;


# time lines
my $minus ="";

# if it's the init step or not
my $init_flag = 0;

# begin column
my $col=0;

# Open a Excel (xlsx format) for resultset.
my $Excel =  Excel::Writer::XLSX->new('iostat_result1.xlsx');
my $Sheet =  $Excel-> add_worksheet();

# Aquired the hash size and diskname
my $size += scalar keys %mydisk;
my @diskname = keys %mydisk;

#print @diskname;

# Define 2nd row as real iostat data write to , because row #1 will always be time lines
my $rows = 2;

# Open the iostat file and begin read and filter data
if ( open(FH2, "< $fname") )
{
	$line = "";

	# Begin fill data
	while ($line = <FH2>) { 
	        $cnt += 1;
		print "Processing $cnt lines.\n";
		next if ($line =~ m/^\s*$/);
		
		if ($line =~ m/\d{2}:\d{2}:\d{2}/ && $init_flag == 0){

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
		else {
	        			 	
		}

	}	

	# last flush
   	$Sheet->write(0,$col,$minus);

	for ($rows=1; $rows<= $size; $rows++) {
   		$Sheet->write($rows,$col,$mydisk{$diskname[$rows-1]});
	}

	# Add a chart object
	my $chart = $Excel -> add_chart( type  => 'line', embedded => 1);
	my $colname = xl_col_to_name($col);
	print "\n","column name is ", $colname, "\n";

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
		print $diskname[$rows-1],"\n";
	}

	# Insert the chart into the worksheet (with an offset).
	#$worksheet->insert_chart( 'D2', $chart, 25, 10 );
	$Sheet ->insert_chart( "D10", $chart, 25, 10 );
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


