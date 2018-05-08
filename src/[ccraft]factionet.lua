--	Title: Factionet
--
--	Version: 1.1
--
--	Description: A fairly advanced messaging tool for
--	ComputerCraft. Is both a client and sever rolled into
--	one. Neat GUI and other features.
--
--	Author: margeobur

--test for non-advanced computer:
if not term.isColor() then
	print("Sorry, this program must be run on an advanced")
	print("computer. Press any key to continue...")
	os.pullEvent("key")
	return false
end

-- *** Global Variables (but local to the program) ***
local rootDir = shell.dir()
local hosting = false
local serverName = ""
local running = false

local chatList = {}			--complete history of chat lines
local chatScreenList = {}	--list of lines of chat on the screen
local lastLine = 0			--indice of the last line in the complete history of chat
local lastScreenLine = 0	--indice of the last line in the list of chat lines on screen
local scrollAmount = 0
local chatExistsAlready = false

local userList = {}
local userScreenList = {}
local lastULline = 0
local lastULScreenLine = 0
local ULscrollAmount = 0
local usersAlreadyOn = false

local hostID, myID = nil, os.getComputerID()
local channelOne = nil
local channelTwo = nil
local modem = nil
local modemSide = ""

--hosting variables
local sessionList = {}
local noSessions = 0
local newSession = nil
local sFilePath = nil
local sPassword = ""
local userList = {}

--client variables
local myuser = ""

-- **************** Functions ********************

--[[
eWrite():
	Boy, has this saved space!
]]
local function eWrite(pstring, xCoord, yCoord)
	term.setCursorPos(xCoord,yCoord)
	term.write(pstring)
end

--[[
getLine() and writeLine():
	Well, I was going to use these functions
	but I didn't end up needing them...
]]
local function getLine(filePath,lineNumber)
	if not fs.exists(filePath) then
		return false
	end
	local text = ""
	local fileHandle = fs.open(filePath, "r")
	for i=1,lineNumber do
		text = fileHandle.readLine()
		if not text then
			break
		end
	end
	fileHandle.close()
	if not text then
		return false
	else
		return text
	end
end

local function writeLine(filePath,lineNumber,newText)
	if not fs.exists(filePath) then
		return false
	end
	if type(newText) ~= "string" then
		return false
	end
	local beforeLine, afterLine = "", ""
	local currentLine, i, j = 1, 0, 0			-- i will be the indice of
	local fileHandle = fs.open(filePath, "r")	-- our wanted newline and j
	local wholeFile = fileHandle.readAll()		-- will be the indice of the
	fileHandle.close()							-- next newline
	for w in string.gmatch(wholeFile, "%a") do
		if w == "\n" then
			currentLine = currentLine + 1
		end
		if currentLine <= lineNumber then
			i = i + 1
		end
		if currentLine <= lineNumber + 1 then
			j = j + 1
		end
	end
	if currentLine < lineNumber then	-- i.e. if lineNumber is past the file
		return nil
	else
		beforeLine = string.sub(wholeFile, 1 , i)
		afterLine = string.sub(wholeFile, j)
		wholeFile = beforeLine .. newText .. afterLine
		fileHandle = fs.open(filePath, "w")
		fileHandle.write(wholeFile)
		fileHandle.close()
		return true	-- returns true on success
	end
end





-- ******* Menu Software ******

--[[
displayHomeScreen():
	This displays the FactioNET logo in the menu.
	I looked at the paintutils api to see how files
	were loaded so that I could just 'make' the image
	in-program instead of having a file with the image.
]]
local function displayHomeScreen()
	local image = {}
	image[1] = "                         dd   d ddd ddddd"
	image[2] = "dddd ddd ddd ddd ddd ddd d d  d d     d"
	image[3] = "d    d d d    d   d  d d d  d d ddd   d"
	image[4] = "ddd  ddd d    d   d  d d d   dd d     d"
	image[5] = "d    d d ddd  d  ddd ddd d    d ddd   d"

	term.setBackgroundColour(colours.white)
	term.setTextColour(colours.black)
	term.clear()

	--** coppied direct from paintutils **
	local tColourLookup = {}
	for n=1,16 do
		tColourLookup[ string.byte( "0123456789abcdef",n,n ) ] = 2^(n-1)
	end

	local tImage= {}
	local i = 1
	local sLine = image[i]
	while sLine do
		local tLine = {}
		for x=1,sLine:len() do
			tLine[x] = tColourLookup[ string.byte(sLine,x,x) ] or 0
		end
		table.insert( tImage, tLine )
		i = i + 1
		sLine = image[i]
	end

	--**

	paintutils.drawImage(tImage, 6,3)
	term.setBackgroundColour(colours.white)
	term.setTextColour(colours.red)
	eWrite("by margeobur", 40,8)
end

--[[
displayExit():
	ditto
]]
local function displayExit()
	term.setBackgroundColour(colours.white)
	term.setTextColour(colours.black)
	term.clear()

	local image = {}
	image[1] = "eee   e   e  eeee"
	image[2] = "e  e   e e   e   "
	image[3] = "eee     e    eeee"
	image[4] = "e  e    e    e   "
	image[5] = "eee     e    eeee"

	local tColourLookup = {}
	for n=1,16 do
		tColourLookup[ string.byte( "0123456789abcdef",n,n ) ] = 2^(n-1)
	end

	local tImage= {}
	local i = 1
	local sLine = image[i]
	while sLine do
		local tLine = {}
		for x=1,sLine:len() do
			tLine[x] = tColourLookup[ string.byte(sLine,x,x) ] or 0
		end
		table.insert( tImage, tLine )
		i = i + 1
		sLine = image[i]
	end

	paintutils.drawImage(tImage, 17,8)
end

--[[
homeMenu():
	Determines what the user wants to do.
	it returns values to determine what happens
	in the main loop. I created this first, so it
	is rather disorganised, but it gets the job
	done.
]]
local function homeMenu()
	while true do
		displayHomeScreen()
		for i=11, 17 do
			paintutils.drawLine(14,i,37,i,colours.lightGrey)
		end
		term.setTextColour(colours.black)
		paintutils.drawLine(16,12,35,12,colours.white)
		eWrite("Host",24,12)
		paintutils.drawLine(16,14,35,14,colours.white)
		eWrite("Join",24,14)
		paintutils.drawLine(16,16,35,16,colours.white)
		eWrite("Exit",24,16)

		local event, button, xCoord, yCoord = os.pullEvent("mouse_click")

		if xCoord > 15 and xCoord < 36 and yCoord == 12 then	--Host

			while true do
				for i=11, 17 do
					paintutils.drawLine(14,i,37,i,colours.lightGrey)
				end
				paintutils.drawLine(16,12,35,12,colours.white)
				paintutils.drawLine(16,14,35,14,colours.white)
				paintutils.drawLine(16,16,35,16,colours.white)
				eWrite("New Server",21,12)
				eWrite("Restore a Server",18,14)
				eWrite("Back",24,16)
				eWrite("                          ",14,18)

				event, button, xCoord, yCoord = os.pullEvent("mouse_click")

				if xCoord > 15 and xCoord < 36 and yCoord == 12 then	--New Server
					for i=11, 17 do
						paintutils.drawLine(14,i,37,i,colours.lightGrey)
					end
					eWrite("   Enter your chat    ",16,12)
					eWrite("   server's name*     ",16,13)
					paintutils.drawLine(16,14,35,14,colours.white)
					paintutils.drawLine(16,16,25,16,colours.white)
					eWrite("Back",19,16)
					paintutils.drawLine(27,16,35,16,colours.white)
					eWrite("Confirm",28,16)
					eWrite("*This can only be set once",14,18)
					while true do
						event, button, xCoord, yCoord = os.pullEvent("mouse_click")
						if xCoord > 15 and xCoord < 36 and yCoord == 14 then	-- enter server name
							paintutils.drawLine(16,14,35,14,colours.white)
							term.setCursorPos(16,14)
							serverName = ""
							serverName = read()
						elseif xCoord > 26 and xCoord < 36 and yCoord == 16 and serverName then	--confirm
							for i=11, 17 do
								paintutils.drawLine(14,i,37,i,colours.lightGrey)
							end
							term.setBackgroundColour(colours.lightGrey)
							eWrite("   Enter your chat    ",16,12)
							eWrite("  server's password   ",16,13)
							term.setBackgroundColour(colours.white)
							eWrite("                          ",14,18)
							paintutils.drawLine(16,14,35,14,colours.white)
							paintutils.drawLine(16,16,25,16,colours.white)
							eWrite("Back",19,16)
							paintutils.drawLine(27,16,35,16,colours.white)
							eWrite("Start!",29,16)
							while true do
								event, button, xCoord, yCoord = os.pullEvent("mouse_click")
								if xCoord > 15 and xCoord < 36 and yCoord == 14 then	--enter server password
									paintutils.drawLine(16,14,35,14,colours.white)
									term.setCursorPos(16,14)
									sPassword = read()
								elseif xCoord > 26 and xCoord < 36 and yCoord == 16 then	--start the server
									sFilePath = rootDir .. "/sessions/" .. serverName
									newSession = true
									while true do
										for i=11, 17 do
											paintutils.drawLine(14,i,37,i,colours.lightGrey)
										end
										hostID = myID
										eWrite("The ID to connect to",16,12)
										eWrite("is ".. hostID,23,13)
										eWrite("Click to continue...",16,15)
										os.pullEvent("mouse_click")
										return 1
									end
								elseif xCoord > 15 and xCoord < 26 and yCoord == 16 then	--back
									break
								end
							end
						elseif xCoord > 15 and xCoord < 26 and yCoord == 16 then	--back
							break
						end
					end

				elseif xCoord > 15 and xCoord < 36 and yCoord == 14 then	--Restore a Server
					local selectedSession = nil
					local posOne, posTwo, posThree = nil, nil, nil

					if not fs.exists(rootDir .. "/sessions") then
						fs.makeDir(rootDir .. "/sessions")
					end
					for i=10, 18 do
						paintutils.drawLine(14,i,37,i,colours.lightGrey)
					end
					for i=11,13 do
						paintutils.drawLine(16,i,34,i,colours.white)
					end
					paintutils.drawLine(16,15,25,15,colours.white)
					eWrite("Delete",18,15)
					paintutils.drawLine(27,15,35,15,colours.white)
					eWrite("Select",28,15)
					paintutils.drawLine(16,17,35,17,colours.white)
					eWrite("Back",24,17)
					paintutils.drawLine(35,11,35,13,colours.lightBlue)
					term.setTextColour(colours.blue)
					eWrite("^",35,11)
					eWrite("v",35,13)
					term.setTextColour(colours.black)
					term.setBackgroundColour(colours.white)

					sessionList = fs.list(rootDir .. "/sessions")
					noSessions = 0
					for i, v in ipairs(sessionList) do
						noSessions = noSessions + 1
					end
					if noSessions > 0 then
						eWrite(sessionList[1],16,11)
					end
					if noSessions > 1 then
						eWrite(sessionList[2],16,12)
					end
					if noSessions > 2 then
						eWrite(sessionList[3],16,13)
					end
					posOne = 1
					posTwo = 2
					posThree = 3

					while true do
						event, button, xCoord, yCoord = os.pullEvent("mouse_click")
						if xCoord == 35 and yCoord == 13 then		-- scroll down
							if noSessions > 3 and posThree ~= noSessions then
								eWrite("                   ",16,11)
								eWrite(sessionList[posTwo],16,11)
								posOne = posOne + 1
								eWrite("                   ",16,12)
								eWrite(sessionList[posThree],16,12)
								posTwo = posTwo + 1
								eWrite("                   ",16,13)
								eWrite(sessionList[posThree + 1],16,13)
								posThree = posThree + 1
							end
						elseif xCoord == 35 and yCoord == 11 then		-- scroll up
							if noSessions > 3 and posOne ~= 1 then
								eWrite("                   ",16,11)
								eWrite(sessionList[posOne - 1],16,11)
								posOne = posOne - 1
								eWrite("                   ",16,12)
								eWrite(sessionList[posTwo - 1],16,12)
								posTwo = posTwo - 1
								eWrite("                   ",16,13)
								eWrite(sessionList[posThree - 1],16,13)
								posThree = posThree - 1
							end
						elseif xCoord > 15 and xCoord < 36 and yCoord == 11 then	--select first list item
							paintutils.drawLine(16,11,34,11,colours.lime)
							paintutils.drawLine(16,12,34,12,colours.white)
							paintutils.drawLine(16,13,34,13,colours.white)
							term.setBackgroundColour(colours.lime)
							eWrite(sessionList[posOne],16,11)
							term.setBackgroundColour(colours.white)
							eWrite(sessionList[posTwo],16,12)
							eWrite(sessionList[posThree],16,13)
							selectedSession = sessionList[posOne]

						elseif xCoord > 15 and xCoord < 36 and yCoord == 12 then	--select second list item
							paintutils.drawLine(16,11,34,11,colours.white)
							paintutils.drawLine(16,12,34,12,colours.lime)
							paintutils.drawLine(16,13,34,13,colours.white)
							term.setBackgroundColour(colours.white)
							eWrite(sessionList[posOne],16,11)
							term.setBackgroundColour(colours.lime)
							eWrite(sessionList[posTwo],16,12)
							term.setBackgroundColour(colours.white)
							eWrite(sessionList[posThree],16,13)
							selectedSession = sessionList[posTwo]

						elseif xCoord > 15 and xCoord < 36 and yCoord == 13 then	--select third list item
							paintutils.drawLine(16,11,34,11,colours.white)
							paintutils.drawLine(16,12,34,12,colours.white)
							paintutils.drawLine(16,13,34,13,colours.lime)
							term.setBackgroundColour(colours.white)
							eWrite(sessionList[posOne],16,11)
							eWrite(sessionList[posTwo],16,12)
							term.setBackgroundColour(colours.lime)
							eWrite(sessionList[posThree],16,13)
							selectedSession = sessionList[posThree]
							term.setBackgroundColour(colours.white)

						elseif xCoord > 15 and xCoord < 26 and yCoord == 15 and selectedSession then	--delete
							paintutils.drawLine(15,15,36,15,colours.lightGrey)
							eWrite("Are you sure you want",15,15)
							eWrite("to delete that save?",15,16)
							paintutils.drawPixel(26,17,colours.lightGrey)
							term.setBackgroundColour(colours.white)
							eWrite("Yes    ",19,17)
							eWrite("   No",27,17)

							while true do
								event, button, xCoord, yCoord = os.pullEvent("mouse_click")
								if xCoord > 15 and xCoord < 26 and yCoord == 17 then
									fs.delete(rootDir .. "/sessions/" .. selectedSession)
									sessionList = fs.list(rootDir .. "/sessions")
									noSessions = 0
									for i, v in ipairs(sessionList) do
										noSessions = noSessions + 1
									end
									if noSessions > 0 then
										eWrite("                   ",16,11)
										eWrite(sessionList[1],16,11)
									end
									if noSessions > 1 then
										eWrite("                   ",16,12)
										eWrite(sessionList[2],16,12)
									end
									if noSessions > 2 then
										eWrite("                   ",16,13)
										eWrite(sessionList[3],16,13)
									end
									posOne = 1
									posTwo = 2
									posThree = 3
									selectedSession = nil
									break
								elseif xCoord > 26 and xCoord < 36 and yCoord == 17 then
									break
								end
							end


							for i=15,16 do
								paintutils.drawLine(15,i,36,i,colours.lightGrey)
							end
							paintutils.drawLine(16,15,25,15,colours.white)
							eWrite("Delete",18,15)
							paintutils.drawLine(27,15,35,15,colours.white)
							eWrite("Select",28,15)
							paintutils.drawLine(16,17,35,17,colours.white)
							eWrite("Back",24,17)


						elseif xCoord > 26 and xCoord < 36 and yCoord == 15  then	--confirm
							serverName = selectedSession
							sFilePath = rootDir .. "/sessions/" .. serverName
							newSession = false
							return 2

						elseif xCoord > 15 and xCoord < 36 and yCoord == 17 then --back
							paintutils.drawLine(14,10,37,10,colours.white)
							paintutils.drawLine(14,18,37,10,colours.white)
							break
						end
					end

				elseif xCoord > 15 and xCoord < 36 and yCoord == 16 then	--back
					break
				end
			end

		elseif xCoord > 15 and xCoord < 36 and yCoord == 14 then	--Join
			while true do
				for i=11, 17 do
					paintutils.drawLine(14,i,37,i,colours.lightGrey)
				end
				eWrite("Enter your host's",18,12)
				eWrite("ID.",25,13)
				paintutils.drawLine(16,14,35,14,colours.white)
				eWrite(hostID,16,14)
				paintutils.drawLine(16,16,25,16,colours.white)
				eWrite("Back",19,16)
				paintutils.drawLine(27,16,35,16,colours.white)
				eWrite("Connect",28,16)

				event, button, xCoord, yCoord = os.pullEvent("mouse_click")
				if xCoord > 15 and xCoord < 35 and yCoord == 14 then	--enter ID
					hostID = -1
					while hostID < 0 do
						for i=11, 17 do
							paintutils.drawLine(14,i,37,i,colours.lightGrey)
						end
						eWrite("Enter your host's",18,12)
						eWrite("ID.",25,13)
						paintutils.drawLine(16,14,35,14,colours.white)
						paintutils.drawLine(16,16,25,16,colours.white)
						eWrite("Back",19,16)
						paintutils.drawLine(27,16,35,16,colours.white)
						eWrite("Connect",28,16)

						term.setCursorPos(16,14)
						local temp = read()
						hostID = tonumber(temp)
						if not hostID or hostID < 0 then
							for i=12, 16 do
								paintutils.drawLine(14,i,37,i,colours.lightGrey)
							end
							eWrite("Error, the ID can't",16,13)
							eWrite(" be below 0 or have",16,14)
							eWrite("      letters      ",16,15)
							hostID = -1
							os.pullEvent("mouse_click")
						end
					end

				elseif xCoord > 26 and xCoord < 36 and yCoord == 16 then	--connect
					return 3

				elseif xCoord > 15 and xCoord < 26 and yCoord == 16 then	--back
					break
				end
			end
		elseif xCoord > 15 and xCoord < 36 and yCoord == 16 then	--Exit
			break
		end
	end
	return 0
end

-- ***** General Software *****
-- functions for both client and host

--[[ displayLoadScreen(): Dunno why I made this XD
	I derped a bit (it is only used once) ]]
local function displayLoadScreen()
	term.setBackgroundColour(colours.white)
	term.clear()
	for i=9,12 do
		paintutils.drawLine(18,i,33,i,colours.lightGrey)
	end
	eWrite("Starting",22,10)
	eWrite("server ...",21,11)
end

--[[
setupGUI():
	This function draws everything to the screen on
	server startup/after connecting. If the host has
	loaded a save and there is already chat, the chat
	is printed. Likewise if there are already users on
	or chat in the history, this will draw those for the
	client.
]]
local function setupGUI()
	term.setBackgroundColour(colours.white)
	term.clear()

	--HotBar
	paintutils.drawLine(1,1,6,1,colours.orange)
	eWrite("[Menu]",1,1)
	paintutils.drawLine(7,1,51,1,colours.grey)
	term.setTextColour(colours.green)
	eWrite("FactioNET | Server:",20,1)
	term.setTextColour(colours.orange)
	eWrite(serverName,40,1)
	term.setTextColour(colours.black)

	--Chat Window
	paintutils.drawLine(1,2,51,2,colours.lightGrey)
	eWrite("Messages:",1,2)
	paintutils.drawLine(34,3,34,15,colours.lightBlue)
	term.setTextColour(colours.blue)
	eWrite("^",34,3)
	eWrite("v",34,15)
	term.setTextColour(colours.black)
	paintutils.drawLine(35,2,35,19,colours.lightGrey)

	if chatExistsAlready then
		term.setBackgroundColour(colours.white)
		for i=1,lastScreenLine do
			eWrite(chatScreenList[i],1,i + 2)
		end
	end

	--Message Composition Window
	paintutils.drawLine(1,16,35,16,colours.lightGrey)
	eWrite("Compose a message:",1,16)
	paintutils.drawLine(29,17,29,19,colours.lightBlue)
	term.setTextColour(colours.black)
	term.setTextColour(colours.blue)
	eWrite("^",29,17)
	eWrite("v",29,19)
	term.setTextColour(colours.black)
	for i=17,19 do
		paintutils.drawLine(30,i,34,i,colours.lightGrey)
	end
	term.setBackgroundColour(colours.orange)
	eWrite("Send",31,18)

	--Player List
	term.setBackgroundColour(colours.lightGrey)
	eWrite("Players in Chat:",36,2)
	paintutils.drawLine(51,3,51,19,colours.lightBlue)
	term.setTextColour(colours.blue)
	eWrite("^",51,3)
	eWrite("v",51,19)
	term.setTextColour(colours.black)

	if usersAlreadyOn then
		term.setBackgroundColour(colours.white)
		for i=1,lastULScreenLine do
			eWrite(userScreenList[i],36,i + 2)
		end
	end
end

--[[
readMessage():
	Custom read() to stop text from overflowing
	in the message composing box.
]]
local function readMessage()
	term.setBackgroundColour(colours.white)
	term.setTextColour(colours.black)
	local event, param1, param2, param3 = nil,nil,nil,nil
	local currentX, currentY = 1,17
	local string2send = ""
	term.setCursorBlink(true)
	eWrite(" ",0,17)
	while true do
		event, param1, param2, param3 = os.pullEvent()
		if event == "key" then
			if param1 == keys.backspace then
				if currentX == 1 and currentY == 17 then
					-- do nothing because we can't backspace
				else
					--remove the last character in our string
					local temp = string.sub(string2send, 1 , -2)
					string2send = temp
				end
				if currentX > 1 then
					eWrite(" ",currentX - 1, currentY)
					currentX = currentX - 1
					term.setCursorPos(currentX, currentY)
				elseif currentX == 1 and currentY ~= 17 then
					eWrite(" ",28,currentY - 1)
					currentX = 28
					currentY = currentY - 1
					term.setCursorPos(currentX, currentY)
				end
			elseif param1 == keys.enter then
				term.setCursorBlink(false)
				for i = 17,19 do
					paintutils.drawLine(1,i,28,i,colours.white)
				end
				return string2send
			end
		elseif event == "char" then
			if currentX == 28 and currentY < 19 then
				eWrite(param1,currentX,currentY)
				currentX = 1
				currentY = currentY + 1
				term.setCursorPos(currentX, currentY)
				string2send = string2send .. param1
			elseif currentX == 28 and currentY == 19 then
			else
				eWrite(param1,currentX,currentY)
				currentX = currentX + 1
				string2send = string2send .. param1
			end
		elseif event == "mouse_click" then
			if param2 > 30 and param2 < 35 and param3 == 18 then	--send
				term.setCursorBlink(false)
				for i = 17,19 do
					paintutils.drawLine(1,i,28,i,colours.white)
				end
				return string2send
			end
		end
	end
end

--[[
hotBarMenu():
	A shared menu for the host and client. It
	currently only has one option, and that's 'logout'.
	The function returns a value that either clientUI()
	or hostUI() acts on.
]]
local function hotBarMenu()
	local event, param1, param2, param3 = nil,nil,nil,nil
	for i=2,4 do
		paintutils.drawLine(1,i,6,i, colours.orange)
	end
	eWrite("Logout",1,4)
	while true do
		event, param1, param2, param3 = os.pullEvent("mouse_click")
		if param2 < 7 and param3 == 4 then
			term.setBackgroundColour(colours.red)
			eWrite("Logout",1,4)
			sleep(0.2)
			return 1
		elseif param2 > 7 or param3 > 4 then
			term.setTextColour(colours.black)
			term.setBackgroundColour(colours.lightGrey)
			eWrite("Messages:",1,2)
			term.setBackgroundColour(colours.white)
			eWrite("                                 ",1,3)
			eWrite(chatScreenList[1],1,3)
			eWrite("                                 ",1,4)
			eWrite(chatScreenList[2],1,4)
			return 0
		end
	end
end

--[[
scrollChatWindow:
	This scrolls the contents of the chat
	window, and changes chatScreenList and
	chatList appropriately. First, however
	it tests to see if we should be able to
	scroll up or down or at all.
]]
local function scrollChatWindow(amount)
	local temp = 0
	local bottomRef = 0
	local topRef = 0

	if lastScreenLine < 13 then
		return false
	elseif chatScreenList[1] == chatList[1] and amount < 0 then
		return false
	elseif scrollAmount + 13 == lastLine
	and amount > 0 then
		return false
	end

	if amount > 0 then
		bottomRef = scrollAmount + 13
		-- this is the position on chatList that is equivalent
		-- to the current last line on the screen
	elseif amount < 0 then
		topRef = scrollAmount
		-- this is the position on chatList that is equivalent
		-- to the current first line on the screen
	end

	if amount == 1 then	--scroll down once
		temp = 1
		for j=1, 12 do
			eWrite("                                 ",1,temp + 2)
			eWrite(chatScreenList[temp + 1],1,temp + 2)
			chatScreenList[j] = chatScreenList[j + 1]
			temp = temp + 1
		end
		chatScreenList[13] = chatList[bottomRef + 1]
		eWrite("                                 ",1,15)
		eWrite(chatScreenList[13],1,15)
		scrollAmount = scrollAmount + 1
	end
	if amount == -1 then	--scroll up once
		temp = 13
		for j=1, 12 do
			eWrite("                                 ",1,temp + 2)
			eWrite(chatScreenList[temp - 1],1,temp + 2)
			chatScreenList[temp] = chatScreenList[temp - 1]
			temp = temp - 1
		end
		chatScreenList[1] = chatList[topRef]
		eWrite("                                 ",1,3)
		eWrite(chatScreenList[1],1,3)
		scrollAmount = scrollAmount - 1
	end

	return true
end

--[[
printChatWindow():
	OMG THIS WAS SO HARD.
	This is what organises your raw chat message
	into lines with complete words, but stops them from
	overflowing. It then prints them in the chat box.
	This is a handy function because you can use it
	to print anything to the chat window.
]]

local function printChatWindow(wholeMessage)
	local lines = {}
	lines[1] = ""
	lines[2] = ""
	lines[3] = ""
	local numbLines = 0
	local messageLength = string.len(wholeMessage)
	if messageLength > 99 then
		wholeMessage = string.sub(wholeMessage,1,99)
	end
	local word, w = "", ""
	local i,j = 1,1
	local wrapOffset1 = 0
	local wrapOffset2 = 0

	term.setBackgroundColour(colours.white)
	term.setTextColour(colours.black)

	for w in string.gmatch(wholeMessage, ".") do
		if w == " " then
			if i == 33 or i == 66 then
				lines[j] = lines[j] .. word
				word = ""
			else
				lines[j] = lines[j] .. word .. " "
				word = ""
			end
		else
			word = word .. w
		end

		if i == 33 then
			-- if the 1st pixel of the 2nd line contains a
			-- space and is the equivalent of the last character
			-- in wholeMessage, do nothing because the second
			-- line would just be blank otherwise
			if messageLength == 34 and
				string.sub(wholeMessage,34,34) == " " then

			else
				j = 2
				i = 32 + string.len(word)
				wrapOffset1 = string.len(word)
			end

		elseif i == 66 then
			-- if the 1st pixel of the 3rd line contains a
			-- space and is the equivalent of the last character
			-- in wholeMessage, do nothing because the third
			-- line would just be blank otherwise
			if messageLength + wrapOffset1 == 67 and
				string.sub(wholeMessage,messageLength,messageLength) == " " then

			else
				if string.len(word) >= 33 then
					lines[j] = lines[j] .. string.sub(word,1,33)
					word = ""
				end
				j = 3
				i = 65 + string.len(word)
				wrapOffset2 = string.len(word)
			end
		end
		i = i + 1
	end
	if string.len(word) > 33 then
		word = string.sub(word,1,33)
		lines[j] = lines[j] .. word
		numbLines = j
	else
		lines[j] = lines[j] .. word
		numbLines = j
	end

	if lastLine < 13 then
		for i=1,numbLines do
			eWrite("                                 ",1,lastScreenLine + 3)
			eWrite(lines[i],1,lastScreenLine + 3)
			lastScreenLine = lastScreenLine + 1
			chatScreenList[lastScreenLine] = lines[i]
			lastLine = lastLine + 1
			chatList[lastLine] = lines[i]
			if lastScreenLine >= 13 then
				for j=i+1,numbLines do
					lastLine = lastLine + 1
					chatList[lastLine] = lines[j]
				end
				scrollChatWindow(numbLines - i)
				break
			end
		end
	elseif lastLine == 100 then
		for	i=1,numbLines do
			for j=1,99 do
				chatList[j] = chatList[j + 1]
			end
			chatList[100] = lines[i]

			for j=1, 13 do
				chatScreenList[j] = chatList[scrollAmount + j]
				eWrite("                                 ",1,j + 2)
				eWrite(chatScreenList[j],1,j + 2)
			end
		end
	else
		for i=1,numbLines do
			lastLine = lastLine + 1
			chatList[lastLine] = lines[i]
			scrollChatWindow(1)
		end
	end
end

--[[
scrollUserList():
	Like scrollChatWindow() but for the user list.
	I'm not sure if it would work well... I haven't
	tried having that many users on.
]]
local function scrollUserList(amount)
	local temp = 0
	local bottomRef = 0
	local topRef = 0

	if lastULScreenLine < 17 then
		return false
	elseif ULscrollAmount == 0 and amount < 0 then
		return false
	elseif ULscrollAmount + 17 == lastULline
	and amount > 0 and lastULline > 17 then
		return false
	end

	if amount > 0 then
		bottomRef = ULscrollAmount + 17
		-- this is the position on userList that is equivalent
		-- to the current last user displayed on the screen
	elseif amount < 0 then
		topRef = ULscrollAmount
		-- this is the position on userList that is equivalent
		-- to the current first user displayed on the screen
	end

	term.setBackgroundColour(colours.white)

	if amount == 1 then	--scroll down once
		temp = 1
		for j=1, 16 do
			eWrite("               ",36,temp + 2)
			eWrite(userScreenList[temp + 1],36,temp + 2)
			userScreenList[j] = userScreenList[j + 1]
			temp = temp + 1
		end
		userScreenList[17] = userList[bottomRef + 1]
		eWrite("               ",36,19)
		eWrite(userScreenList[17],36,19)
		ULscrollAmount = ULscrollAmount + 1
	end
	if amount == -1 then	--scroll up once
		temp = 17
		for j=1, 16 do
			eWrite("               ",36,temp + 2)
			eWrite(userScreenList[temp - 1],36,temp + 2)
			userScreenList[temp] = userScreenList[temp - 1]
			temp = temp - 1
		end
		userScreenList[1] = userList[topRef]
		eWrite("               ",36,3)
		eWrite(userScreenList[1],36,3)
		ULscrollAmount = ULscrollAmount - 1
	end
end

--[[
addUser():
	Adds a user to userList and prints it to the
	screen accordingly.
]]
local function addUser(username)
	term.setBackgroundColour(colours.white)
	if lastULline < 17 then
		if string.len(username) > 15 then
			temp = string.sub(username,1,15)
			eWrite("               ",36,lastULScreenLine + 3)
			eWrite(temp,36,lastULScreenLine + 3)
		else
			eWrite("               ",36,lastULScreenLine + 3)
			eWrite(username,36,lastULScreenLine + 3)
		end

		lastULScreenLine = lastULScreenLine + 1
		userScreenList[lastULScreenLine] = username

		lastULline = lastULline + 1
		userList[lastULline] = username
	else
		lastULline = lastULline + 1
		userList[lastULline] = username
		scrollUserList(1)
	end
end

--[[
removeUser():
	Removes a user from userList and does whatever
	it needs to do.
]]
local function removeUser(username)
	if lastULline == 0 then
		return false
	end

	local userindice = 0

	for i=1,lastULline do
		if userList[i] == username then
			userindice = i
			break
		end
	end

	for i=userindice,lastULline do
		userList[i] = userList[i+1]
	end
	lastULline = lastULline - 1

	for i=1,17 do
		if userList[ULscrollAmount + i] then
			userScreenList[i] = userList[ULscrollAmount + i]
			eWrite("               ",36,i + 2)
			eWrite(userScreenList[i],36,i + 2)
		else
			eWrite("               ",36,i + 2)
		end
	end
	lastULScreenLine = lastULScreenLine - 1
end

-- ******* Host Software ******

--[[
saveServer():
	This function puts all of the necessary
	values and text that are needed to restore
	the server into a file with the name of the
	server in the folder called 'sessions'.
]]
local function saveServer()
	if not fs.exists(rootDir .. "/sessions") then
		fs.makeDir(rootDir .. "/sessions")
	end

	local fileHandle = fs.open(sFilePath, "w")
	if not fileHandle then
		return false
	end

	fileHandle.writeLine("password((" .. sPassword .. "))end")
	fileHandle.writeLine("channel1((" .. channelOne .. "))end")
	fileHandle.writeLine("channel2((" .. channelTwo .. "))end")

	if lastLine > 1 then
		fileHandle.writeLine("((CHAT))")
		fileHandle.writeLine("")

		for i=1,lastLine do
			fileHandle.writeLine("chatLine" .. i .. "((" .. chatList[i] .. "))end")
		end
	end

	fileHandle.close()
	return true
end

--[[
restoreServer():
	Starts a previously made server by loading
	all the values and text from the file
	into the necessary variables.
]]
local function restoreServer()
	local temp1, temp2 = 0,0
	local firstIndice, secondIndice = 0,0

	local fileHandle = fs.open(sFilePath, "r")

	temp = fileHandle.readLine()
	if not temp then
		return false
	elseif string.find(temp,"password((",1,true) and string.find(temp,"))end",1,true) then
		temp1, temp2 = string.find(temp,"password((",1,true)
		firstIndice = temp2 + 1

		temp1, temp2 = string.find(temp,"))end",1,true)
		secondIndice = temp1 - 1

		sPassword = string.sub(temp,firstIndice,secondIndice)
	end

	temp = fileHandle.readLine()
	if not temp then
		return false
	elseif string.find(temp,"channel1((",1,true) and string.find(temp,"))end",1,true) then
		temp1, temp2 = string.find(temp,"channel1((",1,true)
		firstIndice = temp2 + 1

		temp1, temp2 = string.find(temp,"))end",1,true)
		secondIndice = temp1 - 1

		channelOne = tonumber(string.sub(temp,firstIndice,secondIndice))
	end

	temp = fileHandle.readLine()
	if not temp then
		return false
	elseif string.find(temp,"channel2((",1,true) and string.find(temp,"))end",1,true) then
		temp1, temp2 = string.find(temp,"channel2((",1,true)
		firstIndice = temp2 + 1

		temp1, temp2 = string.find(temp,"))end",1,true)
		secondIndice = temp1 - 1

		channelTwo = tonumber(string.sub(temp,firstIndice,secondIndice))
	end

	temp = fileHandle.readLine()
	if temp == "((CHAT))" then
		chatExistsAlready = true
	elseif not temp then
		return false
	end
	temp = fileHandle.readLine()

	for i=1,100 do
		temp = fileHandle.readLine()
		if not temp then
			break
		end

		if string.find(temp,"chatLine" .. i .. "((",1,true) and string.find(temp,"))end",1,true) then
			temp1, temp2 = string.find(temp,"chatLine" .. i .. "((",1,true)
			firstIndice = temp2 + 1

			temp1, temp2 = string.find(temp,"))end",1,true)
			secondIndice = temp1 - 1

			chatList[i] = string.sub(temp,firstIndice,secondIndice)
			lastLine = lastLine + 1

			if i <= 13 then
				chatScreenList[i] = chatList[i]
				lastScreenLine = lastScreenLine + 1
			end
		end
	end

	return true
end

--[[
hostConnectionManager():
	This manages incoming requests to connect to
	or disconnect from the server. I decided to
	use rednet for this in the long run because
	it allows the connecting computer and the
	host to communicate privately without
	disturbing anything else.
]]

local function hostConnectionManager()
	local currentConnectie = nil
	local firstIndice, secondIndice = 0,0
	local temp,temp1, temp2 = 0,0,0
	local username = ""
	local timeout, takenUser = false, false
	rednet.open(modemSide)

	while running == true do
		local tabletosend = {}
		local senderId, message, distance = rednet.receive(7.5)
		if senderId and running then
			if message == "connectme2tsp" then
				currentConnectie = senderId
				for i=1, 10 do				-- times out after 10 times
					rednet.send(currentConnectie,"login")	-- (about 12 secs)
					senderId, message, distance = rednet.receive(1.2)
					if senderId == currentConnectie then
						if message == sPassword then
							timeout = false
							break
						else
							rednet.send(currentConnectie,"badpass")
						end
					end
					timeout = true
				end
				if timeout == false then
					for i=1, 10 do
						rednet.send(currentConnectie,"enteruser")
						senderId, message, distance = rednet.receive(1.2)
						if senderId == currentConnectie then
							if string.find(message,"user((",1,true) then	--login
								temp1, temp2 = string.find(message,"user((",1,true)	-- get username indices
								firstIndice = temp2 + 1
								temp1, temp2 = string.find(message,"))end",1,true)
								secondIndice = temp1 - 1
								username = string.sub(message,firstIndice, secondIndice)
								for key, name in ipairs(userList) do
									if username == name then
										takenUser = true
										break
									end
									local temp = key
								end

								if not takenUser then
									addUser(username)

									tabletosend[1] = "ch1((" .. channelOne .. "))end"
									tabletosend[2] = "ch2((" .. channelTwo .. "))end"
									tabletosend[3] = "servername((" .. serverName .. "))end"

									if lastLine > 0 then
										tabletosend[4] = "((CHAT))"
										tabletosend[5] = ""
										for i=1,lastLine do
											tabletosend[i+5] = "chatLine" .. i .. "((" .. chatList[i] .. "))end"
										end
									end

									if lastULline > 0 then
										tabletosend[lastLine + 6] = "((USERS))"
										tabletosend[lastLine + 7] = ""
										for i=1,lastULline do
											tabletosend[lastLine + 7 + i] = "user" .. i .. "((" .. userList[i] .. "))end"
										end
									end

									sTabletosend = textutils.serialize(tabletosend)

									modem.transmit(channelTwo,0,"userconnect((" .. username .. "))end")
									printChatWindow(username .. " joined the chat server.")

									for i=1,3 do-- just in case
										rednet.send(currentConnectie, "success((".. sTabletosend)
										sleep(0.5)
									end

									break
								else
									rednet.send(currentConnectie, "takenuser")
								end
							else
								rednet.send(currentConnectie, "badmessage")	--some other message has been received
							end
						end
					end
				end
			elseif string.find(message,"disconnectmeFtsp",1,true) then
				temp1, temp2 = string.find(message,"disconnectmeFtsp((",1,true)	-- get username indices
				firstIndice = temp2 + 1
				temp1, temp2 = string.find(message,"))end",1,true)
				secondIndice = temp1 - 1
				username = string.sub(message,firstIndice, secondIndice)
				rednet.send(senderId,"disconnected")

				modem.transmit(channelTwo,0,"userdisconnect((" .. username .. "))end")
				printChatWindow(username .. " left the chat server.")
				removeUser(username)
			end
		end
	end
	rednet.close(modemSide)
end

--[[
hostChatManager:
	receives messages from clients,
	distributes them and prints
	them on the host's own screen
]]

local function hostChatManager()
	local user, chatMessage = ""
	local temp, temp2 = 0,0
	local firstIndice, secondIndice = 0,0
	local wholeOut
	local event, side, frequency, replyFreqency, message, distance

	modem.open(channelOne)
	while running == true do
		os.startTimer(5)
		event, side, frequency, replyFreqency, message, distance = os.pullEvent()
		if event == "modem_message" then
			if frequency == channelOne then
				if string.find(message, "user((", 1, true) and string.find(message, "))message((", 1, true) then
					temp, temp2 = string.find(message,"user((",1,true)	-- get username indices
					firstIndice = temp2 + 1
					temp, temp2 = string.find(message,"))message",1,true)
					secondIndice = temp - 1
					user = string.sub(message,firstIndice, secondIndice)

					temp, temp2 = string.find(message,"message((",1,true)	-- get message indices
					firstIndice = temp2 + 1
					temp, temp2 = string.find(message,"))end",1,true)
					secondIndice = temp - 1
					chatMessage = string.sub(message,firstIndice, secondIndice)	--load whole message

					wholeOut = user.. ": " .. chatMessage
					modem.transmit(channelTwo,channelOne,wholeOut)

					printChatWindow(wholeOut)	--print on host machine
				end
			end
		elseif event == "timer" then
			if running == false then
				break
			end
		end
	end
	modem.close(channelOne)
end

--[[
hostHotBarMenu():
	This controls the Host menu, similar to
	hotBarMenu().
]]
local function hostHotBarMenu()
	local event, param1, param2, param3 = nil,nil,nil,nil
	for i=2,4 do
		paintutils.drawLine(8,i,14,i, colours.orange)
	end
	eWrite("Save",8,2)
	eWrite("Shutdown",7,3)
	while true do
		event, param1, param2, param3 = os.pullEvent("mouse_click")
		if param2 > 7 and param2 < 15 and param3 == 2 then
			term.setBackgroundColour(colours.red)
			eWrite("Save",8,2)
			sleep(0.2)
			term.setTextColour(colours.black)
			term.setBackgroundColour(colours.lightGrey)
			paintutils.drawLine(1,2,20,2,colours.lightGrey)
			eWrite("Messages:",1,2)
			term.setBackgroundColour(colours.white)
			eWrite(chatScreenList[1],1,3)
			eWrite(chatScreenList[2],1,4)
			return 1

		elseif param2 > 7 and param2 < 15 and param3 == 3 then
			term.setBackgroundColour(colours.red)
			eWrite("Shutdown",7,3)
			sleep(0.2)
			term.setTextColour(colours.black)
			term.setBackgroundColour(colours.lightGrey)
			paintutils.drawLine(1,2,20,2,colours.lightGrey)
			eWrite("Messages:",1,2)
			term.setBackgroundColour(colours.white)
			eWrite(chatScreenList[1],1,3)
			eWrite(chatScreenList[2],1,4)
			return 2

		elseif param2 < 7 or param2 > 14 or param3 > 4 then
			term.setTextColour(colours.black)
			term.setBackgroundColour(colours.lightGrey)
			paintutils.drawLine(1,2,20,2,colours.lightGrey)
			eWrite("Messages:",1,2)
			term.setBackgroundColour(colours.white)
			eWrite("                                 ",1,3)
			eWrite(chatScreenList[1],1,3)
			eWrite("                                 ",1,4)
			eWrite(chatScreenList[2],1,4)
			return 0
		end
	end
end

--[[
hostUI():
	This function allows the host to interact with
	everything while the server is running.
]]
local function hostUI()
	local action
	local chatString
	local wholeOut
	setupGUI()
	term.setBackgroundColour(colours.orange)
	eWrite("[Host]",8,1)
	term.setBackgroundColour(colours.white)
	while running == true do
		event, param1, param2, param3 = os.pullEvent()
		if event == "mouse_click" then
			if param2 < 28 and param3 > 16 then
				chatString = readMessage()

				wholeOut = "Host: " .. chatString
				modem.transmit(channelTwo,channelOne,wholeOut)
				printChatWindow(wholeOut)
			elseif param2 < 6 and param3 == 1 then
				term.setBackgroundColour(colours.red)
				eWrite("[Menu]",1,1)
				sleep(0.2)
				term.setBackgroundColour(colours.orange)
				eWrite("[Menu]",1,1)
				action = hotBarMenu()
				if action == 1 then
					printChatWindow("The server is shutting down.")
					modem.transmit(channelTwo,channelOne,"lionelhuttXX((SERVERSHUTDOWN))Xx")
					-- had to make it something no one would likely type XD
					sleep(5)
					running = false
					break
				end
			elseif param2 > 7 and param2 < 14 and param3 == 1 then
				term.setBackgroundColour(colours.red)
				eWrite("[Host]",8,1)
				sleep(0.2)
				term.setBackgroundColour(colours.orange)
				eWrite("[Host]",8,1)
				action = hostHotBarMenu()
				if action == 1 then
					if not saveServer() then
						printChatWindow("save failed.")
					end
				elseif action == 2 then
					printChatWindow("The server is shutting down.")
					modem.transmit(channelTwo,channelOne,"lionelhuttXX((SERVERSHUTDOWN))Xx")
					sleep(5)
					running = false
				end
			elseif param2 == 34 and param3 == 15 then
				scrollChatWindow(1)
			elseif param2 == 34 and param3 == 3 then
				scrollChatWindow(-1)
			end
		end
	end
end


-- ****** Client Software *****

--[[
loadInfo():
	This loads all the values and text received from the
	host into the necessary variables. It's a bit like
	restoreServer() except it's for clients when they
	connect.
]]
local function loadInfo(serverdata)
	local temp, temp1, temp2 = "",0,0
	local firstIndice, secondIndice = 0,0

	if string.find(serverdata[1],"ch1((",1,true) then
		temp1, temp2 = string.find(serverdata[1],"ch1((",1,true)
		firstIndice = temp2 + 1

		temp1, temp2 = string.find(serverdata[1],"))end",1,true)
		secondIndice = temp1 - 1

		temp = string.sub(serverdata[1],firstIndice,secondIndice)
		channelOne = tonumber(temp)
	end

	if string.find(serverdata[2],"ch2((",1,true) then
		temp1, temp2 = string.find(serverdata[2],"ch2((",1,true)
		firstIndice = temp2 + 1

		temp1, temp2 = string.find(serverdata[2],"))end",1,true)
		secondIndice = temp1 - 1

		temp = string.sub(serverdata[2],firstIndice,secondIndice)
		channelTwo = tonumber(temp)
	end

	if string.find(serverdata[3],"servername((",1,true) then
		temp1, temp2 = string.find(serverdata[3],"servername((",1,true)
		firstIndice = temp2 + 1

		temp1, temp2 = string.find(serverdata[3],"))end",1,true)
		secondIndice = temp1 - 1

		temp = string.sub(serverdata[3],firstIndice,secondIndice)
		serverName = temp
	end

	if serverdata[4] == "((CHAT))" then
		chatExistsAlready = true
	elseif not serverdata[4] then
		return true
	end

	for i=1,100 do
		if not serverdata[i+5] then
			break
		end

		if string.find(serverdata[i+5],"chatLine" .. i .. "((",1,true) and string.find(serverdata[i+5],"))end",1,true) then
			temp1, temp2 = string.find(serverdata[i+5],"chatLine" .. i .. "((",1,true)
			firstIndice = temp2 + 1

			temp1, temp2 = string.find(serverdata[i+5],"))end",1,true)
			secondIndice = temp1 - 1

			chatList[i] = string.sub(serverdata[i+5],firstIndice,secondIndice)
			lastLine = lastLine + 1

			if i <= 13 then
				chatScreenList[i] = chatList[i]
				lastScreenLine = lastScreenLine + 1
			end
		end
	end

	if serverdata[lastLine + 6] == "((USERS))" then
		usersAlreadyOn = true
	elseif not serverdata[lastLine + 6] then
		return true
	end

	for i=1,100 do
		if not serverdata[lastLine + 7 + i] then
			break
		end

		if string.find(serverdata[lastLine + 7 + i],"user" .. i .. "((",1,true) and string.find(serverdata[lastLine + 7 + i],"))end",1,true) then
			temp1, temp2 = string.find(serverdata[lastLine + 7 + i],"user" .. i .. "((",1,true)
			firstIndice = temp2 + 1

			temp1, temp2 = string.find(serverdata[lastLine + 7 + i],"))end",1,true)
			secondIndice = temp1 - 1

			userList[i] = string.sub(serverdata[lastLine + 7 + i],firstIndice,secondIndice)
			lastULline = lastULline + 1

			if i <= 17 then
				userScreenList[i] = userList[i]
				lastULScreenLine = lastULScreenLine + 1
			end
		end
	end

	return true
end

--[[
login():
	Does exactly what its name implies. It does all
	the necessary communicating with the server to
	get connnected.
]]
local function login()
	term.setBackgroundColour(colours.white)
	term.clear()
	for i=7,15 do
		paintutils.drawLine(14,i,37,i,colours.lightGrey)
	end
	eWrite("logging in...",20,11)
	local senderId, message, distance
	local timeout = false
	local temp1, temp2, firstIndice, secondIndice = 0,0,0,0
	local password, username = "",""
	local serverdata = {}

	rednet.open(modemSide)
	for i=1, 10 do
		rednet.send(hostID, "connectme2tsp")
		senderId, message, distance = rednet.receive(1.2)
		if senderId == hostID then
			if message == "login" then
				timeout = false
				break
			end
		end
		timeout = true
	end
	if timeout == true then
		for i=7,15 do
			paintutils.drawLine(14,i,37,i,colours.lightGrey)
		end
		eWrite("Could not connect to",16,10)
		eWrite("server",24,11)
		os.pullEvent("mouse_click")
		return false
	end
	for i=1, 12 do
		for i=7,15 do
			paintutils.drawLine(14,i,37,i,colours.lightGrey)
		end
		eWrite("Please enter the",19,8)
		eWrite("server's password.",17,9)
		eWrite("(do this quickly or",16,10)
		eWrite("you will time out)",17,11)
		paintutils.drawLine(16,13,35,13,colours.white)
		term.setCursorPos(16,13)
		password = read()

		rednet.send(hostID,password)
		senderId, message, distance = rednet.receive(1.2)
		if senderId == hostID then
			if message == "enteruser" then
				timeout = false
				break
			elseif message == "badpass" then
				for i=7,15 do
					paintutils.drawLine(14,i,37,i,colours.lightGrey)
				end
				eWrite("Password was incorrect.",15,11)
				os.pullEvent("mouse_click")
			end
		end
		timeout = true
	end
	if timeout == true then
		for i=7,15 do
			paintutils.drawLine(14,i,37,i,colours.lightGrey)
		end
		eWrite("Lost connection to",19,10)
		eWrite("server",20,11)
		os.pullEvent("mouse_click")
		return false
	end
	for i=1, 12 do
		for i=7,15 do
			paintutils.drawLine(14,i,37,i,colours.lightGrey)
		end
		eWrite("Please enter your",18,8)
		eWrite("username for the",19,9)
		eWrite("server",22,10)
		paintutils.drawLine(16,13,35,13,colours.white)
		term.setCursorPos(16,13)
		username = read()

		rednet.send(hostID, "user((".. username .. "))end")
		senderId, message, distance = rednet.receive(1.2)
		if senderId == hostID then
			if string.find(message, "success((",1,true)  then
				myuser = username

				local temp =  string.sub(message,10)
				serverdata = textutils.unserialize(temp)

				loadInfo(serverdata)

				rednet.close(modemSide)
				return true
			elseif message == "takenuser" then
				for i=7,15 do
					paintutils.drawLine(14,i,37,i,colours.lightGrey)
				end
				eWrite("That username was",19,10)
				eWrite("already taken",20,11)
				os.pullEvent("mouse_click")
			end
		end
		timeout = true
	end
	return nil
end

--[[
logout():
	Oh boy, I wonder what this one does? :P
]]
local function logout()
	term.setBackgroundColour(colours.white)
	term.clear()
	for i=9,11 do
		paintutils.drawLine(14,i,37,i,colours.lightGrey)
	end
	term.setBackgroundColour(colours.lightGrey)
	term.setTextColour(colours.black)
	eWrite("logging out...",18,10)

	rednet.open(modemSide)
	for i=1,12 do
		rednet.send(hostID,"disconnectmeFtsp((" .. myuser .. "))end")
		local senderId, message, distance = rednet.receive(2.5)
		if senderId then
			if message == "disconnected" then
				eWrite("successful logout",16,10)
				rednet.close(modemSide)
				return true
			end
		end
	end
	rednet.open(modemSide)
	return false
end

--[[
	This guy watches out for incomming messages from
	the host and either calls printChatWindow() to print
	them or acts on them accordingly.
]]
local function clientReceiver()
	local event, side, frequency, replyFreqency, message, distance
	local temp, temp1, temp2 = "",0,0
	local firstIndice, secondIndice = 0,0
	local username = ""

	modem.open(channelTwo)
	while running == true do
		os.startTimer(5)
		event, side, frequency, replyFreqency, message, distance = os.pullEvent()
		if event == "modem_message" then
			if frequency == channelTwo then
				if string.find(message,"userdisconnect((",1,true)
				and string.find(message,"))end",1,true) then
					temp1, temp2 = string.find(message,"userdisconnect((",1,true)
					firstIndice = temp2 + 1

					temp1, temp2 = string.find(message,"))end",1,true)
					secondIndice = temp1 - 1

					username = string.sub(message,firstIndice,secondIndice)

					printChatWindow(username .. " left the chat server.")
					removeUser(username)

				elseif string.find(message,"userconnect((",1,true)
				and string.find(message,"))end",1,true) then
					temp1, temp2 = string.find(message,"userconnect((",1,true)
					firstIndice = temp2 + 1

					temp1, temp2 = string.find(message,"))end",1,true)
					secondIndice = temp1 - 1

					username = string.sub(message,firstIndice,secondIndice)

					printChatWindow(username .. " joined the chat server.")
					addUser(username)

				elseif string.find(message,"lionelhuttXX((SERVERSHUTDOWN))Xx",1,true) then
					printChatWindow("The server is shutting down, please click somewhere on the screen.")
					running = false
					sleep(4)
					break
				else
					--if scrollAmount < lastLine then
					--	scrollChatWindow(lastLine - scrollAmount)
					--end
					printChatWindow(message)
				end
			end
		elseif event == "timer" then
			if running == false then
				break
			end
		end
	end
	modem.close(channelTwo)
end

--[[
clientUI:
	controls all the user input and interaction
	on the client end.
]]
local function clientUI()
	local action
	local chatString
	setupGUI()
	while running == true do
		event, param1, param2, param3 = os.pullEvent()
		if event == "mouse_click" then
			if param2 < 28 and param3 > 16 then
				chatString = readMessage()
				modem.transmit(channelOne,channelTwo,"user((".. myuser .."))message((".. chatString .."))end")
			elseif param2 < 6 and param3 == 1 then
				term.setBackgroundColour(colours.red)
				eWrite("[Menu]",1,1)
				sleep(0.2)
				term.setBackgroundColour(colours.orange)
				eWrite("[Menu]",1,1)
				action = hotBarMenu()
				if action == 1 then
					running = false
					local test = logout()
					sleep(1)
					break
				end
			elseif param2 == 34 and param3 == 15 then
				scrollChatWindow(1)
			elseif param2 == 34 and param3 == 3 then
				scrollChatWindow(-1)
			end
		end
	end
end

-- ******** Program Functionality Begins *********

--[[ And here we have the actual stuff; where all the
	magic comes together! ]]

displayHomeScreen()

--Check for Modems
term.setTextColour(colours.black)
	for i=13, 15 do
		paintutils.drawLine(14,i,37,i,colours.lightGrey)
	end
term.setCursorPos(15,14)
term.write("Checking for modems...")
sleep(0.75)

if peripheral.getType("top") == "modem" then
	modem = peripheral.wrap("top")
	modemSide = "top"
elseif peripheral.getType("left") == "modem" then
	modem = peripheral.wrap("left")
	modemSide = "left"
elseif peripheral.getType("right") == "modem" then
	modem = peripheral.wrap("right")
	modemSide = "right"
elseif peripheral.getType("back") == "modem" then
	modem = peripheral.wrap("back")
	modemSide = "back"
else
	term.setBackgroundColour(colours.white)
	term.setTextColour(colours.lightBlue)
	term.clear()
	eWrite("No modems were found, please place",8,4)
	eWrite("a modem either on the top, right, left",8,5)
	eWrite("or back side.",10,6)
	eWrite("Click anywhere to exit",8,8)
	os.pullEvent("mouse_click")
	term.setCursorPos(1,4)
	term.setTextColour(colours.white)
	term.setBackgroundColour(colours.black)
	term.clear()
	return
end

-- ******** Main Loop *********

while true do
	displayHomeScreen()
	choice = homeMenu()
	if choice == 1 then	--start new server
		hosting = true
		running = true
		displayLoadScreen()
		math.randomseed(myID)
		channelOne = math.random(0,65535)
		channelTwo = math.random(0,65535)		--is this an OK idea?
		parallel.waitForAll(hostUI,hostConnectionManager,hostChatManager)
	elseif choice == 2 then	--restore server
		hosting = true
		running = true
		restoreServer()
		displayLoadScreen()
		parallel.waitForAll(hostUI,hostConnectionManager,hostChatManager)
	elseif choice == 3 then
		running = true
		local success = login()
		if success then
			parallel.waitForAll(clientUI,clientReceiver)
		end
	elseif choice == 0 then	--quit
		displayExit()
		sleep(2)
		break
	end

	--reset all the necessary variables

	hosting = false
	serverName = ""
	running = false
	chatList = {}
	chatScreenList = {}
	lastLine = 0
	lastScreenLine = 0
	scrollAmount = 0
	chatExistsAlready = false

	userList = {}
	userScreenList = {}
	lastULline = 0
	lastULScreenLine = 0
	ULscrollAmount = 0
	usersAlreadyOn = false

	hostID, myID = nil, os.getComputerID()
	channelOne = nil
	channelTwo = nil

	sessionList = {}
	noSessions = 0
	newSession = nil
	sFilePath = nil
	sPassword = ""

	myuser = ""
end

-- clean up

term.setBackgroundColour(colours.black)
term.setCursorPos(1,1)
term.clear()

-- Wellp, there's my program! Thanks for reading. :)