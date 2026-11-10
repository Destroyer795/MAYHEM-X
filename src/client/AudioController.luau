--!strict
local SoundService = game:GetService("SoundService")
local Debris = game:GetService("Debris")
local Visuals = require(game:GetService("ReplicatedStorage").Mayhem.Shared.Visuals)
local Audio = {}
Audio.__index = Audio

function Audio.new(preferences: any)
	local root = Instance.new("Folder")
	root.Name = "MayhemAudio"
	root.Parent = SoundService
	local self: any = setmetatable({ preferences = preferences, root = root, groups = {}, context = "", loop = nil }, Audio)
	for _, name in { "Music", "Ambience", "Effects", "UI" } do
		local group = Instance.new("SoundGroup")
		group.Name = name
		group.Parent = root
		self.groups[name] = group
	end
	return self
end

function Audio.sound(self: any, cue: string, looped: boolean): Sound?
	local uri = Visuals.Audio[cue]
	if type(uri) ~= "string" or not uri:match("^rbxassetid://[1-9]%d*$") or #self.root:GetChildren() >= 24 then return nil end
	local sound = Instance.new("Sound")
	sound.Name = cue
	sound.SoundId = uri
	sound.Volume = 0.6
	sound.Looped = looped
	sound.SoundGroup = self.groups[if cue == "Menu" then "Music" elseif cue == "Lobby" or cue == "Combat" then "Ambience" elseif cue == "UI" then "UI" else "Effects"]
	sound.Parent = self.root
	return sound
end

function Audio.play(self: any, cue: string): boolean
	local sound = self:sound(cue, false)
	if not sound then return false end
	sound.Ended:Once(function() sound:Destroy() end)
	sound:Play()
	Debris:AddItem(sound, 10)
	return true
end

function Audio.update(self: any, menu: boolean, phase: string)
	self.groups.Music.Volume = self.preferences.music
	self.groups.Ambience.Volume = self.preferences.music
	self.groups.Effects.Volume = self.preferences.sound
	self.groups.UI.Volume = self.preferences.sound
	local context = if menu then "Menu" elseif phase == "Active" then "Combat" else "Lobby"
	if context == self.context then return end
	self.context = context
	if self.loop then self.loop:Destroy(); self.loop = nil end
	self.loop = self:sound(context, true)
	if self.loop then self.loop:Play() end
end

return Audio
