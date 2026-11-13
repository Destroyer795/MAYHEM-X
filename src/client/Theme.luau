--!strict
local TweenService = game:GetService("TweenService")
local Visuals = require(game:GetService("ReplicatedStorage").Mayhem.Shared.Visuals)
local Theme: any = {}
for name, rgb in Visuals.Palette do Theme[name] = Color3.fromRGB(table.unpack(rgb)) end
for name, rgb in {
	Surface = {12, 17, 27}, Panel = {24, 33, 49}, Void = {10, 15, 24}, Navy = {31, 43, 61},
	Ink = {239, 245, 251}, White = {239, 245, 251}, Muted = {168, 185, 204}, Metal = {134, 159, 185},
	Action = {242, 174, 63}, Purple = {92, 215, 234}, Cyan = {92, 215, 234},
} do Theme[name] = Color3.fromRGB(table.unpack(rgb)) end
Theme.Spacing = table.freeze({ Tight = 8, Card = 16, Section = 24 })
Theme.Font = Enum.Font.BuilderSansMedium
Theme.FontStrong = Enum.Font.Oswald
Theme.FontNumeric = Enum.Font.RobotoMono

function Theme.corner(item: Instance, radius: number?)
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, radius or 4)
	corner.Parent = item
end

function Theme.frame(parent: Instance, name: string, position: UDim2, size: UDim2, color: Color3?, transparency: number?): Frame
	local frame = Instance.new("Frame")
	frame.Name = name
	frame.Position = position
	frame.Size = size
	frame.BackgroundColor3 = color or Theme.Panel
	frame.BackgroundTransparency = transparency or 0
	frame.BorderSizePixel = 0
	frame.Parent = parent
	return frame
end

function Theme.text(parent: Instance, name: string, content: string, position: UDim2, size: UDim2, textSize: number?, color: Color3?, bold: boolean?): TextLabel
	local label = Instance.new("TextLabel")
	label.Name = name
	label.Text = content
	label.Position = position
	label.Size = size
	label.TextSize = textSize or 14
	label.TextColor3 = if color == Theme.Action then Theme.Cyan else color or Theme.White
	label.Font = if bold then Theme.FontStrong else Theme.Font
	label.BackgroundTransparency = 1
	label.TextXAlignment = Enum.TextXAlignment.Left
	label.TextWrapped = true
	label.Parent = parent
	return label
end

function Theme.stroke(item: Instance, color: Color3?, transparency: number?)
	local stroke = Instance.new("UIStroke")
	stroke.Color = color or Theme.Muted
	stroke.Transparency = transparency or 0.8
	stroke.Thickness = 1
	stroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
	stroke.Parent = item
	return stroke
end

function Theme.button(parent: Instance, name: string, content: string, position: UDim2, size: UDim2, callback: (() -> ())?, secondary: boolean?): TextButton
	local item = Instance.new("TextButton")
	item.Name = name
	item.Position = position
	item.Size = size
	item.BackgroundColor3 = if secondary then Theme.Panel else Theme.Action
	item.TextColor3 = if secondary then Theme.Ink else Theme.Void
	item.BorderSizePixel = 0
	item.Text = content
	item.TextSize = 16
	item.TextWrapped = true
	item.Font = Theme.FontStrong
	item.AutoButtonColor = false
	item.Selectable = true
	if not Theme.FocusOutline then
		local focus = Instance.new("Frame")
		focus.Name = "MayhemFocus"
		focus.BackgroundTransparency = 1
		focus.Size = UDim2.fromScale(1, 1)
		Theme.corner(focus, 4)
		Theme.stroke(focus, Theme.Cyan, 0).Thickness = 2
		Theme.FocusOutline = focus
	end
	item.SelectionImageObject = Theme.FocusOutline
	item.Parent = parent
	Theme.corner(item, 4)
	local border = Theme.stroke(item, if secondary then Theme.Metal else Theme.Action, if secondary then 0.85 else 0.2)
	local scale = Instance.new("UIScale")
	scale.Parent = item
	local selectedLine = Theme.frame(item, "SelectionMark", UDim2.new(0, 0, 0.2, 0), UDim2.new(0, 3, 0.6, 0), Theme.Cyan)
	selectedLine.Visible = false
	local function press(down: boolean)
		if not item.Active then return end
		TweenService:Create(scale, TweenInfo.new(if Theme.reducedMotion then 0 else 0.1), { Scale = if down then 0.97 else 1 }):Play()
	end
	item.MouseButton1Down:Connect(function() press(true) end)
	item.MouseButton1Up:Connect(function() press(false) end)
	item.InputEnded:Connect(function() press(false) end)
	item:GetPropertyChangedSignal("Active"):Connect(function()
		item.TextTransparency = if item.Active then 0 else 0.5
		if not item.Active then scale.Scale = 1 end
	end)
	item.MouseEnter:Connect(function()
		if not item.Active then return end
		TweenService:Create(border, TweenInfo.new(0.12), { Transparency = 0 }):Play()
		if Theme.onHover then Theme.onHover() end
	end)
	item.MouseLeave:Connect(function()
		press(false)
		TweenService:Create(border, TweenInfo.new(0.12), { Transparency = if secondary then 0.85 else 0.2 }):Play()
	end)
	if callback then item.Activated:Connect(function()
		if not item.Active then return end
		if Theme.onClick then Theme.onClick() end
		callback()
	end) end
	return item
end

function Theme.selected(item: TextButton, selected: boolean)
	item.BackgroundColor3 = if selected then Theme.Action else Theme.Panel
	item.TextColor3 = if selected then Theme.Void else Theme.Muted
	local icon = item:FindFirstChild("Icon")
	if icon then for _, line in icon:GetChildren() do if line:IsA("Frame") then line.BackgroundColor3 = if selected then Theme.Void else Theme.Metal end end end
	local marker = item:FindFirstChild("SelectionMark")
	if marker and marker:IsA("Frame") then marker.Visible = selected end
end

function Theme.bar(parent: Instance, name: string, position: UDim2, size: UDim2, color: Color3): Frame
	local track = Theme.frame(parent, name, position, size, Theme.Navy)
	return Theme.frame(track, "Fill", UDim2.new(), UDim2.fromScale(1, 1), color)
end

function Theme.icon(parent: Instance, index: number)
	local holder = Theme.frame(parent, "Icon", UDim2.new(0, 12, 0.5, -8), UDim2.fromOffset(16, 16), nil, 1)
	local paths = {
		{{3,2,13,8},{13,8,3,14},{3,14,3,2}},
		{{5,2,11,2},{11,2,11,7},{11,7,5,7},{5,7,5,2},{2,14,5,10},{5,10,11,10},{11,10,14,14}},
		{{2,5,14,5},{14,5,14,9},{14,9,8,9},{8,9,5,14},{5,14,4,9},{4,9,2,9}},
		{{8,1,15,8},{15,8,8,15},{8,15,1,8},{1,8,8,1}},
		{{2,14,2,10},{7,14,7,6},{12,14,12,2}},
		{{2,3,5,5},{5,5,7,1},{10,3,15,3},{2,10,5,12},{5,12,7,8},{10,10,15,10}},
		{{2,6,8,1},{8,1,14,6},{2,12,8,7},{8,7,14,12}},
		{{2,14,2,8},{7,14,7,2},{12,14,12,5}},
		{{4,1,12,1},{12,1,15,8},{15,8,12,15},{12,15,4,15},{4,15,1,8},{1,8,4,1}},
	}
	for _, line in paths[index] or paths[4] do
		local delta = Vector2.new(line[3]-line[1], line[4]-line[2])
		local stroke = Theme.frame(holder, "Line", UDim2.fromOffset((line[1]+line[3])/2, (line[2]+line[4])/2), UDim2.fromOffset(delta.Magnitude, 1.3), Theme.Metal)
		stroke.AnchorPoint = Vector2.new(0.5, 0.5)
		stroke.Rotation = math.deg(math.atan2(delta.Y, delta.X))
	end
end

return Theme
