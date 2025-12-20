-- ==========================================
-- SINGLETON CHECK
-- ==========================================
if _G.ProjectStark_Loaded then
    game:GetService("StarterGui"):SetCore("SendNotification", {
        Title = "Already Running",
        Text = "Project Stark is already executed!",
        Duration = 5,
    })
    return
end
_G.ProjectStark_Loaded = true

-- ==========================================
-- BLADE BALL AUTO-PARRY - MOBILE MOVEMENT & SLIDER FIX
-- ==========================================

local Neverzen = loadstring(game:HttpGet("https://raw.githubusercontent.com/zxciaz/VenyxUI/main/Reuploaded"))()

-- ==========================================
-- SERVICES
-- ==========================================

local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")
local VirtualInputManager = game:GetService("VirtualInputManager")
local TweenService = game:GetService("TweenService")
local Debris = game:GetService("Debris")
local workspace = game:GetService("Workspace")
local CoreGui = game:GetService("CoreGui")

-- ==========================================
-- SLIDER FIX (TOUCH MONITOR)
-- ==========================================
-- This loop checks if you have lifted your fingers. 
-- If no touches are active, it forces a MouseUp event to release sliders.
task.spawn(function()
    while true do
        RunService.Heartbeat:Wait()
        if UserInputService.TouchEnabled then
            local touches = UserInputService:GetNavigationGamepads()
            -- If no fingers are touching the screen (GetNavigationGamepads returns empty for touch on some devices, 
            -- but specific touch detection is better via UserInputService logic)
            -- Alternative: simply force release every frame the user isn't dragging explicitly? No.
            
            -- Best Fix for Venyx on Mobile:
            -- Venyx relies on MouseButton1Up. We force it when TouchEnded fires.
        end
    end
end)

UserInputService.TouchEnded:Connect(function()
    -- Force the UI library to think the mouse was released
    VirtualInputManager:SendMouseButtonEvent(0, 0, 0, false, game, 0)
end)

-- ==========================================
-- UI SETUP
-- ==========================================

local UI = Neverzen.new("BURAT")

-- ==========================================
-- SETTINGS
-- ==========================================

local Settings = {
    ParryMode = "Blatant",
    AutoParry = true,
    DetectCurvedShots = true,
    AutoSpam = true,
    MaxHits = 10,
    ModDetection = false,
    CurveShots = false,
    WalkToBall = false,
    WalkDistance = 15,
    PlayerSpeed = 35,
    InfiniteJump = false,
    DebugMode = false,
}

-- ==========================================
-- CONSTANTS
-- ==========================================

local ParryDuration = 0.35
local HitDelayCheck = 0.10
local MinRange = 3.0

-- ==========================================
-- MATCH STATE
-- ==========================================

local Match = {
    ball = {
        ball_itself = nil,
        client_ball_itself = nil,
        properties = {
            last_sphere_location = Vector3.zero,
            aero_dynamic_time = tick(),
            hell_hook_completed = true,
            last_position = Vector3.zero,
            rotation = Vector3.zero,
            position = Vector3.zero,
            last_warping = tick(),
            parry_remote = nil,
            is_curved = false,
            last_tick = tick(),
            auto_spam = false,
            cooldown = false,
            respawn_time = 0,
            parry_range = 0,
            spam_range = 0,
            maximum_speed = 0,
            old_speed = 0,
            parries = 0,
            direction = 0,
            distance = 0,
            velocity = Vector3.zero,
            last_hit = 0,
            lerp_radians = 0,
            radians = 0,
            speed = 0,
            dot = 0,
            last_curve_position = Vector3.zero,
            last_velocity = Vector3.zero,
            parry_in_progress = false,
            adaptive_cooldown = 0.15,
        },
    },
    target = {
        current = nil,
        from = nil,
        aim = nil,
    },
    entity_properties = {
        server_position = Vector3.zero,
        velocity = Vector3.zero,
        is_moving = false,
        direction = 0,
        distance = 0,
        speed = 0,
        dot = 0,
    },
}

local Playuh = {
    Entity = {
        properties = {
            sword = "",
            server_position = Vector3.zero,
            velocity = Vector3.zero,
            position = Vector3.zero,
            is_moving = false,
            speed = 0,
            ping = 0,
        },
    },
    properties = {
        grab_animation = nil,
    },
}

-- ==========================================
-- UTILITY FUNCTIONS
-- ==========================================

local function LerpRadians(from, to, alpha)
    return from + ((to - from) * alpha)
end

-- ==========================================
-- PARRY REMOTE SETUP
-- ==========================================

function Match.get_parry_remote()
    local services = {game:GetService("AnimationFromVideoCreatorService"), game:GetService("AdService")}
    for _, service in services do
        local remoteEvent = service:FindFirstChildOfClass("RemoteEvent")
        if remoteEvent and remoteEvent.Name:find("\n") then
            Match.ball.properties.parry_remote = remoteEvent
            return
        end
    end
end

Match.get_parry_remote()

-- ==========================================
-- INPUT HANDLER (MOVEMENT FIX)
-- ==========================================

local function PerformInput()
    -- METHOD 1: REMOTE EVENT (Silent, doesn't stop movement)
    if Match.ball.properties.parry_remote then
        local camera = workspace.CurrentCamera
        local ballPos = Match.ball.ball_itself and Match.ball.ball_itself.Position or Vector3.zero
        
        -- Default arguments for Blade Ball parry remote
        -- Arg 1: Time/Float (usually ignored or 0.5)
        -- Arg 2: CFrame (Camera Look)
        -- Arg 3: Table {BallName = Position}
        -- Arg 4: Table {Bool, Bool}
        
        Match.ball.properties.parry_remote:FireServer(
            0.5,
            CFrame.new(camera.CFrame.Position, ballPos),
            {[Match.ball.ball_itself.Name] = ballPos},
            {false, false}
        )
    else
        -- METHOD 2: FALLBACK INPUT (Carefully placed)
        -- We tap the CENTER of the screen, not (0,0). 
        -- (0,0) is top-left where the joystick might be.
        if UserInputService.TouchEnabled then
            local viewportSize = workspace.CurrentCamera.ViewportSize
            local centerX = viewportSize.X / 2
            local centerY = viewportSize.Y / 2
            
            VirtualInputManager:SendMouseButtonEvent(centerX, centerY, 0, true, game, 0)
            task.delay(0.05, function()
                VirtualInputManager:SendMouseButtonEvent(centerX, centerY, 0, false, game, 0)
            end)
        else
            VirtualInputManager:SendMouseButtonEvent(0, 0, 0, true, game, 0)
            VirtualInputManager:SendMouseButtonEvent(0, 0, 0, false, game, 0)
        end
    end
end

-- ==========================================
-- BALL FUNCTIONS
-- ==========================================

function Match.get_ball()
    for _, v in workspace.Balls:GetChildren() do
        if v:GetAttribute("realBall") then
            return v
        end
    end
end

function Match.get_client_ball()
    for _, v in workspace.Balls:GetChildren() do
        if not v:GetAttribute("realBall") then
            return v
        end
    end
end

-- ==========================================
-- CURVE CONFIGS
-- ==========================================

local CurveConfigs = {
    Straight = function(targetPos)
        return CFrame.new(LocalPlayer.Character.PrimaryPart.Position, targetPos)
    end,
    Backwards = function()
        local cam = workspace.CurrentCamera
        return CFrame.new(cam.CFrame.Position, cam.CFrame.Position + (-cam.CFrame.LookVector * 10000) + Vector3.new(0, 1000, 0))
    end,
    Randomizer = function()
        return CFrame.new(
            LocalPlayer.Character.PrimaryPart.Position,
            Vector3.new(math.random(-1000, 1000), math.random(-350, 1000), math.random(-1000, 1000))
        )
    end,
    Boost = function(targetPos)
        return CFrame.new(LocalPlayer.Character.PrimaryPart.Position, targetPos + Vector3.new(0, 150, 0))
    end,
    High = function(targetPos)
        return CFrame.new(LocalPlayer.Character.PrimaryPart.Position, targetPos + Vector3.new(0, 1000, 0))
    end,
    CurveBalls = function(targetPos)
        return CFrame.new(LocalPlayer.Character.PrimaryPart.Position, targetPos + Vector3.new(0, 500, 0))
    end,
}

-- ==========================================
-- GRAB ANIMATION
-- ==========================================

function Match.perform_grab_animation()
    local equippedSword = Playuh.Entity.properties.sword
    if not equippedSword or equippedSword == "Titan Blade" then return end

    local grabParryAnim = ReplicatedStorage.Shared.SwordAPI.Collection.Default:FindFirstChild("GrabParry")
    if not grabParryAnim then return end

    local swordData = ReplicatedStorage.Shared.ReplicatedInstances.Swords.GetSword:Invoke(equippedSword)
    if not swordData or not swordData.AnimationType then return end

    local playerChar = LocalPlayer.Character
    if not playerChar or not playerChar:FindFirstChild("Humanoid") then return end

    local swordModel = ReplicatedStorage.Shared.SwordAPI.Collection:FindFirstChild(swordData.AnimationType)
    if swordModel then
        local anim = swordModel:FindFirstChild("GrabParry") or swordModel:FindFirstChild("Grab")
        if anim then
            grabParryAnim = anim
            if anim.Name == "Grab" then
                PerformInput()
            end
        end
    end

    Playuh.properties.grab_animation = playerChar.Humanoid:LoadAnimation(grabParryAnim)
    Playuh.properties.grab_animation:Play()
    PerformInput()
end

-- ==========================================
-- PERFORM SPAM
-- ==========================================

function Match.perform_spam()
    local props = Match.ball.properties
    
    if not Settings.AutoSpam then return end
    if props.auto_spam then return end
    
    local ball = Match.ball.ball_itself
    if not ball then return end
    
    local myRoot = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
    if not myRoot then return end
    
    local myPos = myRoot.Position
    local ballPos = ball.Position
    local dist = (myPos - ballPos).Magnitude
    local ballVelocity = ball.AssemblyLinearVelocity
    local speed = ballVelocity.Magnitude
    
    local SPAM_MIN_DISTANCE = 5
    local SPAM_MAX_DISTANCE = 15
    local SPAM_MIN_SPEED = 50
    
    local isInSpamRange = (dist >= SPAM_MIN_DISTANCE and dist <= SPAM_MAX_DISTANCE and speed > SPAM_MIN_SPEED)
    
    if not isInSpamRange then return end
    
    if Match.ball.ball_itself:GetAttribute("target") ~= LocalPlayer.Name then return end
    
    props.auto_spam = true
    props.cooldown = true
    
    task.spawn(function()
        local startTime = tick()
        local clickCount = 0
        local maxDuration = 2.0
        
        while props.auto_spam and Match.ball.ball_itself do
            local currentTarget = Match.ball.ball_itself:GetAttribute("target")
            if currentTarget ~= LocalPlayer.Name then break end

            if not myRoot or not myRoot.Parent then break end
            local liveDist = (myRoot.Position - Match.ball.ball_itself.Position).Magnitude
            
            if liveDist < SPAM_MIN_DISTANCE then break end
            if liveDist > SPAM_MAX_DISTANCE + 5 then break end
            if (tick() - startTime) > maxDuration then break end

            PerformInput()
            clickCount = clickCount + 1
            props.last_hit = tick()
            
            RunService.Heartbeat:Wait()
        end
        
        props.auto_spam = false
        task.wait(0.1)
        props.cooldown = false
    end)
end

-- ==========================================
-- PERFORM PARRY
-- ==========================================

function Match.perform_parry()
    local props = Match.ball.properties

    if props.auto_spam then return end
    if props.cooldown and not props.auto_spam then return end
    
    if Settings.AutoSpam and props.distance >= 5 and props.distance <= 15 and props.speed > 50 then
        return
    end

    props.parries = props.parries + 1
    props.last_hit = tick()

    Match.perform_grab_animation()
    props.cooldown = true

    if Settings.CurveShots then
        local curveOptions = {"Straight", "CurveBalls", "Boost", "High", "Backwards"}
        local curveType = curveOptions[math.random(#curveOptions)]
        local cameraCFrame = CurveConfigs[curveType](Match.entity_properties.server_position)
        
        task.spawn(function()
            TweenService:Create(workspace.CurrentCamera, TweenInfo.new(0.1, Enum.EasingStyle.Sine), {CFrame = cameraCFrame}):Play()
            task.wait(0.1)
            if Playuh.properties.grab_animation then 
                Playuh.properties.grab_animation.Ended:Wait() 
            end
            TweenService:Create(workspace.CurrentCamera, TweenInfo.new(0.2, Enum.EasingStyle.Sine), {CFrame = workspace.CurrentCamera.CFrame}):Play()
        end)
    end

    PerformInput()

    task.delay(HitDelayCheck, function()
        if props.parries > 0 then
            props.parries = props.parries - 1
        end
    end)
end

-- ==========================================
-- RESET FUNCTION
-- ==========================================

function Match.reset()
    local props = Match.ball.properties
    props.is_curved = false
    props.auto_spam = false
    props.cooldown = false
    props.maximum_speed = 0
    props.parries = 0
    props.parry_in_progress = false
    Match.entity_properties.server_position = Vector3.zero
    Match.target.current = nil
    Match.target.from = nil
end

-- ==========================================
-- CURVE DETECTION
-- ==========================================

function Match.is_curved()
    local target = Match.target.current
    if not target then return false end

    local props = Match.ball.properties
    local targetName = target.Name

    if target.PrimaryPart:FindFirstChild("MaxShield") and targetName ~= LocalPlayer.Name and props.distance < 50 then
        return false
    end

    if Match.ball.ball_itself:FindFirstChild("TimeHole1") and targetName ~= LocalPlayer.Name and props.distance < 100 then
        props.auto_spam = false
        return false
    end

    if Match.ball.ball_itself:FindFirstChild("WEMAZOOKIEGO") and targetName ~= LocalPlayer.Name and props.distance < 100 then
        return false
    end

    if Match.ball.ball_itself:FindFirstChild("At2") and props.speed <= 0 then
        return true
    end

    local aeroVFX = Match.ball.ball_itself:FindFirstChild("AeroDynamicSlashVFX")
    if aeroVFX then
        Debris:AddItem(aeroVFX, 0)
        props.auto_spam = false
        props.aero_dynamic_time = tick()
    end

    local predictedPos = props.position + (props.velocity * (props.distance / props.maximum_speed))
    local lastCurvePos = props.last_curve_position or props.position
    local dirChange = (predictedPos - lastCurvePos).Unit
    local velDirection = props.velocity.Unit:Dot(dirChange)
    local angleDelta = math.acos(math.clamp(velDirection, -1, 1))
    
    local speedFactor = math.min(props.speed / 100, 40)
    local dotFactor = 40.046 * math.max(props.dot, 0)
    local ping = Playuh.Entity.properties.ping
    local travelTime = (props.distance / (props.velocity.Magnitude + 0.01)) - (ping / 1000)
    
    local curveThreshold = (15 - math.min(props.distance / 1000, 15)) + dotFactor + speedFactor
    
    if props.maximum_speed > 100 and travelTime > (ping / 10) then
        curveThreshold = math.max(curveThreshold - 15, 15)
    end

    if props.distance < curveThreshold then return false end
    
    if angleDelta > (0.5 + (props.speed / 310)) then
        props.auto_spam = false
        return true
    end

    if props.lerp_radians < 0.018 then
        props.last_curve_position = props.position
        props.last_warping = tick()
    end

    if (tick() - props.last_warping) < (travelTime / 1.5) then
        return true
    end

    props.last_curve_position = props.position
    return props.dot < (ParryDuration - (ping / 950))
end

-- ==========================================
-- SERVER POSITION SIMULATION
-- ==========================================

RunService:BindToRenderStep("server position simulation", 1, function()
    local char = LocalPlayer.Character
    if char and char.PrimaryPart then
        task.delay(game:GetService("Stats").Network.ServerStatsItem["Data Ping"]:GetValue() / 1000, function()
            if char and char.PrimaryPart then
                Playuh.Entity.properties.server_position = char.PrimaryPart.Position
            end
        end)
    end
end)

-- ==========================================
-- PLAYER PROPERTIES UPDATE
-- ==========================================

RunService.PreSimulation:Connect(function()
    local char = LocalPlayer.Character
    if not char or not char.PrimaryPart then return end

    local props = Playuh.Entity.properties
    props.sword = char:GetAttribute("CurrentlyEquippedSword")
    props.ping = game:GetService("Stats").Network.ServerStatsItem["Data Ping"]:GetValue()
    props.velocity = char.PrimaryPart.AssemblyLinearVelocity
    props.speed = props.velocity.Magnitude
    props.is_moving = props.speed > 30
end)

-- ==========================================
-- BALL PROPERTIES UPDATE
-- ==========================================

Match.ball.ball_itself = Match.get_ball()
Match.ball.client_ball_itself = Match.get_client_ball()

RunService.PreSimulation:Connect(function()
    local ballEntity = Match.ball.ball_itself
    if not ballEntity then return end

    local props = Match.ball.properties
    props.position = ballEntity.Position
    props.velocity = ballEntity.AssemblyLinearVelocity

        local zoomies = ballEntity:FindFirstChild("zoomies")
    if zoomies then
        props.velocity = zoomies.VectorVelocity
    end

    props.distance = (Playuh.Entity.properties.server_position - props.position).Magnitude
    props.speed = props.velocity.Magnitude
    props.direction = (Playuh.Entity.properties.server_position - props.position).Unit
    props.dot = props.direction:Dot(props.velocity.Unit)
    props.radians = math.rad(math.asin(props.dot))
    props.lerp_radians = LerpRadians(props.lerp_radians, props.radians, 0.8)

    if props.lerp_radians ~= props.lerp_radians then
        props.lerp_radians = 0.027
    end

    props.maximum_speed = math.max(props.speed, props.maximum_speed)

    Match.target.aim = (not UserInputService.TouchEnabled and LocalPlayer.Character) or LocalPlayer.Character

    local targetAttr = ballEntity:GetAttribute("target")
    if targetAttr then
        Match.target.current = workspace.Alive:FindFirstChild(targetAttr)
    end

    local fromAttr = ballEntity:GetAttribute("from")
    if fromAttr then
        Match.target.from = workspace.Alive:FindFirstChild(fromAttr)
    end

    if Match.target.current and Match.target.current.Name == LocalPlayer.Name then
        props.rotation = Match.target.aim.PrimaryPart.Position
        return
    end

    if not Match.target.current then return end

    local targetPos = Match.target.current.PrimaryPart.Position
    local targetVel = Match.target.current.PrimaryPart.AssemblyLinearVelocity

    local entityProps = Match.entity_properties
    entityProps.server_position = targetPos
    entityProps.velocity = targetVel
    entityProps.distance = LocalPlayer:DistanceFromCharacter(targetPos)
    entityProps.direction = (Playuh.Entity.properties.server_position - targetPos).Unit
    entityProps.speed = targetVel.Magnitude
    entityProps.is_moving = targetVel.Magnitude > 0.1
    entityProps.dot = entityProps.is_moving and math.max(entityProps.direction:Dot(targetVel.Unit), 0) or 0
end)

-- ==========================================
-- BALL EVENTS
-- ==========================================

local isBallOnGame = false
workspace.Balls.ChildRemoved:Connect(function(v)
    isBallOnGame = false
    if v == Match.ball.ball_itself then
        Match.ball.ball_itself = nil
        Match.ball.client_ball_itself = nil
        Match.reset()
    end
end)

workspace.Balls.ChildAdded:Connect(function()
    if isBallOnGame then return end
    isBallOnGame = true
    
    local props = Match.ball.properties
    props.respawn_time = tick()
    Match.ball.ball_itself = Match.get_ball()
    Match.ball.client_ball_itself = Match.get_client_ball()
    
    Match.ball.ball_itself:GetAttributeChangedSignal("target"):Connect(function()
        local target = Match.ball.ball_itself:GetAttribute("target")
        if target == LocalPlayer.Name then
            props.cooldown = false
            return
        end
        props.cooldown = false
        props.old_speed = props.speed
        props.last_position = props.position
        props.parries = props.parries + 1
        task.delay(1, function()
            if props.parries > 0 then
                props.parries = props.parries - 1
            end
        end)
    end)
end)

-- ==========================================
-- AUTO PARRY LOGIC LOOP
-- ==========================================

task.spawn(function()
    RunService.PostSimulation:Connect(function()
        if not Settings.AutoParry then
            Match.reset()
            return
        end

        local char = LocalPlayer.Character
        if not char or char.Parent == workspace.Dead then
            Match.reset()
            return
        end

        if not Match.ball.ball_itself then return end

        local props = Match.ball.properties
        props.is_curved = Match.is_curved()

        local ping = Playuh.Entity.properties.ping
        local baseAccuracy = 0.99
        local distanceFactor = baseAccuracy * (1 / (Match.entity_properties.distance + 0.05)) * 1000
        local pingFactor = math.clamp(ping / 10, 10, 16)
        local parryBaseRange = (props.maximum_speed / 10.5) + pingFactor

        if Playuh.Entity.properties.is_moving then
            parryBaseRange = parryBaseRange * 0.10
        end

        if ping >= 190 then
            parryBaseRange = parryBaseRange * (1 + (ping / 1000))
        end

        props.parry_range = ((parryBaseRange * 1.16) + pingFactor + props.speed) / MinRange

        if Playuh.Entity.properties.sword == "Titan Blade" then
            props.parry_range = props.parry_range + 11
        end

        if props.is_curved then return end

        if props.distance > props.parry_range 
            and props.distance > parryBaseRange then
            return
        end

        if Match.target.current and Match.target.current ~= LocalPlayer.Character then
            return
        end

        if Settings.ParryMode == "Normal" then
            if props.distance <= 10 and Match.entity_properties.distance <= 50 then
                if math.random(1, 2) == 1 then
                    Match.perform_parry()
                end
            end
            if props.maximum_speed >= 250 then
                parryBaseRange = parryBaseRange * 1.2
            end
        end

        props.last_sphere_location = props.position
        Match.perform_parry()

        task.spawn(function()
            repeat
                RunService.PreSimulation:Wait()
            until (tick() - props.last_hit) > (1 - (pingFactor / 100))
            props.cooldown = false
        end)
    end)
end)

-- ==========================================
-- SPAM CHECKER
-- ==========================================

task.spawn(function()
    RunService.Heartbeat:Connect(function()
        if not Settings.AutoSpam then return end
        if not Settings.AutoParry then return end
        
        local char = LocalPlayer.Character
        if not char or char.Parent == workspace.Dead then return end
        
        local props = Match.ball.properties
        if props.auto_spam then return end
        
        local SPAM_MIN_DISTANCE = 5
        local SPAM_MAX_DISTANCE = 15
        local SPAM_MIN_SPEED = 50
        
        local isInSpamRange = (
            props.distance >= SPAM_MIN_DISTANCE and 
            props.distance <= SPAM_MAX_DISTANCE and 
            props.speed > SPAM_MIN_SPEED
        )
        
        if isInSpamRange and Match.target.current == LocalPlayer.Character then
            Match.perform_spam()
        end
    end)
end)

-- ==========================================
-- WALK TO BALL
-- ==========================================

local walkConnection
local function WalkBall()
    local char = LocalPlayer.Character
    if not char or not char:FindFirstChild("HumanoidRootPart") or not char:FindFirstChild("Humanoid") then
        return
    end

    if walkConnection then
        walkConnection:Disconnect()
    end

    local humanoid = char.Humanoid
    local rootPart = char.HumanoidRootPart

    walkConnection = RunService.Heartbeat:Connect(function()
        if not Settings.WalkToBall then
            humanoid:Move(Vector3.zero)
            walkConnection:Disconnect()
            return
        end

        local ball = Match.get_ball()
        if not ball then
            humanoid:Move(Vector3.zero)
            return
        end

        local distance = (ball.Position - rootPart.Position).Magnitude
        if distance <= Settings.WalkDistance then
            humanoid:Move(Vector3.zero)
            return
        end

        local direction = (ball.Position - rootPart.Position).Unit
        humanoid:MoveTo(rootPart.Position + direction * math.min(distance - Settings.WalkDistance, humanoid.WalkSpeed * 0.1))
    end)
end

-- ==========================================
-- UI TABS
-- ==========================================

local CombatTab = UI:addPage("Combat", 5012544693)
local VisualTab = UI:addPage("Visual", 5012544693)
local MovementTab = UI:addPage("Movement", 5012544693)
local ExtrasTab = UI:addPage("Extras", 5012544693)

-- ==========================================
-- COMBAT TAB
-- ==========================================

local CombatSection = CombatTab:addSection("Auto Parry")

CombatSection:addToggle("Auto Parry", Settings.AutoParry, function(value)
    Settings.AutoParry = value
end)

CombatSection:addToggle("Auto Spam (Close Range)", Settings.AutoSpam, function(value)
    Settings.AutoSpam = value
end)

CombatSection:addDropdown("Parry Mode", {"Normal", "Legit", "Blatant"}, function(selected)
    Settings.ParryMode = selected
end)

CombatSection:addSlider("Accurancy", 1, Settings.MaxHits, 100, function(value)
    Settings.MaxHits = value
end)

-- ==========================================
-- VISUAL TAB
-- ==========================================

local VisualSection = VisualTab:addSection("Curve Shots")

VisualSection:addToggle("Detect Curved Shots", Settings.DetectCurvedShots, function(value)
    Settings.DetectCurvedShots = value
end)

VisualSection:addToggle("Enable Curve Shots", Settings.CurveShots, function(value)
    Settings.CurveShots = value
end)

VisualSection:addButton("Info", function()
    game:GetService("StarterGui"):SetCore("SendNotification", {
        Title = "Curve Shots";
        Text = "Curve shots will aim at different angles. Press L to open a normal sword crate.";
        Duration = 5;
    })
end)

-- ==========================================
-- MOVEMENT TAB
-- ==========================================

local MovementSection = MovementTab:addSection("Movement")

MovementSection:addToggle("Walk To Ball", Settings.WalkToBall, function(value)
    Settings.WalkToBall = value
    if value then WalkBall() end
end)

MovementSection:addSlider("Stop Distance", 5, Settings.WalkDistance, 50, function(value)
    Settings.WalkDistance = value
end)

MovementSection:addSlider("Player Speed", 20, Settings.PlayerSpeed, 200, function(value)
    Settings.PlayerSpeed = value
    if LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("Humanoid") then
        LocalPlayer.Character.Humanoid.WalkSpeed = Settings.PlayerSpeed
    end
end)

MovementSection:addToggle("Infinite Jump", Settings.InfiniteJump, function(value)
    Settings.InfiniteJump = value
end)

-- ==========================================
-- EXTRAS TAB
-- ==========================================

local ExtrasSection = ExtrasTab:addSection("Extras")

ExtrasSection:addButton("FPS Boost", function()
    local Lighting = game:GetService("Lighting")
    local Terrain = workspace:FindFirstChildWhichIsA("Terrain")
    
    if Terrain then
        Terrain.WaterWaveSize = 0
        Terrain.WaterWaveSpeed = 0
        Terrain.WaterReflectance = 0
        Terrain.WaterTransparency = 1
    end
    
    Lighting.GlobalShadows = false
    Lighting.FogEnd = 9e9
    Lighting.FogStart = 9e9
    settings().Rendering.QualityLevel = Enum.QualityLevel.Level01
    
    for _, v in game:GetDescendants() do
        if v:IsA("BasePart") then
            v.CastShadow = false
            v.Material = Enum.Material.Plastic
            v.Reflectance = 0
        elseif v:IsA("Decal") then
            v.Transparency = 1
        elseif v:IsA("ParticleEmitter") or v:IsA("Trail") then
            v.Lifetime = NumberRange.new(0)
        elseif v:IsA("PostEffect") then
            v.Enabled = false
        end
    end
end)

ExtrasSection:addButton("Server Hop", function()
    loadstring(game:HttpGet("https://pastebin.com/raw/nfYuXYqd"))()
end)

ExtrasSection:addButton("Rejoin", function()
    game:GetService("TeleportService"):TeleportToPlaceInstance(game.PlaceId, game.JobId, LocalPlayer)
end)

local CreditsSection = ExtrasTab:addSection("Credits")

CreditsSection:addButton("Discord (Click to Copy)", function()
    setclipboard("https://discord.gg/vgYZApyrZC")
    game:GetService("StarterGui"):SetCore("SendNotification", {
        Title = "Copied!";
        Text = "Discord link copied to clipboard";
        Duration = 3;
    })
end)

-- ==========================================
-- SPEED MONITOR
-- ==========================================

task.spawn(function()
    while task.wait(0.5) do
        pcall(function()
            if LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("Humanoid") then
                if LocalPlayer.Character.Humanoid.WalkSpeed ~= Settings.PlayerSpeed then
                    LocalPlayer.Character.Humanoid.WalkSpeed = Settings.PlayerSpeed
                end
            end
        end)
    end
end)

-- ==========================================
-- INFINITE JUMP
-- ==========================================

UserInputService.InputBegan:Connect(function(input, gameProcessed)
    if Settings.InfiniteJump and input.KeyCode == Enum.KeyCode.Space then
        local humanoid = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("Humanoid")
        if humanoid then
            humanoid:ChangeState(Enum.HumanoidStateType.Jumping)
        end
    end
end)

-- ==========================================
-- SWORD CRATE OPENER
-- ==========================================

UserInputService.InputBegan:Connect(function(input, gameProcessed)
    if gameProcessed or input.KeyCode ~= Enum.KeyCode.L then return end
    
    local cratePrompt = workspace.Spawn 
        and workspace.Spawn.Crates
        and workspace.Spawn.Crates.NormalSwordCrate
        and workspace.Spawn.Crates.NormalSwordCrate.Lock
        and workspace.Spawn.Crates.NormalSwordCrate.Lock.ProximityPrompt
    
    if cratePrompt then
        fireproximityprompt(cratePrompt)
    end
end)

-- ==========================================
-- ANTI-AFK
-- ==========================================

LocalPlayer.Idled:Connect(function()
    game:GetService("VirtualUser"):CaptureController()
    game:GetService("VirtualUser"):ClickButton2(Vector2.zero)
end)

-- ==========================================
-- MOBILE GUI (TOGGLE BUTTON)
-- ==========================================

local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "ProjectStarkMobileUI"
ScreenGui.Parent = CoreGui
ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling

local ToggleBtn = Instance.new("TextButton")
ToggleBtn.Name = "ToggleBtn"
ToggleBtn.Parent = ScreenGui
ToggleBtn.BackgroundColor3 = Color3.fromRGB(35, 35, 35)
ToggleBtn.BorderSizePixel = 0
ToggleBtn.Position = UDim2.new(0.1, 0, 0.1, 0) -- Top left area
ToggleBtn.Size = UDim2.new(0, 50, 0, 50)
ToggleBtn.Font = Enum.Font.SourceSansBold
ToggleBtn.Text = "UI"
ToggleBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
ToggleBtn.TextSize = 20.000

local UICorner = Instance.new("UICorner")
UICorner.CornerRadius = UDim.new(0, 10)
UICorner.Parent = ToggleBtn

-- Make Button Draggable
local dragging, dragInput, dragStart, startPos
local function update(input)
    local delta = input.Position - dragStart
    ToggleBtn.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
end

ToggleBtn.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        dragging = true
        dragStart = input.Position
        startPos = ToggleBtn.Position
        
        input.Changed:Connect(function()
            if input.UserInputState == Enum.UserInputState.End then
                dragging = false
            end
        end)
    end
end)

ToggleBtn.InputChanged:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
        dragInput = input
    end
end)

UserInputService.InputChanged:Connect(function(input)
    if input == dragInput and dragging then
        update(input)
    end
end)

-- Toggle Logic
ToggleBtn.MouseButton1Click:Connect(function()
    UI:toggle()
end)

print("✅ Project Stark Auto-Parry loaded successfully!")
