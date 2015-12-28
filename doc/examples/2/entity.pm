# $Id: entity.pm,v 1.1.1.1 2004/03/03 17:12:46 pmclean Exp $

# Example of extracting information about the host this script is running on.

# The variable $context (an instance of a Morpheus::Module_Context) is
# provides methods for extracting information about this process's context.

my $entity = $context->get_entity();
my $network = $context->get_network();
my $host = $context->get_host();

# Example of using the Logger module.

Logger::informational("Executing for the entity `"
		      . $entity
		      . "' on host `"
		      . $host->get_name()
		      . "' in the network `"
		      . $network->get_name()
		      . "'");

# Example of using the Misc system call facilities. Program output
# will be logged.

Misc::system_to_log_file("date");

