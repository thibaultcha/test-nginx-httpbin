use Test::Nginx::Socket::Httpbin;

repeat_each(1);

plan tests => blocks() * repeat_each() * 3 + repeat_each() * 3;

$ENV{TEST_NGINX_HTTPBIN_PORT} ||= 9000;

httpbin();

run_tests();

__DATA__

=== TEST 1: /status returns given status code
--- config
    location = /t {
        proxy_pass http://127.0.0.1:9000/status/201;
    }
--- request
GET /t
--- error_code: 201
--- response_body

--- no_error_log
[error]



=== TEST 2: /status returns 404 on invalid code
--- config
    location = /t {
        set $port $TEST_NGINX_HTTPBIN_PORT;

        content_by_lua_block {
            local port = ngx.var.port

            local function make_request(status)
                local sock = ngx.socket.tcp()
                local ok, err = sock:connect("127.0.0.1", port)
                if not ok then
                    ngx.say("failed to connect: ", err)
                    return
                end

                local req = "GET /status/" .. status .. " HTTP/1.1\r\nHost: httpbin.org\r\nConnection: close\r\n\r\n"

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

            make_request(2001)
            make_request("foo")
            make_request(20)
            make_request(2)
            make_request(200)
        }
    }
--- request
GET /t
--- response_body
HTTP/1.1 404 Not Found
HTTP/1.1 404 Not Found
HTTP/1.1 404 Not Found
HTTP/1.1 404 Not Found
HTTP/1.1 200 OK
--- error_code: 200
--- error_log
[error]



=== TEST 3: /status returns a teapot
--- config
    location = /t {
        proxy_pass http://127.0.0.1:9000/status/418;
    }
--- request
GET /t
--- error_code: 418
--- response_headers
Content-Length: 135
x-more-info: http://tools.ietf.org/html/rfc2324
--- raw_response_headers_unlike
Content-Type:
--- response_body_like

-=[ teapot ]=-

   _...._
 .'  _ _ `.
| ."` ^ `". _,
\_;`"---"`|//
  |       ;/
  \_     _/
    `"""`

--- no_error_log
[error]
