
--[[
Copyright 2018 Chase Morell

Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), 
to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, 
and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, 
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, 
TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.]]--

physics = require "physics"
perspective = require("perspective") -- Include the library
require "aiTank"
require "userTank"

system.activate( "multitouch" )
physics.start( )
physics.setGravity( 0, 0 )
display.setStatusBar( display.HiddenStatusBar )

--physics.setDrawMode( "hybrid" )

function initiateGame(params) 
    camera = perspective.createView()
    camera:setMasterOffset(0, 0)
    camera.damping = 10

    map = display.newGroup( )
    bullets = display.newGroup( )
    tanks = display.newGroup( )
    ui = display.newGroup( )
    lights = display.newGroup( )
end

function createShadows()
    shadows = Shadows:new( 0, {0.2,0.2,0.2} )
    shadows:SetRealAttenuation( true )

    light1 = shadows:AddLight( 1, {0,0,1}, .5, 0 )
    --light1:SetDraggable( false )
    --light1.x = 1
    --light1.y = 1

    shadows.debugDraw = true

    userTank.shadowCaster = shadows:AddShadowCaster({-90,-90, -90,90, 90,90, 90,-90}, "PNG/Tanks/tankBlue_outline.png",180,180)--shadows:AddShadowCaster({-25,-25, -25,25, 25,25, 25,-25})

    --lights:insert(shadows)
    --lights:insert(light1)
    --lights:insert(userTank.shadowCaster)

    --camera:add(lights,1)
    --camera:add(shadows,1,false)
    --camera:add(light1,1,false)
    --camera:add(userTank.shadowCaster,1)
    --userTank.shadowCaster.alpha = 0
end

function createDemoShadows()
    local shadows = Shadows:new( 0, {0.2,0.2,0.2} )
    shadows.debugDraw = true
    -- CREATE A SHADOW CASTER OBJECT
    local crate1 = shadows:AddShadowCaster({-90,-90, -90,90, 90,90, 90,-90}, "img/crate.png",180,180)
    crate1.x,crate1.y = 150,0

    -- CREATE A SHADOW CASTER OBJECT
    --  local crate2 = shadows:AddShadowCaster({-45,-45, -45,45, 45,45, 45,-45}, "img/crate.png",90,90)
    --  crate2.x,crate2.y = -120, -200


    -- CREATE BLUE LIGHT
    local light1 = shadows:AddLight( 2, {0,0,1}, 0.3, 4 )
    light1.x, light1.y = -50, -350

    -- CREATE RED LIGHT
   -- local light2 = shadows:AddLight( 5, {1,0,0}, 0.5, 7 )
  --  light2.x, light2.y = 150, 350
    --camera:add(light1,1)
   -- camera:add(crate1,1)
end

function createUserBot(params) 
    local tank = {}
    tank.bot = display.newRect( 20,20,100,50)
    tank.bot.alpha = 0
    
    tank.botSprite = display.newImage("PNG/Tanks/tankBlue_outline.png")
    --tank.botSprite = display.newImage("PNG/Tanks/altTank.png")

    tank.barrel = display.newImage("PNG/Tanks/barrelBlue_outline.png")
    --tank.barrel = display.newImage("PNG/Tanks/altTankBarrel.png")

    tank.barrel.x = tank.bot.x
    tank.barrel.y = tank.bot.y
    tank.scale = .7

    --tank.shadowCaster.anchorY = 0
    --tank.shadowCaster.anchorX = 0
    
    --camera:add(tank.shadowCaster,1)
    --tank.shadowCaster:SetDraggable( false )

    --botSprite:scale(scale,scale)

    tank.botSprite.width = 50
    tank.botSprite.height = 50

    tank.barrel:scale(tank.scale,tank.scale)
    tank.barrel.anchorY = 1

    physics.addBody(tank.botSprite, "kinesmatic") --{shape = {-22,-45, -22,45, 22,45, 22,-45}}) 
    tank.botSprite.isFixedRotation = true

    tanks:insert(tank.bot)
    tanks:insert(tank.botSprite)
    tanks:insert(tank.barrel)

    tank.horizontalVelocity = 0 
    tank.verticalVelocity = 0

    tank.potentialHorizontalVelocity = 0 
    tank.potentialVerticalVelocity = 0

    tank.movementJoint = physics.newJoint("touch",tank.botSprite,tank.botSprite.x,tank.botSprite.y)

    camera:add(tank.botSprite, 1, true)
    camera:add(tank.barrel, 1, false)
    camera:track()

    tank.botSprite.id = "user"

    function onCollision( self, event )
        if(event.other.id == "enemy")then
            print("USER HIT BY ENEMY BULLET")
            
            print( event.target )        --the first object in the collision
            print( event.other )         --the second object in the collision
            print( event.selfElement )   --the element (number) of the first object which was hit in the collision
            print( event.otherElement )  --the element (number) of the second object which was hit in the collision
        end
       
    end 

    tank.botSprite.collision = onCollision 
    tank.botSprite:addEventListener( "collision" )

    return tank
end

function createMap(params)
    bg = display.newImage("PNG/Environment/grass.png")
    bg:scale(50,50)
    map:insert(bg)
    camera:add(bg,2,false)

    ground = {}
    for i = 1,10 do 
        print("MAKING GRASS")
        ground[i] = display.newImage("grassy.png")
        ground[i].width = 500
        ground[i].height = 500
        ground[i].x = (i-1)*500
        if(i < 5)then
            ground[i].y = 0
        else
            ground[i].y = 1
        end

        map:insert(ground[i])
        camera:add(ground[i],2)
    end

    wall = display.newRect( 300,300, 10,200 )
    physics.addBody( wall, "static" )

    map:insert(wall)
    wall.id = "map"
    camera:add(wall,2,false)
end

function createUI(params)
    joystick = display.newCircle(50, 240, 20 )
    joystick.restingX = joystick.x
    joystick.restingY = joystick.y
    physics.addBody( joystick, "kinesmatic",{radius = 1})
    joystick.isSensor = true

    joystickT = display.newCircle(joystick.restingX, joystick.restingY, 40)
    joystickT.alpha = .5
    physics.addBody( joystickT, "static")
    joystickT.isSensor = true

    joystickJoint = physics.newJoint( "rope", joystick, joystickT)
    joystickJoint.maxLength = 50

    touchJoint = physics.newJoint( "touch", joystick, joystick.x,joystick.y )
    touchJoint.dampingRatio = .7
    shootButton = display.newCircle(400, joystick.restingY, 30)
    shootButton:setFillColor( 1,0,0)

    healthText = display.newText( "Health: 100", display.actualContentWidth - 100,50,100,50)
    healthText.anchorX = 0
    healthText.x = display.screenOriginX + healthText.width/2
    healthText.amount = 100
    
    ammoText = display.newText( "Ammo: 3", display.actualContentWidth - 100,70,100,50)
    ammoText.anchorX = 0
    ammoText.x = display.screenOriginX + ammoText.width/2
    ammoText.amount = 3

    ui:insert(joystickT)
    ui:insert(joystick)
    ui:insert(shootButton)
    ui:insert(healthText)

    Runtime:addEventListener( "touch", screenTouch )
    Runtime:addEventListener( "key", onKeyEvent )
    shootButton:addEventListener( "touch", touchShoot )
    Runtime:addEventListener("enterFrame",enterFrame) 
end

function screenTouch(e)
    if(userTank)then userTank:setRotationAndVelocity(e) end
end

function touchShoot(e)
    if(e.phase == "began")then
        if(userTank) then userTank:shootBullet() end
    end
end

function enterFrame()
    --[[local speedScale = 7

    local sqCenterX, sqCenterY = userTank.botSprite:contentToLocal( 0, 0 )

    userTank.barrel.x = userTank.botSprite.x
    userTank.barrel.y = userTank.botSprite.y
    userTank.barrel.rotation = userTank.botSprite.rotation
    userTank.movementJoint:setTarget( userTank.botSprite.x - (userTank.horizontalVelocity/speedScale), userTank.botSprite.y - (userTank.verticalVelocity/speedScale)  )
    ]]--
end

function onKeyEvent(e)
    if ( e.keyName == "space" ) then
        if(userTank)then userTank:shootBullet() end
    end 

    if ( e.keyName == "s" ) then
        anotherTank:stop()
    end 
end

function midPoint(aX,aY,bX,bY)
    return ((aX+bX)/2),((aY+bY)/2)
end

function distance(aX,aY,bX,bY)
    return math.sqrt(  ((aX-bX)*(aX-bX)) + ((aY-bY)*(aY-bY))   )
end



initiateGame({})
createUI({})
createMap({})

userTank = newUserTank({})--createUserBot({})

enemyTank = newTank({})
enemyTank:startStandardBehavior()






