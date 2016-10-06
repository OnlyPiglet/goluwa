local gmod = ... or _G.gmod

local file = gmod.env.file

local search_paths = {
	game = "",
	workshop = "",
	lua = "lua/",
	data = gmod.dir .. "data/",
	download = gmod.dir .. "download/",
	mod = gmod.dir,
	base_path = gmod.dir .. "../bin/",
}

function file.Open(path, how, where)
	where = where or "data"

	if how:find("w") then
		llog("opening ", path, " with ", how, " from ", where)
	end

	local self, err = vfs.Open(search_paths[where:lower()] .. path, how)

	if self then
		return gmod.WrapObject(self, "File")
	else
		--llog(err)
	end
end


function file.Write(name, str)
	vfs.Write(search_paths.data .. name, str)
end

function file.Read(path, where)
	where = where or "data"
	return vfs.Read(search_paths[where:lower()] .. path)
end

function file.Append(path, str)
	where = where or "data"
	local content = vfs.Read(search_paths.data .. path)
	content = content .. str
	vfs.Write(search_paths.data .. name, content)
end

function file.Find(path, where)
	local files, folders = {}, {}

	path = path:gsub("%.", ".")
	path = path:gsub("%*", ".*")

	if where == "LUA" then
		for k,v in ipairs(vfs.Find("lua/" .. path, true)) do
			if v:startswith(gmod.dir) then
				if vfs.IsDirectory(v) then
					table.insert(folders, v:match(".+/(.+)"))
				else
					table.insert(files, v:match(".+/(.+)"))
				end
			end
		end
	else
		for k,v in ipairs(vfs.Find(path, true)) do
			if vfs.IsDirectory(v) then
				table.insert(folders, v:match(".+/(.+)"))
			else
				table.insert(files, v:match(".+/(.+)"))
			end
		end
	end

	return files, folders
end

function file.Exists(path, where)
	where = where or "data"
	return vfs.Exists(search_paths[where:lower()] .. path)
end

function file.IsDir(path, where)
	where = where or "data"
	return vfs.IsDirectory(search_paths[where:lower()] .. path)
end

function file.Size(path, where)
	where = where or "data"
	local str = vfs.Read(search_paths[where:lower()] .. path)
	if str then
		return #str
	end
	return 0
end

function file.Time(path, where)
	where = where or "data"
	return vfs.GetLastModified(search_paths[where:lower()] .. path) or 0
end