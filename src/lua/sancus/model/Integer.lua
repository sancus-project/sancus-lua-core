-- This file is part of sancus-lua-core
-- <https://github.com/sancus-project/sancus-lua-core>
--
-- Copyright (c) 2009 - 2012, Alejandro Mery <amery@geeks.cl>
--

local Class = require"sancus.object.Class"
local Decimal = require"sancus.model.Decimal"
local tonumber, type, floor = tonumber, type, math.floor

setfenv(1, {})

local function validate(f, v)
	if type(v) == "string" then
		v = tonumber(v)
	end

	if type(v) ~= 'number' or floor(v) ~= v then
		return false
	else
		return Decimal.validate(f, v)
	end
end

local Integer = Class{
	new = function(cls, model, name, default, min, max)
		local f = model:prepare_add_field(name, validate)

		f.default = default
		f.min = min
		f.max = max

		return f
	end,
}

return Integer
