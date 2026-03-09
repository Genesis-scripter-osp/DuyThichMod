repeat task.wait() until game:IsLoaded()

if _G.PhantomHub_Loader then
    warn("PhantomHub loader đã chạy.")
    return
end
_G.PhantomHub_Loader = true

local URL = "https://raw.githubusercontent.com/Genesis-scripter-osp/DuyThichMod/main/main.lua"

local success,err = pcall(function()
    loadstring(game:HttpGet(URL))()
end)

if not success then
    warn("Loader lỗi:",err)
end
