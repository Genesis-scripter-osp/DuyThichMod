-- ============================================================
--  PHANTOM HUB  |  ui.lua   v4.2.0
--  Fix: Menu nhỏ hơn (560x400) · Sidebar gọn · Font nhỏ hơn
-- ============================================================

local Players          = game:GetService("Players")
local TweenService     = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local RunService       = game:GetService("RunService")

local LocalPlayer = Players.LocalPlayer
local PlayerGui   = LocalPlayer:WaitForChild("PlayerGui")

local UI = {}
local Core

local function Create(class, props)
    local obj = Instance.new(class)
    for k,v in pairs(props) do if k~="Parent" then (obj::any)[k]=v end end
    if props.Parent then obj.Parent = props.Parent end
    return obj
end

local function Tween(obj, goal, t, style, dir)
    TweenService:Create(obj, TweenInfo.new(
        t or 0.2, style or Enum.EasingStyle.Quad,
        dir or Enum.EasingDirection.Out), goal):Play()
end

local function MakeDraggable(frame, handle)
    local drag, ds, sp
    local h = handle or frame
    h.InputBegan:Connect(function(i)
        if i.UserInputType==Enum.UserInputType.MouseButton1 then
            drag=true; ds=i.Position; sp=frame.Position end
    end)
    UserInputService.InputChanged:Connect(function(i)
        if drag and i.UserInputType==Enum.UserInputType.MouseMovement then
            local d=i.Position-ds
            frame.Position=UDim2.new(sp.X.Scale,sp.X.Offset+d.X,sp.Y.Scale,sp.Y.Offset+d.Y)
        end
    end)
    UserInputService.InputEnded:Connect(function(i)
        if i.UserInputType==Enum.UserInputType.MouseButton1 then drag=false end
    end)
end

-- ============================================================
--  THEME
-- ============================================================
local T = {
    Bg        = Color3.fromRGB(10,10,18),
    Panel     = Color3.fromRGB(16,16,26),
    Sidebar   = Color3.fromRGB(12,12,20),
    Border    = Color3.fromRGB(40,40,60),
    Accent    = Color3.fromRGB(0,255,136),
    Text      = Color3.fromRGB(220,220,230),
    TextDim   = Color3.fromRGB(100,100,120),
    TextMuted = Color3.fromRGB(55,55,70),
    Success   = Color3.fromRGB(0,255,136),
    ToggleOff = Color3.fromRGB(35,35,50),
    TC = {
        main    = Color3.fromRGB(0,255,136),
        combat  = Color3.fromRGB(255,68,68),
        boss    = Color3.fromRGB(255,136,0),
        dungeon = Color3.fromRGB(138,43,226),
        trinket = Color3.fromRGB(255,140,0),
        sea     = Color3.fromRGB(0,136,255),
        fruit   = Color3.fromRGB(204,68,255),
        raid    = Color3.fromRGB(255,221,0),
        tp      = Color3.fromRGB(68,255,221),
        esp     = Color3.fromRGB(255,68,170),
        player  = Color3.fromRGB(136,255,68),
        stats   = Color3.fromRGB(255,170,0),
        server  = Color3.fromRGB(170,170,255),
        misc    = Color3.fromRGB(200,200,200),
        cfg     = Color3.fromRGB(120,120,140),
    }
}

local TABS = {
    {id="main",    label="MAIN",    icon="⚡"},
    {id="combat",  label="COMBAT",  icon="⚔"},
    {id="boss",    label="BOSS",    icon="💀"},
    {id="dungeon", label="DUNGEON", icon="🏛"},
    {id="trinket", label="TRINKET", icon="💎"},
    {id="sea",     label="SEA",     icon="🌊"},
    {id="fruit",   label="FRUIT",   icon="🍎"},
    {id="raid",    label="RAID",    icon="🏴"},
    {id="tp",      label="TELEPORT",icon="🌀"},
    {id="esp",     label="ESP",     icon="👁"},
    {id="player",  label="PLAYER",  icon="🧍"},
    {id="stats",   label="STATS",   icon="📊"},
    {id="server",  label="SERVER",  icon="🌐"},
    {id="misc",    label="MISC",    icon="🔧"},
    {id="cfg",     label="SETTINGS",icon="⚙"},
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
--  ANIME BANNER (slideshow header)
-- ============================================================
local ANIME_FRAMES = {
    {char="⚡ PHANTOM",  sub="Auto Farm Master",          color=Color3.fromRGB(0,255,136),   bg=Color3.fromRGB(0,25,12)},
    {char="🏛 DUNGEON",  sub="Update 29 — New!",          color=Color3.fromRGB(138,43,226),  bg=Color3.fromRGB(12,4,25)},
    {char="💎 TRINKET",  sub="Mythical · Epic · Rare",    color=Color3.fromRGB(255,140,0),   bg=Color3.fromRGB(25,12,0)},
    {char="🍎 FRUIT",    sub="Sniper · Notifier · Auto",  color=Color3.fromRGB(204,68,255),  bg=Color3.fromRGB(20,4,28)},
    {char="💀 BOSS",     sub="Darkbeard · Dough King",    color=Color3.fromRGB(255,68,68),   bg=Color3.fromRGB(25,4,4)},
}

local function BuildAnimeBanner(parent)
    local BF = Create("Frame",{Name="AnimeBanner",
        Size=UDim2.new(0,180,0,38),Position=UDim2.new(1,-248,0,4),
        BackgroundTransparency=1,ClipsDescendants=true,ZIndex=5,Parent=parent})

    local slides={}
    for i,f in ipairs(ANIME_FRAMES) do
        local bg=Create("Frame",{
            Size=UDim2.new(1,0,1,0),
            Position=UDim2.new(i==1 and 0 or 1.05,0,0,0),
            BackgroundColor3=f.bg,BackgroundTransparency=0.3,
            BorderSizePixel=0,ZIndex=4,Parent=BF})
        Create("UICorner",{CornerRadius=UDim.new(0,6),Parent=bg})
        Create("UIStroke",{Color=f.color,Thickness=1,Transparency=0.5,Parent=bg})
        Create("Frame",{Size=UDim2.new(0,2,0.7,0),Position=UDim2.new(0,2,0.15,0),
            BackgroundColor3=f.color,BorderSizePixel=0,ZIndex=6,Parent=bg})
        Create("TextLabel",{Size=UDim2.new(1,-8,0,20),Position=UDim2.new(0,7,0,2),
            BackgroundTransparency=1,Text=f.char,TextColor3=f.color,
            TextSize=13,Font=Enum.Font.GothamBlack,
            TextXAlignment=Enum.TextXAlignment.Left,ZIndex=5,Parent=bg})
        Create("TextLabel",{Size=UDim2.new(1,-8,0,14),Position=UDim2.new(0,7,0,22),
            BackgroundTransparency=1,Text=f.sub,TextColor3=Color3.fromRGB(170,170,190),
            TextSize=8,Font=Enum.Font.Code,
            TextXAlignment=Enum.TextXAlignment.Left,ZIndex=5,Parent=bg})
        slides[i]=bg
    end

    local cur,sliding=1,false
    task.spawn(function()
        while true do
            task.wait(3.5)
            if sliding then continue end
            sliding=true
            local nxt=(cur%#slides)+1
            slides[nxt].Position=UDim2.new(1.05,0,0,0)
            Tween(slides[cur],{Position=UDim2.new(-1.05,0,0,0)},0.5,Enum.EasingStyle.Quart,Enum.EasingDirection.InOut)
            Tween(slides[nxt],{Position=UDim2.new(0,0,0,0)},0.5,Enum.EasingStyle.Quart,Enum.EasingDirection.InOut)
            task.wait(0.55); cur=nxt; sliding=false
        end
    end)
    return BF
end

-- ============================================================
--  WIDGETS
-- ============================================================
local function MakeToggle(parent, id, color)
    local on=Core.IsOn(id)
    local f=Create("Frame",{Size=UDim2.new(0,38,0,20),
        BackgroundColor3=on and color or T.ToggleOff,BorderSizePixel=0,Parent=parent})
    Create("UICorner",{CornerRadius=UDim.new(1,0),Parent=f})
    local s=Create("UIStroke",{Color=on and color or T.Border,Thickness=1,Parent=f})
    local k=Create("Frame",{Size=UDim2.new(0,14,0,14),
        Position=on and UDim2.new(0,21,0,3) or UDim2.new(0,3,0,3),
        BackgroundColor3=Color3.fromRGB(255,255,255),BorderSizePixel=0,Parent=f})
    Create("UICorner",{CornerRadius=UDim.new(1,0),Parent=k})
    local function R(v)
        Tween(f,{BackgroundColor3=v and color or T.ToggleOff})
        Tween(k,{Position=v and UDim2.new(0,21,0,3) or UDim2.new(0,3,0,3)})
        Tween(s,{Color=v and color or T.Border})
    end
    f.InputBegan:Connect(function(i)
        if i.UserInputType==Enum.UserInputType.MouseButton1 then Core.Toggle(id); R(Core.IsOn(id)) end
    end)
    Core.OnToggle(id,function(v) R(v) end)
    return f
end

local function MakeSlider(parent, id, color)
    local feat=Core._ById[id]
    local mn=feat.min or 0; local mx=feat.max or 100; local cur=Core.GetSlider(id)
    local c=Create("Frame",{Size=UDim2.new(1,0,0,18),BackgroundTransparency=1,Parent=parent})
    local tr=Create("Frame",{Size=UDim2.new(1,-42,0,4),Position=UDim2.new(0,0,0.5,-2),
        BackgroundColor3=T.Border,BorderSizePixel=0,Parent=c})
    Create("UICorner",{CornerRadius=UDim.new(1,0),Parent=tr})
    local fi=Create("Frame",{Size=UDim2.new((cur-mn)/(mx-mn),0,1,0),
        BackgroundColor3=color,BorderSizePixel=0,Parent=tr})
    Create("UICorner",{CornerRadius=UDim.new(1,0),Parent=fi})
    local lb=Create("TextLabel",{Size=UDim2.new(0,38,1,0),Position=UDim2.new(1,-38,0,0),
        BackgroundTransparency=1,Text=tostring(cur),TextColor3=color,TextSize=10,
        Font=Enum.Font.Code,TextXAlignment=Enum.TextXAlignment.Right,Parent=c})
    local drag=false
    tr.InputBegan:Connect(function(i) if i.UserInputType==Enum.UserInputType.MouseButton1 then drag=true end end)
    UserInputService.InputEnded:Connect(function(i) if i.UserInputType==Enum.UserInputType.MouseButton1 then drag=false end end)
    UserInputService.InputChanged:Connect(function(i)
        if drag and i.UserInputType==Enum.UserInputType.MouseMovement then
            local r=math.clamp((i.Position.X-tr.AbsolutePosition.X)/tr.AbsoluteSize.X,0,1)
            local v=math.round(mn+r*(mx-mn))
            Core.SetSlider(id,v); fi.Size=UDim2.new(r,0,1,0); lb.Text=tostring(v)
        end
    end)
    return c
end

local function MakeRow(scroll, feat, color)
    local h=feat.type=="slider" and 46 or 34
    local row=Create("Frame",{Size=UDim2.new(1,0,0,h),
        BackgroundColor3=T.Panel,BorderSizePixel=0,Parent=scroll})
    Create("UICorner",{CornerRadius=UDim.new(0,5),Parent=row})
    local ac=Create("Frame",{Size=UDim2.new(0,2,0.65,0),Position=UDim2.new(0,0,0.175,0),
        BackgroundColor3=(feat.type=="toggle" and Core.IsOn(feat.id)) and color or T.Border,
        BorderSizePixel=0,Parent=row})
    Create("UICorner",{CornerRadius=UDim.new(1,0),Parent=ac})
    if feat.type=="toggle" then
        Core.OnToggle(feat.id,function(v) Tween(ac,{BackgroundColor3=v and color or T.Border}) end)
    end
    local lx=10
    if NEW_BADGE[feat.id] then
        lx=44
        local b=Create("TextLabel",{Size=UDim2.new(0,30,0,12),Position=UDim2.new(0,7,0,3),
            BackgroundColor3=Color3.fromRGB(255,50,50),BorderSizePixel=0,
            Text="NEW",TextColor3=Color3.fromRGB(255,255,255),TextSize=7,
            Font=Enum.Font.GothamBold,Parent=row})
        Create("UICorner",{CornerRadius=UDim.new(0,3),Parent=b})
    end
    Create("TextLabel",{Size=UDim2.new(1,-60,0,18),
        Position=UDim2.new(0,lx,0,feat.type=="slider" and 3 or 8),
        BackgroundTransparency=1,Text=feat.label,TextColor3=T.Text,
        TextSize=11,Font=Enum.Font.GothamSemibold,
        TextXAlignment=Enum.TextXAlignment.Left,Parent=row})
    if feat.type=="toggle" then
        local tog=MakeToggle(row,feat.id,color)
        tog.Position=UDim2.new(1,-46,0.5,-10)
    elseif feat.type=="slider" then
        local sl=MakeSlider(row,feat.id,color)
        sl.Position=UDim2.new(0,10,0,26); sl.Size=UDim2.new(1,-16,0,18)
    elseif feat.type=="button" then
        local btn=Create("TextButton",{Size=UDim2.new(0,44,0,20),
            Position=UDim2.new(1,-52,0.5,-10),
            BackgroundColor3=Color3.fromRGB(28,28,42),BorderSizePixel=0,
            Text="RUN",TextColor3=color,TextSize=10,Font=Enum.Font.GothamBold,Parent=row})
        Create("UICorner",{CornerRadius=UDim.new(0,4),Parent=btn})
        Create("UIStroke",{Color=color,Thickness=1,Transparency=0.6,Parent=btn})
        btn.MouseEnter:Connect(function() Tween(btn,{BackgroundColor3=Color3.fromRGB(42,42,62)}) end)
        btn.MouseLeave:Connect(function() Tween(btn,{BackgroundColor3=Color3.fromRGB(28,28,42)}) end)
        btn.MouseButton1Click:Connect(function()
            Core.Log(feat.label.." kích hoạt","success")
            if Core._Callbacks[feat.id] then Core._Callbacks[feat.id](true) end
        end)
    end
    return row
end

local function BuildTab(scroll, tabId)
    for _,c in ipairs(scroll:GetChildren()) do
        if not c:IsA("UIListLayout") and not c:IsA("UIPadding") then c:Destroy() end
    end
    local color=T.TC[tabId] or T.Accent
    local feats=Core.GetGroup(tabId)
    if tabId=="dungeon" or tabId=="trinket" then
        local txt=tabId=="dungeon" and "🏛 DUNGEON — Update 29" or "💎 TRINKET — Update 29"
        local ban=Create("Frame",{Size=UDim2.new(1,0,0,26),
            BackgroundColor3=Color3.fromRGB(18,8,28),BorderSizePixel=0,Parent=scroll})
        Create("UICorner",{CornerRadius=UDim.new(0,5),Parent=ban})
        Create("UIStroke",{Color=color,Thickness=1,Transparency=0.5,Parent=ban})
        Create("TextLabel",{Size=UDim2.new(1,0,1,0),BackgroundTransparency=1,
            Text=txt,TextColor3=color,TextSize=10,Font=Enum.Font.GothamBold,Parent=ban})
    end
    for _,feat in ipairs(feats) do MakeRow(scroll,feat,color) end
    local layout=scroll:FindFirstChildOfClass("UIListLayout")
    if layout then scroll.CanvasSize=UDim2.new(0,0,0,layout.AbsoluteContentSize.Y+14) end
end

-- ============================================================
--  BUILD CHÍNH — window 560×400
-- ============================================================
function UI.Build(coreRef)
    Core=coreRef

    local SG=Create("ScreenGui",{Name="PhantomHubGui",ResetOnSpawn=false,
        ZIndexBehavior=Enum.ZIndexBehavior.Sibling,Parent=PlayerGui})
    UI._Gui=SG

    -- Main window 560 × 400
    local Main=Create("Frame",{Name="Main",Size=UDim2.new(0,560,0,400),
        Position=UDim2.new(0.5,-280,0.5,-200),
        BackgroundColor3=T.Bg,BorderSizePixel=0,
        ClipsDescendants=true,Parent=SG})
    Create("UICorner",{CornerRadius=UDim.new(0,10),Parent=Main})
    Create("UIStroke",{Color=T.Border,Thickness=1,Parent=Main})

    -- Header 40px
    local Header=Create("Frame",{Name="Header",Size=UDim2.new(1,0,0,40),
        BackgroundColor3=Color3.fromRGB(8,8,14),BorderSizePixel=0,Parent=Main})
    Create("UIStroke",{Color=T.Border,Thickness=1,
        ApplyStrokeMode=Enum.ApplyStrokeMode.Border,Parent=Header})

    Create("TextLabel",{Size=UDim2.new(0,180,1,0),Position=UDim2.new(0,10,0,0),
        BackgroundTransparency=1,Text="👻  PHANTOM HUB",
        TextColor3=T.Accent,TextSize=14,Font=Enum.Font.GothamBlack,
        TextXAlignment=Enum.TextXAlignment.Left,Parent=Header})

    BuildAnimeBanner(Header)

    Create("TextLabel",{Size=UDim2.new(0,70,1,0),Position=UDim2.new(1,-76,0,0),
        BackgroundTransparency=1,Text="v4.2.0 ●",
        TextColor3=T.Accent,TextSize=9,Font=Enum.Font.Code,
        TextXAlignment=Enum.TextXAlignment.Right,Parent=Header})

    local minimised=false; local Content
    
    local function HBtn(txt,xOff,cb)
        local b=Create("TextButton",{Size=UDim2.new(0,20,0,20),
            Position=UDim2.new(1,xOff,0.5,-10),
            BackgroundColor3=Color3.fromRGB(28,28,42),BorderSizePixel=0,
            Text=txt,TextColor3=T.TextDim,TextSize=11,Font=Enum.Font.GothamBold,Parent=Header})
        Create("UICorner",{CornerRadius=UDim.new(0,4),Parent=b})
        b.MouseButton1Click:Connect(cb); return b
    end
    HBtn("✕",-24,function() SG:Destroy() end)
    HBtn("─",-48,function()
        minimised=not minimised
        if Content then
            Content.Visible=not minimised
            Tween(Main,{Size=minimised and UDim2.new(0,560,0,40) or UDim2.new(0,560,0,400)},0.22)
        end
    end)
    MakeDraggable(Main,Header)

    Content=Create("Frame",{Name="Content",Size=UDim2.new(1,0,1,-40),
        Position=UDim2.new(0,0,0,40),BackgroundTransparency=1,
        BorderSizePixel=0,Parent=Main})

    -- Sidebar 62px
    local Sidebar=Create("Frame",{Size=UDim2.new(0,62,1,0),
        BackgroundColor3=T.Sidebar,BorderSizePixel=0,Parent=Content})
    Create("UIStroke",{Color=T.Border,Thickness=1,
        ApplyStrokeMode=Enum.ApplyStrokeMode.Border,Parent=Sidebar})

    local SScroll=Create("ScrollingFrame",{Size=UDim2.new(1,0,1,0),
        BackgroundTransparency=1,BorderSizePixel=0,ScrollBarThickness=2,
        ScrollBarImageColor3=T.Border,
        CanvasSize=UDim2.new(0,0,0,#TABS*58),Parent=Sidebar})
    Create("UIListLayout",{Padding=UDim.new(0,2),
        HorizontalAlignment=Enum.HorizontalAlignment.Center,Parent=SScroll})
    Create("UIPadding",{PaddingTop=UDim.new(0,4),PaddingBottom=UDim.new(0,4),Parent=SScroll})

    -- Panel
    local Panel=Create("Frame",{Size=UDim2.new(1,-62,1,0),
        Position=UDim2.new(0,62,0,0),BackgroundTransparency=1,
        BorderSizePixel=0,Parent=Content})

    local TH=Create("Frame",{Size=UDim2.new(1,0,0,32),
        BackgroundColor3=Color3.fromRGB(12,12,20),BorderSizePixel=0,Parent=Panel})
    Create("UIStroke",{Color=T.Border,Thickness=1,
        ApplyStrokeMode=Enum.ApplyStrokeMode.Border,Parent=TH})

    local TTitle=Create("TextLabel",{Size=UDim2.new(1,-12,1,0),Position=UDim2.new(0,10,0,0),
        BackgroundTransparency=1,Text="MAIN",TextColor3=T.Accent,TextSize=12,
        Font=Enum.Font.GothamBlack,TextXAlignment=Enum.TextXAlignment.Left,Parent=TH})

    local FCount=Create("TextLabel",{Size=UDim2.new(0,90,1,0),Position=UDim2.new(1,-94,0,0),
        BackgroundTransparency=1,Text="",TextColor3=T.TextMuted,TextSize=9,Font=Enum.Font.Code,
        TextXAlignment=Enum.TextXAlignment.Right,Parent=TH})

    local FScroll=Create("ScrollingFrame",{
        Size=UDim2.new(1,0,1,-32),Position=UDim2.new(0,0,0,32),
        BackgroundTransparency=1,BorderSizePixel=0,
        ScrollBarThickness=3,ScrollBarImageColor3=T.Border,
        CanvasSize=UDim2.new(0,0,0,0),Parent=Panel})
    Create("UIListLayout",{Padding=UDim.new(0,3),SortOrder=Enum.SortOrder.LayoutOrder,Parent=FScroll})
    Create("UIPadding",{PaddingTop=UDim.new(0,6),PaddingBottom=UDim.new(0,6),
        PaddingLeft=UDim.new(0,6),PaddingRight=UDim.new(0,6),Parent=FScroll})

    -- Footer 20px
    local Footer=Create("Frame",{Size=UDim2.new(0,560,0,20),
        Position=UDim2.new(0,0,1,-20),BackgroundColor3=Color3.fromRGB(6,6,10),
        BorderSizePixel=0,ZIndex=10,Parent=Main})
    Create("UIStroke",{Color=T.Border,Thickness=1,
        ApplyStrokeMode=Enum.ApplyStrokeMode.Border,Parent=Footer})

    local UptLbl=Create("TextLabel",{Size=UDim2.new(0,220,1,0),Position=UDim2.new(0,8,0,0),
        BackgroundTransparency=1,Text="UPTIME: 00:00:00",
        TextColor3=T.TextMuted,TextSize=8,Font=Enum.Font.Code,
        TextXAlignment=Enum.TextXAlignment.Left,Parent=Footer})

    Create("TextLabel",{Size=UDim2.new(0,180,1,0),Position=UDim2.new(1,-185,0,0),
        BackgroundTransparency=1,Text="● INJECTED  |  Update 29",
        TextColor3=T.Success,TextSize=8,Font=Enum.Font.Code,
        TextXAlignment=Enum.TextXAlignment.Right,Parent=Footer})

    -- Uptime
    local st=os.clock()
    RunService.Heartbeat:Connect(function()
        local e=os.clock()-st
        UptLbl.Text=string.format("UPTIME: %02d:%02d:%02d  |  %d ON",
            math.floor(e/3600),math.floor((e%3600)/60),math.floor(e%60),Core.GetActiveCount())
    end)

    -- Sidebar buttons (52px height)
    local activeBtn=nil; local curTab="main"

    local function SelTab(tabId, btn)
        if activeBtn then
            Tween(activeBtn,{BackgroundColor3=Color3.fromRGB(0,0,0)})
            activeBtn.BackgroundTransparency=1
            local s=activeBtn:FindFirstChildOfClass("UIStroke")
            if s then s.Color=Color3.fromRGB(0,0,0) end
        end
        curTab=tabId; activeBtn=btn
        local color=T.TC[tabId] or T.Accent
        Tween(btn,{BackgroundColor3=color}); btn.BackgroundTransparency=0.88
        local stroke=btn:FindFirstChildOfClass("UIStroke")
        if stroke then Tween(stroke,{Color=color}) end
        for _,t in ipairs(TABS) do
            if t.id==tabId then
                TTitle.Text=t.icon.." "..t.label
                TTitle.TextColor3=color; break
            end
        end
        local feats=Core.GetGroup(tabId)
        FCount.Text=#feats.." FEATS"
        BuildTab(FScroll,tabId)
    end

    for _,tab in ipairs(TABS) do
        local color=T.TC[tab.id] or T.Accent
        local btn=Create("TextButton",{Size=UDim2.new(0,54,0,52),
            BackgroundColor3=color,BackgroundTransparency=1,
            BorderSizePixel=0,Text="",Parent=SScroll})
        Create("UICorner",{CornerRadius=UDim.new(0,7),Parent=btn})
        Create("UIStroke",{Color=Color3.fromRGB(0,0,0),Thickness=1,Transparency=1,Parent=btn})
        if tab.id=="dungeon" or tab.id=="trinket" then
            local dot=Create("Frame",{Size=UDim2.new(0,7,0,7),Position=UDim2.new(1,-9,0,2),
                BackgroundColor3=Color3.fromRGB(255,50,50),BorderSizePixel=0,ZIndex=5,Parent=btn})
            Create("UICorner",{CornerRadius=UDim.new(1,0),Parent=dot})
        end
        Create("TextLabel",{Size=UDim2.new(1,0,0,22),Position=UDim2.new(0,0,0,6),
            BackgroundTransparency=1,Text=tab.icon,TextSize=17,
            Font=Enum.Font.GothamBold,TextColor3=T.Text,Parent=btn})
        Create("TextLabel",{Size=UDim2.new(1,0,0,12),Position=UDim2.new(0,0,0,30),
            BackgroundTransparency=1,Text=tab.label:sub(1,5),TextSize=7,
            Font=Enum.Font.Code,TextColor3=T.TextDim,Parent=btn})
        btn.MouseEnter:Connect(function()
            if curTab~=tab.id then btn.BackgroundColor3=color; Tween(btn,{BackgroundTransparency=0.92}) end
        end)
        btn.MouseLeave:Connect(function()
            if curTab~=tab.id then Tween(btn,{BackgroundTransparency=1}) end
        end)
        btn.MouseButton1Click:Connect(function() SelTab(tab.id,btn) end)
        if tab.id=="main" then task.defer(function() SelTab("main",btn) end) end
    end

    UI._Main=Main; UI._FeatureScroll=FScroll; UI._SelectTab=SelTab
end

function UI.Cleanup()
    if UI._Gui then UI._Gui:Destroy(); UI._Gui=nil end
end

return UI


