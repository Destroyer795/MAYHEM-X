--!strict
if not game:GetService("RunService"):IsStudio() then return end
local players=game:GetService("Players")
local player=players.LocalPlayer
local mayhem=game.ReplicatedStorage:WaitForChild("Mayhem")
local channel=game.ReplicatedStorage:WaitForChild("MayhemArsenalQA",15)
if not channel then return end
local state,style
local count=0
local function check(ok: boolean,message: string) assert(ok,message); count+=1 end
local function waitFor(predicate: ()->boolean,seconds: number,message: string)
	local deadline=os.clock()+seconds
	while not predicate() and os.clock()<deadline do task.wait(0.05) end
	check(predicate(),message)
end
local c1=mayhem.Remotes.State.OnClientEvent:Connect(function(value) state=value end)
local c2=mayhem.Presentation.OnClientEvent:Connect(function(value) style=value end)
local ok,message=xpcall(function()
	mayhem.Remotes.Action:FireServer("Ready")
	mayhem.Presentation:FireServer("Request")
	waitFor(function() return state~=nil and style~=nil and style.profile.ready and #players:GetPlayers()==2 end,30,"Two clients ready")
	local roster=players:GetPlayers()
	table.sort(roster,function(a,b) return a.UserId<b.UserId end)
	local first=player==roster[1]
	local gun,melee=if first then "Needle" else "Breaker",if first then "Talon" else "Maul"
	local kit,mkit=if first then "Precision" else "Quickdraw",if first then "Reach" else "Tempo"
	mayhem.Presentation:FireServer("Preferences",{primaryWeapon=gun,meleeWeapon=melee,gunKit=kit,meleeKit=mkit})
	waitFor(function() return style.profile.preferences.primaryWeapon==gun and style.profile.preferences.meleeWeapon==melee end,5,"Loadout preferences acknowledged")
	mayhem.Remotes.Action:FireServer("Queue",true)
	waitFor(function() return state.phase=="Active" and state.alive end,45,"Selected loadout entered round")
	check(state.combat.primaryId==gun and state.combat.meleeId==melee and state.combat.gunKit==kit,"Authoritative selected loadout")
	waitFor(function() return state.combat.protectionRemaining<=0 end,5,"Spawn protection ended")
	check(player.Character.MayhemWeapon:GetAttribute("WeaponId")==gun,"Own held firearm model")
	local other=if first then roster[2] else roster[1]
	check(other.Character.MayhemWeapon:GetAttribute("WeaponId")== (if first then "Breaker" else "Needle"),"Other client's firearm replicated")
	local ammo=state.combat.ammo
	for _=1,12 do mayhem.Remotes.Action:FireServer("Fire",Vector3.yAxis) end
	task.wait(0.5)
	check(state.combat.ammo==ammo-1,"Real remote fire-rate protection")
	mayhem.Remotes.Action:FireServer("Reload")
	waitFor(function() return state.combat.reloadRemaining>0 end,2,"Variant reload began")
	waitFor(function() return state.combat.reloadRemaining==0 and state.combat.ammo==ammo end,4,"Variant reload conserved ammo")
	mayhem.Presentation:FireServer("Preferences",{primaryWeapon="Mantis",gunKit="Standard"})
	task.wait(0.5)
	check(state.combat.primaryId==gun and state.combat.gunKit==kit,"Mid-match preference request cannot alter active weapon")
	mayhem.Remotes.Action:FireServer("Switch",2)
	waitFor(function() return state.combat.slot==2 end,2,"Melee switch")
	check(player.Character.MayhemWeapon:GetAttribute("WeaponId")==melee,"Own held melee model")
	task.wait(0.5)
	check(other.Character.MayhemWeapon:GetAttribute("WeaponId")== (if first then "Maul" else "Talon"),"Other client's melee replicated")
	mayhem.Remotes.Action:FireServer("Melee",Vector3.yAxis)
	local errors,environmentErrors={},{}
	for _,entry in game:GetService("LogService"):GetLogHistory() do
		if entry.messageType==Enum.MessageType.MessageError then
			if entry.message:find("ChatScript:116: Error calling SetCore CoreGuiChatConnections",1,true)
				or entry.message:find("[Roblox][CoreGui.",1,true) then table.insert(environmentErrors,entry.message)
			else table.insert(errors,entry.message) end
		end
	end
	check(#errors==0,"Client Output errors: "..table.concat(errors," / "))
	channel:FireServer("Complete",{assertions=count,primary=gun,melee=melee,kit=kit,environmentErrors=environmentErrors})
end,debug.traceback)
c1:Disconnect(); c2:Disconnect()
if not ok then channel:FireServer("Failure",tostring(message)) end
