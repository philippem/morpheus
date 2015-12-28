
# Copyright (c) 2004 Philippe McLean <pmclean@users.sourceforge.net>
# All rights reserved.  This program is free software; you can
# redistribute it and/or modify it under the same terms as Perl
# itself.

# Permission has kindly been given to me by Zero-Knowledge Systems
# Inc., to make this software available under the artistic license.

# $Id: Stage_Number.pm,v 1.1.1.1 2004/03/03 17:12:46 pmclean Exp $

package Morpheus::Stage_Number;
use strict;

# package for encapsulating and manipulating stage numbers

sub new {
  my $class = shift;
  my $string = shift;
  my $self = {};
  bless ($self, $class);
  my $regexp = '(stage)?(\d+)\.(\d\d|\d)';
  if ($string !~ /$regexp/) {
    Logger::warning("invalid stage number `$string', expecting match of $regexp");
    return undef;
  }
    
  $self->{'Major'} = $2;
  $self->{'Minor'} = $3;
    
  $self->{'Ordinal'} = $self->major() * 100 + $self->minor();

  return $self;
}

sub major {
  my $self = shift;
  return $self->{'Major'};
}

sub minor {
  my $self = shift;
  return $self->{'Minor'};
}

sub ordinal {
  my $self = shift;
  return $self->{'Ordinal'};
}

sub compare {
  my $a = shift;
  my $b = shift;
    
  return  $a->ordinal() - $b->ordinal();
}

sub print {
  my $self = shift;
  return $self->{'Major'} . '.' . $self->{'Minor'};
}

  sub before_or_same {
    my $a = shift;
    my $b = shift;
    
    if (!defined($a) || !defined($b)) {
      Logger::error_and_die("undefined stage");
    }
    return compare($a, $b) <= 0;
  }

sub before {
  my $a = shift;
  my $b = shift;
    
  if (!defined($a) || !defined($b)) {
    Logger::error_and_die("undefined stage");
  }
  return compare($a, $b) < 0;
}

sub after {
  my $a = shift;
  my $b = shift;
    
  if (!defined($a) || !defined($b)) {
    Logger::error_and_die("undefined stage");
  }
  return compare($a, $b) > 0;
}

1;
