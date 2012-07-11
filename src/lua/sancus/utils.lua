-- This file is part of sancus-core-lua <http://github.com/sancus-project/sancus-core-lua>
--
-- Copyright (c) 2012, Alejandro Mery <amery@geeks.cl>
--

local _M = {
	_stdout = io.stdout,
	_stderr = io.stderr,
}

assert(io.stdout.setvbuf, "io.stdout has been kidnapped before we could save it")

-- write to stderr
--
function _M.stderr(...)
	if select('#', ...) > 1 then
		return _M._stderr:write(string.format(...))
	else
		return _M._stderr:write(...)
	end
end

-- write to stdout
--
function _M.stdout(...)
	if select('#', ...) > 1 then
		return _M._stdout:write(string.format(...))
	else
		return _M._stdout:write(...)
	end
end

function _M.stdout_buf(mode, size)
	_M._stdout:setvbuf(mode, size)
end

--
function _M.sibling_modules()
	local source = debug.getinfo(2).source
	local basedir, me = source:match("^@(.*[/\\])([^/\\]+)$")
	local t = {}

	if basedir then
		for f in lfs.dir(basedir) do
			if f ~= "." and f ~= ".." and f ~= me then
				local st
				local fn, e = f:match("^(.*)%.([^.]+)$")
				if e == "lua" or e == "so" or e == "dll" then
					t[#t+1] = fn
				else
					fn = string.format("%s/%s/init.lua", basedir, f)
					st = lfs.attributes(fn)
					if st and st.mode == "file" then
						t[#t+1] = f
					end
				end
			end
		end
	end
	return t
end

-- based on table.show() from
-- http://lua-users.org/wiki/TableSerialization
function _M.pformat(o, name, indent)
	local buf1, buf2 = '', ''
	indent = indent or ''

	local function has__tostring(o)
		local mt = getmetatable(o)
		return (mt ~= nil and mt.__tostring ~= nil)
	end

	-- simple serialization of everything except tables
	local function serialize(o)
		local s = tostring(o)
		local t = type(o)

		if t == 'nil' or t == 'boolean' or t == 'number' or has__tostring(o) then
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

		if has__tostring(o) or type(o) ~= 'table' then
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
		if has__tostring(o) or type(o) ~= 'table' then
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
	elseif has__tostring(o) or type(o) ~= 'table' then
		-- simple datum
		return tostring(name) .. ' = ' .. serialize(o) .. ';\n'
	else
		-- table, let's unwind
		stepin(o, name, indent or '', {}, name)
	end
	return buf1 .. buf2
end

function _M.pprint(t, name)
	_M.stdout(_M.pformat(t, name))
end

return _M
