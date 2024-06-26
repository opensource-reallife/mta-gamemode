-- ****************************************************************************
-- *
-- *  PROJECT:     vRoleplay
-- *  FILE:        client/classes/Phone/AppBank.lua
-- *  PURPOSE:     AppBank app class
-- *
-- ****************************************************************************
AppNavigator = inherit(PhoneApp)

function AppNavigator:constructor()
	PhoneApp.constructor(self, "Navigator", "IconNavigator.png")
end

function AppNavigator:onOpen(form)

	-- update faction list
	for id, fac in pairs(FactionManager.Map) do
		AppNavigator.Positions["Fraktionen"][fac:getName()] = fac:getNavigationPosition()
	end

	self.m_TabPanel = GUIPhoneTabPanel:new(0, 0, form.m_Width, form.m_Height, form)
	self.m_Tabs = {}
	self.m_LocationsGrid = {}
	self.m_StartNavigation = {}

	local item

	for category, data in pairs(AppNavigator.Positions) do
		self.m_Tabs[category] = self.m_TabPanel:addTab(_(category), AppNavigator.Icons[category])
		self.m_LocationsGrid[category] = GUIGridList:new(10, 10, form.m_Width-20, form.m_Height-110, self.m_Tabs[category])
		self.m_LocationsGrid[category]:addColumn(_(category), 1)

		for name, pos in pairs(data) do
			item = self.m_LocationsGrid[category]:addItem(_(name))
			item.Position = pos
			item.onLeftDoubleClick = function() self:startNavigationClick(pos) end
		end

		self.m_StartNavigation[category] = GUILabel:new(10, 360, form.m_Width-20, 25, _"Doppelklick um die \nNavigation zu starten!", self.m_Tabs[category]):setMultiline(true):setAlignX("center")

	end


end

function AppNavigator:startNavigationClick(pos)
	if pos then
		GPS:getSingleton():startNavigationTo(pos)
	else
		ErrorBox:new(_"Keinen Punkt ausgewählt!")
		return
	end
end

AppNavigator.Positions = {
	["Allgemein"] = {
		["Stadthalle"] = Vector3(1481.22, -1749.11, 15.45),
		["Billigklamotten"] = Vector3(2244.641, -1664.586, 15.477),
		["Fahrschule"] =  Vector3(1779.07, -1725.88, 13.55),
		["Billigautohändler"] = Vector3(1098.83, -1240.20, 15.55),
		["Tuning-Shop"] = Vector3(1035.58, -1028.90, 32.10),
		["Schrottplatz"] = Vector3(2198.86, -1977.55, 13.56),
		["Krankenhaus"] = Vector3(1183.632, -1323.526, 13.576),
		["Paintball"] = Vector3(1324.733, -1559.327, 13.540),
		["Kartbahn"] = Vector3(1262.375, 188.479, 19.5),
		["ColorCars"] = Vector3(2693.501, -1703.685, 11.502),
		-- ["Premium-Bereich"] = Vector3(1246.52, -2055.33, 59.53),
	},
	["Jobs"] = {
		["Pizza-Lieferant"] = Vector3(2096.89, -1826.28, 13.24),
		["Heli-Transport"] = Vector3(1796.39, -2318.27, 13.11),
		["Müllwagen-Job"] = Vector3(2102.45, -2094.60, 13.23),
		["Logistiker Blueberry"] = Vector3(-234.96, -254.46,  1.11),
		["Logistiker LS Hafen"] = Vector3(2409.07, -2471.10, 13.30),
		["Farmer"] = Vector3(-53.69, 78.28, 2.79),
		["Straßenreinigung"] = Vector3(219.49, -1429.61, 13.0),
		["Schatzsucher"] = Vector3(706.22, -1699.38, 3.12),
		["Gabelstapler"] = Vector3(93.67, -205.68,  1.23),
		["Kiesgruben-Job"] = Vector3(590.71, 868.91, -42.50),
		["Holzfäller"] = Vector3(1026.51, -437.73, 54.24),
		["Boxer"] = Vector3(2219.51, -1715.47, 13.34),
	},
	["Unternehmen"] = {
		["San News"] =     Vector3(762.05, -1343.33, 13.20),
		["Mech & Tow"] =  Vector3(913.83, -1234.65, 16.97),
		["Public Transport"] =	 Vector3(1791.10, -1901.46, 13.08),
	},
	["Fraktionen"] = {}, -- get loaded dynamically!

}

AppNavigator.Icons = {
	["Allgemein"] = FontAwesomeSymbols.Info,
	["Jobs"] = FontAwesomeSymbols.Suitcase,
	["Unternehmen"] = FontAwesomeSymbols.Book,
	["Fraktionen"] = FontAwesomeSymbols.Group,
}
