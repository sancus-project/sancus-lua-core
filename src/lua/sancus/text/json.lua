-- This file is part of sancus-lua-core
-- <https://github.com/sancus-project/sancus-lua-core>
--
-- Copyright (c) 2013, Alejandro Mery <amery@geeks.cl>
--

local _M = { _NAME = ... }
setfenv(1, _M)

function encode(v)
	return ""
end

function decode(v)
	return nil
end

return _M
