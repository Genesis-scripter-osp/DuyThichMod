-- ============================================================
--  PHANTOM HUB  |  main.lua  (Entry Point)
--  Version  : v4.1.0
--  Thêm     : Loading Screen % · Toggle Button nổi · Anime Banner
-- ============================================================

if _G.PhantomHub_Loaded then warn("[PhantomHub] Đã load rồi.") return end
_G.PhantomHub_Loaded = true

local Players          = game:GetService("Players")
local TweenService     = game:GetService("TweenService")
local RunService       = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local LocalPlayer      = Players.LocalPlayer
local PlayerGui        = LocalPlayer:WaitForChild("PlayerGui")

local function Create(class, props)
    local obj = Instance.new(class)
    for k,v in pairs(props) do if k~="Parent" then (obj::any)[k]=v end end
    if props.Parent then obj.Parent = props.Parent end
    return obj
end
local function Tween(obj, goal, t, style, dir)
    TweenService:Create(obj, TweenInfo.new(
        t or 0.3,
        style or Enum.EasingStyle.Quad,
        dir   or Enum.EasingDirection.Out), goal):Play()
end

-- ============================================================
--  LOADING SCREEN
-- ============================================================
local LoadGui = Create("ScreenGui",{Name="PhantomLoad",ResetOnSpawn=false,
    ZIndexBehavior=Enum.ZIndexBehavior.Sibling,Parent=PlayerGui})

local Overlay = Create("Frame",{Size=UDim2.new(1,0,1,0),
    BackgroundColor3=Color3.fromRGB(5,5,10),BorderSizePixel=0,Parent=LoadGui})
Create("UIGradient",{Color=ColorSequence.new({
    ColorSequenceKeypoint.new(0,Color3.fromRGB(10,5,25)),
    ColorSequenceKeypoint.new(1,Color3.fromRGB(5,5,15))}),
    Rotation=135,Parent=Overlay})

-- Bokeh dots
for i=1,25 do
    math.randomseed(i*7777)
    local d=Create("Frame",{
        Size=UDim2.new(0,math.random(2,6),0,math.random(2,6)),
        Position=UDim2.new(math.random(),0,math.random(),0),
        BackgroundColor3=Color3.fromRGB(math.random(60,200),0,math.random(150,255)),
        BackgroundTransparency=math.random(50,80)/100,
        BorderSizePixel=0,Parent=Overlay})
    Create("UICorner",{CornerRadius=UDim.new(1,0),Parent=d})
end

local LoadBox = Create("Frame",{
    Size=UDim2.new(0,440,0,300),
    Position=UDim2.new(0.5,-220,0.6,-150),
    BackgroundColor3=Color3.fromRGB(10,8,20),
    BackgroundTransparency=1,BorderSizePixel=0,Parent=Overlay})
Create("UICorner",{CornerRadius=UDim.new(0,16),Parent=LoadBox})
Create("UIStroke",{Color=Color3.fromRGB(138,43,226),Thickness=1.5,Parent=LoadBox})

Create("TextLabel",{Size=UDim2.new(1,0,0,50),Position=UDim2.new(0,0,0,16),
    BackgroundTransparency=1,Text="👻  PHANTOM HUB",
    TextColor3=Color3.fromRGB(0,255,136),TextSize=28,Font=Enum.Font.GothamBlack,Parent=LoadBox})

Create("TextLabel",{Size=UDim2.new(1,0,0,20),Position=UDim2.new(0,0,0,58),
    BackgroundTransparency=1,Text="Blox Fruits  ·  Update 29  ·  v4.1.0",
    TextColor3=Color3.fromRGB(138,43,226),TextSize=11,Font=Enum.Font.Code,Parent=LoadBox})

Create("Frame",{Size=UDim2.new(0.85,0,0,1),Position=UDim2.new(0.075,0,0,86),
    BackgroundColor3=Color3.fromRGB(50,20,80),BorderSizePixel=0,Parent=LoadBox})

local StatusLabel=Create("TextLabel",{Size=UDim2.new(0.7,0,0,20),
    Position=UDim2.new(0.06,0,0,98),BackgroundTransparency=1,
    Text="Khởi động...",TextColor3=Color3.fromRGB(180,180,200),
    TextSize=11,Font=Enum.Font.GothamSemibold,
    TextXAlignment=Enum.TextXAlignment.Left,Parent=LoadBox})

local PercentLabel=Create("TextLabel",{Size=UDim2.new(0.25,0,0,20),
    Position=UDim2.new(0.69,0,0,98),BackgroundTransparency=1,
    Text="0%",TextColor3=Color3.fromRGB(0,255,136),
    TextSize=13,Font=Enum.Font.GothamBold,
    TextXAlignment=Enum.TextXAlignment.Right,Parent=LoadBox})

local BarTrack=Create("Frame",{Size=UDim2.new(0.88,0,0,10),
    Position=UDim2.new(0.06,0,0,124),BackgroundColor3=Color3.fromRGB(20,12,40),
    BorderSizePixel=0,Parent=LoadBox})
Create("UICorner",{CornerRadius=UDim.new(1,0),Parent=BarTrack})

local BarFill=Create("Frame",{Size=UDim2.new(0,0,1,0),
    BackgroundColor3=Color3.fromRGB(0,255,136),BorderSizePixel=0,Parent=BarTrack})
Create("UICorner",{CornerRadius=UDim.new(1,0),Parent=BarFill})
Create("UIGradient",{Color=ColorSequence.new({
    ColorSequenceKeypoint.new(0,Color3.fromRGB(0,180,255)),
    ColorSequenceKeypoint.new(0.5,Color3.fromRGB(0,255,136)),
    ColorSequenceKeypoint.new(1,Color3.fromRGB(138,43,226))}),Parent=BarFill})

-- Log scrollbox
local LogScroll=Create("ScrollingFrame",{
    Size=UDim2.new(0.88,0,0,100),Position=UDim2.new(0.06,0,0,146),
    BackgroundColor3=Color3.fromRGB(6,4,14),BackgroundTransparency=0.25,
    BorderSizePixel=0,ScrollBarThickness=0,
    CanvasSize=UDim2.new(0,0,0,0),Parent=LoadBox})
Create("UICorner",{CornerRadius=UDim.new(0,6),Parent=LogScroll})
local LogLayout=Create("UIListLayout",{Padding=UDim.new(0,2),
    SortOrder=Enum.SortOrder.LayoutOrder,Parent=LogScroll})
Create("UIPadding",{PaddingLeft=UDim.new(0,6),PaddingRight=UDim.new(0,6),
    PaddingTop=UDim.new(0,4),PaddingBottom=UDim.new(0,4),Parent=LogScroll})

local logIdx=0
local function AddLog(msg, color)
    logIdx+=1
    Create("TextLabel",{Size=UDim2.new(1,0,0,13),BackgroundTransparency=1,
        Text=msg,TextColor3=color or Color3.fromRGB(150,150,170),
        TextSize=10,Font=Enum.Font.Code,
        TextXAlignment=Enum.TextXAlignment.Left,
        LayoutOrder=logIdx,Parent=LogScroll})
    LogScroll.CanvasSize=UDim2.new(0,0,0,LogLayout.AbsoluteContentSize.Y+8)
    LogScroll.CanvasPosition=Vector2.new(0,9999)
end

local function SetProgress(pct, status)
    pct=math.clamp(pct,0,100)
    Tween(BarFill,{Size=UDim2.new(pct/100,0,1,0)},0.35,
        Enum.EasingStyle.Quart,Enum.EasingDirection.Out)
    PercentLabel.Text=math.round(pct).."%"
    StatusLabel.Text=status
    AddLog(string.format("[%3d%%] %s",math.round(pct),status))
end

-- ============================================================
--  MODULES
-- ============================================================
local BASE_URL="https://raw.githubusercontent.com/Genesis-scripter-osp/DuyThichMod/main/"
local MODULES={
    {name="Core",   url=BASE_URL.."core.lua",   required=true, pct=15},
    {name="UI",     url=BASE_URL.."ui.lua",     required=true, pct=35},
    {name="Systems",url=BASE_URL.."systems.lua",required=false,pct=55},
    {name="Network",url=BASE_URL.."network.lua",required=false,pct=70},
    {name="Visual", url=BASE_URL.."visual.lua", required=false,pct=85},
    {name="Phantom",url=BASE_URL.."Phantom.lua",required=false,pct=95},
}

local function SafeLoad(url,name)
    local ok,src=pcall(game.HttpGet,game,url,true)
    if not ok or type(src)~="string" or #src<10 then
        AddLog("✗ "..name.." — tải thất bại",Color3.fromRGB(255,80,80)) return nil end
    local fn,e=loadstring(src,"="..name)
    if not fn then
        AddLog("✗ "..name.." — lỗi biên dịch: "..tostring(e),Color3.fromRGB(255,80,80)) return nil end
    local ok2,r=pcall(fn)
    if not ok2 then
        AddLog("✗ "..name.." — lỗi chạy: "..tostring(r),Color3.fromRGB(255,80,80)) return nil end
    AddLog("✓ "..name.." sẵn sàng",Color3.fromRGB(0,255,136))
    return r
end

-- ============================================================
--  BẮT ĐẦU LOAD (animation intro)
-- ============================================================
SetProgress(0,"Khởi động Phantom Hub...")
task.wait(0.2)
-- Bay lên từ dưới
Tween(LoadBox,{Position=UDim2.new(0.5,-220,0.5,-150),BackgroundTransparency=0},
    0.55,Enum.EasingStyle.Back,Enum.EasingDirection.Out)
task.wait(0.6)

SetProgress(5,"Kết nối GitHub...")
task.wait(0.25)

local Loaded={}
for _,mod in ipairs(MODULES) do
    SetProgress(mod.pct-5,"Đang tải "..mod.name.."...")
    task.wait(0.05)
    local r=SafeLoad(mod.url,mod.name)
    if r then
        Loaded[mod.name]=r
        SetProgress(mod.pct,mod.name.." ✓")
    elseif mod.required then
        SetProgress(mod.pct,"❌ LỖI: "..mod.name.." thất bại!")
        task.wait(1.5) LoadGui:Destroy() _G.PhantomHub_Loaded=false return
    else
        SetProgress(mod.pct,mod.name.." bỏ qua (optional)")
    end
    task.wait(0.12)
end

SetProgress(98,"Khởi tạo modules...")
task.wait(0.2)

local Core=Loaded["Core"]; local UI=Loaded["UI"]
local Systems=Loaded["Systems"]; local Network=Loaded["Network"]
local Visual=Loaded["Visual"]; local Phantom=Loaded["Phantom"]

Core.Init(); Core.LoadConfig()
if Systems then Systems.Init(Core) end
if Network then Network.Init(Core) end
if Visual  then Visual.Init(Core)  end
if Phantom and type(Phantom)=="table" and Phantom.Init then Phantom.Init(Core) end
UI.Build(Core)

SetProgress(100,"PHANTOM HUB sẵn sàng! 🎉")
task.wait(0.5)

-- Đóng loading screen
Tween(LoadBox,{Position=UDim2.new(0.5,-220,0.42,-150)},0.45,
    Enum.EasingStyle.Back,Enum.EasingDirection.In)
Tween(Overlay,{BackgroundTransparency=1},0.5,Enum.EasingStyle.Quad,Enum.EasingDirection.In)
task.wait(0.55)
LoadGui:Destroy()

Core.Log("PHANTOM HUB v4.1.0 khởi động xong! (Update 29)","success")

-- ============================================================
--  TOGGLE BUTTON NỔI (kéo được, pulse animation)
-- ============================================================
local ToggleGui=Create("ScreenGui",{Name="PhantomToggle",ResetOnSpawn=false,
    ZIndexBehavior=Enum.ZIndexBehavior.Sibling,Parent=PlayerGui})

local ToggleBtn=Create("TextButton",{
    Size=UDim2.new(0,50,0,50),Position=UDim2.new(1,-66,0.5,-25),
    BackgroundColor3=Color3.fromRGB(10,8,20),BorderSizePixel=0,
    Text="👻",TextSize=24,Font=Enum.Font.GothamBold,ZIndex=100,Parent=ToggleGui})
Create("UICorner",{CornerRadius=UDim.new(1,0),Parent=ToggleBtn})
local TStroke=Create("UIStroke",{Color=Color3.fromRGB(0,255,136),Thickness=2,Parent=ToggleBtn})

-- Tooltip
local Tooltip=Create("TextLabel",{
    Size=UDim2.new(0,120,0,24),Position=UDim2.new(-1.5,0,0.5,-12),
    BackgroundColor3=Color3.fromRGB(10,8,20),BackgroundTransparency=0.2,
    BorderSizePixel=0,Text="RightCtrl / Click",
    TextColor3=Color3.fromRGB(0,255,136),TextSize=9,Font=Enum.Font.Code,
    Visible=false,ZIndex=101,Parent=ToggleBtn})
Create("UICorner",{CornerRadius=UDim.new(0,4),Parent=Tooltip})

ToggleBtn.MouseEnter:Connect(function() Tooltip.Visible=true end)
ToggleBtn.MouseLeave:Connect(function() Tooltip.Visible=false end)

-- Pulse
local pulsing=true
task.spawn(function()
    while pulsing do
        Tween(TStroke,{Thickness=4,Color=Color3.fromRGB(0,255,180)},0.7)
        task.wait(0.7)
        Tween(TStroke,{Thickness=1.5,Color=Color3.fromRGB(0,100,60)},0.7)
        task.wait(0.7)
    end
end)

-- Drag
local togDrag,togDragStart,togDragPos=false,nil,nil
ToggleBtn.InputBegan:Connect(function(inp)
    if inp.UserInputType==Enum.UserInputType.MouseButton1 then
        togDrag=true; togDragStart=inp.Position; togDragPos=ToggleBtn.Position
    end
end)
UserInputService.InputChanged:Connect(function(inp)
    if togDrag and inp.UserInputType==Enum.UserInputType.MouseMovement then
        local d=inp.Position-togDragStart
        ToggleBtn.Position=UDim2.new(
            togDragPos.X.Scale,togDragPos.X.Offset+d.X,
            togDragPos.Y.Scale,togDragPos.Y.Offset+d.Y)
    end
end)
UserInputService.InputEnded:Connect(function(inp)
    if inp.UserInputType==Enum.UserInputType.MouseButton1 then togDrag=false end
end)

-- Click action
local hubVisible=true
local function ToggleHub()
    if not UI._Main then return end
    hubVisible=not hubVisible
    if hubVisible then
        UI._Main.Visible=true
        UI._Main.Position=UDim2.new(0.5,-360,0.6,-250)
        Tween(UI._Main,{Position=UDim2.new(0.5,-360,0.5,-250)},
            0.4,Enum.EasingStyle.Back,Enum.EasingDirection.Out)
        Tween(TStroke,{Color=Color3.fromRGB(255,80,80)},0.2)
        ToggleBtn.Text="✕"
    else
        Tween(UI._Main,{Position=UDim2.new(0.5,-360,0.62,-250)},
            0.3,Enum.EasingStyle.Quad,Enum.EasingDirection.In)
        task.delay(0.3,function() if UI._Main then UI._Main.Visible=false end end)
        Tween(TStroke,{Color=Color3.fromRGB(0,255,136)},0.2)
        ToggleBtn.Text="👻"
    end
end

ToggleBtn.MouseButton1Click:Connect(function()
    if togDragStart and (ToggleBtn.Position-togDragPos).X.Offset^2
       + (ToggleBtn.Position-togDragPos).Y.Offset^2 > 25 then return end
    ToggleHub()
end)

UserInputService.InputBegan:Connect(function(inp,gp)
    if not gp and inp.KeyCode==Enum.KeyCode.RightControl then ToggleHub() end
end)

-- ============================================================
--  VÒNG LẶP CHÍNH
-- ============================================================
local _conn=RunService.Heartbeat:Connect(function(dt)
    if not Core.State.Running then return end
    if Systems then Systems.Tick(dt) end
    if Network then Network.Tick(dt) end
    if Visual  then Visual.Tick(dt)  end
    if Phantom and type(Phantom)=="table" and Phantom.Tick then Phantom.Tick(dt) end
end)

LocalPlayer.AncestryChanged:Connect(function()
    if not LocalPlayer.Parent then
        pulsing=false; Core.State.Running=false; Core.SaveConfig(); _conn:Disconnect()
        if Visual  then Visual.Cleanup()  end
        if UI      then UI.Cleanup()      end
        if ToggleGui then ToggleGui:Destroy() end
        _G.PhantomHub_Loaded=false
    end
end)
