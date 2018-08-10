-------------------------------------------------
--
-- 2DShadows
-- Shape.lua
--
-- Class to create a shape object
--
-------------------------------------------------

local Log = require("2dshadows.util.log")

local Shape = {}

function Shape:new( shapeData )
	Log:p(0, "Shape:new()" )

	local shape 	= display.newGroup()
	shape.isCircle 	= false
	shape.radius   	= 0
	shape.vertices 	= {}
	
	if (type(shapeData) == "table") then

		-- create vertices (circle display object at each vertex position)
		for i=1,#shapeData,2 do
			local vertex = display.newCircle( shapeData[i], shapeData[i+1], 3 )
			vertex:setFillColor( 1,1,1, 0 )

			table.insert( shape.vertices, vertex )
			shape:insert(vertex)
		end

	elseif (type(shapeData) == "number") then

		-- create cirlce shape
		shape.isCircle = true
		shape.radius = shapeData

	elseif (type(shapeData) == "nil") then

		error( "ERROR Shape:new() - shapeData or radius is nil" )

	end



	-----------------------------------------------------------------------------
	-- shape:Remove()
	-----------------------------------------------------------------------------
	function shape:Remove()
		Log:p(0,"shape:Remove()")

		  -- remove all vertices polygons
		for i=1,#self.vertices do
			display.remove(self.vertices[i])
			self.vertices[i] = nil
		end

		self:removeSelf( )
		self = nil
	end


   
	return shape
end

return Shape