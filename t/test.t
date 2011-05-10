use Test::More tests => 4;

use Cwd qw(cwd abs_path);

my $cwd = cwd;
my $old_path = $ENV{PATH};
my $old_perl5lib = $ENV{PERL5LIB};
my $perl = $^X;
my ($PATH, $PERL5LIB);

chdir 't' or die;
my $t = cwd;

$PATH = `$perl -MDevel::Local=PATH`;
is $PATH, "$t/aaa/bin:$t/bbb/bin:$old_path", 'PATH works';

$PERL5LIB = `$perl -MDevel::Local=PERL5LIB`;
is $PERL5LIB, "$t/aaa/lib:$t/ccc/lib:$old_perl5lib", 'PERL5LIB works';

# Make sure that repeated invocations not increase the paths:
{
    local $ENV{PATH} = $PATH;
    my $PATH2 = `$perl -MDevel::Local=PATH`;
    is $PATH2, $PATH, 'PATH works the second time';

    local $ENV{PERL5LIB} = $PERL5LIB;
    my $PERL5LIB2 = `$perl -MDevel::Local=PERL5LIB`;
    is $PERL5LIB2, $PERL5LIB, 'PERL5LIB works the second time';
};

chdir $cwd or die;

# TODO add tests for $HOME and $PERL_DEVEL_LOCAL
