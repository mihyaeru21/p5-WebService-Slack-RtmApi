package WebService::Slack::RtmApi;
use strict;
use warnings;
use 5.10.0;

our $VERSION = "0.01";

use JSON::XS;
use IO::Socket;
use IO::Socket::SSL;
use Protocol::WebSocket::Client;
use WebService::Slack::WebApi;

use Class::Accessor::Lite::Lazy (
    new     => 1,
    rw      => [qw/ team_domain token socket client id /],
    ro_lazy => [qw/ web_api handlers json /],
);

sub _build_json     { JSON::XS->new->utf8(0) }
sub _build_handlers { [] }
sub _build_web_api {
    my $self = shift;
    WebService::Slack::WebApi->new(
        team_domain => $self->team_domain,
        token       => $self->token,
    );
}

sub add_read_handler {
    my ($self, $callback) = @_;
    push @{$self->handlers}, $callback;
}

sub get_next_id {
    my $self = shift;
    return $self->id($self->id + 1);
}

sub connect {
    my $self = shift;

    # FIXME: handle exception

    my $connect_info = $self->web_api->rtm->start;
    my $url = $connect_info->{url};
    my ($host) = $url =~ m{wss://(.+)/websocket};

    $self->socket(IO::Socket::SSL->new(PeerHost => $host, PeerPort => 443)) or die "failed to open socket: $!";
    $self->socket->blocking(0);

    $self->client(Protocol::WebSocket::Client->new(url => $url));
    $self->client->on(read => sub {
        my ($client, $buffer) = @_;
        my $object = $self->json->decode($buffer);
        $_->($object) for @{$self->handlers};
    });
    $self->client->on(write => sub {
        my ($client, $buffer) = @_;
        syswrite $self->socket, $buffer;
    });
    $self->client->on(error => sub {
        my ($client, $error) = @_;
        warn 'on_error: ', $error;
    });

    # initialize unique id in connection
    $self->id(0);

    $self->socket->connect;
    $self->client->connect;
}

sub disconnect {
    my $self = shift;
    $self->client->disconnect if defined $self->client;
    $self->socket->close      if defined $self->socket;
}

sub read {
    my $self = shift;

    my $buffer = '';
    while (my $line = readline $self->socket) {
        $buffer .= $line;
        last if $line eq "\r\n";
    }
    $self->client->read($buffer) if $buffer;
}

sub post {
    my ($self, $buffer) = @_;
    $self->client->write($buffer);
}

sub ping {
    my $self = shift;
    $self->post(sprintf '{"id":%d,"type":"ping"}', $self->get_next_id);
}

sub DESTROY {
    my $self = shift;
    $self->disconnect;
}

1;
__END__

=encoding utf-8

=head1 NAME

WebService::Slack::RtmApi - It's new $module

=head1 SYNOPSIS

    use WebService::Slack::RtmApi;

=head1 DESCRIPTION

WebService::Slack::RtmApi is ...

=head1 LICENSE

Copyright (C) Mihyaeru/mihyaeru21

Released under the MIT license.

See C<LICENSE> file.

=head1 AUTHOR

Mihyaeru/mihyaeru21 E<lt>mihyaeru21@gmail.comE<gt>

=cut

