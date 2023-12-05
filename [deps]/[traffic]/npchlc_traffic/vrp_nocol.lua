function avoidCollisions(ped) -- VRP: Avoid collisions by disabling collisions with nearby objects and deleting peds too near to each other
	local x, y, z = getElementPosition(ped)
	local nearbyObjects = getElementsWithinRange(x, y, z, 30, "object")
	for i, obj in ipairs(nearbyObjects) do
		setElementCollidableWith(ped, obj, false)
	end
end

addEvent("vrpAvoidCollisions", true)
addEventHandler("vrpAvoidCollisions", resourceRoot, avoidCollisions)