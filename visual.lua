-- ============================================================
--  PHANTOM HUB  |  visual.lua
--  Cập nhật: Blox Fruits Update 29 (Control Update - 23/12/2025)
--  Thêm: Trinket ESP · Dungeon Floor Display
-- ============================================================

local Players   = game:GetService("Players")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")

local LocalPlayer = Players.LocalPlayer
local Camera      = Workspace.CurrentCamera

local Visual = {}
local Core

-- ============================================================
--  TIỆN ÍCH
-- ============================================================
local function GetChar(): BasePart?
    local c = LocalPlayer.Character
    return c and c:FindFirstChild("HumanoidRootPart") or nil
end

local function Distance(pos: Vector3): number
    local hrp = GetChar()
    if not hrp then return 0 end
    return math.round((hrp.Position - pos).Magnitude)
end

-- ============================================================
--  LABEL & HIGHLIGHT FACTORY
-- ============================================================
local function NewLabel(text: string, color: Color3, size: number?): BillboardGui
    local bg = Instance.new("BillboardGui")
    bg.Name = "ESP_Label"; bg.Size = UDim2.new(0,140,0,30)
    bg.StudsOffset = Vector3.new(0,3,0); bg.AlwaysOnTop = true; bg.LightInfluence = 0
    local lbl = Instance.new("TextLabel", bg)
    lbl.Size = UDim2.new(1,0,1,0); lbl.BackgroundTransparency = 1
    lbl.Text = text; lbl.TextColor3 = color; lbl.TextSize = size or 12
    lbl.Font = Enum.Font.GothamBold
    lbl.TextStrokeColor3 = Color3.fromRGB(0,0,0); lbl.TextStrokeTransparency = 0.4
    return bg
end

local function AttachHighlight(model: Model, color: Color3): SelectionBox
    local box = Instance.new("SelectionBox")
    box.Adornee = model; box.Color3 = color; box.SurfaceColor3 = color
    box.SurfaceTransparency = 0.85; box.LineThickness = 0.06; box.Parent = Workspace
    return box
end

-- ============================================================
--  ESP REGISTRY
-- ============================================================
local ESPObjects = {}

local function ClearESP(cat: string)
    if not ESPObjects[cat] then return end
    for _, obj in pairs(ESPObjects[cat]) do
        if obj.gui and obj.gui.Parent then obj.gui:Destroy() end
        if obj.box and obj.box.Parent then obj.box:Destroy() end
    end
    ESPObjects[cat] = {}
end

-- ============================================================
--  Player ESP
-- ============================================================
local PLAYER_COLOR = Color3.fromRGB(255, 255, 100)

local function UpdatePlayerESP()
    if not Core.IsOn("playerESP") then ClearESP("players"); return end
    ESPObjects["players"] = ESPObjects["players"] or {}

    for _, plr in ipairs(Players:GetPlayers()) do
        if plr == LocalPlayer then continue end
        local char = plr.Character
        if not char then continue end
        local hrp = char:FindFirstChild("HumanoidRootPart")
        if not hrp then continue end

        local key   = tostring(plr.UserId)
        local entry = ESPObjects["players"][key]
        local hum   = char:FindFirstChildOfClass("Humanoid")
        local hp    = hum and math.round(hum.Health) or 0
        local dist  = Distance(hrp.Position)
        local text  = string.format("[%s]\n❤ %d  |  📏 %dm", plr.Name, hp, dist)

        if not entry or not entry.gui or not entry.gui.Parent then
            local gui = NewLabel(text, PLAYER_COLOR, 11)
            gui.Parent = hrp
            local box = AttachHighlight(char, PLAYER_COLOR)
            ESPObjects["players"][key] = { gui=gui, box=box }
        else
            local lbl = entry.gui:FindFirstChildOfClass("TextLabel")
            if lbl then lbl.Text = text end
        end
    end

    -- Dọn player đã rời
    for key, entry in pairs(ESPObjects["players"] or {}) do
        local found = false
        for _, p in ipairs(Players:GetPlayers()) do
            if tostring(p.UserId) == key then found = true; break end
        end
        if not found then
            if entry.gui and entry.gui.Parent then entry.gui:Destroy() end
            if entry.box and entry.box.Parent then entry.box:Destroy() end
            ESPObjects["players"][key] = nil
        end
    end
end

-- ============================================================
--  NPC / Boss ESP
-- ============================================================
local NPC_COLOR  = Color3.fromRGB(150, 220, 255)
local BOSS_COLOR = Color3.fromRGB(255, 80,  80)

local BOSS_SET = {
    Darkbeard=true, Rip_Indra=true, ["Dough King"]=true,
    ["Soul Reaper"]=true, Greybeard=true, Dragon=true,
    Stone=true, ["Gorilla King"]=true,
}

local function UpdateNpcESP()
    local wantNpc  = Core.IsOn("npcESP")
    local wantBoss = Core.IsOn("bossESP")
    local wantDist = Core.IsOn("distanceDisplay")
    local wantHp   = Core.IsOn("healthDisplay")
    if not wantNpc and not wantBoss then ClearESP("npcs"); return end
    ESPObjects["npcs"] = ESPObjects["npcs"] or {}

    for _, obj in ipairs(Workspace:GetDescendants()) do
        if not obj:IsA("Model") then continue end
        local hum = obj:FindFirstChildOfClass("Humanoid")
        if not hum or hum.Health <= 0 then continue end
        local root = obj:FindFirstChild("HumanoidRootPart")
        if not root then continue end

        local isBoss = BOSS_SET[obj.Name] == true
        if isBoss and not wantBoss then continue end
        if not isBoss and not wantNpc then continue end

        local key   = obj:GetFullName()
        local color = isBoss and BOSS_COLOR or NPC_COLOR
        local parts = {}
        table.insert(parts, (isBoss and "⚠ " or "") .. obj.Name)
        if wantDist then table.insert(parts, "📏 " .. Distance(root.Position) .. "m") end
        if wantHp   then table.insert(parts, string.format("❤ %d/%d",
            math.round(hum.Health), math.round(hum.MaxHealth))) end
        local text = table.concat(parts, "  ")

        local entry = ESPObjects["npcs"][key]
        if not entry or not entry.gui or not entry.gui.Parent then
            local gui = NewLabel(text, color, 10)
            gui.Parent = root
            local box = isBoss and AttachHighlight(obj, color) or nil
            ESPObjects["npcs"][key] = { gui=gui, box=box }
        else
            local lbl = entry.gui:FindFirstChildOfClass("TextLabel")
            if lbl then lbl.Text = text end
        end
    end
end

-- ============================================================
--  Fruit ESP
-- ============================================================
local FRUIT_COLOR = Color3.fromRGB(204, 68, 255)

local function UpdateFruitESP()
    if not Core.IsOn("fruitESPVis") then ClearESP("fruits"); return end
    ESPObjects["fruits"] = ESPObjects["fruits"] or {}
    local folder = Workspace:FindFirstChild("Fruits")
    if not folder then return end

    local seen = {}
    for _, fruit in ipairs(folder:GetChildren()) do
        local root = fruit:IsA("BasePart") and fruit or fruit:FindFirstChildOfClass("BasePart")
        if not root then continue end
        local key = fruit:GetFullName(); seen[key] = true
        local text = "🍎 " .. fruit.Name .. "\n📏 " .. Distance(root.Position) .. "m"
        local entry = ESPObjects["fruits"][key]
        if not entry or not entry.gui or not entry.gui.Parent then
            local gui = NewLabel(text, FRUIT_COLOR, 11)
            gui.StudsOffset = Vector3.new(0,5,0); gui.Parent = root
            local box = fruit:IsA("Model") and AttachHighlight(fruit, FRUIT_COLOR) or nil
            ESPObjects["fruits"][key] = { gui=gui, box=box }
        else
            local lbl = entry.gui:FindFirstChildOfClass("TextLabel")
            if lbl then lbl.Text = text end
        end
    end
    for key, entry in pairs(ESPObjects["fruits"]) do
        if not seen[key] then
            if entry.gui and entry.gui.Parent then entry.gui:Destroy() end
            if entry.box and entry.box.Parent then entry.box:Destroy() end
            ESPObjects["fruits"][key] = nil
        end
    end
end

-- ============================================================
--  Chest ESP
-- ============================================================
local CHEST_COLOR = Color3.fromRGB(255, 200, 0)

local function UpdateChestESP()
    if not Core.IsOn("chestESP") then ClearESP("chests"); return end
    ESPObjects["chests"] = ESPObjects["chests"] or {}
    local seen = {}
    for _, obj in ipairs(Workspace:GetDescendants()) do
        if not (obj:IsA("Model") or obj:IsA("BasePart")) then continue end
        if not (obj.Name:find("Chest") or obj.Name == "Box") then continue end
        local root = obj:IsA("BasePart") and obj or obj:FindFirstChildOfClass("BasePart")
        if not root then continue end
        local key = obj:GetFullName(); seen[key] = true
        local text = "📦 " .. obj.Name .. "\n📏 " .. Distance(root.Position) .. "m"
        local entry = ESPObjects["chests"][key]
        if not entry or not entry.gui or not entry.gui.Parent then
            local gui = NewLabel(text, CHEST_COLOR, 10)
            gui.Parent = root
            ESPObjects["chests"][key] = { gui=gui, box=nil }
        else
            local lbl = entry.gui:FindFirstChildOfClass("TextLabel")
            if lbl then lbl.Text = text end
        end
    end
    for key, entry in pairs(ESPObjects["chests"]) do
        if not seen[key] then
            if entry.gui and entry.gui.Parent then entry.gui:Destroy() end
            ESPObjects["chests"][key] = nil
        end
    end
end

-- ============================================================
--  Trinket ESP (MỚI - Update 29)
-- ============================================================
local TRINKET_COLOR = Color3.fromRGB(255, 140, 0)
local RARITY_COLORS = {
    Common    = Color3.fromRGB(180, 180, 180),
    Rare      = Color3.fromRGB(0,   120, 255),
    Epic      = Color3.fromRGB(160, 0,   255),
    Legendary = Color3.fromRGB(255, 165, 0),
    Mythical  = Color3.fromRGB(255, 50,  50),
}

local function UpdateTrinketESP()
    if not Core.IsOn("trinketESPVis") and not Core.IsOn("trinketESP") then
        ClearESP("trinkets"); return
    end
    ESPObjects["trinkets"] = ESPObjects["trinkets"] or {}

    -- Tìm trinket drops trong Workspace (rơi ra sau khi hoàn thành dungeon)
    local seen = {}
    for _, obj in ipairs(Workspace:GetDescendants()) do
        if not (obj:IsA("Model") or obj:IsA("BasePart")) then continue end
        if not obj.Name:find("Trinket") then continue end

        local root = obj:IsA("BasePart") and obj or obj:FindFirstChildOfClass("BasePart")
        if not root then continue end

        local key = obj:GetFullName(); seen[key] = true
        local rarityObj = obj:FindFirstChild("Rarity")
        local rarity    = rarityObj and rarityObj.Value or "Common"
        local color     = RARITY_COLORS[rarity] or TRINKET_COLOR
        local dist      = Distance(root.Position)

        local text = string.format("💎 %s\n[%s]  📏 %dm", obj.Name, rarity, dist)

        local entry = ESPObjects["trinkets"][key]
        if not entry or not entry.gui or not entry.gui.Parent then
            local gui = NewLabel(text, color, 11)
            gui.StudsOffset = Vector3.new(0, 5, 0); gui.Parent = root
            local box = obj:IsA("Model") and AttachHighlight(obj, color) or nil
            ESPObjects["trinkets"][key] = { gui=gui, box=box }

            -- Notifier
            if Core.IsOn("trinketNotifier") then
                Core.Log(string.format("Trinket drop: %s [%s] 📏%dm",
                    obj.Name, rarity, dist), "warn")
            end
        else
            local lbl = entry.gui:FindFirstChildOfClass("TextLabel")
            if lbl then lbl.Text = text end
        end
    end

    for key, entry in pairs(ESPObjects["trinkets"]) do
        if not seen[key] then
            if entry.gui and entry.gui.Parent then entry.gui:Destroy() end
            if entry.box and entry.box.Parent then entry.box:Destroy() end
            ESPObjects["trinkets"][key] = nil
        end
    end
end

-- ============================================================
--  Island ESP
-- ============================================================
local ISLAND_COLOR    = Color3.fromRGB(68, 255, 221)
local ISLAND_KEYWORDS = {
    "Island","Village","Town","Fortress","Castle","Mountain",
    "Forest","Prison","Marine","Skylands","Colosseum","City","Arena"
}

local function UpdateIslandESP()
    if not Core.IsOn("islandESP") then ClearESP("islands"); return end
    ESPObjects["islands"] = ESPObjects["islands"] or {}

    for _, obj in ipairs(Workspace:GetChildren()) do
        if not obj:IsA("Model") then continue end
        local isIsland = false
        for _, kw in ipairs(ISLAND_KEYWORDS) do
            if obj.Name:find(kw) then isIsland = true; break end
        end
        if not isIsland then continue end

        local key  = obj.Name
        local root = obj:FindFirstChildOfClass("BasePart")
        if not root or ESPObjects["islands"][key] then continue end

        local gui = NewLabel("🏝 " .. obj.Name, ISLAND_COLOR, 14)
        gui.Size = UDim2.new(0,200,0,40); gui.StudsOffset = Vector3.new(0,20,0)
        gui.Parent = root
        ESPObjects["islands"][key] = { gui=gui }
    end
end

-- ============================================================
--  TICK TỔNG HỢP (~10fps)
-- ============================================================
local _tick = 0

function Visual.Tick(_dt: number)
    _tick += 1
    if _tick % 6 ~= 0 then return end

    UpdatePlayerESP()
    UpdateNpcESP()
    UpdateFruitESP()
    UpdateChestESP()
    UpdateTrinketESP()   -- MỚI U29
    UpdateIslandESP()
end

-- ============================================================
--  INIT & CLEANUP
-- ============================================================
function Visual.Init(coreRef)
    Core = coreRef
    for _, cat in ipairs({ "players","npcs","fruits","chests","trinkets","islands" }) do
        ESPObjects[cat] = {}
    end
    Core.Log("Visual (ESP + Trinket ESP) sẵn sàng.", "info")
end

function Visual.Cleanup()
    for cat in pairs(ESPObjects) do ClearESP(cat) end
    Core.Log("ESP đã xoá sạch.", "info")
end

return Visual


