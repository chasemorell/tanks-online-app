function newTank(args)
	local tank = {}

	if(args.isUser == true)then tank.isUser = true else tank.isUser = false end

	local x = math.random( 500,2500 ) 
	local y = math.random(-50,650) 

	if(args.x)then x = args.x end
	if(args.y)then y = args.y end 

	tank.botSprite = display.newImage("PNG/Tanks/tankRed_outline.png")
	tank.botSprite.x = x
	tank.botSprite.y = y

	tank.shadow = display.newImage("shadow.png")
	tank.shadow.width = 50
	tank.shadow.height = 50
	tank.shadow.alpha = .4


	tank.barrel = display.newImage("PNG/Tanks/barrelRed_outline.png")
	tank.barrel.x = tank.botSprite.x
	tank.barrel.y = tank.botSprite.y
	tank.botSprite.width = 50
	tank.botSprite.height = 50

	--tank.botSprite:scale(scale,scale)
	scale = .7
	tank.barrel:scale(scale,scale)

	tank.barrel.anchorY = 1
	tank.changingPosition = false

	tank.horizontalVelocity = 0
	tank.verticalVelocity = 0 
	tank.destinationCoordinates = {x = 0,y = 0}
	tank.speedScale = 15
	tank.isOn = true
	tank.turning = false
	tank.canShoot = true
	tank.specialMove = false
	tank.speed = 1
	tank.health = 100
	tank.isDead = false
	tank.isAI = false

	tank.healthIndicatorBg = display.newRoundedRect( 0,0, 40,6, 3 )
	tank.healthIndicatorBg.alpha = .5

	tank.amountHealthIndicator = display.newRoundedRect( 0,0, 38,4, 3 )
	tank.amountHealthIndicator.alpha = 1
	tank.amountHealthIndicator:setFillColor(0,1,0 )
	tank.amountHealthIndicator.anchorX = 0

	physics.addBody(tank.botSprite, "kinesmatic" ) 
	tank.botSprite.isFixedRotation = true
	tank.movementJoint = physics.newJoint("touch",tank.botSprite,tank.botSprite.x,tank.botSprite.y)


	camera:add(tank.shadow,1,false)
	camera:add(tank.botSprite, 1, false)
	camera:add(tank.barrel, 1, false)
	camera:add(tank.healthIndicatorBg,1)
	camera:add(tank.amountHealthIndicator,1)



 	function tank:destroy(ghost)

 		if(ghost)then
 			self.isOn = false
 			self.isDead = true
 			physics.removeBody( self.botSprite )
 			self.botSprite.alpha = 0
 			self.barrel.alpha = 0 
 			self.shadow.alpha = 0
 			self.healthIndicatorBg.alpha = 0
 			self.amountHealthIndicator.alpha = 0

 			if(self.isAI)then
 				timer.cancel( self.aiRoutine )
 			end

 			return true
 		end

 		if(self.botSprite)then
	 		self.isOn = false
	 		Runtime:removeEventListener( "enterFrame", self )
	 		self.botSprite:removeSelf()
	 		self.botSprite = nil
	 		self.barrel:removeSelf()
	 		self.shadow:removeSelf()
	 		self.healthIndicatorBg:removeSelf()
	 		self.amountHealthIndicator:removeSelf()
	 		if(self.isAI)then timer.cancel( self.aiRoutine ) end

	 		self = nil
 		end
 	end

	function tank:move(newX,newY)
		if(self.isOn and self.isDead == false)then
			self.speed = 1

			self.destinationCoordinates = {x = newX, y = newY}
			self.speedScale = 7

			if(self.botSprite)then
				local deltaX = newX - self.botSprite.x 
				local deltaY = newY - self.botSprite.y 
				local degree = math.deg( math.atan(deltaY/deltaX)) 
				if(newX < self.botSprite.x)then
					degree = degree + 180
				end
				

				transition.to( self.botSprite, {rotation = degree + 90, transition = easing.inOutSine , onComplete = function()
							self.changingPosition = true

				end}  )
				transition.to( self.shadow, {rotation = degree + 90, transition = easing.inOutSine })
			end
		end

	end

	function tank:rotateTowardPoint(newX,newY)
		--self.changingPosition = true
		if(self.isOn)then
			self.changingPosition = false
			self.speed = 0

			local deltaX = newX - self.botSprite.x 
			local deltaY = newY - self.botSprite.y 
			local degree = math.deg( math.atan(deltaY/deltaX)) 
			if(newX < self.botSprite.x)then
				degree = degree + 180
			end
			

			transition.to( self.botSprite, {rotation = degree + 90, transition = easing.inOutSine , onComplete = function()

			end}  )
			transition.to( self.shadow, {rotation = degree + 90, transition = easing.inOutSine })

		end

	end

	function tank:naturalMove(newX,newY)
		self.isOn = true
		self.changingPosition = true

		self.speed = 1


	
		self.destinationCoordinates = {x = newX, y = newY}
		self.speedScale = 7
		self.turningGranularity = .2
		self.changingPosition = true
		local deltaX = newX - self.botSprite.x 
		local deltaY = newY - self.botSprite.y 
		local degree = math.deg( math.atan(deltaY/deltaX)) 
		if(newX < self.botSprite.x)then
			degree = degree + 180
		end
		
		self.turning = true
		self.turningDirection = 1
		self.turningGoal = degree + 90

		if(((self.botSprite.rotation+90)-degree) > 180)then
			--print("TURNING WITH -1")
			self.turningDirection = -1
		end

	--	transition.to( self.botSprite, {rotation = degree + 90, transition = easing.inOutSine , onComplete = function()
		--			self.changingPosition = true
		--
	--	end}  )

	end


	function tank:backUp()
		self.changingPosition = false
		self.horizontalVelocity = 0
		self.verticalVelocity = 0

		local theta = math.rad(self.botSprite.rotation)
		local Ox = 0 - 25*math.sin(theta)
		local Oy = 0 + 25*math.cos(theta)
		local horizontalVelocity = Ox*3
		local verticalVelocity = Oy*3

		
		self:move(self.botSprite.x + horizontalVelocity,self.botSprite.y + verticalVelocity)
		--transition.to(self.botSprite,{x = self.botSprite.x + horizontalVelocity, y = self.botSprite.y + verticalVelocity})
	end

	function tank:stop(params)
		if(gameOn == true)then
			--self.isOn = false
			--self.specialMove = true
			if(self and self.botSprite)then
				self.changingPosition = false
				self.horizontalVelocity = 0
				self.verticalVelocity = 0

				local side = 1
				if(self.botSprite.rotation)then
					local theta = math.rad(self.botSprite.rotation - (90 * side ))
					local Ox = 0 - 25*math.sin(theta)
					local Oy = 0 + 25*math.cos(theta)
					local horizontalVelocity = Ox*5
					local verticalVelocity = Oy*5--3
					timer.performWithDelay( 1500,function()
						self.specialMove = false
					end )


						self:move(self.botSprite.x - horizontalVelocity,self.botSprite.y - verticalVelocity)
				end

			end
		end
	end

	function tank:shootBullet()
		if(self.canShoot == true and self.isAI == true)then
			--print("Did shoot")
			self.canShoot = false
			

			bullet = display.newImage( "PNG/Bullets/bulletRed_outline.png" )
			bullet:scale(.5,.5)
			tanks:insert(bullet)
			camera:add(bullet, 1, false)
			bullet.id = "enemy"
			physics.addBody( bullet, "kinesmatic",{shape = {-5,-10, -5,10, 5,10, 5,-10}})

			function bullet:timer(e)
				physics.removeBody( self )
				self:removeSelf()
				self = nil
			end
			timer.performWithDelay( 500, bullet)
		
			bullet.rotation = self.barrel.rotation 


			local theta = math.rad(self.barrel.rotation)
			local Ox = 0 - 50*math.sin(theta)
			local Oy = 0 + 50*math.cos(theta)
			 self.horizontalVelocity = Ox
			 self.verticalVelocity = Oy

			bullet.x = self.botSprite.x - self.horizontalVelocity
			bullet.y = self.botSprite.y - self.verticalVelocity


			bullet:setLinearVelocity( Ox*20, Oy*20)

			timer.performWithDelay( 100, function()
			--	self.botSprite.isBodyActive = true
			end )
		end

		if(self.isAI == false)then
			bullet = display.newImage( "PNG/Bullets/bulletRed_outline.png" )
			bullet:scale(.5,.5)
			bullets:insert(bullet)
			self.canShoot = false
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
			bullet.id = "enemy"

			bullet:setLinearVelocity( Ox*50, Oy*50 )
		end
	end

	function tank:sendRayCast(side)
		local distance = 2
		local rotationOffset = 0
		if(side == "left")then rotationOffset = -45 end
		if(side == "right")then rotationOffset = 45 end
		if(side == "center" or side == "far")then rotationOffset = 0 end
		if(side == "far")then distance = 6 end
		local theta = math.rad(self.botSprite.rotation + rotationOffset )
		local Ox = 0 - 25*math.sin(theta)
		local Oy = 0 + 25*math.cos(theta)
		local horizontalVelocity = Ox
		local verticalVelocity = Oy

		--local tracer = display.newCircle( self.botSprite.x - (horizontalVelocity*distance) ,self.botSprite.y - (verticalVelocity*distance), 1 )
		--tracer.alpha = 0
		--tanks:insert(tracer )
		--camera:add(tracer,1)
		--transition.to( tracer, {alpha = 0} )

		return physics.rayCast(self.botSprite.x, self.botSprite.y, self.botSprite.x - (horizontalVelocity*distance) ,self.botSprite.y - (verticalVelocity*distance), "closest" )
	end


	function tank:isHeadingTowardGoal()
		local deltaX = self.destinationCoordinates.x - self.botSprite.x 
		local deltaY = self.destinationCoordinates.y - self.botSprite.y 
		local degree = math.deg( math.atan(deltaY/deltaX)) 
		if(self.destinationCoordinates.x < self.botSprite.x)then
			degree = degree + 180
		end
		
		--print("DEGREE GOAL = " .. degree)
		--print("CURRENT = " .. self.botSprite.rotation - 90)
		if(math.abs(degree - (self.botSprite.rotation-90)) < 3)then
		--	print("TRUE")
			return true
		end

		if(math.abs(degree - (self.botSprite.rotation-90)) < 10)then
			--print("TRUE")
			transition.to( self.botSprite, {rotation = degree + 90,time = 10} )
			transition.to( self.shadow, {rotation = degree + 90,time = 10} )

			return false
		end

		--print("FALSE")
		return false
	end

	function tank:startStandardBehavior()
		self.aiRoutine = timer.performWithDelay( 500, function()
			self.isAI = true
			self.isOn = true
			if(self.specialMove == false and userTank)then

				if(self.health < 50)then
					self:moveTowardHealthDrop()
				elseif(distance(userTank.botSprite.x,userTank.botSprite.y,self.botSprite.x,self.botSprite.y) > 120)then
					local toX,toY = midPoint(userTank.botSprite.x,userTank.botSprite.y,self.botSprite.x,self.botSprite.y)
					self:naturalMove(toX,toY)
				else
					--enemyTank.isOn = false
					--enemyTank:rotateTowardPoint(userTank.botSprite.x,userTank.botSprite.y)
				end


			end
			self.canShoot = true
		end , -1)
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
	--print("IS TURNING? " .. tostring( self.turning))
	
	self.shadow.x = self.botSprite.x
	self.shadow.y = self.botSprite.y + 6
	self.shadow.rotation = self.botSprite.rotation

	if(self.turning == true and self.turningGranularity < 4)then
		self.turningGranularity = self.turningGranularity + .2
	end
	if(self.botSprite.rotation > 360)then
		self.botSprite.rotation = self.botSprite.rotation - 360
	end

	if(self.botSprite.rotation < -360)then
		self.botSprite.rotation = self.botSprite.rotation + 360
	end
 
	if(self.isOn == true and self.isDead == false)then

		if(highGraphics)then
			self:smoke(135)
			self:smoke(-135)
		end

		if(self.turning == true)then

			self.botSprite.rotation = self.botSprite.rotation + (self.turningGranularity * self.turningDirection)

			if(self:isHeadingTowardGoal() == true)then
				--print("NOT TURNING ANYMORE")
				self.turning = false

			end
		end

		if(self.changingPosition == true)then

			--calculate horizontal and vertical velocities
			self.theta = math.rad(self.botSprite.rotation )
			self.Ox = 0 - 50*math.sin(self.theta)
			self.Oy = 0 + 50*math.cos(self.theta)
			self.horizontalVelocity = self.Ox * self.speed
			self.verticalVelocity = self.Oy * self.speed

			rayCastX = self.horizontalVelocity *2
			rayCastY = self.verticalVelocity*2
			--tracer = display.newCircle( self.botSprite.x - rayCastX ,self.botSprite.y - rayCastY, 2 )
			--transition.to( tracer, {alpha = 0} )

			if(self.isUser == false and self.isAI)then

				local centerHit = self:sendRayCast("center")
				local rightHit = self:sendRayCast("right")
				local leftHit = self:sendRayCast("left")
				local reticleHit = self:sendRayCast("far")

				if(reticleHit )then
					--print("SHOOT " .. reticleHit[1].object.id )
											--self:shootBullet() 
					--print_r(reticleHit)
					if(reticleHit[1].object.id == "user") then  
						--print("attempting to shoot bullet ****")
						self:shootBullet() 
					end
				else
					--print("NOPE")
				end
				if ( centerHit or rightHit or leftHit) then
					
					if(centerHit)then
						if(centerHit[1].object.id ~= "enemy" and centerHit[1].object.id ~= "health")then
							self.specialMove = true
							--self:backUp()
							timer.performWithDelay( 1000, function()
								self.changingPosition = false
								self:stop({keepMoving = true})
						end )
						end
					end
					if(rightHit or leftHit)then
						if((rightHit and rightHit[1].object.id ~= "enemy" and rightHit[1].object.id ~= "health") or (leftHit and leftHit[1].object.id == "enemy" and leftHit[1].object.id ~= "health"))then

							self.specialMove = true
							self:backUp()
							
								timer.performWithDelay( 1000, function()
									self.changingPosition = false
									self:stop( {keepMoving = true})
								end )
						end


					end
					if(leftHit)then
						--self:backUp()
					end
					--print("HIT")
					
		    		-- No hits on raycast
				end

			end
		end


		if(self.isUser == false)then
			if(math.abs(self.botSprite.x - self.destinationCoordinates.x) < 5 and math.abs(self.botSprite.y - self.destinationCoordinates.y) < 5)then
				self.changingPosition = false
				self.horizontalVelocity = 0
				self.verticalVelocity = 0
				self.specialMove = false
				--self:naturalMove(math.random(20,400),math.random(20,200 ))
			end

			if(math.abs(self.botSprite.x - self.destinationCoordinates.x) < 40 and math.abs(self.botSprite.y - self.destinationCoordinates.y) < 40)then
				--self.speedScale = 20
				--if(self.isTurning)then self.turningGranularity = 1 end
			end

			if(math.abs(self.botSprite.x - self.destinationCoordinates.x) < 20 and math.abs(self.botSprite.y - self.destinationCoordinates.y) < 20)then
				--self.speedScale = 40
			end
		end

			if(self.isOn == true and self.isDead == false and self.isAI == false)then
				--self.movementJoint:setTarget( self.botSprite.x - (self.horizontalVelocity/self.speedScale), self.botSprite.y - (self.verticalVelocity/self.speedScale) )
				--self.barrel. rotation = self.botSprite.rotation

			end

			if(self.isOn == true and self.isDead == false and self.isAI == true)then
				self.movementJoint:setTarget( self.botSprite.x - (self.horizontalVelocity/self.speedScale), self.botSprite.y - (self.verticalVelocity/self.speedScale) )
				--self.botSprite.x = self.botSprite.x - (self.horizontalVelocity/self.speedScale)
				--self.botSprite.y = self.botSprite.y - (self.verticalVelocity/self.speedScale)
				self.barrel. rotation = self.botSprite.rotation

			end


	    	self.barrel.x = self.botSprite.x
	    	self.barrel.y = self.botSprite.y

	    	

			self.healthIndicatorBg.x = self.botSprite.x
			self.healthIndicatorBg.y = self.botSprite.y - 30

			self.amountHealthIndicator.x = self.botSprite.x - (self.healthIndicatorBg.width/2) + 1
			self.amountHealthIndicator.y = self.botSprite.y - 30

			if(self.health <= 0 and self.isDead == false and self.isAI == true)then
				--Tank Death 
				 self:die()

			end
    	--end
    end
	end

	function tank:die()
				self.isDead = true

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

	function tank:moveTowardHealthDrop()
		local newTarget = self:findNearestHealthDrop()
		if(newTarget)then
			print("GOING TO A HEALTH PACK")
			self:move(newTarget.x,newTarget.y)
			return true
		end
	end

	function tank:updateHealth()
			self.amountHealthIndicator.width = (38)*(self.health/100)
			self.amountHealthIndicator.x = self.healthIndicatorBg.x - self.amountHealthIndicator.width
			self.amountHealthIndicator:setFillColor((1-(self.health/100)),self.health/100,0 )

			if(self.health < 50 and self.isAI)then
				self:moveTowardHealthDrop()
			end
	end

	function tank:findNearestHealthDrop()
		--local nearest
		local nearest = healthDrops[1]
		local lowestDistance = 10000000000

		for i = 1, healthIndex do
			if(healthDrops[i])then
				local dis = distance(self.botSprite.x,self.botSprite.y,healthDrops[i].x,healthDrops[i].y)
				if( dis < lowestDistance and isInBounds(healthDrops[i].x,healthDrops[i].y) )then
					nearest = healthDrops[i]
					lowestDistance = dis

				end
			end
		end

		print("NEAREST HEALTH IS ".. lowestDistance .. "units away")
		return nearest
	end

	function onCollision( self, event )
		if(event.other.id == "userBullet")then

			if(tank.isAI)then tank.health = tank.health - 10 else tank.health = tank.health - 2 end 

			tank:updateHealth()
		
			local explosion = display.newCircle( event.other.x, event.other.y, 5 )
			--explosion:setFillColor( 255/255,250/255,7/255 )
			camera:add(explosion,1)
			transition.to( explosion, {alpha = 0, xScale = 8,yScale = 8,time = 200} )



			function explosion:timer()
				if(self)then
					self:removeSelf()
				self = nil
				end
		    end

			timer.performWithDelay( 100, explosion)

			print("AI HIT BY USER BULLET")
			print( event.target )        --the first object in the collision
		    print( event.other )         --the second object in the collision
		    print( event.selfElement )   --the element (number) of the first object which was hit in the collision
		    print( event.otherElement )  --the element (number) of the second object which was hit in the collision
		end


		if(event.other.id == "health")then
			tank.health = 100

			tank:updateHealth()


			physics.removeBody( event.other )
			dummyHealthRemove(event.other.x,event.other.y)

			--event.other:removeSelf()
			--event.other = nil

			healthDrops[event.other.index]:removeSelf()
			healthDrops[event.other.index] = nil
			return true
		end

	   
	end 

	tank.botSprite.collision = onCollision 
	tank.botSprite:addEventListener( "collision" )

	Runtime:addEventListener( "enterFrame", tank )

	return tank
end