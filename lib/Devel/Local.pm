##
# name:      Devel::Local
# abstract:  Use development modules in place
# author:    Ingy döt Net
# license:   perl
# copyright: 2011
# see:
# - File::Share
# - ylib

use 5.8.3;
package Devel::Local;
use strict;
use warnings;

our $VERSION = '0.13';

use Cwd 'abs_path';

my $path_sep = ':';

sub import {
    my ($package, @args) = @_;

    unshift @INC, get_path('PERL5LIB', @args);
    $ENV{PATH} = join $path_sep, get_path('PATH', @args);
}

sub print_path {
    my ($name, @args) = @_;
    my @path = get_path($name, @args);
    if (@path) {
        warn "${name}:\n";
        warn "    $_\n" for @path;
        warn "\n";
        print join $path_sep, @path;
    }
}

sub get_path {
    my ($name, @args) = @_;
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
    return @$path;
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

Devel::Local sets up your Perl development environment with the PERL5LIB and
PATH variables that you want.

There are several ways to use Devel::Local. In your Perl code you can do just
that:

    use Devel::Local;

Or when you run a Perl program you can do this:

    > perl -MDevel::Local program.pl

To use it with many Perl programs:

    > export PERL5OPT='-MDevel::Local'
    > perl program1.pl
    > perl program2.pl

To set up your environment with Devel::Local:

    > export PERL5LIB=`perl -MDevel::Local::PERL5LIB`
    > export PATH=`perl -MDevel::Local::PATH`

The handiest way to use Devel::Local is to add this line to your .bashrc:

    source `which devel-local.sh`

Then you'll have the C<devel-local> Bash function to set up your environment
whenever you need to:

    > devel-local
    > devel-local src/path
    > devel-local file/path

See L<USAGE> below from more details.

=head1 DESCRIPTION

Sometimes when you are developing Perl software there can several Perl module
code repositories involved. This module lets you specify which repositories
you want to load Perl modules from, and formats them into a PERL5LIB
environment variable format.

Devel::Local takes a list of Perl module repositories that you specify in your
current directory or your home directory. It adds the lib/ subdirectories to
the current value of PERL5LIB, and it also adds the bin/ subdirectories to
your PATH environment variable.

In addition to keeping a list of paths in specially named files, you can name
a specific list file or name specific paths containing lib and bin dirs.

Devel::Local always converts the paths to absolute forms, so switching
directories should break them.

=head1 USAGE

As was pointed out in the L<SYNOPSIS> above, TMTOWTDI. There are many ways to set up and use Devel

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
