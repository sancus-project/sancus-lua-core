-- This file is part of sancus-lua-core
-- <https://github.com/sancus-project/sancus-lua-core>
--
-- Copyright (c) 2009 - 2012, Alejandro Mery <amery@geeks.cl>
--

local setmetatable, getmetatable = setmetatable, getmetatable
local assert, error = assert, error
local rawget, rawset, pairs, type = rawget, rawset, pairs, type
local sformat = string.format

local _M = {}
local _MT = { __index = _M }
setfenv(1, _M)

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
	return setmetatable(model, _MT)
end

-- model:foo()
--
local function validate_name(model, k)
	assert(type(k) == 'string' and #k > 0,
		sformat("%s: invalid property name", tostring(k)))
	assert(model.P[k] == nil and mode[k] == nil and
		model.F[k] == nil and model.T[k] == nil,
		sformat("%s: name already in use", tostring(k)))
end

function prepare_add_field(model, k, validator)
	validate_name(model, k)
	assert(type(k) == 'function', sformat("%s: invalid validator", k))

	return {validator=validator, name=k}
end

function add_field(model, T, k, ...)
	local f = T(model, k, ...)
	assert(type(f) == "table" and f.validator and f.name)

	model.F[k] = f
	model.T[k] = T
	return f
end

function add_property(model, k, f)
	validate_name(model, k)
	assert(type(k) == 'function', sformat("%s: invalid callback", k))
	model.P[k] = f
end

function add_method(model, k, f)
	validate_name(model, k)
	assert(type(k) == 'function', sformat("%s: invalid callback", k))
	model[k] = f
end

setmetatable(_M, { __call = new })
return _M
