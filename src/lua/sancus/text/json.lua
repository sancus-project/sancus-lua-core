-- This file is part of sancus-lua-core
-- <https://github.com/sancus-project/sancus-lua-core>
--
-- Copyright (c) 2013, Alejandro Mery <amery@geeks.cl>
--

local lpeg = require"lpeg"
local P, R, S = lpeg.P, lpeg.R, lpeg.S
local C, Ct, Cg = lpeg.C, lpeg.Ct, lpeg.Cg
local V = lpeg.V

local Class = require"sancus.object.Class"

local type, tonumber, tostring, pairs, ipairs = type, tonumber, tostring, pairs, ipairs
local setmetatable, getmetatable = setmetatable, getmetatable

local tconcat = table.concat

local _M = { _NAME = ... }
setfenv(1, _M)

-- String
--
local function quote(s)
	-- TODO: replace with lpeg
	return s:gsub("\\","\\\\"):gsub("\"", '\\"'):gsub("\n", "\\n"):gsub("\t","\\t")
end

local function encode_string(v)
	return "\"" .. quote(v) .. "\""
end

-- Array
--
local function encode_array(o)
	local t = {}
	for _, v in ipairs(o) do
		t[#t+1] = encode(v)
	end

	if #t > 0 then
		return "[" .. tconcat(t, ", ") .. "]"
	else
		return "[]"
	end
end

Array = Class{
	__tostring = encode_array,
	json_encoded = encode_array,
}

-- Object
--
local function encode_object(o)
	local t = {}
	local fmt = "%s: %s"

	for k, v in pairs(o) do
		k = encode_string(k)
		v = encode(v)
		t[#t+1] = fmt:format(k, v)
	end
	if #t > 0 then
		return "{" .. tconcat(t, ", ") .. "}"
	else
		return "{}"
	end
end

Object = Class{
	__tostring = encode_object,
	json_encoded = encode_object,
}

-- Null
--
local function encode_null(o)
	return "null"
end

Null = {
	__tostring = encode_null,
	json_encoded = encode_null,

	__call = function(self) return self end,
}
Null.__index = Null
setmetatable(Null, Null)

-- Generic Encoder
--
function encode(v)
	local t = type(v)
	local s

	if v == nil then
		s = "null"
	elseif t == "boolean" or t == "number" then
		s = tostring(v)
	elseif t == "string" then
		s = encode_string(v)
	elseif v.json_encoded then
		s = v:json_encoded()
	else
		local mt = getmetatable(v)
		if mt and mt.__tostring then
			s = encode_string(tostring(v))
		elseif #v > 0 then
			s = encode_array(v)
		else
			s = encode_object(v)
			-- prefer empty arrays instead of empty objects
			if s == "{}" then
				s = "[]"
			end
		end
	end

	return s
end

-- Decoder
--
do
	local nl = P"\n" + P"\r\n"
	local white = S" \t" + nl
	local digit, minus, dot, comma, colon = R"09", P"-", P".", P",", P":"

	local escapes = {
		["\""] = "\"", ["\\"] = "\\", ["/"] = "/",
		b = "\b", f = "\f", n = "\n", r = "\r", t = "\t",
	}

	local qq, esc = P"\"", P"\\"
	local char_0 = C((R"\032\126" - qq - esc)^1)
	local char_1 = esc * C(S"\"\\/bfnrt")/escapes
	local char = char_1 + char_0

	local function FoldObject(t)
		local o = Object()
		for _, v in ipairs(t) do
			o[v.key] = v.value
		end
		return o
	end

	local data = P{
		"data",

		NULL = C(P("null"))/function() return Null end,
		TRUE = C(P("true"))/function() return true end,
		FALSE = C(P("false"))/function() return false end,

		number = C(minus^-1 * digit^1 * (dot * digit^1)^-1)/tonumber,
		string = Ct(qq * char^0 * qq)/function (t) return tconcat(t, "") end,

		value = V"number" + V"string" + V"NULL" + V"TRUE" + V"FALSE" + V"array" + V"object",
		data = white^0 * V"value" * white^0,

		array_list = (V"data" * comma)^0 * V"data",
		array = Ct(P"[" * (V"array_list")^0 * P"]")/Array,

		object_entry = Ct(white^0 * Cg(V"string", "key") * colon * Cg(V"data", "value")),
		object_list = V"object_entry" * (white^0 * comma * V"object_entry")^0,
		object = Ct(P"{" * white^0 * (V"object_list")^0 * P"}")/FoldObject,
	} * -1

	decode = function(s)
		return data:match(s)
	end
end

return _M
