-- ****************************************************************************
-- *
-- *  PROJECT:     vRoleplay
-- *  FILE:        server/classes/Faction/Action/HeavyWeaponTransportManager.lua
-- *  PURPOSE:     Heavy Weapon Transport Manager class
-- *
-- ****************************************************************************
HeavyWeaponTransportManager = inherit(Singleton)

function HeavyWeaponTransportManager:constructor()
    self.m_Ped = Ped.create(287, -1369.88, 499.71, 18.23)
    self.m_Ped:setData("NPC:Immortal", true, true)
	self.m_Ped:setData("clickable", true, true)
	self.m_Ped:setData("Ped:Name", "Sergeant Okabe", true, true)
	self.m_Ped:setData("Ped:fakeNameTag", "Sergeant Okabe", true, true)
	self.m_Ped:setFrozen(true)
    addEventHandler("onElementClicked", self.m_Ped, bind(self.onPedClick, self))
end

function HeavyWeaponTransportManager:onPedClick(button, state, player)
    local faction = player:getFaction()

	if
		button ~= "left"
		or state ~= "down"
		or not faction
		or not faction:isStateFaction()
        or not player:isFactionDuty()
		or not ActionsCheck:getSingleton():isActionAllowed(player)
	then
		return
	end
	player:triggerEvent("openArmsDealerGUI", source, "state")
end