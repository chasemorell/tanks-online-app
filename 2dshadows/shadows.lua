-------------------------------------------------
--
-- 2DShadows
-- Shadows.lua
--
-- The main 2D shadow system class
--
-------------------------------------------------

require("2dshadows.shadowMath")

local Log               = require("2dshadows.util.log")
local Vector2D          = require("2dshadows.util.vector2d")
local Helper            = require("2dshadows.util.helper")
local Light             = require("2dshadows.light")
local ShadowCaster      = require("2dshadows.shadowCaster")

local math_floor        = math.floor
local display_remove    = display.remove
local display_newCircle = display.newCircle
local display_newLine   = display.newLine
local display_newPolygon = display.newPolygon
local display_newRect 	= display.newRect
local display_capture 	= display.capture
local table_insert      = table.insert
local system_getTimer   = system.getTimer

local _W                = math_floor( display.actualContentWidth + 0.5 )
local _H                = math_floor( display.actualContentHeight + 0.5 )
local _W2               = _W * 0.5
local _H2               = _H * 0.5





local Shadows = {}

-----------------------------------------------------------------------------
-- Shadows Constructor
--
-- intensity  - intensity (alpha) of the ambient light ( betwwen 0 and 1 - 0 = off, 1 = dark)
-- color      - color table of the ambient shadow 
--
-- Examples
-- local shadows = Shadows:new( 1, {0,0,0} )          -- creates a shadow system with a complete black ambient light (which is nonsense)
-- local shadows = Shadows:new( 0.6, {0.2,0.2,0.2} )  -- creates a shadow system with a with a medium dark neutral ambient light
-- local shadows = Shadows:new( 0.7, {1,0,0} )        -- creates a shadow system with a reddish ambient light
-----------------------------------------------------------------------------

function Shadows:new( intensity, color )
	Log:p(0, "Shadows:new()" )
	local shadows                 	= display.newGroup()
	shadows.x                     	= _W2
	shadows.y                     	= _H2

	shadows.ambientIntensity 		= intensity or 0.8
	shadows.ambientColor 			= color or {0.4, 0.4, 0.4}

	shadows.ambientBackground		= display.newRect( shadows, 0, 0, _W, _H )
	shadows.ambientBackground:setFillColor( shadows.ambientColor[1], shadows.ambientColor[2], shadows.ambientColor[3], shadows.ambientIntensity )
	shadows.ambientTexture			= display.newGroup()	-- the final ambient texture that will be drawn multiplied over the scene
	shadows:insert( shadows.ambientTexture ) 
	shadows.lightTextures           = {}   					-- needed to collect the light textures when creating the ambient buffer
	shadows.isRealAttenuationOn  	= true

	shadows.bgWhite 				= display.newRect( shadows, 0, 0, _W, _H ) 	-- a white backround image used for the shadowBuffers
	shadows.bgWhite:setFillColor( 1,1,1, 1 )

	shadows.shadowPolys             = {}              		-- table with the shadow polygons
	shadows.shadowGroup           	= display.newGroup() 	-- this display group will be the parent of the shadow polygons
	shadows:insert( shadows.shadowGroup ) 		

	shadows.shadowTexture 			= display.newGroup()	-- the display group with all the shadowBuffer images
	shadows.shadowBuffers        	= {}              		-- table of the shadow buffer images (one per light)
	shadows:insert( shadows.shadowTexture ) 

	shadows.lights                	= {}             		-- table of all light objects
	shadows.lightsGroup     		= display.newGroup() 	-- display group of all light objects
	shadows:insert( shadows.lightsGroup )
	
	shadows.shadowCasters         	= {}              		-- table of shadowCaster objects
	shadows.shadowCastersGroup     	= display.newGroup() 	-- display group of shadowCaster objects
	shadows:insert( shadows.shadowCastersGroup )

	shadows.timers                	= {}              		-- table of all timers
	shadows.transitions           	= {}              		-- table of all transitions

	shadows.debugInfo             	= false            		-- if true the draw the debug info text to screen
	shadows.debugDraw             	= false           		-- if true draw the vectors neede for shadow calculation
	shadows.debugText             	= display.newText( {parent=shadows, text="", x=-_W2 + 10, y=-_H2+10, width=256, font=native.systemFont, fontSize=10} )
	shadows.debugText.anchorX     	= 0
	shadows.debugText.anchorY     	= 0
	shadows.debugText:setFillColor( 1,1,1 )
	shadows.debugText.isVisible   	= true
	shadows.debugObjects 			= {} 					-- table of all debug lines, rects etc.
	shadows.debugObjectsGroup     	= display.newGroup() 	-- display group of all debug lines and rectangles etc.
	shadows:insert( shadows.debugObjectsGroup )

	shadows.time                  	= {}               		-- calculate a smoothed average of the time of the shadow drawing
	shadows.timeCounter 			= 0
	
	shadows.deltaTimes         		= {} 					-- store an amount of deltatTimes to calc smooth average
	shadows.deltaTimeCounter		= 0 
	shadows.fps 					= 0


	-----------------------------------------------------------------------------
	-- shadows:AddLight(size,color)
	--
	-- size           - the size of the light texture
	-- color          - a table with three color values
	-- intensity      - intensity (alpha) of the light texture and the shadows it casts
	-- flares         - number of flares, must be between 0 and 7
	-- flareIntensity - intensity (alpha) of the lense flares
	--
	-- Example
	-- AddLight(512,{1,0,0},7) -- creates a red light with seven lenseflares
	-----------------------------------------------------------------------------
	function shadows:AddLight(size,color,intensity,flares,flareIntensity)
	Log:p(1,"shadows:AddLight()")

	local light = Light:new(size,color,intensity,flares,flareIntensity)
	table.insert( self.lights, light )

	self.lightsGroup:insert( light )
	print("#lights " .. #self.lights)

	return light
	end


	-----------------------------------------------------------------------------
	-- shadows:AddShadowCaster(shape, filename, w, h)
	--
	-- shape    - a table with at last three coordinates to create a closed polygon (must be in clockwise order!)
	-- filename - a path to a texture file
	-- w,h      - width and height of the texture
	-- cw       - set this true if the shape vertices order is clockwise. 
	--            this shadow system needs counter clockwise direction. if you set this to true the shape data will be converted
	--            to counter clockwise direction
	--
	-- Example
	-- AddShadowCaster({-45,-45, -45,45, 45,45, 45,-45}, "img/crate.png", 90,90)
	-----------------------------------------------------------------------------
	function shadows:AddShadowCaster(shape, filename, w, h, cw)
		Log:p(0,"shadows:AddShadowCaster()")
	
		if (type(shape) == "table") then

			if shape == nil or #shape < 3 then 
				print("* * * 2D SHADOW ERROR: shape data is nil or has less than 3 vertices -> " .. filename)
				local sc = display.newImageRect( self, filename, w, h )
				return sc 
			end
		
		end

		local cw = cw or false      

		-- if cw is true then convert from clockwise to counter clockwise vertex direction
		if cw == true then
		  	local newShape = {}

		  	for i=#shape,1,-2 do
				table.insert( newShape, shape[i-1] )
				table.insert( newShape, shape[i] )
		  	end
		  	shape = newShape
		end

		-- create a new shadow caster object
		local sc = ShadowCaster:new( filename, w, h, shape )
		table.insert( self.shadowCasters, sc )

		self.shadowCastersGroup:insert( sc )

		return sc
  	end


	-----------------------------------------------------------------------------
	-- shadows:AddPhysicsEditorShadowCaster( filename, w, h, ... )
	-----------------------------------------------------------------------------
	function shadows:AddPhysicsEditorShadowCaster( filename, w, h, ... )
	  	Log:p(1,"shadows:AddPhysicsEditorShadowCaster()")
	  
	  	local sc = ShadowCaster:new( filename, w, h )

	  	for i,v in ipairs(arg) do
			Helper:print_r( v["shape"] )
			local shape = v["shape"]
			local newShape = {}

		  	for i=#shape,1,-2 do
				table.insert( newShape, shape[i-1] )
				table.insert( newShape, shape[i] )
		  	end

			sc:AddShape( newShape )
	  	end

		-- create a new shadow caster object
		
		table.insert( self.shadowCasters, sc )
		self.shadowCastersGroup:insert( sc )

		return sc
	end


	-----------------------------------------------------------------------------
	-- shadows:AllLightsOff()
	-- put all lights off
	-----------------------------------------------------------------------------
	function shadows:AllLightsOff()
		for i=1,#self.lights do
			self.lights[i]:SetOff()
		end
	end


	-----------------------------------------------------------------------------
	-- shadows:AllLightsOff()
	-- put all lights on
	-----------------------------------------------------------------------------
	function shadows:AllLightsOn()
		for i=1,#self.lights do
			self.lights[i]:SetOn()
		end
	end


	-----------------------------------------------------------------------------
	-- shadows:DrawShadows()
	-- the soul of the whole system, here the shadow polygons gets calculated
	-----------------------------------------------------------------------------
	function shadows:DrawShadows()
		local timeStart = system_getTimer()

		-- hide shadowTexture Group
		self.shadowTexture.isVisible = false

		-- hide ambientTexture Group
		self.ambientTexture.isVisible = false

		-- remove all shadow buffer images
		for i=1,#self.shadowBuffers do
		   self.shadowBuffers[i]:removeSelf()
		   self.shadowBuffers[i] = nil
		end

		-- clear all debugging group items
		if self.debugDraw == true then
			for i=1,#self.debugObjects do
			   display_remove(self.debugObjects[i])
			   self.debugObjects[i] = nil
			end
		end

		-- iterate each light

		for l=1, #self.lights do
	  		local light = self.lights[l]

	  		if light.isThrowingShadows == true and light.isOn == true then

				-- remove all shadow polygons
				for i=1,#self.shadowPolys do
				   display_remove(self.shadowPolys[i])
				   self.shadowPolys[i] = nil
				end

				-- create light position vector
				local vLight = Vector2D:new( light.x, light.y )

		  		-- DEBUGDRAW - draw center of light
		  		if self.debugDraw == true then
					local s = display_newCircle( self.debugObjectsGroup, vLight.x, vLight.y, 5 )
					table_insert( self.debugObjects, s )
		  		end

		  		-- ITERATE EACH SHADOW CASTER OBJECTS

		  		for h=1,#self.shadowCasters do
					local sc = self.shadowCasters[h]

					-- iterate each shape object

					for m=1, #sc.shapes do
						local shape = sc.shapes[m]

						--
						-- CIRCLE SHAPES - do the shadow calculation for circle
						--
						if shape.isCircle == true then
							
							-- create position vector of shape's center

							local cx,cy = sc:localToContent( 0, 0 )
							-- subtract half of the display size, since the shadow system origin is at the center of the screen
						  	cx = cx - _W2
						  	cy = cy - _H2
						  	local vC = Vector2D:new(cx,cy)

							-- create vector from light to center of shape

							local vLC = Vector2D:Sub(vLight, vC)

					  		-- DEBUGDRAW - draw center of light
					  		if self.debugDraw == true then
								local line = display_newLine( self.debugObjectsGroup, vLight.x, vLight.y, vC.x, vC.y )
								line:setStrokeColor( 1,0,0 )
								table_insert( self.debugObjects, line )
					  		end


					  		-- create a normal vector vVertex1
					  		-- this is the left point of where the shadow begins

						  	local vVertex1 = Vector2D:NormalA( vLC )

						  	-- normalize vVertex1
						  	vVertex1:normalize()

						  	-- multiplay by radius
						  	vVertex1:mult(shape.radius)

						  	-- add shapes position to move it from 0,0 (center) to shapes position
						  	vVertex1:add( vC )
		

						  	-- create a normal vector vVertex2
					  		-- this is the right point of where the shadow begins

						  	local vVertex2 = Vector2D:NormalB( vLC )

						  	-- nornalize vVertex2
						  	vVertex2:normalize()

						  	-- multiply by radius
						  	vVertex2:mult(shape.radius)

						  	-- add shapes position to move it from 0,0 (center) to shapes position
						  	vVertex2:add( vC )

				  			-- DEBUGDRAW - draw center of light
					  		if self.debugDraw == true then
								local line = display_newLine( self.debugObjectsGroup, vVertex1.x, vVertex1.y, vVertex2.x, vVertex2.y )
								line:setStrokeColor( 1,0,0 )
								table_insert( self.debugObjects, line )

								local rect = display_newRect( self.debugObjectsGroup, vVertex1.x, vVertex1.y, 10, 10 )
								table_insert( self.debugObjects, rect )

								rect = display_newRect( self.debugObjectsGroup, vVertex2.x, vVertex2.y, 10, 10 )
								table_insert( self.debugObjects, rect )
					  		end

					  		local vEdge = Vector2D:Sub( vVertex2, vVertex1 )                        -- vector from vertex1 to vector2 (the edge)
					  		local vLV1 = Vector2D:new( vVertex1.x-vLight.x, vVertex1.y-vLight.y)    -- vector from light to vertex1
					  		local vLV2 = Vector2D:new( vVertex2.x-vLight.x, vVertex2.y-vLight.y)    -- vector from light to vertex2

							-- VECTOR1 FROM EDGE
							-- create projected vertex vector by sub vector light from vertex
							-- by default this is the doubled vector length of the distance from light vertex (light.shadowLength == 1)
							-- if the shadowLength setting from the light is not 1 then scale the projected vector
							if light.shadowLength ~= 1 then
								vLV1Length = vLV1:magnitude()
								vLV1:normalize()
								vLV1:mult( vLV1Length * light.shadowLength )
							end
							local vProjVertex1 = Vector2D:Add( vVertex1, vLV1 )

							-- DEBUGDRAW
							if self.debugDraw == true then
					  			local lv1 = display_newLine( self.debugObjectsGroup, vLight.x, vLight.y, vProjVertex1.x, vProjVertex1.y )
					  			local pv1 = display_newCircle( self.debugObjectsGroup, vProjVertex1.x, vProjVertex1.y, 5 )
					  			table_insert( self.debugObjects, lv1 )
					  			table_insert( self.debugObjects, pv1 )
							end

							-- VECTOR2 FROM EDGE

							-- create projected vertex vector by sub vector light from vertex
							-- by default this is the doubled vector length of the distance from light vertex (light.shadowLength == 1)
							-- if the shadowLength setting from the light is not 1 then scale the projected vector
							if light.shadowLength ~= 1 then
								vLV2Length = vLV2:magnitude()
								vLV2:normalize()
								vLV2:mult( vLV2Length * light.shadowLength )
							end
							local vProjVertex2 = Vector2D:Add( vVertex2, vLV2 )

							-- DEBUGDRAW
							if self.debugDraw == true then
					  			local lv2 = display_newLine( self.debugObjectsGroup, vLight.x, vLight.y, vProjVertex2.x, vProjVertex2.y )
					  			local pv2 = display_newCircle( self.debugObjectsGroup, vProjVertex2.x, vProjVertex2.y, 5 )
					  			table_insert( self.debugObjects, lv2 )
					  			table_insert( self.debugObjects, pv2 )
							end

							-- CREATE END CAP

							-- diameter = vector from vProjVertex1 to vProjVertex2
							local vDiameter  = Vector2D:Sub(vProjVertex2, vProjVertex1)
							local projRadius = vDiameter:magnitude() * 0.5


							-- create projected vLC vector (vector from light to center of shape)
							-- to get center of end cap circle
							if light.shadowLength ~= 1 then
								vLCLength = vLC:magnitude()
								vLC:normalize()
								vLC:mult( vLCLength * light.shadowLength )
							end
							local vProjLC = Vector2D:Mult(vLC, -1)
							local vCapCenter = Vector2D:Sub(vC, vLC)

							-- now we need to overdraw the lower circle with a white rectangle
							-- only the upper half is needed. otherwise the circle bleeds over the other shadow polygon.y
							-- two corners of the rectangle are already found by vProjVertex1 and vProjVertex2 
							
							local vRect3 = Vector2D:new( vProjVertex1.x - vProjLC.x, vProjVertex1.y - vProjLC.y )
							local vRect4 = Vector2D:new( vProjVertex2.x - vProjLC.x, vProjVertex2.y - vProjLC.y )

							local vPV1R3 = Vector2D:Sub(vRect3, vProjVertex1)
							vPV1R3:normalize()
							vPV1R3:mult( projRadius*1.1 )
							vPV1R3:add(vProjVertex1)

							local vPV2R4 = Vector2D:Sub(vRect4, vProjVertex2)
							vPV2R4:normalize()
							vPV2R4:mult( projRadius*1.1 )
							vPV2R4:add(vProjVertex2)	

							-- DEBUGDRAW
							if self.debugDraw == true then
								local capCenter = display_newCircle( self.debugObjectsGroup, vCapCenter.x,vCapCenter.y, 5 )
								capCenter:setFillColor( 1,0,0 )
								table_insert( self.debugObjects, capCenter )

					  			local cap = display.newCircle( self.debugObjectsGroup, vCapCenter.x,vCapCenter.y, projRadius )
					  			cap:setFillColor( 0,0,0, 0 )
					  			cap:setStrokeColor( 1,1,1, 1 )
					  			cap.strokeWidth = 1
					  			table_insert( self.debugObjects, cap )

					  			-- local vrect3 = display_newCircle( self.debugObjectsGroup, vRect3.x, vRect3.y, 5 )
					  			-- vrect3:setFillColor( 0,0,1, 1 )
					  			-- table_insert( self.debugObjects, vrect3 )

					  			-- local vrect4 = display_newCircle( self.debugObjectsGroup, vRect4.x, vRect4.y, 5 )
					  			-- vrect4:setFillColor( 1,0,1, 1 )
					  			-- table_insert( self.debugObjects, vrect4 )

								-- local edge1 = display.newLine( self.debugObjectsGroup, vProjVertex1.x, vProjVertex1.y, vRect3.x, vRect3.y )
								-- edge1:setStrokeColor( 1,0,0 )
								-- table_insert( self.debugObjects, edge1 )

								-- local edge2 = display.newLine( self.debugObjectsGroup, vProjVertex2.x, vProjVertex2.y, vRect4.x, vRect4.y )
								-- edge2:setStrokeColor( 1,0,0 )
								-- table_insert( self.debugObjects, edge2 )

								local PV1R3 = display_newCircle( self.debugObjectsGroup, vPV1R3.x, vPV1R3.y, 5 )
								PV1R3:setFillColor( 1,1,0 )
								table_insert( self.debugObjects, PV1R3 )	

								local PV2R4 = display_newCircle( self.debugObjectsGroup, vPV2R4.x, vPV2R4.y, 5 )
								PV2R4:setFillColor( 1,1,0 )
								table_insert( self.debugObjects, PV2R4 )	

								local polyCutShape = { vPV1R3.x,vPV1R3.y, vPV2R4.x, vPV2R4.y, vProjVertex2.x,vProjVertex2.y, vProjVertex1.x,vProjVertex1.y }
								local bounding = math.getBoundingCentroid( polyCutShape )
								local polyCut = display_newPolygon( self.debugObjectsGroup, bounding.centroid.x, bounding.centroid.y, polyCutShape )
								polyCut:setFillColor(0,0,0,0)
								polyCut.strokeWidth = 1
								table_insert( self.debugObjects, polyCut )			
							end

							-- CREATE SHADOW POLYGON and insert into self.shadowPolys

							-- circle end cap
							local shadowCap = display_newCircle( self.shadowGroup, vCapCenter.x,vCapCenter.y, projRadius )
							shadowCap:setFillColor( 0,0,0, 1 )
							table_insert( self.shadowPolys, shadowCap )

							-- -- SOFT SHADOW TEST
							-- for s=1,10 do
							-- 	local softline = display.newCircle( self.shadowGroup, vProjLC.x,vProjLC.y, projRadius+2*s )
							-- 	softline:setFillColor( 0,0,0, 1-s*0.1 )
							-- 	table_insert( self.shadowPolys, softline )
							-- end

							-- cut the lower half of the circle away (draw with white aobve circle)
							local polyCutShape = { vPV1R3.x,vPV1R3.y, vPV2R4.x, vPV2R4.y, vProjVertex2.x,vProjVertex2.y, vProjVertex1.x,vProjVertex1.y }
							local bounding = math.getBoundingCentroid( polyCutShape )
							local polyCut = display.newPolygon( self.shadowGroup, bounding.centroid.x, bounding.centroid.y, polyCutShape )
							polyCut:setFillColor( 1,1,1, 1 )
							table_insert( self.shadowPolys, polyCut )

							-- shadow polygon
							local shadowVertices = {vVertex1.x, vVertex1.y, vVertex2.x, vVertex2.y, vProjVertex2.x, vProjVertex2.y, vProjVertex1.x, vProjVertex1.y}
							local bounding = math.getBoundingCentroid( shadowVertices )
							local shadowPoly = display_newPolygon( self.shadowGroup, bounding.centroid.x, bounding.centroid.y, shadowVertices )
							shadowPoly:setFillColor( 0,0,0, 1 )
							table_insert( self.shadowPolys, shadowPoly )


						--
						-- POLYGON SHAPES - do the shadow calculation for polygon shapes
						--
						else
							-- iterate each vertex of the shape
							
							local firstdot 	= nil
							local lastdot 	= nil 	-- save the alst dot product of last edge, if there is a change in the sign of the dot, then this vertex is a boundary vertex

							for i=1,#shape.vertices do

						 		-- create vertex vectors

						  		local v1x,v1y = shape.vertices[i]:localToContent( 0, 0 )
						  		local v2x,v2y
						  		-- at last vertex we have to use the very first vertex of the vertices 
						  		-- lists to create the last edge of the shape
						  		if i == #shape.vertices then
									v2x,v2y = shape.vertices[1]:localToContent( 0, 0 )
						  		else
									v2x,v2y = shape.vertices[i+1]:localToContent( 0, 0 )
						  		end

						  		-- subtract half of the display size, since the shadow system origin is at the center of the screen
						  		v1x = v1x - _W2
						  		v1y = v1y - _H2
						  		v2x = v2x - _W2
						  		v2y = v2y - _H2

						  		local vVertex1 = Vector2D:new( v1x, v1y )                               -- position vector of vertex1
						  		local vVertex2 = Vector2D:new( v2x, v2y )                               -- position vector of vertex2

						  		local vEdge = Vector2D:Sub( vVertex2, vVertex1 )                        -- vector from vertex1 to vector2 (the edge)
						  		local vLV1 = Vector2D:new( vVertex1.x-vLight.x, vVertex1.y-vLight.y)    -- vector from light to vertex1
						  		local vLV2 = Vector2D:new( vVertex2.x-vLight.x, vVertex2.y-vLight.y)    -- vector from light to vertex2

						 		 -- NORMAL OF EDGE
						  		local vNormal = Vector2D:NormalA( vEdge )

						 		 -- DOT PRUDOCT OF vLV1 and vNormal
						  		local dot = vLV1:dot( vNormal )

						  		-- DEBUGDRAW
						  		if self.debugDraw == true then
									local dotLine = display_newLine( self.debugObjectsGroup, vVertex1.x, vVertex1.y, vVertex2.x, vVertex2.y )
									if dot > 0 then
							  			dotLine:setStrokeColor( 0,0,1 )
									end
									table_insert( self.debugObjects, dotLine )
						  		end

						  		-- only check the edges that are facing the light source ( = dot > 0 )

						  		local vProjVertex1 = nil
						  		local vProjVertex2 = nil

						  		if dot > 0 then

									-- VECTOR1 FROM EDGE
									-- create projected vertex vector by sub vector light from vertex
									-- by default this is the doubled vector length of the distance from light vertex (light.shadowLength == 1)
									-- if the shadowLength setting from the light is not 1 then scale the projected vector
									if light.shadowLength ~= 1 then
										vLV1Length = vLV1:magnitude()
										vLV1:normalize()
										vLV1:mult( vLV1Length * light.shadowLength )
									end								
									vProjVertex1 = Vector2D:Add( vVertex1, vLV1 )

									-- VECTOR2 FROM EDGE

									-- create projected vertex vector by sub vector light from vertex
									-- if the shadowLength setting from the light is not 1 then scale the projected vector
									if light.shadowLength ~= 1 then
										vLV2Length = vLV2:magnitude()
										vLV2:normalize()
										vLV2:mult( vLV2Length * light.shadowLength )
									end										
									vProjVertex2 = Vector2D:Add( vVertex2, vLV2 )

									-- CREATE SHADOW POLYGON and insert into self.shadowPolys

									local shadowVertices = {vVertex1.x, vVertex1.y, vVertex2.x, vVertex2.y, vProjVertex2.x, vProjVertex2.y, vProjVertex1.x, vProjVertex1.y}
									local bounding = math.getBoundingCentroid( shadowVertices )

									local shadowPoly = display_newPolygon( self.shadowGroup, bounding.centroid.x, bounding.centroid.y, shadowVertices )
									shadowPoly:setFillColor( 0,0,0, 1 )

									table_insert( self.shadowPolys, shadowPoly )
						  		end -- if dot > 0

								-- DEBUGDRAW
								if self.debugDraw == true then
									local c1 = display_newCircle( self.debugObjectsGroup, vVertex1.x, vVertex1.y, 3 )
									local c2 = display_newCircle( self.debugObjectsGroup, vVertex2.x, vVertex2.y, 3 )
									table_insert( self.debugObjects, c1 )
									table_insert( self.debugObjects, c2 )

									local pv1 = nil
									local pv2 = nil
									if dot > 0 then
							  			local lv1 = display_newLine( self.debugObjectsGroup, vLight.x, vLight.y, vProjVertex1.x, vProjVertex1.y )
							  			pv1 = display_newCircle( self.debugObjectsGroup, vProjVertex1.x, vProjVertex1.y, 5 )
							  			table_insert( self.debugObjects, lv1 )
							  			table_insert( self.debugObjects, pv1 )

							  			local lv2 = display_newLine( self.debugObjectsGroup, vLight.x, vLight.y, vProjVertex2.x, vProjVertex2.y )
							  			pv2 = display_newCircle( self.debugObjectsGroup, vProjVertex2.x, vProjVertex2.y, 5 )
							  			table_insert( self.debugObjects, lv2 )
							  			table_insert( self.debugObjects, pv2 )
						  			end

							  		-- check if the dot sign has changed (if yes, then boundary vertex)
							  		if i > 1 then
							  			if ( dot > 0 and lastdot < 0 ) or ( dot < 0 and lastdot > 0 ) then
							  				if dot > 0 then pv1:setFillColor( 1,0,0 ) end
											c1:setFillColor( 1,0,0 )
							  			end
							  		end
							  		if i == #shape.vertices then
							  			if ( dot > 0 and firstdot < 0 ) or ( dot < 0 and firstdot > 0 ) then
							  				if dot > 0 then pv2:setFillColor( 0,0,1 ) end
											c2:setFillColor( 0,0,1 )
							  			end				  			
							  		end
								end

						  		-- save current dot to lastdot
						  		lastdot = dot
						  		if i == 1 then firstdot = dot end

							end -- for each vertex
						end -- if shape is circle
					end -- for each shape
		  		end -- for each shadow caster


		  		-- CREATE SHADOW BUFFER IMAGE FOR EACH LIGHT

		  		self.bgWhite.isVisible = true
		  		self.bgWhite:toFront()

				self.shadowGroup.isVisible = true
				self.shadowGroup:toFront( )

				-- CAPTURE IMAGE and add to self.shadowBuffers
				local shadowBufferImage 	= display_capture( self )
				self.shadowBuffers[#self.shadowBuffers+1] = shadowBufferImage
				self.shadowTexture:insert( shadowBufferImage )

				shadowBufferImage.alpha 		= light.shadowIntensity
				shadowBufferImage.x 			= 0
				shadowBufferImage.y 			= 0
				shadowBufferImage.blendMode		= "multiply"

				self.bgWhite.isVisible 			= false
				self.shadowGroup.isVisible 		= false

			  	-- DEBUGDRAW LIGHT
				if self.debugDraw == true then
					local r1 = display_newRect( self.debugObjectsGroup, light.x, light.y, 100,100 )
					r1:setFillColor( 0,0,0,0 )
					r1:setStrokeColor(1,1,1,1)
					r1.strokeWidth = 1
					table_insert( self.debugObjects, r1 )

					local bulb = display.newImageRect( self.debugObjectsGroup, "2dshadows/img/bulb.png", 16, 28 )
					table_insert( self.debugObjects, bulb )
					bulb.x = light.x + 65
					bulb.y = light.y - 35
				end

			end -- if light.isThrowingShadows == true
		end -- for each light


		-- CREATE FINAL SHADOW TEXTURE IMAGE by combining each shadow buffer image
			
		-- draw each bufferImage
		self.shadowTexture.isVisible = true
		self.shadowTexture:toFront()

		-- Move Shadow Casters to front, so that shadows are drawn below the images
		self.shadowCastersGroup:toFront( )


		-- REAL ATTENUATION

		if self.isRealAttenuationOn then
			-- CREATE AMBIENT TEXTURE IMAGE by combining each ambient buffer image
			self:CreateAmbientTexture()

			-- draw each bufferImage
			self.ambientTexture.isVisible = true
			self.ambientTexture:toFront()
		end

		-- put lights on top of everything

		self.lightsGroup:toFront( )


		-- draw debugging group
		if self.debugDraw == true then
			self.debugObjectsGroup.isVisible = true
			self.debugObjectsGroup:toFront( )
		else
			self.debugObjectsGroup.isVisible = false
		end


		-- update time measerument
		if self.timeCounter >= 100 then self.timeCounter = 0 end
		self.timeCounter = self.timeCounter + 1
		self.time[self.timeCounter] = system_getTimer() - timeStart
	end -- eof




	-----------------------------------------------------------------------------
	-- shadows:CreateAmbientTexture()
	-----------------------------------------------------------------------------
	function shadows:CreateAmbientTexture()

		-- REAL ATTENUATION AMBIENT LIGHT

		-- delete old ambient texture
		self.ambientTexture:removeSelf()

		-- create white background
		self.bgWhite.isVisible = true
		self.bgWhite:toFront()

		-- create ambient imagebuffer for each light
	  	self.ambientBackground.isVisible = true
	  	self.ambientBackground:toFront()

	  	for l=1,#self.lights do
	  		local light = self.lights[l]

	  		if light.isOn == true then

		  		-- create light texture at lights position
		  		local lightTexture = display.newImageRect( self, light.texturefilename, light.texturesize[1], light.texturesize[2] )
		  		lightTexture.x = light.x
			  	lightTexture.y = light.y
			  	lightTexture.xScale = light.size
			  	lightTexture.yScale = light.size
			  	lightTexture.alpha 	= light.intensity
			  	--lightTexture.alpha = light.imageLight.alpha
			  	lightTexture.rotation = light.rotation

			  	table_insert( self.lightTextures, lightTexture )

			end
		end

	  	-- CAPTURE IMAGE
		self.ambientTexture	= display_capture( self, { saveToPhotoLibrary=false } )
		self:insert( self.ambientTexture )

		self.ambientTexture.alpha 		= 1
		self.ambientTexture.x 			= 0
		self.ambientTexture.y 			= 0
		self.ambientTexture.blendMode	= "multiply"

		-- hide the ambient stuff again
		self.ambientBackground.isVisible = false
		self.bgWhite.isVisible = false

		-- clear the light textures
		for i=1,#self.lightTextures do
			self.lightTextures[i]:removeSelf()
			self.lightTextures[i] = nil
		end
	end


	-----------------------------------------------------------------------------
	-- shadows:Pause()
	-----------------------------------------------------------------------------
	function shadows:Pause()
	  	Log:p(1,"shadows:Pause()")
	  
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
	-- shadows:Resume()
	-----------------------------------------------------------------------------
	function shadows:Resume()
	  	Log:p(1,"shadows:Resume()")

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
	-- shadows:Remove()
	-----------------------------------------------------------------------------
	function shadows:Remove()
	  	Log:p(1,"shadows:Remove()")

	  	-- Remove all light objects
	  	for i=1,#self.lights do
	  		self.lights[i]:Remove()
	  	end

	  	-- Remove all shadow caster objects
	  	for i=1,#self.shadowCasters do
	  		self.shadowCasters[i]:Remove()
	  	end

	  	-- cancel all timers
	  	for k,v in pairs(self.timers) do
		 	timer.cancel( v )
	  	end

	  	-- cancel all transitions
	  	for k,v in pairs(self.transitions) do
		 	timer.cancel( v )
	  	end

	  	self:removeSelf( )
	  	self = nil
	end
   

	-----------------------------------------------------------------------------
	-- shadows:SetRealAttenuation()
	-----------------------------------------------------------------------------
	function shadows:SetRealAttenuation( newValue )
		Log:p(1, "shadows:SetRealAttenuation()", tostring(newValue))
   		self.isRealAttenuationOn = newValue

   		if self.isRealAttenuationOn == false then
   			self.ambientBackground.blendMode = "multiply"
   		else
   			self.ambientBackground.blendMode = "normal"
   		end
   	end


	--###########################################################################
	-- TIMERS & UPDATE 
	--###########################################################################


	-----------------------------------------------------------------------------
	-- shadows:Update()
	-----------------------------------------------------------------------------
	function shadows:Update()
		Log:p(0, "shadows:Update()")
		self:DrawShadows()
	end


	-----------------------------------------------------------------------------
	-- shadows:UpdateDebug()
	-----------------------------------------------------------------------------
	function shadows:UpdateDebug()
		Log:p(0, "shadows:UpdateDebug")

		-- calculate a smoothed average of how long the shadow calclulating takes
		local avgTime = 0
		for i=1,#self.time do
			avgTime = avgTime + self.time[i]
		end
		avgTime = math.round(avgTime / #self.time)

		self:UpdateFPS()

		txt = "#lights:" .. tostring(#self.lights) .. "\n"
		txt = txt .. "#shadowCasters: " .. tostring(#self.shadowCasters) .. "\n"
		txt = txt .. "#polygons: " .. tostring(#self.shadowPolys) .. "\n"
		txt = txt .. "Real Attenuation: " .. tostring(self.isRealAttenuationOn) .. "\n"
		txt = txt .. "time to draw: " .. tostring(avgTime) .. " msecs\n"
		txt = txt .. "FPS: " .. tostring(self.fps) .. "\n"
		self.debugText.text = txt
		self.debugText:toFront( )
	end


	-----------------------------------------------------------------------------
	-- shadows:UpdateFPS()
	-----------------------------------------------------------------------------
	function shadows:UpdateFPS()
		local avgSize = 10
		local curTime = system_getTimer()

		self.deltaTimeCounter = self.deltaTimeCounter + 1

		shadows.deltaTimes[self.deltaTimeCounter] = curTime

		if self.deltaTimeCounter == avgSize then 
			local avg = 0
			for i=1,self.deltaTimeCounter-1 do
				local delta = shadows.deltaTimes[i+1] - shadows.deltaTimes[i]
				avg = avg + delta
			end
			avg = avg / self.deltaTimeCounter
			self.fps = math.round( 1000 / avg )
			self.deltaTimeCounter = 0
		end
	end


	-----------------------------------------------------------------------------
	-- shadows:timer( event )
	-----------------------------------------------------------------------------
	function shadows:timer( event )
		self:Update()
	  	if self.debugInfo then self:UpdateDebug() end
	end
	
	local tm = timer.performWithDelay( 1, shadows, 0 )
	table.insert( shadows.timers, tm )
	

   return shadows
end

return Shadows