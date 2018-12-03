function box.sandbox () end

print(package.loaded.log)
local log = require 'log'
for k,v in pairs(log) do
	print(k, ' ' ,v)
end

package.path = '../?.lua;../?/init.lua;'..package.path

require 'kit'

local log = require 'log'
local fiber = require 'fiber'

print("kit.node.hostname = ",kit.node.hostname)
print("kit.node.lsn = ",kit.node.lsn)
print("kit.node = ",box.cjson.encode(kit.node))

log.debug("It' log debug")
log.info("It' log")
log.warn("It' log warn")
log.error("It' log error")



print("kit.node() = ",box.cjson.encode(kit.node()))
