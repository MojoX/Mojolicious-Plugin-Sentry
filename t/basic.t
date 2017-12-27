use Mojo::Base -strict;
use Test::More;
use Mojolicious::Lite;
use Test::Mojo;
use FindBin;
use Mojo::Util qw(dumper);
BEGIN {
	unshift @INC, "$FindBin::Bin/../lib";
	unshift @INC, "$FindBin::Bin/../";
}

plugin 'Sentry' => {dsn=>$ENV{'sentry_dsn'}};

get '/' => sub {
    my $c = shift;
    die 'test error';
    return $c->render(text => 'Hello Mojo!');
};

my $t = Test::Mojo->new();
$t->get_ok('/')->status_is(500);

done_testing();

