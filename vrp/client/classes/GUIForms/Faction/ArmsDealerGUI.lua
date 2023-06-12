-- ****************************************************************************
-- *
-- *  PROJECT:     vRoleplay
-- *  FILE:        client/classes/GUIForms/ArmsDealerGUI.lua
-- *  PURPOSE:     Arrest GUI class
-- *
-- ****************************************************************************
ArmsDealerGUI = inherit(GUIForm)
inherit(Singleton, ArmsDealerGUI)

addRemoteEvents{"showArmsDealerGUI", "updateFactionArmsDealerShopGUI"}

function ArmsDealerGUI:constructor()
	GUIForm.constructor(self, screenWidth/2-945/2, screenHeight/2-230, 945, 460)
	self.m_Window = GUIWindow:new(0, 0, self.m_Width, self.m_Height, _"Waffentruck beladen", true, true, self)
	self.m_Window:deleteOnClose(true)

	self.m_Cart = {}

	self.m_WeaponArea = GUIScrollableArea:new(0, 35, 640, 380, 495, 500, true, false, self.m_Window, 35)

	self.m_WeaponsImage = {}
	self.m_WeaponsName = {}
	self.m_WeaponsMenge = {}
	self.m_WeaponsMunition = {}
	self.m_WeaponsBuyGun = {}
	self.m_WeaponsBuyMunition = {}
	self.m_SpecialItems = {}
	self.m_WaffenAnzahl = 0
	self.m_WaffenRow = 0
	self.m_WaffenColumn = 0
	self.m_TotalCosts = 0

	self.m_BoxContent = {}

	self.m_MaxLoad = 100000

	for i=1, 8 do
		self.m_BoxContent[i] = {}
	end

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
	self.m_Info = GUIButton:new(945-28-15, 395, 28, 28, FontAwesomeSymbols.Info, self.m_Window)
	self.m_Info:setFont(FontAwesome(20)):setFontSize(1)
	self.m_Info:setBarEnabled(false)
    self.m_Info:setBackgroundColor(Color.Accent)
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

function ArmsDealerGUI:Event_updateArmsDealerGUI(specialWeapons, depotWeaponsMax, depotWeapons)
	self.m_SpecialWeapons = specialWeapons
	self.m_DepotWeaponsMax = depotWeaponsMax
	for k,v in pairs(self.m_SpecialWeapons) do
		if v == true then
			if type(k) == "string" or k == 46 then
				self.m_SpecialItems[k] = v		
			else
				self:addWeaponToGUI(k,depotWeapons[k]["Waffe"],depotWeapons[k]["Munition"])
			end
		end
	end

	self.m_WeaponArea:resize(465, 230+self.m_WaffenColumn*200)

	self.m_Depot = depotWeapons
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
	self.m_WeaponsMenge[weaponID] = GUILabel:new(15+self.m_WaffenRow*125, 95+self.m_WaffenColumn*200, 105, 20, "Waffen: "..Waffen.."/"..maxWeapon, self.m_WeaponArea)
	self.m_WeaponsMenge[weaponID]:setAlignX("center")
	self.m_WeaponsBuyGun[weaponID] = GUIButton:new(15+self.m_WaffenRow*125, 130+self.m_WaffenColumn*200, 105, 20,"+Waffe ("..weaponPrice.."$)", self.m_WeaponArea)
	self.m_WeaponsBuyGun[weaponID]:setBackgroundColor(Color.Red):setFontSize(1)
	self.m_WeaponsBuyGun[weaponID].onLeftClick = bind(self.addItemToCart,self,"weapon",weaponID)

	if weaponID >=22 and weaponID <= 43 then
		self.m_WeaponsBuyMunition[weaponID] = GUIButton:new(15+self.m_WaffenRow*125, 155+self.m_WaffenColumn*200, 105, 20,"+Magazin ("..magazinePrice.."$)", self.m_WeaponArea)
		self.m_WeaponsBuyMunition[weaponID]:setBackgroundColor(Color.Blue):setFontSize(1)
		self.m_WeaponsBuyMunition[weaponID].onLeftClick = bind(self.addItemToCart,self,"munition",weaponID)
		self.m_WeaponsMunition[weaponID] = GUILabel:new(15+self.m_WaffenRow*125, 110+self.m_WaffenColumn*200, 105, 20, "Magazine: "..Munition.."/"..maxMagazine, self.m_WeaponArea):setFontSize(0.8)
		self.m_WeaponsMunition[weaponID]:setAlignX("center")

	end

	if not(self.m_Cart[weaponID]) then
		self.m_Cart[weaponID] = {}
		self.m_Cart[weaponID]["Waffe"] = 0
		self.m_Cart[weaponID]["Munition"] = 0
	end

	self.m_WaffenAnzahl = self.m_WaffenAnzahl+1

	if self.m_WaffenAnzahl == 5 or self.m_WaffenAnzahl == 10 or self.m_WaffenAnzahl == 15 then
		self.m_WaffenRow = 0
		self.m_WaffenColumn = self.m_WaffenColumn+1
	else
		self.m_WaffenRow = self.m_WaffenRow+1
	end

end

function ArmsDealerGUI:updateButtons()
	for weaponID,v in pairs(self.m_SpecialWeapons) do
		if v == true then
			if self.m_Depot[weaponID]["Waffe"]+self.m_Cart[weaponID]["Waffe"] < self.m_DepotWeaponsMax[weaponID]["Waffe"] then
				if self.m_TotalCosts + self.m_DepotWeaponsMax[weaponID]["WaffenPreis"] < self.m_MaxLoad then
					self.m_WeaponsBuyGun[weaponID]:setEnabled(true)
				else
					self.m_WeaponsBuyGun[weaponID]:setEnabled(false)
				end
			else
				self.m_WeaponsBuyGun[weaponID]:setEnabled(false)
			end

			if self.m_WeaponsBuyMunition[weaponID] then
				if self.m_Depot[weaponID]["Munition"]+self.m_Cart[weaponID]["Munition"] < self.m_DepotWeaponsMax[weaponID]["Magazine"] then
					if self.m_TotalCosts + self.m_DepotWeaponsMax[weaponID]["MagazinPreis"] <= self.m_MaxLoad then
						self.m_WeaponsBuyMunition[weaponID]:setEnabled(true)
					else
						self.m_WeaponsBuyMunition[weaponID]:setEnabled(false)
					end
				else
					self.m_WeaponsBuyMunition[weaponID]:setEnabled(false)
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
	for weaponID,v in pairs(self.m_Cart) do
		for typ,amount in pairs(self.m_Cart[weaponID]) do
			if amount > 0 then
				if typ == "Waffe" then
					name = WEAPON_NAMES[weaponID]
					price = amount*self.m_DepotWeaponsMax[weaponID]["WaffenPreis"]
				elseif typ == "Munition" then
					name = WEAPON_NAMES[weaponID].." Magazin"
					price = amount*self.m_DepotWeaponsMax[weaponID]["MagazinPreis"]
				end
				totalCosts = totalCosts + price
				item = self.m_CartGrid:addItem(name, amount, price.."$")
				item.typ = typ
				item.id = weaponID
				item.onLeftClick = function() self.m_del:setEnabled(true) end
			end
		end
	end

	local boxTable = {}
	for index, box in pairs(self.m_BoxContent) do
		boxTable[index] = _("Kiste %d: %d$/%d$", index, self:calcBoxAmount(index), self.m_MaxLoadPerBox)
	end

	self.m_TotalCosts = totalCosts
	self.m_Sum:setText(_("Gesamtkosten: %d$/%d$", totalCosts, self.m_MaxLoad))
	self.m_Info:setTooltip(table.concat(boxTable, "\n"), "top", true)
end

function ArmsDealerGUI:deleteItemFromCart()
	local item = self.m_CartGrid:getSelectedItem()
	if item then
		self.m_Cart[item.id][item.typ] = self.m_Cart[item.id][item.typ]-1

		self:removeFromBox(item.typ, item.id)

		self:updateCart()
		self:updateButtons()
	else
		ErrorBox:new(_"Kein Item ausgewählt!")
	end
end

function ArmsDealerGUI:removeFromBox(typ, weapon)
	for index, box in ipairs(self.m_BoxContent) do
		if box[weapon] and box[weapon][typ] and box[weapon][typ] > 0 then
			box[weapon][typ] = box[weapon][typ]-1
			return
		end
	end
end

function ArmsDealerGUI:addItemToCart(typ, weapon)
	local amount = 1
	if getKeyState("lctrl") or getKeyState("lshift") then
		local index = "Waffe"
		local index2 = "Waffe"
		local indexPrice = "WaffenPreis"
		if typ == "munition" then index = "Munition"; index2 = "Magazine"; indexPrice = "MagazinPreis" end

		local max = self.m_DepotWeaponsMax[weapon][index2] - self.m_Depot[weapon][index] - self.m_Cart[weapon][index]

		if getKeyState("lshift") then
			if max > 10 then max = 10 end
		end

		local pricePerUnit = self.m_DepotWeaponsMax[weapon][indexPrice]
		local remainingBudget = self.m_MaxLoad - self.m_TotalCosts

		local maxMoney = math.floor(remainingBudget / pricePerUnit)

		if maxMoney > max then
			amount = max
		else
			amount = maxMoney
		end
	end

	local success = true
	for i = 1, amount do
		local box = self:getBox(typ, weapon)
		if box then
			if not self.m_BoxContent[box][weapon] then self.m_BoxContent[box][weapon] = {} end

			if typ == "weapon" then
				self.m_Cart[weapon]["Waffe"] = self.m_Cart[weapon]["Waffe"] + 1
				if not self.m_BoxContent[box][weapon]["Waffe"] then self.m_BoxContent[box][weapon]["Waffe"] = 0 end

				self.m_BoxContent[box][weapon]["Waffe"] = self.m_BoxContent[box][weapon]["Waffe"] + 1
			end
			if typ == "munition" then
				self.m_Cart[weapon]["Munition"] = self.m_Cart[weapon]["Munition"] + 1
				if not self.m_BoxContent[box][weapon]["Munition"] then self.m_BoxContent[box][weapon]["Munition"] = 0 end
				self.m_BoxContent[box][weapon]["Munition"] = self.m_BoxContent[box][weapon]["Munition"] + 1
			end
		else
			success = false
		end
	end

	if not success then
		ErrorBox:new(_"Es haben nicht alle Waffen/Magazine in den Kisten Platz!")
	end

	self:updateCart()
	self:updateButtons()
end

function ArmsDealerGUI:getBox(typ, weaponID)
	local price = 0
	for index, box in ipairs(self.m_BoxContent) do
		if typ == "weapon" then
			price = self.m_DepotWeaponsMax[weaponID]["WaffenPreis"]
		elseif typ == "munition" then
			price = self.m_DepotWeaponsMax[weaponID]["MagazinPreis"]
		end

		if self:calcBoxAmount(index) + price <= self.m_MaxLoadPerBox then
			return index
		end
	end
	return false
end

function ArmsDealerGUI:calcBoxAmount(i)
	local sum = 0
	for weaponID, data in pairs(self.m_BoxContent[i]) do
		if data["Waffe"] then
			sum = sum + data["Waffe"] * self.m_DepotWeaponsMax[weaponID]["WaffenPreis"]
		end
		if data["Munition"] then
			sum = sum + data["Munition"] * self.m_DepotWeaponsMax[weaponID]["MagazinPreis"]
		end
	end
	return sum
end

function ArmsDealerGUI:factionReceiveArmsDealerShopInfos()
	triggerServerEvent("factionReceiveArmsDealerShopInfos",localPlayer)
end

function ArmsDealerGUI:factionArmsDealerLoad()
	triggerServerEvent("onArmsDealerLoad",root,self.m_BoxContent)
	delete(self)
end

addEventHandler("showArmsDealerGUI", root,
		function()
			if ArmsDealerGUI:getSingleton():isInstantiated() then
				ArmsDealerGUI:getSingleton():open()
			else
				ArmsDealerGUI:getSingleton():new()
			end

		end
	)
