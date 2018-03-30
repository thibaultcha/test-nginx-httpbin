use Test::Nginx::Socket::Httpbin;

repeat_each(1);

plan tests => blocks() * repeat_each() * 2;

$ENV{TEST_NGINX_HTTPBIN_PORT} ||= 9000;

#httpbin();

run_tests();

__DATA__

=== TEST 1: spawn httpbin mock from blocks
--- httpbin
--- config
    location = /t {
        proxy_pass http://127.0.0.1:9000/get;
    }
--- request
GET /t
--- error_code: 200
--- ignore_response
--- no_error_log
[error]



=== TEST 2: do not spawn httpbin mock if not specified
--- config
    location = /t {
        proxy_pass http://127.0.0.1:9000/get;
    }
--- request
GET /t
--- error_code: 502
--- ignore_response
--- error_log
[error]



=== TEST 3: spawn multiple httpbin mocks from blocks
--- httpbin: 3
--- config
    location = /t {
        set $port $TEST_NGINX_HTTPBIN_PORT;

        content_by_lua_block {
            local function make_request(port)
                local sock = ngx.socket.tcp()
                local ok, err = sock:connect("127.0.0.1", port)
                if not ok then
                    ngx.say("failed to connect: ", err)
                    return
                end

                local req = "GET /get HTTP/1.1\r\nHost: httpbin.org\r\nConnection: close\r\n\r\n"

                local bytes, err = sock:send(req)
                if not bytes then
                    ngx.say("failed to send request: ", err)
                    return
                end

                local status_line, err = sock:receive()
                if err then
                    ngx.say("failed to receive a line: ", err)
                    return
                end

                ngx.say(status_line)

                while true do
                    local line = sock:receive()
                    if not line then
                        break
                    end
                end

                sock:close()
            end

            local port = ngx.var.port

            make_request(port)
            make_request(port + 1)
            make_request(port + 2)
        }
    }
--- request
GET /t
--- error_code: 200
--- response_body
HTTP/1.1 200 OK
HTTP/1.1 200 OK
HTTP/1.1 200 OK
--- no_error_log
[error]
[crit]
