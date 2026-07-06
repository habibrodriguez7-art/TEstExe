local _name    = "Habibcrash247's Application"
local _ownerid = "ItRAf4NWgY"
local _secret  = "4b84464a58e0f331c69d3e64eea0316e7671cd9696f318cde9d0eeee5df82ed7"
local _version = "1.0"

local _key = getgenv()._key
if not _key then
    error("[LynX] Key tidak ditemukan. Hubungi seller.")
end

local http = game:GetService("HttpService")

local function validate()
    local url = "https://keyauth.win/api/1.2/?type=license"
        .. "&key=" .. _key
        .. "&ownerid=" .. _ownerid
        .. "&app=" .. http:UrlEncode(_name)
        .. "&version=" .. _version
        .. "&hwid=" .. tostring(game:GetService("RbxAnalyticsService"):GetClientId())

    local ok, res = pcall(function()
        return game:HttpGet(url, true)
    end)

    if not ok then
        error("[LynX] Gagal koneksi ke server.")
    end

    local data = http:JSONDecode(res)

    if data.success then
        return true
    else
        error("[LynX] " .. (data.message or "Key tidak valid atau HWID tidak cocok!"))
    end
end

validate()

loadstring(game:HttpGet(
    "https://raw.githubusercontent.com/habibrodriguez7-art/TEstExe/refs/heads/main/lapet.lua",
    true
))()
