#!/usr/bin/perl -w 


# Copyright (c) 2004 Philippe McLean <pmclean@users.sourceforge.net>
# All rights reserved.  This program is free software; you can
# redistribute it and/or modify it under the same terms as Perl
# itself.

# Permission has kindly been given to me by Zero-Knowledge Systems
# Inc., to make this software available under the artistic license.

# $Id: Genesis.pm,v 1.1.1.1 2004/03/03 17:12:46 pmclean Exp $


use Logger;
use IniConf;
use Data::Dumper;
use Cwd;

use strict;

# classes and methods for manipulating genesis.conf objects.

package Genesis;
use Genesis::Network;
use Genesis::Entity;
use Genesis::RPMs;
use Genesis::Host;

package Genesis;

sub new {
  my $class = shift;
  my $self = { @_ };
  bless ($self, $class);

  Misc::validate_keys($self, [qw(Config_File )]);

  my $config_file = $self->{'Config_File'};

  if (!(-f $config_file)) {
    Logger::fatal("no such genesis config file `$config_file'");
  }     

  # read the conf file

  my $config = IniConf->new( -file => $config_file, -nocase => 1, -default => 'Default', -notrailingwhitespace => 1, );
  if (!defined($config)) {
    if (!defined($config)) {
      Logger::fatal("config initialization error(s):\n" . join("\n", @IniConf::errors)); 
    }
  }

  Logger::informational_to_log_file("read genesis config $config_file");

  # compute an absolute config file path

  if ($config_file =~ /^\//) {
    # absolute path
    $self->{'Config_File_Path'} = $config_file;
  } else {
    # relative path
    $self->{'Config_File_Path'} = Cwd::cwd() . '/' . $config_file;
  }

  # initialize instance variables

  $self->{'Config'} = $config;
  $self->{'Networks'} = {};
  $self->{'RPMs'} = {};

  # rest of initialization
  $self->_initialize();

  return $self;
}

# various instance get methods
sub get_network_by_name {
  my $self = shift;
  my $network_name = shift;
  return $self->{'Networks'}->{$network_name};
}

sub add_network {
  my $self = shift;
  my $network = shift;
  $self->{'Networks'}->{$network->get_name()} = $network;
  return $self;
}

sub add_rpms {
  my $self = shift;
  my $rpms = shift;
  $self->{'RPMs'}->{$rpms->get_name()} = $rpms;
  return $self;
}

sub get_rpms_by_name {
  my $self = shift;
  my $release_name = shift;
  return $self->{'RPMs'}->{$release_name};
}

sub get_networks {
  my $self = shift;
  return [ values(%{$self->{'Networks'}}) ];
}

# read the specified conf file, and create network and host objects

sub _initialize {
  my $self = shift;
  my $config = $self->{'Config'};
  foreach my $section ($config->Sections()) {
    my $network_name;
    my $rpms_name;
    
    # rpms description

    if (($rpms_name) = $section =~ m/^rpms\s+(.+)/) {
      
      my $rpms = new Genesis::RPMs(Name => $rpms_name, Parameters => $config->values($section));

      # validate

      if (!defined($rpms)) {
        Logger::fatal("invalid rpms description at "
		      . $self->{'Config_File'}
		      . ":"
		      . $config->linenumber($section));
      }

      # add to our list

      $self->add_rpms($rpms);

    } elsif (($network_name) = $section =~ m/^network\s+(.+)/) {

      # network description

      my $network = new Genesis::Network(
                                         Name => $network_name, 
                                         Parameters => $config->values($section), 
                                         Genesis => $self,
                                        );

      # validate

      if (!defined($network)) {
        Logger::fatal("invalid network description at "
                              . $self->{'Config_File'}
                              . ":"
                              . $config->linenumber($section));
      }
        

      # examine all the hosts

      foreach my $host_name ($config->GroupMembers($network_name)) {
        my $host = new Genesis::Host(
                                     Name => $host_name, 
                                     Parameters => $config->values("$network_name $host_name"),
                                     Network => $network,
                                    );

        # validate

        if (!defined($host)) {
          Logger::fatal("invalid host description at "
                                . $self->{'Config_File'}
                                . ":"
                                . $config->linenumber($section));
        }                
        
        # add to our lists

        $network->add_host($host);
      }

      $self->add_network($network);
            
      #     use Data::Dumper;
      #     print Dumper($network);         
    }
  }
	   }

      sub get_config {
	my $self = shift;
	return $self->{'Config'};
      }

    sub get_config_file {
      my $self = shift;
      return $self->{'Config_File'};
    }

    sub get_config_file_path {
      my $self = shift;
      return $self->{'Config_File_Path'};
    }

    1;
