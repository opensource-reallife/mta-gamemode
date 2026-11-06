FactionArmoryGUI = inherit(GUIForm)
inherit(Singleton, FactionArmoryGUI)

addRemoteEvents{"factionArmoryOpen", "factionArmorySync"}

local SCALE, WIDTH, HEIGHT, LIST_WIDTH, PANEL_X, PANEL_WIDTH

local function s(value)
	return math.floor(value * SCALE)
end

function FactionArmoryGUI:constructor(key, element)
	SCALE = Inventory.getScale()
	WIDTH, HEIGHT = s(980), s(560)
	LIST_WIDTH, PANEL_X, PANEL_WIDTH = s(660), s(680), s(290)

	GUIForm.constructor(self, screenWidth/2 - WIDTH/2, screenHeight/2 - HEIGHT/2, WIDTH, HEIGHT, true, false, element, element and 10 or nil)
	self.m_Key = key
	self.m_Window = GUIWindow:new(0, 0, WIDTH, HEIGHT, _"Waffenlager", true, true, self)
	Inventory.scaleTitleBar(self.m_Window, SCALE)
	self.m_Window:deleteOnClose(true)
	self.m_Window.closeCallback = function() triggerServerEvent("itemStorageClose", localPlayer) end

	self.m_WeightBar = GUIProgressBar:new(s(10), s(40), WIDTH-s(20), s(28), self.m_Window)
	self.m_WeightBar:setFontSize(1):setFont(VRPFont(s(26))):setColor(Color.White)
	self.m_StorageWeight = GUILabel:new(s(390), s(69), s(280), s(20), "", self.m_Window):setFont(VRPFont(s(20))):setFontSize(1):setAlignX("right")
	self.m_HideEmpty = GUICheckbox:new(s(10), s(70), s(370), s(20), _"Leere Waffen & Munition verbergen", self.m_Window):setFont(VRPFont(s(22))):setFontSize(1)
	self.m_HideEmpty:setChecked(core:get("Inventory", "HideEmptyWeapons", false) == true)
	self.m_HideEmpty.onChange = function(state)
		core:set("Inventory", "HideEmptyWeapons", state)
		self:refresh(self.m_Weapons, self.m_StoredWeight)
	end

	local listHeight = HEIGHT - s(102)
	self.m_Grid = GUIGridList:new(s(10), s(92), LIST_WIDTH, listHeight, self.m_Window, nil, nil, s(30))
	local iconShare = s(34) / LIST_WIDTH
	self.m_NameShare = 1 - iconShare - 0.16 - 0.21 - 0.15 - 20 / LIST_WIDTH
	self.m_Grid:addColumn("", iconShare)
	self.m_Grid:addColumn(_"Waffe", self.m_NameShare)
	self.m_Grid:addColumn(_"Waffen", 0.16)
	self.m_Grid:addColumn(_"Munition", 0.21)
	self.m_Grid:addColumn(_"Dabei", 0.15)
	self.m_Grid:setFont(VRPFont(s(24)))
	self.m_Grid:setSortable({_"Waffe", _"Waffen", _"Munition", _"Dabei"})
	self.m_Grid.sortList = function() end
	self.m_Grid.onInternalLeftClick = function(grid, cx, cy) self:onHeaderClick(cx, cy) end

	local x, y = PANEL_X, s(92)
	self.m_ImageBackground = GUIRectangle:new(x, y, s(54), s(54), tocolor(0, 0, 0, 200), self.m_Window)
	self.m_Image = GUIImage:new(x+s(5), y+s(5), s(44), s(44), "files/images/Other/noImg.png", self.m_Window)
	self.m_Name = GUILabel:new(x+s(62), y, PANEL_WIDTH-s(62), s(30), _"Wähle eine Waffe", self.m_Window):setFont(VRPFont(s(28))):setFontSize(1)
	self.m_Hint = GUILabel:new(x+s(62), y+s(30), PANEL_WIDTH-s(62), s(22), "", self.m_Window):setFont(VRPFont(s(20))):setFontSize(1)

	y = y + s(66)
	self.m_WeaponHeader = GUILabel:new(x, y, PANEL_WIDTH, s(24), "", self.m_Window):setFont(VRPFont(s(24))):setFontSize(1):setColor(Color.Accent)
	self.m_WeaponInfo = GUILabel:new(x, y+s(24), PANEL_WIDTH, s(20), "", self.m_Window):setFont(VRPFont(s(20))):setFontSize(1)
	self.m_WeaponTake = GUIButton:new(x, y+s(48), PANEL_WIDTH/2-s(3), s(32), _"Entnehmen", self.m_Window):setFont(VRPFont(s(24))):setFontSize(1)
	self.m_WeaponTake.onLeftClick = function() self:moveWeapon("toPlayer") end
	self.m_WeaponStore = GUIButton:new(x+PANEL_WIDTH/2+s(3), y+s(48), PANEL_WIDTH/2-s(3), s(32), _"Einlagern", self.m_Window):setFont(VRPFont(s(24))):setFontSize(1):setBackgroundColor(Color.PrimaryNoClick)
	self.m_WeaponStore.onLeftClick = function() self:moveWeapon("toStore") end

	y = y + s(96)
	self.m_AmmoHeader = GUILabel:new(x, y, PANEL_WIDTH, s(24), _"Munition", self.m_Window):setFont(VRPFont(s(24))):setFontSize(1):setColor(Color.Accent)
	self.m_AmmoInfo = GUILabel:new(x, y+s(24), PANEL_WIDTH, s(20), "", self.m_Window):setFont(VRPFont(s(20))):setFontSize(1)
	self.m_AmmoAmount = GUIEdit:new(x, y+s(48), s(90), s(30), self.m_Window):setNumeric(true, true)
	self.m_AmmoClip = GUIButton:new(x+s(95), y+s(48), s(95), s(30), _"Magazin", self.m_Window):setFont(VRPFont(s(22))):setFontSize(1):setBackgroundColor(Color.PrimaryNoClick)
	self.m_AmmoClip.onLeftClick = function() self:setAmmoAmount("clip") end
	self.m_AmmoAll = GUIButton:new(x+s(195), y+s(48), PANEL_WIDTH-s(195), s(30), _"Alle", self.m_Window):setFont(VRPFont(s(22))):setFontSize(1):setBackgroundColor(Color.PrimaryNoClick)
	self.m_AmmoAll.onLeftClick = function() self:setAmmoAmount("all") end
	self.m_AmmoTake = GUIButton:new(x, y+s(84), PANEL_WIDTH/2-s(3), s(32), _"Entnehmen", self.m_Window):setFont(VRPFont(s(24))):setFontSize(1)
	self.m_AmmoTake.onLeftClick = function() self:moveAmmo("toPlayer") end
	self.m_AmmoStore = GUIButton:new(x+PANEL_WIDTH/2+s(3), y+s(84), PANEL_WIDTH/2-s(3), s(32), _"Einlagern", self.m_Window):setFont(VRPFont(s(24))):setFontSize(1):setBackgroundColor(Color.PrimaryNoClick)
	self.m_AmmoStore.onLeftClick = function() self:moveAmmo("toStore") end

	self.m_Weapons = {}
	self:updateDetail()
end

function FactionArmoryGUI:getCarried(itemName)
	if not itemName then return 0 end
	local amount = 0
	for id, row in pairs(Inventory:getSingleton():getItems()) do
		if row["Objekt"] == itemName then
			amount = amount + row["Menge"]
		end
	end
	return amount
end

function FactionArmoryGUI:getSelected()
	for _index, weapon in ipairs(self.m_Weapons) do
		if weapon.id == self.m_SelectedId then
			return weapon
		end
	end
	return false
end

function FactionArmoryGUI:refresh(weapons, storageWeight)
	self.m_Weapons = weapons
	self.m_StoredWeight = storageWeight
	local inventory = Inventory:getSingleton()
	local weight, maxWeight = inventory.m_Weight, inventory.m_MaxWeight
	local ratio = maxWeight > 0 and weight / maxWeight or 0

	self.m_WeightBar:setText(_("Dein Gewicht: %.2f / %.2f kg (noch %.2f kg frei)", weight, maxWeight, math.max(0, maxWeight - weight)))
	self.m_WeightBar:setProgress(math.min(100, ratio*100))
	self.m_WeightBar:setForegroundColor(ratio > 1 and Color.Red or ratio >= 0.85 and Color.Orange or Color.Accent)
	self.m_StorageWeight:setText(_("Gewicht im Lager: %.2f kg", storageWeight))

	local itemData = inventory:getItemData()
	local groups, order = {}, {}
	for _index, weapon in ipairs(weapons) do
		if self.m_HideEmpty:isChecked() and self:isUnavailable(weapon) then
			if weapon.id == self.m_SelectedId then
				self.m_SelectedId = nil
			end
		else
			local group = itemData[weapon.weaponItem]["Gruppe"] or "Waffen"
			if not groups[group] then
				groups[group] = {}
				order[#order + 1] = group
			end
			table.insert(groups[group], weapon)
		end
	end
	table.sort(order)

	self.m_Grid:clear()
	local nameWidth = LIST_WIDTH * self.m_NameShare - s(8)
	for _index, group in ipairs(order) do
		self.m_Grid:addItemNoClick(_(group), "", "", "", ""):setFont(VRPFont(s(24)))
		table.sort(groups[group], function(a, b) return self:compareWeapons(a, b) end)
		for _weaponIndex, weapon in ipairs(groups[group]) do
			self:addRow(weapon, nameWidth)
		end
	end
	self:updateDetail()
end

function FactionArmoryGUI:getSortValue(weapon, column)
	if column == 3 then
		return weapon.stock
	elseif column == 4 then
		return weapon.ammoItem and weapon.ammo or -1
	elseif column == 5 then
		return self:getCarried(weapon.weaponItem) * 1000000 + self:getCarried(weapon.ammoItem)
	end
	return weapon.weaponItem
end

function FactionArmoryGUI:compareWeapons(a, b)
	local column = self.m_Grid.m_SortColumnIndex
	local direction = self.m_Grid.m_SortColumnDirection
	if column and direction ~= "none" then
		local valueA, valueB = self:getSortValue(a, column), self:getSortValue(b, column)
		if valueA ~= valueB then
			if direction == "up" then
				return valueA < valueB
			end
			return valueA > valueB
		end
	end
	return a.weaponItem < b.weaponItem
end

function FactionArmoryGUI:onHeaderClick(cx, cy)
	local grid = self.m_Grid
	local posX, posY = grid:getPosition(true)
	if cy - posY > grid.m_ItemHeight then return end

	local clicked, width = false, 0
	for id, column in ipairs(grid.m_Columns) do
		if cx - posX < width then break end
		clicked = id
		width = width + column.width * grid.m_Width + 5
	end
	if not clicked or clicked == 1 then return end

	if grid.m_SortColumnIndex == clicked then
		grid.m_SortColumnDirection = ({up = "down", down = "none", none = "up"})[grid.m_SortColumnDirection]
	else
		grid.m_SortColumnIndex = clicked
		grid.m_SortColumnDirection = "up"
	end
	self:refresh(self.m_Weapons, self.m_StoredWeight)
end

function FactionArmoryGUI:isEmpty(weapon)
	return weapon.stock <= 0 and (not weapon.ammoItem or weapon.ammo <= 0)
end

function FactionArmoryGUI:isUnavailable(weapon)
	return self:isEmpty(weapon) and self:getCarried(weapon.weaponItem) <= 0 and self:getCarried(weapon.ammoItem) <= 0
end

function FactionArmoryGUI:addRow(weapon, nameWidth)
	local carriedWeapon = self:getCarried(weapon.weaponItem)
	local carriedAmmo = self:getCarried(weapon.ammoItem)
	local carried = weapon.ammoItem and ("%d / %d"):format(carriedWeapon, carriedAmmo) or tostring(carriedWeapon)
	local suffix = weapon.locked and " [Gesperrt]" or ""
	local name = Inventory.fitText(weapon.weaponItem, nameWidth - VRPTextWidth(suffix, s(24)), s(24))..suffix
	local ammoText = weapon.ammoItem and ("%d/%d"):format(weapon.ammo, weapon.ammoLimit) or "-"
	local item = self.m_Grid:addItem(FileModdingHelper:getSingleton():getWeaponImage(weapon.id) or "files/images/Other/noImg.png", name, ("%d/%d"):format(weapon.stock, weapon.limit), ammoText, carried)
	item:setColumnToImage(1, true, s(30))
	item:setFont(VRPFont(s(24)))
	if weapon.locked then
		item:setColumnColor(2, Color.LightGrey)
	end
	if weapon.stock > weapon.limit then
		item:setColumnColor(3, Color.Orange)
	end
	if weapon.ammoItem and weapon.ammo > weapon.ammoLimit then
		item:setColumnColor(4, Color.Orange)
	end
	if self:isEmpty(weapon) then
		item:setColor(Color.LightGrey)
	end
	item.onLeftClick = function()
		self.m_SelectedId = weapon.id
		self.m_AmmoAmount:setText(tostring(getWeaponClipSize(weapon.id)))
		self:updateDetail()
	end
	if weapon.id == self.m_SelectedId then
		self.m_Grid:onInternalSelectItem(item)
	end
end

function FactionArmoryGUI:setAmmoVisible(state)
	for _index, element in ipairs({self.m_AmmoHeader, self.m_AmmoInfo, self.m_AmmoAmount, self.m_AmmoClip, self.m_AmmoAll, self.m_AmmoTake, self.m_AmmoStore}) do
		element:setVisible(state)
	end
end

function FactionArmoryGUI:updateDetail()
	local weapon = self:getSelected()
	local hasSelection = weapon and true or false
	self.m_WeaponHeader:setVisible(hasSelection)
	self.m_WeaponInfo:setVisible(hasSelection)
	self.m_WeaponTake:setVisible(hasSelection)
	self.m_WeaponStore:setVisible(hasSelection)
	self:setAmmoVisible(hasSelection and weapon.ammoItem ~= nil and weapon.ammoItem ~= false)

	if not weapon then
		self.m_Image:setImage("files/images/Other/noImg.png")
		self.m_Name:setText(_"Wähle eine Waffe")
		self.m_Hint:setText("")
		return
	end

	local itemData = Inventory:getSingleton():getItemData()
	local carriedWeapon = self:getCarried(weapon.weaponItem)
	local isThrowable = THROWABLE_WEAPONS[weapon.id]

	self.m_Image:setImage(FileModdingHelper:getSingleton():getWeaponImage(weapon.id) or "files/images/Other/noImg.png")
	self.m_Name:setText(Inventory.fitText(weapon.weaponItem, PANEL_WIDTH - s(62), s(28)))
	self.m_Hint:setText(weapon.locked and _"Keine Berechtigung zum Entnehmen" or "")

	self.m_WeaponHeader:setText(_("Waffe (%.2f kg je Stück)", itemData[weapon.weaponItem]["Gewicht"]))
	self.m_WeaponInfo:setText(_("Im Lager: %d/%d · Dabei: %d", weapon.stock, weapon.limit, carriedWeapon))
	self.m_WeaponTake:setEnabled(not weapon.locked and weapon.stock > 0 and (isThrowable or carriedWeapon == 0))
	self.m_WeaponStore:setEnabled(carriedWeapon > 0 and weapon.stock < weapon.limit)

	if weapon.ammoItem then
		local carriedAmmo = self:getCarried(weapon.ammoItem)
		self.m_AmmoHeader:setText(_("Munition (%.2f kg je Schuss)", itemData[weapon.ammoItem]["Gewicht"]))
		self.m_AmmoInfo:setText(_("Im Lager: %d/%d · Dabei: %d", weapon.ammo, weapon.ammoLimit, carriedAmmo))
		self.m_AmmoTake:setEnabled(not weapon.locked and weapon.ammo > 0)
		self.m_AmmoStore:setEnabled(carriedAmmo > 0 and weapon.ammo < weapon.ammoLimit)
	end
end

function FactionArmoryGUI:setAmmoAmount(mode)
	local weapon = self:getSelected()
	if not weapon or not weapon.ammoItem then return end
	if mode == "clip" then
		self.m_AmmoAmount:setText(tostring(getWeaponClipSize(weapon.id)))
	else
		self.m_AmmoAmount:setText(tostring(math.max(self:getCarried(weapon.ammoItem), weapon.ammo)))
	end
end

function FactionArmoryGUI:moveWeapon(direction)
	local weapon = self:getSelected()
	if not weapon then return end
	triggerServerEvent("itemStorageMove", localPlayer, self.m_Key, direction, weapon.weaponItem, 1)
end

function FactionArmoryGUI:moveAmmo(direction)
	local weapon = self:getSelected()
	if not weapon or not weapon.ammoItem then return end

	local limit = direction == "toPlayer" and weapon.ammo or self:getCarried(weapon.ammoItem)
	if direction == "toStore" then
		limit = math.min(limit, weapon.ammoLimit - weapon.ammo)
	end
	local amount = math.min(math.floor(tonumber(self.m_AmmoAmount:getText()) or 0), limit)
	if amount <= 0 then
		ErrorBox:new(_"Ungültige Menge!")
		return
	end
	triggerServerEvent("itemStorageMove", localPlayer, self.m_Key, direction, weapon.ammoItem, amount)
end

addEventHandler("factionArmoryOpen", root, function(key, element)
	if DutyGUI:isInstantiated() then
		delete(DutyGUI:getSingleton())
	end
	if FactionArmoryGUI:isInstantiated() then
		delete(FactionArmoryGUI:getSingleton())
	end
	FactionArmoryGUI:new(key, element)
end)

addEventHandler("factionArmorySync", root, function(key, weapons, storageWeight)
	if FactionArmoryGUI:isInstantiated() and FactionArmoryGUI:getSingleton().m_Key == key then
		FactionArmoryGUI:getSingleton():refresh(weapons, storageWeight)
	end
end)
