-- This file is part of sancus-lua-core
-- <https://github.com/sancus-project/sancus-lua-core>
--
-- Copyright (c) 2009 - 2012, Alejandro Mery <amery@geeks.cl>
--

local Class = require"sancus.object.Class"
local type = type

setfenv(1, {})

local function validate(f, v)
	if type(v) == "string" and f.enum[v] ~= nil then
		return true, v
	else
		return false
	end
end

local Enum = Class{
	new = function(cls, model, name, enum, default)
		local f = model:prepare_add_field(name, validate)

		f.default = default
		f.enum = enum

		return f
	end,
}

return Enum
