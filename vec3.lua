local createVectorClass = require 'vec.create'
local vec3 = createVectorClass(3)

function vec3.cross(a,b)
	return vec3(
		a[2] * b[3] - a[3] * b[2],
		a[3] * b[1] - a[1] * b[3],
		a[1] * b[2] - a[2] * b[1])
end

return vec3
