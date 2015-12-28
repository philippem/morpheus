# Copyright (c) 2004 Philippe McLean <pmclean@users.sourceforge.net>
# All rights reserved.  This program is free software; you can
# redistribute it and/or modify it under the same terms as Perl
# itself.

# Permission has kindly been given to me by Zero-Knowledge Systems
# Inc., to make this software available under the artistic license.

# $Id: Stage.pm,v 1.1.1.1 2004/03/03 17:12:46 pmclean Exp $

package Morpheus::Stage;
use strict;
use Morpheus::Stage_Number;

# package for encapsulating a morpheus stage

# package method

sub new {
  my $class = shift;
  my $self = { @_ };
  bless ($self, $class);
    
  $self->{'Stage_Number'} = new Morpheus::Stage_Number($self->get_stage_name());

  if (!defined($self->{'Stage_Number'})) {
    return undef;
  }

  return $self;
}

# instance methods

sub get_parameters {
  my $self = shift;
  return $self->{'Parameters'};
}

sub get_description {
  my $self = shift;
  #    use Data::Dumper;
  #    print Dumper($self);         
  return $self->get_parameters()->{'description'};
}

sub get_module {
  my $self = shift;
  return $self->{'Parameters'}->{'module'};
}

sub get_description_file {
  my $self = shift;
  return $self->get_parameters()->{'description-file'};
}

sub get_user {
  my $self = shift;
  return $self->get_parameters()->{'user'};
}

sub get_location {
  my $self = shift;
  my $location = $self->get_parameters()->{'location'};
  if (!defined($location)) {
    $location = 'remote';
  }
  return $location;
}

sub get_executions {
  my $self = shift;
  return $self->get_parameters()->{'executions'};
}

sub get_entity {
  my $self = shift;
  return $self->{'Entity'};
}

sub get_stage_name {
  my $self = shift;
  return $self->{'Stage_Name'};
}

sub get_stage_number {
  my $self = shift;
  return $self->{'Stage_Number'};
}

sub get_exclude_entities {
  my $self = shift;
  my $exclude_entities = $self->get_parameters()->{'exclude-entities'};
  my $entities = [];
  if (defined($exclude_entities)) {
    $entities = [ split(/:/, $exclude_entities) ];
  }
  return $entities;
}

# class methods

sub executions {
  my $self = shift;
  return $self->get_parameters()->{'executions'};
}

sub before {
  my $a = shift;
  my $b = shift;
  return Morpheus::Stage_Number::before($a->get_stage_number(), $b->get_stage_number());
}

sub before_or_same {
  my $a = shift;
  my $b = shift;
  return Morpheus::Stage_Number::before_or_same($a->get_stage_number(), $b->get_stage_number());
}

sub after {
  my $a = shift;
  my $b = shift;
  return Morpheus::Stage_Number::after($a->get_stage_number(), $b->get_stage_number());
}

sub validate {
  my $self = shift;
  my $module = $self->get_module();
  my $morpheus = shift;
 
  if (!defined($module)) {
    Logger::warning("stage has no module");
    return 0;
  }
  
  $module = (split(/\s+/, $module))[0]; # ignore args
  my $module_path = $module;
  
  if (!(-e $module_path)) {
    Logger::warning("stage module `$module_path' does no exist");
    return 0;
  }
  return 1;
}

1;
