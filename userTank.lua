


function newUserTank(params) 

	local tank = {}

	tank.bot = display.newRect( 20,20,100,50)
	tank.bot.alpha = 0
	tank.bot.x = 500
	tank.bot.y = 500

	tank.botSprite = display.newImage("PNG/Tanks/tankBlue_outline.png")
	tank.botSprite.x = 500
	tank.botSprite.y = 500

	tank.barrel = display.newImage("PNG/Tanks/barrelBlue_outline.png")

	tank.barrel.x = tank.bot.x
	tank.barrel.y = tank.bot.y
	tank.scale = .7

	tank.shadow = display.newImage("shadow.png")
	tank.shadow.width = 50
	tank.shadow.height = 50
	tank.shadow.alpha = .4

	tank.botSprite.width = 50
	tank.botSprite.height = 50

	tank.barrel:scale(tank.scale,tank.scale)
	tank.barrel.anchorY = 1

	physics.addBody(tank.botSprite, "kinesmatic") 
	tank.botSprite.isFixedRotation = true

	tanks:insert(tank.shadow)
	tanks:insert(tank.bot)
	tanks:insert(tank.botSprite)
	tanks:insert(tank.barrel)

	tank.horizontalVelocity = 0 
	tank.verticalVelocity = 0

	tank.potentialHorizontalVelocity = 0 
	tank.potentialVerticalVelocity = 0

	tank.movementJoint = physics.newJoint("touch",tank.botSprite,tank.botSprite.x,tank.botSprite.y)

	camera:add(tank.shadow,1,false)
	camera:add(tank.botSprite, 1, true)
	camera:add(tank.barrel, 1, false)
	camera:track()

	tank.botSprite.id = "user"

	tank.health = 100
	tank.hasReloaded = true
	tank.isDead = false

	if(params.isMultiplayer)then tank.isMultiplayer = true else tank.isMultiplayer = false end

	function tank:setRotationAndVelocity(e)
		if(e.phase ~= "ended")then

		   
			if(e.x < 250)then
				touchJoint:setTarget( e.x, e.y )
				potentialHorizontalVelocity = joystick.restingX - e.x
			    potentialVerticalVelocity = joystick.restingY - e.y
			    p = 2
			    degree = nil
				if(   p   > 1  )then
						self.horizontalVelocity = joystick.restingX - joystick.x
						self.verticalVelocity = (joystick.restingY - joystick.y)
					if(e.x ~= joystick.restingX and e.y ~= joystick.restingY)then
							degree = math.deg( math.atan( (joystick.restingY - e.y)/(joystick.restingX - e.x)))
							if(e.x < joystick.restingX)then
								degree = degree + 180
							end
					end

					if(degree)then self.botSprite.rotation = degree+90 end
						--self.botSprite.rotation = degree +90
					if(not dualJoystickMode)then 
						self.barrel.rotation = self.bot.rotation + 90 
					end
					--transition.to( botSprite, {rotation = bot.rotation + 90,time = 100} )
				end
			end
		end

		if(e.phase == "ended")then
			self.verticalVelocity = 0 
			self.horizontalVelocity = 0
			touchJoint:setTarget( joystick.restingX, joystick.restingY )
		end
	end


	function tank:toggleShooting(isOn)
		if(isOn)then
			self:shootBullet(false)
			self:toggleShooting(true)
		else
			return false
		end
	end

	function tank:setBarrelRotation(e)

		

		if(e.x < display.contentWidth/2)then

			 if(shootTimer)then		print("cancelling")

				timer.cancel(shootTimer)
			end
			shootTimer = nil
			self:toggleShooting(false)
			barrelTouchJoint:setTarget( barrelJoystick.restingX, barrelJoystick.restingY )
			return true
		end

		if(e.phase == "began")then

			 if(shootTimer)then		print("cancelling")

				timer.cancel(shootTimer)
			end
			shootTimer = nil
			self:toggleShooting(false)


			self:shootBullet(true)
			shootTimer = timer.performWithDelay(200 , function()
				self:shootBullet(true)
			end,  -1 )

		end

		if(e.phase ~= "ended")then
			local degree
		   
				barrelTouchJoint:setTarget( e.x, e.y )
				
			    p = 2
			    
				if(   p   > 1  and e.x and e.y)then
			
					if(e.x ~= barrelJoystick.restingX and e.y ~= barrelJoystick.restingY)then
							degree = math.deg( math.atan( (barrelJoystick.restingY - e.y)/(barrelJoystick.restingX - e.x)))
							if(e.x < barrelJoystick.restingX)then
								degree = degree + 180

							end
					end

					if degree then 
				  	 	self.barrel.rotation = degree + 90
					end

				end
		end

		if(e.phase == "ended")then
			if(shootTimer)then
				timer.cancel(shootTimer)
			end
			shootTimer = nil
			self:toggleShooting(false)
	
			barrelTouchJoint:setTarget( barrelJoystick.restingX, barrelJoystick.restingY )
		end
	end

	function tank:shootBullet(shouldOverride)
		if(self.barrel and self.barrel.rotation and self.isDead == false and ammoText and ammoText.amount >= 1 and (shouldOverride or self.hasReloaded) and game.hasStarted == true)then

			self.hasReloaded = false

			bullet = display.newImage( "PNG/Bullets/bulletBlue_outline.png" )
			bullet:scale(.5,.5)
			bullets:insert(bullet)
			camera:add(bullet, 1, false)
			physics.addBody( bullet, "kinesmatic", {shape = {-5,-10, -5,10, 5,10, 5,-10}})


			bullet.rotation = self.barrel.rotation 

			function bullet:timer(e)
						physics.removeBody( self )
						self:removeSelf()
						self = nil
			end
			timer.performWithDelay( 1000, bullet)

			local theta = math.rad(self.barrel.rotation + 180 )
			local Ox = 0 - 25*math.sin(theta)
			local Oy = 0 + 25*math.cos(theta)
			

			bullet.x = self.botSprite.x + (Ox)
			bullet.y = self.botSprite.y + (Oy)
			bullet.id = "userBullet"

			self:decreaseAmmo()

			bullet:setLinearVelocity( Ox*50, Oy*50 )

			timer.performWithDelay( 200, function()
				self.hasReloaded = true
			end )

			if(tank.isMultiplayer)then
				client:raiseEvent(9,{userId = userId,x = bullet.x,y = bullet.y, xV, yV = bullet:getLinearVelocity(), rotation = bullet.rotation, health = self.health},{ receivers = LoadBalancingConstants.ReceiverGroup.Others })

			end
		else
			if(ammoText)then
				ammoText.amount = 5
				ammoText.text = "Ammo: " .. ammoText.amount
			end
		end
	end


	function dummyHealthRemove(x,y)

		local dummyHealth = display.newImage("health.png")
		dummyHealth.width = 50
		dummyHealth.height = 50
		dummyHealth.x = x
		dummyHealth.y = y
		dummyHealth.id = "health"

		camera:add(dummyHealth,2)

		transition.to( dummyHealth,{ alpha = 0, width = 100,height = 100,transition = easing.outBack})

		function dummyHealth:timer()
				if(self)then
					self:removeSelf()
				self = nil
				end
		end

		timer.performWithDelay( 500, dummyHealth)
	
	end


	function onCollision( self, event )
		if(event.other.id == "enemy")then
			print("USER HIT BY ENEMY BULLET")
			if(userTank) then userTank:decreaseHealth(2) end
			
			local explosion = display.newCircle( event.other.x, event.other.y, 5 )
			--explosion:setFillColor( 255/255,250/255,7/255 )
			camera:add(explosion,1)
			transition.to( explosion, {alpha = 0, xScale = 5,yScale = 5,time = 200} )


			function explosion:timer()
				if(self)then
					self:removeSelf()
				self = nil
				end
		    end

			timer.performWithDelay( 100, explosion)

			print( event.target )        --the first object in the collision
		    print( event.other )         --the second object in the collision
		    print( event.selfElement )   --the element (number) of the first object which was hit in the collision
		    print( event.otherElement )  --the element (number) of the second object which was hit in the collision
		end

		if(event.other.id == "health")then
			healthText.amount = 100
			healthText.text = "Health: "..100

			userTank:decreaseHealth(100)
			physics.removeBody( event.other )
			dummyHealthRemove(event.other.x,event.other.y)

		

			healthDrops[event.other.index]:removeSelf()
			healthDrops[event.other.index] = nil
			return true
		end
	   
	end 

	function tank:destroy()
 		self.isOn = false
 		camera:cancel()
 		Runtime:removeEventListener( "enterFrame", self )
 		if(self)then
 			physics.removeBody( self.botSprite )
 			self.botSprite:removeSelf()
 			self.barrel:removeSelf()
 			self.shadow:removeSelf()
 		end
 		self = nil

 	end

 	function tank:decreaseAmmo()
 		if(ammoText)then
			ammoText.amount = ammoText.amount - 1
			ammoText.text = "Ammo: "..ammoText.amount
		end
	end

	function tank:decreaseHealth(p)
		if(healthText)then
			if(p == 100)then
				healthText.amount = 100
			else
				healthText.amount = healthText.amount - p 
			end

			self.health = healthText.amount
			healthText.text = "Health: "..healthText.amount

			amountHealthIndicator.width = (295)*(self.health/100)
			amountHealthIndicator.x = healthIndicatorBg.x - amountHealthIndicator.width
			amountHealthIndicator:setFillColor((1-(self.health/100)),self.health/100,0 )
		end
	end


	function tank:smoke(a)
		local distance = .8
		local rotationOffset = a
		
		local theta = math.rad(self.botSprite.rotation + rotationOffset )
		local Ox = 0 - 25*math.sin(theta)
		local Oy = 0 + 25*math.cos(theta)
		local horizontalVelocity = Ox
		local verticalVelocity = Oy

		--local tracer = display.newCircle( self.botSprite.x - (horizontalVelocity*distance) ,self.botSprite.y - (verticalVelocity*distance), 1 )
		--tracer.alpha = 0
		--tanks:insert(tracer )
		--camera:add(tracer,1)

		smoke = display.newImage("PNG/Smoke/smokeGreyCustom.png")--display.newCircle(10,10,5 )--
		smoke.width = 20
		smoke.height = 20
		smoke.rotation = math.random(0,360)
		smoke.alpha = .8
		--tanks:insert(smoke)
		camera:add(smoke,2)

		smoke.x = self.botSprite.x - (horizontalVelocity*distance)
		smoke.y = self.botSprite.y - (verticalVelocity*distance)

		transition.to(smoke,{time = 3000,alpha = 0,width = 10,height = 10, self.botSprite.x - (horizontalVelocity*4),self.botSprite.y - (verticalVelocity*4)} )
		function smoke:timer(e)
						self:removeSelf()
						self = nil
		end
		timer.performWithDelay( 3000, smoke)
	end

	function tank:enterFrame()
		print("X = " .. self.botSprite.x .. " Y = ".. self.botSprite.y)
		local speedScale = 5

		local sqCenterX, sqCenterY = userTank.botSprite:contentToLocal( 0, 0 )

		if(highGraphics)then
			self:smoke(135)
			self:smoke(-135)
		end

		self.barrel.x = self.botSprite.x
		self.barrel.y = self.botSprite.y
		if(not dualJoystickMode)then
			self.barrel.rotation = self.botSprite.rotation
		end
		self.movementJoint:setTarget( self.botSprite.x - (self.horizontalVelocity/speedScale), self.botSprite.y - (self.verticalVelocity/speedScale)  )

		tank.shadow.x = tank.botSprite.x
		tank.shadow.y = tank.botSprite.y + 6
		tank.shadow.rotation = tank.botSprite.rotation

	    amountHealthIndicator.x = healthIndicatorBg.x - (healthIndicatorBg.width/2) + 1


	    if(healthText.amount  <= 0 and self.isDead == false )then
				--Tank Death 
				self.isDead = true

				if(game.isMultiplayer)then
					client:raiseEvent(7,{userId = userId,isDead = true},{ receivers = LoadBalancingConstants.ReceiverGroup.Others })
				end

				local explosionCircle = display.newCircle(self.botSprite.x,self.botSprite.y, 50)
				camera:add(explosionCircle,1)
				transition.to( explosionCircle, {xScale = 10,yScale = 10, alpha = 0,onComplete = function()
					explosionCircle:removeSelf()
				end} )

				if(highGraphics == false or highGraphics == true)then
					eDots = {}
					for i = 1, (100) do 
						
						--transition.to( eDots[i],{alpha = 0,} )

						
							local theta = math.rad(360*(i/100))
							local Ox = 0 - 25*math.sin(theta)
							local Oy = 0 + 25*math.cos(theta)

							eDots[i] = display.newCircle( self.botSprite.x + (Ox/2), self.botSprite.y + (Oy/2),2.5)
							eDots[i]:setFillColor( 255/255,116/255,1/255 )
							camera:add(eDots[i],1)
							physics.addBody( eDots[i], "kinesmatic" )
							eDots[i]:setLinearVelocity((Ox*math.random(5,15)), (Oy*math.random(5,15)) )

							transition.to( eDots[i], {alpha = 0,time = 2000} )
							local dot = eDots[i]
							function dot:timer(e)
										physics.removeBody( self )
										self:removeSelf()
										self = nil
							end
							timer.performWithDelay( 2000, dot)
					end
				end

					transition.to( self.barrel, {alpha = 0, time = 200} )
					transition.to( self.shadow, {alpha = 0, time = 200} )

					transition.to( self.botSprite, {alpha = 0, time = 200, onComplete = function()
						self:destroy(true)
					end} )

			end

	end


	tank.botSprite.collision = onCollision 
	tank.botSprite:addEventListener( "collision" )
	Runtime:addEventListener( "enterFrame", tank )


	return tank
end