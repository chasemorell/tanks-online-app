local composer = require( "composer" )
 
local scene = composer.newScene()
 
function showWaitingForPlayersNotification()
    nBar = display.newRoundedRect(display.contentWidth/2, 0, 200, 40, 10 )
    nBar.alpha = 0
    transition.to( nBar, {y = 75, alpha = .5, transition = easing.outExpo } )
    nText = display.newText( "Waiting For Opponent...", display.contentWidth/2, 0, native.systemFont, 18 )
    nText:setFillColor( 0,0,0 )
    nText.alpha = 0
    transition.to( nText, {y = 75, alpha = 1, transition = easing.outExpo} )
    nBar.isClosing = false

end

function hideWaitingForPlayersNotification()
   -- nBar.alpha = 0
    if(nBar and nBar.isClosing == false)then
        nBar.isClosing = true
        transition.to( nBar, {y = 0, alpha = 0} )
        transition.to( nText, {y = 0, alpha = 0, onComplete = function()
            nBar = nil 
            nText = nil
        end} )

    end

end

function scene:create( event )
 
    local sceneGroup = self.view
 
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

    local function setUpBarricades(prevX,prevY,count,rotation)


            if(count > 200)then
                return
            end

            box = display.newRect( 0,0,50,50)
            --box.width = box.width /3
            --box.height = box.height/3

            local direction = math.random(1,6)

            if(direction == 1)then -- down
                box.x = prevX 
                box.y = prevY + box.height
                box.rotation = 90
                --box.anchorY = 0
            elseif(direction == 2)then -- right
                box.x = prevX + box.width
                box.y = prevY
                box.rotation = 90
                --box.anchorY = 0
            elseif(direction == 3)then -- up
                box.x = prevX
                box.y = prevY + box.height
            elseif(direction == 4)then -- skip right
                box.x = prevX + (box.width*math.random(3,4))
                box.y = prevY
                box.rotation = 90
                --box.anchorY = 0
            elseif(direction == 5)then -- skip up
                box.x = prevX
                box.y = prevY - (box.width*math.random(3,4))
            elseif(direction == 6)then -- skip down
                box.x = prevX
                box.y = prevY + (box.width*math.random(3,4))
            end
            --box.x = prevX
           -- box.y = math.random(300,2000)
            camera:add(box,2)



            physics.addBody( box, "static")
            
            count = count + 1

            setUpBarricades(box.x,box.y,count,box.rotation)
    end

    function enterMultiplayerArena()
        gameOn = true
        highGraphics = true
        initiateGame({})
        createUI({})
        createMap({})

       -- setUpBarricades(0,0,0,0)

        userTank = newUserTank({isMultiplayer = true})--createUserBot({})

        
        
        if(game.didCreateRoom)then
            enemyTank = newTank({x = 2071,y = 300})

            print("WAITING FOR PLAYERS.....................")
            showWaitingForPlayersNotification()
        else
            enemyTank = newTank({x = 700,y = 300})
        end

        createObstacles()


    end

    function setUpMultiplayerEnemies()


        print("ACTOR COUNT:")
        timer.performWithDelay( 1000, function() 
        end, -1)

        if(1 > 2)then
            otherTank = newTank({})
        else
           -- print("user is the only actor in room")
        end
    end


    enterMultiplayerArena()
    end
 
 
function scene:show( event )
 
    local sceneGroup = self.view
    local phase = event.phase
 
    if ( phase == "will" ) then
 
    elseif ( phase == "did" ) then
            sendTimer = timer.performWithDelay( 100, function()
                    client:raiseEvent(100,{barrelRotation = userTank.barrel.rotation, userId = userId,rotation = userTank.botSprite.rotation, x = userTank.botSprite.x,y = userTank.botSprite.y,rotation = userTank.botSprite.rotation, health = userTank.health},{ receivers = LoadBalancingConstants.ReceiverGroup.All, sendReliable = false })
            end, -1 )
             timer.performWithDelay( 1000,  setUpMultiplayerEnemies())

    end
end
 
 
function scene:hide( event )
 
    local sceneGroup = self.view
    local phase = event.phase
 
    if ( phase == "will" ) then
        timer.cancel( sendTimer )
    elseif ( phase == "did" ) then

    end
end
 
 
function scene:destroy( event )
 
    local sceneGroup = self.view
    -- Code here runs prior to the removal of scene's view
 
end

function enterFrame()
    --print("SENDING EVENT")


end
Runtime:addEventListener( "enterFrame", enterFrame )
 
-- -----------------------------------------------------------------------------------
-- Scene event function listeners
-- -----------------------------------------------------------------------------------
scene:addEventListener( "create", scene )
scene:addEventListener( "show", scene )
scene:addEventListener( "hide", scene )
scene:addEventListener( "destroy", scene )
-- -----------------------------------------------------------------------------------
 
return scene