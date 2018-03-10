local _VERSION = '0.02'

if rawget(_G,'kit') then
	if kit._VERSION == _VERSION then
		return kit
	end
end

-- Some awareness
assert(_TARANTOOL,"Module requires Tarantool")
if _TARANTOOL > '2.0' or _TARANTOOL < '1.6.0' then
	error(string.format("Version %s not supported", _TARANTOOL))
end

local maj,min,mic,bld = _TARANTOOL:match("(%d+)%.(%d+)%.(%d+)-(%d+)")
assert(maj,"Failed to parse version")

--[[

Note for developers:

1. Versions are loaded in descending order:

- 1.lua
- 1/6.lua
- 1/6/9.lua
- 1/6/9-90.lua
- 1/6/9-90-g4c94e94.lua

2. Submodule may be 2 of a kind:

- A table. In this case all fields of table will be copied into main table and returned table will be discarded

- A function. In this case it will be called with original copy of main table and index table

3. There could be defined some temporary helper methods in metatable. It would be discarded before return.

]]

local M = setmetatable({
	_VERSION = _VERSION;
},{ __index = {
	-- NOTE: here may be load-time methods
} })


local function extend(m,mod)

	-- local ext = tryload(mod,1)

	local name = 'kit.'..mod
	local r,ext = pcall(require, name)
	-- print(name, r, ext)
	if not r then
		-- local ers = string.split(ext,"\n\t")
		-- print(require'yaml'.encode(ers))

		local errors = {}
		-- -- for x in ext:gmatch("([^\r\n]+)") do
		-- for x in ext:gmatch("([^\r\n]+)\n\t") do
		-- 	if x:match("^%s+no file") then
		-- 	elseif x:match("^%s+no field package%.preload%[[^%]]+%]$") then
		-- 	else
		-- 		x = x:gsub("no field package%.preload%[[^%]]+%]","",1)
		-- 		table.insert(errors,x)
		-- 	end
		-- end

		local ix = 0
		local a,b
		repeat
			a,b = ext:find("\n\t",ix,true)
			if not a then a = #ext+1 end
			local er = ext:sub(ix,a-1):gsub("^%s+","",1):gsub("\n","")
			-- print(er)
			if er:match("^%s*no file") then
			elseif er:match("^%s*no field package%.preload%[[^%]]+%]$") then
			else
				er = er:gsub("no field package%.preload%[[^%]]+%]","",1)
				-- print(er)
				table.insert(errors,er)
			end
			ix = b
		until not b


		if #errors > 1 then
			-- print(mod.." failed to load")
			error(table.concat(errors,"\n"),2)
		end
		return
	end
	if ext then
		-- print(mod.." found ", ext)
		if type(ext) == 'function' then
			ext(m, getmetatable(m).__index)
		elseif type(ext) == 'table' then
			for k,v in pairs(ext) do
				rawset(m,k,v)
			end
		else
			error("Failed to load "..mod..".lua: bad return type: "..type(ext))
		end
		m._FOR = mod
	else
		print(mod.." not found")
	end
end

extend(M, maj)
extend(M, maj..'.'..min)
extend(M, maj..'.'..min..'.'..mic)
extend(M, maj..'.'..min..'.'..mic..'-'..bld)
extend(M, _TARANTOOL)

setmetatable(M,{
	__newindex = function() error("Readonly", 2) end,
	__index = {
		-- NOTE: here may be run-time methods
	};
})

return M
