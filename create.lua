local table = require 'ext.table'
local class = require 'ext.class'
local ast = require 'parser.lua.ast'

function createVectorClass(dim)
	local classname = 'vec'..dim
	local c = class()
	_G[classname] = c

	c.dim = dim

	--[[
	args
		cmd = command to repeat
		var = variable to replace
		n = how many
		sep = separator. default ' '
	--]]
	local function rep(args)
		local r = table()
		for i=1,args.n do
			r:insert((args.cmd:gsub(args.var, i)))
		end
		return r:concat(args.sep or ' ')
	end

	do
		local args = table{ast._arg(1)}
		for i=1,dim do
			args:insert(ast._arg(i+1))
		end
		local stmts = table()
		for i=1,dim do
			stmts:insert(ast._assign( {ast._index( args[1], ast._number(i) )}, {ast._or(
				--ast._call('tonumber', ast._arg(i+1))
				ast._arg(i+1)
			, ast._number(0))} ))
		end
		c.func__set = ast._function(
			ast._index(ast._var(classname), ast._string'set'),
			args,
			stmts:unpack()
		)
		ast.exec(c.func__set)()
	end

	c.init = c.set

	for _,info in ipairs{
		{'add', '+'},
		{'sub', '-'},
	} do
		local name = info[1]
		local op = info[2]
		local exprs = table()
		for i=1,dim do
			exprs:insert(
				ast['_'..name](
					ast._index(ast._arg(1), ast._number(i)),
					ast._index(ast._arg(2), ast._number(i))
			))
		end
		c['func__'..name] = ast._function(
			ast._index(ast._var(classname), ast._string(name)),
			{ast._arg(), ast._arg()},
			ast._return(
				ast._call(ast._var(classname),
					exprs:unpack()
		)))
		ast.exec(c['func__'..name])()
		c['__'..name] = c[name]
	end

	do
		local exprs = table()
		for i=1,dim do
			exprs:insert(ast._unm(
				ast._index(ast._arg(1), ast._number(i))
			))
		end
		c.func__negative = ast._function(
			ast._index(ast._var(classname), ast._string'negative'),
			{ast._arg()},
			ast._return(
				ast._call(ast._var(classname),
					exprs:unpack()
		)))
		ast.exec(c.func__negative)()
		c.__unm = c.negative
	end

	local function scalarop(name, op)
		local exprs = table()
		for i=1,dim do
			exprs:insert(
				ast['_'..name](
					ast._index(ast._arg(1), ast._number(i)),
					ast._arg(2)
			))
		end
		return ast._function(
			ast._index(ast._var(classname), ast._string(name)),
			{ast._arg(),ast._arg()},
			ast._return(
				ast._call(ast._var(classname),
					exprs:unpack()
		)))
	end

	c.func__mul = scalarop('mul', '*')
	ast.exec(c.func__mul)()
	c.__mul = c.mul

	c.func__div = scalarop('div', '*')
	ast.exec(c.func__div)()
	c.__div = c.div

	do
		local exprs = table()
		for i=1,dim do
			exprs:insert(
				ast._eq(
					ast._index(ast._arg(1), ast._number(i)),
					ast._index(ast._arg(2), ast._number(i))
			))
		end
		c.func__equals = ast._function(
			ast._index(ast._var(classname), ast._string'equals'),
			{ast._arg(), ast._arg()},
			ast._return(
				ast._and(exprs:unpack())
		))
		ast.exec(c.func__equals)()
		c.__eq = c.equals
	end

	do
		local exprs = table()
		for i=1,dim do
			exprs:insert(
				ast._mul(
					ast._index(ast._arg(1), ast._number(i)),
					ast._index(ast._arg(2), ast._number(i))
			))
		end
		c.func__dot = ast._function(
			ast._index(ast._var(classname), ast._string'dot'),
			{ast._arg(), ast._arg()},
			ast._return(
				ast._add(exprs:unpack())
		))
		ast.exec(c.func__dot)()

		-- replace dot's 2 args with 1...
		c.func__lenSq = ast.copy(c.func__dot)
		c.func__lenSq.name = ast._index(ast._var(classname), ast._string'lenSq')
		ast.traverse(c.func__lenSq, function(n)
			if type(n) == 'table' then
				if n.type == 'arg' then
					n.index = 1
				elseif n.type == 'function' then
					n.args = {ast._arg(1)}
				end
			end
			return n
		end)
		ast.exec(c.func__lenSq)()
	end

	-- inlining...
	c.func__length = ast.flatten(
		ast._function(
			ast._index(ast._var(classname), ast._string'length'),
			{ast._arg()},
			ast._return(
				ast._call(
					ast._index(ast._var'math', ast._string'sqrt'),
					ast._call(
						ast._index(ast._var(classname), ast._string'lenSq'),
						ast._arg(1)
		)	)	)	),
		{
			[classname..'.lenSq'] = c.func__lenSq
		}
	)
	ast.exec(c.func__length)()

	c.func__normalize = ast.flatten(
		ast._function(
			ast._index(ast._var(classname), ast._string'normalize'),
			{ast._arg()},
			ast._return(
				ast._mul(
					ast._arg(1),
					ast._par(
						ast._div(
							ast._number(1), ast._call(
								ast._index(ast._var(classname), ast._string'length'), ast._arg(1)
		)	)	)	)	)	),
		{
			[classname..'.length'] = c.func__length
		}
	)
	ast.exec(c.func__normalize)()

	c.unpack = table.unpack

	do
		local exprs = table()
		for i=1,dim do
			if i > 1 then
				exprs:insert(ast._string(', '))
			end
			exprs:insert(ast._index(ast._arg(1), ast._number(i)))
		end
		c.func__tostring = ast._function(
			ast._index(ast._var(classname), ast._string'tostring'),
			{ast._arg()},
			ast._return(
				ast._concat(exprs:unpack())
		))
		ast.exec(c.func__tostring)()
		c.__tostring = c.tostring
	end

	-- because you never know which one your object is going to be...
	function c.__concat(a,b)
		return tostring(a)..tostring(b)
	end

	function c.angle(v) return math.atan2(v[2], v[1]) end

	-- Matlab/matrix compat
	c.normSq = c.lenSq
	c.norm = c.length

	-- 'volume' in my math libs (in the context of a bbox difference-of-min/max vectors)
	-- 'prod' in matlab
	function c.volume(v)
		return v[1] * v[2] * v[3]
	end

	return c
end

return createVectorClass
