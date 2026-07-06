local _name    = "Lynx"
local _ownerid = "ItRAf4NWgY"
local _version = "1.0"

local _key = getgenv()._key
if not _key then
    error("[LynX] Key tidak ditemukan.")
end

local http = game:GetService("HttpService")

-- Step 1: Init
local initRes = game:HttpGet(
    "https://keyauth.win/api/1.1/?name=" .. _name .. "&ownerid=" .. _ownerid .. "&type=init&ver=" .. _version,
    true
)

if initRes == "KeyAuth_Invalid" then
    error("[LynX] Aplikasi tidak ditemukan.")
end

local initData = http:JSONDecode(initRes)

if not initData.success then
    error("[LynX] Init gagal: " .. tostring(initData.message))
end

local sessionid = initData.sessionid

-- Step 2: License check
local licRes = game:HttpGet(
    "https://keyauth.win/api/1.1/?name=" .. _name .. "&ownerid=" .. _ownerid .. "&type=license&key=" .. _key .. "&ver=" .. _version .. "&sessionid=" .. sessionid,
    true
)

local licData = http:JSONDecode(licRes)

if not licData.success then
    error("[LynX] " .. tostring(licData.message))
end

-- Key valid, load script utama
loadstring(game:HttpGet(
    "https://raw.githubusercontent.com/habibrodriguez7-art/TEstExe/refs/heads/main/lapet.lua",
    true
))()
