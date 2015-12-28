
# Copyright (c) 2004 Philippe McLean <pmclean@users.sourceforge.net>
# All rights reserved.  This program is free software; you can
# redistribute it and/or modify it under the same terms as Perl
# itself.

# Permission has kindly been given to me by Zero-Knowledge Systems
# Inc., to make this software available under the artistic license.

# $Id: Network.pm,v 1.1.1.1 2004/03/03 17:12:46 pmclean Exp $

# package for representing a network group in genesis.conf

package Genesis::Network;
use strict;
use Misc;

sub new {
  my $class = shift;
  my $self = { @_ };
  bless ($self, $class);

  $self->{'Hosts'} = {};
  Misc::validate_keys($self, [qw(Name Parameters Genesis)]);

  return $self;
}

sub add_host {
  my $self = shift;
  my $host = shift;
  $self->{'Hosts'}->{$host->get_name()} = $host;
}

sub get_host {
  my $self = shift;
  my $host = shift;
  return $self->{'Hosts'}->{$host};
}

sub get_hosts {
  my $self = shift;
  return [ sort { $a->get_name() cmp $b->get_name(); } values(%{$self->{'Hosts'}}) ];
}

sub get_name {
  my $self = shift;
  return $self->{'Name'};
}

sub get_domain {
  my $self = shift;
  return $self->get_parameters()->{'domain'};
}

sub get_dns {
  my $self = shift;
  return $self->get_parameters()->{'dns'};
}

sub get_dns_path {
  my $self = shift;
  return $self->get_parameters()->{'dns_path'};
}

sub get_parameters {
  my $self = shift;
  return $self->{'Parameters'};
}

sub get_host_by_name {
  my $self = shift;
  my $host_name = shift;
  return $self->{'Hosts'}->{$host_name};
}

sub get_entities {
  my $self = shift;
  my $entity = shift;
  my $entities = [];
  foreach my $host (@{$self->get_hosts()}) {
    if ($host->has_entity($entity)) {
      push (@{$entities}, $host);
    }
  }
  return $entities;
}

sub get_release_name {
  my $self = shift;
  return $self->get_parameters()->{'release'};
}

sub get_genesis {
  my $self = shift;
  return $self->{'Genesis'};
}

sub get_rpms {
  my $self = shift;
  my $release_name = $self->get_release_name();
  if (defined($release_name)) {
    return $self->get_genesis()->get_rpms_by_name($release_name);
  }
  return undef;
}

1;
