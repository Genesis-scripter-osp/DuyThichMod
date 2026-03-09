-- ============================================================
--  PHANTOM HUB  |  core.lua
--  Quản lý state trung tâm, feature registry, config I/O
-- ============================================================

local HttpService  = game:GetService("HttpService")
local Players      = game:GetService("Players")
local LocalPlayer  = Players.LocalPlayer

local Core = {}

-- ── CONFIG PATH (dùng writefile / readfile của executor) ─────
local CONFIG_FILE = "PhantomHub_config.json"

-- ============================================================
--  STATE — toàn bộ trạng thái runtime của hub
-- ============================================================
Core.State = {
    Running        = true,
    ActiveToggles  = {},   -- [featureId] = bool
    SliderValues   = {},   -- [featureId] = number
    Stats = {
        MobsKilled      = 0,
        QuestsDone      = 0,
        BossesKilled    = 0,
        FruitsCollected = 0,
        ServerHops      = 0,
        StartTime       = os.clock(),
    },
    Log = {},              -- { time, msg, level }
}

-- ============================================================
--  FEATURE REGISTRY — định nghĩa 120+ chức năng
-- ============================================================
Core.Registry = {

    -- ── 1. MAIN / AUTO FARM ──────────────────────────────────
    { id="autoFarm",         label="Auto Farm",                group="main",   type="toggle", default=false },
    { id="autoFarmLevel",    label="Auto Farm Level",           group="main",   type="toggle", default=false },
    { id="autoQuest",        label="Auto Quest",                group="main",   type="toggle", default=false },
    { id="autoNextQuest",    label="Auto Next Quest",           group="main",   type="toggle", default=false },
    { id="autoNextIsland",   label="Auto Next Island",          group="main",   type="toggle", default=false },
    { id="smartNPCFinder",   label="Smart NPC Finder",          group="main",   type="toggle", default=false },
    { id="autoEquipBest",    label="Auto Equip Best Weapon",    group="main",   type="toggle", default=false },
    { id="autoEquipMelee",   label="Auto Equip Melee",          group="main",   type="toggle", default=false },
    { id="autoEquipSword",   label="Auto Equip Sword",          group="main",   type="toggle", default=false },
    { id="autoEquipFruit",   label="Auto Equip Fruit",          group="main",   type="toggle", default=false },
    { id="autoUseSkills",    label="Auto Use Skills",           group="main",   type="toggle", default=false },
    { id="fastFarm",         label="Fast Farm Mode",            group="main",   type="toggle", default=false },
    { id="farmNearNPC",      label="Farm Near NPC",             group="main",   type="toggle", default=false },
    { id="farmMobCluster",   label="Farm Mob Cluster",          group="main",   type="toggle", default=false },
    { id="farmBossLevel",    label="Farm Boss While Leveling",  group="main",   type="toggle", default=false },
    { id="autoRespawnNPC",   label="Auto Respawn NPC",          group="main",   type="toggle", default=false },
    { id="autoRetarget",     label="Auto Re-target Enemy",      group="main",   type="toggle", default=false },

    -- ── 2. COMBAT SYSTEM ─────────────────────────────────────
    { id="fastAttack",       label="Fast Attack",               group="combat", type="toggle", default=false },
    { id="noDelay",          label="Attack No Delay",           group="combat", type="toggle", default=false },
    { id="autoClick",        label="Auto Click",                group="combat", type="toggle", default=false },
    { id="autoSkillZ",       label="Auto Skill Z",              group="combat", type="toggle", default=false },
    { id="autoSkillX",       label="Auto Skill X",              group="combat", type="toggle", default=false },
    { id="autoSkillC",       label="Auto Skill C",              group="combat", type="toggle", default=false },
    { id="autoSkillV",       label="Auto Skill V",              group="combat", type="toggle", default=false },
    { id="autoSkillF",       label="Auto Skill F",              group="combat", type="toggle", default=false },
    { id="autoHaki",         label="Auto Haki",                 group="combat", type="toggle", default=false },
    { id="autoObsHaki",      label="Auto Observation Haki",     group="combat", type="toggle", default=false },
    { id="aimAssist",        label="Aim Assist",                group="combat", type="toggle", default=false },
    { id="expandHitbox",     label="Expand Hitbox",             group="combat", type="slider", default=1, min=1, max=20 },
    { id="enemyLock",        label="Enemy Lock Target",         group="combat", type="toggle", default=false },
    { id="distanceAttack",   label="Distance Attack Mode",      group="combat", type="toggle", default=false },

    -- ── 3. BOSS SYSTEM ───────────────────────────────────────
    { id="autoBoss",         label="Auto Boss",                 group="boss",   type="toggle", default=false },
    { id="autoEliteBoss",    label="Auto Elite Boss",           group="boss",   type="toggle", default=false },
    { id="autoRaidBoss",     label="Auto Raid Boss",            group="boss",   type="toggle", default=false },
    { id="autoDarkbeard",    label="Auto Darkbeard",            group="boss",   type="toggle", default=false },
    { id="autoRipIndra",     label="Auto Rip Indra",            group="boss",   type="toggle", default=false },
    { id="autoDoughKing",    label="Auto Dough King",           group="boss",   type="toggle", default=false },
    { id="autoSoulReaper",   label="Auto Soul Reaper",          group="boss",   type="toggle", default=false },
    { id="bossNotifier",     label="Boss Spawn Notifier",       group="boss",   type="toggle", default=false },
    { id="bossFinder",       label="Boss Finder",               group="boss",   type="toggle", default=false },
    { id="bossServerHop",    label="Auto Boss Server Hop",      group="boss",   type="toggle", default=false },

    -- ── 4. SEA EVENT SYSTEM ──────────────────────────────────
    { id="autoSeaBeast",     label="Auto Sea Beast",            group="sea",    type="toggle", default=false },
    { id="autoShipRaid",     label="Auto Ship Raid",            group="sea",    type="toggle", default=false },
    { id="autoPirateRaid",   label="Auto Pirate Raid",          group="sea",    type="toggle", default=false },
    { id="autoGhostShip",    label="Auto Ghost Ship",           group="sea",    type="toggle", default=false },
    { id="autoSeaChest",     label="Auto Sea Chest",            group="sea",    type="toggle", default=false },
    { id="seaEventFinder",   label="Sea Event Finder",          group="sea",    type="toggle", default=false },
    { id="seaEventCombat",   label="Sea Event Combat",          group="sea",    type="toggle", default=false },
    { id="seaEventRewards",  label="Sea Event Rewards",         group="sea",    type="toggle", default=false },

    -- ── 5. FRUIT SYSTEM ──────────────────────────────────────
    { id="fruitESP",         label="Fruit ESP",                 group="fruit",  type="toggle", default=false },
    { id="fruitNotifier",    label="Fruit Spawn Notifier",      group="fruit",  type="toggle", default=false },
    { id="autoCollectFruit", label="Auto Collect Fruit",        group="fruit",  type="toggle", default=false },
    { id="fruitSniper",      label="Fruit Sniper",              group="fruit",  type="toggle", default=false },
    { id="autoEatFruit",     label="Auto Eat Fruit",            group="fruit",  type="toggle", default=false },
    { id="fruitStorage",     label="Fruit Storage Manager",     group="fruit",  type="toggle", default=false },
    { id="fruitValue",       label="Fruit Value Checker",       group="fruit",  type="toggle", default=false },

    -- ── 6. RAID SYSTEM ───────────────────────────────────────
    { id="autoBuyChip",      label="Auto Buy Raid Chip",        group="raid",   type="toggle", default=false },
    { id="autoStartRaid",    label="Auto Start Raid",           group="raid",   type="toggle", default=false },
    { id="autoCompleteRaid", label="Auto Complete Raid",        group="raid",   type="toggle", default=false },
    { id="autoRaidFarm",     label="Auto Raid Farm",            group="raid",   type="toggle", default=false },
    { id="autoAwakening",    label="Auto Awakening",            group="raid",   type="toggle", default=false },
    { id="raidBossFinder",   label="Raid Boss Finder",          group="raid",   type="toggle", default=false },

    -- ── 7. TELEPORT SYSTEM ───────────────────────────────────
    { id="tpFirstSea",       label="Teleport First Sea",        group="tp",     type="button" },
    { id="tpSecondSea",      label="Teleport Second Sea",       group="tp",     type="button" },
    { id="tpThirdSea",       label="Teleport Third Sea",        group="tp",     type="button" },
    { id="tpQuestNPC",       label="Teleport Quest NPC",        group="tp",     type="button" },
    { id="tpFruitDealer",    label="Teleport Fruit Dealer",     group="tp",     type="button" },
    { id="tpSwordDealer",    label="Teleport Sword Dealer",     group="tp",     type="button" },
    { id="tpRaidNPC",        label="Teleport Raid NPC",         group="tp",     type="button" },
    { id="tpBoss",           label="Teleport Boss",             group="tp",     type="button" },

    -- ── 8. ESP / VISUAL ──────────────────────────────────────
    { id="playerESP",        label="Player ESP",                group="esp",    type="toggle", default=false },
    { id="npcESP",           label="NPC ESP",                   group="esp",    type="toggle", default=false },
    { id="bossESP",          label="Boss ESP",                  group="esp",    type="toggle", default=false },
    { id="fruitESPVis",      label="Fruit ESP Visual",          group="esp",    type="toggle", default=false },
    { id="chestESP",         label="Chest ESP",                 group="esp",    type="toggle", default=false },
    { id="islandESP",        label="Island ESP",                group="esp",    type="toggle", default=false },
    { id="itemESP",          label="Item ESP",                  group="esp",    type="toggle", default=false },
    { id="distanceDisplay",  label="Distance Display",          group="esp",    type="toggle", default=false },
    { id="healthDisplay",    label="Health Display",            group="esp",    type="toggle", default=false },

    -- ── 9. PLAYER UTILITY ────────────────────────────────────
    { id="flyMode",          label="Fly Mode",                  group="player", type="toggle", default=false },
    { id="noClip",           label="No Clip",                   group="player", type="toggle", default=false },
    { id="walkSpeed",        label="Walk Speed",                group="player", type="slider", default=16,  min=16,  max=500 },
    { id="jumpPower",        label="Jump Power",                group="player", type="slider", default=50,  min=50,  max=500 },
    { id="infiniteEnergy",   label="Infinite Energy",           group="player", type="toggle", default=false },
    { id="infiniteDash",     label="Infinite Dash",             group="player", type="toggle", default=false },
    { id="infiniteGeppo",    label="Infinite Geppo",            group="player", type="toggle", default=false },
    { id="autoDodge",        label="Auto Dodge",                group="player", type="toggle", default=false },

    -- ── 10. STATS SYSTEM ─────────────────────────────────────
    { id="statsMelee",       label="Auto Stats Melee",          group="stats",  type="toggle", default=false },
    { id="statsDefense",     label="Auto Stats Defense",        group="stats",  type="toggle", default=false },
    { id="statsSword",       label="Auto Stats Sword",          group="stats",  type="toggle", default=false },
    { id="statsGun",         label="Auto Stats Gun",            group="stats",  type="toggle", default=false },
    { id="statsFruit",       label="Auto Stats Fruit",          group="stats",  type="toggle", default=false },
    { id="smartStats",       label="Smart Stat Allocation",     group="stats",  type="toggle", default=false },

    -- ── 11. SERVER SYSTEM ────────────────────────────────────
    { id="serverHop",        label="Server Hop",                group="server", type="toggle", default=false },
    { id="autoRejoin",       label="Auto Rejoin",               group="server", type="toggle", default=false },
    { id="findLowServer",    label="Find Low Player Server",    group="server", type="button" },
    { id="findBossServer",   label="Find Boss Server",          group="server", type="button" },
    { id="findEventServer",  label="Find Event Server",         group="server", type="button" },

    -- ── 12. MISC UTILITIES ───────────────────────────────────
    { id="autoChest",        label="Auto Chest",                group="misc",   type="toggle", default=false },
    { id="saberQuest",       label="Auto Saber Quest",          group="misc",   type="toggle", default=false },
    { id="tushitaQuest",     label="Auto Tushita Quest",        group="misc",   type="toggle", default=false },
    { id="yamaQuest",        label="Auto Yama Quest",           group="misc",   type="toggle", default=false },
    { id="cdkQuest",         label="Auto CDK Quest",            group="misc",   type="toggle", default=false },
    { id="mirrorFractal",    label="Auto Mirror Fractal",       group="misc",   type="toggle", default=false },
    { id="antiAFK",          label="Anti AFK",                  group="misc",   type="toggle", default=true  },
    { id="antiKick",         label="Anti Kick",                 group="misc",   type="toggle", default=false },
    { id="fpsBoost",         label="FPS Boost",                 group="misc",   type="toggle", default=false },
    { id="lagReducer",       label="Lag Reducer",               group="misc",   type="toggle", default=false },

    -- ── 13. SETTINGS ─────────────────────────────────────────
    { id="saveConfig",       label="Save Config",               group="cfg",    type="button" },
    { id="loadConfig",       label="Load Config",               group="cfg",    type="button" },
    { id="resetConfig",      label="Reset Config",              group="cfg",    type="button" },
    { id="uiTheme",          label="UI Theme Switch",           group="cfg",    type="button" },
    { id="keybindManager",   label="Keybind Manager",           group="cfg",    type="toggle", default=false },
}

-- ── Index nhanh theo id ──────────────────────────────────────
Core._ById = {}
for _, feat in ipairs(Core.Registry) do
    Core._ById[feat.id] = feat
end

-- ============================================================
--  KHỞI TẠO
-- ============================================================
function Core.Init()
    for _, feat in ipairs(Core.Registry) do
        if feat.type == "toggle" then
            Core.State.ActiveToggles[feat.id] = feat.default or false
        elseif feat.type == "slider" then
            Core.State.SliderValues[feat.id] = feat.default or 0
        end
    end
    Core.Log("Core khởi tạo xong.", "info")
end

-- ============================================================
--  GETTER / SETTER
-- ============================================================
function Core.IsOn(id: string): boolean
    return Core.State.ActiveToggles[id] == true
end

function Core.Toggle(id: string)
    local feat = Core._ById[id]
    if not feat or feat.type ~= "toggle" then return end
    local newVal = not Core.State.ActiveToggles[id]
    Core.State.ActiveToggles[id] = newVal
    Core.Log(feat.label .. (newVal and " BẬT" or " TẮT"),
             newVal and "success" or "info")
    if Core._Callbacks[id] then
        Core._Callbacks[id](newVal)
    end
end

function Core.GetSlider(id: string): number
    return Core.State.SliderValues[id] or 0
end

function Core.SetSlider(id: string, value: number)
    local feat = Core._ById[id]
    if not feat or feat.type ~= "slider" then return end
    value = math.clamp(value, feat.min, feat.max)
    Core.State.SliderValues[id] = value
end

function Core.GetActiveCount(): number
    local n = 0
    for _, v in pairs(Core.State.ActiveToggles) do
        if v then n += 1 end
    end
    return n
end

-- ============================================================
--  CALLBACK SYSTEM
-- ============================================================
Core._Callbacks = {}

function Core.OnToggle(id: string, fn: (bool) -> ())
    Core._Callbacks[id] = fn
end

-- ============================================================
--  ACTIVITY LOG
-- ============================================================
function Core.Log(msg: string, level: string?)
    level = level or "info"
    local entry = {
        time  = os.date("%H:%M:%S"),
        msg   = msg,
        level = level,
    }
    table.insert(Core.State.Log, 1, entry)
    if #Core.State.Log > 200 then
        table.remove(Core.State.Log, #Core.State.Log)
    end
    local prefix = level == "success" and "[✓]"
                or level == "warn"    and "[!]"
                or "[i]"
    print(string.format("[PhantomHub %s] %s %s", entry.time, prefix, msg))
end

-- ============================================================
--  CONFIG I/O
-- ============================================================
function Core.SaveConfig()
    local data = {
        toggles = Core.State.ActiveToggles,
        sliders = Core.State.SliderValues,
    }
    local ok, encoded = pcall(HttpService.JSONEncode, HttpService, data)
    if ok then
        writefile(CONFIG_FILE, encoded)
        Core.Log("Config đã lưu → " .. CONFIG_FILE, "success")
    else
        Core.Log("Lỗi khi lưu config: " .. tostring(encoded), "warn")
    end
end

function Core.LoadConfig()
    local ok, raw = pcall(readfile, CONFIG_FILE)
    if not ok or not raw or raw == "" then
        Core.Log("Không tìm thấy config, dùng mặc định.", "info")
        return
    end
    local parsed = HttpService:JSONDecode(raw)
    if parsed.toggles then
        for k, v in pairs(parsed.toggles) do
            Core.State.ActiveToggles[k] = v
        end
    end
    if parsed.sliders then
        for k, v in pairs(parsed.sliders) do
            Core.State.SliderValues[k] = v
        end
    end
    Core.Log("Config đã tải từ " .. CONFIG_FILE, "success")
end

function Core.ResetConfig()
    Core.Init()
    pcall(delfile, CONFIG_FILE)
    Core.Log("Config đã reset về mặc định.", "warn")
end

-- ============================================================
--  LẤY DANH SÁCH FEATURE THEO GROUP
-- ============================================================
function Core.GetGroup(group: string): { any }
    local result = {}
    for _, feat in ipairs(Core.Registry) do
        if feat.group == group then
            table.insert(result, feat)
        end
    end
    return result
end

return Core
