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

-- Steht der Spieler in einer NoDM-Zone? Wie die Colshapes beim Client: Dimension 0, passendes Interior, innerhalb des Quaders
function NoDm:isPlayerInZone(player)
	if not isElement(player) or player:getDimension() ~= 0 then return false end
	local pos, int = player:getPosition(), player:getInterior()
	local inside = function(k)
		local p, s = k[1], k[2]
		local px, py, pz = p.x or p[1], p.y or p[2], p.z or p[3]
		local sx, sy, sz = s.x or s[1], s.y or s[2], s.z or s[3]
		return (k[3] or 0) == int and pos.x >= px and pos.x <= px + sx and pos.y >= py and pos.y <= py + sy and pos.z >= pz and pos.z <= pz + sz
	end
	for _, k in pairs(NODM_ZONES or {}) do
		if inside(k) then return true end
	end
	for _, k in pairs(self.m_NoDmZones) do
		if inside(k) then return true end
	end
	return false
end

-- 1 / 0, ob ein Spieler in einer NoDM-Zone steht; nil, wenn es kein Spieler ist oder NoDm nicht läuft (z. B. für Kill- und Schadenslogs)
function NoDm.isInZoneOf(player)
	if not isElement(player) or getElementType(player) ~= "player" or not NoDm:isInstantiated() then return nil end
	return NoDm:getSingleton():isPlayerInZone(player) and 1 or 0
end

function NoDm:Event_requestNoDm()
    if source ~= client then return end
    for index, koords in pairs(self.m_NoDmZones) do
        triggerClientEvent(client, "addNoDm", root, koords, index)
    end
end