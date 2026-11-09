FactionArmoryGUI = inherit(GUIForm)
inherit(Singleton, FactionArmoryGUI)

addRemoteEvents{"factionArmoryOpen", "factionArmorySync"}

local SCALE, WIDTH, HEIGHT, LIST_WIDTH, PANEL_X, PANEL_WIDTH

local lastPressX, lastPressY = 0, 0
addEventHandler("onClientClick", root, function(button, state, x, y)
	if button == "left" and state == "down" then
		lastPressX, lastPressY = x, y
	end
end)

function FactionArmoryGUI.isPressInside(element)
	local posX, posY = element:getPosition(true)
	local width, height = element:getSize()
	return lastPressX >= posX and lastPressX <= posX + width and lastPressY >= posY and lastPressY <= posY + height
end

function FactionArmoryGUI.guardItemClick(grid, item)
	item.onInternalLeftClick = function(gridItem)
		if FactionArmoryGUI.isPressInside(grid) then
			GUIGridListItem.onInternalLeftClick(gridItem)
		end
	end
end

function FactionArmoryGUI.sortKey(text)
	return (utf8.lower(tostring(text or "")):gsub("ä", "a"):gsub("ö", "o"):gsub("ü", "u"):gsub("ß", "ss"))
end

FactionArmoryGUI.ClipTooltip = "Linksklick: +1 Magazin\nRechtsklick: -1 Magazin\nShift + Linksklick: +10 Magazine\nShift + Rechtsklick: -10 Magazine"

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
	self.m_AmmoClip = GUIButton:new(x+s(95), y+s(48), s(95), s(30), _"Magazin", self.m_Window):setFont(VRPFont(s(22))):setFontSize(1):setBackgroundColor(Color.Orange)
	self.m_AmmoClip:setTooltip(_(FactionArmoryGUI.ClipTooltip), "bottom", true)
	self.m_AmmoClip.onLeftClick = function() self:setAmmoAmount("clip", 1) end
	self.m_AmmoClip.onRightClick = function() self:setAmmoAmount("clip", -1) end
	self.m_AmmoAll = GUIButton:new(x+s(195), y+s(48), PANEL_WIDTH-s(195), s(30), _"Alle", self.m_Window):setFont(VRPFont(s(22))):setFontSize(1):setBackgroundColor(Color.PrimaryNoClick)
	self.m_AmmoAll.onLeftClick = function() self:setAmmoAmount("all") end
	self.m_AmmoTake = GUIButton:new(x, y+s(84), PANEL_WIDTH/2-s(3), s(32), _"Entnehmen", self.m_Window):setFont(VRPFont(s(24))):setFontSize(1)
	self.m_AmmoTake.onLeftClick = function() self:moveAmmo("toPlayer") end
	self.m_AmmoStore = GUIButton:new(x+PANEL_WIDTH/2+s(3), y+s(84), PANEL_WIDTH/2-s(3), s(32), _"Einlagern", self.m_Window):setFont(VRPFont(s(24))):setFontSize(1):setBackgroundColor(Color.PrimaryNoClick)
	self.m_AmmoStore.onLeftClick = function() self:moveAmmo("toStore") end

	y = y + s(130)
	GUILabel:new(x, y, PANEL_WIDTH, s(24), _"Equipment", self.m_Window):setFont(VRPFont(s(24))):setFontSize(1):setColor(Color.Accent)
	self.m_LoadoutChanger = GUIChanger:new(x, y+s(26), PANEL_WIDTH, s(30), self.m_Window)
	self.m_LoadoutTake = GUIButton:new(x, y+s(62), PANEL_WIDTH, s(32), _"Equipment entnehmen", self.m_Window):setFont(VRPFont(s(24))):setFontSize(1)
	self.m_LoadoutTake.onLeftClick = function() self:takeLoadout() end
	local third = (PANEL_WIDTH - s(12)) / 3
	self.m_LoadoutNew = GUIButton:new(x, y+s(100), third, s(30), _"Neu", self.m_Window):setFont(VRPFont(s(22))):setFontSize(1):setBackgroundColor(Color.PrimaryNoClick)
	self.m_LoadoutNew.onLeftClick = function() self:editLoadout(false) end
	self.m_LoadoutEdit = GUIButton:new(x+third+s(6), y+s(100), third, s(30), _"Bearbeiten", self.m_Window):setFont(VRPFont(s(22))):setFontSize(1):setBackgroundColor(Color.PrimaryNoClick)
	self.m_LoadoutEdit.onLeftClick = function() self:editLoadout(true) end
	self.m_LoadoutDelete = GUIButton:new(x+(third+s(6))*2, y+s(100), third, s(30), _"Löschen", self.m_Window):setFont(VRPFont(s(22))):setFontSize(1):setBackgroundColor(Color.Red)
	self.m_LoadoutDelete.onLeftClick = function() self:deleteLoadout() end
	self:refreshLoadouts()

	self.m_StoreAll = GUIButton:new(x, HEIGHT - s(42), PANEL_WIDTH, s(32), _"Alle Waffen einlagern", self.m_Window):setFont(VRPFont(s(24))):setFontSize(1):setBackgroundColor(Color.Red)
	self.m_StoreAll.onLeftClick = function() triggerServerEvent("factionArmoryStoreAll", localPlayer, self.m_Key) end

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
		if (self.m_HideEmpty:isChecked() and self:isUnavailable(weapon)) or self:isHiddenLocked(weapon) then
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
	table.sort(order, function(a, b) return FactionArmoryGUI.sortKey(a) < FactionArmoryGUI.sortKey(b) end)

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
	return FactionArmoryGUI.sortKey(weapon.weaponItem)
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
	return FactionArmoryGUI.sortKey(a.weaponItem) < FactionArmoryGUI.sortKey(b.weaponItem)
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

function FactionArmoryGUI:isHiddenLocked(weapon)
	return weapon.locked and self:getCarried(weapon.weaponItem) <= 0 and self:getCarried(weapon.ammoItem) <= 0
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
	FactionArmoryGUI.guardItemClick(self.m_Grid, item)
	item.onLeftClick = function()
		if not FactionArmoryGUI.isPressInside(self.m_Grid) then return end
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
		if carriedWeapon > 0 then
			self.m_AmmoInfo:setText(_("Im Lager: %d/%d · Dabei: %d", weapon.ammo, weapon.ammoLimit, carriedAmmo))
		else
			self.m_AmmoInfo:setText(_("Im Lager: %d/%d · Nur mit Waffe entnehmbar", weapon.ammo, weapon.ammoLimit))
		end
		self.m_AmmoTake:setEnabled(not weapon.locked and weapon.ammo > 0 and carriedWeapon > 0)
		self.m_AmmoStore:setEnabled(carriedAmmo > 0 and weapon.ammo < weapon.ammoLimit)
	end
end

function FactionArmoryGUI.stepClips(edit, weaponId, direction)
	local clip = math.max(1, getWeaponClipSize(weaponId) or 1)
	local step = (getKeyState("lshift") or getKeyState("rshift")) and 10 or 1
	local current = math.floor(tonumber(edit:getText()) or 0)
	edit:setText(tostring(math.max(0, current + clip * step * direction)))
end

function FactionArmoryGUI:setAmmoAmount(mode, direction)
	local weapon = self:getSelected()
	if not weapon or not weapon.ammoItem then return end
	if mode == "clip" then
		FactionArmoryGUI.stepClips(self.m_AmmoAmount, weapon.id, direction)
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

function FactionArmoryGUI.getLoadouts()
	local loadouts = fromJSON(core:get("FactionArmory", "Loadouts", "[ [ ] ]") or "")
	return type(loadouts) == "table" and loadouts or {}
end

function FactionArmoryGUI.saveLoadouts(loadouts)
	core:set("FactionArmory", "Loadouts", toJSON(loadouts, true))
end

function FactionArmoryGUI:refreshLoadouts(selectName)
	local loadouts = FactionArmoryGUI.getLoadouts()
	local _current, currentIndex = self.m_LoadoutChanger:getSelectedItem()
	self.m_LoadoutChanger:clear()
	local selectIndex = currentIndex
	for index, loadout in ipairs(loadouts) do
		self.m_LoadoutChanger:addItem(loadout.name)
		if selectName and loadout.name == selectName then
			selectIndex = index
		end
	end
	if #loadouts == 0 then
		self.m_LoadoutChanger:addItem(_"Kein Equipment angelegt")
	end
	self.m_LoadoutChanger:setIndex(math.min(math.max(selectIndex or 1, 1), math.max(#loadouts, 1)), true)
	local hasLoadout = #loadouts > 0
	self.m_LoadoutTake:setEnabled(hasLoadout)
	self.m_LoadoutEdit:setEnabled(hasLoadout)
	self.m_LoadoutDelete:setEnabled(hasLoadout)
end

function FactionArmoryGUI:getSelectedLoadout()
	local _name, index = self.m_LoadoutChanger:getSelectedItem()
	return FactionArmoryGUI.getLoadouts()[index], index
end

function FactionArmoryGUI:takeLoadout()
	local loadout = self:getSelectedLoadout()
	if not loadout or type(loadout.entries) ~= "table" or #loadout.entries == 0 then
		ErrorBox:new(_"Dieses Equipment ist leer!")
		return
	end
	triggerServerEvent("factionArmoryTakeLoadout", localPlayer, self.m_Key, loadout.name, loadout.entries)
end

function FactionArmoryGUI:editLoadout(existing)
	local loadout, index = false, false
	if existing then
		loadout, index = self:getSelectedLoadout()
		if not loadout then return end
	end
	if FactionArmoryLoadoutGUI:isInstantiated() then
		delete(FactionArmoryLoadoutGUI:getSingleton())
	end
	FactionArmoryLoadoutGUI:new(self, loadout, index)
	self:close()
end

function FactionArmoryGUI:deleteLoadout()
	local loadout, index = self:getSelectedLoadout()
	if not loadout then return end
	QuestionBox:new(_("Möchtest du das Equipment \"%s\" wirklich löschen?", loadout.name), function()
		local loadouts = FactionArmoryGUI.getLoadouts()
		table.remove(loadouts, index)
		FactionArmoryGUI.saveLoadouts(loadouts)
		if FactionArmoryGUI:isInstantiated() then
			FactionArmoryGUI:getSingleton():refreshLoadouts()
		end
	end)
end

FactionArmoryLoadoutGUI = inherit(GUIForm)
inherit(Singleton, FactionArmoryLoadoutGUI)

function FactionArmoryLoadoutGUI:constructor(armory, loadout, index)
	local width, height = s(560), s(480)
	GUIForm.constructor(self, screenWidth/2 - width/2, screenHeight/2 - height/2, width, height, true)
	self.m_Armory = armory
	self.m_Index = index
	self.m_Entries = {}
	for _index, entry in ipairs(loadout and loadout.entries or {}) do
		if tonumber(entry.id) then
			self.m_Entries[#self.m_Entries + 1] = {id = tonumber(entry.id), ammo = math.max(0, math.floor(tonumber(entry.ammo) or 0))}
		end
	end

	self.m_Window = GUIWindow:new(0, 0, width, height, loadout and _"Equipment bearbeiten" or _"Neues Equipment", true, true, self)
	Inventory.scaleTitleBar(self.m_Window, SCALE)
	self.m_Window:deleteOnClose(true)

	GUILabel:new(s(10), s(42), s(80), s(30), _"Name:", self.m_Window):setFont(VRPFont(s(24))):setFontSize(1)
	self.m_Name = GUIEdit:new(s(90), s(42), width - s(100), s(30), self.m_Window)
	self.m_Name:setText(loadout and loadout.name or "")

	self.m_Grid = GUIGridList:new(s(10), s(82), width - s(20), s(250), self.m_Window, nil, nil, s(30))
	self.m_Grid:addColumn(_"Waffe", 0.55)
	self.m_Grid:addColumn(_"Im Equipment", 0.45)
	self.m_Grid:setFont(VRPFont(s(24)))

	local y = s(342)
	self.m_AmountLabel = GUILabel:new(s(10), y, s(150), s(30), _"Schuss:", self.m_Window):setFont(VRPFont(s(24))):setFontSize(1)
	self.m_Amount = GUIEdit:new(s(110), y, s(100), s(30), self.m_Window):setNumeric(true, true)
	self.m_Clip = GUIButton:new(s(215), y, s(110), s(30), _"Magazin", self.m_Window):setFont(VRPFont(s(22))):setFontSize(1):setBackgroundColor(Color.Orange)
	self.m_Clip:setTooltip(_(FactionArmoryGUI.ClipTooltip), "bottom", true)
	self.m_Clip.onLeftClick = function() self:stepClips(1) end
	self.m_Clip.onRightClick = function() self:stepClips(-1) end

	y = y + s(38)
	self.m_Apply = GUIButton:new(s(10), y, (width - s(26)) / 2, s(32), _"Übernehmen", self.m_Window):setFont(VRPFont(s(24))):setFontSize(1)
	self.m_Apply.onLeftClick = function() self:applyEntry() end
	self.m_Remove = GUIButton:new(s(16) + (width - s(26)) / 2, y, (width - s(26)) / 2, s(32), _"Entfernen", self.m_Window):setFont(VRPFont(s(24))):setFontSize(1):setBackgroundColor(Color.PrimaryNoClick)
	self.m_Remove.onLeftClick = function() self:removeEntry() end

	y = y + s(50)
	self.m_Save = GUIButton:new(s(10), y, width - s(20), s(34), _"Equipment speichern", self.m_Window):setFont(VRPFont(s(24))):setFontSize(1):setBackgroundColor(Color.Green)
	self.m_Save.onLeftClick = function() self:save() end

	self:refresh()
end

function FactionArmoryLoadoutGUI:destructor()
	if FactionArmoryGUI:isInstantiated() and not FactionArmoryGUI:getSingleton():isVisible() then
		FactionArmoryGUI:getSingleton():open()
	end
	GUIForm.destructor(self)
end

function FactionArmoryLoadoutGUI:findEntry(weaponId)
	for index, entry in ipairs(self.m_Entries) do
		if entry.id == weaponId then
			return entry, index
		end
	end
	return false
end

function FactionArmoryLoadoutGUI:getEntryText(weaponId)
	local entry = self:findEntry(weaponId)
	if not entry then return "" end
	if THROWABLE_WEAPONS[weaponId] then
		return _("%d Stück", math.max(entry.ammo, 1))
	end
	return entry.ammo > 0 and _("Waffe + %d Schuss", entry.ammo) or _"Nur Waffe"
end

function FactionArmoryLoadoutGUI:refresh()
	self.m_Grid:clear()
	local itemData = Inventory:getSingleton():getItemData()
	local listed = {}
	local groups, order = {}, {}
	local addWeapon = function(group, weapon)
		if not groups[group] then
			groups[group] = {}
			order[#order + 1] = group
		end
		table.insert(groups[group], weapon)
	end
	for _index, weapon in ipairs(self.m_Armory.m_Weapons or {}) do
		if not weapon.locked then
			listed[weapon.id] = true
			local group = self:findEntry(weapon.id) and _"Im Equipment" or (itemData[weapon.weaponItem] and itemData[weapon.weaponItem]["Gruppe"] or "Waffen")
			addWeapon(group, {id = weapon.id, name = weapon.weaponItem})
		end
	end
	for _index, entry in ipairs(self.m_Entries) do
		if not listed[entry.id] then
			addWeapon(_"Im Equipment", {id = entry.id, name = (WEAPON_NAMES[entry.id] or tostring(entry.id)).." [nicht verfügbar]"})
		end
	end
	local equipmentGroup = _"Im Equipment"
	table.sort(order, function(a, b)
		if (a == equipmentGroup) ~= (b == equipmentGroup) then return a == equipmentGroup end
		return FactionArmoryGUI.sortKey(a) < FactionArmoryGUI.sortKey(b)
	end)
	for _groupIndex, group in ipairs(order) do
		self.m_Grid:addItemNoClick(group == equipmentGroup and group or _(group), ""):setFont(VRPFont(s(24)))
		table.sort(groups[group], function(a, b)
			return FactionArmoryGUI.sortKey(a.name) < FactionArmoryGUI.sortKey(b.name)
		end)
		for _index, weapon in ipairs(groups[group]) do
			self:addWeaponRow(weapon)
		end
	end
end

function FactionArmoryLoadoutGUI:addWeaponRow(weapon)
	local item = self.m_Grid:addItem(weapon.name, self:getEntryText(weapon.id))
	item:setFont(VRPFont(s(24)))
	if self:findEntry(weapon.id) then
		item:setColumnColor(2, Color.Accent)
	end
	FactionArmoryGUI.guardItemClick(self.m_Grid, item)
	item.onLeftClick = function()
		if not FactionArmoryGUI.isPressInside(self.m_Grid) then return end
		self.m_SelectedId = weapon.id
		local entry = self:findEntry(weapon.id)
		self.m_AmountLabel:setText(THROWABLE_WEAPONS[weapon.id] and _"Anzahl:" or _"Schuss:")
		self.m_Amount:setText(tostring(entry and entry.ammo or (THROWABLE_WEAPONS[weapon.id] and 1 or getWeaponClipSize(weapon.id) or 0)))
	end
	if weapon.id == self.m_SelectedId then
		self.m_Grid:onInternalSelectItem(item)
	end
end

function FactionArmoryLoadoutGUI:stepClips(direction)
	if not self.m_SelectedId then
		ErrorBox:new(_"Wähle zuerst eine Waffe!")
		return
	end
	FactionArmoryGUI.stepClips(self.m_Amount, self.m_SelectedId, direction)
end

function FactionArmoryLoadoutGUI:applyEntry()
	if not self.m_SelectedId then
		ErrorBox:new(_"Wähle zuerst eine Waffe!")
		return
	end
	local amount = math.max(0, math.floor(tonumber(self.m_Amount:getText()) or 0))
	local entry = self:findEntry(self.m_SelectedId)
	if entry then
		entry.ammo = amount
	else
		self.m_Entries[#self.m_Entries + 1] = {id = self.m_SelectedId, ammo = amount}
	end
	self:refresh()
end

function FactionArmoryLoadoutGUI:removeEntry()
	local _entry, index = self:findEntry(self.m_SelectedId)
	if index then
		table.remove(self.m_Entries, index)
		self:refresh()
	end
end

function FactionArmoryLoadoutGUI:save()
	local name = (self.m_Name:getText() or ""):gsub("^%s+", ""):gsub("%s+$", "")
	if name == "" then
		ErrorBox:new(_"Gib dem Equipment einen Namen!")
		return
	end
	if #name > 32 then
		ErrorBox:new(_"Der Name darf höchstens 32 Zeichen lang sein!")
		return
	end
	if #self.m_Entries == 0 then
		ErrorBox:new(_"Füge mindestens eine Waffe hinzu!")
		return
	end
	local loadouts = FactionArmoryGUI.getLoadouts()
	for index, loadout in ipairs(loadouts) do
		if loadout.name == name and index ~= self.m_Index then
			ErrorBox:new(_"Es gibt bereits ein Equipment mit diesem Namen!")
			return
		end
	end
	local data = {name = name, entries = self.m_Entries}
	if self.m_Index and loadouts[self.m_Index] then
		loadouts[self.m_Index] = data
	else
		loadouts[#loadouts + 1] = data
	end
	FactionArmoryGUI.saveLoadouts(loadouts)
	if FactionArmoryGUI:isInstantiated() then
		FactionArmoryGUI:getSingleton():refreshLoadouts(name)
	end
	SuccessBox:new(_"Equipment gespeichert!")
	delete(self)
end

addEventHandler("factionArmoryOpen", root, function(key, element)
	if FactionArmoryLoadoutGUI:isInstantiated() then
		delete(FactionArmoryLoadoutGUI:getSingleton())
	end
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
