--!strict
local Rules = require("../src/shared/Rules")
local Config = require("../src/shared/Config")
local run = require("./RulesCases")
local checks = run(Rules, Config)
checks += require("./VisualCases")(require("../src/shared/Visuals"))
checks += require("./StyleCases")(require("../src/shared/StyleRules"), require("../src/shared/Visuals"))
print(string.format("PASS: %d rule assertions", checks))
