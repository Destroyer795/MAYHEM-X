--!strict
local Theme=require(script.Parent.Theme)
local Preview=require(script.Parent.Preview)
local Visuals=require(game.ReplicatedStorage.Mayhem.Shared.Visuals)
local Arsenal=require(game.ReplicatedStorage.Mayhem.Shared.Arsenal)
local Panel={}
local weaponOrder={"Vector","Needle","Mantis","Breaker","Rift","Talon","Maul"}

local function place(item: GuiObject,x: number,y: number,w: number,h: number)
	item.Position,item.Size=UDim2.fromOffset(math.round(x),math.round(y)),UDim2.fromOffset(math.max(0,math.round(w)),math.max(0,math.round(h)))
end

function Panel.build(self: any,page: Frame)
	self.draftShop,self.collectionFilter,self.collectionWeapon="VoidReaver","SIGNATURE","Vector"
	self.shopTitle=Theme.text(page,"Title","COLLECTION",UDim2.new(),UDim2.new(),32,Theme.Ink,true)
	self.shopWallet=Theme.text(page,"Wallet","",UDim2.new(),UDim2.new(),12,Theme.Muted)
	self.transactionNote=Theme.text(page,"RecentTransaction","",UDim2.new(),UDim2.new(),11,Theme.Muted)
	self.collectionTabs={}
	for _,name in {"SIGNATURE","SIGNAL","OWNED"} do
		self.collectionTabs[name]=Theme.button(page,name,name,UDim2.new(),UDim2.new(),function() self.collectionFilter=name end,true)
	end
	local selector=Instance.new("ScrollingFrame")
	selector.Name,selector.BackgroundTransparency,selector.BorderSizePixel="FinishSelection",1,0
	selector.ScrollBarThickness,selector.ScrollingDirection=1,Enum.ScrollingDirection.Y
	selector.ScrollBarImageColor3=Theme.Metal
	selector.Parent=page
	self.shopSelector,self.shopButtons=selector,{}
	for _,item in Visuals.Skins do
		local button=Theme.button(selector,item.id,"",UDim2.new(),UDim2.new(),function() self.draftShop=item.id;self.compareStock=false end,true)
		button:FindFirstChildOfClass("UIStroke").Enabled=false
		Theme.text(button,"FinishName",item.name,UDim2.fromOffset(14,8),UDim2.new(1,-28,0,23),15,Theme.Ink,true)
		Theme.text(button,"Ownership","",UDim2.fromOffset(14,34),UDim2.new(1,-28,0,18),10,Theme.Muted)
		self.shopButtons[item.id]=button
	end
	self.shopStage=Theme.frame(page,"ItemStage",UDim2.new(),UDim2.new(),Theme.Void,1)
	self.shopPreview=Preview.new(self.shopStage)
	self.shopPreview.frame.Name,self.shopPreview.frame.Size="SelectedWeapon",UDim2.fromScale(1,1)
	self.shopPreviews={Selected=self.shopPreview}
	self.shopName=Theme.text(page,"ItemName","",UDim2.new(),UDim2.new(),32,Theme.Ink,true)
	self.shopDetail=Theme.text(page,"ItemDetail","",UDim2.new(),UDim2.new(),14,Theme.Muted)
	self.shopRarity=Theme.text(page,"Rarity","",UDim2.new(),UDim2.new(),11,Theme.Gold,true)
	self.collectionWeapons={}
	for _,id in weaponOrder do
		self.collectionWeapons[id]=Theme.button(page,"Preview"..id,string.upper(id),UDim2.new(),UDim2.new(),function()
			self.collectionWeapon=id;self.shopWeapon=Arsenal.Items[id].slot
		end,true)
		self.collectionWeapons[id].TextSize=10
	end
	self.shopRotate=Theme.button(page,"Rotate","ROTATE 45",UDim2.new(),UDim2.new(),function() self.shopPreview.yaw=(self.shopPreview.yaw or 0)+math.pi/4;self.shopPreview.lastInputAt=os.clock() end,true)
	self.shopSwap=Theme.button(page,"Compare","COMPARE STOCK",UDim2.new(),UDim2.new(),function() self.compareStock=not self.compareStock end,true)
	self.shopZoomIn=Theme.button(page,"ZoomIn","+",UDim2.new(),UDim2.new(),function() self.shopPreview.zoom=math.clamp((self.shopPreview.zoom or 1)+0.2,0.7,1.7);self.shopPreview.lastInputAt=os.clock() end,true)
	self.shopZoomOut=Theme.button(page,"ZoomOut","-",UDim2.new(),UDim2.new(),function() self.shopPreview.zoom=math.clamp((self.shopPreview.zoom or 1)-0.2,0.7,1.7);self.shopPreview.lastInputAt=os.clock() end,true)
	self.shopAction=Theme.button(page,"Acquire","",UDim2.new(),UDim2.new(),function()
		local item=Visuals.skin(self.draftShop)
		if self.style and self.style.owned[item.id] then self.callbacks.select("skin",item.id)
		elseif item.source=="weekly" or item.source=="daily" then self:open("Daily")
		elseif item.currency then self:confirmPurchase(item.id)
		else self.callbacks.claim(item.id) end
	end)
end

function Panel.render(self: any,preferences: any,style: any)
	if self.page~="Shop" then return end
	local page=self.pages.Shop
	local w=page.AbsoluteSize.X
	local compact=w<680
	local h=if compact then 910 else math.max(610,self.content.AbsoluteSize.Y)
	page.Size=UDim2.fromOffset(w,h)
	place(self.shopTitle,0,0,w*(if compact then 1 else 0.45),40)
	self.shopTitle.TextSize=if compact then 24 else 32
	if compact then place(self.shopTitle,0,0,w*0.56,40) end
	place(self.shopWallet,if compact then 0 else w*0.48,if compact then 44 else 8,w*(if compact then 1 else 0.52),26)
	self.shopWallet.Text=string.format("%d CR / %d SHARDS / %d TOKENS",style.profile.credits,style.profile.shards,style.profile.seasonTokens)
	self.shopWallet.TextXAlignment=if compact then Enum.TextXAlignment.Left else Enum.TextXAlignment.Right
	for i,name in {"SIGNATURE","SIGNAL","OWNED"} do
		local tabWidth=if compact then (w-12)/3 else 122
		place(self.collectionTabs[name],(i-1)*(tabWidth+(if compact then 6 else 8)),if compact then 82 else 58,tabWidth,44)
		Theme.selected(self.collectionTabs[name],self.collectionFilter==name)
	end
	local listW=if compact then w else math.min(250,w*0.27)
	local top=if compact then 138 else 116
	place(self.shopSelector,0,top,listW,if compact then 74 else h-top-26)
	self.shopSelector.ScrollingDirection=if compact then Enum.ScrollingDirection.X else Enum.ScrollingDirection.Y
	local visible={}
	for _,item in Visuals.Skins do
		local show=if self.collectionFilter=="SIGNATURE" then item.fullSurface==true elseif self.collectionFilter=="SIGNAL" then not item.fullSurface else style.owned[item.id]==true
		self.shopButtons[item.id].Visible=show
		if show then table.insert(visible,item) end
	end
	if #visible>0 and not self.shopButtons[self.draftShop].Visible then self.draftShop=visible[1].id end
	for i,item in visible do
		local button=self.shopButtons[item.id]
		place(button,if compact then (i-1)*174 else 0,if compact then 0 else (i-1)*78,if compact then 166 else listW,68)
		local selected=item.id==self.draftShop
		button.BackgroundColor3=if selected then Theme.Navy else Theme.Panel
		button.BackgroundTransparency=if selected then 0 else 0.6
		button.SelectionMark.Visible=selected
		button.FinishName.TextColor3=if selected then Theme.Action else Theme.Ink
		button.Ownership.Text=string.upper(item.rarity).." / "..(if style.skin==item.id then "EQUIPPED" elseif style.owned[item.id] then "OWNED" elseif item.source=="weekly" then "DAY 07" elseif item.cost then item.cost.." "..string.upper(item.currency) else "AVAILABLE")
	end
	self.shopSelector.CanvasSize=if compact then UDim2.fromOffset(#visible*174,0) else UDim2.fromOffset(0,#visible*78)
	local x=if compact then 0 else listW+26
	local paneW=w-x
	local stageY=if compact then 240 else 146
	local stageH=if compact then 235 else math.clamp(self.content.AbsoluteSize.Y-360,185,330)
	place(self.shopName,x,if compact then 218 else 104,paneW-64,42)
	local item=Visuals.skin(self.draftShop)
	local weapon=Arsenal.Items[self.collectionWeapon]
	if weapon.slot~=self.shopWeapon then self.collectionWeapon=if self.shopWeapon==1 then preferences.primaryWeapon else preferences.meleeWeapon;weapon=Arsenal.Items[self.collectionWeapon] end
	self.shopName.Text=if weapon.slot==2 and item.meleeName then item.meleeName else item.name
	self.shopName.TextSize=if compact then 28 else 36
	place(self.shopStage,x,stageY+(if compact then 38 else 8),paneW,stageH)
	local weaponsY=stageY+stageH+(if compact then 48 else 18)
	local cols=if compact then 4 else 7
	local chip=(paneW-(cols-1)*6)/cols
	for i,id in weaponOrder do
		place(self.collectionWeapons[id],x+((i-1)%cols)*(chip+6),weaponsY+math.floor((i-1)/cols)*48,chip,42)
		Theme.selected(self.collectionWeapons[id],id==self.collectionWeapon)
	end
	local detailsY=weaponsY+(if compact then 104 else 56)
	place(self.shopRarity,x,detailsY,paneW,20)
	self.shopRarity.Text=string.upper(item.rarity).." / "..(if item.fullSurface then "FULL SURFACE / PBR" else "LEGACY SIGNAL ACCENT")
	place(self.shopDetail,x,detailsY+28,paneW,58)
	self.shopDetail.Text=item.description
	local controls=if compact then detailsY+96 else detailsY+26
	if not compact then place(self.shopDetail,x,controls+112,paneW,58) end
	place(self.shopAction,x,controls,paneW*0.5-5,48)
	if not compact then
		place(self.shopAction,w-196,0,196,44)
		place(self.shopWallet,w*0.56,52,w*0.44,44)
	else
		place(self.shopAction,w*0.59,0,w*0.41,44)
	end
	self.shopAction.TextSize=if compact then 12 else 16
	place(self.shopSwap,x+paneW*0.5+5,controls,paneW*0.5-5,48)
	place(self.shopRotate,x,controls+58,paneW-108,44)
	place(self.shopZoomOut,w-100,controls+58,46,44)
	place(self.shopZoomIn,w-46,controls+58,46,44)
	self.shopSwap.Text=if self.compareStock then "SHOW FINISH" else "COMPARE STOCK"
	self.shopAction.Text=if style.skin==item.id then "EQUIPPED" elseif style.owned[item.id] then "EQUIP COLLECTION" elseif item.source=="weekly" or item.source=="daily" then "OPEN DAILY CACHE" elseif item.cost then "BUY / "..item.cost..(if item.currency=="credits" then " CR" else " SHARDS") else "CLAIM / FREE"
	self.shopAction.Active=(style.ready and style.skin~=item.id) or item.source=="weekly" or item.source=="daily"
	place(self.transactionNote,x,controls+(if compact then 110 else 174),paneW,28)
	self.transactionNote.Text="DRAG TO ROTATE / SCROLL OR PINCH TO ZOOM / COSMETIC ONLY"
	page.Size=UDim2.fromOffset(w,math.max(h,controls+(if compact then 150 else 206)))
	local kit=if weapon.slot==1 then preferences.gunKit else preferences.meleeKit
	self.shopPreview:show("weapon",style.operative,if self.compareStock then "Stock" else self.draftShop,weapon.slot,weapon.id,kit)
end

return Panel
