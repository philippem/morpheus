#!/usr/bin/perl -w


# Copyright (c) 2004 Philippe McLean <pmclean@users.sourceforge.net>
# All rights reserved.  This program is free software; you can
# redistribute it and/or modify it under the same terms as Perl
# itself.

# Permission has kindly been given to me by Zero-Knowledge Systems
# Inc., to make this software available under the artistic license.


# $Id: Misc.pm,v 1.1.1.1 2004/03/03 17:12:46 pmclean Exp $

# Miscellaneous leaf functions and utilities.

package Misc;
use strict;
use Data::Dumper;
use Logger;

my $zone_string = undef;

sub date {
  if (!defined($zone_string)) {
    $zone_string = `date +"%Z"`;
    chomp($zone_string);
    #	$zone_string = 'UTC';
  }

  my @time = localtime();

#  return strftime("%T ", 
#		  $time[0],
#		  $time[1],
#		  $time[2],
#		  $time[3],
#		  $time[4],
#		  $time[5],
#		 );

  return strftime("%Y-%m-%d %T ", 
		  $time[0],
		  $time[1],
		  $time[2],
		  $time[3],
		  $time[4],
		  $time[5],
		 ) . $zone_string;
}

sub time {

  my @time = localtime();

  return strftime("%T", 
		  $time[0],
		  $time[1],
		  $time[2],
		  $time[3],
		  $time[4],
		  $time[5],
		 );
}

sub date_for_filename {
  my @time = localtime();

  return strftime("%Y%m%d%H%M%S", 
		  $time[0],
		  $time[1],
		  $time[2],
		  $time[3],
		  $time[4],
		  $time[5],
		 );
}

sub hostname {
  my $hostname = `hostname`;
  chomp $hostname;
  return $hostname;
}

sub construct_run_name {
  my $save_name = shift;
  my $run_number = shift;
  if (!defined($save_name) || !defined($run_number)) {
    Carp::confess('');
  }
  return sprintf("%s-%s-%03d", $save_name, Misc::date_for_filename(), $run_number);
}

sub construct_save_name {
  my $save_name = shift;
  my $run_number = shift;
  my $backup_number = shift;
  return construct_run_name($save_name, $run_number) . sprintf("-%03d-%05d", $backup_number, $$);
}

# run a command, emitting its output to the info log (includes console).

sub system_to_log_file {
  my $command = shift;
  my $hide_command = shift;
  my $output = shift;
  my $hide_output = shift;

  my $line;
  my $rc = '';
  

#  Logger::informational("----------------------------------------------------");	
  my $statement = _build_command_diagnostic($command);
  if (defined($hide_command) && $hide_command == 1) {
    Logger::informational_to_log_file($statement);	
  } else {
#    Logger::informational($statement);	
    Logger::informational($command);	
  }

  my $executable;
  my $args;
  my $exit_status = 0;
    
    
  ($executable, $args) = $command =~ /^\s*(\S+)\s*(.*)$/;
    
  #  untaint the bastard
  ($command) = $command =~ m#^(.*)$#; 
    
  open(COMMAND, "$command 2>&1|") or Logger::fatal("couldn't execute $command: $!\n");
  while ($line = <COMMAND>) {
    if ($line =~ /warning: Warning: Need basic cursor movement capablity, using vt100/) {
      next;
    } elsif ($line =~ /You have no controlling terminal.Can't initialize readline for confirmations/) {
      next;
    }
    if (defined($output)) {
      push (@${output}, $line);
    }
    if (defined($hide_output) and ($hide_output == 1)) {
      # nothing
    } else {
      Logger::informational("  $line");	
    }
  }
  close(COMMAND);
  $exit_status = $?;
  Logger::informational(" ");

  Logger::informational_to_log_file("exit status: $exit_status");	    
  $? = $exit_status;
  
  return $?;
}

sub _build_command_diagnostic {
  my $command = shift;
  my $cwd = `/bin/pwd`;
  chomp($cwd);
  return "`$command' cwd=$cwd PATH=" . $ENV{'PATH'};
}
# run a command, emitting all of its output to the log file.

sub system_with_error_to_log_file {
  my $command = shift;

  my $line;

  Logger::informational_to_log_file(_build_command_diagnostic($command));

#  Logger::informational_to_log_file("----------------------------------------------------");	
  open(COMMAND, "$command 2>&1 |") || Logger::fatal("couldn't execute $command: $!\n");
  while ($line = <COMMAND>) {
    Logger::informational_to_log_file("  $line");	
  }
  close(COMMAND);
#  Logger::informational_to_log_file("----------------------------------------------------");	
  Logger::informational_to_log_file(" ");

  Logger::informational_to_log_file("exit status: $?");	    
  return $?;
}

sub become_user {
  my $user_name = shift;
  my @passwd_entry = getpwnam($user_name);
  my $uid = $passwd_entry[2];
  my $gid = $passwd_entry[3];

  if (!@passwd_entry) {
    Logger::fatal("no such user `$user_name'");
  }    
  use POSIX;
  if (POSIX::getuid() != 0) {
    Logger::fatal("must be root to change user in Misc::become_user");
  }

  if (POSIX::setgid($gid) < 0) {
    Logger::fatal("couldn't setgid($uid): `$!'");
  }

  if (POSIX::setuid($uid) < 0) {
    Logger::fatal("couldn't setuid($uid): `$!'");
  }

  $) = $gid;
  $> = $uid;
    
  return 1;
}

# various untainting routines

sub insecure_chdir {
  my $dir = shift;
  chdir(Misc::untaint($dir)) || Logger::fatal("couldn't chdir $dir: `$!'");
  return 1;
}

sub untaint {
  my $string = shift;
  ($string) = $string =~ m#^(.*)$#; 
  return $string;
}

sub ordered_hash_merge {
  my $result = {};
  foreach my $h (@_) {
    foreach my $k (keys(%{$h})) {
      $result->{$k} = $h->{$k};
    }
  }
  return $result;
}

sub list_processes_by_name {
  my $name = shift;
  my $found = 0;
  my $lines = [];
  open(PS, "ps auxw|") || Logger::fatal("couldn't open ps: $!\n");
  my $line = '';
  while(<PS>) {
    chomp;
    next if /ps auxwe/;
    if (/$name/) {
      push(@{$lines}, $_);
    }
  }
  close PS;
  return $lines;
}

sub validate_keys {
  my $hash = shift;
  my $keys = shift;
  my $error = 0;
  foreach my $key (@{$keys}) {
    if (!defined($hash->{$key})) {
      $error = 1;
      Logger::error_stack_trace("required parameter `$key' not found in object:\n" . Dumper($hash) . "\n");
    }
  }
  if ($error) {
    Logger::fatal("bailing.\n");
  }
}

1;

