##
# name:      Devel::Local
# abstract:  Use development modules in place
# author:    Ingy döt Net
# license:   perl
# copyright: 2011

package Devel::Local;
use 5.008003;
use strict;
use warnings;

our $VERSION = '0.12';

use Cwd 'abs_path';

sub import {
    my ($package, $command, @args) = @_;
    if ($command) {
        if ($command =~ /^(PERL5LIB|PATH)$/) {
            print process($command, @args);
            exit;
        }
        die "Unknown Devel::Local command '$command'";
    }
}

sub process {
    my ($name) = @_;
    my $path = $ENV{$name} || '';
    my $env_file = $ENV{PERL_DEVEL_LOCAL} || '';
    my $local_file = abs_path('.') . "/.devel-local";
    my $home_file = $ENV{HOME} && "$ENV{HOME}/.perl-devel-local";
    my $config =
        ($env_file && -e $env_file) && $env_file ||
        (-e $local_file) && $local_file ||
        ($home_file && -e $home_file) && $home_file ||
        '';
    if (not $config) {
        warn <<"...";
No Devel::Local config file found.
Looked for:
    \$PERL_DEVEL_LOCAL=$env_file
    $local_file
    $home_file
...
        return $path;
    }
    my $locals = read_config($config);
    return $path unless @$locals;
    $path = [ split ':', $path, -1 ];
    for my $dir (reverse @$locals) {
        my $add =
            ($name eq 'PATH' and -d "$dir/bin") ? "$dir/bin" :
            ($name eq 'PERL5LIB' and -d "$dir/lib") ? "$dir/lib" :
            '' or next;
        $path = [ $add, grep {
            $_ !~ m!^\Q$add\E/?$!;
        } @$path];
    }
    return join ':', @$path;
}

sub read_config {
    my ($file) = @_;
    open my $f, $file or die "Can't open $file for input";
    my $locals = [];
    while (my $line = <$f>) {
        chomp $line;
        last unless $line =~ /\S/;
        next if $line =~ /^\s*#/;
        $line =~ s/^\s*(.*?)\s*/$1/;
        if (defined $ENV{HOME}) {
            $line =~ s!^~/!$ENV{HOME}/!;
        }
        if (not -d $line) {
            warn "$line is not a directory\n";
            next;
        }
        $line =~ s!/+!/!g;
        $line =~ s!(.)/$!$1!;
        my $dir = abs_path($line);
        push @$locals, $dir;
    }
    warn "No directories found to use by Devel::Local in '$file'\n"
        if not @$locals;
    return $locals;
}

1;

=head1 SYNOPSIS

From the command line:

    > export PERL5LIB=`perl -MDevel::Local=PERL5LIB`
    > export PATH=`perl -MDevel::Local=PATH`

=head1 DESCRIPTION

Sometimes when you are developing software there can several module code
repositories involved. This module lets you specify which repositories you
want to load modules from, and formats them into a PERL5LIB environment
variable format.

Devel::Local takes a list of Perl module repositories that you specify in your
current directory or your home directory. It adds the absolute paths of the
lib/ subdirectories to the current value of PERL5LIB. It can also add the bin/
subdirectories to your PATH environment variable. It prints the new value to
STDOUT and then exits.

NOTE: If Devel::Local runs into problems, it will warn about them, but still
print your environment variable.

=head1 USAGE

Create a file called C<~/.perl-devel-local> that has lines like this:

    # Use the GitHub versions of these:
    ~/src/yaml-libyaml-pm/
    ~/src/catalyst-runtime/

for generic values, or a file called C<./.devel-local> that looks like this:

    # Use the GitHub versions of these:
    ../yaml-libyaml-pm/
    ../catalyst-runtime/

for project specific values.
    
You may also use any other config file path you wish, by setting the
C<PERL_DEVEL_LOCAL> environment variable.

NOTE: Devel::Local will ignore all the lines in the config file after the
first blank line. This way, you can put several groupings of devel libraries
in one file. Just make sure that the grouping you want to use is at the top of
the file.

=head1 BASH

You may want to put a function like this one in your .bashrc file:

    function devel-local() {
        export PERL5LIB=`perl -MDevel::Local=PERL5LIB`
        export PATH=`perl -MDevel::Local=PATH`
        echo "PERL5LIB=$PERL5LIB"
        echo "PATH=$PATH"
    }

Then any time you want to use Devel::Local values, you can just run:

    > devel-local

from the command line. That's all you need to do!
