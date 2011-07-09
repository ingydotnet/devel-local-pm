# Test these usages:
#
#     use Devel::Local;
#     use Devel::Local qw(path/foo path/bar);

use Test::More tests => 6;
use t::Test;

chdir 't' or die;
my $t = cwd;

set_env_min();
my $label = "use Devel::Local;";
my $expected_path = join($sep, "$t/aaa/bin", "$t/bbb/bin", '|', $ENV{PATH});
my $expected_perl5lib = join($sep, "$t/aaa/lib", "$t/ccc/lib", '|');
do {
    test($label,
        sub {
            eval "use Devel::Local; 1" or die $@;
            (($ENV{PERL5LIB} = join $sep, @INC)) =~ s/(?<=\:\|):.*//;
        },
        $expected_path,
        $expected_perl5lib,
    );
    $label .= " (2nd time)";
} for 1..2;

set_env_min();
test("perl -MDevel::Local::ENVVAR ...",
    sub {
        $ENV{PATH} = `$^X -I../lib -MDevel::Local::PATH`;
        $ENV{PERL5LIB} = `$^X -I../lib -MDevel::Local::PERL5LIB`;
    },
    $expected_path,
    $expected_perl5lib,
);

# set_env_min();
# test($label,
#     sub {
#         eval "use Devel::Local 't/ccc'; 1" or die $@;
#         (($ENV{PERL5LIB} = join $sep, @INC)) =~ s/(?<=\:\|):.*//;
#     },
#     $expected_path,
#     $expected_perl5lib,
# );

# test(
#     sub {
#     },
# 
# {
#     local $ENV{PATH} = $_path . $sep;
#     my $PATH3 = `$^X -MDevel::Local::PATH`;
#     is $PATH3, "$t/aaa/bin:$t/bbb/bin:$_path$sep", "PATH works when it ends with $sep";
# 
# }

sub test {
    my ($label, $callback, $expected_path, $expected_perl5lib) = @_;
    $ENV{PERL_DEVEL_LOCAL_QUIET} = 1;
    &$callback();

    is $ENV{PATH}, $expected_path, "$label - PATH works";
    is $ENV{PERL5LIB}, $expected_perl5lib, "$label - PERL5LIB works";
}

