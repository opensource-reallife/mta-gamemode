-- ****************************************************************************
-- *
-- *  PROJECT:     vRoleplay
-- *  FILE:        server/classes/AI/DefendActor.lua
-- *  PURPOSE:     (Area-)Defend actor class
-- *
-- ****************************************************************************
DefendActor = inherit(Actor)

function DefendActor:constructor(model, weapon, range)
    self:setModel(model)
    self:giveWeapon(weapon, 999999999, true)
	self.m_AttackRange = ColShape.Sphere(self:getPosition(), range)
    self.m_ColShapeHitFunc = bind(self.onColShapeHit, self)
	addEventHandler("onColShapeHit", self.m_AttackRange, self.m_ColShapeHitFunc)

    -- Start tasks
    self:startIdleTask()
end

function DefendActor:getIdleTask()
    return TaskGuard
end

function DefendActor:onColShapeHit(ele)
    if self.onAttackRangeHit and self.onAttackRangeHit(self, ele) then
        return
    end
    self:startShooting(ele)
end

function DefendActor:startShooting(target)
    if self:getPrimaryTaskClass() == TaskGuard then
        self:startPrimaryTask(TaskShootTarget, target)
    end
end

function DefendActor:destructor()
    removeEventHandler("onColShapeHit", self.m_AttackRange, self.m_ColShapeHitFunc)
    self:stopPrimaryTask()
    delete(self.m_AttackRange)
    self:destroy()
end