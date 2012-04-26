-- This file is part of sancus-core-lua <http://github.com/sancus-project/sancus-core-lua>
--
-- Copyright (c) 2012, Alejandro Mery <amery@geeks.cl>
--

local _M = {}

-- write to stderr
--
function _M.stderr(...)
	return io.stderr:write(...)
end

-- based on table.show() from
-- http://lua-users.org/wiki/TableSerialization
function _M.pformat(o, name, indent)
	local buf1, buf2 = '', ''
	indent = indent or ''

	-- simple serialization of everything except tables
	local function serialize(o)
		local s = tostring(o)
		local t = type(o)

		if o == nil then
			return 'nil'
		elseif t == 'boolean' then
			return o and 'true' or 'false'
		elseif t == 'number' then
			return s
		elseif t == 'function' then
			local info = debug.getinfo(o, 'S')
			if info.what == 'C' then
				s = s..', C function'
			else
				s = s..', defined in ('..
					info.linedefined..'-'..info.lastlinedefined..
					')'..info.source
			end
		end
		return string.format('%q', s)
	end

	-- recursion
	local function stepin(o, name, indent, cache, field)
		buf1 = buf1 .. indent .. field

		if type(o) ~= 'table' then
			-- simple datum
			buf1 = buf1 .. ' = ' .. serialize(o) .. ';\n'
		elseif cache[o] then
			-- cached table
			buf1 = buf1 .. ' = {}; -- ' .. cache[o] .. ' (self reference)\n'
			buf2 = buf2 .. name .. ' = ' .. cache[o] .. ';\n'
		else
			-- new table
			cache[o] = name
			if next(o) == nil then -- empty table
				buf1 = buf1 .. ' = {};\n'
			else
				buf1 = buf1 .. ' = {\n'
				for k,v in pairs(o) do
					k = string.format('[%s]', serialize(k))
					stepin(v, name..k, indent..'   ', cache, k)
				end
				buf1 = buf1 .. indent .. '};\n'
			end
		end
	end

	if name == nil then
		if type(o) ~= 'table' then
			return serialize(o)
		elseif next(o) == nil then
			return '{}'
		else
			local cache = {}
			cache[o] = '__unnamed__'
			buf1 = '{\n'
			for k,v in pairs(o) do
				k = string.format('[%s]', serialize(k))
				stepin(v, k, indent..'   ', cache, k)
			end
			buf1 = buf1 .. indent .. '}'
		end
	elseif type(o) ~= 'table' then
		-- simple datum
		return tostring(name) .. ' = ' .. serialize(o) .. ';\n'
	else
		-- table, let's unwind
		stepin(o, name, indent or '', {}, name)
	end
	return buf1 .. buf2
end

function _M.pprint(t, name)
	print(_M.pformat(t, name))
end

return _M
