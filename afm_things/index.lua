-- ihaveamac
-- https://ianburgwin.net/
-- https://gbatemp.net/members/ihaveamac.364799/
-- bugs can be reported at https://github.com/ihaveamac/another-file-manager/issues

-- hello! this script may not be very friendly to editing, due to my use of short variable names.
-- I tried to clean it up before release but some may be left behind.

ver = "dev-v"
c_path = System.currentDirectory()
System.currentDirectory("/")

white = Color.new(255, 255, 255)
sys_t = {"Nintendo 3DS", "Nintendo 3DS XL", "New Nintendo 3DS", "Nintendo 2DS", "New Nintendo 3DS XL"}
-- http://3dbrew.org/wiki/Cfg:GetSystemModel

-- this may seem weird but it's done for technical reasons
icon = {}
icon["folder"]		= Screen.loadImage(c_path.."/afm_things/folder.png")
--icon["upfolder"]	= Screen.loadImage(c_path.."/afm_things/arrow_redo.png")
icon["3dsx"]		= Screen.loadImage(c_path.."/afm_things/application.png")
icon["smdh"]		= Screen.loadImage(c_path.."/afm_things/information.png")
icon["img"]			= Screen.loadImage(c_path.."/afm_things/image.png")
icon["img_jpeg"]	= icon["img"]
icon["unknown"]		= Screen.loadImage(c_path.."/afm_things/page_white.png")
-- non-file/folder icons
icon["goback"]		= Screen.loadImage(c_path.."/afm_things/arrow_left.png")

sel_height = 20	-- this has been designed around being 20, don't change it
text_offset = math.floor((sel_height - 10) / 2)
icon_offset = math.floor((sel_height - 16) / 2)

function getTimeDateFormatted()
	local hr, mi, sc = System.getTime()
	local dw, dy, mp, yr = System.getDate()
	return yr.."-"..mp.."-"..dy.."_"..hr.."-"..mi.."-"..sc
end

--------------------------------------------------------------------------------
-- CRASH HANDLING
--------------------------------------------------------------------------------

function crash(status, err)
	Screen.waitVblankStart()
	Screen.refresh()
	Screen.clear(TOP_SCREEN)
	Screen.clear(BOTTOM_SCREEN)
	
	local rg = System.getRegion()
	if rg == 1 then
		rg = "USA"
	elseif rg == 2 then
		rg = "EUR"
	else
		rg = "JPN/Other"
	end
	
	-- rendering the top screen info on an image was intended for debugging
	-- but I left it, since it was easier to keep it, and it might be valuable
	local timg = Screen.createImage(400, 240, Color.new(0, 0, 0))
	--local bimg = Screen.createImage(320, 240, Color.new(0, 0, 0))
	Screen.fillEmptyRect(0, 399, 1, 2, Color.new(255, 0, 0), timg)
	Screen.debugPrint(5, 10, "Something went wrong badly!", Color.new(255, 160, 160), timg)
	Screen.debugPrint(5, 25, "To prevent any potential issues, the", white, timg)
	Screen.debugPrint(5, 40, "program has stopped.", white, timg)
	
	Screen.debugPrint(5, 65, "It's recommended that you report this issue", white, timg)
	Screen.debugPrint(5, 80, "if it happens constantly.", white, timg)
	
	Screen.debugPrint(5, 105, "Go to ianburgwin.net/bug and describe what", white, timg)
	Screen.debugPrint(56, 105, "ianburgwin.net/bug", Color.new(130, 130, 255), timg)
	Screen.debugPrint(5, 120, "you were doing up until it crashed, along with", white, timg)
	Screen.debugPrint(5, 135, "the information on the bottom screen.", white, timg)
	
	Screen.debugPrint(5, 160, "A text file of the info will be saved to", white, timg)
	Screen.debugPrint(5, 175, c_path.."/", Color.new(130, 255, 130), timg)
	Screen.debugPrint(5, 190, getTimeDateFormatted()..".txt", Color.new(130, 255, 130), timg)
	
	local lpb = System.checkBuild()
	if lpb == 0 then
		lpb = "3DSX (0)"
		Screen.debugPrint(5, 215, "Press B to return to the Homebrew Launcher.", white, timg)
	elseif lpb == 1 then
		lpb = "3DS/CIA (1)"
		Screen.debugPrint(5, 215, "Press B to exit.", white, timg)
	else
		lpb = "unknown ("..lpb..")"
		Screen.debugPrint(5, 215, "Press B to exit.", white, timg)
	end
	
	local co = Console.new(BOTTOM_SCREEN)
	local errlog = io.open(c_path.."/"..getTimeDateFormatted()..".txt", FCREATE)
	
	local errlogc = (err.."\n"..
		"\nSystem: "..sys_t[System.getModel() + 1]..
		"\nFirmware: "..System.getFirmware()..
		"\nKernel: "..System.getKernel()..
		"\nRegion: "..rg..
		"\nlpp build: "..lpb..
		"\n"..c_path)

	Console.append(co, errlogc)
	io.write(errlog, 0, errlogc, string.len(errlogc))
	io.close(errlog)
	Console.show(co)
	Screen.flip()
	--Screen.saveImage(timg, c_path.."/Crash information.bmp", false)
	--Screen.saveImage(bimg, c_path.."/lastError.bmp", false)
	Screen.drawImage(0, 0, timg, TOP_SCREEN)
	--Screen.drawImage(0, 0, bimg, BOTTOM_SCREEN)
	local ti = Timer.new()
	while true do
		if Controls.check(Controls.read(), KEY_B) and Timer.getTime(ti) >= 1000 then
			System.exit()
		end
	end
	-- rip in millions of pieces
end

--------------------------------------------------------------------------------
-- GARBAGE COLLECTION
--------------------------------------------------------------------------------

-- http://i.imgur.com/Hyjk2oL.png
status, err = pcall(function()
cf = {"NOTHING", "NOTHING"}
-- [1] = file, [2] = type
--[[function garbageC()
	if cf[2] == "img" then
		Screen.freeImage(cf[1])
	elseif cf[2] == "smdh" or cf[2] == "iconbin" then
		Screen.freeImage(cf[1][icon])
	elseif cf[2] == "NOTHING" then
		-- just to prevent a crash!
		-- garbage collection removes things from memory
		-- otherwise opening tons of files would cause an out of memory error or something
	else
		error("GC failed to match: "..tostring(cf[2]))
	end
end]]

--------------------------------------------------------------------------------
-- DIRECTORY LISTING
--------------------------------------------------------------------------------

cd_name = ""
up_f = ""
is_root = true -- this variable probably isn't even needed, y'know
sel = 1
offset = 0
d_c = {}
function generateList(nd)
	if nd then
		System.currentDirectory(nd)
	end
	sel = 1
	offset = 0
	d_c = {}
	--[[if System.currentDirectory() ~= "/" then
		table.insert(d_c, {"Go up", "upfolder"})
	end]]
	local t_d_c = {{}, {}}
	local t_d_c_b = System.listDirectory(System.currentDirectory())
	for k, v in pairs(t_d_c_b) do
		if v.directory then
			table.insert(t_d_c[1], v)
		else
			table.insert(t_d_c[2], v)
		end
	end
	-- shamelessly stolen from ORGANIZ3D
	table.sort(t_d_c[1], function (a, b) return (a.name:lower() < b.name:lower() ) end)
	table.sort(t_d_c[2], function (a, b) return (a.name:lower() < b.name:lower() ) end)
	for k, v in pairs(t_d_c[1]) do
		table.insert(d_c, {v.name, "folder"})
	end
	for k, v in pairs(t_d_c[2]) do
		sv = v.name:lower()
		local f_d = {v.name}
		if sv:sub(-5) == ".3dsx" then
			table.insert(f_d, "3dsx")
		elseif sv:sub(-5) == ".smdh" or sv == "icon.bin" then
			table.insert(f_d, "smdh")
		elseif sv:sub(-4) == ".png" or sv:sub(-4) == ".bmp" then
			table.insert(f_d, "img")
		elseif sv:sub(-4) == ".jpg" or sv:sub(-5) == ".jpeg" or sv:sub(-4) == ".mpo" then
			table.insert(f_d, "img_jpeg")
		else
			table.insert(f_d, "unknown")
		end
		table.insert(d_c, f_d)
	end
	
	local sep_cd = {}
	for v in string.gmatch(System.currentDirectory(), "([^/]+)") do -- keeping this here for reference: string.gmatch(example, "([^/]+)")
		table.insert(sep_cd, v)
	end
	cd_name = sep_cd[#sep_cd]
	is_root = false
	if cd_name == "" or not cd_name then
		cd_name = "(root)"
		is_root = true
	else
		table.remove(sep_cd, #sep_cd)
		if #sep_cd == 0 then
			up_f = "/"
		else
			up_f = "/"..table.concat(sep_cd, "/").."/"
		end
	end
end
generateList()

allow_control = true
last_button = nil
--------------------------------------------------------------------------------
-- IMAGE FILE RENDERING
--------------------------------------------------------------------------------

function previewImage(img, is_jpg) -- is_jpg is deprecated but i didn't want to bother removing it
	local loadi, imagex, imagey
	is_jpg = false
	if is_jpg then
		loadi = Screen.loadImage(System.currentDirectory()..img)
		imagex, imagey = Screen.getImageWidth(loadi), Screen.getImageHeight(loadi)
	else
		Graphics.init()
		local temp_loadi = Screen.loadImage(System.currentDirectory()..img)
		imagex, imagey = Screen.getImageWidth(temp_loadi), Screen.getImageHeight(temp_loadi)
		Screen.freeImage(temp_loadi)
		temp_loadi = nil
		loadi = Graphics.loadImage(System.currentDirectory()..img)
	end
	local bx, by = imagex > 400, imagey > 240
	local posx, posy, bposx, bposy = 0, 0, 0, 0
	local was_touching = false
	local ptx, pty = 0, 0
	local function render(csx, csy)
		if is_jpg then
			Screen.drawPartialImage(bposx, bposy, posx, posy, math.min(imagex, 400), math.min(imagey, 240), loadi, TOP_SCREEN)
		else
			Graphics.initBlend(TOP_SCREEN)
			Graphics.drawPartialImage(bposx, bposy, posx, posy, math.min(imagex, 400), math.min(imagey, 240), loadi)
			Graphics.termBlend()
		end
		Screen.fillEmptyRect(0, 319, 19, 20, white, BOTTOM_SCREEN)
		Screen.debugPrint(5, 5, img, white, BOTTOM_SCREEN)
		Screen.debugPrint(5, 25, "Resolution: "..imagex.." x "..imagey, white, BOTTOM_SCREEN)
		Screen.debugPrint(5, 55, "B: Close image", white, BOTTOM_SCREEN)
	end
	
	local fcpx, fcpy, fcpxc, fcpyc, fcsx, fcsy, fcsxc, fcsyc, ctx, cty, ptx, pty
	while true do
		Screen.waitVblankStart()
		Screen.refresh()
		Screen.clear(TOP_SCREEN)
		Screen.clear(BOTTOM_SCREEN)
		local cpx, cpy = Controls.readCirclePad()
		local csx, csy = Controls.readCstickPad()
		local pad = Controls.read()
		
		fcpx = math.min(math.max(cpx - 20, 0), 130) + math.max(math.min(cpx + 20, 0), -130)
		fcpy = math.min(math.max(cpy - 20, 0), 130) + math.max(math.min(cpy + 20, 0), -130)
		
		if Controls.check(pad, KEY_L) or Controls.check(pad, KEY_R) then
			fcpxc = ((fcpx / 130) * 20)
			fcpyc = ((fcpy / 130) * 20)
		else
			fcpxc = ((fcpx / 130) * 10)
			fcpyc = ((fcpy / 130) * 10)
		end
		
		fcsx = math.min(math.max(csx, 0), 120) + math.max(math.min(csx, 0), -120)
		fcsy = math.min(math.max(csy, 0), 120) + math.max(math.min(csy, 0), -120)
		
		if Controls.check(pad, KEY_L) or Controls.check(pad, KEY_R) then
			fcsxc = ((fcsx / 120) * 20)
			fcsyc = ((fcsy / 120) * 20)
		else
			fcsxc = ((fcsx / 120) * 10)
			fcsyc = ((fcsy / 120) * 10)
		end
		
		if bx then
			posx = math.max(math.min(posx + math.ceil(fcpxc + fcsxc), imagex - 400), 0)
			bposx = 0
		else
			posx = 0
			bposx = math.floor(200 - (imagex / 2))
		end
		if by then
			posy = math.max(math.min(posy - math.ceil(fcpyc + fcsyc), imagey - 240), 0)
			bposy = 0
		else
			posy = 0
			bposy = math.floor(120 - (imagey / 2))
		end
		if allow_control then
			if Controls.check(pad, KEY_B) then
				if is_jpg then
					Screen.freeImage(loadi)
				else
					Graphics.freeImage(loadi)
				end
				loadi = nil
				allow_control = false
				last_button = KEY_B
				return
			elseif Controls.check(pad, KEY_DUP) then
				allow_control = false
				last_button = KEY_DUP
				if by then
					if Controls.check(pad, KEY_L) or Controls.check(pad, KEY_R) then
						posy = math.max(math.min(posy - 5, imagey - 240), 0)
					else
						posy = math.max(math.min(posy - 1, imagey - 240), 0)
					end
				end
			elseif Controls.check(pad, KEY_DDOWN) then
				allow_control = false
				last_button = KEY_DDOWN
				if by then
					if Controls.check(pad, KEY_L) or Controls.check(pad, KEY_R) then
						posy = math.max(math.min(posy + 5, imagey - 240), 0)
					else
						posy = math.max(math.min(posy + 1, imagey - 240), 0)
					end
				end
			elseif Controls.check(pad, KEY_DLEFT) then
				allow_control = false
				last_button = KEY_DLEFT
				if bx then
					if Controls.check(pad, KEY_L) or Controls.check(pad, KEY_R) then
						posx = math.max(math.min(posx - 5, imagex - 400), 0)
					else
						posx = math.max(math.min(posx - 1, imagex - 400), 0)
					end
				end
			elseif Controls.check(pad, KEY_DRIGHT) then
				allow_control = false
				last_button = KEY_DRIGHT
				if bx then
					if Controls.check(pad, KEY_L) or Controls.check(pad, KEY_R) then
						posx = math.max(math.min(posx + 5, imagex - 400), 0)
					else
						posx = math.max(math.min(posx + 1, imagex - 400), 0)
					end
				end
			end
		else
			if not Controls.check(pad, last_button) then
				allow_control = true
			end
		end
		if Controls.check(pad, KEY_TOUCH) then
			allow_control = false
			last_button = KEY_TOUCH
			if was_touching then
				ctx, cty = Controls.readTouch()
				if bx then
					if Controls.check(pad, KEY_L) or Controls.check(pad, KEY_R) then
						posx = math.max(math.min(posx + (ptx - ctx) * 2, imagex - 400), 0)
					else
						posx = math.max(math.min(posx + (ptx - ctx), imagex - 400), 0)
					end
				end
				if by then
					if Controls.check(pad, KEY_L) or Controls.check(pad, KEY_R) then
						posy = math.max(math.min(posy + (pty - cty) * 2, imagey - 240), 0)
					else
						posy = math.max(math.min(posy + (pty - cty), imagey - 240), 0)
					end
				end
				ptx, pty = ctx, cty
			else
				was_touching = true
				ptx, pty = Controls.readTouch()
			end
		else
			was_touching = false
		end
		render(csx, csy)
		Screen.flip()
	end
end

--------------------------------------------------------------------------------
-- DIRECTORY LISTING RENDERING
--------------------------------------------------------------------------------

was_touching = false
d_allow_control = true
d_last_button = nil
local ctx, cty, ptx, pty
local ox, oy = 0, 0
function renderMain(debug_thing)
	Screen.fillRect(0, 319, 0, sel_height, Color.new(0, 0, 255, 100), BOTTOM_SCREEN)
	if not is_root then
		Screen.fillRect(0, sel_height, 0, sel_height, Color.new(0, 0, 255, 100), BOTTOM_SCREEN)
		Screen.drawImage(icon_offset, icon_offset, icon["goback"], BOTTOM_SCREEN)
	end
	Screen.debugPrint(sel_height + text_offset, text_offset, cd_name, white, BOTTOM_SCREEN)
	for k = offset + 1, math.min(#d_c + offset, 10 + offset) do
		if sel == k then
			Screen.fillRect(0, 319, ((k - offset) * sel_height), ((k - offset) * sel_height) + sel_height - 1, Color.new(0, 255, 0, 175), BOTTOM_SCREEN)
		else
			if math.floor(k / 2) == k / 2 then
				Screen.fillRect(0, 319, ((k - offset) * sel_height), ((k - offset) * sel_height) + sel_height - 1, Color.new(10, 10, 10), BOTTOM_SCREEN)
			else
				Screen.fillRect(0, 319, ((k - offset) * sel_height), ((k - offset) * sel_height) + sel_height - 1, Color.new(0, 0, 0), BOTTOM_SCREEN)
			end
		end
		--[[if d_c[k][2] == "upfolder" then
			Screen.debugPrint((icon_offset * 2) + 16, ((k - offset) * sel_height) + text_offset - 1, d_c[k][1], Color.new(180, 180, 180), BOTTOM_SCREEN)
		else
			Screen.debugPrint((icon_offset * 2) + 16, ((k - offset) * sel_height) + text_offset - 1, d_c[k][1], white, BOTTOM_SCREEN)
		end]]
		Screen.debugPrint((icon_offset * 2) + 16, ((k - offset) * sel_height) + text_offset, d_c[k][1], white, BOTTOM_SCREEN)
		Screen.drawImage(icon_offset, ((k - offset) * sel_height) + icon_offset, icon[d_c[k][2]], BOTTOM_SCREEN)
	end
	Screen.fillRect(0, 319, 240 - sel_height, 239, Color.new(0, 0, 255, 100), BOTTOM_SCREEN)
	Screen.debugPrint(text_offset, 240 - sel_height + text_offset, sel.." / "..#d_c, white, BOTTOM_SCREEN)
	Screen.debugPrint(3, 5, "Another file manager "..ver, white, TOP_SCREEN)
	--Screen.debugPrint(3, 20, "c_path: "..c_path, white, TOP_SCREEN)
	if debug_thing then
		Screen.debugPrint(3, 25, "a: "..tostring(debug_thing), white, TOP_SCREEN)
	end
	
	------------------------------------------------------------------------------------------------------------------------------------------------------------
	-- this is debug code
	local padddd = Controls.read()
	if Controls.check(padddd, KEY_TOUCH) and Controls.check(padddd, KEY_ZL) then
		if Controls.check(padddd, KEY_TOUCH) then
			ctx, cty = Controls.readTouch()
		end
		if not was_touching then
			was_touching = true
			ptx, pty = ctx, cty
			ox, oy = 0, 0
		end
		if d_allow_control then
			if Controls.check(padddd, KEY_DUP) then
				d_allow_control = false
				d_last_button = KEY_DUP
				pty = pty - 1
			elseif Controls.check(padddd, KEY_DDOWN) then
				d_allow_control = false
				d_last_button = KEY_DDOWN
				pty = pty + 1
			elseif Controls.check(padddd, KEY_DLEFT) then
				d_allow_control = false
				d_last_button = KEY_DLEFT
				ptx = ptx - 1
			elseif Controls.check(padddd, KEY_DRIGHT) then
				d_allow_control = false
				d_last_button = KEY_DRIGHT
				ptx = ptx + 1

			elseif Controls.check(padddd, KEY_X) then
				d_allow_control = false
				d_last_button = KEY_X
				oy = oy - 1
			elseif Controls.check(padddd, KEY_B) then
				d_allow_control = false
				d_last_button = KEY_B
				oy = oy + 1
			elseif Controls.check(padddd, KEY_Y) then
				d_allow_control = false
				d_last_button = KEY_Y
				ox = ox - 1
			elseif Controls.check(padddd, KEY_A) then
				d_allow_control = false
				d_last_button = KEY_A
				ox = ox + 1
			end
		else
			if not Controls.check(padddd, d_last_button) then
				d_allow_control = true
			end
		end
		Screen.fillRect(ptx, ctx + ox, pty, cty + oy, Color.new(255, 255, 255, 150), BOTTOM_SCREEN)
		Screen.fillEmptyRect(ptx, ctx + ox, pty, cty + oy, white, BOTTOM_SCREEN)
		Screen.debugPrint(3, 100, "pt: "..ptx..", "..pty, white, TOP_SCREEN)
		Screen.debugPrint(3, 115, "ct: "..(ctx + ox)..", "..(cty + oy), white, TOP_SCREEN)
	else
		was_touching = false
	end
	------------------------------------------------------------------------------------------------------------------------------------------------------------
end

--------------------------------------------------------------------------------
-- CONTROLS
--------------------------------------------------------------------------------

function checkFile(fname, ftype)
	if ftype == "folder" then
		generateList(System.currentDirectory()..fname.."/")
	--elseif ftype == "upfolder" then
		--generateList(up_f)
	elseif ftype == "img" or ftype == "img_jpeg" then
		previewImage(fname, ftype == "img_jpeg")
	end
end

-- -1 = nothing
-- 0 = back
-- 101+ = file selection (subtract 100)
function getTapSelection(tx, ty)
	if tx <= sel_height and ty <= sel_height then
		return 0
	end
	if ty >= sel_height and ty <= 239 - sel_height then
		return 100 + math.floor(ty / 20)
	end
	return -1
end

in_fm = false -- what the hell was this for???
Graphics.init()
while true do
	local checkfile
	Screen.waitVblankStart()
	Screen.refresh()
	Screen.clear(TOP_SCREEN)
	Screen.clear(BOTTOM_SCREEN)
	pad = Controls.read()
	if Controls.check(pad, KEY_START) then -- always allow exit even if other controls are disabled
		error("%EXIT%") -- System.exit doesn't work inside pcall
	end
	if Controls.check(pad, KEY_SELECT) then
		error("crashing demo")
	end
	if allow_control and not in_fm then
		if Controls.check(pad, KEY_A) then
			allow_control = false
			last_button = KEY_A
			checkFile(d_c[sel][1], d_c[sel][2])
		elseif Controls.check(pad, KEY_ZL) then
			allow_control = false
			last_button = KEY_ZL
		elseif Controls.check(pad, KEY_TOUCH) then
			allow_control = false
			last_button = KEY_TOUCH
			local tx, ty = Controls.readTouch()
			local result = getTapSelection(tx, ty)
			if result == -1 then
				-- nothing!
			elseif result == 0 then
				if not is_root then
					generateList(up_f)
				end
			elseif result >= 101 then
				local r_result = result - 100
			else
				error("invalid tap result under 101")
			end
		elseif Controls.check(pad, KEY_B) then
			allow_control = false
			last_button = KEY_B
			if not is_root then
				generateList(up_f)
			end
		elseif Controls.check(pad, KEY_DDOWN) then
			allow_control = false
			last_button = KEY_DDOWN
			sel = sel + 1
			if sel > #d_c then
				sel = #d_c
			elseif sel > math.min(#d_c + offset, 10 + offset) then
				offset = offset + 1
			end
		elseif Controls.check(pad, KEY_DUP) then
			allow_control = false
			last_button = KEY_DUP
			sel = sel - 1
			if sel < 1 then
				sel = 1
			elseif sel < offset + 1 then
				offset = offset - 1
			end
		end
	else
		if not Controls.check(pad, last_button) then
			allow_control = true
		end
	end
	local tx, ty = Controls.readTouch()
    local result = getTapSelection(tx, ty)
	renderMain(result)
	Screen.flip()
end

end) -- end of pcall

if err:sub(-6) == "%EXIT%" then
	System.exit()
else
	crash(status, err) -- theoretically this line should never be reached, but you never know
end
