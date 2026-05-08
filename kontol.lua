repeat task.wait() until game:IsLoaded()
if setfpscap then setfpscap(1000000) end
local Players           = game:GetService("Players")
local RunService        = game:GetService("RunService")
local Workspace         = game:GetService("Workspace")
local Lighting          = game:GetService("Lighting")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService  = game:GetService("UserInputService")
local LocalPlayer       = Players.LocalPlayer
local Library = loadstring(game:HttpGet("https://raw.githubusercontent.com/habibrodriguez7-art/newGui/refs/heads/main/10.lua"))()
local function GetRoot()
    local c = LocalPlayer.Character
    return c and c:FindFirstChild("HumanoidRootPart")
end
local function IsKiller(pl)
    return pl and pl.Character and (
        pl.Character:FindFirstChild("Weapon") ~= nil or
        (pl.Team and (pl.Team.Name == "Killer" or pl.Team.Name == "Murderer"))
    )
end
local function getMapFolders()
    local t = {}
    local m = Workspace:FindFirstChild("Map")
    if m then table.insert(t, m) end
    return t
end
local function Notify(title, desc)
    Library:MakeNotify({ Title = title, Description = desc, Delay = 3 })
end

local Win = Library:Window({ Title = "Lynx", Footer = "Violence District" })
local SurTab = Win:AddTab({ Name = "Survivor", Icon = "user" })
do
    local function shouldSkip(d)
        return d.Name == "HumanoidRootPart" or d.Name == "Hurtbox" or d.Name == "HRP_Clone"
    end
    local INV_CONFIG = {
        DEFAULT_SPEED         = 16,
        BOOSTED_SPEED         = 48,
        INVISIBILITY_POSITION = Vector3.new(-25.95, 84, 3537.55),
        HOTKEY                = Enum.KeyCode.X,
    }
    local invState = {
        isInvisible          = false,
        isSpeedBoosted       = false,
        originalSpeed        = INV_CONFIG.DEFAULT_SPEED,
        originalTransparency = {},
    }
    local SurInvisSection = SurTab:AddSection("Feature Invisible")
    local invToggleRef = SurInvisSection:AddToggle({
        Title    = "Invisible",
        Default  = false,
        Callback = function(v)
            if not LocalPlayer.Character then return end

            if v then
                local hrp = LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
                if not hrp then return end

                invState.originalTransparency = {}
                for _, d in LocalPlayer.Character:GetDescendants() do
                    if (d:IsA("BasePart") or d:IsA("Decal")) and not shouldSkip(d) then
                        invState.originalTransparency[d] = d.Transparency
                    end
                end
                local savedPos = hrp.CFrame
                LocalPlayer.Character:MoveTo(INV_CONFIG.INVISIBILITY_POSITION)
                task.wait(0.15)
                local seat = Instance.new("Seat")
                seat.Name         = "invischair"
                seat.Anchored     = false
                seat.CanCollide   = false
                seat.Transparency = 1
                seat.Position     = INV_CONFIG.INVISIBILITY_POSITION
                seat.Parent       = workspace
                local weld = Instance.new("Weld")
                weld.Part0  = seat
                weld.Part1  = LocalPlayer.Character:FindFirstChild("Torso")
                           or LocalPlayer.Character:FindFirstChild("UpperTorso")
                weld.Parent = seat
                task.wait()
                seat.CFrame = savedPos
                for _, d in LocalPlayer.Character:GetDescendants() do
                    if (d:IsA("BasePart") or d:IsA("Decal")) and not shouldSkip(d) then
                        d.Transparency = 1
                    end
                end
                invState.isInvisible = true
                Library:MakeNotify({
                    Title       = "Invisible ON",
                    Description = "Hotkey: " .. INV_CONFIG.HOTKEY.Name .. " untuk toggle",
                    Delay       = 2,
                })
            else
                invState.isInvisible = false
                for _, obj in workspace:GetChildren() do
                    if obj.Name == "invischair" then obj:Destroy() end
                end
                if LocalPlayer.Character then
                    for _, d in LocalPlayer.Character:GetDescendants() do
                        if (d:IsA("BasePart") or d:IsA("Decal")) and not shouldSkip(d) then
                            local orig = invState.originalTransparency[d]
                            d.Transparency = orig ~= nil and orig or 0
                        end
                    end
                end
                invState.originalTransparency = {}
                Library:MakeNotify({
                    Title       = "Invisible OFF",
                    Description = "Karakter kamu sudah terlihat normal",
                    Delay       = 2,
                })
            end
        end,
    })

    local spdToggleRef = SurInvisSection:AddToggle({
        Title    = "Speed Boost",
        Default  = false,
        Callback = function(v)
            local hum = LocalPlayer.Character
                    and LocalPlayer.Character:FindFirstChildOfClass("Humanoid")
            if not hum then return end
            if v then
                invState.originalSpeed  = hum.WalkSpeed
                invState.isSpeedBoosted = true
                hum.WalkSpeed           = INV_CONFIG.BOOSTED_SPEED
            else
                invState.isSpeedBoosted = false
                hum.WalkSpeed           = invState.originalSpeed
            end
        end,
    })

    SurInvisSection:AddInput({
        Title    = "Hotkey Invisible (PC)",
        Default  = "X",
        Callback = function(text)
            local ok, key = pcall(function()
                return Enum.KeyCode[text:upper()]
            end)
            if ok and key then
                INV_CONFIG.HOTKEY = key
                Library:MakeNotify({
                    Title       = "Hotkey diperbarui",
                    Description = "Key: " .. text:upper(),
                    Delay       = 2,
                })
            else
                warn("Key tidak valid: " .. text)
            end
        end,
    })

    UserInputService.InputBegan:Connect(function(input, gp)
        if gp then return end
        if input.KeyCode == INV_CONFIG.HOTKEY then
            invToggleRef:SetValue(not invState.isInvisible)
        end
    end)

    LocalPlayer.CharacterAdded:Connect(function(character)
        for _, obj in workspace:GetChildren() do
            if obj.Name == "invischair" then obj:Destroy() end
        end
        invState.isInvisible          = false
        invState.isSpeedBoosted       = false
        invState.originalTransparency = {}
        invState.originalSpeed        = INV_CONFIG.DEFAULT_SPEED
        character:WaitForChild("HumanoidRootPart")
        character:WaitForChild("Humanoid")
        character.DescendantAdded:Connect(function(d)
            if not invState.isInvisible then return end
            if (d:IsA("BasePart") or d:IsA("Decal")) and not shouldSkip(d) then
                task.defer(function()
                    if invState.isInvisible then
                        invState.originalTransparency[d] = d.Transparency
                        d.Transparency = 1
                    end
                end)
            end
        end)
        local hum = character:FindFirstChildOfClass("Humanoid")
        if hum then invState.originalSpeed = hum.WalkSpeed end
        if invToggleRef then invToggleRef:SetValue(false) end
        if spdToggleRef then spdToggleRef:SetValue(false) end
    end)
end

do
    local parryEnabled = false
    local parryRange   = 10

    local Players           = game:GetService("Players")
    local LocalPlayer       = Players.LocalPlayer
    local CollectionService = game:GetService("CollectionService")
    local TweenService      = game:GetService("TweenService")
    local ReplicatedStorage = game:GetService("ReplicatedStorage")

    local char = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
    local root = char:WaitForChild("HumanoidRootPart")
    local hum  = char:WaitForChild("Humanoid")

    local parryRemote = ReplicatedStorage.Remotes.Items
        :WaitForChild("Parrying Dagger")
        :WaitForChild("parry")
    local slowRemote = ReplicatedStorage.Remotes.Mechanics
        :WaitForChild("Slow")

    local lastParryTime  = 0
    local PARRY_COOLDOWN = 50

    local ATTACK_ANIMS = {
        ["rbxassetid://110355011987939"] = true,
        ["rbxassetid://105374834496520"] = true,
        ["rbxassetid://113255068724446"] = true,
        ["rbxassetid://117042998468241"] = true,
        ["rbxassetid://122812055447896"] = true,
        ["rbxassetid://118907603246885"] = true,
        ["rbxassetid://129784271201071"] = true
    }

    local function canParry()
        if hum.Health < hum.MaxHealth * 0.5 then return false end
        if char:GetAttribute("IsCarried") then return false end
        if char:GetAttribute("IsHooked") then return false end
        if CollectionService:HasTag(root, "doing action") then return false end
        local check = char:FindFirstChild("CheckInterractable")
        if check then
            for _, attr in ipairs({"isVaulting","isSliding","isDroppingPallet",
                "isRepairing","isHealing","isUnhooking","isExiting"}) do
                if check:GetAttribute(attr) then return false end
            end
        end
        return true
    end

    local function updateUI()
        local pg = LocalPlayer:FindFirstChildOfClass("PlayerGui")
        if not pg then return end
        local paths = {
            {"Survivor",     "Gen", "ItemFrame", "Gui", "Bar", "UIGradient"},
            {"Survivor-mob", "Gen", "ItemFrame", "Gui", "Bar", "UIGradient"},
            {"Survivor-con", "Gen", "ItemFrame", "Gui", "Bar", "UIGradient"},
        }
        for _, path in ipairs(paths) do
            local obj = pg
            for _, name in ipairs(path) do
                obj = obj:FindFirstChild(name)
                if not obj then break end
            end
            if obj and obj:IsA("UIGradient") then
                obj.Offset = Vector2.new(0, 0.75)
                TweenService:Create(obj,
                    TweenInfo.new(PARRY_COOLDOWN, Enum.EasingStyle.Linear),
                    {Offset = Vector2.new(0, 0.25)}
                ):Play()
            end
        end
    end

    local function getKillerInRange(range)
        for _, pl in ipairs(Players:GetPlayers()) do
            if pl == LocalPlayer or not pl.Character then continue end
            if not (pl.Team and pl.Team.Name == "Killer") then continue end
            local kr = pl.Character:FindFirstChild("HumanoidRootPart")
            if not kr then continue end
            if (kr.Position - root.Position).Magnitude <= range then
                return pl
            end
        end
        return nil
    end

    local function doParry(killer)
        local now = tick()
        if now - lastParryTime < PARRY_COOLDOWN then return end
        if not canParry() then return end
        if not killer or not killer.Character then return end

        local killerRoot = killer.Character:FindFirstChild("HumanoidRootPart")
        if not killerRoot then return end

        if not getKillerInRange(parryRange) then return end

        lastParryTime = now

        local direction = Vector3.new(
            killerRoot.Position.X - root.Position.X,
            0,
            killerRoot.Position.Z - root.Position.Z
        ).Unit
        root.CFrame = CFrame.new(root.Position, root.Position + direction)

        slowRemote:Fire(0, 1, 0)
        parryRemote:FireServer()
        updateUI()
    end

    local function hookKiller(pl)
        if not pl.Character then return end
        local hum2 = pl.Character:FindFirstChildOfClass("Humanoid")
        if not hum2 then return end
        local animator = hum2:FindFirstChildOfClass("Animator")
        if not animator then return end

        animator.AnimationPlayed:Connect(function(track)
            local id = track.Animation and track.Animation.AnimationId or ""
            if not ATTACK_ANIMS[id] then return end
            if not parryEnabled then return end
            task.spawn(doParry, pl)
        end)

        pl.CharacterAdded:Connect(function()
            task.wait(1)
            hookKiller(pl)
        end)
    end

    for _, pl in ipairs(Players:GetPlayers()) do
        if pl ~= LocalPlayer then
            task.spawn(hookKiller, pl)
        end
    end

    Players.PlayerAdded:Connect(function(pl)
        pl.CharacterAdded:Connect(function()
            task.wait(1)
            hookKiller(pl)
        end)
    end)

    LocalPlayer.CharacterAdded:Connect(function(newChar)
        char = newChar
        root = newChar:WaitForChild("HumanoidRootPart")
        hum  = newChar:WaitForChild("Humanoid")
        lastParryTime = 0
        for _, pl in ipairs(Players:GetPlayers()) do
            if pl ~= LocalPlayer then
                task.spawn(hookKiller, pl)
            end
        end
    end)

    local s3 = SurTab:AddSection("Auto Parry [BETA]")

    s3:AddToggle({
        Title    = "Enable Auto Parry",
        Default  = false,
        Callback = function(v)
            parryEnabled = v
        end,
    })

    s3:AddInput({
        Title    = "Parry Range (studs)",
        Default  = "10",
        Callback = function(v)
            local n = tonumber(v)
            if n then parryRange = math.max(1, n) end
        end,
    })
end

do
    local teleAway     = false
    local teleAwayDist = 40
    local lastTeleAway = 0
    local s = SurTab:AddSection("Survival Utility")
    s:AddToggle({
        Title    = "No Fall Damage",
        Default  = false,
        Callback = function(v)
            if v then
                task.spawn(function()
                    local noFall = v
                    local fe = pcall(function() return ReplicatedStorage.Remotes.Mechanics.Fall end) and ReplicatedStorage.Remotes.Mechanics:FindFirstChild("Fall")
                    while noFall do
                        if fe then pcall(function() fe:FireServer(-100) end) end
                        task.wait(1)
                    end
                end)
            end
        end,
    })

    s:AddToggle({
        Title    = "Flee Killer (Auto TP Menjauh)",
        Default  = false,
        Callback = function(v)
            teleAway = v
            if v then
                task.spawn(function()
                    while teleAway do
                        local root = GetRoot()
                        if root and tick() - lastTeleAway >= 3 then
                            local killerDist, killerPos = math.huge, nil
                            for _, pl in ipairs(Players:GetPlayers()) do
                                if pl ~= LocalPlayer and IsKiller(pl) and pl.Character then
                                    local kr = pl.Character:FindFirstChild("HumanoidRootPart")
                                    if kr then
                                        local d = (kr.Position - root.Position).Magnitude
                                        if d < killerDist then killerDist = d; killerPos = kr.Position end
                                    end
                                end
                            end
                            if killerPos and killerDist <= teleAwayDist then
                                lastTeleAway = tick()
                                local best, bestD = nil, 0
                                for _, folder in pairs(getMapFolders()) do
                                    for _, obj in pairs(folder:GetChildren()) do
                                        if obj.Name == "Gate" or obj.Name == "Generator" then
                                            local bp = obj.PrimaryPart or obj:FindFirstChildWhichIsA("BasePart")
                                            if bp then
                                                local d = (bp.Position - killerPos).Magnitude
                                                if d > bestD then bestD = d; best = bp.Position end
                                            end
                                        end
                                    end
                                end
                                if best then pcall(function() root.CFrame = CFrame.new(best + Vector3.new(0, 3, 0)) end) end
                            end
                        end
                        task.wait(0.5)
                    end
                end)
            end
        end,
    })
    s:AddInput({ Title = "Flee Distance (studs)", Default = "40", Callback = function(v) local n = tonumber(v); if n then teleAwayDist = n end end })

    local godConn = nil
    s:AddToggle({
        Title    = "God Mode",
        Default  = false,
        Callback = function(v)
            if godConn then godConn:Disconnect(); godConn = nil end
            if v then
                godConn = RunService.Heartbeat:Connect(function()
                    local c = LocalPlayer.Character; if not c then return end
                    local hum = c:FindFirstChildOfClass("Humanoid"); if not hum then return end
                    if hum.Health < hum.MaxHealth then hum.Health = hum.MaxHealth end
                end)
            end
        end,
    })

    local fastVault = false
    local vaultConns = {}
    s:AddToggle({
        Title    = "Fast Vault",
        Default  = false,
        Callback = function(v)
            fastVault = v
            for _, c in ipairs(vaultConns) do pcall(function() c:Disconnect() end) end
            vaultConns = {}
            if v then
                local map = Workspace:FindFirstChild("Map")
                local function hookTrigger(trigger)
                    local conn = trigger.Touched:Connect(function(part)
                        if not fastVault then return end
                        local char = LocalPlayer.Character; if not char then return end
                        local p = part; local isOurs = false
                        while p do if p == char then isOurs = true; break end; p = p.Parent end
                        if not isOurs then return end
                        pcall(function()
                            local rem = ReplicatedStorage.Remotes.Window
                            rem.fastvault:FireServer(LocalPlayer)
                            rem.VaultEvent:FireServer(trigger, true)
                            task.wait(0.03)
                            rem.VaultCompleteEvent:FireServer(trigger, false)
                        end)
                    end)
                    table.insert(vaultConns, conn)
                end
                if map then
                    for _, t in ipairs(map:GetDescendants()) do
                        if t.Name == "VaultTrigger" and t:IsA("BasePart") then hookTrigger(t) end
                    end
                end
                Notify("Vault", "Fast Vault aktif!")
            end
        end,
    })
end

do
    local GenRushSection = SurTab:AddSection("Auto Generator Rush")
    local autoGenRush    = false
    local killerDistance = 30
    local cancelGui = nil
    local function ShowCancelButton(onCancel)
        if cancelGui then return end
        local pGui = game.Players.LocalPlayer:FindFirstChild("PlayerGui")
        if not pGui then return end
        cancelGui = Instance.new("ScreenGui")
        cancelGui.Name           = "GenRushCancelGui"
        cancelGui.ResetOnSpawn   = false
        cancelGui.DisplayOrder   = 9999
        cancelGui.IgnoreGuiInset = true
        cancelGui.Parent         = pGui
        local btn = Instance.new("TextButton")
        btn.Size             = UDim2.new(0, 56, 0, 56)
        btn.Position         = UDim2.new(0, 20, 0.5, 0)
        btn.AnchorPoint      = Vector2.new(0, 0.5)
        btn.BackgroundColor3 = Color3.fromRGB(220, 50, 50)
        btn.BorderSizePixel  = 0
        btn.Text             = "X"
        btn.TextColor3       = Color3.new(1, 1, 1)
        btn.TextSize         = 22
        btn.Font             = Enum.Font.GothamBold
        btn.AutoButtonColor  = false
        btn.Parent           = cancelGui
        Instance.new("UICorner", btn).CornerRadius = UDim.new(1, 0)
        local label = Instance.new("TextLabel")
        label.Size                   = UDim2.new(1, 0, 0, 16)
        label.Position               = UDim2.new(0, 0, 1, 4)
        label.BackgroundTransparency = 1
        label.Text                   = "[Q]"
        label.TextColor3             = Color3.fromRGB(220, 50, 50)
        label.TextSize               = 11
        label.Font                   = Enum.Font.GothamBold
        label.Parent                 = btn
        btn.MouseButton1Click:Connect(function()
            if onCancel then onCancel() end
        end)
    end
    local function HideCancelButton()
        if cancelGui then
            cancelGui:Destroy()
            cancelGui = nil
        end
    end
    game:GetService("UserInputService").InputBegan:Connect(function(input, gpe)
        if gpe then return end
        if input.KeyCode == Enum.KeyCode.Q and cancelGui then
            local btn = cancelGui:FindFirstChildWhichIsA("TextButton")
            if btn then btn:GetPropertyChangedSignal("Text"):Connect(function() end) end
            autoGenRush = false
            HideCancelButton()
        end
    end)
    local genRushThread = nil
    GenRushSection:AddToggle({
        Title    = "Auto Gen Rush",
        Default  = false,
        NoSave   = true,
        Callback = function(v)
            autoGenRush = v
            if not autoGenRush then
                HideCancelButton()
                if genRushThread then
                    task.cancel(genRushThread)
                    genRushThread = nil
                end
                pcall(function()
                    local r = game:GetService("ReplicatedStorage"):FindFirstChild("Remotes")
                    local g = r and r:FindFirstChild("Generator")
                    local repairRemote = g and g:FindFirstChild("RepairEvent")
                    local skillRemote  = g and g:FindFirstChild("SkillCheckResultEvent")
                    if not repairRemote or not skillRemote then return end
                    local map = workspace:FindFirstChild("Map")
                    if not map then return end
                    for _, v2 in ipairs(map:GetDescendants()) do
                        if v2:IsA("Model") and v2.Name == "Generator" then
                            for _, c in ipairs(v2:GetChildren()) do
                                if c.Name:match("GeneratorPoint") then
                                    pcall(repairRemote.FireServer, repairRemote, c, false)
                                    pcall(skillRemote.FireServer, skillRemote, "neutral", 0, v2, c)
                                    break
                                end
                            end
                        end
                    end
                end)
                return
            end
            genRushThread = task.spawn(function()
                local Players         = game:GetService("Players")
                local ReplicatedStorage = game:GetService("ReplicatedStorage")
                local LocalPlayer     = Players.LocalPlayer
                local repairRemote = nil
                local skillRemote  = nil
                local lastScan     = 0
                local genPoints    = {}
                local currentData  = nil
                local function GetHRP()
                    local c = LocalPlayer.Character
                    return c and c:FindFirstChild("HumanoidRootPart")
                end
                local function GetHumanoid()
                    local c = LocalPlayer.Character
                    return c and c:FindFirstChild("Humanoid")
                end
                local function IsKiller(player)
                    if not player.Team then return false end
                    local t = string.lower(player.Team.Name)
                    return string.find(t, "killer") or string.find(t, "murderer")
                end
                local function GetNearestKillerDist()
                    local hrp = GetHRP()
                    if not hrp then return math.huge end
                    local minDist = math.huge
                    for _, p in pairs(Players:GetPlayers()) do
                        if p ~= LocalPlayer and p.Character and IsKiller(p) then
                            local khrp = p.Character:FindFirstChild("HumanoidRootPart")
                            if khrp then
                                local d = (khrp.Position - hrp.Position).Magnitude
                                if d < minDist then minDist = d end
                            end
                        end
                    end
                    return minDist
                end
                local function ScanGenPoints()
                    local result = {}
                    local map = workspace:FindFirstChild("Map")
                    if not map then return result end
                    for _, v2 in ipairs(map:GetDescendants()) do
                        if v2:IsA("Model") and v2.Name == "Generator" then
                            local progress = v2:GetAttribute("RepairProgress") or 0
                            if progress < 100 then
                                local part = v2:FindFirstChildWhichIsA("BasePart")
                                for _, c in ipairs(v2:GetChildren()) do
                                    if c.Name:match("GeneratorPoint") then
                                        table.insert(result, {gen = v2, pt = c, part = part, progress = progress})
                                        break
                                    end
                                end
                            end
                        end
                    end
                    table.sort(result, function(a, b) return a.progress > b.progress end)
                    return result
                end
                local function TeleportToGen(data)
                    local hrp = GetHRP()
                    if not hrp or not data or not data.part then return end
                    local pos = data.part.CFrame * CFrame.new(0, 0, 4)
                    hrp.CFrame = pos
                    local hum = GetHumanoid()
                    if hum then hum:MoveTo(pos.Position) end
                    for _ = 1, 3 do task.wait(0.1); hrp.CFrame = pos end
                end
                local function StopCurrentRepair()
                    if not currentData then return end
                    pcall(repairRemote.FireServer, repairRemote, currentData.pt, false)
                    pcall(skillRemote.FireServer, skillRemote, "neutral", 0, currentData.gen, currentData.pt)
                end
                ShowCancelButton(function()
                    autoGenRush = false
                    StopCurrentRepair()
                    currentData = nil
                    HideCancelButton()
                end)
                while autoGenRush do
                    pcall(function()
                        if not repairRemote or not skillRemote then
                            local r = ReplicatedStorage:FindFirstChild("Remotes")
                            local g = r and r:FindFirstChild("Generator")
                            repairRemote = g and g:FindFirstChild("RepairEvent")
                            skillRemote  = g and g:FindFirstChild("SkillCheckResultEvent")
                        end
                        if not repairRemote or not skillRemote then return end
                        if tick() - lastScan > 2 then
                            genPoints = ScanGenPoints()
                            lastScan  = tick()
                        end
                        if #genPoints == 0 then currentData = nil; return end
                        if currentData then
                            local prog = currentData.gen:GetAttribute("RepairProgress") or 0
                            if prog >= 100 or not currentData.part or not currentData.part.Parent then
                                pcall(repairRemote.FireServer, repairRemote, currentData.pt, false)
                                currentData = nil
                            end
                        end
                        if not currentData then
                            currentData = genPoints[1]
                            if currentData then TeleportToGen(currentData) end
                        end
                        if not currentData then return end
                        local killerDist = GetNearestKillerDist()
                        if killerDist <= killerDistance then
                            local bestData = nil
                            local bestDist = 0
                            for _, data in ipairs(genPoints) do
                                if data.gen ~= currentData.gen and data.part then
                                    local minD = math.huge
                                    for _, p in pairs(Players:GetPlayers()) do
                                        if p ~= LocalPlayer and p.Character and IsKiller(p) then
                                            local khrp = p.Character:FindFirstChild("HumanoidRootPart")
                                            if khrp then
                                                local d = (khrp.Position - data.part.Position).Magnitude
                                                if d < minD then minD = d end
                                            end
                                        end
                                    end
                                    if minD > bestDist then bestDist = minD; bestData = data end
                                end
                            end
                            if bestData and bestDist > killerDistance then
                                StopCurrentRepair()
                                task.wait(0.1)
                                currentData = bestData
                                TeleportToGen(currentData)
                                task.wait(1)
                            end
                            return
                        end
                        for _, data in ipairs(genPoints) do
                            pcall(repairRemote.FireServer, repairRemote, data.pt, true)
                            pcall(skillRemote.FireServer, skillRemote, "success", 1, data.gen, data.pt)
                        end
                    end)
                    task.wait(0.15)
                end
                StopCurrentRepair()
                HideCancelButton()
            end)
        end
    })

    GenRushSection:AddInput({
        Title    = "Killer Escape Distance",
        Default  = tostring(killerDistance),
        NoSave   = true,
        Callback = function(value)
            local num = tonumber(value)
            if num and num > 0 then killerDistance = num end
        end
    })
end

do
    local autoSkill = false
    local s = SurTab:AddSection("Generator")
    s:AddToggle({
        Title    = "Auto SkillCheck (Perfect)",
        Default  = false,
        Callback = function(v)
            autoSkill = v
            if not v then return end
            task.spawn(function()
                local pg = LocalPlayer:FindFirstChild("PlayerGui")
                if not pg then return end

                local function pressSpace()
                    pcall(function()
                        local vim = game:GetService("VirtualInputManager")
                        vim:SendKeyEvent(true,  Enum.KeyCode.Space, false, game)
                        task.wait(0.01)
                        vim:SendKeyEvent(false, Enum.KeyCode.Space, false, game)
                    end)
                end

                local function lineInGoal(line, goal)
                    if not line or not goal then return false end
                    local lr = (line.Rotation or 0) % 360
                    local gr = (goal.Rotation or 0) % 360
                    local gs = (gr + 104) % 360
                    local ge = (gr + 114) % 360
                    if gs > ge then
                        return lr >= gs or lr <= ge
                    else
                        return lr >= gs and lr <= ge
                    end
                end

                local skillGui  = pg:WaitForChild("SkillCheckPromptGui", 10)
                if not skillGui then return end
                local check = skillGui:WaitForChild("Check", 10)
                if not check then return end
                local line = check:WaitForChild("Line", 10)
                local goal = check:WaitForChild("Goal", 10)
                if not line or not goal then return end

                local hbConn = nil
                local function stopHb()
                    if hbConn then hbConn:Disconnect(); hbConn = nil end
                end

                local function startHb()
                    stopHb()
                    hbConn = RunService.Heartbeat:Connect(function()
                        if not autoSkill then stopHb(); return end
                        if not check.Visible then stopHb(); return end
                        if lineInGoal(line, goal) then
                            pressSpace()
                            stopHb()
                        end
                    end)
                end

                check:GetPropertyChangedSignal("Visible"):Connect(function()
                    if not autoSkill then return end
                    if check.Visible then
                        startHb()
                    else
                        stopHb()
                    end
                end)

                if check.Visible then startHb() end

                while autoSkill do task.wait(0.1) end
                stopHb()
            end)
        end,
    })
end

do
    local autoRevive = false
    local s = SurTab:AddSection("Self Heal")
    s:AddToggle({
        Title    = "Auto Self Revive (saat knock)",
        Default  = false,
        Callback = function(v)
            autoRevive = v
            if v then
                Notify("Auto Revive", "Aktif! Bangun otomatis saat knock.")
                task.spawn(function()
                    while autoRevive do
                        local char = LocalPlayer.Character
                        local hum = char and char:FindFirstChildOfClass("Humanoid")
                        local root = char and char:FindFirstChild("HumanoidRootPart")
                        local isKnocked = hum and (hum.Health < 50 or hum:GetState() == Enum.HumanoidStateType.FallingDown)
                        if isKnocked then
                            pcall(function() hum.Health = hum.MaxHealth end)
                            pcall(function() hum:SetStateEnabled(Enum.HumanoidStateType.FallingDown, false) end)
                            pcall(function() hum:ChangeState(Enum.HumanoidStateType.GettingUp) end)
                            if root then pcall(function() root:SetAttribute("Crouchingserver", false) end) end
                            pcall(function() ReplicatedStorage.Remotes.Collision.EnableCollision:FireServer() end)
                            pcall(function() ReplicatedStorage.Remotes.Mechanics.Status.ChangeAttribute:FireServer("Crouchingserver", false) end)
                            pcall(function() ReplicatedStorage.Remotes.EmoteHandler:FireServer("StopEmote") end)
                            pcall(function() ReplicatedStorage.Remotes.Healing.Reset:FireServer(LocalPlayer) end)
                        end
                        task.wait(0.5)
                    end
                end)
            else
                Notify("Auto Revive", "Dimatikan.")
            end
        end,
    })

    s:AddButton({
        Title    = "Instant Full Heal (Self)",
        Callback = function()
            local char = LocalPlayer.Character; if not char then return end
            local hum = char:FindFirstChildOfClass("Humanoid")
            local root = char:FindFirstChild("HumanoidRootPart")
            pcall(function() if hum then hum.Health = hum.MaxHealth end end)
            pcall(function() if hum then hum:ChangeState(Enum.HumanoidStateType.GettingUp) end end)
            if root then pcall(function() root:SetAttribute("Crouchingserver", false) end) end
            pcall(function() ReplicatedStorage.Remotes.Collision.EnableCollision:FireServer() end)
            pcall(function() ReplicatedStorage.Remotes.Healing.Reset:FireServer(LocalPlayer) end)
            Notify("Heal", "Full Heal + Fix Knock!")
        end,
    })

    s:AddButton({
        Title    = "Revive Player Terdekat",
        Callback = function()
            local root = GetRoot(); if not root then return end
            local closest, closestDist = nil, math.huge
            for _, pl in ipairs(Players:GetPlayers()) do
                if pl ~= LocalPlayer and pl.Character then
                    local tr = pl.Character:FindFirstChild("HumanoidRootPart")
                    local th = pl.Character:FindFirstChildOfClass("Humanoid")
                    if tr and th and th.Health < th.MaxHealth and th.Health > 0 then
                        local d = (tr.Position - root.Position).Magnitude
                        if d < closestDist then closestDist = d; closest = pl end
                    end
                end
            end
            if closest and closest.Character then
                local tr = closest.Character:FindFirstChild("HumanoidRootPart")
                local th = closest.Character:FindFirstChildOfClass("Humanoid")
                if tr and th then
                    local isDowned = (th.Health / th.MaxHealth) < 0.5
                    pcall(function() ReplicatedStorage.Remotes.Healing.HealEvent:FireServer(tr, isDowned) end)
                    Notify("Heal", "Heal ke " .. closest.Name .. "!")
                end
            else
                Notify("Heal", "Tidak ada player yang butuh heal.")
            end
        end,
    })
end

do
    local s = SurTab:AddSection("Bypass Gate")
    s:AddToggle({
        Title    = "Bypass Gate",
        Default  = false,
        Callback = function(v)
            for _, folder in pairs(getMapFolders()) do
                local gate = folder:FindFirstChild("Gate")
                if gate then
                    local lg = gate:FindFirstChild("LeftGate")
                    local rg = gate:FindFirstChild("RightGate")
                    local bx = gate:FindFirstChild("Box")
                    if v then
                        if lg then lg.Transparency = 1; lg.CanCollide = false end
                        if rg then rg.Transparency = 1; rg.CanCollide = false end
                        if bx then bx.CanCollide = false end
                    else
                        if lg then lg.Transparency = 0; lg.CanCollide = true end
                        if rg then rg.Transparency = 0; rg.CanCollide = true end
                        if bx then bx.CanCollide = true end
                    end
                end
            end
        end,
    })

    s:AddButton({
        Title    = "Beat Game (Auto Escape)",
        Callback = function()
            task.spawn(function()
                local root = GetRoot(); if not root then return end
                for _, folder in pairs(getMapFolders()) do
                    for _, obj in pairs(folder:GetChildren()) do
                        if obj.Name == "Gate" then
                            local bp = obj.PrimaryPart or obj:FindFirstChildWhichIsA("BasePart")
                            if bp then pcall(function() root.CFrame = CFrame.new(bp.Position + Vector3.new(0, 5, 0)) end) end
                            break
                        end
                    end
                end
                for i = 1, 10 do
                    pcall(function() ReplicatedStorage.Remotes.Game.PlayerActionEvent:FireServer("ESCAPED", 200) end)
                    task.wait(0.2)
                end
            end)
            Notify("Beat", "Auto Escape dijalankan!")
        end,
    })
end

local KillerTab = Win:AddTab({ Name = "Killer", Icon = "boss" })
do
    local killAll = false
    local s = KillerTab:AddSection("Kill All Instant")
    s:AddToggle({
        Title    = "Kill All (Warning: Bisa Ban)",
        Default  = false,
        Callback = function(v)
            killAll = v
            if v then
                task.spawn(function()
                    local remote = ReplicatedStorage:WaitForChild("Remotes"):WaitForChild("Attacks"):WaitForChild("BasicAttack")
                    while killAll do
                        local root = GetRoot()
                        if root then
                            for _, plr in ipairs(Players:GetPlayers()) do
                                if plr ~= LocalPlayer and plr.Character then
                                    local tr = plr.Character:FindFirstChild("HumanoidRootPart")
                                    if tr then
                                        root.CFrame = tr.CFrame * CFrame.new(0, 0, 2)
                                        pcall(function() remote:FireServer() end)
                                        task.wait(0.15)
                                    end
                                end
                            end
                        end
                        task.wait(0.2)
                    end
                end)
            end
        end,
    })
end

do
    local autoAttack = false
    local attackRange = 12
    local s = KillerTab:AddSection("Auto Attack")
    s:AddToggle({
        Title    = "Auto Attack (No Animation)",
        Default  = false,
        Callback = function(v)
            autoAttack = v
            if v then
                task.spawn(function()
                    local remote = ReplicatedStorage:WaitForChild("Remotes"):WaitForChild("Attacks"):WaitForChild("BasicAttack")
                    while autoAttack do
                        local root = GetRoot()
                        if root then
                            for _, pl in ipairs(Players:GetPlayers()) do
                                if pl ~= LocalPlayer and pl.Character then
                                    local tr = pl.Character:FindFirstChild("HumanoidRootPart")
                                    local hum = pl.Character:FindFirstChildOfClass("Humanoid")
                                    if tr and hum and hum.Health > 0 then
                                        if (tr.Position - root.Position).Magnitude <= attackRange then
                                            pcall(function() remote:FireServer(false) end)
                                            break
                                        end
                                    end
                                end
                            end
                        end
                        task.wait(0.1)
                    end
                end)
            end
        end,
    })
    s:AddInput({ Title = "Attack Range (studs)", Default = "12", Callback = function(v) local n = tonumber(v); if n then attackRange = n end end })
end

do
    local hitboxEnabled = false
    local hitboxSize = 15
    local origSizes = {}
    local s = KillerTab:AddSection("Hitbox")
    s:AddToggle({
        Title    = "Expand Hitbox Survivor",
        Default  = false,
        Callback = function(v)
            hitboxEnabled = v
            if not v then
                for pl, sz in pairs(origSizes) do
                    if pl and pl.Character then
                        local r = pl.Character:FindFirstChild("HumanoidRootPart")
                        if r then r.Size = sz; r.Transparency = 1; r.CanCollide = true end
                    end
                end
                origSizes = {}
            else
                task.spawn(function()
                    while hitboxEnabled do
                        for _, pl in ipairs(Players:GetPlayers()) do
                            if pl ~= LocalPlayer and pl.Character then
                                local r = pl.Character:FindFirstChild("HumanoidRootPart")
                                local hum = pl.Character:FindFirstChildOfClass("Humanoid")
                                if r and hum and hum.Health > 0 then
                                    if not origSizes[pl] then origSizes[pl] = r.Size end
                                    r.Size = Vector3.new(hitboxSize, hitboxSize, hitboxSize)
                                    r.CanCollide = false; r.Transparency = 0.7
                                end
                            end
                        end
                        task.wait(0.1)
                    end
                end)
            end
        end,
    })
    s:AddInput({ Title = "Hitbox Size", Default = "15", Callback = function(v) local n = tonumber(v); if n then hitboxSize = n end end })
end

do
    local s = KillerTab:AddSection("Map Destruction [BETA]")
    s:AddToggle({
        Title    = "Auto Destroy Pallets",
        Default  = false,
        Callback = function(v)
            if v then
                task.spawn(function()
                    local destroyPallets = v
                    while destroyPallets do
                        pcall(function()
                            local j = ReplicatedStorage.Remotes.Pallet.Jason
                            local dg = j and j:FindFirstChild("Destroy-Global")
                            if dg then dg:FireServer() end
                        end)
                        task.wait(1.5)
                    end
                end)
            end
        end,
    })

    s:AddToggle({
        Title    = "Auto Break Generator",
        Default  = false,
        Callback = function(v)
            if v then
                task.spawn(function()
                    local breakGen = v
                    while breakGen do
                        pcall(function()
                            local be = ReplicatedStorage.Remotes.Generator.BreakGenEvent
                            local map = Workspace:FindFirstChild("Map"); if not (be and map) then return end
                            for _, obj in ipairs(map:GetDescendants()) do
                                if obj:IsA("BasePart") and obj.Name:find("GeneratorPoint") then
                                    task.spawn(function() pcall(function() be:FireServer(obj) end) end)
                                end
                            end
                        end)
                        task.wait(0.8)
                    end
                end)
            end
        end,
    })

    s:AddButton({
        Title    = "Break All Generator (Sekali)",
        Callback = function()
            pcall(function()
                local be = ReplicatedStorage.Remotes.Generator.BreakGenEvent
                local map = Workspace:FindFirstChild("Map"); if not (be and map) then return end
                for _, obj in ipairs(map:GetDescendants()) do
                    if obj:IsA("BasePart") and obj.Name:find("GeneratorPoint") then
                        task.spawn(function() pcall(function() be:FireServer(obj) end) end)
                    end
                end
            end)
            Notify("Destroy", "Semua Generator dihancurkan!")
        end,
    })
end

do
    local noFlashlight = false
    local s = KillerTab:AddSection("Killer Utility")
    s:AddToggle({
        Title    = "No Flashlight (Anti Blind)",
        Default  = false,
        Callback = function(v)
            noFlashlight = v
            if v then
                task.spawn(function()
                    while noFlashlight do
                        local pg = LocalPlayer:FindFirstChild("PlayerGui")
                        if pg then
                            for _, d in pairs(pg:GetDescendants()) do
                                if d:IsA("GuiObject") and d.Name == "Blind" then d:Destroy() end
                            end
                        end
                        task.wait(0.5)
                    end
                end)
            end
        end,
    })
    s:AddButton({
        Title    = "Fix Camera (3rd Person)",
        Callback = function()
            local char = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
            local hum = char:FindFirstChildOfClass("Humanoid")
            if hum then
                local cam = Workspace.CurrentCamera
                cam.CameraType = Enum.CameraType.Custom
                cam.CameraSubject = hum
                LocalPlayer.CameraMinZoomDistance = 0.5
                LocalPlayer.CameraMaxZoomDistance = 400
                LocalPlayer.CameraMode = Enum.CameraMode.Classic
            end
        end,
    })
end

local EspTab = Win:AddTab({ Name = "ESP", Icon = "eyes" })
do
    local espEnabled   = false
    local espSurvivor  = false
    local espMurder    = false
    local espGenerator = false
    local espGate      = false
    local espHook      = false
    local espPallet    = false
    local ShowName     = false  
    local ShowDistance = false 
    local ShowHP       = false 
    local ShowHL       = false  
    local espObjects   = {}
    local C_SUR  = Color3.fromRGB(255, 255, 255)
    local C_KIL  = Color3.fromRGB(255, 50, 50)
    local C_GEN  = Color3.fromRGB(255, 255, 255)
    local C_GATE = Color3.fromRGB(200, 200, 200)
    local C_HOOK = Color3.fromRGB(255, 80, 80)
    local C_PAL  = Color3.fromRGB(255, 220, 0)
    local function removeESP(obj)
        if espObjects[obj] then
            local d = espObjects[obj]
            if d.highlight then d.highlight:Destroy() end
            if d.bill then d.bill:Destroy() end
            espObjects[obj] = nil
        end
    end
    local function createESP(obj, color)
        if not obj or obj.Name == "Lobby" then return end
        if espObjects[obj] then
            if espObjects[obj].highlight then
                espObjects[obj].highlight.FillColor = color
                espObjects[obj].highlight.OutlineColor = color
            end
            return
        end
        local hl = Instance.new("Highlight")
        hl.Adornee = obj
        hl.FillColor = color
        hl.FillTransparency = 0.8
        hl.OutlineColor = color
        hl.OutlineTransparency = 0.1
        hl.Enabled = ShowHL
        hl.Parent = obj
        local bill = Instance.new("BillboardGui")
        bill.Size = UDim2.new(0, 200, 0, 60)
        bill.Adornee = obj
        bill.AlwaysOnTop = true
        bill.StudsOffsetWorldSpace = Vector3.new(0, 4, 0)  -- digeser ke atas karakter
        bill.Parent = obj
        local frame = Instance.new("Frame", bill)
        frame.Size = UDim2.new(1, 0, 1, 0)
        frame.BackgroundTransparency = 1
        local layout = Instance.new("UIListLayout", frame)
        layout.FillDirection = Enum.FillDirection.Vertical
        layout.HorizontalAlignment = Enum.HorizontalAlignment.Center
        layout.VerticalAlignment = Enum.VerticalAlignment.Top
        layout.Padding = UDim.new(0, 2)
        local function mkLabel()
            local l = Instance.new("TextLabel", frame)
            l.Size = UDim2.new(1, 0, 0, 18)
            l.BackgroundTransparency = 1
            l.Font = Enum.Font.SourceSansBold
            l.TextSize = 14
            l.TextColor3 = color
            l.TextStrokeTransparency = 0
            l.TextXAlignment = Enum.TextXAlignment.Center
            return l
        end
        local nameLbl = mkLabel(); nameLbl.Text = obj.Name; nameLbl.Visible = ShowName
        local hpLbl   = mkLabel(); hpLbl.Text = "";         hpLbl.Visible = ShowHP
        local dstLbl  = mkLabel(); dstLbl.Text = "";        dstLbl.Visible = ShowDistance
        espObjects[obj] = {
            highlight = hl,
            bill = bill,
            nameLbl = nameLbl,
            hpLbl = hpLbl,
            dstLbl = dstLbl,
            color = color
        }
    end
    local lastUp = 0
    RunService.RenderStepped:Connect(function(dt)
        lastUp = lastUp + dt
        if lastUp < 0.5 then return end; lastUp = 0
        if not espEnabled then return end
        local hrp = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
        if not hrp then return end
        for _, pl in pairs(Players:GetPlayers()) do
            if pl.Character and pl.Character ~= LocalPlayer.Character and pl.Character.Name ~= "Lobby" then
                local isMurder = pl.Character:FindFirstChild("Weapon") ~= nil
                if isMurder then
                    if espMurder then createESP(pl.Character, C_KIL) else removeESP(pl.Character) end
                else
                    if espSurvivor then createESP(pl.Character, C_SUR) else removeESP(pl.Character) end
                end
            end
        end
        for _, folder in pairs(getMapFolders()) do
            for _, obj in pairs(folder:GetChildren()) do
                if obj.Name == "Generator" then
                    if espGenerator then createESP(obj, C_GEN) else removeESP(obj) end
                elseif obj.Name == "Gate" then
                    if espGate then createESP(obj, C_GATE) else removeESP(obj) end
                elseif obj.Name == "Hook" then
                    local mdl = obj:FindFirstChild("Model")
                    if mdl then if espHook then createESP(mdl, C_HOOK) else removeESP(mdl) end end
                elseif obj.Name == "Pallet" or obj.Name == "Palletwrong" then
                    if espPallet then createESP(obj, C_PAL) else removeESP(obj) end
                end
            end
        end
        for obj, data in pairs(espObjects) do
            if obj and obj.Parent then
                local tp = obj:FindFirstChild("HumanoidRootPart") or obj.PrimaryPart or obj:FindFirstChildWhichIsA("BasePart")
                if tp then
                    local hum = obj:FindFirstChildOfClass("Humanoid")
                    data.nameLbl.Visible = ShowName
                    if data.highlight then data.highlight.Enabled = ShowHL end
                    if hum then
                        data.hpLbl.Text = ShowHP and ("[ "..math.floor(hum.Health).." HP ]") or ""
                        data.hpLbl.Visible = ShowHP
                    end
                    local d = math.floor((hrp.Position - tp.Position).Magnitude)
                    data.dstLbl.Text = ShowDistance and ("[ "..d.." MM ]") or ""
                    data.dstLbl.Visible = ShowDistance
                end
            else
                removeESP(obj)
            end
        end
    end)
    Players.PlayerRemoving:Connect(function(pl)
        if pl.Character then removeESP(pl.Character) end
    end)
    local s1 = EspTab:AddSection("Enable ESP")
    s1:AddToggle({ Title = "Enable ESP", Default = false, Callback = function(v)
        espEnabled = v
        if not v then for obj in pairs(espObjects) do removeESP(obj) end end
    end })
    local s2 = EspTab:AddSection("ESP Role")
    s2:AddToggle({ Title = "ESP Survivor", Default = false, Callback = function(v) espSurvivor = v end })
    s2:AddToggle({ Title = "ESP Killer",   Default = false, Callback = function(v) espMurder = v end })
    local s3 = EspTab:AddSection("ESP Object")
    s3:AddToggle({ Title = "ESP Generator", Default = false, Callback = function(v) espGenerator = v end })
    s3:AddToggle({ Title = "ESP Gate",      Default = false, Callback = function(v) espGate = v end })
    s3:AddToggle({ Title = "ESP Hook",      Default = false, Callback = function(v) espHook = v end })
    s3:AddToggle({ Title = "ESP Pallet",    Default = false, Callback = function(v) espPallet = v end })
    local s4 = EspTab:AddSection("ESP Settings")
    s4:AddToggle({ Title = "Show Name",      Default = false, Callback = function(v) ShowName = v end })     
    s4:AddToggle({ Title = "Show Distance",  Default = false, Callback = function(v) ShowDistance = v end }) 
    s4:AddToggle({ Title = "Show Health",    Default = false, Callback = function(v) ShowHP = v end })       
    s4:AddToggle({ Title = "Show Highlight", Default = false, Callback = function(v) ShowHL = v end })      
end

local AimTab = Win:AddTab({ Name = "Aimbot", Icon = "crosshair" })
do
    local aimEnabled       = false
    local aimUseRMB        = false
    local aimFOV           = 120
    local aimSmooth        = 0.3
    local aimPredict       = false
    local aimShowFOV       = false
    local aimShowCrosshair = false
    local aimHolding       = false
    local aimShowLine      = false
    local fovCircle        = nil
    local fovCircConn      = nil
    local aimBeam          = nil
    local aimAttachFrom    = nil
    local aimAttachTo      = nil
    local beamUpdateConn   = nil
    local BULLET_SPEED     = 200
    local BULLET_GRAVITY   = 0

    local Players          = game:GetService("Players")
    local LocalPlayer      = Players.LocalPlayer
    local RunService       = game:GetService("RunService")
    local UserInputService = game:GetService("UserInputService")

    local crosshair = {
        top    = Drawing.new("Line"),
        bottom = Drawing.new("Line"),
        left   = Drawing.new("Line"),
        right  = Drawing.new("Line"),
        dot    = Drawing.new("Circle"),
    }
    local CH_SIZE  = 10
    local CH_GAP   = 4
    local CH_THICK = 2

    local function setupCrosshairLine(line)
        line.Thickness = CH_THICK
        line.Color     = Color3.fromRGB(255, 255, 255)
        line.Visible   = false
    end
    local function setupCrosshairDot(dot)
        dot.Radius   = 2
        dot.Color    = Color3.fromRGB(255, 255, 255)
        dot.Filled   = true
        dot.NumSides = 16
        dot.Visible  = false
    end
    for _, name in ipairs({"top","bottom","left","right"}) do
        setupCrosshairLine(crosshair[name])
    end
    setupCrosshairDot(crosshair.dot)

    local function hideCrosshair()
        for _, v in pairs(crosshair) do v.Visible = false end
    end
    local function updateCrosshair(cx, cy, onTarget)
        if not aimShowCrosshair then hideCrosshair() return end
        local color = onTarget and Color3.fromRGB(255, 50, 50) or Color3.fromRGB(255, 255, 255)
        for _, name in ipairs({"top","bottom","left","right"}) do
            crosshair[name].Color = color
        end
        crosshair.dot.Color    = color
        crosshair.top.From     = Vector2.new(cx, cy - CH_GAP - CH_SIZE)
        crosshair.top.To       = Vector2.new(cx, cy - CH_GAP)
        crosshair.bottom.From  = Vector2.new(cx, cy + CH_GAP)
        crosshair.bottom.To    = Vector2.new(cx, cy + CH_GAP + CH_SIZE)
        crosshair.left.From    = Vector2.new(cx - CH_GAP - CH_SIZE, cy)
        crosshair.left.To      = Vector2.new(cx - CH_GAP, cy)
        crosshair.right.From   = Vector2.new(cx + CH_GAP, cy)
        crosshair.right.To     = Vector2.new(cx + CH_GAP + CH_SIZE, cy)
        crosshair.dot.Position = Vector2.new(cx, cy)
        for _, v in pairs(crosshair) do v.Visible = true end
    end

    local function createAimLine()
        pcall(function()
            if aimBeam       then aimBeam:Destroy()       end
            if aimAttachFrom then aimAttachFrom:Destroy() end
            if aimAttachTo   then aimAttachTo:Destroy()   end
            aimBeam, aimAttachFrom, aimAttachTo = nil, nil, nil
        end)
        if not aimShowLine or not aimEnabled then return end
        pcall(function()
            local char = LocalPlayer.Character
            local hrp  = char and char:FindFirstChild("HumanoidRootPart")
            if not hrp then return end
            local attFrom      = Instance.new("Attachment")
            attFrom.Name       = "AimFrom"
            attFrom.Position   = Vector3.new(0, -2.8, 0)
            attFrom.Parent     = hrp
            aimAttachFrom      = attFrom
            local attTo        = Instance.new("Attachment")
            attTo.Name         = "AimTo"
            attTo.Position     = Vector3.new(0, 0, 0)
            attTo.Parent       = workspace.Terrain
            aimAttachTo        = attTo
            local beam         = Instance.new("Beam")
            beam.Name          = "AimBeam"
            beam.Attachment0   = attFrom
            beam.Attachment1   = attTo
            beam.Color         = ColorSequence.new(Color3.fromRGB(0, 255, 0))
            beam.Width0        = 0.08
            beam.Width1        = 0.08
            beam.FaceCamera    = true
            beam.Transparency  = NumberSequence.new(0)
            beam.LightEmission = 1
            beam.LightInfluence= 0
            beam.TextureLength = 1
            beam.Segments      = 1
            beam.Enabled       = true
            beam.Parent        = hrp
            aimBeam            = beam
        end)
    end
    local function updateAimLine(fromPos, toPos)
        if not aimAttachTo then return end
        pcall(function()
            local groundY = fromPos.Y - 2.8
            aimAttachTo.WorldPosition = Vector3.new(toPos.X, groundY, toPos.Z)
        end)
    end
    local function hideAimLine()
        pcall(function() if aimBeam then aimBeam.Enabled = false end end)
    end
    local function showAimLine()
        pcall(function() if aimBeam then aimBeam.Enabled = true end end)
    end
    local function cleanupAimLine()
        pcall(function() if aimBeam       then aimBeam:Destroy()       end end)
        pcall(function() if aimAttachFrom then aimAttachFrom:Destroy() end end)
        pcall(function() if aimAttachTo   then aimAttachTo:Destroy()   end end)
        aimBeam, aimAttachFrom, aimAttachTo = nil, nil, nil
    end

    local function IsKiller(plr)
        return plr and plr.Team and plr.Team.Name == "Killer"
    end

    local function GetTargetPosition(character)
        local head = character:FindFirstChild("Head")
        if head then return head.Position end
        local hrp = character:FindFirstChild("HumanoidRootPart")
        if hrp then return hrp.Position end
        local torso = character:FindFirstChild("Torso") or character:FindFirstChild("UpperTorso")
        if torso then return torso.Position end
        return nil
    end

    local function GetPredictedPosition(target, rawPos)
        if aimPredict then
            local root = target.Character and target.Character:FindFirstChild("HumanoidRootPart")
            if root then
                local cam        = workspace.CurrentCamera
                local dist       = cam and (cam.CFrame.Position - rawPos).Magnitude or 50
                local travelTime = dist / BULLET_SPEED
                local vel        = root.AssemblyLinearVelocity
                local predicted  = rawPos + vel * travelTime
                predicted = predicted + Vector3.new(0, -BULLET_GRAVITY * travelTime * travelTime * 0.5, 0)
                return predicted
            end
        end
        return rawPos
    end

    local function GetClosestTarget(cam, screenCenter)
        local closest, closestDist = nil, math.huge
        for _, pl in ipairs(Players:GetPlayers()) do
            if pl ~= LocalPlayer and IsKiller(pl) and pl.Character then
                local hum = pl.Character:FindFirstChildOfClass("Humanoid")
                if hum and hum.Health > 0 then
                    local pos = GetTargetPosition(pl.Character)
                    if pos then
                        local screen, onScreen = cam:WorldToViewportPoint(pos)
                        if onScreen and screen.Z > 0 then
                            local d2D = (Vector2.new(screen.X, screen.Y) - screenCenter).Magnitude
                            if d2D <= aimFOV and d2D < closestDist then
                                closestDist = d2D
                                closest     = pl
                            end
                        end
                    end
                end
            end
        end
        return closest
    end

    local function setupFOVCircle()
        if fovCircConn then fovCircConn:Disconnect(); fovCircConn = nil end
        pcall(function() if fovCircle then fovCircle:Remove() end end)
        fovCircle = nil
        if not aimShowFOV or not aimEnabled then return end
        pcall(function()
            fovCircle           = Drawing.new("Circle")
            fovCircle.Radius    = aimFOV
            fovCircle.Color     = Color3.fromRGB(255, 255, 255)
            fovCircle.Thickness = 2
            fovCircle.Filled    = false
            fovCircle.NumSides  = 64
            local vp            = workspace.CurrentCamera.ViewportSize
            fovCircle.Position  = Vector2.new(vp.X / 2, vp.Y / 2)
            fovCircle.Visible   = true
            fovCircConn = RunService.RenderStepped:Connect(function()
                if not fovCircle then return end
                pcall(function()
                    local vp2          = workspace.CurrentCamera.ViewportSize
                    fovCircle.Position = Vector2.new(vp2.X / 2, vp2.Y / 2)
                end)
            end)
        end)
    end

    local function startBeamUpdate()
        if beamUpdateConn then beamUpdateConn:Disconnect(); beamUpdateConn = nil end
        beamUpdateConn = RunService.Heartbeat:Connect(function()
            if not aimEnabled or not aimShowLine then return end
            local cam = workspace.CurrentCamera
            if not cam then return end
            local screenCenter = Vector2.new(cam.ViewportSize.X / 2, cam.ViewportSize.Y / 2)
            local target = GetClosestTarget(cam, screenCenter)
            if target and target.Character then
                local rawPos = GetTargetPosition(target.Character)
                if rawPos then
                    local char = LocalPlayer.Character
                    local hrp  = char and char:FindFirstChild("HumanoidRootPart")
                    if hrp then
                        if not aimBeam or not aimBeam.Parent then createAimLine() end
                        showAimLine()
                        updateAimLine(hrp.Position, GetPredictedPosition(target, rawPos))
                    end
                end
            else
                hideAimLine()
            end
        end)
    end

    local function cleanupAimbot()
        if fovCircConn    then fovCircConn:Disconnect();    fovCircConn    = nil end
        if beamUpdateConn then beamUpdateConn:Disconnect(); beamUpdateConn = nil end
        pcall(function() if fovCircle then fovCircle:Remove() end end)
        fovCircle  = nil
        aimHolding = false
        cleanupAimLine()
    end

    LocalPlayer.CharacterAdded:Connect(function()
        task.wait(1)
        if aimEnabled and aimShowLine then
            createAimLine()
        end
    end)

    UserInputService.InputBegan:Connect(function(inp, gpe)
        if not aimEnabled or not aimUseRMB then return end
        if inp.UserInputType == Enum.UserInputType.MouseButton2 and not gpe then
            aimHolding = true
        elseif inp.UserInputType == Enum.UserInputType.Touch and not gpe then
            aimHolding = true
        end
    end)
    UserInputService.InputEnded:Connect(function(inp)
        if not aimEnabled or not aimUseRMB then return end
        if inp.UserInputType == Enum.UserInputType.MouseButton2
        or inp.UserInputType == Enum.UserInputType.Touch then
            aimHolding = false
        end
    end)

    RunService.RenderStepped:Connect(function()
        local cam = workspace.CurrentCamera
        if not cam then hideCrosshair(); return end
        local vp           = cam.ViewportSize
        local cx, cy       = vp.X / 2, vp.Y / 2
        local screenCenter = Vector2.new(cx, cy)
        local onTarget     = false

        if aimEnabled then
            for _, pl in ipairs(Players:GetPlayers()) do
                if pl ~= LocalPlayer and IsKiller(pl) and pl.Character then
                    local pos = GetTargetPosition(pl.Character)
                    if pos then
                        local screen, onScreen = cam:WorldToViewportPoint(pos)
                        if onScreen and screen.Z > 0 then
                            local d = (Vector2.new(screen.X, screen.Y) - screenCenter).Magnitude
                            if d < 30 then onTarget = true; break end
                        end
                    end
                end
            end
        end

        updateCrosshair(cx, cy, onTarget)
        if not aimEnabled then return end
        if aimUseRMB and not aimHolding then return end

        local target = GetClosestTarget(cam, screenCenter)
        if target and target.Character then
            local rawPos = GetTargetPosition(target.Character)
            if rawPos then
                local pos = GetPredictedPosition(target, rawPos)
                pcall(function()
                    local targetCF = CFrame.new(cam.CFrame.Position, pos)
                    local smooth   = aimHolding
                        and math.clamp(aimSmooth * 3, 0.5, 1)
                        or  math.clamp(aimSmooth, 0.05, 1)
                    cam.CFrame = cam.CFrame:Lerp(targetCF, smooth)
                end)
            end
        end
    end)

    local s1 = AimTab:AddSection("Camera Aimbot")

    s1:AddToggle({
        Title    = "Enable Aimbot",
        Default  = false,
        Callback = function(v)
            aimEnabled = v
            cleanupAimbot()
            if not v then hideCrosshair(); hideAimLine(); return end
            setupFOVCircle()
            createAimLine()
            startBeamUpdate()
        end,
    })
    s1:AddToggle({
        Title    = "Hold RMB to Aim",
        Default  = false,
        Callback = function(v) aimUseRMB = v end,
    })
    s1:AddToggle({
        Title    = "Show FOV Circle",
        Default  = false,
        Callback = function(v)
            aimShowFOV = v
            setupFOVCircle()
        end,
    })
    s1:AddToggle({
        Title    = "Show Crosshair",
        Default  = false,
        Callback = function(v)
            aimShowCrosshair = v
            if not v then hideCrosshair() end
        end,
    })
    s1:AddToggle({
        Title    = "Show Aim Line (3D)",
        Default  = false,
        Callback = function(v)
            aimShowLine = v
            if not v then
                hideAimLine()
            elseif aimEnabled then
                createAimLine()
                startBeamUpdate()
            end
        end,
    })
    s1:AddToggle({
        Title    = "Prediction",
        Default  = false,
        Callback = function(v) aimPredict = v end,
    })
    s1:AddInput({
        Title    = "FOV Radius (pixels)",
        Default  = "120",
        Callback = function(v)
            local n = tonumber(v)
            if not n then return end
            aimFOV = n
            pcall(function() if fovCircle then fovCircle.Radius = n end end)
        end,
    })
    s1:AddInput({
        Title    = "Smooth (0.05 - 1.0)",
        Default  = "0.3",
        Callback = function(v)
            local n = tonumber(v)
            if not n then return end
            aimSmooth = math.clamp(n, 0.05, 1)
        end,
    })
    s1:AddInput({
        Title    = "Bullet Speed (stud/s)",
        Default  = "200",
        Callback = function(v)
            local n = tonumber(v)
            if not n then return end
            BULLET_SPEED = n
        end,
    })
end

do
    local spearSmooth = 0.5
    local spearRange  = 150
    local spearSpeed  = 100
    local spearGMult  = 1
    local spearConn   = nil
    local s2 = AimTab:AddSection("Spear Aimbot [BETA]")
    s2:AddToggle({
        Title    = "Enable Spear Aimbot",
        Default  = false,
        Callback = function(v)
            if spearConn then spearConn:Disconnect(); spearConn = nil end
            if not v then return end
            spearConn = RunService.RenderStepped:Connect(function()
                if not LocalPlayer.Team or LocalPlayer.Team.Name ~= "Killer" then return end
                local cam  = workspace.CurrentCamera
                local char = LocalPlayer.Character
                if not cam or not char then return end
                local root = char:FindFirstChild("HumanoidRootPart")
                if not root then return end
                local closest, closestDist = nil, math.huge
                for _, pl in Players:GetPlayers() do
                    if pl == LocalPlayer then continue end
                    if not pl.Team or pl.Team.Name ~= "Survivors" then continue end
                    if not pl.Character then continue end
                    local hum = pl.Character:FindFirstChildOfClass("Humanoid")
                    local tr  = pl.Character:FindFirstChild("HumanoidRootPart")
                    if not tr or not hum or hum.Health <= 0 then continue end
                    local isDowned = hum.Health <= 50
                        or hum:GetState() == Enum.HumanoidStateType.FallingDown
                        or hum:GetState() == Enum.HumanoidStateType.Ragdoll
                        or pl.Character:GetAttribute("IsCarried")
                    if isDowned then continue end
                    local dist = (tr.Position - root.Position).Magnitude
                    if dist > spearRange then continue end
                    local screenPos, onScreen = cam:WorldToViewportPoint(tr.Position)
                    if not onScreen then continue end
                    local vp         = cam.ViewportSize
                    local centerDist = (Vector2.new(screenPos.X, screenPos.Y) - vp / 2).Magnitude
                    if centerDist < closestDist then
                        closestDist = centerDist
                        closest     = pl
                    end
                end
                if not closest or not closest.Character then return end
                local tr = closest.Character:FindFirstChild("HumanoidRootPart")
                if not tr then return end
                local hrp      = root
                local spawnPos = hrp.Position + hrp.CFrame.LookVector * 3 + Vector3.new(0, 1.5, 0)
                local targetPos  = tr.Position + Vector3.new(0, 1, 0)
                local vel        = tr.AssemblyLinearVelocity
                local travelTime = (spawnPos - targetPos).Magnitude / spearSpeed
                for _ = 1, 3 do
                    local predicted = targetPos + Vector3.new(vel.X, 0, vel.Z) * travelTime
                    travelTime = (spawnPos - predicted).Magnitude / spearSpeed
                end
                local predicted  = targetPos + Vector3.new(vel.X, 0, vel.Z) * travelTime
                local gravDrop   = 0.5 * workspace.Gravity * spearGMult * travelTime * travelTime
                local aimPos     = predicted + Vector3.new(0, gravDrop, 0)
                local camPos   = cam.CFrame.Position
                local targetCF = CFrame.new(camPos, aimPos)
                cam.CFrame     = cam.CFrame:Lerp(targetCF, math.clamp(spearSmooth, 0.05, 1))
            end)
        end,
    })

    s2:AddInput({
        Title    = "Smooth (0.05 - 1.0)",
        Default  = "0.5",
        Callback = function(v)
            local n = tonumber(v)
            if n then spearSmooth = math.clamp(n, 0.05, 1) end
        end,
    })

    s2:AddInput({
        Title    = "Range (studs)",
        Default  = "150",
        Callback = function(v)
            local n = tonumber(v)
            if n then spearRange = n end
        end,
    })

    s2:AddInput({
        Title    = "Spear Speed",
        Default  = "100",
        Callback = function(v)
            local n = tonumber(v)
            if n then spearSpeed = n end
        end,
    })

    s2:AddInput({
        Title    = "Gravity Mult (default 1)",
        Default  = "1",
        Callback = function(v)
            local n = tonumber(v)
            if n then spearGMult = n end
        end,
    })
end

local SettingsTab = Win:AddTab({ Name = "Settings", Icon = "settings"})
do
    local speedValue = 4
    local originalWalkSpeed = nil
    local originalCanCollide = {}
    local noclipConnection = nil
    local PlayerFeatureSection = SettingsTab:AddSection("Player Utility")
    PlayerFeatureSection:AddInput({
        Title       = "Set Speed Value",
        Default     = "4",
        Callback    = function(val)
            local num = tonumber(val)
            if num then speedValue = num end
        end,
    })

    PlayerFeatureSection:AddToggle({
        Title    = "Enable Speed",
        Default  = false,
        NoSave   = true,
        Callback = function(v)
            local char = LocalPlayer.Character
            local hum  = char and char:FindFirstChildOfClass("Humanoid")
            if not hum then return end
            if v then
                originalWalkSpeed = hum.WalkSpeed
                hum.WalkSpeed     = speedValue
                speedConnection = hum:GetPropertyChangedSignal("WalkSpeed"):Connect(function()
                    if hum.WalkSpeed ~= speedValue then
                        hum.WalkSpeed = speedValue
                    end
                end)
            else
                if speedConnection then
                    speedConnection:Disconnect()
                    speedConnection = nil
                end
                hum.WalkSpeed     = originalWalkSpeed or 16
                originalWalkSpeed = nil
            end
        end,
    })

    PlayerFeatureSection:AddToggle({
        Title    = "No Clip",
        Default  = false,
        NoSave   = true,
        Callback = function(v)
            local char = LocalPlayer.Character
            if not char then return end
            if v then
                originalCanCollide = {}
                for _, part in char:GetDescendants() do
                    if part:IsA("BasePart") then
                        originalCanCollide[part] = part.CanCollide
                        part.CanCollide = false
                    end
                end
                noclipConnection = RunService.Stepped:Connect(function()
                    local c = LocalPlayer.Character
                    if not c then return end
                    for _, part in c:GetDescendants() do
                        if part:IsA("BasePart") then
                            part.CanCollide = false
                        end
                    end
                end)
            else
                if noclipConnection then
                    noclipConnection:Disconnect()
                    noclipConnection = nil
                end
                if char then
                    for _, part in char:GetDescendants() do
                        if part:IsA("BasePart") then
                            local orig = originalCanCollide[part]
                            part.CanCollide = orig ~= nil and orig or true
                        end
                    end
                end
                originalCanCollide = {}
            end
        end,
    })

    PlayerFeatureSection:AddToggle({
        Title    = "Moonwalk (badan ikut kamera)",
        Default  = false,
        Callback = function(v)
            if moonConn then moonConn:Disconnect(); moonConn = nil end
            local char = LocalPlayer.Character
            local hum  = char and char:FindFirstChildOfClass("Humanoid")
            if not v then
                if hum then hum.AutoRotate = true end
                return
            end
            if hum then hum.AutoRotate = false end
            moonConn = RunService.RenderStepped:Connect(function()
                local c = LocalPlayer.Character
                if not c then return end
                local hrp = c:FindFirstChild("HumanoidRootPart")
                if not hrp then return end
                local h = c:FindFirstChildOfClass("Humanoid")
                if h and h.AutoRotate then h.AutoRotate = false end
                local look = Workspace.CurrentCamera.CFrame.LookVector
                local flat = Vector3.new(look.X, 0, look.Z)
                if flat.Magnitude > 0.001 then
                    hrp.CFrame = CFrame.lookAt(hrp.Position, hrp.Position + flat.Unit)
                end
            end)
        end,
    })
    LocalPlayer.CharacterAdded:Connect(function(character)
        originalWalkSpeed  = nil
        originalCanCollide = {}

        if noclipConnection then
            noclipConnection:Disconnect()
            noclipConnection = nil
        end
    end)

    local defaultMaxZoom = LocalPlayer.CameraMaxZoomDistance
    PlayerFeatureSection:AddToggle({
        Title    = "Unlimited Zoom",
        Default  = false,
        Callback = function(v)
            if v then
                LocalPlayer.CameraMaxZoomDistance = 500
            else
                LocalPlayer.CameraMaxZoomDistance = defaultMaxZoom
            end
        end,
    })
end

do
    local fullBright = false
    local noFog = false
    local s = SettingsTab:AddSection("Visuals")
    s:AddToggle({
        Title    = "Full Bright",
        Default  = false,
        Callback = function(v)
            fullBright = v
            if v then
                task.spawn(function()
                    while fullBright do
                        Lighting.Brightness = 2; Lighting.ClockTime = 14
                        Lighting.Ambient = Color3.fromRGB(255, 255, 255)
                        task.wait(0.5)
                    end
                end)
            else
                Lighting.Brightness = 1; Lighting.ClockTime = 12
                Lighting.Ambient = Color3.fromRGB(128, 128, 128)
            end
        end,
    })
    s:AddToggle({
        Title    = "No Fog",
        Default  = false,
        Callback = function(v)
            noFog = v
            if v then
                task.spawn(function()
                    while noFog do
                        if Lighting:FindFirstChild("Atmosphere") then Lighting.Atmosphere.Density = 0 end
                        task.wait(0.5)
                    end
                end)
            else
                if Lighting:FindFirstChild("Atmosphere") then Lighting.Atmosphere.Density = 0.5 end
            end
        end,
    })
end

do
    local s = SettingsTab:AddSection("Performance")
    s:AddToggle({
        Title    = "Disable Particles",
        Default  = false,
        Callback = function(v)
            for _, obj in ipairs(Workspace:GetDescendants()) do
                if obj:IsA("ParticleEmitter") or obj:IsA("Trail") or obj:IsA("Beam") then obj.Enabled = not v end
            end
        end,
    })
    s:AddToggle({
        Title    = "Lower Graphics",
        Default  = false,
        Callback = function(v)
            pcall(function() settings().Rendering.QualityLevel = v and Enum.QualityLevel.Level01 or Enum.QualityLevel.Automatic end)
        end,
    })
    s:AddToggle({
        Title    = "Disable Shadows",
        Default  = false,
        Callback = function(v) Lighting.GlobalShadows = not v end,
    })
    s:AddToggle({
        Title    = "FPS Counter",
        Default  = false,
        Callback = function(v)
            local existing = LocalPlayer.PlayerGui:FindFirstChild("VD_FPS")
            if existing then existing:Destroy() end
            if not v then return end
            local theme = {
                Good = Color3.fromRGB(80,  255, 140),
                Warn = Color3.fromRGB(255, 220, 90),
                Bad  = Color3.fromRGB(255, 90,  90),
            }
            local sg = Instance.new("ScreenGui")
            sg.Name           = "VD_FPS"
            sg.ResetOnSpawn   = false
            sg.DisplayOrder   = 999999
            sg.IgnoreGuiInset = true
            sg.Parent         = LocalPlayer.PlayerGui
            local container = Instance.new("Frame")
            container.Size                   = UDim2.new(0, 0, 0, 30)
            container.Position  = UDim2.new(0.5, 0, 0, 14)
            container.AnchorPoint = Vector2.new(0.5, 0)
            container.AutomaticSize          = Enum.AutomaticSize.X
            container.BackgroundColor3       = Color3.fromRGB(18, 8, 2)
            container.BackgroundTransparency = 0.45
            container.BorderSizePixel        = 0
            container.Parent                 = sg
            Instance.new("UICorner", container).CornerRadius = UDim.new(1, 0)
            local grad = Instance.new("UIGradient")
            grad.Color = ColorSequence.new{
                ColorSequenceKeypoint.new(0,    Color3.fromRGB(8,  4,  1)),
                ColorSequenceKeypoint.new(0.25, Color3.fromRGB(30, 12, 2)),
                ColorSequenceKeypoint.new(0.5,  Color3.fromRGB(70, 28, 4)),
                ColorSequenceKeypoint.new(0.75, Color3.fromRGB(30, 12, 2)),
                ColorSequenceKeypoint.new(1,    Color3.fromRGB(8,  4,  1)),
            }
            grad.Rotation = 0
            grad.Parent   = container
            local padding = Instance.new("UIPadding")
            padding.PaddingLeft   = UDim.new(0, 14)
            padding.PaddingRight  = UDim.new(0, 14)
            padding.PaddingTop    = UDim.new(0, 0)
            padding.PaddingBottom = UDim.new(0, 0)
            padding.Parent        = container
            local shine = Instance.new("Frame")
            shine.Size                   = UDim2.new(0.7, 0, 0, 1)
            shine.Position               = UDim2.new(0.15, 0, 0, 1)
            shine.BackgroundColor3       = Color3.fromRGB(255, 160, 60)
            shine.BackgroundTransparency = 0.5
            shine.BorderSizePixel        = 0
            shine.Parent                 = container
            Instance.new("UICorner", shine).CornerRadius = UDim.new(1, 0)
            local shineGrad = Instance.new("UIGradient")
            shineGrad.Transparency = NumberSequence.new{
                NumberSequenceKeypoint.new(0,   1),
                NumberSequenceKeypoint.new(0.2, 0.3),
                NumberSequenceKeypoint.new(0.5, 0.2),
                NumberSequenceKeypoint.new(0.8, 0.3),
                NumberSequenceKeypoint.new(1,   1),
            }
            shineGrad.Parent = shine
            local lbl = Instance.new("TextLabel")
            lbl.Size                   = UDim2.new(0, 0, 1, 0)
            lbl.AutomaticSize          = Enum.AutomaticSize.X
            lbl.BackgroundTransparency = 1
            lbl.Text                   = "-- fps  ·  -- ms"
            lbl.TextColor3             = Color3.fromRGB(210, 150, 80)
            lbl.TextSize               = 11
            lbl.Font                   = Enum.Font.GothamBold
            lbl.TextXAlignment         = Enum.TextXAlignment.Center
            lbl.RichText               = true
            lbl.Parent                 = container
            local drag = { active = false, input = nil, startPos = nil, startCont = nil, changedConn = nil }
            container.InputBegan:Connect(function(input)
                if input.UserInputType ~= Enum.UserInputType.MouseButton1
                and input.UserInputType ~= Enum.UserInputType.Touch then return end
                drag.active    = true
                drag.startPos  = input.Position
                drag.startCont = container.Position
                if drag.changedConn then drag.changedConn:Disconnect() end
                drag.changedConn = input.Changed:Connect(function()
                    if input.UserInputState == Enum.UserInputState.End then
                        drag.active = false
                        if drag.changedConn then drag.changedConn:Disconnect(); drag.changedConn = nil end
                    end
                end)
            end)
            container.InputChanged:Connect(function(input)
                if input.UserInputType == Enum.UserInputType.MouseMovement
                or input.UserInputType == Enum.UserInputType.Touch then
                    drag.input = input
                end
            end)
            UserInputService.InputChanged:Connect(function(input)
                if input == drag.input and drag.active then
                    local delta = input.Position - drag.startPos
                    container.Position = UDim2.new(
                        drag.startCont.X.Scale, drag.startCont.X.Offset + delta.X,
                        drag.startCont.Y.Scale, drag.startCont.Y.Offset + delta.Y
                    )
                end
            end)
            local function colorTag(val, good, warn, rev)
                local c = rev
                    and ((val >= good and theme.Good) or (val >= warn and theme.Warn) or theme.Bad)
                    or  ((val <= good and theme.Good) or (val <= warn and theme.Warn) or theme.Bad)
                return string.format('<font color="rgb(%d,%d,%d)">', math.floor(c.R*255), math.floor(c.G*255), math.floor(c.B*255))
            end
            local sep      = '<font color="rgb(90,40,10)"> · </font>'
            local frames   = 0
            local fpsAccum = 0
            local lastUp   = 0
            local pingMs   = 0
            local pingT    = 0
            RunService.Heartbeat:Connect(function(dt)
                if not (container and container.Parent) then return end
                frames   = frames + 1
                fpsAccum = fpsAccum + dt
                local now = tick()
                if now - pingT >= 2 then
                    pcall(function() pingMs = math.floor(LocalPlayer:GetNetworkPing() * 1000) end)
                    pingT = now
                end
                if now - lastUp < 0.5 then return end
                lastUp = now
                local fps = fpsAccum > 0 and math.floor(frames / fpsAccum) or 0
                frames   = 0
                fpsAccum = 0
                lbl.Text = string.format(
                    "%s%d fps</font>%s%s%d ms</font>",
                    colorTag(fps,   50, 30, true),  fps, sep,
                    colorTag(pingMs, 50, 100, false), pingMs
                )
            end)
        end,
    })
end

do
    local ServerSection = SettingsTab:AddSection("Server")
    ServerSection:AddButton({
        Title    = "Rejoin Server",
        Callback = function()
            pcall(function()
                game:GetService("TeleportService"):Teleport(game.PlaceId, LocalPlayer)
            end)
        end,
    })
    ServerSection:AddButton({
        Title    = "Serverhop",
        Callback = function()
            local TeleportService = game:GetService("TeleportService")
            local HttpService     = game:GetService("HttpService")
            local placeId         = game.PlaceId
            local currentJobId    = game.JobId
            local foundJobId      = nil
            local cursor          = nil
            repeat
                local ok, result = pcall(function()
                    local url = string.format(
                        "https://games.roblox.com/v1/games/%d/servers/Public?sortOrder=Asc&limit=100%s",
                        placeId,
                        cursor and ("&cursor=" .. cursor) or ""
                    )
                    return HttpService:JSONDecode(HttpService:GetAsync(url))
                end)
                if not ok or not result then break end
                for _, server in ipairs(result.data) do
                    if server.id ~= currentJobId and (server.maxPlayers - server.playing) > 0 then
                        foundJobId = server.id
                        break
                    end
                end
                cursor = result.nextPageCursor
            until foundJobId or not cursor
            pcall(function()
                if foundJobId then
                    TeleportService:TeleportToPlaceInstance(placeId, foundJobId, LocalPlayer)
                else
                    TeleportService:Teleport(placeId, LocalPlayer)
                end
            end)
        end,
    })
end
