package Mojolicious::Plugin::Sentry;
use Mojo::Base 'Mojolicious::Plugin';
use Mojo::Util qw(dumper);
use Mojo::URL;
use Mojo::UserAgent;
use UUID::Tiny ':std';
use Sys::Hostname;
use Try::Tiny;
use Carp qw(croak);

our $VERSION = '0.01';

sub register {
    my ($self, $app, $config) = @_;

    $app->hook(around_dispatch => sub {
        my ($next, $c) = @_;
        try {
            $next->();
        }
        catch {
            $self->data($c, $config, $_);
        };
        $next->();
    });
}


sub data {
    my ($self, $c, $config, $exception) = @_;
    my $url = Mojo::URL->new($config->{'dsn'});

    my @auth = ();
    push(@auth, "Sentry sentry_version=7");
    push(@auth, "sentry_key=".$url->username);
    push(@auth, "sentry_secret=".$url->password);
    push(@auth, "sentry_timestamp=".time());
    push(@auth, "sentry_client=Mojolicious::Plugin::Sentry/$VERSION");

    my $ua = Mojo::UserAgent->new();
    $ua->on(start => sub {
        my ($ua, $tx) = @_;
        $tx->req->headers->user_agent("Mojolicious::Plugin::Sentry/$VERSION");
        $tx->req->headers->content_type('application/json');
        $tx->req->headers->header('X-Sentry-Auth' => join(",",@auth));
    });

    my $uuid = create_uuid_as_string(UUID_V4);
    $uuid =~ s/-//gx;

    my $user = {
        ip_address=>$c->req->headers->header('X-Real-IP') || $c->req->headers->header('X-Forwarded-For') || $c->tx->remote_address || '127.0.0.1',
    };

    my @frames = ();
    for my $frame (@{$exception->frames}){
        my ($module,$filename,$line) = @{$frame};
        push(@frames, {module=>$module, lineno=>$line});
    }
    @frames = reverse @frames;
    my $stacktrace = {frames=>\@frames} if(@frames);
    my $message = $exception->message;

    my $version  = $Mojolicious::VERSION;
    my $codename = $Mojolicious::CODENAME;

    my $json = {
        event_id=>$uuid,
        message=>$message,
        timestamp=>Mojo::Date->new(time)->to_datetime,
        level=>'error',
        logger=>'Mojolicious::Plugin::Sentry',
        platform=>'perl',
        server_name=>hostname,
        environment=>$c->app->mode,
        user=>$user,
        stacktrace=>$stacktrace,
        request=>{
            url=>$c->req->url,
            method=>$c->req->method,
            query_string=>$c->req->url->query->to_hash,
            headers=>$c->req->headers->to_hash,
            env=>\%ENV,
            version=>$c->req->version,
        },
        tags=>{
            moniker=>$c->app->moniker,
        },
        extra=>{
            perl=>"$^V ($^O)",
            mojolicious=>"$version ($codename)",
            home=>$c->app->home,
            moniker=>$c->app->moniker,
            name=>$0,
            executable=>$^X,
            pid=>$$,
        }
    };

    if(my $json = $c->req->json){
        $json->{'request'}->{'data'} = $json;
    }
    elsif(my $body = $c->req->body){
        $json->{'request'}->{'data'} = $body;
    }

    my $tx = $ua->post($url->scheme.'://'.$url->host.'/api'.$url->path.'/store/'=>json=>$json);

    croak "invalid http sentry.io code:".$tx->res->code if($tx->res->code != 200);
    return;
}


1;

__END__


=encoding utf8

=head1 NAME

  Mojolicious::Plugin::Sentry - Mojolicious Plugin for Sentry.io

=head1 SYNOPSIS

  # Mojolicious
  $self->plugin('Sentry'=>{dsn=>'https://username:password@sentry.io/project_id'});

  # Mojolicious::Lite
  plugin 'Sentry' => {dsn=>'https://username:password@sentry.io/project_id'};

=head1 EXAMPLE

 use Mojolicious::Lite;
 use Carp qw(croak);
 plugin 'Sentry' => {dsn=>'https://username:password@sentry.io/project_id'};

 get '/' => sub {
     my $c = shift;
     croak 'test error';
     return $c->render(text => 'Hello word!');
 };

=head1 SEE ALSO

L<Mojolicious>, L<Mojolicious::Guides>, L<http://mojolicious.org>.

=cut
