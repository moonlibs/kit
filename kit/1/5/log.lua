local function log(...) print(string.format(...)) end

M.debug = log
M.info = log
M.warn = log
M.error = log

return {
	debug = log,
	info  = log,
	warn  = log,
	error = log,
}
