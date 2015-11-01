## Synopsis

This is a collection of Corona SDK functions for Active Documents, as requested by JCH.
Functions (April, 2015)
* Slideviewer
* Styled wrapped text
* Scrolling styled wrapped text
* Accordian text box

## Code Example

Show what the library does as concisely as possible, developers should be able to figure out **how** your project solves their problem by looking at the code example. Make sure the API you are showing off is obvious, and that your code is short and concise.

### Slideviewer
This is like a Javascript slider (see http://www.jssor.com/demos/full-width-slider.html for an example).
It shows a series of slides in a box. The user can swipe between the slides.

####Slideviewer Installation :
From the main folder of this repo, copy these files to your main folder:
* dmc_corona_boot.lua
* dmc_corona.cfg

Next, in your main Corona app folder, create a folder named "scripts". From the "scripts" folder in this repo, copy these folders to your scripts folder.
* dmc
* funx.lua
* slideviewer
* textrender

Your app folder should now look something like this:
* main folder
	* main.lua (your main file)
	* dmc_corona_boot.lua
	* dmc_corona.cfg
	* scripts
		* dmc
		* funx.lua
		* slideviewer
		* textrender


####Slideviewer Options :
* width : [integer] width in pixels
* height : [integer] height in pixels
* x : [integer] left position of viewer window in pixels
* y : [integer] top position of viewer window in pixels
* backgroundColor : [table] { red, green, blue, alpha } Viewer window background color, default is transparent
* automask : [boolean] Default is true. Masks the slideshow to the viewing port. Not needed for full-screen shows.
* x_offset : [integer] Unknown, does nothing.
* y_offset : [integer] Slide position vertical offset (moves slides down),
* autoAdvanceTime : [integer] Time in milliseconds between slide changes
* autoAdvanceState : [boolean] Default is false. If true, slide show will auto advance, left to right.
* margins : [table] Default internal margin around a slide (padding) in pixels
	* top : [integer] margin in pixels
	* left : [integer] margin in pixels
	* bottom : [integer] margin in pixels
	* right : [integer] margin in pixels
* slides : [table]
	* backgroundColor : [integer] {(1/slideCount) * i, 0.6, 0.2 * i},
	* width : [integer] slideWidth,
	* height : [integer] slideHeight,
	* margins : [table] Internal margin around a slide (padding) in pixels
		* top : [integer] margin in pixels
		* left : [integer] margin in pixels
		* bottom : [integer] margin in pixels
		* right : [integer] margin in pixels
	* data : [table]
		* idx : [integer] index of the slide
		* str : [string] a custom string to store and retrieve for each slide, e.g. a code
		* isCategory : [boolean] Default is false. Does not seem to have any affect.
		* slide : [display object] A Corona display object, e.g. a group with a picture and text

####Slideviewer Variables :
If your slideviewer instance is called "mySlideViewer", then you can modify :
mySlideviewer._autoAdvanceState 
mySlideviewer._autoAdvanceTime 

####Slideviewer Examples :

```
local slideviewer = require("scripts.slideviewer.slideviewer")

local params = {
	width = 400, 
	height = 300,
	x = 50,
	y = 50,
	margins = { top = 20, left =40, bottom = 40, right = 40, },
	backgroundColor = { 0.7, 0.1, 1, 1.0 },
	automask = true,
	slides = slides,
	autoAdvanceTime = 2000,
	autoAdvance = true,
}

local myslideviewer = slideviewer.new ( params )

-- go to a slide by number without animation
local function goSlide( index )
	myslideviewer:gotoSlide( index )	
end

-- go to a slide by number with animation
local function scrollToSlide( index )
	myslideviewer:do_scroll_to_slide( index )
end

local function goPrevSlide()
	myslideviewer:scroll_one_slide( "left" )	
end

local function goNextSlide()
	myslideviewer:scroll_one_slide( "right" )
end


local function goFirstSlide()
	myslideviewer:do_scroll_to_slide( "first" )
end


local function goLastSlide()
	myslideviewer:do_scroll_to_slide( "last" )
end

local function removeShow()
	if (myslideviewer) then
		myslideviewer:removeSelf()
		myslideviewer = nil
	end	
end

local function startShow()
	if (not myslideviewer) then
		myslideviewer = slideviewer.new ( params )
	end
end

local function switchAutoAdvance( e )
	myslideviewer:flip_auto_advance()
	if (myslideviewer._autoAdvanceState) then
		e.target:setLabel( "Manual Advance" )
	else
		e.target:setLabel( "Auto Advance" )
	end
	
end
```

#Work In Progress Or Not Begun....

### SliderFromFile
Params:
* (see above)
* source file name, of the file containing a JSON-format text file, and JPG/PNG graphics, as required for display
 

#### Notes:
Elements to create to a slider will be in a JSON. Elements relatives to a catalog will be in a global JSON lets say pageExtraContent. When I will display a page, the table will be checked. 
`pageExtraContent[6]={“slider1234-1”,”accordion7”,”scroll8”}`
where the table elements are names of zip files containing elements. 
If the file is present, then elements will be loaded and displayed.


## Motivation

A short description of the motivation behind the creation and maintenance of the project. This should explain **why** the project exists.

## Installation

Provide code examples and explanations of how to get the project.

## API Reference

Depending on the size of the project, if it is small and simple enough the reference docs can be added to the README. For medium size to larger projects it is important to at least provide a link to where the API reference docs live.

## Tests

Describe and show how to run the tests with code examples.

## Contributors

Let people know how they can dive into the project, include important links to things like issue trackers, irc, twitter accounts if applicable.

## License

A short snippet describing the license (MIT, Apache, etc.)
