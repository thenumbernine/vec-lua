-- NOTICE only used by gui.lua at the moment
local class = require 'ext.class'
local vec3 = require 'vec.vec3'
local box3 = class()

function box3:init(a, ...)
	self.min = vec3()
	self.max = vec3()
	if a ~= nil then
		self:set(a, ...)
	end
end

function box3.set(dst,a,b,c,d)
	if type(a) == 'table' then
		if type(a.min) == 'table' then	--box
			dst.min[1] = a.min[1]
			dst.min[2] = a.min[2]
			dst.min[3] = a.min[3]
			dst.max[1] = a.max[1]
			dst.max[2] = a.max[2]
			dst.max[3] = a.max[3]
		else -- vector
			dst.min[1] = -a[1]
			dst.min[2] = -a[2]
			dst.min[3] = -a[3]
			dst.max[1] = a[1]
			dst.max[2] = a[2]
			dst.max[3] = a[3]
		end
	elseif b == nil then
		a = tonumber(a) or 0
		dst.min[1] = -a
		dst.min[2] = -a
		dst.min[3] = -a
		dst.max[1] = a
		dst.max[2] = a
		dst.max[3] = a
	elseif c == nil then
		elseif c == nil then
		a = tonumber(a) or 0
		b = tonumber(b) or 0
		dst.min:set(a,a,a)
		dst.max:set(b,b,b)
	else
		-- technically we shouldn't get here ... since it's handled by the first condition
		error("don't know how to initialize")
		dst.min:set(tonumber(a) or 0, tonumber(b) or 0)
		dst.max:set(tonumber(c) or 0, tonumber(d) or 0)
	end
	return dst
end

	-- vec3 size(self)
function box3.size(b)
	return b.max - b.min
end

	-- bool touches(box3, box3)
function box3.touches(a,b)
	return	a.min[1] < b.max[1] and
			a.max[1] > b.min[1] and
			a.min[2] < b.max[2] and
			a.max[2] > b.min[2] and
			a.min[3] < b.max[3] and
			a.max[3] > b.min[3]
end

	-- bool contains(box3, vec3)
function box3.contains(a,b)
	return	a.min[1] < b[1] and
			a.max[1] > b[1] and
			a.min[2] < b[2] and
			a.max[2] > b[2] and
			a.min[3] < b[3] and
			a.max[3] > b[3]
end

function box3.containsE(a,b)
	return	a.min[1] <= b[1] and
			a.max[1] >= b[1] and
			a.min[2] <= b[2] and
			a.max[2] >= b[2] and
			a.min[3] <= b[3] and
			a.max[3] >= b[3]
end


-- 'b' is a 'box3', clamps 'self' to be within 'b'
function box3:clamp(b)
	for i=1,3 do
		if self.min[i] < b.min[i] then self.min[i] = b.min[i] end
		if self.max[i] > b.max[i] then self.max[i] = b.max[i] end
	end
	return self
end

-- 'v' is a vec3, stretches 'self' to contain 'v'
function box3:stretch(v)
	for i=1,3 do
		self.min[i] = math.min(self.min[i], v[i])
		self.max[i] = math.max(self.max[i], v[i])
	end
end

function box3.map(a,b) a.min:map(b) a.max:map(b) return a end

function box3.__tostring(b) return '[' .. b.min .. ', ' .. b.max .. ']' end
function box3.__concat(a,b) return tostring(a) .. tostring(b) end

function box3.__add(a,b)
	local bmin, bmax = b, b
	if getmetatable(b) == box3 then bmin = b.min bmax = b.max end
	return box3{min = a.min + bmin, max = a.max + bmax}
end

function box3.__sub(a,b)
	local bmin, bmax = b, b
	if getmetatable(b) == box3 then bmin = b.min bmax = b.max end
	return box3{min = a.min - bmin, max = a.max - bmax}
end

return box3
