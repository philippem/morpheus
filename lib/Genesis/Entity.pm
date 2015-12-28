
# Copyright (c) 2004 Philippe McLean <pmclean@users.sourceforge.net>
# All rights reserved.  This program is free software; you can
# redistribute it and/or modify it under the same terms as Perl
# itself.

# Permission has kindly been given to me by Zero-Knowledge Systems
# Inc., to make this software available under the artistic license.

# $Id: Entity.pm,v 1.1.1.1 2004/03/03 17:12:46 pmclean Exp $

package Genesis::Entity;
use strict;

sub new {
  my $class = shift;
  my $self = { @_ };
  bless ($self, $class);
  return $self;
}

1;
