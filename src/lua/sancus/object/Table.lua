-- This file is part of sancus-lua-core
-- <https://github.com/sancus-project/sancus-lua-core>
--
-- Copyright (c) 2013, Alejandro Mery <amery@geeks.cl>
--

local assert, pcall = assert, pcall
local type, select, rawset = type, select, rawset
local setmetatable = setmetatable
local tostring, tonumber, tconcat = tostring, tonumber, table.concat

local _M = {}
setfenv(1, _M)

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

local function table_get(self, index)
	if index ~= nil and type(index) ~= 'number' then
		index = tonumber(index)
	end
	if index ~= nil then
		return self[index]
	end
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
		local status, err = pcall(o.init, o, key, ...)
		if not status then
			return nil, err
		end
	elseif select('#', ...) > 0 then
		return nil, "classes without init() can't take extra args"
	else
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

--
--
local function table_json_encoded(self)
	local max
	local t = {}
	if self._max > 0 then
		max = self._max
	else
		max = self._last
	end

	for i,v in self(1, max, false) do
		if v == false then
			v = "null"
		else
			assert(v.json_encoded ~= nil, tostring(v) .. ": no json_encoded() provided")
			v = v:json_encoded()
		end
		t[i] = v
	end

	if #t > 0 then
		return "[" .. tconcat(t, ", ") .. "]"
	else
		return "[]"
	end
end

--
--
local function table_after(self, id)
	if not id or id < 0 then
		id = 0
	end

	for i = id+1, self._last do
		local e = self[i]

		if e ~= nil then
			return i, e
		end
	end
end

local function table_before(self, id)
	if not id or id < 0 then
		id = 0
	end

	for i = id-1, 1, -1 do
		local e = self[i]

		if e ~= nil then
			return i, e
		end
	end
end

-- iterator
--
local function table_iterator_next(self, prev, last, placeholder)
	local o, i

	if prev > last then
		return
	end

	if null ~= nil then
		i = prev + 1
		o = self[i]
		if o == nil then
			o = placeholder
		end
		return i, o
	else
		for i = prev+1,last do
			o = self[i]
			if o ~= nil then
				return i, o
			end
		end
	end
end

local function table_iterator(self, from, to, placeholder)
	if from == nil or from < 1 then
		from = 1
	end

	if to == nil or to < 1 then
		to = self._last
	end

	if self._max > 0 and to > self._max then
		to = self._max
	end

	if to > 0 then
		local f = function(_, prev)
			return table_iterator_next(self, prev, to, placeholder)
		end
		return f, nil, 0
	else
		return function() end
	end
end

local function table_available(self, max)
	local t = {}

	max = tonumber(max) or self._max
	if self._max > 0 then
		if max < 0 or max > self._max then
			max = self._max -- truncate
		end
	elseif max < 0 then
		error "table_available: can't work on infinite tables unless a limit is given"
	end

	for i = 1,max do
		if self[i] == nil then
			t[#t+1] = i
		end
	end

	return t
end

--
--
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
		__call = table_iterator,
		__ipairs = table_iterator,

		max = table_max,
		last = table_last,
		empty = table_empty,
		full = table_full,
		available = table_available,

		before = table_before,
		after = table_after,

		json_encoded = table_json_encoded,

		new = function(self, key, ...)
			return table_newentry(self, C, key, ...)
		end,

		get = table_get,

		_key_field = key_field,
		_max = max,
	}
	MT.__index = MT

	setmetatable(self, MT)
	return self
end

return Table
