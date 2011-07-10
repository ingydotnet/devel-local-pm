##
# name:      Devel::Local::PERL5LIB 
# abstract:  Set PERL5LIB with Devel::Local
# author:    Ingy döt Net
# license:   perl
# copyright: 2011

package Devel::Local::PERL5LIB;
use strict;

use Devel::Local ();

sub import {
    Devel::Local::print_path('PERL5LIB', @ARGV);
    exit 0;
}

1;
