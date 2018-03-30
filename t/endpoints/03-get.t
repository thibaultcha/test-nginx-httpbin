use Test::Nginx::Socket::Httpbin;

repeat_each(1);

plan tests => blocks() * repeat_each() * 3;

httpbin();

run_tests();

__DATA__

=== TEST 1: /get returns GET data
--- config
    location = /t {
        proxy_pass http://127.0.0.1:9000/get?foo=bar;
    }
--- request
GET /t
--- response_body
{"url":"http:\/\/127.0.0.1\/get?foo=bar","headers":{"host":"127.0.0.1:9000","connection":"close"},"origin":"127.0.0.1","args":{"foo":"bar"}}
--- no_error_log
[error]



=== TEST 2: /get only accepts GET method
--- config
    location = /t {
        proxy_method POST;
        proxy_pass http://127.0.0.1:9000/get;
    }
--- request
GET /t
--- response_body
The method is not allowed for the requested URL
--- error_code: 405
--- no_error_log
[error]
