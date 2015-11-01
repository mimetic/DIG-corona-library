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

-- @param params.padding [table] Table of padding inside each row { top = top, bottom = bottom, left = left, right = right }

-- TESTING
local testing = true

-- Main var for this module
local M = {}

local pathToModule = "scripts/accordian/"
M.path = pathToModule


-- Corona Widgets
local widget = require ("widget")

-- My useful function collection
local funx = require("scripts.funx")

local textrender = require("scripts.textrender.textrender")

local json = require("json")

-- functions
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
	local padding = params.padding or { top = 10, left = 10, bottom = 10, right = 10, }

	local myListTop = params.top or navBarHeight
	local myListLeft = params.left or 0
	local myListWidth = params.width or display.contentWidth
	local myListHeight = params.height or display.contentHeight - navBarHeight
	
	-- Default is to allow the table to scroll.
	local isLocked = params.isLocked
	if (isLocked == nil) then
		params.isLocked = false
	end

	-- Default is to allow the table to scroll.
	local noLines = params.noLines
	if (noLines == nil) then
		params.noLines = false
	end

	-- The accordian
	local myList = {}

	-- Source data, also holds 
	local myData = params.rowdata
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
	local headerGraphicWidth = params.headerGraphicWidth or 0
	local headerGraphicHeight = params.headerGraphicHeight or 0
	
	if (math.min(headerGraphicWidth, headerGraphicHeight) == 0) then
		local temp  = funx.loadImageFile(headerClosedGraphicFilename)
		headerGraphicWidth = temp.width
		headerGraphicHeight = temp.height
		temp:removeSelf()
		temp = nil
	end


	--===================================================================--
	local function onRowRender( event )
		print ("accordian:onRowRender()")
	   --Set up the localized variables to be passed via the event table

		local row = event.row
		local rowid = event.row.id
		local id = row.params.id
		local params = event.row.params
		local headerGraphic
		if (showHeaderGraphic) then
			if(myData[id].isHeader) then
				if (myData[id].isCompressed) then
					headerGraphic = funx.loadImageFile(pathToModule .. "assets/arrow-right.png")
				else
					headerGraphic = funx.loadImageFile(pathToModule .. "assets/arrow-down.png")
				end
				funx.ScaleObjToSize (headerGraphic, headerGraphicWidth, headerGraphicHeight)
			end
		end
	
		local x = 0

		if ( event.row.params ) then
			if (showHeaderGraphic and myData[id].isHeader) then
				row:insert(headerGraphic)
				funx.anchor(headerGraphic, "TopLeft")
				x = x + 20 + headerGraphicWidth
				headerGraphic.x = padding.left
				headerGraphic.y = 10
			end
			if (myData[id].obj) then
				row:insert(myData[id].obj)
				myData[id].obj.x = x + padding.left
				myData[id].obj.isVisible = true
			end
		
		
		end
		return true
	end


	--===================================================================--
	local function buildTable(  )
	
		for i = 1, #myData do
			if (not myData[i].isHidden and myData[i].obj) then
				local rc = params.rowColor.default or {1,1,1}
				local rh = padding.top + myData[i].obj.height + padding.bottom

				if (myData[i].isHeader) then
					rc = params.headerRowColor or {.8, .8, .8}
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
		
		-- Bug in corona widgets, so we have to reset the y
		myList._view.y = 0

	end



	--===================================================================--
	local function reBuildTable(  )

		print ("accordian: reBuildTable()")
	
		if (myList:getNumRows() > 0) then
			-- Save all objects in the current table
			for i = 1, #myData do
				display.currentStage:insert( myData[i].obj )
			end

			-- Now, we can delete the table's rows
			-- Unlike delete row, this should be instantaneous
			myList:deleteAllRows()
		end
		
		-- Build the table
		buildTable()

	
	end

	--===================================================================--
	-- Set the hidden/not hidden for rows depending on whether the section header
	-- is set to be compressed.
	-- Useful for preparing the initial table.
	local function autoDiscoverCompression()
	
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

	--===================================================================--
	-- Decompress section starting with row = id,
	-- then compress all other sections.
	local function compressAllButOne(id)
		local isCompressed = false
	
		for i = 1, #myData do
			local row = myData[i]
			if (row.isHeader) then
				myData[i].isCompressed = (i ~= id)
			end			
		end
	
		autoDiscoverCompression()
		
	end



	--===================================================================--
	local function onRowTouch( event )

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
		
			compressAllButOne(thisHeaderID)
			reBuildTable()
		end

	end


	--===================================================================--
	-- Function to open a particular row after the accordian is built
	local function openRow( id )
		compressAllButOne( id )
		reBuildTable( )
	end



--===================================================================--
-- MAIN CODE
--===================================================================--

myList = widget.newTableView {
	top = myListTop, 
	left = myListLeft,
	width = myListWidth, 
	height = myListHeight,

	backgroundColor = params.backgroundColor or { 1,1,1,1 },

	onRowRender = onRowRender,
	onRowTouch = onRowTouch,
	
	isBounceEnabled = false,
	noLines = noLines,
	isLocked = isLocked,
}

	compressAllButOne( initialOpenRow)
	buildTable( )
	
	
	-- Method for opening a row
	myList.openRow = openRow

	return myList

end

--===================================================================--


return M