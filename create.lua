local table = require 'ext.table'
local class = require 'ext.class'
local ast = require 'parser.ast'

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
			stmts:insert(ast._assign( {ast._index( args[1], i )}, {ast._or(
				--ast._call('tonumber', ast._arg(i+1))
				ast._arg(i+1)
			, 0)} ))
		end
		c.func__set = ast._function(
			ast._index(ast._var(classname), ast._string'set'),
			args,
			unpack(stmts)	
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
		local exprs = {}
		for i=1,dim do
			table.insert(exprs, 
				ast['_'..name](
					ast._index(ast._arg(1), i), 
					ast._index(ast._arg(2), i)
			))
		end
		c['func__'..name] = ast._function(
			ast._index(ast._var(classname), ast._string(name)),
			{ast._arg(), ast._arg()},
			ast._return(
				ast._call(ast._var(classname),
					unpack(exprs)
		)))
		ast.exec(c['func__'..name])()
		c['__'..name] = c[name]
	end
	
	do
		local exprs = {}
		for i=1,dim do
			table.insert(exprs, ast._unm(
				ast._index(ast._arg(1), i)
			))
		end
		c.func__negative = ast._function(
			ast._index(ast._var(classname), ast._string'negative'),
			{ast._arg()},
			ast._return(
				ast._call(ast._var(classname),
					unpack(exprs)
		)))
		ast.exec(c.func__negative)()
		c.__unm = c.negative
	end

	local function scalarop(name, op)
		local exprs = {}
		for i=1,dim do
			table.insert(exprs, 
				ast['_'..name](
					ast._index(ast._arg(1), i), 
					ast._arg(2)
			))
		end
		return ast._function(
			ast._index(ast._var(classname), ast._string(name)),
			{ast._arg(),ast._arg()},
			ast._return(
				ast._call(ast._var(classname),
					unpack(exprs)
		)))
	end

	c.func__mul = scalarop('mul', '*')
	ast.exec(c.func__mul)()
	c.__mul = c.mul
	
	c.func__div = scalarop('div', '*')
	ast.exec(c.func__div)()
	c.__div = c.div
	
	do
		local exprs = {}
		for i=1,dim do
			table.insert(exprs, 
				ast._eq(
					ast._index(ast._arg(1), i),
					ast._index(ast._arg(2), i)
			))
		end
		c.func__equals = ast._function(
			ast._index(ast._var(classname), ast._string'equals'),
			{ast._arg(), ast._arg()},
			ast._return(
				ast._and(unpack(exprs))
		))
		ast.exec(c.func__equals)()
		c.__eq = c.equals
	end
	
	do
		local exprs = {}
		for i=1,dim do
			table.insert(exprs,
				ast._mul(
					ast._index(ast._arg(1), i),
					ast._index(ast._arg(2), i)
			))
		end
		c.func__dot = ast._function(
			ast._index(ast._var(classname), ast._string'dot'),
			{ast._arg(), ast._arg()},
			ast._return(
				ast._add(unpack(exprs))
		))
		ast.exec(c.func__dot)()

		-- replace dot's 2 args with 1...
		c.func__lenSq = ast.copy(c.func__dot)
		c.func__lenSq.name = classname..'.lenSq'
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
							1, ast._call(
								ast._index(ast._var(classname), ast._string'length'), ast._arg(1)
		)	)	)	)	)	),
		{
			[classname..'.length'] = c.func__length
		}
	)
	ast.exec(c.func__normalize)()

	do
		local exprs = {}
		for i=1,dim do
			if i > 1 then
				table.insert(exprs, ast._string(', '))
			end
			table.insert(exprs, ast._index(ast._arg(1), i))
		end
		c.func__tostring = ast._function(
			ast._index(ast._var(classname), ast._string'tostring'),
			{ast._arg()},
			ast._return(
				ast._concat(unpack(exprs))
		))
		ast.exec(c.func__tostring)()
		c.__tostring = c.tostring
	end
	
	-- because you never know which one your object is going to be...
	function c.__concat(a,b)
		return tostring(a)..tostring(b)
	end

	function c.angle(v) return math.atan2(v[2], v[1]) end
	
	return c
end

return createVectorClass
