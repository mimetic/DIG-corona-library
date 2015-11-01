
-- Abstract: physics-water main
-- Version: 1.0
-- Sample code is MIT licensed; see https://www.coronalabs.com/links/code/license
---------------------------------------------------------------------------------------

local funx = require ("scripts.funx")

-- Set up physics engine
local physics = require( "physics" )


-- TESTING:
local testing = false


----------------------------------------------------------------------------------
local min = math.min
local max = math.max
local random = math.random
local floor = math.floor
local lower = string.lower

----------------------------------------------------------------------------------
-- MODULE TABLE
local WATER = {}

----------------------------------------------------------------------------------
local pathToModule = "scripts/physics-water/"

----------------------------------------------------------------------------------
-- GAME ID, USED TO IDENTIFY THING RELATED TO THIS GAME
local gameID = "physics-water"

function WATER.new()

	
	----------------------
	-- NEW OBJECT TABLE
	----------------------
	local instance = {
		view = {},
	}

	instance.gameID = gameID
	instance._conflicts = {}
	
	instance.displaygroup = display.newGroup()


	------------------------------
	-- REMOVESELF()
	------------------------------
	-- Remove objects AND handlers, e.g. the particle water handler!
	-- Note the board is also part of EcosystemGame, i.e. EcosystemGame.view
	local function _removeSelf(me)
		print ("remove me:",me.test)	
		if (me.onEnterFrame) then
			Runtime:removeEventListener( "enterFrame", me.onEnterFrame )
		end

		me.particleSystem:removeSelf()
		me.particleSystem = nil
		me.displaygroup:removeSelf()
		me.displaygroup = nil
		-- Remove the table itself
		me = nil
	end
	instance._removeSelf = _removeSelf


	------------------------------
	-- OPEN PAGE ()
	------------------------------
	local function _openPage(me)
		--instance:_openPage( )
	end
	instance._openPage = _openPage




	------------------------------
	-- LEAVE PAGE ()
	------------------------------
	local function _leavePage(me)
		--instance:_leavePage( )
	end
	instance._leavePage = _leavePage



	------------------------------
	-- INIT ()
	------------------------------
	function instance:init()
		------------------------------
		-- CONFIGURE STAGE
		------------------------------
		local displaygroup = display.newGroup()

		physics.start()
		physics.setGravity( 0,9.8 )
		physics.setDrawMode( "normal" )
		
		-- Show the mixer object the user can use to mix up the water
		local mixerIsActive = true
		local mixer

		-- Declare initial variables
		local screenW, screenH = display.contentWidth, display.contentHeight
		local letterboxWidth = (display.actualContentWidth-display.contentWidth)/2
		local letterboxHeight = (display.actualContentHeight-display.contentHeight)/2

		local waterW = display.contentWidth+letterboxWidth
		local waterH = display.contentHeight

		local waterBoundaryOutline = graphics.newOutline( 2, "_user/plugin/ecosystem-game/tidepool/water-boundary.png" )

		local waterBoundary = {}
		for i = 1, #waterBoundaryOutline-1, 2 do
			waterBoundary[i] = waterBoundaryOutline[i] - display.contentCenterX
			waterBoundary[i+1] = waterBoundaryOutline[i+1] - display.contentCenterY
		end
		
		-- For some reason, <30 doesn't work. Too many points, perhaps?
		local waterShapeOutline = graphics.newOutline( 30, "_user/plugin/ecosystem-game/tidepool/water-shape.png" )
		local waterShape = {}
		for i = 1, #waterShapeOutline-1, 2 do
			waterShape[i] = waterShapeOutline[i] - display.contentCenterX
			waterShape[i+1] = waterShapeOutline[i+1] - display.contentCenterY
		end

--[[
		-- TESTING
		local poly = display.newPolygon( display.contentCenterX, display.contentCenterY, waterShapeOutline )
		poly.strokeWidth = 10
		poly:setStrokeColor( 25, 250, 0, 50)
		poly:setFillColor( 255,0,0, 50)
--]]
		local boundary = display.newRect(displaygroup, 0,0, 100,100 )
		boundary.x, boundary.y = display.contentCenterX, display.contentCenterY
		boundary:setFillColor (255,0,0,0)
		physics.addBody( boundary, "static",
			{
				chain = waterBoundary,
				connectFirstAndLastChainVertex = false,
			}
		)
		boundary.isSleepingAllowed = true



		-- Create our stirring object
		-- This can be moved to stir the water!
		if (mixerIsActive) then
			mixer = display.newImageRect( displaygroup, pathToModule.."hero.png", 64, 64 )
			mixer.x = display.contentCenterX
			mixer.y = display.contentCenterY
			physics.addBody( mixer, { density=0.3, friction=0.3, bounce=0.2, radius=30 } )
			mixer:applyTorque( 100 )
			mixer.isSleepingAllowed = true

			-- Make mixer draggable via a touch handler and physics touch joint
			local function dragBody( event )
				local body = event.target
				local phase = event.phase
				if ( "began" == phase ) then
					display.getCurrentStage():setFocus( body, event.id )
					body.isFocus = true
					body.tempJoint = physics.newJoint( "touch", body, event.x, event.y )
					body.isFixedRotation = true
				elseif ( body.isFocus ) then
					if ( "moved" == phase ) then
						body.tempJoint:setTarget( event.x, event.y )
					elseif ( "ended" == phase or "cancelled" == phase ) then
						display.getCurrentStage():setFocus( body, nil )
						body.isFocus = false
						event.target:setLinearVelocity( 0,0 )
						event.target.angularVelocity = 0
						body.tempJoint:removeSelf()
						body.isFixedRotation = false
					end
				end
				return true
			end
			mixer:addEventListener( "touch", dragBody )
		end


		-- Create the LiquidFun particle system for the water
		local particleSystem = physics.newParticleSystem{
			filename = pathToModule.."liquidParticle.png",
		--	radius = 3,
		--	imageRadius = 5,
			radius = 18,
			imageRadius = 30,
			gravityScale = 1,
			strictContactCheck = true,
			--staticPressureIterations = 4,
			--viscousStrength = 1,
		}

		-- Create a "block" of water (LiquidFun group)
		-- 'tensile' is cooler than 'water' for the flag
		particleSystem:createGroup(
			 {
				 flags = { "tensile"},
				 x = waterShapeOutline[1],--display.contentCenterX,
				 y = waterShapeOutline[2],--display.contentCenterY,
				 color = { 0, 0.6, 0.6, 1 },
				 outline = waterShape,
			 }
		)


		particleSystem:createGroup(
			 {
				 flags = { "tensile"},
				 x = waterShapeOutline[1],--display.contentCenterX,
				 y = waterShapeOutline[2],--display.contentCenterY,
				 color = { 0, 0.5, 0.7, 0.8 },
				 outline = waterShape,
			 }
		)

		-- Initialize snapshot for full screen
		local snapshot = display.newSnapshot( displaygroup, screenW+letterboxWidth+letterboxWidth, screenH+letterboxHeight+letterboxHeight )
		local snapshotGroup = snapshot.group
		snapshot.x = display.contentCenterX
		snapshot.y = display.contentCenterY
		snapshot.canvasMode = "discard"
		snapshot.alpha = 0.5

		-- Apply a "sobel" filter to portray the visible surface of the water
		--snapshot.fill.effect = "filter.sobel"

		-- Insert the particle system into the snapshot
		snapshotGroup:insert( particleSystem )
		snapshotGroup.x = -display.contentCenterX
		snapshotGroup.y = -display.contentCenterY

		-- Bring mixer to front of its display group
		if (mixerIsActive) then
			mixer:toFront()
		end

		------------------------------
		-- Update (invalidate) the snapshot each frame
		function self.onEnterFrame( event )
			snapshot:invalidate()
		end
		
		------------------------------
		-- Add tilt gravity
		-- This value is always relative to the device in portrait orientation, regardless of the current orientation of your application. So, if your application is running in landscape mode, you'll need to compensate by 90 degrees.

-- TESTING
-- t = display.newText("X,Y", 250,50, native.systemFontBold, 24)


		function self.onAccelerate( event )
			-- reverse x,y because we are displaying landscape
			physics.setGravity( -9.8 * event.yGravity, 9.8 )
			--TESTING:
			--t.text = "Gravity: gx, gy: ".. -9.8 * gy  .. ", " .. 9.8
		end
		
		
		
		
		-- Begin with this system paused!
		particleSystem.particlePaused = true

		-- Expose displaygroup for removal
		self.view = displaygroup
		self.mixer = mixer
		self.particleSystem = particleSystem
	end	-- init()
	
	
	
	------------------------------
	function instance:resume()
		if (self.onEnterFrame) then
			Runtime:addEventListener( "enterFrame", self.onEnterFrame )
		end
		
		if (self.onAccelerate) then
			Runtime:addEventListener( "accelerometer", self.onAccelerate )
		end
		if (mixerIsActive) then
			transition.to (self.mixer, {x = display.contentCenterX, y = 50, time=1500})
			self.mixer:applyTorque( 100 )
		end
		
		self.particleSystem.particlePaused = false
	end -- start()


	------------------------------
	function instance:pause()
		if (self.onEnterFrame) then
			Runtime:removeEventListener( "enterFrame", self.onEnterFrame )
		end
		if (self.onAccelerate) then
			Runtime:removeEventListener( "accelerometer", self.onAccelerate )
		end

		--transition.to (self.mixer, {x = display.contentCenterX, y = display.contentCenterY, time=1000})
		self.particleSystem.particlePaused = true
	end -- stop()

	return instance
	
end -- new()


return WATER