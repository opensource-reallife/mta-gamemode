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
	GUIForm.constructor(self, screenWidth/2-screenWidth*0.3*0.5, screenHeight/2-screenHeight*0.4*0.5, screenWidth*0.3, screenHeight*0.4, true, false, rangeElement)

	self.m_Window = GUIWindow:new(0, 0, self.m_Width, self.m_Height, shopName or _"Shop", true, true, self)
	self.m_Preview = GUIWebView:new(self.m_Height*0.08, self.m_Height*0.12, 204, 125, ("%s/images/logo.png"):format(INGAME_WEB_PATH), true, self.m_Window)
	self.m_Preview:hide()
	self.m_LabelDescription = GUILabel:new(self.m_Width*0.02, self.m_Width*0.32, self.m_Width*0.45, self.m_Height-self.m_Width*0.76, "", self.m_Window) -- use width to align correctly
	self.m_LabelDescription:setFont(VRPFont(self.m_Height*0.07)):setMultiline(true)

	self.m_LabelMaxVehicles = GUILabel:new(self.m_Width*0.5, self.m_Height*0.09, self.m_Width*0.48, self.m_Height*0.05, _("%d/%d Fahrzeuge", #currentVehicles, maxVehicles), self.m_Window)
	self.m_LabelMaxVehicles:setFont(VRPFont(self.m_Height*0.07)):setAlignX("right")

	self.m_Grid = GUIGridList:new(self.m_Width*0.5, self.m_Height*0.17, self.m_Width*0.48, self.m_Height*0.6, self.m_Window)
	self.m_Grid:addColumn(_"Name", 0.5)
	self.m_Grid:addColumn(_"Anzahl", 0.2)
	self.m_Grid:addColumn(_"Preis", 0.3)

	self.m_ButtonBuy = GUIButton:new(self.m_Width*0.65, self.m_Height*0.85, self.m_Width*0.33, self.m_Height*0.12, _"Kaufen", self.m_Window):setBackgroundColor(Color.Green):setBarEnabled(true)
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
