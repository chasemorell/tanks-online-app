
--[[
Copyright 2018 Chase Morell

Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), 
to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, 
and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, 
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, 
TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.]]--
--local facebook = require( "plugin.facebook.v4a" )

physics = require "physics"
perspective = require("perspective") -- Include the library
require "aiTank"
require "userTank"
local composer  = require( "composer" )
local widget = require "widget"
local gameNetwork = require( "gameNetwork" )

vungle = require "plugin.vungle"

system.activate( "multitouch" )
physics.start( )
physics.setGravity( 0, 0 )
display.setStatusBar( display.HiddenStatusBar )

appID = "5b0f53ad19829714e5acfcdb"
placementID1 = "DEFAULT-9126284"

highGraphics = false
dualJoystickMode = true

game = {} 
game.isMultiplayer = true

 function facebookListener( event )
 
    if ( "fbinit" == event.name ) then
 
        print( "Facebook initialized" )
 
        -- Initialization complete; call "facebook.publishInstall()"
        facebook.publishInstall()
 
    elseif ( "fbconnect" == event.name ) then
 
        if ( "session" == event.type ) then
            -- Handle login event and try to share the link again if needed
        elseif ( "dialog" == event.type ) then
            -- Handle dialog event
        end
    end
end
 
-- Set the "fbinit" listener to be triggered when initialization is complete
--facebook.init( facebookListener )

local function adListener( event )
 
    if ( event.type == "adInitialize" ) then  -- Successful initialization
        print( event.provider )
    end
end
 
-- Initialize the Vungle plugin
local initParams = appID .. "," .. placementID1 
vungle.init( "vungle", initParams, adListener )


--physics.setDrawMode( "hybrid" )

local function initiateGame(params) 
	--vungle.load(placementID1)

	camera = perspective.createView()
	camera:setMasterOffset(0, 0)
	camera.damping = 10

	 map = display.newGroup( )
	 bullets = display.newGroup( )
	 tanks = display.newGroup( )
	 ui = display.newGroup( )
	 lights = display.newGroup( )
	return map, bullets, tanks, ui,lights
end

function createUserBot(params) 
	game.hasStarted = false
	local tank = {}
	tank.bot = display.newRect( 20,20,100,50)
	tank.bot.alpha = 0
	
	tank.botSprite = display.newImage("PNG/tanks/tankBlue_outline.png")
	--tank.botSprite = display.newImage("PNG/Tanks/altTank.png")

	tank.barrel = display.newImage("PNG/tanks/barrelBlue_outline.png")
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

function spawnHealth(x,y)
	healthIndex = healthIndex+1
	local index = healthIndex
	--print("INDEX = "..healthIndex)
	healthDrops[index] = display.newImage("health.png")
	healthDrops[index].width = 40
	healthDrops[index].height = 40
	healthDrops[index].x = x
	healthDrops[index].y = y
	healthDrops[index].id = "health"
	healthDrops[index].index = index

	physics.addBody( healthDrops[index], "static" )

	healthDrops[index].isSensor = true

	camera:add(healthDrops[index],2)
end


function createMap(params)
   	bg = display.newImage("PNG/Environment/grass.png")
   	bg:scale(50,50)
	map:insert(bg)
	camera:add(bg,2,false)
	healthIndex = 0

	healthDrops = {}

   	ground = {}
    for x = 1,10 do 
    	ground[x] = {}
    	for y = 1,10 do
	   		ground[x][y] = display.newImage("grassy.png")
	   		ground[x][y].width = 500
	   		ground[x][y].height = 500
	   		ground[x][y].x = (x-1)*500
	   		ground[x][y].y = (y-1)*500

	   
	   		map:insert(ground[x][y])
	   		camera:add(ground[x][y],2)

	   	   -- spawnHealth(ground[x][y].x + (math.random(-1,1)*math.random(200,200)),ground[x][y].y + (math.random(-1,1)*math.random(200,200)) )

   		end
   	end



	

	
end

function isInBounds(x,y)
	if(x < 3000 and x > 0 and y > 0 and y < 3000)then return true end 
	return false
end


function createUI(params)

	leftRegion = display.newRect(display.contentWidth/2,0, 500, 500 )
	leftRegion.anchorX = 1
	leftRegion.anchorY = 0

	leftRegion.isVisible = false
	leftRegion.isHitTestable = true
--	leftRegion.alpha = .0001

	rightRegion = display.newRect(display.contentWidth/2 + 75,0, 500, 500 )
	rightRegion.anchorX = 0
	rightRegion.anchorY = 0
	rightRegion:setFillColor( .5,.5,0 )
	--rightRegion.alpha = .0001

	rightRegion.isVisible = false
	rightRegion.isHitTestable = true

	joystick = display.newCircle(display.screenOriginX + 100, 240, 20 )
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

	--BARREL JOYSTICK 
	if(dualJoystickMode)then
		barrelJoystick = display.newCircle(display.screenOriginX + display.actualContentWidth - 100, 240, 20 )
		barrelJoystick.restingX = barrelJoystick.x
		barrelJoystick.restingY = barrelJoystick.y
		physics.addBody( barrelJoystick, "kinesmatic",{radius = 1})
		barrelJoystick.isSensor = true

		barrelJoystickT = display.newCircle(barrelJoystick.restingX, barrelJoystick.restingY, 40)
		barrelJoystickT.alpha = .5
		physics.addBody( barrelJoystickT, "static")
		barrelJoystickT.isSensor = true

		barrelJoystickJoint = physics.newJoint( "rope", barrelJoystick, barrelJoystickT)
		barrelJoystickJoint.maxLength = 50

		barrelTouchJoint = physics.newJoint( "touch", barrelJoystick, barrelJoystick.x,barrelJoystick.y )
		barrelTouchJoint.dampingRatio = .7
	end



	if(not dualJoystickMode)then
		 shootButton = widget.newButton(
	    {
	        width = 70,
	        height = 70,
	        defaultFile = "shootButton.png",
	        overFile = "shootButtonDown.png",
	       -- label = "button",
	        x = display.actualContentWidth - 170,
	        y = joystick.restingY,
	        onEvent = touchShoot,

	    })
	end

	--shootButton = display.newImage("shootButton.png")--display.newCircle(400, joystick.restingY, 30)
	--shootButton.width = 70
	--shootButton.height = 70
	--shootButton.y = joystick.restingY
	--shootButton.x = display.actualContentWidth - 170

	pauseButton = display.newImage("pauseButton.png")
	pauseButton.width = 40
	pauseButton.height = 40
	pauseButton.x = display.screenOriginX + display.actualContentWidth - 50
	pauseButton.y = 50
	pauseButton.isActive = true
	--shootButton:setFillColor( 1,0,0)

	healthText = display.newText( "Health: 100", display.actualContentWidth - 100,50,100,50)
	healthText.anchorX = 0
	healthText.x = display.screenOriginX + healthText.width/2
	healthText.amount = 100
	healthText.alpha = 0

	ammoText = display.newText( "Ammo: 3", display.actualContentWidth - 100,50,100,50)
	ammoText.anchorX = 0
	ammoText.x = display.screenOriginX + ammoText.width/2
	ammoText.amount = 3

	healthIndicatorBg = display.newRoundedRect( display.contentWidth/2,30, 300,15, 5 )
	healthIndicatorBg.alpha = .5

	amountHealthIndicator = display.newRoundedRect( display.contentWidth/2,30, 298,12, 5)
	amountHealthIndicator.alpha = .8
	amountHealthIndicator:setFillColor(0,1,0 )
	amountHealthIndicator.anchorX = 0

	ui:insert(joystickT)
	ui:insert(joystick)

	if(not dualJoystickMode)then
		ui:insert(shootButton)
		--shootButton:addEventListener( "touch", touchShoot )

	end

	ui:insert(healthText)
	ui:insert(pauseButton)
	ui:insert(healthIndicatorBg)
	ui:insert(amountHealthIndicator)
	--ui:insert(rightRegion)
	--ui:insert(leftRegion)

	if(dualJoystickMode)then
		ui:insert(barrelJoystickT)
		ui:insert(barrelJoystick)
	end

	Runtime:addEventListener( "touch", screenTouch )
	Runtime:addEventListener( "key", onKeyEvent )
	Runtime:addEventListener("enterFrame",enterFrame) 
	pauseButton:addEventListener( "touch", pauseTouch )

	rightRegion:addEventListener( "touch", rightRegionTouch )
	leftRegion:addEventListener( "touch", leftRegionTouch )

	return joystick, joystickT, shootButton, healthText,ammoText
end

function destroyUI()
	joystick:removeSelf()
	joystickT:removeSelf()

	if(dualJoystickMode)then
		barrelJoystick:removeSelf()
		barrelJoystickT:removeSelf()
		barrelJoystick = nil 
		barrelJoystickT = nil
	end

	healthText:removeSelf()
	ammoText:removeSelf()
	pauseButton:removeSelf()

	healthIndicatorBg:removeSelf()
	amountHealthIndicator:removeSelf()


	Runtime:removeEventListener( "touch", screenTouch )
	Runtime:removeEventListener( "key", onKeyEvent )
	if(not dualJoystickMode)then
		shootButton:removeSelf()
		shootButton:removeEventListener( "touch", touchShoot )
		shootButton = nil

	end

	Runtime:removeEventListener( "enterFrame", enterFrame )
	pauseButton:removeEventListener( "touch", pauseTouch )

	rightRegion:removeEventListener( "touch", rightRegionTouch )
	leftRegion:removeEventListener( "touch", leftRegionTouch )

	rightRegion:removeSelf()
	leftRegion:removeSelf()

	rightRegion = nil 
	leftRegion = nil 

	joystick = nil
	joystickT = nil
	
	healthText = nil
	ammoText = nil
	pauseButton = nil
end

function destroyMap()
	bg:removeSelf()
	bg = nil 

	wallSouth:removeSelf()
	wallNorth:removeSelf()
	wallEast:removeSelf()
	wallWest:removeSelf()

	for i = 1,#obstacles do 
		obstacles[i]:removeSelf()
		obstacleShadows[i]:removeSelf()

		obstacles[i] = nil
	end

	for i = 1,#trees do 
		trees[i]:removeSelf()
		shadowTrees[i]:removeSelf()
		trees[i] = nil
	end

	blueBase:removeSelf()
	blueBaseShadow:removeSelf()
	orangeBase:removeSelf()
	orangeBaseShadow:removeSelf()

	for x = 1, 10 do 
		for y = 1,10 do 
			ground[x][y]:removeSelf()
			ground[x][y] = nil

			
		end
	end

	for i = 1,healthIndex do 
		if(healthDrops[i])then
				healthDrops[i]:removeSelf()
				healthDrops[i] = nil
		end
	end

end

function screenTouch(e)
--	if(userTank and e.x < display.contentWidth/2)then userTank:setRotationAndVelocity(e) end
--	if(userTank and e.x > display.contentWidth/2 and dualJoystickMode)then userTank:setBarrelRotation(e) end
end

function rightRegionTouch(e)

			if(userTank and dualJoystickMode)then userTank:setBarrelRotation(e) end
		


end

function leftRegionTouch(e)
		if(userTank and e.x < display.contentWidth/2)then userTank:setRotationAndVelocity(e) end

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

function openPauseOverlay()

	local function closePauseOverlay(initialYOffset, speed)
		transition.to( Pbg, {alpha = 0} )
		transition.to( bgPanel, {alpha = 0,y = bgPanel.y + initialYOffset, transition = easing.outBack, time = speed} )
		transition.to( exitButton, {alpha = 0, y = exitButton.y + initialYOffset, transition = easing.outBack, time = speed} )
		transition.to( graphicsButton, {alpha = 0, y = graphicsButton.y + initialYOffset, transition = easing.outBack, time = speed} )
		transition.to( exitText, {alpha = 0, y = exitText.y + initialYOffset, transition = easing.outBack, time = speed} )
		transition.to( graphicsText, {alpha = 0, y = graphicsText.y + initialYOffset, transition = easing.outBack, time = speed} )
		transition.to( logo, {alpha = 0, y = logo.y + initialYOffset, transition = easing.outBack, time = speed} )
		transition.to( backButton, {alpha = 0, y = backButton.y + initialYOffset, transition = easing.outBack, time = speed} )
		transition.to( backText, {alpha = 0, y = backText.y + initialYOffset, transition = easing.outBack, time = speed} )

		timer.performWithDelay( speed, function()

			if(Pbg)then
				Pbg:removeSelf()
				bgPanel:removeSelf()
				exitButton:removeSelf()
				graphicsButton:removeSelf()
				exitText:removeSelf()
				graphicsText:removeSelf()
				logo:removeSelf()

				Pbg = nil 
				bgPanel = nil 
				exitButton = nil 
				graphicsButton = nil 
				exitText = nil 
				graphicsText = nil 
				logo = nil 
			end

			if(pauseButton)then
				pauseButton.isActive = true
			end
			physics.start( )

		end )	
	end

	Pbg = display.newRect(0,0,10000,10000)
	Pbg:setFillColor( 0,0,0 )
	Pbg.alpha = 0

	physics.pause()

	local initialYOffset = 100
	local speed = 400

	bgPanel = display.newRoundedRect( display.contentWidth/2, 150+initialYOffset, 200, 250, 20 )
	bgPanel.alpha = 0

	logo = display.newImage("logo.png")
	logo.x = display.contentWidth/2
	logo.y = 75 + initialYOffset
	logo.width = 200
	logo.height = 200
	logo.alpha = 0

	graphicsButton = display.newRoundedRect( display.contentWidth/2, 190 + initialYOffset, 180, 40, 10 )
	graphicsButton:setFillColor( .2,.2,.2 )

	exitButton = display.newRoundedRect( display.contentWidth/2, 240 + initialYOffset, 180, 40, 10 )
	exitButton:setFillColor( .5,.5,.5 )

	backButton = display.newRoundedRect( display.contentWidth/2, 140 + initialYOffset, 180, 40, 10 )
	backButton:setFillColor( .7,.1,.1 )

	backText = display.newText( {
		text = "Back" ,
		x =  display.contentWidth/2,
		y =  140 + initialYOffset , 
		width = 170, 
		height = 20,  
		fontSize = 15 ,
		align = "center"} )

	graphicsText = display.newText( {
		text = "Graphics Quality: High" ,
		x =  display.contentWidth/2,
		y =  190 + initialYOffset , 
		width = 170, 
		height = 20,  
		fontSize = 15 ,
		align = "center"} )

	exitText = display.newText( {
		text = "Exit Arena" ,
		x =  display.contentWidth/2,
		y =  240 + initialYOffset , 
		width = 170, 
		height = 20,  
		fontSize = 15 ,
		align = "center"} )

	--display.newText( [parent,], text, x, y [, width, height], font [, fontSize] )

	local quality
	if(highGraphics)then
		 quality = "High"
	else
		 quality = "Low"
	end
	graphicsText.text = "Graphics Quality: " .. quality

	exitButton.alpha = 0 
	exitText.alpha = 0 
	graphicsText.alpha = 0 
	graphicsButton.alpha = 0
	backText.alpha = 0
	backButton.alpha = 0

	transition.to( Pbg, {alpha = .5} )
	transition.to( bgPanel, {alpha = 1,y = 150, transition = easing.outBack, time = speed} )
	transition.to( exitButton, {alpha = 1, y = exitButton.y - initialYOffset, transition = easing.outBack, time = speed} )
	transition.to( graphicsButton, {alpha = 1, y = graphicsButton.y - initialYOffset, transition = easing.outBack, time = speed} )
	transition.to( exitText, {alpha = 1, y = exitText.y - initialYOffset, transition = easing.outBack, time = speed} )
	transition.to( graphicsText, {alpha = 1, y = graphicsText.y - initialYOffset, transition = easing.outBack, time = speed} )
	transition.to( logo, {alpha = 1, y = logo.y - initialYOffset, transition = easing.outBack, time = speed} )
	transition.to( backButton, {alpha = 1, y = backButton.y - initialYOffset, transition = easing.outBack, time = speed} )
	transition.to( backText, {alpha = 1, y = backText.y - initialYOffset, transition = easing.outBack, time = speed} )

	local function graphicsToggle(e)

		if(e.phase == "began")then
			--transition.to( graphicsButton, {width = 180,height = 40, transition = easing.outBack} )
			highGraphics = not highGraphics
			if(highGraphics)then
		 		quality = "High"
			else
		 		quality = "Low"
			end
			graphicsText.text = "Graphics Quality: " .. quality
		end
	end

	local function exitButtonTouch(e)
		if(e.phase == "ended")then

			if(game.isMultiplayer)then
				cleanupMultiplayer()
			end

			exitButton:removeEventListener( "touch", exitButtonTouch )

			closePauseOverlay(initialYOffset, speed)
			timer.performWithDelay( speed + 100,function()

				destroyPracticeArena(true)
		 	end)
		end
	end

	local function backButtonTouch(e)

		if(e.phase == "ended")then
			backButton:removeEventListener( "touch", backButtonTouch )
			closePauseOverlay(initialYOffset, speed)
			
		end
	end


	graphicsButton:addEventListener("touch",graphicsToggle)
	exitButton:addEventListener( "touch", exitButtonTouch )
	backButton:addEventListener( "touch", backButtonTouch )

end



function pauseTouch(e)
	if(e.phase == "ended" and pauseButton.isActive == true)then
		pauseButton.isActive = false
		openPauseOverlay()
--[[
		destroyPracticeArena(false)
		overlay = display.newImage("PNG/Environment/grass.png")
   		overlay:scale(50,50)
	--	vungle.show({
	--		placementId = placementID1,
	--	})
		timer.performWithDelay( 3000,function()
			overlay:removeSelf()
			composer.gotoScene( "menu"  )

		end )]]--
	end

end

function onKeyEvent(e)
	if(e.keyName == "w" and userTank)then userTank.barrel.rotation = 0 end
	if(e.keyName == "s" and userTank)then userTank.barrel.rotation = 180 end
	if(e.keyName == "a" and userTank)then userTank.barrel.rotation = -90 end
	if(e.keyName == "d" and userTank)then userTank.barrel.rotation = 90 end

	if ( e.keyName == "space" ) then
		if(userTank)then userTank:shootBullet() end
	end 

	if ( e.keyName == "s" ) then
		--destroyPracticeArena(true)

		--anotherTank:stop()
	end 
end

function midPoint(aX,aY,bX,bY)
	return ((aX+bX)/2),((aY+bY)/2)
end

function distance(aX,aY,bX,bY)
	if(aX and aY and bX and bY)then
		return math.sqrt(  ((aX-bX)*(aX-bX)) + ((aY-bY)*(aY-bY))   )
	else
		return 0
	end 
end


function enterPracticeArena()
	gameOn = true
	initiateGame({})
	createUI({})
	createMap({})


	userTank = newUserTank({})--createUserBot({})

	enemyTank = newTank({})
	enemyTank:startStandardBehavior()

	enemyTank2 = newTank({})
	enemyTank2:startStandardBehavior()

	enemyTanks = {}
	for i = 1, 10 do 
		enemyTanks[i] = newTank({})
		enemyTanks[i]:startStandardBehavior()
	end

	        createObstacles()

end


    function createObstacles()
        --client:raiseEvent(2, {state = "initGame", player1x = 700, player1y = 300, player2x = 1500, player2y = 300},{ receivers = LoadBalancingConstants.ReceiverGroup.All }  )

        obstacles = {}
        obstacleShadows = {}
        trees = {}
        shadowTrees = {}

        local radius = 10

        --Green Side
        obstacles[1] = display.newRoundedRect( 700,240, 100,20, radius)
        obstacles[2] = display.newRoundedRect( 700,360, 100,20, radius)
        obstacles[3] = display.newRoundedRect( 740,300, 20,130, radius)

        obstacles[4] = display.newRoundedRect( 520,110, 20,250, radius)
        obstacles[20] = display.newRoundedRect( 520,490, 20,250, radius)


        obstacles[5] = display.newRoundedRect( 710,540, 400,20, radius)
        obstacles[6] = display.newRoundedRect( 710,60, 400,20, radius)

        --Orange Side
        local orangeDistance = 800
        local orangeTreeMove = 300
        local horizontalObMove = 460*2
        local startingSquareAjustment = -(220*2)
        obstacles[7] = display.newRoundedRect( 700 + orangeDistance + horizontalObMove + startingSquareAjustment+80,240, 100,20, radius)
        obstacles[8] = display.newRoundedRect( 700 + orangeDistance+horizontalObMove + startingSquareAjustment+80,360, 100,20, radius)
        obstacles[9] = display.newRoundedRect( 740+ orangeDistance+horizontalObMove + startingSquareAjustment,300, 20,130, radius)


        obstacles[10] = display.newRoundedRect( 520+ orangeDistance + horizontalObMove,110, 20,250, radius)
        obstacles[21] = display.newRoundedRect( 520 + orangeDistance + horizontalObMove,490, 20,250, radius)

        obstacles[11] = display.newRoundedRect( 710+ orangeDistance+ horizontalObMove - 380,540, 400,20, radius)
        obstacles[12] = display.newRoundedRect( 710+ orangeDistance+ horizontalObMove - 380,60, 400,20, radius)

        obstacles[13] = display.newRoundedRect( 1382,300, 250,20, radius)
        obstacles[14] = display.newRoundedRect( 1382,100, 20,200, radius)
        obstacles[15] = display.newRoundedRect( 1382,500, 20,200, radius)

        obstacles[16] = display.newRoundedRect( 1619,37, 100,20, radius)
        obstacles[17] = display.newRoundedRect( 1619,589, 100,20, radius)

        obstacles[18] = display.newRoundedRect( 1123,37, 100,20, radius)
        obstacles[19] = display.newRoundedRect( 1123,589, 100,20, radius)


        for i = 1,#obstacles do 
            obstacleShadows[i] = display.newRoundedRect( obstacles[i].x, obstacles[i].y + 5,obstacles[i].width,obstacles[i].height,10)

            if(obstacleShadows[i].height> obstacleShadows[i].width)then
                obstacleShadows[i].height = obstacleShadows[i].height - 20
            end

            camera:add(obstacleShadows[i],2,false)
            obstacleShadows[i]:setFillColor( 0,0,0 )
            obstacleShadows[i].alpha = .15
        end


        for i = 1,#obstacles do
            obstacles[i]:setFillColor( 220/255,220/255,220/255 )
            physics.addBody( obstacles[i], "static" )
            camera:add(obstacles[i],2,false)
        end

        --Blue Side
        trees[1] = display.newImage("PNG/Environment/treeLarge.png")
        trees[1].x = 770
        trees[1].y = 280
     
        trees[2] = display.newImage("PNG/Environment/treeLarge.png")
        trees[2].x = 770
        trees[2].y = 320
     
        trees[3] = display.newImage("PNG/Environment/treeLarge.png")
        trees[3].x = 820
        trees[3].y = 300

        trees[4] = display.newImage("PNG/Environment/treeLarge.png")
        trees[4].x = 820
        trees[4].y = 250

        trees[5] = display.newImage("PNG/Environment/treeLarge.png")
        trees[5].x = 810
        trees[5].y = 350

        trees[6] = display.newImage("PNG/Environment/treeLarge.png")
        trees[6].x = 850
        trees[6].y = 100

        trees[7] = display.newImage("PNG/Environment/treeLarge.png")
        trees[7].x = 900
        trees[7].y = 150

        trees[8] = display.newImage("PNG/Environment/treeLarge.png")
        trees[8].x = 850
        trees[8].y = 180

        trees[9] = display.newImage("PNG/Environment/treeLarge.png")
        trees[9].x = 850
        trees[9].y = 500

        trees[10] = display.newImage("PNG/Environment/treeLarge.png")
        trees[10].x = 900
        trees[10].y = 450

        trees[11] = display.newImage("PNG/Environment/treeLarge.png")
        trees[11].x = 850
        trees[11].y = 400

        blueBase = display.newImage("PNG/Environment/blueBase.png")
        blueBase.width = 250
        blueBase.height = 250
        blueBase.x = 980
        blueBase.y = 300

         blueBaseShadow = display.newImage("PNG/Environment/baseShadow.png")
        blueBaseShadow.width = 250
        blueBaseShadow.height = 250
        blueBaseShadow.x = 980 
        blueBaseShadow.y = 300 + 10
        blueBaseShadow.alpha = .3


        --Orange Side
        trees[12] = display.newImage("PNG/Environment/treeLarge.png")
        trees[12].x = 770 + orangeDistance + orangeTreeMove + 50
        trees[12].y = 280
     
        trees[13] = display.newImage("PNG/Environment/treeLarge.png")
        trees[13].x = 770 + orangeDistance + orangeTreeMove + 50
        trees[13].y = 320
     
        trees[14] = display.newImage("PNG/Environment/treeLarge.png")
        trees[14].x = 820 + orangeDistance + orangeTreeMove + 50
        trees[14].y = 300

        trees[15] = display.newImage("PNG/Environment/treeLarge.png")
        trees[15].x = 820 + orangeDistance + orangeTreeMove + 50
        trees[15].y = 250

        trees[16] = display.newImage("PNG/Environment/treeLarge.png")
        trees[16].x = 810 + orangeDistance + orangeTreeMove + 50
        trees[16].y = 350

        trees[17] = display.newImage("PNG/Environment/treeLarge.png")
        trees[17].x = 850 + orangeDistance + orangeTreeMove - 50
        trees[17].y = 100

        trees[18] = display.newImage("PNG/Environment/treeLarge.png")
        trees[18].x = 900 + orangeDistance + orangeTreeMove - 150
        trees[18].y = 150

        trees[19] = display.newImage("PNG/Environment/treeLarge.png")
        trees[19].x = 850 + orangeDistance + orangeTreeMove - 50
        trees[19].y = 180 

        trees[20] = display.newImage("PNG/Environment/treeLarge.png")
        trees[20].x = 850 + orangeDistance + orangeTreeMove - 50
        trees[20].y = 500

        trees[21] = display.newImage("PNG/Environment/treeLarge.png")
        trees[21].x = 900 + orangeDistance + orangeTreeMove - 150
        trees[21].y = 450

        trees[22] = display.newImage("PNG/Environment/treeLarge.png")
        trees[22].x = 850 + orangeDistance + orangeTreeMove -50
        trees[22].y = 400

        orangeBase = display.newImage("PNG/Environment/orangeBase.png")
        orangeBase.width = 250
        orangeBase.height = 250
        orangeBase.x = 980 + orangeDistance
        orangeBase.y = 300
        orangeBase.rotation = 90

        orangeBaseShadow = display.newImage("PNG/Environment/baseShadow.png")
        orangeBaseShadow.width = 250
        orangeBaseShadow.height = 250
        orangeBaseShadow.x = 980 + orangeDistance
        orangeBaseShadow.y = 300 + 10
        orangeBaseShadow.rotation = 90
        orangeBaseShadow.alpha = .3


        camera:add(blueBaseShadow,2)
        camera:add(blueBase,2)
        physics.addBody( blueBase, "static" )

        camera:add(orangeBaseShadow,2)

        camera:add(orangeBase,2)
        physics.addBody( orangeBase, "static" )
      
       -- 98, 107
        --treesp
        for i = 1,#trees do 
            trees[i].width = 98*.7
            trees[i].height = 107*.7
            trees[i].rotation = math.random(0,360)
            camera:add(trees[i],1)

            shadowTrees[i] = display.newImage("PNG/Environment/treeLargeShadow.png")
            shadowTrees[i].x = trees[i].x
            shadowTrees[i].y = trees[i].y + 10
            shadowTrees[i].width = trees[i].width 
            shadowTrees[i].height = trees[i].height 
            shadowTrees[i].rotation = trees[i].rotation

            shadowTrees[i].alpha = .3
            camera:add(shadowTrees[i],2)

        end

        spawnHealth(562,109)
        spawnHealth(556,503)
        spawnHealth(2203,500)
        spawnHealth(2198,96)

        wallNorth = display.newRect( 400,-100, 4000, 5 )
    wallNorth.alpha = .5
    physics.addBody( wallNorth, "static" )

    wallSouth = display.newRect( 400,700, 4000, 5 )
    wallSouth.alpha = .5
    physics.addBody( wallSouth, "static" )

    wallEast = display.newRect( 400,0, 5, 4000 )
    wallEast.alpha = .5
    physics.addBody( wallEast, "static" )

    wallWest = display.newRect( 2340,0, 5, 4000 )
    wallWest.alpha = .5
    physics.addBody( wallWest, "static" )

    local color = {1,0,0}

    wallNorth:setFillColor( 1,0,0 )
    wallSouth:setFillColor( 1,0,0 )
    wallEast:setFillColor( 1,0,0 )
    wallWest:setFillColor( 1,0,0 )

    --map:insert(wallNorth)
    --map:insert(wallSouth)
    --map:insert(wallEast)
    --map:insert(wallWest)

    camera:add(wallNorth,2,false)
    camera:add(wallSouth,2)
    camera:add(wallEast,2)
    camera:add(wallWest,2)



    end



function destroyPracticeArena(gotoMenu)
	gameOn =false
	destroyUI()
	destroyMap()

	if(game.isMultiplayer)then
		hideWaitingForPlayersNotification()
	end

	if(userTank and userTank.isDead == false)then
		userTank:destroy()
	end
	
	if(enemyTank)then
		enemyTank:destroy()
	end

	if(enemyTank2)then
		enemyTank2:destroy()
	end

	if(enemyTanks and game.isMultiplayer == false)then
		for i = 1,10 do 
			enemyTanks[i]:destroy()
			enemyTanks[i] = nil
		end
	end

	if(gotoMenu == true)then composer.gotoScene( "menu" ) end
end

function listener( event )
    if event.isShake and joystick then
        destroyPracticeArena(true)
    end
     
    return true
end
 
Runtime:addEventListener( "accelerometer", listener )

function print_r ( t ) 
    local print_r_cache={}
    local function sub_print_r(t,indent)
        if (print_r_cache[tostring(t)]) then
            print(indent.."*"..tostring(t))
        else
            print_r_cache[tostring(t)]=true
            if (type(t)=="table") then
                for pos,val in pairs(t) do
                    if (type(val)=="table") then
                        print(indent.."["..pos.."] => "..tostring(t).." {")
                        sub_print_r(val,indent..string.rep(" ",string.len(pos)+8))
                        print(indent..string.rep(" ",string.len(pos)+6).."}")
                    else
                        print(indent.."["..pos.."] => "..tostring(val))
                    end
                end
            else
                print(indent..tostring(t))
            end
        end
    end
    sub_print_r(t,"  ")
end



--composer.gotoScene( "aiGame" )
composer.gotoScene( "credits"  )



--[[timer.performWithDelay( 2000, function()
	destroyUI()
	destroyMap()
	userTank:destroy()
	enemyTank:destroy()
end )]]--




