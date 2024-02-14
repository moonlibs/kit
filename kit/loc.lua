local _VERSION = '2'

if rawget(_G,'kit') then
	if kit._VERSION == _VERSION then
		return kit
	end
end

-- Some awareness
if not _TARANTOOL then
	if rawget(_G,'box') and rawget(box,'info') then
		_TARANTOOL = box.info.version
	end
end

assert(_TARANTOOL,"Module requires Tarantool")

local maj,min,mic,bld = _TARANTOOL:match("(%d+)%.(%d+)%.(%d+)-(%d+)")
if not maj then
	maj,min,mic,bld = _TARANTOOL:match("(%d+)%.(%d+)%.(%d+)-([%w%d]+%-%d+)")
end
if not maj then
	maj,min,mic,bld = _TARANTOOL:match("(%d+)%.(%d+)%.(%d+)-([%w%d]+)")
end
assert(maj,"Failed to parse version ".._TARANTOOL)

repeat
	if (0+maj) == 1 then
		if (0+min) >= 5 then break end -- 1.5+ is acceptable
	elseif (0+maj) == 2 then
		if (0+min) <= 11 then break end -- <= 2.10 is acceptable
	elseif (0+maj) == 3 then
		if (0+min) == 0 then break end -- < 3.1 is acceptable
	end
	error(string.format("Version %s not supported", _TARANTOOL))
until true

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
	_FOR = {};
},{ __index = {
	-- NOTE: here may be load-time methods
} })

local function extend(m,mod)

	-- local ext = tryload(mod,1)

	local name = 'kit.'..mod
	local ext = require(name)
	if ext then
		-- print(mod.." found ", ext)
		if type(ext) == 'function' then
			ext(m, getmetatable(m).__index)
		elseif type(ext) == 'table' then
			for k,v in pairs(ext) do
				rawset(m,k,v)
			end
		elseif type(ext) == 'boolean' and ext == false then
			-- false is apecial value for skip
		else
			error("Failed to load "..mod..".lua: bad return type: "..type(ext))
		end
		table.insert(m._FOR, mod)
	else
		-- print(mod.." not found")
	end
end

local function myloader(nm)
	return function(...) return false end
end

table.insert(package.loaders, myloader)
extend(M, maj)
if tonumber(maj) > 1 or tonumber(min) > 5 then
	-- all versions greater than 1.5
	extend(M, '1.6+')
end
extend(M, maj..'.'..min)
extend(M, maj..'.'..min..'.'..mic)
extend(M, maj..'.'..min..'.'..mic..'-'..bld)
extend(M, _TARANTOOL)

for i,v in pairs(package.loaders) do
	if v == myloader then
		table.remove(package.loaders,i)
	end
end

setmetatable(M,{
	__newindex = function() error("Readonly", 2) end,
	__index = {
		-- NOTE: here may be run-time methods
	};
})

return M
