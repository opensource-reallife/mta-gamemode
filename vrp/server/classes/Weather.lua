-- ****************************************************************************
-- *
-- *  PROJECT:     vRoleplay
-- *  FILE:        server/classes/Weather.lua
-- *  PURPOSE:     Weather managing class
-- *
-- ****************************************************************************
Weather = inherit(Singleton)

local WEATHER_STATIONS = {
	{
		MainStation = true,
		Name = "Los Santos",
		Position = Vector3(1275.4, -1784.5, 35),
	},
	{
		Name = "Missionary Hill",
		Position = Vector3(-2508.52, -678.44, 143.62),
	},
	{
		Name = "Bone County",
		Position = Vector3(-229.31, 1404.6, 74.43),
	},
	{
		Name = "Palomino Creek",
		Position = Vector3(2255.26, -71.85, 35.25),
	},
}

Weather.Data = {
	{0, "Sehr sonnig, warm", 0}, -- EXTRASUNNY_LA
	{1, "Sonnig, warm", 0}, -- SUNNY_LA
	{2, "Sehr sonnig, Smog", 0}, -- EXTRASUNNY_SMOG_LA
	{3, "Sonnig, Smog", 0}, -- SUNNY_SMOG_LA
	{4, "Bewölkt, warm", 0}, -- CLOUDY_LA
	{4, "Bewölkt, warm", 1}, -- CLOUDY_LA
	{5, "Sonnig, kühl", 0}, -- SUNNY_SF
	{6, "Sehr sonnig, kühl", 0}, -- EXTRASUNNY_SF
	{7, "Bewölkt, kühl", 0}, -- CLOUDY_SF
	{7, "Bewölkt, kühl", 1}, -- CLOUDY_SF
	--{8, "Gewitter", 1}, -- RAINY_SF
	--{9, "Nebel", 0}, -- FOGGY_SF
	{10, "Sonnig, heiß", 0}, -- SUNNY_VEGAS
	{11, "Sehr sonnig, heiß", 0}, -- EXTRASUNNY_VEGAS
	{12, "Bewölkt, heiß", 0}, -- CLOUDY_VEGAS
	{12, "Bewölkt, heiß", 1}, -- CLOUDY_VEGAS
	{13, "Sehr sonnig, mild", 0}, -- EXTRASUNNY_COUNTRYSIDE
	{14, "Sonnig, mild", 0}, -- SUNNY_COUNTRYSIDE
	{15, "Bewölkt, mild", 0}, -- CLOUDY_COUNTRYSIDE
	{15, "Bewölkt, mild", 1}, -- CLOUDY_COUNTRYSIDE
	--{16, "Gewitter", 1}, -- RAINY_COUNTRYSIDE
	{17, "Sehr sonnig, trocken", 0}, -- EXTRASUNNY_DESERT
	{18, "Sonnig, trocken", 0}, -- SUNNY_DESERT
	--{19, "Sandsturm", 0}, -- SANDSTORM_DESERT
	--{20, "Toxisch", 0}, -- UNDERWATER
}

function Weather:constructor()
	self:setWeather(Weather.Data[Randomizer:get(1, #Weather.Data)])
	Timer(bind(self.checkWeatherBlended, self), 30000, 0)

	self:loadWeatherStations()

	addRemoteEvents({"requestRainLevel", "receiveFrequency", "requestWeatherData"})
	addEventHandler("requestRainLevel", resourceRoot, function()
		triggerClientEvent(client, "receiveRainLevel", resourceRoot, getRainLevel())
	end)
	addEventHandler("receiveFrequency", root, bind(self.Event_receiveFrequency, self))
	addEventHandler("requestWeatherData", resourceRoot, bind(self.Event_requestWeatherData, self))
end

function Weather:changeWeatherRandomly()
	local nextWeather
	repeat
		nextWeather = Weather.Data[Randomizer:get(1, #Weather.Data)]
	until self.m_CurrentWeather ~= nextWeather
	self:setWeatherBlended(nextWeather)
end

function Weather:setWeather(weather)
	setWeather(weather[1])
	self.m_CurrentWeather = weather
	self.m_NextWeather = false
	self:setRainLevel(weather[3])
	self:changeWeatherRandomly()
end

function Weather:setWeatherBlended(nextWeather)
	setWeatherBlended(nextWeather[1])
	self.m_NextWeather = nextWeather
	self.m_LastChange = getRealTime()
	CompanyManager:getSingleton():getFromId(CompanyStaticId.SANNEWS):sendShortMessage("Es sind neue Wetterdaten verfügbar!")
end

function Weather:checkWeatherBlended()
	local weather = getWeather()
	if self.m_NextWeather and weather == self.m_NextWeather[1] then
		self:setRainLevel(self.m_NextWeather[3])
		self.m_CurrentWeather = self.m_NextWeather
		self.m_NextWeather = false
		self:changeWeatherRandomly()
	end
end

function Weather:setRainLevel(rainLevel)
	setRainLevel(rainLevel)
	triggerClientEvent("receiveRainLevel", resourceRoot, rainLevel)
end

function Weather:loadWeatherStations()
	self.m_WeatherStations = {}
	for k, station in ipairs(WEATHER_STATIONS) do
		if station.MainStation then
			self.m_MainStation = WeatherStation:new(station)
		else
			self.m_WeatherStations[station.Name] = WeatherStation:new(station)
		end
	end
end

function Weather:Event_receiveFrequency(frequency, stationName)
	if source ~= client then return end
	for k, station in pairs(self.m_WeatherStations) do
		if station.m_StationName == stationName then
			if station.m_Frequency ~= station.m_TargetFrequency then
				local frequency = tonumber(frequency)
				if frequency == station.m_TargetFrequency then
					local sanNews = CompanyManager.Map[CompanyStaticId.SANNEWS]
					local bankServer = sanNews.m_BankAccountServer
					station.m_Frequency = frequency
					station.m_Connected = true
					client:sendSuccess(_("Frequenz erfolgreich geändert!", client))
					bankServer:transferMoney(sanNews, 1000, "Wartung Wetterstation", "Company", "Maintenance")
					bankServer:transferMoney({client, true}, 500, "Wartung Wetterstation", "Company", "Maintenance")
					sanNews:addLog(player, "Wartung", "hat eine Wetterstation eingestellt!")
					station:resetTimer(true)
				else
					client:sendError(_("Falsche Frequenz!", client))
				end
			end
		end
	end
end

function Weather:Event_requestWeatherData()
	client:triggerEvent("receiveWeatherData", self.m_WeatherStations, self.m_CurrentWeather, self.m_NextWeather, self.m_LastChange)
end