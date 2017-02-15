use Test::Nginx::Socket::Httpbin;

repeat_each(1);

plan tests => blocks() * repeat_each() * 3;

$ENV{TEST_NGINX_HTTPBIN_PORT} ||= 9000;

httpbin(3);

run_tests();

__DATA__

=== TEST 1: spawn multiple httpbin mocks
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
--- response_body
HTTP/1.1 200 OK
HTTP/1.1 200 OK
HTTP/1.1 200 OK
--- error_code: 200
--- no_error_log
[error]
