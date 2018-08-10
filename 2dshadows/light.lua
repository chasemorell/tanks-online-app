-------------------------------------------------
--
-- 2DShadows
-- Light.lua
--
-- Class to create light sources
--
-------------------------------------------------
local Log      = require("2dshadows.util.log")
local Vector2D = require("2dshadows.util.vector2d")

local _W    = math.floor( display.actualContentWidth + 0.5 )
local _H    = math.floor( display.actualContentHeight + 0.5 )
local _W2   = _W * 0.5
local _H2   = _H * 0.5
local _W4   = _W2 * 0.5
local _H4   = _H2 * 0.5

local Light = {}


-----------------------------------------------------------------------------
-- Light Constructor
--
-- size                 - the size of the light texture
-- color                - a table with three color values
-- intensity            - intensity (alpha) of the light texture
-- lenseflares          - number of flares, must be between 0 and 7
-- lenseflareIntensity  - alpha of the lense flare textures
-----------------------------------------------------------------------------
function Light:new(size, color, intensity, lenseflares, lenseflareIntensity)
   Log:p(0, "Light:new()" )
   local light = display.newGroup()

   light.size                    = size or 1                      -- size is the scale factor of the light texture
   light.intensity               = intensity or 0.75              -- intensity is the alpha value of the light texture
   light.intensityBck            = intensity or 0.75              -- backup of the original intensity value (neede for the flickering effect that changes intensity)
   light.shadowIntensity         = light.intensity                -- per default the shadow alpha == light alpha (can be changed separately with SetShadowIntensity)
   light.shadowLength            = 1.0                            -- factor of the projected shadow polygon, 1 means to doueble the distance from light to vertex (default)
   light.isThrowingShadows       = true                           -- you can set the shadow calculus off

   light.color                   = color or {1,1,1}               -- the color of the light
   light.texturefilename         = "2dshadows/img/light04.png"    -- the path to the light texture
   light.texturesize             = {366,366}                      -- the width and height of the texture
   light.imageLight              = display.newImageRect( light, light.texturefilename, light.texturesize[1], light.texturesize[2] )
   light.imageLight.blendMode    = "add"
   light.imageLight.alpha        = light.intensity
   light.imageLight:setFillColor( light.color[1], light.color[2], light.color[3])
   light.imageLight:scale( size or 1, size or 1 )

   light.x                       = px or 0
   light.y                       = py or 0

   light.markX                   = 0               -- this is needed for dragging the lights
   light.markY                   = 0
   light.type                    = "light"
   light.isDraggable             = true            -- set to true to make light draggable
   light.hasMoved                = false           -- neded to check if light has been dragged or only tapped
   light.isTouched               = false           -- if the light is currently being touched

   light.timers                  = {}              -- table of all timers
   light.transitions             = {}              -- table of all transitions

   light.debug                   = false
   light.debugText               = display.newText( {parent=light, text="Debug", x=0, y=0, width=128, font=native.systemFont, fontSize=10} )
   light.debugText:setFillColor( 0,0,0 )
   light.debugText.isVisible     = false

   light.hasLensflares           = false
   if lenseflares == nil then lenseflares = 0 end
   if lenseflares > 0 then light.hasLensflares = true end
   light.lensFlareCount          = lenseflares or 4
   if light.lensFlareCount > 7 then light.lensFlareCount = 7 end
   light.lensFlareIntensity      = lenseflareIntensity or 0.8
   light.lensFlareImages         = {}

   -- create lensflare images
   light.lensFlareImages[1]      = display.newImageRect( light, "2dshadows/img/lens1.jpg", 128, 128 )
   light.lensFlareImages[1]:setFillColor(0,0,1)
   light.lensFlareImages[2]      = display.newImageRect( light, "2dshadows/img/lens2.jpg", 128*0.5, 128*0.5 )
   light.lensFlareImages[2]:setFillColor(0,0,1)
   light.lensFlareImages[3]      = display.newImageRect( light, "2dshadows/img/lens1.jpg", 128*0.25, 128*0.25 )
   light.lensFlareImages[3]:setFillColor(0,0,0)
   light.lensFlareImages[4]      = display.newImageRect( light, "2dshadows/img/lens3-2.jpg", 256, 256 )
   light.lensFlareImages[4]:setFillColor(0,1,0)
   light.lensFlareImages[5]      = display.newImageRect( light, "2dshadows/img/lens1.jpg", 128*0.5, 128*0.5 )
   light.lensFlareImages[5]:setFillColor(1,0,0)
   light.lensFlareImages[6]      = display.newImageRect( light, "2dshadows/img/lens4.jpg", 128*0.25, 128*0.25 )
   light.lensFlareImages[6]:setFillColor(1,1,0)
   light.lensFlareImages[7]      = display.newImageRect( light, "2dshadows/img/lens1.jpg", 128*0.25, 128*0.25 )
   light.lensFlareImages[7]:setFillColor(0,1,0)

   for i=1,7 do
      light.lensFlareImages[i].blendMode  = "add"
      light.lensFlareImages[i].isVisible  = false
      light.lensFlareImages[i].alpha      = light.lensFlareIntensity
      light.lensFlareImages[i]:toFront( )
   end

   -- flicker effect
   light.isFlickering            = false
   light.flickerType             = "damaged"       -- flicker types: "damaged","torch"          
   light.flickerMin              = 0.5             -- the minimum alpha value wehn flickering

   -- on/off 
   light.isOn                    = true            -- set light on or off yb settings this value to true or false



   -----------------------------------------------------------------------------
   -- light:Move(pX,pY)
   -----------------------------------------------------------------------------
   function light:Move(pX, pY)
      self.x = pX
      self.y = pY
   end


   -----------------------------------------------------------------------------
   -- light:Pause()
   -----------------------------------------------------------------------------
   function light:Pause()
      Log:p(1,"light:Pause()")
      
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
   -- light:Resume()
   -----------------------------------------------------------------------------
   function light:Resume()
      Log:p(1,"light:Resume()")

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
   -- light:Remove()
   -----------------------------------------------------------------------------
   function light:Remove()
      Log:p(1,"light:Remove()")

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
   -- light:SetFlicker( flickerOnOff, flickerType, flickerMin )
   -- flickerOnOff   - true/false to set flickering on/off 
   -- flickerType    - set the type of flicker, string values: "damaged","torch"
   -- flickerMin     - set this to set the minimum flicker value. 
   --                  the lower the value the more intense the flickering
   --                  use values between 0 and 1 (alpha value of light texture)
   -----------------------------------------------------------------------------
   function light:SetFlicker( flickerOnOff, flickerType, flickerMin )
      self.isFlickering = flickerOnOff

      -- reset intensity to original value
      if self.isFlickering == false then
         self:SetIntensity( self.intensityBck )
      end

      if flickerType ~= nil then self.flickerType  = string.lower( flickerType ) end
      if flickerMin ~= nil then self.flickerMin = flickerMin end
   end


   -----------------------------------------------------------------------------
   -- light:SetDraggable( newValue )
   -- set true or false if the light should be draggable or not
   -----------------------------------------------------------------------------
   function light:SetDraggable( newValue )
      self.isDraggable = newValue
   end


   -----------------------------------------------------------------------------
   -- light:SetIntensity( newValue )
   -- is the opacity of the light source texture AND the light cookie, use value between 0 and 1
   -- default is 0.75
   -----------------------------------------------------------------------------
   function light:SetIntensity( newValue )
      self.intensity = newValue
      self.intensityBck = newValue
   end


   -----------------------------------------------------------------------------
   -- light:SetOff()
   -- sets the light off
   -----------------------------------------------------------------------------
   function light:SetOff()
      self.isOn = false
      self.isVisible = false
   end


   -----------------------------------------------------------------------------
   -- light:SetOn()
   -- sets the light on
   -----------------------------------------------------------------------------
   function light:SetOn()
      self.isOn = true
      self.isVisible = true
   end

   -----------------------------------------------------------------------------
   -- light:SetShadowIntensity( newValue )
   -- is the opacity of the shadow, use value between 0 and 1
   -- default is the same value as light intensity
   -----------------------------------------------------------------------------
   function light:SetShadowIntensity( newValue )
      self.shadowIntensity = newValue
   end


   -----------------------------------------------------------------------------
   -- light:SetShadowLength( newValue )
   -- set the length of the value (comparable to the height of light source)
   -- nawValue  - the factor of the shadow length, 1 means the shadow is exactly
   --             double as long as the distance from light to vertices (default setting)
   -----------------------------------------------------------------------------
   function light:SetShadowLength( newValue )
      self.shadowLength = newValue
   end


   -----------------------------------------------------------------------------
   -- light:SetShadowThrowing( newValue )
   -- set shadow throwing on or off
   -- nawValue  - use true or false to set shadow throwing on or off
   -----------------------------------------------------------------------------
   function light:SetShadowThrowing( newValue )
      self.isThrowingShadows = newValue
   end


   -----------------------------------------------------------------------------
   -- light:SetSize( newSize )
   -- sets the size of the light texture (scale factor)
   -- newSize - the new size factors
   -----------------------------------------------------------------------------
   function light:SetSize( newSize )
      self.size               = newSize
      self.imageLight.xScale  = self.size
      self.imageLight.yScale  = self.size
   end


   -----------------------------------------------------------------------------
   -- light:SetTexture( filename, w, h )
   -- sets a new texture (light cookie) for the light
   -- filename  - the path to the texture
   -- w,h       - dimensions of the texture
   -----------------------------------------------------------------------------
   function light:SetTexture( filename, w, h )
      Log:p(1, "light:SetTexture:", filename, w, h)

      -- remove old texture
      self.imageLight:removeSelf( )

      -- load new one
      self.texturefilename       = filename
      self.texturesize[1]        = w
      self.texturesize[2]        = h
      self.imageLight            = display.newImageRect( self, self.texturefilename, self.texturesize[1], self.texturesize[2] )
      self.imageLight.xScale     = self.size
      self.imageLight.yScale     = self.size
      self.imageLight.blendMode  = "add"
      self.imageLight.alpha      = self.intensity
      self.imageLight:setFillColor( self.color[1], self.color[2], self.color[3])
   end


   -----------------------------------------------------------------------------
   -- light:SetTextureIntensity( newValue )
   -- sets the intensity of the light texture (not the light cookie), use value between 0 and 1
   -- this way you can create light cookies that do not affect the shadow casters
   -----------------------------------------------------------------------------
   function light:SetTextureIntensity( newValue )
      self.imageLight.alpha = newValue
   end


   -----------------------------------------------------------------------------
   -- light:touch(event)
   -----------------------------------------------------------------------------
   function light:touch(event)
      Log:p(0, "light:touch phase:" .. event.phase)

      -- since the textures of the light can be really big I set up a fixed box size
      -- which is for touching/dragging purposes only
      local lightSize = 50

      if event.phase == "began" then
         -- check if touch is within lightSize

         -- get global position
         local gx,gy = self:localToContent( 0, 0 )

         -- do a simple box check
         if event.x > gx + lightSize or event.x < gx - lightSize then return end
         if event.y > gy + lightSize or event.y < gy - lightSize then return end

         -- begin focus
         display.getCurrentStage():setFocus( self, event.id )

         self.isFocus   = true
         self.isTouched = true

         self.markX = self.x
         self.markY = self.y

      elseif self.isFocus then

         if event.phase == "moved" then
            self.hasMoved = true

            -- drag touch light
            if self.isDraggable == true then
               self.x = event.x - event.xStart + self.markX
               self.y = event.y - event.yStart + self.markY
            end

         elseif event.phase == "ended" or event.phase == "cancelled" then
            
            -- check if has moved or only tapped
            if self.hasMoved == false then
            end

            -- end focus
            display.getCurrentStage():setFocus( self, nil )
            self.isFocus   = false
            self.hasMoved  = false
            self.isTouched = false
         end

      end

      return true
   end

   -- create an event listener for touching
   light:addEventListener("touch", object)



   -----------------------------------------------------------------------------
   -- light:UpdateLensFlares()
   -----------------------------------------------------------------------------
   function light:UpdateLensFlares()
      Log:p(0,"light:UpdateLensFlares()")

      local vl = Vector2D:new( self.x, self.y )
      local vc = Vector2D:new( 0, 0 )
      local vv = Vector2D:Sub( vc, vl )
      local length = vv:magnitude()
       vv:normalize()

      if self.lensFlareCount >= 1 then
         local lf = length
         self.lensFlareImages[1].isVisible = true
         self.lensFlareImages[1].x = vc.x - vv.x * lf
         self.lensFlareImages[1].y = vc.y - vv.y * lf
      end

      if self.lensFlareCount >= 2 then
         local lf = length / 2.0
         self.lensFlareImages[2].isVisible = true
         self.lensFlareImages[2].x = vc.x - vv.x * lf
         self.lensFlareImages[2].y = vc.y - vv.y * lf
      end

      if self.lensFlareCount >= 3 then
         local lf = length / 3.0
         self.lensFlareImages[3].isVisible = true
         self.lensFlareImages[3].x = vc.x - vv.x * lf
         self.lensFlareImages[3].y = vc.y - vv.y * lf
      end

      if self.lensFlareCount >= 4 then
         local lf = length / 8.0
         self.lensFlareImages[4].isVisible = true
         self.lensFlareImages[4].x = vc.x - vv.x * lf
         self.lensFlareImages[4].y = vc.y - vv.y * lf
      end

      if self.lensFlareCount >= 5 then
         local lf = -(length / 2.0)
         self.lensFlareImages[5].isVisible = true
         self.lensFlareImages[5].x = vc.x - vv.x * lf
         self.lensFlareImages[5].y = vc.y - vv.y * lf
      end

      if self.lensFlareCount >= 6 then
         local lf = -(length / 4.0)
         self.lensFlareImages[6].isVisible = true
         self.lensFlareImages[6].x = vc.x - vv.x * lf
         self.lensFlareImages[6].y = vc.y - vv.y * lf
      end

      if self.lensFlareCount >= 7 then
         local lf = -(length / 5.5)
         self.lensFlareImages[7].isVisible = true
         self.lensFlareImages[7].x = vc.x - vv.x * lf
         self.lensFlareImages[7].y = vc.y - vv.y * lf
      end
   end


   -----------------------------------------------------------------------------
   -- light:UpdateFlicker()
   -----------------------------------------------------------------------------
   function light:UpdateFlicker()
      if self.isFlickering == false then return end
      Log:p(0,"light:UpdateFlicker()")

      -- FLICKER TYPE "DAMAGED"
      -- a very random flicker type like a damaged flash light
      if self.flickerType == "damaged" then

         local randomNumber = math.random( 10 )

         -- big flickers
         if randomNumber > 7 and randomNumber <= 10 then

            local flicker1 = function( obj )
               Log:p(0,"light:UpdateFlicker() flicker1")
               transition.to( self.imageLight, {time=750, alpha=self.intensity, transition=easing.inOutBounce})
            end

            transition.to( self.imageLight, {time=350, alpha=self.flickerMin, transition=easing.inOutBounce, onComplete=flicker1})
         
         -- small flickers
         elseif randomNumber > 3 and randomNumber < 7 then
            local flicker2 = function( obj )
               Log:p(0,"light:UpdateFlicker() flicker2")
               transition.to( self.imageLight, {time=50, alpha=self.intensity, transition=easing.inOutBounce})
            end

            transition.to( self.imageLight, {time=70, alpha=self.flickerMin*0.5, transition=easing.inOutBounce, onComplete=flicker2})

         end

      -- FLICKER TYPE "TORCH" 
      -- a more regular flickering like a torch
      elseif self.flickerType == "torch" then
         local randomTime = math.random( 200,225 )
         local flicker3 = function( obj )
            Log:p(0,"light:UpdateFlicker() flicker3")
            transition.to( self.imageLight, {time=randomTime, alpha=self.intensity, transition=easing.inOutBounce})
         end

         transition.to( self.imageLight, {time=randomTime, alpha=self.flickerMin, transition=easing.inOutBounce, onComplete=flicker3})
      end
   end


    -----------------------------------------------------------------------------
    -- light:timer( event )
    -----------------------------------------------------------------------------
    function light:timer( event )
      self:UpdateLensFlares()

      if self.debug then self:UpdateDebug() end
    end

    local tm = timer.performWithDelay( 1, light, 0 )
    table.insert( light.timers, tm )

    local tm2 = timer.performWithDelay( 500, function() light:UpdateFlicker() end, 0 )
    table.insert( light.timers, tm2 )

   return light
end

return Light