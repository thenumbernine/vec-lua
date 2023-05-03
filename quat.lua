local class = require 'ext.class'
local vec3 = require 'vec.vec3'
local math = require 'ext.math'	--math.clamp
local table = require 'ext.table'

local Quat = class()

function Quat:init(x,y,z,w)
	self[1] = x or 0
	self[2] = y or 0
	self[3] = z or 0
	self[4] = w or 1
end

function Quat.mul(q, r, res)
	if not res then res = Quat() end

	local a = (q[4] + q[1]) * (r[4] + r[1])
	local b = (q[3] - q[2]) * (r[2] - r[3])
	local c = (q[1] - q[4]) * (r[2] + r[3])
	local d = (q[2] + q[3]) * (r[1] - r[4])
	local e = (q[1] + q[3]) * (r[1] + r[2])
	local f = (q[1] - q[3]) * (r[1] - r[2])
	local g = (q[4] + q[2]) * (r[4] - r[3])
	local h = (q[4] - q[2]) * (r[4] + r[3])

	res[1] = a - .5 * ( e + f + g + h)
	res[2] = -c + .5 * ( e - f + g - h)
	res[3] = -d + .5 * ( e - f - g + h)
	res[4] = b + .5 * (-e - f + g + h)

	return res
end
Quat.__mul = Quat.mul

function Quat.add(a,b,res)
	if not res then res = Quat() end
	res[1] = a[1] + b[1]
	res[2] = a[2] + b[2]
	res[3] = a[3] + b[3]
	res[4] = a[4] + b[4]
	return res
end
Quat.__add = Quat.add

function Quat.sub(a,b,res)
	if not res then res = Quat() end
	res[1] = a[1] - b[1]
	res[2] = a[2] - b[2]
	res[3] = a[3] - b[3]
	res[4] = a[4] - b[4]
	return res
end
Quat.__sub = Quat.sub

function Quat.negate(a,res)
	if not res then res = Quat() end
	res[1] = -a[1]
	res[2] = -a[2]
	res[3] = -a[3]
	res[4] = -a[4]
	return res
end
-- bad: some Lua implementations (Lua 5.3.6, LuaJIT 2.1.0, as I see it) pass TWO args into __unm, both are the same object
-- so if we forward args as-is to negate() then we get the result as the source
--Quat.__unm = Quat.negate
-- so instead ...
function Quat:__unm() return self:negate() end

-- in degrees
function Quat:toAngleAxis(res)
	if not res then res = {} end

	local cosom = math.clamp(self[4], -1, 1)

	local halfangle = math.acos(cosom)
	local scale = math.sin(halfangle)

	if scale >= -.00001 and scale <= .00001 then
		res[1] = 0
		res[2] = 0
		res[3] = 1
		res[4] = 0
	else
		scale = 1 / scale
		res[1] = self[1] * scale
		res[2] = self[2] * scale
		res[3] = self[3] * scale
		res[4] = halfangle * 360 / math.pi
	end

	return res
end

function Quat.fromAngleAxis(q, x, y, z, degrees)
	local vlen = math.sqrt(x*x + y*y + z*z)
	local radians = math.rad(degrees)
	local costh = math.cos(radians / 2)
	local sinth = math.sin(radians / 2)
	local vscale = sinth / vlen
	q[1] = x * vscale
	q[2] = y * vscale
	q[3] = z * vscale
	q[4] = costh

	return q
end

function Quat.vectorRotate(q, v1, v2)
	-- TODO ffi compat, prefer v1:unpack() if available
	v1 = vec3(table.unpack(v1)):normalize()
	v2 = vec3(table.unpack(v2)):normalize()
	local costh = v1:dot(v2)
	local eps = 1e-9
	if math.abs(costh) > 1 - eps then
		return Quat()
	else
		local theta = math.acos(math.clamp(costh,-1,1))
		local v3 = v1:cross(v2):normalize()
		return Quat():fromAngleAxis(v3[1], v3[2], v3[3], math.deg(theta))
	end
end

function Quat.xAxis(q, res)
	if not res then res = vec3() end
	res[1] = 1 - 2 * (q[2] * q[2] + q[3] * q[3])
	res[2] = 2 * (q[1] * q[2] + q[3] * q[4])
	res[3] = 2 * (q[1] * q[3] - q[4] * q[2])
	return res
end

function Quat.yAxis(q, res)
	if not res then res = vec3() end
	res[1] = 2 * (q[1] * q[2] - q[4] * q[3])
	res[2] = 1 - 2 * (q[1] * q[1] + q[3] * q[3])
	res[3] = 2 * (q[2] * q[3] + q[4] * q[1])
	return res
end

function Quat.zAxis(q, res)
	if not res then res = vec3() end
	res[1] = 2 * (q[1] * q[3] + q[4] * q[2])
	res[2] = 2 * (q[2] * q[3] - q[4] * q[1])
	res[3] = 1 - 2 * (q[1] * q[1] + q[2] * q[2])
	return res
end

function Quat.toMatrix(q, mat)
	if not mat then mat = {} end
	mat[1] = Quat.xAxis(q, mat[1])
	mat[2] = Quat.yAxis(q, mat[2])
	mat[3] = Quat.zAxis(q, mat[3])
	return mat
end

-- Quat's fromMatrix uses col-major  (just like 'toMatrix')
-- https://math.stackexchange.com/a/3183435/206369
function Quat.fromMatrix(q, mat)
	local m00, m01, m02 = table.unpack(mat[1])
	local m10, m11, m12 = table.unpack(mat[2])
	local m20, m21, m22 = table.unpack(mat[3])
	local t
	if m22 < 0 then
		if m00 > m11 then
			t = 1 + m00 - m11 - m22
			q[1] = t
			q[2] = m01+m10
			q[3] = m20+m02
			q[3] = m12-m21
		else
			t = 1 - m00 + m11 - m22
			q[1] = m01+m10
			q[2] = t
			q[3] = m12+m21
			q[3] = m20-m02
		end
	else
		if m00 < -m11 then
			t = 1 - m00 - m11 + m22
			q[1] = m20+m02
			q[2] = m12+m21
			q[3] = t
			q[3] = m01-m10
		else
			t = 1 + m00 + m11 + m22
			q[1] = m12-m21
			q[2] = m20-m02
			q[3] = m01-m10
			q[3] = t
		end
	end
	assert(t, "somehow we missed this")
	q[1] = q[1] * .5 / math.sqrt(t)
	q[2] = q[2] * .5 / math.sqrt(t)
	q[3] = q[3] * .5 / math.sqrt(t)
	q[3] = q[3] * .5 / math.sqrt(t)
	return q
end


function Quat.dot(a,b)
	return a[1] * b[1] + a[2] * b[2] + a[3] * b[3] + a[4] * b[4]
end

function Quat:rotate(v)
	return vec3(table.unpack(self * Quat(v[1], v[2], v[3], 0) * self:conjugate()))
end

function Quat:lenSq()
	return self:dot(self)
end

function Quat:length()
	local lenSq = self:lenSq()
	return math.sqrt(lenSq)
end

-- Matlab/matrix alias.
Quat.normSq = Quat.lenSq
Quat.norm = Quat.length

-- when using conj for quaternion orientations, you can get by just negative'ing the w
-- ... since q == inv(q)
-- makes a difference when you are using this for 3D rotations
function Quat:conjugate()
	return Quat(-self[1], -self[2], -self[3], self[4])
end

-- in-place
function Quat:normalize()
	local len = self:length()
	if math.abs(len) < 1e-20 then
		self[1] = 0
		self[2] = 0
		self[3] = 0
		self[4] = 1
	else
		local invlen = 1 / len
		self[1] = self[1] * invlen
		self[2] = self[2] * invlen
		self[3] = self[3] * invlen
		self[4] = self[4] * invlen
	end
	return self
end

function Quat:__tostring()
	return table.concat(self, ',')
end

return Quat
