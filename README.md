# morpheus
Infrastructure deployment automation framework (written in Perl).

# History

In Montreal, during the winter of 2000-2001 at
https://en.wikipedia.org/wiki/Zero_Knowledge_Systems (ZKS), we were
building version 2.0 of the Freedom Network. Freedom was a
client-server application that allowed people to browse the web and
send email in privacy. A client installed on your PC would encrypt and
send traffic through a network of routers (using onion routing).

On the "SysDev" team, we were responsible for testing and deployments.
It was a fun team, we put in long hours, and had a great time.

Testing a new build would require deploying 10 - 15 rpms across half a
dozen Linux boxes. A script called "genesis" automated most of this
process using ssh, but it mixed network configuration with the
configuration steps.

One day Luc Boulianne and I discussed the limitations of "genesis". I
then set myself to the task of automating the network deployments,
using my favourite language, and an appropriate one for the day: Perl
5.

The result was morpheus. I have included it here as an example of
clean, opinionated Perl, and also as an example of an effective
automation tool for small networks. We used it to automate all our
deployments during the later stages of the Freedom 2.0 project.

Tools in use today that solve this problem include Octopus Deploy,
Puppet, and Chef. Morpheus is most similar to Octopus Deploy in that
changes to a network are initiated and executed sequentially from a
single host. It is different from both of these, in that network
connections are initiated from the master. 

# Architecture

Morpheus takes two inputs: a network definition file, and an ordered
set of steps to execute on hosts in the network (the morpheus file).
Hosts in the network definition have key-value attributes. Each step
is named by key and stage number. Each step contains a perl script,
that will be executed remotely on all hosts that have the stage's key.

An operator invokes morpheus from a single, privileged host. Morpheus
connects to each host sequentially, using rsync and ssh, and executes
scripts on the remote host. All output is logged on the master.
Morpheus uses rsync to copy itself to the remote host before
execution, to avoid the requirement of any additional dependencies.

For example, given the network definition

- [network alpha]
- domain = alpha.something.net
-
- [alpha web]
- hostname = host0.something.net
- www = nginx
-
- [alpha database]
- hostname = host1.something.net
- db = PostgreSQL
-

and the morpheus definition

- [hostname stage0.0]
- module = print_hostname.pm
-
- [www stage1.0]
- module = print_http_stats.pm
-
- [db stage2.0]
- module = print_db_stats.pm
-

Morpheus will run the following scripts:

- print_hostname.pm on host0.something.net
- print_hostname.pm on host1.something.net
- print_http_stats.pm on host0.something.net
- print_db_stats.pm on host1.something.net





