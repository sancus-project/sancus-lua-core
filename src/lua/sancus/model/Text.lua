-- This file is part of sancus-lua-core
-- <https://github.com/sancus-project/sancus-lua-core>
--
-- Copyright (c) 2009 - 2012, Alejandro Mery <amery@geeks.cl>
--

local Class = require("sancus.object").Class
local tostring, type = tonumber, type

setfenv(1, {})

local function validate(f, v)
	if type(v) ~= "string" then
		v = tostring(v)
	end

	if type(v) == 'string' then
		return true, v
	else
		return false
	end
end

local Text = Class{
	new = function(cls, model, name, default)
		local f = model:prepare_add_field(name, validate)

		f.default = default or ""

		return f
	end,
}

return Text
