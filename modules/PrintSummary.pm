# $Id: PrintSummary.pm,v 1.1.1.1 2004/03/03 17:12:46 pmclean Exp $

# Copyright (c) 2004 Philippe McLean <pmclean@users.sourceforge.net>
# All rights reserved.  This program is free software; you can
# redistribute it and/or modify it under the same terms as Perl
# itself.

# Permission has kindly been given to me by Zero-Knowledge Systems
# Inc., to make this software available under the artistic license.

# Generate a summary of stage executions

my $summary_file = shift;
my $default_summary_file = "/tmp/morpheus-summary.log";

my $log_open = 1;
if (!open(SUMMFILE,">$summary_file")) {
  Logger::warning("Could not open $summary_file for writing (returned $!) - writing to $default_summary_file");
  if (!open(SUMMFILE,">$default_summary_file")) {
    Logger::warning("Could not open $default_summary_file for writing");
    $log_open = 0;
  } 
    
}
 
my $stage_executions = $context->get_morpheus()->get_stage_executions();
my %return_codes;
%return_codes = ('0' => 'PASSED',
                 '1' => 'FAILED',
                 '5' => 'UNTESTED',
                 '101' => 'FATAL'
                );

foreach my $execution (@{$stage_executions}) {
  #print Dumper($execution);
  my $stage = $execution->get_stage();
  my $host = $execution->get_host();
  my $name = $host->get_name();
  my $hostname = $host->get_hostname();
  my $location = $stage->get_location();

  my $status = $return_codes{$execution->get_exit_code()};
  my $message;
  if ($location eq "remote") {
    $message = ("stage " . $stage->get_stage_number()->print() . ":" . $stage->get_description() . " on " . $hostname . " (" . "$name" . ")... " . $status);
  } else {
    $message = ("stage " . $stage->get_stage_number()->print() . ":" . $stage->get_description() . "... " . $status);
  }

  Logger::informational("$message");
  if ($log_open == 1) {
    print SUMMFILE "$message\n";
  }

}

if ($log_open == 1) {
  close(SUMMFILE);
}

1;

