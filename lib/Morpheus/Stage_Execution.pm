
# Copyright (c) 2004 Philippe McLean <pmclean@users.sourceforge.net>
# All rights reserved.  This program is free software; you can
# redistribute it and/or modify it under the same terms as Perl
# itself.

# Permission has kindly been given to me by Zero-Knowledge Systems
# Inc., to make this software available under the artistic license.

# $Id: Stage_Execution.pm,v 1.1.1.1 2004/03/03 17:12:46 pmclean Exp $

package Morpheus::Stage_Execution;
use strict;
use Morpheus::Stage;
use Misc;

# package for encapsulating the execution of a stage

# class methods

sub new {
  my $class = shift;
  my $self = { @_ };
  bless ($self, $class);

  Misc::validate_keys($self, [qw(Stage Host)]);
  
  return $self;
}

# instance methods

sub get_stage {
  my $self = shift;
  
  return $self->{'Stage'};
}

sub get_host {
  my $self = shift;
  
  return $self->{'Host'};
}

sub set_exit_code {
  my $self = shift;
  my $exit_code = shift;

  $self->{'Exit_Code'} = $exit_code;
  
  return $self;
}

sub get_exit_code {
  my $self = shift;
  
  return $self->{'Exit_Code'};
}

1;


  
