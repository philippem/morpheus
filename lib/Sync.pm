#!/usr/bin/perl -w

# Copyright (c) 2004 Philippe McLean <pmclean@users.sourceforge.net>
# All rights reserved.  This program is free software; you can
# redistribute it and/or modify it under the same terms as Perl
# itself.

# Permission has kindly been given to me by Zero-Knowledge Systems
# Inc., to make this software available under the artistic license.

# $Id: Sync.pm,v 1.1.1.1 2004/03/03 17:12:46 pmclean Exp $

# Methods for syncing trees between hosts

package Sync;

use strict;

use Logger;

sub sync {
  my $parameters = { @_ };
  Misc::validate_keys($parameters, [qw(Source Destination ssh_user ssh_command)]);

  my $extra_options = '';
  if (defined($parameters->{'Extra_Rsync_Options'})) {
    $extra_options = $parameters->{'Extra_Rsync_Options'};
  }
      
  my $source = $parameters->{'Source'};
  my $destination = $parameters->{'Destination'};

  my $user = $parameters->{'ssh_user'};
  my $ssh_command = $parameters->{'ssh_command'};

  if (!defined($user)) {
    $user = 'root';
  }

#  my $remote_user = 'root';

  my $sync_command = '';

  my $rsh_command = '';
  if (defined($parameters->{'Proxy'})) {
    my $proxy = $parameters->{'Proxy'};
    $rsh_command = "$ssh_command -x -l $user $proxy ssh -x -l $user";
  } else {
    $rsh_command = "$ssh_command -x -l $user";
  }
  
  $sync_command = "rsync --verbose $extra_options --archive --compress -e \"$rsh_command\" $source $destination";
    
  my $exit_status = Misc::system_with_error_to_log_file($sync_command);
#  my $exit_status = Misc::system_to_log_file($sync_command);
    
  return $exit_status;
}
    
1;
