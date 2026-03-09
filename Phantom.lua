-- ============================================================
--  PHANTOM HUB  |  main.lua  (Loader)
--  Paste file này vào executor — các module tự load từ GitHub
--  Repo : https://github.com/Genesis-scripter-osp/DuyThichMod
-- ============================================================

-- ── Thông tin hub ────────────────────────────────────────────
local HUB = {
    Name    = "PHANTOM HUB",
    Version = "3.0.0",
    Author  = "Genesis",
    Repo    = "https://raw.githubusercontent.com/Genesis-scripter-osp/DuyThichMod/main/",
}

-- ── Base URL — đổi ở đây nếu chuyển repo ────────────────────
local BASE = HUB.Repo

-- ── Danh sách module theo thứ tự load ───────────────────────
local MODULES_LIST = {
    { key = "Core",    file = "core.lua"    },
    { key = "UI",      file = "ui.lua"      },
    { key = "Systems", file = "systems.lua" },
    { key = "Network", file = "network.lua" },
    { key = "Visual",  file = "visual.lua"  },
    { key = "Phantom", file = "Phantom.lua" },
}

-- ── Logger ───────────────────────────────────────────────────
local function Log(msg: string, level: string?)
    local icon = level == "ok" and "✓" or level == "warn" and "!" or "i"
    print(string.format("[%s v%s] [%s] %s", HUB.Name, HUB.Version, icon, msg))
end

-- ── Load an toàn 1 module từ GitHub raw URL ─────────────────
local function SafeLoad(url: string, name: string): any?
    -- Bước 1: tải source code
    local httpOk, src = pcall(game.HttpGet, game, url, true)
    if not httpOk or not src or src == "" then
        Log("HttpGet thất bại: " .. name .. "\n  URL: " .. url, "warn")
        return nil
    end

    -- Bước 2: biên dịch Luau
    local fn, compileErr = loadstring(src)
    if not fn then
        Log("Lỗi biên dịch " .. name .. ": " .. tostring(compileErr), "warn")
        return nil
    end

    -- Bước 3: thực thi & lấy kết quả return
    local runOk, result = pcall(fn)
    if not runOk then
        Log("Lỗi runtime " .. name .. ": " .. tostring(result), "warn")
        return nil
    end

    Log(name .. " OK", "ok")
    return result
end

-- ── Tải tất cả module ────────────────────────────────────────
Log("Đang tải module từ GitHub...", "i")

local Loaded = {}

for _, mod in ipairs(MODULES_LIST) do
    local url = BASE .. mod.file
    Loaded[mod.key] = SafeLoad(url, mod.key)

    -- Core và UI là bắt buộc — dừng nếu lỗi
    if not Loaded[mod.key] and (mod.key == "Core" or mod.key == "UI") then
        Log("Module " .. mod.key .. " bắt buộc — huỷ khởi động.", "warn")
        return
    end
end

local Core    = Loaded.Core
local UI      = Loaded.UI
local Systems = Loaded.Systems
local Network = Loaded.Network
local Visual  = Loaded.Visual
local Phantom = Loaded.Phantom

-- ── Khởi tạo theo thứ tự ────────────────────────────────────
Core.Init()
UI.Build(Core)
if Systems then Systems.Init(Core) end
if Network then Network.Init(Core) end
if Visual  then Visual.Init(Core)  end
if Phantom then
    if type(Phantom) == "table" and Phantom.Init then
        Phantom.Init(Core)
    end
end
Core.LoadConfig()

Log(string.format(
    "Sẵn sàng! %d module · %d feature · RightCtrl = ẩn/hiện",
    #MODULES_LIST, #Core.Registry
), "ok")

-- ── Vòng lặp chính ───────────────────────────────────────────
local RunService  = game:GetService("RunService")
local LocalPlayer = game:GetService("Players").LocalPlayer

RunService.Heartbeat:Connect(function(dt: number)
    if not Core.State.Running then return end
    if Systems then Systems.Tick(dt) end
    if Network then Network.Tick(dt) end
    if Visual  then Visual.Tick(dt)  end
    if Phantom and type(Phantom) == "table" and Phantom.Tick then
        Phantom.Tick(dt)
    end
end)

-- ── Dọn dẹp khi thoát ───────────────────────────────────────
LocalPlayer.AncestryChanged:Connect(function()
    Core.SaveConfig()
    if Visual then Visual.Cleanup() end
    if UI     then UI.Cleanup()     end
    Log("Config đã lưu. Bye!", "ok")
end)

return HUB
