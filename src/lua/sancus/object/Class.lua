-- This file is part of sancus-lua-core
-- <https://github.com/sancus-project/sancus-lua-core>
--
-- Copyright (c) 2013, Alejandro Mery <amery@geeks.cl>
--

local type, select = type, select
local setmetatable = setmetatable

local _class = {
	__call = function (c, ...) return c:new(...) end,
}

function object_constructor(c, ...)
	local l = select('#', ...)
	local o

	if l == 0 then
		o = {}
	elseif l > 1 then
		o = { ... }
	else
		o = select(1, ...)
		if type(o) ~= 'table' then
			o = { o }
		end
	end
	return o
end

function object_new(c, ...)
	local o = c:init(...)
	if o ~= nil then
		setmetatable(o, c)
		return o
	end
end

function Class(c)
	c = c or {}
	c.__index = c

	if not c.new then
		if not c.init then
			c.init = object_constructor
		end

		c.new = object_new
	end

	setmetatable(c, _class)
	return c
end

return Class
