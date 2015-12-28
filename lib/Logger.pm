#!/usr/bin/perl -w


# Copyright (c) 2004 Philippe McLean <pmclean@users.sourceforge.net>
# All rights reserved.  This program is free software; you can
# redistribute it and/or modify it under the same terms as Perl
# itself.

# Permission has kindly been given to me by Zero-Knowledge Systems
# Inc., to make this software available under the artistic license.

# $Id: Logger.pm,v 1.1.1.1 2004/03/03 17:12:46 pmclean Exp $ 

# Package for atomically emitting log messages to a log file and/or
# the console.

# Three kinds of messages are supported, informational, warning, and
# error.

package Logger;

use Carp;
use Misc;
use Error_Code;

use strict;

BEGIN {
  # default
  $Logger::log_file = "/tmp/log.$$";
}

# names that appear in the log file

my $abbreviated_names = {
                         'informational' => 'I',
                         'warning' => 'W',
                         'error' => 'E',
                         'fatal' => 'F',
                        };

# names that appear on the console

my $long_names = {
                  'informational' => '',
                  'warning' => 'WARNING',
                  'error' => 'ERROR',
                  'fatal' => 'FATAL',
                 };

# this crap is deprecated

my @month_names = ('Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec');
my @day_names = ('Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat');


sub set_log_file {
  $Logger::log_file = shift;
}

sub _date_string {
  return Misc::date();

  my($date,$month,$day,@now, $year);

  @now = localtime(time);
  $month = $month_names[$now[4]];
  $year = $now[5];
  $year += 1900;
  $day = $day_names[$now[6]];
  $date = sprintf("%s %s %s %02d:%02d:%02d %4.4d",
                  $day, $month, $now[3], $now[2], $now[1], $now[0], $year);

  return $date;
}

#truncate the log file

sub trim_log {
  my $log_file = $Logger::log_file;
  if (!open(ERRLOG, ">$log_file")) {
    warn("Logger could not open log file `$log_file'");
  }
  close(ERRLOG);
}

# write to the log file atomically

sub _write_to_log {
  my($message) = shift;
  my $log_file = $Logger::log_file;

  if (!open(ERRLOG,">>$log_file")) {
    warn("Logger Couldn't open log file `$log_file': `$!', using STDERR \n");
    print STDERR $message;
  } else {
    # don't bother if we aren't root
    if ($> == 0) {
      chmod(0666, $log_file) || die("Couldn't chmod(0666, $log_file): `$!'\n");
    }
    flock(ERRLOG, 2) || die("couldn't lock $log_file: `$!'\n");
    print ERRLOG $message;
    flock(ERRLOG, 8) || die("couldn't unlock $log_file: `$!'\n");
    close(ERRLOG);
  }
}

sub _write_to_console {
  my($message) = shift;
  print "$message";
}

sub _normalize_message {
  my $message = shift;
  confess('undefined message') unless defined $message;
#  $message =~ s/\t/ /mg;
#  $message =~ s/\n$//m;
  return $message;
}

# format a message for the log file
sub _construct_log_message {
  my $type = shift;
  my $message = _normalize_message(shift);
    
  return "[" . Misc::time() .  "] (" . $abbreviated_names->{$type} . ") $0: $message\n";
}

# format a message for the console
sub _construct_console_message {
  my $type = shift;
  my $message = _normalize_message(shift);

  if ($long_names->{$type} ne '') {
    return "[" . Misc::time() .  "] (" . $long_names->{$type} . "): $message\n";
  } else {
    return "[" . Misc::time() .  "] $message\n";
  }     
}

sub _write_message_to_console {
  my($class) = shift;
  my($message) = _normalize_message(shift);

  my $number = 0;
  foreach my $line (split(m/^/m, $message)) {        
    chomp($line);
#    print "NUMBER " . ++$number . "\n";

    _write_to_console(_construct_console_message($class, $line));
  }
  return 0;
}

sub _write_message_to_log {
  my($class) = shift;
  my($message) = _normalize_message(shift);

  foreach my $line (split(/\n/, $message)) {        
    _write_to_log(_construct_log_message($class, $line));
  }
  return 0;
}


# emit an informational message to the console
sub informational_to_console{
  _write_message_to_console('informational', shift);
}

# emit an informational message to both the console and the log file
sub informational {
  my $message = shift;
  _write_message_to_log('informational', $message);
  _write_message_to_console('informational', $message);
}

# emit an informational message
sub informational_to_log_file {
  my $message = shift;
  _write_message_to_log('informational', $message);
}

sub get_longmess {
  $Carp::CarpLevel += 2;
  my @lines = split(/\n/, Carp::longmess());
  $Carp::CarpLevel -= 2;
  return @lines;
}

# emit a warning message
sub warning {
  my $message = shift;

  _write_message_to_log('warning', $message);
#  stack_trace_to_log_file();

  _write_message_to_console('warning', $message);
#  stack_trace_to_console();
}

sub stack_trace_to_log_file {
  foreach my $line (get_longmess()) {
    _write_to_log(_construct_log_message('informational', " $line"));   
  }
}

sub stack_trace_to_console {
  foreach my $line (get_longmess()) {
    _write_to_console(_construct_console_message('informational', " $line"));   
  }
}

# emit an error message
sub error {
  my $message = shift;

  _write_message_to_log('error', $message);
#  stack_trace_to_log_file();

  _write_message_to_console('error', $message);
#  stack_trace_to_console();
}

sub fatal {
  my $message = shift;

  _write_message_to_log('fatal', $message);
#  stack_trace_to_log_file();

  _write_message_to_console('fatal', $message);
#  stack_trace_to_console();

  print "Morpheus terminating with fatal error.\n";

  exit($Error_Code::FATAL); 
}


# emit an error message, and croak
sub error_and_die {
  my($message) = shift;

  _write_message_to_log('error', $message);
  stack_trace_to_log_file();

  _write_message_to_console('error', $message);
  stack_trace_to_console();

  print "Morpheus terminating with fatal error.\n";

  exit($Error_Code::FATAL);
}

# emit an error message, and croak
sub error_stack_trace {
  my($message) = shift;

  _write_message_to_log('error', $message);
  stack_trace_to_log_file();

  _write_message_to_console('error', $message);
  stack_trace_to_console();
}

1;
