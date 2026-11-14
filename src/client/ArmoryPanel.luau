--!strict
local Arsenal = require(game.ReplicatedStorage.Mayhem.Shared.Arsenal)
local Theme = require(script.Parent.Theme)
local ArmoryPanel = {}

local function place(item: GuiObject, x: number, y: number, w: number, h: number)
	item.Position, item.Size = UDim2.fromOffset(math.round(x),math.round(y)), UDim2.fromOffset(math.round(w),math.round(h))
end

function ArmoryPanel.build(self: any)
	local page = self.pages.Armory
	self.armoryId, self.armoryKit = "Vector", "Standard"
	self.armoryRifle.Visible, self.armoryBlade.Visible = false, false
	page.Finishes.Visible = false
	page.Title.Text, page.Scope.Text = "FIELD ARMORY", "FREE ARMORY / EQUAL ACCESS / ROUND-LOCKED LOADOUTS"
	page.Title.Font = Theme.FontDisplay
	self.armoryName = Theme.text(page,"WeaponName","",UDim2.new(),UDim2.new(),38,Theme.Ink,true)
	self.armoryName.Font = Theme.FontDisplay
	self.armoryDescription = Theme.text(page,"WeaponDescription","",UDim2.new(),UDim2.new(),14,Theme.Muted)
	self.armoryRoster = Theme.frame(page,"WeaponRoster",UDim2.new(),UDim2.new(),nil,1)
	self.weaponChoices = {}
	for index,id in {"Vector","Needle","Mantis","Breaker","Rift","Talon","Maul"} do
		local definition = Arsenal.Items[id]
		local button = Theme.button(self.armoryRoster,id,"",UDim2.new(),UDim2.new(),function()
			self.armoryId = id
			self.armoryKit = if definition.slot==1 then "Standard" else "Balanced"
			self.armoryPreview.yaw = 0
		end,true)
		button:FindFirstChildOfClass("UIStroke").Enabled = false
		local name = Theme.text(button,"Name",definition.name,UDim2.fromOffset(16,7),UDim2.new(1,-24,0,21),15,Theme.Ink,true)
		local category = Theme.text(button,"Category",definition.category,UDim2.fromOffset(16,30),UDim2.new(1,-24,0,16),10,Theme.Muted)
		self.weaponChoices[id] = {button=button,name=name,category=category,index=index}
	end
	self.kitTitle = Theme.text(page,"KitHeading","HANDLING KIT",UDim2.new(),UDim2.new(),11,Theme.Muted,true)
	self.kitChoices = {}
	for _,id in {"Standard","Precision","Quickdraw","Balanced","Reach","Tempo"} do
		self.kitChoices[id] = Theme.button(page,id,string.upper(id),UDim2.new(),UDim2.new(),function() self.armoryKit=id end,true)
		self.kitChoices[id].TextSize = 12
	end
	self.kitDescription = Theme.text(page,"KitDescription","",UDim2.new(),UDim2.new(),13,Theme.Muted)
	self.loadoutApply = Theme.button(page,"EquipLoadout","",UDim2.new(),UDim2.new(),function()
		local item = Arsenal.Items[self.armoryId]
		self.callbacks.loadout(if item.slot==1 then "primaryWeapon" else "meleeWeapon",item.id)
		self.callbacks.loadout(if item.slot==1 then "gunKit" else "meleeKit",self.armoryKit)
	end)
	self.loadoutRotate = Theme.button(page,"RotateWeapon","ROTATE",UDim2.new(),UDim2.new(),function() self.armoryPreview.yaw=(self.armoryPreview.yaw or 0)+math.pi/4 end,true)
	self.loadoutFinish = Theme.button(page,"WeaponFinish","FINISHES",UDim2.new(),UDim2.new(),function()
		self.weapon=Arsenal.Items[self.armoryId].slot
		self:open("Inventory")
	end,true)
	self.loadoutNote = Theme.text(page,"LoadoutNotice","",UDim2.new(),UDim2.new(),12,Theme.Muted)
end

function ArmoryPanel.render(self: any, state: any, preferences: any, style: any)
	if self.page~="Armory" then return end
	local page = self.pages.Armory
	local w = page.AbsoluteSize.X
	local compact = w<620
	local item = Arsenal.resolve(self.armoryId,self.armoryKit)
	local base = Arsenal.Items[self.armoryId]
	local paneX = if compact then 0 else math.min(260,w*0.28)+28
	local paneW = w-paneX
	local stageY = if compact then 326 else 76
	place(page.Title,0,0,w,42)
	place(page.Scope,0,45,w,30)
	page.Scope.Text = "4 FIREARMS / 3 MELEE / FREE HANDLING KITS"
	page.Scope.TextSize = 11
	page.Size = UDim2.fromOffset(w,math.max(page.Size.Y.Offset,if compact then 1054 else 726))
	place(self.armoryRoster,0,82,if compact then w else paneX-28,if compact then 230 else 480)
	for id,entry in self.weaponChoices do
		local i = entry.index-1
		local colW = if compact then (w-8)/2 else paneX-28
		place(entry.button,if compact then (i%2)*(colW+8) else 0,if compact then math.floor(i/2)*58 else i*64,colW,54)
		local selected = id==self.armoryId
		entry.button.BackgroundColor3 = if selected then Theme.Action else Theme.Panel
		entry.button.BackgroundTransparency = if selected then 0 else 0.35
		entry.name.TextColor3 = if selected then Theme.Void else Theme.Ink
		entry.category.TextColor3 = if selected then Theme.Void else Theme.Muted
		entry.button.SelectionMark.Visible = selected
	end
	place(self.armoryName,paneX,stageY,paneW-90,48)
	self.armoryName.Text,self.armoryName.TextSize = item.name, if compact then 32 else 42
	place(self.loadoutRotate,w-82,stageY+4,82,44)
	place(self.armoryPreview.frame,paneX,stageY+52,paneW,240)
	place(self.armoryDescription,paneX,stageY+278,paneW,42)
	self.armoryDescription.Text = item.description
	place(self.weaponStats,paneX,stageY+326,paneW,70)
	self.weaponStats.Font,self.weaponStats.TextSize,self.weaponStats.TextColor3 = Theme.FontNumeric,13,Theme.Ink
	self.weaponStats.Text = if item.slot==1 then string.format("%d%s DMG    %d RPM    %.0f STUDS\n%d ROUNDS    %.2fs RELOAD\nBASE: %.0f RANGE / %d ROUNDS / %.2fs RELOAD",item.damage,if item.pellets>1 then " x"..item.pellets else "",60/item.interval,item.range,item.magazine,item.reload,base.range,base.magazine,base.reload)
		else string.format("%d DAMAGE    %.2fs RECOVERY    %.1f REACH\nBASE: %d DAMAGE / %.2fs / %.1f REACH",item.damage,item.interval,item.range,base.damage,base.interval,base.range)
	place(self.kitTitle,paneX,stageY+405,paneW,18)
	local kits = if item.slot==1 then Arsenal.GunKits else Arsenal.MeleeKits
	for id,button in self.kitChoices do button.Visible=table.find(kits,id)~=nil end
	for i,id in kits do
		local kw=(paneW-16)/3
		place(self.kitChoices[id],paneX+(i-1)*(kw+8),stageY+430,kw,44)
		Theme.selected(self.kitChoices[id],id==item.kit)
	end
	place(self.kitDescription,paneX,stageY+484,paneW,44)
	self.kitDescription.Text = Arsenal.KitDescriptions[item.kit]
	local equipped = (if item.slot==1 then preferences.primaryWeapon else preferences.meleeWeapon)==item.id
		and (if item.slot==1 then preferences.gunKit else preferences.meleeKit)==item.kit
	place(self.loadoutApply,paneX,stageY+540,paneW-108,48)
	place(self.loadoutFinish,w-100,stageY+540,100,48)
	if not compact then
		place(page.Title,0,0,w-280,42)
		page.Title.TextSize=30
		place(self.loadoutApply,w-272,0,166,44)
		place(self.loadoutFinish,w-98,0,98,44)
	end
	self.loadoutApply.Active = preferences.loaded==true and not state.inMatch and not equipped
	self.loadoutApply.Text = if state.inMatch then "LOCKED DURING MATCH" elseif equipped then "EQUIPPED" else "EQUIP "..(if item.slot==1 then "PRIMARY" else "MELEE")
	place(self.loadoutNote,paneX,stageY+598,paneW,30)
	self.loadoutNote.Text = if state.inMatch then "Your round loadout is locked." else "Free sidegrades. Saved with preferences. Applied next round."
	if self.page=="Armory" then self.armoryPreview:show("weapon",style.operative,style.skin,item.slot,item.id,item.kit) end
end

return ArmoryPanel
