#!/bin/sh

# You can set this to the absolute path of the perl where Devel::Local is
# installed, if you switch perls a lot (with perlbrew or such) and you want
# devel-local to still work.
PERL=perl

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
    if [ `$PERL -e 'eval {require Devel::Local; print "ok"}'` ]; then
        export PERL5LIB=`$PERL -MDevel::Local=PERL5LIB -e1 $* || echo $PERL5LIB`
        export PATH=`$PERL -MDevel::Local=PATH -e1 $* || echo $PATH`
    else
        echo Devel::Local not installed.
    fi
}
