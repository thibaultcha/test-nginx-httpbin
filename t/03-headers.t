use Test::Nginx::Socket::Httpbin;

repeat_each(1);

plan tests => blocks() * repeat_each() * 3;

httpbin();

run_tests();

__DATA__

=== TEST 1: /headers returns request headers
--- config
    location = /t {
        proxy_pass http://127.0.0.1:9000/headers;
    }
--- request
GET /t
--- response_body
{"headers":{"host":"127.0.0.1:9000","connection":"close"}}
--- no_error_log
[error]



=== TEST 2: /headers only accepts GET method
--- config
    location = /t {
        proxy_method POST;
        proxy_pass http://127.0.0.1:9000/headers;
    }
--- request
GET /t
--- response_body
The method is not allowed for the requested URL
--- error_code: 405
--- no_error_log
[error]
