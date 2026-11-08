GangwarVehicleGUI = inherit(GUIForm)

function GangwarVehicleGUI:constructor(list, carsLeft, carsTotal)
	GUIWindow.updateGrid()
	self.m_Width = grid("x", 10)
	self.m_Height = grid("y", 12)
	GUIForm.constructor(self, screenWidth/2-self.m_Width/2, screenHeight/2-self.m_Height/2, self.m_Width, self.m_Height, true)
	self.m_Window = GUIWindow:new(0, 0, self.m_Width, self.m_Height, _"Fahrzeug spawnen", true, true, self)

	self.m_CarBar = GUIGridProgressBar:new(1, 1, 9, 1, self.m_Window)
	self.m_List = GUIGridGridList:new(1, 2, 9, 9, self.m_Window)
	self.m_List:addColumn(_"Fahrzeug", 0.7)
	self.m_List:addColumn(_"Frei", 0.3)
	self.m_SpawnButton = GUIGridButton:new(1, 11, 9, 1, _"Spawnen", self.m_Window):setBackgroundColor(Color.Green)
	self.m_SpawnButton.onLeftClick = bind(self.onSpawnClick, self)
	self:fill(list, carsLeft, carsTotal)
end

function GangwarVehicleGUI:destructor()
	GangwarVehicleGUI.Current = nil
	GUIForm.destructor(self)
end

function GangwarVehicleGUI:fill(list, carsLeft, carsTotal)
	self.m_CarBar:setProgress(carsTotal > 0 and carsLeft/carsTotal*100 or 0)
	self.m_CarBar:setText(_("%d / %d Fahrzeuge frei", carsLeft, carsTotal))
	self.m_List:clear()
	for key, vehicle in ipairs(list) do
		local item = self.m_List:addItem(vehicle.name, tostring(vehicle.left))
		item.m_Vehicle = vehicle
		item.onLeftDoubleClick = function() self:spawnVehicle(vehicle) end
	end
end

function GangwarVehicleGUI:onSpawnClick()
	local item = self.m_List:getSelectedItem()
	if not item then
		ErrorBox:new(_"Bitte wähle ein Fahrzeug aus!")
		return
	end
	self:spawnVehicle(item.m_Vehicle)
end

function GangwarVehicleGUI:spawnVehicle(vehicle)
	if vehicle.left <= 0 then
		ErrorBox:new(_"Das Limit für dieses Fahrzeug ist erreicht!")
		return
	end
	triggerServerEvent("Gangwar:spawnVehicle", localPlayer, vehicle.id)
end
