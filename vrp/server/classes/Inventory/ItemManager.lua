-- ****************************************************************************
-- *
-- *  PROJECT:     vRoleplay
-- *  FILE:        server/classes/Item/ItemManager.lua
-- *  PURPOSE:     Item manager class
-- *
-- ****************************************************************************
ItemManager = inherit(Singleton)
ItemManager.Map = {}

function ItemManager:constructor()
	addRemoteEvents{"onClientBreakItem"}
	self.m_ClassItems = {}

	for name, data in pairs(InventoryManager:getSingleton().m_ItemData) do
		local class = (data["Klasse"] and _G[data["Klasse"]]) or (data["Effekte"] and ItemFood)
		if class then
			local instance = class:new()
			instance:setName(name)
			instance:loadItem()
			instance.m_Breakable = data["Zerbrechlich"] == 1
			data["HatAlternativ"] = instance:hasSecondaryUse(name)
			self.m_ClassItems[name] = class
			ItemManager.Map[name] = instance
		elseif data["Klasse"] then
			outputServerLog(("[INV] Unbekannte Item-Klasse '%s' bei Item '%s'"):format(data["Klasse"], name))
		end
	end

	addEventHandler("onClientBreakItem",root, bind(self.Event_onItemBreak,self))
end

function ItemManager:updateOnQuit()

end

function ItemManager:Event_onItemBreak()
	if source and isElement(source) then
		if source.m_Super and source.m_Super.m_Breakable then
			delete(source.m_Super)
		end
	end
end

function ItemManager:getClassItems()
	return self.m_ClassItems
end

function ItemManager:getInstance(itemName)
	return ItemManager.Map[itemName]
end
