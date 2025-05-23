#!/usr/bin/env tarantool

local ok, runner = pcall(require, 'luacov.runner')
if ok then
	print("Running luacov")
	runner.init()
end

local kit = require 'kit'
local tap = require 'tap'
local t = tap.test("base")

-- before box.cfg
t:is(kit.node.ro, true, "kit.node.ro - before box.cfg")
t:is(kit.node.lsn, box.NULL, "kit.node.lsn - before box.cfg")
t:is(kit.node.rw, false, "kit.node.rw - before box.cfg")
t:is(kit.node.uuid, box.NULL, "kit.node.uuid - before box.cfg")
t:is(kit.node.id, box.NULL, "kit.node.id - before box.cfg")
t:is(kit.node.name, box.NULL, "kit.node.name - before box.cfg")
t:isstring(kit.node.hostname, "kit.node.hostname - before box.cfg")

box.cfg{log_level=4}


-- unmasking in some versions
t:is(kit.node.ro, box.info.ro, "kit.node.ro")
t:is(kit.node.ro, box.info.ro, "kit.node.ro")
t:is(kit.node.lsn, box.info.lsn, "kit.node.lsn")
t:is(kit.node.lsn, box.info.lsn, "kit.node.lsn")
t:is(kit.node.rw, not box.info.ro, "kit.node.rw")
t:is(kit.node.rw, not box.info.ro, "kit.node.rw")
t:is(kit.node.uuid, box.info.uuid, "kit.node.uuid")
t:is(kit.node.uuid, box.info.uuid, "kit.node.uuid")
t:is(kit.node.id, box.info.id, "kit.node.id")
t:is(kit.node.id, box.info.id, "kit.node.id")
t:is(kit.node.name, box.NULL, "kit.node.name")
t:is(kit.node.name, box.NULL, "kit.node.name")
t:isstring(kit.node.hostname, "kit.node.hostname is string")

t:isnumber(kit.schema_version(), "kit.schema_version")

t:ok(kit.wait_lsn(kit.node.id, kit.node.lsn, 0), "wait_lsn(lsn, 0)")
t:ok(kit.wait_lsn(kit.node.id, kit.node.lsn, 0), "wait_lsn(lsn, 0)")

t:is(kit.wait_lsn(kit.node.id, kit.node.lsn+1, 0), false, "wait_lsn(lsn+1, 0)")
t:ok(kit.wait_status('running', 0), "wait_status(running, 0)")

t:plan(t.total)

if t.failed > 0 then
	os.exit(1)
else
	os.exit(0)
end
