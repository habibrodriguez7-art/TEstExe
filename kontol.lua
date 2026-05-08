--[[
 ███████╗ █████╗ ██████╗ ██╗   ██╗██████╗
 ╚════██║██╔══██╗██╔══██╗██║   ██║██╔══██╗
     ██╔╝███████║██████╔╝██║   ██║██║  ██║
    ██╔╝ ██╔══██║██╔══██╗╚██╗ ██╔╝██║  ██║
    ██║  ██║  ██║██║  ██║ ╚████╔╝ ██████╔╝
    ╚═╝  ╚═╝  ╚═╝╚═╝  ╚═╝  ╚═══╝  ╚═════╝
    ZarVD • Violence District Script
    UI  : WindUI  |  Dev: ZarOfficial
]]

-- ════════════════════════════════════════════════
--  [1] SERVICES — harus paling atas
-- ════════════════════════════════════════════════
local Players             = game:GetService("Players")
local RunService          = game:GetService("RunService")
local ReplicatedStorage   = game:GetService("ReplicatedStorage")
local VirtualInputManager = game:GetService("VirtualInputManager")
local GuiService          = game:GetService("GuiService")
local Lighting            = game:GetService("Lighting")
local UserInputService    = game:GetService("UserInputService")

local LocalPlayer = Players.LocalPlayer
local PlayerGui   = LocalPlayer:WaitForChild("PlayerGui")

-- ════════════════════════════════════════════════
--  [2] WINDUI LOADER
-- ════════════════════════════════════════════════
local WindUI
local ok = pcall(function()
    WindUI = loadstring(game:HttpGet(
        "https://github.com/Footagesus/WindUI/releases/latest/download/main.lua"
    ))()
end)
if not ok or not WindUI then
    warn("[ZarVD] Gagal load WindUI!")
end

local function Notify(title, content, icon, dur)
    if not WindUI then return end
    pcall(function()
        WindUI:Notify({ Title=title, Content=content, Icon=icon or "zap", Duration=dur or 3 })
    end)
end

-- ════════════════════════════════════════════════
--  [3] SETTINGS
-- ════════════════════════════════════════════════
local Settings = {
    PlayerESP=true, KillerTracker=true, KillerWarning=true,
    GeneratorESP=true, HookESP=true, PalletESP=true, GateESP=true, WindowESP=true,
    NextKiller=true, AutoSkillCheck=true, Fullbright=true,
    NoClip=false, PlayerSpeed=16,
    AutoAttack=false, AttackRange=10,
    SafeTeleport=true, TeleportOffset=3, TeleportDelay=0.5,
    TPTargetName="", BringTarget="", KeepBringing=false,
    FPSCounter=false,
    Aimbot=false, AimbotSmoothing=0.15, AimbotFOV=350, AimbotTargetHead=true,
    Crosshair=false, CrosshairStyle="cross", CrosshairSize=12, CrosshairGap=4,
    CrosshairColor=Color3.fromRGB(255,60,60),
    Invisible=false,
}

-- ════════════════════════════════════════════════
--  [4] BASE HELPERS (semua fungsi harus di atas pemanggilnya)
-- ════════════════════════════════════════════════

local function GetRoot()
    local c = LocalPlayer.Character
    return c and c:FindFirstChild("HumanoidRootPart")
end

local function GetMap()
    return workspace:FindFirstChild("Map")
end

local function IsKiller()
    return LocalPlayer.Team and LocalPlayer.Team.Name == "Killer"
end

local function IsSurvivor()
    return LocalPlayer.Team and LocalPlayer.Team.Name == "Survivors"
end

local function RemoveHighlight(obj)
    if not obj then return end
    local h = obj:FindFirstChild("H")
    if h then h:Destroy() end
end

local function ClearObjectHighlights(name)
    for _, o in ipairs(workspace:GetDescendants()) do
        if o.Name == name then RemoveHighlight(o) end
    end
end

local function ClearGeneratorESP()
    for _, o in ipairs(workspace:GetDescendants()) do
        if o.Name == "Generator" then
            RemoveHighlight(o)
            local bb = o:FindFirstChild("GenBitchHook")
            if bb then bb:Destroy() end
        end
    end
end

local function ClearHookESP()
    local Map = GetMap() if not Map then return end
    for _, o in ipairs(Map:GetDescendants()) do
        if o.Name == "Hook" then
            local m = o:FindFirstChild("Model")
            if m then for _, p in ipairs(m:GetDescendants()) do
                if p:IsA("MeshPart") then RemoveHighlight(p) end
            end end
        end
    end
end

local function ClearPlayerESP()
    for _, p in ipairs(Players:GetPlayers()) do
        if p ~= LocalPlayer and p.Character then
            local root = p.Character:FindFirstChild("HumanoidRootPart")
            if root then
                local bb = root:FindFirstChild("BitchHook") if bb then bb:Destroy() end
                local mb = root:FindFirstChild("MaskHook")  if mb then mb:Destroy() end
            end
            RemoveHighlight(p.Character)
        end
    end
end

-- ════════════════════════════════════════════════
--  [5] SPEED & NOCLIP
-- ════════════════════════════════════════════════
local function ApplySpeed(speed)
    Settings.PlayerSpeed = speed
    local c = LocalPlayer.Character
    if c then local h = c:FindFirstChildOfClass("Humanoid") if h then h.WalkSpeed = speed end end
end

local NoClipConn = nil
local function EnableNoClip()
    if NoClipConn then NoClipConn:Disconnect() end
    NoClipConn = RunService.Stepped:Connect(function()
        if not Settings.NoClip then return end
        local c = LocalPlayer.Character if not c then return end
        for _, p in ipairs(c:GetDescendants()) do
            if p:IsA("BasePart") then p.CanCollide = false end
        end
    end)
end
local function DisableNoClip()
    if NoClipConn then NoClipConn:Disconnect() NoClipConn = nil end
    local c = LocalPlayer.Character if not c then return end
    for _, p in ipairs(c:GetDescendants()) do
        if p:IsA("BasePart") then p.CanCollide = true end
    end
end
EnableNoClip()

-- ════════════════════════════════════════════════
--  [6] INVISIBLE MODE
-- ════════════════════════════════════════════════
local InvisConn  = nil
local OrigTransp = {}

local function ApplyInvis(char)
    if not char then return end
    for _, v in ipairs(char:GetDescendants()) do
        pcall(function()
            if v:IsA("BasePart") then
                if not OrigTransp[v] then OrigTransp[v] = v.Transparency end
                v.Transparency = 1
                v.LocalTransparencyModifier = 1
            elseif v:IsA("Decal") or v:IsA("Texture") then
                if not OrigTransp[v] then OrigTransp[v] = v.Transparency end
                v.Transparency = 1
            end
        end)
    end
end

local function EnableInvisible()
    if InvisConn then InvisConn:Disconnect() end
    OrigTransp = {}
    ApplyInvis(LocalPlayer.Character)
    InvisConn = RunService.RenderStepped:Connect(function()
        if not Settings.Invisible then return end
        local c = LocalPlayer.Character if not c then return end
        for _, v in ipairs(c:GetDescendants()) do
            pcall(function()
                if v:IsA("BasePart") then
                    v.LocalTransparencyModifier = 1
                    v.Transparency = 1
                elseif (v:IsA("Decal") or v:IsA("Texture")) then
                    v.Transparency = 1
                end
            end)
        end
    end)
end

local function DisableInvisible()
    if InvisConn then InvisConn:Disconnect() InvisConn = nil end
    local c = LocalPlayer.Character
    if c then
        for _, v in ipairs(c:GetDescendants()) do
            pcall(function()
                if v:IsA("BasePart") then
                    v.LocalTransparencyModifier = 0
                    v.Transparency = OrigTransp[v] or 0
                elseif v:IsA("Decal") or v:IsA("Texture") then
                    v.Transparency = OrigTransp[v] or 0
                end
            end)
        end
    end
    OrigTransp = {}
end

-- ════════════════════════════════════════════════
--  [7] BRING PLAYER
-- ════════════════════════════════════════════════
local BringConn    = nil
local BringAllConn = nil

local function ForceBring(tRoot, hrp)
    if not tRoot or not hrp then return end
    pcall(function() tRoot.CFrame = hrp.CFrame * CFrame.new(2, 0, -1) end)
    pcall(function()
        local dir  = hrp.Position - tRoot.Position
        local dist = dir.Magnitude
        if dist > 1 then
            tRoot.AssemblyLinearVelocity = dir.Unit * math.min(dist * 15, 350)
        else
            tRoot.AssemblyLinearVelocity = Vector3.zero
        end
    end)
end

local function BringPlayer(name)
    if not name or name == "" or name == "(belum ada player)" then
        Notify("ZarVD","Pilih player dulu!","alert-circle",2) return false
    end
    local hrp = GetRoot() if not hrp then return false end
    local tgt = Players:FindFirstChild(name)
    if not tgt or not tgt.Character then
        Notify("ZarVD ✗", name.." tidak ada/belum spawn","x-circle",2) return false
    end
    local tRoot = tgt.Character:FindFirstChild("HumanoidRootPart")
    if not tRoot then return false end
    ForceBring(tRoot, hrp)
    return true
end

local function BringAllPlayers()
    local hrp = GetRoot() if not hrp then return end
    local list, count = {}, 0
    for _, p in ipairs(Players:GetPlayers()) do
        if p ~= LocalPlayer and p.Character then
            local tRoot = p.Character:FindFirstChild("HumanoidRootPart")
            if tRoot then list[#list+1] = tRoot end
        end
    end
    local n = #list
    for i, tRoot in ipairs(list) do
        local angle = n > 1 and ((i-1)/(n-1))*math.pi*2 or 0
        local dest  = hrp.CFrame * CFrame.new(math.cos(angle)*3, 0, math.sin(angle)*3)
        pcall(function() tRoot.CFrame = dest end)
        pcall(function()
            local dir = dest.Position - tRoot.Position
            if dir.Magnitude > 0.5 then
                tRoot.AssemblyLinearVelocity = dir.Unit * math.min(dir.Magnitude*15, 350)
            end
        end)
        count = count + 1
    end
    if count > 0 then Notify("Bring All ✓", count.." player ditarik!","users",3)
    else Notify("ZarVD","Tidak ada player lain!","alert-circle",2) end
end

local function StartKeepBringing()
    if BringConn then BringConn:Disconnect() end
    BringConn = RunService.RenderStepped:Connect(function()
        if not Settings.KeepBringing then return end
        local name = Settings.BringTarget
        if not name or name == "" then return end
        local hrp = GetRoot() if not hrp then return end
        local tgt = Players:FindFirstChild(name)
        if not tgt or not tgt.Character then return end
        local tRoot = tgt.Character:FindFirstChild("HumanoidRootPart")
        if tRoot then ForceBring(tRoot, hrp) end
    end)
end

local function StopKeepBringing()
    if BringConn then BringConn:Disconnect() BringConn = nil end
end

local function StartKeepBringAll()
    if BringAllConn then BringAllConn:Disconnect() end
    BringAllConn = RunService.RenderStepped:Connect(function()
        local hrp = GetRoot() if not hrp then return end
        local list = {}
        for _, p in ipairs(Players:GetPlayers()) do
            if p ~= LocalPlayer and p.Character then
                local tRoot = p.Character:FindFirstChild("HumanoidRootPart")
                if tRoot then list[#list+1] = tRoot end
            end
        end
        local n = #list
        for i, tRoot in ipairs(list) do
            local angle = n > 1 and ((i-1)/(n-1))*math.pi*2 or 0
            local dest  = hrp.CFrame * CFrame.new(math.cos(angle)*3, 0, math.sin(angle)*3)
            pcall(function() tRoot.CFrame = dest end)
            pcall(function()
                local dir = dest.Position - tRoot.Position
                if dir.Magnitude > 0.5 then
                    tRoot.AssemblyLinearVelocity = dir.Unit * math.min(dir.Magnitude*15, 350)
                end
            end)
        end
    end)
end

local function StopKeepBringAll()
    if BringAllConn then BringAllConn:Disconnect() BringAllConn = nil end
end

-- ════════════════════════════════════════════════
--  [8] TELEPORT
-- ════════════════════════════════════════════════
local TeleportDebounce = false

local function SafeTeleport(targetCF, offsetVec)
    if TeleportDebounce then return false end
    local hrp = GetRoot() if not hrp then return false end
    TeleportDebounce = true
    local offset = offsetVec or Vector3.new(0, Settings.TeleportOffset, 0)
    if Settings.SafeTeleport then
        pcall(function()
            for _, p in ipairs(LocalPlayer.Character:GetDescendants()) do
                if p:IsA("BasePart") then p.CanCollide = false end
            end
        end)
    end
    hrp.CFrame = targetCF + offset
    if Settings.SafeTeleport then
        task.delay(0.5, function()
            pcall(function()
                if not LocalPlayer.Character then return end
                for _, p in ipairs(LocalPlayer.Character:GetDescendants()) do
                    if p:IsA("BasePart") and p.Name ~= "HumanoidRootPart" then
                        p.CanCollide = true
                    end
                end
            end)
        end)
    end
    task.delay(0.3, function() TeleportDebounce = false end)
    return true
end

local function GetGeneratorsByDist()
    local hrp = GetRoot()
    local map = GetMap()
    if not hrp or not map then return {} end
    local list = {}
    for _, o in ipairs(map:GetDescendants()) do
        if o:IsA("Model") and o.Name == "Generator" then
            local part = o:FindFirstChildWhichIsA("BasePart")
            if part then
                list[#list+1] = {model=o, part=part, pos=part.Position,
                    dist=(part.Position - hrp.Position).Magnitude}
            end
        end
    end
    table.sort(list, function(a,b) return a.dist < b.dist end)
    return list
end

local function LeaveGenerator()
    local hrp = GetRoot() if not hrp then return end
    local map = GetMap() if not map then return end
    local near, nearDist = nil, math.huge
    for _, o in ipairs(map:GetDescendants()) do
        if o:IsA("Model") and o.Name == "Generator" then
            local p = o:FindFirstChildWhichIsA("BasePart")
            if p then
                local d = (p.Position - hrp.Position).Magnitude
                if d < nearDist then nearDist = d near = o end
            end
        end
    end
    if not near or nearDist > 20 then
        Notify("ZarVD","Tidak dekat generator!","alert-circle",2) return
    end
    local part = near:FindFirstChildWhichIsA("BasePart")
    if part then
        local dir = (hrp.Position - part.Position).Unit
        if SafeTeleport(CFrame.new(hrp.Position + dir*25), Vector3.new(0,2,0)) then
            Notify("Kabur!","Teleport menjauh dari generator","wind",2)
        end
    end
end

local function TPToPlayer(name)
    if not name or name == "" or name == "(belum ada player)" then
        Notify("ZarVD","Pilih player dulu!","alert-circle",2) return
    end
    local tgt = Players:FindFirstChild(name)
    if not tgt or tgt == LocalPlayer then
        Notify("ZarVD ✗","Player tidak valid!","x-circle",2) return
    end
    local root = tgt.Character and tgt.Character:FindFirstChild("HumanoidRootPart")
    if not root then
        Notify("ZarVD ✗", name.." tidak punya character","x-circle",2) return
    end
    if SafeTeleport(root.CFrame, Vector3.new(2,2,0)) then
        Notify("TP ✓","Teleport ke "..name,"map-pin",3)
    end
end

-- ════════════════════════════════════════════════
--  [9] AUTO ATTACK
-- ════════════════════════════════════════════════
local AutoAttackConn = nil
local LastAttackTick = 0
local ATTACK_CD      = 0.35

local function StartAutoAttack()
    if AutoAttackConn then return end
    if not IsKiller() then
        Notify("ZarVD ✗","Harus jadi Killer!","shield-off",3) return
    end
    AutoAttackConn = RunService.Heartbeat:Connect(function()
        if not Settings.AutoAttack then return end
        local now = tick()
        if now - LastAttackTick < ATTACK_CD then return end
        LastAttackTick = now
        if not IsKiller() then return end
        local hrp = GetRoot() if not hrp then return end
        local closest, closeDist = nil, math.huge
        for _, p in ipairs(Players:GetPlayers()) do
            if p ~= LocalPlayer and p.Team and p.Team.Name == "Survivors" and p.Character then
                local r = p.Character:FindFirstChild("HumanoidRootPart")
                if r then
                    local d = (r.Position - hrp.Position).Magnitude
                    if d < closeDist and d <= Settings.AttackRange then
                        closeDist = d closest = p
                    end
                end
            end
        end
        if not closest then return end
        pcall(function()
            local rem = ReplicatedStorage:FindFirstChild("Remotes") if not rem then return end
            local atk = rem:FindFirstChild("Attacks") if not atk then return end
            local ba  = atk:FindFirstChild("BasicAttack") if ba then ba:FireServer(false) end
        end)
    end)
    Notify("Auto Attack ON","Range: "..Settings.AttackRange.." studs","crosshair",3)
end

local function StopAutoAttack()
    if AutoAttackConn then AutoAttackConn:Disconnect() AutoAttackConn = nil end
end

-- ════════════════════════════════════════════════
--  [10] AIMBOT
-- ════════════════════════════════════════════════
local AimbotConn = nil

local function StartAimbot()
    if AimbotConn then return end
    AimbotConn = RunService.RenderStepped:Connect(function()
        if not Settings.Aimbot then return end
        local hrp = GetRoot() if not hrp then return end
        local cam = workspace.CurrentCamera
        local vc  = cam.ViewportSize / 2
        local best, bestDist = nil, Settings.AimbotFOV
        for _, p in ipairs(Players:GetPlayers()) do
            if p ~= LocalPlayer and p.Character then
                local root = p.Character:FindFirstChild("HumanoidRootPart")
                local hum  = p.Character:FindFirstChildOfClass("Humanoid")
                if root and hum and hum.Health > 0 then
                    local valid = (IsKiller() and p.Team and p.Team.Name=="Survivors")
                               or (IsSurvivor() and p.Team and p.Team.Name=="Killer")
                    if valid then
                        local aimPos = Settings.AimbotTargetHead
                            and root.Position+Vector3.new(0,2,0)
                            or  root.Position+Vector3.new(0,0.5,0)
                        local sp, onScreen = cam:WorldToScreenPoint(aimPos)
                        if onScreen then
                            local sd = (Vector2.new(sp.X,sp.Y)-vc).Magnitude
                            if sd < bestDist then bestDist=sd best={pos=aimPos} end
                        end
                    end
                end
            end
        end
        if best then
            cam.CFrame = cam.CFrame:Lerp(
                CFrame.lookAt(cam.CFrame.Position, best.pos),
                math.clamp(Settings.AimbotSmoothing, 0.01, 1)
            )
        end
    end)
end

local function StopAimbot()
    if AimbotConn then AimbotConn:Disconnect() AimbotConn = nil end
    pcall(function() workspace.CurrentCamera.CameraType = Enum.CameraType.Custom end)
end

-- ════════════════════════════════════════════════
--  [11] FPS COUNTER HUD
-- ════════════════════════════════════════════════
local FPSGui, FPSHb = nil, nil
local FPSDrag, FPSDragInput, FPSMPos, FPSFPos = false, nil, nil, nil

local function CreateFPSCounter()
    if FPSGui then return end
    local sg = Instance.new("ScreenGui")
    sg.Name,sg.ResetOnSpawn,sg.DisplayOrder,sg.IgnoreGuiInset = "ZarVD_FPS",false,9999,true
    sg.Parent = PlayerGui
    local frame = Instance.new("Frame")
    frame.Size,frame.Position = UDim2.new(0,130,0,72),UDim2.new(0,12,0,12)
    frame.BackgroundColor3,frame.BackgroundTransparency,frame.BorderSizePixel = Color3.fromRGB(10,10,14),0.08,0
    frame.Parent = sg
    Instance.new("UICorner",frame).CornerRadius = UDim.new(0,10)
    local stroke = Instance.new("UIStroke",frame)
    stroke.Color,stroke.Thickness,stroke.Transparency = Color3.fromRGB(80,80,110),1.2,0.3
    local accent = Instance.new("Frame",frame)
    accent.Name,accent.Size,accent.BackgroundColor3,accent.BorderSizePixel = "Accent",UDim2.new(1,0,0,3),Color3.fromRGB(0,255,128),0
    Instance.new("UICorner",accent).CornerRadius = UDim.new(0,10)
    local brand = Instance.new("TextLabel",frame)
    brand.Size,brand.Position,brand.BackgroundTransparency = UDim2.new(1,-8,0,14),UDim2.new(0,8,0,5),1
    brand.Text,brand.TextColor3,brand.Font,brand.TextSize = "ZarVD • HUD",Color3.fromRGB(130,130,160),Enum.Font.GothamBold,9
    brand.TextXAlignment = Enum.TextXAlignment.Left
    local fpsLbl = Instance.new("TextLabel",frame)
    fpsLbl.Name,fpsLbl.Size,fpsLbl.Position,fpsLbl.BackgroundTransparency = "FPS",UDim2.new(0.6,0,0,36),UDim2.new(0,8,0,18),1
    fpsLbl.Text,fpsLbl.TextColor3,fpsLbl.Font,fpsLbl.TextSize = "--",Color3.fromRGB(0,255,128),Enum.Font.GothamBold,30
    fpsLbl.TextXAlignment = Enum.TextXAlignment.Left
    local fpsTag = Instance.new("TextLabel",frame)
    fpsTag.Size,fpsTag.Position,fpsTag.BackgroundTransparency = UDim2.new(0.4,-8,0,18),UDim2.new(0.6,0,0,18),1
    fpsTag.Text,fpsTag.TextColor3,fpsTag.Font,fpsTag.TextSize = "FPS",Color3.fromRGB(90,90,120),Enum.Font.GothamBold,11
    fpsTag.TextXAlignment,fpsTag.TextYAlignment = Enum.TextXAlignment.Left,Enum.TextYAlignment.Bottom
    local pingLbl = Instance.new("TextLabel",frame)
    pingLbl.Name,pingLbl.Size,pingLbl.Position,pingLbl.BackgroundTransparency = "Ping",UDim2.new(1,-8,0,16),UDim2.new(0,8,0,52),1
    pingLbl.Text,pingLbl.TextColor3,pingLbl.Font,pingLbl.TextSize = "PING  -- ms",Color3.fromRGB(100,100,130),Enum.Font.Gotham,9
    pingLbl.TextXAlignment = Enum.TextXAlignment.Left
    frame.InputBegan:Connect(function(i)
        if i.UserInputType==Enum.UserInputType.MouseButton1 or i.UserInputType==Enum.UserInputType.Touch then
            FPSDrag,FPSMPos,FPSFPos = true,i.Position,frame.Position
            i.Changed:Connect(function() if i.UserInputState==Enum.UserInputState.End then FPSDrag=false end end)
        end
    end)
    frame.InputChanged:Connect(function(i)
        if i.UserInputType==Enum.UserInputType.MouseMovement or i.UserInputType==Enum.UserInputType.Touch then FPSDragInput=i end
    end)
    UserInputService.InputChanged:Connect(function(i)
        if i==FPSDragInput and FPSDrag then
            local d = i.Position-FPSMPos
            frame.Position = UDim2.new(FPSFPos.X.Scale,FPSFPos.X.Offset+d.X,FPSFPos.Y.Scale,FPSFPos.Y.Offset+d.Y)
        end
    end)
    local fc, lt = 0, tick()
    FPSHb = RunService.Heartbeat:Connect(function()
        if not Settings.FPSCounter then return end
        fc = fc + 1
        local now = tick()
        if now - lt >= 1.0 then
            local fps = math.floor(fc/(now-lt))
            fc,lt = 0,now
            local col = fps>=55 and Color3.fromRGB(0,255,128) or fps>=30 and Color3.fromRGB(255,200,0) or Color3.fromRGB(255,60,60)
            fpsLbl.Text,fpsLbl.TextColor3,accent.BackgroundColor3,stroke.Color = tostring(fps),col,col,col
            local ping = math.floor(game:GetService("Stats").Network.ServerStatsItem["Data Ping"]:GetValue())
            local pc = ping<80 and Color3.fromRGB(0,200,100) or ping<150 and Color3.fromRGB(255,180,0) or Color3.fromRGB(255,60,60)
            pingLbl.Text,pingLbl.TextColor3 = "PING  "..ping.." ms",pc
        end
    end)
    FPSGui = sg
end

local function DestroyFPSCounter()
    if FPSHb then FPSHb:Disconnect() FPSHb=nil end
    if FPSGui then FPSGui:Destroy() FPSGui=nil end
end

-- ════════════════════════════════════════════════
--  [12] CROSSHAIR
-- ════════════════════════════════════════════════
local CrosshairGui, CrosshairConn = nil, nil

local function DestroyCrosshair()
    if CrosshairConn then CrosshairConn:Disconnect() CrosshairConn=nil end
    if CrosshairGui then CrosshairGui:Destroy() CrosshairGui=nil end
end

local function CreateCrosshair()
    DestroyCrosshair()
    local sg = Instance.new("ScreenGui")
    sg.Name,sg.ResetOnSpawn,sg.DisplayOrder,sg.IgnoreGuiInset = "ZarVD_CH",false,10000,true
    sg.Parent = PlayerGui
    local cx  = UDim2.new(0.5,0,0.5,0)
    local col = Settings.CrosshairColor
    local sz  = Settings.CrosshairSize
    local gap = Settings.CrosshairGap
    local function mkF(ap,pos,size)
        local f = Instance.new("Frame",sg)
        f.AnchorPoint,f.Position,f.Size = ap,pos,size
        f.BackgroundColor3,f.BorderSizePixel = col,0
        local sh = Instance.new("UIStroke",f)
        sh.Color,sh.Thickness,sh.Transparency = Color3.new(0,0,0),0.8,0.5
        return f
    end
    if Settings.CrosshairStyle == "dot" then
        local dot = mkF(Vector2.new(0.5,0.5),cx,UDim2.new(0,6,0,6))
        Instance.new("UICorner",dot).CornerRadius = UDim.new(1,0)
        local ring = Instance.new("Frame",sg)
        ring.AnchorPoint,ring.Position,ring.Size,ring.BackgroundTransparency,ring.BorderSizePixel = Vector2.new(0.5,0.5),cx,UDim2.new(0,12,0,12),1,0
        local rs = Instance.new("UIStroke",ring) rs.Color,rs.Thickness = col,1.5
        Instance.new("UICorner",ring).CornerRadius = UDim.new(1,0)
    elseif Settings.CrosshairStyle == "circle" then
        local ring = Instance.new("Frame",sg)
        ring.AnchorPoint,ring.Position,ring.Size,ring.BackgroundTransparency,ring.BorderSizePixel = Vector2.new(0.5,0.5),cx,UDim2.new(0,sz*2,0,sz*2),1,0
        local rs = Instance.new("UIStroke",ring) rs.Color,rs.Thickness = col,1.5
        Instance.new("UICorner",ring).CornerRadius = UDim.new(1,0)
        local dot = mkF(Vector2.new(0.5,0.5),cx,UDim2.new(0,3,0,3))
        Instance.new("UICorner",dot).CornerRadius = UDim.new(1,0)
    elseif Settings.CrosshairStyle == "dynamic" then
        local dirs = {
            {ap=Vector2.new(0.5,1),ox=0,oy=-(gap+sz),v=true,n="T"},
            {ap=Vector2.new(0.5,0),ox=0,oy=gap,v=true,n="B"},
            {ap=Vector2.new(1,0.5),ox=-(gap+sz),oy=0,v=false,n="L"},
            {ap=Vector2.new(0,0.5),ox=gap,oy=0,v=false,n="R"},
        }
        local lines = {}
        for _, d in ipairs(dirs) do
            local f = mkF(d.ap,UDim2.new(0.5,d.ox,0.5,d.oy),d.v and UDim2.new(0,2,0,sz) or UDim2.new(0,sz,0,2))
            lines[#lines+1] = {f=f,d=d}
        end
        local dot = mkF(Vector2.new(0.5,0.5),cx,UDim2.new(0,3,0,3))
        Instance.new("UICorner",dot).CornerRadius = UDim.new(1,0)
        CrosshairConn = RunService.RenderStepped:Connect(function()
            if not Settings.Crosshair then return end
            local c   = LocalPlayer.Character
            local hum = c and c:FindFirstChildOfClass("Humanoid")
            if not hum then return end
            local moving = hum.MoveDirection.Magnitude > 0.1
            local tgap   = moving and gap+8 or gap
            for _, l in ipairs(lines) do
                local d,cp = l.d,l.f.Position
                local tx = d.n=="L" and -(tgap+sz) or d.n=="R" and tgap or d.ox
                local ty = d.n=="T" and -(tgap+sz) or d.n=="B" and tgap or d.oy
                local nx = cp.X.Offset+(tx-cp.X.Offset)*0.2
                local ny = cp.Y.Offset+(ty-cp.Y.Offset)*0.2
                l.f.Position = UDim2.new(0.5,nx,0.5,ny)
            end
        end)
    else -- cross
        mkF(Vector2.new(0.5,1),UDim2.new(0.5,0,0.5,-gap),UDim2.new(0,2,0,sz))
        mkF(Vector2.new(0.5,0),UDim2.new(0.5,0,0.5,gap),UDim2.new(0,2,0,sz))
        mkF(Vector2.new(1,0.5),UDim2.new(0.5,-gap,0.5,0),UDim2.new(0,sz,0,2))
        mkF(Vector2.new(0,0.5),UDim2.new(0.5,gap,0.5,0),UDim2.new(0,sz,0,2))
        local dot = mkF(Vector2.new(0.5,0.5),cx,UDim2.new(0,3,0,3))
        Instance.new("UICorner",dot).CornerRadius = UDim.new(1,0)
    end
    CrosshairGui = sg
end

-- ════════════════════════════════════════════════
--  [13] ORIGINAL GAME LOGIC
-- ════════════════════════════════════════════════
local Config = {
    Players = {Killer={Color=Color3.fromRGB(255,93,108)},Survivor={Color=Color3.fromRGB(64,224,255)}},
    Objects = {Generator={Color=Color3.fromRGB(150,0,200)},Gate={Color=Color3.fromRGB(255,255,255)},
               Pallet={Color=Color3.fromRGB(74,255,181)},Window={Color=Color3.fromRGB(74,255,181)},
               Hook={Color=Color3.fromRGB(132,255,169)}}
}
local MaskNames  = {["Richard"]="Rooster",["Tony"]="Tiger",["Brandon"]="Panther",["Cobra"]="Cobra",["Richter"]="Rat",["Rabbit"]="Rabbit",["Alex"]="Chainsaw"}
local MaskColors = {["Richard"]=Color3.fromRGB(255,0,0),["Tony"]=Color3.fromRGB(255,255,0),["Brandon"]=Color3.fromRGB(160,32,240),["Cobra"]=Color3.fromRGB(0,255,0),["Richter"]=Color3.fromRGB(0,0,0),["Rabbit"]=Color3.fromRGB(255,105,180),["Alex"]=Color3.fromRGB(255,255,255)}

local ActiveGenerators = {}
local LastUpdateTick, LastFullESPRefresh = 0, 0
local TouchID    = 8822
local ActionPath = "Survivor-mob.Controls.action.check"
local HeartbeatConn, VisibilityConn, IndicatorGui = nil, nil, nil

local function SetupGui()
    if PlayerGui:FindFirstChild("ChasedInds") then PlayerGui:FindFirstChild("ChasedInds"):Destroy() end
    IndicatorGui = Instance.new("ScreenGui")
    IndicatorGui.Name,IndicatorGui.IgnoreGuiInset,IndicatorGui.DisplayOrder,IndicatorGui.Parent = "ChasedInds",true,999,PlayerGui
end

local function GetGameValue(obj, name)
    if not obj then return nil end
    local a = obj:GetAttribute(name) if a ~= nil then return a end
    local c = obj:FindFirstChild(name)
    if c then local ok2,v = pcall(function() return c.Value end) if ok2 then return v end end
    return nil
end

local function ApplyHighlight(obj, color)
    local h = obj:FindFirstChild("H") or Instance.new("Highlight")
    h.Name,h.Adornee,h.FillColor,h.OutlineColor = "H",obj,color,color
    h.FillTransparency,h.OutlineTransparency,h.DepthMode = 0.8,0.3,Enum.HighlightDepthMode.AlwaysOnTop
    h.Parent = obj
end

local function CreateBBTag(text, color, size, ts)
    local bb = Instance.new("BillboardGui")
    bb.Name,bb.AlwaysOnTop,bb.Size = "BitchHook",true,size or UDim2.new(0,120,0,30)
    local lbl = Instance.new("TextLabel")
    lbl.Name,lbl.Size,lbl.BackgroundTransparency = "BitchHook",UDim2.new(1,0,1,0),1
    lbl.Text,lbl.TextColor3,lbl.TextStrokeTransparency,lbl.TextStrokeColor3 = text,color,0,Color3.new(0,0,0)
    lbl.Font,lbl.TextSize,lbl.TextWrapped,lbl.RichText = Enum.Font.GothamBold,ts or 10,true,true
    lbl.Parent = bb
    return bb
end

local function updatePlayerNametag(player)
    if not IndicatorGui or not IndicatorGui.Parent then return end
    if not player.Character then
        for _, n in ipairs({player.Name,player.Name.."_Chased",player.Name.."_Killer"}) do
            local o = IndicatorGui:FindFirstChild(n) if o then o:Destroy() end
        end
        return
    end
    local rootPart = player.Character:FindFirstChild("HumanoidRootPart")
    local humanoid = player.Character:FindFirstChildOfClass("Humanoid")
    if not rootPart then return end
    local teamName  = (player.Team and player.Team.Name:lower()) or ""
    local selKiller = GetGameValue(player,"SelectedKiller")
    local rawMask   = GetGameValue(player,"Mask") or GetGameValue(player.Character,"Mask")
    local isKnocked = GetGameValue(player.Character,"Knocked")
    local isHooked  = GetGameValue(player.Character,"IsHooked")
    local isChased  = GetGameValue(player.Character,"IsChased")
    local isKP      = teamName:find("killer") ~= nil
    local color = isKP and Config.Players.Killer.Color or Config.Players.Survivor.Color
    if isHooked then color = Color3.fromRGB(255,182,193)
    elseif humanoid and humanoid.Health < humanoid.MaxHealth then
        color = isKnocked and Color3.fromRGB(200,100,0) or Color3.fromRGB(200,200,0)
    end
    local dist = 0
    if LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then
        dist = math.floor((rootPart.Position-LocalPlayer.Character.HumanoidRootPart.Position).Magnitude)
    end
    local baseName = (isKP and selKiller and tostring(selKiller) ~= "") and tostring(selKiller) or player.Name
    if not Settings.PlayerESP then
        local bb = rootPart:FindFirstChild("BitchHook") if bb then bb:Destroy() end
        local mb = rootPart:FindFirstChild("MaskHook")  if mb then mb:Destroy() end
        RemoveHighlight(player.Character)
    else
        local bb  = rootPart:FindFirstChild("BitchHook")
        local txt = baseName.."\n["..dist.." studs]"
        if not bb then
            bb = CreateBBTag(txt,color) bb.Adornee,bb.Parent = rootPart,rootPart
        else
            local l = bb:FindFirstChild("BitchHook") or bb:FindFirstChildOfClass("TextLabel")
            if l then l.Text,l.TextColor3 = txt,color end
        end
        ApplyHighlight(player.Character, color)
        local hasMask = false
        if isKP and string.match(tostring(selKiller):lower(),"masked") and rawMask then
            for key,mname in pairs(MaskNames) do
                if key:lower() == tostring(rawMask):lower() then
                    hasMask = true
                    local mb = rootPart:FindFirstChild("MaskHook")
                    if not mb then
                        mb = CreateBBTag(mname,MaskColors[key] or Color3.new(1,1,1),UDim2.new(0,100,0,20),12)
                        mb.Name,mb.StudsOffset,mb.Adornee,mb.Parent = "MaskHook",Vector3.new(0,3,0),rootPart,rootPart
                    else
                        local l = mb:FindFirstChild("BitchHook") or mb:FindFirstChildOfClass("TextLabel")
                        if l then l.Text,l.TextColor3 = mname,MaskColors[key] or Color3.new(1,1,1) end
                    end
                    break
                end
            end
        end
        if not hasMask then local mb = rootPart:FindFirstChild("MaskHook") if mb then mb:Destroy() end end
    end
    local cl2d = IndicatorGui:FindFirstChild(player.Name.."_Chased")
    if isChased then
        local bb = rootPart:FindFirstChild("BitchHook")
        if bb then
            local ct = bb:FindFirstChild("ChasedLabel")
            if not ct then
                ct = Instance.new("TextLabel",bb)
                ct.Name,ct.Size,ct.Position,ct.BackgroundTransparency = "ChasedLabel",UDim2.new(1,0,1,0),UDim2.new(0,0,-1.2,0),1
                ct.Font,ct.TextSize = Enum.Font.GothamBold,24
            end
            ct.Text,ct.TextColor3,ct.TextStrokeTransparency = "!!",color,0
        end
        if not cl2d then
            cl2d = Instance.new("TextLabel",IndicatorGui)
            cl2d.Name,cl2d.BackgroundTransparency = player.Name.."_Chased",1
            cl2d.Font,cl2d.TextSize,cl2d.TextStrokeTransparency = Enum.Font.GothamBold,24,0
            cl2d.AnchorPoint = Vector2.new(0.5,0.5)
        end
        cl2d.Text,cl2d.TextColor3 = "!!",color
        local sp,os = workspace.CurrentCamera:WorldToScreenPoint(rootPart.Position)
        if os then cl2d.Visible = false
        else
            cl2d.Visible = true
            local vc = workspace.CurrentCamera.ViewportSize/2
            local dir = Vector2.new(sp.X,sp.Y)-vc if sp.Z<0 then dir=-dir end
            local ms = math.max(math.abs(dir.X)/(vc.X-30),math.abs(dir.Y)/(vc.Y-30))
            cl2d.Position = UDim2.new(0,vc.X+dir.X/(ms==0 and 1 or ms),0,vc.Y+dir.Y/(ms==0 and 1 or ms))
        end
    else
        if cl2d then cl2d:Destroy() end
        local bb = rootPart:FindFirstChild("BitchHook")
        if bb then local ct=bb:FindFirstChild("ChasedLabel") if ct then ct:Destroy() end end
    end
    local kl2d = IndicatorGui:FindFirstChild(player.Name.."_Killer")
    if isKP and Settings.KillerTracker then
        if not kl2d then
            kl2d = Instance.new("TextLabel",IndicatorGui)
            kl2d.Name,kl2d.BackgroundTransparency = player.Name.."_Killer",1
            kl2d.Font,kl2d.TextSize,kl2d.TextStrokeTransparency = Enum.Font.GothamBold,10,0
            kl2d.Size,kl2d.RichText,kl2d.AnchorPoint = UDim2.new(0,120,0,30),true,Vector2.new(0.5,0.5)
        end
        kl2d.Text,kl2d.TextColor3 = baseName.."\n["..dist.." studs]",color
        local sp,os = workspace.CurrentCamera:WorldToScreenPoint(rootPart.Position)
        if not os then
            kl2d.Visible = true
            local vc = workspace.CurrentCamera.ViewportSize/2
            local dir = Vector2.new(sp.X,sp.Y)-vc if sp.Z<0 then dir=-dir end
            local ms = math.max(math.abs(dir.X)/(vc.X-30),math.abs(dir.Y)/(vc.Y-30))
            kl2d.Position = UDim2.new(0,vc.X+dir.X/(ms==0 and 1 or ms),0,vc.Y+dir.Y/(ms==0 and 1 or ms))
        else kl2d.Visible = false end
    elseif kl2d then kl2d:Destroy() end
end

local function updateGeneratorProgress(gen)
    if not gen or not gen.Parent then return true end
    local pct = GetGameValue(gen,"RepairProgress") or GetGameValue(gen,"Progress") or 0
    local bb  = gen:FindFirstChild("GenBitchHook")
    if pct >= 100 then if bb then bb:Destroy() end local h=gen:FindFirstChild("H") if h then h:Destroy() end return true end
    if not Settings.GeneratorESP then if bb then bb:Destroy() end RemoveHighlight(gen) return false end
    local cp = math.clamp(pct,0,100)
    local fc2 = cp<50 and Config.Objects.Generator.Color:Lerp(Color3.fromRGB(180,180,0),cp/50) or Color3.fromRGB(180,180,0):Lerp(Color3.fromRGB(0,150,0),(cp-50)/50)
    local ps = string.format("[%.2f%%]",pct)
    if not bb then
        bb = CreateBBTag(ps,fc2) bb.Name,bb.StudsOffset = "GenBitchHook",Vector3.new(0,2,0)
        bb.Adornee = gen:FindFirstChild("defaultMaterial",true) or gen bb.Parent = gen
    else local l=bb:FindFirstChild("BitchHook") or bb:FindFirstChildOfClass("TextLabel") if l then l.Text,l.TextColor3=ps,fc2 end end
    return false
end

local function updateNextKillerDisplay()
    if not IndicatorGui or not IndicatorGui.Parent then return end
    local lbl  = IndicatorGui:FindFirstChild("NextKillerDisplay")
    local team = (LocalPlayer.Team and LocalPlayer.Team.Name:lower()) or ""
    if not Settings.NextKiller then if lbl then lbl:Destroy() end return end
    if team:find("spectator") or team:find("lobby") then
        if not lbl then
            lbl = Instance.new("TextLabel",IndicatorGui)
            lbl.Name,lbl.Size,lbl.Position = "NextKillerDisplay",UDim2.new(0,220,0,30),UDim2.new(0.5,0,0,45)
            lbl.AnchorPoint,lbl.BackgroundTransparency,lbl.BackgroundColor3 = Vector2.new(0.5,0),0.5,Color3.new(0,0,0)
            lbl.TextColor3,lbl.Font,lbl.TextSize,lbl.RichText = Color3.new(1,1,1),Enum.Font.GothamBold,14,true
        end
        local ps = Players:GetPlayers()
        table.sort(ps,function(a,b)
            local aA,bA = GetGameValue(a,"AllowKiller") or false,GetGameValue(b,"AllowKiller") or false
            if aA~=bA then return aA==true end
            return (GetGameValue(a,"KillerChance") or 0)>(GetGameValue(b,"KillerChance") or 0)
        end)
        local nk = ps[1]
        if nk then lbl.Text = "Next Killer: <font color=\"rgb(255,0,0)\">"..
            (nk==LocalPlayer and "YOU" or tostring(GetGameValue(nk,"SelectedKiller") or nk.Name)).."</font>" end
    elseif lbl then lbl:Destroy() end
end

local function RefreshESP()
    ActiveGenerators = {}
    for _, o in ipairs(workspace:GetDescendants()) do
        if o.Name=="Window" then
            if Settings.WindowESP then ApplyHighlight(o,Config.Objects.Window.Color) else RemoveHighlight(o) end
        end
    end
    local Map = GetMap() if not Map then return end
    for _, o in ipairs(Map:GetDescendants()) do
        if o.Name=="Generator" then
            if Settings.GeneratorESP then ApplyHighlight(o,Config.Objects.Generator.Color) end
            ActiveGenerators[#ActiveGenerators+1] = o
        elseif o.Name=="Hook" then
            local m = o:FindFirstChild("Model")
            if m then for _, p in ipairs(m:GetDescendants()) do if p:IsA("MeshPart") then
                if Settings.HookESP then ApplyHighlight(p,Config.Objects.Hook.Color) else RemoveHighlight(p) end
            end end end
        elseif o.Name=="Palletwrong" or o.Name=="Pallet" then
            if Settings.PalletESP then ApplyHighlight(o,Config.Objects.Pallet.Color) else RemoveHighlight(o) end
        elseif o.Name=="Gate" then
            if Settings.GateESP then ApplyHighlight(o,Config.Objects.Gate.Color) else RemoveHighlight(o) end
        end
    end
end

local function GetActionTarget()
    local cur = PlayerGui
    for seg in string.gmatch(ActionPath,"[^%.]+") do cur = cur and cur:FindFirstChild(seg) end
    return cur
end

local function TriggerMobileButton()
    local b = GetActionTarget()
    if b and b:IsA("GuiObject") then
        local p2,s2,i2 = b.AbsolutePosition,b.AbsoluteSize,GuiService:GetGuiInset()
        local cx,cy = p2.X+(s2.X/2)+i2.X,p2.Y+(s2.Y/2)+i2.Y
        pcall(function() VirtualInputManager:SendTouchEvent(TouchID,0,cx,cy) task.wait(0.01) VirtualInputManager:SendTouchEvent(TouchID,2,cx,cy) end)
    end
end

local function InitializeAutobuy()
    if not Settings.AutoSkillCheck then return end
    task.spawn(function()
        local prompt = PlayerGui:WaitForChild("SkillCheckPromptGui",10)
        local check  = prompt and prompt:WaitForChild("Check",10)
        if not check then return end
        local line,goal = check:WaitForChild("Line"),check:WaitForChild("Goal")
        if VisibilityConn then VisibilityConn:Disconnect() end
        VisibilityConn = check:GetPropertyChangedSignal("Visible"):Connect(function()
            if not Settings.AutoSkillCheck then return end
            if LocalPlayer.Team and LocalPlayer.Team.Name=="Survivors" and check.Visible then
                if HeartbeatConn then HeartbeatConn:Disconnect() end
                HeartbeatConn = RunService.Heartbeat:Connect(function()
                    local lr,gr = line.Rotation%360,goal.Rotation%360
                    local ss,se = (gr+101)%360,(gr+115)%360
                    if (ss>se and (lr>=ss or lr<=se)) or (lr>=ss and lr<=se) then
                        TriggerMobileButton()
                        if HeartbeatConn then HeartbeatConn:Disconnect() HeartbeatConn=nil end
                    end
                end)
            elseif HeartbeatConn then HeartbeatConn:Disconnect() HeartbeatConn=nil end
        end)
    end)
end

-- Event connections (SATU per jenis, tidak duplikat)
workspace.ChildAdded:Connect(function(c)
    if c.Name=="Map" then task.wait(1) RefreshESP() end
end)

LocalPlayer.CharacterAdded:Connect(function(char)
    if HeartbeatConn then HeartbeatConn:Disconnect() end
    if VisibilityConn then VisibilityConn:Disconnect() end
    SetupGui()
    task.wait(1) InitializeAutobuy()
    task.wait(0.5) ApplySpeed(Settings.PlayerSpeed)
    if Settings.NoClip then EnableNoClip() end
    if Settings.AutoAttack and IsKiller() then StartAutoAttack() end
    -- Re-apply invisible kalau aktif
    if Settings.Invisible then
        task.wait(0.5)
        ApplyInvis(char)
    end
end)

RunService.Heartbeat:Connect(function()
    local now = tick()
    if now - LastUpdateTick < 0.05 then return end
    LastUpdateTick = now
    if Settings.Fullbright then
        Lighting.Ambient,Lighting.OutdoorAmbient = Color3.fromRGB(255,255,255),Color3.fromRGB(255,255,255)
        Lighting.Brightness,Lighting.ClockTime,Lighting.GlobalShadows,Lighting.FogEnd = 2,14,false,9e9
    end
    if now - LastFullESPRefresh > 5 then LastFullESPRefresh=now RefreshESP() end
    updateNextKillerDisplay()
    local myChar = LocalPlayer.Character
    local myRoot = myChar and myChar:FindFirstChild("HumanoidRootPart")
    local killerNear = false
    for _, p in ipairs(Players:GetPlayers()) do
        if p ~= LocalPlayer then
            updatePlayerNametag(p)
            local pt = p.Team and p.Team.Name:lower() or ""
            if pt:find("killer") and myRoot and p.Character and p.Character:FindFirstChild("HumanoidRootPart") then
                if (p.Character.HumanoidRootPart.Position-myRoot.Position).Magnitude < 99 then killerNear=true end
            end
        end
    end
    if myRoot then
        local w = myRoot:FindFirstChild("KillerWarn")
        if killerNear and Settings.KillerWarning then
            if not w then
                w = CreateBBTag("!",Color3.fromRGB(255,0,0),UDim2.new(0,50,0,50),40)
                w.Name,w.StudsOffset,w.Adornee,w.Parent = "KillerWarn",Vector3.new(0,4,0),myRoot,myRoot
            end
        elseif w then w:Destroy() end
    end
    for i=#ActiveGenerators,1,-1 do
        local g=ActiveGenerators[i]
        if g and g.Parent then if updateGeneratorProgress(g) then table.remove(ActiveGenerators,i) end
        else table.remove(ActiveGenerators,i) end
    end
end)

Players.PlayerRemoving:Connect(function(p)
    if not IndicatorGui then return end
    for _, n in ipairs({p.Name.."_Chased",p.Name.."_Killer",p.Name}) do
        local o=IndicatorGui:FindFirstChild(n) if o then o:Destroy() end
    end
    -- Stop keep bring kalau target leave
    if Settings.BringTarget == p.Name then
        Settings.BringTarget = ""
        StopKeepBringing()
    end
end)

SetupGui() RefreshESP() InitializeAutobuy()

-- ════════════════════════════════════════════════
--  [14] WINDUI — BUILD WINDOW
-- ════════════════════════════════════════════════
if not WindUI then
    warn("[ZarVD] WindUI tidak tersedia.")
    return
end

local function Safe(fn)
    local ok2,err = pcall(fn)
    if not ok2 then warn("[ZarVD UI] "..tostring(err)) end
end

local Window = WindUI:CreateWindow({
    Title="ZarVD", Icon="sword", Author="by ZarOfficial",
    Folder="ZarVD", Size=UDim2.fromOffset(580,460),
    ToggleKey=Enum.KeyCode.RightShift, Theme="Dark",
    Transparent=true, Resizable=true,
})

-- Helper list player
local function GetPlayerNames()
    local list = {}
    for _, p in ipairs(Players:GetPlayers()) do
        if p ~= LocalPlayer then list[#list+1] = p.Name end
    end
    return list
end

-- ── TAB: ESP ─────────────────────────────────────
local tESP = Window:Tab({ Title="ESP", Icon="eye" })
Safe(function()
    local s = tESP:Section({ Title="Player" })
    s:Toggle({ Title="Player ESP", Desc="Nametag + highlight", Value=Settings.PlayerESP,
        Callback=function(v) Settings.PlayerESP=v if not v then ClearPlayerESP() end end })
    s:Toggle({ Title="Killer Tracker", Desc="Off-screen arrow ke killer", Value=Settings.KillerTracker,
        Callback=function(v)
            Settings.KillerTracker=v
            if not v and IndicatorGui then
                for _, p in ipairs(Players:GetPlayers()) do
                    local l=IndicatorGui:FindFirstChild(p.Name.."_Killer") if l then l:Destroy() end
                end
            end
        end })
    s:Toggle({ Title="Killer Warning !", Desc="Billboard ! kalau killer < 99 studs", Value=Settings.KillerWarning,
        Callback=function(v)
            Settings.KillerWarning=v
            if not v then
                local r=LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
                if r then local w=r:FindFirstChild("KillerWarn") if w then w:Destroy() end end
            end
        end })
end)
Safe(function()
    local s = tESP:Section({ Title="Objects" })
    s:Toggle({ Title="Generator ESP", Desc="Highlight + progress %", Value=Settings.GeneratorESP,
        Callback=function(v) Settings.GeneratorESP=v if not v then ClearGeneratorESP() end end })
    s:Toggle({ Title="Hook ESP", Value=Settings.HookESP,
        Callback=function(v) Settings.HookESP=v if not v then ClearHookESP() end end })
    s:Toggle({ Title="Pallet ESP", Value=Settings.PalletESP,
        Callback=function(v) Settings.PalletESP=v
            if not v then ClearObjectHighlights("Pallet") ClearObjectHighlights("Palletwrong") end end })
    s:Toggle({ Title="Gate ESP", Value=Settings.GateESP,
        Callback=function(v) Settings.GateESP=v if not v then ClearObjectHighlights("Gate") end end })
    s:Toggle({ Title="Window ESP", Value=Settings.WindowESP,
        Callback=function(v) Settings.WindowESP=v if not v then ClearObjectHighlights("Window") end end })
end)

-- ── TAB: Player ──────────────────────────────────
local tPlayer = Window:Tab({ Title="Player", Icon="user" })
Safe(function()
    local s = tPlayer:Section({ Title="Movement" })
    s:Slider({ Title="Walk Speed", Desc="16 = default", Step=1,
        Value={Min=16,Max=150,Default=16},
        Callback=function(v) ApplySpeed(v) end })
    s:Button({ Title="Reset Speed (16)", Callback=function() ApplySpeed(16) Notify("Speed","Reset ke 16","rotate-ccw",2) end })
end)
Safe(function()
    local s = tPlayer:Section({ Title="Collision" })
    s:Toggle({ Title="NoClip", Desc="Tembus dinding & object", Value=Settings.NoClip,
        Callback=function(v) Settings.NoClip=v if v then EnableNoClip() else DisableNoClip() end end })
end)
Safe(function()
    local s = tPlayer:Section({ Title="Appearance" })
    s:Toggle({ Title="Invisible Mode", Desc="Tidak terlihat oleh semua player", Value=Settings.Invisible,
        Callback=function(v)
            Settings.Invisible=v
            if v then EnableInvisible() Notify("Invisible ON","Kamu tidak terlihat!","eye-off",3)
            else DisableInvisible() Notify("Invisible OFF","Kamu terlihat kembali","eye",2) end
        end })
    s:Button({ Title="Force Restore Visibility", Desc="Paksa balik jadi terlihat",
        Callback=function() Settings.Invisible=false DisableInvisible() Notify("Restored","Visibility direset!","eye",2) end })
end)

-- ── TAB: Combat ──────────────────────────────────
local tCombat = Window:Tab({ Title="Combat", Icon="crosshair" })
Safe(function()
    local s = tCombat:Section({ Title="Auto Attack (Killer Only)" })
    s:Toggle({ Title="Auto Attack", Desc="Serang survivor terdekat otomatis", Value=Settings.AutoAttack,
        Callback=function(v) Settings.AutoAttack=v if v then StartAutoAttack() else StopAutoAttack() end end })
    s:Slider({ Title="Attack Range", Step=1, Value={Min=5,Max=25,Default=10},
        Callback=function(v) Settings.AttackRange=v end })
end)
Safe(function()
    local s = tCombat:Section({ Title="Aimbot" })
    s:Toggle({ Title="Aimbot", Desc="Camera lock ke target di FOV", Value=Settings.Aimbot,
        Callback=function(v) Settings.Aimbot=v
            if v then StartAimbot() Notify("Aimbot ON","Camera lock aktif","crosshair",3)
            else StopAimbot() Notify("Aimbot OFF","Camera normal","crosshair",2) end end })
    s:Slider({ Title="Smoothing", Desc="1=smooth, 20=instant snap", Step=1,
        Value={Min=1,Max=20,Default=3}, Callback=function(v) Settings.AimbotSmoothing=v/20 end })
    s:Slider({ Title="FOV (pixel radius)", Step=25, Value={Min=50,Max=600,Default=350},
        Callback=function(v) Settings.AimbotFOV=v end })
    s:Toggle({ Title="Target Kepala", Desc="Off = aim ke body", Value=Settings.AimbotTargetHead,
        Callback=function(v) Settings.AimbotTargetHead=v end })
end)
Safe(function()
    local s = tCombat:Section({ Title="Manual (Killer)" })
    s:Button({ Title="Basic Attack", Desc="Trigger serangan basic sekarang",
        Callback=function()
            if not IsKiller() then Notify("ZarVD ✗","Harus jadi Killer!","shield-off",2) return end
            pcall(function()
                local r=ReplicatedStorage:FindFirstChild("Remotes") if not r then return end
                local a=r:FindFirstChild("Attacks") if not a then return end
                local b=a:FindFirstChild("BasicAttack") if b then b:FireServer(false) end
            end)
            Notify("Attack","Basic attack dikirim!","zap",2)
        end })
    s:Button({ Title="Activate Killer Power",
        Callback=function()
            if not IsKiller() then Notify("ZarVD ✗","Harus jadi Killer!","shield-off",2) return end
            pcall(function()
                local r=ReplicatedStorage:FindFirstChild("Remotes") if not r then return end
                local k=r:FindFirstChild("Killers") if not k then return end
                local kf=k:FindFirstChild("Killer") if not kf then return end
                local ap=kf:FindFirstChild("ActivatePower") if ap then ap:FireServer() end
            end)
            Notify("Power!","Killer power diaktifkan!","zap",2)
        end })
end)

-- ── TAB: Teleport ────────────────────────────────
local tTP = Window:Tab({ Title="Teleport", Icon="map-pin" })

-- TP to Player
local PlayerDropdown = nil
local BringDropdown  = nil

Safe(function()
    local s = tTP:Section({ Title="Teleport ke Player" })
    local names    = GetPlayerNames()
    local initVals = #names > 0 and names or {"(belum ada player)"}
    PlayerDropdown = s:Dropdown({
        Title="Pilih Target TP", Desc="Player tujuan teleport",
        Values=initVals, Value=initVals[1], Multi=false,
        Callback=function(val)
            local v = type(val)=="table" and (val[1] or "") or tostring(val or "")
            if v=="(belum ada player)" then v="" end
            Settings.TPTargetName = v
        end })
    s:Button({ Title="TP ke Player Terpilih", Callback=function() TPToPlayer(Settings.TPTargetName) end })
    s:Button({ Title="Refresh List Player",
        Callback=function()
            local fresh = GetPlayerNames()
            local nv = #fresh > 0 and fresh or {"(belum ada player)"}
            if PlayerDropdown then pcall(function() PlayerDropdown:Refresh(nv) end) end
            Notify("Refresh","List diperbarui","refresh-cw",2)
        end })
end)

-- Bring Player
Safe(function()
    local s = tTP:Section({ Title="Bring Player" })
    local names    = GetPlayerNames()
    local initVals = #names > 0 and names or {"(belum ada player)"}
    BringDropdown = s:Dropdown({
        Title="Pilih Target Bring", Desc="Player yang ditarik ke kamu",
        Values=initVals, Value=initVals[1], Multi=false,
        Callback=function(val)
            local v = type(val)=="table" and (val[1] or "") or tostring(val or "")
            if v=="(belum ada player)" then v="" end
            Settings.BringTarget = v
        end })
    s:Button({ Title="Bring (Sekali)", Desc="Tarik player terpilih ke kamu",
        Callback=function()
            if BringPlayer(Settings.BringTarget) then
                Notify("Bring ✓",Settings.BringTarget.." ditarik!","user-check",2)
            end
        end })
    s:Toggle({ Title="Keep Bringing (Loop)", Desc="Terus tarik walau kabur", Value=false,
        Callback=function(v)
            Settings.KeepBringing=v
            if v then
                if Settings.BringTarget=="" then Notify("ZarVD","Pilih target dulu!","alert-circle",2) Settings.KeepBringing=false return end
                StartKeepBringing()
                Notify("Keep Bring ON","Menarik "..Settings.BringTarget.." terus-menerus","anchor",3)
            else
                StopKeepBringing()
                Notify("Keep Bring OFF","Berhenti menarik","anchor",2)
            end
        end })
    s:Button({ Title="Bring ALL Players", Desc="Tarik semua player ke kamu sekarang",
        Callback=function() BringAllPlayers() end })
    s:Toggle({ Title="Keep Bring ALL (Loop)", Desc="Terus tarik semua player tiap frame", Value=false,
        Callback=function(v)
            if v then StartKeepBringAll() Notify("Bring ALL ON","Semua player ditarik terus!","users",3)
            else StopKeepBringAll() Notify("Bring ALL OFF","Berhenti menarik semua","users",2) end
        end })
    s:Button({ Title="Refresh List (Bring)",
        Callback=function()
            local fresh = GetPlayerNames()
            local nv = #fresh > 0 and fresh or {"(belum ada player)"}
            if BringDropdown then pcall(function() BringDropdown:Refresh(nv) end) end
            Notify("Refresh","List diperbarui","refresh-cw",2)
        end })
end)

-- Generator
Safe(function()
    local s = tTP:Section({ Title="Generator" })
    s:Button({ Title="TP → Generator Terdekat",
        Callback=function()
            local g=GetGeneratorsByDist()
            if #g==0 then Notify("ZarVD","Tidak ada generator!","alert-circle",3) return end
            if SafeTeleport(g[1].part.CFrame) then
                Notify("TP ✓",string.format("Gen terdekat — %.0f studs",g[1].dist),"map-pin",3)
            end
        end })
    s:Button({ Title="TP → Generator Terjauh",
        Callback=function()
            local g=GetGeneratorsByDist()
            if #g==0 then Notify("ZarVD","Tidak ada generator!","alert-circle",3) return end
            if SafeTeleport(g[#g].part.CFrame) then
                Notify("TP ✓",string.format("Gen terjauh — %.0f studs",g[#g].dist),"map-pin",3)
            end
        end })
    s:Button({ Title="Tour Semua Generator", Desc="TP ke tiap gen satu-satu",
        Callback=function()
            local g=GetGeneratorsByDist()
            if #g==0 then Notify("ZarVD","Tidak ada generator!","alert-circle",3) return end
            Notify("Tour Mulai","Mengunjungi "..#g.." generator...","map",3)
            task.spawn(function()
                for i,gen in ipairs(g) do
                    if not GetRoot() then break end
                    SafeTeleport(gen.part.CFrame)
                    Notify("Gen "..i.."/"..#g,string.format("%.0f studs",gen.dist),"map-pin",1.5)
                    task.wait(Settings.TeleportDelay+0.5)
                end
                Notify("Tour Selesai ✓","Semua generator dikunjungi!","check-circle",3)
            end)
        end })
    s:Button({ Title="Leave Generator (Kabur)", Callback=function() LeaveGenerator() end })
end)

-- Lokasi Lain
Safe(function()
    local s = tTP:Section({ Title="Lokasi Lain" })
    s:Button({ Title="TP → Gate Terdekat",
        Callback=function()
            local hrp=GetRoot() local map=GetMap()
            if not hrp or not map then Notify("ZarVD ✗","Character/Map tidak ada!","alert-circle",3) return end
            local near,nearD=nil,math.huge
            for _, o in ipairs(map:GetDescendants()) do
                if o:IsA("Model") and o.Name=="Gate" then
                    local p=o:FindFirstChildWhichIsA("BasePart")
                    if p then local d=(p.Position-hrp.Position).Magnitude if d<nearD then nearD=d near=p end end
                end
            end
            if near then SafeTeleport(near.CFrame) Notify("TP ✓",string.format("Gate — %.0f studs",nearD),"door-open",3)
            else Notify("ZarVD","Gate tidak ditemukan!","alert-circle",3) end
        end })
    s:Button({ Title="Escape Game (Survivor Only)",
        Callback=function()
            if not IsSurvivor() then Notify("ZarVD ✗","Harus jadi Survivor!","shield-off",3) return end
            local map=GetMap() if not map then Notify("ZarVD ✗","Map tidak ada!","alert-circle",3) return end
            local gate=nil
            for _, o in ipairs(map:GetDescendants()) do if o:IsA("Model") and o.Name=="Gate" then gate=o break end end
            if not gate then Notify("ZarVD ✗","Gate tidak ditemukan!","alert-circle",3) return end
            local ez=gate:FindFirstChild("Escape") or gate:FindFirstChildWhichIsA("BasePart")
            if ez then
                SafeTeleport(ez.CFrame,Vector3.new(0,5,0))
                task.wait(0.5)
                pcall(function()
                    local r=ReplicatedStorage:FindFirstChild("Remotes") if not r then return end
                    local gr=r:FindFirstChild("Gate") if not gr then return end
                    local ev=gr:FindFirstChild("Escape") if ev then ev:FireServer() end
                end)
                Notify("Escape!","Jalan ke luar gate!","door-open",4)
            else Notify("ZarVD ✗","Zona escape tidak ditemukan!","alert-circle",3) end
        end })
end)

-- Settings TP
Safe(function()
    local s = tTP:Section({ Title="Pengaturan Teleport" })
    s:Slider({ Title="Height Offset", Step=1, Value={Min=0,Max=10,Default=3},
        Callback=function(v) Settings.TeleportOffset=v end })
    s:Slider({ Title="Tour Delay (detik)", Step=1, Value={Min=0,Max=5,Default=1},
        Callback=function(v) Settings.TeleportDelay=v end })
    s:Toggle({ Title="Safe Teleport", Desc="Nonaktifin collision saat TP", Value=Settings.SafeTeleport,
        Callback=function(v) Settings.SafeTeleport=v end })
end)

-- Auto refresh dropdown saat player join/leave (SATU koneksi)
Players.PlayerAdded:Connect(function()
    task.wait(0.5)
    local fresh = GetPlayerNames()
    local nv = #fresh > 0 and fresh or {"(belum ada player)"}
    if PlayerDropdown then pcall(function() PlayerDropdown:Refresh(nv) end) end
    if BringDropdown  then pcall(function() BringDropdown:Refresh(nv)  end) end
end)
Players.PlayerRemoving:Connect(function(p)
    task.wait(0.1)
    local fresh = GetPlayerNames()
    local nv = #fresh > 0 and fresh or {"(belum ada player)"}
    if PlayerDropdown then pcall(function() PlayerDropdown:Refresh(nv) end) end
    if BringDropdown  then pcall(function() BringDropdown:Refresh(nv)  end) end
end)

-- ── TAB: Misc ────────────────────────────────────
local tMisc = Window:Tab({ Title="Misc", Icon="settings" })
Safe(function()
    local s = tMisc:Section({ Title="Lighting" })
    s:Toggle({ Title="Fullbright", Desc="Terangin seluruh map", Value=Settings.Fullbright,
        Callback=function(v)
            Settings.Fullbright=v
            if not v then
                Lighting.Ambient=Color3.fromRGB(70,70,70) Lighting.OutdoorAmbient=Color3.fromRGB(70,70,70)
                Lighting.Brightness=1 Lighting.GlobalShadows=true Lighting.FogEnd=100000
            end
        end })
end)
Safe(function()
    local s = tMisc:Section({ Title="Gameplay" })
    s:Toggle({ Title="Auto Skill Check", Desc="Auto repair skillcheck (Mobile)", Value=Settings.AutoSkillCheck,
        Callback=function(v)
            Settings.AutoSkillCheck=v
            if v then InitializeAutobuy()
            else
                if HeartbeatConn then HeartbeatConn:Disconnect() HeartbeatConn=nil end
                if VisibilityConn then VisibilityConn:Disconnect() VisibilityConn=nil end
            end
        end })
    s:Toggle({ Title="Next Killer Display", Desc="Prediksi killer berikutnya di lobby", Value=Settings.NextKiller,
        Callback=function(v)
            Settings.NextKiller=v
            if not v and IndicatorGui then
                local l=IndicatorGui:FindFirstChild("NextKillerDisplay") if l then l:Destroy() end
            end
        end })
end)
Safe(function()
    local s = tMisc:Section({ Title="FPS Counter" })
    s:Toggle({ Title="FPS Counter HUD", Desc="HUD FPS + Ping, bisa di-drag", Value=Settings.FPSCounter,
        Callback=function(v)
            Settings.FPSCounter=v
            if v then CreateFPSCounter() Notify("FPS ON","Drag untuk pindahkan HUD","activity",3)
            else DestroyFPSCounter() end
        end })
end)
Safe(function()
    local s = tMisc:Section({ Title="Crosshair" })
    s:Toggle({ Title="Crosshair", Desc="Crosshair di tengah layar", Value=Settings.Crosshair,
        Callback=function(v)
            Settings.Crosshair=v
            if v then CreateCrosshair() Notify("Crosshair ON","Style: "..Settings.CrosshairStyle,"crosshair",2)
            else DestroyCrosshair() end
        end })
    s:Dropdown({ Title="Style Crosshair", Values={"cross","dot","circle","dynamic"}, Value="cross", Multi=false,
        Callback=function(val)
            local v2=type(val)=="table" and (val[1] or "cross") or tostring(val or "cross")
            Settings.CrosshairStyle=v2
            if Settings.Crosshair then CreateCrosshair() end
        end })
    s:Slider({ Title="Size", Step=1, Value={Min=4,Max=30,Default=12},
        Callback=function(v) Settings.CrosshairSize=v if Settings.Crosshair then CreateCrosshair() end end })
    s:Slider({ Title="Gap", Step=1, Value={Min=1,Max=20,Default=4},
        Callback=function(v) Settings.CrosshairGap=v if Settings.Crosshair then CreateCrosshair() end end })
    s:Dropdown({ Title="Warna", Values={"Merah","Hijau Neon","Putih","Kuning","Cyan"}, Value="Merah", Multi=false,
        Callback=function(val)
            local v2=type(val)=="table" and (val[1] or "Merah") or tostring(val or "Merah")
            local map2={Merah=Color3.fromRGB(255,60,60),["Hijau Neon"]=Color3.fromRGB(0,255,100),
                        Putih=Color3.fromRGB(255,255,255),Kuning=Color3.fromRGB(255,220,0),Cyan=Color3.fromRGB(0,200,255)}
            Settings.CrosshairColor=map2[v2] or Color3.fromRGB(255,60,60)
            if Settings.Crosshair then CreateCrosshair() end
        end })
end)

-- ── TAB: Info ────────────────────────────────────
local tInfo = Window:Tab({ Title="Info", Icon="info" })
Safe(function()
    tInfo:Paragraph({ Title="ZarVD • Violence District",
        Content="UI: WindUI  |  Dev: ZarOfficial\nHandle: @ZarOffc  |  Toggle: RightShift" })
    tInfo:Paragraph({ Title="Semua Fitur", Content=
        "ESP: Player, Killer Tracker, Warning, Gen, Hook, Pallet, Gate, Window\n"..
        "Auto Skill Check + Fullbright + Next Killer Predictor\n"..
        "Speed Slider + NoClip + Invisible Mode\n"..
        "Auto Attack + Aimbot (FOV+Smooth+Head/Body)\n"..
        "TP ke Player / Bring Player / Bring ALL\n"..
        "TP Gen (Terdekat/Terjauh/Tour) + Gate + Escape\n"..
        "FPS Counter HUD (draggable) + Crosshair (4 style)"
    })
end)

Notify("ZarVD Loaded ✓","Violence District aktif! | Dev: ZarOfficial","check-circle",5)
