-- ****************************************************************************
-- *
-- *  PROJECT:     vRoleplay
-- *  FILE:        client/classes/GUIForms/Shop/FurnitureShopGUI.lua
-- *  PURPOSE:     FurnitureShopGUI class
-- *
-- ****************************************************************************
FurnitureShopGUI = inherit(GUIForm)
inherit(Singleton, FurnitureShopGUI)
addRemoteEvents{"furnitureBought"}

function FurnitureShopGUI:constructor(marker)
	GUIForm.constructor(self, 10, 10, screenWidth/5/ASPECT_RATIO_MULTIPLIER, screenHeight/2, true, false, marker)

	self.m_Window = GUIWindow:new(0, 0, self.m_Width, self.m_Height, _"Kleidungsgeschäft", false, true, self)
	self.m_FurnitureList = GUIGridList:new(0, self.m_Height*0.22, self.m_Width, self.m_Height*0.72, self.m_Window)
	self.m_FurnitureList:addColumn(_"Name", 0.75)
	self.m_FurnitureList:addColumn(_"Preis", 0.25)
	self.m_ShopImage = GUIImage:new(0, 30, self.m_Width, self.m_Height/7, "files/images/Shops/FurnitureHeader.png", self.m_Window)
	GUILabel:new(0, self.m_Height-self.m_Height/14, self.m_Width, self.m_Height/14, "↕", self.m_Window):setAlignX("center")
	GUILabel:new(6, self.m_Height-self.m_Height/14, self.m_Width*0.5, self.m_Height/14, _"Doppelklick zum Kaufen", self.m_Window):setFont(VRPFont(self.m_Height*0.045)):setAlignY("center"):setColor(Color.Red)

	-- Load furniture info
	for k, category in pairs(FurnitureCategories) do
		self.m_FurnitureList:addItemNoClick(category)
		for model, info in pairs(FurnitureInfo) do
			if category == info[3] then
				local item = self.m_FurnitureList:addItem(info[1], toMoneyString(info[2]))

				-- Add doubleclick event
				item.onLeftDoubleClick = function() triggerServerEvent("furnitureBuy", localPlayer, model) end
				item.onLeftClick = function()
					if self.m_Object then
						self.m_Object:setModel(model)
					else
						self.m_Object = createObject(model, 1390.32, -23.21, 1000.91)
						self.m_Object:setDoubleSided(true)
						self.m_Object:setDimension(PRIVATE_DIMENSION_CLIENT)
						self.m_Object:setInterior(1)
					end
				end
			end
		end
	end

	self.m_FurnitureBought = bind(self.Event_FurnitureBought, self)
	self.m_RotateObject = bind(self.rotateObject, self)

	addEventHandler("furnitureBought", root, self.m_FurnitureBought)
	addEventHandler("onClientPreRender", root, self.m_RotateObject)

	showChat(false)
end

function FurnitureShopGUI:virtual_destructor()
	HUDRadar:getSingleton():show()
	removeEventHandler("furnitureBought", root, self.m_FurnitureBought)
	removeEventHandler("onClientPreRender", root, self.m_RotateObject)
	localPlayer:setFrozen(false)
	localPlayer:setPosition(-551.76, 2593.88, 53.93)
	localPlayer:setRotation(0, 0, 270, "default", true)
	localPlayer:setDimension(0)
	localPlayer:setInterior(0)
	if isElement(self.m_Object) then
		self.m_Object:destroy()
	end
	setCameraTarget(localPlayer)
	showChat(true)
end

function FurnitureShopGUI:Event_FurnitureBought()
	delete(self)
end

function FurnitureShopGUI:rotateObject()
	if self.m_Object then
		local rot = self.m_Object:getRotation()
		self.m_Object:setRotation(0, 0, rot.z+1)
	end
end

function FurnitureShopGUI.initialize()
	local marker = Marker.create(-553.23, 2593.86, 53.93-1, "cylinder", 1.4, 255, 255, 0)
	addEventHandler("onClientMarkerHit", marker, function(hitElement, matchingDimension)
		if hitElement == localPlayer and matchingDimension then
			HUDRadar:getSingleton():hide()
			localPlayer:setFrozen(true)
			localPlayer:setPosition(0, 0, 0, i)
			localPlayer:setDimension(PRIVATE_DIMENSION_CLIENT)
			localPlayer:setInterior(1)
			setCameraMatrix(1396.98, -22.93, 1005.92, 1390.32, -23.21, 1000.91)
			FurnitureShopGUI:new(marker)
		end
	end)

	removeWorldModel(2832, 10000, 0, 0, 0)
	removeWorldModel(2850, 10000, 0, 0, 0)
	removeWorldModel(2812, 10000, 0, 0, 0)
	removeWorldModel(2829, 10000, 0, 0, 0)
	removeWorldModel(2830, 10000, 0, 0, 0)
	removeWorldModel(2831, 10000, 0, 0, 0)
	removeWorldModel(2816, 10000, 0, 0, 0)
	removeWorldModel(2826, 10000, 0, 0, 0)
	removeWorldModel(2852, 10000, 0, 0, 0)
	removeWorldModel(2857, 10000, 0, 0, 0)
	removeWorldModel(2857, 10000, 0, 0, 0)

	for i = 0, 4 do
		setInteriorFurnitureEnabled(i, false)
	end
end