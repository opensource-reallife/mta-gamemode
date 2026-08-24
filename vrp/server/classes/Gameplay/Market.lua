Market = inherit(Singleton)

function Market:constructor()
	self.m_BankServer = BankServer.get("gameplay.market")
    self.m_Blip = Blip:new("Calendar.png", 1480.60, -1666.62, root, 100)
    self.m_Blip:setDisplayText("Wochenmarkt")
	self.m_MapParser = MapParser:new(":exo_maps/market.map")
	self.m_MapParser:create()
    self.m_Traders = {}
    self.m_Binds = {
        ["onTraderColShapeHit"] = bind(self.Event_onTraderColShapeHit, self),
        ["onTraderClicked"] = bind(self.Event_onTraderClicked, self),
        ["marketSellItem"] = bind(self.Event_marketSellItem, self),
        ["marketSellWeapon"] = bind(self.Event_marketSellWeapon, self)
    }

    self:addTrader(218, Vector3(1480.17, -1705.34, 14.05), 140, "Frida Fraise", "Möchtest du Erdbeeren verkaufen?", "Erdbeeren", Randomizer:get(5, 15), 70)
    self:addTrader(31, Vector3(1480.41, -1710.62, 14.05), 38, "Maria Manzana", "Verkaufst du Äpfel?", "Apfel", Randomizer:get(5, 30), 70)
    self:addTrader(158, Vector3(1480.48, -1684.65, 14.05), 124, "Carlos Carota", "Hast du Karotten? Ich zahle gut!", "Karotte", Randomizer:get(15, 60), 70)
    self:addTrader(264, Vector3(1478.28, -1706.71, 14.05), 205, "Benjamin Blume", "Wenn du Blumen hast, kaufe ich sie dir ab!", 14, Randomizer:get(200, 500), 50)
    self:addTrader(72, Vector3(1478.29, -1689.98, 14.05), 315, "Patrick Pera", "Kaufe Birnen zu fairen Preisen!", "Birne", Randomizer:get(5, 30), 70)
    self:addTrader(205, Vector3(1470.76, -1677.19, 14.05), 246, "Wilma Worstje", "Würstchen sind leider ausverkauft!")

    addRemoteEvents({"marketSellItem", "marketSellWeapon"})
    addEventHandler("marketSellItem", root, self.m_Binds["marketSellItem"])
    addEventHandler("marketSellWeapon", root, self.m_Binds["marketSellWeapon"])
end

function Market:addTrader(model, pos, rotZ, name, text, item, price, spawnChance)
    if spawnChance and not chance(spawnChance) then return end

    local id = #self.m_Traders + 1
    local trader = Ped.create(model, pos, rotZ)
    trader:setData("NPC:Immortal", true, true)
	trader:setData("clickable", true, true)
	trader:setData("Ped:Name", name, true, true)
	trader:setData("Ped:fakeNameTag", name, true, true)
	trader:setFrozen(true)
    self.m_Traders[id] = trader

    trader.m_Id = id
    trader.m_Name = name
    trader.m_Text = text
    trader.m_Item = item
    trader.m_Price = price

    local colShape = createColSphere(trader:getPosition(), 5)
    colShape:attach(trader)
    trader.m_ColShape = colShape

	addEventHandler("onColShapeHit", trader.m_ColShape, self.m_Binds["onTraderColShapeHit"])
    addEventHandler("onElementClicked", trader, self.m_Binds["onTraderClicked"])
end

function Market:Event_onTraderClicked(button, state, player)
	if getDistanceBetweenPoints3D(source.position, player.position) > 10 then return end
	if button == "left" and state == "down" then
        local item, price = source.m_Item, source.m_Price
        if item and price then
            if type(item) == "number" then
                QuestionBox:new(player, _("Möchtest du %s für %s$ verkaufen?", player, _(WEAPON_NAMES[item], player), price), "marketSellWeapon", nil, false, false, source.m_Id)
            else
                player:triggerEvent("inputBox", _("Verkaufen: %s", player, _(item, player)), _("Wie viel möchtest du verkaufen? (%s$ pro Stück)", player, price), "marketSellItem", source.m_Id)
            end
        end
    end
end

function Market:Event_onTraderColShapeHit(hitElement, matchingDimension)
    if not matchingDimension then return end
    if getElementType(hitElement) == "player" then
        local trader = source:getAttachedTo()
        hitElement:sendMessage(("#FE8A00%s: #FFFFFF%s"):format(trader.m_Name, _(trader.m_Text, hitElement)))
    end
end

function Market:Event_marketSellItem(amount, traderId)
    if source ~= client then return end

    local amount = tonumber(amount)
    if not amount then return end
    
    local trader = self.m_Traders[traderId]
    if trader then
        if client:getInventory():removeItem(trader.m_Item, amount) then
            self.m_BankServer:transferMoney(client, trader.m_Price * amount, "Item-Verkauf", "Gameplay", "Item")
        else
            client:sendError(_("Du hast nicht genug davon in deinem Inventar!", client))
        end
    end
end

function Market:Event_marketSellWeapon(traderId)
    local trader = self.m_Traders[traderId]
    if trader then
        if source:takeWeapon(trader.m_Item) then
            self.m_BankServer:transferMoney(source, trader.m_Price, "Verkauf", "Gameplay", "Weapon")
        else
            source:sendError(_("Du hast diesen Gegenstand nicht!", source))
        end
    end
end

function Market:destructor()
    delete(self.m_Blip)
    delete(self.m_MapParser)
    for k, trader in pairs(self.m_Traders) do
        removeEventHandler("onColShapeHit", trader.m_ColShape, self.m_Binds["onTraderColShapeHit"])
        removeEventHandler("onElementClicked", trader, self.m_Binds["onTraderClicked"])
        trader.m_ColShape:destroy()
        trader:destroy()
    end
    removeEventHandler("marketSellItem", root, self.m_Binds["marketSellItem"])
    removeEventHandler("marketSellWeapon", root, self.m_Binds["marketSellWeapon"])
end