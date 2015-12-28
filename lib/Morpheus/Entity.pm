
# Copyright (c) 2004 Philippe McLean <pmclean@users.sourceforge.net>
# All rights reserved.  This program is free software; you can
# redistribute it and/or modify it under the same terms as Perl
# itself.

# Permission has kindly been given to me by Zero-Knowledge Systems
# Inc., to make this software available under the artistic license.


# $Id: Entity.pm,v 1.1.1.1 2004/03/03 17:12:46 pmclean Exp $

# package for encapsulating a sequence of migration stages for an entity

package Morpheus::Entity;
use strict;
use Misc;

sub new {
  my $class = shift;
  my $self = { @_ };
  bless ($self, $class);
  Misc::validate_args($self, [qw(Name Parameters)]);

  return $self;
}

1;
