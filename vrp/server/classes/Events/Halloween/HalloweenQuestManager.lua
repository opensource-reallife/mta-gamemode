HalloweenQuestManager = inherit(Singleton)

HalloweenQuestManager.ms_QuestRewards = {
	--{pumpkins=2, sweets=5},
	--{pumpkins=5, sweets=15},
	--{pumpkins=2, sweets=10},
	{pumpkins=10, sweets=25},
	--{pumpkins=2, sweets=10},
	--{pumpkins=2, sweets=10},
	--{pumpkins=10, sweets=25},
	--{pumpkins=25, sweets=50},
}

function HalloweenQuestManager:constructor()
	addRemoteEvents{"Halloween:giveGhostCleaner", "Halloween:takeGhostCleaner", "Halloween:requestQuestState", "Halloween:requestQuestUpdate"}

	addEventHandler("Halloween:requestQuestState", root, bind(self.requestQuestState, self))
	addEventHandler("Halloween:requestQuestUpdate", root, bind(self.requestQuestUpdate, self))

	--[[ Ghost Cleaner Questline
	addEventHandler("onPlayerQuit", root, bind(self.onPlayerQuit, self))
	addEventHandler("Halloween:giveGhostCleaner", root, bind(self.Event_giveGhostCleaner, self))
	addEventHandler("Halloween:takeGhostCleaner", root, bind(self.Event_takeGhostCleaner, self))

	self:createQuestMarkers()
	]]
end

function HalloweenQuestManager:Event_giveGhostCleaner()
	giveWeapon(client, 27, 9999, true)
end

function HalloweenQuestManager:Event_takeGhostCleaner()
	takeWeapon(client, 27)
end

function HalloweenQuestManager:onPlayerQuit()
	takeWeapon(source, 27)
end

function HalloweenQuestManager:createQuestMarkers()
	self.m_QuestEnterExits = {
		[1] = {
			InteriorEnterExit:new(Vector3(2751.914, -1962.834, 13.548), Vector3(-42.56, 1405.99, 1084.43), 270, 0, 8, 13, 0, 0)
		},
		[2] = {
			InteriorEnterExit:new(Vector3(1851.825, -2135.402, 15.388), Vector3(-68.89, 1351.71, 1080.21), 0, 180, 6, 13, 0, 0),
			InteriorEnterExit:new(Vector3(986.370, -1624.505, 14.930), Vector3(2365.25, -1135.06, 1050.88), 0, 90, 8, 13, 0, 0),
			InteriorEnterExit:new(Vector3(824.521, -1423.724, 14.496), Vector3(-261.17, 1456.69, 1084.37), 90, 0, 4, 13, 0, 0),
			InteriorEnterExit:new(Vector3(2092.063, -1166.489, 26.586), Vector3(318.55, 1114.98, 1083.88), 0, 90, 5, 13, 0, 0)
		},
		[3] = {
			InteriorEnterExit:new(Vector3(2058.01, -1697.27, 13.55), Vector3(2270.01, -1210.48, 1047.56), 90, 0, 10, 13, 0, 0)
		},
		[4] = {
			InteriorEnterExit:new(Vector3(2539.86, -1303.96, 34.95), Vector3(2542.45, -1304.00, 1025.07), 90, 270, 2, 13, 0, 0)
		},
		[7] = {
			InteriorEnterExit:new(Vector3(1412.666,-1304.790, 8.561), Vector3(1426.313, -1938.632, -38.160), 180, 90, 0, 3, 0, 0)
		}
	}
end

function HalloweenQuestManager:requestQuestState()
	local state = self:getQuestState(client)
	client:triggerEvent("Halloween:sendQuestState", state)
end

function HalloweenQuestManager:getQuestState(player)
	local result = sql:queryFetchSingle("SELECT Quest FROM ??_halloween_quest WHERE UserId = ?", sql:getPrefix(), player:getId())
	return result and result.Quest or 0 
end

function HalloweenQuestManager:requestQuestUpdate(quest)
	self:setQuestState(client, quest)

	client:getInventory():giveItem("Kürbis", HalloweenQuestManager.ms_QuestRewards[quest].pumpkins)
    client:getInventory():giveItem("Suessigkeiten", HalloweenQuestManager.ms_QuestRewards[quest].sweets)

    client:sendSuccess(_("Du hast %s Kürbisse und und %s Süßigkeiten erhalten!", client, HalloweenQuestManager.ms_QuestRewards[quest].pumpkins, HalloweenQuestManager.ms_QuestRewards[quest].sweets))
end

function HalloweenQuestManager:setQuestState(player, quest)
	if quest == 1 then
		sql:queryExec("INSERT INTO ??_halloween_quest (UserId, Quest) VALUES (?, ?)", sql:getPrefix(), player:getId(), 1)
	else
		sql:queryExec("UPDATE ??_halloween_quest SET Quest = ? WHERE UserId = ?", sql:getPrefix(), quest, player:getId())
	end
end