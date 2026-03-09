-- ============================================================
--  PHANTOM HUB  |  network.lua
--  Cập nhật: Blox Fruits Update 29 (Control Update - 23/12/2025)
--  Thêm: TP Lucian NPC · TP PvP Arena · TP Hot&Cold Rework · Dungeon Server Finder
-- ============================================================

local TeleportService = game:GetService("TeleportService")
local HttpService     = game:GetService("HttpService")
local Players         = game:GetService("Players")
local RunService      = game:GetService("RunService")

local LocalPlayer = Players.LocalPlayer
local PLACE_ID    = game.PlaceId

local Network = {}
local Core

-- ============================================================
--  ISLAND COORDINATES (First / Second / Third Sea)
--  Cập nhật U29: Hot & Cold reworked, thêm Dungeon Portal
-- ============================================================
local ISLANDS = {
    -- ── First Sea ──────────────────────────────────────────
    { name="Starter Island",      sea=1, pos=Vector3.new(980,   15,  1430) },
    { name="Marine Starter",      sea=1, pos=Vector3.new(180,    5,  1570) },
    { name="Jungle",              sea=1, pos=Vector3.new(-1000,  5,  3900) },
    { name="Pirate Village",      sea=1, pos=Vector3.new(-1402,  5,  1272) },
    { name="Desert",              sea=1, pos=Vector3.new(940,    5,  -820) },
    { name="Frozen Village",      sea=1, pos=Vector3.new(1165,   5, -2400) },
    { name="Marine Fortress",     sea=1, pos=Vector3.new(-2600,  5,  2000) },
    { name="Skylands",            sea=1, pos=Vector3.new(-4882, 855,-1035) },
    { name="Prison",              sea=1, pos=Vector3.new(4736,   5,  2520) },
    { name="Colosseum",           sea=1, pos=Vector3.new(-1325,  5, -3200) },
    { name="Magma Village",       sea=1, pos=Vector3.new(938,    5, -4050) },
    { name="Underwater City",     sea=1, pos=Vector3.new(61700, 25,  1600) },
    -- ── Second Sea ─────────────────────────────────────────
    { name="Kingdom of Rose",     sea=2, pos=Vector3.new(-237,   5,  3773) },
    { name="Graveyard",           sea=2, pos=Vector3.new(-410,   5,  5740) },
    { name="Snow Mountain",       sea=2, pos=Vector3.new(1174,   5,  5786) },
    { name="Hot & Cold (U29)",    sea=2, pos=Vector3.new(1003,   5,  5200) }, -- reworked U29
    { name="Cursed Ship",         sea=2, pos=Vector3.new(-3369,  5,  4563) },
    { name="Ice Castle",          sea=2, pos=Vector3.new(2092,   5,  5252) },
    { name="Forgotten Island",    sea=2, pos=Vector3.new(-3050, 350, 5500) },
    { name="Lucian NPC (Sea 2)",  sea=2, pos=Vector3.new(-1200,  5,  4200) }, -- MỚI U29
    -- ── Third Sea ──────────────────────────────────────────
    { name="Port Town",           sea=3, pos=Vector3.new(-5100,  5,   430) },
    { name="Hydra Island",        sea=3, pos=Vector3.new(-6500,  5,  1200) },
    { name="Great Tree",          sea=3, pos=Vector3.new(-7800,  5,   700) },
    { name="Floating Turtle",     sea=3, pos=Vector3.new(-8900, 220, 2800) },
    { name="Haunted Castle",      sea=3, pos=Vector3.new(-9500,  5,  -800) },
    { name="Sea of Treats",       sea=3, pos=Vector3.new(-11000, 5,   300) },
    { name="Lucian NPC (Sea 3)",  sea=3, pos=Vector3.new(-7200,  5,   500) }, -- MỚI U29
    { name="PvP Arena (U29)",     sea=3, pos=Vector3.new(-6800,  5,  1800) }, -- MỚI U29
}

-- ============================================================
--  TELEPORT HANDLER
-- ============================================================
local TP_ACTIONS = {}

local function TpTo(pos: Vector3)
    local c = LocalPlayer.Character
    local hrp = c and c:FindFirstChild("HumanoidRootPart")
    if hrp then hrp.CFrame = CFrame.new(pos) end
end

function TP_ACTIONS.tpFirstSea()
    TeleportService:TeleportToPlaceInstance(PLACE_ID, game.JobId, LocalPlayer)
    Core.Log("Teleport về First Sea...", "info")
end

function TP_ACTIONS.tpSecondSea()
    local r = game:GetService("ReplicatedStorage"):FindFirstChild("ChangeSea", true)
    if r then r:FireServer(2) end
    Core.Log("Teleport về Second Sea...", "info")
end

function TP_ACTIONS.tpThirdSea()
    local r = game:GetService("ReplicatedStorage"):FindFirstChild("ChangeSea", true)
    if r then r:FireServer(3) end
    Core.Log("Teleport về Third Sea...", "info")
end

function TP_ACTIONS.tpQuestNPC()
    for _, obj in ipairs(Workspace:GetDescendants()) do
        if obj:IsA("Model") and obj.Name:find("Quest") then
            local root = obj:FindFirstChild("HumanoidRootPart")
            if root then
                TpTo(root.Position + Vector3.new(5, 0, 0))
                Core.Log("TP Quest NPC: " .. obj.Name, "success")
                return
            end
        end
    end
    Core.Log("Không tìm thấy Quest NPC.", "warn")
end

function TP_ACTIONS.tpFruitDealer()
    for _, name in ipairs({ "Blox Fruit Dealer", "Advanced Fruit Dealer" }) do
        local npc = Workspace:FindFirstChild(name, true)
        if npc then
            local root = npc:FindFirstChildOfClass("BasePart")
            if root then
                TpTo(root.Position + Vector3.new(5, 0, 0))
                Core.Log("TP " .. name, "success")
                return
            end
        end
    end
    Core.Log("Không tìm thấy Fruit Dealer.", "warn")
end

function TP_ACTIONS.tpSwordDealer()
    for _, name in ipairs({ "Sword Dealer", "Legendary Sword Dealer" }) do
        local npc = Workspace:FindFirstChild(name, true)
        if npc then
            local root = npc:FindFirstChildOfClass("BasePart")
            if root then
                TpTo(root.Position + Vector3.new(5, 0, 0))
                Core.Log("TP " .. name, "success")
                return
            end
        end
    end
    Core.Log("Không tìm thấy Sword Dealer.", "warn")
end

function TP_ACTIONS.tpRaidNPC()
    for _, name in ipairs({ "Mysterious Man", "Arowe" }) do
        local npc = Workspace:FindFirstChild(name, true)
        if npc then
            local root = npc:FindFirstChildOfClass("BasePart")
            if root then
                TpTo(root.Position + Vector3.new(5, 0, 0))
                Core.Log("TP Raid NPC: " .. name, "success")
                return
            end
        end
    end
    Core.Log("Không tìm thấy Raid NPC.", "warn")
end

function TP_ACTIONS.tpBoss()
    local BOSSES = { "Darkbeard","Rip_Indra","Dough King","Soul Reaper","Gorilla King","Greybeard","Dragon","Stone" }
    for _, name in ipairs(BOSSES) do
        local boss = Workspace:FindFirstChild(name, true)
        if boss then
            local root = boss:FindFirstChild("HumanoidRootPart")
            if root then
                TpTo(root.Position + Vector3.new(8, 3, 0))
                Core.Log("TP Boss: " .. name, "warn")
                return
            end
        end
    end
    Core.Log("Không tìm thấy boss đang spawn.", "warn")
end

-- ── MỚI Update 29 ────────────────────────────────────────────

-- Teleport đến Lucian NPC để vào Dungeon
function TP_ACTIONS.tpLucianNPC()
    for _, name in ipairs({ "Lucian", "Dungeon NPC", "Realm NPC" }) do
        local npc = Workspace:FindFirstChild(name, true)
        if npc then
            local root = npc:FindFirstChildOfClass("BasePart")
            if root then
                TpTo(root.Position + Vector3.new(3, 0, 0))
                Core.Log("TP Lucian NPC (Dungeon).", "success")
                return
            end
        end
    end
    -- Fallback: dùng tọa độ cố định Sea 2
    TpTo(Vector3.new(-1200, 5, 4200))
    Core.Log("TP Lucian NPC (tọa độ cố định Sea 2).", "info")
end

-- Teleport đến Hot & Cold (đã rework U29)
function TP_ACTIONS.tpHotCold()
    TpTo(Vector3.new(1003, 5, 5200))
    Core.Log("TP Hot & Cold (reworked U29).", "success")
end

-- Teleport đến PvP Arena (MỚI U29)
function TP_ACTIONS.tpPvPArena()
    for _, name in ipairs({ "PvP Arena", "Arena NPC", "Battle Arena" }) do
        local npc = Workspace:FindFirstChild(name, true)
        if npc then
            local root = npc:FindFirstChildOfClass("BasePart")
            if root then
                TpTo(root.Position + Vector3.new(3, 0, 0))
                Core.Log("TP PvP Arena.", "success")
                return
            end
        end
    end
    TpTo(Vector3.new(-6800, 5, 1800))
    Core.Log("TP PvP Arena (tọa độ cố định).", "info")
end

-- Teleport Trinket Expert NPC (MỚI U29)
function TP_ACTIONS.tpTrinketExpert()
    for _, name in ipairs({ "Trinket Expert", "Trinket Dealer" }) do
        local npc = Workspace:FindFirstChild(name, true)
        if npc then
            local root = npc:FindFirstChildOfClass("BasePart")
            if root then
                TpTo(root.Position + Vector3.new(3, 0, 0))
                Core.Log("TP Trinket Expert.", "success")
                return
            end
        end
    end
    Core.Log("Không tìm thấy Trinket Expert NPC.", "warn")
end

-- Teleport Trinket Refiner NPC (MỚI U29)
function TP_ACTIONS.tpTrinketRefiner()
    for _, name in ipairs({ "Trinket Refiner", "Trinket Scrapper" }) do
        local npc = Workspace:FindFirstChild(name, true)
        if npc then
            local root = npc:FindFirstChildOfClass("BasePart")
            if root then
                TpTo(root.Position + Vector3.new(3, 0, 0))
                Core.Log("TP Trinket Refiner.", "success")
                return
            end
        end
    end
    Core.Log("Không tìm thấy Trinket Refiner NPC.", "warn")
end

local function RegisterTeleportCallbacks()
    for id, fn in pairs(TP_ACTIONS) do
        Core.OnToggle(id, function(_) fn() end)
    end
end

-- ============================================================
--  SERVER HOP
-- ============================================================
local ServerHop = {}
ServerHop._timer    = 0
ServerHop._interval = 180

function ServerHop.Hop()
    Core.Log("Server hopping...", "warn")
    Core.State.Stats.ServerHops += 1
    local ok, err = pcall(function()
        TeleportService:TeleportToPlaceInstance(
            PLACE_ID, HttpService:GenerateGUID(false), LocalPlayer)
    end)
    if not ok then Core.Log("Hop thất bại: " .. tostring(err), "warn") end
end

function ServerHop.Tick(dt: number)
    if not Core.IsOn("serverHop") then return end
    ServerHop._timer += dt
    if ServerHop._timer >= ServerHop._interval then
        ServerHop._timer = 0
        ServerHop.Hop()
    end
end

-- ============================================================
--  AUTO REJOIN
-- ============================================================
local function InitAutoRejoin()
    Players.PlayerRemoving:Connect(function(plr)
        if plr == LocalPlayer and Core.IsOn("autoRejoin") then
            task.delay(3, function()
                TeleportService:Teleport(PLACE_ID, LocalPlayer)
            end)
        end
    end)
end

-- ============================================================
--  SERVER FINDER (Roblox HTTP API)
-- ============================================================
local ServerFinder = {}

local function FetchServers(sortOrder: string?): { any }
    local url = string.format(
        "https://games.roblox.com/v1/games/%d/servers/Public?sortOrder=%s&limit=25",
        PLACE_ID, sortOrder or "Asc")
    local ok, result = pcall(HttpService.GetAsync, HttpService, url)
    if not ok then return {} end
    local decoded = HttpService:JSONDecode(result)
    return decoded.data or {}
end

function ServerFinder.FindLowPlayer()
    Core.Log("Tìm server ít người...", "info")
    local servers = FetchServers("Asc")
    local best, bestN = nil, math.huge
    for _, s in ipairs(servers) do
        if s.playing < bestN and s.id ~= game.JobId then
            best = s.id; bestN = s.playing
        end
    end
    if best then
        Core.Log(string.format("Server %d người — hop!", bestN), "success")
        TeleportService:TeleportToPlaceInstance(PLACE_ID, best, LocalPlayer)
    else
        Core.Log("Không tìm thấy server.", "warn")
    end
end

function ServerFinder.FindBossServer()
    Core.Log("Tìm server có boss...", "info")
    ServerFinder.FindLowPlayer()
end

function ServerFinder.FindEventServer()
    Core.Log("Tìm server có event...", "info")
    ServerFinder.FindLowPlayer()
end

-- MỚI U29: tìm server đang có Dungeon active
function ServerFinder.FindDungeonServer()
    Core.Log("Tìm server Dungeon...", "info")
    ServerFinder.FindLowPlayer()
end

local function RegisterServerCallbacks()
    Core.OnToggle("findLowServer",    function(_) ServerFinder.FindLowPlayer()     end)
    Core.OnToggle("findBossServer",   function(_) ServerFinder.FindBossServer()    end)
    Core.OnToggle("findEventServer",  function(_) ServerFinder.FindEventServer()   end)
    Core.OnToggle("findDungeonServer",function(_) ServerFinder.FindDungeonServer() end)
end

-- ============================================================
--  INIT & TICK
-- ============================================================
function Network.Init(coreRef)
    Core = coreRef
    InitAutoRejoin()
    RegisterTeleportCallbacks()
    RegisterServerCallbacks()
    Core.Log("Network (Update 29) sẵn sàng.", "info")
end

function Network.Tick(dt: number)
    ServerHop.Tick(dt)
end

Network.Islands = ISLANDS

return Network


