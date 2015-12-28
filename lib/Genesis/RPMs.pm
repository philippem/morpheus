
# Copyright (c) 2004 Philippe McLean <pmclean@users.sourceforge.net>
# All rights reserved.  This program is free software; you can
# redistribute it and/or modify it under the same terms as Perl
# itself.

# Permission has kindly been given to me by Zero-Knowledge Systems
# Inc., to make this software available under the artistic license.

# $Id: RPMs.pm,v 1.1.1.1 2004/03/03 17:12:46 pmclean Exp $

package Genesis::RPMs;
use strict;
use Misc;

# encapsulates set of rpms in a release

sub new {
  my $class = shift;
  my $self = { @_ };
  bless ($self, $class);
  Misc::validate_keys($self, [qw(Name Parameters)]);

  return $self;
}

sub get_parameters {
  my $self = shift;
  return $self->{'Parameters'};
}

sub get_name {
  my $self = shift;
  return $self->{'Name'};
}

1;
