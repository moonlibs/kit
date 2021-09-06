--[[

kit.1

 Generic functions for Tarantool 1.*
(Until something new or not compatible appeared)

Return of function is better since temporary table is not created
]]

-- Newer versions of tarantool brings table.new and table.clear
-- Since use of this functions considered useful, mimic them if absent

if not table.new then
	table.new = function() return {} end
end

if not table.clear then
	table.clear = function(t)
		if type(t) ~= 'table' then
			error("bad argument #1 to 'clear' (table expected, got "..(t ~= nil and type(t) or 'no value')..")",2)
		end
		for k in pairs(t) do
			t[k] = nil
		end
		return
	end
end

-- cdata-error compatible assert function
-- useful for wrapping so-called `nil, err` returns
if not pcall(assert, false, {}) then
	_G._assert = _G.assert
	function assert(test, ...)
		if not test then
			local msg = select(1, ...)
			if msg then
				error(msg, 2)
			else
				error("assertion failed!", 2)
			end
		end
		return test, ...
	end
end

local HASH_MT = { __serialize = 'mapping' }


local ffi = require 'ffi'
if not (pcall(function() return not not ffi.C.gethostname end)) then
	ffi.cdef[[ int gethostname(char *name, size_t len); ]]
end
if not (pcall(function() return not not ffi.C.strerror end)) then
	ffi.cdef[[ char *strerror(int errnum); ]]
end
local size = 256
local buf = ffi.new('char[?]',size)
local function hostname()
	local ret = ffi.C.gethostname(buf,size)
	if ret == 0 then
		return (string.gsub(ffi.string(buf), "%z+$", ""))
	else
		local log = require 'log'
		log.info("Failed to get hostname: %s",ffi.string(ffi.C.strerror(ffi.errno())))
		return
	end
end

return function(M,I)
	local _node_keys = {
		-- id
		-- uuid
		-- ro
		-- lsn
		-- rw
		name = function() return config and config.get('sys.instance_name') end;
		hostname = hostname;
	};
	I._node_keys = _node_keys

	local _serialize = function(self)
		local t = setmetatable({},HASH_MT)
		for k in pairs(_node_keys) do
			t[k] = self[k]
		end
		return t
	end
	
	M.node = setmetatable({},{
		__newindex = function() error("table is readonly",2) end,
		__index = function(_,k)
			if _node_keys[k] then
				return _node_keys[k]()
			end
		end,
		__serialize = _serialize,
		__call = _serialize,
	})

end
