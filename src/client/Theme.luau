--!strict
local TweenService = game:GetService("TweenService")
local Visuals = require(game:GetService("ReplicatedStorage").Mayhem.Shared.Visuals)
local Theme: any = {}
for name, rgb in Visuals.Palette do Theme[name] = Color3.fromRGB(table.unpack(rgb)) end

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
	label.TextColor3 = color or Theme.White
	label.Font = if bold then Enum.Font.GothamBold else Enum.Font.GothamMedium
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
	stroke.Parent = item
	return stroke
end

function Theme.button(parent: Instance, name: string, content: string, position: UDim2, size: UDim2, callback: (() -> ())?, secondary: boolean?): TextButton
	local item = Instance.new("TextButton")
	item.Name = name
	item.Position = position
	item.Size = size
	item.BackgroundColor3 = if secondary then Theme.Panel else Theme.Purple
	item.TextColor3 = Theme.White
	item.BorderSizePixel = 0
	item.Text = content
	item.TextSize = 13
	item.Font = Enum.Font.GothamBold
	item.AutoButtonColor = false
	item.Selectable = true
	item.Parent = parent
	local border = Theme.stroke(item, if secondary then Theme.Muted else Theme.Purple, if secondary then 0.7 else 0.2)
	item.MouseEnter:Connect(function() TweenService:Create(border, TweenInfo.new(0.12), { Transparency = 0 }):Play() end)
	item.MouseLeave:Connect(function() TweenService:Create(border, TweenInfo.new(0.12), { Transparency = if secondary then 0.7 else 0.2 }):Play() end)
	if callback then item.Activated:Connect(callback) end
	return item
end

function Theme.bar(parent: Instance, name: string, position: UDim2, size: UDim2, color: Color3): Frame
	local track = Theme.frame(parent, name, position, size, Theme.Metal)
	return Theme.frame(track, "Fill", UDim2.new(), UDim2.fromScale(1, 1), color)
end

return Theme
