-- main.lua

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

-- Patches to allow Graphics 1.0 calls while using Graphics 2.0
--require( 'scripts.dmc.dmc_kompatible' )
--require( 'scripts.dmc.dmc_kolor' )
--require ( 'scripts.patches.refPointConversions' )

-- Default anchor settings
--display.setDefault( "anchorX", 0 )
--display.setDefault( "anchorY", 0 )

-- MUST LOAD BEFORE ANYTHING ELSE
-- Patches to allow Graphics 1.0 calls while using Graphics 2.0
require( 'scripts.dmc.dmc_kolor' )

-- My useful function collection
local funx = require("scripts.funx")
local textrender = require("scripts.textrender.textrender")

-- Make a local copy of the application settings global
local screenW, screenH = display.contentWidth, display.contentHeight
local viewableScreenW, viewableScreenH = display.viewableContentWidth, display.viewableContentHeight
local screenOffsetW, screenOffsetH = display.contentWidth -	 display.viewableContentWidth, display.contentHeight - display.viewableContentHeight
local midscreenX = screenW*(0.5)
local midscreenY = screenH*(0.5)



local showTextrenderExample = false
local showDialogExample = true


if (showTextrenderExample) then
	local w = 510
	--w = 270

	local textStyles = funx.loadTextStyles("scripts/textrender/textstyles.txt", system.ResourceDirectory)

	local mytext = funx.readFile("textrender-sample-text.html")

	-- To cache using files, set the cache directory
	-- To cache using the sqlLite database (faster), set cacheDir to nil
	local cacheDir = "textrender_cache"
	funx.mkdir (cacheDir, "",false, system.CachesDirectory)




	------------------------------------------------------------
	------------------------------------------------------------

	local reps = 1

	------------------------------------------------------------
	------------------------------------------------------------


	-- To prevent caching, set the cache dir to empty
	cacheDir = ""

	local params = {
		text = mytext,
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
		maxHeight = nil,	-- set to nil for a scrolling textfield, otherwise chopped!
		minWordLen = 2,
		textstyles = textStyles,
		defaultStyle = "Normal",
		cacheDir = cacheDir,
		cacheToDB = false,
		isHTML = true,
		useHTMLSpacing = true,
		hyperlinkFillColor = "250,250,0,180",
		hyperlinkTextColor = "0,0,255,255",
		testing = false,
	}


	local tmsg = ""




	------------------------------------------
	-- Page background
	local bkgd = display.newRect(0,0,screenW, screenH)
	bkgd:setFillColor(255,255,255,255)
	funx.anchor(bkgd, "TopLeft")
	bkgd.x = 0
	bkgd.y = 0
	bkgd.strokeWidth = 20
	bkgd:setStrokeColor(0,200,200)

	local t, t2, textframe, textframe2

	------------
	-- We clear the cache before begining, so first render creates a cache, second uses it.
	textrender.clearAllCaches(cacheDir)

	------------------------------------------
	-- Make a textblock
	params.text = mytext .. tmsg
	params.cacheDir = cacheDir
	params.cacheToDB = false

	local x,y = 50,100
	local h = 400

	t = textrender.autoWrappedText(params)
	t.x = 10
	t.y = 10

	params.testing = false

	local yAdjustment = t.yAdjustment

	------------------------------------------
	-- Make the textblock a scrolling text block
	local options = {
		maxVisibleHeight = h,
		parentTouchObject = nil,
	
		hideBackground = false,
		backgroundColor = {255,255,255},	-- hidden by the above line
	
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
	local scrollblock = {}

	scrollblock = t:fitBlockToHeight( options )

	scrollblock.x = x
	scrollblock.y = y



	------------------------------------------
	-- Labels
	local label1 = display.newText("This Text is from XML", 0, 0, nil, 18)
	funx.anchor(label1, "BottomLeft")
	label1.x = x
	label1.y = y - 30
	label1:setFillColor(100,100,0) -- transparent

	------------------------------------------
	-- Frame the text
	textframe = display.newRect(0,0, w+20, h + 20)
	textframe:setFillColor(100,100,100,120) -- transparent
	textframe:setStrokeColor(0,0,0,255)
	textframe.strokeWidth = 1
	funx.anchor(textframe, "TopLeft")
	textframe.x = x-10
	textframe.y = y-10
	textframe:toBack()


	bkgd:toBack()

	------------------------------------------


	if textrender.db and textrender.db:isopen() then
		textrender.db:close()
		print ("MAIN TESTING: Close DB. The textrender database was left open?")
	end



	local widget = require ( "widget" )
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
				label = "WIREFRAME",
				labelColor = { default={ 200, 1, 1 }, over={ 250, 0, 0, 0.5 } },
				fontSize = 20,
				x =screenW - 100,
				y=50,
				onRelease = toggleWireframe,
			}
	wfb:toFront()

end -- show textrender example

if showDialogExample then

	------------------------------------------
	-- Dialog
	-- Create a dialog
	------------------------------------------

	-- This creates a dialog generator function
	local dialog = require ("scripts.dialog.dialog")

	-- Be CAREFUL not to use names of existing lua files, e.g. settings.lua unless you mean it!!!
	local settingsDialogName = "settingsDialog"
	local signInDialogName = "signinDialog"
	local newAccountDialogName = "createAccountDialog"
	local askPasswordDialogName = "askPasswordDialog"

	-- Should we use Modal dialogs or let them stick around?
	-- Probably not if we want dialogs to be able to jump around. If we allow modal,
	-- then dialogs can lose their storyboard.scenes, not a good thing.
	local isModal = true

	local function createSignInDialog(dialogName, callback)
		local options = {
			effect = "fade",
			time = 250,
			isModal = isModal,
		}
	
		-- Values to replace {{code}} or {{index:subindex}} in the dialog definition.
		local substitutionValues = {
			shelves = {
				bookstore = "My Bookstore",
			},
			currentuser = {
				username = "John Doe",
			},
		}
	
	
		-- Options for the dialog builder
		local params = {
			name = dialogName,
			substitutions = substitutionValues,
			restoreValues = false,	-- restore previous results from disk
			writeValues = false,	-- save the results to disk
			onSubmitButton = nil, -- set this function or have another scene check storyboard.dialogResults
			--onCancelButton = showSettingsDialog, -- set this function or have another scene check storyboard.dialogResults
			cancelToSceneName = settingsDialogName,
			showSavedFeedback = false,	-- show "saved" if save succeeds
			options = options,
			isModal = isModal,
			functions = {
				createNewAccountDialog = openCreateNewAccountDialog,
				confirmAccount = confirmAccount,
				signin = {
					action = signin_user,
					success = callback,
					failure = nil,
				},
			},
			cancelToSceneName = settingsDialogName,
		}


		-- Creates a new dialog scene
		dialog.new(params)
	end


	------------------------------------------------------------------------
	--- Show a dialog
	-- @windowName	[string] The name of the dialog window (the scene?)
	-- @values	Table of key-value pairs for substition in the dialog, e.g. a username or title.
	-- @conditions [table] A table of key-value pairs. The key is the name of a field in the dialog, the value is true/false, indicating whether the show the field.
	-- @vars 	table of pass-through vars, e.g ID of an item this dialog is about.
	local function showDialog(windowName, vars)
		local conditions = {}
		local values = {
			shelves = {
				registerDisplayURL = "http://google.com/",
				bookstore = "My Bookstore",
			},
		}
		local vars = {}
		dialog:showWindow(windowName, funx.flattenTable(values), conditions, vars)
	end


	--- Shortcut to show sign-in dialog
	local function showSignInUserDialog()
		showDialog(signInDialogName)
	end


	-- Print values to the monitor from the completed dialog.
	local function dialogCallBack(values)
		funx.dump(values)
	end

	createSignInDialog(signInDialogName, dialogCallBack)
	showSignInUserDialog()


end -- show dialog example