# $Id: master.pm,v 1.1.1.1 2004/03/03 17:12:46 pmclean Exp $

# Get my hostname.

my $hostname= `/bin/hostname`;
chomp ($hostname);

# Save it in the shared context.

my $shared = $context->get_shared();

# $shared is a reference to a hash. We can save anything we want in it.

Logger::informational("Saving my hostname `$hostname'");

$shared->{'Hostname'} = $hostname;

