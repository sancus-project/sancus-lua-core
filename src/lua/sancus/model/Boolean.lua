-- This file is part of sancus-lua-core
-- <https://github.com/sancus-project/sancus-lua-core>
--
-- Copyright (c) 2009 - 2012, Alejandro Mery <amery@geeks.cl>
--

local Class = require("sancus.object").Class
local type = type

setfenv(1, {})

local values = {
	Y=true, y=true, ["1"]=true,
	N=false, n=false, ["0"]=false,
	on=true, On=true, ON=true,
	off=false, Off=false, OFF=false,
}

local function validate(f, v)
	if type(v) == "number" then
		v = (v ~= 0) -- C style booleans
	elseif type(v) == "string" then
		local b = values[v]
		if b ~= nil then
			v = b
		end
	end

	if type(v) == "boolean" then
		return true, v
	else
		return false
	end
end

local Boolean = Class{
	new = function(cls, model, name, default)
		local f = model:prepare_add_field(name, validate)

		f.default = default

		return f
	end,
}

return Boolean
