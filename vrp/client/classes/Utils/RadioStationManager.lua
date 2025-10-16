

RadioStationManager = inherit(Singleton)
RadioStationManager.FilePath = "radio_stations.xml"
RadioStationManager.Presets = {
	-- GTA channels
	{"Playback FM", 1},
	{"K-Rose", 2},
	{"K-DST", 3},
	{"Bounce FM", 4},
	{"SF-UR", 5},
	{"Radio Los Santos", 6},
	{"Radio X", 7},
	{"CSR 103.9", 8},
	{"K-Jah West", 9},
	{"Master Sounds 98.3", 10},
	{"WCTR", 11},
	{"User Track Player", 12}
}

function RadioStationManager:constructor()
    if not fileExists(RadioStationManager.FilePath) then
        local node = xmlCreateFile(RadioStationManager.FilePath, "stations")
        for i, v in ipairs(RadioStationManager.Presets) do
            local newChild = node:createChild("station")
            newChild:setAttribute("name", v[1])
            newChild:setAttribute("url", v[2])
            newChild:setAttribute("gta", type(v[2]) == "number" and "true" or nil)
        end
        node:saveFile()
        node:unload()
    end
    self:loadFromConfig()
end

function RadioStationManager:loadFromConfig()
    self.m_Stations = {}
	local node = xmlLoadFile(RadioStationManager.FilePath)
	for i,child in ipairs(node:getChildren()) do
		self.m_Stations[i] = {child:getAttribute("name"), child:getAttribute("url")}
		if child:getAttribute("gta") then
			self.m_Stations[i][2] = tonumber(self.m_Stations[i][2]) -- convert the radio station number to a real number
		end
	end
	node:unload()
end

function RadioStationManager:getStations()
    return self.m_Stations
end


function RadioStationManager:saveStations(newStations)
	if newStations and type(newStations) == "table" then
		self.m_Stations = newStations
	end
    local node = xmlCreateFile(RadioStationManager.FilePath, "stations") --override the old file
	for i, v in ipairs(self.m_Stations) do
		local newChild = node:createChild("station")
		newChild:setAttribute("name", v[1])
		newChild:setAttribute("url", v[2])
		newChild:setAttribute("gta", type(v[2]) == "number" and "true" or nil)
	end
	node:saveFile()
	node:unload()
end
