-- ****************************************************************************
-- *
-- *  PROJECT:     vRoleplay
-- *  FILE:        client/classes/Events/Halloween/Quests/GhostFinderQuest.lua
-- *  PURPOSE:     Ghost Finder Quest class
-- *
-- ****************************************************************************

GhostFinderQuest = inherit(HalloweenQuest)

function GhostFinderQuest:constructor()
    self.m_Ghost = HalloweenGhost:new(Vector3(-50.91, 1399.30, 1084.43), 341, 8, 13, false, bind(self.onGhostKill, self))
    self.m_Ghost:setAttackMode(true)
end

function GhostFinderQuest:virtual_destructor()
    if self.m_Ghost then
        delete(self.m_Ghost)
    end
end

function GhostFinderQuest:startQuest()
    self:createDialog(bind(self.onStart, self), 
        "Okay, jetzt gibt es wirklich ein Problem!",
        "In meinem Haus spukt es und Ich bin zu alt, um den Geist zu vertreiben!",
        "Hier, nimm diesen Geistvertreiber und treib den Geist aus!"
    )
end

function GhostFinderQuest:onStart()
    triggerServerEvent("Halloween:giveGhostCleaner", localPlayer)
    self.m_QuestMessage = ShortMessage:new("Vertreibe den Geist aus dem Haus des Fremden!", "Halloween: Quest", Color.Orange, -1, false, false, Vector2(1851.825, -2135.402), {{path="Marker.png", pos=Vector2(1851.825, -2135.402)}}, true)
end

function GhostFinderQuest:onGhostKill()
    delete(self.m_QuestMessage)
    self.m_QuestMessage = ShortMessage:new("Kehre nun zum Friedhof zurück!", "Halloween: Quest", Color.Orange, -1, false, false, false, false, true)
    self:setSucceeded()
end

function GhostFinderQuest:endQuest()
    self:createDialog(false, 
        "Ich danke dir vielmals für deine Hilfe!",
        "Hier, eine Belohnung für deine Arbeit!"
    )
end