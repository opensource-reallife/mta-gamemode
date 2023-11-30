function avoidCollisions(ped) -- VRP: Avoid collisions by disable collisions with nearby objects and peds
	local x, y, z = getElementPosition(ped)
	local nearbyObjects = getElementsWithinRange(x, y, z, 10, "object")
	for i, obj in ipairs(nearbyObjects) do
		setElementCollidableWith(ped, obj, false)
	end
	local nearbyPeds = getElementsWithinRange(x, y, z, 10, "ped")
	for i, ped2 in ipairs(nearbyPeds) do
		setElementCollidableWith(ped, ped2, false)
	end
end

addEvent("vrpAvoidCollisions", true)
addEventHandler("vrpAvoidCollisions", resourceRoot, avoidCollisions)