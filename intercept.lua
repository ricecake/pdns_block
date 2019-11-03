--[[
This script reads a list of domains we want to block from a file and redirects
all A or AAAA requsts to a "sorry page".
--]]

-- returns true if the given file exists
function fileExists(file)
	local f = io.open(file, "rb")
	if f then
		f:close()
	end
	return f ~= nil
end

-- loads contents of a file line by line into the given table
function loadFile(filename, list)
	if fileExists(filename) then
		for line in io.lines(filename) do
			list:add(line)
		end
		pdnslog("Lua script: " .. filename .. " successfully loaded", pdns.loglevels.Notice)
	else
		pdnslog("Lua script: could not open file " .. filename, pdns.loglevels.Warning)
	end
end


-- this funciton is hooked before resolving starts
function preresolve(dq)
	-- check blocklist
	if blocklist:check(dq.qname) then
		blocklist_metric:inc()
		return true
	end

	-- default, do not rewrite this response
	return false
end

function maintenance()
	loadFile("/etc/pdns-recursor/block.list", blocklist)
end

-- import court mandated blocklist
blocklist=newDS()
loadFile("/etc/pdns-recursor/block.list", blocklist)

-- get metrics
blocklist_metric = getMetric("blocklist_hits")

local redis = require 'redis'
local client = redis.connect('127.0.0.1', 6379)
local response = client:ping()           -- true

