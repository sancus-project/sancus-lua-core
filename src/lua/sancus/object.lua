--

local _class = {
	__call = function (c, ...) return c:new(...) end,
}

function Class(c)
	c = c or {}
	c.__index = c

	if not c.new then
		function c:new(o)
			o = o or {}
			setmetatable(o, self)
			return o
		end
	end

	setmetatable(c, _class)

	return c
end

return {
	Class = Class,
}
