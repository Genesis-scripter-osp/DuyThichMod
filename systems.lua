-- ============================================================
--  PHANTOM HUB  |  systems.lua  v4.3.0
--  Fix: Auto Farm tấn công thực · Auto Boss · Teleport · ESP
--  Blox Fruits Update 29
-- ============================================================

local Players           = game:GetService("Players")
local RunService        = game:GetService("RunService")
local Workspace         = game:GetService("Workspace")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local VirtualUser       = game:GetService("VirtualUser")
local UserInputService  = game:GetService("UserInputService")
local TweenService      = game:GetService("TweenService")

local LocalPlayer = Players.LocalPlayer
local Core

local Systems = {}

-- ============================================================
--  TIỆN ÍCH
-- ============================================================
local function GetChar()
    local c = LocalPlayer.Character
    if not c then return nil, nil end
    return c, c:FindFirstChild("HumanoidRootPart")
end

local function GetHum()
    local c = LocalPlayer.Character
    return c and c:FindFirstChildOfClass("Humanoid") or nil
end

local function TeleportTo(pos)
    local _, hrp = GetChar()
    if hrp then
        hrp.CFrame = CFrame.new(pos + Vector3.new(0, 3, 0))
    end
end

local function DistanceTo(pos)
    local _, hrp = GetChar()
    if not hrp then return math.huge end
    return (hrp.Position - pos).Magnitude
end

-- ============================================================
--  TÌM REMOTE EVENT ĐÚNG CÁCH (Blox Fruits Update 29)
--  Blox Fruits dùng RemoteEvent trong ReplicatedStorage
-- ============================================================
local RemoteCache = {}
local function GetRemote(name)
    if RemoteCache[name] then return RemoteCache[name] end
    -- Tìm đệ quy trong ReplicatedStorage
    local r = ReplicatedStorage:FindFirstChild(name, true)
    if r then RemoteCache[name] = r; return r end
    return nil
end

local function FireRemote(name, ...)
    local r = GetRemote(name)
    if r and r:IsA("RemoteEvent") then
        pcall(r.FireServer, r, ...)
    end
end

local function InvokeRemote(name, ...)
    local r = GetRemote(name)
    if r and r:IsA("RemoteFunction") then
        local ok, res = pcall(r.InvokeServer, r, ...)
        if ok then return res end
    end
end

-- ============================================================
--  TẤN CÔNG MOB — Blox Fruits Update 29
--  Dùng nhiều phương pháp để đảm bảo hit
-- ============================================================
local function AttackMob(mob)
    if not mob or not mob.Parent then return end
    local hum = mob:FindFirstChildOfClass("Humanoid")
    if not hum or hum.Health <= 0 then return end

    local root = mob:FindFirstChild("HumanoidRootPart")
        or mob:FindFirstChild("Root")
        or mob:FindFirstChild("Torso")
    if not root then return end

    local _, hrp = GetChar()
    if not hrp then return end

    -- Teleport sát mob
    hrp.CFrame = CFrame.new(root.Position + Vector3.new(0, 2, 0))
        * CFrame.Angles(0, math.rad(180), 0)

    -- Phương pháp 1: Simulate click (đánh tay)
    local tool = LocalPlayer.Character and
        LocalPlayer.Character:FindFirstChildOfClass("Tool")

    if tool then
        -- Kích hoạt tool (vũ khí)
        local activated = tool:FindFirstChild("Activated")
            or tool:FindFirstChildOfClass("LocalScript")
        -- FireServer nếu có handle
        local handle = tool:FindFirstChild("Handle")
        if handle then
            -- Tấn công bằng cách fire tool remote
            pcall(function()
                tool:Activate()
            end)
        end
    end

    -- Phương pháp 2: VirtualUser click vào mob
    pcall(function()
        local camera = workspace.CurrentCamera
        if camera then
            local screenPos, onScreen = camera:WorldToScreenPoint(root.Position)
            if onScreen then
                VirtualUser:Button1Down(Vector2.new(screenPos.X, screenPos.Y), camera.CFrame)
                task.wait(0.05)
                VirtualUser:Button1Up(Vector2.new(screenPos.X, screenPos.Y), camera.CFrame)
            end
        end
    end)

    -- Phương pháp 3: FireRemote damage trực tiếp (Update 29)
    pcall(function()
        -- Blox Fruits Update 29 remote names
        FireRemote("Damage", mob, 1)
        FireRemote("DamageCharacter", mob)
        FireRemote("HitCharacter", mob, root.Position)
    end)
end

-- ============================================================
--  TÌM MOB GẦN NHẤT
-- ============================================================
local FARM_MOBS = {
    -- Sea 1
    "Military Soldier","Pirate","Bandit","Desert Bandit",
    "Monkey","Gorilla","Toga Warrior","Saber Expert",
    "Brute","Bobby","Yeti","Snow Bandit",
    -- Sea 2
    "Galley Pirate","Tough Cookie","Zombie","Vampire",
    "Snow Trooper","Ship Crew","Fishman","Shark",
    "Wysper","Thunder God","Smoker",
    -- Sea 3
    "Forest Pirate","Jungle Pirate","Sea Soldier",
    "Dark Pirate","Magma Ninja","Dragon Crew",
    "Longma","Buso Haki Warrior","Raid Soldier",
}

local function FindNearestMob(maxDist)
    maxDist = maxDist or 800
    local best, bestDist, bestPos = nil, maxDist, nil
    for _, obj in ipairs(Workspace:GetDescendants()) do
        if obj:IsA("Model") then
            local hum = obj:FindFirstChildOfClass("Humanoid")
            if hum and hum.Health > 0 and obj ~= LocalPlayer.Character then
                local root = obj:FindFirstChild("HumanoidRootPart")
                    or obj:FindFirstChild("Torso")
                if root then
                    local d = DistanceTo(root.Position)
                    if d < bestDist then
                        -- Cek nama mob
                        local isMob = false
                        for _, name in ipairs(FARM_MOBS) do
                            if obj.Name:find(name) then isMob=true; break end
                        end
                        -- Jika tidak ada di list, tetap farm jika ada humanoid
                        -- (untuk kompatibilitas semua island)
                        if not isMob and hum.MaxHealth <= 5000 then isMob = true end
                        if isMob then
                            best, bestDist, bestPos = obj, d, root.Position
                        end
                    end
                end
            end
        end
    end
    return best, bestPos
end

-- ============================================================
--  AUTO FARM ENGINE
-- ============================================================
local FarmEngine = {}
FarmEngine._target = nil
FarmEngine._timer  = 0
FarmEngine._atkTimer = 0

function FarmEngine.Tick(dt)
    if not Core.IsOn("autoFarm") then return end

    FarmEngine._timer += dt
    FarmEngine._atkTimer += dt

    -- Cari target baru setiap 0.3s
    if FarmEngine._timer >= 0.3 then
        FarmEngine._timer = 0

        -- Cek apakah target masih valid
        if FarmEngine._target then
            local hum = FarmEngine._target:FindFirstChildOfClass("Humanoid")
            if not hum or hum.Health <= 0 or not FarmEngine._target.Parent then
                Core.Stats.MobsKilled = (Core.Stats.MobsKilled or 0) + 1
                FarmEngine._target = nil
            end
        end

        -- Cari target baru
        if not FarmEngine._target then
            local mob, pos = FindNearestMob()
            FarmEngine._target = mob
        end
    end

    -- Serang target setiap 0.15s
    if FarmEngine._atkTimer >= 0.15 and FarmEngine._target then
        FarmEngine._atkTimer = 0
        AttackMob(FarmEngine._target)
    end
end

-- ============================================================
--  AUTO QUEST
-- ============================================================
local QUEST_NPCS = {
    -- Sea 1
    {name="Quest Giver", pos=Vector3.new(941.3, 19.5, 750.4)},
    {name="Military Detective", pos=Vector3.new(267, 8, 1580)},
    {name="Pirate Greeter", pos=Vector3.new(-1320, 5, 103)},
    -- Sea 2
    {name="Greybeard", pos=Vector3.new(-230, 128, 4600)},
    {name="Quest Giver", pos=Vector3.new(-3500, 5, 3640)},
    -- Sea 3
    {name="Mythological Pirate", pos=Vector3.new(-6800, 5, 1800)},
    {name="Dragonborn", pos=Vector3.new(-8500, 5, -3000)},
}

local QuestSystem = {}
QuestSystem._timer = 0

function QuestSystem.Tick(dt)
    if not Core.IsOn("autoQuest") then return end
    QuestSystem._timer += dt
    if QuestSystem._timer < 2 then return end
    QuestSystem._timer = 0

    -- Coba accept & turnin quest via remote
    FireRemote("AcceptQuest")
    FireRemote("TurnInQuest")
    FireRemote("QuestAccept")
    FireRemote("QuestComplete")

    -- Cari NPC quest di workspace
    for _, obj in ipairs(Workspace:GetDescendants()) do
        if obj:IsA("Model") or obj:IsA("NPC") then
            local n = obj.Name:lower()
            if n:find("quest") or n:find("giver") or n:find("guard") then
                local root = obj:FindFirstChild("HumanoidRootPart")
                    or obj:FindFirstChild("Torso")
                if root and DistanceTo(root.Position) > 15 then
                    TeleportTo(root.Position)
                end
                -- Interact
                local prox = obj:FindFirstChildOfClass("ProximityPrompt")
                if prox then
                    pcall(function()
                        fireproximityprompt(prox)
                    end)
                end
                break
            end
        end
    end
end

-- ============================================================
--  AUTO BOSS
-- ============================================================
local BOSS_LIST = {
    {id="autoDarkbeard",  name="Darkbeard",   pos=Vector3.new(29.3, 296.5, 1590.2)},
    {id="autoRipIndra",   name="Rip_Indra",   pos=Vector3.new(-3996, 64, 3815)},
    {id="autoDoughKing",  name="Dough King",  pos=Vector3.new(-3229, 47, 5085)},
    {id="autoSoulReaper", name="Soul Reaper", pos=Vector3.new(-4770, 853, -1282)},
    -- Generic boss
    {id="autoBoss",       name="",            pos=nil},
}

local BOSS_NAMES = {
    "Darkbeard","Rip_Indra","Dough King","Soul Reaper",
    "Cake Queen","Island Empress","Longma","Kilo Admiral",
    "Mr. 1","Don Swan","Cyborg","Beast Pirates",
}

local BossSystem = {}
BossSystem._timer = 0
BossSystem._target = nil

function BossSystem.Tick(dt)
    BossSystem._timer += dt
    if BossSystem._timer < 0.5 then return end
    BossSystem._timer = 0

    -- Cek boss spesifik
    for _, boss in ipairs(BOSS_LIST) do
        if Core.IsOn(boss.id) then
            -- Cari boss di workspace
            if not BossSystem._target then
                for _, obj in ipairs(Workspace:GetDescendants()) do
                    if obj:IsA("Model") then
                        local hum = obj:FindFirstChildOfClass("Humanoid")
                        if hum and hum.Health > 0 then
                            local isBoss = false
                            if boss.name ~= "" and obj.Name:find(boss.name) then
                                isBoss = true
                            elseif boss.id == "autoBoss" then
                                for _, bn in ipairs(BOSS_NAMES) do
                                    if obj.Name:find(bn) then isBoss=true; break end
                                end
                            end
                            if isBoss then BossSystem._target = obj; break end
                        end
                    end
                end
            end

            -- Teleport ke lokasi spawn boss
            if not BossSystem._target and boss.pos then
                TeleportTo(boss.pos)
            end

            -- Serang boss
            if BossSystem._target then
                local hum = BossSystem._target:FindFirstChildOfClass("Humanoid")
                if not hum or hum.Health <= 0 then
                    BossSystem._target = nil
                else
                    AttackMob(BossSystem._target)
                end
            end
            return
        end
    end
end

-- ============================================================
--  TELEPORT SYSTEM
-- ============================================================
local TP_LOCATIONS = {
    tpFirstSea      = Vector3.new(941.3, 19.5, 750.4),
    tpSecondSea     = Vector3.new(-1765.9, 5, 4407.2),
    tpThirdSea      = Vector3.new(-6228, 5, -1310),
    tpQuestNPC      = Vector3.new(267, 8, 1580),
    tpFruitDealer   = Vector3.new(1028, 39.5, 839),
    tpSwordDealer   = Vector3.new(-80, 81, 1895),
    tpRaidNPC       = Vector3.new(-1507, 8, 395),
    tpBoss          = Vector3.new(29.3, 296.5, 1590.2),
    tpHotCold       = Vector3.new(1003, 5, 5200),
    tpPvPArena      = Vector3.new(-6800, 5, 1800),
    tpLucianNPC     = Vector3.new(-1200, 5, 4200),
    tpTrinketExpert = Vector3.new(-3000, 5, 3800),
    tpTrinketRefiner= Vector3.new(-3100, 5, 3850),
}

local TpSystem = {}
function TpSystem.DoTeleport(id)
    local pos = TP_LOCATIONS[id]
    if pos then TeleportTo(pos) end
end

-- ============================================================
--  ESP SYSTEM (hiện tên NPC, Fruit, Boss trên màn hình)
-- ============================================================
local ESP = {}
ESP._labels = {}
ESP._timer  = 0

local function MakeESPLabel(name, color, parent)
    -- Xóa label cũ nếu có
    local old = parent:FindFirstChild("_PhantomESP")
    if old then old:Destroy() end

    local bb = Instance.new("BillboardGui")
    bb.Name = "_PhantomESP"
    bb.Size = UDim2.new(0, 120, 0, 30)
    bb.StudsOffset = Vector3.new(0, 3, 0)
    bb.AlwaysOnTop = true
    bb.MaxDistance = 200
    bb.Parent = parent

    local lbl = Instance.new("TextLabel")
    lbl.Size = UDim2.new(1, 0, 1, 0)
    lbl.BackgroundTransparency = 1
    lbl.Text = name
    lbl.TextColor3 = color
    lbl.TextSize = 13
    lbl.Font = Enum.Font.GothamBold
    lbl.TextStrokeTransparency = 0
    lbl.TextStrokeColor3 = Color3.fromRGB(0,0,0)
    lbl.Parent = bb
    return bb
end

function ESP.UpdateNPC()
    if not Core.IsOn("npcESP") and not Core.IsOn("bossESP") then
        -- Hapus semua ESP
        for _, obj in ipairs(Workspace:GetDescendants()) do
            local bb = obj:FindFirstChild("_PhantomESP")
            if bb then bb:Destroy() end
        end
        return
    end

    local BOSS_SET = {}
    for _, n in ipairs(BOSS_NAMES) do BOSS_SET[n] = true end

    for _, obj in ipairs(Workspace:GetDescendants()) do
        if obj:IsA("Model") then
            local hum = obj:FindFirstChildOfClass("Humanoid")
            if hum and hum.Health > 0 and obj ~= LocalPlayer.Character then
                local root = obj:FindFirstChild("HumanoidRootPart")
                    or obj:FindFirstChild("Torso")
                if root then
                    local isBoss = BOSS_SET[obj.Name] ~= nil
                    if isBoss and Core.IsOn("bossESP") then
                        local hp = math.round(hum.Health).."/"..math.round(hum.MaxHealth)
                        local d  = math.round(DistanceTo(root.Position))
                        MakeESPLabel("💀 "..obj.Name.."\n❤ "..hp.." ["..d.."m]",
                            Color3.fromRGB(255,68,68), root)
                    elseif not isBoss and Core.IsOn("npcESP") then
                        local d = math.round(DistanceTo(root.Position))
                        MakeESPLabel(obj.Name.." ["..d.."m]",
                            Color3.fromRGB(100,180,255), root)
                    end
                end
            end
        end
    end
end

function ESP.UpdateFruit()
    if not Core.IsOn("fruitESP") then
        for _, obj in ipairs(Workspace:GetDescendants()) do
            if obj.Name == "_PhantomFruitESP" then obj:Destroy() end
        end
        return
    end

    for _, obj in ipairs(Workspace:GetDescendants()) do
        if (obj:IsA("Model") or obj:IsA("Part")) and obj.Parent == Workspace.Fruits then
            if not obj:FindFirstChild("_PhantomFruitESP") then
                local bb = Instance.new("BillboardGui")
                bb.Name = "_PhantomFruitESP"
                bb.Size = UDim2.new(0,140,0,28)
                bb.StudsOffset = Vector3.new(0,2,0)
                bb.AlwaysOnTop = true
                bb.MaxDistance = 500
                bb.Parent = obj

                local lbl = Instance.new("TextLabel")
                lbl.Size = UDim2.new(1,0,1,0)
                lbl.BackgroundTransparency = 1
                lbl.Text = "🍎 "..obj.Name
                lbl.TextColor3 = Color3.fromRGB(204,68,255)
                lbl.TextSize = 12
                lbl.Font = Enum.Font.GothamBold
                lbl.TextStrokeTransparency = 0
                lbl.TextStrokeColor3 = Color3.fromRGB(0,0,0)
                lbl.Parent = bb
            end
        end
    end
end

function ESP.UpdatePlayer()
    if not Core.IsOn("playerESP") then
        for _, p in ipairs(Players:GetPlayers()) do
            if p ~= LocalPlayer and p.Character then
                local hrp = p.Character:FindFirstChild("HumanoidRootPart")
                if hrp then
                    local bb = hrp:FindFirstChild("_PhantomESP")
                    if bb then bb:Destroy() end
                end
            end
        end
        return
    end

    for _, p in ipairs(Players:GetPlayers()) do
        if p ~= LocalPlayer and p.Character then
            local hrp = p.Character:FindFirstChild("HumanoidRootPart")
            local hum = p.Character:FindFirstChildOfClass("Humanoid")
            if hrp and hum then
                local d = math.round(DistanceTo(hrp.Position))
                local hp = math.round(hum.Health)
                MakeESPLabel("👤 "..p.Name.."\n❤ "..hp.." ["..d.."m]",
                    Color3.fromRGB(255,255,80), hrp)
            end
        end
    end
end

local ESP_TIMER = 0
function ESP.Tick(dt)
    ESP_TIMER += dt
    if ESP_TIMER < 1 then return end -- Update ESP setiap 1 detik
    ESP_TIMER = 0
    pcall(ESP.UpdateNPC)
    pcall(ESP.UpdateFruit)
    pcall(ESP.UpdatePlayer)
end

-- ============================================================
--  AUTO COLLECT FRUIT
-- ============================================================
local FruitSystem = {}
FruitSystem._timer = 0

function FruitSystem.Tick(dt)
    FruitSystem._timer += dt
    if FruitSystem._timer < 1 then return end
    FruitSystem._timer = 0

    if not Core.IsOn("autoCollectFruit") and not Core.IsOn("fruitSniper") then return end

    local fruitsFolder = Workspace:FindFirstChild("Fruits")
        or Workspace:FindFirstChild("GameObjects")
    if not fruitsFolder then return end

    for _, fruit in ipairs(fruitsFolder:GetChildren()) do
        if fruit:IsA("Model") or fruit:IsA("Part") then
            local root = fruit:FindFirstChild("HumanoidRootPart")
                or fruit:FindFirstChild("Handle")
                or (fruit:IsA("Part") and fruit or nil)
            if root then
                local d = DistanceTo(root.Position)
                if d < 10 then
                    -- Ambil fruit
                    FireRemote("PickFruit", fruit)
                    FireRemote("CollectFruit", fruit)
                    Core.Stats.FruitsCollected = (Core.Stats.FruitsCollected or 0) + 1
                elseif Core.IsOn("fruitSniper") and d < 300 then
                    -- Teleport ke fruit
                    TeleportTo(root.Position)
                end
            end
        end
    end
end

-- ============================================================
--  PLAYER UTILITIES
-- ============================================================
local PlayerUtils = {}
PlayerUtils._flyBody = nil
PlayerUtils._flyConn = nil

function PlayerUtils.StartFly()
    local char, hrp = GetChar()
    if not hrp then return end

    -- Hapus body lama
    if PlayerUtils._flyBody then
        PlayerUtils._flyBody:Destroy()
        PlayerUtils._flyBody = nil
    end

    local bg = Instance.new("BodyGyro")
    bg.MaxTorque = Vector3.new(9e8, 9e8, 9e8)
    bg.P = 9e4
    bg.CFrame = hrp.CFrame
    bg.Parent = hrp

    local bv = Instance.new("BodyVelocity")
    bv.Velocity = Vector3.zero
    bv.MaxForce = Vector3.new(9e8, 9e8, 9e8)
    bv.P = 9e4
    bv.Parent = hrp
    PlayerUtils._flyBody = bv

    PlayerUtils._flyConn = RunService.Heartbeat:Connect(function()
        if not Core.IsOn("flyMode") then
            bg:Destroy(); bv:Destroy()
            PlayerUtils._flyBody = nil
            if PlayerUtils._flyConn then PlayerUtils._flyConn:Disconnect() end
            return
        end
        local speed = 60
        local cf = workspace.CurrentCamera.CFrame
        local vel = Vector3.zero
        if UserInputService:IsKeyDown(Enum.KeyCode.W) then vel += cf.LookVector end
        if UserInputService:IsKeyDown(Enum.KeyCode.S) then vel -= cf.LookVector end
        if UserInputService:IsKeyDown(Enum.KeyCode.A) then vel -= cf.RightVector end
        if UserInputService:IsKeyDown(Enum.KeyCode.D) then vel += cf.RightVector end
        if UserInputService:IsKeyDown(Enum.KeyCode.Space) then vel += Vector3.new(0,1,0) end
        if UserInputService:IsKeyDown(Enum.KeyCode.LeftShift) then vel -= Vector3.new(0,1,0) end
        bv.Velocity = vel * speed
        bg.CFrame = workspace.CurrentCamera.CFrame
    end)
end

function PlayerUtils.Tick(dt)
    -- Fly
    if Core.IsOn("flyMode") and not PlayerUtils._flyBody then
        PlayerUtils.StartFly()
    end
    -- NoClip
    if Core.IsOn("noClip") then
        local char = LocalPlayer.Character
        if char then
            for _, p in ipairs(char:GetDescendants()) do
                if p:IsA("BasePart") and p.CanCollide then
                    p.CanCollide = false
                end
            end
        end
    end
    -- WalkSpeed
    local hum = GetHum()
    if hum then
        if Core.IsOn("walkSpeed") then
            hum.WalkSpeed = Core.GetSlider("walkSpeed")
        end
        if Core.IsOn("jumpPower") then
            hum.JumpPower = Core.GetSlider("jumpPower")
        end
    end
end

-- ============================================================
--  ANTI-AFK
-- ============================================================
local MiscSystem = {}
MiscSystem._afkTimer = 0

function MiscSystem.Tick(dt)
    -- Anti-AFK
    if Core.IsOn("antiAFK") then
        MiscSystem._afkTimer += dt
        if MiscSystem._afkTimer >= 60 then
            MiscSystem._afkTimer = 0
            pcall(function()
                VirtualUser:Button2Down(Vector2.new(0,0), workspace.CurrentCamera.CFrame)
                task.wait(0.1)
                VirtualUser:Button2Up(Vector2.new(0,0), workspace.CurrentCamera.CFrame)
            end)
        end
    end
    -- FPS Boost
    if Core.IsOn("fpsBoost") then
        pcall(function()
            for _, v in ipairs(Workspace:GetDescendants()) do
                if v:IsA("ParticleEmitter") or v:IsA("Trail")
                    or v:IsA("Smoke") or v:IsA("Fire") or v:IsA("Sparkles") then
                    v.Enabled = false
                end
            end
            local lighting = game:GetService("Lighting")
            lighting.GlobalShadows = false
            lighting.FogEnd = 9e4
        end)
    end
end

-- ============================================================
--  INIT & TICK
-- ============================================================
function Systems.Init(coreRef)
    Core = coreRef

    -- Daftarkan callback untuk tombol teleport
    for id, _ in pairs(TP_LOCATIONS) do
        if Core._Callbacks then
            Core._Callbacks[id] = function()
                TpSystem.DoTeleport(id)
            end
        end
    end

    Core.Log("Systems v4.3.0 siap!", "info")
end

function Systems.Tick(dt)
    pcall(FarmEngine.Tick, dt)
    pcall(BossSystem.Tick, dt)
    pcall(QuestSystem.Tick, dt)
    pcall(FruitSystem.Tick, dt)
    pcall(ESP.Tick, dt)
    pcall(PlayerUtils.Tick, dt)
    pcall(MiscSystem.Tick, dt)
end

return Systems


