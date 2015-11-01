--====================================================================--
-- widget_scroller.lua
--
--
-- by David McCuskey
-- Documentation: http://docs.davidmccuskey.com/display/docs/newScroller.lua
--====================================================================--

--[[

Copyright (C) 2013-2014 David McCuskey. All Rights Reserved.

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


-- Semantic Versioning Specification: http://semver.org/

local VERSION = "1.0.0"



--====================================================================--
-- DMC Widgets : newScroller
--====================================================================--

local dmc_lib_data, dmc_lib_func
dmc_lib_data = _G.__dmc_library
dmc_lib_func = dmc_lib_data.func



--====================================================================--
-- Imports
--====================================================================--

local Utils = require( dmc_lib_func.find('dmc_utils') )
local Objects = require( dmc_lib_func.find('dmc_objects') )



--====================================================================--
-- Setup, Constants
--====================================================================--

-- setup some aliases to make code cleaner
local inheritsFrom = Objects.inheritsFrom
local CoronaBase = Objects.CoronaBase



--====================================================================--
-- Scroller Class
--====================================================================--

local Scroller = inheritsFrom( CoronaBase )
Scroller.NAME = "Scroller Class"


Scroller.TRANSITION_TIME = 250

Scroller.BACKGROUND_COLOR = { 0.5, 0.5, 0, 1 }


--== Event Constants
Scroller.EVENT = "page_scroller_event"

Scroller.SLIDES_ON_STAGE = "slide_onstage_event"
Scroller.UI_TAPPED = "scroller_ui_tapped_event"
Scroller.CENTER_STAGE = "slide_center_stage_event"
Scroller.SLIDES_MODIFIED = "slides_modified_event"



--== Start: Setup DMC Objects

function Scroller:_init( params )
	-- print( "Scroller:_init", params )
	self:superCall( "_init", params )
	--==--

	params = params or {}

	--== Create Properties ==--

	self._width = params.width or display.contentWidth
	self._height = params.height or display.contentHeight

	self._slides = params.slides or {} -- slide list, in order
	self._curr_slide = 0 -- showing current slide

	self._padding = params.padding or {0,0}

	self._offset = params.offset or {0,0}

	self._canInteract = true
	self._isMoving = false -- flag, used to control dispatched events during touch move


	-- current, prev, next tweens
	self._tween = {
		c = nil,
		p = nil,
		n = nil
	} -- showing current slide

	--== Display Groups ==--

	--== Object References ==--

	self._primer = nil -- ref to display primer object

	self._onStage = params.onStageFunc -- reference to onStage callback



end
-- function Scroller:_undoInit()
-- 	--print( "Scroller:_undoInit" )

-- 	--==--
-- 	self:superCall( "_undoInit" )
-- end



function Scroller:_createView()
	-- print( "Scroller:_createView" )
	self:superCall( "_createView" )
	--==--

	local o, p, dg, tmp  -- object, display group, tmp

	--== Setup display primer

	o = display.newRect( 0, 0, self._width, self._height )
	o:setFillColor(1,.5,0)
	o.anchorX, o.anchorY = 0.5, 0.5
	o.x, o.y = 0,0

	self:insert( o )
	self._primer = o

	-- set the main object, after first child object
	o.anchorX, o.anchorY = 0.5, 0.5
	self.x, self.y = 0,0

end



-- _initComplete()
--
function Scroller:_initComplete()
	--print( "Scroller:_initComplete" )
	self:superCall( "_initComplete" )
	--==--

	self:addEventListener( 'touch', self )
end
function Scroller:_undoInitComplete()
	--print( "Scroller:_undoInitComplete" )

	self:removeEventListener( 'touch', self )

	--==--
	self:superCall( "_undoInitComplete" )
end

--== END: Setup DMC Objects




--== Public Methods




function Scroller:viewIsVisible( value )
	-- print( "Scroller:viewIsVisible" )
	local o = self._current_view
	if o and o.viewIsVisible then o:viewIsVisible( value ) end
end

function Scroller:viewInMotion( value )
	-- print( "Scroller:viewInMotion" )
	local o = self._current_view
	if o and o.viewInMotion then o:viewInMotion( value ) end
end



function Scroller:getSlide( index )
	-- print( "Scroller:getSlide ", index )
	return self._slides[ index ]
end


function Scroller:addSlide( object, params )
	-- print( "Scroller:addSlide" )

	local W, H = self._width, self._height
	local H_CENTER, V_CENTER = W*0.5, H*0.5

	params = params or {}

	table.insert( self._slides, object )
	-- object.isVisible = false

	if self._curr_slide == 0 then self._curr_slide = 1 end

	local o = object
	if object.view then o = object.view end
	self:insert( o )

	o.x, o.y = 0, 0

	self:_loadSlides()

	self:_dispatchEvent( Scroller.SLIDES_MODIFIED, { count=#self._slides } )
end


function Scroller:goto( key, params )
	-- print( "Scroller:goto ", key )

	local W, H = self._width, self._height
	local H_CENTER, V_CENTER = W*0.5, H*0.5

	params = params or {}
	params.do_animation = params.do_animation or true
	params.direction = params.direction or Scroller.FORWARD

	local o

	if self._current_view == nil or params.do_animation == false then
		-- have seen a view, but no transition necessary
		o = self._current_view
		if o then
			o.x, o.y = H_CENTER, 0
			o.isVisible = false
			if o.viewIsVisible then o:viewIsVisible( false ) end
		end

		o = self:getSlide( key )
		o.x, o.y = 0, 0
		o.isVisible = true
		if o.viewIsVisible then o:viewIsVisible( true ) end
		if o.viewOnStage then o:viewOnStage( true ) end

		self._current_view = o

	else
		self:_transitionViews( key, params )

	end

	return self._current_view
end





function Scroller:reset()
	--print( "Scroller:reset" )
	self._slides = nil
	self._onStage = nil
	self._curr_slide = 0
end



function Scroller.__getters:slides()
	--print( "Scroller.__getters:slides" )
	return self._slides
end
function Scroller.__setters:slides( value )
	--print( "Scroller.__setters:slides ", value )
	self._slides = value
	self:_loadSlides()
end
function Scroller.__getters:index()
	--print( "Scroller.__getters:index" )
	return self._curr_slide
end
function Scroller.__setters:index( value )
	-- print( "Scroller.__setters:index ", value )
	self._curr_slide = value
end
function Scroller.__setters:onStageFunc( value )
	--print( "Scroller.__setters:onStageFunc" )
	self._onStage = value
end


function Scroller.__getters:hasNext()
	-- print( "Scroller.__getters:hasNext" )
	return (self._curr_slide < #self._slides)
end

function Scroller.__getters:hasPrev()
	--print( "Scroller.__getters:hasPrev" )
	return (self._curr_slide > 1)
end


function Scroller:load( params )

	self._slides = params.slides or {}

end

function Scroller:show( value )
	-- print( "Scroller:show ", value )

	if value == nil and self._curr_slide == nil then
		self._curr_slide = 1
	elseif value ~= nil then
		self._curr_slide = value
	end
	if self._curr_slide > #self._slides then
		self._curr_slide = #self._slides
	elseif self._curr_slide < 1 then
		self._curr_slide = 1
	end

	-- dispatch on stage event
	event_data = {
		index = self._curr_slide,
		slide = self._slides[ self._curr_slide ]
	}
	if self._onStage then self._onStage( { event_data } ) end
	self:_dispatchEvent( Scroller.CENTER_STAGE, event_data )
end


function Scroller:showPage( index )
	-- print( "Scroller:showPage ", index )
	local screenW, screenH = display.contentWidth, display.contentHeight
	local PADDING = self._padding

	if(self._curr_slide > 0 and self._curr_slide <= #self._slides) then

		if(self._curr_slide < index) then
			for i=self._curr_slide, index do
				o = self._slides[i]
				o.isVisible = false
				o.x = -(screenW + PADDING[1])
			end
		elseif(index < self._curr_slide ) then
			for i=index, self._curr_slide do
				o = self._slides[i]
				o.isVisible = false
				o.x = (screenW + PADDING[1])
			end
		end
	end
	if index == nil and self._curr_slide == nil then
		self._curr_slide = 1
	elseif index ~= nil then
		self._curr_slide = index
	end
	if self._curr_slide > #self._slides then
		self._curr_slide = #self._slides
	elseif self._curr_slide < 1 then
		self._curr_slide = 1
	end


	o = self._slides[index]
	o.isVisible = true
	o.x = 0

	-- dispatch on stage event
	event_data = {
		index = self._curr_slide,
		slide = self._slides[ self._curr_slide ]
	}
	if self._onStage then self._onStage( { event_data } ) end
	self:_dispatchEvent( Scroller.CENTER_STAGE, event_data )
end

function Scroller:nextSlide()
	-- print( "Scroller:nextSlide" )
	if self.hasNext then
		self:_nextSlide()
	end
end


function Scroller:prevSlide()
	--print( "Scroller:prevSlide" )
	if self.hasPrev then
		self:_prevSlide()
	end
end


function Scroller:cancelMove()
	--print("Scroller:cancelMove ")

	local screenW, screenH = display.contentWidth, display.contentHeight
	local TIME = Scroller.TRANSITION_TIME
	local PADDING = self._padding

	local twn = {}
	local idx = self._curr_slide
	local o

	local f = self:createCallback( Scroller._onComplete_handler )

	o = self._slides[idx]
	if o ~= nil then
		o.isVisible = true
		twn.c = transition.to( o, {time=TIME, x=0, transition=easing.outExpo } )
	end

	o = self._slides[idx-1]
	if o ~= nil then
		o.isVisible = true
		twn.p = transition.to( o, {time=TIME, x=-(screenW + PADDING[1]), transition=easing.outExpo } )
	end

	o = self._slides[idx+1]
	if o ~= nil then
		o.isVisible = true
		twn.n = transition.to( o, {time=TIME, x=(screenW + PADDING[1]), transition=easing.outExpo, onComplete=f } )
	end


	self._canInteract = true
	self._tween = twn

end




--== Private Methods






function Scroller:_transitionViews( next_key, params )
	--print( "Scroller:_transitionViews" )

	local W, H = self._width, self._height
	local H_CENTER, V_CENTER = W*0.5, H*0.5

	local direction = params.direction
	local prev_view, next_view

	prev_view = self._current_view
	next_view = self:getSlide( next_key )
	self._current_view = next_view


	-- remove previous view
	local step_3 = function()
		self.display.x, self.display.y = 0, 0

		prev_view.x, prev_view.y = H_CENTER, 0
		prev_view.isVisible = false
		if prev_view.viewOnStage then prev_view:viewOnStage( false ) end

		next_view.x, next_view.y = H_CENTER, 0
		next_view.isVisible = true
		if next_view.viewOnStage then next_view:viewOnStage( true ) end

	end

	-- transition both views
	local step_2 = function()

		local s2_c = function()
			if prev_view.viewInMotion then prev_view:viewInMotion( false ) end
			if prev_view.viewIsVisible then prev_view:viewIsVisible( false ) end
			if next_view.viewInMotion then next_view:viewInMotion( false ) end
			if next_view.viewIsVisible then next_view:viewIsVisible( true ) end

			step_3()
		end

		-- perform transition
		local s2_b = function()
			local p = {
				time=Scroller.VIEW_TRANSITION_TIME,
				onComplete=s2_c
			}
			if direction == Scroller.FORWARD then
				p.x = -W
				transition.to( self.display, p )
			else
				p.x = 0
				transition.to( self.display, p )
			end
		end

		local s2_a = function()
			if prev_view.viewInMotion then prev_view:viewInMotion( true ) end
			if prev_view.viewIsVisible then prev_view:viewIsVisible( false ) end
			if next_view.viewInMotion then next_view:viewInMotion( true ) end
			if next_view.viewIsVisible then next_view:viewIsVisible( false ) end
			s2_b()
		end

		s2_a()
	end

	-- setup next view
	local step_1 = function()

		next_view.isVisible = true

		if direction == Scroller.FORWARD then
			self.display.x, self.display.y = 0, 0
			prev_view.x, prev_view.y = H_CENTER, 0
			next_view.x, next_view.y = W+H_CENTER, 0

		else
			self.display.x, self.display.y = -W, 0
			prev_view.x, prev_view.y = W+H_CENTER, 0
			next_view.x, next_view.y = H_CENTER, 0

		end

		step_2()
	end

	step_1()
end


function Scroller:_removeViews()
	--print( "Scroller:_removeViews" )

	for k,v in pairs( self._views ) do
		--print(k,v)
		v:removeSelf()
		self._views[k] = nil
	end
end




function Scroller:_loadSlides()
	-- print( "Scroller:_loadSlides" )

	local screenW, screenH = display.contentWidth, display.contentHeight

	-- delete all current slides
	-- TODO

	-- setup new slides
	for i, slide in ipairs( self._slides ) do

		self:insert( slide )
		if i == self._curr_slide then
			slide.x, slide.y = 0,0
		else
			slide.x, slide.y = screenW,0
		end
	end

	self:_updateSlides( self._curr_slide )

end



function Scroller:_nextSlide()
	-- print("Scroller:_nextSlide")

	local screenW, screenH = display.contentWidth, display.contentHeight

	local PADDING = self._padding
	local TIME = Scroller.TRANSITION_TIME
	local twn = {}
	local idx = self._curr_slide
	local o, f
	local event_data

	f = self:createCallback( Scroller._onComplete_handler )

	o = self._slides[idx]
	o.isVisible = true
	twn.c = transition.to( o, {time=TIME, x=-(screenW + PADDING[1]), transition=easing.outExpo } )

	o = self._slides[idx+1]
	o.isVisible = true
	twn.n = transition.to( o, {time=TIME, x=0, transition=easing.outExpo, onComplete=f } )

	twn.p = nil

	self._tween = twn
	self._curr_slide = self._curr_slide + 1

	-- dispatch on stage event
	event_data = {
		index = self._curr_slide,
		slide = self._slides[ self._curr_slide ]
	}
	if self._onStage then self._onStage( { event_data } ) end
	self:_dispatchEvent( Scroller.CENTER_STAGE, event_data )
end


function Scroller:_prevSlide()
	--print("Scroller:_prevSlide ")

	local screenW, screenH = display.contentWidth, display.contentHeight

	local TIME = Scroller.TRANSITION_TIME
	local PADDING = self._padding
	local twn = {}
	local idx = self._curr_slide
	local o, f
	local event_data


	f = self:createCallback( Scroller._onComplete_handler )

	o = self._slides[idx]
	o.isVisible = true
	twn.c = transition.to( o, {time=TIME, x=(screenW + PADDING[1]), transition=easing.outExpo } )

	o = self._slides[idx-1]
	o.isVisible = true
	twn.p = transition.to( o, {time=TIME, x=0, transition=easing.outExpo, onComplete=f } )

	twn.n = nil

	self._tween = twn
	self._curr_slide = self._curr_slide - 1

	-- dispatch on stage event
	event_data = {
		index = self._curr_slide,
		slide = self._slides[ self._curr_slide ]
	}
	if self._onStage then self._onStage( { event_data } ) end

	self:_dispatchEvent( Scroller.CENTER_STAGE, event_data )
end



function Scroller:_cancelTweens()
	--print( "Scroller:_cancelTweens" )

	-- cancel the animation
	-- TODO

	-- set to nil
	self._tween = nil

end



-- put slides to left/right of current
--
function Scroller:_updateSlides( value )
	-- print( "Scroller:_updateSlides ", value )

	local screenW, screenH = display.contentWidth, display.contentHeight
	local slides = self._slides
	local PADDING = self._padding

	if value < #slides then
		slides[value+1].x = (screenW + PADDING[1])
	end
	if value > 1 then
		slides[value-1].x = -(screenW + PADDING[1])
	end

end




--== Event Handlers



function Scroller:_onComplete_handler( event )
	--print("Scroller:_onComplete_handler ", event )

	self._canInteract = true
	self:_updateSlides( self._curr_slide )

	-- turn off slides to left/right of current
	for i, slide in ipairs( self._slides ) do
		if self._curr_slide ~= i then
			slide.isVisible = false
		end
	end

	self:_cancelTweens()

end




function Scroller:touch( event )
	-- print( "Scroller:touch ", event.phase )

	local phase = event.phase


	if phase == "began" then

		display.getCurrentStage():setFocus( self.display )
		self.isFocus = true

		self.startPos = event.x
		self.prevPos = event.x


	elseif self.isFocus then

		local PADDING = self._padding
		local curr_slide = self._curr_slide
		local slides = self._slides

		if phase == 'moved' then

			if self._tween then self:_cancelTweens() end


			local delta = event.x - self.prevPos
			self.prevPos = event.x

			slides[curr_slide].x = slides[curr_slide].x + delta

			if slides[curr_slide-1] then
				slides[curr_slide-1].isVisible = true
				slides[curr_slide-1].x = slides[curr_slide-1].x + delta
			end

			if slides[curr_slide+1] then
				slides[curr_slide+1].isVisible = true
				slides[curr_slide+1].x = slides[curr_slide+1].x +delta
			end

			if not self._isMoving and self._onStage then
					local event_data = {} -- list of objects
					local idx, o

				idx = curr_slide-1
				o = slides[idx]
				if o then
					table.insert( event_data, { slide=o, index=idx }  )
				end
				idx = curr_slide+1
				o = slides[idx]
				if slides[curr_slide+1] then
					table.insert( event_data, { slide=o, index=idx }  )
				end


				if self._onStage then self._onStage( { event_data } ) end

			end

			self._isMoving = true


		elseif phase == "ended" or phase == "cancelled" then

			local dragDistance = event.x - self.startPos


			-- A tap took place
			if math.abs(dragDistance) <= 10 and self._canInteract then
				self:_dispatchEvent( Scroller.UI_TAPPED )
			end

			if (self._canInteract == true) then
				self._canInteract = false

				if (dragDistance < -40 and curr_slide < #self._slides) then
					self:nextSlide()
				elseif (dragDistance > 40 and curr_slide > 1) then
					self:prevSlide()
				else
					self:cancelMove()
				end
			end

			if ( phase == "cancelled" ) then
				self:cancelMove()
			end

			display.getCurrentStage():setFocus( nil )
			self.isFocus = false
			self._isMoving = false


		end -- moved/ended

	end -- begin/is.focus

	return true
end




-- callback from main image lod
function Scroller:_dispatchEvent( e_type, data )
	--print( "Scroller:_dispatchEvent ", e_type )

	params = params or {}

	-- setup custom event
	local e = {
		name = Scroller.EVENT,
		type = e_type,
		data = data
	}

	self:dispatchEvent( e )
end



return Scroller




