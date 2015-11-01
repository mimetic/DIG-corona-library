-- accordian.lua
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
local M = {}

local pathToModule = "scripts/accordian/"
M.path = pathToModule


-- Corona Widgets
local widget = require ("widget")

-- My useful function collection
local funx = require("scripts.funx")

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

-- Height of the system navbar
local navBarHeight = 60

function M.new( params )

	-- Defaults
	local myListTop = navBarHeight
	local myListLeft = 40
	local myListWidth = display.contentWidth - 100
	local myListHeight = display.contentHeight - navBarHeight
	local margins = { top = navBarHeight, left = 30, bottom = 10, right = 30, }
	

	-- The accordian
	local myList = {}

	-- Source data, also holds 
	local myData = params.myData
	myList._params = params

	local initialOpenRow = params.initialOpenRow

	-- Graphics for uncompressed/compressed
	-- Show a triangle for open/close in headers
	local showHeaderGraphic = params.showHeaderGraphic
	
	-- These graphics must have the same height/width
	local headerClosedGraphicFilename = params.headerClosedGraphicFilename or "assets/arrow-right.png"
	local headerOpenGraphicFilename = params.headerOpenGraphicFilename or "assets/arrow-down.png"
	
	-- Get the size of the graphic
	-- Space to leave for the header graphic (triangle)
	local headerGraphicWidth = tonumber(params.headerGraphicWidth) + 0
	local headerGraphicHeight = tonumber(params.headerGraphicHeight) + 0
	
	if (math.min(headerGraphicWidth, headerGraphicHeight) == 0) then
		local temp  = funx.loadImageFile(headerClosedGraphicFilename)
		headerGraphicWidth = temp.width
		headerGraphicHeight = temp.height
		temp:removeSelf()
		temp = nil
	end


	local function makeTextBlock( mytext, custom)
		-- To prevent caching, set the cache dir to empty
		cacheDir = ""
		custom = custom or ""

		local params = {
			text = custom .. mytext,	--loaded above
			font = "AvenirNext-Regular",
			size = "12",
			lineHeight = "16",
			color = {0, 0, 0, 255},
			width = myListWidth - headerGraphicWidth - margins.left - margins.right,
			alignment = "Left",
			opacity = "100%",
			minCharCount = 5,	-- 	Minimum number of characters per line. Start low.
			targetDeviceScreenSize = display.contentWidth..","..display.contentHeight,	-- Target screen size, may be different from current screen size
			letterspacing = 0,
			maxHeight = display.contentWidth - 50,
			minWordLen = 2,
			textstyles = textStyles,
			defaultStyle = "Normal",
			cacheToDB = true,
			isHTML = true,
			useHTMLSpacing = true,
	
		}

		params.cacheDir = ""
		params.cacheToDB = true

		t = textrender.autoWrappedText(params)
	
		return t
	
	end



	local function onRowRender( event )

	   --Set up the localized variables to be passed via the event table

		local row = event.row
		local rowid = event.row.id
		local id = row.params.id
		local params = event.row.params
		local headerGraphic
	
		if (showHeaderGraphic) then
			if(myData[id].isHeader) then
				if (myData[id].isCompressed) then
					headerGraphic = funx.loadImageFile(headerClosedGraphicFilename)
				else
					headerGraphic = funx.loadImageFile(headerOpenGraphicFilename)
				end
				headerGraphicWidth = headerGraphic.width
			end
		end
	
		local x = 0

		if ( event.row.params ) then
			if (showHeaderGraphic and myData[id].isHeader) then
				row:insert(headerGraphic)
				funx.anchor(headerGraphic, "TopLeft")
				x = x + 20 + headerGraphicWidth
				headerGraphic.x = margins.left
				headerGraphic.y = headerGraphicHeight/2
			end
			if (myData[id].obj) then
				row:insert(myData[id].obj)
				myData[id].obj.x = x + margins.left
				myData[id].obj.isVisible = true
			end
		
		
		end
		return true
	end


	local function reloadTable(  )
		if (myList:getNumRows() > 0) then
			myList:deleteAllRows()
		end
	
		local rowColor = { 237/255, 243/255, 210/255, 1 }
		local headerColor = { 183/255, 213/255, 0/255, 1 }
		for i = 1, #myData do
			if (not myData[i].isHidden and myData[i].obj) then
				local rc = rowColor
				local rh = margins.top + myData[i].obj.height + margins.bottom

				if (myData[i].isHeader) then
					rc = headerColor
				end

				myList:insertRow{
				  rowHeight = rh,
				  isCategory = false,
				  rowColor = { default= rc , over={ 1, 0.5, 0, 0.2 } },
				  lineColor = { 0.30, 0.30, 0.90 },
				  params = {
					 id = i,
					 isHeader = myData[i].isHeader,
					 isCompressed = myData[i].isCompressed,
				  }
				}
			end
		end
	end


	-- Set the hidden/not hidden for rows depending on whether the section header
	-- is set to be compressed.
	-- Useful for preparing the initial table.
	local function autoDiscoverCompression(myData)
	
		local isCompressed = false
	
		for i = 1, #myData do
			local row = myData[i]
			if (row.isHeader ) then
				isCompressed = row.isCompressed
			else
				myData[i].isHidden = isCompressed
				-- Unlink the display object from the row, so the obj
				-- won't be removed when the row is removed!
				if (isCompressed) then
					-- Store the obj on the stage
					display.currentStage:insert( myData[i].obj )
					myData[i].obj.isVisible = false
				end
			end
		end
		
	end

	-- Decompress section starting with row = id,
	-- then compress all other sections.
	local function compressAllButOne(myData, id)
	
		local isCompressed = false
	
		for i = 1, #myData do
			local row = myData[i]
			if (row.isHeader) then
					myData[i].isCompressed = (i ~= id)
			end			
		end
	
		autoDiscoverCompression(myData)
		
	end



	local function onRowTouch ( event )

		local row = event.row
		local id = event.target.index

		-- Possible that this is called when the table is rebuilding or
		-- the rows aren't available!
		if (not id) then
			return
		end
	
		local i = row.params.id

		if (myData[i].isHeader) then
	
			local thisHeaderID = i
		
			-- Flag section as "compressed"
			myData[i].isCompressed = not myData[i].isCompressed
		
			-- Get rows in this category
			i = i + 1
			local first, last = i,i
			while (i <= #myData and not myData[i].isHeader) do
					last = i
					myData[i].isHidden = not myData[i].isHidden
				i = i + 1
			end
		
			compressAllButOne(myData, thisHeaderID)
			reloadTable()
		end

	end

	-- Create the table widget
	myList = widget.newTableView {
		top = myListTop, 
		left = myListLeft,
		width = myListWidth, 
		height = myListHeight,

		backgroundColor = { 0.8, 0.8, 0.8 },

		onRowRender = onRowRender,
		onRowTouch = onRowTouch,
	}

	compressAllButOne( myData, initialOpenRow)
	reloadTable( )
	
	return myList

end

M.new = new

return M