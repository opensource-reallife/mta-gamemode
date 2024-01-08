-- ****************************************************************************
-- *
-- *  PROJECT:     vRoleplay
-- *  FILE:        client/classes/GUIForms/Shop/FCVehicleShopGUI.lua
-- *  PURPOSE:     Faction/Company vehicle shop GUI class
-- *
-- ****************************************************************************
FCVehicleShopGUI = inherit(GUIForm)
inherit(Singleton, FCVehicleShopGUI)

addRemoteEvents{"showFCVehicleShopGUI", "refreshFCVehicleShopGUI"}

function FCVehicleShopGUI:constructor(shopId, shopName, vehicleLimits, currentVehicles, maxVehicles, vehicleList, rangeElement)
	GUIWindow.updateGrid()			-- initialise the grid function to use a window
	self.m_Width = grid("x", 17) 	-- width of the window
	self.m_Height = grid("y", 12) 	-- height of the window

	GUIForm.constructor(self, screenWidth/2-self.m_Width/2, screenHeight/2-self.m_Height/2, self.m_Width, self.m_Height, true)
	self.m_Window = GUIWindow:new(0, 0, self.m_Width, self.m_Height, shopName or _"Shop", true, true, self)
	
	self.m_Preview = GUIGridWebView:new(1, 1, 6, 4, ("%s/images/logo.png"):format(INGAME_WEB_PATH), true, self.m_Window)
	self.m_Preview:hide()
	
	self.m_LabelDescription = GUIGridLabel:new(1, 5, 6, 7, "", self.m_Window):setAlignY("top"):setMultiline(true)
	
	self.m_Grid = GUIGridGridList:new(8, 1, 9, 10, self.m_Window)
	self.m_Grid:addColumn(_"Name", 0.5)
	self.m_Grid:addColumn(_"Anzahl", 0.2)
	self.m_Grid:addColumn(_"Preis", 0.30)
	
	self.m_LabelMaxVehicles = GUIGridLabel:new(8, 11, 5, 1, _("%d/%d Fahrzeuge", #currentVehicles, maxVehicles), self.m_Window)
	
	self.m_ButtonBuy = GUIGridButton:new(13, 11, 4, 1, _"Kaufen", self.m_Window):setBackgroundColor(Color.Green):setBarEnabled(true)
	self.m_ButtonBuy.onLeftClick = bind(self.ButtonBuy_Click, self)


    self.m_Shop = shopId

	for k, vehicle in pairs(vehicleList) do
        local name = VehicleCategory:getSingleton():getModelName(vehicle.model)
		local current, limit = FCVehicleShopGUI.getVehicleLimit(vehicle.model, vehicleLimits, currentVehicles)
        local item = self.m_Grid:addItem(name, ("%d/%d"):format(current, limit), toMoneyString(vehicle.price))
		item.Id = k

        item.onLeftClick = function()
            self.m_Preview:loadURL(("%s/images/veh/Vehicle_%d.jpg"):format(INGAME_WEB_PATH, vehicle.model))
			self.m_Preview:show()
            self.m_LabelDescription:setText(vehicle.description)
        end
    end
end

function FCVehicleShopGUI:ButtonBuy_Click()
	if not self.m_Grid:getSelectedItem() then
		ErrorBox:new(_"Bitte wähle zuerst ein Fahrzeug aus")
		return
	end

	local vehicle = self.m_Grid:getSelectedItem().Id
	if not vehicle then
		core:throwInternalError("Unknown item @ FCVehicleShopGUI")
		return
	end

	triggerServerEvent("buyFCVehicle", localPlayer, self.m_Shop, vehicle)
end

function FCVehicleShopGUI.getVehicleLimit(model, vehicleLimits, currentVehicles)
	local current = 0
	local limit = 0

	for id, max in pairs(vehicleLimits) do
		if id == model then
			limit = max
		end
	end

	for k, vehicle in pairs(currentVehicles) do
		if vehicle:getModel() == model then
			current = current + 1
		end
	end

	return current, limit
end

addEventHandler("showFCVehicleShopGUI", root,
	function(shopId, shopName, vehicleLimits, currentVehicles, maxVehicles, vehicleList, ped)
		if FCVehicleShopGUI:isInstantiated() then delete(FCVehicleShopGUI:getSingleton()) end
		FCVehicleShopGUI:new(shopId, shopName, vehicleLimits, currentVehicles, maxVehicles, vehicleList, ped)
	end
)
