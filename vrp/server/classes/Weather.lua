-- ****************************************************************************
-- *
-- *  PROJECT:     vRoleplay
-- *  FILE:        server/classes/Weather.lua
-- *  PURPOSE:     Weather managing class
-- *
-- ****************************************************************************
Weather = inherit(Singleton)

Weather.Data = {
	{0, "sehr sonnig, warm", 0}, -- EXTRASUNNY_LA
	{1, "sonnig, warm", 0}, -- SUNNY_LA
	{2, "sehr sonnig, Smog", 0}, -- EXTRASUNNY_SMOG_LA
	{3, "sonnig, Smog", 0}, -- SUNNY_SMOG_LA
	{4, "bewölkt, warm", {0, 1}}, -- CLOUDY_LA
	{5, "sonnig, kühl", 0}, -- SUNNY_SF
	{6, "sehr sonnig, kühl", 0}, -- EXTRASUNNY_SF
	{7, "bewölkt, kühl", {0, 1}}, -- CLOUDY_SF
	--{8, "Gewitter", 1}, -- RAINY_SF
	--{9, "Nebel", 0}, -- FOGGY_SF
	{10, "sonnig, trocken", 0}, -- SUNNY_VEGAS
	{11, "sehr sonnig, trocken", 0}, -- EXTRASUNNY_VEGAS
	{12, "bewölkt, trocken", {0, 1}}, -- CLOUDY_VEGAS
	{13, "sehr sonnig, mild", 0}, -- EXTRASUNNY_COUNTRYSIDE
	{14, "sonnig, mild", 0}, -- SUNNY_COUNTRYSIDE
	{15, "bewölkt, mild", {0, 1}}, -- CLOUDY_COUNTRYSIDE
	--{16, "Gewitter", 1}, -- RAINY_COUNTRYSIDE
	{17, "sehr sonnig, heiß", 0}, -- EXTRASUNNY_DESERT
	{18, "sonnig, heiß", 0}, -- SUNNY_DESERT
	--{19, "Sandsturm", 0}, -- SANDSTORM_DESERT
	--{20, "Toxisch", 0}, -- UNDERWATER
}

function Weather:constructor()
	self:setWeather(Weather.Data[Randomizer:get(1, #Weather.Data)])
	setTimer(bind(self.checkWeatherBlended, self), 1000, 0)

	addRemoteEvents({"requestRainLevel"})
	addEventHandler("requestRainLevel", resourceRoot, function()
		triggerClientEvent(client, "receiveRainLevel", resourceRoot, getRainLevel())
	end)
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
	CompanyManager:getSingleton():getFromId(CompanyStaticId.SANNEWS):sendShortMessage(("Das Wetter ändert sich in den nächsten 1-2 Stunden von %s zu %s"):format(self.m_CurrentWeather[2], nextWeather[2]))
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
	if type(rainLevel) == "table" then rainLevel = Randomizer:get(rainLevel[1], rainLevel[2]) end
	setRainLevel(rainLevel)
	triggerClientEvent("receiveRainLevel", resourceRoot, rainLevel)
end