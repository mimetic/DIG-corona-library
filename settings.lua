-- settings.lua
--
-- Version 0.1
--
-- Copyright (C) 2010 David I. Gross. All Rights Reserved.
--
-- This software is is protected by the author's copyright, and may not be used, copied,
-- modified, merged, published, distributed, sublicensed, and/or sold, without
-- written permission of the author.
--
-- The above copyright notice and this permission notice shall be included in all copies
-- or substantial portions of the Software.
--
-- THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED,
-- INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR
-- PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE
-- FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR
-- OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER
-- DEALINGS IN THE SOFTWARE.
--
-- Load the settings file (settings.xml) and return a table.
-- Sample XML file:
--[[


REQUIRES: require ("XmlParser")

<?xml version="1.0" encoding="UTF-8" ?>
<settings>
	<class value="navbar">
		<color>1</color>
		<height value="1" />
	</class>
</settings>

returns a table where

1) navbar.color = 1
2) navbar.height = 1

]]


local S = {}

local xml = require ("xml")
local handler = require "handler"

local funx = require ("scripts.funx")


------------------------------------------------------------------------
-- Load a settings file and return the table
------------------------------------------------------------------------
local function loadSettings (filename, sourceDirectory)
	
	local settings = {}

	if (filename == nil) then
		filename = "_user/settings.xml"
	end

	sourceDirectory = sourceDirectory or system.ResourceDirectory


	local filePath = system.pathForFile( filename, sourceDirectory )
	if (filePath) then
		


--if (true) then


		-- setup for xml.lua
		local h = handler.simpleTreeHandler()
		--local h = handler.domHandler()
		local x = xml.xmlParser(h)
		x.options.stripWS = true
		x.options.expandEntities = true
		--x.options.noReduce = { class = true, }
		x.options.tagLowercase = false
		x:parseFile(filePath)
		local xmlTree = h.root
		
		if (not xmlTree) then
			print ("WARNING: Tried to load empty or damaged XML file from " .. filePath)
			return {}
		end

		-- Newer parser, handles CDATA
		-- We coded XML by wrapping in a single element, for no good reason, e.g.
		-- <settings>....<settings>
		
		-- simpleTreeHandler Version:
		
			local function convertXmlNode(xmlNode)
				local testvalue
				
				local settings = {}

				for i,s in pairs(xmlNode) do
					if (type(s) ~= "table") then
						settings[i] = s
					elseif (i ~= "_attr") then
						if (s._attr) then
							-- We only use the "value" value; the rest is thrown away!!!
							-- (How sad...)
							
							-- This XML reader doesn't handle types!
							-- Fix the booleans:
							if (s._attr.value == "true") then
								s._attr.value = true
							elseif (s._attr.value == "false") then
								s._attr.value = false
								
							-- Fix numbers
							elseif pcall( function() local x=tonumber(s._attr.value)+0; end ) then
								s._attr.value = tonumber(s._attr.value)
							end

							settings[i] = s._attr.value


							--[[
							-- This works when we can handle tables as values:
							local j,v
							-- Remove comments first!
							s._attr.comment = nil
							-- remove "alt" values, we don't use them
							s._attr.alt = nil
							-- Get first value of the table
							j, settings[i] = next(s._attr, nil)
							-- Is there more in the _attr table,i.e. it isn't just a single value
							-- like 'value'?
							j,v = next(s._attr, j)
							if ( j ) then
								settings[i] = s._attr			
							end
							--]]
						end
					end
				end
				return settings
			end
		
		
		-- Get the root, which is the first element
		for rootName,node in pairs(xmlTree) do
			-- classes in the XML
			for xmlNodeName, xmlNode in pairs(node) do
				if (type(xmlNode) == "table") then
					-- Two ways of have classes in the XML: element by name, or element is a 'class' with a name value:
					-- <shelves>...</shelves>
					-- or, we might have class, which returns a table 
					-- of classes, found when we do this: <class value="shelves">...</class>
					local className = xmlNodeName
					if (className == "class" ) then
						print ("ERROR: in file ".. filename .. " using legacy XML 'class' elements!!! Change to named elements.")
						
						-- Array count will tell us whether this class element is a numerical array of
						-- tables, or it is a hash of elements of a single class element.
						if (#xmlNode==0) then
							-- there was only one class, so the node is the contents of that one class
							className = xmlNode._attr.value
							settings[className] = convertXmlNode(xmlNode)
						else
							-- Here we have an array of classes
							for i, class in pairs(xmlNode) do
								className = class._attr.value
								settings[className] = convertXmlNode(class)
							end
						end
					else
						settings[className] = convertXmlNode(xmlNode)
					end
				end
			end
		end

		
--[[		
		-- Use older XMP parser
else
		-- Using older parser
		local xmlTree = XmlParser:ParseXmlFile(filePath)
		
			for i,xmlNode in pairs(xmlTree.ChildNodes) do
				if (xmlNode.Name == "class") then
					local c = xmlNode.Attributes.value
					--print ("* Add class "..c.." to settings")
					settings[c] = {}
					for i,s in pairs(xmlNode.ChildNodes) do
						if (s.value ~= nil) then
							settings[c][s.Name] = s.value
							--print (i..") "..c.."."..s.Name.." = "..s.value )
						elseif (s.Attributes.value ~= nil) then
							settings[c][s.Name] = s.Attributes.value
							--print (i..") "..c.."."..s.Name.." = "..s.Attributes.value )
						end
					end
				end
			end

end -- if-then for testing
--]]		
	else
		print ("WARNING: missing settings file", filename)
		settings = {}
	end

	return settings

end

------------------------------------------------------------------------
-- Load a settings file, merge with custom settings file with the same
-- name in the _custom folder and return the table. 
------------------------------------------------------------------------
function S.new(filename, sourceDirectory)
	local s = loadSettings (filename, sourceDirectory)
	
	local customSettingsFileName = "_custom/" .. filename
	if (funx.fileExists(customSettingsFileName, sourceDirectory) ) then
		local cs = loadSettings(customSettingsFileName, sourceDirectory)
		s = funx.tableMerge(s, cs)
	end
	return s
end

return S