-- This file is part of sancus-lua-core
-- <https://github.com/sancus-project/sancus-lua-core>
--
-- Copyright (c) 2009 - 2012, Alejandro Mery <amery@geeks.cl>
--

local Class = require"sancus.object.Class"
local tonumber, type = tonumber, type

setfenv(1, {})

local Decimal = Class{
	new = function(cls, model, name, default, min, max)
		local f = model:prepare_add_field(name, cls.validate)

		f.default = default
		f.min = min
		f.max = max

		return f
	end,
}

function Decimal.validate(f, v)
	if type(v) == "string" then
		v = tonumber(v)
	end

	if type(v) ~= 'number' then
		-- NOP
	elseif f.min and v < f.min then
		-- NOP
	elseif f.max and v > f.max then
		-- NOP
	else
		-- valid number
		return true, v
	end
	return false
end

return Decimal
