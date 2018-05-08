--	Title: FacSetup
--
--	Version: 1.0 - useless
--
--	Description: Installs Factionet (downloads the
--	main Factionet script). After I got rid of the
--	image files and just put them in the main program
--	this actually became kind of useless... Oh well,
--	who doesn't like useless programs?!
--
--	Author: margeobur

-- 'global' variables
local rootDir = shell.dir()
local installPath = rootDir .. "/Factionet"
local stringInPathbox
local done = false

-- functions

local function eWrite(pstring, xCoord, yCoord) --saves so many lines!
	term.setCursorPos(xCoord,yCoord)
	term.write(pstring)
end

local function displayHomeScreen()
	term.setBackgroundColour(colours.white)
	term.clear()
	term.setTextColour(colours.green)
	eWrite("Factionet Setup",18,6)

	for i=12, 16 do
		paintutils.drawLine(14,i,37,i,colours.lightGrey)
	end
	term.setTextColour(colours.black)
	paintutils.drawLine(16,13,35,13,colours.white)
	eWrite("Install",23,13)
	paintutils.drawLine(16,15,35,15,colours.white)
	eWrite("Update",23,15)

	paintutils.drawPixel(51,1,colours.green)
	term.setTextColour(colours.red)
	eWrite("X",51,1)
end

local function displayInstallScreen()
	term.setBackgroundColour(colours.white)
	term.setTextColour(colours.black)
	term.clear()

	paintutils.drawLine(50,1,51,1,colours.green)
	term.setTextColour(colours.red)
	eWrite("<-",50,1)

	term.setBackgroundColour(colours.white)
	term.setTextColour(colours.black)
	eWrite("Factionet will be installed in",12,6)
	eWrite("   the following directory:   ",12,7)
	for i=12,16 do
		paintutils.drawLine(9,i,42,i,colours.lightGrey)
	end
	paintutils.drawLine(10,13,41,13,colours.white)
	if string.len(installPath) > 32 then
		local temp = string.sub(installPath,1,32)
		eWrite(temp,10,13)
	else
		eWrite(installPath,10,13)
	end

	paintutils.drawLine(16,15,35,15,colours.white)
	eWrite("Install",23,15)
end

local function editInstallPath()
	local event, param1, param2, param3 = nil,nil,nil,nil
	local currentPos = 0
	local displayString = ""
	if string.len(installPath) > 32 then
		displayString = string.sub(installPath,-32,-1)
		currentPos = 41
	else
		displayString = installPath
		currentPos = string.len(installPath) + 10
	end
	eWrite(displayString,10,13)
	term.setCursorPos(currentPos,13)
	term.setCursorBlink(true)

	while true do
		event, param1, param2, param3 = os.pullEvent()
		if event == "mouse_click" then
			if param2 > 9 and param2 < 42 and param3 == 13 then

			else
				break
			end

		elseif event == "key" then
			if param1 == keys.enter then
				break
			elseif param1 == keys.backspace then
				if string.len(installPath) < 33 then
					if currentPos < 11 then
						-- do nothing because we can't backspace
					else
						local temp = string.sub(installPath, 1 , -2)
						installPath = temp
						eWrite(" ",currentPos - 1,13)
						currentPos = currentPos - 1
						term.setCursorPos(currentPos,13)
					end
				end
			end
		elseif event == "char" then
			if currentPos < 31 + 11 then
				eWrite(param1,currentPos,13)
				currentPos = currentPos + 1
				installPath = installPath .. param1
			end
		end
	end

	term.setCursorBlink(false)
end

local function askBox(string1,string2,string3,string4)
	for i=10,16 do
		paintutils.drawLine(14,i,37,i,colours.green)
	end
	term.setTextColour(colours.magenta)
	term.setBackgroundColour(colours.green)
	eWrite(string1,15,11)
	eWrite(string2,15,12)
	eWrite(string3,15,13)
	eWrite(string4,15,14)

	term.setTextColour(colours.black)
	term.setBackgroundColour(colours.white)
	paintutils.drawLine(16,15,25,15,colours.white)
	eWrite("No",20,15)
	paintutils.drawLine(27,15,35,15,colours.white)
	eWrite("Yes",30,15)

	while true do
		local event, button, xCoord, yCoord = os.pullEvent("mouse_click")
		if xCoord > 15 and xCoord < 26 and yCoord == 15 then
			return false
		elseif xCoord > 26 and xCoord < 36 and yCoord == 15 then
			return true
		end
	end

	return true
end

-- install: downloads the main script and creates
-- the image files

local function install()
	if not fs.isDir(installPath) then
		if not askBox("That filepath does not","exist, should I create","    it?","") then
			return false
		else
			fs.makeDir(installPath)
		end
	end

	if not http then
		for i=9,16 do
			paintutils.drawLine(14,i,37,i,colours.green)
		end
		term.setTextColour(colours.magenta)
		term.setBackgroundColour(colours.green)
		eWrite("The http API is not",16,10)
		eWrite("enabled on this map/",16,11)
		eWrite("server. It needs to be",15,12)
		eWrite("enabled to connect to",15,13)
		eWrite("pastebin.",21,14)

		paintutils.drawLine(15,15,35,15,colours.white)
		term.setTextColour(colours.black)
		term.setBackgroundColour(colours.white)
		eWrite("ok",26,15)

		while true do
			local event, button, xCoord, yCoord = os.pullEvent("mouse_click")
			if xCoord > 15 and xCoord < 36 and yCoord == 15 then
				return false
			end
		end
	end

	term.clear()
	for i=9,11 do
		paintutils.drawLine(11,i,40,i,colours.lightGrey)
	end
	term.setTextColour(colours.black)
	term.setBackgroundColour(colours.lightGrey)
	eWrite("connecting to pastebin...",13,10)

	local response = http.get(
		"http://pastebin.com/raw.php?i="..textutils.urlEncode( "8Uhx0G2C" )
		)

	if response then
		eWrite("installing main script...",13,10)
		sleep(1)

		local sResponse = response.readAll()
		response.close()

		local mainFile = fs.open( installPath .. "/Factionet" , "w" )
		mainFile.write( sResponse )
		mainFile.close()

	else
		for i=10,15 do
			paintutils.drawLine(14,i,37,i,colours.lightGrey)
		end
		term.setTextColour(colours.black)
		term.setBackgroundColour(colours.lightGrey)
		eWrite("Could not connect to",16,11)
		eWrite("pastebin",16,12)

		paintutils.drawLine(15,14,35,14,colours.white)
		term.setTextColour(colours.black)
		term.setBackgroundColour(colours.white)
		eWrite("ok",26,14)

		while true do
			local event, button, xCoord, yCoord = os.pullEvent("mouse_click")
			if xCoord > 15 and xCoord < 36 and yCoord == 14 then
				return false
			end
		end
		return false
	end

	if not fs.isDir(installPath .. "/sessions") then
		fs.makeDir(installPath .. "/sessions")
	end

	term.setBackgroundColour(colours.white)
	term.clear()

	for i=9,15 do
		paintutils.drawLine(14,i,37,i,colours.lightGrey)
	end
	term.setTextColour(colours.black)
	term.setBackgroundColour(colours.lightGrey)
	eWrite("Success. Thank you for",15,10)
	eWrite("choosing to install",16,11)
	eWrite("Factionet, enjoy!",17,12)

	paintutils.drawLine(15,14,35,14,colours.white)
	term.setTextColour(colours.black)
	term.setBackgroundColour(colours.white)
	eWrite("ok",26,14)

	while true do
		local event, button, xCoord, yCoord = os.pullEvent("mouse_click")
		if xCoord > 15 and xCoord < 36 and yCoord == 14 then
			return true
		end
	end
	return 0
end

local function displayUpdateScreen()
	term.setBackgroundColour(colours.white)
	term.setTextColour(colours.black)
	term.clear()

	paintutils.drawLine(50,1,51,1,colours.green)
	term.setTextColour(colours.red)
	eWrite("<-",50,1)

	term.setBackgroundColour(colours.white)
	term.setTextColour(colours.black)
	eWrite("Directory of your Factionet",12,6)
	eWrite("   installation:   ",15,7)
	for i=12,16 do
		paintutils.drawLine(9,i,42,i,colours.lightGrey)
	end
	paintutils.drawLine(10,13,41,13,colours.white)
	if string.len(installPath) > 32 then
		local temp = string.sub(installPath,1,32)
		eWrite(temp,10,13)
	else
		eWrite(installPath,10,13)
	end

	paintutils.drawLine(16,15,35,15,colours.white)
	eWrite("Update",23,15)
end

local function Update()
	if not fs.isDir(installPath) then
		if not askBox("That filepath does not","exist, would you like","to create it and","install Factionet there?") then
			return false
		else
			fs.makeDir(installPath)
			return 2
		end
	elseif not fs.exists(installPath .. "/Factionet") or not fs.exists(installPath .. "/sessions") then
		if not askBox("  Factionet is not"," installed properly at"," this location. Do you","want to install it there?") then
			return false
		else
			return 2
		end
	end
	if not http then
		for i=9,16 do
			paintutils.drawLine(14,i,37,i,colours.green)
		end
		term.setTextColour(colours.magenta)
		term.setBackgroundColour(colours.green)
		eWrite("The http API is not",16,10)
		eWrite("enabled on this map/",16,11)
		eWrite("server. It needs to be",15,12)
		eWrite("enabled to connect to",15,13)
		eWrite("pastebin.",21,14)

		paintutils.drawLine(15,15,35,15,colours.white)
		term.setTextColour(colours.black)
		term.setBackgroundColour(colours.white)
		eWrite("ok",26,15)

		while true do
			local event, button, xCoord, yCoord = os.pullEvent("mouse_click")
			if xCoord > 15 and xCoord < 36 and yCoord == 15 then
				return false
			end
		end
	end

	--otherwise...

	term.clear()
	for i=9,11 do
		paintutils.drawLine(11,i,40,i,colours.lightGrey)
	end
	term.setTextColour(colours.black)
	term.setBackgroundColour(colours.lightGrey)
	eWrite("connecting to pastebin...",13,10)

	local response = http.get(
		"http://pastebin.com/raw.php?i="..textutils.urlEncode( "8Uhx0G2C" )
		)

	if response then
		eWrite("replacing...",13,10)

		local sResponse = response.readAll()
		response.close()

		local mainFile = fs.open( installPath .. "/Factionet" , "w" )
		mainFile.write( sResponse )
		mainFile.close()

	else
		for i=10,15 do
			paintutils.drawLine(14,i,37,i,colours.lightGrey)
		end
		term.setTextColour(colours.black)
		term.setBackgroundColour(colours.lightGrey)
		eWrite("Could not connect to",16,11)
		eWrite("pastebin",16,12)

		paintutils.drawLine(15,14,35,14,colours.white)
		term.setTextColour(colours.black)
		term.setBackgroundColour(colours.white)
		eWrite("ok",26,14)

		while true do
			local event, button, xCoord, yCoord = os.pullEvent("mouse_click")
			if xCoord > 15 and xCoord < 36 and yCoord == 14 then
				return false
			end
		end
		return false
	end

	term.setBackgroundColour(colours.white)
	term.clear()

	for i=9,15 do
		paintutils.drawLine(14,i,37,i,colours.lightGrey)
	end
	term.setTextColour(colours.black)
	term.setBackgroundColour(colours.lightGrey)
	eWrite("Success. Factionet is",15,10)
	eWrite("up to date. :)",16,11)
	eWrite("",17,12)

	paintutils.drawLine(15,14,35,14,colours.white)
	term.setTextColour(colours.black)
	term.setBackgroundColour(colours.white)
	eWrite("ok",26,14)

	while true do
		local event, button, xCoord, yCoord = os.pullEvent("mouse_click")
		if xCoord > 15 and xCoord < 36 and yCoord == 14 then
			return 1
		end
	end

	return 0
end

-- functionality begins here
local event, param1, param2, param3 = "",0,0,0

while true do
	displayHomeScreen()
	event, param1, param2, param3 = os.pullEvent()

	if event == "mouse_click" then
		if param2 == 51 and param3 == 1 then
			term.setBackgroundColour(colours.black)
			term.clear()
			term.setCursorPos(1,1)
			return 0
		elseif param2 > 15 and param2 < 36 and param3 == 13 then
			while true do
				displayInstallScreen()
				event, param1, param2, param3 = os.pullEvent()
				if event == "mouse_click" then
					if param2 > 49 and param3 == 1 then
						break
					elseif param2 > 9 and param2 < 42 and param3 == 13 then
						editInstallPath()
					elseif param2 > 15 and param2 < 36 and param3 == 15 then
						if install() then
							done = true
							break
						end
					end
				end
			end
		elseif param2 > 15 and param2 < 36 and param3 == 15 then
			while true do
				displayUpdateScreen()
				event, param1, param2, param3 = os.pullEvent()
				if event == "mouse_click" then
					if param2 > 49 and param3 == 1 then
						break
					elseif param2 > 9 and param2 < 42 and param3 == 13 then
						editInstallPath()
					elseif param2 > 15 and param2 < 36 and param3 == 15 then
						local temp = Update()
						if temp == 1 then
							done = true
							break
						elseif temp == 2 then
							displayInstallScreen()
							if install() then
								done = true
								break
							end
						end
					end
				end
			end
		end
	end

	if done then
		break
	end
end

term.setBackgroundColour(colours.black)
term.clear()
term.setCursorPos(1,1)