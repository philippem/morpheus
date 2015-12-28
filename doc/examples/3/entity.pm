# $Id: entity.pm,v 1.1.1.1 2004/03/03 17:12:46 pmclean Exp $

# Example of extracting information from the shared context.

my $shared = $context->get_shared();
my $name = $context->get_host()->get_name();

my $master_hostname = $shared->{'Hostname'};

Logger::informational("My master's hostname is `$master_hostname'");

# add my name to the hosts

push(@{$shared->{'hosts'}}, $name);

