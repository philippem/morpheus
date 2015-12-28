#!/usr/bin/perl -w

# Copyright (c) 2004 Philippe McLean <pmclean@users.sourceforge.net>
# All rights reserved.  This program is free software; you can
# redistribute it and/or modify it under the same terms as Perl
# itself.

# Permission has kindly been given to me by Zero-Knowledge Systems
# Inc., to make this software available under the artistic license.


# $Id: Crypt.pm,v 1.1.1.1 2004/03/03 17:12:46 pmclean Exp $

package Crypt;
use strict;

sub new {
  my $class = shift;
  my $self = { @_ };
  bless ($self, $class);

  Misc::validate_keys($self, [qw(Key)]);

  if (!defined($self->{'Crypt_Dir'})
     || !(-d $self->{'Crypt_Dir'})) {
    return undef;
  }

  my $minimum_key_length = 8;

  if (length($self->{'Key'}) < $minimum_key_length) {
    return undef;
  }    

  return $self;
}

sub empty {
  my $self = shift;
  use File::Find qw(finddepth);
  finddepth(\&zap, $self->get_crypt_dir() . "/.");
  
  sub zap {
    return if /\./;
    if (!-l && -d) {
      rmdir || Logger::fatal("couldn't rmdir $_: `$!'\n");
    } else {
      unlink || Logger::fatal("couldn't unlink $_: `$!'\n");
    }
  }
}  
  
sub move_to_crypt {
  my $self = shift;
  my $file = shift;

  if ($self->file_in_crypt($file)) {
    Logger::fatal("crypt: `$file' already in crypt");
    return 0;
  }
  if (!(-f $file)) {
    Logger::fatal("crypt: `$file' is not a plain file");
    return 0;
  }
  
  my $crypt_dir = $self->get_crypt_dir();

  return 0 if $self->_copy_to_crypt($file);

  unlink($file) || Logger::fatal("crypt: couldn't unlink file `$file': $!");
  return 1;
};

sub write_string_to_crypt_file {
  my $self = shift;
  my $file = shift;
  my $string = shift;

  if ($self->file_in_crypt($file)) {
    Logger::fatal("crypt: `$file' already in crypt");
    return 0;
  }  
  
  my $crypt_dir = $self->get_crypt_dir();

  open(FILE, ">$crypt_dir/$file") || Logger::fatal("couldn't create crypt file `$file': `$!'");
  print FILE $string;
  close FILE;

  return 1;
}

sub read_string_from_crypt_file {
  my $self = shift;
  my $file = shift;
  my $string = undef;

  if (!$self->file_in_crypt($file)) {
    Logger::fatal("uncrypt: `$file' not in crypt");
    return 0;
  }

  my $crypt_dir = $self->get_crypt_dir();

  open(FILE, "$crypt_dir/$file") || Logger::fatal("couldn't open crypt file `$file': `$!'");
  $string = join('', <FILE>);
  close FILE;

  unlink("$crypt_dir/$file") || Logger::fatal("uncrypt: couldn't unlink crypt file `$file': $!");

  return $string;
}

sub _copy_to_crypt {
  my $self = shift;
  my $file = shift;
  my $crypt_dir = $self->get_crypt_dir();
  return system("/bin/cp $file $crypt_dir");
};
  
sub _copy_from_crypt {
  my $self = shift;
  my $file = shift;
  my $destination = shift;

  my $crypt_dir = $self->get_crypt_dir();    
  return system("/bin/cp ${crypt_dir}/${file} $destination");
}
  
sub get_crypt_dir {
  my $self = shift;
  return $self->{'Crypt_Dir'};
}

sub file_in_crypt {
  my $self = shift;
  my $file = shift;
  my $crypt_dir = $self->get_crypt_dir();
  return (-f "$crypt_dir/$file");
}

sub get_file_list {
  my $self = shift;
  my $crypt_dir = $self->get_crypt_dir();
  my $files = [];
  my $file;
  opendir(DIR, $crypt_dir) || Logger::fatal("get_file_list: opendir failed: $!");
  while (defined($file = readdir(DIR))) {
    next if $file eq '.';
    next if $file eq '..';

    push (@{$files}, $file);
  }
  closedir(DIR);
  return $files;
}

sub move_from_crypt {
  my $self = shift;
  my $file = shift;
  my $destination_dir = shift;
  my $crypt_dir = $self->get_crypt_dir();

  if (!$self->file_in_crypt($file)) {
    Logger::fatal("uncrypt: `$file' not in crypt");
    return 0;
  }
  
  if (!(-d $destination_dir)) {
    Logger::fatal("uncrypt: destination `$destination_dir' is not a directory");    
  }
  
  return 0 if $self->_copy_from_crypt($file, $destination_dir);

  unlink("${crypt_dir}/$file") || Logger::fatal("uncrypt: couldn't unlink crypt file `$file': $!");
}

1;
