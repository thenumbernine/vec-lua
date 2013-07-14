local createVectorClass = require 'vec.create'

local vec2 = createVectorClass(2)

function vec2.determinant(a,b)
	return a[1] * b[2] - a[2] * b[1]
end

return vec2