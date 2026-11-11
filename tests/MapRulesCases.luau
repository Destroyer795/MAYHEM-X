--!strict
return function(Rules: any): number
	local catalog = { { id = "A" }, { id = "B" }, { id = "C" } }
	assert(Rules.resolve(catalog, { [1] = "B", [2] = "B", [3] = "A" }, { 1, 2, 3 }, nil, 3) == "B", "Majority must win")
	assert(Rules.resolve(catalog, { [9] = "B" }, { 1, 2 }, "A", 0) == "B", "Ineligible votes cannot alter random fallback")
	assert(Rules.resolve(catalog, {}, {}, "A", 100) == "C", "Empty votes rotate away from the previous arena")
	assert(Rules.resolve({ { id = "A" } }, {}, {}, "A", 1) == "A", "One-map development remains valid")
	assert(Rules.resolve(catalog, { [1] = "Missing" }, { 1 }, nil, 0) == "A", "Unknown IDs cannot win")
	assert(Rules.resolve(catalog, { [1] = "A", [2] = "B" }, { 1, 2 }, nil, 0.25) == "A", "First half of a tie draw must select the first candidate")
	assert(Rules.resolve(catalog, { [1] = "A", [2] = "B" }, { 1, 2 }, nil, 0.75) == "B", "Second half of a tie draw must select the second candidate")
	assert(Rules.radius(0, 240) == 185 and Rules.radius(45, 240) == 185, "Safe zone starts after its delay")
	assert(Rules.radius(100, 240) < 185 and Rules.radius(240, 240) == 24, "Safe zone must shrink and clamp")
	assert(Rules.duelRadius(0) == 31 and Rules.duelRadius(10) == 31, "Duel grace must preserve both insertion positions")
	assert(Rules.duelRadius(30) < 31 and Rules.duelRadius(100) == 8, "Duel zone must shrink and clamp")
	return 11
end
