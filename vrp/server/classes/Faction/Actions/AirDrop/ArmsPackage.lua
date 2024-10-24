-- ****************************************************************************
-- *
-- *  PROJECT:     vRoleplay
-- *  FILE:        server/classes/Gameplay/ArmsPackage.lua
-- *  PURPOSE:     Arms Dealer class
-- *
-- ****************************************************************************
ArmsPackage = inherit(Object)
ArmsPackage.Model = 2903

function ArmsPackage:constructor(content, pos, destination, type)
    self.m_Position = pos
    self.m_Destination = destination
    self.m_Content = content
    self.m_FactionType = type
    self:create()
end

function ArmsPackage:create()
    local distance = (self.m_Position - self.m_Destination):getLength()
    local time = distance*(60/100)*1000
    local boxId, flyingId, scaleX, scaleY, scaleZ = 2919, 2903, 0.5, 0.5, 0.5
    
    self.m_Object = createObject(flyingId, self.m_Position)
    self.m_Object:setScale(scaleX, scaleY, scaleZ)
    self.m_Object:setCollisionsEnabled(false)
    self.m_Object:setRotation(Vector3(0, 60, 0))
    self.m_Object:move(time, self.m_Destination.x, self.m_Destination.y, self.m_Destination.z+(6.2*0.5), Vector3(0,-60,0), "OutQuad")
    self.m_Timer = setTimer(function()   
        self.m_Object:destroy()
        self.m_Box = createObject(boxId, self.m_Destination)
        self.m_Box:setFrozen(true)
        self.m_Box.m_Package = self
        self.m_Box:setScale(scaleX, scaleY, scaleZ)
        addEventHandler("onElementClicked", self.m_Box, bind(self.dragBox, self))
        self.m_Box:setData("ArmsPackageBox", true)
        self.m_Box.m_Content = self.m_Content
        self.m_Box.m_Type = self.m_FactionType
    end, time, 1)
end

function ArmsPackage:dragBox(button, state, player)
	if button ~= "left" or state ~= "down" or player:isInVehicle() or player:isDead() then
		return
	end
	if getDistanceBetweenPoints3D(player:getPosition(), source:getPosition()) > 3 then
		player:sendError(_("Du bist zu weit von dem Sack entfernt!", player))

		return
	end
	local faction = player:getFaction()
	if not faction or not faction:isStateFaction() and not faction:isEvilFaction() then
        player:sendError(_("Du kannst diesen Sack nicht aufheben!", player))
	    return
	end
	--player:setAnimation("carry", "crry_prtial", 1, true, true, false, true)
    player:attachPlayerObject(source)
    self.m_Carrier = player
end

function ArmsPackage:removeBox(player)
	local box = player:getPlayerAttachedObject()
	if not box then
		return
	end
	player:detachPlayerObject(box)
	box:destroy()
end

function ArmsPackage:destructor()
    if self.m_Carrier and isElement(self.m_Carrier) then 
        self:removeBox(self.m_Carrier)
    end
    if self.m_Box and isElement(self.m_Box) then 
        self.m_Box:destroy() 
    end
    if self.m_Object and isElement(self.m_Object) then 
        self.m_Object:destroy()
    end
end