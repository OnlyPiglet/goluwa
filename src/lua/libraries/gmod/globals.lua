local gmod = ... or gmod
local globals = gmod.env

local function make_is(name)
	if name:sub(1,1) == name:sub(1,1):upper() then
		globals["is" .. name:lower()] = function(var)
			return typex(var) == name
		end
	else
		globals["is" .. name:lower()] = function(var)
			return type(var) == name
		end
	end
end

make_is("nil")
make_is("string")
make_is("number")
make_is("table")
make_is("bool")
make_is("Entity")
make_is("Angle")
make_is("Vector")
make_is("Color")
make_is("function")
make_is("Panel")

function globals.type(obj)
	local t = type(obj)

	if t == "table" then
		local meta = getmetatable(obj)
		if meta and meta.MetaName then
			return meta.MetaName
		end
	end

	return t
end

function globals.istable(obj)
	return globals.type(obj) == "table"
end

do
	local nw_globals = {}

	local function ADD(name)
		globals["SetGlobal" .. name] = function(key, val) nw_globals[key] = val end
		globals["GetGlobal" .. name] = function(key) return nw_globals[key] end
	end

	ADD("String")
	ADD("Int")
	ADD("Float")
	ADD("Vector")
	ADD("Angles")
	ADD("Entity")
	ADD("Bool")
end

function globals.HSVToColor(h,s,v)
	return globals.Color(ColorHSV(h*360,s,v):Unpack())
end

function globals.ColorToHSV(r,g,b)
	if type(r) == "table" then
		local t = r
		r = t.r
		g = t.g
		b = t.b
	end
	return ColorBytes(r,g,b):GetHSV()
end

function globals.GetHostName()
	return "TODO: hostname"
end

function globals.AddCSLuaFile()

end

function globals.AddConsoleCommand(name)
	commands.Add(name, function(line, ...)
		gmod.env.concommand.Run(NULL, name, {...}, line)
	end)
end

function globals.RunConsoleCommand(...)
	logn("gmod cmd: ", table.concat({...}, " "))
	commands.RunCommand(...)
end

function globals.RealTime() return system.GetElapsedTime() end
function globals.FrameNumber() return tonumber(system.GetFrameNumber()) end
function globals.FrameTime() return system.GetFrameTime() end
function globals.VGUIFrameTime() return system.GetElapsedTime() end
function globals.CurTime() return system.GetElapsedTime() end --system.GetServerTime()
function globals.SysTime() return system.GetTime() end --system.GetServerTime()

function globals.EyeVector()
	return gmod.env.Vector(render.camera_3d:GetAngles():GetForward():Unpack())
end

function globals.EyePos()
	return gmod.env.Vector(render.camera_3d:GetPosition():Unpack())
end

function globals.EyeAngles()
	return gmod.env.Angle(render.camera_3d:GetAngles():Unpack())
end

function globals.FindMetaTable(name)
	return globals._R[name]
end

function globals.Material(path)
	local mat = render.CreateMaterial("model")
	mat.gmod_name = path

	if path:lower():endswith(".png") then
		mat:SetAlbedoTexture(render.CreateTextureFromPath("materials/" .. path))
	elseif vfs.IsFile("materials/" .. path) then
		steam.LoadMaterial("materials/" .. path, mat)
	elseif vfs.IsFile("materials/" .. path .. ".vmt") then
		steam.LoadMaterial("materials/" .. path .. ".vmt", mat)
	elseif vfs.IsFile("materials/" .. path .. ".png") then
		steam.LoadMaterial("materials/" .. path .. ".png", mat)
	end

	return gmod.WrapObject(mat, "IMaterial")
end

function globals.LoadPresets()
	local out = {}

	for folder_name in vfs.Iterate("settings/presets/") do
		if vfs.IsDirectory("settings/presets/"..folder_name) then
			out[folder_name] = {}
			for file_name in vfs.Iterate("settings/presets/"..folder_name.."/") do
				table.insert(out[folder_name], steam.VDFToTable(vfs.Read("settings/presets/"..folder_name.."/" .. file_name)))
			end
		end
	end

	return out
end

function globals.SavePresets()

end

function globals.PrecacheParticleSystem() end

function globals.CreateSound(ent, path, filter)
	local self = audio.CreateSource("sound/" .. path)

	return gmod.WrapObject(self, "CSoundPatch")
end

function globals.Msg(...) log(...) end
function globals.MsgC(...) log(...) end
function globals.MsgN(...) logn(...) end

globals.include = function(path)
	local ok, err = include({
		path,
		"lua/" .. path,
		path:lower(),
		"lua/" .. path:lower()
	})
	if not ok then
		logn(err)
	end
end

function globals.module(name, _ENV)
	--logn("gmod: module(",name,")")

	local tbl = package.loaded[name] or globals[name] or {}

	if _ENV == package.seeall then
		_ENV = globals
		setmetatable(tbl, {__index = _ENV})
	elseif _ENV then
		print(_ENV, "!?!??!?!")
	end

	if not tbl._NAME then
		tbl._NAME = name
		tbl._M = tbl
		tbl._PACKAGE = name:gsub("[^.]*$", "")
	end

	package.loaded[name] = tbl
	globals[name] = tbl

	setfenv(2, tbl)
end

function globals.require(name, ...)
	--logn("gmod: require(",name,")")

	local func, err, path = require.load(name, gmod.dir, true)

	if type(func) == "function" then
		if debug.getinfo(func).what ~= "C" then
			setfenv(func, globals)
		end

		return require.require_function(name, func, path, name)
	end

	if pcall(require, name) then
		return require(name)
	end

	if globals[name] then return globals[name] end

	if not func and err then print(name, err) end

	return func
end

function globals.ParticleEmitter()
	return gmod.WrapObject(ParticleEmitter(), "CLuaEmitter")
end

function globals.CreateMaterial()
	return gmod.WrapObject(render.CreateMaterial("model"), "IMaterial")
end

function globals.HTTP(tbl)
	if tbl.parameters then
		warning("NYI parameters")
		table.print(tbl.parameters)
	end

	if tbl.headers then
		warning("NYI headers")
		table.print(tbl.headers)
	end

	if tbl.body then
		warning("NYI body")
		print(tbl.headers)
	end

	if tbl.type then
		warning("NYI type")
		print(tbl.type)
	end

	sockets.Request({
		url = tbl.url,
		callback = tbl.success,
		on_fail = tbl.failed,
		method = tbl.method:upper(),
	})
end

function globals.CompileString(code, identifier, handle_error)
	if handle_error == nil then handle_error = true end
	local func, err = loadstring(code)
	if func then
		setfenv(func, gmod.env)
		return func
	end
	if handle_error then
		error(err, 2)
	end
	return err
end