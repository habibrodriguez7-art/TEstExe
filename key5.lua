local _name    = "Lynx"
local _ownerid = "ItRAf4NWgY"
local _version = "1.0"

local _key = getgenv()._key
if not _key then
    error("[LynX] Key tidak ditemukan.")
end

local hwid = tostring(game:GetService("RbxAnalyticsService"):GetClientId())
local url = "https://keyauth.win/api/1.2/?type=license&key=" .. _key .. "&ownerid=" .. _ownerid .. "&app=" .. _name .. "&version=" .. _version .. "&hwid=" .. hwid

local res = game:HttpGet(url, true)
local data = game:GetService("HttpService"):JSONDecode(res)

if not data.success then
    error("[LynX] " .. tostring(data.message))
end

loadstring(game:HttpGet(
    "https://raw.githubusercontent.com/habibrodriguez7-art/TEstExe/refs/heads/main/lapet.lua",
    true
))()
