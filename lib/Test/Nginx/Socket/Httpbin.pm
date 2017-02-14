package Test::Nginx::Socket::Httpbin;

use strict;
use warnings;
use Test::Nginx::Socket -base;

our $VERSION = '0.01';

our $UseHttpbin = $ENV{TEST_NGINX_USE_HTTPBIN} || 0;

my $httpbin_conf = do { local $/; <DATA> };

sub httpbin {
    $UseHttpbin = 1;
}

sub inject_httpbin {
    my $block = shift;
    local $UseHttpbin = $UseHttpbin;

    if (defined $block->no_httpbin) {
        $UseHttpbin = 0;

    } elsif (defined $block->httpbin) {
        $UseHttpbin = 1;
    }

    if ($UseHttpbin) {
        my $http_config = $block->http_config;

        if (!defined $http_config) {
            $http_config = '';
        }

        $block->set_value('http_config' => qq{
            $http_config
            $httpbin_conf
        });
    }
}

our @EXPORT = qw(
    httpbin
);

add_block_preprocessor(\&inject_httpbin);

1;
__DATA__
server {
    listen 9000;
    server_name httpbin.org;

    location /get {
        return 200;
    }
}
