-- This file is part of sancus-lua-core
-- <https://github.com/sancus-project/sancus-lua-core>
--
-- Copyright (c) 2013, Alejandro Mery <amery@geeks.cl>
--

-- t[key] = object
local function table_newindex(self, key_field, key, object)
	assert(type(key) == "number" and key > 0, "invalid index")
	assert(type(object) == "table", "invalid object")

	if self[key] == nil then
		-- new
		local fmt = "index out of range (%u > %u)"
		assert(self._max < 0 or key <= self._max, fmt:format(key, self._max))

		if key > self._last then
			self._last = key
			self._count = self._count + 1
		end
	else
		assert(object[self._key_field] == key, "assigning inconsistent object")
	end

	rawset(self, key, object)
end

-- t(key, ...) -> t[key] = C(key, ...)
local function table_newentry(self, C, key, ...)
	local o, mt
	assert(type(key) == "number" and key > 0, "invalid index")

	if (self._max > 0 and key > self._max) or self[key] ~= nil then
		return -- out of range or unavailable
	end

	o = C()
	if type(o.init) == "function" then
		o.init(key, ...)
	else
		assert(select('#', ...) == 0, "classes without init() can't take extra args")

		o[self._key_field] = key
	end

	self[key] = o
	return o
end

local function table_max(self)
	return self._max
end
local function table_last(self)
	return self._last
end
local function table_empty(self)
	return (self._count == 0)
end
local function table_full(self)
	return self._count == self._max
end

function Table(key_field, C, max)
	local self = { _last = -1, _count = 0 }
	local MT

	assert(type(key_field) == 'string', "invalid key field")
	assert(type(max) == 'number' or max == nil, "invalid max")

	if max == nil or max < 0 then
		max = -1 -- unlimited
	end

	MT = {
		__newindex = function(self, key, value)
			return table_newindex(self, key_field, key, value)
		end,
		__call = function(self, from, to)
			-- TODO: iterator
			--return table_newentry(self, C, key, ...)
		end,

		max = table_max,
		last = table_last,
		empty = table_empty,
		full = table_full,

		new = function(self, key, ...)
			return table_newentry(self, C, key, ...)
		end,

		_key_field = key_field,
		_max = max,
	}
	MT.__index = MT

	setmetatable(self, MT)
	return self
end

return Table
