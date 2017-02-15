use Test::Nginx::Socket::Httpbin;

repeat_each(1);

plan tests => blocks() * repeat_each() * 3;

httpbin();

run_tests();

__DATA__

=== TEST 1: /post returns POST data
--- config
    location = /t {
        proxy_pass http://127.0.0.1:9000/post;
    }
--- request
POST /t
--- response_body
{"json":null,"origin":"127.0.0.1","data":"","form":{},"url":"http:\/\/127.0.0.1\/post","args":{},"files":{},"headers":{"host":"127.0.0.1:9000","connection":"close"}}
--- no_error_log
[error]



=== TEST 2: /post returns POST data (args)
--- config
    location = /t {
        proxy_pass http://127.0.0.1:9000/post;
    }
--- request
POST /t?foo=bar
--- response_body
{"json":null,"origin":"127.0.0.1","data":"","form":{},"url":"http:\/\/127.0.0.1\/post?foo=bar","args":{"foo":"bar"},"files":{},"headers":{"host":"127.0.0.1:9000","connection":"close"}}
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
