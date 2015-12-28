#!/usr/bin/perl

# $Id: run-example.pl,v 1.1.1.1 2004/03/03 17:12:46 pmclean Exp $


my $dir = shift;
my $network = shift;
my $network_conf = shift;

die("usage: $0 <dir> <network> <network config>") unless (defined($dir) and defined($network) and defined($network_conf));

system("morpheus --network $network --config $dir/example.morpheus --genesis-config $network_conf --master");

