package = "vec"
version = "dev-1"
source = {
	url = "git+https://github.com/thenumbernine/vec-lua"
}
description = {
	summary = "Vector Math Library in Lua",
	detailed = "Vector Math Library in Lua",
	homepage = "https://github.com/thenumbernine/vec-lua",
	license = "MIT"
}
dependencies = {
	"lua >= 5.1"
}
build = {
	type = "builtin",
	modules = {
		["vec.box2"] = "box2.lua",
		["vec.box3"] = "box3.lua",
		["vec.create"] = "create.lua",
		["vec.quat"] = "quat.lua",
		["vec"] = "vec.lua",
		["vec.vec2"] = "vec2.lua",
		["vec.vec3"] = "vec3.lua",
		["vec.vec4"] = "vec4.lua"
	}
}
