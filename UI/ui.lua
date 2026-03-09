-- ============================================================
--  PHANTOM HUB  |  ui.lua   v4.1.0
--  Thêm: Anime Banner Animation · Intro slide-in · Particles
-- ============================================================

local Players          = game:GetService("Players")
local TweenService     = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local RunService       = game:GetService("RunService")

local LocalPlayer = Players.LocalPlayer
local PlayerGui   = LocalPlayer:WaitForChild("PlayerGui")

local UI = {}
local Core

-- ============================================================
--  TIỆN ÍCH
-- ============================================================
local function Create(class, props)
    local obj = Instance.new(class)
    for k,v in pairs(props) do if k~="Parent" then (obj::any)[k]=v end end
    if props.Parent then obj.Parent = props.Parent end
    return obj
end

local function Tween(obj, goal, t, style, dir)
    TweenService:Create(obj, TweenInfo.new(
        t or 0.2,
        style or Enum.EasingStyle.Quad,
        dir   or Enum.EasingDirection.Out), goal):Play()
end

local function MakeDraggable(frame, handle)
    local drag, dragStart, startPos
    local h = handle or frame
    h.InputBegan:Connect(function(inp)
        if inp.UserInputType == Enum.UserInputType.MouseButton1 then
            drag=true; dragStart=inp.Position; startPos=frame.Position
        end
    end)
    UserInputService.InputChanged:Connect(function(inp)
        if drag and inp.UserInputType == Enum.UserInputType.MouseMovement then
            local d = inp.Position - dragStart
            frame.Position = UDim2.new(
                startPos.X.Scale, startPos.X.Offset+d.X,
                startPos.Y.Scale, startPos.Y.Offset+d.Y)
        end
    end)
    UserInputService.InputEnded:Connect(function(inp)
        if inp.UserInputType == Enum.UserInputType.MouseButton1 then drag=false end
    end)
end

-- ============================================================
--  THEME
-- ============================================================
local THEME = {
    Bg        = Color3.fromRGB(10,  10,  18),
    Panel     = Color3.fromRGB(16,  16,  26),
    Sidebar   = Color3.fromRGB(12,  12,  20),
    Border    = Color3.fromRGB(40,  40,  60),
    Accent    = Color3.fromRGB(0,   255, 136),
    Text      = Color3.fromRGB(220, 220, 230),
    TextDim   = Color3.fromRGB(100, 100, 120),
    TextMuted = Color3.fromRGB(55,  55,  70),
    Success   = Color3.fromRGB(0,   255, 136),
    ToggleOff = Color3.fromRGB(35,  35,  50),
    TabColors = {
        main    = Color3.fromRGB(0,   255, 136),
        combat  = Color3.fromRGB(255, 68,  68),
        boss    = Color3.fromRGB(255, 136, 0),
        dungeon = Color3.fromRGB(138, 43,  226),
        trinket = Color3.fromRGB(255, 140, 0),
        sea     = Color3.fromRGB(0,   136, 255),
        fruit   = Color3.fromRGB(204, 68,  255),
        raid    = Color3.fromRGB(255, 221, 0),
        tp      = Color3.fromRGB(68,  255, 221),
        esp     = Color3.fromRGB(255, 68,  170),
        player  = Color3.fromRGB(136, 255, 68),
        stats   = Color3.fromRGB(255, 170, 0),
        server  = Color3.fromRGB(170, 170, 255),
        misc    = Color3.fromRGB(200, 200, 200),
        cfg     = Color3.fromRGB(120, 120, 140),
    }
}

-- ============================================================
--  TABS
-- ============================================================
local TABS = {
    {id="main",    label="MAIN",     icon="⚡"},
    {id="combat",  label="COMBAT",   icon="⚔"},
    {id="boss",    label="BOSS",     icon="💀"},
    {id="dungeon", label="DUNGEON",  icon="🏛"},
    {id="trinket", label="TRINKET",  icon="💎"},
    {id="sea",     label="SEA",      icon="🌊"},
    {id="fruit",   label="FRUIT",    icon="🍎"},
    {id="raid",    label="RAID",     icon="🏴"},
    {id="tp",      label="TELEPORT", icon="🌀"},
    {id="esp",     label="ESP",      icon="👁"},
    {id="player",  label="PLAYER",   icon="🧍"},
    {id="stats",   label="STATS",    icon="📊"},
    {id="server",  label="SERVER",   icon="🌐"},
    {id="misc",    label="MISC",     icon="🔧"},
    {id="cfg",     label="SETTINGS", icon="⚙"},
}

local NEW_BADGE = {
    autoDungeon=true,dungeonNormal=true,dungeonHard=true,
    dungeonNightmare=true,dungeonInferno=true,autoClearFloors=true,
    autoPickPowerUp=true,dungeonBossKill=true,autoCollectReward=true,
    dungeonServerHop=true,tpLucianNPC=true,
    autoFarmTrinket=true,autoEquipTrinket=true,autoFuseTrinket=true,
    autoScrapTrinket=true,trinketESP=true,trinketNotifier=true,
    autoReforge=true,tpTrinketExpert=true,tpTrinketRefiner=true,
    tpHotCold=true,tpPvPArena=true,findDungeonServer=true,trinketESPVis=true,
}

-- ============================================================
--  ANIME BANNER SYSTEM
--  Hiển thị các "nhân vật anime" bằng text art + glow
--  (Roblox không cho load URL ảnh ngoài nên dùng ImageLabel rbxassetid)
-- ============================================================

-- Asset IDs của decal "anime character" style đã có sẵn trên Roblox catalog
-- (đây là các decal public, không cần gamepass)
local ANIME_FRAMES = {
    -- Frame 1: silhouette trái
    {
        char  = "⚔ PHANTOM",
        sub   = "Auto Farm Master",
        color = Color3.fromRGB(0,255,136),
        bg    = Color3.fromRGB(0,30,15),
    },
    -- Frame 2
    {
        char  = "🏛 DUNGEON",
        sub   = "Update 29 — New!",
        color = Color3.fromRGB(138,43,226),
        bg    = Color3.fromRGB(15,5,30),
    },
    -- Frame 3
    {
        char  = "💎 TRINKET",
        sub   = "Mythical  ·  Epic  ·  Rare",
        color = Color3.fromRGB(255,140,0),
        bg    = Color3.fromRGB(30,15,0),
    },
    -- Frame 4
    {
        char  = "🍎 FRUIT",
        sub   = "Sniper  ·  Notifier  ·  Auto",
        color = Color3.fromRGB(204,68,255),
        bg    = Color3.fromRGB(25,5,35),
    },
    -- Frame 5
    {
        char  = "💀 BOSS",
        sub   = "Darkbeard  ·  Dough King",
        color = Color3.fromRGB(255,68,68),
        bg    = Color3.fromRGB(30,5,5),
    },
}

-- ASCII-style "anime lines" để tạo feel manga panel
local ASCII_LINES = {
    "  ╔══════════════╗",
    "  ║ ///  ///  // ║",
    "  ║ ///  ///  // ║",
    "  ║  ★  •  ★    ║",
    "  ║  ( ͡° ͜ʖ ͡°)  ║",
    "  ║  PHANTOM HUB ║",
    "  ╚══════════════╝",
}

-- ============================================================
--  WIDGETS
-- ============================================================
local function MakeToggle(parent, featureId, color)
    local isOn = Core.IsOn(featureId)
    local frame = Create("Frame",{Size=UDim2.new(0,44,0,24),
        BackgroundColor3=isOn and color or THEME.ToggleOff,
        BorderSizePixel=0,Parent=parent})
    Create("UICorner",{CornerRadius=UDim.new(1,0),Parent=frame})
    local stroke=Create("UIStroke",{Color=isOn and color or THEME.Border,
        Thickness=1,Parent=frame})
    local knob=Create("Frame",{Size=UDim2.new(0,18,0,18),
        Position=isOn and UDim2.new(0,23,0,3) or UDim2.new(0,3,0,3),
        BackgroundColor3=Color3.fromRGB(255,255,255),
        BorderSizePixel=0,Parent=frame})
    Create("UICorner",{CornerRadius=UDim.new(1,0),Parent=knob})
    local function Refresh(on)
        Tween(frame,{BackgroundColor3=on and color or THEME.ToggleOff})
        Tween(knob,{Position=on and UDim2.new(0,23,0,3) or UDim2.new(0,3,0,3)})
        Tween(stroke,{Color=on and color or THEME.Border})
    end
    frame.InputBegan:Connect(function(inp)
        if inp.UserInputType==Enum.UserInputType.MouseButton1 then
            Core.Toggle(featureId); Refresh(Core.IsOn(featureId))
        end
    end)
    Core.OnToggle(featureId,function(val) Refresh(val) end)
    return frame
end

local function MakeSlider(parent, featureId, color)
    local feat=Core._ById[featureId]
    local minV=feat.min or 0; local maxV=feat.max or 100
    local cur=Core.GetSlider(featureId)
    local c=Create("Frame",{Size=UDim2.new(1,0,0,20),BackgroundTransparency=1,Parent=parent})
    local track=Create("Frame",{Size=UDim2.new(1,-50,0,4),Position=UDim2.new(0,0,0.5,-2),
        BackgroundColor3=THEME.Border,BorderSizePixel=0,Parent=c})
    Create("UICorner",{CornerRadius=UDim.new(1,0),Parent=track})
    local fill=Create("Frame",{Size=UDim2.new((cur-minV)/(maxV-minV),0,1,0),
        BackgroundColor3=color,BorderSizePixel=0,Parent=track})
    Create("UICorner",{CornerRadius=UDim.new(1,0),Parent=fill})
    local lbl=Create("TextLabel",{Size=UDim2.new(0,44,1,0),Position=UDim2.new(1,-44,0,0),
        BackgroundTransparency=1,Text=tostring(cur),TextColor3=color,TextSize=11,
        Font=Enum.Font.Code,TextXAlignment=Enum.TextXAlignment.Right,Parent=c})
    local dragging=false
    track.InputBegan:Connect(function(i) if i.UserInputType==Enum.UserInputType.MouseButton1 then dragging=true end end)
    UserInputService.InputEnded:Connect(function(i) if i.UserInputType==Enum.UserInputType.MouseButton1 then dragging=false end end)
    UserInputService.InputChanged:Connect(function(i)
        if dragging and i.UserInputType==Enum.UserInputType.MouseMovement then
            local r=math.clamp((i.Position.X-track.AbsolutePosition.X)/track.AbsoluteSize.X,0,1)
            local v=math.round(minV+r*(maxV-minV))
            Core.SetSlider(featureId,v); fill.Size=UDim2.new(r,0,1,0); lbl.Text=tostring(v)
        end
    end)
    return c
end

local function MakeFeatureRow(scroll, feat, color)
    local rowH = feat.type=="slider" and 52 or 38
    local row=Create("Frame",{Size=UDim2.new(1,0,0,rowH),
        BackgroundColor3=THEME.Panel,BorderSizePixel=0,Parent=scroll})
    Create("UICorner",{CornerRadius=UDim.new(0,6),Parent=row})
    local accent=Create("Frame",{Size=UDim2.new(0,2,0.7,0),Position=UDim2.new(0,0,0.15,0),
        BackgroundColor3=(feat.type=="toggle" and Core.IsOn(feat.id)) and color or THEME.Border,
        BorderSizePixel=0,Parent=row})
    Create("UICorner",{CornerRadius=UDim.new(1,0),Parent=accent})
    if feat.type=="toggle" then
        Core.OnToggle(feat.id,function(v)
            Tween(accent,{BackgroundColor3=v and color or THEME.Border}) end)
    end
    local lblX=12
    if NEW_BADGE[feat.id] then
        lblX=50
        local badge=Create("TextLabel",{Size=UDim2.new(0,34,0,14),Position=UDim2.new(0,8,0,4),
            BackgroundColor3=Color3.fromRGB(255,50,50),BorderSizePixel=0,
            Text="NEW",TextColor3=Color3.fromRGB(255,255,255),TextSize=8,
            Font=Enum.Font.GothamBold,Parent=row})
        Create("UICorner",{CornerRadius=UDim.new(0,3),Parent=badge})
    end
    Create("TextLabel",{Size=UDim2.new(1,-70,0,20),
        Position=UDim2.new(0,lblX,0,feat.type=="slider" and 4 or 9),
        BackgroundTransparency=1,Text=feat.label,TextColor3=THEME.Text,
        TextSize=13,Font=Enum.Font.GothamSemibold,
        TextXAlignment=Enum.TextXAlignment.Left,Parent=row})
    if feat.type=="toggle" then
        local tog=MakeToggle(row,feat.id,color)
        tog.Position=UDim2.new(1,-54,0.5,-12)
    elseif feat.type=="slider" then
        local sl=MakeSlider(row,feat.id,color)
        sl.Position=UDim2.new(0,12,0,28); sl.Size=UDim2.new(1,-20,0,20)
    elseif feat.type=="button" then
        local btn=Create("TextButton",{Size=UDim2.new(0,52,0,22),
            Position=UDim2.new(1,-62,0.5,-11),
            BackgroundColor3=Color3.fromRGB(30,30,45),BorderSizePixel=0,
            Text="RUN",TextColor3=color,TextSize=11,Font=Enum.Font.GothamBold,Parent=row})
        Create("UICorner",{CornerRadius=UDim.new(0,4),Parent=btn})
        Create("UIStroke",{Color=color,Thickness=1,Transparency=0.6,Parent=btn})
        btn.MouseEnter:Connect(function() Tween(btn,{BackgroundColor3=Color3.fromRGB(45,45,65)}) end)
        btn.MouseLeave:Connect(function() Tween(btn,{BackgroundColor3=Color3.fromRGB(30,30,45)}) end)
        btn.MouseButton1Click:Connect(function()
            Core.Log(feat.label.." kích hoạt","success")
            if Core._Callbacks[feat.id] then Core._Callbacks[feat.id](true) end
        end)
    end
    return row
end

local function BuildTabContent(scroll, tabId)
    for _,c in ipairs(scroll:GetChildren()) do
        if not c:IsA("UIListLayout") and not c:IsA("UIPadding") then c:Destroy() end
    end
    local color=THEME.TabColors[tabId] or THEME.Accent
    local features=Core.GetGroup(tabId)
    if tabId=="dungeon" or tabId=="trinket" then
        local txt=tabId=="dungeon"
            and "🏛  DUNGEON SYSTEM  —  Blox Fruits Update 29"
            or  "💎  TRINKET SYSTEM  —  Blox Fruits Update 29"
        local ban=Create("Frame",{Size=UDim2.new(1,0,0,32),
            BackgroundColor3=Color3.fromRGB(20,10,30),BorderSizePixel=0,Parent=scroll})
        Create("UICorner",{CornerRadius=UDim.new(0,6),Parent=ban})
        Create("UIStroke",{Color=color,Thickness=1,Transparency=0.5,Parent=ban})
        Create("TextLabel",{Size=UDim2.new(1,0,1,0),BackgroundTransparency=1,
            Text=txt,TextColor3=color,TextSize=11,Font=Enum.Font.GothamBold,Parent=ban})
    end
    for _,feat in ipairs(features) do MakeFeatureRow(scroll,feat,color) end
    local layout=scroll:FindFirstChildOfClass("UIListLayout")
    if layout then
        scroll.CanvasSize=UDim2.new(0,0,0,layout.AbsoluteContentSize.Y+16) end
end

-- ============================================================
--  ANIME BANNER BUILDER
--  Tạo animated banner trên header với text frames
-- ============================================================
local function BuildAnimeBanner(parent)
    -- Container banner nằm bên phải header
    local BannerFrame = Create("Frame",{
        Name="AnimeBanner",
        Size=UDim2.new(0,220,0,46),
        Position=UDim2.new(1,-300,0,0),
        BackgroundTransparency=1,
        ClipsDescendants=true,
        ZIndex=5,
        Parent=parent,
    })

    -- Tạo 2 "slide" — hiển thị xen kẽ nhau
    local function MakeSlide(frame, idx)
        local bg = Create("Frame",{
            Size=UDim2.new(1,0,1,0),
            Position=UDim2.new(idx==1 and 0 or 1, 0, 0, 0),
            BackgroundColor3=frame.bg,
            BackgroundTransparency=0.4,
            BorderSizePixel=0,
            ZIndex=4,
            Parent=BannerFrame,
        })
        Create("UICorner",{CornerRadius=UDim.new(0,6),Parent=bg})
        -- Glow stroke warna frame
        Create("UIStroke",{Color=frame.color,Thickness=1,
            Transparency=0.4,Parent=bg})
        -- Char text (besar)
        Create("TextLabel",{
            Size=UDim2.new(1,-8,0,26),Position=UDim2.new(0,6,0,3),
            BackgroundTransparency=1,Text=frame.char,
            TextColor3=frame.color,TextSize=17,Font=Enum.Font.GothamBlack,
            TextXAlignment=Enum.TextXAlignment.Left,ZIndex=5,Parent=bg})
        -- Sub text
        Create("TextLabel",{
            Size=UDim2.new(1,-8,0,16),Position=UDim2.new(0,6,0,28),
            BackgroundTransparency=1,Text=frame.sub,
            TextColor3=Color3.fromRGB(180,180,200),TextSize=9,Font=Enum.Font.Code,
            TextXAlignment=Enum.TextXAlignment.Left,ZIndex=5,Parent=bg})
        -- Dekorasi garis vertikal warna
        Create("Frame",{Size=UDim2.new(0,2,0.7,0),Position=UDim2.new(0,2,0.15,0),
            BackgroundColor3=frame.color,BorderSizePixel=0,ZIndex=6,Parent=bg})
        return bg
    end

    local slides = {}
    for i,frame in ipairs(ANIME_FRAMES) do
        slides[i] = MakeSlide(frame, i)
    end

    -- Set slide pertama visible
    slides[1].Position = UDim2.new(0,0,0,0)
    for i=2,#slides do
        slides[i].Position = UDim2.new(1.05,0,0,0)
    end

    -- Animasi slideshow
    local current = 1
    local sliding = false

    task.spawn(function()
        while true do
            task.wait(3.5)
            if sliding then continue end
            sliding = true

            local next = (current % #slides) + 1
            -- Slide tiếp theo vào từ phải
            slides[next].Position = UDim2.new(1.05,0,0,0)

            -- Current slide keluar ke kiri
            Tween(slides[current], {Position=UDim2.new(-1.05,0,0,0)},
                0.55, Enum.EasingStyle.Quart, Enum.EasingDirection.InOut)
            -- Next slide masuk dari kanan
            Tween(slides[next], {Position=UDim2.new(0,0,0,0)},
                0.55, Enum.EasingStyle.Quart, Enum.EasingDirection.InOut)
            task.wait(0.6)
            current = next
            sliding = false
        end
    end)

    return BannerFrame
end

-- ============================================================
--  BUILD CHÍNH
-- ============================================================
function UI.Build(coreRef)
    Core = coreRef

    local ScreenGui=Create("ScreenGui",{Name="PhantomHubGui",ResetOnSpawn=false,
        ZIndexBehavior=Enum.ZIndexBehavior.Sibling,Parent=PlayerGui})
    UI._Gui=ScreenGui

    local Main=Create("Frame",{Name="Main",Size=UDim2.new(0,720,0,500),
        Position=UDim2.new(0.5,-360,0.5,-250),
        BackgroundColor3=THEME.Bg,BorderSizePixel=0,
        ClipsDescendants=true,Parent=ScreenGui})
    Create("UICorner",{CornerRadius=UDim.new(0,12),Parent=Main})
    Create("UIStroke",{Color=THEME.Border,Thickness=1,Parent=Main})

    -- ── HEADER ──────────────────────────────────────────────
    local Header=Create("Frame",{Name="Header",Size=UDim2.new(1,0,0,46),
        BackgroundColor3=Color3.fromRGB(8,8,14),BorderSizePixel=0,Parent=Main})
    Create("UIStroke",{Color=THEME.Border,Thickness=1,
        ApplyStrokeMode=Enum.ApplyStrokeMode.Border,Parent=Header})

    -- Logo
    Create("TextLabel",{Size=UDim2.new(0,200,1,0),Position=UDim2.new(0,14,0,0),
        BackgroundTransparency=1,Text="👻  PHANTOM HUB",
        TextColor3=THEME.Accent,TextSize=16,Font=Enum.Font.GothamBlack,
        TextXAlignment=Enum.TextXAlignment.Left,Parent=Header})

    -- ── ANIME BANNER (area tengah header) ───────────────────
    BuildAnimeBanner(Header)

    -- Version label
    Create("TextLabel",{Size=UDim2.new(0,80,1,0),Position=UDim2.new(1,-86,0,0),
        BackgroundTransparency=1,Text="v4.1.0  ●",
        TextColor3=THEME.Accent,TextSize=9,Font=Enum.Font.Code,
        TextXAlignment=Enum.TextXAlignment.Right,Parent=Header})

    -- Tombol close/minimize
    local minimised=false
    local Content
    local function HeaderBtn(txt,xOff,cb)
        local b=Create("TextButton",{Size=UDim2.new(0,22,0,22),
            Position=UDim2.new(1,xOff,0.5,-11),
            BackgroundColor3=Color3.fromRGB(30,30,45),BorderSizePixel=0,
            Text=txt,TextColor3=THEME.TextDim,TextSize=12,
            Font=Enum.Font.GothamBold,Parent=Header})
        Create("UICorner",{CornerRadius=UDim.new(0,4),Parent=b})
        b.MouseButton1Click:Connect(cb)
        return b
    end
    HeaderBtn("✕",-28,function() ScreenGui:Destroy() end)
    HeaderBtn("─",-54,function()
        minimised=not minimised
        if Content then
            Content.Visible=not minimised
            Tween(Main,{Size=minimised and UDim2.new(0,720,0,46) or UDim2.new(0,720,0,500)},0.25)
        end
    end)
    MakeDraggable(Main,Header)

    -- ── CONTENT ──────────────────────────────────────────────
    Content=Create("Frame",{Name="Content",Size=UDim2.new(1,0,1,-46),
        Position=UDim2.new(0,0,0,46),BackgroundTransparency=1,
        BorderSizePixel=0,Parent=Main})

    local Sidebar=Create("Frame",{Name="Sidebar",Size=UDim2.new(0,74,1,0),
        BackgroundColor3=THEME.Sidebar,BorderSizePixel=0,Parent=Content})
    Create("UIStroke",{Color=THEME.Border,Thickness=1,
        ApplyStrokeMode=Enum.ApplyStrokeMode.Border,Parent=Footer})

    local UptimeLabel=Create("TextLabel",{Size=UDim2.new(0,260,1,0),Position=UDim2.new(0,12,0,0),
        BackgroundTransparency=1,Text="UPTIME: 00:00:00",
        TextColor3=THEME.TextMuted,TextSize=9,Font=Enum.Font.Code,
        TextXAlignment=Enum.TextXAlignment.Left,Parent=Footer})

    Create("TextLabel",{Size=UDim2.new(0,220,1,0),Position=UDim2.new(1,-230,0,0),
        BackgroundTransparency=1,Text="● INJECTED  |  Update 29  |  v4.1.0",
        TextColor3=THEME.Success,TextSize=9,Font=Enum.Font.Code,
        TextXAlignment=Enum.TextXAlignment.Right,Parent=Footer})

    -- Uptime loop
    local startTime=os.clock()
    RunService.Heartbeat:Connect(function()
        local e=os.clock()-startTime
        UptimeLabel.Text=string.format("UPTIME: %02d:%02d:%02d  |  %d ACTIVE",
            math.floor(e/3600),math.floor((e%3600)/60),math.floor(e%60),Core.GetActiveCount())
    end)

    UI._Main=Main
    UI._FeatureScroll=FeatureScroll
    UI._SelectTab=SelectTab
end

function UI.Cleanup()
    if UI._Gui then UI._Gui:Destroy(); UI._Gui=nil end
end

return UI

