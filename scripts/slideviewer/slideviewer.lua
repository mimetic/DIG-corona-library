-- slider.lua
--
-- Version 0.1
--
-- Copyright (C) 2015 David I. Gross. All Rights Reserved.
--
--[[
Permission is hereby granted, free of charge, to any person obtaining a copy of
this software and associated documentation files (the "Software"), to deal in the
Software without restriction, including without limitation the rights to use, copy,
modify, merge, publish, distribute, sublicense, and/or sell copies of the Software,
and to permit persons to whom the Software is furnished to do so, subject to the
following conditions:

The above copyright notice and this permission notice shall be included in all copies
or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED,
INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR
PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE
FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR
OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER
DEALINGS IN THE SOFTWARE.
--]]

--

-- TESTING
local testing = false

-- Main var for this module
local S = {}

local pathToModule = "scripts/slideviewer/"
S.path = pathToModule


-- Corona Widgets
local widget = require ("widget")

-- DMC Widgets
local Widgets = require 'scripts.dmc.dmc_widget'

local funx = require ("scripts.funx")

local json = require("json")

-- functions
local max = math.max
local min = math.min
local lower = string.lower
local upper = string.upper
local gmatch = string.gmatch
local gsub = string.gsub
local strlen = string.len
local substring = string.sub
local find = string.find
local floor = math.floor
local gfind = string.gfind

-- shortcuts to my functions
local anchor = funx.anchor
local anchorZero = funx.anchorZero
local trim = funx.trim
local rtrim = funx.rtrim
local ltrim = funx.ltrim
local stringToColorTable = funx.stringToColorTable
local setFillColorFromString = funx.setFillColorFromString
local split = funx.split
local setCase = funx.setCase
local fixCapsForReferencePoint = funx.fixCapsForReferencePoint

-- Useful constants
local OPAQUE = 255
local TRANSPARENT = 0

print( "\n\n#########################################################\n\n" )



--===================================================================--
--== Imports


local Widgets = require 'scripts.dmc.dmc_widget'



--===================================================================--
--== Setup, Constants


local W,H = display.contentWidth, display.contentHeight
local H_CENTER, V_CENTER = W*0.5, H*0.5

-- Default position on screen of center of viewer
-- if no x,y is given
local OFFSET = 100



--===================================================================--
--== Support Functions


-- onRender()
-- called when table view needs to display a row
--
local function onRender( event )
	-- print( 'Main:onRender' )

	local view = event.view
	local slide_data = event.data
	local index = slide_data.idx
	-- A display object to show
	local slide = slide_data.slide
	
	-- If there is a display object for this slide, then
	-- insert it, centered.
	if (slide) then
		view:insert(slide)
		view._slide = slide
		slide.anchorX, slide.anchorY = 0,0
		-- it's possible this display was stored and hidden
		-- while the row was unrendered.
		slide.isVisible = true
		slide.x = event.target.margins.left or 0
		slide.y = event.target.margins.top or 0
	end
	
--	local o
--	o = display.newText( tostring(index), 40,30, native.systemFont, 32)
--	o.anchorX, o.anchorY = 0.5,0
--	view:insert( o )
--
--	view._o = o

	

end

-- onUnrender()
-- called when table view needs to destroy a row
--
local function onUnrender( event )
	-- print( 'Main:onUnrender' )

	local view = event.view
	
	-- Copy the slide's embedded display object ('slide') to stage for storage
	-- Hide it.
	display.currentStage:insert(view._slide)
	view._slide.isVisible = false
	view._slide = nil

--	local o = view._o
--	o:removeSelf()
--
--	view._o = nil

end

--===================================================================--
-- Main
--===================================================================--

-- create Slide View

function S.new( options )

	local mySlideViewer
	
			local function onEvent( event )

				local etype = event.type
				local sv = event.target -- our scroll view

				if etype == sv.ITEMS_MODIFIED then
					--print( "slideviewer:onEvent: Items Modified" )
				elseif etype == sv.ITEM_SELECTED then
					local slide_data = event.data
					--print( "slideviewer:onEvent: Item Selected", event.index, event.slide )
					--print( "slideviewer:onEvent: >data ", slide_data.idx, slide_data.str )
				elseif etype == sv.TAKE_FOCUS then
					--print( "slideviewer:onEvent: Take Focus" )
				elseif etype == sv.SCROLLING then
					--print( "slideviewer:onEvent: View Scrolling", event.x, event.y, event.velocity )
				elseif etype == sv.SCROLLED then
					--print( "slideviewer:onEvent: View Scrolled", event.x, event.y, event.velocity )

				elseif etype == sv.SLIDE_IN_FOCUS then
					local slide_data = event.data
		
					-- Update the navbar
					-- On startup, this may be called before the navbar has been attached.
					if (mySlideViewer._navbar) then
						mySlideViewer._navbar:setSelected( slide_data.index )
					else
						--print ("No navbar")
					end
					
--					print( "slideviewer:onEvent: Slide in Focus", slide_data.index, slide_data.slide )
--					print( "slideviewer:onEvent: Item Selected", slide_data.index, slide_data.slide )
--					print( "slideviewer:onEvent: >data ", slide_data.idx, slide_data.str )
				else
					--print( "slideviewer:onEvent: onEvent", event.type )
				end

			end


	local width = options.width or W-OFFSET
	local height = options.height or H-OFFSET
	
	if (options.automask == nil) then
		options.automask = true
	end
	
	mySlideViewer = Widgets.newSlideView{
		width 	= width,
		height 	= height,
		-- Mask the slides to display inside the viewer frame
		automask = options.automask,
		-- offset inside the frame of the viewer.
		-- y moves slides down.
		-- x doesn't seem to do anything
		x_offset = 0,
		y_offset = 0,
		bgColor = options.backgroundColor or {0,0,0,0},
		autoAdvanceTime = options.autoAdvanceTime,
		autoAdvanceState = options.autoAdvance,
	}
	mySlideViewer.anchorX, mySlideViewer.anchorY = 0,0
	mySlideViewer.x, mySlideViewer.y = options.x or OFFSET*0.5, options.y or OFFSET*0.5

	mySlideViewer:addEventListener( mySlideViewer.EVENT, onEvent )



	return mySlideViewer
end


-- Add slides to a slideviewer. We do this after creation so the slides can reference the slideviewer, allowing
-- objects on the slides to pass focus!
-- This should be a method, but if we do that, we are adding too much to the widget_slideview.
function S.addSlides(mySlideViewer, options)

	-- create slides
	--for i,data in pairs(options.data) do
	for i,slide in pairs(options.slides) do
		
		local data = slide.data
		
		-- Hide display objects that will be shown.
		-- They will be made visible at the right time
		if (data.slide) then
			data.slide.isVisible=false
		end
		
		-- height of a slide can be less than the slide viewer window.
		-- width can be shorter, too, but it looks weird.
		local p = {
			onItemRender=onRender,
			onItemUnrender=onUnrender,
			onItemEvent=onEvent,
			
			isCategory = false,
			
			-- height/width cause problems if they're different from the viewer height/width
			--height = slide.height,
			--width = slide.width,
			-- margins control how the slide is positioned in its column
			-- in the viewer.
			margins = slide.margins or ( options.margins or {} ),
			bgColor = slide.backgroundColor or {},

			data = data,
		}

		mySlideViewer:insertSlide( p )

	end
end


-- Create a tab bar GUI for the slideshow
-- Note, this is a separate object you have to dispose of separately.
-- However, changes in the slideshow are reflected in the navbar

function S.newNavBar ( mySlideViewer, options )
	
	local slides = options.slides

	-- Function to handle button events
	local function handleTabBarEvent( event )
		--print( "slideviwer:newNavBar:handleTabBarEvent: event.target._id",event.target._id)  --reference to button's 'id' parameter
		mySlideViewer:do_scroll_to_slide( event.target._id )
	end

	local buttons = {}
	local selected = 1
	for i,s in pairs(slides) do
	
		--Build tabs using either category slides or all slides
		if (options.type ~= "categories" or s.data.isCategory) then
			local tab = {
				width = options.tabWidth, 
				height = options.tabHeight,
				defaultFile = options.defaultFile,
				overFile = options.overFile,
				label = s.data.title,
				id = s.data.idx,
				selected = (i == selected),
				size = options.fontSize,
				font = options.font,
				labelColor = options.labelColor,
				labelYOffset = options.labelYOffset or -8,
				onPress = handleTabBarEvent,
			}

			buttons[#buttons+1] = tab
		end
	end

	-- Create the widget
	options.buttons = buttons

	local tabBar = widget.newTabBar( options )
	tabBar.anchorX, tabBar.anchorY = 0,0
	tabBar.x, tabBar.y = options.left, options.top
	
	-- Attach the navbar to the slideview, so the slideview can tell it when to change
	-- if user goes to a new slide
	mySlideViewer._navbar = tabBar

	return tabBar
	
end


return S