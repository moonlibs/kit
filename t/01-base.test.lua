#!/usr/bin/env tarantool

if os.getenv("LUACOV_ENABLE") then
    print("enabling luacov")
    require 'luacov.runner'.init()
end

local kit = require 'kit'
box.cfg{}

local tap = require 'tap'
local t = tap.test("base")

t:is(kit.node.ro, box.info.ro, "kit.node.ro")
t:is(kit.node.lsn, box.info.lsn, "kit.node.lsn")
t:is(kit.node.rw, not box.info.ro, "kit.node.rw")
t:is(kit.node.uuid, box.info.uuid, "kit.node.uuid")
t:is(kit.node.id, box.info.id, "kit.node.id")

t:isstring(kit.node.hostname, "kit.node.hostname is string")

t:ok(kit.wait_lsn(kit.node.id, kit.node.lsn, 0), "wait_lsn(lsn, 0)")
t:ok(kit.wait_lsn(kit.node.id, kit.node.lsn, 0), "wait_lsn(lsn, 0)")

t:is(kit.wait_lsn(kit.node.id, kit.node.lsn+1, 0), false, "wait_lsn(lsn+1, 0)")

t:plan(t.total)

if t.failed > 0 then
	os.exit(1)
else
	os.exit(0)
end
