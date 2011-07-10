##
# name:      Devel::Local
# abstract:  Use development code in place
# author:    Ingy döt Net
# license:   perl
# copyright: 2011
# see:
# - File::Share
# - ylib
# - local::lib

use 5.8.3;
package Devel::Local;
use strict;
use warnings;

# use XXX;

our $VERSION = '0.13';

use Cwd 'abs_path';
use Config;
use File::Spec;

my $path_sep = $Config::Config{'path_sep'};

sub import {
    my ($package, @args) = @_;
    unshift @INC, get_path('PERL5LIB', @args);
    $ENV{PATH} = join $path_sep, get_path('PATH', @args);
}

sub print_path {
    my ($name, @args) = @_;
    my @path = get_path($name, @args);
    if (@path) {
        if (not $ENV{PERL_DEVEL_LOCAL_QUIET}) {
            warn "${name}:\n";
            for (@path) {
                warn "    $_\n";
            }
            warn "\n";
        }
        print join $path_sep, @path;
    }
}

sub get_path {
    my ($name, @args) = @_;
    my $cmd = '';
    if (not @args) {
        @args = get_config_file();
    }
    elsif (@args == 1 and $args[0] =~ /^[\!\?]$/) {
        $cmd = shift @args;
    }
    my (@left, @right, $found);
    map {
        if ($_ eq '|') {
            $found = 1;
        }
        elsif ($found) {
            unshift @left, $_;
        }
        else {
            unshift @right, $_;
        }
    } reverse(($ENV{$name})
        ? grep($_, split($path_sep, $ENV{$name}, -1))
        : ()
    );
    if ($cmd eq '!') {
        return @right;
    }
    if ($cmd eq '?') {
        return scalar(@left) ? (@left, '|', @right) : (@right);
    }
    
    my @locals = get_locals(@args);
    for my $dir (reverse @locals) {
        add_to_path($name, $dir, \@left);
    }
    return scalar(@left) ? (@left, '|', @right) : (@right);
}

sub get_config_file {
    my $home_file = File::Spec->catfile($ENV{HOME}, '.perl-devel-local');
    my $dot_file = File::Spec->catfile(File::Spec->curdir, '.devel-local');
    return
        $ENV{PERL_DEVEL_LOCAL} ? $ENV{PERL_DEVEL_LOCAL} :
        (-f $dot_file) ? $dot_file :
        ($ENV{HOME} && -f $home_file) ? $home_file :
        ();
}

sub get_locals {
    return map {
        s!([\\/])/+!$1!g;
        s!(.)/$!$1!;
        abs_path($_);
    } grep {
        s!^~/!$ENV{HOME}/! if defined $ENV{HOME};
        -d $_;
    } map {
        -f($_) ? map { /\*/ ? glob($_) : $_ } read_config($_) :
        /\*/ ? glob($_) :
        ($_);
    } @_;
}

sub add_to_path {
    my ($name, $dir, $path) = @_;
    my $blib = File::Spec->catfile($dir, 'blib');
    my $lib = File::Spec->catfile($dir, 'lib');
    my $bin = File::Spec->catfile($dir, 'bin');
    my $add =
        ($name eq 'PERL5LIB' and -d $lib) ? (
            -d $blib ? $blib : -d $lib ? $lib : ''
        ) :
        ($name eq 'PATH' and -d $bin) ? $bin :
        '';
    return unless $add;
    @$path = (
        $add,
        grep(
            {
                (my $badd = $add) =~
                    s!/(blib|lib)$!$1 eq 'lib' ? '/blib' : '/lib'!e;
                not(m!^\Q$add\E[\\/]?$!) and
                not(m!^\Q$badd\E[\\/]?$!);
            }
            @$path
        )
    );
}

sub read_config {
    my ($file) = @_;
    return () unless $file and -f $file;
    open my $f, $file or die "Can't open $file for input";
    my @lines;
    while (my $line = <$f>) {
        chomp $line;
        last unless $line =~ /\S/;
        next if $line =~ /^\s*#/;
        $line =~ s/^\s*(.*?)\s*/$1/;
        push @lines, $line;
    }
    return @lines;
}

1;

=head1 SYNOPSIS

Devel::Local sets up your Perl development environment with the PERL5LIB and
PATH variables that you want. This lets you write and test code in several
interdependent repositories at once, without needing to install anything after
changing it. It is similar to L<local::lib> but easier to use, and simlar to
ylib but more complete.

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

    > devel-local [optional-arguments]

See L<USAGE> below from more details.

=head1 DESCRIPTION

Sometimes when you are developing Perl software there can several Perl module
code repositories involved. This module lets you specify which repositories
you want to load Perl modules from, and formats them into a PERL5LIB
environment variable format.

Devel::Local takes a list of Perl module repositories that you specify in your
current directory or your home directory. It adds the lib/ subdirectories to
the current value of PERL5LIB, and it also adds the bin/ subdirectories to
your PATH environment variable. You can use absolute paths, relative paths and
even type-globs.

In addition to keeping a list of paths in specially named files, you can name
a specific list file or name specific paths containing lib and bin dirs.

Devel::Local always converts the paths to absolute forms, so switching
directories should not break the behavior.

=head1 USAGE

As was pointed out in the L<SYNOPSIS> above, there are several ways to invoke
Devel::Local. In each of those forms, you have several ways to indicate your
paths of interest:

=over

=item $HOME/.perl-devel-local

Create a file called C<~/.perl-devel-local> that has lines like this:

    # Use the GitHub versions of these:
    .
    ~/src/yaml-libyaml-pm/
    ~/src/catalyst-*

=item ./.devel-local

Create a file called C<./.devel-local> that looks like this:

    # Use the GitHub versions of these:
    .
    ../yaml-libyaml-pm/
    ../catalyst-*

=item $PERL_DEVEL_LOCAL

You may also use any other config file path you wish, by setting the
C<PERL_DEVEL_LOCAL> environment variable.

NOTE: Devel::Local will ignore all the lines in these config files after the
first blank line. This way, you can put several groupings of devel libraries
in one file. Just make sure that the grouping you want to use is at the top of
the file.

=item Specify Config File

You can specify the config file directly:

    use Devel::Local /path/to/devel-local-conf

or:

    > devel-local /path/to/devel-local-conf

=item List of Paths

You can list paths directly:

    use Devel::Local qw(.  ../yaml-libyaml-pm/ ../catalyst-*);

or:

    > devel-local .  ../yaml-libyaml-pm/ ../catalyst-*

=back

=head1 XS AND BLIB

You can use Devel::Local with modules that are not pure Perl. In other words,
modules that get compiled before installing.

The trick is to run C<make> (or equivalent) in the appropriate directories so
that things get compiled into C<blib/> before using Devel::Local. If
Devel::Local sees a C<blib/> subdirectory it will use that instead of C<lib>.

=head1 DISPLAY $PATH AND $PERL5LIB

Whenever you use the C<devel-local> bash function, it will pretty print the
values. If you just want to see the values listed without modifying them, do
this:

    > devel-local ?

=head1 TURNING Devel::Local OFF

Devel::Local puts a special delimiter, '|', in the PATH variables, so that it
can later remove the things it added. You can trigger this by passing it a
single argument of '!'.

    > devel::local      # Add stuff to $PATH and $PERL5LIB
    > devel::local path/foo path/bar-*  # Add more stuff
    > devel::local !    # Reset to original values

