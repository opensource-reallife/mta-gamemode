-- ****************************************************************************
-- *
-- *  PROJECT:     vRoleplay
-- *  FILE:        client/classes/GUIForms/GroupPropertyBuy.lua
-- *  PURPOSE:     Group creation GUI class
-- *
-- ****************************************************************************
GroupPropertyBuy = inherit(GUIForm)
inherit(Singleton, GroupPropertyBuy)
addRemoteEvents{"GetImmoForSale","ForceClose" }

function GroupPropertyBuy:constructor()
	GUIWindow.updateGrid()			-- initialise the grid function to use a window
		self.m_Width = grid("x", 27) 	-- width of the window
		self.m_Height = grid("y", 20) 	-- height of the window
	
		GUIForm.constructor(self, screenWidth/2-self.m_Width/2, screenHeight/2-self.m_Height/2, self.m_Width, self.m_Height, true, false, Vector3(2763.01, -2374.46, 819.24))
		self.m_Window = GUIWindow:new(0, 0, self.m_Width, self.m_Height, _"Erwerbliche Immobilien", true, true, self)
		
		self.m_ImmoGrid = GUIGridGridList:new(1, 1, 26, 17, self.m_Window)
		self.m_ImmoGrid:addColumn(_"Id", 0.05)
		self.m_ImmoGrid:addColumn(_"Name", 0.25)
		self.m_ImmoGrid:addColumn(_"Grundpreis", 0.1)
		self.m_ImmoGrid:addColumn(_"Verkaufspreis", 0.15)
		self.m_ImmoGrid:addColumn(_"Ort", 0.20)
		self.m_ImmoGrid:addColumn(_"Besitzer", 0.25)
		self.m_ImmoGrid:setSortable{"Id", "Name", "Grundpreis", "Verkaufspreis", "Ort", "Besitzer"}

		self.m_BuyButton = GUIGridButton:new(1, 19, 26, 1, _"Kaufen", self.m_Window):setBackgroundColor(Color.Green)
		self.m_BuyButton.onLeftClick = bind(self.BuyButton_Click, self)
		
		self.m_LocateButton = GUIGridButton:new(1, 18, 13, 1, _"Position von Immobilie anzeigen", self.m_Window):setBackgroundColor(Color.Accent)
		self.m_LocateButton.onLeftClick = bind(self.LocateButton_Click, self)
		
		self.m_PreviewButton = GUIGridButton:new(14, 18, 13, 1, _"Anschauen", self.m_Window):setBackgroundColor(Color.Orange)
		self.m_PreviewButton.onLeftClick = bind(self.PreviewButton_Click, self)
		
		triggerServerEvent("RequestImmoInfos",localPlayer)

		self.m_GetImmoFunc = bind( GroupPropertyBuy.updateList, self)
		addEventHandler("GetImmoForSale", localPlayer, self.m_GetImmoFunc)
		
		self.m_ForceCloseFunc = bind( GroupPropertyBuy.forceClose, self)
		addEventHandler("ForceClose", localPlayer, self.m_ForceCloseFunc)

		self.m_StartPos = {getElementPosition(localPlayer)}
end

function GroupPropertyBuy:virtual_destructor()
	removeEventHandler("GetImmoForSale", localPlayer, self.m_GetImmoFunc)
	removeEventHandler("ForceClose", localPlayer, self.m_ForceCloseFunc)
	setElementInterior(localPlayer, 5)
	setElementDimension( localPlayer, 0)
	setElementPosition( localPlayer, self.m_StartPos[1],self.m_StartPos[2],self.m_StartPos[3])
	setCameraInterior(5)
	setCameraTarget(localPlayer)
	setTimer(setElementFrozen, 3000,1,localPlayer,false)
end

function GroupPropertyBuy:forceClose()
	delete( GroupPropertyBuy:getSingleton())
end

function GroupPropertyBuy:BuyButton_Click()
	local selected = self.m_ImmoGrid:getSelectedItem()
	QuestionBox:new(_("Bist du dir sicher, dass du die Immobilie für %s kaufen möchtest", toMoneyString(selected.salePrice + selected.price)),
	function()
		if selected then
			if self.m_ImmoTable then
				triggerServerEvent("GroupPropertyBuy",localPlayer, selected.Id)
			end
		else
			ErrorBox:new(_"Du hast keine Immobilie ausgewählt!")
		end
	end,
	function() end, localPlayer, 5)
end

function GroupPropertyBuy:PreviewButton_Click()
	if self.m_ImmoGrid then
		local selected = self.m_ImmoGrid:getSelectedItem()
		if self.m_ImmoTable then
			setElementFrozen(localPlayer,true)
			local matrix = self.m_ImmoTable[selected.Id].camMatrix
			local interior = self.m_ImmoTable[selected.Id].interior
			local dimension = self.m_ImmoTable[selected.Id].dimension
			self:setVisible(false)
			setTimer(function() self:setVisible(true) end, 7500, 1)
			setElementInterior(localPlayer, 0)
			setElementDimension(localPlayer, 0)
			setCameraInterior(0)
			setCameraMatrix(matrix[1], matrix[2], matrix[3],matrix[4], matrix[5], matrix[6])
		end
	end
end

function GroupPropertyBuy:LocateButton_Click()
	if self.m_ImmoGrid:getSelectedItem() then
		local item = self.m_ImmoGrid:getSelectedItem()
		if item.position then
			local blipPos = Vector2(item.position.x, item.position.y)
			ShortMessage:new("Klicke um die Immobilie auf der Karte zu markieren.\n(Beachte, dass du nicht in einem Interior sein darfst)", "Immobilie", false, -1, function()
				GPS:getSingleton():startNavigationTo(item.Position)
			end, false, blipPos, {{path = "Marker.png", pos = blipPos}})
		else
			ErrorBox:new(_"Fehler: Haus hat keine Position")
		end
	else
		WarningBox:new(_"Kein Haus ausgewählt!")
	end
end

function GroupPropertyBuy:updateList( _table )
	self.m_ImmoTable = _table
	if _table then
		self.m_ImmoGrid:clear()
		for id, obj in pairs( _table ) do
			local price = obj.price
			local pos = normaliseVector(obj.pos)
			local zoneName = getZoneName(pos)
			
			local ownerName = "- Keiner -"
			if obj.owner then
				ownerName = obj.owner
			end

			local salePrice = "-"
			if obj.salePrice[1] then
				salePrice = obj.salePrice[2]
			end

			local item = self.m_ImmoGrid:addItem(obj.id, obj.name, price, salePrice, zoneName, ownerName)
			
			item:setColor((obj.salePrice[1] and Color.Orange) or (obj.owner and Color.Red) or Color.Green)
			item.hasCamMatrix = obj.camMatrix and true or false
			item.position = pos
			item.Id = id
			item.salePrice = obj.salePrice[2]
			item.price = obj.price
			item.onLeftDoubleClick = function ()  end
			item.onLeftClick = function()
				self.m_PreviewButton:setEnabled(item.hasCamMatrix)
			end
		end
	end
end
