--!strict
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Inspection = {}

function Inspection.new(frame: ViewportFrame, rotate: (Vector2)->(), zoom: (number)->()): any
	local root=Instance.new("InputContext")
	root.Name,root.Priority,root.Sink,root.Enabled="MayhemInspection",1200,false,false
	root.Parent=ReplicatedStorage
	local button=Instance.new("TextButton")
	button.Name,button.Text="InspectDrag",""
	button.BackgroundTransparency,button.Size,button.AutoButtonColor=1,UDim2.fromScale(1,1),false
	button.ZIndex,button.Parent=2,frame
	local function action(name: string,kind: Enum.InputActionType,keys: {Enum.KeyCode}): InputAction
		local item=Instance.new("InputAction")
		item.Name,item.Type,item.Parent=name,kind,root
		for _,key in keys do
			local binding=Instance.new("InputBinding")
			binding.KeyCode,binding.Parent=key,item
			if kind==Enum.InputActionType.Direction2D then binding.ClampMagnitudeToOne=false end
		end
		return item
	end
	local hold=action("HoldItem",Enum.InputActionType.Bool,{})
	local binding=Instance.new("InputBinding")
	binding.UIButton,binding.Parent=button,hold
	local motion=action("RotateItem",Enum.InputActionType.Direction2D,{})
	local pointer=Instance.new("InputBinding")
	pointer.Type,pointer.ClampMagnitudeToOne,pointer.Parent=Enum.InputBindingType.Scriptable,false,motion
	local wheel=action("ZoomItem",Enum.InputActionType.Direction1D,{})
	local wheelBinding=Instance.new("InputBinding")
	wheelBinding.Type,wheelBinding.Parent=Enum.InputBindingType.Scriptable,wheel
	local self: any={root=root,dragging=false,hovered=false,pinching=false}
	local previous: Vector2?=nil
	local pan=Vector2.zero
	local pinchScale=1
	local scroller=frame:FindFirstAncestorWhichIsA("ScrollingFrame")
	local function lockScroll(locked: boolean)
		if scroller then scroller.ScrollingEnabled=not locked end
	end
	local function move(delta: Vector2)
		if not root.Enabled or self.pinching then return end
		pointer:Fire(delta);pointer:Fire(Vector2.zero)
	end
	local function magnify(value: number)
		if not root.Enabled then return end
		wheelBinding:Fire(value);wheelBinding:Fire(0)
	end
	button.MouseEnter:Connect(function() self.hovered=true;lockScroll(root.Enabled) end)
	button.MouseLeave:Connect(function() self.hovered=false;previous=nil;lockScroll(false) end)
	hold.Pressed:Connect(function() self.dragging=true;lockScroll(root.Enabled) end)
	hold.Released:Connect(function() self.dragging=false;lockScroll(false) end)
	-- UI-processed gestures feed the same IAS intents as the held button.
	button.MouseMoved:Connect(function(x: number,y: number)
		local position=Vector2.new(x,y)
		if previous and self.dragging then move(position-previous) end
		previous=position
	end)
	button.MouseWheelForward:Connect(function() magnify(1) end)
	button.MouseWheelBackward:Connect(function() magnify(-1) end)
	button.TouchPan:Connect(function(positions: {Vector2},translation: Vector2,_velocity: Vector2,state: Enum.UserInputState)
		if state==Enum.UserInputState.Begin then pan=Vector2.zero;lockScroll(root.Enabled) end
		if #positions==1 and not self.pinching then move(translation-pan) end
		pan=translation
		if state==Enum.UserInputState.End or state==Enum.UserInputState.Cancel then lockScroll(false) end
	end)
	button.TouchPinch:Connect(function(_positions: {Vector2},scale: number,_velocity: number,state: Enum.UserInputState)
		if state==Enum.UserInputState.Begin then self.pinching=true;pinchScale=scale;lockScroll(root.Enabled)
		elseif state==Enum.UserInputState.Change then magnify((scale-pinchScale)*6);pinchScale=scale
		elseif state==Enum.UserInputState.End or state==Enum.UserInputState.Cancel then self.pinching=false;lockScroll(false) end
	end)
	motion.StateChanged:Connect(function(value: Vector2) rotate(value) end)
	wheel.StateChanged:Connect(function(value: number) zoom(value) end)
	root:GetPropertyChangedSignal("Enabled"):Connect(function()
		if not root.Enabled then self.dragging=false;self.pinching=false;previous=nil;lockScroll(false) end
	end)
	frame.Destroying:Connect(function() lockScroll(false);root:Destroy() end)
	return self
end

return Inspection
