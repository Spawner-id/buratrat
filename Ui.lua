--[[ 
    MODERN UI LIBRARY + EXAMPLE 
    Paste this into a LocalScript in StarterPlayerScripts or StarterGui.
    Press RightControl to toggle visibility.
]]

local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local Players = game:GetService("Players")
local CoreGui = game:GetService("CoreGui")

local LocalPlayer = Players.LocalPlayer

--// 1. THE LIBRARY LOGIC //--
local Library = {}

-- Theme Configuration
local THEME = {
	Background = Color3.fromRGB(25, 25, 30),
	Header = Color3.fromRGB(35, 35, 40),
	Section = Color3.fromRGB(40, 40, 45),
	Text = Color3.fromRGB(240, 240, 240),
	Accent = Color3.fromRGB(0, 120, 215), -- Modern Blue
	Outline = Color3.fromRGB(60, 60, 65),
	DarkText = Color3.fromRGB(150, 150, 150)
}

local TWEEN_INFO = TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)

-- Utility: Create Instance
local function Create(className, properties)
	local instance = Instance.new(className)
	for k, v in pairs(properties) do
		instance[k] = v
	end
	return instance
end

-- Utility: Dragging Logic
local function MakeDraggable(topbar, widget)
	local dragging, dragInput, dragStart, startPos

	topbar.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 then
			dragging = true
			dragStart = input.Position
			startPos = widget.Position
			
			input.Changed:Connect(function()
				if input.UserInputState == Enum.UserInputState.End then
					dragging = false
				end
			end)
		end
	end)

	topbar.InputChanged:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseMovement then
			dragInput = input
		end
	end)

	UserInputService.InputChanged:Connect(function(input)
		if input == dragInput and dragging then
			local delta = input.Position - dragStart
			local targetPos = UDim2.new(
				startPos.X.Scale, startPos.X.Offset + delta.X, 
				startPos.Y.Scale, startPos.Y.Offset + delta.Y
			)
			-- Smooth drag
			TweenService:Create(widget, TweenInfo.new(0.05), {Position = targetPos}):Play()
		end
	end)
end

function Library:CreateWindow(config)
	local Title = config.Title or "UI Library"
	
	-- Determine Parent (Safe for standard Studio, works in exploits if CoreGui is accessible)
	local ParentTarget = LocalPlayer:WaitForChild("PlayerGui")
	pcall(function() 
		if not RunService:IsStudio() then 
			-- Attempt to use CoreGui if not in studio (usually requires higher context/executor)
			-- If this fails, it falls back to PlayerGui automatically via the variable above if logic allows, 
			-- but strictly speaking standard scripts can't access CoreGui.
			-- We will stick to PlayerGui for this safe example.
		end 
	end)

	local ScreenGui = Create("ScreenGui", {
		Name = "ModernUI_Standalone",
		Parent = ParentTarget,
		ResetOnSpawn = false,
		ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
		IgnoreGuiInset = true -- Makes it look better
	})
	
	-- Toggle Keybind
	UserInputService.InputBegan:Connect(function(input, gpe)
		if input.KeyCode == Enum.KeyCode.RightControl then
			ScreenGui.Enabled = not ScreenGui.Enabled
		end
	end)

	local MainFrame = Create("Frame", {
		Name = "MainFrame",
		Parent = ScreenGui,
		BackgroundColor3 = THEME.Background,
		Position = UDim2.new(0.5, -275, 0.5, -175),
		Size = UDim2.new(0, 550, 0, 350),
		BorderSizePixel = 0,
		ClipsDescendants = true
	})
	
	Create("UICorner", {Parent = MainFrame, CornerRadius = UDim.new(0, 8)})
	Create("UIStroke", {Parent = MainFrame, Color = THEME.Outline, Thickness = 1.5})

	-- Topbar
	local Topbar = Create("Frame", {
		Name = "Topbar",
		Parent = MainFrame,
		BackgroundColor3 = THEME.Header,
		Size = UDim2.new(1, 0, 0, 40),
		BorderSizePixel = 0
	})
	
	local TitleLabel = Create("TextLabel", {
		Parent = Topbar,
		BackgroundTransparency = 1,
		Position = UDim2.new(0, 15, 0, 0),
		Size = UDim2.new(1, -30, 1, 0),
		Font = Enum.Font.GothamBold,
		Text = Title,
		TextColor3 = THEME.Text,
		TextSize = 16,
		TextXAlignment = Enum.TextXAlignment.Left
	})
	
	local CloseTip = Create("TextLabel", {
		Parent = Topbar,
		BackgroundTransparency = 1,
		Position = UDim2.new(0, 0, 0, 0),
		Size = UDim2.new(1, -15, 1, 0),
		Font = Enum.Font.Gotham,
		Text = "RightCtrl to Hide",
		TextColor3 = THEME.DarkText,
		TextSize = 12,
		TextXAlignment = Enum.TextXAlignment.Right
	})

	MakeDraggable(Topbar, MainFrame)

	-- Sidebar (Tabs)
	local TabContainer = Create("Frame", {
		Name = "TabContainer",
		Parent = MainFrame,
		BackgroundColor3 = THEME.Section,
		Position = UDim2.new(0, 0, 0, 40),
		Size = UDim2.new(0, 130, 1, -40),
		BorderSizePixel = 0
	})
	
	local TabListLayout = Create("UIListLayout", {
		Parent = TabContainer,
		SortOrder = Enum.SortOrder.LayoutOrder,
		Padding = UDim.new(0, 2)
	})
	Create("UIPadding", {Parent = TabContainer, PaddingTop = UDim.new(0, 10), PaddingLeft = UDim.new(0, 10), PaddingRight = UDim.new(0, 10)})

	-- Pages Area
	local PageContainer = Create("Frame", {
		Name = "PageContainer",
		Parent = MainFrame,
		BackgroundTransparency = 1,
		Position = UDim2.new(0, 145, 0, 50),
		Size = UDim2.new(1, -160, 1, -60)
	})

	local Window = { Tabs = {} }
	local firstTab = true

	function Window:CreateTab(name, iconId)
		-- Tab Button
		local TabButton = Create("TextButton", {
			Name = name,
			Parent = TabContainer,
			BackgroundColor3 = THEME.Section,
			Size = UDim2.new(1, 0, 0, 32),
			AutoButtonColor = false,
			Font = Enum.Font.GothamMedium,
			Text = name,
			TextColor3 = THEME.DarkText,
			TextSize = 13,
			TextXAlignment = Enum.TextXAlignment.Left
		})
		Create("UICorner", {Parent = TabButton, CornerRadius = UDim.new(0, 6)})
		Create("UIPadding", {Parent = TabButton, PaddingLeft = UDim.new(0, 10)})

		-- Page ScrollFrame
		local Page = Create("ScrollingFrame", {
			Name = name .. "_Page",
			Parent = PageContainer,
			Active = true,
			BackgroundTransparency = 1,
			BorderSizePixel = 0,
			Size = UDim2.new(1, 0, 1, 0),
			ScrollBarThickness = 4,
			ScrollBarImageColor3 = THEME.Outline,
			Visible = false,
			CanvasSize = UDim2.new(0,0,0,0)
		})
		
		local PageLayout = Create("UIListLayout", {
			Parent = Page,
			SortOrder = Enum.SortOrder.LayoutOrder,
			Padding = UDim.new(0, 8)
		})
		
		PageLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
			Page.CanvasSize = UDim2.new(0, 0, 0, PageLayout.AbsoluteContentSize.Y + 20)
		end)

		-- Switch Logic
		local function Activate()
			for _, t in pairs(Window.Tabs) do
				TweenService:Create(t.Button, TWEEN_INFO, {TextColor3 = THEME.DarkText, BackgroundColor3 = THEME.Section}):Play()
				t.Page.Visible = false
			end
			TweenService:Create(TabButton, TWEEN_INFO, {TextColor3 = THEME.Text, BackgroundColor3 = THEME.Accent}):Play()
			Page.Visible = true
		end

		TabButton.MouseButton1Click:Connect(Activate)

		if firstTab then
			firstTab = false
			Activate()
		end

		table.insert(Window.Tabs, {Button = TabButton, Page = Page})
		
		-- Elements
		local TabFunctions = {}
		
		function TabFunctions:CreateSection(text)
			local SectionFrame = Create("Frame", {
				Parent = Page,
				BackgroundTransparency = 1,
				Size = UDim2.new(1, 0, 0, 30)
			})
			local SectionLabel = Create("TextLabel", {
				Parent = SectionFrame,
				BackgroundTransparency = 1,
				Size = UDim2.new(1, 0, 1, 0),
				Font = Enum.Font.GothamBold,
				Text = text:upper(),
				TextColor3 = THEME.DarkText,
				TextSize = 11,
				TextXAlignment = Enum.TextXAlignment.Left
			})
		end

		function TabFunctions:CreateButton(text, callback)
			callback = callback or function() end
			local Button = Create("TextButton", {
				Parent = Page,
				BackgroundColor3 = THEME.Section,
				Size = UDim2.new(1, -5, 0, 35),
				AutoButtonColor = false,
				Font = Enum.Font.Gotham,
				Text = text,
				TextColor3 = THEME.Text,
				TextSize = 13
			})
			Create("UICorner", {Parent = Button, CornerRadius = UDim.new(0, 6)})
			Create("UIStroke", {Parent = Button, Color = THEME.Outline, Thickness = 1})

			Button.MouseEnter:Connect(function()
				TweenService:Create(Button, TWEEN_INFO, {BackgroundColor3 = Color3.fromRGB(50, 50, 55)}):Play()
			end)
			Button.MouseLeave:Connect(function()
				TweenService:Create(Button, TWEEN_INFO, {BackgroundColor3 = THEME.Section}):Play()
			end)
			Button.MouseButton1Click:Connect(function()
				local t = TweenService:Create(Button, TweenInfo.new(0.05), {Size = UDim2.new(1, -10, 0, 32)})
				t:Play()
				t.Completed:Wait()
				TweenService:Create(Button, TweenInfo.new(0.05), {Size = UDim2.new(1, -5, 0, 35)}):Play()
				callback()
			end)
		end

		function TabFunctions:CreateToggle(text, callback)
			callback = callback or function() end
			local toggled = false
			
			local ToggleFrame = Create("TextButton", {
				Parent = Page,
				BackgroundColor3 = THEME.Section,
				Size = UDim2.new(1, -5, 0, 35),
				AutoButtonColor = false,
				Text = ""
			})
			Create("UICorner", {Parent = ToggleFrame, CornerRadius = UDim.new(0, 6)})
			Create("UIStroke", {Parent = ToggleFrame, Color = THEME.Outline, Thickness = 1})

			local Label = Create("TextLabel", {
				Parent = ToggleFrame,
				BackgroundTransparency = 1,
				Position = UDim2.new(0, 12, 0, 0),
				Size = UDim2.new(1, -60, 1, 0),
				Font = Enum.Font.Gotham,
				Text = text,
				TextColor3 = THEME.Text,
				TextSize = 13,
				TextXAlignment = Enum.TextXAlignment.Left
			})

			local Indicator = Create("Frame", {
				Parent = ToggleFrame,
				BackgroundColor3 = Color3.fromRGB(30, 30, 30),
				AnchorPoint = Vector2.new(1, 0.5),
				Position = UDim2.new(1, -10, 0.5, 0),
				Size = UDim2.new(0, 42, 0, 22)
			})
			Create("UICorner", {Parent = Indicator, CornerRadius = UDim.new(1, 0)})
			
			local Circle = Create("Frame", {
				Parent = Indicator,
				BackgroundColor3 = Color3.fromRGB(150, 150, 150),
				AnchorPoint = Vector2.new(0, 0.5),
				Position = UDim2.new(0, 2, 0.5, 0),
				Size = UDim2.new(0, 18, 0, 18)
			})
			Create("UICorner", {Parent = Circle, CornerRadius = UDim.new(1, 0)})

			ToggleFrame.MouseButton1Click:Connect(function()
				toggled = not toggled
				local color = toggled and THEME.Accent or Color3.fromRGB(150, 150, 150)
				local pos = toggled and UDim2.new(0, 22, 0.5, 0) or UDim2.new(0, 2, 0.5, 0)
				
				TweenService:Create(Circle, TWEEN_INFO, {Position = pos, BackgroundColor3 = Color3.fromRGB(255,255,255)}):Play()
				TweenService:Create(Indicator, TWEEN_INFO, {BackgroundColor3 = toggled and THEME.Accent or Color3.fromRGB(30,30,30)}):Play()
				callback(toggled)
			end)
		end

		function TabFunctions:CreateSlider(text, min, max, default, callback)
			callback = callback or function() end
			local value = default or min
			local dragging = false

			local SliderFrame = Create("Frame", {
				Parent = Page,
				BackgroundColor3 = THEME.Section,
				Size = UDim2.new(1, -5, 0, 55)
			})
			Create("UICorner", {Parent = SliderFrame, CornerRadius = UDim.new(0, 6)})
			Create("UIStroke", {Parent = SliderFrame, Color = THEME.Outline, Thickness = 1})

			local Label = Create("TextLabel", {
				Parent = SliderFrame,
				BackgroundTransparency = 1,
				Position = UDim2.new(0, 12, 0, 5),
				Size = UDim2.new(1, -24, 0, 20),
				Font = Enum.Font.Gotham,
				Text = text,
				TextColor3 = THEME.Text,
				TextSize = 13,
				TextXAlignment = Enum.TextXAlignment.Left
			})
			
			local ValLabel = Create("TextLabel", {
				Parent = SliderFrame,
				BackgroundTransparency = 1,
				Position = UDim2.new(0, 12, 0, 5),
				Size = UDim2.new(1, -24, 0, 20),
				Font = Enum.Font.Gotham,
				Text = tostring(value),
				TextColor3 = THEME.DarkText,
				TextSize = 13,
				TextXAlignment = Enum.TextXAlignment.Right
			})

			local Bar = Create("TextButton", {
				Parent = SliderFrame,
				BackgroundColor3 = Color3.fromRGB(25, 25, 25),
				Position = UDim2.new(0, 12, 0, 32),
				Size = UDim2.new(1, -24, 0, 8),
				AutoButtonColor = false,
				Text = ""
			})
			Create("UICorner", {Parent = Bar, CornerRadius = UDim.new(1, 0)})

			local Fill = Create("Frame", {
				Parent = Bar,
				BackgroundColor3 = THEME.Accent,
				Size = UDim2.new((value - min) / (max - min), 0, 1, 0)
			})
			Create("UICorner", {Parent = Fill, CornerRadius = UDim.new(1, 0)})

			local function Update(input)
				local SizeX = Bar.AbsoluteSize.X
				local PosX = Bar.AbsolutePosition.X
				local percent = math.clamp((input.Position.X - PosX) / SizeX, 0, 1)
				value = math.floor(min + (max - min) * percent)
				
				ValLabel.Text = tostring(value)
				TweenService:Create(Fill, TweenInfo.new(0.05), {Size = UDim2.new(percent, 0, 1, 0)}):Play()
				callback(value)
			end

			Bar.InputBegan:Connect(function(input)
				if input.UserInputType == Enum.UserInputType.MouseButton1 then
					dragging = true
					Update(input)
				end
			end)
			
			UserInputService.InputChanged:Connect(function(input)
				if dragging and input.UserInputType == Enum.UserInputType.MouseMovement then
					Update(input)
				end
			end)
			
			UserInputService.InputEnded:Connect(function(input)
				if input.UserInputType == Enum.UserInputType.MouseButton1 then
					dragging = false
				end
			end)
		end

		return TabFunctions
	end

	return Window
end

--// 2. EXAMPLE USAGE //--

-- Create the Window
local Window = Library:CreateWindow({
	Title = "Admin Panel | v1.0"
})

-- Tab 1: LocalPlayer
local MainTab = Window:CreateTab("LocalPlayer")

MainTab:CreateSection("Movement")

MainTab:CreateSlider("WalkSpeed", 16, 200, 16, function(v)
	if LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("Humanoid") then
		LocalPlayer.Character.Humanoid.WalkSpeed = v
	end
end)

MainTab:CreateSlider("JumpPower", 50, 300, 50, function(v)
	if LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("Humanoid") then
		LocalPlayer.Character.Humanoid.JumpPower = v
	end
end)

MainTab:CreateSection("Actions")

MainTab:CreateToggle("Infinite Jump", function(state)
	-- Simple example logic (State is true/false)
	_G.InfJump = state
end)

UserInputService.JumpRequest:Connect(function()
	if _G.InfJump and LocalPlayer.Character then
		LocalPlayer.Character:FindFirstChildOfClass("Humanoid"):ChangeState("Jumping")
	end
end)

MainTab:CreateButton("Reset Character", function()
	if LocalPlayer.Character then
		LocalPlayer.Character:BreakJoints()
	end
end)

-- Tab 2: Visuals
local VisualsTab = Window:CreateTab("Visuals")

VisualsTab:CreateSection("World Settings")

VisualsTab:CreateSlider("FOV", 70, 120, 70, function(v)
	workspace.CurrentCamera.FieldOfView = v
end)

VisualsTab:CreateToggle("Dark Mode (Time)", function(state)
	if state then
		game.Lighting.TimeOfDay = "00:00:00"
	else
		game.Lighting.TimeOfDay = "14:00:00"
	end
end)
