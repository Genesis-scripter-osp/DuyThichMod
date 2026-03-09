-- ============================================================
--  PHANTOM HUB  |  systems.lua
--  Toàn bộ logic tự động hoá gameplay:
--  Auto Farm · Combat · Boss · Sea · Fruit · Raid · Player · Stats
-- ============================================================

local Players           = game:GetService("Players")
local RunService        = game:GetService("RunService")
local Workspace         = game:GetService("Workspace")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService      = game:GetService("TweenService")
local VirtualUser       = game:GetService("VirtualUser")

local LocalPlayer = Players.LocalPlayer
local Character: Model?
local HRP: BasePart?
local Core

local Systems = {}

-- ============================================================
--  TIỆN ÍCH NỘI BỘ
-- ============================================================
local function GetChar(): (Model?, BasePart?)
    local c = LocalPlayer.Character
    if not c then return nil, nil end
    local h = c:FindFirstChild("HumanoidRootPart")
    return c, h
end

local function GetHumanoid(): Humanoid?
    local c = LocalPlayer.Character
    return c and c:FindFirstChildOfClass("Humanoid") or nil
end

local function TeleportTo(pos: Vector3)
    local _, hrp = GetChar()
    if hrp then hrp.CFrame = CFrame.new(pos) end
end

local function DistanceTo(pos: Vector3): number
    local _, hrp = GetChar()
    if not hrp then return math.huge end
    return (hrp.Position - pos).Magnitude
end

-- Tìm NPC / mob gần nhất theo tên
local function FindNearestNPC(names: { string }, maxDist: number?): (Model?, Vector3?)
    maxDist = maxDist or 500
    local best, bestDist, bestPos = nil, maxDist, nil
    for _, obj in ipairs(Workspace:GetDescendants()) do
        if obj:IsA("Model") then
            local hum = obj:FindFirstChildOfClass("Humanoid")
            if hum and hum.Health > 0 then
                for _, name in ipairs(names) do
                    if obj.Name:lower():find(name:lower()) then
                        local root = obj:FindFirstChild("HumanoidRootPart")
                        if root then
                            local d = DistanceTo(root.Position)
                            if d < bestDist then
                                best, bestDist, bestPos = obj, d, root.Position
                            end
                        end
                        break
                    end
                end
            end
        end
    end
    return best, bestPos
end

-- Kích hoạt RemoteEvent
local function FireRemote(name: string, ...)
    local remote = ReplicatedStorage:FindFirstChild(name, true)
    if remote and remote:IsA("RemoteEvent") then
        remote:FireServer(...)
    end
end

-- ============================================================
--  MODULE: Auto Farm Engine
-- ============================================================
local FarmEngine = {}
FarmEngine._target = nil
FarmEngine._timer  = 0

local QUEST_NPCS = {
    "Military Soldier", "Pirate", "Bandit", "Desert Bandit",
    "Sky Bandit", "Dark Master", "Snow Bandit", "Galley Pirate"
}

function FarmEngine.Tick(dt: number)
    if not Core.IsOn("autoFarm") then return end

    FarmEngine._timer += dt
    if FarmEngine._timer < 0.1 then return end
    FarmEngine._timer = 0

    local c, hrp = GetChar()
    if not c or not hrp then return end
    local hum = GetHumanoid()
    if not hum or hum.Health <= 0 then return end

    -- Tìm mục tiêu mới nếu cần
    if not FarmEngine._target or not FarmEngine._target.Parent
       or FarmEngine._target:FindFirstChildOfClass("Humanoid") == nil
       or FarmEngine._target:FindFirstChildOfClass("Humanoid").Health <= 0 then

        FarmEngine._target = nil
        local names = Core.IsOn("farmMobCluster") and QUEST_NPCS or { "Bandit", "Pirate" }
        local mob, pos = FindNearestNPC(names, Core.IsOn("fastFarm") and 1000 or 400)
        FarmEngine._target = mob

        if mob and pos then
            if DistanceTo(pos) > 20 then
                TeleportTo(pos + Vector3.new(0, 3, 0))
            end
        end
    end

    -- Tấn công mục tiêu
    if FarmEngine._target then
        local root = FarmEngine._target:FindFirstChild("HumanoidRootPart")
        if root then
            if DistanceTo(root.Position) > 15 then
                TeleportTo(root.Position + Vector3.new(0, 3, 0))
            end
            hrp.CFrame = CFrame.lookAt(hrp.Position, root.Position)
            if Core.IsOn("autoClick") then
                mouse1click()
            end
        end
    end
end

-- ============================================================
--  MODULE: Combat System
-- ============================================================
local Combat = {}
Combat._skillTimer = { Z=0, X=0, C=0, V=0, F=0 }
Combat._skillDelay = { Z=2, X=3, C=4, V=5, F=8 }

function Combat.Tick(dt: number)
    -- Fast Attack & No Delay
    if Core.IsOn("fastAttack") or Core.IsOn("noDelay") then
        local hum = GetHumanoid()
        if hum then
            hum.WalkSpeed = Core.IsOn("fastAttack") and 28 or hum.WalkSpeed
        end
    end

    -- Auto Skills Z/X/C/V/F
    local skillMap = {
        Z = "autoSkillZ", X = "autoSkillX", C = "autoSkillC",
        V = "autoSkillV", F = "autoSkillF"
    }
    for key, featureId in pairs(skillMap) do
        if Core.IsOn(featureId) then
            Combat._skillTimer[key] = (Combat._skillTimer[key] or 0) + dt
            if Combat._skillTimer[key] >= Combat._skillDelay[key] then
                Combat._skillTimer[key] = 0
                keypress(string.byte(key))
                task.delay(0.05, function() keyrelease(string.byte(key)) end)
            end
        end
    end

    -- Auto Haki
    if Core.IsOn("autoHaki") then
        FireRemote("Haki", "Armament", true)
    end

    -- Expand Hitbox
    if Core.IsOn("expandHitbox") then
        local mult = Core.GetSlider("expandHitbox")
        for _, desc in ipairs(Workspace:GetDescendants()) do
            if desc:IsA("Model") and desc ~= LocalPlayer.Character then
                local hum = desc:FindFirstChildOfClass("Humanoid")
                if hum and hum.Health > 0 then
                    local root = desc:FindFirstChild("HumanoidRootPart")
                    if root and root:IsA("BasePart") then
                        root.Size = Vector3.new(mult * 5, mult * 5, mult * 5)
                    end
                end
            end
        end
    end
end

-- ============================================================
--  MODULE: Boss System
-- ============================================================
local BossSystem = {}
BossSystem._farmTimer = 0

local BOSS_NAMES = {
    autoDarkbeard  = { "Darkbeard" },
    autoRipIndra   = { "Rip_Indra", "Rip Indra" },
    autoDoughKing  = { "Dough King" },
    autoSoulReaper = { "Soul Reaper" },
    autoBoss       = { "Gorilla King", "Bobby", "Yeti", "Snow Lurker",
                       "Saber Expert", "Greybeard", "Dragon" },
    autoEliteBoss  = { "Stone", "Island Empress", "Kilo Admiral",
                       "Tide Keeper" },
}

function BossSystem.Tick(dt: number)
    BossSystem._farmTimer += dt
    if BossSystem._farmTimer < 0.5 then return end
    BossSystem._farmTimer = 0

    local c, hrp = GetChar()
    if not c or not hrp then return end
    local hum = GetHumanoid()
    if not hum or hum.Health <= 0 then return end

    for featureId, names in pairs(BOSS_NAMES) do
        if Core.IsOn(featureId) then
            local boss, pos = FindNearestNPC(names, 2000)
            if boss and pos then
                if DistanceTo(pos) > 30 then
                    TeleportTo(pos + Vector3.new(0, 5, 0))
                end
                hrp.CFrame = CFrame.lookAt(hrp.Position, pos)
                if Core.IsOn("autoClick") then mouse1click() end
            else
                if Core.IsOn("bossServerHop") then
                    Core.Log("Boss không có mặt, chờ server hop...", "warn")
                end
            end
            break
        end
    end
end

-- ============================================================
--  MODULE: Sea Event System
-- ============================================================
local SeaSystem = {}
SeaSystem._timer = 0

local SEA_NAMES = {
    autoSeaBeast   = { "Sea Beast", "Terrorshark", "Bone Demon" },
    autoPirateRaid = { "Pirate Raid", "Mob" },
    autoGhostShip  = { "Ghost Ship" },
}

function SeaSystem.Tick(dt: number)
    SeaSystem._timer += dt
    if SeaSystem._timer < 0.5 then return end
    SeaSystem._timer = 0

    for featureId, names in pairs(SEA_NAMES) do
        if Core.IsOn(featureId) then
            local target, pos = FindNearestNPC(names, 3000)
            if target and pos then
                local _, hrp = GetChar()
                if hrp and DistanceTo(pos) > 40 then
                    TeleportTo(pos + Vector3.new(0, 5, 0))
                end
                if Core.IsOn("autoClick") then mouse1click() end
            end
        end
    end

    -- Auto Sea Chest
    if Core.IsOn("autoSeaChest") then
        for _, obj in ipairs(Workspace:GetDescendants()) do
            if obj:IsA("Model") and obj.Name:find("Chest") then
                local root = obj:FindFirstChild("HumanoidRootPart")
                          or obj:FindFirstChildOfClass("BasePart")
                if root and DistanceTo(root.Position) > 5 then
                    TeleportTo(root.Position + Vector3.new(0, 2, 0))
                end
                FireRemote("OpenChest", obj)
                Core.Log("Sea chest mở xong.", "success")
            end
        end
    end
end

-- ============================================================
--  MODULE: Fruit System
-- ============================================================
local FruitSystem = {}
FruitSystem._timer = 0

local FRUIT_FOLDER = "Fruits"

function FruitSystem.Tick(dt: number)
    FruitSystem._timer += dt
    if FruitSystem._timer < 1 then return end
    FruitSystem._timer = 0

    local folder = Workspace:FindFirstChild(FRUIT_FOLDER)
    if not folder then return end

    for _, fruit in ipairs(folder:GetChildren()) do
        if fruit:IsA("Model") or fruit:IsA("Part") then
            local pos = fruit:IsA("Part") and fruit.Position
                     or (fruit:FindFirstChildOfClass("BasePart") and
                         fruit:FindFirstChildOfClass("BasePart").Position)
            if pos then
                if Core.IsOn("fruitNotifier") then
                    Core.Log("Fruit spawn: " .. fruit.Name, "warn")
                end
                if Core.IsOn("fruitSniper") or Core.IsOn("autoCollectFruit") then
                    TeleportTo(pos + Vector3.new(0, 2, 0))
                    FireRemote("PickFruit", fruit)
                    Core.State.Stats.FruitsCollected += 1
                    Core.Log("Thu thập: " .. fruit.Name, "success")
                end
            end
        end
    end
end

-- ============================================================
--  MODULE: Player Utilities
-- ============================================================
local PlayerUtils = {}
PlayerUtils._flyBV   = nil
PlayerUtils._flyConn = nil

function PlayerUtils.Init()
    -- Fly Mode
    Core.OnToggle("flyMode", function(on)
        local c, hrp = GetChar()
        if not c or not hrp then return end
        if on then
            hrp.Anchored = false
            local bg = Instance.new("BodyGyro", hrp)
            bg.Name      = "FlyGyro"
            bg.MaxTorque = Vector3.new(1e9, 1e9, 1e9)
            bg.D         = 50
            local bv = Instance.new("BodyVelocity", hrp)
            bv.Name     = "FlyVelocity"
            bv.MaxForce = Vector3.new(1e9, 1e9, 1e9)
            bv.Velocity = Vector3.zero
            PlayerUtils._flyBV = bv
            PlayerUtils._flyConn = RunService.Heartbeat:Connect(function()
                if not Core.IsOn("flyMode") then return end
                local cam = Workspace.CurrentCamera
                local vel = Vector3.zero
                local spd = 60
                local UIS = game:GetService("UserInputService")
                if UIS:IsKeyDown(Enum.KeyCode.W) then
                    vel = vel + cam.CFrame.LookVector * spd end
                if UIS:IsKeyDown(Enum.KeyCode.S) then
                    vel = vel - cam.CFrame.LookVector * spd end
                if UIS:IsKeyDown(Enum.KeyCode.A) then
                    vel = vel - cam.CFrame.RightVector * spd end
                if UIS:IsKeyDown(Enum.KeyCode.D) then
                    vel = vel + cam.CFrame.RightVector * spd end
                if UIS:IsKeyDown(Enum.KeyCode.Space) then
                    vel = vel + Vector3.new(0, spd, 0) end
                if UIS:IsKeyDown(Enum.KeyCode.LeftShift) then
                    vel = vel - Vector3.new(0, spd, 0) end
                if PlayerUtils._flyBV then
                    PlayerUtils._flyBV.Velocity = vel
                end
            end)
        else
            if PlayerUtils._flyConn then PlayerUtils._flyConn:Disconnect() end
            if hrp then
                local bg = hrp:FindFirstChild("FlyGyro")
                local bv = hrp:FindFirstChild("FlyVelocity")
                if bg then bg:Destroy() end
                if bv then bv:Destroy() end
            end
        end
    end)

    -- No Clip
    Core.OnToggle("noClip", function(on)
        local c = LocalPlayer.Character
        if not c then return end
        for _, part in ipairs(c:GetDescendants()) do
            if part:IsA("BasePart") then
                part.CanCollide = not on
            end
        end
    end)

    -- WalkSpeed & JumpPower
    RunService.Heartbeat:Connect(function()
        if Core.IsOn("flyMode") then return end
        local hum = GetHumanoid()
        if hum then
            hum.WalkSpeed = Core.GetSlider("walkSpeed")
            hum.JumpPower = Core.GetSlider("jumpPower")
        end
    end)

    -- Infinite Energy
    RunService.Heartbeat:Connect(function()
        if Core.IsOn("infiniteEnergy") then
            local stats = LocalPlayer:FindFirstChild("leaderstats")
                       or LocalPlayer:FindFirstChild("Data")
            if stats then
                local energy = stats:FindFirstChild("Energy")
                if energy then energy.Value = 10000 end
            end
        end
    end)
end

function PlayerUtils.Tick(_dt: number)
    -- Auto Dodge
    if Core.IsOn("autoDodge") then
        local c, hrp = GetChar()
        if c and hrp then
            for _, obj in ipairs(Workspace:GetDescendants()) do
                if obj:IsA("BasePart") and obj.Name:find("Bullet") then
                    if DistanceTo(obj.Position) < 12 then
                        TeleportTo(hrp.Position + Vector3.new(
                            math.random(-20, 20), 0, math.random(-20, 20)))
                    end
                end
            end
        end
    end
end

-- ============================================================
--  MODULE: Stats System
-- ============================================================
local StatsSystem = {}

local STAT_MAP = {
    statsMelee   = "Melee",
    statsDefense = "Defense",
    statsSword   = "Sword",
    statsGun     = "Gun",
    statsFruit   = "Blox Fruit",
}

function StatsSystem.Tick(_dt: number)
    for featureId, statName in pairs(STAT_MAP) do
        if Core.IsOn(featureId) then
            FireRemote("AddStat", statName)
        end
    end

    if Core.IsOn("smartStats") then
        local data = LocalPlayer:FindFirstChild("Data")
        if data then
            local maxStat, maxName = 0, "Melee"
            for _, name in ipairs({ "Melee","Defense","Sword","Gun","Blox Fruit" }) do
                local val = data:FindFirstChild(name)
                if val and val.Value > maxStat then
                    maxStat = val.Value
                    maxName = name
                end
            end
            FireRemote("AddStat", maxName)
        end
    end
end

-- ============================================================
--  MODULE: Quest System
-- ============================================================
local QuestSystem = {}
QuestSystem._timer = 0

function QuestSystem.Tick(dt: number)
    if not (Core.IsOn("autoQuest") or Core.IsOn("autoNextQuest")) then return end
    QuestSystem._timer += dt
    if QuestSystem._timer < 2 then return end
    QuestSystem._timer = 0

    local questNPC, pos = FindNearestNPC({ "Quest", "Guard" }, 200)
    if questNPC and pos then
        TeleportTo(pos + Vector3.new(0, 3, 0))
        FireRemote("AcceptQuest")
        FireRemote("TurnInQuest")
        Core.State.Stats.QuestsDone += 1
        Core.Log("Quest hoàn thành #" .. Core.State.Stats.QuestsDone, "success")
    end
end

-- ============================================================
--  MODULE: Misc (Anti-AFK, FPS Boost, Auto Chest)
-- ============================================================
local MiscSystem = {}
MiscSystem._afkTimer = 0

function MiscSystem.Init()
    -- Anti AFK
    RunService.Heartbeat:Connect(function(dt)
        if not Core.IsOn("antiAFK") then return end
        MiscSystem._afkTimer += dt
        if MiscSystem._afkTimer >= 60 then
            MiscSystem._afkTimer = 0
            VirtualUser:CaptureController()
            VirtualUser:ClickButton2(Vector2.new())
        end
    end)

    -- FPS Boost
    Core.OnToggle("fpsBoost", function(on)
        local ls = game:GetService("Lighting")
        if on then
            ls.GlobalShadows = false
            ls.FogEnd        = 10000
            for _, obj in ipairs(Workspace:GetDescendants()) do
                if obj:IsA("ParticleEmitter") or obj:IsA("Smoke")
                   or obj:IsA("Fire") or obj:IsA("Sparkles") then
                    obj.Enabled = false
                end
            end
            Core.Log("FPS Boost bật — shadow & particles tắt.", "success")
        else
            ls.GlobalShadows = true
        end
    end)
end

function MiscSystem.Tick(_dt: number)
    -- Auto Chest
    if Core.IsOn("autoChest") then
        for _, obj in ipairs(Workspace:GetDescendants()) do
            if obj:IsA("Model") and (obj.Name:find("Chest") or obj.Name == "Box") then
                local root = obj:FindFirstChildOfClass("BasePart")
                if root and DistanceTo(root.Position) < 300 then
                    TeleportTo(root.Position + Vector3.new(0, 2, 0))
                    FireRemote("OpenChest", obj)
                end
            end
        end
    end
end

-- ============================================================
--  INIT & TICK TỔNG HỢP
-- ============================================================
function Systems.Init(coreRef)
    Core = coreRef
    PlayerUtils.Init()
    MiscSystem.Init()
    Core.Log("Systems khởi tạo xong.", "info")
end

function Systems.Tick(dt: number)
    FarmEngine.Tick(dt)
    Combat.Tick(dt)
    BossSystem.Tick(dt)
    SeaSystem.Tick(dt)
    FruitSystem.Tick(dt)
    PlayerUtils.Tick(dt)
    StatsSystem.Tick(dt)
    QuestSystem.Tick(dt)
    MiscSystem.Tick(dt)
end

return Systems
