use Test::Nginx::Socket::Httpbin;

repeat_each(1);

plan tests => blocks() * repeat_each() * 2;

httpbin();

run_tests();

__DATA__

=== TEST 1: spawn httpbin mock for blocks
--- config
    location = /t {
        proxy_pass http://127.0.0.1:9000/get;
    }
--- request
GET /t
--- error_code: 200
--- no_error_log
[error]



=== TEST 2: no_httpbin disables httpbin for block
--- no_httpbin
--- config
    location = /t {
        proxy_pass http://127.0.0.1:9000/get;
    }
--- request
GET /t
--- error_code: 502
--- error_log
Connection refused



=== TEST 3: does not override http_config section
--- http_config
    init_by_lua_block {
        print("do not override")
    }
--- config
    location = /t {
        proxy_pass http://127.0.0.1:9000/get;
    }
--- request
GET /t
--- error_code: 200
--- error_log eval
qr{\[notice\] .*? do not override}
