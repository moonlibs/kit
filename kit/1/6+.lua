return function(M, I)
	do -- monkey-patching for :yield on fun iterators
		local fiber = require 'fiber'
		local fun = require 'fun'
		local ix = getmetatable(fun.wrap({})).__index
		ix.yield = ix.yield or (function(fun)
			return function(self, arg1)
				return fun(arg1, self.gen, self.param, self.state)
			end
		end)(function(N, gen, param, state)
			if type(N)~='number' or N < 1 then error("Bad argument to yield",2) end
			return fun.wrap(function(ctx, state_x)
				local gen_x, param_x, N, cnt = ctx[1], ctx[2], ctx[3], ctx[4]+1
				ctx[4] = cnt
				if cnt % N == 0 then fiber.sleep(0) end
				return gen_x(param_x, state_x)
			end, {gen, param, N, 0}, state)
		end)
	end

	if not rawget(box,'NULL') then
		rawset(box,'NULL',require'msgpack'.NULL)
	end
end
