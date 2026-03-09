-- ============================================================
--  PHANTOM HUB  |  systems.lua
--  Cập nhật: Blox Fruits Update 29 (Control Update - 23/12/2025)
--  Thêm: Dungeon System · Trinket Farm · PvP Arena · Control Rework
-- ============================================================

local Players           = game:GetService("Players")
local RunService        = game:GetService("RunService")
local Workspace         = game:GetService("Workspace")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local VirtualUser       = game:GetService("VirtualUser")

local LocalPlayer = Players.LocalPlayer
local Core

local Systems = {}

-- ============================================================
--  TIỆN ÍCH NỘI BỘ
-- ============================================================
local function GetChar(): (Model?, BasePart?)
    local c = LocalPlayer.Character
    if not c then return nil, nil end
    return c, c:FindFirstChild("HumanoidRootPart")
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

local function FindNearestNPC(names: {string}, maxDist: number?): (Model?, Vector3?)
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

local function FireRemote(name: string, ...)
    local remote = ReplicatedStorage:FindFirstChild(name, true)
    if remote and remote:IsA("RemoteEvent") then
        remote:FireServer(...)
    end
end

local function InvokeRemote(name: string, ...): any
    local remote = ReplicatedStorage:FindFirstChild(name, true)
    if remote and remote:IsA("RemoteFunction") then
        return remote:InvokeServer(...)
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
    "Sky Bandit", "Dark Master", "Snow Bandit", "Galley Pirate",
    "Monkey", "Gorilla", "Toga Warrior", "Saber Expert"
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

    if not FarmEngine._target or not FarmEngine._target.Parent
        or not FarmEngine._target:FindFirstChildOfClass("Humanoid")
        or FarmEngine._target:FindFirstChildOfClass("Humanoid").Health <= 0 then

        FarmEngine._target = nil
        local names = Core.IsOn("farmMobCluster") and QUEST_NPCS or { "Bandit", "Pirate" }
        local mob, pos = FindNearestNPC(names, Core.IsOn("fastFarm") and 1000 or 400)
        FarmEngine._target = mob
        if mob and pos and DistanceTo(pos) > 20 then
            TeleportTo(pos + Vector3.new(0, 3, 0))
        end
    end

    if FarmEngine._target then
        local root = FarmEngine._target:FindFirstChild("HumanoidRootPart")
        if root then
            if DistanceTo(root.Position) > 15 then
                TeleportTo(root.Position + Vector3.new(0, 3, 0))
            end
            hrp.CFrame = CFrame.lookAt(hrp.Position, root.Position)
            if Core.IsOn("autoClick") then mouse1click() end
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
    if Core.IsOn("fastAttack") or Core.IsOn("noDelay") then
        local hum = GetHumanoid()
        if hum then hum.WalkSpeed = Core.IsOn("fastAttack") and 28 or hum.WalkSpeed end
    end

    local skillMap = { Z="autoSkillZ", X="autoSkillX", C="autoSkillC", V="autoSkillV", F="autoSkillF" }
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

    if Core.IsOn("autoHaki") then FireRemote("Haki", "Armament", true) end

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
BossSystem._timer = 0

local BOSS_MAP = {
    autoDarkbeard  = { "Darkbeard" },
    autoRipIndra   = { "Rip_Indra", "Rip Indra" },
    autoDoughKing  = { "Dough King" },
    autoSoulReaper = { "Soul Reaper" },
    autoBoss       = { "Gorilla King", "Bobby", "Yeti", "Snow Lurker", "Greybeard", "Dragon" },
    autoEliteBoss  = { "Stone", "Island Empress", "Kilo Admiral", "Tide Keeper" },
}

function BossSystem.Tick(dt: number)
    BossSystem._timer += dt
    if BossSystem._timer < 0.5 then return end
    BossSystem._timer = 0

    local c, hrp = GetChar()
    if not c or not hrp then return end
    local hum = GetHumanoid()
    if not hum or hum.Health <= 0 then return end

    for featureId, names in pairs(BOSS_MAP) do
        if Core.IsOn(featureId) then
            local boss, pos = FindNearestNPC(names, 2000)
            if boss and pos then
                if DistanceTo(pos) > 30 then TeleportTo(pos + Vector3.new(0, 5, 0)) end
                hrp.CFrame = CFrame.lookAt(hrp.Position, pos)
                if Core.IsOn("autoClick") then mouse1click() end
            else
                if Core.IsOn("bossServerHop") then
                    Core.Log("Boss không spawn — đợi server hop...", "warn")
                end
            end
            break
        end
    end
end

-- ============================================================
--  MODULE: Dungeon System (MỚI - Update 29)
--  - 15 tầng (floor), sau mỗi 5 tầng có boss
--  - 4 độ khó: Normal(Lv500) / Hard(Lv1000) / Nightmare(Lv1800) / Inferno(Lv2400)
--  - Stat points bị cân bằng trong dungeon (không quan trọng)
--  - Reward: Trinkets, Cash, Simulation Data
-- ============================================================
local DungeonSystem = {}
DungeonSystem._timer       = 0
DungeonSystem._floor       = 0
DungeonSystem._inDungeon   = false
DungeonSystem._difficultyMap = {
    dungeonNormal    = "Normal",
    dungeonHard      = "Hard",
    dungeonNightmare = "Nightmare",
    dungeonInferno   = "Inferno",
}

local function GetDungeonDifficulty(): string?
    for featureId, diffName in pairs(DungeonSystem._difficultyMap) do
        if Core.IsOn(featureId) then return diffName end
    end
    return nil
end

local function EnterDungeon(difficulty: string)
    -- Tìm Lucian NPC để vào dungeon (Sea 2 & Sea 3)
    local lucianNames = { "Lucian", "Dungeon Portal", "Realm Teleporter" }
    local npc, pos = FindNearestNPC(lucianNames, 5000)

    if npc and pos then
        TeleportTo(pos + Vector3.new(3, 0, 0))
        task.wait(0.5)
        FireRemote("EnterDungeon", difficulty)
        Core.Log("Vào Dungeon " .. difficulty .. "...", "success")
        DungeonSystem._inDungeon = true
        DungeonSystem._floor = 0
    else
        -- Thử dùng Realm Teleporter trong Server Browser
        FireRemote("OpenRealmTeleporter")
        task.wait(0.3)
        FireRemote("EnterDungeonFromBrowser", difficulty)
        Core.Log("Dùng Realm Teleporter → Dungeon " .. difficulty, "info")
        DungeonSystem._inDungeon = true
    end
end

local function ClearDungeonFloor()
    local c, hrp = GetChar()
    if not c or not hrp then return end

    -- Tìm tất cả enemy trong dungeon
    local enemyNames = { "Dungeon Enemy", "Floor Enemy", "Dungeon Mob", "Realm Enemy" }
    local enemy, pos = FindNearestNPC(enemyNames, 300)

    if enemy and pos then
        if DistanceTo(pos) > 20 then TeleportTo(pos + Vector3.new(0, 3, 0)) end
        hrp.CFrame = CFrame.lookAt(hrp.Position, pos)
        if Core.IsOn("autoClick") then mouse1click() end
    else
        -- Tầng sạch — lên tầng tiếp theo
        DungeonSystem._floor += 1
        Core.Log("Tầng " .. DungeonSystem._floor .. " hoàn thành!", "success")
        FireRemote("NextDungeonFloor")
    end
end

local function PickPowerUpCard()
    if not Core.IsOn("autoPickPowerUp") then return end
    -- Tự động chọn power-up card tốt nhất (ưu tiên damage > defense > speed)
    local priority = { "Damage", "CritRate", "Speed", "Defense", "Energy" }
    for _, cardType in ipairs(priority) do
        local ok = pcall(FireRemote, "SelectPowerUpCard", cardType)
        if ok then
            Core.Log("Chọn Power-Up Card: " .. cardType, "success")
            break
        end
    end
end

local function CollectDungeonReward()
    if not Core.IsOn("autoCollectReward") then return end
    FireRemote("ClaimDungeonReward")
    Core.State.Stats.DungeonRuns += 1
    Core.Log("Dungeon run #" .. Core.State.Stats.DungeonRuns .. " hoàn thành!", "success")
    DungeonSystem._inDungeon = false
    DungeonSystem._floor = 0
end

function DungeonSystem.Tick(dt: number)
    if not Core.IsOn("autoDungeon") then return end

    DungeonSystem._timer += dt
    if DungeonSystem._timer < 0.3 then return end
    DungeonSystem._timer = 0

    local c, hrp = GetChar()
    if not c or not hrp then return end
    local hum = GetHumanoid()
    if not hum or hum.Health <= 0 then return end

    -- Chưa trong dungeon → vào dungeon
    if not DungeonSystem._inDungeon then
        local diff = GetDungeonDifficulty()
        if not diff then diff = "Normal" end
        EnterDungeon(diff)
        return
    end

    -- Đang trong dungeon
    if Core.IsOn("autoClearFloors") then
        -- Kiểm tra có đến boss tầng chưa (tầng 5, 10, 15)
        if DungeonSystem._floor > 0 and DungeonSystem._floor % 5 == 0
            and Core.IsOn("dungeonBossKill") then
            -- Boss floor: tìm và giết boss dungeon
            local bossNames = { "Floor Boss", "Dungeon Boss", "Realm Guardian" }
            local boss, pos = FindNearestNPC(bossNames, 500)
            if boss and pos then
                if DistanceTo(pos) > 25 then TeleportTo(pos + Vector3.new(0, 5, 0)) end
                hrp.CFrame = CFrame.lookAt(hrp.Position, pos)
                if Core.IsOn("autoClick") then mouse1click() end
            end
        else
            ClearDungeonFloor()
        end

        -- Power-up card sau mỗi tầng
        PickPowerUpCard()

        -- Tầng 15 = hoàn thành
        if DungeonSystem._floor >= 15 then
            CollectDungeonReward()
        end
    end
end

-- ============================================================
--  MODULE: Trinket System (MỚI - Update 29)
--  - Trinkets: equippable RPG gear, stat buff thụ động
--  - Nhận từ Dungeon (Normal→Common, Hard→Rare, Nightmare→Epic, Inferno→Mythical)
--  - Fuse: ghép 2 trinket cùng loại → mạnh hơn
--  - Scrap: phá trinket yếu → lấy Simulation Data (tiền tệ dungeon)
--  - Reforge: thay đổi modifier của trinket
-- ============================================================
local TrinketSystem = {}
TrinketSystem._timer = 0

local TRINKET_STATS = { "MeleeDmg", "SwordStat", "CooldownReduction", "Armor", "OverflowHealth", "EnergyRegen" }

local function GetTrinketInventory(): { any }
    -- Lấy danh sách trinket trong inventory
    local inv = {}
    local data = LocalPlayer:FindFirstChild("Data") or LocalPlayer:FindFirstChild("PlayerData")
    if data then
        local trinkets = data:FindFirstChild("Trinkets")
        if trinkets then
            for _, t in ipairs(trinkets:GetChildren()) do
                table.insert(inv, t)
            end
        end
    end
    return inv
end

local function GetBestTrinket(trinkets: { any }): any?
    -- So sánh theo rarity: Mythical > Epic > Rare > Common
    local rarityScore = { Common=1, Rare=2, Epic=3, Legendary=4, Mythical=5 }
    local best, bestScore = nil, 0
    for _, t in ipairs(trinkets) do
        local rarity = t:FindFirstChild("Rarity")
        local score  = rarity and (rarityScore[rarity.Value] or 0) or 0
        if score > bestScore then best, bestScore = t, score end
    end
    return best
end

function TrinketSystem.Tick(dt: number)
    TrinketSystem._timer += dt
    if TrinketSystem._timer < 2 then return end
    TrinketSystem._timer = 0

    local trinkets = GetTrinketInventory()
    if #trinkets == 0 then return end

    -- Auto Equip Best Trinket
    if Core.IsOn("autoEquipTrinket") then
        local best = GetBestTrinket(trinkets)
        if best then
            FireRemote("EquipTrinket", best.Name)
            Core.Log("Trang bị Trinket: " .. best.Name, "success")
        end
    end

    -- Auto Fuse Trinket — ghép 2 trinket cùng loại
    if Core.IsOn("autoFuseTrinket") and #trinkets >= 2 then
        -- Nhóm theo loại
        local groups: { [string]: { any } } = {}
        for _, t in ipairs(trinkets) do
            local tType = t:FindFirstChild("Type")
            if tType then
                groups[tType.Value] = groups[tType.Value] or {}
                table.insert(groups[tType.Value], t)
            end
        end
        for tType, group in pairs(groups) do
            if #group >= 2 then
                FireRemote("FuseTrinket", group[1].Name, group[2].Name)
                Core.State.Stats.TrinketsFound += 1
                Core.Log("Fuse Trinket: " .. tType, "success")
                break
            end
        end
    end

    -- Auto Scrap Weak Trinket (Common rarity)
    if Core.IsOn("autoScrapTrinket") then
        for _, t in ipairs(trinkets) do
            local rarity = t:FindFirstChild("Rarity")
            if rarity and rarity.Value == "Common" then
                FireRemote("ScrapTrinket", t.Name)
                Core.Log("Scrap Trinket Common: " .. t.Name, "info")
            end
        end
    end

    -- Auto Reforge Trinket
    if Core.IsOn("autoReforge") then
        for _, t in ipairs(trinkets) do
            local rarity = t:FindFirstChild("Rarity")
            if rarity and (rarity.Value == "Rare" or rarity.Value == "Epic") then
                FireRemote("ReforgeTrinket", t.Name)
                Core.Log("Reforge: " .. t.Name, "info")
                break
            end
        end
    end
end

-- ============================================================
--  MODULE: Sea Event System
-- ============================================================
local SeaSystem = {}
SeaSystem._timer = 0

local SEA_MAP = {
    autoSeaBeast   = { "Sea Beast", "Terrorshark", "Bone Demon" },
    autoPirateRaid = { "Pirate Raid", "Mob" },
    autoGhostShip  = { "Ghost Ship" },
}

function SeaSystem.Tick(dt: number)
    SeaSystem._timer += dt
    if SeaSystem._timer < 0.5 then return end
    SeaSystem._timer = 0

    for featureId, names in pairs(SEA_MAP) do
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

    if Core.IsOn("autoSeaChest") then
        for _, obj in ipairs(Workspace:GetDescendants()) do
            if obj:IsA("Model") and obj.Name:find("Chest") then
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
--  MODULE: Fruit System
-- ============================================================
local FruitSystem = {}
FruitSystem._timer = 0

function FruitSystem.Tick(dt: number)
    FruitSystem._timer += dt
    if FruitSystem._timer < 1 then return end
    FruitSystem._timer = 0

    local folder = Workspace:FindFirstChild("Fruits")
    if not folder then return end

    for _, fruit in ipairs(folder:GetChildren()) do
        local root = fruit:IsA("BasePart") and fruit
                  or fruit:FindFirstChildOfClass("BasePart")
        if root then
            if Core.IsOn("fruitNotifier") then
                Core.Log("Fruit spawn: " .. fruit.Name, "warn")
            end
            if Core.IsOn("fruitSniper") or Core.IsOn("autoCollectFruit") then
                TeleportTo(root.Position + Vector3.new(0, 2, 0))
                FireRemote("PickFruit", fruit)
                Core.State.Stats.FruitsCollected += 1
                Core.Log("Thu thập: " .. fruit.Name, "success")
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
            
            local bg = Instance.new("BodyGyro", hrp)
            bg.Name = "FlyGyro"; bg.MaxTorque = Vector3.new(1e9,1e9,1e9); bg.D = 50
            
            local bv = Instance.new("BodyVelocity", hrp)
            bv.Name = "FlyVelocity"; bv.MaxForce = Vector3.new(1e9,1e9,1e9); bv.Velocity = Vector3.zero
            
            PlayerUtils._flyBV = bv
            PlayerUtils._flyConn = RunService.Heartbeat:Connect(function()
                if not Core.IsOn("flyMode") then return end
                local UIS = game:GetService("UserInputService")
                local cam = Workspace.CurrentCamera
                local vel, spd = Vector3.zero, 60
                if UIS:IsKeyDown(Enum.KeyCode.W) then vel += cam.CFrame.LookVector  * spd end
                if UIS:IsKeyDown(Enum.KeyCode.S) then vel -= cam.CFrame.LookVector  * spd end
                if UIS:IsKeyDown(Enum.KeyCode.A) then vel -= cam.CFrame.RightVector * spd end
                if UIS:IsKeyDown(Enum.KeyCode.D) then vel += cam.CFrame.RightVector * spd end
                if UIS:IsKeyDown(Enum.KeyCode.Space)     then vel += Vector3.new(0, spd, 0) end
                if UIS:IsKeyDown(Enum.KeyCode.LeftShift) then vel -= Vector3.new(0, spd, 0) end
                if PlayerUtils._flyBV then PlayerUtils._flyBV.Velocity = vel end
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
        for _, p in ipairs(c:GetDescendants()) do
            if p:IsA("BasePart") then p.CanCollide = not on end
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
        if not Core.IsOn("infiniteEnergy") then return end
        local data = LocalPlayer:FindFirstChild("Data") or LocalPlayer:FindFirstChild("leaderstats")
        if data then
            local e = data:FindFirstChild("Energy")
            if e then e.Value = 10000 end
        end
    end)
end

function PlayerUtils.Tick(_dt: number)
    if Core.IsOn("autoDodge") then
        local c, hrp = GetChar()
        if c and hrp then
            for _, obj in ipairs(Workspace:GetDescendants()) do
                if obj:IsA("BasePart") and obj.Name:find("Bullet") then
                    if DistanceTo(obj.Position) < 12 then
                        TeleportTo(hrp.Position + Vector3.new(
                            math.random(-20,20), 0, math.random(-20,20)))
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
    statsMelee="Melee", statsDefense="Defense",
    statsSword="Sword", statsGun="Gun", statsFruit="Blox Fruit"
}

function StatsSystem.Tick(_dt: number)
    for id, name in pairs(STAT_MAP) do
        if Core.IsOn(id) then FireRemote("AddStat", name) end
    end
    if Core.IsOn("smartStats") then
        local data = LocalPlayer:FindFirstChild("Data")
        if data then
            local maxS, maxN = 0, "Melee"
            for _, n in ipairs({"Melee","Defense","Sword","Gun","Blox Fruit"}) do
                local v = data:FindFirstChild(n)
                if v and v.Value > maxS then maxS = v.Value; maxN = n end
            end
            FireRemote("AddStat", maxN)
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

    local npc, pos = FindNearestNPC({"Quest", "Guard"}, 200)
    if npc and pos then
        TeleportTo(pos + Vector3.new(0, 3, 0))
        FireRemote("AcceptQuest")
        FireRemote("TurnInQuest")
        Core.State.Stats.QuestsDone += 1
        Core.Log("Quest #" .. Core.State.Stats.QuestsDone .. " hoàn thành!", "success")
    end
end

-- ============================================================
--  MODULE: Misc
-- ============================================================
local MiscSystem = {}
MiscSystem._afkTimer = 0

function MiscSystem.Init()
    RunService.Heartbeat:Connect(function(dt)
        if not Core.IsOn("antiAFK") then return end
        MiscSystem._afkTimer += dt
        if MiscSystem._afkTimer >= 60 then
            MiscSystem._afkTimer = 0
            VirtualUser:CaptureController()
            VirtualUser:ClickButton2(Vector2.new())
        end
    end)

    Core.OnToggle("fpsBoost", function(on)
        local ls = game:GetService("Lighting")
        ls.GlobalShadows = not on
        if on then
            ls.FogEnd = 10000
            for _, o in ipairs(Workspace:GetDescendants()) do
                if o:IsA("ParticleEmitter") or o:IsA("Smoke")
                   or o:IsA("Fire") or o:IsA("Sparkles") then
                    o.Enabled = false
                end
            end
            Core.Log("FPS Boost bật.", "success")
        end
    end)
end

function MiscSystem.Tick(_dt: number)
    if Core.IsOn("autoChest") then
        for _, obj in ipairs(Workspace:GetDescendants()) do
            if obj:IsA("Model") and (obj.Name:find("Chest") or obj.Name == "Box") then
                local root = obj:FindFirstChildOfClass("BasePart")
                if root and DistanceTo(root.Position) < 300 then
                    TeleportTo(root.Position + Vector3.new(0,2,0))
                    FireRemote("OpenChest", obj)
                end
            end
        end
    end
end

-- ============================================================
--  INIT & TICK
-- ============================================================
function Systems.Init(coreRef)
    Core = coreRef
    PlayerUtils.Init()
    MiscSystem.Init()
    Core.Log("Systems (Update 29) khởi tạo xong.", "info")
end

function Systems.Tick(dt: number)
    FarmEngine.Tick(dt)
    Combat.Tick(dt)
    BossSystem.Tick(dt)
    DungeonSystem.Tick(dt)
    TrinketSystem.Tick(dt)
    SeaSystem.Tick(dt)
    FruitSystem.Tick(dt)
    PlayerUtils.Tick(dt)
    StatsSystem.Tick(dt)
    QuestSystem.Tick(dt)
    MiscSystem.Tick(dt)
end

return Systems


