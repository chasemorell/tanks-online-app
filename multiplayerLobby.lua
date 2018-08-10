local composer = require( "composer" )
--local facebook = require( "plugin.facebook.v4a" )

local scene = composer.newScene()
local widget = require( "widget" )
local gameNetwork = require( "gameNetwork" )


local photon = require "plugin.photon"
local masterAddress = "ns.exitgames.com:5058" -- using Photon Cloud EU region as default
local appId = "c68a53a4-6124-4a93-8d33-94435d4a2839" -- each application on the Photon Cloud gets an appId
local appVersion = "1.0" -- clients with different versions will be separated (easy to update clients)

if pcall(require,"plugin.photon") then -- try to load Corona photon plugin
    print("Demo: main module:","Corona plugin used")
    photon = require "plugin.photon"    
    LoadBalancingClient = photon.loadbalancing.LoadBalancingClient
    LoadBalancingConstants = photon.loadbalancing.constants
    Logger = photon.common.Logger
    tableutil = photon.common.util.tableutil    
else  -- or load photon.lua module
    print("Demo: main module:","Lua lib used")
    photon = require("photon")
    LoadBalancingClient = require("photon.loadbalancing.LoadBalancingClient")
    LoadBalancingConstants = require("photon.loadbalancing.constants")
    Logger = require("photon.common.Logger")
    tableutil = require("photon.common.util.tableutil")    
end

local EVENT_CODE = 101
local MAX_SENDCOUNT = 100

client = LoadBalancingClient.new(masterAddress, appId,appVersion)
--client:setLogLevel(Logger.Level.DEBUG)
local lastErrMess = ""
client.mRunning = true


function client:onOperationResponse(errorCode, errorMsg, code, content)
    --self.logger:debug("onOperationResponse", errorCode, errorMsg, code, tableutil.toStringReq(content))
    print("OPERATION RESPONSE : " )
    print_r(content)
    if errorCode ~= 0 then
        if code == LoadBalancingConstants.OperationCode.JoinRandomGame then  -- master random room fail - try create
           -- self.logger:info("createRoom")
            game.didCreateRoom = true
            self:createRoom("2PlayerMultiplayerRoom_"..tostring(math.random(1,999999)),{emptyRoomLiveTime = 200,maxPlayers = 2})
        elseif errorCode == 32758 then
            print("Lol, that game doesn't exist mate") 
            joinPrivateButton.alpha = 1 
            joinPrivateButton:setEnabled(true)
            nameField.alpha = 1
            --closeSearchOverlay()
           
        end
         self.logger:error(errorCode, errorMsg)
    end
end

function client:onStateChange(state)
    print("**** Status has changed to "..state)
    self.stateInt = state
    if(state == 8)then 
        userId = tostring(math.random(100,999))
        print("USER ID IS ".. userId)
        client:setUserId (userId)

        if(Pbg)then
            closeSearchOverlay()
        end
        client:initActor ()

        if(game.didCreateRoom)then
            --photon.loadbalancing.Room:setEmptyRoomLiveTime(200)
        end

        timer.performWithDelay( 400, function()
               actors = client:myRoom().playerCount
               print("PLAYER COUNT: ".. actors)

            composer.gotoScene( "multiplayerGame" )
        end )
    end

    if state == LoadBalancingClient.State.JoinedLobby then
        print("SHOWING FIND MATCH BUTTON")
        findMatchButton.alpha = 1
        findMatchButton:setEnabled(true)
        createGameButton:setEnabled( true )
        joinGameButton:setEnabled( true )
        createGameButton.alpha = 1
        joinGameButton.alpha = 1
   
    end
end

function client:onError(errorCode, errorMsg)
    if errorCode == LoadBalancingClient.PeerErrorCode.MasterAuthenticationFailed then
        errorMsg = errorMsg .. " with appId = " .. self.appId .. "\nCheck app settings in cloud-app-info.lua"
    end
    self.logger:error(errorCode, errorMsg)
    lastErrMess = errorMsg;
end

function client:onEvent(code, content, actorNr)
   if(enemyTank and enemyTank.isOn)then
        if(code == 9 and content.userId ~= userId)then
            print("SHOOT BULLET")
            enemyTank.barrel.rotation = content.rotation
            enemyTank:shootBullet()
        elseif(content.x and content.userId ~= userId)then --not nil and isn't the local player, set position of enemy
           -- print("ACTOR ID IS ".. content.userId)
           -- print(" x = "..content.x)
           -- print(" y = "..content.y) 
            enemyTank.movementJoint:setTarget( content.x, content.y )
            enemyTank.barrel.rotation = content.barrelRotation

           -- print("ROTATION = "..content.rotation)
            if(content.rotation > 360)then content.rotation = content.rotation - 360 end
            if(content.rotation < 0)then content.rotation = content.rotation + 360 end
           -- print("Revised Rotation = "..content.rotation)

            --enemyTank.botSprite.rotation = content.rotation

             transition.to( enemyTank.botSprite, {rotation = content.rotation, time = 200} )

            if(content.health)then
                enemyTank.health = content.health
                enemyTank:updateHealth()
            end
            
        end
    end

    if(code == 7 and content.isDead == true)then
        enemyTank:die()
        client:raiseEvent(10,{winner = userId},{ receivers = LoadBalancingConstants.ReceiverGroup.All })
    end

    if(code == 10)then

        pauseButton.isActive = false
        local imageToLoad

        if(content.winner == userId)then
            imageToLoad = "victory.png"
        else
            imageToLoad = "defeat.png"
        end

        endLogo = display.newImage(imageToLoad)
        endLogo.x = display.contentWidth/2
        endLogo.y = 100
        endLogo.width = 300
        endLogo.height = 300
        endLogo.alpha = 0 

        timer.performWithDelay( 1000, function() 

            transition.to( endLogo, {transition = easing.outBack, alpha = 1, y = 150, onComplete = function()
                timer.performWithDelay( 1000, function()
                    transition.to( endLogo, {alpha = 0, width = 400, height = 400, y = 100, onComplete = function()
                        endLogo:removeSelf()


                                    if(game.isMultiplayer)then
                                        cleanupMultiplayer()
                                    end
                                    timer.performWithDelay( 500,function()
                                        destroyPracticeArena(true)
                                    end)
                    end} )
                end )
             
            end} )
        end)
    end

    if(code == 2 )then
        startRound(content)
    end

end

function startRound(content)

    black = display.newRect( 0,0,100000,100000)
    black:setFillColor( 0,0,0 )
    physics.pause()
    if(game.didCreateRoom)then
            userTank.botSprite.x = content.player1x 
            userTank.botSprite.y = content.player1y
        else
            userTank.botSprite.x = content.player2x 
            userTank.botSprite.y = content.player2y
        end

        battleLogo = display.newImage("battleLogo.png")
        battleLogo.x = display.contentWidth/2
        battleLogo.y = 100
        battleLogo.width = 300
        battleLogo.height = 300
        battleLogo.alpha = 0 

        timer.performWithDelay( 1000, function() 
            transition.to( black, {alpha = 0, time = 300, transition = easing.outExpo} )

            transition.to( battleLogo, {transition = easing.outBack, alpha = 1, y = 150, onComplete = function()
                timer.performWithDelay( 1000, function()
                    circle = display.newCircle( display.contentWidth/2,150, 10 )
                    transition.to( circle, {alpha = 0,width = 400,height = 400} )
                    transition.to( battleLogo, {alpha = 0, width = 400, height = 400, y = 100, onComplete = function()
                        battleLogo:removeSelf()
                        circle:removeSelf()
                        black:removeSelf()
                        game.hasStarted = true
                        physics.start()
                    end} )
                end )
             
            end} )
        end)
end

local textObject
if display then
    
end

client.mState = "Init"
client.mLastSentEvent = ""
client.mSendCount = 0
client.mReceiveCount = 0
client.mLastReceiveEvent= ""
client.mRunning = true
client.stateInt = 0

function client:update()
    --self:sendData()
    self:service()
end

function client:sendData()
    if self:isJoinedToRoom() and self.mSendCount < MAX_SENDCOUNT then
        self.mState = "Data Sending"    
        local data = {}
        self.mLastSentEvent = "e" .. self.mSendCount
        data[2] = self.mLastSentEvent
        data[3] = string.rep("x", 160)
        self:raiseEvent(EVENT_CODE, data, { receivers = LoadBalancingConstants.ReceiverGroup.All } ) 
        self.mSendCount = self.mSendCount + 1
        if self.mSendCount >= MAX_SENDCOUNT then
            self.mState = "Data Sent"
        end
    end
end

function client:getStateString()
    return LoadBalancingClient.StateToName(self.state) --.. "\n\nevents: " .. self.mState .."\nsent "..self.mLastSentEvent..", total: ".. self.mSendCount .. "\nreceived "..self.mLastReceiveEvent .. ", total: " .. self.mReceiveCount 
      --  .. "\n\n" .. lastErrMess
end

local prevStr = ""

function client:timer(event)
    local str = nil
    self.logger:trace("quant")
    if self.mRunning then
        self:update()
    else
        timer.cancel(event.source)
        self.mState = "Stopped"
    end

    str = client:getStateString()
    if(prevStr ~= str) then
        prevStr = str
        print("\n\n")        
        print(str)
        if display then
            textObject.alpha = 1
            textObject.text = str
            transition.to(textObject, {alpha = 0, time = 2000, transition = easing.inQuint })

     
        end
    end

end

if display then
    client.logger:info("Start")
    timer.performWithDelay( 2, client, 0)
else
    while true do
        client:timer()
        socket.sleep(0.1)
    end
end

function client:onActorJoin (actor)
    print("A NEW PLAYER HAS JOINED THIS ROOM")
    actors = client:myRoom().playerCount
    print("PLAYER COUNT: ".. actors)


    if(game.didCreateRoom)then
        hideWaitingForPlayersNotification()
        --client:raiseEvent(1, "HELLO WORLD", { receivers = LoadBalancingConstants.ReceiverGroup.All } ) 
        timer.performWithDelay( 1000, function()
            client:raiseEvent(2, {state = "initGame", player1x = 700, player1y = 300, player2x = 2071, player2y = 300},{ receivers = LoadBalancingConstants.ReceiverGroup.All }  )
        end )
    end
    
end


function attemptToJoinMultiplayer()
        game.didCreateRoom  = false
        client:joinRandomRoom()
end

function cleanupMultiplayer()
    print("cleaning up multiplayer")
    client:leaveRoom()


    timer.performWithDelay( 1000, function()
       composer.removeScene( "multiplayerLobby" , false )
        client:reset (true)

        composer.removeScene( "multiplayerGame" , false )
    end )
    --composer.gotoScene( "menu"  )
end


function openSearchOverlay(action)

     function closeSearchOverlay(initialYOffset, speed)

        local initialYOffset = 100
        local speed = 400


        if(Pbg == nil or spinner == nil)then 
            return 
        end

        spinner:removeSelf()
        spinner = nil
        transition.to( Pbg, {alpha = 0} )
        transition.to( bgPanel, {alpha = 0,y = bgPanel.y + initialYOffset, transition = easing.outBack, time = speed} )
        transition.to( exitButton, {alpha = 0, y = exitButton.y + initialYOffset, transition = easing.outBack, time = speed} )
        transition.to( graphicsButton, {alpha = 0, y = graphicsButton.y + initialYOffset, transition = easing.outBack, time = speed} )
        transition.to( exitText, {alpha = 0, y = exitText.y + initialYOffset, transition = easing.outBack, time = speed} )
        transition.to( graphicsText, {alpha = 0, y = graphicsText.y + initialYOffset, transition = easing.outBack, time = speed} )
        transition.to( logo, {alpha = 0, y = logo.y + initialYOffset, transition = easing.outBack, time = speed} )
        transition.to( backButton, {alpha = 0, y = backButton.y + initialYOffset, transition = easing.outBack, time = speed} )
        transition.to( backText, {alpha = 0, y = backText.y + initialYOffset, transition = easing.outBack, time = speed} )
        --transition.to( spinner, {alpha = 0, y = spinner.y + initialYOffset, transition = easing.outBack, time = speed} )


        timer.performWithDelay( speed, function()

            if(Pbg)then
                Pbg:removeSelf()
                --spinner:removeSelf()
                bgPanel:removeSelf()
                exitButton:removeSelf()
                graphicsButton:removeSelf()
                exitText:removeSelf()
                graphicsText:removeSelf()
                logo:removeSelf()

                Pbg = nil 
                bgPanel = nil 
                spinner = nil
                exitButton = nil 
                graphicsButton = nil 
                exitText = nil 
                graphicsText = nil 
                logo = nil 
            end

            if(pauseButton)then
                pauseButton.isActive = true
            end

            findMatchButton:setEnabled( true )

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

    spinner = widget.newSpinner( {} )
    spinner.x = display.contentWidth/2
    spinner.y = display.contentHeight + 190
    spinner:start()


    backText = display.newText( {
        text = "Searching..." ,
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


    if(action == nil)then
         action = "Searching..."
    end

    exitText = display.newText( {
        text = action ,
        x =  display.contentWidth/2,
        y =  240 + initialYOffset , 
        width = 170, 
        height = 20,  
        fontSize = 15 ,
        align = "center"} )

    local spinnerOptions = {
        width = 128,
        height = 128,
        numFrames = 1,
        sheetContentWidth = 128,
        sheetContentHeight = 128
    }
    local spinnerSingleSheet = graphics.newImageSheet( "spinner.png", spinnerOptions )
     
    -- Create the widget
     spinner = widget.newSpinner(
        {
            width = 100,
            height = 100,
            sheet = spinnerSingleSheet,
            startFrame = 1,
            deltaAngle = 10,
            incrementEvery = 15
        }
    )
    spinner.x = display.contentWidth/2
    spinner.y = 160 + initialYOffset
     
    spinner:start()
    spinner.alpha = 0

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
    --transition.to( graphicsButton, {alpha = .5, y = graphicsButton.y - initialYOffset, transition = easing.outBack, time = speed} )
    transition.to( exitText, {alpha = 1, y = exitText.y - initialYOffset, transition = easing.outBack, time = speed} )
    transition.to( spinner, {alpha = 1, y = spinner.y - initialYOffset, transition = easing.outBack, time = speed} )

    --transition.to( graphicsText, {alpha = 1, y = graphicsText.y - initialYOffset, transition = easing.outBack, time = speed} )
    transition.to( logo, {alpha = 1, y = logo.y - initialYOffset, transition = easing.outBack, time = speed} )
    --transition.to( backButton, {alpha = 1, y = backButton.y - initialYOffset, transition = easing.outBack, time = speed} )
    --transition.to( backText, {alpha = 1, y = backText.y - initialYOffset, transition = easing.outBack, time = speed} )

    local function graphicsToggle(e)
        system.vibrate()

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
        system.vibrate()
        if(e.phase == "ended")then
            timer.performWithDelay( speed + 100,function()

            end)
        end
    end

    local function backButtonTouch(e)
        system.vibrate()

        if(e.phase == "ended")then
            backButton:removeEventListener( "touch", backButtonTouch )
            closeSearchOverlay(initialYOffset, speed)
            
        end
    end

    timer.performWithDelay( 5000, function()
        if(client:isJoinedToRoom() == false)then

            if(finalCreateButton.alpha == .5 or finalCreateButton == 1)then
                nameField.alpha = 1
            end
            client:reset()
            client:connectToRegionMaster("US")
            closeSearchOverlay(initialYOffset,speed)
        end
    end)
end




local function hideMultiplayerLobby()
     transition.to( findMatchButton, {transition = easing.outBack, y = 280, alpha = 0, time = 500})
     transition.to(createGameButton, {transition = easing.outBack, y = 280 , alpha = 0, time = 500})
     transition.to( joinGameButton, {transition = easing.outBack, y = 280 , alpha = 0, time = 500} )
     transition.to( groupPanel, {transition = easing.outBack, y = 280 , alpha = 0, time = 500} )

end


function scene:create( event )
 
    local sceneGroup = self.view

    menuBg = display.newImage("menuBg.png")
    menuBg.alpha = 1

    sceneGroup:insert(menuBg)

    logo = display.newImage("multiplayerLogo.png")
    logo.width = 350/2
    logo.height = 350/2
    logo.alpha = 1

    logo.x = display.contentWidth/2
    logo.y = 50

    textObject = display.newText("", 0, 280, 240, 30, native.systemFont, 12)
    textObject:setFillColor(1,1,1)
    textObject.align = "right"
    textObject.anchorX = 0
    textObject.anchorY = 0
    textObject.alpha = 1

   -- timer.performWithDelay( 100, client, 0)

    findMatchButton = widget.newButton(
    {
        width = 800/5,
        height = 400/5,
        defaultFile = "findMatchButton.png",
        overFile = "findMatchButton2.png",
       -- label = "button",
        onEvent = function(e)
            if(e.phase == "ended")then
                findMatchButton:setEnabled(false)
                openSearchOverlay()
                attemptToJoinMultiplayer()
                        
            end
        end
    })

     createGameButton = widget.newButton(
    {
        width = 800/6,
        height = 400/6,
        defaultFile = "private.png",
        overFile = "private2.png",
       -- label = "button",
        onEvent = function(e)
            if(e.phase == "ended")then
                hideMultiplayerLobby()
                transition.to( nameField, {alpha = 1, y =100, transition = easing.outBack} )
                transition.to( finalCreateButton, {alpha = 1, transition = easing.outBack, x = display.contentWidth/2 + 200} )


            end
        end
    })

    joinGameButton = widget.newButton(
    {
        width = 800/6,
        height = 400/6,
        defaultFile = "joinPrivate.png",
        overFile = "joinPrivate2.png",
       -- label = "button",
        onEvent = function(e)
            if(e.phase == "ended")then
                hideMultiplayerLobby()
                transition.to( nameField, {alpha = 1, y =100, transition = easing.outBack} )
                transition.to( joinPrivateButton, {alpha = 1, transition = easing.outBack, x = display.contentWidth/2 + 200} )

            end
        end
    })


    backButton = widget.newButton(
    {
        
        defaultFile = "backButton.png",
        overFile = "backButton2.png",
        width = 800/8,
        height = 400/8,
        --label = "back",
        onEvent = function(e)
            if(e.phase == "ended")then
               composer.gotoScene( "menu" )
            end
        end
    })

    backButton.alpha = .7
    backButton.x = 30
    backButton.y = 50

    nameField = native.newTextField( display.contentWidth/2, -50, 220, 30 )
    nameField.placeholder = "Enter Match Name "
    nameField.alpha = 0
    nameField.text = ""

    finalCreateButton = widget.newButton(
            {
                width = 800/6,
                height = 400/6,
                defaultFile = "createMatch.png",
                overFile = "createMatch2.png",
               -- label = "button",
                onEvent = function(e)
                    if(e.phase == "ended")then
                        if(nameField.text ~= "")then
                            finalCreateButton:setEnabled(false)
                            finalCreateButton.alpha = .5
                            openSearchOverlay("Creating Match")
                            nameField.alpha = 0 
                            game.didCreateRoom = true

                            client:createRoom (nameField.text, {maxPlayers = 2, isVisible = false})

                        else
                            native.showAlert( "Take a second look", "You must enter a name for the match" , {"Ok"} )

                        end
                    end
                end
    })



    finalCreateButton.alpha = 0
    finalCreateButton.x = display.contentWidth/2 + 400
    finalCreateButton.y = 100

    findMatchButton.x = display.contentWidth/2 - 80
    findMatchButton.y = 320

    findMatchButton.alpha = 0
    findMatchButton:setEnabled(false)

    joinPrivateButton = widget.newButton(
            {
                width = 800/6,
                height = 400/6,
                defaultFile = "joinMatch.png",
                overFile = "joinMatch2.png",
               -- label = "button",
                onEvent = function(e)
                    if(e.phase == "ended")then
                        if(nameField.text ~= "")then
                            joinPrivateButton:setEnabled(false)
                            joinPrivateButton.alpha = .5
                            --openSearchOverlay("Joining "..nameField.text)
                            nameField.alpha = 0 
                            game.didCreateRoom = false

                            client:joinRoom (nameField.text, {createIfNotExists = false})

                        else
                            native.showAlert( "Take a second look", "You must enter the name of the match" , {"Ok"} )

                        end
                    end
                end
    })



    joinPrivateButton.alpha = 0
    joinPrivateButton.x = display.contentWidth/2 + 400
    joinPrivateButton.y = 100


    createGameButton.x = display.contentWidth/2 + 80
    createGameButton.y = 320
    createGameButton.alpha = 0 
    createGameButton:setEnabled(false )

    joinGameButton.x = display.contentWidth/2 + 80
    joinGameButton.y = 350
    joinGameButton.alpha = 0 
    joinGameButton:setEnabled(false )


     --[[
    rightRect = display.newRoundedRect( display.contentWidth/2 + 100, 200,160,160 , 20 ) 
    rightRect.alpha = 0

    leftRect = display.newRoundedRect( display.contentWidth/2 - 100, 200,160,160 , 20 ) 
    leftRect.alpha = 0

    leftNameText = display.newText( "", display.contentWidth/2 - 60, 200, 160, 30, 18 )
    leftNameText.align = "center"
    leftNameText:setFillColor( 0,0,0 ) ]]--

    groupPanel = display.newRoundedRect( display.contentWidth/2 - 7, 230, 320, 115, 15 )
    groupPanel.alpha = .5


    sceneGroup:insert(backButton)
    sceneGroup:insert(groupPanel)
    sceneGroup:insert(textObject)
    sceneGroup:insert(findMatchButton)
    sceneGroup:insert(createGameButton)
    sceneGroup:insert(joinGameButton)
    sceneGroup:insert(finalCreateButton)
    sceneGroup:insert(nameField)
    sceneGroup:insert(joinPrivateButton)
    sceneGroup:insert(logo)

    --sceneGroup:insert(rightRect)
    --sceneGroup:insert(leftRect)
    --sceneGroup:insert(leftNameText)
    --multiplayerButton:setEnabled(false )

end
 
function fillPlayerBox(isLocalPlayer, name)
    if(isLocalPlayer)then
        leftRect.alpha = 1
        leftNameText.text = name
    end
end

-- show()
function scene:show( event )
 
    local sceneGroup = self.view
    local phase = event.phase
 
    if ( phase == "will" ) then

        -- Code here runs when the scene is still off screen (but is about to come on screen)
 
    elseif ( phase == "did" ) then

        --  facebook.login( { "public_profile"} )

           findMatchButton.y = 350
           findMatchButton.alpha = 0

          local yShift = 60

           transition.to( findMatchButton, {transition = easing.outBack, y = 230 - yShift, alpha = .5, time = 500})
           transition.to(createGameButton, {transition = easing.outBack, y = 210 - yShift, alpha = .5, time = 700})
           transition.to( joinGameButton, {transition = easing.outBack, y = 260 - yShift, alpha = .5, time = 800} )
           transition.to( groupPanel, {transition = easing.outBack, y = 175, alpha = .5, time = 800} )

            timer.performWithDelay( 500, function()
                client:reset()
                client:connectToRegionMaster("US")
            end )

            timer.performWithDelay( 1000, function()
                
              --  fillPlayerBox(true,"Chase's Tank")
            end )
        -- Code here runs when the scene is entirely on screen


    end
end
 
 
-- hide()
function scene:hide( event )
 
    local sceneGroup = self.view
    local phase = event.phase
 
    if ( phase == "will" ) then
       -- facebook.request( "me", "GET", {"first_name"} )

        -- Code here runs when the scene is on screen (but is about to go off screen)
 
    elseif ( phase == "did" ) then
        composer.removeScene( "multiplayerLobby" , false )
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