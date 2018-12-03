return function(M, I)
	if not rawget(box,'NULL') then
		rawset(box,'NULL',require'msgpack'.NULL)
	end
end
