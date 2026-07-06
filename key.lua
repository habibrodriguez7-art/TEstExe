local _name    = "Habibcrash247's Application"
local _ownerid = "ItRAf4NWgY"
local _secret  = "4b84464a58e0f331c69d3e64eea0316e7671cd9696f318cde9d0eeee5df82ed7"
local _version = "1.0"

local KeyAuth = loadstring(game:HttpGet(
    "https://raw.githubusercontent.com/KeyAuth/KeyAuth-Roblox-Example/main/source.lua",
    true
))()

KeyAuth.init({
    name    = _name,
    ownerid = _ownerid,
    secret  = _secret,
    version = _version
})

local _key = getgenv()._key
if not _key then
    error("[LynX] Key tidak ditemukan. Hubungi seller.")
end

local ok, err = pcall(function()
    KeyAuth.license(_key)
end)

if not ok then
    error("[LynX] Key tidak valid atau HWID tidak cocok!")
end

-- Key valid, load script utama
loadstring(game:HttpGet(
    "https://raw.githubusercontent.com/habibrodriguez7-art/TEstExe/refs/heads/main/lapet.lua",
    true
))()
