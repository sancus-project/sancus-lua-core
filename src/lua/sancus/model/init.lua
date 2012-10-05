-- This file is part of sancus-lua-core
-- <https://github.com/sancus-project/sancus-lua-core>
--
-- Copyright (c) 2009 - 2012, Alejandro Mery <amery@geeks.cl>
--

local utils = require"sancus.utils"
local sibling_modules = utils.sibling_modules

local setmetatable, getmetatable, require = setmetatable, getmetatable, require
local assert, error = assert, error
local rawget, rawset, ipairs, pairs, type = rawget, rawset, ipairs, pairs, type
local tostring = tostring
local sformat = string.format

local _M = { _NAME = ... }
setfenv(1, _M)

-- load type handlers
--
for _, x in ipairs(sibling_modules()) do
	_M[x] = require(... .. "." .. x)
end

local MI = {}
local MT = { __index = MI }

-- set_field
--
local function rawset_field(o, k, v)
	local t = rawget(o, '__fields')
	rawset(t, k, v)
end

local function set_field(o, k, v)
	local model = getmetatable(o)
	local f = model.F[k]
	if f then
		local ok, val = f.validator(f, v)
		if ok then
			rawset_field(o, k, val)
		elseif v == nil and f.default ~= nil then
			rawset_field(o, k, f.default)
		else
			error(sformat("%s: invalid value (%q)", k, tostring(v)), 2)
		end
	else
		error(sformat("%s: field not supported", k), 2)
	end
end

local function set(o, k, v)
	local f = function() set_field(o, k, v) end
	return pcall(f)
end

-- get_field
--
local function rawget_field(o, k)
	local t = rawget(o, '__fields')
	return rawget(t, k)
end

local function get_field(o, k)
	local model, v = getmetatable(o), rawget_field(o, k)

	if v ~= nil then -- field
		return v
	elseif model.P[k] then -- property
		return model.P[k](o)
	else
		return model[k]
	end
end

local function get(o, k, default)
	local v = get_field(o, k)
	if v ~= nil then
		return v
	else
		return default
	end
end

-- new object
--
local function new_object(model, t)
	t = t or {}
	local o = { __fields = t }

	-- init
	for k, f in pairs(model.F) do
		if rawget(t, k) == nil and f.default ~= nil then
			rawset(t, k, f.default)
		end
	end

	return setmetatable(o, model)
end

-- new model
--
local function new()
	local model = {
		P = {}, -- properties
		F = {}, -- fields
		T = {}, -- types

		__call = new_object,
		__index = get_field,
		__newindex = set_field,

		get = get,
		set = set,
	}
	return setmetatable(model, MT)
end

-- model:foo()
--
local function validate_name(model, k)
	assert(type(k) == 'string' and #k > 0,
		sformat("%s: invalid property name", tostring(k)))
	assert(model.P[k] == nil and model[k] == nil and
		model.F[k] == nil and model.T[k] == nil,
		sformat("%s: name already in use", tostring(k)))
end

function MI:prepare_add_field(k, f)
	validate_name(self, k)
	assert(type(f) == 'function', sformat("%s: invalid validator (%q)", k, type(f)))

	return {validator=f, name=k}
end

function MI:add_field(T, k, ...)
	local f = T(self, k, ...)
	assert(type(f) == "table" and f.validator and f.name)

	self.F[k] = f
	self.T[k] = T
	return f
end

function MI:add_property(k, f)
	validate_name(self, k)
	assert(type(f) == 'function', sformat("%s: invalid callback (%q)", k, type(f)))
	self.P[k] = f
end

function MI:add_method(k, f)
	validate_name(self, k)
	assert(type(k) == 'function', sformat("%s: invalid callback", k))
	self[k] = f
end

setmetatable(_M, { __call = new })
return _M