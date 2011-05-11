use Test::More tests => 5;

use Cwd qw(cwd abs_path);

my $cwd = cwd;
my $old_path = $ENV{PATH};
my $old_perl5lib = $ENV{PERL5LIB};
my $perl = $^X;

chdir 't' or die;
my $t = cwd;

my $PATH1 = `$perl -MDevel::Local=PATH`;
is $PATH1, "$t/aaa/bin:$t/bbb/bin:$old_path", 'PATH works';

my $PERL5LIB1 = `$perl -MDevel::Local=PERL5LIB`;
is $PERL5LIB1, "$t/aaa/lib:$t/ccc/lib:$old_perl5lib", 'PERL5LIB works';

# Make sure that repeated invocations not increase the paths:
{
    local $ENV{PATH} = $PATH1;
    my $PATH2 = `$perl -MDevel::Local=PATH`;
    is $PATH2, $PATH1, 'PATH works the second time';

    local $ENV{PERL5LIB} = $PERL5LIB1;
    my $PERL5LIB2 = `$perl -MDevel::Local=PERL5LIB`;
    is $PERL5LIB2, $PERL5LIB1, 'PERL5LIB works the second time';
};

{
    local $ENV{PATH} = $old_path . ':';
    my $PATH3 = `$perl -MDevel::Local=PATH`;
    is $PATH3, "$t/aaa/bin:$t/bbb/bin:$old_path\:", 'PATH works when it ends with :';
}

chdir $cwd or die;

# TODO add tests for $HOME and $PERL_DEVEL_LOCAL
