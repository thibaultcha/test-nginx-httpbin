use Test::Nginx::Socket::Httpbin;
use Cwd qw(cwd);

repeat_each(1);

plan tests => blocks() * repeat_each() * 3;

my $pwd = cwd();

our $HttpConfig = <<_EOC_;
    lua_package_path "$pwd/lib/?.lua;../lua-resty-lrucache/lib/?.lua;;";
    init_by_lua_block {
        function dump(t, lvl)
            if not lvl then
                lvl = 0
            end

            local arr = {}
            local indent = string.rep(" ", lvl * 2)

            for k, v in pairs(t) do
                table.insert(arr, { k, v })
            end

            table.sort(arr, function(a, b)
                return a[1] < b[1]
            end)

            for _, v in ipairs(arr) do
                if type(v[2]) == "table" then
                    ngx.say(indent, v[1])
                    dump(v[2], lvl + 1)
                else
                    ngx.say(indent, v[1], ": ", v[2])
                end
            end
        end
    }
_EOC_

httpbin();

run_tests();

__DATA__

=== TEST 1: /post returns POST data
--- http_config eval: $::HttpConfig
--- config
    location = /proxy {
        proxy_pass http://127.0.0.1:9000/post;
    }

    location = /t {
        content_by_lua_block {
            local cjson = require "cjson"

            local res = ngx.location.capture("/proxy", {
                method = ngx.HTTP_POST,
                always_forward_body = true,
            })

            if res.status ~= 200 then
                ngx.status = res.status
                ngx.print(res.body)
                return
            end

            local json = cjson.decode(res.body)
            dump(json)
        }
    }
--- request
POST /t
--- response_body_like chop
args
data:\s
files
form
headers
  connection: close
  host: 127\.0\.0\.1:9000
json: null
origin: 127\.0\.0\.1
url: http:\/\/127\.0\.0\.1\/post
--- no_error_log
[error]



=== TEST 2: /post returns POST data (args)
--- http_config eval: $::HttpConfig
--- config
    location = /proxy {
        proxy_pass http://127.0.0.1:9000/post;
    }

    location = /t {
        content_by_lua_block {
            local cjson = require "cjson"

            local res = ngx.location.capture("/proxy" .. ngx.var.is_args .. ngx.var.args, {
                method = ngx.HTTP_POST,
                always_forward_body = true,
            })

            if res.status ~= 200 then
                ngx.status = res.status
                ngx.print(res.body)
                return
            end

            local json = cjson.decode(res.body)
            dump(json)
        }
    }
--- request
POST /t?foo=bar
--- response_body_like chop
args
  foo: bar
data:\s
files
form
headers
  connection: close
  host: 127\.0\.0\.1:9000
json: null
origin: 127\.0\.0\.1
url: http:\/\/127\.0\.0\.1\/post
--- no_error_log
[error]



=== TEST 3: /post only accepts POST method
--- config
    location = /t {
        proxy_method GET;
        proxy_pass http://127.0.0.1:9000/post;
    }
--- request
POST /t
--- response_body
The method is not allowed for the requested URL
--- error_code: 405
--- no_error_log
[error]
