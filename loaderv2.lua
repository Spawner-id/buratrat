--[[
    Infinixity | Blade Ball
    UI Library: Fluent
    Logic: Shared (shared/core.lua)
]]

-- // UI LIBRARY //
local Library = loadstring(game:HttpGet("https://github.com/dawid-scripts/Fluent/releases/latest/download/main.lua"))()

-- // SHARED CORE //
local CoreModule = loadstring(game:HttpGet("https://raw.githubusercontent.com/Spawner-id/buratrat/main/shared/core.lua"))()
local C = CoreModule.init({
    notify = function(text, duration)
        Library:Notify({
            Title = "Infinixity",
            Content = text,
            Duration = duration
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

-- // UI CONSTRUCTION (FLUENT) //
local Window = Library:CreateWindow({
    Name = "Infinixity",
    Scale = 1
})

do
    local Tab = Window:CreateTab({
        Name = "Configuration"
    })

    do
        GUI.Combat = {
            Label = {},
            Paragraph = {},
            Button = {},
            Toggle = {},
            Dropdown = {},
            Slider = {},
            Input = {}
        }
        local Section = Tab:CreateSection({
            Name = "Combat"
        })

        GUI.Combat.Toggle["Optimize"] = Section:CreateToggle({
            Name = "Optimize",
            Body = "",
            Init = true,
            State = SettingsData.Toggle["Optimize"],
            Function = function(bool)
                SettingsData.Toggle["Optimize"] = bool
                if FX.ClientFX then
                    FX.ClientFX.Enabled = not bool
                end
            end
        })

        GUI.Combat.Toggle["Visualize"] = Section:CreateToggle({
            Name = "Visualize",
            Body = "",
            Init = true,
            State = SettingsData.Toggle["Visualize"],
            Function = function(bool)
                SettingsData.Toggle["Visualize"] = bool
                Config.Visualize = bool
            end
        })

        GUI.Combat.Button["Parry"] = Section:CreateButton({
            Name = "Parry",
            Body = "",
            Function = TEMP_NO_VIRTUALIZE(function(val)
                Callbacks.manualParry()
            end)
        })

        GUI.Combat.Toggle["Auto-Parry"] = Section:CreateToggle({
            Name = "Auto Parry",
            Body = "",
            Init = true,
            State = SettingsData.Toggle["Auto-Parry"],
            Function = function(bool)
                Callbacks.autoParryToggle(bool)
            end
        })

        GUI.Combat.Toggle["Auto-Spam-Parry"] = Section:CreateToggle({
            Name = "Auto Spam Parry",
            Body = "",
            Init = true,
            State = SettingsData.Toggle["Auto-Spam-Parry"],
            Function = function(bool)
                Callbacks.autoSpamParryToggle(bool)
            end
        })

        GUI.Combat.Toggle["Auto-Counter"] = Section:CreateToggle({
            Name = "Auto Counter",
            Body = "",
            Init = true,
            State = SettingsData.Toggle["Auto-Counter"],
            Function = function(bool)
                SettingsData.Toggle["Auto-Counter"] = bool
            end
        })

        GUI.Combat.Slider["Range"] = Section:CreateSlider({
            Name = "Parry Range",
            Body = "",
            Init = true,
            Min = 0,
            Max = 1,
            Increment = 0.025,
            Value = SettingsData.Slider["Range"],
            Function = function(val)
                SettingsData.Slider["Range"] = val
            end
        })

        GUI.Combat.Slider["Direct-Point"] = Section:CreateSlider({
            Name = "Direct Point",
            Body = "",
            Init = true,
            Min = -1.0,
            Max = 1,
            Increment = 0.025,
            Value = SettingsData.Slider["Direct-Point"],
            Function = function(val)
                SettingsData.Slider["Direct-Point"] = val
            end
        })

        GUI.Combat.Slider["Spam-Iteration"] = Section:CreateSlider({
            Name = "Spam Iteration",
            Body = "",
            Init = true,
            Min = 1,
            Max = 50,
            Increment = 1,
            Value = SettingsData.Slider["Spam-Iteration"],
            Function = function(val)
                SettingsData.Slider["Spam-Iteration"] = val
            end
        })
    end

    do
        GUI.Macro = {
            Label = {},
            Paragraph = {},
            Button = {},
            Toggle = {},
            Dropdown = {},
            Slider = {},
            Input = {}
        }
        local Section = Window:CreateTab({
            Name = "Macro"
        }):CreateSection({
            Name = "Macro"
        })

        GUI.Macro.Input["Block-Keybind"] = Section:CreateInput({
            Name = "Block Keybind",
            Body = "",
            PlaceholderText = SettingsData.Input["Block-Keybind"],
            Text = "",
            RemoveTextAfterFocusLost = false,
            Function = function(val)
                SettingsData.Input["Block-Keybind"] = Enum.KeyCode[tostring(val:upper())]
            end
        })
    end

    do
        GUI.Settings = {
            Label = {},
            Paragraph = {},
            Button = {},
            Toggle = {},
            Dropdown = {},
            Slider = {},
            Input = {}
        }
        local Section = Window:CreateTab({
            Name = "Settings"
        }):CreateSection({
            Name = "Settings"
        })

        GUI.Settings.Button["Save-Configuration"] = Section:CreateButton({
            Name = "Save Configuration",
            Body = "Save chosen configuration",
            Function = function()
            end
        })

        GUI.Settings.Toggle["Auto-Config"] = Section:CreateToggle({
            Name = "Auto Config",
            Body = "",
            Init = true,
            State = SettingsData.Toggle["Auto-Config"],
            Function = function(bool)
                Callbacks.autoConfigToggle(bool, function(val)
                    GUI.Combat.Slider["Range"]:Set("Value", val)
                end, function(val)
                    GUI.Combat.Slider["Direct-Point"]:Set("Value", val)
                end)
            end
        })

        local TargetOptions = {
            "Nearest to Mouse",
            "Nearest to Screen Center",
            "Nearest Player",
            "Furthest Player",
            "Last Targeted Player",
            "Weakest Player",
            "Strongest Player"
        }

        GUI.Settings.Dropdown["Targeting-Mode"] = Section:CreateDropdown({
            Name = "Targeting Mode",
            Body = "",
            Init = true,
            Table = TargetOptions,
            Text = SettingsData.Dropdown["Targeting-Mode"],
            Function = function(val)
                SettingsData.Dropdown["Targeting-Mode"] = val
            end
        })

        GUI.Settings.Toggle["Aim-Camera"] = Section:CreateToggle({
            Name = "Aim Camera at Ball",
            Body = "",
            Init = true,
            State = SettingsData.Toggle["Aim-Camera"],
            Function = function(val)
                SettingsData.Toggle["Aim-Camera"] = val
            end
        })

        GUI.Settings.Toggle["Block-Spam-Parry"] = Section:CreateToggle({
            Name = "Block Spam Parry",
            Body = "",
            Init = true,
            State = SettingsData.Toggle["Block-Spam-Parry"],
            Function = function(bool)
                Callbacks.blockSpamParryToggle(bool)
            end
        })

        local BlockModes = { "Hold", "Toggle" }
        GUI.Settings.Dropdown["Block-Mode"] = Section:CreateDropdown({
            Name = "Block Mode",
            Body = "",
            Init = true,
            Table = BlockModes,
            Text = SettingsData.Dropdown["Block-Mode"],
            Function = function(val)
                SettingsData.Dropdown["Block-Mode"] = val
            end
        })

        GUI.Settings.Toggle["Curve-Ball"] = Section:CreateToggle({
            Name = "Auto Curve Ball",
            Body = "",
            Init = true,
            State = SettingsData.Toggle["Curve-Ball"],
            Function = function(val)
                SettingsData.Toggle["Curve-Ball"] = val
            end
        })

        local CurveModes = {
            "Adaptive",
            "Random",
            "Upward",
            "Downward",
            "Reverse",
            "Verse",
            "Backward",
            "Forward",
            "Default"
        }
        GUI.Settings.Dropdown["Curving-Mode"] = Section:CreateDropdown({
            Name = "Curving Mode",
            Body = "",
            Init = true,
            Table = CurveModes,
            Text = SettingsData.Dropdown["Curving-Mode"],
            Function = function(val)
                SettingsData.Dropdown["Curving-Mode"] = val
            end
        })
    end
end
