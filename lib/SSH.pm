#!/usr/bin/perl -w

# Copyright (c) 2004 Philippe McLean <pmclean@users.sourceforge.net>
# All rights reserved.  This program is free software; you can
# redistribute it and/or modify it under the same terms as Perl
# itself.

# Permission has kindly been given to me by Zero-Knowledge Systems
# Inc., to make this software available under the artistic license.

# $Id: SSH.pm,v 1.1.1.1 2004/03/03 17:12:46 pmclean Exp $

# Methods for invoking shells via ssh and ssh proxies.
# Includes method for testing whether the correct keys have been installed.

package SSH;

use Misc;
use Data::Dumper;

use strict;

sub test {
  my $options = { @_ };

  Misc::validate_keys($options, [qw(Host ssh_user ssh_command Morpheus_Bin)]);

  my $host = $options->{'Host'};
  my $user = $options->{'ssh_user'};
  my $ssh_command = $options->{'ssh_command'};
  my $bin = $options->{'Morpheus_Bin'};

  my $proxy = $host->get_ssh_proxy();
  my $nated_address = $host->get_parameters()->{'nat-name'};
  my $host_name = defined($nated_address) ? $nated_address : $host->get_hostname();
  my $command = '';
  if (defined($proxy) and !defined($nated_address)) {
    $command = "$bin/test-ssh.exp $ssh_command $user $host_name $proxy";
  } else {
    $command = "$bin/test-ssh.exp $ssh_command $user $host_name";
  }

  my $result = Misc::system_to_log_file($command);
  if ($result) {
    return 0;
  } else {
    return 1;
  }
}

sub execute {
  my $options = { @_ };

  Misc::validate_keys($options, [qw(Remote_Host Command Hide_Command ssh_user ssh_command)]);

  my $remote_host = $options->{'Remote_Host'};
  my $remote_command = $options->{'Command'};
  my $hide_command = $options->{'Hide_Command'};
  my $user = $options->{'ssh_user'};
  my $ssh_command = $options->{'ssh_command'};
  my $output = $options->{'Output'};
  my $hide_output = $options->{'Hide_Output'};

  if (!defined($hide_output)) {
    $hide_output = 0;
  }

  my $proxy = $remote_host->get_ssh_proxy();
  my $nated_address = $remote_host->get_parameters()->{'nat-name'};

  my $remote_host_name = defined($nated_address) ? $nated_address : $remote_host->get_hostname();

  my $command = '';
  if (defined($proxy) and !defined($nated_address)) {
    $command = "$ssh_command -x -l $user $proxy \"ssh -x -l $user $remote_host_name \'$remote_command\' \" 2>\&1";
  } else {
    $command = "$ssh_command -x -l $user $remote_host_name \'$remote_command\' 2>\&1";
  }

  if (defined($hide_command) && $hide_command) {
    return Misc::system_to_log_file($command, 1, $output, $hide_output);
  } else {
    return Misc::system_to_log_file($command, 0, $output, $hide_output);
  }
}

1;

