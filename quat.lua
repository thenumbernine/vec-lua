local class = require 'ext.class'
local vec3 = require 'vec.vec3'
require 'ext.math'	--math.clamp

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

function Quat.dot(a,b)
	return a[1] * b[1] + a[2] * b[2] + a[3] * b[3] + a[4] * b[4]
end

function Quat:rotate(v)
	return vec3(unpack(self * Quat(v[1], v[2], v[3], 0) * self:conjugate()))
end

function Quat:length()
	local lenSq = self:dot(self)
	return math.sqrt(lenSq)
end

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
