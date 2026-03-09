-- ============================================================
--  PHANTOM HUB  |  main.lua  v4.2.0
--  Fix: systems.lua load lỗi → dùng pcall an toàn hơn
--       Menu nhỏ lại 560×400
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
    TweenService:Create(obj, TweenInfo.new(t or 0.3,
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

-- Bokeh dots trang trí
for i=1,20 do
    math.randomseed(i*9999)
    local d=Create("Frame",{
        Size=UDim2.new(0,math.random(2,5),0,math.random(2,5)),
        Position=UDim2.new(math.random(),0,math.random(),0),
        BackgroundColor3=Color3.fromRGB(math.random(60,180),0,math.random(150,255)),
        BackgroundTransparency=math.random(50,80)/100,
        BorderSizePixel=0,Parent=Overlay})
    Create("UICorner",{CornerRadius=UDim.new(1,0),Parent=d})
end

-- Loading box 380×270
local LoadBox = Create("Frame",{
    Size=UDim2.new(0,380,0,270),
    Position=UDim2.new(0.5,-190,0.65,-135),
    BackgroundColor3=Color3.fromRGB(10,8,20),
    BackgroundTransparency=1,BorderSizePixel=0,Parent=Overlay})
Create("UICorner",{CornerRadius=UDim.new(0,14),Parent=LoadBox})
Create("UIStroke",{Color=Color3.fromRGB(138,43,226),Thickness=1.5,Parent=LoadBox})

Create("TextLabel",{Size=UDim2.new(1,0,0,44),Position=UDim2.new(0,0,0,14),
    BackgroundTransparency=1,Text="👻  PHANTOM HUB",
    TextColor3=Color3.fromRGB(0,255,136),TextSize=24,Font=Enum.Font.GothamBlack,Parent=LoadBox})

Create("TextLabel",{Size=UDim2.new(1,0,0,18),Position=UDim2.new(0,0,0,52),
    BackgroundTransparency=1,Text="Blox Fruits  ·  Update 29  ·  v4.2.0",
    TextColor3=Color3.fromRGB(138,43,226),TextSize=10,Font=Enum.Font.Code,Parent=LoadBox})

Create("Frame",{Size=UDim2.new(0.85,0,0,1),Position=UDim2.new(0.075,0,0,78),
    BackgroundColor3=Color3.fromRGB(50,20,80),BorderSizePixel=0,Parent=LoadBox})

local StatusLbl=Create("TextLabel",{Size=UDim2.new(0.68,0,0,18),
    Position=UDim2.new(0.06,0,0,88),BackgroundTransparency=1,
    Text="Khởi động...",TextColor3=Color3.fromRGB(180,180,200),
    TextSize=10,Font=Enum.Font.GothamSemibold,
    TextXAlignment=Enum.TextXAlignment.Left,Parent=LoadBox})

local PctLbl=Create("TextLabel",{Size=UDim2.new(0.24,0,0,18),
    Position=UDim2.new(0.7,0,0,88),BackgroundTransparency=1,
    Text="0%",TextColor3=Color3.fromRGB(0,255,136),
    TextSize=12,Font=Enum.Font.GothamBold,
    TextXAlignment=Enum.TextXAlignment.Right,Parent=LoadBox})

local BarTrack=Create("Frame",{Size=UDim2.new(0.88,0,0,8),
    Position=UDim2.new(0.06,0,0,112),
    BackgroundColor3=Color3.fromRGB(20,12,40),BorderSizePixel=0,Parent=LoadBox})
Create("UICorner",{CornerRadius=UDim.new(1,0),Parent=BarTrack})

local BarFill=Create("Frame",{Size=UDim2.new(0,0,1,0),
    BackgroundColor3=Color3.fromRGB(0,255,136),BorderSizePixel=0,Parent=BarTrack})
Create("UICorner",{CornerRadius=UDim.new(1,0),Parent=BarFill})
Create("UIGradient",{Color=ColorSequence.new({
    ColorSequenceKeypoint.new(0,Color3.fromRGB(0,180,255)),
    ColorSequenceKeypoint.new(0.5,Color3.fromRGB(0,255,136)),
    ColorSequenceKeypoint.new(1,Color3.fromRGB(138,43,226))}),Parent=BarFill})

-- Log box
local LogScroll=Create("ScrollingFrame",{
    Size=UDim2.new(0.88,0,0,100),Position=UDim2.new(0.06,0,0,130),
    BackgroundColor3=Color3.fromRGB(6,4,14),BackgroundTransparency=0.2,
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
    PctLbl.Text=math.round(pct).."%"
    StatusLbl.Text=status
    AddLog(string.format("[%3d%%] %s",math.round(pct),status))
end

-- ============================================================
--  MODULES — required=false cho tất cả trừ Core+UI
--  để tránh dừng khi 1 file lỗi
-- ============================================================
local BASE="https://raw.githubusercontent.com/Genesis-scripter-osp/DuyThichMod/main/"
local MODULES={
    {name="Core",   url=BASE.."core.lua",   required=true,  pct=18},
    {name="UI",     url=BASE.."ui.lua",     required=true,  pct=36},
    {name="Systems",url=BASE.."systems.lua",required=false, pct=54},
    {name="Network",url=BASE.."network.lua",required=false, pct=70},
    {name="Visual", url=BASE.."visual.lua", required=false, pct=85},
    {name="Phantom",url=BASE.."Phantom.lua",required=false, pct=95},
}

local function SafeLoad(url, name)
    -- Thử load, nếu 404 hoặc lỗi thì bỏ qua
    local ok, src = pcall(function()
        return game:HttpGet(url, true)
    end)
    if not ok or type(src)~="string" or #src<20 then
        AddLog("✗ "..name.." — HTTP lỗi/404",Color3.fromRGB(255,80,80))
        return nil
    end
    -- Kiểm tra có phải trang 404 HTML không
    if src:sub(1,15):find("<!DOCTYPE") or src:find("404: Not Found") then
        AddLog("✗ "..name.." — File chưa có trên GitHub",Color3.fromRGB(255,140,0))
        return nil
    end
    local fn, e = loadstring(src, "="..name)
    if not fn then
        AddLog("✗ "..name.." — lỗi biên dịch",Color3.fromRGB(255,80,80))
        warn("[PhantomHub] "..name.." compile error: "..tostring(e))
        return nil
    end
    local ok2, r = pcall(fn)
    if not ok2 then
        AddLog("✗ "..name.." — lỗi chạy: "..tostring(r),Color3.fromRGB(255,80,80))
        return nil
    end
    AddLog("✓ "..name.." sẵn sàng",Color3.fromRGB(0,255,136))
    return r
end

-- ============================================================
--  BẮT ĐẦU LOAD
-- ============================================================
SetProgress(0,"Khởi động Phantom Hub...")
task.wait(0.2)
-- Intro animation
Tween(LoadBox,{Position=UDim2.new(0.5,-190,0.5,-135),BackgroundTransparency=0},
    0.5,Enum.EasingStyle.Back,Enum.EasingDirection.Out)
task.wait(0.55)

SetProgress(5,"Kết nối GitHub...")
task.wait(0.2)

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
        AddLog("Kiểm tra file "..mod.name:lower()..".lua trên GitHub!",Color3.fromRGB(255,200,0))
        task.wait(2)
        LoadGui:Destroy(); _G.PhantomHub_Loaded=false; return
    else
        SetProgress(mod.pct,mod.name.." — bỏ qua (404)")
    end
    task.wait(0.1)
end

SetProgress(98,"Khởi tạo...")
task.wait(0.2)

local Core=Loaded["Core"]; local UI=Loaded["UI"]
local Systems=Loaded["Systems"]; local Network=Loaded["Network"]
local Visual=Loaded["Visual"]; local Phantom=Loaded["Phantom"]

Core.Init(); Core.LoadConfig()
if Systems then
    local ok,err=pcall(Systems.Init,Systems,Core)
    if not ok then AddLog("⚠ Systems.Init lỗi: "..tostring(err),Color3.fromRGB(255,140,0)) end
end
if Network then pcall(Network.Init,Network,Core) end
if Visual  then pcall(Visual.Init,Visual,Core)   end
if Phantom and type(Phantom)=="table" and Phantom.Init then pcall(Phantom.Init,Phantom,Core) end

UI.Build(Core)
SetProgress(100,"PHANTOM HUB sẵn sàng! 🎉")
task.wait(0.45)

-- Đóng loading
Tween(LoadBox,{Position=UDim2.new(0.5,-190,0.42,-135)},0.4,
    Enum.EasingStyle.Back,Enum.EasingDirection.In)
Tween(Overlay,{BackgroundTransparency=1},0.45,Enum.EasingStyle.Quad,Enum.EasingDirection.In)
task.wait(0.5)
LoadGui:Destroy()

Core.Log("PHANTOM HUB v4.2.0 sẵn sàng!","success")

-- ============================================================
--  TOGGLE BUTTON NỔI
-- ============================================================
local ToggleGui=Create("ScreenGui",{Name="PhantomToggle",ResetOnSpawn=false,
    ZIndexBehavior=Enum.ZIndexBehavior.Sibling,Parent=PlayerGui})

local ToggleBtn=Create("TextButton",{
    Size=UDim2.new(0,44,0,44),Position=UDim2.new(1,-58,0.5,-22),
    BackgroundColor3=Color3.fromRGB(10,8,20),BorderSizePixel=0,
    Text="👻",TextSize=20,Font=Enum.Font.GothamBold,ZIndex=100,Parent=ToggleGui})
Create("UICorner",{CornerRadius=UDim.new(1,0),Parent=ToggleBtn})
local TStroke=Create("UIStroke",{Color=Color3.fromRGB(0,255,136),Thickness=2,Parent=ToggleBtn})

-- Tooltip
local Tip=Create("TextLabel",{
    Size=UDim2.new(0,110,0,20),Position=UDim2.new(-1.4,0,0.5,-10),
    BackgroundColor3=Color3.fromRGB(10,8,20),BackgroundTransparency=0.15,
    BorderSizePixel=0,Text="RightCtrl / Click",
    TextColor3=Color3.fromRGB(0,255,136),TextSize=8,Font=Enum.Font.Code,
    Visible=false,ZIndex=101,Parent=ToggleBtn})
Create("UICorner",{CornerRadius=UDim.new(0,4),Parent=Tip})
ToggleBtn.MouseEnter:Connect(function() Tip.Visible=true end)
ToggleBtn.MouseLeave:Connect(function() Tip.Visible=false end)

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
local td,tds,tdp=false,nil,nil
ToggleBtn.InputBegan:Connect(function(i)
    if i.UserInputType==Enum.UserInputType.MouseButton1 then
        td=true; tds=i.Position; tdp=ToggleBtn.Position end
end)
UserInputService.InputChanged:Connect(function(i)
    if td and i.UserInputType==Enum.UserInputType.MouseMovement then
        local d=i.Position-tds
        ToggleBtn.Position=UDim2.new(tdp.X.Scale,tdp.X.Offset+d.X,tdp.Y.Scale,tdp.Y.Offset+d.Y)
    end
end)
UserInputService.InputEnded:Connect(function(i)
    if i.UserInputType==Enum.UserInputType.MouseButton1 then td=false end
end)

local hubVisible=true
local function ToggleHub()
    if not UI._Main then return end
    hubVisible=not hubVisible
    if hubVisible then
        UI._Main.Visible=true
        UI._Main.Position=UDim2.new(0.5,-280,0.6,-200)
        Tween(UI._Main,{Position=UDim2.new(0.5,-280,0.5,-200)},
            0.4,Enum.EasingStyle.Back,Enum.EasingDirection.Out)
        Tween(TStroke,{Color=Color3.fromRGB(255,80,80)},0.2)
        ToggleBtn.Text="✕"
    else
        Tween(UI._Main,{Position=UDim2.new(0.5,-280,0.62,-200)},
            0.3,Enum.EasingStyle.Quad,Enum.EasingDirection.In)
        task.delay(0.3,function() if UI._Main then UI._Main.Visible=false end end)
        Tween(TStroke,{Color=Color3.fromRGB(0,255,136)},0.2)
        ToggleBtn.Text="👻"
    end
end

ToggleBtn.MouseButton1Click:Connect(ToggleHub)
UserInputService.InputBegan:Connect(function(i,gp)
    if not gp and i.KeyCode==Enum.KeyCode.RightControl then ToggleHub() end
end)

-- ============================================================
--  VÒNG LẶP CHÍNH — pcall bảo vệ từng module
-- ============================================================
local _conn=RunService.Heartbeat:Connect(function(dt)
    if not Core.State.Running then return end
    if Systems then pcall(Systems.Tick,Systems,dt) end
    if Network then pcall(Network.Tick,Network,dt) end
    if Visual  then pcall(Visual.Tick,Visual,dt)   end
    if Phantom and type(Phantom)=="table" and Phantom.Tick then
        pcall(Phantom.Tick,Phantom,dt) end
end)

LocalPlayer.AncestryChanged:Connect(function()
    if not LocalPlayer.Parent then
        pulsing=false; Core.State.Running=false; Core.SaveConfig(); _conn:Disconnect()
        if Visual  then pcall(Visual.Cleanup,Visual)   end
        if UI      then UI.Cleanup()                   end
        if ToggleGui then ToggleGui:Destroy()          end
        _G.PhantomHub_Loaded=false
    end
end)


