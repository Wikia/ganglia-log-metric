#!/usr/bin/perl

use strict;
use warnings;
use Getopt::Long;
my $GMETRIC_BIN = "/usr/bin/gmetric";
my $location = 0;

my $log_file;
my @log_patterns;

my $result = GetOptions ( "pattern|p=s" => \@log_patterns,
                        "log|l=s" =>\$log_file);

if ( ! $log_file || scalar(@log_patterns) < 1 ) {
   print "requires -l and -p arguements\n";
   exit 1;
}

my $log_file_no_slash = $log_file;
$log_file_no_slash =~ s/\//_/g;

my @log_path = split(/\//, $log_file);
my $log_file_short = $log_path[-1];
my $last_location = "/tmp/locaiton_" . $log_file_no_slash;

if ( -e $last_location) {
   open (LOC, $last_location);
   while (<LOC>) {
      chomp($_);
      $location = $_;
   }
   close LOC;
}

open(LOG, $log_file);

my $current_size = -s $log_file;

if ( $current_size >= $location) {
   seek(LOG, $location, 0 );
}

my $log_patterns_count = {};
foreach my $log_pattern (@log_patterns) {
   $log_patterns_count->{$log_pattern}=0;
}
my $host_log_patterns = {};

while (<LOG>) { 

foreach my $log_pattern (@log_patterns) {
   if( $_ =~ /$log_pattern/){
     $log_patterns_count->{$log_pattern}++;
     my @log_line = split(/ /, $_);

     if( exists $host_log_patterns->{$log_line[4]}->{$log_pattern} ){
        $host_log_patterns->{$log_line[4]}->{$log_pattern}++; 
     } else {
        $host_log_patterns->{$log_line[4]}->{$log_pattern}=1;
     }
  }
}
}
   
   
my $current_location = tell(LOG);
open (LOC2, ">", $last_location) or die $@; 
print LOC2 $current_location;
close(LOC2);

foreach my $log_pattern (@log_patterns) {
   my $log_pattern_no_space = $log_pattern;
   $log_pattern_no_space =~ s/\s/_/g;
   system $GMETRIC_BIN .  " -g " . $log_file_short  . " -n " . $log_pattern_no_space . " -v " . $log_patterns_count->{$log_pattern} . " -u count -t int32\n";
}

