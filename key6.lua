local _name    = "Lynx"
local _ownerid = "ItRAf4NWgY"
local _version = "1.0"

local _key = getgenv()._key
if not _key then
    error("[LynX] Key tidak ditemukan.")
end

local http = game:GetService("HttpService")
local hwid = tostring(game:GetService("RbxAnalyticsService"):GetClientId())

-- Step 1: Init dulu untuk dapat sessionid
local initUrl = "https://keyauth.win/api/1.3/?type=init&ver=" .. _version .. "&name=" .. _name .. "&ownerid=" .. _ownerid .. "&hash=undefined&token=undefined&thash=undefined"

local initRes = game:HttpGet(initUrl, true)
local initData = http:JSONDecode(initRes)

if not initData.success then
    error("[LynX] Init gagal: " .. tostring(initData.message))
end

local sessionid = initData.sessionid

-- Step 2: License check pakai sessionid
local licUrl = "https://keyauth.win/api/1.3/?type=license&key=" .. _key .. "&sessionid=" .. sessionid .. "&name=" .. _name .. "&ownerid=" .. _ownerid .. "&hwid=" .. hwid .. "&code=undefined"

local licRes = game:HttpGet(licUrl, true)
local licData = http:JSONDecode(licRes)

if not licData.success then
    error("[LynX] " .. tostring(licData.message))
end

-- Key valid, load script utama
loadstring(game:HttpGet(
    "https://raw.githubusercontent.com/habibrodriguez7-art/TEstExe/refs/heads/main/lapet.lua",
    true
))()
