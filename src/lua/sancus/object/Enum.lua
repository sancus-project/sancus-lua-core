-- This file is part of sancus-lua-core
-- <https://github.com/sancus-project/sancus-lua-core>
--
-- Copyright (c) 2013, Alejandro Mery <amery@geeks.cl>
--

local Class = require"sancus.object.Class"
local utils = require"sancus.utils"

local ipairs, rawget = ipairs, rawget

setfenv(1, {})

local function enum_iter(self, default)
	local i = 1
	return function(_, _)
		local k = self._keys[i]
		if k then
			i = i + 1
			return k, self._enum[k], k == default
		end
	end
end

Enum = {
	init = function(cls, self)
		self = self or {}

		return {
			_enum = self,
			_keys = utils.sorted_keys(self),
		}
	end,

	-- iterators
	--
	__ipairs = function(self)
		return ipairs(self._keys)
	end,
	__pairs = enum_iter,
	__call = enum_iter,

	__len = function(self)
		return #self._keys
	end,

	-- key access
	--
	__index = function(self, key)
		return rawget(self._enum, key) or rawget(Enum, key)
	end,
	__newindex = function (self, key, value)
		error("attempt to update a read-only table", 2)
	end
}

return Class(Enum)
