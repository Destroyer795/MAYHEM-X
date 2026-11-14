--!strict
return function(Art: any,Arsenal: any,Visuals: any): number
	local checks=0
	local function check(ok: boolean,message: string) assert(ok,message);checks+=1 end
	local library=game.ReplicatedStorage.Mayhem.Art.Skins
	check(#library:GetChildren()==21,"Three complete collections cover all seven weapons")
	for _,skin in {"VoidReaver","Solaris","Frostborn"} do
		check(Visuals.skin(skin).fullSurface==true,"Catalog identifies a full-surface finish")
		for _,id in {"Vector","Needle","Mantis","Breaker","Rift","Talon","Maul"} do
			local item=Arsenal.Items[id]
			local model=Art.weapon(nil,item.slot,CFrame.identity,Color3.new(1,1,1),id,nil,skin)
			check(model:GetAttribute("SkinId")==skin and model:GetAttribute("FullSurfaceSkin")==true and not model:GetAttribute("SkinUnavailable"),"Actual weapon resolves the requested full-surface variant")
			local meshes=0
			for _,part in model:GetDescendants() do
				if part:IsA("MeshPart") then
					meshes+=1
					local surface=part:FindFirstChildOfClass("SurfaceAppearance")
					check(surface~=nil and surface.ColorMap~="" and surface.RoughnessMap~="" and surface.MetalnessMap~="","Every component has real PBR maps")
					if skin=="Solaris" then check(surface.Color==Color3.fromRGB(255,211,139),"Gold tint preserves the underlying PBR engraving") end
					check(not part.CanCollide and not part.CanTouch and not part.CanQuery and part.Massless,"Skins cannot affect collision or hit detection")
				end
			end
			check(meshes>0 and not model:FindFirstChild("EnergyInlay"),"Full wrap is not a legacy stripe")
			model:Destroy()
		end
	end
	local stock=Art.weapon(nil,1,CFrame.identity,Color3.new(1,1,1),"Vector",nil,"Stock")
	check(not stock:GetAttribute("FullSurfaceSkin") and not stock:FindFirstChild("EnergyInlay"),"Stock comparison uses the original weapon")
	stock:Destroy()
	return checks
end
