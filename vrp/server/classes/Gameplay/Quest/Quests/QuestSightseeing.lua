QuestSightseeing = inherit(Quest)
QuestSightseeing.Locations = {
    Vector3(-2236.07, -1743.28, 480.85), -- Mount Chiliad
    Vector3(-237.75, 2651.87, 62.73), -- Las Payasadas
    Vector3(-372.54, 1576.28, 76.02), -- The Big Ear
    Vector3(-1427.59, -963.59, 200.87), -- San Fierro
    Vector3(-1982.51, 1118.12, 53.13), -- Calton Heights
    Vector3(2120.49, 1333.33, 10.82), -- The Camel's Toe
}

function QuestSightseeing:constructor()
    local position = QuestSightseeing.Locations[Randomizer:get(1, #QuestSightseeing.Locations)]
    self.m_Marker = createMarker(position.x, position.y, position.z - 1, "cylinder", 4, 255, 0, 0, 128)
	self.m_Marker:setVisibleTo(root, false)
    self.m_MarkerHitBind = bind(self.onMarkerHit, self)
    self.m_Blips = {}
    addEventHandler("onMarkerHit", self.m_Marker, self.m_MarkerHitBind)
end

function QuestSightseeing:destructor()
	if isElement(self.m_Marker) then self.m_Marker:destroy() end
end

function QuestSightseeing:addPlayer(player)
    self.m_Blips[player] = Blip:new("Marker.png", self.m_Marker.position.x, self.m_Marker.position.y, player, 6000, {255, 0, 0})
	self.m_Marker:setVisibleTo(player, true)
	Quest.addPlayer(self, player)
end

function QuestSightseeing:removePlayer(player)
	if self.m_Blips[player] then delete(self.m_Blips[player]) end
	self.m_Marker:setVisibleTo(player, false)
	Quest.removePlayer(self, player)
end

function QuestSightseeing:onMarkerHit(hitElement)
    if isElement(hitElement) and hitElement:getType() == "player" then
        local player = hitElement
        if table.find(self:getPlayers(), player) then
            self:success(player)
        end
    end
end