#!/usr/bin/perl -w


# Copyright (c) 2004 Philippe McLean <pmclean@users.sourceforge.net>
# All rights reserved.  This program is free software; you can
# redistribute it and/or modify it under the same terms as Perl
# itself.

# Permission has kindly been given to me by Zero-Knowledge Systems
# Inc., to make this software available under the artistic license.

# $Id: Morpheus.pm,v 1.1.1.1 2004/03/03 17:12:46 pmclean Exp $

# Module for Morpheus, a utility for transforming networks.

package Morpheus;

use Morpheus::Stage_Number;
use Morpheus::Stage; 
use Morpheus::Entity;
use Morpheus::Module_Context;
use Morpheus::Stage_Execution;

use Error_Code;
use Logger;
use Misc;
use Data::Dumper;
use IniConf;
use Genesis;
use Sync;
use Cwd;
use SSH;
use Crypt;

use strict;

# encapsulate the morpheus configuration

package Morpheus;

sub set_defaults {
  my $self = shift;
  my $class = shift;
  my $parameters = shift;
    
  my $defaults = $self->{'Defaults'};
  if (defined($defaults->{$class})) {
    Logger::warning("redefining defaults for class `$class' in morpheus config "
                    . "`"
                    . $self->{'Config_File_Path'}
                    . "'");
  }
    
  $defaults->{$class} = $parameters;
    
  #    use Data::Dumper;
  #    my $dump = Dumper($self->get_defaults($class));
  #  Logger::informational("setting default parameters for class `$class' to `$dump'");
    
  return $self;
}

sub get_defaults {
  my $self = shift;
  my $class = shift;
  return $self->{'Defaults'}->{$class};
}

# called by constructor

sub _initialize_as_master {
  my $self = shift;

  for my $dir (
               $self->get_tmp_dir(),
               $self->get_local_dir(), 
               $self->get_shadow_dir(),
               $self->get_crypt_dir(),
	       $self->get_shadow_dir(),
              ) {
    if (!(-d $dir)) {
      mkdir($dir, 0777);
    }
  }

  
  chmod(0777, $self->get_crypt_dir());

  my $user_link = $self->get_user_shadow_dir();
  my $morpheus_link = $self->get_morpheus_shadow_dir();
  
  while (-e $user_link) {
    unlink $user_link || Logger::fatal("couldn't unlink $user_link: `$!'");
  }
  symlink($self->get_user_dir(), $user_link) || Logger::fatal("symlink(" . $self->get_user_dir() . ", $user_link) failed : `$!'\n");

  while (-e $morpheus_link) {
    unlink $morpheus_link || Logger::fatal("couldn't unlink $morpheus_link: `$!'");
  }
  symlink($self->get_morpheus_dir(), $morpheus_link) || Logger::fatal("symlink(" . $self->get_morpheus_dir() . ", $morpheus_link) failed : `$!'\n");

}
  
sub _initialize {
  my $self = shift;
  my $config = $self->{'Config'};
    
  # walk through the sections in the config file, creating migrations and migration stages
    
  foreach my $section ($config->Sections()) {
        
    my $entity_name;
    my $stage_name;

    if ($section =~ m/^defaults\s+(.+)/) {

      # read defaults section
      
      my $class = $1;
      my $defaults = $config->values($section); 
      $self->set_defaults($class, $defaults);

    } elsif ($section =~ /^info/) {

      # read info section
      $self->{'Info'} = $config->values($section);

    } elsif (($entity_name) = $section =~ m/^entity\s+(.+)/) {
      
      # read entity description

      my $entity = new Morpheus::Entity(Name => $entity_name, 
					Parameters => Misc::ordered_hash_merge($self->get_defaults('entity'),
									       $config->values($section), )
				       );

      # validate

      if (!defined($entity)) {
        Logger::error_and_die("invalid entity description at "
                              . $self->get_config_file()
                              . ":"
                              . $config->linenumber($section));
      }

      $self->add_entity($entity);

      #           use Data::Dumper;
      #           print Dumper($network);         
    } elsif (($entity_name, $stage_name) = $section =~ m/^(\S+)\s+(stage\d+\.\d+|\d+\.\d+)/) {

      my $stage = new Morpheus::Stage(Entity => $entity_name,
                                      Stage_Name => $stage_name,
                                      Parameters => Misc::ordered_hash_merge($self->get_defaults('stage'),
                                                                             $config->values("$entity_name $stage_name"), ),
                                     );



      # use Data::Dumper;
      #        print Dumper($sequence);

      # validate

      if (!defined($stage)) {
        Logger::fatal("invalid stage description in morpheus configuration "
		      . $self->get_config_file()
		      . ":"
		      . $config->linenumber("$entity_name $stage_name"));
      }

      if (!defined($stage->get_module())) {
        Logger::fatal("no module in stage description in morpheus configuration "
		      . $self->get_config_file()
		      . ":"
		      . $config->linenumber("$entity_name $stage_name"));
      }
        
      # update our first and last stage pointers

      if (!defined($self->{'First_Stage'})
          || Morpheus::Stage::before($stage, $self->{'First_Stage'})) {
        $self->{'First_Stage'} = $stage;
      }
                
      if (!defined($self->{'Last_Stage'})
          || Morpheus::Stage::after($stage, $self->{'Last_Stage'})) {
        $self->{'Last_Stage'} = $stage;
      }

      #               print $sequence->get_description() . "\n";
      #    my $dump = Dumper($self->get_defaults($class));

      # update our sets

      $self->add_stage($stage);
    }
  }
}

# constructor

sub new {
  my $class = shift;
  my $self = { @_ };
    
  bless($self, $class);

  Misc::validate_keys($self, [qw(Config_File Tmp_Dir User_Dir Morpheus_Executable Module_Search_Dirs ssh_user ssh_command)]);

  my $config_file = $self->{'Config_File'};
    
  if (!(-f $config_file)) {
    Logger::fatal("no such morpheus configuration file `$config_file'");
  }
    
  # read the conf file

  my $config = $self->{'Config'} = new IniConf(-file => $config_file,
                                               -nocase => 1,
                                               -default => 'Default',
                                               -notrailingwhitespace => 1,
                                              );
  #  use Data::Dumper;
  #  print Dumper($config);

  if (!defined($config)) {
    Logger::fatal("config initialization error(s):" . join("\n", @IniConf::errors)); 
  }

  # compute an absolute config file path

  if ($config_file =~ /^\//) {
    # absolute path
    $self->{'Config_File_Path'} = $config_file;
  } else {
    # relative path
    $self->{'Config_File_Path'} = Cwd::cwd() . '/' . $config_file;
  }
    
  Logger::informational_to_log_file("read morpheus configuration from `$config_file'");
    
  # intialize instance variables

  $self->{'Defaults'} = {};
  $self->{'Info'} = {};

  $self->{'Entities'} = [];
  $self->{'Stages'} = [];

  $self->{'Stage_Executions'} = [];

  $self->{'_local_dir'} = $self->{'Tmp_Dir'} . '/local';

  $self->{'_synced_hosts'} = {};

  $self->{'_current_execution_host'} = undef;

  $self->{'_hosts_visited'} = {};

  # make directories that won't exist (shadow always does)


  if ($self->is_master()) {
    $self->_initialize_as_master();
  }

  $self->{'_crypt'} = new Crypt('Crypt_Dir' => $self->get_crypt_dir(),
                                'Key' => 'silly willy key',
                               );

  if ($self->is_master()) {
    $self->get_crypt()->empty();
  }
  # do the rest of the initialization

  $self->_initialize();

  return $self;
}

sub get_crypt {
  my $self = shift;
  return $self->{'_crypt'};
}

sub get_stages {
  my $self = shift;
  return $self->{'Stages'};
}

sub find_file_using_module_search_path {
  my $self = shift;
  my $file = shift;
  my $path = undef;
  foreach my $dir (@{$self->get_module_search_dirs()}) {
    my $m = $dir . '/' . $file;
    if (-f $m) {
      $path = $m;
      last;
    }
  }  
  return $path;
}

# return all the migration stages, in sorted order

sub get_all_stages_sorted {
  my $self = shift;
  return [ sort { Morpheus::Stage_Number::compare($a->get_stage_number(), $b->get_stage_number()) } @{$self->get_stages()} ];
}

sub get_ssh_command {
  my $self = shift;
  return $self->{'ssh_command'};
}

sub get_ssh_user {
  my $self = shift;
  return $self->{'ssh_user'};
}

sub get_shadow_dir {
  my $self = shift;
  return $self->get_tmp_dir() . "/shadow";
}

sub compute_shadow_dir {
  my $self = shift;
  my $root = shift;
  return $root . "/shadow";
}

sub get_module_search_dirs {
  my $self = shift;
  return $self->{'Module_Search_Dirs'};
}

sub get_user_shadow_dir {
  my $self = shift;
  return $self->get_shadow_dir() . "/user";
}

sub compute_user_shadow_dir {
  my $self = shift;
  my $root = shift;
  return $self->compute_shadow_dir($root) . "/user";
}

sub get_morpheus_executable {
  my $self = shift;
  return $self->{'Morpheus_Executable'};
}

sub get_user_dir {
  my $self = shift;
  return $self->{'User_Dir'};
}

sub get_morpheus_dir {
  my $self = shift;
  return $self->{'Morpheus_Root'}
}

sub get_morpheus_shadow_dir {
  my $self = shift;
  return $self->get_shadow_dir() . "/morpheus";
}

sub compute_morpheus_shadow_dir {
  my $self = shift;
  my $root = shift;
  return $self->compute_shadow_dir($root) . "/morpheus";
}
  
# sync up my local morpheus tree to a remote host's shadow_dir

sub push_sync_host {
  my $self = shift;
  my $options = { @_ };

  Misc::validate_keys($options, [qw(Host)]);

  my $remote_host = $options->{'Host'};
  my $clean_shadow = 0;
  if (defined($options->{'Clean_Shadow'})) {
    $clean_shadow = $options->{'Clean_Shadow'};
  }
    
  # always sync


  my $root = $remote_host->find_or_create_shadow_directory($self);
  if (!defined($root)) {
    Logger::fatal("could not create shadow directory on host `" . $remote_host->get_hostname() . "'");
  }

  my $remote_shadow = $self->compute_shadow_dir($root);

  my $nated_address = $remote_host->get_parameters()->{'nat-name'};
  my $destination_host = defined($nated_address) ? $nated_address : $remote_host->get_hostname();


  # 28sep2001plm always create the remote_shadow dir, in case
  # machine was rebooted and wiped.

  SSH::execute(
	       Remote_Host => $remote_host,
	       Command => "mkdir -p $remote_shadow",
	       Hide_Command => 1,
	       ssh_user => $self->get_ssh_user(),
	       ssh_command => $self->get_ssh_command(),
	      );

  my $return_value = Sync::sync(
				Source => $self->get_shadow_dir() . '/.',
                                Destination => "${destination_host}:" . $remote_shadow,
                                Proxy => $remote_host->get_ssh_proxy(),
                                Extra_Rsync_Options => "--delete --copy-unsafe-links",
				ssh_user => $self->get_ssh_user(),
				ssh_command => $self->get_ssh_command(),
			       );
  return $return_value;
}

sub pull_crypt {
  my $self = shift;
  my $options = { @_ };

  Misc::validate_keys($options, [qw(Host)]);

  my $remote_host = $options->{'Host'};

  my $root = $remote_host->find_or_create_shadow_directory($self);
  if (!defined($root)) {
    Logger::fatal("could not create shadow directory on host `" . $remote_host->get_hostname() . "'");
  }
    
  #  Logger::informational("syncing... ");

  my $remote_crypt = $self->compute_crypt_dir($root);

  my $nated_address = $remote_host->get_parameters()->{'nat-name'};
  my $remote_hostname = defined($nated_address) ? $nated_address : $remote_host->get_hostname();

  my $return_value = Sync::sync(Source => "${remote_hostname}:${remote_crypt}/.",
                                Destination => $self->get_crypt_dir(),
                                Proxy => $remote_host->get_ssh_proxy(),
                                Extra_Rsync_Options => "--delete",
				ssh_user => $self->get_ssh_user(),
				ssh_command => $self->get_ssh_command(),
                               );     
  return $return_value;
}

# invoke genesis.pl in my shadow

sub run_genesis {
  my $self = shift;
  my $options = shift;
    
  my $shadow_dir = $self->get_shadow_dir();

  if ($self->get_current_execution_host()->has_entity('v11host')) {
    Logger::fatal("genesis is forbidden to run on a v11host");
  }    
  use Cwd;
  my $save_dir = cwd();
  my $genesis_command = "perl ./genesis.pl --config "
    . $self->get_genesis_config_file_path()
      . " "
        . $options;
    
  chdir("data/genesis") || Logger::error_and_die("couldn't chdir data/genesis: $!");
  my $exit_status = Misc::system_to_log_file($genesis_command);
  if ($exit_status) {
    Logger::error_and_die("genesis returned non zero exit status $exit_status");
  }    
  chdir($save_dir) || Logger::error_and_die("couldn't chdir $save_dir: $!");
  return 1;
}

# execute morpheus on a remote machine, and pass it essential options

sub remote_execute {
  my $self = shift;

  my $options = { @_ };
  
  Misc::validate_keys($options, [qw(Host Stage)]);

  my $host = $options->{'Host'};
  my $stage = $options->{'Stage'};

  my $root = $host->find_or_create_shadow_directory($self);
  if (!defined($root)) {
    Logger::fatal("could not create shadow directory on host `" . $host->get_hostname() . "'");
  }
    
  $self->{'_hosts_visited'}->{$host->get_hostname()} = $host;

  my $network = $host->get_network();

  my $user_shadow = $self->compute_user_shadow_dir($root);
  my $morpheus_shadow = $self->compute_morpheus_shadow_dir($root);

  my $command = 
    "perl $morpheus_shadow/bin/" . $self->get_morpheus_executable . " "
      . "--cwd $user_shadow"
      . " --first-stage " . $stage->get_stage_number()->print()
        . " --last-stage " . $stage->get_stage_number()->print()
          . " --network " . $network->get_name()
            . " --host " . $host->get_name()
              . " --config " . $self->get_config_file()
                . " --tmp-dir " . $root
                  . " --slave-entity " . $stage->get_entity()
                    . " --genesis-config " . $self->get_genesis()->get_config_file() 
		      . " " 
			. join(' ', map(" --module-search-dir $_", @{$self->get_module_search_dirs()}));
  
  if (@{$self->get_extra_module_options()}) {
    $command .= " --extra-module-options " . join(' ', @{$self->get_extra_module_options()});
  }
    
  my $regexps = [ 'Morpheus terminating with fatal error' ];
  my $regexps_seen = {};
  my $rc = SSH::execute(
			Remote_Host => $host,
			Command => $command,
			Hide_Command => 1,
			Regexps => $regexps,
			Regexps_Seen => $regexps_seen,
			ssh_user => $self->get_ssh_user(),
			ssh_command => $self->get_ssh_command(),
		       );
#  my $rc = SSH::execute($host, $command, 0, $regexps, $regexps_seen );
  return $rc >> 8;
}

sub emit_initial_log_message {
  my $self = shift;
  Logger::informational_to_log_file(sprintf("%s %03d %s", "**** this is Morpheus on " 
                                            . Misc::hostname()
                                           )
                                   );
    
  Logger::informational_to_log_file(sprintf('**** ' . ' $Id: Morpheus.pm,v 1.1.1.1 2004/03/03 17:12:46 pmclean Exp $ ' . ' ****')); # ' help emacs
}

  
  
# execute a migration stage locally. fork() and eval/exec, so that the
# module runs in its own process.

sub execute_migration_stage {
  my $self = shift;
  my $migration_stage = shift;
  my $genesis = shift;
  my $network = shift;
  my $entity = shift;
  my $host = shift;
  my $exit_status = 0;
  my $exit_code = 0;
    
  $self->set_current_execution_host($host);

  my $module = $migration_stage->get_module();

  if (!defined($module)) {
    Logger::warning("no module defined");
    return 0;
  }	

  my @module_argv = (split(/\s+/, $module), @{$self->get_extra_module_options()});

  $module = shift(@module_argv);
    
  my $return_value = undef;
    
  return unless defined $module;

  #  my $module_path = $self->get_modules_dir() . '/' . $module;
  my $module_path = undef;

  #  print "module args = `" . join("|", @module_argv) . "'\n";

  $module_path = $self->find_file_using_module_search_path($module);

  if (!defined($module_path)) {
    Logger::fatal("couldn't find module `$module',  search path is `" . join(":", @{$self->get_module_search_dirs()}) . "'");
  }

  my $hostname;

  if (defined($host)) {
    $hostname = $host->get_hostname_string();
  } else {
    $hostname = " master (" . Misc::hostname() . ")";
  }

  #  Logger::informational("executing module "
  #                        . "`"
  #                        . $module
  #                        . "'"
  #                        . " on "
  #                     . $hostname
  #                        . " for entity `"
  #                        . $entity
  #                        . "'");
    
    
  #  Logger::informational(" ");

  my $child_pid = fork();

  $| = 1;

  if ($child_pid < 0) {
    # error
    Logger::error_and_die("couldn't fork: $!\n");
  } elsif ($child_pid > 0) {
    # parent
    waitpid($child_pid, 0);
    $exit_status = $?;
    $exit_code = $exit_status >> 8;

    if ($exit_status) {
      Logger::warning("child returned nonzero exit code $exit_code");
      return $exit_code;
    }
  } elsif ($child_pid == 0) {
    # child

    # create an environment

    if (-x $module_path) {
      # executable. Exec it directly
      
      Logger::informational(" execing `$module_path' cwd=" . cwd());
      print "------------------------------------------------------------------------------------------------\n";
      exec $module_path, @module_argv;

    } else {
      open(MODULE, $module_path) || Logger::error_and_die("couldn't open `$module_path': $!");       
      my $module_contents = '';
      my $line_number = 0;
      while (<MODULE>) {
	$module_contents .= $_;
      }
      close(MODULE);

    
      if ($migration_stage->get_user()) {
	Logger::informational("becoming user `" . $migration_stage->get_user() . "'");
	Misc::become_user($migration_stage->get_user());
      }

      @ARGV = @module_argv;

      package main;

      use strict;

      my $shared_file = 'shared';
      my $shared_dump = '$shared = {};';
      my $shared = undef;
      if ($self->get_crypt()->file_in_crypt($shared_file)) {
	$shared_dump = $self->get_crypt()->read_string_from_crypt_file($shared_file);

      }
      # untaint

      ($shared_dump) = $shared_dump =~ /^(.*)$/s; 
      $shared = eval $shared_dump;

      my $context = new Morpheus::Module_Context( 
						 Module => $module,
						 Morpheus => $self,
						 Stage => $migration_stage,
						 Genesis => $genesis,
						 Entity => $entity,
						 Host => $host,
						 Network => $network,
						 Shared => $shared,
						);

      # catch errors emitted during eval, and add them to the log file.
        
      $SIG{'__WARN__'} = sub { 
	Logger::error( $_[0] ); 
      };
      Logger::informational(" evaling `$module_path' cwd=" . cwd());
      print "------------------------------------------------------------------------------------------------\n";
      $return_value = eval $module_contents;

      $shared_dump = Data::Dumper->Dump([$context->{'Shared'}], ['shared']);

      $self->get_crypt()->write_string_to_crypt_file($shared_file, $shared_dump) 
	|| Logger::fatal("couldn't write string to crypt file `$shared_file': `$!'");
    
      if (!defined($return_value)) {
	my $error = $@;
	Logger::fatal("couldn't eval `$module_path': `$error'");
	exit(-1);
      }           

      exit(0);
    }
  }
  return $exit_code;
}


# various instance get methods

sub is_master {
  my $self = shift;
  return defined($self->{'Master'}) && $self->{'Master'};
}

sub get_tmp_dir {
  my $self = shift;
  return $self->{'Tmp_Dir'};
}

sub get_local_dir {
  my $self = shift;
  return $self->{'_local_dir'};
}

sub get_genesis {
  my $self = shift;
  return $self->{'Genesis'};
}

sub get_genesis_config_file_path {
  my $self = shift;
  return $self->get_genesis()->get_config_file_path();
}

sub get_bin_dir {
  my $self = shift;
  return $self->get_shadow_dir() . '/bin';
}

sub get_crypt_dir {
  my $self = shift;
  return $self->get_shadow_dir() . '/crypt';
}

sub compute_crypt_dir {
  my $self = shift;
  my $root = shift;
  return $self->compute_shadow_dir($root) . '/crypt';
}

sub get_config_file_path {
  my $self = shift;
  return $self->{'Config_File_Path'};
}

sub get_config_file {
  my $self = shift;
  return $self->{'Config_File'};
}

sub get_first_stage {
  my $self = shift;
  return $self->{'First_Stage'};
}

sub get_last_stage {
  my $self = shift;
  return $self->{'Last_Stage'};
}

sub add_stage {
  my $self = shift;
  my $stage = shift;

  push(@{$self->{'Stages'}}, $stage);
  return $self;
}

sub add_entity {
  my $self = shift;
  my $entity = shift;

  push(@{$self->{'Entities'}}, $entity);
  return $self;
}

sub get_description {
  my $self = shift;
  return $self->{'Info'}->{'description'};
}

sub get_extra_module_options {
  my $self = shift;
  return $self->{'Extra_Module_Options'};
}

sub get_current_execution_host {
  my $self = shift;
  return $self->{'_current_execution_host'};
}

sub set_current_execution_host {
  my $self = shift;
  my $host = shift;
  return $self->{'_current_execution_host'} = $host;
}

sub get_stage_executions {
  my $self = shift;
  return $self->{'Stage_Executions'};
}

sub add_stage_execution {
  my $self = shift;
  my $stage_execution = shift;

  push(@{$self->get_stage_executions()}, $stage_execution);
  return $self;
}

package Morpheus;

sub prompt_user {
  my $pill = '';
  for (;;) {
    Logger::informational("Morpheus waits for you to choose a pill. Red or blue?");
    print "                          (red/blue) : ";
    $pill = lc(<STDIN>);
    chomp($pill);
    if ($pill =~ /^\s*red/) {
      Logger::informational("<gulp> Red pill swallowed. Excellent choice.");
      $pill = 'red';
      last;
    } elsif ($pill =~ /^\s*blue/) {
      Logger::informational("<ulp> Blue pill down the hatch. Wise choice.");
      $pill = 'blue';
      last;
    } elsif ($pill =~ /^\s*white/) {
      Logger::informational("mmm, white pill, chewable, crunch crunch, yum yum.");
      $pill = 'white';
      last; 
    } elsif ($pill =~ /^\s*black/) {
      Logger::informational("<gurgle> oh... nasty black pill...");
      $pill = 'black';
      last;
    } else {
      Logger::informational("`$pill' is not a choice. You may only choose from what you are offered.");
    }
  }
  return $pill;
}

sub clean_shadow_dirs {
  my $self = shift;

  my $hosts_visited = $self->{'_hosts_visited'};

  foreach my $hostname (keys %{$hosts_visited}) {
    $hosts_visited->{$hostname}->clean_shadow_directory($self);
  }

  return 1;
}

1;

