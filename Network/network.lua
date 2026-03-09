-- ============================================================
--  PHANTOM HUB  |  network.lua
--  Server Hop · Auto Rejoin · Server Finder · Teleport Actions
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
-- ============================================================
local ISLANDS = {
    -- ── First Sea ──────────────────────────────────────────
    { name="Starter Island",   sea=1, pos=Vector3.new(980,   15,  1430)  },
    { name="Marine Starter",   sea=1, pos=Vector3.new(180,    5,  1570)  },
    { name="Jungle",           sea=1, pos=Vector3.new(-1000,  5,  3900)  },
    { name="Pirate Village",   sea=1, pos=Vector3.new(-1402,  5,  1272)  },
    { name="Desert",           sea=1, pos=Vector3.new(940,    5,  -820)  },
    { name="Frozen Village",   sea=1, pos=Vector3.new(1165,   5, -2400)  },
    { name="Marine Fortress",  sea=1, pos=Vector3.new(-2600,  5,  2000)  },
    { name="Skylands",         sea=1, pos=Vector3.new(-4882, 855, -1035) },
    { name="Prison",           sea=1, pos=Vector3.new(4736,   5,  2520)  },
    { name="Colosseum",        sea=1, pos=Vector3.new(-1325,  5, -3200)  },
    { name="Magma Village",    sea=1, pos=Vector3.new(938,    5, -4050)  },
    { name="Underwater City",  sea=1, pos=Vector3.new(61700, 25,  1600)  },
    -- ── Second Sea ─────────────────────────────────────────
    { name="Kingdom of Rose",  sea=2, pos=Vector3.new(-237,   5,  3773)  },
    { name="Graveyard",        sea=2, pos=Vector3.new(-410,   5,  5740)  },
    { name="Snow Mountain",    sea=2, pos=Vector3.new(1174,   5,  5786)  },
    { name="Hot & Cold",       sea=2, pos=Vector3.new(1003,   5,  5200)  },
    { name="Cursed Ship",      sea=2, pos=Vector3.new(-3369,  5,  4563)  },
    { name="Ice Castle",       sea=2, pos=Vector3.new(2092,   5,  5252)  },
    { name="Forgotten Island", sea=2, pos=Vector3.new(-3050, 350, 5500)  },
    -- ── Third Sea ──────────────────────────────────────────
    { name="Port Town",        sea=3, pos=Vector3.new(-5100,  5,   430)  },
    { name="Hydra Island",     sea=3, pos=Vector3.new(-6500,  5,  1200)  },
    { name="Great Tree",       sea=3, pos=Vector3.new(-7800,  5,   700)  },
    { name="Floating Turtle",  sea=3, pos=Vector3.new(-8900, 220, 2800)  },
    { name="Haunted Castle",   sea=3, pos=Vector3.new(-9500,  5,  -800)  },
    { name="Sea of Treats",    sea=3, pos=Vector3.new(-11000, 5,   300)  },
}

-- ============================================================
--  TELEPORT HANDLER
-- ============================================================
local TP_ACTIONS = {}

function TP_ACTIONS.tpFirstSea()
    TeleportService:TeleportToPlaceInstance(PLACE_ID, game.JobId, LocalPlayer)
    Core.Log("Teleport về First Sea...", "info")
end

function TP_ACTIONS.tpSecondSea()
    local remote = game:GetService("ReplicatedStorage"):FindFirstChild("ChangeSea", true)
    if remote then remote:FireServer(2) end
    Core.Log("Teleport về Second Sea...", "info")
end

function TP_ACTIONS.tpThirdSea()
    local remote = game:GetService("ReplicatedStorage"):FindFirstChild("ChangeSea", true)
    if remote then remote:FireServer(3) end
    Core.Log("Teleport về Third Sea...", "info")
end

function TP_ACTIONS.tpQuestNPC()
    for _, obj in ipairs(game.Workspace:GetDescendants()) do
        if obj:IsA("Model") and obj.Name:find("Quest") then
            local root = obj:FindFirstChild("HumanoidRootPart")
            if root then
                local hrp = LocalPlayer.Character
                    and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
                if hrp then
                    hrp.CFrame = CFrame.new(root.Position + Vector3.new(5, 0, 0))
                end
                Core.Log("Teleport đến Quest NPC: " .. obj.Name, "success")
                return
            end
        end
    end
    Core.Log("Không tìm thấy Quest NPC gần đây.", "warn")
end

function TP_ACTIONS.tpFruitDealer()
    local dealers = { "Blox Fruit Dealer", "Advanced Fruit Dealer" }
    for _, name in ipairs(dealers) do
        local npc = game.Workspace:FindFirstChild(name, true)
        if npc then
            local root = npc:FindFirstChildOfClass("BasePart")
            if root then
                local hrp = LocalPlayer.Character
                    and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
                if hrp then
                    hrp.CFrame = CFrame.new(root.Position + Vector3.new(5, 0, 0))
                end
                Core.Log("Teleport đến " .. name, "success")
                return
            end
        end
    end
    Core.Log("Không tìm thấy Fruit Dealer.", "warn")
end

function TP_ACTIONS.tpSwordDealer()
    local names = { "Sword Dealer", "Legendary Sword Dealer" }
    for _, name in ipairs(names) do
        local npc = game.Workspace:FindFirstChild(name, true)
        if npc then
            local root = npc:FindFirstChildOfClass("BasePart")
            if root then
                local hrp = LocalPlayer.Character
                    and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
                if hrp then
                    hrp.CFrame = CFrame.new(root.Position + Vector3.new(5, 0, 0))
                end
                Core.Log("Teleport đến " .. name, "success")
                return
            end
        end
    end
    Core.Log("Không tìm thấy Sword Dealer.", "warn")
end

function TP_ACTIONS.tpRaidNPC()
    local names = { "Mysterious Man", "Arowe" }
    for _, name in ipairs(names) do
        local npc = game.Workspace:FindFirstChild(name, true)
        if npc then
            local root = npc:FindFirstChildOfClass("BasePart")
            if root then
                local hrp = LocalPlayer.Character
                    and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
                if hrp then
                    hrp.CFrame = CFrame.new(root.Position + Vector3.new(5, 0, 0))
                end
                Core.Log("Teleport đến Raid NPC.", "success")
                return
            end
        end
    end
    Core.Log("Không tìm thấy Raid NPC.", "warn")
end

function TP_ACTIONS.tpBoss()
    local BOSS_NAMES = {
        "Darkbeard", "Rip_Indra", "Dough King", "Soul Reaper",
        "Gorilla King", "Greybeard", "Dragon", "Stone"
    }
    for _, name in ipairs(BOSS_NAMES) do
        local boss = game.Workspace:FindFirstChild(name, true)
        if boss then
            local root = boss:FindFirstChild("HumanoidRootPart")
            if root then
                local hrp = LocalPlayer.Character
                    and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
                if hrp then
                    hrp.CFrame = CFrame.new(root.Position + Vector3.new(8, 3, 0))
                end
                Core.Log("Teleport đến boss: " .. name, "warn")
                return
            end
        end
    end
    Core.Log("Không tìm thấy boss đang spawn.", "warn")
end

-- Đăng ký tất cả callback teleport vào Core
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
ServerHop._interval = 180  -- giây giữa mỗi lần hop

function ServerHop.Hop()
    Core.Log("Server hopping...", "warn")
    Core.State.Stats.ServerHops += 1
    local ok, err = pcall(function()
        TeleportService:TeleportToPlaceInstance(
            PLACE_ID,
            HttpService:GenerateGUID(false),
            LocalPlayer
        )
    end)
    if not ok then
        Core.Log("Server hop thất bại: " .. tostring(err), "warn")
    end
end

function ServerHop.Tick(dt: number)
    if not Core.IsOn("serverHop") then return end
    ServerHop._timer += dt
    if ServerHop._timer >= ServerHop._interval then
        ServerHop._timer = 0
        ServerHop.Hop()
    end
end

function ServerHop.BossHop()
    if Core.IsOn("bossServerHop") then
        ServerHop.Hop()
    end
end

-- ============================================================
--  AUTO REJOIN
-- ============================================================
local AutoRejoin = {}

function AutoRejoin.Init()
    game:GetService("Players").PlayerRemoving:Connect(function(player)
        if player == LocalPlayer and Core.IsOn("autoRejoin") then
            task.delay(3, function()
                TeleportService:Teleport(PLACE_ID, LocalPlayer)
            end)
        end
    end)
end

-- ============================================================
--  FIND SERVER UTILITIES
-- ============================================================
local ServerFinder = {}

function ServerFinder.FindLowPlayer()
    Core.Log("Đang tìm server ít người...", "info")
    local ok, result = pcall(function()
        return HttpService:GetAsync(
            "https://games.roblox.com/v1/games/" .. PLACE_ID ..
            "/servers/Public?sortOrder=Asc&limit=25"
        )
    end)
    if ok and result then
        local data = HttpService:JSONDecode(result)
        local best, bestPlayers = nil, math.huge
        for _, server in ipairs(data.data or {}) do
            if server.playing < bestPlayers and server.id ~= game.JobId then
                best        = server.id
                bestPlayers = server.playing
            end
        end
        if best then
            Core.Log(string.format(
                "Tìm thấy server %d người — đang hop...", bestPlayers), "success")
            TeleportService:TeleportToPlaceInstance(PLACE_ID, best, LocalPlayer)
        else
            Core.Log("Không tìm thấy server phù hợp.", "warn")
        end
    else
        Core.Log("Lỗi HTTP: " .. tostring(result), "warn")
    end
end

function ServerFinder.FindBossServer()
    Core.Log("Tìm server có boss — đang scan...", "info")
    ServerFinder.FindLowPlayer()
end

function ServerFinder.FindEventServer()
    Core.Log("Tìm server có event đang diễn ra...", "info")
    ServerFinder.FindLowPlayer()
end

local function RegisterServerCallbacks()
    Core.OnToggle("findLowServer",   function(_) ServerFinder.FindLowPlayer()   end)
    Core.OnToggle("findBossServer",  function(_) ServerFinder.FindBossServer()  end)
    Core.OnToggle("findEventServer", function(_) ServerFinder.FindEventServer() end)
end

-- ============================================================
--  INIT & TICK
-- ============================================================
function Network.Init(coreRef)
    Core = coreRef
    AutoRejoin.Init()
    RegisterTeleportCallbacks()
    RegisterServerCallbacks()
    Core.Log("Network module sẵn sàng.", "info")
end

function Network.Tick(dt: number)
    ServerHop.Tick(dt)
end

-- ============================================================
--  EXPORT ISLANDS (cho UI dropdown)
-- ============================================================
Network.Islands = ISLANDS

return Network
