-- frame.lua
--
-- Version 1.0
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


Paint a rough frame around a rectangle or picture. 
Return the modifed picture with the frame drawn on it.
The frame is drawn on the edge of the image, making it larger and drawing over
the interior edges of the image.

local opts = {
	image = funx.loadImageFile("pic.jpg"),
	-- OR, use height/width
	width = 400, height = 300,

	brushname = "default" ("pencil", "pencil-light")
	padding = transparent extra space around the image, in pixels
	size = size of the brush (not in pixels), e.g. 4
	alpha = alpha of the brush (0.0 - 1.0)
	jitter = max setting for random resizing of the brush (not in pixels), e.g. 6
	scatter = max setting for random scattering from the path (not in pixels), e.g. 6 
	rotation = maximum random rotation of the brush, e.g. 180,
	spacing = pixel spacing between brushes
}

local pic = frameLib.new ( opts )

]]




-- TESTING
-- Check the GLOBAL testing variable
local testing = _TESTING
local noCache = _NOCACHE

if (noCache) then
	print ("**** WARNING: frame: CACHING TURNED OFF FOR TESTING!!!! ****")
end

-- Main var for this module
local F = {}

local pathToModule = "scripts/frame/"
F.path = pathToModule

-- funx must be installed in scripts folder
local funx = require ("scripts.funx")

-- Math functions for improved speed
local sqrt = math.sqrt
local pow = math.pow
local abs = math.abs
local random = math.random
local max = math.max
local min = math.min
local floor = math.floor

local lower = string.lower

-- Scalers for jitter and scatter of a brush
local jitterScaler = 8000
local scatterScaler = 300

local cosineFortyFiveDegrees = math.cos(math.rad(45))
	
	
local brushfile = "brush-a.png"

----------------------------------------------------------------------
-- CACHE SETTINGS
local cacheDir = "frame-cache"

--------------------------------------------------------
-- CACHE: Clear all caches

local function clearAllCaches(cacheDir)
	if (cacheDir and cacheDir ~= "") then
		funx.rmDir (cacheDir .. "/" .. textWrapCacheDir, system.CachesDirectory, true) -- keep structure, delete contents
	end
end


--------------------------------------------------------
local function saveToCache(id, image, cacheDir)
	if (cacheDir and cacheDir ~= "") then
		funx.mkdirTree (cacheDir .. "/" .. textWrapCacheDir, system.CachesDirectory)
	end
end


--------------------------------------------------------
local function loadFromCache(id, cacheDir)
	if (cacheDir) then
		local fn = cacheDir .. "/" .. textWrapCacheDir .. "/" ..  id .. ".json"

		if (funx.fileExists(fn, system.CachesDirectory)) then
			local c = funx.loadTable(fn, system.CachesDirectory)
			return c
		end
	end
end



----------------------------------------------------------------------
-- How much extra space does the brush add outside the frameline
-- Answer: 1/2 ( brushwidth (at 45 degrees rotation!) + max scatter + max jitter )
local function extraForBrush(brushfile, size, jitter, scatter)
	-- for jitter and scatter and scale
	local sc,j = 0,0
	local brush = funx.loadImageFile(brushfile)
	local scale = (size or 1)/100

	if (jitter > 0) then
		j = (jitter/jitterScaler) * 100
		scale = scale + j
	end

	-- Scale the brush for max jitter
	if (scale ~= 1) then
		brush:scale(scale,scale)
	end
		
	if (scatter and scatter > 0) then
		sc = (scatter/scatterScaler) * 50
	end
	--print ("Scatter",sc)	
	
	-- A 45 degree rotated square is wider than a 90 degree square.
	local maxBrushWidth = max(brush.contentWidth, brush.contentHeight) * 1/cosineFortyFiveDegrees
	local extraSize =  (maxBrushWidth + sc)

	brush:removeSelf()
	brush = nil


	return extraSize
end

----------------------------------------------------------------------
-- Paint a line using a brush image
local function paintLine( opts )
	
	opts.size = opts.size or 1
	opts.jitter = opts.jitter or 0
	opts.scatter = opts.scatter or 0
	opts.rotation = opts.rotation or 179
	opts.spacing = opts.spacing or 1
	
	local scale = (opts.size or 1)/100
	local alpha = opts.alpha or 1
	local x1,y1,x2,y2 = opts.x1, opts.y1, opts.x2, opts.y2
	
	local dx = x2-x1
	local dy = y2-y1
	
	local snapshot = display.newSnapshot( opts.image.width, opts.image.height )
	snapshot.group:insert(opts.image)
	snapshot.canvasMode = "discard"

	local d = sqrt( pow(x2-x1,2) + pow(y2-y1,2) )
	local xStep = dx/d
	local yStep = dy/d

	
	-- for jitter and scatter and scale
	local j,sc = 0,0
	
	local x,y
	-- Steps of the brush
	local step = max(opts.spacing,1)
	for i = 1,d,step do

		-- scatter (brush random resizing)
		if (opts.scatter > 0) then
			--sc = (random (scatter) - (scatter/2) )
			sc = (opts.scatter/scatterScaler) * (random (100)-50)
			--print ("scatter="..sc)
		end

		-- jitter (brush random resizing)
		-- The min value is the brush size, jitter always grows
		if (opts.jitter > 0) then
			j = (opts.jitter/jitterScaler) * random (100)
		end

		x = x1 + (xStep * i) + sc
		y = y1 + (yStep * i) + sc

		local brush = funx.loadImageFile(opts.brushfile)
		snapshot.group:insert(brush)
		funx.anchor(brush, "Center")
		brush.alpha = alpha
		-- More interesting to keep stroke angle more confined
		brush.rotation = random(opts.rotation)
		
		s = scale + j

		if (scale ~= 1) then
			brush:scale(s,s)
			--print ("scale",s,j)
		end
		
		
		
		--brush.rotation = random(360)
		brush.x, brush.y = x,y
		
	end
	--snapshot:invalidate()
	snapshot:invalidate( "canvas" )
	return snapshot
end
	

----------------------------------------------------------------------
-- Paint lines around an image
local function frameObject(opts)
	local canvas
	
	opts.size = tonumber(opts.size) or 1
	opts.jitter = tonumber(opts.jitter) or 0
	opts.scatter = tonumber(opts.scatter) or 0
	opts.padding = tonumber(opts.padding) or 0
	opts.rotation = tonumber(opts.rotation) or 179
	opts.spacing = tonumber(opts.spacing) or 1
	opts.alpha = tonumber(opts.alpha) or 1
	opts.fit = opts.fit or "none"
	opts.mattecolor = opts.mattecolor
	

	-- Amount to embed the frame in the final image
	local indent = 0
	
	-- Unscaled image size
	local imageW, imageH = opts.image.contentWidth, opts.image.contentHeight
	-- Sizing rect for the snapshot 
	local w,h
	-- Sizing for a matte rectangle
	local mw, mh
	
	
	-- enlarge the final picture+frame and keep the image the same size
	if (opts.fit == "enlarge") then
		indent = extraForBrush(opts.brushfile, opts.size, opts.jitter, opts.scatter)
		
		-- Sizing rect
		-- Use even spacing around the scaled image
		w = imageW + 2*opts.padding + indent
		h = imageH + 2*opts.padding + indent
		
		-- Matte rect
		--mw, mh = imageW + opts.padding*2, imageH + opts.padding*2
		mw, mh = w - indent/2, h - indent/2
	
	-- Shrink the image, draw a frame around the original image borders
	-- Doesn't work well with long/tall images and padding.
	elseif (opts.fit == "fit") then
		-- make sure padding isn't greater than picture dimensions
		opts.padding = min( max(imageW, imageH)/2, opts.padding )

		indent = extraForBrush(opts.brushfile, opts.size, opts.jitter, opts.scatter)

		local border = 2*opts.padding
		local scale = min(imageW/(imageW + border), imageH/(imageH + border))
		
		opts.image:scale(scale,scale)

		-- Sizing rect
		w = imageW
		h = imageH

		-- Matte rect
		mw, mh = w - indent/2,h - indent/2
	
	-- Shrink the image, but draw a frame evenly around it.
	elseif (opts.fit == "even") then
		-- make sure padding isn't greater than picture dimensions
		opts.padding = min( max(imageW, imageH)/2, opts.padding )

		indent = extraForBrush(opts.brushfile, opts.size, opts.jitter, opts.scatter)

		local border = 2*opts.padding
		local scale = max(imageW/(imageW + border), imageH/(imageH + border))

		opts.image:scale(scale,scale)

		-- Sizing rect
		w = opts.image.contentWidth + 2*opts.padding
		h = opts.image.contentHeight + 2*opts.padding

		-- Matte rect
		mw, mh = w - indent/2,h - indent/2
		
	-- Shrink the image and crop to fit, but draw a frame evenly around it.
	elseif (opts.fit == "crop") then
		-- make sure padding isn't greater than picture dimensions
		opts.padding = min( max(imageW, imageH)/2, opts.padding )

		indent = extraForBrush(opts.brushfile, opts.size, opts.jitter, opts.scatter)

		local border = 2*opts.padding
		local scale = max(imageW/(imageW + border), imageH/(imageH + border))
		opts.image:scale(scale,scale)
		
		-- Crop the image using a snapshot
		local snapshot = display.newSnapshot( imageW - border, imageH - border )
		snapshot.group:insert(opts.image)
		snapshot:invalidate( "canvas" )
		opts.image = snapshot
		snapshot:removeSelf()
		snapshot = nil

		-- Sizing rect
		w = imageW
		h = imageH

		-- Matte rect
		mw, mh = w - indent/2,h - indent/2
		
	else
		-- Final same size, and do not change the image size
		indent = extraForBrush(opts.brushfile, opts.size, opts.jitter, opts.scatter)

		-- Sizing rect
		w = imageW
		h = imageH

		-- Matte rect
		mw, mh = w - indent/2,h - indent/2
	end
	
	
	local g = display.newGroup()
	
	-- Create an invisible rect for sizing
	local r
	r = display.newRect(g, 0,0, w, h )
	r:setFillColor (0,0,250,0)
	
	-- Add a colored matte
	-- A rounded Rect doesn't show at corners with a round brush
	if (opts.mattecolor) then
		local matte = display.newRoundedRect(g, 0,0, mw, mh, opts.size/2)
		local mattecolor = funx.stringToColorTable(opts.mattecolor)
		matte:setFillColor ( mattecolor[1], mattecolor[2], mattecolor[3], mattecolor[4] )
	end

	-- Rect for drawing the frame itself:
	w = (w - indent)/2
	h = (h - indent)/2

	
	g:insert(opts.image)
	opts.image = g
	
	opts.x1, opts.y1 = -w,-h
	opts.x2, opts.y2 = w, -h
	canvas = paintLine (opts)
	
	opts.x1, opts.y1 = opts.x2, opts.y2
	opts.x2, opts.y2 = w, h
	opts.image = canvas
	canvas = paintLine (opts)

	opts.x1, opts.y1 = opts.x2, opts.y2
	opts.x2, opts.y2 = -w, h
	opts.image = canvas
	canvas = paintLine (opts)

	opts.x1, opts.y1 = opts.x2, opts.y2
	opts.x2, opts.y2 = -w, -h
	opts.image = canvas
	canvas = paintLine (opts)
	
	return canvas
end


----------------------------------------------------------------------
-- Scale and Crop Image and image to fit a rectangle
-- Crop an image to fit a rectangle
-- Return the cropped image
function F.crop( obj, w, h)
		imageW, imageH = obj.contentWidth, obj.contentHeight
		border = border * 2
		local scale = max(w/imageW, h/imageH)
		obj:scale(scale,scale)
		
		-- Crop the image using a snapshot
		local snapshot = display.newSnapshot( w, h )
		snapshot.group:insert(obj)
		snapshot:invalidate( "canvas" )
		obj = snapshot
		snapshot:removeSelf()
		snapshot = nil
		return obj
end


----------------------------------------------------------------------
-- New Frame Object
-- Create a new framed image based on an existing image
-- or, if no image provided, return a frame based on width,height options
--[[
	options:
		image = A display object to draw on. If NIL, we use an invisible rect.
		brushname = Name of the brush to use, e.g. "default"
		width, height = if no image given, create an invisible rect sized width,height
--]]
function F.frame( opts )
	
	-- Fill in default values
	local defaults = {
		brushname = "default",
		padding = 0,
		size = 4, 
		alpha = 1, 
		jitter = 13,
		scatter = 16,
		rotation = 179,
		spacing = 1,
		fit = "fit",
		mattecolor = "100%, 100%, 100%, 100%",
	}
	opts = funx.tableMerge (defaults, opts)
	if (not opts.image) then
		if (opts.width and opts.height) then
			-- use an invisible rect
			opts.image = display.newRect(0,0, opts.width, opts.height)
			opts.image:setFillColor(0,0,255)
			opts.image.alpha = 0
		else
			-- missing params
			print ("ERROR: frame(): Missing an image OR height/width values. Must have one or the other.")
			return false
		end
	end
	
	local brushlist = {}
	local sbase = system.pathForFile( nil, srcBaseDir )
	for filename in lfs.dir(sbase .. "/" .. pathToModule .. "brushes") do
		if (filename:sub(1,1) ~= ".") then
			brushlist[filename] = pathToModule .. "brushes/" .. filename
		end
	end
	
	-- If brush chosen by name, check for it by adding ".png" because
	-- all brushes are PNG files. A
	local brushfile = brushlist[opts.brushname..".png"] or pathToModule .. "brushes/default.png"
	opts.brushfile = brushfile

	local canvas = frameObject(opts)
	--[[
	local filename = "framed-"..opts.id .. ".png"
	local saveOpts = {
		filename = filename,
		baseDir = system.CachesDirectory,
		isFullResolution = true,
	}
	
	if (false) then	
		display.save(canvas, saveOpts)
		canvas:removeSelf()
		local f = funx.loadImageFile(filename, "", system.CachesDirectory)
		return f
	else
		return canvas
	end
	--]]
	
	return canvas
end


-------------------------------------------------
-------------------------------------------------
-- Frame an object
-- Designed to go behind an image, not in front.
-- params may include:
-- stroke width (stroke)
-- Styles:
-- solid : a stroke 100% outside the image (not like a Corona stroke that is on the edge)
-- thin-thick : 25% inner stroke, 50% out, with 25% padding
-- thick-thin : 50% inner stroke, 25% out, with 25% padding
-- The matte color is for a matte around the image. 

--[[
	@param	params	A table, params = { 
								width, height = integers,
								stroke = integer, 
								style = solid | thick-thin | thin-thick, 
								color = RGBAColorString, 
								matteColor = RGBAColorString, 
								matte = integer,
							}
--]]
function F.vectorFrame (params)
	local floor = floor

	-- BACKGROUND
	-- Default is transparent fill for stroking boxes
	local color = funx.stringToColorTable(params.color or "0,0,0")
	local mattecolor = funx.stringToColorTable(params.matteColor or "255,255,255,100%")
	params.stroke = params.stroke or 0
	params.matte = params.matte or 0

	-- Size
	local w = params.width + 2*params.matte
	local h = params.height + 2*params.matte
	
	-- FRAME
	local f = display.newGroup()
	--f.anchorChildren = true

	params.style = lower(params.style)
	if ( params.style == "solid") then

		fr = display.newRect(f, 0,0, w + params.stroke, h + params.stroke)
		fr.strokeWidth = params.stroke or 0
		fr:setStrokeColor(color[1], color[2], color[3], color[4])
		if (mattecolor) then
			fr:setFillColor(mattecolor[1], mattecolor[2], mattecolor[3], mattecolor[4])
		end

	elseif (params.style == "thick-thin") then
		
		local sw = params.stroke or 0
		local innerW = floor(sw * 0.5) or 1
		local outerW = floor(sw * 0.25) or 1
		local padding = (sw-(innerW + outerW)) or 1

		local innerFrame = display.newRect(f, 0,0, w + innerW - 1, h + innerW - 1 )
		innerFrame.strokeWidth = innerW
		innerFrame:setStrokeColor(color[1], color[2], color[3], color[4])
		if (mattecolor) then
			innerFrame:setFillColor(mattecolor[1], mattecolor[2], mattecolor[3], mattecolor[4])
		end

		local outerOffset = innerW + padding + outerW/2
		local outerFrame = display.newRect(f, 0,0, w - 1 + 2*outerOffset, h - 1 + 2*outerOffset)
		outerFrame.strokeWidth = outerW
		outerFrame:setStrokeColor(color[1], color[2], color[3], color[4])
		outerFrame:setFillColor(255)
		outerFrame:toBack()
		
--		innerFrame:translate(-params.stroke, -params.stroke)
--		outerFrame:translate(-params.stroke, -params.stroke)

	elseif (params.style == "thin-thick") then
		
		local sw = params.stroke or 0
		local innerW = floor(sw * 0.25) or 1
		local outerW = floor(sw * 0.5) or 1
		local padding = (sw-(innerW + outerW)) or 1

		local innerFrame = display.newRect(f, 0,0, w + innerW, h + innerW )
		innerFrame.strokeWidth = innerW
		innerFrame:setStrokeColor(color[1], color[2], color[3], color[4])
		if (mattecolor) then
			innerFrame:setFillColor(mattecolor[1], mattecolor[2], mattecolor[3], mattecolor[4])
		end

		local outerOffset = innerW + padding + outerW/2
		local outerFrame = display.newRect(f, 0,0, w + 2*outerOffset, h + 2*outerOffset)
		outerFrame.strokeWidth = outerW
		outerFrame:setStrokeColor(color[1], color[2], color[3], color[4])
		outerFrame:setFillColor(255)
		outerFrame:toBack()

	end

--local q = display.newRect(f, -w/2,-h/2,10,10)
--q:setFillColor(0,255,0,120)

	return f

end



return F