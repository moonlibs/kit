return function(M,I)
	require 'kit.1'(M, I)
	require 'kit.1.10'(M, I)

	function M.schema_version()
		return box.info.schema_version
	end

	I._node_keys.hostname = function()
		return box.info.hostname
	end
	I._node_keys.name = function()
		return box.info.name
	end
end
