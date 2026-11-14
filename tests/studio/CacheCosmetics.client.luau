--!strict
if not game:GetService("RunService"):IsStudio() then return end
local player=game.Players.LocalPlayer
local channel=game.ReplicatedStorage:WaitForChild("MayhemCacheQA",15)
if not channel then return end
local mayhem=game.ReplicatedStorage.Mayhem
local state: any,style: any
local checks=0
local renderFrames=0
local renderConnection=game:GetService("RunService").RenderStepped:Connect(function() renderFrames+=1 end)
local function check(ok: boolean,message: string) assert(ok,message);checks+=1 end
local function waitFor(predicate: ()->boolean,seconds: number,message: string)
	local untilTime=os.clock()+seconds
	while not predicate() and os.clock()<untilTime do task.wait(0.05) end
	check(predicate(),message)
end
local stateConnection=mayhem.Remotes.State.OnClientEvent:Connect(function(v) state=v end)
local styleConnection=mayhem.Presentation.OnClientEvent:Connect(function(v) style=v end)
local function surface(model: Model?,id: string)
	check(model~=nil and model:GetAttribute("SkinId")=="VoidReaver" and model:GetAttribute("FullSurfaceSkin")==true and model:GetAttribute("WeaponId")==id,"Actual equipped model must carry the full wrap")
	for _,part in (model :: Model):GetDescendants() do
		if part:IsA("MeshPart") then
			local pbr=part:FindFirstChildOfClass("SurfaceAppearance")
			check(pbr~=nil,"Generated SurfaceAppearance replicates with the mesh; map URLs are Plugin-only")
			check(not part.CanCollide and not part.CanQuery and not part.CanTouch,"Cosmetic remains outside hit detection")
		end
	end
end
local ok,message=xpcall(function()
	mayhem.Remotes.Action:FireServer("Ready")
	mayhem.Presentation:FireServer("Request")
	waitFor(function() return state~=nil and style~=nil and style.profile.ready and #game.Players:GetPlayers()==2 end,30,"Both real clients ready")
	check(not style.profile.persistent,"Local file must disclose session-only storage")
	local failedAssets={}
	local fetched=0
	game:GetService("ContentProvider"):PreloadAsync({mayhem.Art.Skins},function(id,status)
		if status==Enum.AssetFetchStatus.Success then fetched+=1 else table.insert(failedAssets,id.." / "..tostring(status)) end
	end)
	check(#failedAssets==0 and fetched>0,"Full-surface client assets: "..table.concat(failedAssets," / "))
	local day=style.profile.calendar.day
	local reward=style.profile.calendar.days[day].reward
	mayhem.Presentation:FireServer("Daily",{day=99999999,credits=99999999})
	waitFor(function() return style.dailyClaimed and style.profile.credits==reward.credits end,5,"Server chooses the real UTC day, ignoring the forged date and amount")
	local earned=style.profile.credits
	for _=1,3 do mayhem.Presentation:FireServer("Daily") end
	task.wait(0.8)
	check(style.profile.credits==earned,"Real remote duplicates cannot grant more Credits")
	channel:FireServer("Seed")
	waitFor(function() return style.profile.credits==earned+135 end,3,"Explicit server-side purchase fixture credited")
	mayhem.Presentation:FireServer("Select",{kind="skin",id="VoidReaver"})
	task.wait(0.4)
	check(style.skin=="Pulse","Unowned full wrap cannot be equipped")
	mayhem.Presentation:FireServer("Purchase","VoidReaver")
	waitFor(function() return style.owned.VoidReaver and style.profile.credits==earned end,3,"Real purchase conserves the Credit balance")
	task.wait(0.4)
	mayhem.Presentation:FireServer("Purchase","VoidReaver")
	task.wait(0.4)
	check(style.profile.credits==earned,"Duplicate purchase does not charge twice")
	mayhem.Presentation:FireServer("Select",{kind="skin",id="VoidReaver"})
	waitFor(function() return style.skin=="VoidReaver" and player:GetAttribute("MayhemSkin")=="VoidReaver" end,3,"Owned collection equipped")
	local previous=player.Character
	channel:FireServer("Respawn")
	waitFor(function() return player.Character~=nil and player.Character~=previous and player.Character:GetAttribute("MayhemSkin")=="VoidReaver" end,10,"Respawn preserves the selected collection")
	mayhem.Presentation:FireServer("Daily")
	task.wait(0.4)
	check(style.dailyClaimed and style.profile.credits==earned,"Respawn does not reset the claim cursor")
	local roster=game.Players:GetPlayers()
	table.sort(roster,function(a,b) return a.UserId<b.UserId end)
	local first=player==roster[1]
	local gun,melee=if first then "Needle" else "Mantis",if first then "Talon" else "Maul"
	local other=if first then roster[2] else roster[1]
	mayhem.Presentation:FireServer("Preferences",{firstPerson=true,primaryWeapon=gun,meleeWeapon=melee})
	waitFor(function() return style.profile.preferences.firstPerson and style.profile.preferences.primaryWeapon==gun end,3,"First-person loadout acknowledged")
	mayhem.Remotes.Action:FireServer("Queue",true)
	waitFor(function() return state.phase=="Active" and state.alive end,45,"Normal queue starts a real match")
	waitFor(function() return state.combat.protectionRemaining<=0 end,5,"Server spawn protection ends before switching")
	waitFor(function() return player.Character:FindFirstChild("MayhemWeapon")~=nil end,5,"Server creates the real held weapon")
	local liveRender=renderFrames>0
	local function viewmodel(slot: number,id: string)
		if liveRender then
			waitFor(function() local m=workspace.CurrentCamera:FindFirstChild("MayhemViewmodel");return m~=nil and m:GetAttribute("WeaponId")==id end,5,"Live first-person viewmodel, frames="..renderFrames..", camera="..tostring(workspace.CurrentCamera.CameraType))
			surface(workspace.CurrentCamera.MayhemViewmodel,id)
		else
			local controller=require(player.PlayerScripts.MayhemClient.CameraController)
			local factory=setmetatable({preferences={skin="VoidReaver"},combat=state.combat},controller)
			factory:makeViewmodel(slot)
			surface(factory.viewmodel,id)
			factory.viewmodel:Destroy()
		end
	end
	surface(player.Character.MayhemWeapon,gun)
	viewmodel(1,gun)
	waitFor(function() return other.Character and other.Character:FindFirstChild("MayhemWeapon")~=nil end,3,"Other player's firearm replicated")
	surface(other.Character.MayhemWeapon,if first then "Mantis" else "Needle")
	channel:FireServer("GunReady")
	waitFor(function() return other:GetAttribute("QAGunReady")==true end,3,"Both clients inspect firearms before switching")
	mayhem.Remotes.Action:FireServer("Switch",2)
	waitFor(function() return state.combat.slot==2 and player.Character.MayhemWeapon:GetAttribute("WeaponId")==melee end,4,"Actual melee switch")
	surface(player.Character.MayhemWeapon,melee)
	viewmodel(2,melee)
	waitFor(function() return other.Character.MayhemWeapon:GetAttribute("WeaponId")== (if first then "Maul" else "Talon") end,3,"Other player's melee finish replicated")
	surface(other.Character.MayhemWeapon,if first then "Maul" else "Talon")
	local errors={}
	for _,v in game.LogService:GetLogHistory() do
		if v.messageType==Enum.MessageType.MessageError and not v.message:find("[Roblox][CoreGui.",1,true) and not v.message:find("ChatScript:116",1,true) then table.insert(errors,v.message) end
	end
	check(#errors==0,"Client script errors: "..table.concat(errors," / "))
	channel:FireServer("Complete",{assertions=checks,utcDay=day,skin="VoidReaver",primary=gun,melee=melee,respawn=true,firstPersonLiveRender=liveRender,firstPersonFactory=true,renderFrames=renderFrames,assetRequests=fetched,otherPlayer=true,persistenceVerified=false})
end,debug.traceback)
stateConnection:Disconnect();styleConnection:Disconnect();renderConnection:Disconnect()
if not ok then channel:FireServer("Failure",tostring(message)) end
