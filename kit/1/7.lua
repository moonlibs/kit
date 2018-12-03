local fiber = require 'fiber'

return function(M, I)
	function M.schema_version()
		return box.internal.schema_version()
	end

	function M.wait_lsn(server_id, lsn, timeout, pause)
		server_id = server_id or M.node.id
		pause = pause or 0.01
		if box.info.replication[server_id].lsn >= lsn then return true end
		local start = fiber.time()
		repeat
			fiber.sleep(pause)
		until box.info.replication[server_id].lsn >= lsn or ( timeout and fiber.time() > start + timeout )
		return box.info.replication[server_id].lsn >= lsn
	end
	
	local _node_keys = I._node_keys
	local node_functions_raw = {
		id    = { function() return box.info.id   end,           box.NULL };
		uuid  = { function() return box.info.uuid end,           box.NULL };
		lsn   = { function() return box.info.lsn  end,           box.NULL };
		ro    = { function() return box.info.ro   end,               true };
		rw    = { function() return not box.info.ro == true end,    false };
	}

	local function unmask()
		for k,v in pairs(node_functions_raw) do
			_node_keys[k] = v[1]
		end
	end
	
	for k,v in pairs(node_functions_raw) do
		_node_keys[k] = function()
			if type(box.cfg) == 'function' then
				return v[2]
			end
			unmask()
			return v[1]()
		end
	end
end
