-----------------------------------------------------------------------------------------
--
-- level1.lua
-- simple shadow scenen with two lights
--
-----------------------------------------------------------------------------------------

local composer  = require( "composer" )
local scene     = composer.newScene()


--------------------------------------------

-- forward declarations and other locals


function scene:create( event )

    -- Called when the scene's view does not exist.
    -- 
    -- INSERT code here to initialize the scene
    -- e.g. add display objects to 'sceneGroup', add touch listeners, etc.

    local sceneGroup = self.view

    function scene:createMap(params)
        bg = display.newImage("PNG/Environment/grass.png")
        bg:scale(50,50)
        sceneGroup:insert(bg)
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

            sceneGroup:insert(ground[i])
            camera:add(ground[i],2)

        end

        wall = display.newRect( 300,300, 10,200 )
        physics.addBody( wall, "static" )

        map:insert(wall)
        wall.id = "map"
        camera:add(wall,2,false)
        print("DONE")
    end


    map, bullets, tanks, ui,lights =  initiateGame({})

    sceneGroup:insert(map)
    sceneGroup:insert(bullets)
    sceneGroup:insert(tanks)
    sceneGroup:insert(ui)
    sceneGroup:insert(lights)
    
    self:createMap({})

    joystick, joystickT,shootButton, healthText, ammoText = createUI({})

    sceneGroup:insert(joystick)
    sceneGroup:insert(joystickT)
    sceneGroup:insert(shootButton)
    sceneGroup:insert(healthText)
    sceneGroup:insert(ammoText)



    userTank = newUserTank({})--createUserBot({})

    enemyTank = newTank({})
    enemyTank:startStandardBehavior()

end

function scene:hide( event )
    local sceneGroup = self.view
    
    local phase = event.phase
    
    if event.phase == "will" then
        -- Called when the scene is on screen and is about to move off screen
        --
        -- INSERT code here to pause the scene
        -- e.g. stop timers, stop animation, unload sounds, etc.)
    elseif phase == "did" then
        -- Called when the scene is now off screen
    end 
    
end

function scene:destroy( event )

    -- Called prior to the removal of scene's "view" (sceneGroup)
    -- 
    -- INSERT code here to cleanup the scene
    -- e.g. remove display objects, remove touch listeners, save state, etc.
    local sceneGroup = self.view
    
    physics = nil
end



---------------------------------------------------------------------------------

-- Listener setup
scene:addEventListener( "create", scene )
scene:addEventListener( "show", scene )
scene:addEventListener( "hide", scene )
scene:addEventListener( "destroy", scene )

-----------------------------------------------------------------------------------------

return scene