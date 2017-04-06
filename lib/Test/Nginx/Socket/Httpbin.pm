package Test::Nginx::Socket::Httpbin;

use strict;
use warnings;
use Test::Nginx::Socket -base;

our $VERSION = '0.01';

our $UseHttpbin = $ENV{TEST_NGINX_USE_HTTPBIN} || 0;
our $HttpbinPort = $ENV{TEST_NGINX_HTTPBIN_PORT} || 9000;
our $HttpbinHost = $ENV{TEST_NGINX_HTTPBIN_HOST} || 'httpbin.org';
our $HttpbinInstances = $ENV{TEST_NGINX_HTTPBIN_INSTANCES} || 1;

my $httpbin_conf_template = do { local $/; <DATA> };

sub httpbin {
    $UseHttpbin = 1;

    my $n = shift;
    if (defined $n && $n > 0) {
        $HttpbinInstances = $n;
    }
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
        local $HttpbinPort = $HttpbinPort;

        for my $i (0..$HttpbinInstances - 1) {
            my $httpbin_conf = $httpbin_conf_template;
            my $HttpbinPort = $HttpbinPort + $i;

            my $http_config = $block->http_config;
            if (!defined $http_config) {
                $http_config = '';
            }

            $httpbin_conf =~ s/(\$\w+)/$1/eeg;

            $block->set_value('http_config' => qq{
                $http_config
                $httpbin_conf
            });
        }
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


    location = /ip {
        access_by_lua_block {
            if ngx.req.get_method() ~= "GET" then
                ngx.status = ngx.HTTP_NOT_ALLOWED
                ngx.say("The method is not allowed for the requested URL")
                return ngx.exit(ngx.HTTP_NOT_ALLOWED)
            end
        }

        content_by_lua_block {
            local cjson = require "cjson"

            ngx.say(cjson.encode {
                origin = ngx.var.remote_addr
            })
        }
    }


    location = /headers {
        access_by_lua_block {
            if ngx.req.get_method() ~= "GET" then
                ngx.status = ngx.HTTP_NOT_ALLOWED
                ngx.say("The method is not allowed for the requested URL")
                return ngx.exit(ngx.HTTP_NOT_ALLOWED)
            end
        }

        content_by_lua_block {
            local cjson = require "cjson"

            ngx.say(cjson.encode {
                headers = ngx.req.get_headers()
            })
        }
    }


    location = /get {
        access_by_lua_block {
            if ngx.req.get_method() ~= "GET" then
                ngx.status = ngx.HTTP_NOT_ALLOWED
                ngx.say("The method is not allowed for the requested URL")
                return ngx.exit(ngx.HTTP_NOT_ALLOWED)
            end
        }

        content_by_lua_block {
            local cjson = require "cjson"

            local headers = ngx.req.get_headers()
            local origin = ngx.var.remote_addr
            local args = ngx.req.get_uri_args()
            local url = string.format("%s://%s%s", ngx.var.scheme,
                                                   ngx.var.host,
                                                   ngx.var.request_uri)

            local t     = {
                url     = url,
                args    = args,
                origin  = origin,
                headers = headers,
            }

            ngx.say(cjson.encode(t))
        }
    }


    location = /post {
        access_by_lua_block {
            if ngx.req.get_method() ~= "POST" then
                ngx.status = ngx.HTTP_NOT_ALLOWED
                ngx.say("The method is not allowed for the requested URL")
                return ngx.exit(ngx.HTTP_NOT_ALLOWED)
            end
        }

        content_by_lua_block {
            local cjson = require "cjson"
            local cjson_safe = require "cjson.safe"

            local headers = ngx.req.get_headers()
            local origin = ngx.var.remote_addr
            local args = ngx.req.get_uri_args()
            local url = string.format("%s://%s%s", ngx.var.scheme,
                                                   ngx.var.host,
                                                   ngx.var.request_uri)

            local json
            local data = ""
            local form = {}
            local files = {} -- not supported

            local ct = headers["content-type"]
            if ct then
                ngx.req.read_body()

                if string.find(ct, "application/x-www-form-urlencoded",
                   nil, true) then
                    form = ngx.req.get_post_args()

                elseif string.find(ct, "application/json", nil, true) then
                    local err
                    data, err = ngx.req.get_body_data()
                    if not data then
                        ngx.log(ngx.ERR, "could not read body data: ", err)
                        return ngx.exit(ngx.HTTP_INTERNAL_SERVER_ERROR)
                    end

                    -- httpbin just ignores decoding errors
                    json = cjson_safe.decode(data)
                end
            end

            local t     = {
                args    = args,
                data    = data,
                files   = files,
                form    = form,
                headers = headers,
                json    = json or cjson.null,
                origin  = origin,
                url     = url,
            }

            ngx.say(cjson.encode(t))
        }
    }


    location ~ "/status/(?<code>\d{3})$" {
        content_by_lua_block {
            local code = tonumber(ngx.var.code)

            if not code then
                return ngx.exit(ngx.HTTP_NOT_FOUND)
            end

            ngx.status = code

            if code == 418 then
                local teapot = [[

    -=[ teapot ]=-

       _...._
     .'  _ _ `.
    | ."` ^ `". _,
    \_;`"---"`|//
      |       ;/
      \_     _/
        `"""`]]

                ngx.header["X-More-Info"] = "http://tools.ietf.org/html/rfc2324"
                ngx.header["Content-Length"] = #teapot + 1
                ngx.header["Content-Type"] = nil
                ngx.say(teapot)
            end
        }
    }
}
