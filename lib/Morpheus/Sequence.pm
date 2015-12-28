
# Copyright (c) 2004 Philippe McLean <pmclean@users.sourceforge.net>
# All rights reserved.  This program is free software; you can
# redistribute it and/or modify it under the same terms as Perl
# itself.

# Permission has kindly been given to me by Zero-Knowledge Systems
# Inc., to make this software available under the artistic license.

# $Id: Sequence.pm,v 1.1.1.1 2004/03/03 17:12:46 pmclean Exp $

# package for encapsulating a sequence of migration stages for an entity

package Morpheus::Sequence;
use strict;
use Misc;

sub new {
  my $class = shift;
  my $self = { @_ };
  bless ($self, $class);
    
  $self->{'Stages'} = [];

  Misc::validate_keys($self, [qw(Stages)]);

  return $self;
}

sub add_stage {
  my $self = shift;
  my $entity_migration_stage = shift;
  push(@{$self->{'Stages'}}, $entity_migration_stage);
  return $self;
}

sub get_stages {
  my $self = shift;
  return $self->{'Stages'};
}

1;
