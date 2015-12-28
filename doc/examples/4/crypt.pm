# $Id: crypt.pm,v 1.1.1.1 2004/03/03 17:12:46 pmclean Exp $

my $crypt = $context->get_morpheus()->get_crypt();

my $hostname = `/bin/hostname`;
chomp($hostname);

my $tmp_file = "/tmp/$hostname";

my $master_hostname = `cat master-hostname`;
chomp($master_hostname);

Logger::informational("My master's hostname is `$master_hostname'");

# create a file named after our hostname, containing the date

Misc::system_to_log_file("date >$tmp_file");

# move it to the crypt

Logger::informational("Adding $tmp_file to the crypt");

$crypt->move_to_crypt($tmp_file);


