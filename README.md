[![Coverage Status](https://coveralls.io/repos/github/moonlibs/kit/badge.svg)](https://coveralls.io/github/moonlibs/kit)

<a href="http://tarantool.org">
	<img src="https://avatars2.githubusercontent.com/u/2344919?v=2&s=250" align="right">
</a>

# Compatibility kit for 1.6+ (and maybe 1.5 later)

There are many minor differences between 1.6 and 1.7, which are mostly naming and data-sources. This kit was created to eliminate support hell in applications for upcoming changes in different versions and to update all of them in one place (this).

Updating single module is much simplier and safer than update of tarantool or application. And if some issue was provided within given version (as was with box.info.server), it can't be fixed within that version (only next), but it could be easily fixed with separate module.

Backward compatibility, stability and feature backporting is the main goal and value of this project.

For now it's a working draft. I'd expect requests and patches for different features and incompatibilities between 1.6 and 1.7. There is an imlpemetation of 2 features to demonstrate the way it could be used.

Currently supported versions

* 1.6
* 1.7
* 1.9
* 1.10
* 2.x
* 3.0.x

## `_G`lobal

Basically, polluting `_G` is a bad idea, but when you need something to be available remotely, it's the only way. But for those, who want to do it another way, there is a possibility

```lua
require 'kit' -- will import kit into _G

package.loaded['kit'] = nil

require 'kit' -- will check, if kit._VERSION changed and reload

local kit = require 'kit.loc' -- no global import, only as retval
```

## Provided methods and properties

### kit.node

Returns node properties in the same way in 1.6 or 1.7 or later (like 1.6' box.info.server)

```yaml
> kit.node
---
- ro: false
  rw: true
  lsn: 2
  uuid: 0a58cc6e-9df0-4044-ae0e-2a345ee136ec
  id: 1
  hostname: my.hostname.com
...
```

### kit.wait_lsn(node_id, lsn \[,timeout\])

Wait until given `lsn` reached for given `server_id` within timeout and return true or return false otherwise. Usecase is to wait, until some remote peer to reach ours lsn

```lua
local remote = net_box:new('somehost')

box.cfg{ read_only = true }

if remote:call('kit.wait_lsn', kit.node.id, kit.node.lsn, 3) then
    remote:eval('box.cfg{ read_only = false }')
else
    box.cfg{ read_only = false };
    error("Failed to switch rw node")
end
```

## Compatibility functions

* `table.new`

* `table.clear`

* `box.NULL`
  * for every version, including 1.5 and accessible without box.cfg

* `kit.schema_version`

* module `fiber`
  * module `fiber.channel`
