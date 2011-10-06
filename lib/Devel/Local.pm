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

our $VERSION = '0.16';

use Cwd 'abs_path';
use Config;
use File::Spec;
use File::Find;

my $path_sep = $Config::Config{'path_sep'};

sub import {
    my ($package, @args) = @_;
    if ((caller(0))[1] =~ /^-e?$/ and
        @args == 1 and $args[0] =~ /^(PATH|PERL5LIB)$/
    ) {
        @ARGV = ('?') if not @ARGV;
        @ARGV = () if $ARGV[0] eq $ENV{HOME};
        Devel::Local::print_path($args[0], @ARGV);
        exit 0;
    }
    unshift @INC, get_path('PERL5LIB', @args);
    $ENV{PATH} = join $path_sep, get_path('PATH', @args);
}

sub print_path {
    my ($name, @args) = @_;
    my @path = get_path($name, @args);
    if (not $ENV{PERL_DEVEL_LOCAL_QUIET}) {
        warn "${name}:\n";
        for (@path) {
            warn "    $_\n";
        }
        warn "\n";
    }
    print join $path_sep, @path;
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
    my $dot_file = File::Spec->catfile(File::Spec->curdir, 'devel-local');
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
    my $bin = File::Spec->catfile($dir, 'bin');
    my $lib = File::Spec->catfile($dir, 'lib');
    my $blib = File::Spec->catfile($dir, 'blib');
    my @add;
    if ($name eq 'PERL5LIB' and -d $lib) {
        push @add, $lib;
        if (has_xs($dir)) {
            push @add, $blib;
        }
    }
    elsif ($name eq 'PATH' and -d $bin) {
        push @add, $bin;
    }
    return unless @add;
    @$path = (
        @add,
        grep {
            not(
                ($name eq 'PERL5LIB' and ($_ eq $lib or $_ eq $blib)) or
                ($name eq 'PATH' and ($_ eq $bin))
            )
        } @$path
    );
    return;
}

sub has_xs {
    my $dir = shift;
    my @xs;
    File::Find::find sub {
        push @xs, $_ if /\.xs$/;
    }, $dir;
    return scalar @xs;
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

From the command line:

    > devel-local dir/path      # Add dir/path/lib to PERL5LIB
                                # and dir/path/bin to PATH
    > devel-local file/path     # Apply a Devel::Local config file
    > devel-local .             # Add current dir's lib/ and bin/
    > devel-local ../*          # Add all your source repos at once!
    > devel-local ~             # Apply ~/.perl-devel-local config file
    > devel-local ?             # Pretty print $PERL5LIB and $PATH
    > devel-local !             # Reset $PERL5LIB and $PATH to original
    > devel-local               # Default action (pretty print)

Using this command line tool is the simplest way to do it, but TMTOWTDI. See
L<USAGE> for more ways.

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

In addition to keeping a list of paths in specially named files, you can
request a specific list file or name specific paths containing lib and bin
dirs.

Devel::Local always converts the paths to absolute forms, so switching
directories should not break the behavior.

Finally, Devel::Local can reset the PERL5LIB and PATH variables to their
original state.

=head1 USAGE

As was pointed out in the L<SYNOPSIS> above, there are several ways to invoke
Devel::Local.

The handiest way to use Devel::Local is to add this line to your .bashrc:

    source `which devel-local.sh`

Then you'll have the C<devel-local> Bash function to set up your environment
whenever you need to:

    > devel-local [optional-arguments]

If you don't use Bash for your shell, use an option below or considering
contacting me to add support for your shell.

The explicit way to use Devel::Local from the command line is thus:

    export PERL5LIB=`$PERL -MDevel::Local=PERL5LIB -e1 <arguments>`
    export PATH=`$PERL -MDevel::Local=PATH -e1 <arguments>`

This is actually what the C<devel-local> script does internally.

Finally you can use Devel::Local from inside your code like thus:

    use Devel::Local <arguments>;

This will modify $ENV{PERL5LIB} and $ENV{PATH} appropriately.

For each of the above forms there are different arguments you can specify:

=over

=item Devel::Local config files

If you don't give C<use Devel::Local> any arguments it will search for one of
these files:

    ./devel-local
    ./.devel-local
    ~/.perl-devel-local

that has lines like this:

    # Use the GitHub versions of these:
    .
    ~/src/yaml-libyaml-pm/
    ~/src/catalyst-*

You can also put a file of the above format anywhere, and just specify its
path.

=item $PERL_DEVEL_LOCAL

You may also use any other config file path you wish, by setting the
C<PERL_DEVEL_LOCAL> environment variable.

NOTE: Devel::Local will ignore all the lines in these config files after the
first blank line. This way, you can put several groupings of devel libraries
in one file. Just make sure that the grouping you want to use is at the top of
the file.

=head1 XS AND BLIB

You can use Devel::Local with modules that are not pure Perl. In other words,
modules that get compiled before installing.

If Devel::Local sees a C<.xs> file anywhere in the dist, it will add C<blib/>
to the C<PERL5LIB> after <lib/>.

It is up to you to run C<make> after changing your .xs code, so that the
changes get added to your C<blib/>.

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

