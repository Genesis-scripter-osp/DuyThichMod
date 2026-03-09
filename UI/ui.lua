-- ============================================================
--  PHANTOM HUB  |  ui.lua
--  Xây dựng toàn bộ giao diện người dùng bằng Roblox GUI
-- ============================================================

local Players          = game:GetService("Players")
local TweenService     = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local RunService       = game:GetService("RunService")

local LocalPlayer = Players.LocalPlayer
local PlayerGui   = LocalPlayer:WaitForChild("PlayerGui")

local UI   = {}
local Core -- sẽ được gán trong Build()

-- ============================================================
--  HÀM TIỆN ÍCH UI
-- ============================================================
local function Create(class: string, props: { [string]: any }): Instance
    local obj = Instance.new(class)
    for k, v in pairs(props) do
        if k ~= "Parent" then
            (obj :: any)[k] = v
        end
    end
    if props.Parent then obj.Parent = props.Parent end
    return obj
end

local function Tween(obj: Instance, goal: { [string]: any }, t: number?)
    local ti = TweenInfo.new(t or 0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
    TweenService:Create(obj, ti, goal):Play()
end

local function MakeDraggable(frame: Frame, handle: Frame?)
    local drag, dragStart, startPos
    local dragTarget = handle or frame
    dragTarget.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            drag      = true
            dragStart = input.Position
            startPos  = frame.Position
        end
    end)
    UserInputService.InputChanged:Connect(function(input)
        if drag and input.UserInputType == Enum.UserInputType.MouseMovement then
            local delta = input.Position - dragStart
            frame.Position = UDim2.new(
                startPos.X.Scale, startPos.X.Offset + delta.X,
                startPos.Y.Scale, startPos.Y.Offset + delta.Y
            )
        end
    end)
    UserInputService.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            drag = false
        end
    end)
end

-- ============================================================
--  THEME
-- ============================================================
local THEME = {
    Bg         = Color3.fromRGB(10,  10,  18),
    Panel      = Color3.fromRGB(16,  16,  26),
    Sidebar    = Color3.fromRGB(12,  12,  20),
    Border     = Color3.fromRGB(40,  40,  60),
    Accent     = Color3.fromRGB(0,   255, 136),
    AccentBlue = Color3.fromRGB(0,   136, 255),
    Text       = Color3.fromRGB(220, 220, 230),
    TextDim    = Color3.fromRGB(100, 100, 120),
    TextMuted  = Color3.fromRGB(55,  55,  70),
    Success    = Color3.fromRGB(0,   255, 136),
    Warn       = Color3.fromRGB(255, 170, 0),
    Danger     = Color3.fromRGB(255, 68,  68),
    ToggleOff  = Color3.fromRGB(35,  35,  50),
    ToggleOn   = Color3.fromRGB(0,   255, 136),

    TabColors = {
        main   = Color3.fromRGB(0,   255, 136),
        combat = Color3.fromRGB(255, 68,  68),
        boss   = Color3.fromRGB(255, 136, 0),
        sea    = Color3.fromRGB(0,   136, 255),
        fruit  = Color3.fromRGB(204, 68,  255),
        raid   = Color3.fromRGB(255, 221, 0),
        tp     = Color3.fromRGB(68,  255, 221),
        esp    = Color3.fromRGB(255, 68,  170),
        player = Color3.fromRGB(136, 255, 68),
        stats  = Color3.fromRGB(255, 170, 0),
        server = Color3.fromRGB(170, 170, 255),
        misc   = Color3.fromRGB(200, 200, 200),
        cfg    = Color3.fromRGB(120, 120, 140),
    }
}

-- ============================================================
--  KHAI BÁO TABS
-- ============================================================
local TABS = {
    { id="main",   label="MAIN",     icon="⚡" },
    { id="combat", label="COMBAT",   icon="⚔" },
    { id="boss",   label="BOSS",     icon="💀" },
    { id="sea",    label="SEA",      icon="🌊" },
    { id="fruit",  label="FRUIT",    icon="🍎" },
    { id="raid",   label="RAID",     icon="🏴" },
    { id="tp",     label="TELEPORT", icon="🌀" },
    { id="esp",    label="ESP",      icon="👁" },
    { id="player", label="PLAYER",   icon="🧍" },
    { id="stats",  label="STATS",    icon="📊" },
    { id="server", label="SERVER",   icon="🌐" },
    { id="misc",   label="MISC",     icon="🔧" },
    { id="cfg",    label="SETTINGS", icon="⚙" },
}

-- ============================================================
--  PHẦN TỬ UI: Toggle
-- ============================================================
local function MakeToggle(parent: Instance, featureId: string, color: Color3): Frame
    local isOn = Core.IsOn(featureId)

    local frame = Create("Frame", {
        Size             = UDim2.new(0, 44, 0, 24),
        BackgroundColor3 = isOn and color or THEME.ToggleOff,
        BorderSizePixel  = 0,
        Parent           = parent,
    })
    Create("UICorner", { CornerRadius = UDim.new(1, 0), Parent = frame })
    Create("UIStroke", {
        Color     = isOn and color or THEME.Border,
        Thickness = 1,
        Parent    = frame,
    })

    local knob = Create("Frame", {
        Size             = UDim2.new(0, 18, 0, 18),
        Position         = isOn and UDim2.new(0, 23, 0, 3) or UDim2.new(0, 3, 0, 3),
        BackgroundColor3 = Color3.fromRGB(255, 255, 255),
        BorderSizePixel  = 0,
        Parent           = frame,
    })
    Create("UICorner", { CornerRadius = UDim.new(1, 0), Parent = knob })

    local function Refresh(on: boolean)
        Tween(frame, { BackgroundColor3 = on and color or THEME.ToggleOff })
        Tween(knob, {
            Position = on and UDim2.new(0, 23, 0, 3) or UDim2.new(0, 3, 0, 3)
        })
        local stroke = frame:FindFirstChildOfClass("UIStroke")
        if stroke then
            Tween(stroke, { Color = on and color or THEME.Border })
        end
    end

    frame.InputBegan:Connect(function(inp)
        if inp.UserInputType == Enum.UserInputType.MouseButton1 then
            Core.Toggle(featureId)
            Refresh(Core.IsOn(featureId))
        end
    end)

    Core.OnToggle(featureId, function(val) Refresh(val) end)

    return frame
end

-- ============================================================
--  PHẦN TỬ UI: Slider
-- ============================================================
local function MakeSlider(parent: Instance, featureId: string, color: Color3): Frame
    local feat    = Core._ById[featureId]
    local minVal  = feat.min or 0
    local maxVal  = feat.max or 100
    local current = Core.GetSlider(featureId)

    local container = Create("Frame", {
        Size                   = UDim2.new(1, 0, 0, 20),
        BackgroundTransparency = 1,
        Parent                 = parent,
    })

    local track = Create("Frame", {
        Size             = UDim2.new(1, -50, 0, 4),
        Position         = UDim2.new(0, 0, 0.5, -2),
        BackgroundColor3 = THEME.Border,
        BorderSizePixel  = 0,
        Parent           = container,
    })
    Create("UICorner", { CornerRadius = UDim.new(1, 0), Parent = track })

    local fill = Create("Frame", {
        Size             = UDim2.new((current - minVal) / (maxVal - minVal), 0, 1, 0),
        BackgroundColor3 = color,
        BorderSizePixel  = 0,
        Parent           = track,
    })
    Create("UICorner", { CornerRadius = UDim.new(1, 0), Parent = fill })

    local label = Create("TextLabel", {
        Size                   = UDim2.new(0, 44, 1, 0),
        Position               = UDim2.new(1, -44, 0, 0),
        BackgroundTransparency = 1,
        Text                   = tostring(current),
        TextColor3             = color,
        TextSize               = 11,
        Font                   = Enum.Font.Code,
        TextXAlignment         = Enum.TextXAlignment.Right,
        Parent                 = container,
    })

    local dragging = false
    track.InputBegan:Connect(function(inp)
        if inp.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = true
        end
    end)
    UserInputService.InputEnded:Connect(function(inp)
        if inp.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = false
        end
    end)
    UserInputService.InputChanged:Connect(function(inp)
        if dragging and inp.UserInputType == Enum.UserInputType.MouseMovement then
            local absPos  = track.AbsolutePosition.X
            local absSize = track.AbsoluteSize.X
            local ratio   = math.clamp((inp.Position.X - absPos) / absSize, 0, 1)
            local newVal  = math.round(minVal + ratio * (maxVal - minVal))
            Core.SetSlider(featureId, newVal)
            fill.Size  = UDim2.new(ratio, 0, 1, 0)
            label.Text = tostring(newVal)
        end
    end)

    return container
end

-- ============================================================
--  PHẦN TỬ UI: Feature Row
-- ============================================================
local function MakeFeatureRow(scroll: ScrollingFrame, feat: { [string]: any }, color: Color3)
    local row = Create("Frame", {
        Size             = UDim2.new(1, 0, 0, feat.type == "slider" and 52 or 38),
        BackgroundColor3 = THEME.Panel,
        BorderSizePixel  = 0,
        Parent           = scroll,
    })
    Create("UICorner", { CornerRadius = UDim.new(0, 6), Parent = row })

    -- Đường viền trái màu tab
    local accent = Create("Frame", {
        Size             = UDim2.new(0, 2, 0.7, 0),
        Position         = UDim2.new(0, 0, 0.15, 0),
        BackgroundColor3 = Core.IsOn(feat.id) and color or THEME.Border,
        BorderSizePixel  = 0,
        Parent           = row,
    })
    Create("UICorner", { CornerRadius = UDim.new(1, 0), Parent = accent })

    if feat.type == "toggle" then
        Core.OnToggle(feat.id, function(val)
            Tween(accent, { BackgroundColor3 = val and color or THEME.Border })
        end)
    end

    -- Label tên feature
    Create("TextLabel", {
        Size                   = UDim2.new(1, -70, 0, 20),
        Position               = UDim2.new(0, 12, 0, feat.type == "slider" and 4 or 9),
        BackgroundTransparency = 1,
        Text                   = feat.label,
        TextColor3             = THEME.Text,
        TextSize               = 13,
        Font                   = Enum.Font.GothamSemibold,
        TextXAlignment         = Enum.TextXAlignment.Left,
        Parent                 = row,
    })

    -- Control theo loại
    if feat.type == "toggle" then
        local tog = MakeToggle(row, feat.id, color)
        tog.Position = UDim2.new(1, -54, 0.5, -12)

    elseif feat.type == "slider" then
        local sl = MakeSlider(row, feat.id, color)
        sl.
