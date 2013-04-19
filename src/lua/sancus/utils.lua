-- This file is part of sancus-core-lua <http://github.com/sancus-project/sancus-core-lua>
--
-- Copyright (c) 2012, Alejandro Mery <amery@geeks.cl>
--

local ipairs, next, pairs, select, type = ipairs, next, pairs, select, type
local tostring, string, debug = tostring, string, debug
local getmetatable = getmetatable

local lfs = require"lfs"

local _M = {
	_stdout = io.stdout,
	_stderr = io.stderr,
	_NAME = ...,
}

assert(io.stdout.setvbuf, "io.stdout has been kidnapped before we could save it")

setfenv(1, _M)

-- write to stderr
--
function stderr(...)
	if select('#', ...) > 1 then
		return _stderr:write(string.format(...))
	else
		return _stderr:write(...)
	end
end

-- write to stdout
--
function stdout(...)
	if select('#', ...) > 1 then
		return _stdout:write(string.format(...))
	else
		return _stdout:write(...)
	end
end

function stdout_buf(mode, size)
	_stdout:setvbuf(mode, size)
end

-- POSIXish getopt()
function getopt(arg, options)
	local opt, optind = {}, 1
	local waiting

	for _,v in ipairs(arg) do
		if waiting then
			-- short option waiting for a value
			opt[waiting] = v
			optind = optind + 1
			waiting = nil
		elseif v == "-" then
			break
		elseif v:sub(1, 1) == "-" then
			optind = optind + 1
			if v == "--" then
				break
			elseif v:sub(1, 2) == "--" then
				-- long option
				local x = v:find("=", 1, true)
				if x then
					opt[v:sub(3, x-1)] = v:sub(x+1)
				else
					opt[v:sub(3)] = true
				end
			else
				-- short option
				local j, l = 2, #v
				while (j <= l) do
					local t = v:sub(j, j)
					local x = options:find(t, 1, true)
					if t == ":" then
						stderr:write("%s: invalid option -- '%s'\n", arg[0], t)
						opt["?"] = true
					elseif x then
						if options:sub(x+1, x+1) == ":" then
							local w = v:sub(j+1)
							if #w > 0 then
								opt[t] = w
								j = l
							else
								waiting = t
							end
						else
							opt[t] = true
						end
					else
						stderr:write("%s: invalid option -- '%s'\n", arg[0], t)
						opt["?"] = true
					end
					j = j + 1
				end
			end
		else
			break
		end
	end

	if waiting ~= nil then
		io.stderr:write(arg[0],": option requires an argument -- '",waiting,"'\n")
		opt[":"] = true
	end

	return opt, optind
end

--
function sibling_modules()
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
function pformat(o, name, indent)
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

function pprint(t, name)
	stdout(pformat(t, name))
end

return _M
