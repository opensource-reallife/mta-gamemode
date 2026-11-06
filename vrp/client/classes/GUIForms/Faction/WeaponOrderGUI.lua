WeaponOrderGUI = inherit(GUIForm)

local SCALE, WIDTH, HEIGHT, LIST_WIDTH, CART_X, CART_WIDTH

local function s(value)
	return math.floor(value * SCALE)
end

function WeaponOrderGUI:constructor(title, submitText)
	SCALE = Inventory.getScale()
	WIDTH, HEIGHT = s(980), s(560)
	LIST_WIDTH, CART_X, CART_WIDTH = s(610), s(630), s(340)

	GUIForm.constructor(self, screenWidth/2 - WIDTH/2, screenHeight/2 - HEIGHT/2, WIDTH, HEIGHT)
	self.m_Window = GUIWindow:new(0, 0, WIDTH, HEIGHT, title, true, true, self)
	Inventory.scaleTitleBar(self.m_Window, SCALE)
	self.m_Window:deleteOnClose(true)

	self.m_Products = {}
	self.m_ProductByKey = {}
	self.m_Cart = {}

	self.m_CostBar = GUIProgressBar:new(s(10), s(40), WIDTH-s(20), s(28), self.m_Window)
	self.m_CostBar:setFontSize(1):setFont(VRPFont(s(26))):setColor(Color.White)

	self.m_HideFull = GUICheckbox:new(s(10), s(74), LIST_WIDTH, s(20), _"Volle Waffen & Munition verbergen", self.m_Window):setFont(VRPFont(s(22))):setFontSize(1)
	self.m_HideFull:setChecked(core:get("Inventory", "HideFullWeapons", false) == true)
	self.m_HideFull.onChange = function(state)
		core:set("Inventory", "HideFullWeapons", state)
		self:refresh()
	end

	self.m_ProductGrid = GUIGridList:new(s(10), s(100), LIST_WIDTH, HEIGHT-s(170), self.m_Window, nil, nil, s(30))
	self.m_ProductGrid:addColumn("", s(34) / LIST_WIDTH)
	self.m_ProductGrid:addColumn(_"Ware", 1 - s(34) / LIST_WIDTH - 0.17 - 0.18 - 0.1 - 20 / LIST_WIDTH)
	self.m_ProductGrid:addColumn(_"Lager", 0.17)
	self.m_ProductGrid:addColumn(_"Preis", 0.18)
	self.m_ProductGrid:addColumn(_"Korb", 0.1)
	self.m_ProductGrid:setFont(VRPFont(s(24)))

	self.m_CartGrid = GUIGridList:new(CART_X, s(100), CART_WIDTH, HEIGHT-s(170), self.m_Window, nil, nil, s(30))
	self.m_CartGrid:addColumn(_"Warenkorb", 0.55)
	self.m_CartGrid:addColumn(_"Anz.", 0.17)
	self.m_CartGrid:addColumn(_"Preis", 0.24)
	self.m_CartGrid:setFont(VRPFont(s(24)))

	self.m_SelectedImage = GUIImage:new(s(14), HEIGHT-s(62), s(44), s(44), "files/images/Other/noImg.png", self.m_Window)
	self.m_SelectedName = GUILabel:new(s(66), HEIGHT-s(62), s(260), s(24), _"Wähle eine Ware aus", self.m_Window):setFont(VRPFont(s(24))):setFontSize(1)
	self.m_SelectedInfo = GUILabel:new(s(66), HEIGHT-s(38), s(260), s(20), "", self.m_Window):setFont(VRPFont(s(20))):setFontSize(1)

	self.m_Amount = GUIEdit:new(s(330), HEIGHT-s(56), s(70), s(32), self.m_Window):setNumeric(true, true)
	self.m_AddButton = GUIButton:new(s(405), HEIGHT-s(56), s(120), s(32), _"Hinzufügen", self.m_Window):setFont(VRPFont(s(24))):setFontSize(1)
	self.m_AddButton.onLeftClick = function() self:addSelected(false) end
	self.m_MaxButton = GUIButton:new(s(530), HEIGHT-s(56), s(90), s(32), _"Maximal", self.m_Window):setFont(VRPFont(s(24))):setFontSize(1):setBackgroundColor(Color.PrimaryNoClick)
	self.m_MaxButton.onLeftClick = function() self:addSelected(true) end

	self.m_RemoveButton = GUIButton:new(CART_X, HEIGHT-s(56), CART_WIDTH/2-s(3), s(32), _"Entfernen", self.m_Window):setFont(VRPFont(s(24))):setFontSize(1):setBackgroundColor(Color.Red)
	self.m_RemoveButton.onLeftClick = bind(self.removeSelected, self)
	self.m_SubmitButton = GUIButton:new(CART_X+CART_WIDTH/2+s(3), HEIGHT-s(56), CART_WIDTH/2-s(3), s(32), submitText, self.m_Window):setFont(VRPFont(s(24))):setFontSize(1):setBackgroundColor(Color.Green)
	self.m_SubmitButton.onLeftClick = function()
		self:submit()
		delete(self)
	end

	self:refresh()
end

function WeaponOrderGUI:addProduct(product)
	product.key = ("%s:%s"):format(product.kind, tostring(product.id))
	self.m_Products[#self.m_Products + 1] = product
	self.m_ProductByKey[product.key] = product
	self.m_Cart[product.key] = 0
end

function WeaponOrderGUI:getBudget()
	return false
end

function WeaponOrderGUI:getProductCost(product, amount)
	return math.ceil(product.price * amount)
end

function WeaponOrderGUI:getTotalCost()
	local total = 0
	for key, amount in pairs(self.m_Cart) do
		if amount > 0 then
			total = total + self:getProductCost(self.m_ProductByKey[key], amount)
		end
	end
	return total
end

function WeaponOrderGUI:getMaxAddable(product)
	if product.limit < 0 then return 0 end
	local free = product.limit - product.stock - self.m_Cart[product.key]
	local budget = self:getBudget()
	if budget and product.price > 0 then
		free = math.min(free, math.floor((budget - self:getTotalCost()) / product.price))
	end
	return math.max(0, free)
end

function WeaponOrderGUI:isFull(product)
	return product.limit >= 0 and product.stock + self.m_Cart[product.key] >= product.limit
end

function WeaponOrderGUI:onAdded(product, amount)
	return amount
end

function WeaponOrderGUI:onRemoved(product, amount)
end

function WeaponOrderGUI:submit()
end

function WeaponOrderGUI:formatPrice(product)
	if product.price < 1 then
		return ("%.2f$"):format(product.price)
	end
	return toMoneyString(math.ceil(product.price))
end

function WeaponOrderGUI:formatStock(product)
	if product.limit < 0 then return tostring(product.stock) end
	return ("%d/%d"):format(product.stock, product.limit)
end

function WeaponOrderGUI:addSelected(useMaximum)
	local product = self.m_SelectedKey and self.m_ProductByKey[self.m_SelectedKey]
	if not product then return end

	local maximum = self:getMaxAddable(product)
	local amount = useMaximum and maximum or math.min(math.floor(tonumber(self.m_Amount:getText()) or 0), maximum)
	if amount <= 0 then
		ErrorBox:new(_"Davon kannst du nichts mehr hinzufügen!")
		return
	end

	local added = self:onAdded(product, amount)
	self.m_Cart[product.key] = self.m_Cart[product.key] + added
	if added < amount then
		ErrorBox:new(_"Es passt nicht alles in die Kisten!")
	end
	self:refresh()
end

function WeaponOrderGUI:removeSelected()
	local key = self.m_SelectedCartKey
	if not key or not self.m_Cart[key] or self.m_Cart[key] <= 0 then return end
	self:onRemoved(self.m_ProductByKey[key], self.m_Cart[key])
	self.m_Cart[key] = 0
	self.m_SelectedCartKey = nil
	self:refresh()
end

function WeaponOrderGUI:selectProduct(product)
	self.m_SelectedKey = product.key
	self.m_Amount:setText(tostring(product.step or 1))
	self:updateSelection()
end

function WeaponOrderGUI:updateSelection()
	local product = self.m_SelectedKey and self.m_ProductByKey[self.m_SelectedKey]
	self.m_AddButton:setEnabled(product ~= nil and product ~= false and self:getMaxAddable(product) > 0)
	self.m_MaxButton:setEnabled(product ~= nil and product ~= false and self:getMaxAddable(product) > 0)
	if not product then
		self.m_SelectedImage:setImage("files/images/Other/noImg.png")
		self.m_SelectedName:setText(_"Wähle eine Ware aus")
		self.m_SelectedInfo:setText("")
		return
	end

	self.m_SelectedImage:setImage(product.icon or "files/images/Other/noImg.png")
	self.m_SelectedName:setText(Inventory.fitText(product.name, s(260), s(24)))
	self.m_SelectedInfo:setText(_("Noch möglich: %d", self:getMaxAddable(product)))
end

function WeaponOrderGUI:refresh()
	self.m_ProductGrid:clear()
	local groups, order = {}, {}
	for _index, product in ipairs(self.m_Products) do
		if self.m_HideFull:isChecked() and self:isFull(product) then
			if product.key == self.m_SelectedKey then
				self.m_SelectedKey = nil
			end
		else
			if not groups[product.group] then
				groups[product.group] = {}
				order[#order + 1] = product.group
			end
			table.insert(groups[product.group], product)
		end
	end

	local nameWidth = self.m_ProductGrid:getColumnWidth(2) * LIST_WIDTH - s(8)
	for _index, groupName in ipairs(order) do
		self.m_ProductGrid:addItemNoClick(_(groupName), "", "", "", ""):setFont(VRPFont(s(24)))
		for _productIndex, product in ipairs(groups[groupName]) do
			local cartAmount = self.m_Cart[product.key]
			local item = self.m_ProductGrid:addItem(product.icon or "files/images/Other/noImg.png", Inventory.fitText(product.name, nameWidth, s(24)), self:formatStock(product), self:formatPrice(product), cartAmount > 0 and cartAmount or "")
			item:setColumnToImage(1, true, s(30))
			item:setFont(VRPFont(s(24)))
			if self:isFull(product) then
				item:setClickable(false)
				item:setColor(Color.LightGrey)
				if product.key == self.m_SelectedKey then
					self.m_SelectedKey = nil
				end
			else
				item.onLeftClick = function() self:selectProduct(product) end
				if product.key == self.m_SelectedKey then
					self.m_ProductGrid:onInternalSelectItem(item)
				end
			end
		end
	end

	self.m_CartGrid:clear()
	local cartWidth = CART_WIDTH * 0.55 - s(8)
	for _index, product in ipairs(self.m_Products) do
		local amount = self.m_Cart[product.key]
		if amount > 0 then
			local item = self.m_CartGrid:addItem(Inventory.fitText(product.name, cartWidth, s(24)), amount, toMoneyString(self:getProductCost(product, amount)))
			item:setFont(VRPFont(s(24)))
			item.onLeftClick = function()
				self.m_SelectedCartKey = product.key
				self.m_RemoveButton:setEnabled(true)
			end
			if product.key == self.m_SelectedCartKey then
				self.m_CartGrid:onInternalSelectItem(item)
			end
		end
	end

	local total = self:getTotalCost()
	local budget = self:getBudget()
	if budget then
		self.m_CostBar:setText(_("Gesamtkosten: %s / %s", toMoneyString(total), toMoneyString(budget)))
		self.m_CostBar:setProgress(math.min(100, total / budget * 100))
	else
		self.m_CostBar:setText(_("Gesamtkosten: %s", toMoneyString(total)))
		self.m_CostBar:setProgress(total > 0 and 100 or 0)
	end
	self.m_SubmitButton:setEnabled(total > 0)
	self.m_RemoveButton:setEnabled(self.m_SelectedCartKey ~= nil and self.m_Cart[self.m_SelectedCartKey] and self.m_Cart[self.m_SelectedCartKey] > 0)
	self:updateSelection()
end

function WeaponOrderGUI:onShow()
	AntiClickSpam:getSingleton():setEnabled(false)
end

function WeaponOrderGUI:onHide()
	AntiClickSpam:getSingleton():setEnabled(true)
end
