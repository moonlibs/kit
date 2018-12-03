local fiber = require 'kit.1.5.fiber'

package.preload.fiber = function()
	return require 'kit.1.5.fiber'
end

local log = require 'log'
log.debug = log.info

return function(M,I)

	if not rawget(box,'NULL') then
		rawset(box,'NULL',require'ffi'.typeof('void *')(nil))
	end
	
	function M.schema_version()
		return 0
	end
	
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
	
	for k,v in pairs(_node_keys) do
		I._node_keys[k] = v
	end
end
