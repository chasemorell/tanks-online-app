local composer = require( "composer" )
 
local scene = composer.newScene()
local widget = require( "widget" )


function menuExitAnimation( )
   local offset = 100
    transition.to( logo, {alpha = 0} )
    transition.to( logo, {transition = easing.inOutQuint , width = 350, height = 350, y = 75 - offset} )
    
    aiButton:setEnabled(false)
    transition.to( aiButton, {alpha = 0} )
    transition.to( aiButton, {transition = easing.inOutQuint, width = 800/5, height = 300/5, y = 270 + offset + 50, onComplete = function()
     end} )

    multiplayerButton:setEnabled(false)
        transition.to( multiplayerButton, {alpha = 0} )
        transition.to( multiplayerButton, {transition = easing.inOutQuint, width = 800/5, height = 400/5, y = 220 + offset, onComplete = function()
            end} )


    timer.performWithDelay( 200, function()
        transition.to( settingsButton, {alpha = 0, y = 280 + offset, transition = easing.inOutQuint} )
    end)

    transition.to( orangeTank, {x = -400, transition = easing.inOutQuint} )
    transition.to( blueTank, {x = display.contentWidth + 400, transition = easing.inOutQuint} )



end


function menuIntroAnimation()
    logo.alpha = 0
    logo.width = 350/5
    logo.height = 350/5
    transition.to( logo, {alpha = 1} )
    transition.to( logo, {transition = easing.outBack, width = 350, height = 350, y = 75} )

    aiButton.alpha = 0
    multiplayerButton.alpha = 0
   -- aiButton.width = 800/10
   -- aiButton.height = 300/10

    timer.performWithDelay( 750,function()
        transition.to( aiButton, {alpha = 1} )
        transition.to( aiButton, {transition = easing.outBack, width = 800/5, height = 300/5, y = 270, onComplete = function()
            aiButton:setEnabled(true)
            end} )
    end )

    timer.performWithDelay( 500,function()
        transition.to( multiplayerButton, {alpha = 1} )
        transition.to( multiplayerButton, {transition = easing.outBack, width = 800/5, height = 400/5, y = 220, onComplete = function()
            multiplayerButton:setEnabled(true)
            end} )
    end )

    timer.performWithDelay( 1000, function()
        transition.to( settingsButton, {alpha = 1, y = 280, transition = easing.outBack} )
    end)

    transition.to( orangeTank, {x = -10, transition = easing.outBack} )
    transition.to( blueTank, {x = display.contentWidth + 30, transition = easing.outBack} )

end


function scene:create( event )
 
    local sceneGroup = self.view

    menuBg = display.newImage("menuBg.png")

    logo = display.newImage("logo.png")
    logo.width = 350
    logo.height = 350
    logo.alpha = 0

    logo.x = display.contentWidth/2
    logo.y = 300


    function aiButtonHandler(e)
        if(e.phase == "ended")then 
            menuExitAnimation()

            timer.performWithDelay( 1200, function()
                composer.removeScene( "menu", false ) 
                game.isMultiplayer = false
                enterPracticeArena()

                timer.performWithDelay( 1000, function()
                    game.hasStarted = true
                end )
            end )
          
        end
    end

    function multiplayerButtonHandler(e)
        if(e.phase == "ended")then
            menuExitAnimation()
            game.isMultiplayer = true
            multiplayerButton:setEnabled( false )
            timer.performWithDelay( 1200, function()
                composer.removeScene( "menu", false ) 

                composer.gotoScene( "multiplayerLobby" ) 
               
            end )
        end
    end

    function settingsTouch(e)
        if e.phase == "ended" then
            composer.gotoScene( "settings" )
        end
    end

    aiButton = widget.newButton(
    {
        width = 800/5,
        height = 300/5,
        defaultFile = "aiButton.png",
        overFile = "aiButtonDown.png",
       -- label = "button",
        onEvent = aiButtonHandler
    })

    multiplayerButton = widget.newButton(
    {
        width = 800/5,
        height = 400/5,
        defaultFile = "multiplayer.png",
        overFile = "multiplayerDown.png",
       -- label = "button",
        onEvent = multiplayerButtonHandler
    })

    settingsButton = display.newRoundedRect( display.screenOriginX + 40, 280 + 50, 40, 40, 4 )
    settingsButton.alpha = 0 
    settingsButton:addEventListener( "touch", settingsTouch )

    aiButton.x = display.contentWidth/2
    aiButton.y = 270 + 200
    aiButton:setEnabled(false )

    multiplayerButton.x = display.contentWidth/2
    multiplayerButton.y = 220 + 200
    multiplayerButton:setEnabled(false )

    orangeTank = display.newImage("orangeTank.png")
    orangeTank.width = 1600/4
    orangeTank.height = 1200/4
    orangeTank.x = -400 -- -10
    orangeTank.y = 200

    blueTank = display.newImage("blueTank.png")
    blueTank.width = 1600/4
    blueTank.height = 1200/4
    blueTank.x = display.contentWidth + 400 --display.contentWidth + 30
    blueTank.y = 200

    sceneGroup:insert(menuBg)
    sceneGroup:insert(settingsButton)
    sceneGroup:insert(logo)
    sceneGroup:insert(aiButton)
    sceneGroup:insert(multiplayerButton)
    sceneGroup:insert(orangeTank)
    sceneGroup:insert(blueTank)

    timer.performWithDelay( 750, function()
        menuIntroAnimation()
    end)
    -- Code here runs when the scene is first created but has not yet appeared on screen
 
end
 
 
-- show()
function scene:show( event )
 
    local sceneGroup = self.view
    local phase = event.phase
 
    if ( phase == "will" ) then
        -- Code here runs when the scene is still off screen (but is about to come on screen)
 
    elseif ( phase == "did" ) then
        highGraphics = false
            --    menuIntroAnimation()

        -- Code here runs when the scene is entirely on screen
 
    end
end
 
 
-- hide()
function scene:hide( event )
 
    local sceneGroup = self.view
    local phase = event.phase
 
    if ( phase == "will" ) then
        -- Code here runs when the scene is on screen (but is about to go off screen)
 
    elseif ( phase == "did" ) then
        -- Code here runs immediately after the scene goes entirely off screen
 
    end
end
 
 
-- destroy()
function scene:destroy( event )
 
    local sceneGroup = self.view
    -- Code here runs prior to the removal of scene's view
 
end
 
 
-- -----------------------------------------------------------------------------------
-- Scene event function listeners
-- -----------------------------------------------------------------------------------
scene:addEventListener( "create", scene )
scene:addEventListener( "show", scene )
scene:addEventListener( "hide", scene )
scene:addEventListener( "destroy", scene )
-- -----------------------------------------------------------------------------------
 
return scene