-- NOTICE only used by gui.lua at the moment
local class = require 'ext.class'
local vec2 = require 'vec.vec2'
local box2 = class()

function box2:init(a, ...)
	self.min = vec2()
	self.max = vec2()
	if a ~= nil then
		self:set(a, ...)
	end
end

function box2.set(dst,a,b,c,d)
	if d ~= nil then
		dst.min[1] = tonumber(a) or 0
		dst.min[2] = tonumber(b) or 0
		dst.max[1] = tonumber(c) or 0
		dst.max[2] = tonumber(d) or 0
	elseif type(a) == 'table' then
		if type(a.min) == 'table' then	--box
			dst.min[1] = a.min[1]
			dst.min[2] = a.min[2]
			dst.max[1] = a.max[1]
			dst.max[2] = a.max[2]
		else -- vector
			dst.min[1] = -a[1]
			dst.min[2] = -a[2]
			dst.max[1] = a[1]
			dst.max[2] = a[2]
		end
	elseif b == nil then
		a = tonumber(a) or 0
		dst.min[1] = -a
		dst.min[2] = -a
		dst.max[1] = a
		dst.max[2] = a
	elseif c == nil then
		elseif c == nil then
		a = tonumber(a) or 0
		b = tonumber(b) or 0
		dst.min:set(a,a)
		dst.max:set(b,b)
	else
		-- technically we shouldn't get here ... since it's handled by the first condition
		error("don't know how to initialize")
		dst.min:set(tonumber(a) or 0, tonumber(b) or 0)
		dst.max:set(tonumber(c) or 0, tonumber(d) or 0)
	end
	return dst
end

	-- vec2 size(self)
function box2.size(b)
	return b.max - b.min
end

	-- bool touches(box2, box2)
function box2.touches(a,b)
	return	a.min[1] < b.max[1] and
			a.max[1] > b.min[1] and
			a.min[2] < b.max[2] and
			a.max[2] > b.min[2]
end

	-- bool contains(box2, vec2)
function box2.contains(a,b)
	return	a.min[1] < b[1] and
			a.min[2] < b[2] and
			a.max[1] > b[1] and
			a.max[2] > b[2]
end

function box2.containsE(a,b)
	return	a.min[1] <= b[1] and
			a.min[2] <= b[2] and
			a.max[1] >= b[1] and
			a.max[2] >= b[2]
end


function box2:clamp(b)
	for i=1,2 do
		if self.min[i] < b.min[i] then self.min[i] = b.min[i] end
		if self.max[i] > b.max[i] then self.max[i] = b.max[i] end
	end
	return self
end

function box2.map(a,b) a.min:map(b) a.max:map(b) return a end

function box2.__tostring(b) return '[' .. b.min .. ', ' .. b.max .. ']' end
function box2.__concat(a,b) return tostring(a) .. tostring(b) end

function box2.__add(a,b)
	local bmin, bmax = b, b
	if getmetatable(b) == box2 then bmin = b.min bmax = b.max end
	return box2{min = a.min + bmin, max = a.max + bmax}
end

function box2.__sub(a,b)
	local bmin, bmax = b, b
	if getmetatable(b) == box2 then bmin = b.min bmax = b.max end
	return box2{min = a.min - bmin, max = a.max - bmax}
end

return box2
