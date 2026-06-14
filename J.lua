--[[
    Infinixity | Blade Ball
    UI Library: Venyx (Replaced from Orion)
    Logic: Shared (shared/core.lua)
]]

-- // UI LIBRARY //
local Neverzen = loadstring(game:HttpGet("https://raw.githubusercontent.com/zxciaz/VenyxUI/main/Reuploaded"))()

-- // SHARED CORE //
local CoreModule = loadstring(game:HttpGet("https://raw.githubusercontent.com/Spawner-id/buratrat/main/shared/core.lua"))()
local C = CoreModule.init({
    notify = function(text, duration)
        game:GetService("StarterGui"):SetCore("SendNotification", {
            Title = "Infinixity",
            Text = text,
            Duration = duration
        })
    end
})
if not C then return end

local Utils = C.Utils
local Logic = C.Logic
local State = C.State
local Config = C.Config
local FX = C.FX
local SettingsData = C.SettingsData
local SignalWrapper = C.SignalWrapper
local RemoteSignals = C.RemoteSignals
local GUI = C.GUI
local Callbacks = C.Callbacks
local TEMP_NO_VIRTUALIZE = C.TEMP_NO_VIRTUALIZE
local LocalPlayer = C.LocalPlayer
local Camera = C.Camera
local Mouse = C.Mouse
local PlayerGui = C.PlayerGui
local RunService = C.RunService
local Workspace = C.Workspace

-- // UI CONSTRUCTION (VENYX) //
local Window = Neverzen.new("Infinixity | Blade Ball", 5013109572)

-- // COMBAT PAGE //
local CombatPage = Window:addPage("Combat", 5012544693)
local CombatMain = CombatPage:addSection("Main")
local CombatAuto = CombatPage:addSection("Automation")
local CombatSettings = CombatPage:addSection("Settings")

CombatMain:addToggle("Optimize", SettingsData.Toggle["Optimize"], function(bool)
    SettingsData.Toggle["Optimize"] = bool
    if FX.ClientFX then FX.ClientFX.Enabled = not bool end
end)

CombatMain:addToggle("Visualize", SettingsData.Toggle["Visualize"], function(bool)
    SettingsData.Toggle["Visualize"] = bool
    Config.Visualize = bool
end)

CombatMain:addButton("Manual Parry", TEMP_NO_VIRTUALIZE(function()
    Callbacks.manualParry()
end))

CombatAuto:addToggle("Auto Parry", SettingsData.Toggle["Auto-Parry"], function(bool)
    Callbacks.autoParryToggle(bool)
end)

CombatAuto:addToggle("Auto Spam Parry", SettingsData.Toggle["Auto-Spam-Parry"], function(bool)
    Callbacks.autoSpamParryToggle(bool)
end)

CombatAuto:addToggle("Auto Counter", SettingsData.Toggle["Auto-Counter"], function(bool)
    SettingsData.Toggle["Auto-Counter"] = bool 
end)

CombatSettings:addSlider("Parry Range", SettingsData.Slider["Range"], 0, 1, function(val)
    SettingsData.Slider["Range"] = val
end)

CombatSettings:addSlider("Direct Point", SettingsData.Slider["Direct-Point"], -1, 1, function(val)
    SettingsData.Slider["Direct-Point"] = val
end)

CombatSettings:addSlider("Spam Iteration", SettingsData.Slider["Spam-Iteration"], 1, 50, function(val)
    SettingsData.Slider["Spam-Iteration"] = val
end)

-- // MACRO PAGE //
local MacroPage = Window:addPage("Macro", 5012544693)
local MacroSection = MacroPage:addSection("Inputs")

MacroSection:addKeybind("Block Keybind", Enum.KeyCode.V, function() 
end, function(key)
end)

-- // SETTINGS PAGE //
local SettingsPage = Window:addPage("Settings", 5012544693)
local SettingsSection = SettingsPage:addSection("Configuration")

SettingsSection:addToggle("Auto Config", SettingsData.Toggle["Auto-Config"], function(bool)
    Callbacks.autoConfigToggle(bool, function(val)
        SettingsData.Slider["Range"] = val
    end, function(val)
        SettingsData.Slider["Direct-Point"] = val
    end)
end)

SettingsSection:addDropdown("Targeting Mode", {"Nearest to Mouse", "Nearest to Screen Center", "Nearest Player", "Furthest Player", "Last Targeted Player", "Weakest Player", "Strongest Player"}, function(val)
    SettingsData.Dropdown["Targeting-Mode"] = val
end)

SettingsSection:addToggle("Aim Camera at Ball", SettingsData.Toggle["Aim-Camera"], function(val)
    SettingsData.Toggle["Aim-Camera"] = val
end)

SettingsSection:addToggle("Block Spam Parry", SettingsData.Toggle["Block-Spam-Parry"], function(bool)
    Callbacks.blockSpamParryToggle(bool)
end)

SettingsSection:addDropdown("Block Mode", {"Hold", "Toggle"}, function(val)
    SettingsData.Dropdown["Block-Mode"] = val
end)

SettingsSection:addToggle("Auto Curve Ball", SettingsData.Toggle["Curve-Ball"], function(val)
    SettingsData.Toggle["Curve-Ball"] = val
end)

SettingsSection:addDropdown("Curving Mode", {"Adaptive", "Random", "Upward", "Downward", "Reverse", "Verse", "Backward", "Forward", "Default"}, function(val)
    SettingsData.Dropdown["Curving-Mode"] = val
end)

-- Select the first page
Window:SelectPage(Window.pages[1], true)
