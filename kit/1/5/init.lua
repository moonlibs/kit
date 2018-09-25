local fiber = require 'kit.1.5.fiber'

package.preload.fiber = function()
	return require 'kit.1.5.fiber'
end

package.preload.log = function()
	return require 'kit.1.5.log'
end

return function(M)
	
	function M.wait_lsn(server_id, lsn, timeout, pause)
		pause = pause or 0.01
		local start = fiber.time()
		while box.info.lsn < lsn do
			if timeout and fiber.time() > start + timeout then break end
			fiber.sleep(pause)
		end
		return box.info.lsn >= lsn
	end


	local _node_keys = {
		rw    = function() return box.info.status == 'primary' end,
		ro    = function() return box.info.status ~= 'primary' end,
		lsn   = function() return box.info.lsn end,
		
		-- stubs
		id    = function() return 1 end,
		uuid  = function() return '...' end,
	};

	getmetatable(M.node).__index = function(_,k)
		if _node_keys[k] then
			return _node_keys[k]()
		end
		return
	end
	
end
