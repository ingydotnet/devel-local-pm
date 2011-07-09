#!/bin/sh

<<=cut

=encoding utf8

=head1 NAME

devel-local.sh - Bash function to invoke the Devel::Local Perl tool.

=head1 SYNOPSIS

In C<$HOME/.bashrc>:

    source `which devel-local.sh`

=head1 DESCRIPTION

This I<bash module> is used to let Devel::Local set the PERL5LIB and PATH
environment variables.

=head1 AUTHOR

Ingy döt Net

=head1 COPYRIGHT AND LICENSE

Copyright (c) 2011. Ingy döt Net.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl.

See http://www.perl.com/perl/misc/Artistic.html

=cut

function devel-local() {
    perl -MDevel::Local -e1 || exit
    export PERL5LIB=`perl -MDevel::Local::PERL5LIB -e1 $* || echo $PATH`
    export PATH=`perl -MDevel::Local::PATH -e1 $* || echo $PATH`
}
