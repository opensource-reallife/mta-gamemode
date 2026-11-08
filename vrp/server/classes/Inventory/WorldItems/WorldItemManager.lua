-- ****************************************************************************
-- *
-- *  PROJECT:     vRoleplay
-- *  FILE:        server/classes/Inventory/WorldItems/WorldItemManager.lua
-- *  PURPOSE:     This class manages WorldItems
-- *
-- ****************************************************************************
WorldItemManager = inherit(Singleton) 
WorldItemManager.Map = {}

function WorldItemManager:constructor() 
	self.m_CallbackMap = -- functions that are called once a specific world-item is created for an item
	{
		[81] =  ItemManager:getSingleton():getInstance(81).addWorldObjectCallback, 
		[80] =  ItemManager:getSingleton():getInstance(80).addWorldObjectCallback,
		[82] =  ItemManager:getSingleton():getInstance(82).addWorldObjectCallback,
		[123] = ItemManager:getSingleton():getInstance(123).addWorldObjectCallback,
	}
	local result = sql:queryFetch("SELECT * FROM ??_WorldItems", sql:getPrefix())
	local model, item, obj, value, interior, dimension, posX, posY, posZ, owner, id, worldItemInstance
	for k, row in pairs(result) do 
		id, model, item, value, interior, dimension, breakable, owner, locked = row.Id, row.Model, row.Item, row.Value, row.Interior, row.Dimension, row.Breakable, row.Owner, row.Locked
		posX, posY, posZ, rot = row.PosX, row.PosY, row.PosZ, row.Rotation
		worldItemInstance = PlayerWorldItem:new(ItemManager:getSingleton():getInstance(item), owner, Vector3(posX, posY, posZ), rot, breakable, owner, true, locked, row.Model)
		worldItemInstance:setDataBaseId(id)
		worldItemInstance:setValue(value)
		worldItemInstance:setInterior(interior) 
		worldItemInstance:setDimension(dimension)
		if self.m_CallbackMap[InventoryManager:getSingleton():getItemId(item)] then 
			self.m_CallbackMap[InventoryManager:getSingleton():getItemId(item)](ItemManager:getSingleton():getInstance(item), id, worldItemInstance)
		end
	end
end

function WorldItemManager:destructor()
	self:onDestruction()
	local obj, isPermanent, hasChanged, pos, rot, value, dump
	for obj, id in pairs(WorldItemManager.Map) do 
		if not obj.m_Delete then
			if obj and obj:isPermanent() then 
				pos, rot, value = obj:getObject():getPosition(), obj:getObject():getRotation(), obj:getValue()
				if id > 0 then
					if obj:hasChanged() then
						sql:queryExec("UPDATE ??_WorldItems SET PosX=?, PosY=?, PosZ=?, Rotation=?, Value=?, Locked=? WHERE Id=?", sql:getPrefix(), pos.x, pos.y, pos.z, rot.z, obj:getValue(), obj:isLocked(), id)
					end
				else 
					sql:queryExec("INSERT INTO ??_WorldItems (Item, Model, Owner, PosX, posY, posZ, Rotation, Value, Interior, Dimension, Breakable, Locked, Date) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, NOW())", sql:getPrefix(),
					obj:getItem():getName() or "Generic", obj:getModel(), obj:getOwner(), pos.x, pos.y, pos.z, rot.z, obj:getValue(), obj:getInterior(), obj:getDimension(), obj:isBreakable(), obj:isLocked())
				end
			end
		else
			if id > 0 then
				sql:queryExec("DELETE FROM ??_WorldItems WHERE Id=?", sql:getPrefix(), id)
			end
		end
	end
end

function WorldItemManager:onDestruction() 
	if ItemManager.Map[80] then 
		ItemManager.Map[80]:delete() 
	end
	if ItemManager.Map[81] then 
		ItemManager.Map[81]:delete() 
	end
	if ItemManager.Map[82] then 
		ItemManager.Map[82]:delete() 
	end
	if ItemManager.Map[92] then 
		ItemManager.Map[92]:delete() 
	end
end

