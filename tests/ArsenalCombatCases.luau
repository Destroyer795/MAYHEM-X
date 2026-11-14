--!strict
return function(Combat: any, Arsenal: any): number
	assert(game:GetService("RunService"):IsStudio(),"Studio fixture only")
	local checks=0
	local function check(ok: boolean,message: string) assert(ok,message); checks+=1 end
	local folder=Instance.new("Folder")
	folder.Name,folder.Parent="ArsenalCombatFixture",workspace
	local actors={}
	local function actor(name: string,position: Vector3)
		local player: any={Name=name,Parent=nil}
		local model=Instance.new("Model")
		model.Name,model.Parent=name,folder
		local root=Instance.new("Part")
		root.Name,root.Size,root.CFrame,root.Anchored="HumanoidRootPart",Vector3.new(4,6,2),CFrame.new(position),true
		root.Parent=model
		local hand=Instance.new("Part")
		hand.Name,hand.Size,hand.CFrame,hand.Anchored="RightHand",Vector3.one,CFrame.new(position+Vector3.new(3,0,0)),true
		hand.CanCollide,hand.CanQuery=false,false
		hand.Parent=model
		local humanoid=Instance.new("Humanoid")
		humanoid.RequiresNeck=false
		humanoid.Parent=model
		player.Character=model
		table.insert(actors,player)
		return player,model,root,humanoid
	end
	local ok,message=xpcall(function()
		local a,ac,ar=actor("Attacker",Vector3.new(1800,100,1800))
		local b,bc,br,bh=actor("Target",Vector3.new(1800,100,1804))
		local prefs={}
		local effects={}
		local canFight=true
		local combat
		combat=Combat.new({
			loadout=function() return prefs end,
			canFight=function() return canFight end,
			bounds=function() return {center=Vector3.new(1800,100,1800),half=40,ceiling=150} end,
			sendState=function() end,
			eliminate=function(victim) combat:endLife(victim) end,
			effect={FireAllClients=function(_,kind,data) table.insert(effects,{kind=kind,data=data}) end,FireClient=function() end},
		})
		for id,base in Arsenal.Items do
			local kits=if base.slot==1 then Arsenal.GunKits else Arsenal.MeleeKits
			for _,kit in kits do
				prefs={primaryWeapon=if base.slot==1 then id else "Vector",meleeWeapon=if base.slot==2 then id else "Rift",gunKit=if base.slot==1 then kit else "Standard",meleeKit=if base.slot==2 then kit else "Balanced"}
				combat:beginLife(a,ac); combat:beginLife(b,bc)
				local ra,rb=combat.records[a],combat.records[b]
				local now=os.clock()
				combat:release(a,now); combat:release(b,now)
				ar.Anchored,br.Anchored=true,true
				ra.protectedUntil,rb.protectedUntil,rb.shield=0,0,0
				bh.MaxHealth,bh.Health=500,500
				local item=if base.slot==1 then ra.primary else ra.melee
				local before=bh.Health
				table.clear(effects)
				if base.slot==1 then
					combat:fire(a,Vector3.zAxis,now)
					check(ra.ammo==item.magazine-1,"Shot spends one shell: "..id..kit)
					check(#effects==1 and #effects[1].data.traces==item.pellets,"Bounded pellet replication")
					check(math.abs(before-bh.Health-item.damage*item.pellets)<0.01,"Server ray damage: "..id..kit)
					combat:fire(a,Vector3.zAxis,now)
					check(ra.ammo==item.magazine-1,"Fire-rate spam rejected")
					local ammo=ra.ammo
					combat:fire(a,Vector3.new(0/0,0,0),now+1)
					check(ra.ammo==ammo,"Invalid aim rejected")
					combat:reload(a,now+1)
					check(math.abs(ra.reloadAt-(now+1+item.reload))<0.01,"Weapon reload duration")
					combat:fire(a,Vector3.zAxis,now+1.2)
					check(ra.ammo==ammo,"No firing during reload")
					combat:tick(now+1+item.reload+0.01,0)
					check(ra.ammo==item.magazine and ra.reserve==item.reserve-1,"Reload capacity and reserve conservation")
				else
					combat:switch(a,2,now)
					check(ac.MayhemWeapon:GetAttribute("WeaponId")==id,"Held melee model matches loadout")
					combat:melee(a,Vector3.zAxis,now+0.3)
					check(math.abs(before-bh.Health-item.damage)<0.01,"Server melee damage: "..id..kit)
					combat:melee(a,Vector3.zAxis,now+0.3)
					check(math.abs(before-bh.Health-item.damage)<0.01,"Melee recovery enforced")
					br.CFrame=CFrame.new(1800,100,1820)
					combat:melee(a,Vector3.zAxis,now+2)
					check(math.abs(before-bh.Health-item.damage)<0.01,"Out-of-range melee rejected")
					br.CFrame=CFrame.new(1800,100,1804)
				end
				prefs.primaryWeapon="Needle"
				check(ra.primary.id==(if base.slot==1 then id else "Vector"),"Round loadout cannot mutate")
				canFight=false
				local ammo=ra.ammo
				combat:fire(a,Vector3.zAxis,now+10)
				check(ra.ammo==ammo,"Inactive match rejects combat")
				canFight=true
			end
		end
		combat:remove(a); combat:remove(b)
	end,debug.traceback)
	for _,player in actors do player.Character=nil end
	folder:Destroy()
	assert(ok,message)
	return checks
end
