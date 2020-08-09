---
-- Read more: https://github.com/moonlibs/tarantool/blob/stable/src/lua/bsdsocket.lua
local box_socket = assert(rawget(_G.box, 'socket'), "no box.socket")

local create_socket = select(2, debug.getupvalue(getmetatable(box_socket).__call, 1))
local internal = select(2, debug.getupvalue(create_socket, 2))

local socket = {
	tcp_connect = box_socket.tcp_connect,
	tcp_server  = box_socket.tcp_server,
	getaddrinfo = box_socket.getaddrinfo,
	iowait      = internal.iowait,
}

return setmetatable(socket, {
	__call = function(_, ...) return create_socket(...)  end,
})
