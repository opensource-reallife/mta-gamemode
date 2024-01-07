-- ****************************************************************************
-- *
-- *  PROJECT:     vRoleplay
-- *  FILE:        client/classes/GUIForms/ArmsDealerGUI.lua
-- *  PURPOSE:     Arrest GUI class
-- *
-- ****************************************************************************
ArmsDealerGUI = inherit(GUIForm)
inherit(Singleton, ArmsDealerGUI)

addRemoteEvents{"openArmsDealerGUI", "updateFactionArmsDealerShopGUI"}

function ArmsDealerGUI:constructor(type)
	GUIForm.constructor(self, screenWidth/2-945/2, screenHeight/2-230, 945, 460)
	self.m_Window = GUIWindow:new(0, 0, self.m_Width, self.m_Height, _"Waffenlieferung", true, true, self)
	self.m_Window:deleteOnClose(true)

	self.m_Type = type

	self.m_Cart = {}
	self.m_Cart["Weapon"] = {}
	self.m_Cart["Equipment"] = {}

	self.m_WeaponArea = GUIScrollableArea:new(0, 35, 640, 380, 495, 500, true, false, self.m_Window, 35)

	self.m_WeaponsImage = {}
	self.m_WeaponsName = {}
	self.m_WeaponsMenge = {}
	self.m_WeaponsMunition = {}
	self.m_WeaponsBuyGun = {}
	self.m_WeaponsBuyMunition = {}
	self.m_Equipment = {}
	self.m_WaffenAnzahl = 0
	self.m_WaffenRow = 0
	self.m_WaffenColumn = 0
	self.m_TotalCosts = 0

	self.m_MaxCosts = 0

	self.m_CartGrid = GUIGridList:new(645, 35, 280, 350, self.m_Window)
	self.m_CartGrid:addColumn(_"Ware", 0.6)
	self.m_CartGrid:addColumn(_"Anz.", 0.1)
	self.m_CartGrid:addColumn(_"Preis", 0.3)
	self.m_del = GUIButton:new(645, 430, 135, 20,_"Entfernen", self.m_Window)
	self.m_del:setBackgroundColor(Color.Red)
	self.m_del:setEnabled(false)
	self.m_del.onLeftClick = bind(self.deleteItemFromCart,self)
	self.m_buy = GUIButton:new(795, 430, 135, 20,_"Beladen", self.m_Window)
	self.m_buy.onLeftClick = bind(self.factionArmsDealerLoad,self)
	self.m_ShiftNotice = GUILabel:new(25, 430, 500, 20, _("Info: Strg + Klick: Alles aufladen | Shift + Klick: 10 aufladen"), self.m_Window)
	self.m_Sum = GUILabel:new(645, 395, 280, 28, _("Gesamtkosten: 0$"), self.m_Window)
	--self.m_Info = GUIButton:new(945-28-15, 395, 28, 28, FontAwesomeSymbols.Info, self.m_Window)
	--self.m_Info:setFont(FontAwesome(20)):setFontSize(1)
	--self.m_Info:setBarEnabled(false)
    --self.m_Info:setBackgroundColor(Color.Accent)
	addEventHandler("updateFactionArmsDealerShopGUI", root, bind(self.Event_updateArmsDealerGUI, self))

	self:factionReceiveArmsDealerShopInfos()
end

function ArmsDealerGUI:destuctor()
	removeEventHandler("updateFactionArmsDealerShopGUI", root, bind(self.Event_updateArmsDealerGUI, self))
	GUIForm.destructor(self)
end

function ArmsDealerGUI:onShow()
	AntiClickSpam:getSingleton():setEnabled(false)
end

function ArmsDealerGUI:onHide()
	AntiClickSpam:getSingleton():setEnabled(true)
end

function ArmsDealerGUI:Event_updateArmsDealerGUI(specialWeapons, depotWeaponsMax, depotWeapons, depotEquipmentMax, depotEquipments)
	self.m_SpecialWeapons = specialWeapons
	self.m_DepotWeaponsMax = depotWeaponsMax
	self.m_DepotEquipmentMax = depotEquipmentMax
	self.m_Weapons = specialWeapons["Weapons"]
	self.m_Equipment = specialWeapons["Equipment"]
	if self.m_Weapons then
		for k,v in pairs(self.m_Weapons) do
			if v == true then
				self:addWeaponToGUI(k,depotWeapons[k]["Waffe"],depotWeapons[k]["Munition"])
			end
		end
	end
	
	if self.m_Equipment then
		self.m_WaffenColumn = self.m_WaffenColumn + 1
		self.m_WaffenRow = 0
		self.m_WaffenAnzahl = 0
		for k, v in pairs(self.m_Equipment) do
			if v == true then
				self:addEquipmentToGUI(k, depotEquipments[k])
			end
			
		end
	end

	self.m_WeaponArea:resize(465, 230+self.m_WaffenColumn*140)

	self.m_WeaponDepot = depotWeapons
	self.m_EquipmentDepot = depotEquipments
	self:updateButtons()
	self:updateCart()
end

function ArmsDealerGUI:addWeaponToGUI(weaponID,Waffen,Munition)
	local maxWeapon = self.m_DepotWeaponsMax[weaponID]["Waffe"]
	local maxMagazine = self.m_DepotWeaponsMax[weaponID]["Magazine"]
	local weaponPrice = self.m_DepotWeaponsMax[weaponID]["WaffenPreis"]
	local magazinePrice = self.m_DepotWeaponsMax[weaponID]["MagazinPreis"]

	self.m_WeaponsName[weaponID] = GUILabel:new(15+self.m_WaffenRow*125, 5+self.m_WaffenColumn*200, 105, 25, WEAPON_NAMES[weaponID], self.m_WeaponArea)
	self.m_WeaponsName[weaponID]:setAlignX("center")
	self.m_WeaponsImage[weaponID] = GUIImage:new(35+self.m_WaffenRow*125, 30+self.m_WaffenColumn*200, 60, 60, FileModdingHelper:getSingleton():getWeaponImage(weaponID), self.m_WeaponArea)
	self.m_WeaponsMenge[weaponID] = GUILabel:new(15+self.m_WaffenRow*125, 95+self.m_WaffenColumn*200, 105, 20, _("Waffen: %s%s",Waffen, maxWeapon ~= -1 and ("/%s"):format(maxWeapon) or ""), self.m_WeaponArea)
	self.m_WeaponsMenge[weaponID]:setAlignX("center")
	self.m_WeaponsBuyGun[weaponID] = GUIButton:new(15+self.m_WaffenRow*125, 130+self.m_WaffenColumn*200, 105, 20,_("+Waffe (%s)", toMoneyString(weaponPrice)), self.m_WeaponArea)
	self.m_WeaponsBuyGun[weaponID]:setBackgroundColor(Color.Red):setFontSize(1)
	self.m_WeaponsBuyGun[weaponID].onLeftClick = bind(self.addItemToCart,self,"weapon",weaponID)
	
	if maxWeapon - Waffen > 0 then
		self.m_MaxCosts = self.m_MaxCosts + ((maxWeapon - Waffen) * weaponPrice)
	end

	if weaponID >=22 and weaponID <= 43 then
		self.m_WeaponsBuyMunition[weaponID] = GUIButton:new(15+self.m_WaffenRow*125, 155+self.m_WaffenColumn*200, 105, 20,_("+Magazin (%s)", toMoneyString(magazinePrice)), self.m_WeaponArea)
		self.m_WeaponsBuyMunition[weaponID]:setBackgroundColor(Color.Blue):setFontSize(1)
		self.m_WeaponsBuyMunition[weaponID].onLeftClick = bind(self.addItemToCart,self,"ammu",weaponID)
		self.m_WeaponsMunition[weaponID] = GUILabel:new(15+self.m_WaffenRow*125, 110+self.m_WaffenColumn*200, 105, 20, _("Magazine: %s%s",Munition, maxMagazine ~= -1 and ("/%s"):format(maxMagazine) or ""), self.m_WeaponArea):setFontSize(0.8)
		self.m_WeaponsMunition[weaponID]:setAlignX("center")
		if maxMagazine - Munition > 0 then
			self.m_MaxCosts = self.m_MaxCosts + ((maxMagazine - Munition) * magazinePrice)
		end
	end

	if not(self.m_Cart["Weapon"][weaponID]) then
		self.m_Cart["Weapon"][weaponID] = {}
		self.m_Cart["Weapon"][weaponID]["Waffe"] = 0
		self.m_Cart["Weapon"][weaponID]["Munition"] = 0
	end

	self.m_WaffenAnzahl = self.m_WaffenAnzahl+1

	if self.m_WaffenAnzahl % 5 == 0 then
		self.m_WaffenRow = 0
		self.m_WaffenColumn = self.m_WaffenColumn+1
	else
		self.m_WaffenRow = self.m_WaffenRow+1
	end

end

function ArmsDealerGUI:addEquipmentToGUI(item, itemCount)
	local maxItems = self.m_DepotEquipmentMax[item]["Item"]
	local itemPrice = self.m_DepotEquipmentMax[item]["Price"]

	self.m_WeaponsName[item] = GUILabel:new(15+self.m_WaffenRow*125, 5+self.m_WaffenColumn*200, 105, 25, WEAPON_NAMES[item == "Fallschirm" and 46 or item], self.m_WeaponArea)
	self.m_WeaponsName[item]:setAlignX("center")
	self.m_WeaponsImage[item] = GUIImage:new(35+self.m_WaffenRow*125, 30+self.m_WaffenColumn*200, 60, 60, FileModdingHelper:getSingleton():getWeaponImage(item == "Fallschirm" and 46 or item), self.m_WeaponArea)
	self.m_WeaponsMenge[item] = GUILabel:new(15+self.m_WaffenRow*125, 95+self.m_WaffenColumn*200, 105, 20, _("Anzahl: %s%s",itemCount , maxItems ~= -1 and ("/%s"):format(maxItems) or ""), self.m_WeaponArea)
	self.m_WeaponsMenge[item]:setAlignX("center")
	self.m_WeaponsBuyGun[item] = GUIButton:new(15+self.m_WaffenRow*125, 130+self.m_WaffenColumn*200, 105, 20,_("+Item (%s)", toMoneyString(itemPrice)), self.m_WeaponArea)
	self.m_WeaponsBuyGun[item]:setBackgroundColor(Color.Red):setFontSize(1)
	self.m_WeaponsBuyGun[item].onLeftClick = bind(self.addItemToCart,self,"equipment",item)
	self.m_MaxCosts = self.m_MaxCosts + (self.m_DepotEquipmentMax[item]["MaxPerAirDrop"] * itemPrice)

	if not(self.m_Cart["Equipment"][item]) then
		self.m_Cart["Equipment"][item] = {}
		self.m_Cart["Equipment"][item]["Count"] = 0
	end

	self.m_WaffenAnzahl = self.m_WaffenAnzahl+1

	if self.m_WaffenAnzahl % 5 == 0 then
		self.m_WaffenRow = 0
		self.m_WaffenColumn = self.m_WaffenColumn+1
	else
		self.m_WaffenRow = self.m_WaffenRow+1
	end

end


function ArmsDealerGUI:updateButtons()
	if self.m_Weapons then
		for weaponID,v in pairs(self.m_Weapons) do
			if v == true then
				if self.m_WeaponDepot[weaponID]["Waffe"]+self.m_Cart["Weapon"][weaponID]["Waffe"] < self.m_DepotWeaponsMax[weaponID]["Waffe"] then
					self.m_WeaponsBuyGun[weaponID]:setEnabled(true)
				else
					self.m_WeaponsBuyGun[weaponID]:setEnabled(false)
				end

				if self.m_WeaponsBuyMunition[weaponID] then
					if self.m_WeaponDepot[weaponID]["Munition"]+self.m_Cart["Weapon"][weaponID]["Munition"] < self.m_DepotWeaponsMax[weaponID]["Magazine"] then
						self.m_WeaponsBuyMunition[weaponID]:setEnabled(true)
					else
						self.m_WeaponsBuyMunition[weaponID]:setEnabled(false)
					end
				end
			end
		end
	end

	if self.m_Equipment then
		for equip, state  in pairs(self.m_Equipment) do
			if state then
				if self.m_Cart["Equipment"][equip]["Count"] >= self.m_DepotEquipmentMax[equip]["MaxPerAirDrop"] then
					self.m_WeaponsBuyGun[equip]:setEnabled(false)
				else
					self.m_WeaponsBuyGun[equip]:setEnabled(true)
				end
			end
		end
	end
	if self.m_TotalCosts > 0 then self.m_buy:setEnabled(true) else	self.m_buy:setEnabled(false) end
end

function ArmsDealerGUI:updateCart()
	self.m_del:setEnabled(false)
	self.m_CartGrid:clear()
	local name, item, price
	local totalCosts = 0
	for itemType , tbl in pairs(self.m_Cart) do
		for id,amountInfo in pairs(tbl) do
			for type, amount in pairs(amountInfo) do
				if amount > 0 then
					if itemType == "Weapon" then
						if type == "Waffe" then
							name = WEAPON_NAMES[id]
							price = amount*self.m_DepotWeaponsMax[id]["WaffenPreis"]
						elseif type == "Munition" then
							name = WEAPON_NAMES[id].." Magazin"
							price = amount*self.m_DepotWeaponsMax[id]["MagazinPreis"]
						end
					elseif itemType == "Equipment" then
						name = WEAPON_NAMES[id]
						price = amount*self.m_DepotEquipmentMax[id]["Price"]
					end
					totalCosts = totalCosts + price
					item = self.m_CartGrid:addItem(name, amount, toMoneyString(price))
					item.itemType = itemType
					item.typ = type
					item.id = id
					item.onLeftClick = function() self.m_del:setEnabled(true) end
				end
			end

		end
	end

	self.m_TotalCosts = totalCosts
	self.m_Sum:setText(_("Gesamtkosten: %s", toMoneyString(totalCosts)))
	--self.m_Info:setTooltip(table.concat(boxTable, "\n"), "top", true)
end

function ArmsDealerGUI:deleteItemFromCart() --TODO Do this
	local item = self.m_CartGrid:getSelectedItem()
	if item then
		self.m_Cart[item.itemType][item.id][item.typ] = self.m_Cart[item.itemType][item.id][item.typ]-1

		self:updateCart()
		self:updateButtons()
	else
		ErrorBox:new(_"Kein Item ausgewählt!")
	end
end

function ArmsDealerGUI:addItemToCart(typ, weapon)
	local amount = 1
	local itemType, index, index2, indexPrice, max
	if typ == "weapon" or typ == "ammu" then
		itemType = "Weapon"
		index = "Waffe"
		index2 = "Waffe"
		indexPrice = "WaffenPreis"
		if typ == "ammu" then index = "Munition"; index2 = "Magazine"; indexPrice = "MagazinPreis" end
		
		if getKeyState("lctrl") or getKeyState("lshift") then
			max = self.m_DepotWeaponsMax[weapon][index2] - self.m_WeaponDepot[weapon][index] - self.m_Cart[itemType][weapon][index]
		
			if getKeyState("lshift") then
				if max > 10 then max = 10 end
			end
		end

	elseif typ == "equipment" then
		itemType = "Equipment"
		index = "Count"
		index2 = "MaxPerAirDrop"
		indexPrice = "ItemPrice"

		if getKeyState("lctrl") or getKeyState("lshift") then
			max = self.m_DepotEquipmentMax[weapon][index2] - self.m_Cart[itemType][weapon][index]
		
			if getKeyState("lshift") then
				if max > 10 then max = 10 end
			end
		end
	else

	end
	amount = max and max or amount
	self.m_Cart[itemType][weapon][index] = self.m_Cart[itemType][weapon][index] + amount

	self:updateCart()
	self:updateButtons()
end

function ArmsDealerGUI:factionReceiveArmsDealerShopInfos()
	triggerServerEvent("factionReceiveArmsDealerShopInfos",localPlayer)
end

function ArmsDealerGUI:factionArmsDealerLoad()
	triggerServerEvent("checkoutArmsDealerCart", root, self.m_Cart, self.m_MaxCosts)
	delete(self)
end

addEventHandler("openArmsDealerGUI", root,
		function(type)
			if ArmsDealerGUI:getSingleton():isInstantiated() then
				ArmsDealerGUI:getSingleton():open()
			else
				ArmsDealerGUI:getSingleton():new(type)
			end

		end
	)
