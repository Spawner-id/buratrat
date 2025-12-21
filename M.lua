--[[
    Infinixity | Blade Ball
    UI Library: Orion (Fixed Mirror)
    Logic: Preserved
]]

-- CHANGELOG: Switched to working Orion mirror to fix HTTP 404
local OrionLib = loadstring(game:HttpGet(('https://raw.githubusercontent.com/jensonhirst/Orion/main/source')))()
local NotifyName = "Infinixity"

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local HttpService = game:GetService("HttpService")
local Debris = game:GetService("Debris")
local CollectionService = game:GetService("CollectionService")
local UserInputService = game:GetService("UserInputService")

local LocalPlayer = Players.LocalPlayer
local Camera = Workspace.CurrentCamera
local Mouse = LocalPlayer:GetMouse()
local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")

-- // UTILITY FUNCTIONS //
local Utils = {}
function Utils:GetHumanoid(model)
    return model and model:FindFirstChildWhichIsA("Humanoid")
end
function Utils:GetHumanoidRootPart(model)
    return model and model:FindFirstChild("HumanoidRootPart")
end
function Utils:TowardsPosition(pos, target, dir)
    if not (pos and target and dir) then return 0 end
    local directionToPos = (pos - target).Unit
    return directionToPos:Dot(dir)
end
function Utils:Timer(duration)
    local startTime = os.clock()
    return function()
        return (os.clock() - startTime) >= duration
    end
end
function Utils:FireRemote(_, remote, ...)
    if remote and remote:IsA("RemoteEvent") then
        remote:FireServer(...)
    end
end
function Utils:Random(tbl)
    local totalWeight = 0
    for _, v in ipairs(tbl) do
        totalWeight = totalWeight + v.Weight
    end
    local r = math.random() * totalWeight
    for _, v in ipairs(tbl) do
        r = r - v.Weight
        if r <= 0 then
            return v.Value
        end
    end
    return tbl[1].Value
end
function Utils:TimeToPosition(distanceVector, velocityVector)
    if velocityVector.Magnitude == 0 then return math.huge end
    return distanceVector.Magnitude / velocityVector.Magnitude
end

local Services = {
    Debris = Debris,
    CollectionService = CollectionService
}

local function TEMP_NO_VIRTUALIZE(f)
    return f
end

-- // MAIN SCRIPT LOGIC //
local State = {
    Local = {}
}
local Config = {
    Visualize = false
}

local RemotesFolder = ReplicatedStorage:WaitForChild("Remotes")
local PackagesFolder = ReplicatedStorage:WaitForChild("Packages")
local BallsFolder = Workspace.Balls
local Cooldown = PackagesFolder:WaitForChild("Cooldown")

local References = {
    Remotes = ReplicatedStorage:WaitForChild("Remotes"),
    Packages = ReplicatedStorage:WaitForChild("Packages"),
    Block = PlayerGui:WaitForChild("Hotbar"):WaitForChild("Block"),
    EffectScripts = ReplicatedStorage:WaitForChild("EffectScripts"),
    Collection = ReplicatedStorage:WaitForChild("Shared"):WaitForChild("SwordAPI"):WaitForChild("Collection")
}

local FX = {
    ClientFX = References.EffectScripts:WaitForChild("ClientFX")
}

local RemoteSignals = {
    RagingAttempt = References.Remotes.PlrRagingDeflectiond,
    RaptureAttempt = References.Remotes.PlrRaptured,
    RagingSuccessAll = References.Remotes.RagingSuccessAll,
    RaptureSuccessAll = References.Remotes.RaptureSuccess2,
    AbilityButtonPress = References.Remotes.AbilityButtonPress,
    BallAdded = References.Remotes.BallAdded,
    BallRemoved = References.Remotes.BallRemoved,
    Killed = References.Remotes.Killed,
    ParryAttemptAll = References.Remotes.ParryAttemptAll,
    ParrySuccessAll = References.Remotes.ParrySuccessAll,
    UnParry = References.Remotes.UnParry,
    PlrDashed = References.Remotes.PlrDashed,
    PlrPulled = References.Remotes.PlrPulled,
    EndCD = References.Remotes.EndCD
}

local SignalWrapper = setmetatable({}, {
    __newindex = function(t, k, v)
        rawset(t, k, {
            ["Signal"] = v,
            ["Disconnect"] = function(self)
                v:Disconnect()
                rawset(t, k, nil)
            end
        })
    end
})

local Logic = {}

Logic.Alive = TEMP_NO_VIRTUALIZE(function(self, plr)
    local char = Workspace.Alive:FindFirstChild(plr.Name)
    local hum = char and char:FindFirstChildWhichIsA("Humanoid")
    return hum and (hum.Health > 0)
end)

Logic.IsInvisible = TEMP_NO_VIRTUALIZE(function(self, model)
    for _, part in pairs(model:GetChildren()) do
        if part:IsA("BasePart") and part.Transparency < 0.95 then
            return false
        end
    end
    return true
end)

Logic.MouseNearestPlayer = TEMP_NO_VIRTUALIZE(function(self, mousePos)
    local result = { Object = nil, Distance = math.huge }
    for _, char in pairs(Workspace.Alive:GetChildren()) do
        local root = Logic:Alive(char) and Utils:GetHumanoidRootPart(char) or char
        if char ~= LocalPlayer.Character and root and root:IsA("BasePart") and not Logic:IsInvisible(char) then
            local dist = (root.Position - mousePos).Magnitude
            if dist < result.Distance then
                result.Distance = dist
                result.Object = root
            end
        end
    end
    return result.Object
end)

Logic.Mouse2DNearestPlayer = TEMP_NO_VIRTUALIZE(function(self, screenPos)
    local result = { Object = nil, Distance = math.huge }
    for _, char in pairs(Workspace.Alive:GetChildren()) do
        local root = Logic:Alive(char) and Utils:GetHumanoidRootPart(char) or char
        if char ~= LocalPlayer.Character and root and root:IsA("BasePart") and not Logic:IsInvisible(char) then
            local pos, visible = Camera:WorldToScreenPoint(root.Position)
            local charScreenPos = Vector2.new(pos.X, pos.Y)
            local dist = (charScreenPos - screenPos).Magnitude
            if dist < result.Distance and visible then
                result.Distance = dist
                result.Object = char
            end
        end
    end
    return result.Object
end)

Logic.NearestPlayer = TEMP_NO_VIRTUALIZE(function(self, pos)
    local result = { Object = nil, Distance = math.huge }
    for _, char in pairs(Workspace.Alive:GetChildren()) do
        local root = Logic:Alive(char) and Utils:GetHumanoidRootPart(char) or char
        if char ~= LocalPlayer.Character and root and root:IsA("BasePart") and not Logic:IsInvisible(char) then
            local dist = (pos - root.Position).Magnitude
            if dist < result.Distance then
                result.Distance = dist
                result.Object = char
            end
        end
    end
    return result.Object
end)

Logic.FurthestPlayer = TEMP_NO_VIRTUALIZE(function(self, pos)
    local result = { Object = nil, Distance = -math.huge }
    for _, char in pairs(Workspace.Alive:GetChildren()) do
        local root = Logic:Alive(char) and Utils:GetHumanoidRootPart(char) or char
        if char ~= LocalPlayer.Character and root and root:IsA("BasePart") and not Logic:IsInvisible(char) then
            local dist = (pos - root.Position).Magnitude
            if dist > result.Distance then
                result.Distance = dist
                result.Object = char
            end
        end
    end
    return result.Object
end)

Logic.WeakestPlayer = TEMP_NO_VIRTUALIZE(function(self)
    local result = { Object = nil, Distance = math.huge }
    for _, plr in pairs(Players:GetPlayers()) do
        if plr ~= LocalPlayer then
            local data = { Player = Utils:GetHumanoidRootPart(plr) }
            if data.Player and data.Player.RootPart and not Logic:IsInvisible(plr.Character) then
                local leaderstats = plr:FindFirstChild("leaderstats")
                local kills = leaderstats and leaderstats:FindFirstChild("Kills")
                local val = kills and kills.Value
                if val and val < result.Distance and Logic:Alive(plr) then
                    result.Distance = val
                    result.Object = plr
                end
            end
        end
    end
    return result.Object
end)

Logic.StrongestPlayer = TEMP_NO_VIRTUALIZE(function(self)
    local result = { Object = nil, Distance = -math.huge }
    for _, plr in pairs(Players:GetPlayers()) do
        if plr ~= LocalPlayer then
            local data = { Player = Utils:GetHumanoidRootPart(plr) }
            if data.Player and data.Player.RootPart and not Logic:IsInvisible(plr.Character) then
                local leaderstats = plr:FindFirstChild("leaderstats")
                local kills = leaderstats and leaderstats:FindFirstChild("Kills")
                local val = kills and kills.Value
                if val and val > result.Distance and Logic:Alive(plr) then
                    result.Distance = val
                    result.Object = plr
                end
            end
        end
    end
    return result.Object
end)

Logic.Angle = TEMP_NO_VIRTUALIZE(function(self, mode, target)
    local data = { LocalPlayer = Utils:GetHumanoid(LocalPlayer.Character) }
    local cf
    local diff
    if not target then
        if data.LocalPlayer and data.LocalPlayer.RootPart then
            target = data.LocalPlayer.RootPart
        end
    end
    if target then
        diff = (target.CFrame.Position - Camera.CFrame.Position)
    end
    if mode == "Default" then
        cf = Camera.CFrame
    elseif mode == "Backward" and target then
        local p = target.CFrame.Position + Vector3.new(-diff.X, 0, -diff.Z)
        cf = CFrame.lookAt(target.CFrame.Position, p)
    elseif mode == "Forward" and target then
        local p = target.CFrame.Position + Vector3.new(diff.X, 0, diff.Z)
        cf = CFrame.lookAt(target.CFrame.Position, p)
    elseif mode == "Upward" and target then
        local p = target.CFrame.Position + Vector3.new(0, 1, 0)
        cf = CFrame.lookAt(target.CFrame.Position, p)
    elseif mode == "Downward" and target then
        local p = target.CFrame.Position + Vector3.new(0, -1.0, 0)
        cf = CFrame.lookAt(target.CFrame.Position, p)
    elseif mode == "Reverse" and target then
        local p = target.CFrame.Position + Vector3.new(-diff.X, -diff.Y, -diff.Z)
        cf = CFrame.lookAt(target.CFrame.Position, p)
    elseif mode == "Verse" and target then
        local p = target.CFrame.Position + Vector3.new(diff.X, diff.Y, diff.Z)
        cf = CFrame.lookAt(target.CFrame.Position, p)
    elseif mode == "Adaptive" and target then
        local dot = Utils:TowardsPosition(target.Position, data.LocalPlayer.RootPart.Position, data.LocalPlayer.MoveDirection)
        if dot >= 0 then
            cf = Logic:Angle("Forward", target)
        elseif dot <= 0 then
            cf = Logic:Angle("Backward", target)
        end
    elseif mode == "Random" and target then
        local choices = {
            { Value = Logic:Angle("Forward", target), Weight = 60 },
            { Value = Logic:Angle("Backward", target), Weight = 30 },
            { Value = Logic:Angle("Upward", target), Weight = 10 }
        }
        cf = Utils:Random(choices)
    end
    if not cf then cf = Camera.CFrame end
    return cf
end)

Logic.Untarget = TEMP_NO_VIRTUALIZE(function(self, obj, _)
    local body = obj:IsA("Model") and obj:FindFirstChild("Body")
    if body then
        if body.BrickColor.Number == 331 and not obj:GetAttribute("realBall") then
            obj.Color = Color3.fromRGB(127, 127, 127)
            return
        end
    end
end)

Logic.Target = TEMP_NO_VIRTUALIZE(function(self, obj, _)
    local body = obj:IsA("Model") and obj:FindFirstChild("Body")
    if body then
        if body.BrickColor.Number == 331 and not obj:GetAttribute("realBall") then
            return true
        end
    end
end)

Logic.QuadBezier = TEMP_NO_VIRTUALIZE(function(self, t, p0, p1, p2)
    local l1 = p0:Lerp(p1, t)
    local l2 = p1:Lerp(p2, t)
    return l1:Lerp(l2, t)
end)

Logic.CubicBezier = TEMP_NO_VIRTUALIZE(function(self, t, p0, p1, p2, p3)
    local q1 = Logic:QuadBezier(t, p0, p1, p2)
    local q2 = Logic:QuadBezier(t, p1, p2, p3)
    return q1:Lerp(q2, t)
end)

Logic.VisualizeBall = TEMP_NO_VIRTUALIZE(function(self, ball, info)
    if Config.Visualize then
        local visual = ball:Clone()
        for _, child in pairs(visual:GetChildren()) do child:Destroy() end
        visual.Size = info.Size or ball.Size
        visual.Transparency = info.Transparency
        visual.Color = info.Color
        visual.Anchored = true
        visual.Velocity = Vector3.zero
        visual.AssemblyLinearVelocity = Vector3.zero
        visual.AssemblyAngularVelocity = Vector3.zero
        visual.Position = Vector3.new(info.Position.X, math.clamp(info.Position.Y, ball:GetAttribute("minHeight"), math.huge), info.Position.Z)
        visual.Parent = State.VisualBalls
        if info.Cache then return visual end
        Services.Debris:AddItem(visual, info.Duration)
    end
end)

Logic.RealBall = TEMP_NO_VIRTUALIZE(function(self, specificBall)
    local function SetupBall(obj)
        local BallClass = {}
        local instance = setmetatable({
            Object = obj, Target = LocalPlayer, TargetCount = 0,
            ZoomiesVelocity = Vector3.zero, Velocity = Vector3.zero, Position = Vector3.zero,
            LastPosition = Vector3.zero, LastZoomiesVelocity = Vector3.zero, LastVelocity = Vector3.zero,
            HighestVelocity = Vector3.zero, LastParriedVelocity = Vector3.zero,
            FluctuationLastVelocity = Vector3.zero, FluctuateBallLastPosition = Vector3.zero,
            ZoomiesFluctuateBallLastPosition = Vector3.zero, FluctuationVelocity = Vector3.zero,
            ZoomiesFluctuationVelocity = Vector3.zero, FluctuationZoomiesVelocity = Vector3.zero,
            ZoomiesFluctuationZoomiesVelocity = Vector3.zero, Parried = false, InitialDot = 0,
            Dot = -1.0, FluctuationDot = -1.0, ZoomiesFluctuationDot = -1.0, ZoomiesDot = -1.0,
            FluctuationZoomiesDot = -1.0, ZoomiesFluctuationZoomiesDot = -1.0, DotTarget = -1.0,
            LastDot = -1.0, AntiCurve = true, TargetInterval = os.clock(), LastTargetInterval = 0, Animators = {}
        }, { BallClass == BallClass })
        
        local connections = {}
        local function Cleanup()
            if State.Parried[instance] then
                State.ParryAmount = State.ParryAmount - 1
                State.Parried[instance] = nil
            end
            State.RealBall = nil
            for idx, conn in pairs(connections) do
                conn:Disconnect()
                connections[idx] = nil
            end
        end

        instance.Model = obj:IsA("Model") and obj
        local whitelist = instance.Model and obj:WaitForChild("CollisionWhitelist")
        instance.IsReal = obj:GetAttribute("realBall") == true

        instance.SetParry = function(self, val, reason)
            instance.Parried = val
            if not val then
                instance.PreviousDistanceFromTarget = nil
                instance.PreviousDot = nil
            end
        end

        local targetHistory = {}
        local function UpdateTargets()
            table.insert(targetHistory, instance.Target)
            local prevTarget = targetHistory[#targetHistory - 1]
            if instance.Target ~= prevTarget or instance.TargetCount >= 1 then
                instance:SetParry(false, "Target")
                instance.InitialDot = 0.75
                instance.TargetCount = 0
                instance.LastTarget = prevTarget
                instance.ZoomiesFluctuated = false
                instance.Fluctuated = false
                instance.ZoomiesParryable = false
                instance.Parryable = false
                instance.DebounceZoomiesDecreaseParryable = false
                instance.ZoomiesDecreaseParryable = false
                instance.DecreaseParryable = false
                instance.ZoomiesProressionTimestamp = nil
                instance.ZoomiesProgressionParryable = false
                instance.ProgressionParryable = false
                instance.VelocityThreshold = nil
                instance.PreviousDistanceFromTarget = nil
                instance.PreviousDot = nil

                if #targetHistory > 2 then table.remove(targetHistory, #targetHistory - 2) end
                if instance.Target ~= LocalPlayer then
                    instance.LastActualTarget = instance.Target
                else
                    instance.TargetInterval = os.clock() - instance.LastTargetInterval
                    instance.LastTargetInterval = os.clock()
                end
                instance.LastParriedVelocity = instance.Velocity
                instance.TargetFrequency = instance.LastTargeted and os.clock() - instance.LastTargeted
                instance.LastTargeted = os.clock()
            else
                table.remove(targetHistory, #targetHistory)
                instance.TargetCount = instance.TargetCount + 1
            end
        end

        if not whitelist then
            local targetAttr, fromAttr = obj:GetAttribute("target"), obj:GetAttribute("from")
            if targetAttr then
                instance.Target = Players:FindFirstChild(targetAttr) or Workspace.Alive:FindFirstChild(targetAttr)
                instance.TargetAlive = Workspace.Alive:FindFirstChild(targetAttr)
            end
            if fromAttr then
                instance.From = Players:FindFirstChild(fromAttr) or Workspace.Alive:FindFirstChild(fromAttr)
                instance.FromAlive = Workspace.Alive:FindFirstChild(fromAttr)
            end
            connections[#connections + 1] = obj.AttributeChanged:Connect(function()
                local t, f = obj:GetAttribute("target"), obj:GetAttribute("from")
                if t then
                    instance.Target = Players:FindFirstChild(t) or Workspace.Alive:FindFirstChild(t)
                    instance.TargetAlive = Workspace.Alive:FindFirstChild(t)
                end
                if f then
                    instance.From = Players:FindFirstChild(f) or Workspace.Alive:FindFirstChild(f)
                    instance.FromAlive = Workspace.Alive:FindFirstChild(f)
                end
                UpdateTargets()
            end)

            task.spawn(function()
                repeat
                    for _, child in pairs(obj:GetChildren()) do
                        if child:IsA("LinearVelocity") then
                            if child.Name == "zoomies" then
                                instance.Zoomies = child
                                child:GetPropertyChangedSignal("VectorVelocity"):Connect(function() instance.Zoomies = child end)
                            end
                        end
                    end
                    task.wait()
                until instance.Zoomies
            end)
        elseif whitelist then
            instance.Target = Players:FindFirstChild(whitelist.Value.Name) or Workspace.Alive:FindFirstChild(whitelist.Value.Name)
            connections[#connections + 1] = whitelist:GetPropertyChangedSignal("Value"):Connect(function()
                instance.Target = Players:FindFirstChild(whitelist.Value.Name) or Workspace.Alive:FindFirstChild(whitelist.Value.Name)
                UpdateTargets()
            end)
        end

        instance.StopInterval = nil
        instance.Stopped = false
        instance.Interrupted = false

        local function RenderLoop(dt)
            local ping
            pcall(function() ping = (LocalPlayer:GetNetworkPing() * 2) or (game.Stats.Network.ServerStatsItem["Data Ping"]:GetValue() / 1000) end)
            if not ping then ping = 0.05 end

            local Humanoids = { LocalPlayer = Utils:GetHumanoid(LocalPlayer.Character) }
            Humanoids.Target = Utils:GetHumanoid(instance.Target)
            Humanoids.LastTarget = Utils:GetHumanoid(instance.LastTarget)
            Humanoids.LastActualTarget = Utils:GetHumanoid(instance.LastActualTarget)

            if Humanoids.Target and Humanoids.Target.RootPart and Humanoids.LastTarget and Humanoids.LastTarget.RootPart then
                local dir = Utils:TowardsPosition(Humanoids.Target.RootPart.Position, Humanoids.LastTarget.RootPart.Position, Humanoids.LastTarget.MoveDirection)
                instance.MoveDirectionToTarget = dir
            end

            if Humanoids.LocalPlayer and Humanoids.LocalPlayer.RootPart and instance.Object and instance.Object:GetAttribute("realBall") and instance.Object.Parent then
                instance.Position = (instance.Model and instance.Object:GetPivot().Position or instance.Object.Position)
                instance.ZoomiesVelocity = instance.Zoomies and instance.Zoomies.VectorVelocity or Vector3.zero
                instance.Velocity = (instance.Model and instance.Object:GetAttribute("Velocity") or instance.Object.Velocity)
                instance.ZoomiesDot = Utils:TowardsPosition(Humanoids.LocalPlayer.RootPart.Position, instance.Position, instance.ZoomiesVelocity)
                instance.Dot = Utils:TowardsPosition(Humanoids.LocalPlayer.RootPart.Position, instance.Position, instance.Velocity)

                if instance.Dot >= 0 and instance.LastDot >= 0 then instance.DotInterval = instance.Dot - instance.LastDot end
                if instance == State.RealBall then State.RealBall = nil end

                local function UpdateZoomiesFluctuation()
                    instance.ZoomiesFluctuated = true
                    instance.ZoomiesFluctuationDot = instance.Dot
                    instance.ZoomiesFluctuationZoomiesDot = instance.ZoomiesDot
                    instance.ZoomiesFluctuationVelocity = instance.Velocity
                    instance.ZoomiesFluctuationZoomiesVelocity = instance.ZoomiesVelocity
                    instance.ZoomiesFluctuationLastVelocity = instance.LastVelocity
                    instance.ZoomiesFluctuationLastZoomiesVelocity = instance.LastZoomiesVelocity
                    instance.ZoomiesFluctuationDistance = (instance.ZoomiesFluctuateBallLastPosition - instance.Position)
                    instance.ZoomiesFluctuateDistance = (Humanoids.LocalPlayer.RootPart.Position - instance.Position)
                    instance.ZoomiesFluctuateBallLastPosition = instance.Position
                end

                local function UpdateFluctuation()
                    instance.Fluctuated = true
                    instance.FluctuationDot = instance.Dot
                    instance.FluctuationZoomiesDot = instance.ZoomiesDot
                    instance.FluctuationVelocity = instance.Velocity
                    instance.FluctuationZoomiesVelocity = instance.ZoomiesVelocity
                    instance.FluctuationLastVelocity = instance.LastVelocity
                    instance.FluctuationLastZoomiesVelocity = instance.LastZoomiesVelocity
                    instance.FluctuationDistance = (instance.FluctuateBallLastPosition - instance.Position)
                    instance.FluctuateDistance = (Humanoids.LocalPlayer.RootPart.Position - instance.Position)
                    instance.FluctuateBallLastPosition = instance.Position
                end

                if instance.ZoomiesFluctuated and instance.ZoomiesProgressionParryable and not instance.ZoomiesDecreaseParryable then
                    if ((instance.ZoomiesVelocity.Magnitude - instance.LastZoomiesVelocity.Magnitude) < instance.LastZoomiesVelocity.Magnitude * -0.0125) or (instance.ZoomiesProressionTimestamp and os.clock() - instance.ZoomiesProressionTimestamp >= 0.175) or ((function()
                        local dist = (Humanoids.LocalPlayer.RootPart.Position - instance.Position).Magnitude
                        if dist <= instance.Velocity.Magnitude * ((ping + dt) * 3) then return true end
                    end)()) then
                        if not instance.DebounceZoomiesDecreaseParryable then
                            task.spawn(function()
                                instance.DebounceZoomiesDecreaseParryable = true
                                instance.DebounceZoomiesDecreaseParryable = false
                                instance.ZoomiesDecreaseParryable = true
                                if Config.Visualize then
                                    if Humanoids.Target and Humanoids.Target.RootPart and Humanoids.LastTarget and Humanoids.LastTarget.RootPart then
                                        local loopId = {}
                                        State.VisualBallsLoopId3 = loopId
                                        local p0, p1, p2 = Humanoids.LastTarget.RootPart.Position, instance.Position + (instance.ZoomiesVelocity * (0.225 + (ping + dt))), Humanoids.Target.RootPart.Position
                                        for i = 65.0, 96 do
                                            local t = (i - 64) / 32.0
                                            local pos = Logic:QuadBezier(t, p0, p1, p2)
                                            if State.VisualBallsCache[i] then
                                                State.VisualBallsCache[i].Transparency = instance.Target == LocalPlayer and 0 or 0.8
                                                State.VisualBallsCache[i].Position = Vector3.new(pos.X, math.clamp(pos.Y, obj:GetAttribute("minHeight"), math.huge), pos.Z)
                                                task.spawn(function()
                                                    local timer = Utils:Timer(1)
                                                    while not timer() do if loopId ~= State.VisualBallsLoopId3 then break end task.wait() end
                                                    if timer() then State.VisualBallsCache[i].Transparency = 1 end
                                                end)
                                            else
                                                State.VisualBallsCache[i] = Logic:VisualizeBall(obj, { Cache = true, Transparency = instance.Target == LocalPlayer and 0 or 0.8, Position = pos, Size = Vector3.new(1, 1, 1), Color = Color3.fromRGB(0, 0, 0) })
                                            end
                                        end
                                    end
                                    local vizPos = instance.Position + (instance.ZoomiesVelocity * (0.225 + (ping + dt)))
                                    Logic:VisualizeBall(obj, { Duration = 1, Transparency = instance.Target == LocalPlayer and 0 or 0.8, Position = vizPos, Size = Vector3.new(3, 3, 3), Color = Color3.fromRGB(0, 254, 220) })
                                end
                            end)
                        end
                    end
                end

                if instance.ZoomiesFluctuated and not instance.ZoomiesProgressionParryable then
                    if (instance.ZoomiesVelocity.Magnitude - instance.LastZoomiesVelocity.Magnitude) > instance.ZoomiesFluctuationLastZoomiesVelocity.Magnitude * -0.05 then
                        instance.ZoomiesProgressionParryable = true
                        instance.ZoomiesProressionTimestamp = os.clock()
                        instance.ZoomiesProgressionDot = instance.Dot
                        instance.ZoomiesProgressionZoomiesDot = instance.ZoomiesDot
                        instance.ZoomiesProgressionVelocity = instance.Velocity
                        instance.ZoomiesProgressionZoomiesVelocity = instance.ZoomiesVelocity
                        if Config.Visualize then
                            if Humanoids.Target and Humanoids.Target.RootPart and Humanoids.LastTarget and Humanoids.LastTarget.RootPart then
                                local loopId = {}
                                State.VisualBallsLoopId1 = loopId
                                local p0, p1, p2 = Humanoids.LastTarget.RootPart.Position, instance.Position + (instance.ZoomiesVelocity * (0.225 + (ping + dt))), Humanoids.Target.RootPart.Position
                                for i = 1.0, 32 do
                                    local t = (i - 0) / 32.0
                                    local pos = Logic:QuadBezier(t, p0, p1, p2)
                                    if State.VisualBallsCache[i] then
                                        State.VisualBallsCache[i].Transparency = instance.Target == LocalPlayer and 0 or 0.8
                                        State.VisualBallsCache[i].Position = Vector3.new(pos.X, math.clamp(pos.Y, obj:GetAttribute("minHeight"), math.huge), pos.Z)
                                        task.spawn(function()
                                            local timer = Utils:Timer(1)
                                            while not timer() do if loopId ~= State.VisualBallsLoopId1 then break end task.wait() end
                                            if timer() then State.VisualBallsCache[i].Transparency = 1 end
                                        end)
                                    else
                                        State.VisualBallsCache[i] = Logic:VisualizeBall(obj, { Cache = true, Transparency = instance.Target == LocalPlayer and 0 or 0.8, Position = pos, Size = Vector3.new(1, 1, 1), Color = Color3.fromRGB(254, 0, 254) })
                                    end
                                end
                            end
                            local vizPos = instance.Position + (instance.ZoomiesVelocity * (0.225 + (ping + dt)))
                            Logic:VisualizeBall(obj, { Duration = 1, Transparency = instance.Target == LocalPlayer and 0 or 0.8, Position = vizPos, Size = Vector3.new(3, 3, 3), Color = Color3.fromRGB(254, 254, 0) })
                        end
                    end
                end

                if instance.Fluctuated and not instance.ProgressionParryable then
                    if (instance.Velocity.Magnitude - instance.LastVelocity.Magnitude) > 0 then
                        instance.ProgressionParryable = true
                        instance.ProgressionDot = instance.Dot
                        instance.ProgressionZoomiesDot = instance.ZoomiesDot
                        instance.ProgressionVelocity = instance.Velocity
                        instance.ProgressionZoomiesVelocity = instance.ZoomiesVelocity
                    end
                end

                if not instance.ZoomiesFluctuated then
                    if ((instance.ZoomiesVelocity.Magnitude - instance.LastZoomiesVelocity.Magnitude) <= (instance.LastZoomiesVelocity.Magnitude * -0.0)) or ((function()
                        if instance.Target ~= LocalPlayer and Humanoids.Target and Humanoids.Target.RootPart then
                            local dist = (Humanoids.Target.RootPart.Position - instance.Position).Magnitude
                            if dist <= 17 then return true end
                        end
                        if instance.LastTarget ~= LocalPlayer and Humanoids.LastTarget and Humanoids.LastTarget.RootPart then
                            local dist = (Humanoids.LastTarget.RootPart.Position - instance.Position).Magnitude
                            if dist <= 17 then return true end
                        end
                    end)()) or not instance.LastActualTarget then
                        UpdateZoomiesFluctuation()
                        if Config.Visualize then
                            if Humanoids.Target and Humanoids.Target.RootPart and Humanoids.LastTarget and Humanoids.LastTarget.RootPart then
                                local loopId = {}
                                State.VisualBallsLoopId2 = loopId
                                local p0, p1, p2 = Humanoids.LastTarget.RootPart.Position, instance.Position + (instance.ZoomiesVelocity * (0.225 + (ping + dt))), Humanoids.Target.RootPart.Position
                                for i = 33.0, 64 do
                                    local t = (i - 32) / 32.0
                                    local pos = Logic:QuadBezier(t, p0, p1, p2)
                                    if State.VisualBallsCache[i] then
                                        State.VisualBallsCache[i].Transparency = instance.Target == LocalPlayer and 0 or 0.8
                                        State.VisualBallsCache[i].Position = Vector3.new(pos.X, math.clamp(pos.Y, obj:GetAttribute("minHeight"), math.huge), pos.Z)
                                        task.spawn(function()
                                            local timer = Utils:Timer(1)
                                            while not timer() do if loopId ~= State.VisualBallsLoopId2 then break end task.wait() end
                                            if timer() then State.VisualBallsCache[i].Transparency = 1 end
                                        end)
                                    else
                                        State.VisualBallsCache[i] = Logic:VisualizeBall(obj, { Cache = true, Transparency = instance.Target == LocalPlayer and 0 or 0.8, Position = pos, Size = Vector3.new(1, 1, 1), Color = Color3.fromRGB(254, 0, 0) })
                                    end
                                end
                            end
                            local vizPos = instance.Position + (instance.ZoomiesVelocity * (0.225 + (ping + dt)))
                            Logic:VisualizeBall(obj, { Duration = 1, Transparency = instance.Target == LocalPlayer and 0 or 0.8, Position = vizPos, Size = Vector3.new(3, 3, 3), Color = Color3.fromRGB(0, 254, 0) })
                        end
                    end
                end

                if not instance.Fluctuated then
                    if (instance.Velocity.Magnitude - instance.LastVelocity.Magnitude <= instance.LastVelocity.Magnitude * -0.0) or ((function()
                        if instance.Target ~= LocalPlayer and Humanoids.Target and Humanoids.Target.RootPart then
                            local dist = (Humanoids.Target.RootPart.Position - instance.Position).Magnitude
                            if dist <= 17 then return true end
                        end
                        if instance.LastTarget ~= LocalPlayer and Humanoids.LastTarget and Humanoids.LastTarget.RootPart then
                            local dist = (Humanoids.LastTarget.RootPart.Position - instance.Position).Magnitude
                            if dist <= 17 then return true end
                        end
                    end)()) or not instance.LastActualTarget then
                        UpdateFluctuation()
                        if Config.Spam then State.Exchanges = State.Exchanges + 1 else State.Exchanges = 0 end
                    end
                end

                if instance.Velocity.Magnitude > instance.HighestVelocity.Magnitude then instance.HighestVelocity = instance.Velocity end
                if Humanoids.Target then
                    instance.DistanceFromTarget = (Humanoids.Target.RootPart.Position - instance.Position).Magnitude
                    instance.DotTarget = Utils:TowardsPosition(Humanoids.Target.RootPart.Position, instance.Position, instance.Velocity)
                end
                if Humanoids.LastTarget then instance.DistanceFromLastTarget = (Humanoids.LastTarget.RootPart.Position - instance.Position).Magnitude end
                if Humanoids.LastActualTarget then instance.DistanceFromLastActualTarget = (Humanoids.LastActualTarget.RootPart.Position - instance.Position).Magnitude end

                if instance.Target == LocalPlayer then
                    if instance.DistanceFromTarget < (instance.PreviousDistanceFromTarget or math.huge) then
                        instance.PreviousDistanceFromTarget = instance.DistanceFromTarget
                        instance.Approaching = true
                    else
                        instance.Approaching = false
                    end
                    if instance.Dot > (instance.PreviousDot or 0) then
                        instance.PreviousDot = instance.PreviousDot
                        instance.Approaching = true
                    end
                    if not State.RealBall then
                        if instance.IsReal then State.RealBall = instance end
                    else
                        if State.RealBall.Target ~= LocalPlayer or instance.DistanceFromTarget < State.RealBall.DistanceFromTarget then
                            if instance.IsReal then State.RealBall = instance end
                        end
                    end
                end

                if not Config.AwaitParry then
                    Config.AwaitParry = true
                    if instance.Target and instance.Target ~= LocalPlayer and ((Humanoids.LocalPlayer.RootPart.Position - instance.Position).Magnitude <= 10 and instance.DistanceFromTarget and instance.DistanceFromTarget <= 10) then end
                    Config.AwaitParry = false
                end

                instance.LastPosition = instance.Position
                instance.LastDot = instance.Dot
                instance.LastZoomiesVelocity = instance.ZoomiesVelocity
                instance.LastVelocity = instance.Velocity
            else
                Cleanup()
            end
        end
        connections[#connections + 1] = RunService.PreRender:Connect(RenderLoop)
        connections[#connections + 1] = obj.Destroying:Connect(function() Cleanup() end)
        return instance
    end

    if specificBall then
        if specificBall:GetAttribute("realBall") == true then return SetupBall(specificBall) end
    else
        for _, ball in pairs(BallsFolder:GetChildren()) do
            if ball:GetAttribute("realBall") == true then return SetupBall(ball) end
        end
    end
end)

Logic.DynamicDistance = TEMP_NO_VIRTUALIZE(function(self, dist)
    local factor = 1 + dist * 1 * 0.008
    return math.max(20, math.min(120, 20 * factor))
end)

Logic.PlayersScreenPoint = TEMP_NO_VIRTUALIZE(function(self)
    local points = {}
    for _, char in pairs(Workspace.Alive:GetChildren()) do
        local root = Utils:GetHumanoidRootPart(char)
        if root then points[char.Name] = Camera:WorldToScreenPoint(root.Position) end
    end
    return points
end)

Logic.BlockButton = TEMP_NO_VIRTUALIZE(function(self)
    local hotbar = PlayerGui:FindFirstChild("Hotbar")
    return hotbar and hotbar:FindFirstChild("Block")
end)

Logic.AbilityButton = TEMP_NO_VIRTUALIZE(function(self)
    local hotbar = PlayerGui:FindFirstChild("Hotbar")
    return hotbar and hotbar:FindFirstChild("Ability")
end)

-- Config Init
if not (isfile("Infinixity") or isfolder("Infinixity")) then makefolder("Infinixity") end
local ConfigPath = ("%s/Blade_Ball"):format("Infinixity")
if not (isfile(ConfigPath) or isfolder(ConfigPath)) then makefolder(ConfigPath) end

local SettingsData = {
    Info = { ["Version"] = "2.0.0" },
    Toggle = {
        ["Optimize"] = false, ["Visualize"] = false, ["Auto-Config"] = false,
        ["Auto-Counter"] = true, ["Auto-Parry"] = true, ["Auto-Spam-Parry"] = true,
        ["Hook-Parry"] = true, ["Anti-Curve"] = false, ["Can-Collide"] = true,
        ["Visualize-Path"] = true, ["Unlock-FPS"] = true, ["Safety-Mode"] = true,
        ["Fast-Mode"] = true, ["Beast-Mode"] = false, ["Aim-Camera"] = false,
        ["Block-Spam-Parry"] = true, ["Curve-Ball"] = true, ["Hide-Button"] = false,
        ["Debug-Mode"] = true
    },
    Dropdown = {
        ["Targeting-Mode"] = "Nearest to Screen Center",
        ["Block-Mode"] = "Hold",
        ["Curving-Mode"] = "Adaptive"
    },
    Slider = {
        ["Range"] = 0.15, ["Direct-Point"] = -1.0, ["Spam-Distance"] = 17.5,
        ["Spam-Iteration"] = 2, ["Spam-Time-Threshold"] = 0.3
    },
    Input = { ["Block-Keybind"] = "V" }
}

if isfile(ConfigPath .. "/config.json") then
    local loaded = HttpService:JSONDecode(readfile(ConfigPath .. "/config.json"))
    if loaded.Info and loaded.Info.Version and loaded.Info.Version == SettingsData.Info.Version then
        for k, v in pairs(loaded) do
            for key, val in pairs(v) do
                if type(SettingsData[k]) == "table" then SettingsData[k][key] = val end
            end
        end
    end
end

local GUI = {}
State.VisualBalls = Instance.new("Folder")
State.VisualBalls.Name = "VisualBalls"
State.VisualBalls.Parent = Workspace
State.VisualBallsCache = {}

State.ParryAttemptKey = nil
if getgc and getgc() then
    for _, v in pairs(getgc()) do
        if type(v) == "function" then
            local info = debug.info(v, "slnaf")
            if info and info:match("SwordsController") then
                local upvals = debug.getupvalues(v)
                for _, uv in pairs(upvals) do
                    if uv[19] and typeof(uv[19]) == "Instance" then
                        State.ParryAttemptKey = uv[17]
                        RemoteSignals.ParryAttempt = uv[18]
                    end
                end
            end
        end
    end
end

if typeof(State.ParryAttemptKey) ~= "string" and typeof(RemoteSignals.ParryAttempt) ~= "Instance" then
    OrionLib:MakeNotification({
        Name = ("%s"):format(NotifyName),
        Content = "Executor does not support function.",
        Image = "rbxassetid://4483345998",
        Time = 15
    })
    return
end

while not RemoteSignals.ParryAttempt do task.wait() end

State.AliveData = {}
State.Exchanges = 0
State.ParryAmount = 0
State.Parried = {}
State.BallCount = 0
State.Balls = {}
State.TargetInterval = os.clock()
State.LastTargetInterval = os.clock()
State.DecrementRange = 0

Workspace.Runtime.ChildAdded:Connect(TEMP_NO_VIRTUALIZE(function(child)
    if SettingsData.Toggle["Optimize"] and child.Name == "clash" then
        game:GetService("Debris"):AddItem(child, 0)
    end
end))

local function RegisterBall(ball)
    if ball:GetAttribute("realBall") or ball:IsA("Model") then
        local obj = Logic:RealBall(ball)
        State.Balls[ball] = obj
        State.BallCount = State.BallCount + 1
        State.LocalParryFrequency = nil
        State.LocalLastParried = nil
        State.ClashParry = nil
        State.ParryFrequency = nil
        State.LastParried = nil
        ball.Destroying:Connect(function()
            State.Balls[ball] = nil
            State.BallCount = State.BallCount - 1
            State.LocalParryFrequency = nil
            State.LocalLastParried = nil
            State.ClashParry = nil
            if State.RealBall == obj then State.RealBall = nil end
        end)
    end
end

for _, b in pairs(BallsFolder:GetChildren()) do RegisterBall(b) end
BallsFolder.ChildAdded:Connect(TEMP_NO_VIRTUALIZE(function(b) RegisterBall(b) end))

CollectionService:GetInstanceAddedSignal("AerodynamicSlashTornado"):Connect(TEMP_NO_VIRTUALIZE(function(inst)
    for _, ballWrapper in pairs(State.Balls) do
        if ballWrapper and ballWrapper.Object then
            if ballWrapper.Object.Name == inst:GetAttribute("Ball") then
                table.insert(ballWrapper.Animators, inst)
                local idx = #ballWrapper.Animators
                task.delay(inst:GetAttribute("TornadoTime"), function() table.remove(ballWrapper.Animators, idx) end)
            end
        end
    end
end))

RemoteSignals.Killed.OnClientEvent:Connect(TEMP_NO_VIRTUALIZE(function(...) end))

RemoteSignals.ParrySuccessAll.OnClientEvent:Connect(TEMP_NO_VIRTUALIZE(function(ball, plr)
    local model = plr:FindFirstAncestorOfClass("Model") or plr:FindFirstAncestorOfClass("Actor")
    if model then
        local player = Players:FindFirstChild(model.Name) or model
        if player == LocalPlayer then
            State.LocalParryFrequency = State.LocalLastParried and os.clock() - State.LocalLastParried
            State.LocalLastParried = os.clock()
        end
        local data = State.AliveData[model]
        if data then
            data.ParryFrequency = data.LastParried and os.clock() - data.LastParried
            data.LastParried = os.clock()
        end
        State.ParryFrequency = State.LastParried and os.clock() - State.LastParried
        State.LastParried = os.clock()
    end
end))

RemoteSignals.EndCD.OnClientEvent:Connect(TEMP_NO_VIRTUALIZE(function(...)
    Config.Parry = false
    State.ClashParry = nil
    State.LocalParryFrequency = nil
    State.LocalLastParried = nil
    State.ParryFrequency = nil
    State.LastParried = nil
end))

Workspace.ChildAdded:Connect(TEMP_NO_VIRTUALIZE(function(child)
    if child.Name:lower() == "clash" and child:IsA("BasePart") then
        State.ClashObject = State.ClashObject and State.ClashObject + 1 or 1
        local conn
        conn = child.Destroying:Connect(function()
            if conn then conn:Disconnect() conn = nil end
            State.ClashObject = State.ClashObject and State.ClashObject - 1
            if State.ClashObject and State.ClashObject <= 0 then State.ClashObject = nil end
        end)
    end
end))

local function SetupAlive(child)
    if not State.AliveData[child] then State.AliveData[child] = { ParryFrequency = math.huge, LastParried = math.huge } end
end
local function RemoveAlive(child)
    if State.AliveData[child] then State.AliveData[child] = nil end
end

for _, c in pairs(Workspace.Alive:GetChildren()) do SetupAlive(c) end
Workspace.Alive.ChildAdded:Connect(SetupAlive)
Workspace.Alive.ChildRemoved:Connect(RemoveAlive)

loadstring(game:HttpGet("https://raw.githubusercontent.com/EdgeIY/infiniteyield/master/source"))()

-- // UI CONSTRUCTION (ORION) //
local Window = OrionLib:MakeWindow({Name = "Infinixity | Blade Ball", HidePremium = false, SaveConfig = true, ConfigFolder = "Infinixity"})

do
    -- // COMBAT TAB //
    local CombatTab = Window:MakeTab({
        Name = "Combat",
        Icon = "rbxassetid://4483345998",
        PremiumOnly = false
    })

    GUI.Combat = { Toggle = {}, Slider = {}, Dropdown = {}, Button = {} }

    GUI.Combat.Toggle["Optimize"] = CombatTab:AddToggle({
        Name = "Optimize",
        Default = SettingsData.Toggle["Optimize"],
        Callback = function(bool)
            SettingsData.Toggle["Optimize"] = bool
            if FX.ClientFX then FX.ClientFX.Enabled = not bool end
        end
    })

    GUI.Combat.Toggle["Visualize"] = CombatTab:AddToggle({
        Name = "Visualize",
        Default = SettingsData.Toggle["Visualize"],
        Callback = function(bool)
            SettingsData.Toggle["Visualize"] = bool
            Config.Visualize = bool
        end
    })

    GUI.Combat.Button["Parry"] = CombatTab:AddButton({
        Name = "Manual Parry",
        Callback = TEMP_NO_VIRTUALIZE(function()
            local ping
            pcall(function() ping = (LocalPlayer:GetNetworkPing() * 2) or (game.Stats.Network.ServerStatsItem["Data Ping"]:GetValue() / 1000) end)
            if not ping then ping = 0.05 end

            local Humanoids = { LocalPlayer = Utils:GetHumanoid(LocalPlayer.Character) }
            local realBall = State.RealBall
            local isSpamming = false
            local parryArgs = {}

            if State.Spamming then
                if State.ParryCache then
                    if State.ParryCacheTimestamp and (os.clock() - State.ParryCacheTimestamp <= 0.325) then
                        isSpamming = true
                        parryArgs = State.ParryCache
                    end
                end
            end

            local targetPlayer
            if not State.Dungeon then
                for _, v in pairs(Workspace.Map:GetChildren()) do
                    if v.Name:lower():match("^dungeon") then State.Dungeon = true break end
                end
            end

            if not isSpamming then
                if State.Dungeon then
                    parryArgs[1] = Camera.CFrame
                    parryArgs[2] = Mouse.Hit
                    parryArgs[3] = false
                else
                    parryArgs[1] = 0.5
                    parryArgs[2] = State.ParryAttemptKey
                    parryArgs[3] = 0.15
                    parryArgs[5] = Logic:PlayersScreenPoint()
                    parryArgs[7] = false

                    if Humanoids.LocalPlayer and Humanoids.LocalPlayer.RootPart then
                        if SettingsData.Dropdown["Targeting-Mode"] == "Nearest to Mouse" then
                            targetPlayer = Logic:Mouse2DNearestPlayer(Vector2.new(Mouse.X, Mouse.Y))
                        elseif SettingsData.Dropdown["Targeting-Mode"] == "Nearest to Screen Center" then
                            targetPlayer = Logic:Mouse2DNearestPlayer(Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y / 2))
                        elseif SettingsData.Dropdown["Targeting-Mode"] == "Last Targeted Player" then
                            if State.RealBall and State.RealBall.LastActualTarget then
                                targetPlayer = Utils:GetHumanoidRootPart(State.RealBall.LastActualTarget:IsA("Player") and State.RealBall.LastActualTarget.Character or State.RealBall.LastActualTarget)
                            end
                        elseif SettingsData.Dropdown["Targeting-Mode"] == "Nearest Player" then
                            targetPlayer = Logic:NearestPlayer(Humanoids.LocalPlayer.RootPart.Position)
                        elseif SettingsData.Dropdown["Targeting-Mode"] == "Furthest Player" then
                            targetPlayer = Logic:FurthestPlayer(Humanoids.LocalPlayer.RootPart.Position)
                        elseif SettingsData.Dropdown["Targeting-Mode"] == "Weakest Player" then
                            targetPlayer = Logic:WeakestPlayer()
                        elseif SettingsData.Dropdown["Targeting-Mode"] == "Strongest Player" then
                            targetPlayer = Logic:StrongestPlayer()
                        else
                            targetPlayer = Logic:Mouse2DNearestPlayer(Mouse.Position)
                        end
                    end

                    if targetPlayer then
                        local pos
                        local success, _ = pcall(function() return targetPlayer.Position end)
                        if not success then targetPlayer = Utils:GetHumanoidRootPart(targetPlayer) end
                        local screenPos = Camera:WorldToScreenPoint(targetPlayer.Position)
                        parryArgs[6] = { screenPos.X, screenPos.Y }
                    end

                    if not parryArgs[6] then parryArgs[6] = { Mouse.X, Mouse.Y } end
                    if SettingsData.Toggle["Curve-Ball"] then
                        parryArgs[4] = Logic:Angle(SettingsData.Dropdown["Curving-Mode"], targetPlayer)
                    else
                        parryArgs[4] = Camera.CFrame
                    end

                    Config.Parry = true
                    task.spawn(function()
                        local timer = Utils:Timer(0.8666666666666667)
                        repeat task.wait() until timer() or not Config.Parry
                        if Config.Parry then Config.Parry = false end
                    end)
                end
            end

            if Humanoids.LocalPlayer and Humanoids.LocalPlayer.RootPart then
                State.ParryCache = parryArgs
                State.ParryCacheTimestamp = os.clock()
                Utils:FireRemote(val, RemoteSignals.ParryAttempt, unpack(parryArgs))
            end
        end)
    })

    GUI.Combat.Toggle["Auto-Parry"] = CombatTab:AddToggle({
        Name = "Auto Parry",
        Default = SettingsData.Toggle["Auto-Parry"],
        Callback = function(bool)
            SettingsData.Toggle["Auto-Parry"] = bool
            if SignalWrapper["Auto-Parry"] then SignalWrapper["Auto-Parry"]:Disconnect() end
            local debounce = false
            SignalWrapper["Auto-Parry"] = RunService.PreRender:Connect(TEMP_NO_VIRTUALIZE(function(dt)
                if not SettingsData.Toggle["Auto-Parry"] then SignalWrapper["Auto-Parry"]:Disconnect() return end
                if debounce then return end
                local ping
                pcall(function() ping = (LocalPlayer:GetNetworkPing() * 2) or (game.Stats.Network.ServerStatsItem["Data Ping"]:GetValue() / 1000) end)
                if not ping then ping = 0.05 end
                local Humanoids = { LocalPlayer = Utils:GetHumanoid(LocalPlayer.Character) }
                local realBall = State.RealBall
                if Logic:Alive(LocalPlayer) and realBall and realBall.Object and realBall.Target == LocalPlayer and not realBall.Parried and realBall.Velocity.Magnitude >= 0 and #realBall.Animators <= 0 and Humanoids.LocalPlayer and LocalPlayer.Character.Parent == Workspace.Alive and ((realBall.ZoomiesFluctuated and ((function()
                    if realBall.ZoomiesDot >= 0 then
                        local dist = (Humanoids.LocalPlayer.RootPart.Position - realBall.Position).Magnitude
                        if dist <= math.clamp(realBall.Velocity.Magnitude, 17, 17) then return true end
                    end
                end)())) or (realBall.ZoomiesFluctuated and realBall.ZoomiesDecreaseParryable and ((function()
                    local function check(offset)
                        local direction = (Humanoids.LocalPlayer.RootPart.Position - realBall.Position)
                        local adjusted = direction - (direction.Unit * offset)
                        local time = Utils:TimeToPosition(adjusted, realBall.ZoomiesVelocity)
                        local toward = Utils:TowardsPosition(realBall.Position, Humanoids.LocalPlayer.RootPart.Position, Humanoids.LocalPlayer.MoveDirection)
                        local range = SettingsData.Slider["Range"] + (toward > 0 and toward * 0.05 or toward < 0 and toward * -0.05 or 0) + (LocalPlayer.Character:FindFirstChild("Titan Blade") and 0.1 or 0)
                        return time <= (range + (ping + dt))
                    end
                    return check(0) or check(17)
                end)()) and ((function()
                    local cond1 = realBall.Dot >= (SettingsData.Slider["Direct-Point"] - (ping + dt))
                    local cond2 = realBall.ZoomiesDot >= (1 - ((ping * 2) + dt))
                    return (cond1 and cond2) or nil
                end)()))) then
                    debounce = true
                    if GUI.Combat.Button["Parry"] then
                         local parryArgs = {
                             0.5, State.ParryAttemptKey, 0.15, Camera.CFrame, Logic:PlayersScreenPoint(), {Mouse.X, Mouse.Y}, false
                         }
                         if SettingsData.Toggle["Curve-Ball"] then
                            local targetPlayer = Logic:Mouse2DNearestPlayer(Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y / 2)) 
                            parryArgs[4] = Logic:Angle(SettingsData.Dropdown["Curving-Mode"], targetPlayer)
                         end
                         Utils:FireRemote(nil, RemoteSignals.ParryAttempt, unpack(parryArgs))
                    end
                    
                    realBall:SetParry(true, "Parry")
                    task.spawn(function()
                        local timer = Utils:Timer(0.8666666666666667)
                        repeat task.wait() until timer() or not (realBall and realBall.Parried)
                        if realBall and realBall.Parried then realBall:SetParry(false, "Due") end
                    end)
                    debounce = false
                end
            end))
        end
    })

    GUI.Combat.Toggle["Auto-Spam-Parry"] = CombatTab:AddToggle({
        Name = "Auto Spam Parry",
        Default = SettingsData.Toggle["Auto-Spam-Parry"],
        Callback = function(bool)
            SettingsData.Toggle["Auto-Spam-Parry"] = bool
            if SignalWrapper["Auto-Spam-Parry"] then SignalWrapper["Auto-Spam-Parry"]:Disconnect() end
            SignalWrapper["Auto-Spam-Parry"] = RunService.PostSimulation:Connect(TEMP_NO_VIRTUALIZE(function(step)
                if not SettingsData.Toggle["Auto-Spam-Parry"] then SignalWrapper["Auto-Spam-Parry"]:Disconnect() return end
                local ping
                pcall(function() ping = (LocalPlayer:GetNetworkPing() * 2) or (game.Stats.Network.ServerStatsItem["Data Ping"]:GetValue() / 1000) end)
                if not ping then ping = 0.05 end
                local Humanoids = { LocalPlayer = Utils:GetHumanoid(LocalPlayer.Character) }
                local realBall = State.RealBall
                if not Config.Spam and Logic:Alive(LocalPlayer) and realBall and realBall.Object and realBall.Velocity.Magnitude > 0 and realBall.Target == LocalPlayer and #realBall.Animators <= 0 and Humanoids.LocalPlayer and LocalPlayer.Character.Parent == Workspace.Alive and (State.ForceSpam or (realBall.ZoomiesFluctuated and (Utils:TowardsPosition(Humanoids.LocalPlayer.RootPart.Position, realBall.Position, realBall.Velocity) >= 0)) or (realBall.ZoomiesFluctuated and ((function()
                    local dist = (Humanoids.LocalPlayer.RootPart.Position - realBall.Position).Magnitude
                    if dist <= math.clamp(realBall.Velocity.Magnitude, 17, 17) then return true end
                end)()))) then
                    local connections = {}
                    local function CleanupConnections()
                        RunService:UnbindFromRenderStep("AutoSpamParry")
                        for _, c in pairs(connections) do c:Disconnect() end
                        table.clear(connections)
                    end

                    local function SpamLogic(dt)
                        local p
                        pcall(function() p = (LocalPlayer:GetNetworkPing() * 2) or (game.Stats.Network.ServerStatsItem["Data Ping"]:GetValue() / 1000) end)
                        if not p then p = 0.05 end
                        if (Logic:Alive(LocalPlayer) and SettingsData.Toggle["Auto-Parry"] and SettingsData.Toggle["Auto-Spam-Parry"] and ((State.LocalParryFrequency and State.LocalLastParried and State.LocalParryFrequency <= 0.225 + (p + dt) and os.clock() - State.LocalLastParried <= 0.325 + (p + dt)) or (State.EstimatedTimeArrival and State.LastEstimatedTimeArrival and State.LastEstimatedTimeArrivalTimestamp and (State.EstimatedTimeArrival <= 0.225 + (p + dt) and State.LastEstimatedTimeArrival <= 0.225 + (p + dt) and State.EstimatedTimeArrival - State.LastEstimatedTimeArrival < 0.225 + (p + dt)) and os.clock() - State.LastEstimatedTimeArrivalTimestamp <= 0.35))) then
                            State.Spamming = true
                            Config.Spam = true
                            task.spawn(function()
                                for i = 1, SettingsData.Slider["Spam-Iteration"] do
                                     local parryArgs = {0.5, State.ParryAttemptKey, 0.15, Camera.CFrame, Logic:PlayersScreenPoint(), {Mouse.X, Mouse.Y}, false}
                                     Utils:FireRemote(nil, RemoteSignals.ParryAttempt, unpack(parryArgs))
                                     task.wait()
                                end
                            end)
                        else
                            State.Spamming = false
                            Config.Spam = false
                            CleanupConnections()
                        end
                    end
                    SpamLogic(0)
                    RunService:BindToRenderStep("AutoSpamParry", 0, SpamLogic)
                    connections[#connections + 1] = RunService.PreAnimation:Connect(SpamLogic)
                    connections[#connections + 1] = RunService.PreRender:Connect(SpamLogic)
                    connections[#connections + 1] = RunService.PreSimulation:Connect(SpamLogic)
                    connections[#connections + 1] = RunService.PostSimulation:Connect(SpamLogic)
                    connections[#connections + 1] = RunService.Heartbeat:Connect(SpamLogic)
                end
            end))
        end
    })

    GUI.Combat.Toggle["Auto-Counter"] = CombatTab:AddToggle({
        Name = "Auto Counter",
        Default = SettingsData.Toggle["Auto-Counter"],
        Callback = function(bool) SettingsData.Toggle["Auto-Counter"] = bool end
    })

    GUI.Combat.Slider["Range"] = CombatTab:AddSlider({
        Name = "Parry Range",
        Min = 0, Max = 1, Default = SettingsData.Slider["Range"], Increment = 0.01,
        Callback = function(val) SettingsData.Slider["Range"] = val end
    })

    GUI.Combat.Slider["Direct-Point"] = CombatTab:AddSlider({
        Name = "Direct Point",
        Min = -1.0, Max = 1, Default = SettingsData.Slider["Direct-Point"], Increment = 0.01,
        Callback = function(val) SettingsData.Slider["Direct-Point"] = val end
    })

    GUI.Combat.Slider["Spam-Iteration"] = CombatTab:AddSlider({
        Name = "Spam Iteration",
        Min = 1, Max = 50, Default = SettingsData.Slider["Spam-Iteration"], Increment = 1,
        Callback = function(val) SettingsData.Slider["Spam-Iteration"] = val end
    })
end

do
    -- // MACRO TAB //
    local MacroTab = Window:MakeTab({ Name = "Macro", Icon = "rbxassetid://4483345998" })
    GUI.Macro = { Input = {} }
    
    GUI.Macro.Input["Block-Keybind"] = MacroTab:AddBind({
        Name = "Block Keybind",
        Default = Enum.KeyCode.V,
        Hold = false,
        Callback = function() end
    })
    GUI.Macro.Input["Block-Keybind"].Callback = function() end
end

do
    -- // SETTINGS TAB //
    local SettingsTab = Window:MakeTab({ Name = "Settings", Icon = "rbxassetid://4483345998" })
    GUI.Settings = { Toggle = {}, Dropdown = {} }

    GUI.Settings.Toggle["Auto-Config"] = SettingsTab:AddToggle({
        Name = "Auto Config",
        Default = SettingsData.Toggle["Auto-Config"],
        Callback = function(bool)
            SettingsData.Toggle["Auto-Config"] = bool
            if SignalWrapper["Auto-Config"] then SignalWrapper["Auto-Config"]:Disconnect() end
            SignalWrapper["Auto-Config"] = RunService.PostSimulation:Connect(TEMP_NO_VIRTUALIZE(function()
                if not SettingsData.Toggle["Auto-Config"] then SignalWrapper["Auto-Config"]:Disconnect() return end
                local ping
                pcall(function() ping = (LocalPlayer:GetNetworkPing() * 2) or (game.Stats.Network.ServerStatsItem["Data Ping"]:GetValue() / 1000) end)
                if not ping then ping = 0.05 end
                local isDungeon = false
                for _, v in pairs(Workspace.Map:GetChildren()) do
                    if v.Name:lower():match("^dungeon") then isDungeon = true break end
                end
                if isDungeon then
                    GUI.Combat.Slider["Range"]:Set(0.3)
                    GUI.Combat.Slider["Direct-Point"]:Set(-0.25)
                elseif GUI.Combat and GUI.Combat.Slider["Range"] then
                    GUI.Combat.Slider["Range"]:Set(0.35 + 0.05 * (ping / 0.05))
                    GUI.Combat.Slider["Direct-Point"]:Set(0)
                end
            end))
        end
    })

    GUI.Settings.Dropdown["Targeting-Mode"] = SettingsTab:AddDropdown({
        Name = "Targeting Mode",
        Default = SettingsData.Dropdown["Targeting-Mode"],
        Options = {"Nearest to Mouse", "Nearest to Screen Center", "Nearest Player", "Furthest Player", "Last Targeted Player", "Weakest Player", "Strongest Player"},
        Callback = function(val) SettingsData.Dropdown["Targeting-Mode"] = val end
    })

    GUI.Settings.Toggle["Aim-Camera"] = SettingsTab:AddToggle({
        Name = "Aim Camera at Ball",
        Default = SettingsData.Toggle["Aim-Camera"],
        Callback = function(val) SettingsData.Toggle["Aim-Camera"] = val end
    })

    GUI.Settings.Toggle["Block-Spam-Parry"] = SettingsTab:AddToggle({
        Name = "Block Spam Parry",
        Default = SettingsData.Toggle["Block-Spam-Parry"],
        Callback = function(bool)
            SettingsData.Toggle["Block-Spam-Parry"] = bool
            if not State["Block-Spam-Parry"] then
                local active = false
                local conns = {}
                local function BindBlock(button1, button2)
                    local g1 = button1:WaitForChild("UIGradient")
                    g1:GetPropertyChangedSignal("Offset"):Connect(TEMP_NO_VIRTUALIZE(function()
                        if g1.Offset.Y < 0.5 then
                            Config.Parrying = true
                            State.Parryable = LocalPlayer.Character and LocalPlayer.Character:GetAttribute("Parrying")
                        else
                            Config.Parrying = false
                            State.Parryable = LocalPlayer.Character and LocalPlayer.Character:GetAttribute("Parrying")
                        end
                    end))
                    conns[#conns + 1] = button1.InputBegan:Connect(TEMP_NO_VIRTUALIZE(function(input)
                        if SettingsData.Toggle["Block-Spam-Parry"] and active and (input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch) then
                            local spamConns = {}
                            local function SpamLoop()
                                local function stop()
                                    RunService:UnbindFromRenderStep("AutoSpamParry")
                                    for _, c in pairs(spamConns) do c:Disconnect() end
                                    table.clear(spamConns)
                                end
                                if Logic:Alive(LocalPlayer) then
                                    State.Spamming = true
                                    task.spawn(function()
                                        for i = 1, SettingsData.Slider["Spam-Iteration"] do
                                            local parryArgs = {0.5, State.ParryAttemptKey, 0.15, Camera.CFrame, Logic:PlayersScreenPoint(), {Mouse.X, Mouse.Y}, false}
                                            Utils:FireRemote(nil, RemoteSignals.ParryAttempt, unpack(parryArgs))
                                            task.wait()
                                        end
                                    end)
                                else
                                    State.Spamming = false
                                    stop()
                                end
                            end
                            SpamLoop()
                        end
                    end))
                    conns[#conns + 1] = button1.MouseButton1Down:Connect(function() if SettingsData.Dropdown["Block-Mode"] == "Hold" then active = true end end)
                    conns[#conns + 1] = button1.MouseButton1Up:Connect(function() if SettingsData.Dropdown["Block-Mode"] == "Hold" then active = false end end)
                end
                BindBlock(Logic:BlockButton(), Logic:AbilityButton())
                PlayerGui.ChildAdded:Connect(function(c) if c.Name == "Hotbar" then BindBlock(c:WaitForChild("Block"), c:WaitForChild("Ability")) end end)
                State["Block-Spam-Parry"] = true
            end
        end
    })

    GUI.Settings.Dropdown["Block-Mode"] = SettingsTab:AddDropdown({
        Name = "Block Mode",
        Default = SettingsData.Dropdown["Block-Mode"],
        Options = {"Hold", "Toggle"},
        Callback = function(val) SettingsData.Dropdown["Block-Mode"] = val end
    })

    GUI.Settings.Toggle["Curve-Ball"] = SettingsTab:AddToggle({
        Name = "Auto Curve Ball",
        Default = SettingsData.Toggle["Curve-Ball"],
        Callback = function(val) SettingsData.Toggle["Curve-Ball"] = val end
    })

    GUI.Settings.Dropdown["Curving-Mode"] = SettingsTab:AddDropdown({
        Name = "Curving Mode",
        Default = SettingsData.Dropdown["Curving-Mode"],
        Options = {"Adaptive", "Random", "Upward", "Downward", "Reverse", "Verse", "Backward", "Forward", "Default"},
        Callback = function(val) SettingsData.Dropdown["Curving-Mode"] = val end
    })
end

OrionLib:Init()
