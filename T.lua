--[[
    Infinixity | Blade Ball
    UI Library: Orion (Replaced from Fluent)
    Logic: Shared (shared/core.lua)
]]

-- // UI LIBRARY //
local OrionLib = loadstring(game:HttpGet(('https://raw.githubusercontent.com/jensonhirst/Orion/main/source')))()

-- // SHARED CORE //
local CoreModule = loadstring(game:HttpGet("https://raw.githubusercontent.com/Spawner-id/buratrat/main/shared/core.lua"))()
local C = CoreModule.init({
    notify = function(text, duration)
        OrionLib:MakeNotification({
            Name = "Infinixity",
            Content = text,
            Time = duration
        })
    end
})
if not C then return end

local Config = C.Config
local FX = C.FX
local SettingsData = C.SettingsData
local GUI = C.GUI
local Callbacks = C.Callbacks
local TEMP_NO_VIRTUALIZE = C.TEMP_NO_VIRTUALIZE

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
            Callbacks.manualParry()
        end)
    })

    GUI.Combat.Toggle["Auto-Parry"] = CombatTab:AddToggle({
        Name = "Auto Parry",
        Default = SettingsData.Toggle["Auto-Parry"],
        Callback = function(bool)
            Callbacks.autoParryToggle(bool)
        end
    })

    GUI.Combat.Toggle["Auto-Spam-Parry"] = CombatTab:AddToggle({
        Name = "Auto Spam Parry",
        Default = SettingsData.Toggle["Auto-Spam-Parry"],
        Callback = function(bool)
            Callbacks.autoSpamParryToggle(bool)
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
    GUI.Macro.Input["Block-Keybind"].Callback = function() 
    end
end

do
    -- // SETTINGS TAB //
    local SettingsTab = Window:MakeTab({ Name = "Settings", Icon = "rbxassetid://4483345998" })
    GUI.Settings = { Toggle = {}, Dropdown = {} }

    GUI.Settings.Toggle["Auto-Config"] = SettingsTab:AddToggle({
        Name = "Auto Config",
        Default = SettingsData.Toggle["Auto-Config"],
        Callback = function(bool)
            Callbacks.autoConfigToggle(bool, function(val)
                GUI.Combat.Slider["Range"]:Set(val)
            end, function(val)
                GUI.Combat.Slider["Direct-Point"]:Set(val)
            end)
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
            Callbacks.blockSpamParryToggle(bool)
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
