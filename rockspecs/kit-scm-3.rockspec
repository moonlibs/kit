package = 'kit'
version = 'scm-3'
source  = {
	url    = 'git+https://github.com/moonlibs/kit.git',
	branch = 'master',
}
description = {
	summary  = "Compatibility kit for Tarantool",
	homepage = 'https://github.com/moonlibs/kit.git',
	license  = 'BSD',
}
dependencies = {
	'lua >= 5.1'
}
build = {
	type = 'builtin',
	modules = {
		['kit']       = 'kit.lua';
		['kit.1']     = 'kit/1.lua';
		['kit.loc']   = 'kit/loc.lua';
		['kit.1.6+']  = 'kit/1/6+.lua';
		['kit.1.6']   = 'kit/1/6.lua';
		['kit.1.7']   = 'kit/1/7.lua';
		['kit.1.9']   = 'kit/1/9.lua';
		['kit.1.10']  = 'kit/1/10.lua';
		['kit.2']     = 'kit/2.lua';
		['kit.1.5']   = 'kit/1/5/init.lua';
		['kit.1.5.fiber'] = 'kit/1/5/fiber.lua';
		['kit.1.5.socket'] = 'kit/1/5/socket.lua';
		['kit.1.5.errno'] = 'kit/1/5/errno.lua';
		['kit.3']     = 'kit/3.lua';
	}
}

-- vim: syntax=lua
