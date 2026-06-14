--[[
    Shared UI Helper Functions
    Used by Ui.lua and uii.lua to avoid duplicating Create/MakeDraggable.
    
    Usage:
        local UIHelpers = loadstring(game:HttpGet("<raw-url>/shared/ui_helpers.lua"))()
        local Create = UIHelpers.Create
        local MakeDraggable = UIHelpers.MakeDraggable
]]

local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")

local UIHelpers = {}

function UIHelpers.Create(class, props)
    local inst = Instance.new(class)
    for k, v in pairs(props) do inst[k] = v end
    return inst
end

function UIHelpers.MakeDraggable(topbar, widget)
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

return UIHelpers
