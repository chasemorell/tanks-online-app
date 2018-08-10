-------------------------------------------------
--
-- 2DShadows
-- ShadowCaster.lua
--
-- Class to create a shadow caster object
--
-------------------------------------------------

local Log 		= require("2dshadows.util.log")
local Helper    = require("2dshadows.util.helper")
local Shape 	= require("2dshadows.shape")


local ShadowCaster = {}

function ShadowCaster:new(filename,width,height,shapeData)
	Log:p(0, "ShadowCaster:new()" )

	local sc = display.newGroup()

	sc.x                       	= px or 0
	sc.y                       	= py or 0

	if filename then
		sc.image               	= display.newImageRect( sc, filename, width or 100, height or 100 )
	end

	sc.markX                   	= 0               	-- this is needed for dragging the scs
	sc.markY                   	= 0
	sc.type                    	= "sc"
	sc.isDraggable             	= false
	sc.isRotateable            	= true
	sc.hasMoved                	= false           	-- neded to check if sc has been dragged or only tapped
	sc.isTouched               	= false           	-- if the sc is currently being touched

	sc.timers                  	= {}              	-- table of all timers
	sc.transitions             	= {}              	-- table of all transitions

	sc.debug                   	= false
	sc.debugText               	= display.newText( {parent=sc, text="Debug", x=0, y=0, width=128, font=native.systemFont, fontSize=10} )
	sc.debugText:setFillColor( 0,0,0 )
	sc.debugText.isVisible     	= false

	sc.shapes 					= {} 				-- table of all shapes, each shadow caster can hold several shapes, each shape throws one shadow 

	-- CREATE THE VERTICES OF THE SHAPE
	-- in this case each vertex a simple circle display object
	-- I use display objects so I can parent them to the main displayGroup (sc = shadow caster)
	-- this way the 'vertices' gets automatically updated when the whole shadow caster object is moved

	if shapeData ~= nil then
		local newShape = Shape:new( shapeData )
		table.insert( sc.shapes, newShape )
		sc:insert( newShape )
	end

	-----------------------------------------------------------------------------
	-- sc:AddShape( shapeData )
	-- adds a new shape to a shadow caster
	-----------------------------------------------------------------------------
	function sc:AddShape( shapeData, cw )
		local cw = cw or false      

		-- if cw is true then convert from clockwise to counter clockwise vertex direction
		if cw == true then
		  	local newShape = {}

		  	for i=#shapeData,1,-2 do
				table.insert( newShape, shapeData[i-1] )
				table.insert( newShape, shapeData[i] )
		  	end
		  	shapeData = newShape
		end

		local newShape = Shape:new( shapeData )
		table.insert( self.shapes, newShape )
		self:insert( newShape )
	end

	-----------------------------------------------------------------------------
	-- sc:Pause()
	-----------------------------------------------------------------------------
	function sc:Pause()
		Log:p(1,"sc:Pause()")

		-- pause all timers
		for k,v in pairs(self.timers) do
		 	timer.pause( v )
		end

		-- pause all transitions
		for k,v in pairs(self.transitions) do
		 	transition.pause( v )
		end
	end

	-----------------------------------------------------------------------------
	-- sc:Resume()
	-----------------------------------------------------------------------------
	function sc:Resume()
		Log:p(1,"sc:Resume()")

		-- resume all timers
		for k,v in pairs(self.timers) do
		 	timer.resume( v )
		end

		-- resume all transitions
		for i,v in ipairs(self.transitions) do
		 	transition.resume( v )
		end
	end


	-----------------------------------------------------------------------------
	-- sc:Remove()
	-----------------------------------------------------------------------------
	function sc:Remove()
		Log:p(1,"sc:Remove()")

		-- cancel all timers
		for k,v in pairs(self.timers) do
		 	timer.cancel( v )
		end

		-- cancel all transitions
		for k,v in pairs(self.transitions) do
		 	timer.cancel( v )
		end

		-- remove all vertices polygons
		for i=1,#self.shapes do
		 	self.shapes[i]:Remove()
		end

		self:removeSelf( )
		self = nil
	end

   -----------------------------------------------------------------------------
   -- sc:SetDraggable( newValue )
   -- set true or false if the shadow caster should be draggable or not
   -----------------------------------------------------------------------------
   function sc:SetDraggable( newValue )
      self.isDraggable = newValue
   end

	-----------------------------------------------------------------------------
	-- sc:touch(event)
	-----------------------------------------------------------------------------
	function sc:touch(event)
	  	Log:p(0, "sc:touch phase:" .. event.phase)

	 	if event.phase == "began" then
		 	-- begin focus
		 	display.getCurrentStage():setFocus( self, event.id )

		 	self.isFocus   = true
		 	self.isTouched = true

		 	self.markX = self.x
		 	self.markY = self.y

		 	-- physics off
		 	self.isBodyActive = false

	  	elseif self.isFocus then

		 	if event.phase == "moved" then
				self.hasMoved = true

				-- drag touch sc
				if self.isDraggable == true then
			   		self.x = event.x - event.xStart + self.markX
			   		self.y = event.y - event.yStart + self.markY
				end

		 	elseif event.phase == "ended" or event.phase == "cancelled" then
			
				-- check if has moved or only tapped
				if self.hasMoved == false then
			   		if self.isRotateable == true then
				 		transition.to( self, {rotation=self.rotation+30, time=500, transition=easing.outExpo, onComplete=function() 
					 		self.rotation = self.rotation - (self.rotation % 30)
					 		print(self.rotation) 
				  		end })
			   		end
				end

				-- end focus
				display.getCurrentStage():setFocus( self, nil )
				self.isFocus   = false
				self.hasMoved  = false
				self.isTouched = false

				-- physics on
				self.isBodyActive = true
		 	end

	  	end

	  	return true
	end

   	-- create an event listener for touching
   	sc:addEventListener("touch", object)

   	return sc
end

return ShadowCaster