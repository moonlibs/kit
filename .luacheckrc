std="tarantool"

max_line_length=140
include_files = {"kit/", "kit.lua"}

globals = { "kit" }

read_globals = {
	"_TARANTOOL",
	"config",
	"package.reload",
	"kit",
}

files["kit/1/5/*.lua"] = {
	read_globals = {
		"box.fiber",
		"box.time",
		"box.time64",
		"box.ipc",
		"box.errno",
	}
}

globals = { "table" }

ignore = {
	"121", -- setting read-only global variable
	"211", -- unused variable
	"212", -- unused argument
	"213", -- unused loop variable
	"411", -- redefinition of the variable
	"421", -- shadowing definition of variable
	"431", -- shadwing upvalue
	"432", -- shadowing upvalue argument
	"542", -- empty if branch
	"611", -- contains only whitespaces
}
