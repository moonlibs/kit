local net_box = require 'net.box'
local clock = require 'clock'
local fiber = require 'fiber'
local log = require 'log'
local json = require 'json'

return function(M,I)
	require 'kit.1'(M,I)
	require 'kit.1.10'(M,I)

	M.sys = {}

	-- Experimental manual switchover function
	-- Do not use yet

	function M.sys.transfer_leadership(args)
		args = args or {
			--  id = | uuid =
			-- host = -- later
			ignore_etcd_current_master = false,
		}

		local function logerror(f, ...)
			local msg = (f):format(...)
			log.error("kit.sys.xfr: %s", msg)
			error(msg, 0)
		end

		if not M.node.rw then error("Instance must be readwrite", 0) end

		local me = M.node.id
		local candidates = {}
		local timeout = args.timeout or 3

		if args.id then
			table.insert(candidates, assert(box.info.replication[args.id],
				"Id "..args.id.." is not known to cluster"))
		elseif args.uuid then
			for id, peer in pairs(box.info.replication) do
				if args.uuid == peer.uuid then
					table.insert(candidates, peer)
				end
			end
			assert(#candidates > 0, "uuid "..args.uuid.." is not known to cluster")
		else
			for id, peer in pairs(box.info.replication) do
				if id ~= me then
					table.insert(candidates, peer)
				end
			end
		end

		for _, peer in pairs(candidates) do
			if peer.downstream and peer.downstream.status == 'follow' then
				if peer.upstream then
					-- ok
				else
					error(("Peer %s/%s have downstream and have no upstream:"
						.." only fullmesh is supported"):format(peer.id, peer.uuid), 0)
				end
			else
				error(("Peer %s/%s have no downstream:"
					.." only fullmesh is supported"):format(peer.id, peer.uuid), 0)
			end
		end

		if #candidates == 0 then
			error("No suitable candidates found", 0)
		end

		table.sort(candidates, function(a,b)
			if b.downstream.vclock[me] < a.downstream.vclock[me] then
				return true
			elseif b.downstream.vclock[me] == a.downstream.vclock[me] then
				return a.downstream.lag < b.downstream.lag
			end
		end)

		local remote = candidates[1]

		log.info("kit.sys.xfr: Chosen candidate %s/%s: %s for switch", remote.id, remote.uuid, remote.upstream.peer)

		local conn = net_box.connect( remote.upstream.peer, {
			connect_timeout = timeout,
			wait_connected  = false,
			reconnect_after = 0,
		} )
		if not conn:wait_connected(timeout) then
			logerror("Failed to connect to peer %s within timeout %s",
				remote.upstream.peer, timeout)
		end
		local replica_info = conn:call('kit.node', {}, {timeout = timeout})
		if replica_info.uuid ~= remote.uuid then
			logerror("Connected to wrong destination. Expected %s, got %s",
				remote.uuid, replica_info.uuid)
		end
		log.info("kit.sys.xfr: Connected to candidate at %s. Local vclock: %s, remote vclock: %s",
			replica_info.hostname, json.encode(box.info.vclock),
			json.encode(box.info.replication[ remote.id ].downstream.vclock))

		-- 1. dry-run. make some modification and wait_lsn
		local lsn = box.info.lsn
		box.space._schema:replace(box.space._schema:get('_advance') or {'_advance'})
		assert( box.info.lsn > lsn, "Lsn not advanced after modification" )
		lsn = box.info.lsn

		local start = clock.time()
		local replica_awaited = conn:call('kit.wait_lsn', {me, lsn, timeout}, { timeout = timeout + 0.1 })
		local lag_time = clock.time() - start

		if not replica_awaited then
			logerror("Failed to await changes from replica (changes not made)")
		else
			log.info("kit.sys.xfr: Candidate advanced to lsn %d in %0.6f", lsn, lag_time)
		end

		-- 2. Prepare etcd for switching. Switch master key for this cluster
		local instance_name
		if config and config.etcd then
			local prefix = config.get("etcd.prefix")
			local cfg = config.etcd:get_all()
			instance_name = config.get('sys.instance_name')
			local this = assert(cfg.instances[ instance_name ], "Instance not found in etcd config " .. instance_name)
			local clusters_key = assert( cfg.clusters and 'clusters' or cfg.shards and 'shards' or nil, "No clusters section" )
			local cluster_key = assert( this.cluster and 'cluster' or this.shard and 'shard' or nil, "No cluster key in instance" )
			local cluster_name = assert(this[ cluster_key ], "No cluster name in instance")
			local cluster = assert(cfg[ clusters_key ][ cluster_name ], "No cluster " .. cluster_name)
			local candidate_name
			for inst, data in pairs( cfg.instances ) do
				if data.box.instance_uuid == remote.uuid then
					candidate_name = inst
					break
				end
			end
			assert(candidate_name, "Candidate not found by uuid " .. remote.uuid)
			local current_master = cfg[ clusters_key ][ cluster_name ].master
			if not args.ignore_etcd_current_master then
				if current_master ~= instance_name and current_master ~= candidate_name then
					logerror(
						"Current master for cluster %s is %. Neither me (%s), not candidate (%s). "
						.. "To bypass this chech run with `ignore_etcd_current_master = true`",
						cluster_name, current_master, instance_name, candidate_name
					)
				end
			end

			local path = "/keys" .. prefix .. "/" .. clusters_key .. "/" .. cluster_name .. "/master"
			local res = config.etcd:request( "PUT", path, {
				value = candidate_name, prevValue = current_master
			} )

			log.info("kit.sys.xfr: Update etcd CAS %s: %s->%s: %s", path, current_master, candidate_name, json.encode(res))
			if res.errorCode then
				logerror("Etcd CAS failed: %s", json.encode( res ))
			end
		end

		-- 3. ready to break things. Switch master to ro and propagate final changes to replica

		start = clock.time()
		box.cfg{ read_only = true }
		fiber.yield() -- allow state changes to be detected and lsn to advance
		lsn = box.info.lsn

		local r, state, replica_info = pcall(function()
			return conn:eval([[
				local id,lsn,to = ...
				if not kit.wait_lsn(id,lsn,to) then
					return false, kit.node
				end

				local r,e = pcall(package.reload)
				if not r then
					if not e:match("console is already started") then
						error(e)
					end
				end
				require "fiber".yield()

				return true, kit.node
			]], {me, lsn, timeout}, {timeout = timeout + 0.1})
		end)

		local switch_time = clock.time() - start

		if not r then
			logerror("Replica switch failed! Emergency repair required! Don't know actual state. %s", state)
		end

		if state then
			-- got true from switch script
			if replica_info.rw then
				local r,e = pcall(package.reload)

				log.info(
					"kit.sys.xfr: Replica %s was promoted and reloaded: %s in %0.6fs",
					remote.upstream.peer, json.encode( replica_info ), switch_time
				);

				if not r then
					log.info("Local reload failed with error: %s", e)
				end

				return { success = {
					msg = "Replica was promoted and reloaded",
					time = switch_time,
					target = {
						instance_name = instance_name,
						addr = remote.upstream.peer,
						info = replica_info,
					},
					local_reload = {
						[ r and "success" or "failure" ] = e or true
					}
				} }
			else
				box.cfg{ read_only = false }

				logerror(
					"Replica %s was !!!NOT!!! promoted after reload: %s in %0.6fs, switched master back",
					remote.upstream.peer, json.encode( replica_info ), switch_time
				)
			end
		else
			-- got false from switch script: wait_lsn failed
			box.cfg{ read_only = false }
			logerror( "Replica failed to await for lsn: %s, switched master back", json.encode( replica_info ) );
		end
	end
end
