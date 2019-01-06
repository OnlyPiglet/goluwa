local ffi = require("ffi")
local socket = require("bsocket")

local host = "www.lunduke.com"

local res = ffi.new("struct addrinfo*[1]")

assert(socket.getaddrinfo(host, "http", ffi.new("struct addrinfo", {
    ai_family = e.AF_INET,
    ai_socktype = e.SOCK_STREAM,
    ai_protocol = e.IPPROTO_TCP,
}), res))

local STAGE = "connect"

-- Create a SOCKET for connecting to server
local client = assert(socket.socket(res[0].ai_family, res[0].ai_socktype, res[0].ai_protocol))
assert(socket.socket_blocking(client, false))



local str = ""
local total_length

local buff = ffi.new("char[1024]")
event.AddListener("Update", "test", function()
    if STAGE == "connect" then
        local ret, err = socket.socket_connect(client, res[0].ai_addr, res[0].ai_addrlen)

        if not socket.wouldblock() then
            local header = "GET / HTTP/1.1\r\n"..
            "Host: "..host.."\r\n"..
            "User-Agent: Mozilla/5.0 (X11; Ubuntu; Linux x86_64; rv:64.0) Gecko/20100101 Firefox/64.0\r\n"..
            "Accept: text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8\r\n"..
            "Accept-Language: nb,nb-NO;q=0.9,en;q=0.8,no-NO;q=0.6,no;q=0.5,nn-NO;q=0.4,nn;q=0.3,en-US;q=0.1\r\n"..
            --"Accept-Encoding: gzip, deflate\r\n"..
            "DNT: 1\r\n"..
            "Connection: keep-alive\r\n"..
            "Upgrade-Insecure-Requests: 1\r\n"..
            "\r\n"

            socket.socket_send(client, header, #header, 0)

            STAGE = "send"
        end
    else
        local len = socket.socket_recv(client, buff, ffi.sizeof(buff), 0)
        if not socket.wouldblock() then
            error(socket.lasterror())
        end
        if len > 0 then
            str = str .. ffi.string(buff, len)

            if not total_length then
                total_length = tonumber(str:match("Content%-Length: (%d+)"))
            end

            if #str >= total_length then
                event.RemoveListener("Update", "test")
                print(str)
            end
        end
    end
end)