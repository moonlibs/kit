--[[

kit.1

 Generic functions for Tarantool 1.*
(Until something new or not compatible appeared)

Return of function is better since temporary table is not created
]]

return function(M,I)
	local _node_keys = {
		id    = true,
		uuid  = true,
		ro    = true,
		lsn   = true,
	};
	I._node_keys = _node_keys

	local _serialize = function(self)
		local t = {}
		for k in pairs(_node_keys) do
			t[k] = self[k]
		end
		t.rw = not t.ro
		return t
	end

	M.node = setmetatable({},{
		__newindex = function() error("table is readonly",2) end,
		__index = function(_,k) error(".node.__index to be defined",2) end,
		__serialize = _serialize,
		__call = _serialize,
	})

end
