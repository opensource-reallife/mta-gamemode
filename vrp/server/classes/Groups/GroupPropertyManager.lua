GroupPropertyManager = inherit(Singleton)
local PICKUP_ARROW = 1318
local PICKUP_FOR_SALE = 1272
addRemoteEvents{"GroupPropertyClientInput", "GroupPropertyBuy", "GroupPropertySell", "RequestImmoInfos","KeyChangeAction","requestRefresh","switchGroupDoorState","requestImmoPanel","updatePropertyText","requestImmoPanelClose","requestPropertyItemDepot", "GroupPropertySetForSale"}
function GroupPropertyManager:constructor( )
	local st, count = getTickCount(), 0
	self.Map = {}
	self.ChangeMap = {}
	self.m_BankAccountServer = BankServer.get("group.properties")
	local result = sql:queryFetch("SELECT * FROM ??_group_property", sql:getPrefix())
	for k, row in ipairs(result) do
		self.Map[row.Id] = GroupProperty:new(row.Id, row.Name, row.GroupId, row.Type, row.Price, Vector3(unpack(split(row.Pickup, ","))), row.InteriorId,  Vector3(unpack(split(row.InteriorSpawn, ","))), row.Cam, row.open, row.Message, row.DepotId, row.ElevatorData, row.SalePrice)
		count = count + 1
	end

	addEventHandler("GroupPropertyClientInput", root, function()
		if client.m_LastPropertyPickup then
			if not client.m_LastGroupPropertyInside then
				local px, py, pz = getElementPosition(client)
				local mx, my, mz = getElementPosition(client.m_LastPropertyPickup.m_Pickup)
				if getDistanceBetweenPoints3D(px, py, pz, mx, my, mz) < 3 then
					client.m_LastPropertyPickup:openForPlayer(client)
				end
			else
				local px, py, pz = getElementPosition(client)
				local mx, my, mz = getElementPosition(client.m_LastPropertyPickup.m_ExitMarker)
				if getDistanceBetweenPoints3D(px, py, pz, mx, my, mz) < 3 then
					client.m_LastPropertyPickup:closeForPlayer(client)
				end
			end
		end
	end)

	addEventHandler("GroupPropertyBuy", root, bind( GroupPropertyManager.checkPropertyBuy, self))
	addEventHandler("GroupPropertySell", root, bind( GroupPropertyManager.SellProperty, self))
	addEventHandler("GroupPropertySetForSale", root, bind( GroupPropertyManager.setPropertyForSale, self))
	addEventHandler("RequestImmoInfos", root, bind( GroupPropertyManager.OnRequestImmoInfos, self))
	addEventHandler("requestImmoPanel", root, bind( GroupPropertyManager.OnRequestImmoPanel, self))
	addEventHandler("requestImmoPanelClose", root, bind( GroupPropertyManager.OnRequestImmoPanelClose, self))
	addEventHandler("switchGroupDoorState", root, bind( GroupPropertyManager.OnDrooStateSwitch, self))
	addEventHandler("KeyChangeAction", root, bind( GroupPropertyManager.OnKeyChange, self))
	addEventHandler("requestRefresh", root, bind( GroupPropertyManager.OnRefreshRequest, self))
	addEventHandler("updatePropertyText",root,bind(GroupPropertyManager.OnMessageTextChange,self))
	addEventHandler("requestPropertyItemDepot",root,bind(GroupPropertyManager.OnRequestPropertyItemDepot,self))
	if DEBUG_LOAD_SAVE then outputServerLog(("Created %s group-properties in %sms"):format(count, getTickCount()-st)) end
end

function GroupPropertyManager:OnMessageTextChange( text )
	if text then
		if client then
			if client.m_LastPropertyPickup then
				client.m_LastPropertyPickup.m_Message = text
				client:sendInfo(_"Die Eingangsnachricht wurde aktualisiert!")
			end
		end
	end
end

function GroupPropertyManager:OnRequestPropertyItemDepot(id)
	if client then
		if client.m_LastPropertyPickup then
			if PermissionsManager:getSingleton():hasPlayerPermissionsTo(client, "group", "manageImmoDepot") then
				client.m_LastPropertyPickup:getDepot():showItemDepot(client, client.m_LastPropertyPickup)
			else
				return client:sendError(_("Du bist nicht berechtigt das Depot zu verwalten"))
			end
		end
	end
end

function GroupPropertyManager:OnRequestImmoPanel( id )
	if client then
		if GroupPropertyManager:getSingleton().Map[id] then
			GroupPropertyManager:getSingleton().Map[id]:Event_requestImmoPanel( client )
			client.m_LastPropertyPickup = GroupPropertyManager:getSingleton().Map[id]
		end
	end
end

function GroupPropertyManager:OnRequestImmoPanelClose( id )
	if client then
		if GroupPropertyManager:getSingleton().Map[id] then
			client:triggerEvent("forceGroupPropertyClose")
		end
	end
end

function GroupPropertyManager:addNewProperty( )
	sql:queryExec("INSERT INTO ??_group_property (UserId, Type, Weapons, Costs, Position, Date) VALUES(?, ?, ?, ?, ?, NOW())",
        sql:getPrefix(), userId, type, weapons, costs, self:getZone(player))
end

function GroupPropertyManager:OnRequestImmoInfos()
	local tempTable = {}
	for index, property in pairs(GroupPropertyManager:getSingleton().Map) do
		local ownerName = false
		if property:hasOwner() then
			ownerName = property:getOwner():getName()
		end
		tempTable[index] = {
			id = property.m_Id,
			name = property.m_Name,
			price = property.m_Price,
			salePrice = {property.m_ForSale, property.m_SalePrice},
			pos = serialiseVector(property.m_Position),
			--owner = property.m_OwnerID,
			owner = ownerName,
			camMatrix = property.m_CamMatrix,
			interior = property.m_Interior,
			dimension = property.m_Dimension
		}
	end
	client:triggerEvent("GetImmoForSale", tempTable)
end

function GroupPropertyManager:OnKeyChange( player,action)
	if client then
		if client.m_LastPropertyPickup then
			client.m_LastPropertyPickup:Event_keyChange( player, action, client )
		end
	end
end

function GroupPropertyManager:OnRefreshRequest()
	if client then
		if client.m_LastPropertyPickup then
			client.m_LastPropertyPickup:Event_RefreshPlayer( client )
		end
	end
end

function GroupPropertyManager:OnDrooStateSwitch( )
	if client then
		if client.m_LastPropertyPickup then
			client.m_LastPropertyPickup:Event_ChangeDoor( client )
		end
	end
end

function GroupPropertyManager:checkPropertyBuy(id)
	if not PermissionsManager:getSingleton():hasPlayerPermissionsTo(client, "group", "buyProperty") then
		client:sendError(_("Du bist nicht berechtigt eine Immobilie für deine Gruppe zu kaufen!", client))
		return
	end

	local prop = self.Map[id]
	if prop:isForSale() and prop:getSalePrice() > 0 then
		self:buyPropertyFromGroup(id, client)
	else
		self:BuyProperty(id, client)
	end
end

function GroupPropertyManager:BuyProperty( Id, player )
	if not client then player = client end
	if not player or not client then return end
	if not client:getGroup() then
		client:sendError(_("Du bist in keiner Gruppe oder Gang!", client))
		return
	end
	if not PermissionsManager:getSingleton():hasPlayerPermissionsTo(client, "group", "buyProperty") then
		client:sendError(_("Du bist nicht berechtigt eine Immobilie für deine Gruppe zu kaufen!", client))
		return
	end

	local newOwner = client:getGroup()
	local property = GroupPropertyManager:getSingleton().Map[Id]
	local propCount = self:getPropsForPlayer( client )
	if #propCount > 0 then
		return 	client:sendError(_("Deine Gruppe besitzt bereits eine Immobilie", client))
	end
	if property then
		local price = property.m_Price
		if price <= newOwner:getMoney() then
			local oldOwner = property.m_Owner
			if not oldOwner then
				property.m_Owner = newOwner or false
				property.m_OwnerID = newOwner.m_Id or false
				sql:queryExec("UPDATE ??_group_property SET GroupId=? WHERE Id=?", sql:getPrefix(), newOwner.m_Id, property.m_Id)
				property.m_Open = 1
				newOwner:transferMoney(self.m_BankAccountServer, price, "Immobilie "..property.m_Name.." gekauft!", "Group", "PropertyBuy")
				newOwner:addLog(client, "Immobilien", _("hat die Immobilie '%s' für %d$ gekauft!", client, property.m_Name, property.m_Price))
				client:sendInfo("Du hast die Immobilie gekauft!")
				if property.m_Pickup and isElement(property.m_Pickup) then
					setPickupType(property.m_Pickup, 3, PICKUP_ARROW)
				end
				client:triggerEvent("ForceClose")
				for key, player in ipairs( newOwner:getOnlinePlayers() ) do
					player:triggerEvent("addPickupToGroupStream",property.m_ExitMarker, property.m_Id)
					local x,y,z = getElementPosition( property.m_Pickup )
					player:triggerEvent("createGroupBlip",x,y,z,property.m_Id,newOwner.m_Type)
				end
				StatisticsLogger:GroupBuyImmoLog( property.m_OwnerID or 0, "BUY", property.m_Id)
				property:setForSale(false)
			else
				if property:isForSale() then
					self:sellPropertyToGroup(Id)
				else
					client:sendError(_("Diese Immobilie ist bereits vergeben!", client))
				end
			end
		else
			client:sendError(_("In deiner Gruppen-Kasse befindet sich nicht genug Geld!", client))
		end
	else
		client:sendError(_("Immobilie nicht gefunden!", client))
		outputDebugString("GroupPropertyManager:BuyProperty: Immobile ID "..Id.." not found!")
	end
end

function GroupPropertyManager:SellProperty(  )
	if client then
		if not client:getGroup() then
			client:sendError(_("Du bist in keiner Gruppe oder Gang!", client))
			return
		end
		if not PermissionsManager:getSingleton():hasPlayerPermissionsTo(client, "group", "sellProperty") then
			client:sendError(_("Du bist nicht berechtigt diese Immobilie zu verkaufen!", client))
			return
		end

		local property = client.m_LastPropertyPickup
		if property then
			local price = property.m_Price
			local sellMoney = math.floor(price * 0.75)
			local pOwner = property.m_Owner
			local group = client:getGroup()
			if pOwner == group then
				property.m_Owner = false
				property.m_OwnerID = 0
				sql:queryExec("UPDATE ??_group_property SET GroupId=? WHERE Id=?", sql:getPrefix(), 0, property.m_Id)
				property.m_Open = 1
				if property.m_Pickup and isElement(property.m_Pickup) then
					setPickupType(property.m_Pickup, 3, PICKUP_FOR_SALE)
				end
				self.m_BankAccountServer:transferMoney(group, sellMoney, "Immobilie "..property.m_Name.." verkauft!", "Group", "PropertySell")
				group:addLog(client, "Immobilien", _("hat die Immobilie '%s' verkauft!", client, property.m_Name))
				client:sendInfo("Sie haben die Immobilie verkauft! Das Geld befindet sich in der Gruppenkasse!")
				for key, player in ipairs( pOwner:getOnlinePlayers() ) do
					player:triggerEvent("destroyGroupBlip",property.m_Id)
					player:triggerEvent("forceGroupPropertyClose")
				end
				property:setForSale(false)
				StatisticsLogger:GroupBuyImmoLog( pOwner.m_Id or 0, "SELL", property.m_Id or 0)
			end
		end
	end
end

function GroupPropertyManager:destructor()
	for id, obj in pairs( self.Map ) do
		obj:delete()
	end
end

function GroupPropertyManager:getPropsForPlayer( player )
	local playerProps = {}
	if player then
		if player:getGroup() then
			for k,v in pairs(GroupPropertyManager:getSingleton().Map) do
				if v.m_OwnerID == player:getGroup():getId() then
					playerProps[#playerProps+1] = v
				end
			end
		end
	end
	return playerProps
end

function GroupPropertyManager:takePropsFromGroup(group) --in case the group gets deleted with active props
	for k,v in pairs(GroupPropertyManager:getSingleton().Map) do
		if v.m_OwnerID == group.m_Id then
			local property = v
			v.m_Owner = false
			v.m_OwnerID = 0
			sql:queryExec("UPDATE ??_group_property SET GroupId=? WHERE Id=?", sql:getPrefix(), 0, v.m_Id)
			v.m_Open = 1
			if v.m_Pickup and isElement(v.m_Pickup) then
				setPickupType(v.m_Pickup, 3, PICKUP_FOR_SALE)
			end
			StatisticsLogger:GroupBuyImmoLog( group.m_Id or 0, "GROUP_DELETED", property.m_Id or 0)
		end
	end
end

function GroupPropertyManager:clearProperty(id, groupId, price, inactivityClear)
	local property = self.Map[id]			
	property.m_Owner = false
	property.m_OwnerID = 0
	sql:queryExec("UPDATE ??_group_property SET GroupId=? WHERE Id=?", sql:getPrefix(), 0, property.m_Id)
	property.m_Open = 1
	
	for key, player in ipairs( GroupManager.Map[tonumber(groupId)]:getOnlinePlayers() ) do
		player:triggerEvent("destroyGroupBlip",property.m_Id)
		player:triggerEvent("forceGroupPropertyClose")
	end
	if property.m_Pickup and isElement(property.m_Pickup) then
		setPickupType(property.m_Pickup, 3, 1273)
	end
	if GroupManager.Map[groupId] and inactivityClear then
		self.m_BankAccountServer:transferMoney(GroupManager.Map[groupId].m_BankAccount, math.floor(price * 0.75), "Inactivity", "Group", "PropertyClear")
		sqlLogs:queryExec("INSERT INTO ??_propertiesfreed (GroupId, PropertyID, Date) VALUES (?, ?, Now())", sqlLogs:getPrefix(), groupId, id)
	end
end

function GroupPropertyManager:buyPropertyFromGroup(Id, player)
	local property = self.Map[Id]
	if not client then client = player end
	if not player or not client then return end
	if not client:getGroup() then return client:sendError(_("Du bist in keiner Gruppe", client)) end
	if not PermissionsManager:getSingleton():hasPlayerPermissionsTo(client, "group", "buyProperty") then
		client:sendError(_("Du bist nicht berechtigt eine Immobilie für deine Gruppe zu kaufen!", client))
		return
	end
	if #self:getPropsForPlayer(client) > 0 then
		return client:sendWarning(_("Du hast bereits eine Immobilie!", client))
	end
	if not property.m_Owner or property.m_OwnerID == 0 then
		return client:sendError(_("Die Immobilie hat keinen Besitzer", client)) 
	end

	local price = property:getSalePrice()
	local forSale = property:isForSale()
	local housePrice = property.m_Price
	if price > 0 and forSale then
		if price + housePrice <= property:getOwner():getMoney() then
			property:sellToPlayer(property.m_Owner, client)
		else
			return client:sendError(_("Die Gruppe hat nicht genug Geld. (%s)", client, toMoneyString(housePrice + price)))
		end
	else
		return client:sendError(_("Die Immobilie steht nicht zum Verkauf!", client))
	end
end

function GroupPropertyManager:setPropertyForSale(state, money)
	if client and client:getGroup() then
		local group = client:getGroup()
		local property = client.m_LastPropertyPickup
		if property and property.m_Owner == group then
			if state then		
				if group:transferMoney(self.m_BankAccountServer, GROUP_PROPERTY_SET_FOR_SALE_FEE, "Anzeigengebühr", "Property", "Group") then
					property:setForSale(true, money)
					client:sendSuccess(_("Verkauf gestartet.", client))
					group:sendShortMessage(_("%s hat die Immobilie für %s zum Verkauf gestellt", client, client:getName(), toMoneyString(money)))
				else
					return client:sendError(_("Deine Gruppe hat nicht genug Geld in Kasse.", client))
				end
			else
				property:setForSale(false)
				client:sendSuccess(_("Verkauf beendet.", client))
				group:sendShortMessage(_("%s hat den Verkauf für die Immobilie beendet.", client, client:getName()))
			end
			client:triggerEvent("isPropertyForSale", property:isForSale())
		else
			return client:sendError(_("Deine Gruppe gehört diese Immobilie nicht.", client))
		end
	end
end