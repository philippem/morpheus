# $Id: master-final.pm,v 1.1.1.1 2004/03/03 17:12:46 pmclean Exp $

# List the files in the crypt

my $crypt = $context->get_morpheus()->get_crypt();

my $files = $crypt->get_file_list();

Logger::informational("Contents of the crypt:");

foreach my $file (@{$files}) {
  my $string = $crypt->read_string_from_crypt_file($file);
  chomp($string);
  Logger::informational("$file contains `$string'");
}
