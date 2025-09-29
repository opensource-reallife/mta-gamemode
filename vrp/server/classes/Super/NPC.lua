-- ****************************************************************************
-- *
-- *  PROJECT:     vRoleplay
-- *  FILE:        server/classes/Super/NPC.lua
-- *  PURPOSE:     NPC class
-- *
-- ****************************************************************************
NPC = inherit(MTAElement)

function NPC:new(skinId, x, y, z, rotation)
	local ped = createPed(skinId, x, y, z)
	setElementRotation(ped, 0, 0, rotation or 0)
	return enew(ped, self, skinId, x, y, z, rotation or 0)
end

function NPC:constructor(skinId, x, y, z, rotation)

end

function NPC:setImmortal(bool)
	self:setData("NPC:Immortal", bool, true)
end

function NPC:toggleWanteds(state)
	if state == true then
		addEventHandler("onPedWasted", self, bind(self.onWasted, self) )
	else
		removeEventHandler("onPedWasted", self, bind(self.onWasted, self) )
	end
end

function NPC:onWasted(ammo, killer, weapon, bodypart, stealth)
	local wanteds = WANTED_AMOUNT_MURDER_BEGGAR
	killer:giveWanteds(wanteds)
	killer:sendMessage(_("Verbrechen begangen: %s, %d Wanted/s", killer, _("Mord", killer), wanteds), 255, 255, 0)
end
