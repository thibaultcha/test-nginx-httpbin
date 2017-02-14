package Test::Nginx::Socket::Httpbin;

use strict;
use warnings;
use Test::Nginx::Socket -base;

our $VERSION = '0.01';

our $UseHttpbin = $ENV{TEST_NGINX_USE_HTTPBIN} || 0;
our $HttpbinPort = $ENV{TEST_NGINX_HTTPBIN_PORT} || 9000;
our $HttpbinHost = $ENV{TEST_NGINX_HTTPBIN_HOST} || 'httpbin.org';

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

        local $HttpbinPort = $HttpbinPort;

        $httpbin_conf =~ s/(\$\w+)/$1/eeg;

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
    listen $HttpbinPort;
    server_name $HttpbinHost;

    location /get {
        return 200;
    }
}
