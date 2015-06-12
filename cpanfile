requires 'perl', '5.008001';

requires 'IO::Socket::SSL';
requires 'Protocol::WebSocket::Client';
requires 'WebService::Slack::WebApi';

on 'test' => sub {
    requires 'Test::More', '0.98';
};

