--!strict
local TweenService = game:GetService("TweenService")
local Visuals = require(game:GetService("ReplicatedStorage").Mayhem.Shared.Visuals)
local Theme: any = {}
for name, rgb in Visuals.Palette do Theme[name] = Color3.fromRGB(table.unpack(rgb)) end
Theme.Spacing = table.freeze({ Tight = 8, Card = 16, Section = 24 })
Theme.Font = Enum.Font.GothamMedium
Theme.FontStrong = Enum.Font.GothamBold

function Theme.corner(item: Instance, radius: number?)
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, radius or 8)
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
	label.TextColor3 = color or Theme.White
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
	stroke.Parent = item
	return stroke
end

function Theme.button(parent: Instance, name: string, content: string, position: UDim2, size: UDim2, callback: (() -> ())?, secondary: boolean?): TextButton
	local item = Instance.new("TextButton")
	item.Name = name
	item.Position = position
	item.Size = size
	item.BackgroundColor3 = if secondary then Theme.Panel else Theme.Action
	item.TextColor3 = if secondary then Theme.Ink else Theme.White
	item.BorderSizePixel = 0
	item.Text = content
	item.TextSize = 13
	item.TextWrapped = true
	item.Font = Theme.FontStrong
	item.AutoButtonColor = false
	item.Selectable = true
	item.Parent = parent
	Theme.corner(item, 6)
	local border = Theme.stroke(item, if secondary then Theme.Muted else Theme.Action, if secondary then 0.7 else 0.2)
	item.MouseEnter:Connect(function()
		if not item.Active then return end
		TweenService:Create(border, TweenInfo.new(0.12), { Transparency = 0 }):Play()
		if Theme.onHover then Theme.onHover() end
	end)
	item.MouseLeave:Connect(function() TweenService:Create(border, TweenInfo.new(0.12), { Transparency = if secondary then 0.7 else 0.2 }):Play() end)
	if callback then item.Activated:Connect(function()
		if not item.Active then return end
		if Theme.onClick then Theme.onClick() end
		callback()
	end) end
	return item
end

function Theme.selected(item: TextButton, selected: boolean)
	item.BackgroundColor3 = if selected then Theme.Action else Theme.Panel
	item.TextColor3 = if selected then Theme.White else Theme.Ink
end

function Theme.bar(parent: Instance, name: string, position: UDim2, size: UDim2, color: Color3): Frame
	local track = Theme.frame(parent, name, position, size, Theme.Metal)
	return Theme.frame(track, "Fill", UDim2.new(), UDim2.fromScale(1, 1), color)
end

return Theme
