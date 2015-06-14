use strict;
use warnings;
use utf8;
use 5.10.0;

use DDP;
use Encode;
use WebService::Slack::RtmApi;

my $slack = WebService::Slack::RtmApi->new(token => 'access token');

# dump all event object
$slack->add_read_handler(sub {
    my $obj = shift;
    say encode_utf8('dump: ' . p $obj);
});

# show only message text
$slack->add_read_handler(sub {
    my $obj = shift;
    return unless $obj->{type} eq 'message';
    say encode_utf8('text: ' . $obj->{text});
});

$slack->connect;
for my $i (1..300) {
    $slack->read;
    $slack->ping if $i % 30 == 0;
    sleep 1;
}
$slack->disconnect;

