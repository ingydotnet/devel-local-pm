##
# name:      Devel::Local::PATH 
# abstract:  Set PATH with Devel::Local
# author:    Ingy döt Net
# license:   perl
# copyright: 2011

package Devel::Local::PATH;
use strict;

use Devel::Local ();

sub import {
    Devel::Local::print_path('PATH', @ARGV);
    exit 0;
}

1;
