
# Copyright (c) 2004 Philippe McLean <pmclean@users.sourceforge.net>
# All rights reserved.  This program is free software; you can
# redistribute it and/or modify it under the same terms as Perl
# itself.

# Permission has kindly been given to me by Zero-Knowledge Systems
# Inc., to make this software available under the artistic license.

# $Id: Host.pm,v 1.1.1.1 2004/03/03 17:12:46 pmclean Exp $

# encapsulates a host description in genesis.conf

package Genesis::Host;
use strict;
use Misc;

sub new {
  my $class = shift;
  my $self = { @_ };
  bless ($self, $class);
  Misc::validate_keys($self, [qw(Name Parameters Network)]);
  return $self;
}

sub get_network {
  my $self = shift;
  return $self->{'Network'};
}

sub get_parameters {
  my $self = shift;
  return $self->{'Parameters'};
}

sub has_entity {
  my $self = shift;
  my $entity = shift;
  return defined($self->get_parameters()->{$entity});
}

sub get_name {
  my $self = shift;
  return $self->{'Name'};
}

sub get_hostname {
  my $self = shift;
  return $self->get_parameters()->{'hostname'};
}

sub get_ssh_proxy {
  my $self = shift;
  return $self->get_parameters()->{'ssh-proxy'};
}

sub get_rsh {
  my $self = shift;
  if (defined($self->get_parameters()->{'rsh'})) {
    return $self->get_parameters()->{'rsh'};
  } else {
    return 'ssh -x';
  }
}

sub get_hostname_string {
  my $self = shift;
  return $self->get_name() . " (" . $self->get_hostname() . ")";
}

sub get_annotated_entity_list {
  my $self = shift;
  my $note = shift || '';
  
  return $self->get_hostname_string() . " --> " . join(', ', map( $_ eq $note ? (uc($_) . "=" . $self->get_parameters()->{$_}) : $_ , keys(%{$self->get_parameters()})));
}

sub clean_shadow_directory ($$) {
  my $self = shift;
  my $morpheus = shift;

  my $shadow_directory = $self->{'shadow_directory'};

  return unless defined($shadow_directory);

  my $output = [];

  # do it safely, in case shadow_directory is something stupid like /

  SSH::execute(Remote_Host => $self,
	       Command => "rm -rf $shadow_directory/local $shadow_directory/shadow",
	       Hide_Command => 1,
	       ssh_user => $morpheus->get_ssh_user(), 
	       ssh_command => $morpheus->get_ssh_command(),
	       Output => $output,
	       );


  SSH::execute(Remote_Host => $self,
	       Command => "rmdir $shadow_directory",
	       Hide_Command => 1,
	       ssh_user => $morpheus->get_ssh_user(), 
	       ssh_command => $morpheus->get_ssh_command(),
	       Output => $output,
	       );

  
  $self->{'shadow_directory'} = undef;
  
  return 1;
}

sub find_or_create_shadow_directory ($$) {
  my $self = shift;
  my $morpheus = shift;
  
  if (defined($self->{'shadow_directory'})) {
    return $self->{'shadow_directory'};
  }
  
  my $output = [];

  SSH::execute(Remote_Host => $self,
	       Command => 'perl -e "use POSIX; my \$name = undef; my \$tries = 0; my \$max_tries = 10; do {  \$name = POSIX::tmpnam();  ++\$tries;} until (mkdir(\$name, 0777) or (\$tries > \$max_tries)); if (!-d \$name) {  die (\"failed: could not create directory \$d\n\");} print \"directory: \$name\n\"; "',

	       Hide_Command => 1,
	       Hide_Output => 1,
	       ssh_user => $morpheus->get_ssh_user(), 
	       ssh_command => $morpheus->get_ssh_command(),
	       Output => $output,
	       );

  use Data::Dumper;

  my $directory = undef;
  foreach my $line (@{$output}) {
    if ($line =~ /^directory: (.*)$/) {
      $directory = $1;
    } elsif ($line =~ /failed: (.*)$/) {
      # failed for some reason....
    }
  }

  $self->{'shadow_directory'} = $directory;

  return $directory;
}

1;
