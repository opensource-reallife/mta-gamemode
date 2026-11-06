StorageGUI = inherit(GUIForm)
inherit(Singleton, StorageGUI)

addRemoteEvents{"itemStorageOpen", "itemStorageSync"}

local SCALE, WIDTH, HEIGHT, LIST_WIDTH

local function s(value)
	return math.floor(value * SCALE)
end

function StorageGUI:constructor(key, title, head, rule, element)
	SCALE = Inventory.getScale()
	WIDTH, HEIGHT, LIST_WIDTH = s(860), s(560), s(395)

	GUIForm.constructor(self, screenWidth/2 - WIDTH/2, screenHeight/2 - HEIGHT/2, WIDTH, HEIGHT, true, false, element, element and 8 or nil)
	self.m_Key = key
	self.m_Window = GUIWindow:new(0, 0, WIDTH, HEIGHT, title, true, true, self)
	Inventory.scaleTitleBar(self.m_Window, SCALE)
	self.m_Window:deleteOnClose(true)
	self.m_Window.closeCallback = function() triggerServerEvent("itemStorageClose", localPlayer) end

	GUILabel:new(s(10), s(36), s(200), s(24), _"Inventar:", self.m_Window):setFont(VRPFont(s(26))):setFontSize(1)
	self.m_Hidden = GUILabel:new(s(210), s(38), LIST_WIDTH-s(200), s(20), "", self.m_Window):setFont(VRPFont(s(20))):setFontSize(1):setAlignX("right")
	GUILabel:new(WIDTH-s(10)-LIST_WIDTH, s(36), s(200), s(24), head, self.m_Window):setFont(VRPFont(s(26))):setFontSize(1)
	GUILabel:new(WIDTH-s(210), s(38), s(200), s(20), rule or "", self.m_Window):setFont(VRPFont(s(20))):setFontSize(1):setAlignX("right")

	self.m_PlayerBar = self:createBar(s(10))
	self.m_StorageBar = self:createBar(WIDTH-s(10)-LIST_WIDTH)
	self.m_PlayerList = self:createList(s(10))
	self.m_StorageList = self:createList(WIDTH-s(10)-LIST_WIDTH)

	self.m_ToStore = GUIButton:new(WIDTH/2-s(15), s(120), s(30), s(180), FontAwesomeSymbols.Right, self.m_Window):setFont(FontAwesome(s(15))):setFontSize(1):setBarEnabled(false):setBackgroundColor(Color.Accent)
	self.m_ToStore.onLeftClick = function() self:move("toStore") end
	self.m_ToPlayer = GUIButton:new(WIDTH/2-s(15), s(306), s(30), s(180), FontAwesomeSymbols.Left, self.m_Window):setFont(FontAwesome(s(15))):setFontSize(1):setBarEnabled(false):setBackgroundColor(Color.Accent)
	self.m_ToPlayer.onLeftClick = function() self:move("toPlayer") end

	self.m_SelectedImage = GUIImage:new(s(16), HEIGHT-s(54), s(44), s(44), "files/images/Other/noImg.png", self.m_Window)
	self.m_SelectedName = GUILabel:new(s(70), HEIGHT-s(58), s(460), s(26), _"Wähle ein Item aus", self.m_Window):setFont(VRPFont(s(26))):setFontSize(1)
	self.m_SelectedInfo = GUILabel:new(s(70), HEIGHT-s(32), s(500), s(20), "", self.m_Window):setFont(VRPFont(s(20))):setFontSize(1)
	GUILabel:new(WIDTH-s(280), HEIGHT-s(46), s(70), s(30), _"Menge:", self.m_Window):setFont(VRPFont(s(24))):setFontSize(1)
	self.m_Amount = GUIEdit:new(WIDTH-s(205), HEIGHT-s(46), s(110), s(30), self.m_Window):setNumeric(true, true)
	self.m_All = GUIButton:new(WIDTH-s(90), HEIGHT-s(46), s(80), s(30), _"Alle", self.m_Window):setFont(VRPFont(s(24))):setFontSize(1)
	self.m_All.onLeftClick = function() self:setMaxAmount() end

	self.m_Rows = {}
	self.m_Accepted = {}
	self.m_Weight, self.m_Capacity = 0, 0
	self:updateSelection()
end

function StorageGUI:createBar(x)
	local bar = GUIProgressBar:new(x, s(62), LIST_WIDTH, s(26), self.m_Window)
	bar:setFontSize(1):setFont(VRPFont(s(24))):setColor(Color.White)
	return bar
end

function StorageGUI:getNameShare()
	return 1 - s(34) / LIST_WIDTH - 0.2 - 0.16 - 15 / LIST_WIDTH
end

function StorageGUI:createList(x)
	local list = GUIGridList:new(x, s(92), LIST_WIDTH, HEIGHT-s(160), self.m_Window, nil, nil, s(30))
	list:addColumn("", s(34) / LIST_WIDTH)
	list:addColumn(_"Item", self:getNameShare())
	list:addColumn(_"Menge", 0.2)
	list:addColumn(_"Gewicht", 0.16)
	list:setFont(VRPFont(s(24)))
	return list
end

function StorageGUI:getCategoryLabel(data)
	return _(data["Gruppe"])
end

function StorageGUI:fillList(list, side, entries)
	local inventory = Inventory:getSingleton()
	local itemData = inventory:getItemData()
	list:clear()

	local groups, order = {}, {}
	for _index, entry in ipairs(entries) do
		local data = itemData[entry.name]
		local label = self:getCategoryLabel(data)
		if not groups[label] then
			groups[label] = {weight = 0, entries = {}}
			order[#order + 1] = label
		end
		groups[label].entries[#groups[label].entries + 1] = entry
		groups[label].weight = groups[label].weight + data["Gewicht"] * entry.amount
		groups[label].rank = math.min(groups[label].rank or 3, data["WaffenId"] and 1 or data["MunitionFuer"] and 3 or 2)
	end
	table.sort(order, function(a, b)
		if groups[a].rank ~= groups[b].rank then return groups[a].rank < groups[b].rank end
		return a < b
	end)

	for _index, label in ipairs(order) do
		list:addItemNoClick(label, "", "", ("%.2f"):format(groups[label].weight)):setFont(VRPFont(s(24)))
		table.sort(groups[label].entries, function(a, b) return a.name < b.name end)
		for _index, entry in ipairs(groups[label].entries) do
			local row = {["Objekt"] = entry.name, ["Value"] = entry.value, ["Menge"] = entry.amount, ["WeaponIcon"] = entry.weaponIcon}
			local suffix = side == "player" and inventory:getRowFlags(row) or ""
			local suffixWidth = suffix ~= "" and dxGetTextWidth(suffix, 1, getVRPFont(VRPFont(s(24)))) or 0
			local name = Inventory.fitText(inventory:getDisplayName(row), LIST_WIDTH*self:getNameShare() - s(8) - suffixWidth, s(24))
			local item = list:addItem(inventory:getItemIcon(row), name..suffix, entry.amount, ("%.2f"):format(itemData[entry.name]["Gewicht"] * entry.amount))
			item:setColumnToImage(1, true, s(30))
			item:setFont(VRPFont(s(24)))
			local rarity = Inventory.RarityColor[itemData[entry.name]["Seltenheit"]]
			if rarity then item:setColumnColor(2, rarity) end
			item.onLeftClick = function()
				self.m_Selected = {side = side, name = entry.name, value = entry.value, amount = entry.amount, weaponIcon = entry.weaponIcon, wear = entry.wear}
				self:setMaxAmount()
				self:updateSelection()
			end
			if self.m_Selected and self.m_Selected.side == side and self.m_Selected.name == entry.name and self.m_Selected.value == entry.value and self.m_Selected.wear == entry.wear then
				list:onInternalSelectItem(item)
				self.m_Selected.amount = entry.amount
				self.m_StillThere = true
			end
		end
	end
end

function StorageGUI:refresh(rows, weight, capacity, accepted, options)
	self.m_Rows, self.m_Weight, self.m_Capacity = rows or {}, weight or 0, capacity or 0
	self.m_Accepted = accepted or self.m_Accepted

	local inventory = Inventory:getSingleton()
	local items = inventory:getItems()
	local playerEntries, storageEntries = {}, {}
	local hiddenNames = 0
	for id, row in pairs(items) do
		if self.m_Accepted[row["Objekt"]] and (row["Value"] ~= "duty" or (options and options.showDuty)) then
			playerEntries[#playerEntries + 1] = {name = row["Objekt"], value = row["Value"] or "", amount = row["Menge"], wear = row["WearLevel"]}
		else
			hiddenNames = hiddenNames + 1
		end
	end
	for id, row in pairs(self.m_Rows) do
		storageEntries[#storageEntries + 1] = {name = row["Item"], value = row["Value"] or "", amount = row["Amount"], weaponIcon = row["WeaponIcon"], wear = row["WearLevel"]}
	end

	for _index, entry in ipairs(options and options.entries or {}) do
		playerEntries[#playerEntries + 1] = entry
	end

	self.m_StillThere = false
	self:fillList(self.m_PlayerList, "player", playerEntries)
	self:fillList(self.m_StorageList, "store", storageEntries)
	if not self.m_StillThere then self.m_Selected = nil end

	self.m_Hidden:setText(hiddenNames > 0 and _("%d Items passen hier nicht", hiddenNames) or "")
	self:updateBar(self.m_PlayerBar, inventory.m_Weight, inventory.m_MaxWeight)
	self:updateBar(self.m_StorageBar, self.m_Weight, self.m_Capacity)
	self:updateSelection()
end

function StorageGUI:updateBar(bar, weight, maxWeight)
	local ratio = maxWeight > 0 and weight / maxWeight or 0
	if maxWeight <= 0 then
		bar:setText(_("Gesamtgewicht: %.2f kg", weight))
		bar:setProgress(0)
		return
	end
	bar:setText(_("%.2f / %.2f kg (noch %.2f kg frei)", weight, maxWeight, math.max(0, maxWeight - weight)))
	bar:setProgress(math.min(100, math.max(0, ratio*100)))
	bar:setForegroundColor(ratio > 1 and Color.Red or ratio >= 0.85 and Color.Orange or Color.Accent)
end

function StorageGUI:isSingleCarry(name)
	local data = Inventory:getSingleton():getItemData()[name]
	return data["WaffenId"] and not THROWABLE_WEAPONS[data["WaffenId"]]
end

function StorageGUI:setMaxAmount()
	if not self.m_Selected then return end
	local amount = self.m_Selected.amount
	if self.m_Selected.side == "store" and self:isSingleCarry(self.m_Selected.name) then amount = 1 end
	self.m_Amount:setText(tostring(amount))
end

function StorageGUI:getBlockReason()
	local selected = self.m_Selected
	if not selected then return false end
	local inventory = Inventory:getSingleton()
	local data = inventory:getItemData()[selected.name]
	if selected.side == "player" and data["WaffenId"] and inventory:isWeaponArmed(data["WaffenId"]) then
		return _"Erst wegstecken."
	end
	if selected.side == "store" and self:isSingleCarry(selected.name) and inventory:getItemAmount(selected.name) > 0 then
		return _("Du hast bereits eine %s dabei.", selected.name)
	end
	return false
end

function StorageGUI:updateSelection()
	local selected = self.m_Selected
	local reason = self:getBlockReason()
	self.m_ToStore:setEnabled(selected ~= nil and selected.side == "player" and not reason)
	self.m_ToPlayer:setEnabled(selected ~= nil and selected.side == "store" and not reason)
	self.m_All:setEnabled(selected ~= nil)

	if not selected then
		self.m_SelectedImage:setImage("files/images/Other/noImg.png")
		self.m_SelectedName:setText(_"Wähle ein Item aus")
		self.m_SelectedInfo:setText(_"Verschiebe es mit den Pfeilen.")
		return
	end

	local inventory = Inventory:getSingleton()
	local row = {["Objekt"] = selected.name, ["Value"] = selected.value, ["Menge"] = selected.amount, ["WeaponIcon"] = selected.weaponIcon}
	self.m_SelectedImage:setImage(inventory:getItemIcon(row))
	self.m_SelectedName:setText(inventory:getDisplayName(row))
	local data = inventory:getItemData()[selected.name]
	local info = _("%.2f kg je Stück · Dabei: %d", data["Gewicht"], inventory:getItemAmount(selected.name))
	if data["MaxWear"] and selected.wear then
		info = info.." · ".._("Verschleiß: %d / %d", selected.wear, data["MaxWear"])
	end
	self.m_SelectedInfo:setText(reason or info)
end

function StorageGUI:move(direction)
	local selected = self.m_Selected
	if not selected then return end
	local amount = math.floor(tonumber(self.m_Amount:getText()) or 0)
	if amount <= 0 or amount > selected.amount then
		ErrorBox:new(_"Ungültige Menge!")
		return
	end
	triggerServerEvent("itemStorageMove", localPlayer, self.m_Key, direction, selected.name, amount, selected.value, selected.wear)
end

addEventHandler("itemStorageOpen", root, function(key, title, head, rule, element)
	if StorageGUI:isInstantiated() then
		delete(StorageGUI:getSingleton())
	end
	StorageGUI:new(key, title, head, rule, element)
end)

addEventHandler("itemStorageSync", root, function(key, rows, weight, capacity, accepted, options)
	if StorageGUI:isInstantiated() and StorageGUI:getSingleton().m_Key == key then
		StorageGUI:getSingleton():refresh(rows, weight, capacity, accepted, options)
	end
end)
