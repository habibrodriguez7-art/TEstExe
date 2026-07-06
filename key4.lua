local _name    = "Lynx"
local _ownerid = "ItRAf4NWgY"
local _secret  = "4b84464a58e0f331c69d3e64eea0316e7671cd9696f318cde9d0eeee5df82ed7"
local _version = "1.0"

local _key = getgenv()._key
if not _key then
    error("[LynX] Key tidak ditemukan.")
end

local http = game:GetService("HttpService")
local hwid = tostring(game:GetService("RbxAnalyticsService"):GetClientId())

local url = "https://keyauth.win/api/1.2/?type=license&key=" .. _key .. "&ownerid=" .. _ownerid .. "&app=" .. _name .. "&version=" .. _version .. "&hwid=" .. hwid

local res = http:GetAsync(url)

local data = http:JSONDecode(res)

if not data.success then
    error("[LynX] " .. tostring(data.message))
end

loadstring(game:HttpGet(
    "https://raw.githubusercontent.com/habibrodriguez7-art/TEstExe/refs/heads/main/lapet.lua",
    true
))()
