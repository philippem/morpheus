
# Copyright (c) 2004 Philippe McLean <pmclean@users.sourceforge.net>
# All rights reserved.  This program is free software; you can
# redistribute it and/or modify it under the same terms as Perl
# itself.

# Permission has kindly been given to me by Zero-Knowledge Systems
# Inc., to make this software available under the artistic license.

# 
# $Id: Module_Context.pm,v 1.1.1.1 2004/03/03 17:12:46 pmclean Exp $

# encapsulation of context provided to a Morpheus module upon execution.
# use these get methods to extract information.

package Morpheus::Module_Context;
use strict;
use Misc;

# instance methods 

sub get_module {
  my $self = shift;
  return $self->{'Module'};
}

sub get_morpheus_configuration {
  # deprecated
  my $self = shift;
  return $self->get_morpheus();
}

sub get_morpheus {
  # deprecated
  my $self = shift;
  return $self->{'Morpheus'};
}

sub get_genesis_configuration {
  # deprecated
  my $self = shift;
  return $self->get_genesis();
}

sub get_genesis {
  # deprecated
  my $self = shift;
  return $self->{'Genesis'};
}

sub get_migration_stage {
  my $self = shift;
  return $self->{'Migration_Stage'};
}

sub get_entity {
  my $self = shift;
  return $self->{'Entity'};
}

sub get_host {
  my $self = shift;
  return $self->{'Host'};
}

sub get_network {
  my $self = shift;
  return $self->{'Network'};
}

sub get_shared {
  my $self = shift;
  return $self->{'Shared'};
}

# package methods

sub new {
  my $class = shift;
  my $self = { @_ };
  bless ($self, $class);
  Misc::validate_keys($self, [qw(Module Morpheus Stage Genesis Entity Host Network Shared)]);
  return $self;
}

1;
