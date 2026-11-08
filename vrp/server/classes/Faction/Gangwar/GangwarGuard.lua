GangwarGuard = inherit(Object)

function GangwarGuard:constructor()
	self.m_AttackerLocks = {}
	self.m_DefenderLocks = {}
	self.m_PairLocks = {}
end

function GangwarGuard:destructor()
end

function GangwarGuard:lockAfterAttack(attacker, defender, seconds, pairSeconds)
	local now = getRealTime().timestamp
	self.m_AttackerLocks[attacker:getId()] = now + seconds
	self.m_DefenderLocks[defender:getId()] = now + seconds
	self.m_PairLocks[attacker:getId()] = self.m_PairLocks[attacker:getId()] or {}
	self.m_PairLocks[attacker:getId()][defender:getId()] = now + pairSeconds
end

function GangwarGuard:clearAfterAttack(attacker, defender)
	self.m_AttackerLocks[attacker:getId()] = nil
	self.m_DefenderLocks[defender:getId()] = nil
	if self.m_PairLocks[attacker:getId()] then
		self.m_PairLocks[attacker:getId()][defender:getId()] = nil
	end
end

function GangwarGuard:getPairLock(attacker, defender)
	local locks = self.m_PairLocks[attacker:getId()]
	return math.max(0, (locks and locks[defender:getId()] or 0) - getRealTime().timestamp)
end

function GangwarGuard:getAttackerLock(faction)
	return math.max(0, (self.m_AttackerLocks[faction:getId()] or 0) - getRealTime().timestamp)
end

function GangwarGuard:getDefenderLock(faction)
	return math.max(0, (self.m_DefenderLocks[faction:getId()] or 0) - getRealTime().timestamp)
end
