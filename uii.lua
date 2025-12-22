--[[ 
    MODERN UI LIBRARY v3 (Full Border + Mobile + Min/Max)
    -----------------------------------------------------
    1. Paste into a LocalScript in StarterGui or StarterPlayerScripts.
    2. Press Play.
]]

local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local Players = game:GetService("Players")
local CoreGui = game:GetService("CoreGui")

local LocalPlayer = Players.LocalPlayer

--// LIBRARY CONFIGURATION //--
local Library = {}

local THEME = {
	Background = Color3.fromRGB(20, 20, 25),
	Header = Color3.fromRGB(25, 25, 30),
	Section = Color3.fromRGB(30, 30, 35),
	Text = Color3.fromRGB(240, 240, 240),
	Accent = Color3.fromRGB(0, 140, 255), -- Neon Blue Border Color
	DarkText = Color3.fromRGB(150, 150, 150),
	Red = Color3.fromRGB(255, 60, 60)
}

--// HELPER FUNCTIONS //--
local function Create(class, props)
	local inst = Instance.new(class)
	for k, v in pairs(props) do inst[k] = v end
	return inst
end

local function MakeDraggable(topbar, widget)
	local dragging, dragInput, dragStart, startPos

	local function Update(input)
		local delta = input.Position - dragStart
		local targetPos = UDim2.new(
			startPos.X.Scale, startPos.X.Offset + delta.X, 
			startPos.Y.Scale, startPos.Y.Offset + delta.Y
		)
		TweenService:Create(widget, TweenInfo.new(0.05), {Position = targetPos}):Play()
	end

	topbar.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
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
		if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
			dragInput = input
		end
	end)

	UserInputService.InputChanged:Connect(function(input)
		if input == dragInput and dragging then
			Update(input)
		end
	end)
end

--// MAIN LIBRARY LOGIC //--
function Library:CreateWindow(config)
	local Title = config.Title or "UI Library"
	
	-- Cleanup old instances
	local Parent = LocalPlayer:WaitForChild("PlayerGui")
	if Parent:FindFirstChild("ModernLibrary_v3") then
		Parent.ModernLibrary_v3:Destroy()
	end

	local ScreenGui = Create("ScreenGui", {
		Name = "ModernLibrary_v3",
		Parent = Parent,
		ResetOnSpawn = false,
		ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
		IgnoreGuiInset = true
	})

	-- 1. THE OPEN BUTTON (Visible when minimized)
	local OpenFrame = Create("Frame", {
		Name = "OpenFrame",
		Parent = ScreenGui,
		AnchorPoint = Vector2.new(0.5, 0),
		Position = UDim2.new(0.5, 0, 0, 10),
		Size = UDim2.new(0, 0, 0, 0), -- Starts invisible
		BackgroundColor3 = THEME.Background,
		ClipsDescendants = true,
		Visible = false
	})
	Create("UICorner", {Parent = OpenFrame, CornerRadius = UDim.new(1, 0)})
	-- Full Border for Open Button
	Create("UIStroke", {Parent = OpenFrame, Color = THEME.Accent, Thickness = 2}) 
	
	local OpenBtn = Create("TextButton", {
		Parent = OpenFrame,
		Size = UDim2.new(1, 0, 1, 0),
		BackgroundTransparency = 1,
		Text = "OPEN MENU",
		Font = Enum.Font.GothamBold,
		TextColor3 = THEME.Accent,
		TextSize = 14
	})

	-- 2. THE MAIN WINDOW
	local MainFrame = Create("Frame", {
		Name = "MainFrame",
		Parent = ScreenGui,
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.new(0.5, 0, 0.5, 0),
		Size = UDim2.new(0, 500, 0, 350),
		BackgroundColor3 = THEME.Background,
		ClipsDescendants = true
	})
	Create("UICorner", {Parent = MainFrame, CornerRadius = UDim.new(0, 10)})
	
	-- [[ HERE IS THE FULL BORDER CHANGE ]] --
	Create("UIStroke", {
		Parent = MainFrame, 
		Color = THEME.Accent, -- Neon Blue All Around
		Thickness = 2, 
		ApplyStrokeMode = Enum.ApplyStrokeMode.Border
	})

	-- Topbar (Header)
	local Topbar = Create("Frame", {
		Parent = MainFrame,
		BackgroundColor3 = THEME.Header,
		Size = UDim2.new(1, 0, 0, 40),
		BorderSizePixel = 0
	})
	MakeDraggable(Topbar, MainFrame)

	local TitleLabel = Create("TextLabel", {
		Parent = Topbar,
		BackgroundTransparency = 1,
		Position = UDim2.new(0, 15, 0, 0),
		Size = UDim2.new(0.6, 0, 1, 0),
		Font = Enum.Font.GothamBold,
		Text = Title,
		TextColor3 = THEME.Text,
		TextSize = 16,
		TextXAlignment = Enum.TextXAlignment.Left
	})

	-- Control Buttons (Min / Exit)
	local Controls = Create("Frame", {
		Parent = Topbar,
		AnchorPoint = Vector2.new(1, 0.5),
		Position = UDim2.new(1, -10, 0.5, 0),
		Size = UDim2.new(0, 60, 0, 24),
		BackgroundTransparency = 1
	})
	local UIList = Create("UIListLayout", {
		Parent = Controls, 
		FillDirection = Enum.FillDirection.Horizontal, 
		SortOrder = Enum.SortOrder.LayoutOrder, 
		Padding = UDim.new(0, 5)
	})

	local MinBtn = Create("TextButton", {
		Parent = Controls,
		BackgroundColor3 = THEME.Section,
		Size = UDim2.new(0, 24, 0, 24),
		Text = "-",
		Font = Enum.Font.GothamBold,
		TextColor3 = THEME.Text,
		AutoButtonColor = false
	})
	Create("UICorner", {Parent = MinBtn, CornerRadius = UDim.new(0, 4)})

	local ExitBtn = Create("TextButton", {
		Parent = Controls,
		BackgroundColor3 = THEME.Red,
		Size = UDim2.new(0, 24, 0, 24),
		Text = "X",
		Font = Enum.Font.GothamBold,
		TextColor3 = Color3.fromRGB(255,255,255),
		AutoButtonColor = false
	})
	Create("UICorner", {Parent = ExitBtn, CornerRadius = UDim.new(0, 4)})

	-- Functionality: Minimize
	MinBtn.MouseButton1Click:Connect(function()
		-- Shrink MainFrame
		MainFrame:TweenSize(UDim2.new(0, 500, 0, 0), "In", "Quad", 0.3, true, function()
			MainFrame.Visible = false
			-- Show Open Button
			OpenFrame.Visible = true
			OpenFrame:TweenSize(UDim2.new(0, 120, 0, 35), "Out", "Back", 0.3, true)
		end)
	end)

	-- Functionality: Open
	OpenBtn.MouseButton1Click:Connect(function()
		OpenFrame:TweenSize(UDim2.new(0, 0, 0, 0), "In", "Quad", 0.2, true, function()
			OpenFrame.Visible = false
			-- Show MainFrame
			MainFrame.Visible = true
			MainFrame:TweenSize(UDim2.new(0, 500, 0, 350), "Out", "Back", 0.3, true)
		end)
	end)

	-- Functionality: Exit
	ExitBtn.MouseButton1Click:Connect(function()
		ScreenGui:Destroy()
	end)

	-- Sidebar (Tabs)
	local Sidebar = Create("Frame", {
		Parent = MainFrame,
		BackgroundColor3 = THEME.Section,
		Position = UDim2.new(0, 0, 0, 40),
		Size = UDim2.new(0, 140, 1, -40),
		BorderSizePixel = 0
	})
	local SidebarLayout = Create("UIListLayout", {Parent = Sidebar, SortOrder = Enum.SortOrder.LayoutOrder, Padding = UDim.new(0, 5)})
	Create("UIPadding", {Parent = Sidebar, PaddingTop = UDim.new(0, 10), PaddingLeft = UDim.new(0, 10), PaddingRight = UDim.new(0, 10)})

	-- Pages Container
	local PageContainer = Create("Frame", {
		Parent = MainFrame,
		BackgroundTransparency = 1,
		Position = UDim2.new(0, 150, 0, 50),
		Size = UDim2.new(1, -160, 1, -60)
	})

	local Window = {Tabs = {}}
	local FirstTab = true

	function Window:CreateTab(name)
		local TabBtn = Create("TextButton", {
			Parent = Sidebar,
			BackgroundColor3 = THEME.Section,
			BackgroundTransparency = 1,
			Size = UDim2.new(1, 0, 0, 30),
			Text = name,
			Font = Enum.Font.GothamMedium,
			TextColor3 = THEME.DarkText,
			TextSize = 13,
			TextXAlignment = Enum.TextXAlignment.Left,
			AutoButtonColor = false
		})
		Create("UICorner", {Parent = TabBtn, CornerRadius = UDim.new(0, 6)})
		Create("UIPadding", {Parent = TabBtn, PaddingLeft = UDim.new(0, 8)})

		local Page = Create("ScrollingFrame", {
			Parent = PageContainer,
			Size = UDim2.new(1, 0, 1, 0),
			BackgroundTransparency = 1,
			Visible = false,
			ScrollBarThickness = 2,
			ScrollBarImageColor3 = THEME.Accent,
			BorderSizePixel = 0
		})
		local PageLayout = Create("UIListLayout", {Parent = Page, SortOrder = Enum.SortOrder.LayoutOrder, Padding = UDim.new(0, 6)})
		PageLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
			Page.CanvasSize = UDim2.new(0, 0, 0, PageLayout.AbsoluteContentSize.Y + 20)
		end)

		local function Activate()
			for _, v in pairs(Window.Tabs) do
				TweenService:Create(v.Btn, TweenInfo.new(0.2), {TextColor3 = THEME.DarkText}):Play()
				v.Page.Visible = false
			end
			TweenService:Create(TabBtn, TweenInfo.new(0.2), {TextColor3 = THEME.Accent}):Play()
			Page.Visible = true
		end

		TabBtn.MouseButton1Click:Connect(Activate)
		if FirstTab then FirstTab = false; Activate() end

		table.insert(Window.Tabs, {Btn = TabBtn, Page = Page})

		local Elements = {}

		function Elements:CreateSection(text)
			local Lbl = Create("TextLabel", {
				Parent = Page,
				BackgroundTransparency = 1,
				Size = UDim2.new(1, 0, 0, 25),
				Text = text:upper(),
				Font = Enum.Font.GothamBold,
				TextColor3 = THEME.DarkText,
				TextSize = 11,
				TextXAlignment = Enum.TextXAlignment.Left
			})
		end

		function Elements:CreateButton(text, callback)
			callback = callback or function() end
			local Btn = Create("TextButton", {
				Parent = Page,
				BackgroundColor3 = THEME.Section,
				Size = UDim2.new(1, -5, 0, 32),
				Text = text,
				Font = Enum.Font.Gotham,
				TextColor3 = THEME.Text,
				TextSize = 13,
				AutoButtonColor = false
			})
			Create("UICorner", {Parent = Btn, CornerRadius = UDim.new(0, 6)})
			-- Gray border for elements
			Create("UIStroke", {Parent = Btn, Color = Color3.fromRGB(50,50,55), Thickness = 1}) 

			Btn.MouseButton1Click:Connect(function()
				TweenService:Create(Btn, TweenInfo.new(0.1), {BackgroundColor3 = THEME.Accent}):Play()
				task.wait(0.1)
				TweenService:Create(Btn, TweenInfo.new(0.2), {BackgroundColor3 = THEME.Section}):Play()
				callback()
			end)
		end

		function Elements:CreateToggle(text, callback)
			callback = callback or function() end
			local Toggled = false
			local Btn = Create("TextButton", {
				Parent = Page,
				BackgroundColor3 = THEME.Section,
				Size = UDim2.new(1, -5, 0, 32),
				Text = "",
				AutoButtonColor = false
			})
			Create("UICorner", {Parent = Btn, CornerRadius = UDim.new(0, 6)})
			Create("UIStroke", {Parent = Btn, Color = Color3.fromRGB(50,50,55), Thickness = 1})

			local Lbl = Create("TextLabel", {
				Parent = Btn,
				BackgroundTransparency = 1,
				Position = UDim2.new(0, 10, 0, 0),
				Size = UDim2.new(1, -50, 1, 0),
				Text = text,
				Font = Enum.Font.Gotham,
				TextColor3 = THEME.Text,
				TextSize = 13,
				TextXAlignment = Enum.TextXAlignment.Left
			})

			local Tracker = Create("Frame", {
				Parent = Btn,
				BackgroundColor3 = Color3.fromRGB(30, 30, 30),
				AnchorPoint = Vector2.new(1, 0.5),
				Position = UDim2.new(1, -10, 0.5, 0),
				Size = UDim2.new(0, 36, 0, 18)
			})
			Create("UICorner", {Parent = Tracker, CornerRadius = UDim.new(1, 0)})

			local Dot = Create("Frame", {
				Parent = Tracker,
				BackgroundColor3 = Color3.fromRGB(100, 100, 100),
				AnchorPoint = Vector2.new(0, 0.5),
				Position = UDim2.new(0, 2, 0.5, 0),
				Size = UDim2.new(0, 14, 0, 14)
			})
			Create("UICorner", {Parent = Dot, CornerRadius = UDim.new(1, 0)})

			Btn.MouseButton1Click:Connect(function()
				Toggled = not Toggled
				local TargetPos = Toggled and UDim2.new(0, 20, 0.5, 0) or UDim2.new(0, 2, 0.5, 0)
				local TargetColor = Toggled and THEME.Accent or Color3.fromRGB(30, 30, 30)
				local DotColor = Toggled and Color3.new(1,1,1) or Color3.fromRGB(100,100,100)
				
				TweenService:Create(Dot, TweenInfo.new(0.2), {Position = TargetPos, BackgroundColor3 = DotColor}):Play()
				TweenService:Create(Tracker, TweenInfo.new(0.2), {BackgroundColor3 = TargetColor}):Play()
				callback(Toggled)
			end)
		end

		function Elements:CreateSlider(text, min, max, default, callback)
			callback = callback or function() end
			local Value = default or min
			local Dragging = false

			local Frame = Create("Frame", {
				Parent = Page,
				BackgroundColor3 = THEME.Section,
				Size = UDim2.new(1, -5, 0, 45)
			})
			Create("UICorner", {Parent = Frame, CornerRadius = UDim.new(0, 6)})
			Create("UIStroke", {Parent = Frame, Color = Color3.fromRGB(50,50,55), Thickness = 1})

			local Lbl = Create("TextLabel", {
				Parent = Frame,
				BackgroundTransparency = 1,
				Position = UDim2.new(0, 10, 0, 5),
				Size = UDim2.new(1, -20, 0, 15),
				Text = text,
				Font = Enum.Font.Gotham,
				TextColor3 = THEME.Text,
				TextSize = 12,
				TextXAlignment = Enum.TextXAlignment.Left
			})
			local ValLbl = Create("TextLabel", {
				Parent = Frame,
				BackgroundTransparency = 1,
				Position = UDim2.new(0, 10, 0, 5),
				Size = UDim2.new(1, -20, 0, 15),
				Text = tostring(Value),
				Font = Enum.Font.Gotham,
				TextColor3 = THEME.DarkText,
				TextSize = 12,
				TextXAlignment = Enum.TextXAlignment.Right
			})

			local Bar = Create("TextButton", {
				Parent = Frame,
				BackgroundColor3 = Color3.fromRGB(25, 25, 25),
				Position = UDim2.new(0, 10, 0, 25),
				Size = UDim2.new(1, -20, 0, 6),
				AutoButtonColor = false,
				Text = ""
			})
			Create("UICorner", {Parent = Bar, CornerRadius = UDim.new(1, 0)})

			local Fill = Create("Frame", {
				Parent = Bar,
				BackgroundColor3 = THEME.Accent,
				Size = UDim2.new((Value - min) / (max - min), 0, 1, 0)
			})
			Create("UICorner", {Parent = Fill, CornerRadius = UDim.new(1, 0)})

			local function Update(input)
				local SizeX = Bar.AbsoluteSize.X
				local PosX = Bar.AbsolutePosition.X
				local Percent = math.clamp((input.Position.X - PosX) / SizeX, 0, 1)
				Value = math.floor(min + (max - min) * Percent)
				ValLbl.Text = tostring(Value)
				TweenService:Create(Fill, TweenInfo.new(0.05), {Size = UDim2.new(Percent, 0, 1, 0)}):Play()
				callback(Value)
			end

			Bar.InputBegan:Connect(function(input)
				if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
					Dragging = true
					Update(input)
				end
			end)
			UserInputService.InputChanged:Connect(function(input)
				if Dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
					Update(input)
				end
			end)
			UserInputService.InputEnded:Connect(function(input)
				if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
					Dragging = false
				end
			end)
		end

		return Elements
	end

	return Window
end

--// 3. EXAMPLE USAGE //--

local Window = Library:CreateWindow({
	Title = "Full Border Panel"
})

-- Tab 1
local MainTab = Window:CreateTab("Main")

MainTab:CreateSection("Player Stats")

MainTab:CreateToggle("Super Speed", function(state)
	if LocalPlayer.Character then
		LocalPlayer.Character.Humanoid.WalkSpeed = state and 50 or 16
	end
end)

MainTab:CreateSlider("Jump Power", 50, 300, 50, function(val)
	if LocalPlayer.Character then
		LocalPlayer.Character.Humanoid.JumpPower = val
	end
end)

MainTab:CreateButton("Reset Character", function()
	LocalPlayer.Character:BreakJoints()
end)

-- Tab 2
local VisualsTab = Window:CreateTab("Visuals")

VisualsTab:CreateSection("World")
VisualsTab:CreateSlider("Field Of View", 70, 120, 70, function(v)
	workspace.CurrentCamera.FieldOfView = v
end)

VisualsTab:CreateToggle("Night Mode", function(state)
	game.Lighting.TimeOfDay = state and "00:00:00" or "14:00:00"
end)
