--====================================================================--
-- Slideviewer example
--
-- Shows use of the DIG Widget, sliderviewer, which uses the DMC Widget: Slide View
--
-- Sample code is MIT licensed, the same license which covers Lua itself
-- http://en.wikipedia.org/wiki/MIT_License
-- Copyright (C) 2015 David Gross. All Rights Reserved.
-- Copyright (C) 2014 David McCuskey. All Rights Reserved.
--====================================================================--



--[[
	Demonstration of textrender.lua, a module for rendering styled text.


	textrender parameters:

	text = text to render
	font = font name, e.g. "AvenirNext-DemiBoldItalic"
	size = font size in pixels
	lineHeight = line height in pixels
	color = text color in an RGBa color table, e.g. {250, 0, 0, 255}
	width = Width of the text column,
	alignment = text alignment: "Left", "Right", "Center"
	opacity = text opacity (between 0 and 1, or as a percent, e.g. "50%" or 0.5
	minCharCount = Minimum number of characters per line. Estimate low, e.g. 5
	targetDeviceScreenSize = String of target screen size, in the form, "width,height", e.g. e.g. "1024,768".  May be different from current screen size.
	letterspacing = (unused)
	maxHeight = Maximum height of the text column. Extra text will be hidden.
	minWordLen = Minimum length of a word shown at the end of a line. In good typesetting, we don't end our lines with single letter words like "a", so normally this value is 2.
	textstyles = A table of text styles, loaded using funx.loadTextStyles()
	defaultStyle = The name of the default text style for the text block
	cacheDir = the name of the cache folder to use inside system.CachesDirectory, e.g. "text_render_cache"
--]]


local widget = require ( "widget" )

-- My useful function collection
local funx = require("scripts.funx")

local textrender = require("scripts.textrender.textrender")

-- Scripts for making the slideviewer and navigation bar
local slideviewer = require("scripts.slideviewer.slideviewer")


-- Make a local copy of the application settings global
local screenW, screenH = display.contentWidth, display.contentHeight
local viewableScreenW, viewableScreenH = display.viewableContentWidth, display.viewableContentHeight
local screenOffsetW, screenOffsetH = display.contentWidth -	 display.viewableContentWidth, display.contentHeight - display.viewableContentHeight
local midscreenX = screenW*(0.5)
local midscreenY = screenH*(0.5)

local w = screenW/2 - 50
--w = 270

local textStyles = funx.loadTextStyles("scripts/textrender/textstyles.txt", system.ResourceDirectory)

local mytext = funx.readFile("assets/slideviewer-sample-text.txt")
local mytext2 = funx.readFile("assets/text-render-sample.html")

-- To cache, set the cache directory
local cacheDir = "textrender_cache"
funx.mkdir (cacheDir, "",false, system.CachesDirectory)


local viewerWidth, viewerHeight = 400, 200
local viewerTop, viewerLeft = 50, 50
local margins = { top = 10, left = 10, bottom = 10, right = 10, }
local slideWidth = viewerWidth - margins.left - margins.right
local slideHeight = viewerHeight - margins.top - margins.bottom

local navbarHeight = 50


------------
-- Clear text caches for TESTING
-- We clear the cache before begining, so first render creates a cache, second uses it.
textrender.clearAllCaches(cacheDir)


-- ------------------------------------------
-- Page background
-- ------------------------------------------
local bkgd = display.newRect(0,0,screenW, screenH)
bkgd:setFillColor(1,1,1)
funx.anchor(bkgd,"TopLeftReferencePoint")
bkgd.x = 0
bkgd.y = 0
bkgd.strokeWidth = 20
bkgd:setStrokeColor(.2, .2, .2, 1)

------------------------------------------------------------
-- TESTING: text block for slides
------------------------------------------------------------

local function makeTextBlock( mytext, width, height)
	-- To prevent caching, set the cache dir to empty
	cacheDir = ""

	local params = {
		text =  mytext,	--loaded above
		
		width = width,
		maxHeight = height,

		isHTML = true,
		useHTMLSpacing = true,
		
		textstyles = textStyles,
		cacheToDB = true,	-- true is default, for fast caches using sql database

		-- Not needed, but defaults
		font = "AvenirNext-Regular",
		size = "12",
		lineHeight = "16",
		color = {0, 0, 0, 255},
		alignment = "Left",
		opacity = "100%",
		letterspacing = 0,
		defaultStyle = "Normal",

		-- The higher these are, the faster a row is wrapped
		minCharCount = 10,	-- 	Minimum number of characters per line. Start low. Default is 5
		minWordLen = 2,
		
		-- not necessary, might not even work
		targetDeviceScreenSize = screenW..","..screenH,	-- Target screen size, may be different from current screen size
		
		-- cacheDir is empty so we do not use caching with files, instead we use the SQLite database
		-- which is faster.
		cacheDir = "",
		cacheToDB = true,
	}


	params.cacheDir = ""
	params.cacheToDB = true

	t = textrender.autoWrappedText(params)
	
	return t
	
end


-- Supposedly, the database will be automatically closed when the app is closed.
if textrender.db and textrender.db:isopen() then
	textrender.db:close()
	print ("MAIN TESTING: Close DB. The textrender database was left open?")
end


--===================================================================--

-- functions called in buttons, below
local mySlideViewer

local function goPrevSlide()
	mySlideViewer._slideviewer:scroll_one_slide( "left" )	
end

local function goNextSlide()
	mySlideViewer._slideviewer:scroll_one_slide( "right" )
end


local function goFirstSlide()
	mySlideViewer._slideviewer:do_scroll_to_slide( "first" )
end


local function goLastSlide()
	mySlideViewer._slideviewer:do_scroll_to_slide( "last" )
end

local function removeShow()
	if (mySlideViewer) then
		mySlideViewer._slideviewer:removeSelf()
		mySlideViewer._navbar:removeSelf()
		mySlideViewer = nil
	end	
end

local function switchAutoAdvance( e )
	mySlideViewer._slideviewer:flip_auto_advance()
	if (mySlideViewer._slideviewer._autoAdvanceState) then
		e.target:setLabel( "Manual Advance" )
	else
		e.target:setLabel( "Auto Advance" )
	end
	
end


--===================================================================--
-- Build a slideviewer show.
--===================================================================--

local function newShow()

	local mySlideViewer, mySlideViewerNavbar, slideviewOptions, slideOptions, navbarOptions
	
	local show = {}
	
	--===================================================================--
	-- Create the slideviewer object
	--===================================================================--
	slideviewOptions = {
		width = viewerWidth, 
		height = viewerHeight,
		x = viewerLeft,	-- viewer x (top-left corner)
		y = viewerTop,	-- viewer y (top-left corner)
		backgroundColor = { 237/255, 243/255, 210/255, 1 },	-- viewer same color as the slides

		autoAdvanceTime = 2000,	-- two seconds
		autoAdvance = false,

		slides = slides,
		automask = true,	-- not full screen width
		
		navbar = mySlideViewerNavbar, -- the navigator for this viewer
	}

	-- Now, create our viewer
	mySlideViewer = slideviewer.new ( slideviewOptions )
	show._slideviewer = mySlideViewer


	--===================================================================--
	-- Create and add slides
	--===================================================================--
	local slides = {}
	local slideCount = 3
	for i=1, slideCount do
	
		-- A group to hold our slide image + text
		local g = display.newGroup()

		--===================================================================--
		-- Make a slide image
		--===================================================================--
		--[[
		-- Rect on a slide if you want it.
		local s = display.newRect(g, 0,0,slideWidth, slideHeight)
			s:setFillColor(237/255, 243/255, 210/255, 1)
			s.x = 0
			s.y = 0
			s.strokeWidth = 0
			s:setStrokeColor(0.2, .2, .2)
			s.anchorX, s.anchorY = 0,0
		--]]		
		--===================================================================--
		-- Sample image on the slide
		--===================================================================--

		local p = funx.loadImageFile("assets/slide-"..tostring(i)..".jpg")
		p.width, p.height = funx.getFinalSizes( slideWidth/2 - margins.left - margins.right, slideHeight, p.width, p.height, true)
		p.width, p.height = p.width, p.height
		p.alpha = 0.5
		g:insert(p)
		p.anchorX, p.anchorY = 0,0
		p.x = 0
		p.y = 0

	
		--===================================================================--
		-- Add some styled text to the slide
		-- See the params in "makeTextBlock".
		--===================================================================--
		local textblock = makeTextBlock( "<p class='title'>Slide #"..i.."<p>" .. mytext, slideWidth/2 - margins.left - margins.right, slideHeight-20)
		
		local options = {
			parentTouchObject = mySlideViewer,
			maxVisibleHeight = slideHeight - margins.top - margins.bottom,
			scrollingFieldIndicatorActive = false,
			hideBackground = true,
		}
		local scrollingblock = textblock:fitBlockToHeight( options )
	
		local yAdjustment = textblock.yAdjustment
		g:insert(scrollingblock)
		scrollingblock.x = slideWidth/2 + margins.left
		scrollingblock.y = margins.top + yAdjustment
		--===================================================================--

	
	
		--===================================================================--
		-- Category
		-- Here are sample values
		--[[
		local isCategory = (i == 3) or (i == 5) or (i == 8)
		--===================================================================--
		--]]


		--===================================================================--
		-- Data values for each slide
		--===================================================================--	
		local data = {
			idx = i, 
			str="our-data-#"..i,
			title = i,
			slide = g,
			isCategory = isCategory,
		}
	
	
		--===================================================================--
		-- add to slides table
		slides[#slides+1] = {
			data = data,
			backgroundColor = { 237/255, 243/255, 210/255, 1 },	-- viewer same color as the slides
			width = slideWidth,
			height = slideHeight,
			margins = margins,
		}
		--===================================================================--

	end --for


	slideOptions = {
		slides = slides,
		margins = margins, -- default margins for all slides 
	}	
	slideviewer.addSlides( mySlideViewer, slideOptions )


	--===================================================================--
	-- Create Navbar
	-- Do after slides are created, so we can refer to them.
	--===================================================================--
	navbarOptions = {
		type = "slides",	 -- "slides" | "categories"
	
		slides = slides,

		left = viewerLeft,
		top = viewerTop + viewerHeight + 20,
		width = viewerWidth,
		height = navbarHeight,

		fontSize = 18,
		font = "Helvetica-Bold",
		labelColor = { default={ 1, 1, 1, 1 }, over={ 1, 1, 1, 1 } },
		labelYOffset = -12,

		defaultFile = "assets/tabBarIconDef.png",
		overFile = "assets/tabBarIconOver.png",
		tabWidth = 50,
		tabHeight = navbarHeight,
		backgroundFile = "assets/tabBarBkgd.png",
		tabSelectedLeftFile = "assets/tabBarSelL.png",
		tabSelectedRightFile = "assets/tabBarSelR.png",
		tabSelectedMiddleFile = "assets/tabBarSelM.png",
		tabSelectedFrameWidth = 40,
		tabSelectedFrameHeight = 120,
		buttons = tabButtons,

	}
	mySlideViewerNavbar = slideviewer.newNavBar( mySlideViewer, navbarOptions  )

	show._navbar = mySlideViewerNavbar
	
	return show
	
	
end -- newShow()

-- If the show has been removed, we can recreate it.
local function recreateShow()
	if (not mySlideViewer) then
		mySlideViewer = newShow()
	end
end



mySlideViewer = newShow()

mySlideViewer._slideviewer:gotoSlide( 3 )

--===================================================================--
-- Slideviewer Methods:

-- Jumps to slide 2 (without animation)
-- mySlideViewer:gotoSlide(2)
--===================================================================--




--===================================================================--
-- Build a scrolling text field.
--===================================================================--

-- Green for scrolling text demo: 220, 234, 156 => 0.23, 0.92, 0.61

local x,y = 500,50
local w,h = 250, 600
local sw = 2
local padding = 10



-- Background
local textblockBkgd = display.newRect(x - sw - padding , y - sw - padding, w + sw + 2*padding, h + sw + 2*padding)
textblockBkgd:setFillColor( 0.86, 0.92, 0.61 )
funx.anchor(textblockBkgd,"TopLeftReferencePoint")
textblockBkgd.x = x - padding
textblockBkgd.y = y - padding
textblockBkgd.strokeWidth = sw
textblockBkgd:setStrokeColor( 0,0,0,1)


-- Set up the params
-- Here, we depend on the defaults
local params = {
	text = mytext2,	--loaded above
	font = "AvenirNext-Regular",
	size = "12",
	lineHeight = "16",
	color = {0, 0, 0, 255},
	width = w,
	alignment = "Left",
	opacity = "100%",
	minCharCount = 5,	-- 	Minimum number of characters per line. Start low.
	targetDeviceScreenSize = screenW..","..screenH,	-- Target screen size, may be different from current screen size
	letterspacing = 0,
	maxHeight = nil,	-- clear this for a scrolling field so it isn't chopped!
	minWordLen = 2,
	textstyles = textStyles,
	defaultStyle = "Normal",
	cacheDir = cacheDir,
	cacheToDB = true,
	isHTML = true,
	useHTMLSpacing = true,
	hyperlinkFillColor = "250,250,0,180",
	hyperlinkTextColor = "0,0,255,255",
	testing = false,
	cacheToDB = true,
}
local textblock = textrender.autoWrappedText(params)

	-- Make the textblock a scrolling text block
local options = {
	maxVisibleHeight = h,
	parentTouchObject = nil,
	
	hideBackground = true,
	backgroundColor = {1,1,1},	-- hidden by the above line
	
	-- Show an icon over scrolling fields: values are "over", "bottom", anything else otherwise defaults to top+bottom
	scrollingFieldIndicatorActive = true,
	-- "over", "bottom", else top and bottom
	scrollingFieldIndicatorLocation = "",
	-- image files
	scrollingFieldIndicatorIconOver = "scripts/textrender/assets/scrolling-indicator-1024.png",
	scrollingFieldIndicatorIconDown = "scripts/textrender/assets/scrollingfieldindicatoricon-down.png",
	scrollingFieldIndicatorIconUp = "scripts/textrender/assets/scrollingfieldindicatoricon-up.png",
	pageItemsFadeOutOpeningTime = 300,
	pageItemsFadeInOpeningTime = 500,
	pageItemsPrefadeOnOpeningTime = 500,

}

local scrollblock = textblock:fitBlockToHeight( options )

local yAdjustment = textblock.yAdjustment
scrollblock.x = x
scrollblock.y = y



--===================================================================--
-- Accordian Example:
--===================================================================--

local accordian = require ( "scripts.accordian.accordian" )

--===================================================================--
-- Create display objects for each row of the accordian
local mytexta = funx.readFile("assets/accordian-sample-text-a.txt")
local mytextb = funx.readFile("assets/accordian-sample-text-b.txt")
local mytextc = funx.readFile("assets/accordian-sample-text-c.txt")
local mytextd = funx.readFile("assets/accordian-sample-text-d.txt")

local w = 360
local h = 100

local h1 = makeTextBlock( "<b>Quelle</b> précautions?" ,w,h)
local t1 = makeTextBlock( mytexta ,w,h)

local h2 = makeTextBlock( "<b>Quelle</b> terre?" ,w,h)
local t2 = makeTextBlock( mytextb ,w,h)
local t3 = makeTextBlock( mytextc ,w,h)

local h3 = makeTextBlock( "<i><b>Quelle</b> horreur?</i>" ,w,h)
local t4 = makeTextBlock( mytextd ,w,h)

-- Make a table to hold the accordian info
local myData = {}
myData[1] = { obj = h1, isHeader = true,  }
myData[2] = { obj = t1, }
myData[3] = { obj = h2, isHeader = true,  }
myData[4] = { obj = t2, }
myData[5] = { obj = t3, }
myData[6] = { obj = h3, isHeader = true,  }
myData[7] = { obj = t4, }


--===================================================================--
-- Create the accordian

local params = {
	rowdata = myData,
	initialOpenRow = 1,
	
	width = 400,
	height = 300,
	top = 400,
	left = 50,
	margins = { top = 10, left = 10, bottom = 10, right = 10, },
	
	backgroundColor = { 237/255, 243/255, 210/255, 1 },
	headerRowColor = { 183/255, 213/255, 0/255, 1 },
	rowColor = { 
			default = { 237/255, 243/255, 210/255, 1 },
			over = { 1, 0.5, 0, 0.2 },
	},
	lineColor = { 0.30, 0.30, 0.90 },
	
	showHeaderGraphic = true,
	headerGraphicWidth = 14,
	headerGraphicHeight = 14,
	
	isLocked = false,	-- If bigger than space provided the whol accordian can be scrolled
	noLines = true,	-- no lines between rows
	
}
	
myAccordian = accordian.new( params )

-- Example: open myData row 3 (NOT row three as it appears in the table on screen!)
--myAccordian.openRow( 3 )



--===================================================================--
-- TESTING BUTTONS
--===================================================================--
-- Control buttons for demonstration
-- Code must be after the functions they call.

local buttonX = screenW - 120
local buttonY = 110



local wf = false
local function toggleWireframe()
	wf = not wf
	display.setDrawMode( "wireframe", wf )
	if (not wf) then
		display.setDrawMode( "forceRender" )
	end
	print ("WF = ",wf)
end

local wfb = widget.newButton{
			label = "Wireframe",
			labelColor = { default={ 0,0,0 }, over={ 1, 0, 0, 0.5 } },
			fontSize = 20,
			x =buttonX,
			y=buttonY,
			shape = "roundedRect",
			fillColor = { default={ .7,.7,.7 }, over={ .2, .2, .2 } },
			onRelease = toggleWireframe,
		}
wfb:toFront()



--===================================================================--
buttonY = buttonY + 60
local prevslide = widget.newButton{
			label = "Prev",
			labelColor = { default={ 0,0,0 }, over={ 1, 0, 0, 0.5 } },
			fontSize = 20,
			x =buttonX,
			y=buttonY,
			shape = "roundedRect",
			fillColor = { default={ .7,.7,.7 }, over={ .2, .2, .2 } },
			onRelease = goPrevSlide,
		}
prevslide:toFront()

--===================================================================--
buttonY = buttonY + 60
local nextslide = widget.newButton{
			label = "Next",
			labelColor = { default={ 0,0,0 }, over={ 1, 0, 0, 0.5 } },
			fontSize = 20,
			x =buttonX,
			y= buttonY,
			shape = "roundedRect",
			fillColor = { default={ .7,.7,.7 }, over={ .2, .2, .2 } },
			onRelease = goNextSlide,
		}
nextslide:toFront()


--===================================================================--
buttonY = buttonY + 60
local firstslide = widget.newButton{
			label = "First",
			labelColor = { default={ 0,0,0 }, over={ 1, 0, 0, 0.5 } },
			fontSize = 20,
			x =buttonX,
			y= buttonY,
			shape = "roundedRect",
			fillColor = { default={ .7,.7,.7 }, over={ .2, .2, .2 } },
			onRelease = goFirstSlide,
		}
firstslide:toFront()


--===================================================================--
buttonY = buttonY + 60
local lastslide = widget.newButton{
			label = "Last",
			labelColor = { default={ 0,0,0 }, over={ 1, 0, 0, 0.5 } },
			fontSize = 20,
			x =buttonX,
			y= buttonY,
			shape = "roundedRect",
			fillColor = { default={ .7,.7,.7 }, over={ .2, .2, .2 } },
			onRelease = goLastSlide,
		}
lastslide:toFront()

--===================================================================--
buttonY = buttonY + 60
local lastslide = widget.newButton{
			label = "Auto Advance",
			labelColor = { default={ 0,0,0 }, over={ 1, 0, 0, 0.5 } },
			fontSize = 20,
			x =buttonX,
			y= buttonY,
			shape = "roundedRect",
			fillColor = { default={ .7,.7,.7 }, over={ .2, .2, .2 } },
			onRelease = switchAutoAdvance,
		}
lastslide:toFront()

--===================================================================--
buttonY = buttonY + 60
local removeShowB = widget.newButton{
			label = "Remove Slideviewer",
			labelColor = { default={ 0,0,0 }, over={ 1, 0, 0, 0.5 } },
			fontSize = 20,
			x =buttonX,
			y= buttonY,
			shape = "roundedRect",
			fillColor = { default={ .7,.7,.7 }, over={ .2, .2, .2 } },
			onRelease = removeShow,
		}
removeShowB:toFront()


--===================================================================--
buttonY = buttonY + 60
local createShowB = widget.newButton{
			label = "Create Slideviewer",
			labelColor = { default={ 0,0,0 }, over={ 1, 0, 0, 0.5 } },
			fontSize = 20,
			x =buttonX,
			y= buttonY,
			shape = "roundedRect",
			fillColor = { default={ .7,.7,.7 }, over={ .2, .2, .2 } },
			onRelease = recreateShow,
		}
createShowB:toFront()



