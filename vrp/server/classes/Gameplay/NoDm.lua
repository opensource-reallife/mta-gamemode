NoDm = inherit(Singleton)
addRemoteEvents{"requestNoDm"}

function NoDm:constructor()
	self.m_NoDmZones = {}
    addEventHandler("requestNoDm", root, bind(self.Event_requestNoDm, self))
end

function NoDm:addZone(koords, index)
    triggerClientEvent(PlayerManager:getSingleton():getReadyPlayers(), "addNoDm", root, koords, index)
    self.m_NoDmZones[index] = koords
end

function NoDm:removeZone(index)
    triggerClientEvent(PlayerManager:getSingleton():getReadyPlayers(), "removeNoDm", root, index)
    self.m_NoDmZones[index] = nil
end

function NoDm:Event_requestNoDm()
    if source ~= client then return end
    for index, koords in pairs(self.m_NoDmZones) do
        triggerClientEvent(client, "addNoDm", root, koords, index)
    end
end