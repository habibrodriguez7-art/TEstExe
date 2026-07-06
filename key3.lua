local _name    = "Habibcrash247s Application"
local _ownerid = "ItRAf4NWgY"
local _version = "1.0"

local _key = getgenv()._key
if not _key then
    error("[LynX] Key tidak ditemukan. Hubungi seller.")
end

local http = game:GetService("HttpService")
local hwid = tostring(game:GetService("RbxAnalyticsService"):GetClientId())

local url = "https://keyauth.win/api/1.2/?type=license&key=" .. _key .. "&ownerid=" .. _ownerid .. "&app=" .. _name .. "&version=" .. _version .. "&hwid=" .. hwid

local ok, res = pcall(game.HttpGet, game, url, true)

if not ok then
    error("[LynX] Gagal koneksi ke server.")
end

local ok2, data = pcall(function()
    return http:JSONDecode(res)
end)

if not ok2 or not data.success then
    error("[LynX] Key tidak valid atau HWID tidak cocok!")
end

loadstring(game:HttpGet(
    "https://raw.githubusercontent.com/habibrodriguez7-art/TEstExe/refs/heads/main/lapet.lua",
    true
))()
