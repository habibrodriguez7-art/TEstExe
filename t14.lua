local ReplicatedStorage, _Workspace, RunService, Players =
    game:GetService("ReplicatedStorage"), game:GetService("Workspace"),
    game:GetService("RunService"),        game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local _LP = LocalPlayer
local UIS = game:GetService("UserInputService")
local _fishingActive = false
_G.AutoMineActive = false
local _moduleCache = {}
local function cachedRequire(moduleInstance)
    if not moduleInstance then return nil end
    if _moduleCache[moduleInstance] then return _moduleCache[moduleInstance] end
    local ok, result = pcall(function() return require(moduleInstance) end)
    if ok and result then _moduleCache[moduleInstance] = result end
    return ok and result or nil
end
local _cachedReplionData = nil
local function getCachedReplionData()
    if _cachedReplionData then return _cachedReplionData end
    local ok, data = pcall(function()
        local rep = cachedRequire(ReplicatedStorage:FindFirstChild("Packages")
            and ReplicatedStorage.Packages:FindFirstChild("Replion"))
        if rep then return rep.Client:GetReplion("Data") end
    end)
    if ok and data then _cachedReplionData = data end
    return _cachedReplionData
end
local _cachedReplionModule = nil
local function getCachedReplion()
    if _cachedReplionModule then return _cachedReplionModule end
    local ok, rep = pcall(function()
        return cachedRequire(ReplicatedStorage.Packages.Replion)
    end)
    if ok and rep then _cachedReplionModule = rep end
    return _cachedReplionModule
end
local Library = loadstring(game:HttpGet("https://raw.githubusercontent.com/habibrodriguez7-art/MainLib/refs/heads/main/Main.lua"))()
_G.EventResolver = (function()
    local self = {
        _isInitialized = false,
        _remoteEvents   = {},
        _remoteFunctions = {},
        _netFolder      = nil,
    }
    local function isHashString(name)
        return #name >= 32 and name:match("^[0-9a-f]+$") ~= nil
    end
    local function stripPrefix(name)
        return name:match("^[A-Z]+/(.+)$") or name
    end
    local function findNetFolder()
        if self._netFolder and self._netFolder.Parent then
            return self._netFolder
        end
        local success, netFolder = pcall(function()
            return ReplicatedStorage.Packages._Index["sleitnick_net@0.2.0"].net
        end)
        if success and netFolder then
            self._netFolder = netFolder
            return netFolder
        end
        return nil
    end
    local function scanNetFolder(netFolder)
        local children = netFolder:GetChildren()
        local index = 1
        while index <= #children do
            local current = children[index]
            local next    = children[index + 1]
            local currentName = stripPrefix(current.Name)
            if next then
                local nextName = stripPrefix(next.Name)
                if current.ClassName == next.ClassName
                    and not isHashString(currentName)
                    and isHashString(nextName)
                then
                    if current:IsA("RemoteFunction") then
                        self._remoteFunctions[currentName] = next
                    elseif current:IsA("RemoteEvent") or current:IsA("UnreliableRemoteEvent") then
                        self._remoteEvents[currentName] = next
                    end
                    index += 2
                    continue
                end
            end
            if not isHashString(currentName) then
                if current:IsA("RemoteFunction") and not self._remoteFunctions[currentName] then
                    self._remoteFunctions[currentName] = current
                elseif (current:IsA("RemoteEvent") or current:IsA("UnreliableRemoteEvent"))
                    and not self._remoteEvents[currentName]
                then
                    self._remoteEvents[currentName] = current
                end
            end
            index += 1
        end
    end
    function self:Init()
        if self._isInitialized then return true end
        local netFolder = findNetFolder()
        if not netFolder then
            warn("[EventResolver] Folder Net tidak ditemukan!")
            return false
        end
        self._remoteEvents    = {}
        self._remoteFunctions = {}
        scanNetFolder(netFolder)
        self._isInitialized = true
        _G.ResolvedNetEvents = {
            RemoteEvents    = self._remoteEvents,
            RemoteFunctions = self._remoteFunctions,
        }
        return true
    end
    function self:GetRemoteFunction(name)
        if not self._isInitialized then self:Init() end
        if not self._remoteFunctions[name] then
            local netFolder = findNetFolder()
            if netFolder then scanNetFolder(netFolder) end
        end
        return self._remoteFunctions[name]
    end
    function self:GetRemoteEvent(name)
        if not self._isInitialized then self:Init() end
        if not self._remoteEvents[name] then
            local netFolder = findNetFolder()
            if netFolder then scanNetFolder(netFolder) end
        end
        return self._remoteEvents[name]
    end
    function self:Reset()
        self._isInitialized  = false
        self._netFolder       = nil
        self._remoteEvents    = {}
        self._remoteFunctions = {}
    end
    function self:IsReady()     return self._isInitialized end
    function self:GetNetFolder() return findNetFolder() end
    self:Init()
    return self
end)()

LocalPlayer.CharacterAdded:Connect(function()
    task.wait(3)
    _cachedReplionData = nil
    _cachedReplionModule = nil
    _G.EventResolver:Reset()
    task.spawn(function()
        _G.EventResolver:Init()
    end)
end)

local NetEvents = setmetatable({}, {
    __index = function(_, key)
        local map = {
            RF_ChargeFishingRod              = function() return _G.EventResolver:GetRemoteFunction("ChargeFishingRod") end,
            RF_RequestMinigame               = function() return _G.EventResolver:GetRemoteFunction("RequestFishingMinigameStarted") end,
            RF_CancelFishingInputs           = function() return _G.EventResolver:GetRemoteFunction("CancelFishingInputs") end,
            RF_UpdateAutoFishingState        = function() return _G.EventResolver:GetRemoteFunction("UpdateAutoFishingState") end,
            RF_InitiateTrade                 = function() return _G.EventResolver:GetRemoteFunction("InitiateTrade") end,
            RF_AwaitTradeResponse            = function() return _G.EventResolver:GetRemoteFunction("AwaitTradeResponse") end,
            RF_ConsumePotion                 = function() return _G.EventResolver:GetRemoteFunction("ConsumePotion") end,
            RF_PurchaseCharm                 = function() return _G.EventResolver:GetRemoteFunction("PurchaseCharm") end,
            RF_SellItem                      = function() return _G.EventResolver:GetRemoteFunction("SellItem") end,
            RF_SellAllItems                  = function() return _G.EventResolver:GetRemoteFunction("SellAllItems") end,
            RF_PurchaseFishingRod            = function() return _G.EventResolver:GetRemoteFunction("PurchaseFishingRod") end,
            RF_PurchaseBait                  = function() return _G.EventResolver:GetRemoteFunction("PurchaseBait") end,
            RF_UpdateFishingRadar            = function() return _G.EventResolver:GetRemoteFunction("UpdateFishingRadar") end,
            RF_StartCrafting                 = function() return _G.EventResolver:GetRemoteFunction("StartCrafting") end,
            RF_ConfirmCrafting               = function() return _G.EventResolver:GetRemoteFunction("ConfirmCrafting") end,
            RF_CancelCrafting                = function() return _G.EventResolver:GetRemoteFunction("CancelCrafting") end,
            RF_ActivateEggMachineEgg         = function() return _G.EventResolver:GetRemoteFunction("ActivateEggMachineEgg") end,
            RF_ExchangeEggMachine            = function() return _G.EventResolver:GetRemoteFunction("ExchangeEggMachine") end,
            RF_ConsumeCaveCrystal            = function() return _G.EventResolver:GetRemoteFunction("ConsumeCaveCrystal") end,
            RF_PurchaseWeatherEvent          = function() return _G.EventResolver:GetRemoteFunction("PurchaseWeatherEvent") end,
            RF_SacrificeAtlantisFish         = function() return _G.EventResolver:GetRemoteFunction("SacrificeAtlantisFish") end,
            RF_SacrificeAtlantisSellAll      = function() return _G.EventResolver:GetRemoteFunction("SacrificeAtlantisSellAll") end,
            RF_EquipOxygenTank               = function() return _G.EventResolver:GetRemoteFunction("EquipOxygenTank") end,
            RF_UnequipOxygenTank             = function() return _G.EventResolver:GetRemoteFunction("UnequipOxygenTank") end,
            RF_ClassicMachineActivate        = function() return _G.EventResolver:GetRemoteFunction("ClassicMachineActivate") end,
            RF_ConsumeItem                   = function() return _G.EventResolver:GetRemoteFunction("ConsumeItem") end,
            RF_EquipToolFromHotbar           = function() return _G.EventResolver:GetRemoteEvent("EquipToolFromHotbar") end,
            RF_PurchaseMarketItem            = function() return _G.EventResolver:GetRemoteFunction("PurchaseMarketItem") end,
            RF_RodCraftingMinigameClick      = function() return _G.EventResolver:GetRemoteFunction("RodCraftingMinigameClick") end,
            RF_FinishRodCraftingMinigame     = function() return _G.EventResolver:GetRemoteFunction("FinishRodCraftingMinigame") end,

            RE_PlayRodCraftingMinigame       = function() return _G.EventResolver:GetRemoteEvent("PlayRodCraftingMinigame") end,
            RE_FishingCompleted              = function() return _G.EventResolver:GetRemoteEvent("CatchFishCompleted") end,
            RE_UpdateChargeState             = function() return _G.EventResolver:GetRemoteEvent("UpdateChargeState") end,
            RE_MinigameChanged               = function() return _G.EventResolver:GetRemoteEvent("FishingMinigameChanged") end,
            RE_FishCaught                    = function() return _G.EventResolver:GetRemoteEvent("FishCaught") end,
            RE_FishingStopped                = function() return _G.EventResolver:GetRemoteEvent("FishingStopped") end,
            RE_FavoriteItem                  = function() return _G.EventResolver:GetRemoteEvent("FavoriteItem") end,
            RE_EquipItem                     = function() return _G.EventResolver:GetRemoteEvent("EquipItem") end,
            RE_ActivateEnchantingAltar       = function() return _G.EventResolver:GetRemoteEvent("ActivateEnchantingAltar") end,
            RE_ActivateSecondEnchantingAltar = function() return _G.EventResolver:GetRemoteEvent("ActivateSecondEnchantingAltar") end,
            RE_RollEnchant                   = function() return _G.EventResolver:GetRemoteEvent("RollEnchant") end,
            RE_BaitSpawned                   = function() return _G.EventResolver:GetRemoteEvent("BaitSpawned") end,
            RE_BaitDestroyed                 = function() return _G.EventResolver:GetRemoteEvent("BaitDestroyed") end,
            RE_ObtainedNewFishNotification   = function() return _G.EventResolver:GetRemoteEvent("ObtainedNewFishNotification") end,
            RE_PlaceLeverItem                = function() return _G.EventResolver:GetRemoteEvent("PlaceLeverItem") end,
            RE_PlacePressurePlateItem        = function() return _G.EventResolver:GetRemoteEvent("PlacePressureItem") end,
            RE_EquipBait                     = function() return _G.EventResolver:GetRemoteEvent("EquipBait") end,
            RE_PlayFishEffect                = function() return _G.EventResolver:GetRemoteEvent("PlayFishingEffect") end,
            RE_TextEffect                    = function() return _G.EventResolver:GetRemoteEvent("ReplicateTextEffect") end,
            RE_OpenEggMachine                = function() return _G.EventResolver:GetRemoteEvent("OpenEggMachine") end,
            RE_BaitCastVisual                = function() return _G.EventResolver:GetRemoteEvent("BaitCastVisual") end,
            RE_FishCaughtVisual              = function() return _G.EventResolver:GetRemoteEvent("FishCaughtVisual") end,
            RE_PlayVideoAd                   = function() return _G.EventResolver:GetRemoteEvent("PlayVideoAd") end,
            RE_RelayVideoAd                  = function() return _G.EventResolver:GetRemoteEvent("RelayVideoAd") end,
            RE_DialogueEnded                 = function() return _G.EventResolver:GetRemoteEvent("DialogueEnded") end,
            RE_PickaxeMining                 = function() return _G.EventResolver:GetRemoteEvent("PickaxeMining") end,
            RE_SpawnTotem                    = function() return _G.EventResolver:GetRemoteEvent("SpawnTotem") end,
            RE_ClaimPirateChest              = function() return _G.EventResolver:GetRemoteEvent("ClaimPirateChest") end,
            RE_PlacePressureItem             = function() return _G.EventResolver:GetRemoteEvent("PlacePressureItem") end,
            RE_TotemPickup                   = function() return _G.EventResolver:GetRemoteEvent("TotemPickup") end,
            RE_TotemCreated                  = function() return _G.EventResolver:GetRemoteEvent("TotemCreated") end,
            RE_PlaceLeviathanPressureItem    = function() return _G.EventResolver:GetRemoteEvent("PlaceLeviathanPressureItem") end,
            RE_PlayLeviathanSequence         = function() return _G.EventResolver:GetRemoteEvent("PlayLeviathanSequence") end,
            RE_PlayAbilityVFX                = function() return _G.EventResolver:GetRemoteEvent("PlayAbilityVFX") end,
            RE_TradePlazaTeleport            = function() return _G.EventResolver:GetRemoteEvent("TradePlazaTeleport") end,
            netFolder                        = function() return _G.EventResolver:GetNetFolder() end,
            IsInitialized                    = function() return _G.EventResolver:IsReady() end,
        }
        local resolver = map[key]
        return resolver and resolver() or nil
    end,
    __newindex = function(t, k, v)
        rawset(t, k, v)
    end,
})

local function autoEquipRod()
    local char = LocalPlayer.Character
    if not char then return end
    if char:FindFirstChildOfClass("Tool") then return end
    local remote = NetEvents.RF_EquipToolFromHotbar
    if remote then remote:FireServer(1) end
    task.wait(0.5)
end

local SCRIPT_URL = "https://raw.githubusercontent.com/habibrodriguez7-art/TEstExe/refs/heads/main/t14.lua"
local _queueExecuted = false

local function sharedQueueAutoExecute(enableTreasureJoin)
    if _queueExecuted then return end
    _queueExecuted = true

    local flagLine = enableTreasureJoin and 'getgenv().__autoTreasureJoin = true' or ''

    local queueFn = queue_on_teleport
        or (syn and syn.queue_on_teleport)
        or (fluxus and fluxus.queue_on_teleport)
        or (solara and solara.queue_on_teleport)
        or (Delta and Delta.queue_on_teleport)
        or (getgenv and getgenv().queue_on_teleport)

    if type(queueFn) == "function" then
        pcall(function()
            queueFn(([[
                if not game:IsLoaded() then game.Loaded:Wait() end
                local Players = game:GetService("Players")
                local LocalPlayer = Players.LocalPlayer
                if not LocalPlayer.Character then
                    LocalPlayer.CharacterAdded:Wait()
                end
                local char = LocalPlayer.Character
                char:WaitForChild("HumanoidRootPart", 10)
                local hum = char:WaitForChild("Humanoid", 10)
                if hum then
                    repeat task.wait(0.5) until hum.Health > 0
                end
                task.wait(2)
                %s
                loadstring(game:HttpGet("%s"))()
            ]]):format(flagLine, SCRIPT_URL))
        end)
    end
end

game:GetService("Players").LocalPlayer.CharacterAdded:Connect(function()
    _queueExecuted = false
end)

local function safeFire(fn) pcall(fn) end
local fishingController
local _atlantis, _classicMachineBusy
local _ev, _dropdown, _totem, _totemOriginal, _dropdownRefs
local _art, _deep, _elem, _ruin
local _ELEM_GOALS, _DEEP_GOALS
local _totemSpawning = false
local _priorityDropRef = nil
_classicMachineBusy = false
local http = (rawget(_G, "http") or nil)

local MainWindow = Library:Window({
    Title         = "Lynx",
    Footer        = "Fish It",
})

-- [Main Tab]
do
    local FishingTab = MainWindow:AddTab({ Name = "Main", Icon = "home" })
    do
        local _sup = {
            AnimConn   = nil, AnimEnabled = false,
            RodThread  = nil, RodEnabled  = false,
            RodSupported = false,
            RodReplion   = nil, RodStats = nil, RodItems = nil,
            LockConn   = nil, LockEnabled = false, LockedCFrame = nil,
            NotifConn  = nil,
            VFXDisabled     = false,
            VFXController   = nil,
            VFXOrigHandle   = nil, VFXOrigAtPoint = nil, VFXOrigInstance = nil,
            VFXSupported    = false,
            CutsceneCtrl    = nil, CutsceneOrigPlay = nil, CutsceneDisabled = false,
            WaterEnabled    = false, WaterPlatform = nil,
            WaterAlign      = nil,   WaterConn     = nil, WaterSurfaceY = nil,
            WaterCharConn   = nil,
            MonitorConn = nil, MonitorGui = nil,
            MonitorState = nil,
            AbilityVFXEnabled = false, AbilityVFXConn = nil, AbilityVFXLoop = nil,
        }

        local SupportSection = FishingTab:AddSection("Support Features")
        SupportSection:AddToggle({
            Title   = "No Fishing Animation",
            Default = false,
            Callback = function(on)
                local animator = (LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait())
                    :WaitForChild("Humanoid")
                    :FindFirstChildOfClass("Animator")
                if not animator then return end
                if on then
                    _sup.stopAnimHookEnabled = true
                    for _, track in ipairs(animator:GetPlayingAnimationTracks()) do
                        track:Stop(0)
                    end
                    _sup.stopAnimConn = animator.AnimationPlayed:Connect(function(track)
                        if _sup.stopAnimHookEnabled then
                            task.defer(function()
                                pcall(function() track:Stop(0) end)
                            end)
                        end
                    end)
                else
                    _sup.stopAnimHookEnabled = false
                    if _sup.stopAnimConn then
                        _sup.stopAnimConn:Disconnect()
                        _sup.stopAnimConn = nil
                    end
                end
            end,
        })

        SupportSection:AddToggle({
            Title    = "Auto Equip Rod",
            Default  = false,
            Callback = function(on)
                if on then
                    if _sup.RodEnabled then return end
                    local ok = pcall(function()
                        _sup.RodStats   = _sup.RodStats   or cachedRequire(ReplicatedStorage.Shared.PlayerStatsUtility)
                        _sup.RodItems   = _sup.RodItems   or cachedRequire(ReplicatedStorage.Shared.ItemUtility)
                        _sup.RodReplion = _sup.RodReplion or (function()
                            local rep = getCachedReplion()
                            return rep and rep.Client:GetReplion("Data") or nil
                        end)()
                        _sup.RodSupported = true
                    end)
                    if not ok or not _sup.RodSupported then return end
                    _sup.RodEnabled = true
                    _sup.RodThread  = task.spawn(function()
                        while _sup.RodEnabled do
                            if not _G.AutoMineActive then
                                pcall(function()
                                    local isEquipped = false
                                    local uuid = _sup.RodReplion:Get("EquippedId")
                                    if uuid then
                                        local item = _sup.RodStats:GetItemFromInventory(
                                            _sup.RodReplion,
                                            function(i) return i.UUID == uuid end
                                        )
                                        if item then
                                            local data = _sup.RodItems:GetItemData(item.Id)
                                            isEquipped = data and data.Data.Type == "Fishing Rods"
                                        end
                                    end
                                    if not isEquipped then
                                        local remote = NetEvents.RF_EquipToolFromHotbar
                                        if remote then remote:FireServer(1) end
                                    end
                                end)
                            end
                            task.wait(1)
                        end
                    end)
                else
                    _sup.RodEnabled = false
                    if _sup.RodThread then task.cancel(_sup.RodThread); _sup.RodThread = nil end
                end
            end,
        })

        SupportSection:AddToggle({
            Title = "Bypass Radar",
            Default = false,
            Callback = function(enabled)
                pcall(function()
                    NetEvents.RF_UpdateFishingRadar:InvokeServer(enabled)
                end)
            end
        })

        SupportSection:AddToggle({
            Title    = "Lock Position",
            Default  = false,
            NoSave   = true,
            Callback = function(on)
                if on then
                    if _sup.LockEnabled then return end
                    _sup.LockEnabled = true
                    local char = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
                    local root = char:WaitForChild("HumanoidRootPart")
                    _sup.LockedCFrame = root.CFrame
                    _sup.LockConn = RunService.Heartbeat:Connect(function()
                        if not _sup.LockEnabled then return end
                        local r = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
                        if r then r.CFrame = _sup.LockedCFrame end
                    end)
                else
                    _sup.LockEnabled = false
                    if _sup.LockConn then _sup.LockConn:Disconnect(); _sup.LockConn = nil end
                end
            end,
        })

        SupportSection:AddToggle({
            Title    = "Show Real Ping Panel",
            Default  = false,
            Callback = function(on)
                local _monitor = _sup.MonitorState
                if not _monitor then
                    _monitor = { enabled = false, conn = nil, inputConn = nil, charConn = nil, gui = nil }
                    _sup.MonitorState = _monitor
                end
                _monitor.enabled = on
                if _monitor.conn      then _monitor.conn:Disconnect();      _monitor.conn      = nil end
                if _monitor.inputConn then _monitor.inputConn:Disconnect(); _monitor.inputConn = nil end
                if _monitor.charConn  then _monitor.charConn:Disconnect();  _monitor.charConn  = nil end
                if _monitor.gui       then _monitor.gui:Destroy();          _monitor.gui       = nil end
                if not on then return end
                local _TweenService = game:GetService("TweenService")
                local Stats        = game:GetService("Stats")
                local PlayerGui    = LocalPlayer:WaitForChild("PlayerGui")
                local oldGui       = PlayerGui:FindFirstChild("LynxPanelMonitor")
                if oldGui then oldGui:Destroy() end
                local _theme = {
                    Good = Color3.fromRGB(80,  255, 140),
                    Warn = Color3.fromRGB(255, 220, 90),
                    Bad  = Color3.fromRGB(255, 90,  90),
                }
                local screenGui = Instance.new("ScreenGui")
                screenGui.Name           = "LynxPanelMonitor"
                screenGui.ResetOnSpawn   = false
                screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Global
                screenGui.DisplayOrder   = 999999
                screenGui.IgnoreGuiInset = true
                screenGui.Parent         = PlayerGui
                _monitor.gui             = screenGui
                local container = Instance.new("Frame")
                container.Size                   = UDim2.new(0, 0, 0, 30)
                container.Position               = UDim2.new(0.5, 0, 0, 14)
                container.AnchorPoint            = Vector2.new(0.5, 0)
                container.AutomaticSize          = Enum.AutomaticSize.X
                container.BackgroundColor3       = Color3.fromRGB(18, 8, 2)
                container.BackgroundTransparency = 0.45
                container.BorderSizePixel        = 0
                container.Parent                 = screenGui
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
                local statsLabel = Instance.new("TextLabel")
                statsLabel.Size                   = UDim2.new(0, 0, 1, 0)
                statsLabel.AutomaticSize          = Enum.AutomaticSize.X
                statsLabel.BackgroundTransparency = 1
                statsLabel.Text                   = "-- ms  ·  CPU --  ·  -- fps  ·  Notif 0"
                statsLabel.TextColor3             = Color3.fromRGB(210, 150, 80)
                statsLabel.TextSize               = 11
                statsLabel.Font                   = Enum.Font.GothamBold
                statsLabel.TextXAlignment         = Enum.TextXAlignment.Center
                statsLabel.RichText               = true
                statsLabel.Parent                 = container
                local _drag = { active = false, input = nil, startPos = nil, startCont = nil, changedConn = nil }
                container.InputBegan:Connect(function(input)
                    if input.UserInputType ~= Enum.UserInputType.MouseButton1
                    and input.UserInputType ~= Enum.UserInputType.Touch then return end
                    _drag.active    = true
                    _drag.startPos  = input.Position
                    _drag.startCont = container.Position
                    if _drag.changedConn then _drag.changedConn:Disconnect() end
                    _drag.changedConn = input.Changed:Connect(function()
                        if input.UserInputState == Enum.UserInputState.End then
                            _drag.active = false
                            if _drag.changedConn then _drag.changedConn:Disconnect(); _drag.changedConn = nil end
                        end
                    end)
                end)
                container.InputChanged:Connect(function(input)
                    if input.UserInputType == Enum.UserInputType.MouseMovement
                    or input.UserInputType == Enum.UserInputType.Touch then
                        _drag.input = input
                    end
                end)
                _monitor.inputConn = UIS.InputChanged:Connect(function(input)
                    if input == _drag.input and _drag.active then
                        local delta = input.Position - _drag.startPos
                        container.Position = UDim2.new(
                            _drag.startCont.X.Scale, _drag.startCont.X.Offset + delta.X,
                            _drag.startCont.Y.Scale, _drag.startCont.Y.Offset + delta.Y
                        )
                    end
                end)
                local _acc = {
                    currentFPS   = 0,
                    ping         = 0,
                    UI_INTERVAL  = 1,
                    uiAccum      = 0,
                    frames       = 0,
                    fpsAccum     = 0,
                    currentCpuMs = 0,
                }
                local _notifFrame = nil
                local function getNotifFrame()
                    if _notifFrame and _notifFrame.Parent then return _notifFrame end
                    local gui = LocalPlayer.PlayerGui:FindFirstChild("Text Notifications")
                    _notifFrame = gui and gui:FindFirstChild("Frame") or nil
                    return _notifFrame
                end
                local function colorTag(val, good, warn, rev)
                    local c = rev
                        and ((val >= good and _theme.Good) or (val >= warn and _theme.Warn) or _theme.Bad)
                        or  ((val <= good and _theme.Good) or (val <= warn and _theme.Warn) or _theme.Bad)
                    return string.format('<font color="rgb(%d,%d,%d)">', math.floor(c.R*255), math.floor(c.G*255), math.floor(c.B*255))
                end
                _monitor.conn = RunService.Heartbeat:Connect(function(dt)
                    _acc.uiAccum     += dt
                    _acc.frames      += 1
                    _acc.fpsAccum    += dt
                    _acc.currentCpuMs = _acc.currentCpuMs * 0.8 + (dt * 1000) * 0.2
                    if _acc.uiAccum < _acc.UI_INTERVAL then return end
                    _acc.uiAccum = 0
                    _acc.currentFPS = _acc.fpsAccum > 0 and math.floor(_acc.frames / _acc.fpsAccum) or 0
                    _acc.frames   = 0
                    _acc.fpsAccum = 0
                    local p = 0
                    pcall(function()
                        p = math.floor(Stats.Network.ServerStatsItem["Data Ping"]:GetValue())
                    end)
                    if p <= 0 then
                        pcall(function() p = math.floor(LocalPlayer:GetNetworkPing() * 1000) end)
                    end
                    _acc.ping = math.max(p, 0)
                    local notifCount = 0
                    local frame = getNotifFrame()
                    if frame then
                        for _, child in ipairs(frame:GetChildren()) do
                            if child.Name == "Tile" and child:IsA("Frame") then
                                notifCount += 1
                            end
                        end
                    end
                    local cpuDisplay = math.floor(math.clamp(_acc.currentCpuMs, 0, 999))
                    local sep = '<font color="rgb(90,40,10)"> · </font>'
                    statsLabel.Text = string.format(
                        "%s%d ms</font>%sCPU %s%d ms</font>%s%s%d fps</font>%sNotif %d",
                        colorTag(_acc.ping, 50, 100, false), _acc.ping, sep,
                        colorTag(cpuDisplay, 33, 50, false), cpuDisplay, sep,
                        colorTag(_acc.currentFPS, 50, 30, true), _acc.currentFPS, sep,
                        notifCount
                    )
                end)
            end,
        })

        SupportSection:AddToggle({
            Title    = "Disable Cutscenes",
            Default  = false,
            Callback = function(on)
                _sup.CutsceneDisabled = on
                if on then
                    if not _sup.CutsceneCtrl then
                        pcall(function()
                            _sup.CutsceneCtrl = require(
                                ReplicatedStorage:WaitForChild("Controllers"):WaitForChild("CutsceneController")
                            )
                            if _sup.CutsceneCtrl and _sup.CutsceneCtrl.Play then
                                _sup.CutsceneOrigPlay = _sup.CutsceneCtrl.Play
                                _sup.CutsceneCtrl.Play = function(selfArg, ...)
                                    if _sup.CutsceneDisabled then return end
                                    return _sup.CutsceneOrigPlay(selfArg, ...)
                                end
                            end
                        end)
                    end
                else
                    if _sup.CutsceneCtrl and _sup.CutsceneOrigPlay then
                        _sup.CutsceneCtrl.Play = _sup.CutsceneOrigPlay
                    end
                end
            end,
        })

        SupportSection:AddToggle({
            Title    = "Disable Obtained Fish Notification",
            Default  = false,
            Callback = function(on)
                if on then
                    if _sup.NotifConn then return end
                    local PlayerGui = LocalPlayer.PlayerGui
                    local notifGui  = PlayerGui:FindFirstChild("Small Notification")
                                or PlayerGui:WaitForChild("Small Notification", 5)
                    if not notifGui then return end
                    notifGui.Enabled = false
                    _sup.NotifConn = notifGui:GetPropertyChangedSignal("Enabled"):Connect(function()
                        if notifGui.Enabled then notifGui.Enabled = false end
                    end)
                else
                    if _sup.NotifConn then _sup.NotifConn:Disconnect(); _sup.NotifConn = nil end
                    local notifGui = LocalPlayer.PlayerGui:FindFirstChild("Small Notification")
                    if notifGui then notifGui.Enabled = true end
                end
            end,
        })

        SupportSection:AddToggle({
            Title    = "Disable Skin Effect",
            Default  = false,
            Callback = function(on)
                if on then
                    if _sup.VFXDisabled then return end
                    if not _sup.VFXSupported then
                        local ok = pcall(function()
                            _sup.VFXController   = require(ReplicatedStorage:WaitForChild("Controllers").VFXController)
                            _sup.VFXOrigHandle   = _sup.VFXController.Handle
                            _sup.VFXOrigAtPoint  = _sup.VFXController.RenderAtPoint
                            _sup.VFXOrigInstance = _sup.VFXController.RenderInstance
                            _sup.VFXSupported    = true
                        end)
                        if not ok or not _sup.VFXSupported then return end
                    end
                    _sup.VFXDisabled = true
                    _sup.VFXController.Handle         = function() end
                    _sup.VFXController.RenderAtPoint  = function() end
                    _sup.VFXController.RenderInstance = function() end
                else
                    _sup.VFXDisabled = false
                    if _sup.VFXController then
                        _sup.VFXController.Handle         = _sup.VFXOrigHandle
                        _sup.VFXController.RenderAtPoint  = _sup.VFXOrigAtPoint
                        _sup.VFXController.RenderInstance = _sup.VFXOrigInstance
                    end
                end
            end,
        })

        _G._wowToggleRef = SupportSection:AddToggle({
            Title    = "Walk On Water",
            Default  = false,
            Callback = function(on)
                _sup.WaterEnabled = on

                local function cleanup()
                    if _sup.WaterConn      then _sup.WaterConn:Disconnect();      _sup.WaterConn      = nil end
                    if _sup.WaterCharConn  then _sup.WaterCharConn:Disconnect();  _sup.WaterCharConn  = nil end
                    if _sup.WaterAncConn   then _sup.WaterAncConn:Disconnect();   _sup.WaterAncConn   = nil end
                    if _sup.WaterAlign     then _sup.WaterAlign:Destroy();        _sup.WaterAlign     = nil end
                    if _sup.WaterPlatform  then _sup.WaterPlatform:Destroy();     _sup.WaterPlatform  = nil end
                    _sup.WaterSurfaceY    = nil
                    _sup.WaterLastPos     = nil
                    _sup.WaterLastCollide = nil
                    _sup.WaterFrameSkip   = 0
                end

                if not on then
                    cleanup()
                    return
                end

                cleanup()

                local function setupForCharacter(char)
                    if _sup.WaterConn     then _sup.WaterConn:Disconnect();     _sup.WaterConn     = nil end
                    if _sup.WaterAncConn  then _sup.WaterAncConn:Disconnect();  _sup.WaterAncConn  = nil end
                    if _sup.WaterAlign    then _sup.WaterAlign:Destroy();       _sup.WaterAlign    = nil end
                    if _sup.WaterPlatform then _sup.WaterPlatform:Destroy();    _sup.WaterPlatform = nil end
                    _sup.WaterLastPos     = nil
                    _sup.WaterLastCollide = nil
                    _sup.WaterFrameSkip   = 0

                    if not _sup.WaterEnabled then return end

                    local root = char:WaitForChild("HumanoidRootPart", 5)
                    if not root or not _sup.WaterEnabled then return end

                    local rayParams = RaycastParams.new()
                    rayParams.FilterType                 = Enum.RaycastFilterType.Exclude
                    rayParams.FilterDescendantsInstances = { char }
                    rayParams.IgnoreWater                = false

                    local rayResult = workspace:Raycast(
                        root.Position + Vector3.new(0, 10, 0),
                        Vector3.new(0, -200, 0),
                        rayParams
                    )

                    if not rayResult then return end
                    _sup.WaterSurfaceY = rayResult.Position.Y

                    local platform        = Instance.new("Part")
                    platform.Name         = "WaterLockPlatform"
                    platform.Size         = Vector3.new(15, 1, 15)
                    platform.Anchored     = true
                    platform.CanCollide   = false
                    platform.Transparency = 1
                    platform.Material     = Enum.Material.SmoothPlastic
                    platform.CastShadow   = false
                    platform.CanQuery     = false
                    platform.CanTouch     = false
                    platform.Position     = Vector3.new(root.Position.X, _sup.WaterSurfaceY, root.Position.Z)
                    platform.Parent       = workspace
                    _sup.WaterPlatform    = platform

                    _sup.WaterAncConn = root.AncestryChanged:Connect(function()
                        if not root.Parent then cleanup() end
                    end)

                    local MOVE_THRESHOLD     = 0.5
                    local TELEPORT_THRESHOLD = 50
                    local COLLIDE_MARGIN     = 0.5
                    local COLLIDE_SKIP       = 6
                    local surfaceY           = _sup.WaterSurfaceY
                    local lastPosX           = root.Position.X
                    local lastPosZ           = root.Position.Z
                    local frameCount         = 0
                    local posSkip            = 0

                    _sup.WaterConn = RunService.Heartbeat:Connect(function()
                        posSkip += 1
                        if posSkip < 2 then return end
                        posSkip = 0

                        if not _sup.WaterEnabled then return end
                        if not root.Parent then
                            cleanup()
                            return
                        end

                        local rPos = root.Position
                        local dx   = rPos.X - lastPosX
                        local dz   = rPos.Z - lastPosZ
                        local distSq = dx * dx + dz * dz

                        if distSq > TELEPORT_THRESHOLD * TELEPORT_THRESHOLD then
                            platform.Position     = Vector3.new(rPos.X, surfaceY, rPos.Z)
                            platform.CanCollide   = rPos.Y >= (surfaceY - COLLIDE_MARGIN)
                            _sup.WaterLastCollide = platform.CanCollide
                            lastPosX              = rPos.X
                            lastPosZ              = rPos.Z
                            _sup.WaterLastPos     = rPos
                            return
                        end

                        if distSq > MOVE_THRESHOLD * MOVE_THRESHOLD then
                            platform.Position = Vector3.new(rPos.X, surfaceY, rPos.Z)
                            lastPosX          = rPos.X
                            lastPosZ          = rPos.Z
                            _sup.WaterLastPos = rPos
                        end

                        frameCount += 1
                        if frameCount < COLLIDE_SKIP then return end
                        frameCount = 0

                        local shouldCollide = rPos.Y >= (surfaceY - COLLIDE_MARGIN)
                        if shouldCollide ~= _sup.WaterLastCollide then
                            platform.CanCollide   = shouldCollide
                            _sup.WaterLastCollide = shouldCollide
                        end
                    end)
                end

                _sup.WaterCharConn = LocalPlayer.CharacterAdded:Connect(function(newChar)
                    if _sup.WaterEnabled then
                        task.spawn(setupForCharacter, newChar)
                    end
                end)

                local char = LocalPlayer.Character
                if char then task.spawn(setupForCharacter, char) end
            end,
        })

        SupportSection:AddToggle({
            Title   = "Hide Other Players",
            Default = false,
            NoSave  = true,
            Callback = (function()
                local enabled       = false
                local hidden        = {}
                local charConns     = {}
                local charAddConns  = {}
                local addedConn, removedConn
                local V3zero = Vector3.zero
                local function applyHide(part)
                    if part:IsA("BasePart") then
                        part.Transparency = 1
                        part.LocalTransparencyModifier = 1
                    elseif part:IsA("Decal") then
                        part.Transparency = 1
                    elseif part:IsA("SpecialMesh") then
                        part.Scale = V3zero
                    elseif part:IsA("ParticleEmitter") or part:IsA("Trail") or part:IsA("Beam") then
                        part.Enabled = false
                    elseif part:IsA("BillboardGui") or part:IsA("SurfaceGui") then
                        part.Enabled = false
                    end
                end
                local function hideCharacter(player)
                    if player == LocalPlayer then return end
                    local char = player.Character
                    if not char or hidden[player] then return end
                    local data = {}
                    hidden[player] = data
                    for _, part in next, char:GetDescendants() do
                        if part:IsA("BasePart") then
                            data[part] = { part.Transparency, part.LocalTransparencyModifier }
                            part.Transparency = 1
                            part.LocalTransparencyModifier = 1
                        elseif part:IsA("Decal") then
                            data[part] = { part.Transparency }
                            part.Transparency = 1
                        elseif part:IsA("SpecialMesh") then
                            data[part] = { part.Scale }
                            part.Scale = V3zero
                        elseif part:IsA("ParticleEmitter") or part:IsA("Trail") or part:IsA("Beam") then
                            data[part] = { part.Enabled }
                            part.Enabled = false
                        elseif part:IsA("BillboardGui") or part:IsA("SurfaceGui") then
                            data[part] = { part.Enabled }
                            part.Enabled = false
                        end
                    end
                    if charConns[player] then charConns[player]:Disconnect() end
                    charConns[player] = char.DescendantAdded:Connect(function(part)
                        if enabled then applyHide(part) end
                    end)
                end
                local function restoreCharacter(player)
                    local data = hidden[player]
                    if not data then return end
                    local char = player.Character
                    if char then
                        for part, props in next, data do
                            if part and part.Parent then
                                if part:IsA("BasePart") then
                                    part.Transparency = props[1]
                                    part.LocalTransparencyModifier = props[2]
                                elseif part:IsA("Decal") then
                                    part.Transparency = props[1]
                                elseif part:IsA("SpecialMesh") then
                                    part.Scale = props[1]
                                elseif part:IsA("ParticleEmitter") or part:IsA("Trail") or part:IsA("Beam") then
                                    part.Enabled = props[1]
                                elseif part:IsA("BillboardGui") or part:IsA("SurfaceGui") then
                                    part.Enabled = props[1]
                                end
                            end
                        end
                    end
                    hidden[player] = nil
                    if charConns[player] then
                        charConns[player]:Disconnect()
                        charConns[player] = nil
                    end
                end
                local function watchCharAdded(player)
                    return player.CharacterAdded:Connect(function()
                        task.defer(function()
                            if enabled then
                                hidden[player] = nil
                                if charConns[player] then
                                    charConns[player]:Disconnect()
                                    charConns[player] = nil
                                end
                                hideCharacter(player)
                            end
                        end)
                    end)
                end
                return function(on)
                    enabled = on
                    if on then
                        for _, player in next, Players:GetPlayers() do
                            if player ~= LocalPlayer then
                                hideCharacter(player)
                                charAddConns[player] = watchCharAdded(player)
                            end
                        end
                        addedConn = Players.PlayerAdded:Connect(function(player)
                            charAddConns[player] = watchCharAdded(player)
                            task.defer(function()
                                if enabled then hideCharacter(player) end
                            end)
                        end)
                        removedConn = Players.PlayerRemoving:Connect(function(player)
                            hidden[player] = nil
                            if charConns[player] then
                                charConns[player]:Disconnect()
                                charConns[player] = nil
                            end
                            if charAddConns[player] then
                                charAddConns[player]:Disconnect()
                                charAddConns[player] = nil
                            end
                        end)

                        Library:MakeNotify({ Title = "Remove Players", Content = "Player lain disembunyikan.", Delay = 2 })
                    else
                        if addedConn   then addedConn:Disconnect();   addedConn   = nil end
                        if removedConn then removedConn:Disconnect(); removedConn = nil end
                        for player, conn in next, charAddConns do
                            conn:Disconnect()
                            charAddConns[player] = nil
                        end
                        for _, player in next, Players:GetPlayers() do
                            restoreCharacter(player)
                        end

                        Library:MakeNotify({ Title = "Remove Players", Content = "Player lain ditampilkan kembali.", Delay = 2 })
                    end
                end
            end)(),
        })

        SupportSection:AddToggle({
            Title    = "Disable Ability VFX",
            Default  = false,
            Callback = function(on)
                _sup.AbilityVFXEnabled = on
                if _sup.AbilityVFXConn then _sup.AbilityVFXConn:Disconnect(); _sup.AbilityVFXConn = nil end
                if _sup.AbilityVFXLoop then _sup.AbilityVFXLoop:Disconnect(); _sup.AbilityVFXLoop = nil end
                if not on then return end
                for _, obj in ipairs(workspace:GetDescendants()) do
                    if obj:GetAttribute("AbilityVFX") == true then
                        pcall(function() obj:Destroy() end)
                    end
                end
                _sup.AbilityVFXLoop = workspace.DescendantAdded:Connect(function(obj)
                    if not _sup.AbilityVFXEnabled then return end
                    task.defer(function()
                        if obj and obj.Parent and obj:GetAttribute("AbilityVFX") == true then
                            pcall(function() obj:Destroy() end)
                        end
                    end)
                end)
            end,
        })
    end

    do
        local _stable = {
            enabled   = false,
            watchConn = nil,
        }
        local StableSection = FishingTab:AddSection("Stable Result Good/Perfection")
        StableSection:AddToggle({
            Title    = "Stable Result Good/Perfection",
            Default  = false,
            Callback = function(on)
                if on then
                    if _stable.enabled then return end
                    local replionData = getCachedReplionData()
                    if not replionData then
                        task.wait(1)
                        replionData = getCachedReplionData()
                    end
                    if not replionData then return end
                    local remote = NetEvents.RF_UpdateAutoFishingState
                    if not remote then return end
                    if not pcall(function() remote:InvokeServer(true) end) then return end
                    _stable.enabled = true
                    pcall(function() LocalPlayer:SetAttribute("Loading", nil) end)
                    _stable.watchConn = replionData:OnChange("AutoFishing", function(newState)
                        if _stable.enabled and not newState then
                            local r = NetEvents.RF_UpdateAutoFishingState
                            if r then pcall(function() r:InvokeServer(true) end) end
                        end
                    end)
                else
                    if not _stable.enabled then return end
                    _stable.enabled = false
                    if _stable.watchConn then
                        _stable.watchConn:Disconnect()
                        _stable.watchConn = nil
                    end
                    local remote = NetEvents.RF_UpdateAutoFishingState
                    if remote then pcall(function() remote:InvokeServer(false) end) end
                    pcall(function() LocalPlayer:SetAttribute("Loading", false) end)
                end
            end,
        })
    end

    do
        local _legit = {
            active      = false,
            autoShaking = false,
            settings    = { clickWait = 0, shakeDelay = 0.05 },
            fishThread  = nil,
            shakeThread = nil,
            watchConn   = nil,
        }
        local _replionData = nil
        local function _getController()
            if not fishingController then
                local folder = ReplicatedStorage:FindFirstChild("Controllers")
                local module = folder and folder:FindFirstChild("FishingController")
                if not module then return nil end
                fishingController = require(module)
            end
            return fishingController
        end
        local function _getReplion()
            if _replionData then return _replionData end
            _replionData = getCachedReplionData()
            return _replionData
        end
        local function _setAutoFishing(state)
            local remote = NetEvents.RF_UpdateAutoFishingState
            if not remote then return false end
            local ok = pcall(function() remote:InvokeServer(state) end)
            return ok
        end
        local LegitSection = FishingTab:AddSection("Legit Fishing", false)
        LegitSection:AddInput({
            Title    = "Shake Delay",
            Default  = "0.05",
            Callback = function(value)
                local num = tonumber(value)
                if num and num >= 0 then
                    _legit.settings.clickWait  = num
                    _legit.settings.shakeDelay = num
                end
            end,
        })
        LegitSection:AddToggle({
            Title    = "Enable Legit Fishing",
            Default  = false,
            Callback = function(on)
                if on then
                    local ctrl = _getController()
                    if not ctrl then return end
                    local replionData = _getReplion()
                    if not replionData then return end
                    if not _setAutoFishing(true) then return end
                    if _fishingActive then return end
                    _fishingActive = true
                    _legit.active = true
                    _legit.watchConn = replionData:OnChange("AutoFishing", function(newState)
                        if _legit.active and not newState then
                            _setAutoFishing(true)
                        end
                    end)
                    _legit.fishThread = task.spawn(function()
                        while _legit.active do
                            if _G.AutoMineActive then task.wait(1); continue end
                            pcall(function()
                                if ctrl:GetCurrentGUID() then ctrl:RequestFishingMinigameClick() end
                            end)
                            task.wait(_legit.settings.clickWait)
                        end
                    end)
                else
                    _fishingActive = false
                    _legit.active = false
                    if _legit.watchConn  then _legit.watchConn:Disconnect();    _legit.watchConn  = nil end
                    if _legit.fishThread then task.cancel(_legit.fishThread);    _legit.fishThread = nil end
                    _setAutoFishing(false)
                end
            end,
        })

        LegitSection:AddToggle({
            Title    = "Auto Shake (klik terus)",
            Default  = false,
            Callback = function(on)
                if on then
                    local ctrl = _getController()
                    if not ctrl then return end
                    _legit.autoShaking = true
                    _legit.shakeThread = task.spawn(function()
                        while _legit.autoShaking do
                            if _G.AutoMineActive then task.wait(1); continue end
                            pcall(function() ctrl:RequestFishingMinigameClick() end)
                            task.wait(_legit.settings.shakeDelay)
                        end
                    end)
                else
                    _legit.autoShaking = false
                    if _legit.shakeThread then task.cancel(_legit.shakeThread); _legit.shakeThread = nil end
                end
            end,
        })
    end

    do
        local _instant = {
            active        = false,
            castMode      = "normal",
            completeDelay = 0.04,
            loopThread    = nil,
        }
        local function _safe(fn) task.spawn(function() pcall(fn) end) end
        local InstantSection = FishingTab:AddSection("Instant Fishing")
        InstantSection:AddDropdown({
            Title    = "Mode Cast",
            Options  = { "Normal", "Perfect" },
            Default  = "Normal",
            Callback = function(v) _instant.castMode = v:lower() end,
        })
        InstantSection:AddInput({
            Title    = "Instant Delay",
            Default  = "0.04",
            Callback = function(v)
                local n = tonumber(v)
                if n then _instant.completeDelay = n end
            end,
        })
        local function calcPower(chargeTime, atTime)
            local speed   = Random.new(chargeTime):NextInteger(4, 10)
            local elapsed = (atTime or workspace:GetServerTimeNow()) - chargeTime
            local angle   = math.pi / 2 + elapsed * speed
            return (1 - math.sin(angle)) / 2, speed
        end
        local function findPerfectTime(chargeTime, threshold, maxK)
            local speed = Random.new(chargeTime):NextInteger(4, 10)
            threshold   = threshold or 0.99
            maxK        = maxK or 3
            local best  = math.huge
            for k = 0, maxK do
                local t = math.pi * (1 + 2 * k) / speed
                if t > 0 and t < best then
                    best = t
                    break
                end
            end
            return chargeTime + best, speed
        end
        InstantSection:AddToggle({
            Title    = "Enable Instant",
            Default  = false,
            Callback = function(on)
                if on then
                    if not NetEvents.IsInitialized then return end
                    _instant.active     = true
                    _instant.loopThread = task.spawn(function()
                        autoEquipRod()
                        if not _instant.active then return end
                        local latency = 0
                        while _instant.active do
                            if _G.AutoMineActive then task.wait(1); continue end
                            if not NetEvents.IsInitialized then task.wait(1); continue end
                            if _instant.castMode == "perfect" then
                                local chargeTime = workspace:GetServerTimeNow()
                                local perfectAbsTime, speed = findPerfectTime(chargeTime, 0.99)
                                local ok, serverTime = safeFire(function()
                                    return NetEvents.RF_ChargeFishingRod:InvokeServer(nil, nil, chargeTime, nil)
                                end)
                                local actualCharge = (ok and serverTime and type(serverTime) == "number")
                                    and serverTime or chargeTime
                                if actualCharge ~= chargeTime then
                                    perfectAbsTime, speed = findPerfectTime(actualCharge, 0.99)
                                end
                                local waitDur = perfectAbsTime - workspace:GetServerTimeNow() - latency
                                if waitDur > 0 then task.wait(waitDur) end
                                local now        = workspace:GetServerTimeNow()
                                local power, _   = calcPower(actualCharge, now)
                                power            = math.clamp(power, 0, 1)
                                safeFire(function()
                                    NetEvents.RF_RequestMinigame:InvokeServer(-1.2, power, actualCharge)
                                end)
                                if _instant.completeDelay > 0 then task.wait(_instant.completeDelay) end
                                safeFire(function() NetEvents.RE_FishingCompleted:FireServer() end)
                                task.wait(0.1)
                            else
                                local sTime = workspace:GetServerTimeNow()
                                task.spawn(function()
                                    NetEvents.RF_ChargeFishingRod:InvokeServer(nil, nil, sTime, nil)
                                end)
                                safeFire(function()
                                    NetEvents.RF_RequestMinigame:InvokeServer(-1.2, 0.5, sTime)
                                end)
                                if _instant.completeDelay > 0 then task.wait(_instant.completeDelay) end
                                task.spawn(function() NetEvents.RE_FishingCompleted:FireServer() end)
                                task.wait(0.1)
                            end
                        end
                    end)
                else
                    _instant.active = false
                    if _instant.loopThread then
                        task.cancel(_instant.loopThread)
                        _instant.loopThread = nil
                    end
                    safeFire(function() NetEvents.RF_CancelFishingInputs:InvokeServer() end)
                end
            end,
        })
    end

    do
        local _ifr = {
            active       = false,
            castMode     = "normal",
            settings     = { completeDelay = 0.02, baitSpeed = 99999, notifMult = 1.34 },
            loopThread   = nil,
            animConn     = nil,
            connections  = {},
            curveUtil    = nil, origCurve    = nil,
            notifCtrl    = nil, origDeliver  = nil, notifHooked = false,
        }
        local IFRSection = FishingTab:AddSection("Instant Fast Reel [BETA]", false)
        IFRSection:AddDropdown({
            Title    = "Mode",
            Default  = "normal",
            Options  = { "normal", "perfect" },
            Callback = function(value) _ifr.castMode = value end,
        })
        IFRSection:AddInput({
            Title    = "Complete Delay",
            Default  = "0.02",
            Callback = function(value)
                local num = tonumber(value)
                if num and num >= 0 then _ifr.settings.completeDelay = num end
            end,
        })
        IFRSection:AddToggle({
            Title    = "Instant Fast Reel",
            Default  = false,
            Callback = function(on)
                if on then
                    if not NetEvents.IsInitialized then return end
                    if _fishingActive then return end
                    _fishingActive = true
                    _ifr.active    = true
                    pcall(function()
                        local cu = require(ReplicatedStorage.Modules.Util.CurveUtil)
                        _ifr.curveUtil = cu
                        _ifr.origCurve = cu.GetCurveBetween
                        cu.GetCurveBetween = function(params)
                            if not _ifr.active then return _ifr.origCurve(params) end
                            local finishPos = params.finish or params["finish"]
                            if (_ifr.settings.baitSpeed or 999) >= 99 then
                                return { CFrame.new(finishPos), CFrame.new(finishPos) }
                            end
                            local orig   = _ifr.origCurve(params)
                            local total  = #orig
                            local target = math.max(2, math.floor(total / _ifr.settings.baitSpeed))
                            local result = {}
                            for i = 1, target do
                                local idx = math.clamp(math.round((i-1)/(target-1)*(total-1))+1, 1, total)
                                table.insert(result, orig[idx])
                            end
                            return result
                        end
                    end)
                    pcall(function()
                        local nc = require(ReplicatedStorage.Controllers.TextNotificationController)
                        _ifr.notifCtrl   = nc
                        _ifr.origDeliver = nc.DeliverNotification
                        _ifr.notifHooked = true
                        nc.DeliverNotification = function(selfArg, params)
                            params = table.clone(params)
                            if not params.CustomDuration then
                                local base = 3
                                if params.Type == "Location" then base = 4
                                elseif params.Type == "Event" then base = 5 end
                                params.CustomDuration = base * _ifr.settings.notifMult
                            else
                                params.CustomDuration = params.CustomDuration * _ifr.settings.notifMult
                            end
                            return _ifr.origDeliver(selfArg, params)
                        end
                    end)
                    local blockedVFX     = { ["Bait Dive"] = true, ["Water Impact"] = true }
                    local cosmeticFolder = workspace:WaitForChild("CosmeticFolder", 10)
                    if cosmeticFolder then
                        for _, child in ipairs(cosmeticFolder:GetChildren()) do
                            if blockedVFX[child.Name] then child.Parent = nil end
                        end
                        table.insert(_ifr.connections, cosmeticFolder.ChildAdded:Connect(function(child)
                            if _ifr.active and blockedVFX[child.Name] then child.Parent = nil end
                        end))
                    end
                    local _ifrAnimSkip = 0
                    _ifr.animConn = RunService.Heartbeat:Connect(function()
                        if not _ifr.active then return end
                        if _G.AutoMineActive then return end
                        _ifrAnimSkip = _ifrAnimSkip + 1
                        if _ifrAnimSkip < 3 then return end
                        _ifrAnimSkip = 0
                        local char = LocalPlayer.Character
                        if not char then return end
                        local hum = char:FindFirstChildOfClass("Humanoid")
                        if not hum then return end
                        local animator = hum:FindFirstChildOfClass("Animator")
                        if not animator then return end
                        for _, track in pairs(animator:GetPlayingAnimationTracks()) do
                            if track.Name:find("Reel") or track.Name:find("Fish") then
                                track:Stop(0)
                            end
                        end
                    end)
                    _ifr.loopThread = task.spawn(function()
                        autoEquipRod()
                        if not _ifr.active then return end
                        while _ifr.active do
                            if _G.AutoMineActive then task.wait(1); continue end
                            if not NetEvents.IsInitialized then task.wait(1); continue end
                            if _ifr.castMode == "perfect" then
                                local sTime     = workspace:GetServerTimeNow()
                                local speed     = Random.new(sTime):NextInteger(4, 10)
                                local bestDelay = math.huge
                                for k = 0, 10 do
                                    local d = (math.pi * (1 + 2 * k)) / speed
                                    if d > 0 and d < bestDelay then bestDelay = d end
                                end
                                local chargeTime  = sTime
                                local perfectTime = sTime + bestDelay
                                safeFire(function() NetEvents.RF_ChargeFishingRod:InvokeServer(nil, nil, chargeTime, nil) end)
                                local waitTime = perfectTime - workspace:GetServerTimeNow() - 0.01
                                if waitTime > 0 then task.wait(waitTime) end
                                local speed2 = Random.new(chargeTime):NextInteger(4, 10)
                                local power  = math.clamp(
                                    (1 - math.sin(math.pi / 2 + (workspace:GetServerTimeNow() - chargeTime) * speed2)) / 2,
                                    0, 1
                                )
                                safeFire(function() NetEvents.RF_RequestMinigame:InvokeServer(-1.2, power, chargeTime) end)
                                task.wait(_ifr.settings.completeDelay)
                                safeFire(function() NetEvents.RE_FishingCompleted:FireServer() end)
                                task.wait(0.1)
                            else
                                local sTime = workspace:GetServerTimeNow()
                                task.spawn(function() NetEvents.RF_ChargeFishingRod:InvokeServer(nil, nil, sTime, nil) end)
                                safeFire(function() NetEvents.RF_RequestMinigame:InvokeServer(-1.2, 0.5, sTime) end)
                                task.wait(_ifr.settings.completeDelay)
                                task.spawn(function() NetEvents.RE_FishingCompleted:FireServer() end)
                                task.wait(0.1)
                            end
                        end
                    end)
                    Library:MakeNotify({
                        Title       = "Instant Fast Reel",
                        Description = "Mode: " .. _ifr.castMode,
                        Delay       = 2,
                    })
                else
                    _fishingActive = false
                    _ifr.active    = false
                    if _ifr.loopThread then task.cancel(_ifr.loopThread); _ifr.loopThread = nil end
                    if _ifr.animConn   then _ifr.animConn:Disconnect();   _ifr.animConn   = nil end
                    if _ifr.curveUtil and _ifr.origCurve then
                        _ifr.curveUtil.GetCurveBetween = _ifr.origCurve
                        _ifr.curveUtil = nil
                        _ifr.origCurve = nil
                    end
                    if _ifr.notifHooked and _ifr.notifCtrl then
                        _ifr.notifCtrl.DeliverNotification = _ifr.origDeliver
                        _ifr.notifHooked = false
                    end
                    for _, c in ipairs(_ifr.connections) do c:Disconnect() end
                    _ifr.connections = {}
                    pcall(function() NetEvents.RF_CancelFishingInputs:InvokeServer() end)
                    Library:MakeNotify({
                        Title       = "Instant Fast Reel",
                        Description = "Dimatikan.",
                        Delay       = 2,
                    })
                end
            end,
        })
    end

    do
        local _ub = {
            active        = false,
            completeDelay = 0.04,
            spamDelay     = 0.1,
            loopThread    = nil,
            fishConn      = nil,
            playFXConn    = nil,
            onChangeConn  = nil,
            notifConn     = nil,
            origSet       = nil,
            hooksReady    = false,
        }
        local cachedAreas, cachedTiers, cachedItems, cachedReplionData
        local function getAreas()
            if not cachedAreas then
                pcall(function() cachedAreas = cachedRequire(ReplicatedStorage.Areas) end)
            end
            return cachedAreas
        end
        local function getTiers()
            if not cachedTiers then
                pcall(function() cachedTiers = cachedRequire(ReplicatedStorage.Tiers) end)
            end
            return cachedTiers
        end
        local function getItems()
            if not cachedItems then
                pcall(function() cachedItems = cachedRequire(ReplicatedStorage.Items) end)
            end
            return cachedItems
        end
        local function getReplionData()
            if not cachedReplionData then
                cachedReplionData = getCachedReplionData()
            end
            return cachedReplionData
        end
        local lastRodTier, isSpoofing, isVisualFiring = 2, false, false
        local goldCounter, rainbowCounter, bagCounter, isCounterLocked, isOurOwnSet = 0, 0, 0, false, false
        _G._lynxVisualUUIDs = {}
        local ALLOWED_ROD_IDS = { [559] = true, [257] = true }
        local TIER_COLOR_SEQUENCES = {
            [1] = ColorSequence.new(Color3.fromRGB(255, 250, 246)),
            [2] = ColorSequence.new(Color3.fromRGB(195, 255, 85)),
            [3] = ColorSequence.new(Color3.fromRGB(85, 162, 255)),
            [4] = ColorSequence.new(Color3.fromRGB(178, 114, 247)),
            [5] = ColorSequence.new({
                ColorSequenceKeypoint.new(0,   Color3.fromRGB(255, 184, 42)),
                ColorSequenceKeypoint.new(0.6, Color3.fromRGB(255, 184, 42)),
                ColorSequenceKeypoint.new(1,   Color3.fromRGB(255, 232, 142)),
            }),
            [6] = ColorSequence.new({
                ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 24, 24)),
                ColorSequenceKeypoint.new(1, Color3.fromRGB(102, 0,  0)),
            }),
            [7] = ColorSequence.new({
                ColorSequenceKeypoint.new(0, Color3.fromRGB(23,  255, 151)),
                ColorSequenceKeypoint.new(1, Color3.fromRGB(11,  149, 255)),
            }),
        }
        local function _connectPlayFXListener()
            if _ub.playFXConn then return end
            local playFX = NetEvents.RE_PlayFishEffect
            if playFX then
                _ub.playFXConn = playFX.OnClientEvent:Connect(function(player, _, tierValue)
                    if player == LocalPlayer
                        and not isSpoofing
                        and type(tierValue) == "number"
                        and tierValue > 0
                    then
                        lastRodTier = tierValue
                    end
                end)
            end
        end
        local function incrementCounters(amount)
            if isCounterLocked then return end
            isCounterLocked = true
            amount = amount or 1
            goldCounter    = goldCounter + amount
            rainbowCounter = rainbowCounter + amount
            bagCounter     = bagCounter + amount
            if goldCounter    > 10 then goldCounter    = 1 end
            if rainbowCounter > 40 then rainbowCounter = 1 end
            local replionData = getReplionData()
            if replionData then
                isOurOwnSet = true
                pcall(function() replionData:_set("Modifiers.Golden",             goldCounter) end)
                pcall(function() replionData:_set("Modifiers.Rainbow",            rainbowCounter) end)
                pcall(function() replionData:_set("InventoryNotifications.Fish",  bagCounter) end)
                isOurOwnSet = false
            end
            isCounterLocked = false
        end
        local function getTierFromChance(chance)
            local tiers = getTiers()
            if not tiers then return 1 end
            local bestTier = 1
            for _, tierData in pairs(tiers) do
                if type(tierData) == "table"
                    and tierData.Rarity
                    and tierData.Tier
                    and chance <= tierData.Rarity
                    and tierData.Tier > bestTier
                    and tierData.Tier <= 7
                then
                    bestTier = tierData.Tier
                end
            end
            return bestTier
        end
        local function getFishIdByName(fishName)
            local items = getItems()
            if not items then return 0 end
            for _, itemData in pairs(items) do
                if itemData.Data
                    and itemData.Data.Name == fishName
                    and itemData.Data.Type == "Fish"
                then
                    return itemData.Data.Id or 0
                end
            end
            return 0
        end
        local function getTierColorByFishName(fishName)
            local items = getItems()
            if not items then return TIER_COLOR_SEQUENCES[1] end
            for _, itemData in pairs(items) do
                if itemData.Data
                    and itemData.Data.Name == fishName
                    and itemData.Data.Type == "Fish"
                then
                    return TIER_COLOR_SEQUENCES[itemData.Data.Tier or 1] or TIER_COLOR_SEQUENCES[1]
                end
            end
            return TIER_COLOR_SEQUENCES[1]
        end
        local function getEquippedRodTier()
            local replionData = getReplionData()
            if not replionData then return lastRodTier end
            local equippedUUID = replionData:Get("EquippedId")
            if not equippedUUID or equippedUUID == "" then return lastRodTier end
            local fishingRods = replionData:Get("Inventory.Fishing Rods") or {}
            for _, rod in ipairs(fishingRods) do
                if rod.UUID == equippedUUID then
                    local allItems = getItems() or {}
                    for _, itemData in pairs(allItems) do
                        if itemData.Data
                            and tostring(itemData.Data.Id) == tostring(rod.Id)
                            and itemData.Data.Type == "Fishing Rods"
                        then
                            return itemData.Data.Tier or lastRodTier
                        end
                    end
                end
            end
            return lastRodTier
        end
        local function isEquippedRodAllowed()
            local replionData = getReplionData()
            if not replionData then return false end
            local equippedUUID = replionData:Get("EquippedId")
            if not equippedUUID or equippedUUID == "" then return false end
            local fishingRods = replionData:Get("Inventory.Fishing Rods") or {}
            for _, rod in ipairs(fishingRods) do
                if rod.UUID == equippedUUID then
                    return ALLOWED_ROD_IDS[rod.Id] == true
                end
            end
            return false
        end
        local function getPlayerLocation()
            local success, locationValue = pcall(function() return LocalPlayer.LocationName end)
            if success and locationValue and tostring(locationValue) ~= "" then
                return tostring(locationValue)
            end
            local character = LocalPlayer.Character
            if character then
                local attr = character:GetAttribute("LocationName")
                if attr and tostring(attr) ~= "" then return tostring(attr) end
            end
            local playerAttr = LocalPlayer:GetAttribute("LocationName")
            if playerAttr and tostring(playerAttr) ~= "" then return tostring(playerAttr) end
        end
        local function calculateCastPosition()
            local character = LocalPlayer.Character
            if not character then
                return Vector3.zero, Vector3.new(0, 6, 0)
            end
            local rootPart = character:FindFirstChild("HumanoidRootPart")
            if not rootPart then
                return Vector3.zero, Vector3.new(0, 6, 0)
            end
            local forwardDirection = rootPart.CFrame.LookVector
            local castTarget = rootPart.Position + forwardDirection * 10
            local rayParams = RaycastParams.new()
            rayParams.FilterType = Enum.RaycastFilterType.Exclude
            rayParams.FilterDescendantsInstances = { character }
            local rayResult = Workspace:Raycast(
                castTarget + Vector3.new(0, 50, 0),
                Vector3.new(0, -150, 0),
                rayParams
            )
            local castPosition  = rayResult and (rayResult.Position + Vector3.new(0, 0.1, 0))
                                  or (castTarget + Vector3.new(0, -5, 0))
            local originPosition = rootPart.Position + forwardDirection * 5 + Vector3.new(0, 6.5, 0)
            return castPosition, originPosition
        end
        local function getFishListByTiers(tierList)
            local items = getItems()
            local areas = getAreas()
            if not items or not areas then return {} end
            local locationName = getPlayerLocation()
            local currentArea  = (locationName and areas[locationName]) or areas["Fisherman Island"]
            if not currentArea or not currentArea.Items then return {} end
            local result = {}
            for _, fishName in ipairs(currentArea.Items) do
                for _, itemData in pairs(items) do
                    if itemData.Data
                        and itemData.Data.Name == fishName
                        and itemData.Data.Type == "Fish"
                    then
                        local fishTier = (itemData.Probability and itemData.Probability.Chance
                            and getTierFromChance(itemData.Probability.Chance))
                            or itemData.Data.Tier or 1

                        for _, targetTier in ipairs(tierList) do
                            if fishTier == targetTier then
                                table.insert(result, { Name = fishName, Id = itemData.Data.Id or 0 })
                                break
                            end
                        end
                        break
                    end
                end
            end
            return result
        end
        local function generateUUID()
            return ("xxxxxxxx-xxxx-4xxx-yxxx-xxxxxxxxxxxx"):gsub("[xy]", function(char)
                return string.format("%x",
                    char == "x" and math.random(0, 15) or math.random(8, 11)
                )
            end)
        end
        local function getEquippedRodName()
            local success, value = pcall(function() return LocalPlayer.FishingRod end)
            return (success and value and tostring(value) ~= "" and tostring(value)) or ""
        end
        local function getEquippedRodSkin()
            local success, value = pcall(function() return LocalPlayer.FishingRodSkin end)
            return (success and value and tostring(value) ~= "" and tostring(value)) or ""
        end
        local _lynxUUIDCount = 0
        for _ in pairs(_G._lynxVisualUUIDs) do _lynxUUIDCount += 1 end
        local function spoofFishCaughtVisual(fish)
            if isSpoofing then return end
            isSpoofing = true
            local uuid      = generateUUID()
            _G._lynxVisualUUIDs[uuid] = true
            _lynxUUIDCount += 1
            if _lynxUUIDCount > 200 then
                _G._lynxVisualUUIDs = {}
                _G._lynxVisualUUIDs[uuid] = true
                _lynxUUIDCount = 1
            end
            local fishId    = fish.Id
            local fishName  = fish.Name
            local weight    = math.random(100, 2500) / 700
            local castPosition, originPosition = calculateCastPosition()
            local headPart = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("Head")
                       or LocalPlayer.Character
            pcall(function()
                firesignal(NetEvents.RE_BaitCastVisual.OnClientEvent,
                    LocalPlayer,
                    {
                        CastPosition     = castPosition,
                        Power            = 0.86895783044309,
                        RodName          = getEquippedRodName(),
                        CosmeticTemplateId = -1,
                        EquippedToolModel  = LocalPlayer.Character
                            and LocalPlayer.Character:FindFirstChild("!!!EQUIPPED_TOOL!!!") or nil,
                        ConnectingJoint  = 0,
                        NoFishingZone    = false,
                        BaitIdentifier   = 3,
                        Origin           = originPosition,
                        CustomModel      = false,
                    }
                )
            end)
            pcall(function()
                firesignal(NetEvents.RE_PlayFishEffect.OnClientEvent, LocalPlayer, headPart, getEquippedRodTier())
            end)
            pcall(function()
                firesignal(NetEvents.RE_BaitSpawned.OnClientEvent,
                    LocalPlayer,
                    getEquippedRodSkin(),
                    Vector3.new(castPosition.X, castPosition.Y + 0.1, castPosition.Z)
                )
            end)
            isSpoofing = false
            task.wait(0.05)
            pcall(function()
                firesignal(NetEvents.RE_TextEffect.OnClientEvent,
                    {
                        Channel  = "All",
                        TextData = {
                            AttachTo   = headPart,
                            Text       = "!",
                            TextColor  = getTierColorByFishName(fishName),
                            EffectType = "Exclaim",
                        },
                        Duration  = 0.5,
                        Container = headPart,
                    }
                )
            end)

            pcall(function()
                local replionData = getReplionData()
                if not replionData then return end
                local inventory = replionData:Get("Inventory.Items") or {}
                local newItem = {
                    Id        = fishId,
                    Favorited = false,
                    UUID      = uuid,
                    Metadata  = { Weight = weight },
                }
                table.insert(inventory, newItem)
                replionData:_set("Inventory.Items", inventory)
            end)
            isVisualFiring = true
            pcall(function()
                firesignal(NetEvents.RE_ObtainedNewFishNotification.OnClientEvent,
                    fishId,
                    { Weight = weight },
                    {
                        CustomDuration = 5,
                        InventoryItem  = { Id = fishId, Favorited = false, UUID = uuid, Metadata = { Weight = weight } },
                        ItemType       = "Fish",
                        _newlyIndexed  = false,
                        Type           = "Item",
                        ItemId         = fishId,
                    },
                    false
                )
            end)
            incrementCounters(1)
            isVisualFiring = false
            isSpoofing = true
            pcall(function()
                firesignal(NetEvents.RE_FishCaught.OnClientEvent, fishName, { Weight = weight }, 0, 0)
            end)
            task.wait(0.1)
            isSpoofing = false
            pcall(function()
                firesignal(NetEvents.RE_FishCaughtVisual.OnClientEvent,
                    LocalPlayer, castPosition, fishName, { Weight = weight }
                )
            end)
        end
        local function _setupReplionHooks()
            if _ub.hooksReady then return end
            local replionData = getReplionData()
            if not replionData then return end
            _ub.hooksReady = true
            local modifiers = replionData:Get("Modifiers")
            if modifiers then
                goldCounter    = modifiers.Golden  or 0
                rainbowCounter = modifiers.Rainbow or 0
            end
            local inventoryNotifications = replionData:Get("InventoryNotifications")
            if inventoryNotifications then
                bagCounter = inventoryNotifications.Fish or 0
            end
            pcall(function()
                _ub.onChangeConn = replionData:OnChange("InventoryNotifications.Fish", function(newValue)
                    if newValue == 0 then bagCounter = 0 end
                end)
            end)
            _ub.origSet = replionData._set
            replionData._set = function(selfArg, path, value)
                if isOurOwnSet then
                    return _ub.origSet(selfArg, path, value)
                end
                if path == "Modifiers.Golden"            then return _ub.origSet(selfArg, path, goldCounter) end
                if path == "Modifiers.Rainbow"           then return _ub.origSet(selfArg, path, rainbowCounter) end
                if path == "InventoryNotifications.Fish" then return _ub.origSet(selfArg, path, bagCounter) end
                return _ub.origSet(selfArg, path, value)
            end
            if NetEvents.RE_ObtainedNewFishNotification then
                _ub.notifConn = NetEvents.RE_ObtainedNewFishNotification.OnClientEvent:Connect(function()
                    if not isVisualFiring then
                        incrementCounters(1)
                    end
                end)
            end
        end
        local function _cleanupReplionHooks()
            if _ub.playFXConn then _ub.playFXConn:Disconnect(); _ub.playFXConn = nil end
            if _ub.onChangeConn then pcall(function() _ub.onChangeConn:Disconnect() end); _ub.onChangeConn = nil end
            if _ub.notifConn then _ub.notifConn:Disconnect(); _ub.notifConn = nil end
            if _ub.origSet then
                local replionData = getReplionData()
                if replionData then replionData._set = _ub.origSet end
                _ub.origSet = nil
            end
            _ub.hooksReady = false
        end
        local UBSection = FishingTab:AddSection("Ini Blatant kayaknya [Visual]", false)
        UBSection:AddInput({
            Title    = "Fishing Complete Delay",
            Default  = "0.3",
            Callback = function(value)
                local num = tonumber(value)
                if num and num >= 0 then _ub.completeDelay = num end
            end,
        })
        UBSection:AddToggle({
            Title    = "Enable Ultra Blatant",
            Default  = false,
            NoSave   = true,
            Callback = function(on)
                if on then
                    if not NetEvents.IsInitialized then return end
                    if _fishingActive then warn("[Module] Fishing lain sudah aktif!"); return end
                    _fishingActive = true
                    _ub.active     = true
                    _connectPlayFXListener()
                    _setupReplionHooks()
                    _ub.loopThread = task.spawn(function()
                        while _ub.active do
                            if _G.AutoMineActive then task.wait(1); continue end
                            local sTime = tick()
                            pcall(function() NetEvents.RF_ChargeFishingRod:InvokeServer({ [1] = sTime }) end)
                            pcall(function() NetEvents.RF_RequestMinigame:InvokeServer(1, 0, sTime) end)
                            task.wait(_ub.completeDelay)
                            pcall(function() NetEvents.RE_FishingCompleted:FireServer() end)
                            task.wait(_ub.spamDelay)
                        end
                    end)
                    task.spawn(function()
                        local elapsed = 0
                        while not NetEvents.RE_FishCaught and elapsed < 10 do
                            task.wait(0.5); elapsed += 0.5
                        end
                        if not NetEvents.RE_FishCaught then return end
                        _ub.fishConn = NetEvents.RE_FishCaught.OnClientEvent:Connect(function(fishName)
                            if not _ub.active or isSpoofing or not isEquippedRodAllowed() then return end
                            task.spawn(function()
                                if _ub.completeDelay > 0 then task.wait(_ub.completeDelay) end
                                local selectedFish
                                if fishName and fishName ~= "" then
                                    local items    = getItems()
                                    local fishTier = 1
                                    if items then
                                        for _, itemData in pairs(items) do
                                            if itemData.Data
                                                and itemData.Data.Name == fishName
                                                and itemData.Data.Type == "Fish"
                                            then
                                                fishTier = (itemData.Probability and itemData.Probability.Chance
                                                    and getTierFromChance(itemData.Probability.Chance))
                                                    or itemData.Data.Tier or 1
                                                break
                                            end
                                        end
                                    end
                                    if fishTier >= 4 then
                                        local rare     = getFishListByTiers({ 3 })
                                        local uncommon = getFishListByTiers({ 2 })
                                        if math.random(1, 10) <= 8 and #rare > 0 then
                                            selectedFish = rare[math.random(1, #rare)]
                                        elseif #uncommon > 0 then
                                            selectedFish = uncommon[math.random(1, #uncommon)]
                                        elseif #rare > 0 then
                                            selectedFish = rare[math.random(1, #rare)]
                                        end
                                    else
                                        if math.random(1, 10) <= 7 then
                                            selectedFish = { Name = fishName, Id = getFishIdByName(fishName) }
                                        else
                                            local sameTier = getFishListByTiers({ fishTier })
                                            local other    = {}
                                            for _, f in ipairs(sameTier) do
                                                if f.Name ~= fishName then table.insert(other, f) end
                                            end
                                            selectedFish = (#other > 0 and other[math.random(1, #other)])
                                                        or { Name = fishName, Id = getFishIdByName(fishName) }
                                        end
                                    end
                                end
                                if selectedFish then spoofFishCaughtVisual(selectedFish) end
                            end)
                        end)
                    end)
                else
                    _fishingActive = false
                    _ub.active = false
                    if _ub.loopThread then task.cancel(_ub.loopThread); _ub.loopThread = nil end
                    if _ub.fishConn   then _ub.fishConn:Disconnect();   _ub.fishConn   = nil end
                    _cleanupReplionHooks()
                    pcall(function() NetEvents.RF_CancelFishingInputs:InvokeServer() end)
                end
            end,
        })
    end

    do
        local _bv2 = {
            active   = false,
            settings = { completeDelay = 0.01, spamDelay = 0.05, chargeSpam = 2 },
            thread   = nil,
            minConn  = nil,
        }
        local function _safe(fn) task.spawn(function() pcall(fn) end) end
        local BV2Section = FishingTab:AddSection("Blatant V2 [BETA]")
        BV2Section:AddToggle({
            Title    = "Enable Blatant V2",
            Default  = false,
            Callback = function(on)
                if on then
                    if not NetEvents.IsInitialized then
                        warn("[BlatantV2] EventResolver belum siap!"); return
                    end
                    if _fishingActive then warn("[Module] Fishing lain sudah aktif!"); return end
                    _fishingActive = true
                    _bv2.active    = true
                    if NetEvents.RE_MinigameChanged then
                        _bv2.minConn = NetEvents.RE_MinigameChanged.OnClientEvent:Connect(function()
                            if not _bv2.active then return end
                            pcall(function() NetEvents.RE_FishingCompleted:FireServer() end)
                        end)
                    end
                    _bv2.thread = task.spawn(function()
                        autoEquipRod()
                        if not _bv2.active then return end
                        while _bv2.active do
                            if _G.AutoMineActive then task.wait(1); continue end
                            if not NetEvents.IsInitialized then continue end
                            local sTime = tick()
                            for i = 1, _bv2.settings.chargeSpam do
                                _safe(function() NetEvents.RF_ChargeFishingRod:InvokeServer({ [1] = sTime }) end)
                                _safe(function() NetEvents.RF_RequestMinigame:InvokeServer(1, 0, sTime) end)
                                if i < _bv2.settings.chargeSpam then task.wait(0.05) end
                            end
                            task.wait(_bv2.settings.completeDelay)
                            _safe(function() NetEvents.RE_FishingCompleted:FireServer() end)
                            task.wait(_bv2.settings.spamDelay)
                        end
                    end)
                else
                    _fishingActive = false
                    _bv2.active    = false
                    if _bv2.thread  then task.cancel(_bv2.thread);  _bv2.thread  = nil end
                    if _bv2.minConn then _bv2.minConn:Disconnect(); _bv2.minConn = nil end
                    pcall(function() NetEvents.RF_CancelFishingInputs:InvokeServer() end)
                end
            end,
        })
        BV2Section:AddInput({
            Title    = "Spam Cast Delay v2",
            Default  = "0.05",
            Callback = function(value)
                local num = tonumber(value)
                if num then _bv2.settings.spamDelay = num end
            end,
        })
        BV2Section:AddInput({
            Title    = "Complete Delay v2",
            Default  = "0.01",
            Callback = function(value)
                local num = tonumber(value)
                if num then _bv2.settings.completeDelay = num end
            end,
        })
    end
    do
        local AutoCraftSection = FishingTab:AddSection("Auto Perfect Rod Crafting [BETA]", false)

        local _craftState = {
            enabled   = false,
            thread    = nil,
            eventConn = nil,
        }

        AutoCraftSection:AddParagraph({
            Title   = "Info",
            Content = "Otomatis klik di zona Perfect untuk setiap bar saat minigame crafting rod berlangsung.\nAktifkan lalu klik Craft Rod secara manual di UI crafting.\n⚠️Gatau fitur ini bisa jalan apa enggaa, soalnya belum punya rod buat testing, jadi coba sendiri yaa⚠️",
        })

        local function waitForPerfectTiming(barData, startedAt)
            local RodCraftingMinigame = require(ReplicatedStorage.Shared.RodCraftingMinigame)
            local PERFECT_START = RodCraftingMinigame.PerfectStart or 0.8
            while true do
                local serverTime = Workspace:GetServerTimeNow()
                local pos = RodCraftingMinigame.GetBarPosition(serverTime, startedAt, barData)
                if pos >= PERFECT_START then
                    return
                end
                if (PERFECT_START - pos) > 0.05 then
                    task.wait(0.01)
                else
                    task.wait(0.001)
                end
            end
        end

        local function runAutoCraft(minigameData)
            local RodCraftingMinigame = require(ReplicatedStorage.Shared.RodCraftingMinigame)

            local ClickRemote  = NetEvents.RF_RodCraftingMinigameClick
            local FinishRemote = NetEvents.RF_FinishRodCraftingMinigame

            if not ClickRemote then
                warn("[AutoCraft] RF_RodCraftingMinigameClick not found")
                return
            end

            local startedAt = minigameData.StartedAt
            local bars      = minigameData.Bars
            local barCount  = RodCraftingMinigame.BarCount or 4
            local barIndex  = 1

            while barIndex <= barCount and _craftState.enabled do
                local barData = bars and bars[barIndex]
                if not barData then
                    task.wait(0.1)
                    barIndex += 1
                    continue
                end

                waitForPerfectTiming(barData, startedAt)

                if not _craftState.enabled then break end

                local result
                local ok, err = pcall(function()
                    result = ClickRemote:InvokeServer(barIndex)
                end)

                if not ok then
                    warn("[AutoCraft] Click error:", err)
                    break
                end

                if not result then break end

                if result.Complete then
                    if result.Passed and FinishRemote then
                        task.wait(0.3)
                        pcall(function()
                            FinishRemote:InvokeServer()
                        end)
                    end
                    break
                end

                if result.Accepted then
                    startedAt = result.NextStartedAt or Workspace:GetServerTimeNow()
                    barIndex  = result.NextBarIndex or barIndex + 1
                else
                    task.wait(0.05)
                end
            end
        end

        local function setupHook()
            if _craftState.eventConn then
                pcall(function() _craftState.eventConn:Disconnect() end)
                _craftState.eventConn = nil
            end

            local PlayEvent = NetEvents.RE_PlayRodCraftingMinigame
            if not PlayEvent then
                warn("[AutoCraft] RE_PlayRodCraftingMinigame not found")
                return
            end

            _craftState.eventConn = PlayEvent.OnClientEvent:Connect(function(minigameData)
                if not _craftState.enabled then return end
                if not minigameData then return end

                if _craftState.thread then
                    pcall(task.cancel, _craftState.thread)
                    _craftState.thread = nil
                end

                _craftState.thread = task.spawn(function()
                    task.wait(0.4)
                    if _craftState.enabled then
                        runAutoCraft(minigameData)
                    end
                end)
            end)
        end

        AutoCraftSection:AddToggle({
            Title    = "Enable Auto Perfect Crafting",
            Default  = false,
            NoSave   = true,
            Callback = function(on)
                _craftState.enabled = on

                if _craftState.thread then
                    pcall(task.cancel, _craftState.thread)
                    _craftState.thread = nil
                end

                if on then
                    setupHook()
                    Library:MakeNotify({
                        Title       = "Auto Craft",
                        Description = "Aktif — akan auto perfect saat minigame crafting rod dimulai.",
                        Delay       = 3,
                    })
                else
                    if _craftState.eventConn then
                        pcall(function() _craftState.eventConn:Disconnect() end)
                        _craftState.eventConn = nil
                    end
                    Library:MakeNotify({
                        Title       = "Auto Craft",
                        Description = "Dinonaktifkan.",
                        Delay       = 2,
                    })
                end
            end,
        })
    end
end

-- [Favorite Tab]
local FavoriteTab    = MainWindow:AddTab({ Name = "Favorite", Icon = "star" })
local TIER_NAMES = {
    [1] = "Common",    [2] = "Uncommon", [3] = "Rare",
    [4] = "Epic",      [5] = "Legendary",[6] = "Mythic",
    [7] = "SECRET",    [8] = "FORGOTTEN",
}
do
    local AutoFavSection = FavoriteTab:AddSection("Auto Favorite")
    local _favState = {
        enabled         = false,
        isScanning      = false,
        onChangeHooked  = false,
        selectedName    = {},
        selectedRarity  = {},
        selectedVariant = {},
    }
    local _favCache = {
        refsReady      = false,
        itemUtility    = nil,
        replionData    = nil,
        itemsFolder    = nil,
        variantsFolder = nil,
        variantById    = {},
    }
    local _favFishList, _favVariantList = {}, {}
    local function toSet(arr)
        local s = {}
        for _, v in ipairs(arr) do s[v] = true end
        return s
    end
    local function favInitRefs()
        if _favCache.refsReady then return true end
        local ok = pcall(function()
            _favCache.itemUtility    = cachedRequire(ReplicatedStorage.Shared.ItemUtility)
            _favCache.replionData    = getCachedReplionData()
            _favCache.itemsFolder    = ReplicatedStorage:FindFirstChild("Items")
            _favCache.variantsFolder = ReplicatedStorage:FindFirstChild("Variants")
            _favCache.refsReady      = _favCache.replionData ~= nil
        end)
        return ok and _favCache.refsReady
    end
    local function favBuildFishList()
        _favFishList = {}
        if not _favCache.refsReady or not _favCache.itemsFolder then return end
        local function scanFolder(folder)
            for _, child in ipairs(folder:GetChildren()) do
                if child:IsA("ModuleScript") then
                    local ok, data = pcall(function() return require(child) end)
                    if ok and data and data.Data then
                        local name = data.Data.DisplayName or data.Data.Name
                        if name and not table.find(_favFishList, name) then
                            table.insert(_favFishList, name)
                        end
                    end
                elseif child:IsA("Folder") then
                    scanFolder(child)
                end
            end
        end
        pcall(function()
            scanFolder(_favCache.itemsFolder)
            table.sort(_favFishList)
        end)
    end
    local function favBuildVariantList()
        _favVariantList = {}
        _favCache.variantById = {}
        if not _favCache.refsReady or not _favCache.variantsFolder then return end
        pcall(function()
            for _, m in ipairs(_favCache.variantsFolder:GetChildren()) do
                if m:IsA("ModuleScript") and m.Name ~= "1x1x1x1" then
                    if not table.find(_favVariantList, m.Name) then
                        table.insert(_favVariantList, m.Name)
                    end
                    local ok, data = pcall(function() return require(m) end)
                    if ok and type(data) == "table" then
                        local variantId = data.Id or data.VariantId
                        if variantId == nil and type(data.Data) == "table" then
                            variantId = data.Data.Id or data.Data.VariantId
                        end
                        if variantId ~= nil then
                            _favCache.variantById[variantId] = m.Name
                            _favCache.variantById[tostring(variantId)] = m.Name
                        end
                    end
                end
            end
            table.sort(_favVariantList)
        end)
    end
    local function favGetVariantName(item)
        local md = item and item.Metadata
        if not md then return nil end
        local function cleanVariantName(v)
            if type(v) ~= "string" then return nil end
            local s = v:gsub("^%s+", ""):gsub("%s+$", "")
            if s == "" or s == "None" then return nil end
            return s
        end
        local explicit = md.Variant or md.VariantName or md.MutationName
        local cleanedExplicit = cleanVariantName(explicit)
        if cleanedExplicit then
            return cleanedExplicit
        end
        local variantId = md.VariantId
        if variantId == nil or variantId == "" or variantId == "None" then
            return nil
        end
        local cleanedId = cleanVariantName(variantId)
        if cleanedId and _favState.selectedVariant[cleanedId] then
            return cleanedId
        end
        local fromCache = _favCache.variantById[variantId] or _favCache.variantById[tostring(variantId)]
        if fromCache then return fromCache end
        if _favCache.itemUtility and _favCache.itemUtility.GetVariantData then
            local ok, variantData = pcall(function()
                return _favCache.itemUtility:GetVariantData(variantId)
            end)
            if ok and type(variantData) == "table" then
                local name = variantData.Name
                    or (type(variantData.Data) == "table" and (variantData.Data.Name or variantData.Data.DisplayName))
                if type(name) == "string" and name ~= "" then
                    _favCache.variantById[variantId] = name
                    _favCache.variantById[tostring(variantId)] = name
                    return name
                end
            end
        end
        return nil
    end
    local function favScanInventory()
        if not _favState.enabled   then return end
        if not _favCache.refsReady then return end
        if _favState.isScanning    then return end
        local hasName    = next(_favState.selectedName)    ~= nil
        local hasVariant = next(_favState.selectedVariant) ~= nil
        local hasRarity  = next(_favState.selectedRarity)  ~= nil
        if not hasName and not hasVariant and not hasRarity then return end
        _favState.isScanning = true
        pcall(function()
            local inventory = _favCache.replionData:Get({"Inventory", "Items"})
            if not inventory or typeof(inventory) ~= "table" then return end
            for _, item in ipairs(inventory) do
                if not _favState.enabled then break end
                if item.Favorited == true then continue end
                local fishData = _favCache.itemUtility:GetItemData(item.Id)
                if not fishData or not fishData.Data then continue end
                if fishData.Data.Type ~= "Fish" then continue end
                local fishName  = fishData.Data.DisplayName or fishData.Data.Name
                local fishTier  = fishData.Data.Tier
                local tierName  = TIER_NAMES[fishTier]
                local variantName = favGetVariantName(item)
                local hasItemVariant = variantName ~= nil and variantName ~= ""
                local nameOk, rarityOk, variantOk = true, true, true
                if hasName    then nameOk    = fishName ~= nil and _favState.selectedName[fishName] == true end
                if hasRarity  then rarityOk  = tierName ~= nil and _favState.selectedRarity[tierName] == true end
                if hasVariant then variantOk = hasItemVariant and _favState.selectedVariant[variantName] == true end
                if nameOk and rarityOk and variantOk then
                    pcall(function() NetEvents.RE_FavoriteItem:FireServer(item.UUID) end)
                    task.wait(0.15)
                end
            end
        end)
        _favState.isScanning = false
    end
    local nameUniqueId    = "Name"
    local variantUniqueId = "Variant"
    local rarityUniqueId  = "Rarity"
    local nameConfigPath    = "MultiDropdowns.Name"
    local variantConfigPath = "MultiDropdowns.Variant"
    local rarityConfigPath  = "MultiDropdowns.Rarity"
    local nameDropdownRef    = nil
    local variantDropdownRef = nil
    local _rarityDropdownRef  = nil
    local autoFavToggleRef   = nil
    task.spawn(function()
        if not game:IsLoaded() then game.Loaded:Wait() end
        task.wait(1)
        if not favInitRefs() then
            task.wait(2)
            favInitRefs()
        end
        favBuildFishList()
        favBuildVariantList()
        local savedName    = Library.ConfigSystem.Get(nameConfigPath,    {})
        local savedVariant = Library.ConfigSystem.Get(variantConfigPath, {})
        local savedRarity  = Library.ConfigSystem.Get(rarityConfigPath,  {})
        if nameDropdownRef then
            local flagObj = Library.flags[nameUniqueId]
            if flagObj then
                pcall(function()
                    flagObj:SetValues(
                        #_favFishList > 0 and _favFishList or {"No Fish Found"},
                        type(savedName) == "table" and savedName or {}
                    )
                end)
                if type(savedName) == "table" then
                    _favState.selectedName = toSet(savedName)
                end
            end
        end
        if variantDropdownRef then
            local flagObj = Library.flags[variantUniqueId]
            if flagObj then
                pcall(function()
                    flagObj:SetValues(
                        #_favVariantList > 0 and _favVariantList or {"No Variants Found"},
                        type(savedVariant) == "table" and savedVariant or {}
                    )
                end)
                if type(savedVariant) == "table" then
                    _favState.selectedVariant = toSet(savedVariant)
                end
            end
        end
        if type(savedRarity) == "table" and #savedRarity > 0 then
            local flagObj = Library.flags[rarityUniqueId]
            if flagObj then
                pcall(function() flagObj:Set(savedRarity) end)
                _favState.selectedRarity = toSet(savedRarity)
            end
        end
        if #_favFishList > 0 or #_favVariantList > 0 then
            Library:MakeNotify({
                Title   = "Auto Favorite",
                Content = "Loaded: " .. #_favFishList .. " fish | " .. #_favVariantList .. " variants",
                Delay   = 3,
            })
        end
    end)
    AutoFavSection:AddParagraph({
        Title   = "Filter Logic (AND)",
        Content = "Semua filter aktif bekerja sebagai AND.\n\n" ..
                "• Name saja         → ikan cocok name\n" ..
                "• Rarity saja       → ikan cocok rarity\n" ..
                "• Variant saja      → ikan cocok variant\n" ..
                "• Name + Rarity     → ikan cocok name DAN rarity\n" ..
                "• Name + Variant    → ikan cocok name DAN variant\n" ..
                "• Rarity + Variant  → ikan cocok rarity DAN variant\n" ..
                "• Name+Rarity+Variant → ikan cocok ketiganya\n\n" ..
                "Filter kosong diabaikan.\n" ..
                "Contoh: Mythic + Corrupt → hanya ikan Mythic ber-variant Corrupt.",
    })
    nameDropdownRef = AutoFavSection:AddDropdown({
        Title    = "Name",
        Multi    = true,
        Options  = {"Loading..."},
        Default  = {},
        Callback = function(selected)
            _favState.selectedName = toSet(type(selected) == "table" and selected or {})
            if _favState.enabled then task.spawn(favScanInventory) end
        end,
    })
    variantDropdownRef = AutoFavSection:AddDropdown({
        Title    = "Variant",
        Multi    = true,
        Options  = {"Loading..."},
        Default  = {},
        Callback = function(selected)
            _favState.selectedVariant = toSet(type(selected) == "table" and selected or {})
            if _favState.enabled then task.spawn(favScanInventory) end
        end,
    })
    _rarityDropdownRef = AutoFavSection:AddDropdown({
        Title    = "Rarity",
        Multi    = true,
        Options  = {"Common","Uncommon","Rare","Epic","Legendary","Mythic","SECRET","FORGOTTEN"},
        Default  = {},
        Callback = function(selected)
            _favState.selectedRarity = toSet(type(selected) == "table" and selected or {})
            if _favState.enabled then task.spawn(favScanInventory) end
        end,
    })
    autoFavToggleRef = AutoFavSection:AddToggle({
        Title    = "Auto Favorite",
        Default  = false,
        Callback = function(on)
            if on then
                if not favInitRefs() then
                    Library:MakeNotify({ Title = "Auto Favorite", Content = "Failed to initialize", Delay = 3 })
                    if autoFavToggleRef then
                        pcall(function() autoFavToggleRef:SetValue(false) end)
                    end
                    return
                end
                _favState.enabled = true
                task.spawn(favScanInventory)
                if not _favState.onChangeHooked and _favCache.replionData then
                    _favState.onChangeHooked = true
                    _favCache.replionData:OnChange({"Inventory", "Items"}, function()
                        if _favState.enabled then
                            task.spawn(function()
                                task.wait(0.3)
                                favScanInventory()
                            end)
                        end
                    end)
                end
                Library:MakeNotify({ Title = "Auto Favorite", Content = "Started", Delay = 2 })
            else
                _favState.enabled = false
                Library:MakeNotify({ Title = "Auto Favorite", Content = "Stopped", Delay = 2 })
            end
        end,
    })

    AutoFavSection:AddButton({
        Title    = "Refresh Lists",
        Callback = function()
            local savedName    = Library.ConfigSystem.Get(nameConfigPath,    {})
            local savedVariant = Library.ConfigSystem.Get(variantConfigPath, {})
            _favFishList    = {}
            _favVariantList = {}
            favBuildFishList()
            favBuildVariantList()
            local flagName    = Library.flags[nameUniqueId]
            local flagVariant = Library.flags[variantUniqueId]
            if flagName then
                pcall(function()
                    flagName:SetValues(
                        #_favFishList > 0 and _favFishList or {"No Fish Found"},
                        type(savedName) == "table" and savedName or {}
                    )
                end)
                if type(savedName) == "table" then
                    _favState.selectedName = toSet(savedName)
                end
            end
            if flagVariant then
                pcall(function()
                    flagVariant:SetValues(
                        #_favVariantList > 0 and _favVariantList or {"No Variants Found"},
                        type(savedVariant) == "table" and savedVariant or {}
                    )
                end)
                if type(savedVariant) == "table" then
                    _favState.selectedVariant = toSet(savedVariant)
                end
            end
            Library:MakeNotify({
                Title   = "Refresh",
                Content = "Fish: " .. #_favFishList .. " | Variant: " .. #_favVariantList,
                Delay   = 3,
            })
        end,
    })
end
do
    local UnfavSection = FavoriteTab:AddSection("Un-Favorite")
    UnfavSection:AddParagraph({
        Title   = "Info",
        Content = "Un-favorite ikan yang cocok dengan filter.\n"
               .. "Semua filter aktif bekerja sebagai AND.\n"
               .. "Filter kosong diabaikan.\n\n"
               .. "Contoh: Mythic + Corrupt → hanya un-favorite\n"
               .. "ikan Mythic ber-variant Corrupt.",
    })
    local _unfavState = {
        enabled         = false,
        isScanning      = false,
        selectedName    = {},
        selectedVariant = {},
        selectedRarity  = {},
    }
    local _unfavCache = {
        refsReady   = false,
        replionData = nil,
        itemUtility = nil,
        variantById = {},
    }
    local function unfavToSet(arr)
        local s = {}
        if type(arr) ~= "table" then return s end
        for _, v in ipairs(arr) do s[v] = true end
        return s
    end
    local function unfavInitRefs()
        if _unfavCache.refsReady then return true end
        local ok = pcall(function()
            _unfavCache.replionData = getCachedReplionData()
            _unfavCache.itemUtility = cachedRequire(ReplicatedStorage.Shared.ItemUtility)
        end)
        _unfavCache.refsReady = ok and _unfavCache.replionData ~= nil and _unfavCache.itemUtility ~= nil
        return _unfavCache.refsReady
    end
    local function unfavGetVariantName(item)
        local md = item and item.Metadata
        if not md then return nil end
        local function clean(v)
            if type(v) ~= "string" then return nil end
            local s = v:gsub("^%s+", ""):gsub("%s+$", "")
            if s == "" or s == "None" then return nil end
            return s
        end
        local explicit = md.Variant or md.VariantName or md.MutationName
        local c = clean(explicit)
        if c then return c end
        local variantId = md.VariantId
        if variantId == nil or variantId == "" or variantId == "None" then return nil end
        local cid = clean(variantId)
        if cid and _unfavState.selectedVariant[cid] then return cid end
        local cached = _unfavCache.variantById[variantId] or _unfavCache.variantById[tostring(variantId)]
        if cached then return cached end
        if _unfavCache.itemUtility and _unfavCache.itemUtility.GetVariantData then
            local ok2, vd = pcall(function()
                return _unfavCache.itemUtility:GetVariantData(variantId)
            end)
            if ok2 and type(vd) == "table" then
                local name = vd.Name
                    or (type(vd.Data) == "table" and (vd.Data.Name or vd.Data.DisplayName))
                if type(name) == "string" and name ~= "" then
                    _unfavCache.variantById[variantId] = name
                    _unfavCache.variantById[tostring(variantId)] = name
                    return name
                end
            end
        end
        return nil
    end
    local function unfavScanInventory()
        if not _unfavState.enabled   then return end
        if not _unfavCache.refsReady then
            Library:MakeNotify({ Title = "Un-Fav", Content = "Refs not ready!", Delay = 3 })
            return
        end
        if _unfavState.isScanning    then return end
        local hasName    = next(_unfavState.selectedName)    ~= nil
        local hasVariant = next(_unfavState.selectedVariant) ~= nil
        local hasRarity  = next(_unfavState.selectedRarity)  ~= nil
        if not hasName and not hasVariant and not hasRarity then
            Library:MakeNotify({ Title = "Un-Fav", Content = "No filter selected!", Delay = 3 })
            return
        end
        _unfavState.isScanning = true
        local totalItems, favFish, matched, done = 0, 0, 0, 0
        local scanOk, scanErr = pcall(function()
            local inventory = _unfavCache.replionData:Get({"Inventory", "Items"})
            if not inventory or typeof(inventory) ~= "table" then
                Library:MakeNotify({ Title = "Un-Fav", Content = "Inventory nil!", Delay = 3 })
                return
            end
            totalItems = #inventory
            for _, item in ipairs(inventory) do
                if not _unfavState.enabled then break end
                if item.Favorited ~= true then continue end

                local fishData = _unfavCache.itemUtility:GetItemData(item.Id)
                if not fishData or not fishData.Data then continue end
                if fishData.Data.Type ~= "Fish" then continue end
                favFish += 1
                local fishName  = fishData.Data.DisplayName or fishData.Data.Name
                local fishTier  = fishData.Data.Tier
                local tierName  = TIER_NAMES[fishTier]
                local variantName = unfavGetVariantName(item)
                local hasItemVariant = variantName ~= nil and variantName ~= ""
                local nameOk, rarityOk, variantOk = true, true, true
                if hasName    then nameOk    = fishName ~= nil and _unfavState.selectedName[fishName] == true end
                if hasRarity  then rarityOk  = tierName ~= nil and _unfavState.selectedRarity[tierName] == true end
                if hasVariant then variantOk = hasItemVariant and _unfavState.selectedVariant[variantName] == true end
                if nameOk and rarityOk and variantOk then
                    matched += 1
                    local ok2 = pcall(function() NetEvents.RE_FavoriteItem:FireServer(item.UUID) end)
                    if ok2 then done += 1 end
                    task.wait(0.15)
                end
            end
        end)
        if not scanOk then
            Library:MakeNotify({ Title = "Un-Fav", Content = "Error: " .. tostring(scanErr), Delay = 5 })
        else
            Library:MakeNotify({
                Title = "Un-Fav",
                Content = ("Items:%d FavFish:%d Match:%d Done:%d"):format(totalItems, favFish, matched, done),
                Delay = 5,
            })
        end
        _unfavState.isScanning = false
        _unfavState.enabled = false
    end
    local _unfavFishList    = {}
    local _unfavVariantList = {}
    local function unfavBuildFishList()
        _unfavFishList = {}
        pcall(function()
            local itemsFolder = ReplicatedStorage:FindFirstChild("Items")
            if not itemsFolder then return end
            local function scan(folder)
                for _, child in ipairs(folder:GetChildren()) do
                    if child:IsA("ModuleScript") then
                        local ok2, data = pcall(function() return require(child) end)
                        if ok2 and data and data.Data and data.Data.Type == "Fish" then
                            local name = data.Data.DisplayName or data.Data.Name
                            if name and not table.find(_unfavFishList, name) then
                                _unfavFishList[#_unfavFishList + 1] = name
                            end
                        end
                    elseif child:IsA("Folder") then
                        scan(child)
                    end
                end
            end
            scan(itemsFolder)
        end)
        table.sort(_unfavFishList)
    end
    local function unfavBuildVariantList()
        _unfavVariantList = {}
        pcall(function()
            local variantsFolder = ReplicatedStorage:FindFirstChild("Variants")
            if not variantsFolder then return end
            for _, m in ipairs(variantsFolder:GetChildren()) do
                if m:IsA("ModuleScript") and m.Name ~= "1x1x1x1" and not table.find(_unfavVariantList, m.Name) then
                    _unfavVariantList[#_unfavVariantList + 1] = m.Name
                end
            end
        end)
        table.sort(_unfavVariantList)
    end
    local _unfavNameDropdownRef    = nil
    local _unfavVariantDropdownRef = nil
    local _unfavToggleRef          = nil
    local unfavNameUniqueId       = "UnfavName"
    local unfavVariantUniqueId    = "UnfavVariant"
    _unfavNameDropdownRef = UnfavSection:AddDropdown({
        Title    = unfavNameUniqueId,
        Multi    = true,
        Options  = {"Loading..."},
        Default  = {},
        Callback = function(selected)
            _unfavState.selectedName = unfavToSet(type(selected) == "table" and selected or {})
            if _unfavState.enabled then task.spawn(unfavScanInventory) end
        end,
    })
    _unfavVariantDropdownRef = UnfavSection:AddDropdown({
        Title    = unfavVariantUniqueId,
        Multi    = true,
        Options  = {"Loading..."},
        Default  = {},
        Callback = function(selected)
            _unfavState.selectedVariant = unfavToSet(type(selected) == "table" and selected or {})
            if _unfavState.enabled then task.spawn(unfavScanInventory) end
        end,
    })
    task.spawn(function()
        if not game:IsLoaded() then game.Loaded:Wait() end
        task.wait(2)
        unfavInitRefs()
        unfavBuildFishList()
        unfavBuildVariantList()
        local flagName    = Library.flags[unfavNameUniqueId]
        local flagVariant = Library.flags[unfavVariantUniqueId]
        if flagName then
            pcall(function()
                flagName:SetValues(
                    #_unfavFishList > 0 and _unfavFishList or {"No Fish Found"},
                    {}
                )
            end)
        end
        if flagVariant then
            pcall(function()
                flagVariant:SetValues(
                    #_unfavVariantList > 0 and _unfavVariantList or {"No Variants Found"},
                    {}
                )
            end)
        end
    end)

    UnfavSection:AddDropdown({
        Title    = "Unfav Rarity",
        Multi    = true,
        Options  = {"Common","Uncommon","Rare","Epic","Legendary","Mythic","SECRET","FORGOTTEN"},
        Default  = {},
        Callback = function(selected)
            _unfavState.selectedRarity = unfavToSet(type(selected) == "table" and selected or {})
            if _unfavState.enabled then task.spawn(unfavScanInventory) end
        end,
    })
    UnfavSection:AddButton({
        Title    = "Un-Favorite Selected",
        Callback = function()
            if not unfavInitRefs() then
                Library:MakeNotify({ Title = "Un-Favorite", Content = "Gagal init refs!", Delay = 3 })
                return
            end
            _unfavState.isScanning = false
            _unfavState.enabled = true
            task.spawn(unfavScanInventory)
            Library:MakeNotify({ Title = "Un-Favorite", Content = "Scanning...", Delay = 2 })
        end,
    })

    UnfavSection:AddButton({
        Title    = "Refresh List Items",
        Callback = function()
            _unfavFishList    = {}
            _unfavVariantList = {}
            unfavBuildFishList()
            unfavBuildVariantList()
            local flagName    = Library.flags[unfavNameUniqueId]
            local flagVariant = Library.flags[unfavVariantUniqueId]
            if flagName then
                pcall(function()
                    flagName:SetValues(
                        #_unfavFishList > 0 and _unfavFishList or {"No Fish Found"}, {}
                    )
                end)
            end
            if flagVariant then
                pcall(function()
                    flagVariant:SetValues(
                        #_unfavVariantList > 0 and _unfavVariantList or {"No Variants Found"}, {}
                    )
                end)
            end
            Library:MakeNotify({
                Title   = "Refresh",
                Content = "Fish: " .. #_unfavFishList .. " | Variant: " .. #_unfavVariantList,
                Delay   = 3,
            })
        end,
    })
end

-- [Teleport Tab]
do
    local _tp = {
        SelectedIsland            = nil,
        SelectedPlayer            = nil,
        AutoTeleportEnabled       = false,
        AutoTeleportConnection    = nil,
        ReplicatedEventData       = {},
        EventDataLoaded           = false,
        WorkspaceEventCache       = {},
        IsTeleporting             = false,
        ForceTeleportCancel       = false,
        CurrentEventName          = nil,
        CachedEventPosition       = nil,
        CachedEventObject         = nil,
        IsEventActive             = false,
        LastManualScanTime        = 0,
        LastAutoScanTime          = 0,
        TeleportLoopThread        = nil,
        ScanCooldown              = 5,
        HeightOffset              = 15,
        SafeRadius                = 150,
        CheckInterval             = 8,
        WaitTimeout               = 300,
    }
    local HttpService       = game:GetService("HttpService")
    local SAVE_FOLDER       = "LynxGUI_Configs"
    local SAVE_FILE         = SAVE_FOLDER .. "/LynxSavedLocationn.json"
    local ISLAND_COORDS_URL = "https://raw.githubusercontent.com/4LynxX/Coords/refs/heads/main/coords.json"
    local _islandCoords  = {}
    local _islandList    = {}
    local _islandLoaded  = false
    local _islandDropRef = nil
    local function _applyIslandOptions()
        if not _islandDropRef then return end
        local opts = #_islandList > 0 and _islandList or {"(Gagal load)"}
        local last = nil
        if #_islandList > 0 then
            local ok, saved = pcall(function()
                return Library.ConfigSystem.Get("Dropdowns.Select_Island", nil)
            end)
            if ok and type(saved) == "string" and _islandCoords[saved] then
                last = saved
            end
        end
        local uniqueId = "Select_Island"
        local flagObj  = Library and Library.flags and Library.flags[uniqueId]
        if flagObj and flagObj.SetValues then
            pcall(function() flagObj:SetValues(opts, last) end)
        elseif _islandDropRef.SetOptions then
            _islandDropRef:SetOptions(opts)
        end
        if last and _islandCoords[last] then
            _tp.SelectedIsland = last
        end
    end

    local function _loadIslandCoords(onDone)
        if _islandLoaded then
            if onDone then onDone() end
            return
        end
        task.spawn(function()
            local MAX_RETRY = 3
            for attempt = 1, MAX_RETRY do
                local ok, result = pcall(function()
                    local req = (syn and syn.request) or (http and http.request) or request
                    local response = req({
                        Url    = ISLAND_COORDS_URL,
                        Method = "GET",
                    })
                    return HttpService:JSONDecode(response.Body)
                end)
                if ok and result and type(result) == "table" then
                    table.clear(_islandCoords)
                    table.clear(_islandList)
                    for name, data in pairs(result) do
                        if data.pos and data.look then
                            _islandCoords[name] = {
                                pos  = Vector3.new(data.pos[1],  data.pos[2],  data.pos[3]),
                                look = Vector3.new(data.look[1], data.look[2], data.look[3]),
                            }
                            table.insert(_islandList, name)
                        end
                    end
                    table.sort(_islandList)
                    _islandLoaded = true
                    _applyIslandOptions()
                    if onDone then onDone() end
                    return
                else
                    warn(("[Teleport] Gagal load island coords (attempt %d/%d): %s"):format(attempt, MAX_RETRY, tostring(result)))
                    if attempt < MAX_RETRY then task.wait(2) end
                end
            end
            warn("[Teleport] Island coords tidak bisa diload setelah " .. MAX_RETRY .. " percobaan.")
            _applyIslandOptions()
        end)
    end
    _loadIslandCoords()
    local _eventFallback = {
        ["Shark Hunt"]      = {
            Vector3.new(1.649,    -1.350, 2095.72),
            Vector3.new(1369.94,  -1.350,  930.125),
            Vector3.new(-1585.5,  -1.350, 1242.87),
            Vector3.new(-1896.8,  -1.350, 2634.37),
        },
        ["Worm Hunt"]       = {
            Vector3.new(2190.85,  -1.399,   97.574),
            Vector3.new(-2450.6,  -1.399,  139.731),
            Vector3.new(-267.47,  -1.399, 5188.53),
        },
        ["Megalodon Hunt"]  = {
            Vector3.new(-1076.3,  -1.399, 1676.19),
            Vector3.new(-1191.8,  -1.399, 3597.30),
            Vector3.new(412.700,  -1.399, 4134.39),
        },
        ["Ghost Shark Hunt"] = {
            Vector3.new(489.558,  -1.350,   25.406),
            Vector3.new(-1358.2,  -1.350, 4100.55),
            Vector3.new(627.859,  -1.350, 3798.08),
        },
    }

    local function _notify(title, desc, color)
        Library:MakeNotify({
            Title       = title,
            Description = desc,
            Delay       = 3,
        })
    end
    local function _getRootPart()
        local char = LocalPlayer.Character
        return char and char:FindFirstChild("HumanoidRootPart")
    end
    local function _forceTeleport(targetCFrame)
        _tp.ForceTeleportCancel = false
        local capturedCFrame = targetCFrame
        task.spawn(function()
            for _ = 1, 10 do
                if _tp.ForceTeleportCancel then break end
                if _totemSpawning then task.wait(0.5); continue end
                local root = _getRootPart()
                if root and root.Parent then
                    root.CFrame = capturedCFrame
                end
                task.wait(0.1)
            end
        end)
    end
    local function _loadSavedPosition()
        local ok, data = pcall(function()
            return HttpService:JSONDecode(readfile(SAVE_FILE))
        end)
        if not ok or not data or type(data) ~= "table" then return nil end
        if #data ~= 12 then
            warn("[SavedLocation] File lokasi corrupt (jumlah komponen: " .. tostring(#data) .. "), expected 12")
            return nil
        end
        local cf = nil
        local parseOk = pcall(function()
            cf = CFrame.new(table.unpack(data))
        end)
        if not parseOk or not cf then
            warn("[SavedLocation] Gagal parse CFrame dari file lokasi")
            return nil
        end
        return cf
    end
    local function _isAlive(obj)
        if not obj then return false end
        local ok, result = pcall(function()
            return obj.Parent ~= nil and obj:IsDescendantOf(workspace)
        end)
        return ok and result
    end
    local function _posFromInstance(obj)
        if obj:IsA("Model") then
            if obj.PrimaryPart then return obj.PrimaryPart.Position end
            local ok, cf, size = pcall(function() return obj:GetBoundingBox() end)
            if ok and cf then
                return Vector3.new(cf.Position.X, cf.Position.Y - (size.Y / 4), cf.Position.Z)
            end
        elseif obj:IsA("BasePart") then
            return obj.Position
        end
        return nil
    end
    local function _withOffset(pos)
        return Vector3.new(pos.X, pos.Y + _tp.HeightOffset, pos.Z)
    end
    local function _doTeleport(targetPos)
        local root = _getRootPart()
        if not root then return false end
        if (root.Position - targetPos).Magnitude <= _tp.SafeRadius then return true end
        local ok = pcall(function()
            local char = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
            local r    = char:FindFirstChild("HumanoidRootPart")
            if not r then return end
            if char.PrimaryPart then
                char:PivotTo(CFrame.new(targetPos))
            else
                r.CFrame = CFrame.new(targetPos)
            end
            r.Anchored = false
            r.Velocity = Vector3.zero
        end)
        return ok
    end
    local function _findPropsContainers(parent, result, depth)
        depth  = depth  or 0
        result = result or {}
        if depth > 4 then return end
        for _, child in ipairs(parent:GetChildren()) do
            if child.Name == "Props" and (child:IsA("Model") or child:IsA("Folder")) then
                table.insert(result, child)
            end
            if child:IsA("Model") or child:IsA("Folder") then
                _findPropsContainers(child, result, depth + 1)
            end
        end
        return result
    end
    local function _loadEventData()
        local eventsFolder = ReplicatedStorage:FindFirstChild("Events")
        if not eventsFolder then
            local ok, res = pcall(function() return ReplicatedStorage:WaitForChild("Events", 5) end)
            if ok and res then eventsFolder = res end
        end
        if not eventsFolder then return end
        _tp.ReplicatedEventData = {}
        for _, child in ipairs(eventsFolder:GetChildren()) do
            if child:IsA("ModuleScript") then
                local ok, data = pcall(function() return require(child) end)
                if ok and data and type(data) == "table" and data.Name then
                    local coords = {}
                    if data.Coordinates then
                        for _, c in ipairs(data.Coordinates) do table.insert(coords, c) end
                    end
                    _tp.ReplicatedEventData[data.Name] = { coords = coords, icon = data.Icon }
                end
            end
        end
        _tp.EventDataLoaded = true
    end
    local function _scanAllProps()
        local now = tick()
        if now - _tp.LastAutoScanTime < 3 then return _tp.WorkspaceEventCache end
        _tp.LastAutoScanTime = now
        if not _tp.EventDataLoaded then _loadEventData() end
        _tp.WorkspaceEventCache = {}
        for _, container in ipairs(_findPropsContainers(workspace)) do
            for _, item in ipairs(container:GetChildren()) do
                local matched = nil
                if _tp.ReplicatedEventData[item.Name] then
                    matched = item.Name
                else
                    for eventName in pairs(_tp.ReplicatedEventData) do
                        if item.Name:find(eventName, 1, true) or eventName:find(item.Name, 1, true) then
                            matched = eventName; break
                        end
                    end
                end
                if matched and _isAlive(item) then
                    local pos = _posFromInstance(item)
                    if pos then
                        _tp.WorkspaceEventCache[matched] = { position = _withOffset(pos), object = item }
                    end
                end
            end
        end
        return _tp.WorkspaceEventCache
    end
    local function _scanEventPos(eventName)
        local now = tick()
        if now - _tp.LastManualScanTime < _tp.ScanCooldown then
            if _tp.CachedEventPosition and _isAlive(_tp.CachedEventObject) then
                return _tp.CachedEventPosition
            end
        end
        _tp.LastManualScanTime = now
        _scanAllProps()
        local cached = _tp.WorkspaceEventCache[eventName]
        if cached and _isAlive(cached.object) then
            _tp.CachedEventPosition = cached.position
            _tp.CachedEventObject   = cached.object
            _tp.IsEventActive       = true
            return _tp.CachedEventPosition
        end
        local allCoords = {}
        local rep = _tp.ReplicatedEventData[eventName]
        if rep and rep.coords then for _, c in ipairs(rep.coords) do table.insert(allCoords, c) end end
        local fb = _eventFallback[eventName]
        if fb then for _, c in ipairs(fb) do table.insert(allCoords, c) end end
        for _, coord in ipairs(allCoords) do
            local region = Region3.new(
                coord - Vector3.new(50, 50, 50),
                coord + Vector3.new(50, 50, 50)
            ):ExpandToGrid(4)
            local ok, parts = pcall(function() return workspace:FindPartsInRegion3(region, nil, 100) end)
            if ok and parts then
                for _, part in ipairs(parts) do
                    if typeof(part) == "Instance"
                        and part:IsA("BasePart")
                        and _isAlive(part)
                        and (part.Position - coord).Magnitude <= 40
                    then
                        _tp.CachedEventPosition = _withOffset(part.Position)
                        _tp.CachedEventObject   = part
                        _tp.IsEventActive       = true
                        return _tp.CachedEventPosition
                    end
                end
            end
        end
        _tp.IsEventActive = false
        return nil
    end
    local function _getEventNameList()
        if not _tp.EventDataLoaded then _loadEventData() end
        _scanAllProps()
        local list, seen = {}, {}
        for name in pairs(_tp.ReplicatedEventData) do
            if not seen[name] then
                seen[name] = true
                table.insert(list, _tp.WorkspaceEventCache[name] and (name .. " *") or name)
            end
        end
        for name in pairs(_tp.WorkspaceEventCache) do
            if not seen[name] then
                seen[name] = true
                table.insert(list, name .. " *")
            end
        end
        table.sort(list)
        return list
    end
    local function _cleanEventName(name)
        return name and name:gsub(" %*$", "") or nil
    end
    local function _stopEventTeleport()
        _tp.IsTeleporting       = false
        _tp.CachedEventPosition = nil
        _tp.CachedEventObject   = nil
        _tp.IsEventActive       = false
        if _tp.TeleportLoopThread and _tp.TeleportLoopThread ~= coroutine.running() then
            task.cancel(_tp.TeleportLoopThread)
        end
        _tp.TeleportLoopThread = nil
    end
    local function _startEventTeleport(eventName)
        if _tp.IsTeleporting then return false end
        if not _tp.EventDataLoaded then _loadEventData() end
        _tp.IsTeleporting       = true
        _tp.CurrentEventName    = eventName
        _tp.CachedEventPosition = nil
        _tp.CachedEventObject   = nil
        _tp.IsEventActive       = false
        _tp.LastManualScanTime  = 0
        _tp.TeleportLoopThread = task.spawn(function()
            local startTime   = tick()
            local eventPos    = nil
            while tick() - startTime < _tp.WaitTimeout do
                eventPos = _scanEventPos(eventName)
                if eventPos then break end
                task.wait(5)
            end
            if not eventPos then _stopEventTeleport(); return end
            _doTeleport(eventPos)
            local failCount = 0
            while _tp.IsTeleporting do
                if _tp.CachedEventObject and not _isAlive(_tp.CachedEventObject) then
                    _tp.CachedEventPosition = nil
                    _tp.CachedEventObject   = nil
                    _tp.IsEventActive       = false
                end
                local newPos = _scanEventPos(eventName)
                if newPos then
                    _doTeleport(newPos)
                    failCount = 0
                else
                    failCount += 1
                    if failCount >= 3 then _stopEventTeleport(); break end
                end
                task.wait(_tp.CheckInterval)
            end
        end)
        return true
    end
    workspace.ChildAdded:Connect(function(child)
        if child.Name == "Props" and _tp.EventDataLoaded then
            task.wait(0.5)
            _tp.LastAutoScanTime = 0
            _scanAllProps()
        end
    end)
    workspace.ChildRemoved:Connect(function(child)
        if child.Name == "Props" and _tp.EventDataLoaded then
            _tp.LastAutoScanTime = 0
            _scanAllProps()
        end
    end)
    local TeleportTab = MainWindow:AddTab({ Name = "Teleport", Icon = "gps" })
    do
        local IslandSection = TeleportTab:AddSection("Teleport to Island")
        _islandDropRef = IslandSection:AddDropdown({
            Title    = "Select Island",
            Multi    = false,
            Options  = #_islandList > 0 and _islandList or {"Loading..."},
            Default  = nil,
            Callback = function(v)
                local val = v
                if type(val) == "table" then
                    local k, tVal = next(val)
                    val = (type(k) == "number" and tVal) or (type(tVal) == "boolean" and k) or k
                end
                if val == "Loading..." or val == "(Gagal load)" then
                    _tp.SelectedIsland = ""
                    return
                end
                _tp.SelectedIsland = type(val) == "string" and val or ""
            end,
        })
        IslandSection:AddButton({
            Title    = "Teleport",
            Callback = function()
                if not _islandLoaded then
                    _loadIslandCoords(function()
                        _notify("Teleport", "Island list sudah dimuat, pilih island lalu tekan Teleport lagi.", nil)
                    end)
                    return
                end
                if not _tp.SelectedIsland or _tp.SelectedIsland == "" then
                    _notify("Teleport", "Pilih island dulu dari dropdown!", Color3.fromRGB(255, 179, 71))
                    return
                end
                local islandData = _islandCoords[_tp.SelectedIsland]
                if not islandData then
                    _notify("Teleport", "Island tidak valid!", Color3.fromRGB(255, 85, 127))
                    return
                end
                local char = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
                local root = char:WaitForChild("HumanoidRootPart")
                root.CFrame = CFrame.new(islandData.pos, islandData.look)
                _notify("Teleport", "Teleported to " .. _tp.SelectedIsland, Color3.fromRGB(123, 239, 178))
            end,
        })
    end

    do
        local PlayerSection  = TeleportTab:AddSection("Teleport to Player", false)
        local _playerList    = {}
        local _playerLookup  = {}
        local _playerDropRef = nil
        local function _refreshPlayerList()
            table.clear(_playerList)
            table.clear(_playerLookup)
            for _, player in ipairs(Players:GetPlayers()) do
                if player ~= LocalPlayer then
                    local display = player.DisplayName or player.Name
                    local label   = display .. " (" .. player.Name .. ")"
                    table.insert(_playerList, label)
                    _playerLookup[label] = player.Name
                end
            end
            table.sort(_playerList)
        end
        _refreshPlayerList()
        _playerDropRef = PlayerSection:AddDropdown({
            Title    = "Select Player",
            Multi    = false,
            Options  = _playerList,
            Default  = nil,
            NoSave   = false,
            Callback = function(v)
                local val = v
                if type(val) == "table" then
                    local k, tVal = next(val)
                    val = (type(k) == "number" and tVal) or (type(tVal) == "boolean" and k) or k
                end
                local label = type(val) == "string" and val or ""
                _tp.SelectedPlayer      = _playerLookup[label] or label
                _tp.SelectedPlayerLabel = label
            end,
        })
        PlayerSection:AddButton({
            Title    = "Teleport to selected Player",
            Callback = function()
                if not _tp.SelectedPlayer or _tp.SelectedPlayer == "" then
                    _notify("Teleport", "Pilih player dulu dari dropdown!", Color3.fromRGB(255, 179, 71))
                    return
                end
                local target  = Players:FindFirstChild(_tp.SelectedPlayer)
                local myChar  = LocalPlayer.Character
                if not target or not target.Character then
                    _notify("Teleport", "Player tidak ditemukan!", Color3.fromRGB(255, 85, 127))
                    return
                end
                local targetRoot = target.Character:FindFirstChild("HumanoidRootPart")
                if targetRoot and myChar then
                    myChar:PivotTo(targetRoot.CFrame * CFrame.new(0, 3, 0))
                    _notify("Teleport", "Teleported to " .. (_tp.SelectedPlayerLabel or _tp.SelectedPlayer), Color3.fromRGB(123, 239, 178))
                else
                    _notify("Teleport", "HumanoidRootPart target tidak ditemukan!", Color3.fromRGB(255, 85, 127))
                end
            end,
        })
        PlayerSection:AddButton({
            Title    = "Refresh Player List",
            Callback = function()
                _refreshPlayerList()
                if _playerDropRef and _playerDropRef.SetOptions then
                    _playerDropRef:SetOptions(_playerList)
                elseif _playerDropRef and _playerDropRef.Refresh then
                    _playerDropRef:Refresh(_playerList)
                end
                _notify("Teleport", "Player list diperbarui.", Color3.fromRGB(100, 200, 255))
            end,
        })
    end

    do
        local _autoTpToggleRef = nil
        local SavedSection = TeleportTab:AddSection("Saved Location", false)
        SavedSection:AddButton({
            Title    = "Save Current Location",
            Callback = function()
                local root = _getRootPart()
                if not root then
                    _notify("Error", "Character tidak ditemukan!", Color3.fromRGB(255, 85, 127))
                    return
                end
                pcall(function()
                    if not isfolder(SAVE_FOLDER) then makefolder(SAVE_FOLDER) end
                end)
                local ok = pcall(function()
                    writefile(SAVE_FILE, HttpService:JSONEncode({ root.CFrame:GetComponents() }))
                end)
                if ok then
                    _notify("Saved", "Lokasi berhasil disimpan!", Color3.fromRGB(123, 239, 178))
                else
                    _notify("Error", "Gagal menyimpan lokasi!", Color3.fromRGB(255, 85, 127))
                end
            end,
        })
        SavedSection:AddButton({
            Title    = "Teleport to Saved",
            Callback = function()
                local savedCFrame = _loadSavedPosition()
                if not savedCFrame then
                    _notify("Error", "Tidak ada lokasi tersimpan!", Color3.fromRGB(255, 85, 127))
                    return
                end
                if not _getRootPart() then
                    _notify("Error", "Character tidak ditemukan!", Color3.fromRGB(255, 85, 127))
                    return
                end
                _forceTeleport(savedCFrame)
                _notify("Teleported", "Teleport ke lokasi tersimpan berhasil!", Color3.fromRGB(123, 239, 178))
            end,
        })
        SavedSection:AddButton({
            Title    = "Reset Saved Location",
            Callback = function()
                _tp.ForceTeleportCancel = true
                _tp.AutoTeleportEnabled = false
                if _tp.AutoTeleportConnection then
                    _tp.AutoTeleportConnection:Disconnect()
                    _tp.AutoTeleportConnection = nil
                end
                if _autoTpToggleRef then
                    pcall(function() _autoTpToggleRef:Set(false) end)
                end
                local deleted = false
                pcall(function()
                    if isfile(SAVE_FILE) then
                        delfile(SAVE_FILE)
                        deleted = not isfile(SAVE_FILE)
                    else
                        deleted = true
                    end
                end)
                _tp.ForceTeleportCancel = false
                if deleted then
                    _notify("Reset", "Lokasi tersimpan & auto teleport telah direset.", Color3.fromRGB(255, 179, 71))
                else
                    _notify("Error", "Gagal menghapus file lokasi!", Color3.fromRGB(255, 85, 127))
                end
            end,
        })
        _autoTpToggleRef = SavedSection:AddToggle({
            Title    = "Auto Teleport on Spawn",
            Default  = false,
            Callback = function(on)
                if on then
                    if _tp.AutoTeleportEnabled then return end
                    _tp.AutoTeleportEnabled = true
                    local function _onCharAdded(char)
                        task.spawn(function()
                            local root = char:WaitForChild("HumanoidRootPart", 10)
                            if not root then return end
                            task.wait(1.5)
                            local waitCount = 0
                            while _totemSpawning and waitCount < 30 do
                                task.wait(1)
                                waitCount = waitCount + 1
                            end
                            if waitCount > 0 then task.wait(1.5) end
                            local saved = _loadSavedPosition()
                            if saved then
                                _forceTeleport(saved)
                                _notify("Auto Teleport", "Teleported ke lokasi tersimpan!", Color3.fromRGB(123, 239, 178))
                            end
                        end)
                    end
                    _tp.AutoTeleportConnection = LocalPlayer.CharacterAdded:Connect(_onCharAdded)
                    if LocalPlayer.Character then _onCharAdded(LocalPlayer.Character) end
                else
                    _tp.AutoTeleportEnabled = false
                    if _tp.AutoTeleportConnection then
                        _tp.AutoTeleportConnection:Disconnect()
                        _tp.AutoTeleportConnection = nil
                    end
                end
            end,
        })
    end

    do
        _ev = {
            active         = false,
            selectedEvents = {},
            priorityEvent  = nil,
            loopThread     = nil,
            origCF         = nil,
            curCF          = nil,
            curEventName   = nil,
            flt            = false,
            con            = nil,
            charConn       = nil,
            refreshThread  = nil,
            wowAutoEnabled = false,
        }
        local _evReplion  = (function()
            local rep = getCachedReplion()
            if rep then
                local ok, data = pcall(function() return rep.Client:GetReplion("Events") end)
                if ok and data then return data end
                ok, data = pcall(function() return rep.Client:WaitReplion("Events") end)
                if ok and data then return data end
            end
            return nil
        end)()
        local _evData     = cachedRequire(ReplicatedStorage:FindFirstChild("Events"))
        local _ignoreList = {
            Cloudy             = true,
            Day                = true,
            ["Increased Luck"] = true,
            Mutated            = true,
            Night              = true,
            Snow               = true,
            ["Sparkling Cove"] = true,
            Storm              = true,
            Wind               = true,
            Radiant            = true,
            ["Present Rain"]   = true,
            ["Admin - Super Mutated"]     = true,
            ["Admin - Shocked"]           = true,
            ["Admin - MEGA Luck"]         = true,
            ["Admin - Super Luck"]        = true,
            ["Admin - Night Celebration"] = true,
            ["Admin - Forgotten Tier"]    = true,
            ["Admin - Galaxy Storm"]      = true,
        }
        local TELEPORT_OFFSET = 12
        _totemSpawning = false
        local function _getActiveEventNames()
            if not _evReplion then return {} end
            local active = _evReplion:Get("Events")
            if not active then return {} end
            local result = {}
            for _, name in pairs(active) do
                if typeof(name) == "string" then
                    result[name] = true
                end
            end
            return result
        end
        local function _getEventList()
            local result = {}
            if not _evData then return result end
            for eventId, info in pairs(_evData) do
                if info.Coordinates and not _ignoreList[eventId] then
                    table.insert(result, eventId)
                end
            end
            table.sort(result)
            return result
        end
        local function _getRoot(char)
            return char and (char:FindFirstChild("HumanoidRootPart") or char:FindFirstChildWhichIsA("BasePart"))
        end
        local function _setAnchored(char, state)
            if not char then return end
            for _, v in ipairs(char:GetDescendants()) do
                if v:IsA("BasePart") then v.Anchored = state end
            end
        end
        local function _setFloat(char, root, enabled)
            if _ev.con then _ev.con:Disconnect(); _ev.con = nil end
            _ev.flt = enabled or false
            if not char then return end
            local oldFp = char:FindFirstChild("FloatPart")
            if oldFp then oldFp:Destroy() end
            if not enabled then return end
            root = root or _getRoot(char)
            if not root then return end
            local hum = char:FindFirstChildOfClass("Humanoid")
            local params = RaycastParams.new()
            params.FilterType = Enum.RaycastFilterType.Exclude
            params.FilterDescendantsInstances = { char }
            params.IgnoreWater = false
            local rayOrigin = root.Position + Vector3.new(0, 60, 0)
            local rayDir    = Vector3.new(0, -220, 0)
            local hit = workspace:Raycast(rayOrigin, rayDir, params)
            if not hit then return end
            local standY = hit.Position.Y + ((hum and hum.HipHeight) or 2) + 2.5
            local pos = root.Position
            char:PivotTo(CFrame.new(pos.X, standY, pos.Z))
        end
        local _eventPartCache = {}
        local _eventPartCacheTime = {}
        local EVENT_PART_CACHE_TTL = 3
        local function _findEventPart(eventName)
            if not eventName then return nil end
            local now = tick()
            if _eventPartCache[eventName] and _eventPartCacheTime[eventName]
                and (now - _eventPartCacheTime[eventName]) < EVENT_PART_CACHE_TTL then
                local cached = _eventPartCache[eventName]
                if cached and cached.Parent then return cached end
                _eventPartCache[eventName] = nil
            end
            local propsFolders = {}
            for _, obj in ipairs(workspace:GetChildren()) do
                if obj.Name == "Props" then
                    propsFolders[#propsFolders + 1] = obj
                end
            end
            for _, props in ipairs(propsFolders) do
                for _, group in ipairs(props:GetChildren()) do
                    for _, desc in ipairs(group:GetDescendants()) do
                        if desc:IsA("TextLabel") and desc.Name == "DisplayName" then
                            local txt = desc.ContentText ~= "" and desc.ContentText or desc.Text
                            if txt:lower() == eventName:lower() then
                                local part = desc:FindFirstAncestorWhichIsA("BasePart")
                                if part then
                                    _eventPartCache[eventName] = part
                                    _eventPartCacheTime[eventName] = now
                                    return part
                                end
                                local p = group:FindFirstChild("Part")
                                if p and p:IsA("BasePart") then
                                    _eventPartCache[eventName] = p
                                    _eventPartCacheTime[eventName] = now
                                    return p
                                end
                            end
                        end
                    end
                end
            end
            for _, props in ipairs(propsFolders) do
                local group = props:FindFirstChild(eventName)
                if group then
                    local namedPart = group:FindFirstChild(eventName, true)
                    if namedPart and namedPart:IsA("BasePart") then
                        _eventPartCache[eventName] = namedPart
                        _eventPartCacheTime[eventName] = now
                        return namedPart
                    end
                    local p = group:FindFirstChild("Part")
                    if p and p:IsA("BasePart") then
                        _eventPartCache[eventName] = p
                        _eventPartCacheTime[eventName] = now
                        return p
                    end
                    local bestPart = nil
                    local lowestY  = math.huge
                    for _, desc in ipairs(group:GetDescendants()) do
                        if desc:IsA("BasePart") and desc.Position.Y < lowestY and desc.Position.Y > -10 then
                            lowestY  = desc.Position.Y
                            bestPart = desc
                        end
                    end
                    if bestPart then
                        _eventPartCache[eventName] = bestPart
                        _eventPartCacheTime[eventName] = now
                        return bestPart
                    end
                end
            end
            local info = _evData and _evData[eventName]
            if info and info.Coordinates and #info.Coordinates > 0 then
                local root    = _getRoot(LocalPlayer.Character)
                local bestPos = info.Coordinates[1]
                if #info.Coordinates > 1 and root then
                    local closestDist = math.huge
                    for _, coord in ipairs(info.Coordinates) do
                        local dist = (root.Position - coord).Magnitude
                        if dist < closestDist then
                            closestDist = dist
                            bestPos     = coord
                        end
                    end
                end
                local fake = Instance.new("Part")
                fake.Anchored     = true
                fake.CanCollide   = false
                fake.Transparency = 1
                fake.Size         = Vector3.new(1, 1, 1)
                fake.CFrame       = CFrame.new(bestPos)
                fake.Parent       = workspace
                task.delay(5, function() pcall(function() fake:Destroy() end) end)
                return fake
            end
            return nil
        end
        local function _stopEvent()
            _ev.active = false
            if _ev.loopThread then pcall(task.cancel, _ev.loopThread); _ev.loopThread = nil end
            if _ev.charConn then pcall(function() _ev.charConn:Disconnect() end); _ev.charConn = nil end
            if _ev.wowAutoEnabled and _G._wowToggleRef then
                _ev.wowAutoEnabled = false
                pcall(function() _G._wowToggleRef:SetValue(false) end)
            end
            local char = LocalPlayer.Character
            _setAnchored(char, false)
            _setFloat(char, nil, false)
            if _ev.origCF and char then char:PivotTo(_ev.origCF) end
            _ev.origCF       = nil
            _ev.curCF        = nil
            _ev.curEventName = nil
        end
        local function _startEvent()
            if _ev.active then _stopEvent() end
            if #_ev.selectedEvents == 0 and not _ev.priorityEvent then return false end
            _ev.active       = true
            _ev.origCF       = nil
            _ev.curCF        = nil
            _ev.curEventName = nil
            _ev.loopThread = task.spawn(function()
                while _ev.active do
                    if _totemSpawning then task.wait(2); continue end
                    local activeNames = _getActiveEventNames()
                    local foundPart   = nil
                    local foundName   = nil
                    if _ev.priorityEvent and activeNames[_ev.priorityEvent] then
                        local part = _findEventPart(_ev.priorityEvent)
                        if part then
                            foundPart = part
                            foundName = _ev.priorityEvent
                        end
                    end
                    if not foundPart then
                        for _, evName in ipairs(_ev.selectedEvents) do
                            if activeNames[evName] then
                                local part = _findEventPart(evName)
                                if part then
                                    foundPart = part
                                    foundName = evName
                                    break
                                end
                            end
                        end
                    end
                    local char = LocalPlayer.Character
                    local root = _getRoot(char)
                    if foundPart and root then
                        if _ev.curEventName ~= foundName then
                            _setAnchored(char, false)
                            _setFloat(char, nil, false)
                            _ev.curCF        = nil
                            _ev.curEventName = foundName
                        end
                        if not _ev.origCF then
                            _ev.origCF = root.CFrame
                        end
                        if (root.Position - foundPart.Position).Magnitude > 40 then
                            local targetPos = Vector3.new(
                                foundPart.Position.X,
                                foundPart.Position.Y + TELEPORT_OFFSET,
                                foundPart.Position.Z
                            )
                            _ev.curCF = CFrame.new(targetPos)
                            char:PivotTo(_ev.curCF)
                            _setFloat(char, root, true)
                        end
                    elseif foundPart == nil and _ev.curCF and root then
                        _setAnchored(char, false)
                        _setFloat(char, nil, false)
                        if _ev.origCF then
                            char:PivotTo(_ev.origCF)
                            _ev.origCF = nil
                        end
                        _ev.curCF        = nil
                        _ev.curEventName = nil
                    end
                    task.wait(1)
                end
                local char = LocalPlayer.Character
                _setAnchored(char, false)
                _setFloat(char, nil, false)
                if _ev.origCF and char then char:PivotTo(_ev.origCF) end
                _ev.origCF       = nil
                _ev.curCF        = nil
                _ev.curEventName = nil
            end)
            if _ev.charConn then pcall(function() _ev.charConn:Disconnect() end); _ev.charConn = nil end
            _ev.charConn = LocalPlayer.CharacterAdded:Connect(function(char)
                if not _ev.active then return end
                task.spawn(function()
                    local root = char:WaitForChild("HumanoidRootPart", 5)
                    task.wait(0.3)
                    if not root then return end
                    if _ev.curCF then
                        char:PivotTo(_ev.curCF)
                        _setFloat(char, root, true)
                    elseif _ev.origCF then
                        char:PivotTo(_ev.origCF)
                        _setFloat(char, root, true)
                    end
                end)
            end)
            if _G._wowToggleRef and not _G._wowToggleRef.Value then
                _ev.wowAutoEnabled = true
                pcall(function() _G._wowToggleRef:SetValue(true) end)
            end
            return true
        end

        local EventSection = TeleportTab:AddSection("Event Teleport", false)
        local _dropRef     = nil
        local _toggleRef   = nil
        local function _refreshDropdown(silent)
            local names = _getEventList()
            if _dropRef and _dropRef.Refresh then
                local keepList = {}
                for _, sel in ipairs(_ev.selectedEvents) do
                    for _, name in ipairs(names) do
                        if name == sel then table.insert(keepList, name); break end
                    end
                end
                _dropRef:Refresh(names, #keepList == 0)
                if #keepList > 0 then pcall(function() _dropRef:SetValue(keepList) end) end
            end
            if _priorityDropRef and _priorityDropRef.Refresh then
                local keepPriority = nil
                if _ev.priorityEvent then
                    for _, name in ipairs(names) do
                        if name == _ev.priorityEvent then keepPriority = name; break end
                    end
                end
                _priorityDropRef:Refresh(names, keepPriority == nil)
                if keepPriority then pcall(function() _priorityDropRef:SetValue(keepPriority) end) end
            end
            if not silent then
                _notify("Event Scan", "Ditemukan " .. #names .. " event.", Color3.fromRGB(100, 200, 255))
            end
        end
        _dropRef = EventSection:AddDropdown({
            Title    = "Select Event",
            Options  = _getEventList(),
            Default  = nil,
            Multi    = true,
            Callback = function(selected)
                _ev.selectedEvents = type(selected) == "table" and selected or (selected and { selected } or {})
                if _toggleRef and _toggleRef.Value and #_ev.selectedEvents > 0 then
                    _stopEvent()
                    task.wait(0.1)
                    _startEvent()
                end
            end,
        })
        _priorityDropRef = EventSection:AddDropdown({
            Title    = "Priority Event",
            Options  = _getEventList(),
            Default  = nil,
            Multi    = false,
            Callback = function(selected)
                _ev.priorityEvent = (selected and selected ~= "") and selected or nil
                if _toggleRef and _toggleRef.Value then
                    _stopEvent()
                    task.wait(0.1)
                    _startEvent()
                end
            end,
        })
        EventSection:AddButton({
            Title    = "Refresh Event List",
            Callback = function() _refreshDropdown(false) end,
        })
        _toggleRef = EventSection:AddToggle({
            Title    = "Auto Event Teleport",
            Default  = false,
            Callback = function(on)
                if on then
                    if #_ev.selectedEvents == 0 then
                        _notify("Auto Teleport", "Pilih event terlebih dahulu!", Color3.fromRGB(255, 100, 100))
                        if _toggleRef then _toggleRef:SetValue(false) end
                        return
                    end
                    local ok = _startEvent()
                    if ok then
                        _notify("Auto Teleport", "Monitoring " .. #_ev.selectedEvents .. " event...", Color3.fromRGB(100, 200, 255))
                    else
                        _notify("Auto Teleport", "Gagal start. Pilih event lagi.", Color3.fromRGB(255, 180, 50))
                        if _toggleRef then _toggleRef:SetValue(false) end
                    end
                else
                    _stopEvent()
                    _notify("Auto Teleport", "Auto teleport dimatikan.", Color3.fromRGB(255, 100, 100))
                end
            end,
        })
        if _evReplion then
            _evReplion:OnChange("Events", function()
                if not _ev.active then
                    _refreshDropdown(true)
                end
            end)
        end
        _ev.refreshThread = task.spawn(function()
            task.wait(3)
            _refreshDropdown(true)
            while task.wait(120) do
                if not _ev.active then
                    _refreshDropdown(true)
                end
            end
        end)
    end

    do
        local PlazaSection = TeleportTab:AddSection("Plaza Teleport", false)
        PlazaSection:AddButton({
            Title    = "Teleport ke Trade Plaza",
            Callback = function()
                pcall(function()
                    NetEvents.RE_TradePlazaTeleport:FireServer(79378095465365)
                end)
            end,
        })
        PlazaSection:AddButton({
            Title    = "Teleport ke Trade Plaza (Alt)",
            Callback = function()
                pcall(function()
                    NetEvents.RE_TradePlazaTeleport:FireServer(82602826017494)
                end)
            end,
        })
    end

    do
        local _npcFolder   = nil
        local _npcList     = {}
        local _selectedNpc = nil
        local _npcLoaded   = false
        local _npcDropdown = nil
        local NpcSection = TeleportTab:AddSection("Teleport to NPC", false)
        local function _ensureFolder()
            if not _npcFolder then
                _npcFolder = workspace:FindFirstChild("NPC")
            end
            return _npcFolder
        end
        local function _refresh()
            _npcList = {}
            if not _ensureFolder() then return end
            for _, npc in ipairs(_npcFolder:GetChildren()) do
                if npc:IsA("Model") then
                    table.insert(_npcList, npc.Name)
                end
            end
            table.sort(_npcList, function(a, b) return a < b end)
            if _npcDropdown and _npcDropdown.SetOptions then
                _npcDropdown:SetOptions(_npcList)
            elseif _npcDropdown and _npcDropdown.Refresh then
                _npcDropdown:Refresh(_npcList)
            end
            _npcLoaded = true
        end
        _npcDropdown = NpcSection:AddDropdown({
            Title    = "Pilih NPC",
            Options  = {},
            Default  = "",
            Callback = function(val)
                if not _npcLoaded then _refresh() end
                _selectedNpc = val
            end,
        })
        NpcSection:AddButton({
            Title    = "Teleport to NPC",
            Callback = function()
                if not _npcLoaded then _refresh() end
                if not _selectedNpc or _selectedNpc == "" then
                    Library:MakeNotify({ Title = "NPC TP", Description = "Pilih NPC dulu!", Color = Color3.fromRGB(255,100,100), Delay = 2 })
                    return
                end
                local npc = _npcFolder and _npcFolder:FindFirstChild(_selectedNpc)
                if not npc then
                    Library:MakeNotify({ Title = "NPC TP", Description = "NPC tidak ditemukan!", Color = Color3.fromRGB(255,100,100), Delay = 2 })
                    return
                end
                local hrp = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
                if not hrp then return end
                local ok, pivot = pcall(function() return npc:GetPivot() end)
                if ok and pivot then hrp.CFrame = pivot * CFrame.new(0, 0, 3) end
            end,
        })
        NpcSection:AddButton({
            Title    = "Refresh List",
            Callback = function()
                _refresh()
                Library:MakeNotify({ Title = "NPC TP", Description = ("Ditemukan %d NPC"):format(#_npcList), Color = Color3.fromRGB(123,239,178), Delay = 2 })
            end,
        })
    end
end

-- [Shop Tab]
do
    local _shopItemUtil, _shopReplion
    local function _getItemUtility()
        if not _shopItemUtil then
            pcall(function() _shopItemUtil = cachedRequire(ReplicatedStorage.Shared.ItemUtility) end)
        end
        return _shopItemUtil
    end
    local function _getReplionData()
        if not _shopReplion then
            pcall(function() _shopReplion = getCachedReplionData() end)
        end
        return _shopReplion
    end
    local ItemUtility = setmetatable({}, { __index = function(_, k)
        local u = _getItemUtility(); return u and u[k]
    end })
    local ReplionData = setmetatable({}, { __index = function(_, k)
        local r = _getReplionData(); if not r then return nil end
        local v = r[k]
        if type(v) == "function" then return function(_, ...) return v(r, ...) end end
        return v
    end })
    local ShopTab            = MainWindow:AddTab({ Name = "Shop", Icon = "cart" })
    do
        local SellSection = ShopTab:AddSection("Auto Sell")
        local _sellState  = { enabled = false, mode = "Timer", interval = 5, target = 235, lastSell = 0, timerTask = nil, countTask = nil, countConn = nil }
        local function getSellAllRemote()
            return NetEvents.RF_SellAllItems
        end
        local function parseNumber(text)
            if not text or text == "" then return 0 end
            local cleaned = tostring(text):gsub("%D", "")
            return tonumber(cleaned == "" and "0" or cleaned) or 0
        end
        local function getBagLabel()
            local gui = LocalPlayer:FindFirstChild("PlayerGui")
            if not gui then return nil end
            local inv = gui:FindFirstChild("Inventory")
            if not inv then return nil end
            -- Coba path langsung dulu
            local direct = inv:FindFirstChild("Main")
                and inv.Main:FindFirstChild("Top")
                and inv.Main.Top:FindFirstChild("Options")
                and inv.Main.Top.Options:FindFirstChild("Fish")
                and inv.Main.Top.Options.Fish:FindFirstChild("Label")
                and inv.Main.Top.Options.Fish.Label:FindFirstChild("BagSize")
            if direct and direct:IsA("TextLabel") then return direct end
            -- Fallback: recursive search
            return inv:FindFirstChild("BagSize", true)
        end
        local function getBagCount()
            local label = getBagLabel()
            if not label or not label:IsA("TextLabel") then return 0 end
            local cur = label.Text:match("(.+)%/")
            return parseNumber(cur)
        end
        local function executeSellAll()
            local remote = getSellAllRemote()
            if not remote then return end
            if tick() - _sellState.lastSell < 0.5 then return end
            pcall(function() remote:InvokeServer() end)
            _sellState.lastSell = tick()
        end
        local function stopSellLoops()
            if _sellState.timerTask then task.cancel(_sellState.timerTask); _sellState.timerTask = nil end
            if _sellState.countTask then task.cancel(_sellState.countTask); _sellState.countTask = nil end
            if _sellState.countConn then _sellState.countConn:Disconnect(); _sellState.countConn = nil end
        end
        local function startSellLoop()
            stopSellLoops()
            if _sellState.mode == "Timer" then
                _sellState.timerTask = task.spawn(function()
                    while _sellState.enabled do
                        task.wait(_sellState.interval)
                        if _sellState.enabled then executeSellAll() end
                    end
                end)
            else
                -- Event-driven: langsung trigger saat label berubah, tidak pakai polling
                local function attachCountWatcher()
                    local label = getBagLabel()
                    if not label then
                        -- Label belum ada, tunggu dengan polling ringan lalu coba lagi
                        _sellState.countTask = task.spawn(function()
                            while _sellState.enabled do
                                task.wait(1)
                                local lbl = getBagLabel()
                                if lbl then
                                    -- Cek langsung dulu sebelum pasang listener
                                    local current = parseNumber(lbl.Text:match("(.+)%/"))
                                    if current >= _sellState.target then
                                        executeSellAll()
                                    end
                                    -- Pasang event listener
                                    if _sellState.countConn then _sellState.countConn:Disconnect() end
                                    _sellState.countConn = lbl:GetPropertyChangedSignal("Text"):Connect(function()
                                        if not _sellState.enabled then return end
                                        local count = parseNumber(lbl.Text:match("(.+)%/"))
                                        if count >= _sellState.target then
                                            executeSellAll()
                                        end
                                    end)
                                    break
                                end
                            end
                        end)
                        return
                    end
                    -- Label sudah ada: cek langsung dulu
                    local current = parseNumber(label.Text:match("(.+)%/"))
                    if current >= _sellState.target then
                        executeSellAll()
                    end
                    -- Pasang event listener di label
                    _sellState.countConn = label:GetPropertyChangedSignal("Text"):Connect(function()
                        if not _sellState.enabled then return end
                        local count = parseNumber(label.Text:match("(.+)%/"))
                        if count >= _sellState.target then
                            executeSellAll()
                        end
                    end)
                end
                attachCountWatcher()
            end
        end

        SellSection:AddButton({ Title = "Sell All Now", Callback = executeSellAll })
        SellSection:AddDropdown({
            Title    = "Auto Sell Mode",
            Options  = {"Timer", "By Count"},
            Default  = "Timer",
            Callback = function(selected)
                _sellState.mode = selected
                if _sellState.enabled then startSellLoop() end
            end,
        })
        SellSection:AddInput({
            Title    = "Value (Seconds / Fish Count)",
            Default  = "5",
            Callback = function(value)
                local n = tonumber(value)
                if n and n >= 1 then
                    _sellState.interval = n
                    _sellState.target   = n
                    -- Kalau mode By Count sedang aktif, restart loop dengan target baru
                    if _sellState.enabled and _sellState.mode ~= "Timer" then
                        startSellLoop()
                    end
                end
            end,
        })
        SellSection:AddToggle({
            Title    = "Enable Auto Sell",
            Default  = false,
            Callback = function(on)
                _sellState.enabled = on
                if on then
                    if not getSellAllRemote() then _sellState.enabled = false; return end
                    startSellLoop()
                else
                    stopSellLoops()
                end
            end,
        })
    end

    do
        local WeatherSection = ShopTab:AddSection("Auto Buy Weather")
        local _weatherState = { enabled = false, selected = {"Cloudy", "Storm", "Wind"}, task = nil }
        WeatherSection:AddDropdown({
            Title    = "Weather",
            Multi    = true,
            Options  = {"Cloudy", "Storm", "Wind", "Snow", "Radiant", "Shark Hunt"},
            Default  = _weatherState.selected,
            Callback = function(selected)
                _weatherState.selected = type(selected) == "table" and selected or {}
            end,
        })
        WeatherSection:AddToggle({
            Title    = "Enable Auto Buy Weather",
            Default  = false,
            Callback = function(on)
                if on then
                    if _weatherState.enabled then return end
                    if #_weatherState.selected == 0 then return end
                    local remote = NetEvents.RF_PurchaseWeatherEvent
                    if not remote then return end
                    local Replion = require(game.ReplicatedStorage.Packages.Replion)
                    local eventsReplion = Replion.Client:WaitReplion("Events")
                    if not eventsReplion then return end
                    _weatherState.enabled = true
                    _weatherState.task = task.spawn(function()
                        while _weatherState.enabled do
                            local ok, currentQueue = pcall(function()
                                return eventsReplion:Get("WeatherMachine") or {}
                            end)
                            if ok then
                                local slotsUsed = #currentQueue
                                for _, weather in ipairs(_weatherState.selected) do
                                    if not _weatherState.enabled then break end
                                    if slotsUsed >= 3 then break end
                                    local alreadyActive = eventsReplion:Find("Events", weather)
                                    local alreadyQueued = eventsReplion:Find("WeatherMachine", weather)
                                    if not alreadyActive and not alreadyQueued then
                                        local success, result = pcall(function()
                                            return remote:InvokeServer(weather)
                                        end)
                                        if success and result then
                                            slotsUsed = slotsUsed + 1
                                        end
                                        task.wait(1)
                                    end
                                end
                            end
                            task.wait(15)
                        end
                    end)
                else
                    _weatherState.enabled = false
                    if _weatherState.task then
                        task.cancel(_weatherState.task)
                        _weatherState.task = nil
                    end
                end
            end,
        })
    end

    do
        local SellPresentSection = ShopTab:AddSection("Auto Sell Present")
        local _presentState      = { enabled = false, interval = 10, task = nil, lastSell = 0 }
        SellPresentSection:AddInput({
            Title    = "Interval (Seconds)",
            Default  = "10",
            Callback = function(value)
                local n = tonumber(value)
                if n and n >= 1 then _presentState.interval = n end
            end,
        })
        SellPresentSection:AddToggle({
            Title    = "Enable Auto Sell Present",
            Default  = false,
            NoSave   = true,
            Callback = function(on)
                if on then
                    if _presentState.enabled then return end
                    local sellRemote = NetEvents.RF_SellItem
                    if not sellRemote or not ReplionData or not ItemUtility then return end
                    _presentState.enabled = true
                    _presentState.task = task.spawn(function()
                        while _presentState.enabled do
                            pcall(function()
                                if tick() - _presentState.lastSell >= 0.5 then
                                    local inventory = ReplionData:GetExpect({"Inventory", "Items"})
                                    for _, item in ipairs(inventory) do
                                        local d = ItemUtility:GetItemData(item.Id)
                                        if d and d.Present == true then
                                            pcall(function() sellRemote:InvokeServer(item.UUID) end)
                                            task.wait(0.1)
                                        end
                                    end
                                    _presentState.lastSell = tick()
                                end
                            end)
                            task.wait(_presentState.interval)
                        end
                    end)
                else
                    _presentState.enabled = false
                    if _presentState.task then
                        task.cancel(_presentState.task)
                        _presentState.task = nil
                    end
                end
            end,
        })

        SellPresentSection:AddButton({
            Title    = "Sell Present Now",
            Callback = function()
                local sellRemote = NetEvents.RF_SellItem
                if not sellRemote or not ReplionData or not ItemUtility then return end
                pcall(function()
                    local inventory = ReplionData:GetExpect({"Inventory", "Items"})
                    for _, item in ipairs(inventory) do
                        local d = ItemUtility:GetItemData(item.Id)
                        if d and d.Present == true then
                            pcall(function() sellRemote:InvokeServer(item.UUID) end)
                            task.wait(0.1)
                        end
                    end
                end)
            end,
        })
    end

    do
        local MerchantSection = ShopTab:AddSection("Remote Merchant")
        local PlayerGui       = LocalPlayer:FindFirstChild("PlayerGui")
        MerchantSection:AddButton({
            Title    = "Open Merchant",
            Callback = function()
                pcall(function()
                    local gui      = PlayerGui or LocalPlayer:WaitForChild("PlayerGui", 5)
                    local merchant = gui and (gui:FindFirstChild("Merchant") or gui:WaitForChild("Merchant", 3))
                    if merchant then merchant.Enabled = true end
                end)
            end,
        })
        MerchantSection:AddButton({
            Title    = "Close Merchant",
            Callback = function()
                pcall(function()
                    local gui      = PlayerGui or LocalPlayer:FindFirstChild("PlayerGui")
                    local merchant = gui and gui:FindFirstChild("Merchant")
                    if merchant then merchant.Enabled = false end
                end)
            end,
        })
    end

    do
        local MerchantSection = ShopTab:AddSection("Auto Buy Merchant Items", false)
        local _merchantState = {
            enabled      = false,
            task         = nil,
            selectedItem = nil,
            amount       = 1,
            boughtCount  = 0,
            data         = nil,
            merchantData = nil,
        }
        local _itemList = {}
        local _itemMap  = {}
        local MerchantStatusParagraph = MerchantSection:AddParagraph({
            Title   = "Status",
            Content = "Item   : -\nHarga  : -\nDibeli : 0 / 0",
        })
        local _itemDropdown = MerchantSection:AddDropdown({
            Title    = "Pilih Item",
            Options  = {},
            NoSave   = true,
            Callback = function(selected)
                _merchantState.selectedItem = _itemMap[selected]
                _merchantState.boughtCount  = 0
                local item = _merchantState.selectedItem
                MerchantStatusParagraph:SetContent(
                    ("Item   : %s\nHarga  : %s\nDibeli : %d / %d"):format(
                        item and item.name or "-",
                        item and (tostring(item.price) .. " " .. item.currency) or "-",
                        0,
                        _merchantState.amount
                    )
                )
            end,
        })
        MerchantSection:AddInput({
            Title    = "Jumlah Beli",
            Default  = "1",
            Numeric  = true,
            NoSave   = true,
            Callback = function(value)
                local n = tonumber(value)
                if n and n >= 1 then
                    _merchantState.amount = math.floor(n)
                end
            end,
        })
        MerchantSection:AddButton({
            Title    = "Refresh Item Merchant",
            Callback = function()
                local ok = pcall(function()
                    local RS      = game:GetService("ReplicatedStorage")
                    local Replion = require(RS.Packages.Replion)
                    if not _merchantState.data         then _merchantState.data         = Replion.Client:WaitReplion("Data")     end
                    if not _merchantState.merchantData then _merchantState.merchantData = Replion.Client:WaitReplion("Merchant") end
                end)
                if not ok or not _merchantState.merchantData then
                    warn("[AutoBuyMerchant] Gagal init refs.")
                    return
                end
                _itemList = {}
                _itemMap  = {}
                pcall(function()
                    local RS              = game:GetService("ReplicatedStorage")
                    local ItemUtility     = require(RS.Shared.ItemUtility)
                    local MarketItemData  = require(RS.Shared.MarketItemData)
                    local CurrencyUtility = require(RS.Modules.CurrencyUtility)
                    local currentItems = _merchantState.merchantData:GetExpect("Items")
                    for _, itemId in ipairs(currentItems) do
                        local marketData = nil
                        for _, v in MarketItemData do
                            if v.Id == itemId then marketData = v; break end
                        end
                        if not marketData          then continue end
                        if marketData.SkinCrate    then continue end
                        if marketData.ProductId    then continue end
                        if not marketData.Price    then continue end
                        if not marketData.Currency then continue end
                        local itemData = ItemUtility.GetItemDataFromItemType(marketData.Type, marketData.Identifier)
                        if not itemData then continue end
                        local currencyData = CurrencyUtility:GetCurrency(marketData.Currency)
                        if not currencyData then continue end
                        local entry = {
                            id           = itemId,
                            name         = itemData.Data.Name or ("Item #" .. itemId),
                            price        = marketData.Price,
                            currency     = marketData.Currency,
                            currencyPath = currencyData.Path,
                        }
                        table.insert(_itemList, entry.name)
                        _itemMap[entry.name] = entry
                    end
                end)
                _itemDropdown:SetOptions(_itemList)
                if _merchantState.selectedItem and not _itemMap[_merchantState.selectedItem.name] then
                    _merchantState.selectedItem = nil
                end
                if not _merchantState.selectedItem and #_itemList > 0 then
                    _merchantState.selectedItem = _itemMap[_itemList[1]]
                end
                Library:MakeNotify({
                    Title       = "Auto Buy Merchant",
                    Description = ("Ditemukan %d item di merchant"):format(#_itemList),
                    Delay       = 3,
                })
            end,
        })
        MerchantSection:AddToggle({
            Title    = "Auto Buy",
            Default  = false,
            NoSave   = true,
            Callback = function(on)
                if on then
                    if _merchantState.enabled then return end
                    if not _merchantState.data or not _merchantState.merchantData then
                        Library:MakeNotify({ Title = "Auto Buy Merchant", Description = "Tekan Refresh dulu!", Delay = 3 })
                        return
                    end
                    if not _merchantState.selectedItem then
                        Library:MakeNotify({ Title = "Auto Buy Merchant", Description = "Pilih item dulu dari dropdown!", Delay = 3 })
                        return
                    end
                    _merchantState.enabled     = true
                    _merchantState.boughtCount = 0
                    _merchantState.task = task.spawn(function()
                        while _merchantState.enabled do
                            if _merchantState.boughtCount >= _merchantState.amount then
                                _merchantState.enabled = false
                                Library:MakeNotify({
                                    Title       = "Auto Buy Merchant",
                                    Description = ("Selesai! Terbeli %d x %s"):format(
                                        _merchantState.boughtCount,
                                        _merchantState.selectedItem.name
                                    ),
                                    Delay = 4,
                                })
                                break
                            end
                            local item    = _merchantState.selectedItem
                            local balance = _merchantState.data:Get(item.currencyPath) or 0
                            if balance < item.price then
                                _merchantState.enabled = false
                                Library:MakeNotify({ Title = "Auto Buy Merchant", Description = "Saldo tidak cukup, dihentikan.", Delay = 4 })
                                break
                            end
                            local ok, result = pcall(function()
                                return NetEvents.RF_PurchaseMarketItem:InvokeServer(item.id)
                            end)
                            if ok and result then
                                _merchantState.boughtCount = _merchantState.boughtCount + 1
                                MerchantStatusParagraph:SetContent(
                                    ("Item   : %s\nHarga  : %s\nDibeli : %d / %d"):format(
                                        item.name,
                                        tostring(item.price) .. " " .. item.currency,
                                        _merchantState.boughtCount,
                                        _merchantState.amount
                                    )
                                )
                            else
                                _merchantState.enabled = false
                                Library:MakeNotify({ Title = "Auto Buy Merchant", Description = "Gagal beli, dihentikan.", Delay = 4 })
                                break
                            end
                            task.wait(0.05)
                        end
                        _merchantState.task = nil
                    end)
                else
                    _merchantState.enabled = false
                    if _merchantState.task then
                        task.cancel(_merchantState.task)
                        _merchantState.task = nil
                    end
                    Library:MakeNotify({
                        Title       = "Auto Buy Merchant",
                        Description = ("Dihentikan. Terbeli: %d item"):format(_merchantState.boughtCount),
                        Delay       = 3,
                    })
                end
            end,
        })

        MerchantSection:AddButton({
            Title    = "Buy Once (Manual)",
            Callback = function()
                if not _merchantState.data or not _merchantState.merchantData then
                    Library:MakeNotify({ Title = "Auto Buy Merchant", Description = "Tekan Refresh dulu!", Delay = 3 })
                    return
                end
                if not _merchantState.selectedItem then
                    Library:MakeNotify({ Title = "Auto Buy Merchant", Description = "Pilih item dulu dari dropdown!", Delay = 3 })
                    return
                end
                local item    = _merchantState.selectedItem
                local balance = _merchantState.data:Get(item.currencyPath) or 0
                if balance < item.price then
                    Library:MakeNotify({ Title = "Auto Buy Merchant", Description = "Saldo tidak cukup!", Delay = 3 })
                    return
                end
                local ok, result = pcall(function()
                    return NetEvents.RF_PurchaseMarketItem:InvokeServer(item.id)
                end)
                if ok and result then
                    _merchantState.boughtCount = _merchantState.boughtCount + 1
                end
                Library:MakeNotify({
                    Title       = "Auto Buy Merchant",
                    Description = (ok and result)
                        and ("Berhasil beli: " .. item.name)
                        or  "Gagal beli item!",
                    Delay = 3,
                })
            end,
        })
    end

    do
        local BuyRodSection = ShopTab:AddSection("Buy Rod")
        local _buyRodState  = { selectedName = nil, selectedId = nil }
        local rodNames, rodLookup, rodLoaded = {}, {}, false
        local function loadRods()
            if rodLoaded then return end
            rodLoaded = true
            pcall(function()
                local rods = ItemUtility:GetFishingRods()
                for _, rod in ipairs(rods) do
                    local price = rod.Price or 0
                    if price >= 1 and not rod.LinkedGamePass then
                        local name = rod.Data.Name
                        table.insert(rodNames, name)
                        rodLookup[name] = { Id = rod.Data.Id, Price = price }
                    end
                end
                table.sort(rodNames, function(a, b)
                    return (rodLookup[a].Price) < (rodLookup[b].Price)
                end)
            end)
            if rodNames[1] then
                _buyRodState.selectedName = rodNames[1]
                local d = rodLookup[rodNames[1]]
                if d then _buyRodState.selectedId = d.Id end
            end
        end
        BuyRodSection:AddDropdown({
            Title    = "Select Rod",
            Options  = rodNames,
            Default  = nil,
            Callback = function(value)
                loadRods()
                _buyRodState.selectedName = value
                local d = rodLookup[value]
                if d then _buyRodState.selectedId = d.Id end
            end,
        })
        BuyRodSection:AddButton({
            Title    = "Buy Rod",
            Callback = function()
                loadRods()
                pcall(function()
                    if not _buyRodState.selectedName or not _buyRodState.selectedId then return end
                    local d = rodLookup[_buyRodState.selectedName]
                    if not d then return end
                    local inventory = ReplionData:GetExpect({ "Inventory", "Fishing Rods" })
                    for _, item in ipairs(inventory) do
                        if item.Id == _buyRodState.selectedId then return end
                    end
                    local coins = ReplionData:GetExpect("Coins") or 0
                    if coins < d.Price then return end
                    local success, newItemId = NetEvents.RF_PurchaseFishingRod:InvokeServer(_buyRodState.selectedId)
                    if success and newItemId then
                        NetEvents.RE_EquipItem:FireServer(newItemId, "Fishing Rods")
                    end
                end)
            end,
        })
    end

    do
        local BuyBaitSection = ShopTab:AddSection("Buy Bait")
        local _buyBaitState  = { selectedName = nil, selectedId = nil }
        local baitNames, baitLookup, baitLoaded = {}, {}, false
        local function loadBaits()
            if baitLoaded then return end
            baitLoaded = true
            pcall(function()
                local baits = ItemUtility:GetBaits()
                for _, bait in ipairs(baits) do
                    if not bait.HiddenInShop then
                        local price = bait.Price or 0
                        if price >= 1 and not bait.LinkedGamePass then
                            local name = bait.Data.Name
                            table.insert(baitNames, name)
                            baitLookup[name] = { Id = bait.Data.Id, Price = price }
                        end
                    end
                end
                table.sort(baitNames, function(a, b)
                    return (baitLookup[a].Price) < (baitLookup[b].Price)
                end)
            end)
            if baitNames[1] then
                _buyBaitState.selectedName = baitNames[1]
                local d = baitLookup[baitNames[1]]
                if d then _buyBaitState.selectedId = d.Id end
            end
        end
        BuyBaitSection:AddDropdown({
            Title    = "Select Bait",
            Options  = baitNames,
            Default  = nil,
            Callback = function(value)
                loadBaits()
                _buyBaitState.selectedName = value
                local d = baitLookup[value]
                if d then _buyBaitState.selectedId = d.Id end
            end,
        })
        BuyBaitSection:AddButton({
            Title    = "Buy Bait",
            Callback = function()
                loadBaits()
                pcall(function()
                    if not _buyBaitState.selectedName or not _buyBaitState.selectedId then return end
                    local d = baitLookup[_buyBaitState.selectedName]
                    if not d then return end
                    local inventory = ReplionData:GetExpect({ "Inventory", "Baits" })
                    for _, item in ipairs(inventory) do
                        if item.Id == _buyBaitState.selectedId then return end
                    end
                    local coins = ReplionData:GetExpect("Coins") or 0
                    if coins < d.Price then return end
                    local success, newItemId = NetEvents.RF_PurchaseBait:InvokeServer(_buyBaitState.selectedId)
                    if success and newItemId then
                        NetEvents.RE_EquipBait:FireServer(_buyBaitState.selectedId)
                    end
                end)
            end,
        })
    end
end

-- [Automation]
do
    local AutoTab = MainWindow:AddTab({ Name = "Automation", Icon = "next" })
    local CollectionService = game:GetService("CollectionService")
    do
        local AutoIndexSection = AutoTab:AddSection("Auto Complete Fish Index [BETA]", false)
        local _indexState = {
            enabled         = false,
            thread          = nil,
            statusParagraph = nil,
            excludedTiers   = {},
        }
        local AREA_COORDS = {
            ["Ancient Jungle"]        = { pos = Vector3.new(1467.427, 7.574, -327.697),        look = Vector3.new(1610.471, 7.574, -282.549) },
            ["Ancient Ruin"]          = { pos = Vector3.new(6045.402, -588.601, 4608.938),     look = Vector3.new(6059.215, -588.601, 4758.300) },
            ["Coral Reefs"]           = { pos = Vector3.new(-2921.858, 3.250, 2083.297),       look = Vector3.new(-3068.679, 3.250, 2052.582) },
            ["Crater Island"]         = { pos = Vector3.new(1074.376, 4.027, 5098.477),        look = Vector3.new(928.264, 4.027, 5064.545) },
            ["Esoteric Depths"]       = { pos = Vector3.new(3206.972, -1302.855, 1417.300),    look = Vector3.new(3274.385, -1302.855, 1551.298) },
            ["Fisherman Island"]      = { pos = Vector3.new(-61.728, 3.532, 2770.768),         look = Vector3.new(-211.452, 3.532, 2761.671) },
            ["Kohana"]                = { pos = Vector3.new(-655.469, 17.245, 501.038),        look = Vector3.new(-511.246, 17.245, 542.266) },
            ["Kohana Lab"]            = { pos = Vector3.new(-201.608, 63.556, 475.351),        look = Vector3.new(-206.758, 63.556, 483.923) },
            ["Kohana Volcano"]        = { pos = Vector3.new(-552.305, 20.729, 183.195),        look = Vector3.new(-604.901, 20.729, 42.719) },
            ["Lost Isle"]             = { pos = Vector3.new(-3685.375, 5.426, -1066.627),      look = Vector3.new(-3638.585, 5.426, -1209.143) },
            ["Sisyphus Statue"]       = { pos = Vector3.new(-3656.654, -134.358, -963.251),    look = Vector3.new(-3802.689, -134.358, -928.990) },
            ["Sacred Temple"]         = { pos = Vector3.new(1453.839, -22.125, -621.652),      look = Vector3.new(1480.257, -22.125, -473.996) },
            ["Treasure Room"]         = { pos = Vector3.new(-3597.324, -275.674, -1641.224),   look = Vector3.new(-3722.606, -275.674, -1558.736) },
            ["Tropical Grove"]        = { pos = Vector3.new(-2140.796, 53.487, 3622.714),      look = Vector3.new(-2216.205, 53.487, 3752.381) },
            ["Underground Cellar"]    = { pos = Vector3.new(2161.391, -91.198, -729.227),      look = Vector3.new(2022.332, -91.198, -672.990) },
            ["Pirate Cove"]           = { pos = Vector3.new(3406.972, 4.193, 3497.086),        look = Vector3.new(3512.487, 4.193, 3390.472) },
            ["Leviathan's Den"]       = { pos = Vector3.new(3472.983, -287.843, 3471.071),     look = Vector3.new(3530.812, -287.843, 3609.456) },
            ["Pirate Treasure Room"]  = { pos = Vector3.new(3349.351, -297.941, 3086.003),     look = Vector3.new(3247.830, -297.941, 2975.578) },
            ["Crystal Depths"]        = { pos = Vector3.new(5729.334, -904.818, 15408.078),    look = Vector3.new(5691.893, -904.818, 15262.826) },
            ["Volcanic Cavern"]       = { pos = Vector3.new(1145.140, 74.942, -10234.558),     look = Vector3.new(1277.255, 74.942, -10163.525) },
            ["Lava Basin"]            = { pos = Vector3.new(894.223, 89.033, -10195.547),      look = Vector3.new(1032.501, 89.033, -10137.418) },
            ["Weather Machine"]       = { pos = Vector3.new(-1528.407, 2.875, 1915.324),       look = Vector3.new(-1513.045, 2.875, 2064.535) },
            ["Underwater City"]       = { pos = Vector3.new(-3140.833, -643.477, -10415.806),  look = Vector3.new(-2990.863, -643.477, -10418.791) },
            ["Planetary Observatory"] = { pos = Vector3.new(423.340, 3.673, 2184.189),         look = Vector3.new(570.127, 3.673, 2215.069) },
            ["Sewers"]                = { pos = Vector3.new(-1448.109, -1041.589, -10447.079), look = Vector3.new(-1598.040, -1041.589, -10442.528) },
            ["Classic Island"]        = { pos = Vector3.new(1442.234, 58.001, 2877.836),       look = Vector3.new(1407.905, -34.288, 2764.680) },
            ["Classic Cave"]          = { pos = Vector3.new(1503.046, -1132.000, 2869.713),    look = Vector3.new(1602.930, -1132.000, 2874.513) },
            ["Iron Cave"]             = { pos = Vector3.new(1469.620, -1109.000, 2576.640),    look = Vector3.new(1483.381, -1109.000, 2477.591) },
            ["Classic School"]        = { pos = Vector3.new(1374.785, 54.000, 2730.551),       look = Vector3.new(1374.494, 54.000, 2630.552) },
            ["Aquarium"]              = { pos = Vector3.new(-3039.558, -624.243, -10573.49),   look = Vector3.new(-3036.04, -624.243, -10582.851) },
            ["Copper Canyon"]         = { pos = Vector3.new(-4145.043, 7.947, 617.358),        look = Vector3.new(-4154.176, 7.947, 613.285) },
            ["Copper Canyon Mines"]   = { pos = Vector3.new(-4079.106, -547.174, 548.035),     look = Vector3.new(-4069.595, -547.174, 551.125) },
            ["Ocean"]                 = { pos = Vector3.new(-1528.407, 2.875, 1915.324),       look = Vector3.new(-1513.045, 2.875, 2064.535) },
        }
        local SPECIAL_DATA = {
            ["Ocean"]                = { "Ghost Worm Fish", "Megalodon", "Thunderzilla", "Bloodmoon Whale", "1x1x1x1 Comet Shark" },
            ["Ancient Jungle"]       = { "Crescent Artifact", "Arrow Artifact", "Hourglass Diamond Artifact", "Diamond Artifact" },
            ["Ancient Ruin"]         = { "Ancient Lochness Monster" },
            ["Sisyphus Statue"]      = { "Depthseeker Ray" },
            ["Copper Canyon Mines"]  = { "Cerulean Dragon" },
            ["Pirate Treasure Room"] = { "Pirate Starfish", "Stormy Dumbo" },
            ["Pirate Cove"]          = { "Rainy Dumbo" },
            ["Crystal Depths"]       = { "Cute Dumbo", "Hank's Diary" },
            ["Underwater City"]      = { "Mutant Runic Koi" },
        }
        local function indexSetStatus(title, content)
            pcall(function()
                _indexState.statusParagraph:SetTitle(title)
                _indexState.statusParagraph:SetContent(content)
            end)
        end

        local function teleportTo(coords)
            local hrp = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
            if not hrp then return false end
            local lookDir = (coords.look - coords.pos).Unit
            hrp.CFrame = CFrame.lookAt(coords.pos, coords.pos + lookDir)
            return true
        end

        local function getMissingFishByArea(excludedTiers)
            local Replion     = require(ReplicatedStorage.Packages.Replion)
            local Areas       = require(ReplicatedStorage.Areas)
            local ItemUtility = require(ReplicatedStorage.Shared.ItemUtility)
            local TierUtility = require(ReplicatedStorage.Shared.TierUtility)

            local replionData = Replion.Client:GetReplion("Data")
            if not replionData then return {} end

            local caughtMastery = replionData:Get("CaughtFishMastery") or {}

            local excludeSet = {}
            if excludedTiers then
                for _, tierName in ipairs(excludedTiers) do
                    excludeSet[tierName] = true
                end
            end

            local result = {}

            for areaName, areaData in pairs(Areas) do
                if areaData.NoDisplay or areaData.Hidden or areaData.ComingSoon then continue end
                if not AREA_COORDS[areaName] then continue end

                local missing  = {}
                local allItems = {}

                if areaData.Items then
                    for _, fishId in ipairs(areaData.Items) do
                        table.insert(allItems, fishId)
                    end
                end

                local specialList = SPECIAL_DATA[areaName]
                if specialList then
                    for _, fishId in ipairs(specialList) do
                        table.insert(allItems, fishId)
                    end
                end

                for _, fishId in ipairs(allItems) do
                    local itemData = ItemUtility:GetItemData(fishId)
                    if not itemData then continue end

                    local fishName = itemData.Data and itemData.Data.Name
                    if not fishName then continue end

                    if itemData.Events ~= nil then continue end

                    local prob = itemData.Probability or itemData.ForcedProbability
                    if prob then
                        local tierData = TierUtility.GetTierFromRarity(nil, prob.Chance)
                        if tierData and excludeSet[tierData.Name] then continue end
                    else
                        local tier = itemData.Data and itemData.Data.Tier
                        if tier then
                            local tierData = TierUtility.GetTier(nil, tier)
                            if tierData and excludeSet[tierData.Name] then continue end
                        end
                    end

                    if not caughtMastery[fishName] then
                        table.insert(missing, fishName)
                    end
                end

                if #missing > 0 then
                    table.insert(result, {
                        areaName = areaName,
                        missing  = missing,
                        coords   = AREA_COORDS[areaName],
                        order    = areaData.Order or 9999,
                    })
                end
            end

            table.sort(result, function(a, b)
                return a.order < b.order
            end)

            return result
        end

        _indexState.statusParagraph = AutoIndexSection:AddParagraph({
            Title   = "Status",
            Content = "Idle",
        })

        AutoIndexSection:AddParagraph({
            Title   = "Info",
            Content = "Otomatis teleport ke setiap area yang masih ada ikan belum di-index.\n"
                .. "Tunggu di area sampai semua ikan tertangkap, lalu pindah ke area berikutnya.\n"
                .. "Event fish dan special/limited fish dilewati.",
        })

        AutoIndexSection:AddDropdown({
            Title    = "Exclude Rarity",
            Multi    = true,
            Default  = {},
            Options   = {
                "Common",
                "Uncommon",
                "Rare",
                "Epic",
                "Legendary",
                "Mythic",
                "SECRET",
                "FORGOTTEN",
                "Trophy",
                "Collectible",
                "Exclusive",
            },
            Callback = function(selected)
                _indexState.excludedTiers = selected
            end,
        })

        AutoIndexSection:AddToggle({
            Title    = "Enable Auto Complete Fish Index",
            Default  = false,
            NoSave   = true,
            Callback = function(on)
                _indexState.enabled = on

                if _indexState.thread then
                    pcall(task.cancel, _indexState.thread)
                    _indexState.thread = nil
                end

                if not on then
                    indexSetStatus("Status", "Idle")
                    return
                end

                _indexState.thread = task.spawn(function()
                    indexSetStatus("Scanning...", "Mengecek index yang belum lengkap...")

                    local missingAreas = getMissingFishByArea(_indexState.excludedTiers)

                    if #missingAreas == 0 then
                        indexSetStatus("Complete!", "Semua fish index sudah lengkap!")
                        Library:MakeNotify({
                            Title       = "Auto Index",
                            Description = "Semua fish index sudah lengkap!",
                            Delay       = 4,
                        })
                        _indexState.enabled = false
                        return
                    end

                    local totalAreas = #missingAreas
                    local areasDone  = 0

                    for _, areaInfo in ipairs(missingAreas) do
                        if not _indexState.enabled then break end

                        areasDone += 1
                        local areaName    = areaInfo.areaName
                        local missingList = areaInfo.missing
                        local coords      = areaInfo.coords

                        indexSetStatus(
                            "Teleporting... (" .. areasDone .. "/" .. totalAreas .. ")",
                            "Area: " .. areaName .. "\nIkan missing: " .. #missingList
                        )

                        Library:MakeNotify({
                            Title       = "Auto Index",
                            Description = "Menuju: " .. areaName .. " (" .. #missingList .. " ikan)",
                            Delay       = 3,
                        })

                        teleportTo(coords)
                        task.wait(2)

                        if not _indexState.enabled then break end

                        local remaining = {}
                        for _, fishName in ipairs(missingList) do
                            table.insert(remaining, fishName)
                        end

                        while #remaining > 0 and _indexState.enabled do
                            local Replion     = require(ReplicatedStorage.Packages.Replion)
                            local replionData = Replion.Client:GetReplion("Data")
                            if replionData then
                                local caughtMastery = replionData:Get("CaughtFishMastery") or {}
                                local stillMissing  = {}
                                for _, fishName in ipairs(remaining) do
                                    if not caughtMastery[fishName] then
                                        table.insert(stillMissing, fishName)
                                    end
                                end
                                remaining = stillMissing
                            end

                            if #remaining > 0 then
                                indexSetStatus(
                                    "Fishing at " .. areaName .. " (" .. areasDone .. "/" .. totalAreas .. ")",
                                    "Sisa: " .. table.concat(remaining, ", ")
                                )
                                task.wait(3)
                            end
                        end

                        if #remaining == 0 then
                            Library:MakeNotify({
                                Title       = "Auto Index",
                                Description = "Area " .. areaName .. " complete!",
                                Delay       = 3,
                            })
                        end

                        task.wait(1)
                    end

                    if _indexState.enabled then
                        indexSetStatus("Done!", "Semua area sudah dikunjungi.")
                        Library:MakeNotify({
                            Title       = "Auto Index",
                            Description = "Auto Complete Fish Index selesai!",
                            Delay       = 4,
                        })
                        _indexState.enabled = false
                    else
                        indexSetStatus("Status", "Idle")
                    end
                end)
            end,
        })

        AutoIndexSection:AddButton({
            Title    = "Scan Missing Now",
            Callback = function()
                task.spawn(function()
                    indexSetStatus("Scanning...", "Mengecek index...")
                    local missingAreas = getMissingFishByArea(_indexState.excludedTiers)
                    if #missingAreas == 0 then
                        indexSetStatus("Complete!", "Semua fish index sudah lengkap!")
                        Library:MakeNotify({ Title = "Auto Index", Description = "Semua index sudah lengkap!", Delay = 3 })
                    else
                        local totalMissing = 0
                        local areaNames    = {}
                        for _, info in ipairs(missingAreas) do
                            totalMissing += #info.missing
                            table.insert(areaNames, info.areaName .. " (" .. #info.missing .. ")")
                        end
                        indexSetStatus(
                            "Missing: " .. totalMissing .. " ikan",
                            table.concat(areaNames, "\n")
                        )
                        Library:MakeNotify({
                            Title       = "Auto Index",
                            Description = totalMissing .. " ikan belum di-index di " .. #missingAreas .. " area.",
                            Delay       = 4,
                        })
                    end
                end)
            end,
        })
    end

    do
        local TreasureJoinSection = AutoTab:AddSection("Auto Join Treasure Hunt Server", false)
        local _tjState = {
            enabled   = false,
            thread    = nil,
            lastJobId = nil,
            scanning  = false,
        }

        local _tjStatusParagraph = TreasureJoinSection:AddParagraph({
            Title   = "Status",
            Content = "Idle",
        })

        local function tjSetStatus(title, content)
            pcall(function()
                _tjStatusParagraph:SetTitle(title)
                _tjStatusParagraph:SetContent(content)
            end)
        end

        local function tjFindTreasureServers()
            local Replion = require(ReplicatedStorage.Packages.Replion)
            local v3 = Replion.Client:WaitReplion("ServerBrowser")
            if not v3 then return {} end

            local servers = v3.Data and v3.Data.Servers
            if not servers then return {} end

            local maxPlayers = Players.MaxPlayers
            local candidates = {}

            for jobId, serverData in pairs(servers) do
                if jobId == game.JobId then continue end
                if not serverData.Events then continue end

                local playerCount = serverData.Players and #serverData.Players or 0
                if playerCount >= maxPlayers then continue end

                for _, eventName in ipairs(serverData.Events) do
                    if eventName == "Treasure Hunt" then
                        table.insert(candidates, {
                            jobId   = jobId,
                            ping    = serverData.Ping or 9999,
                            players = playerCount,
                            max     = maxPlayers,
                        })
                        break
                    end
                end
            end

            table.sort(candidates, function(a, b)
                return a.ping < b.ping
            end)

            return candidates
        end

        local function tjTeleportToServer(jobId)
            local TeleportService = game:GetService("TeleportService")
            sharedQueueAutoExecute(true)
            local ok, err = pcall(function()
                TeleportService:TeleportToPlaceInstance(game.PlaceId, jobId, LocalPlayer)
            end)
            if not ok then
                warn("[TreasureJoin] Teleport failed:", err)
                _queueExecuted = false
            end
            return ok
        end

        local function tjIsCurrentServerTreasure()
            local ok, result = pcall(function()
                local Replion = require(ReplicatedStorage.Packages.Replion)
                local v3 = Replion.Client:WaitReplion("ServerBrowser")
                if not v3 then return false end
                local servers = v3.Data and v3.Data.Servers
                if not servers then return false end
                local current = servers[game.JobId]
                if not current or not current.Events then return false end
                for _, eventName in ipairs(current.Events) do
                    if eventName == "Treasure Hunt" then return true end
                end
                return false
            end)
            return ok and result
        end

        local function tjStartLoop()
            if _tjState.thread then
                pcall(task.cancel, _tjState.thread)
                _tjState.thread = nil
            end

            _tjState.thread = task.spawn(function()
                while _tjState.enabled do
                    if tjIsCurrentServerTreasure() then
                        tjSetStatus("Active", "On a Treasure Hunt server!\nWaiting for event to end...")
                        Library:MakeNotify({
                            Title       = "Treasure Hunt",
                            Description = "Already on a Treasure Hunt server!",
                            Delay       = 3,
                        })
                        while _tjState.enabled do
                            task.wait(5)
                            if not tjIsCurrentServerTreasure() then
                                tjSetStatus("Scanning...", "Event ended. Looking for next server...")
                                break
                            end
                        end
                        continue
                    end

                    tjSetStatus("Scanning...", "Looking for Treasure Hunt servers...")
                    _tjState.scanning = true

                    local candidates = {}
                    pcall(function()
                        candidates = tjFindTreasureServers()
                    end)

                    _tjState.scanning = false

                    if #candidates > 0 then
                        local teleported = false

                        for _, candidate in ipairs(candidates) do
                            if not _tjState.enabled then break end

                            _tjState.lastJobId = candidate.jobId
                            local info = "Players: " .. candidate.players .. "/" .. candidate.max
                            tjSetStatus("Found!", "Treasure Hunt server found!\n" .. info .. "\nTeleporting...")
                            Library:MakeNotify({
                                Title       = "Treasure Hunt",
                                Description = "Trying server... " .. info,
                                Delay       = 2,
                            })

                            task.wait(1)
                            if not _tjState.enabled then break end

                            local ok = tjTeleportToServer(candidate.jobId)
                            if ok then
                                teleported = true
                                task.wait(10)
                                break
                            else
                                tjSetStatus("Retrying...", "Server full or failed, trying next...")
                                Library:MakeNotify({
                                    Title       = "Treasure Hunt",
                                    Description = "Failed, trying next server...",
                                    Delay       = 2,
                                })
                                task.wait(1)
                            end
                        end

                        if not teleported and _tjState.enabled then
                            tjSetStatus("Not Found", "All servers full or failed.\nRetrying in 30 seconds...")
                            Library:MakeNotify({
                                Title       = "Treasure Hunt",
                                Description = "All servers failed. Retrying in 30s...",
                                Delay       = 4,
                            })
                            local waited = 0
                            while _tjState.enabled and waited < 30 do
                                task.wait(1)
                                waited += 1
                            end
                        end
                    else
                        tjSetStatus("Not Found", "No Treasure Hunt server found.\nRetrying in 30 seconds...")
                        Library:MakeNotify({
                            Title       = "Treasure Hunt",
                            Description = "No server found. Retrying in 30s...",
                            Delay       = 4,
                        })
                        local waited = 0
                        while _tjState.enabled and waited < 30 do
                            task.wait(1)
                            waited += 1
                        end
                    end
                end

                tjSetStatus("Status", "Idle")
            end)
        end

        TreasureJoinSection:AddParagraph({
            Title   = "Info",
            Content = "Automatically scans the server list for a server with an active Treasure Hunt event "
                .. "and teleports to it.\n"
                .. "Tries all available servers if one is full.\n"
                .. "Waits for event to end then finds next server automatically.\n"
                .. "Rescans every 30 seconds if no server is found.\n\n"
                .. "⚠️ To disable this feature, you must rejoin the server manually, leave and rejoin the map, or restart Roblox.\n"
                .. "⚠️ Untuk menonaktifkan fitur ini, kamu harus rejoin server secara manual, keluar masuk map, atau restart Roblox.",
        })

        local _tjToggle = TreasureJoinSection:AddToggle({
            Title    = "Enable Auto Join Treasure Hunt",
            Default  = false,
            NoSave   = true,
            Callback = function(on)
                _tjState.enabled = on

                if not on then
                    if _tjState.thread then
                        pcall(task.cancel, _tjState.thread)
                        _tjState.thread = nil
                    end
                    tjSetStatus("Status", "Idle")
                    return
                end

                tjStartLoop()
            end,
        })

        task.spawn(function()
            task.wait(8)
            if getgenv().__autoTreasureJoin then
                getgenv().__autoTreasureJoin = nil
                _tjState.enabled = true
                tjStartLoop()
                task.wait(1)
                pcall(function()
                    if _tjToggle then
                        _tjToggle:Set(true)
                    end
                end)
            end
        end)

        TreasureJoinSection:AddButton({
            Title    = "Scan Now",
            Callback = function()
                if _tjState.scanning then
                    Library:MakeNotify({ Title = "Treasure Hunt", Description = "Already scanning...", Delay = 2 })
                    return
                end
                _tjState.scanning = true
                tjSetStatus("Scanning...", "Manually scanning for Treasure Hunt servers...")
                task.spawn(function()
                    local candidates = {}
                    pcall(function() candidates = tjFindTreasureServers() end)
                    _tjState.scanning = false
                    if #candidates > 0 then
                        local best = candidates[1]
                        _tjState.lastJobId = best.jobId
                        local info = best.players .. "/" .. best.max .. " players"
                        tjSetStatus("Found!", "Server found!\n" .. info .. "\n(" .. #candidates .. " servers available)")
                        Library:MakeNotify({
                            Title       = "Treasure Hunt",
                            Description = #candidates .. " server(s) found! " .. info .. " — Press Teleport Now to join.",
                            Delay       = 4,
                        })
                    else
                        tjSetStatus("Not Found", "No Treasure Hunt server available right now.\n(All servers may be full or no event active)")
                        Library:MakeNotify({
                            Title       = "Treasure Hunt",
                            Description = "No available Treasure Hunt server found.",
                            Delay       = 3,
                        })
                    end
                end)
            end,
        })

        TreasureJoinSection:AddButton({
            Title    = "Teleport Now",
            Callback = function()
                if not _tjState.lastJobId then
                    Library:MakeNotify({
                        Title       = "Treasure Hunt",
                        Description = "No server found yet. Scan first!",
                        Delay       = 3,
                    })
                    return
                end
                Library:MakeNotify({
                    Title       = "Treasure Hunt",
                    Description = "Teleporting to: " .. _tjState.lastJobId,
                    Delay       = 3,
                })
                tjTeleportToServer(_tjState.lastJobId)
            end,
        })
    end
    do
        local autoTreasureRunning = false
        local treasureStatus = nil
        local _treasureState = {
            savedPos        = nil,
            isAtEvent       = false,
            loopThread      = nil,
            childAddedConn  = nil,
            charAddedConn   = nil,
            antiDrownConn   = nil,
            antiDrownThread = nil,
            o2Equipped      = false,
        }
        local _lastStreamTime = 0
        local STREAM_INTERVAL = 10
        local TWEEN_DURATION = 4
        local TWEEN_EASING   = 3

        local TreasureSection = AutoTab:AddSection("Auto Treasure Hunt", false)

        TreasureSection:AddParagraph({
            Title   = "Info",
            Content = "Automatically detects Treasure Hunt (Sunken Wreckage) when event starts, "
                .. "teleports & collects chests, then returns to last position before the event.\n"
                .. "Uses Oxygen Tank to avoid drowning.\n"
                .. "After finishing will idle and wait for the next event automatically.",
        })

        treasureStatus = TreasureSection:AddParagraph({
            Title   = "Status",
            Content = "Inactive",
        })

        local function setStatus(msg)
            pcall(function() treasureStatus:SetContent(msg) end)
        end

        local function treasureEquipO2()
            pcall(function()
                if NetEvents.RF_EquipOxygenTank then
                    NetEvents.RF_EquipOxygenTank:InvokeServer(575)
                end
            end)
            _treasureState.o2Equipped = true
        end

        local function treasureUnequipO2()
            pcall(function()
                if NetEvents.RF_UnequipOxygenTank then
                    NetEvents.RF_UnequipOxygenTank:InvokeServer()
                end
            end)
            _treasureState.o2Equipped = false
        end

        local function startAntiDrown()
            if _treasureState.antiDrownConn then
                pcall(function() _treasureState.antiDrownConn:Disconnect() end)
                _treasureState.antiDrownConn = nil
            end
            if _treasureState.antiDrownThread then
                pcall(task.cancel, _treasureState.antiDrownThread)
                _treasureState.antiDrownThread = nil
            end
            _treasureState.antiDrownConn = RunService.Heartbeat:Connect(function()
                if not autoTreasureRunning then return end
                local char = LocalPlayer.Character
                if not char then return end
                local hum = char:FindFirstChild("Humanoid")
                if hum and hum.Health > 0 then
                    hum.Health = hum.MaxHealth
                end
            end)
            _treasureState.antiDrownThread = task.spawn(function()
                while autoTreasureRunning and _treasureState.isAtEvent do
                    pcall(function()
                        local char = LocalPlayer.Character
                        if not char then return end
                        local hum = char:FindFirstChild("Humanoid")
                        if hum then hum.Health = hum.MaxHealth end
                    end)
                    task.wait(0.5)
                end
            end)
        end

        local function stopAntiDrown()
            if _treasureState.antiDrownConn then
                pcall(function() _treasureState.antiDrownConn:Disconnect() end)
                _treasureState.antiDrownConn = nil
            end
            if _treasureState.antiDrownThread then
                pcall(task.cancel, _treasureState.antiDrownThread)
                _treasureState.antiDrownThread = nil
            end
        end

        local function streamTreasureArea(position)
            local now = tick()
            if now - _lastStreamTime < STREAM_INTERVAL then return end
            _lastStreamTime = now
            pcall(function()
                LocalPlayer:RequestStreamAroundAsync(position, 300)
            end)
        end

        local function getTreasureChests()
            local chests = {}
            local sw = workspace:FindFirstChild("Sunken Wreckage")
            if not sw then return chests end
            for _, child in ipairs(sw:GetChildren()) do
                if child.Name == "Treasure" and not child:GetAttribute("Opened") then
                    table.insert(chests, child)
                end
            end
            return chests
        end

        local function findPrompt(chest)
            return chest:FindFirstChildWhichIsA("ProximityPrompt", true)
        end

        local function getSunkenWreckageSurfacePos()
            local sw = workspace:FindFirstChild("Sunken Wreckage")
            if not sw then return nil end
            local centerPos = sw:GetPivot().Position
            return CFrame.new(Vector3.new(centerPos.X, 5, centerPos.Z))
        end

        local function tweenHRPToTarget(hrp, targetCF, duration)
            if not hrp or not hrp.Parent then return end
            local startCF = hrp.CFrame
            local startTime = tick()
            pcall(function()
                hrp.Anchored = true
                hrp.AssemblyLinearVelocity  = Vector3.zero
                hrp.AssemblyAngularVelocity = Vector3.zero
            end)
            local tweenDone = false
            local tweenConn
            tweenConn = RunService.Heartbeat:Connect(function()
                if not hrp or not hrp.Parent then
                    tweenConn:Disconnect()
                    tweenDone = true
                    return
                end
                local elapsed = tick() - startTime
                local alpha = math.min(elapsed / duration, 1)
                local easedAlpha = 1 - (1 - alpha) ^ TWEEN_EASING
                pcall(function()
                    hrp.CFrame = startCF:Lerp(targetCF, easedAlpha)
                    hrp.AssemblyLinearVelocity  = Vector3.zero
                    hrp.AssemblyAngularVelocity = Vector3.zero
                end)
                if alpha >= 1 then
                    tweenConn:Disconnect()
                    tweenDone = true
                end
            end)
            local waitStart = tick()
            while not tweenDone and (tick() - waitStart) < (duration + 1) do
                task.wait(0.05)
            end
            pcall(function()
                if tweenConn then tweenConn:Disconnect() end
            end)
        end

        local function teleportToSurface()
            local surfaceCF = getSunkenWreckageSurfacePos()
            if not surfaceCF then return false end
            local char = LocalPlayer.Character
            local hrp = char and char:FindFirstChild("HumanoidRootPart")
            if not hrp then return false end
            pcall(function()
                hrp.Anchored = true
                hrp.CFrame = surfaceCF
                hrp.AssemblyLinearVelocity  = Vector3.zero
                hrp.AssemblyAngularVelocity = Vector3.zero
            end)
            task.wait(0.15)
            pcall(function()
                hrp.CFrame = surfaceCF
                hrp.AssemblyLinearVelocity  = Vector3.zero
                hrp.AssemblyAngularVelocity = Vector3.zero
                hrp.Anchored = false
            end)
            return true
        end

        local function teleportToChestViaTween(hrp, chestCF)
            local surfaceCF = getSunkenWreckageSurfacePos()
            if surfaceCF then
                local nearSurfaceCF = CFrame.new(
                    Vector3.new(chestCF.Position.X, surfaceCF.Position.Y, chestCF.Position.Z)
                )
                pcall(function()
                    hrp.Anchored = true
                    hrp.CFrame = nearSurfaceCF
                    hrp.AssemblyLinearVelocity  = Vector3.zero
                    hrp.AssemblyAngularVelocity = Vector3.zero
                end)
                task.wait(0.2)
            end
            tweenHRPToTarget(hrp, chestCF, TWEEN_DURATION)
        end

        local function treasureCleanup()
            stopAntiDrown()
            if _treasureState.o2Equipped then
                treasureUnequipO2()
            end
            if _treasureState.loopThread then
                pcall(task.cancel, _treasureState.loopThread)
                _treasureState.loopThread = nil
            end
            if _treasureState.childAddedConn then
                pcall(function() _treasureState.childAddedConn:Disconnect() end)
                _treasureState.childAddedConn = nil
            end
            if _treasureState.charAddedConn then
                pcall(function() _treasureState.charAddedConn:Disconnect() end)
                _treasureState.charAddedConn = nil
            end
        end

        local function returnToSavedPos()
            local targetCF = _treasureState.savedPos
            if not targetCF then return false end

            setStatus("Returning to last position...")
            stopAntiDrown()

            local success = false
            for attempt = 1, 10 do
                local char = LocalPlayer.Character
                local hrp = char and char:FindFirstChild("HumanoidRootPart")
                if not hrp or not hrp.Parent then
                    task.wait(0.5)
                    continue
                end
                pcall(function()
                    hrp.Anchored = true
                    hrp.CFrame = targetCF
                    hrp.AssemblyLinearVelocity  = Vector3.zero
                    hrp.AssemblyAngularVelocity = Vector3.zero
                end)
                task.wait(0.2)
                pcall(function()
                    hrp.CFrame = targetCF
                    hrp.AssemblyLinearVelocity  = Vector3.zero
                    hrp.AssemblyAngularVelocity = Vector3.zero
                end)
                task.wait(0.1)
                local dist = (hrp.Position - targetCF.Position).Magnitude
                if dist < 5 then
                    success = true
                    pcall(function()
                        hrp.Anchored = false
                        hrp.AssemblyLinearVelocity  = Vector3.zero
                        hrp.AssemblyAngularVelocity = Vector3.zero
                    end)
                    break
                end
                pcall(function() hrp.Anchored = false end)
                task.wait(0.15)
            end

            task.spawn(function()
                for _ = 1, 20 do
                    local char = LocalPlayer.Character
                    local hrp = char and char:FindFirstChild("HumanoidRootPart")
                    if hrp and hrp.Parent then
                        pcall(function()
                            hrp.AssemblyLinearVelocity  = Vector3.zero
                            hrp.AssemblyAngularVelocity = Vector3.zero
                        end)
                    end
                    RunService.Heartbeat:Wait()
                end
            end)

            if _treasureState.o2Equipped then
                task.wait(0.3)
                treasureUnequipO2()
            end

            _treasureState.isAtEvent = false
            _treasureState.savedPos  = nil
            return success
        end

        local function processTreasureEvent()
            if not autoTreasureRunning then return end
            if _treasureState.isAtEvent then return end

            local sw = workspace:FindFirstChild("Sunken Wreckage")
            if not sw then return end

            pcall(function() streamTreasureArea(sw:GetPivot().Position) end)
            task.wait(0.5)

            local chests = getTreasureChests()
            if #chests == 0 then return end

            local char = LocalPlayer.Character
            local hrp  = char and char:FindFirstChild("HumanoidRootPart")
            if not hrp then return end

            _treasureState.savedPos  = hrp.CFrame
            _treasureState.isAtEvent = true

            setStatus("Teleporting to surface...")
            teleportToSurface()
            task.wait(0.5)

            setStatus("Equipping Oxygen Tank...")
            treasureEquipO2()
            task.wait(0.5)
            startAntiDrown()

            while autoTreasureRunning do
                chests = getTreasureChests()
                if #chests == 0 then break end

                char = LocalPlayer.Character
                hrp  = char and char:FindFirstChild("HumanoidRootPart")
                if not hrp then
                    task.wait(1)
                    continue
                end

                pcall(function()
                    local hum = char:FindFirstChild("Humanoid")
                    if hum then hum.Health = hum.MaxHealth end
                end)

                local targetChest = chests[1]
                local chestCF     = targetChest:GetPivot() * CFrame.new(0, 3, 3)

                setStatus("Moving to Treasure (" .. #chests .. " remaining)...")
                streamTreasureArea(targetChest:GetPivot().Position)

                teleportToChestViaTween(hrp, chestCF)
                task.wait(0.3)

                local prompt = nil
                for attempt = 1, 5 do
                    prompt = findPrompt(targetChest)
                    if prompt then break end
                    task.wait(0.3)
                end

                if prompt then
                    pcall(function()
                        hrp.CFrame = chestCF
                        hrp.AssemblyLinearVelocity  = Vector3.zero
                        hrp.AssemblyAngularVelocity = Vector3.zero
                    end)
                    pcall(fireproximityprompt, prompt)
                    local waitStart = tick()
                    while not targetChest:GetAttribute("Opened") and (tick() - waitStart) < 5 do
                        pcall(function()
                            if hrp and hrp.Parent then
                                hrp.CFrame = chestCF
                                hrp.AssemblyLinearVelocity  = Vector3.zero
                                hrp.AssemblyAngularVelocity = Vector3.zero
                            end
                        end)
                        task.wait(0.2)
                    end
                    task.wait(0.3)
                else
                    pcall(function() hrp.Anchored = false end)
                    task.wait(1)
                end

                pcall(function()
                    if hrp and hrp.Parent then
                        hrp.Anchored = false
                        hrp.AssemblyLinearVelocity  = Vector3.zero
                        hrp.AssemblyAngularVelocity = Vector3.zero
                    end
                end)
            end

            returnToSavedPos()
            setStatus("Waiting for Treasure Hunt...")
        end

        TreasureSection:AddButton({
            Title    = "Go To Treasure Hunt",
            Callback = function()
                task.spawn(function()
                    local sw = workspace:FindFirstChild("Sunken Wreckage")
                    if not sw then
                        Library:MakeNotify({
                            Title       = "Treasure Hunt",
                            Description = "Sunken Wreckage not found!",
                            Color       = Color3.fromRGB(255, 80, 80),
                            Delay       = 3,
                        })
                        return
                    end
                    local char = LocalPlayer.Character
                    local hrp = char and char:FindFirstChild("HumanoidRootPart")
                    if not hrp then return end
                    local surfaceCF = getSunkenWreckageSurfacePos()
                    if not surfaceCF then return end
                    pcall(function()
                        hrp.Anchored = true
                        hrp.CFrame = surfaceCF
                        hrp.AssemblyLinearVelocity  = Vector3.zero
                        hrp.AssemblyAngularVelocity = Vector3.zero
                    end)
                    task.wait(0.15)
                    pcall(function()
                        hrp.CFrame = surfaceCF
                        hrp.AssemblyLinearVelocity  = Vector3.zero
                        hrp.AssemblyAngularVelocity = Vector3.zero
                        hrp.Anchored = false
                    end)
                    Library:MakeNotify({
                        Title       = "Treasure Hunt",
                        Description = "Teleported to surface!",
                        Color       = Color3.fromRGB(255, 140, 0),
                        Delay       = 2,
                    })
                end)
            end,
        })

        TreasureSection:AddToggle({
            Title    = "Auto Treasure Hunt",
            Default  = false,
            Callback = function(on)
                autoTreasureRunning = on

                if not on then
                    if _treasureState.isAtEvent and _treasureState.savedPos then
                        returnToSavedPos()
                    end
                    treasureCleanup()
                    setStatus("Inactive")
                    return
                end

                setStatus("Waiting for Treasure Hunt...")
                treasureCleanup()

                _treasureState.childAddedConn = workspace.ChildAdded:Connect(function(child)
                    if not autoTreasureRunning then return end
                    if child.Name == "Sunken Wreckage" then
                        task.wait(2)
                        if autoTreasureRunning then
                            task.spawn(processTreasureEvent)
                        end
                    end
                end)

                _treasureState.charAddedConn = LocalPlayer.CharacterAdded:Connect(function(newChar)
                    task.wait(3)
                    if _treasureState.savedPos and _treasureState.isAtEvent then
                        local hrp = newChar and newChar:FindFirstChild("HumanoidRootPart")
                        if hrp then
                            pcall(function()
                                hrp.CFrame = _treasureState.savedPos
                                hrp.AssemblyLinearVelocity  = Vector3.zero
                                hrp.AssemblyAngularVelocity = Vector3.zero
                            end)
                        end
                    end
                    if _treasureState.o2Equipped then treasureUnequipO2() end
                    stopAntiDrown()
                    _treasureState.isAtEvent = false
                    _treasureState.savedPos  = nil
                end)

                _treasureState.loopThread = task.spawn(function()
                    local existing = workspace:FindFirstChild("Sunken Wreckage")
                    if existing then
                        task.spawn(processTreasureEvent)
                    end
                    while autoTreasureRunning do
                        task.wait(3)
                        if not autoTreasureRunning then break end
                        local chests = getTreasureChests()
                        if #chests > 0 and not _treasureState.isAtEvent then
                            task.spawn(processTreasureEvent)
                        end
                    end
                end)
            end,
        })
    end
    do
        local AutoMineSection = AutoTab:AddSection("Auto Mine Crystal [BETA]")
        local _mine = {
            enabled    = false,
            loopThread = nil,
            savedPos   = nil,
        }
        AutoMineSection:AddParagraph({
            Title   = "Note",
            Content = "Untuk menggunakan fitur ini harus berada di Crystal Depths!",
        })
        AutoMineSection:AddToggle({
            Title    = "Enable Auto Mine Crystal",
            Default  = false,
            NoSave   = true,
            Callback = function(on)
                if on then
                    _mine.enabled = true
                    _mine.loopThread = task.spawn(function()
                        local function getReplionData()
                            local data = getCachedReplionData()
                            if data then return data end
                            local rep = getCachedReplion()
                            if not rep then return nil end
                            local ok, d = pcall(function() return rep.Client:WaitReplion("Data") end)
                            return ok and d or nil
                        end

                        local function isPickaxeEquipped()
                            local myChar = LocalPlayer.Character
                            if not myChar then return false end
                            for _, v in ipairs(myChar:GetChildren()) do
                                if v:IsA("Tool") and (v.Name:lower():find("pick") or v.Name == "Pickaxe") then
                                    return true
                                end
                            end
                            return false
                        end

                        local function equipPickaxe(replionData)
                            if not replionData then return false end
                            local pickaxeUUID = nil
                            pcall(function()
                                local gears = replionData:Get({"Inventory", "Gears"}) or {}
                                for _, item in pairs(gears) do
                                    if item.Id == 20220 then pickaxeUUID = item.UUID; break end
                                end
                            end)
                            if not pickaxeUUID then
                                pcall(function()
                                    local items = replionData:Get({"Inventory", "Items"}) or {}
                                    for _, item in pairs(items) do
                                        if item.Id == 20220 then pickaxeUUID = item.UUID; break end
                                    end
                                end)
                            end
                            if not pickaxeUUID then return false end
                            local slotKey = nil
                            local timeout = tick()
                            while tick() - timeout < 5 do
                                local equippedItems = replionData:Get("EquippedItems") or {}
                                for key, uuid in pairs(equippedItems) do
                                    if uuid == pickaxeUUID then slotKey = key; break end
                                end
                                if slotKey then break end
                                pcall(function() NetEvents.RE_EquipItem:FireServer(pickaxeUUID, "Gears") end)
                                task.wait(0.5)
                            end
                            if not slotKey then return false end
                            pcall(function() NetEvents.RF_EquipToolFromHotbar:FireServer(slotKey) end)
                            task.wait(0.5)
                            return true
                        end
                        local function ensurePickaxe(replionData)
                            if isPickaxeEquipped() then return true end
                            return equipPickaxe(replionData)
                        end
                        local function teleportTo(position)
                            local myChar = LocalPlayer.Character
                            local myRoot = myChar and myChar:FindFirstChild("HumanoidRootPart")
                            if not myRoot then return false end
                            local target = CFrame.new(position + Vector3.new(0, 4, 0))
                            for _ = 1, 5 do
                                pcall(function()
                                    myRoot.Anchored = true
                                    myRoot.CFrame = target
                                end)
                                task.wait(0.1)
                                pcall(function()
                                    myRoot.Anchored = false
                                    myRoot.AssemblyLinearVelocity = Vector3.zero
                                    myRoot.AssemblyAngularVelocity = Vector3.zero
                                end)
                                task.wait(0.2)
                                local root2 = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
                                if root2 and (root2.Position - position).Magnitude < 20 then
                                    return true
                                end
                            end
                            return false
                        end
                        local function returnToSaved()
                            if not _mine.savedPos then return end
                            local myChar = LocalPlayer.Character
                            local myRoot = myChar and myChar:FindFirstChild("HumanoidRootPart")
                            if not myRoot then return end
                            pcall(function()
                                myRoot.Anchored = true
                                myRoot.CFrame = _mine.savedPos
                            end)
                            task.wait(0.1)
                            pcall(function()
                                myRoot.Anchored = false
                                myRoot.AssemblyLinearVelocity = Vector3.zero
                                myRoot.AssemblyAngularVelocity = Vector3.zero
                            end)
                        end
                        local function waitForMiningConfirmation(timeoutSecs)
                            local done = false
                            local conn = NetEvents.RE_PickaxeMining.OnClientEvent:Connect(function()
                                done = true
                            end)
                            local elapsed = 0
                            while not done and elapsed < timeoutSecs do
                                task.wait(0.2)
                                elapsed += 0.2
                            end
                            conn:Disconnect()
                            return done
                        end
                        local function getAvailableCrystals()
                            local curChar = LocalPlayer.Character
                            local curRoot = curChar and curChar:FindFirstChild("HumanoidRootPart")
                            local curPos  = curRoot and curRoot.Position or Vector3.new(0, 0, 0)
                            local available = {}
                            for _, crystal in ipairs(CollectionService:GetTagged("GlowingCrystal")) do
                                local prompt = crystal:FindFirstChildOfClass("ProximityPrompt")
                                if prompt and prompt.Enabled then
                                    table.insert(available, { part = crystal, prompt = prompt })
                                end
                            end
                            table.sort(available, function(a, b)
                                return (a.part.Position - curPos).Magnitude < (b.part.Position - curPos).Magnitude
                            end)
                            return available
                        end
                        local replionData = getReplionData()
                        if not replionData then
                            Library:MakeNotify({ Title = "Auto Mine", Description = "Gagal load data player!", Delay = 3 })
                            _mine.enabled = false
                            return
                        end
                        local myChar = LocalPlayer.Character
                        local myRoot = myChar and myChar:FindFirstChild("HumanoidRootPart")
                        if myRoot then _mine.savedPos = myRoot.CFrame end
                        while _mine.enabled do
                            task.wait(0.5)
                            local available = getAvailableCrystals()
                            if #available == 0 then
                                returnToSaved()
                                Library:MakeNotify({
                                    Title       = "Auto Mine",
                                    Description = "Tidak ada crystal, menunggu respawn...",
                                    Delay       = 3,
                                })
                                while _mine.enabled do
                                    task.wait(5)
                                    local recheck = getAvailableCrystals()
                                    if #recheck > 0 then
                                        Library:MakeNotify({
                                            Title       = "Auto Mine",
                                            Description = "Crystal respawn! Mulai mining lagi...",
                                            Delay       = 3,
                                        })
                                        break
                                    end
                                end
                                continue
                            end
                            _G.AutoMineActive = true
                            _totemSpawning = true
                            if not ensurePickaxe(replionData) then
                                Library:MakeNotify({ Title = "Auto Mine", Description = "Pickaxe tidak ditemukan!", Delay = 3 })
                                _G.AutoMineActive = false
                                _totemSpawning = false
                                _mine.enabled = false
                                break
                            end
                            task.wait(0.5)
                            for i, data in ipairs(available) do
                                if not _mine.enabled then break end
                                local prompt = data.prompt
                                local part   = data.part
                                if not prompt or not prompt.Parent or not prompt.Enabled then continue end
                                teleportTo(part.Position)
                                task.wait(0.5)
                                if not _mine.enabled then break end
                                if not prompt or not prompt.Parent or not prompt.Enabled then continue end
                                if not ensurePickaxe(replionData) then
                                    Library:MakeNotify({ Title = "Auto Mine", Description = "Pickaxe tidak ditemukan!", Delay = 3 })
                                    _mine.enabled = false
                                    break
                                end
                                task.wait(0.3)
                                pcall(function() fireproximityprompt(prompt) end)
                                local holdDuration = prompt.HoldDuration + 0.5
                                local elapsed = 0
                                while elapsed < holdDuration and _mine.enabled do
                                    task.wait(0.3)
                                    elapsed += 0.3
                                    if not isPickaxeEquipped() then
                                        ensurePickaxe(replionData)
                                        task.wait(0.2)
                                        pcall(function() fireproximityprompt(prompt) end)
                                    end
                                end
                                waitForMiningConfirmation(5)
                                local waitTimeout = tick()
                                while prompt and prompt.Parent and prompt.Enabled and tick() - waitTimeout < 5 do
                                    task.wait(0.3)
                                end

                                Library:MakeNotify({
                                    Title       = "Auto Mine",
                                    Description = "Crystal " .. i .. "/" .. #available .. " selesai!",
                                    Delay       = 2,
                                })

                                if i < #available and _mine.enabled then
                                    task.wait(3)
                                end
                            end
                            _G.AutoMineActive = false
                            _totemSpawning = false

                            if _mine.enabled then
                                Library:MakeNotify({
                                    Title       = "Auto Mine",
                                    Description = "Semua crystal selesai! Menunggu respawn...",
                                    Delay       = 3,
                                })
                                returnToSaved()
                            end
                        end

                        _G.AutoMineActive = false
                        _totemSpawning = false
                    end)
                    Library:MakeNotify({ Title = "Auto Mine", Description = "Auto Mine Crystal aktif!", Delay = 2 })
                else
                    _mine.enabled = false
                    _G.AutoMineActive = false
                    _totemSpawning = false
                    if _mine.loopThread then pcall(task.cancel, _mine.loopThread); _mine.loopThread = nil end
                    Library:MakeNotify({ Title = "Auto Mine", Description = "Auto Mine Crystal dihentikan.", Delay = 2 })
                end
            end,
        })
    end
    do
        local VeilshardSection = AutoTab:AddSection("Auto Mining Veilshard [BETA]")
        local _veil = {
            enabled    = false,
            loopThread = nil,
            savedPos   = nil,
        }
        VeilshardSection:AddParagraph({
            Title   = "Note",
            Content = "Otomatis mining Veilshard di Lava Basin.\nCrystal yang bercahaya (ada PointLight) akan di-mine secara otomatis.\nSetelah semua selesai akan menunggu respawn.",
        })
        VeilshardSection:AddToggle({
            Title    = "Enable Auto Mine Veilshard",
            Default  = false,
            NoSave   = true,
            Callback = function(on)
                if on then
                    _veil.enabled = true
                    _veil.loopThread = task.spawn(function()
                        local function getReplionData()
                            local data = getCachedReplionData()
                            if data then return data end
                            local rep = getCachedReplion()
                            if not rep then return nil end
                            local ok, d = pcall(function() return rep.Client:WaitReplion("Data") end)
                            return ok and d or nil
                        end

                        local function isPickaxeEquipped()
                            local myChar = LocalPlayer.Character
                            if not myChar then return false end
                            for _, v in ipairs(myChar:GetChildren()) do
                                if v:IsA("Tool") and (v.Name:lower():find("pick") or v.Name == "Pickaxe") then
                                    return true
                                end
                            end
                            return false
                        end

                        local function equipPickaxe(replionData)
                            if not replionData then return false end
                            local pickaxeUUID = nil
                            pcall(function()
                                local gears = replionData:Get({"Inventory", "Gears"}) or {}
                                for _, item in pairs(gears) do
                                    if item.Id == 20220 then pickaxeUUID = item.UUID; break end
                                end
                            end)
                            if not pickaxeUUID then
                                pcall(function()
                                    local items = replionData:Get({"Inventory", "Items"}) or {}
                                    for _, item in pairs(items) do
                                        if item.Id == 20220 then pickaxeUUID = item.UUID; break end
                                    end
                                end)
                            end
                            if not pickaxeUUID then return false end
                            local slotKey = nil
                            local timeout = tick()
                            while tick() - timeout < 5 do
                                local equippedItems = replionData:Get("EquippedItems") or {}
                                for key, uuid in pairs(equippedItems) do
                                    if uuid == pickaxeUUID then slotKey = key; break end
                                end
                                if slotKey then break end
                                pcall(function() NetEvents.RE_EquipItem:FireServer(pickaxeUUID, "Gears") end)
                                task.wait(0.5)
                            end
                            if not slotKey then return false end
                            pcall(function() NetEvents.RF_EquipToolFromHotbar:FireServer(slotKey) end)
                            task.wait(0.5)
                            return true
                        end
                        local function ensurePickaxe(replionData)
                            if isPickaxeEquipped() then return true end
                            return equipPickaxe(replionData)
                        end
                        local function teleportTo(position)
                            local myChar = LocalPlayer.Character
                            local myRoot = myChar and myChar:FindFirstChild("HumanoidRootPart")
                            if not myRoot then return false end
                            local target = CFrame.new(position + Vector3.new(0, 4, 0))
                            for _ = 1, 5 do
                                pcall(function()
                                    myRoot.Anchored = true
                                    myRoot.CFrame = target
                                end)
                                task.wait(0.1)
                                pcall(function()
                                    myRoot.Anchored = false
                                    myRoot.AssemblyLinearVelocity = Vector3.zero
                                    myRoot.AssemblyAngularVelocity = Vector3.zero
                                end)
                                task.wait(0.2)
                                local root2 = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
                                if root2 and (root2.Position - position).Magnitude < 20 then
                                    return true
                                end
                            end
                            return false
                        end
                        local function returnToSaved()
                            if not _veil.savedPos then return end
                            local myChar = LocalPlayer.Character
                            local myRoot = myChar and myChar:FindFirstChild("HumanoidRootPart")
                            if not myRoot then return end
                            pcall(function()
                                myRoot.Anchored = true
                                myRoot.CFrame = _veil.savedPos
                            end)
                            task.wait(0.1)
                            pcall(function()
                                myRoot.Anchored = false
                                myRoot.AssemblyLinearVelocity = Vector3.zero
                                myRoot.AssemblyAngularVelocity = Vector3.zero
                            end)
                        end
                        local function waitForMiningConfirmation(timeoutSecs)
                            local done = false
                            local conn = NetEvents.RE_PickaxeMining.OnClientEvent:Connect(function()
                                done = true
                            end)
                            local elapsed = 0
                            while not done and elapsed < timeoutSecs do
                                task.wait(0.2)
                                elapsed += 0.2
                            end
                            conn:Disconnect()
                            return done
                        end
                        local function isBasinCrystalGlowing(crystalFolder)
                            local basinCrystal = crystalFolder:FindFirstChild("BasinCrystal")
                            if not basinCrystal then
                                for _, child in ipairs(crystalFolder:GetChildren()) do
                                    if child:IsA("BasePart") and child.Name:find("Crystal") then
                                        basinCrystal = child
                                        break
                                    end
                                end
                            end
                            if not basinCrystal then return false end
                            for _, desc in ipairs(basinCrystal:GetDescendants()) do
                                if desc:IsA("PointLight") and desc.Enabled then
                                    return true
                                end
                            end
                            for _, desc in ipairs(crystalFolder:GetDescendants()) do
                                if desc:IsA("PointLight") and desc.Enabled then
                                    return true
                                end
                            end
                            return false
                        end
                        local function getAvailableVeilshards()
                            local curChar = LocalPlayer.Character
                            local curRoot = curChar and curChar:FindFirstChild("HumanoidRootPart")
                            local curPos  = curRoot and curRoot.Position or Vector3.new(0, 0, 0)
                            local available = {}
                            local islands = workspace:FindFirstChild("Islands")
                            if not islands then return available end
                            local lavaBasin = islands:FindFirstChild("Lava Basin")
                            if not lavaBasin then return available end
                            pcall(function()
                                LocalPlayer:RequestStreamAroundAsync(lavaBasin:GetPivot().Position, 500)
                            end)
                            local crystalsFolder = lavaBasin:FindFirstChild("Crystals")
                            if not crystalsFolder then return available end
                            for _, crystalFolder in ipairs(crystalsFolder:GetChildren()) do
                                if crystalFolder.Name == "Crystal" then
                                    local glowing = isBasinCrystalGlowing(crystalFolder)
                                    if glowing then
                                        local prompt = crystalFolder:FindFirstChildWhichIsA("ProximityPrompt", true)
                                        if prompt then
                                            table.insert(available, {
                                                part   = crystalFolder:FindFirstChild("BasinCrystal") or crystalFolder,
                                                prompt = prompt,
                                                folder = crystalFolder,
                                            })
                                        end
                                    end
                                end
                            end
                            table.sort(available, function(a, b)
                                return (a.part.Position - curPos).Magnitude < (b.part.Position - curPos).Magnitude
                            end)
                            return available
                        end
                        local replionData = getReplionData()
                        if not replionData then
                            Library:MakeNotify({ Title = "Auto Veilshard", Description = "Gagal load data player!", Delay = 3 })
                            _veil.enabled = false
                            return
                        end
                        local myChar = LocalPlayer.Character
                        local myRoot = myChar and myChar:FindFirstChild("HumanoidRootPart")
                        if myRoot then _veil.savedPos = myRoot.CFrame end
                        while _veil.enabled do
                            task.wait(0.5)
                            local available = getAvailableVeilshards()
                            if #available == 0 then
                                returnToSaved()
                                Library:MakeNotify({
                                    Title       = "Auto Veilshard",
                                    Description = "Tidak ada Veilshard bercahaya, menunggu respawn...",
                                    Delay       = 3,
                                })
                                while _veil.enabled do
                                    task.wait(3)
                                    pcall(function()
                                        local islands = workspace:FindFirstChild("Islands")
                                        local lb = islands and islands:FindFirstChild("Lava Basin")
                                        if lb then
                                            LocalPlayer:RequestStreamAroundAsync(lb:GetPivot().Position, 500)
                                        end
                                    end)
                                    local recheck = getAvailableVeilshards()
                                    if #recheck > 0 then
                                        Library:MakeNotify({
                                            Title       = "Auto Veilshard",
                                            Description = "Veilshard respawn! Mulai mining lagi...",
                                            Delay       = 3,
                                        })
                                        break
                                    end
                                end
                                continue
                            end
                            local myChar2 = LocalPlayer.Character
                            local myRoot2 = myChar2 and myChar2:FindFirstChild("HumanoidRootPart")
                            if myRoot2 then _veil.savedPos = myRoot2.CFrame end
                            _G.AutoMineActive = true
                            _totemSpawning = true
                            if not ensurePickaxe(replionData) then
                                Library:MakeNotify({ Title = "Auto Veilshard", Description = "Pickaxe tidak ditemukan!", Delay = 3 })
                                _G.AutoMineActive = false
                                _totemSpawning = false
                                _veil.enabled = false
                                break
                            end
                            task.wait(0.5)
                            for i, data in ipairs(available) do
                                if not _veil.enabled then break end
                                local prompt = data.prompt
                                local part   = data.part
                                if not prompt or not prompt.Parent or not prompt.Enabled then continue end
                                teleportTo(part.Position)
                                task.wait(0.5)
                                if not _veil.enabled then break end
                                if not prompt or not prompt.Parent or not prompt.Enabled then continue end
                                if not ensurePickaxe(replionData) then
                                    Library:MakeNotify({ Title = "Auto Veilshard", Description = "Pickaxe tidak ditemukan!", Delay = 3 })
                                    _veil.enabled = false
                                    break
                                end
                                task.wait(0.3)
                                pcall(function() fireproximityprompt(prompt, 0) end)
                                local holdDuration = prompt.HoldDuration + 0.5
                                local elapsed = 0
                                while elapsed < holdDuration and _veil.enabled do
                                    task.wait(0.3)
                                    elapsed += 0.3
                                    if not isPickaxeEquipped() then
                                        ensurePickaxe(replionData)
                                        task.wait(0.2)
                                        pcall(function() fireproximityprompt(prompt, 0) end)
                                    end
                                end
                                waitForMiningConfirmation(5)
                                local waitTimeout = tick()
                                while prompt and prompt.Parent and prompt.Enabled and tick() - waitTimeout < 5 do
                                    task.wait(0.3)
                                end

                                Library:MakeNotify({
                                    Title       = "Auto Veilshard",
                                    Description = "Veilshard " .. i .. "/" .. #available .. " selesai!",
                                    Delay       = 2,
                                })

                                if i < #available and _veil.enabled then
                                    task.wait(3)
                                end
                            end
                            _G.AutoMineActive = false
                            _totemSpawning = false

                            if _veil.enabled then
                                Library:MakeNotify({
                                    Title       = "Auto Veilshard",
                                    Description = "Semua Veilshard selesai! Menunggu respawn...",
                                    Delay       = 3,
                                })
                                returnToSaved()
                                task.wait(0.5)
                                autoEquipRod()
                            end
                        end

                        _G.AutoMineActive = false
                        _totemSpawning = false
                    end)
                    Library:MakeNotify({ Title = "Auto Veilshard", Description = "Auto Mine Veilshard aktif!", Delay = 2 })
                else
                    _veil.enabled = false
                    _G.AutoMineActive = false
                    _totemSpawning = false
                    if _veil.loopThread then pcall(task.cancel, _veil.loopThread); _veil.loopThread = nil end
                    Library:MakeNotify({ Title = "Auto Veilshard", Description = "Auto Mine Veilshard dihentikan.", Delay = 2 })
                end
            end,
        })
    end
    do
        local CharmCraftSection = AutoTab:AddSection("Auto Craft Charm", false)
        local _charmCraft = {
            enabled      = false,
            loop         = nil,
            selectedItem = nil,
            delay        = 2,
            amount       = 1,
            crafted      = 0,
        }
        local CraftingItems = cachedRequire(ReplicatedStorage:FindFirstChild("Shared")
            and ReplicatedStorage.Shared:FindFirstChild("CraftingItems"))
        local _charmList = {}
        local function _buildCharmList()
            _charmList = {}
            pcall(function()
                if not CraftingItems or not CraftingItems.Items then return end
                for name, _ in pairs(CraftingItems.Items) do
                    table.insert(_charmList, name)
                end
                table.sort(_charmList)
            end)
            return _charmList
        end
        _buildCharmList()
        CharmCraftSection:AddParagraph({
            Title   = "Info",
            Content = "Auto Craft Charm otomatis start & confirm crafting.\n" ..
                    "Pilih charm dari dropdown lalu aktifkan toggle.\n" ..
                    "Pastikan bahan crafting tersedia di inventory.\n" ..
                    "Quest Kohana Gatekeeper harus sudah selesai.",
        })
        local charmDropdownRef = CharmCraftSection:AddDropdown({
            Title    = "Pilih Charm",
            Options  = #_charmList > 0 and _charmList or {"Loading..."},
            Default  = nil,
            Callback = function(v)
                _charmCraft.selectedItem = v
            end,
        })
        CharmCraftSection:AddInput({
            Title    = "Jumlah Craft",
            Default  = 1,
            Callback = function(v)
                _charmCraft.amount = v
            end,
        })
        CharmCraftSection:AddToggle({
            Title    = "Enable Auto Craft",
            Default  = false,
            NoSave   = true,
            Callback = function(on)
                if on then
                    if _charmCraft.enabled then return end
                    if not _charmCraft.selectedItem then
                        Library:MakeNotify({
                            Title       = "Auto Craft Charm",
                            Description = "Pilih charm dari dropdown dulu!",
                            Color       = Color3.fromRGB(255, 80, 80),
                            Delay       = 3,
                        })
                        return
                    end
                    _charmCraft.enabled = true
                    _charmCraft.crafted = 0
                    Library:MakeNotify({
                        Title       = "Auto Craft Charm",
                        Description = "Mulai craft " .. _charmCraft.amount .. "x " .. _charmCraft.selectedItem,
                        Color       = Color3.fromRGB(34, 197, 94),
                        Delay       = 2,
                    })
                    _charmCraft.loop = task.spawn(function()
                        while _charmCraft.enabled and _charmCraft.crafted < _charmCraft.amount do
                            local itemName = _charmCraft.selectedItem
                            if not itemName then task.wait(1); continue end
                            local itemData = CraftingItems.Items[itemName]
                            if not itemData then
                                Library:MakeNotify({
                                    Title       = "Auto Craft Charm",
                                    Description = "Item tidak ditemukan: " .. tostring(itemName),
                                    Color       = Color3.fromRGB(255, 80, 80),
                                    Delay       = 3,
                                })
                                _charmCraft.enabled = false
                                break
                            end
                            local startOk, startResult = pcall(function()
                                return NetEvents.RF_StartCrafting:InvokeServer(itemName)
                            end)
                            if not startOk or not startResult then
                                Library:MakeNotify({
                                    Title       = "Auto Craft Charm",
                                    Description = "Gagal start! Bahan kurang atau quest belum selesai.",
                                    Color       = Color3.fromRGB(255, 80, 80),
                                    Delay       = 3,
                                })
                                _charmCraft.enabled = false
                                break
                            end
                            task.wait(0.5)
                            if not _charmCraft.enabled then break end
                            local confirmOk, confirmResult = pcall(function()
                                return NetEvents.RF_ConfirmCrafting:InvokeServer()
                            end)
                            if confirmOk and confirmResult then
                                _charmCraft.crafted = _charmCraft.crafted + 1
                                Library:MakeNotify({
                                    Title       = "Auto Craft Charm",
                                    Description = "[" .. _charmCraft.crafted .. "/" .. _charmCraft.amount .. "] Berhasil craft: " .. itemName,
                                    Color       = Color3.fromRGB(255, 140, 0),
                                    Delay       = 2,
                                })
                            else
                                pcall(function()
                                    NetEvents.RF_CancelCrafting:InvokeServer()
                                end)
                                Library:MakeNotify({
                                    Title       = "Auto Craft Charm",
                                    Description = "Gagal confirm craft, mencoba lagi...",
                                    Color       = Color3.fromRGB(255, 80, 80),
                                    Delay       = 2,
                                })
                            end
                            task.wait(_charmCraft.delay)
                        end
                        if _charmCraft.enabled and _charmCraft.crafted >= _charmCraft.amount then
                            Library:MakeNotify({
                                Title       = "Auto Craft Charm",
                                Description = "Selesai! Total craft: " .. _charmCraft.crafted .. "x " .. (_charmCraft.selectedItem or ""),
                                Color       = Color3.fromRGB(34, 197, 94),
                                Delay       = 4,
                            })
                            _charmCraft.enabled = false
                        end
                    end)
                else
                    _charmCraft.enabled = false
                    if _charmCraft.loop then
                        task.cancel(_charmCraft.loop)
                        _charmCraft.loop = nil
                    end
                    pcall(function()
                        NetEvents.RF_CancelCrafting:InvokeServer()
                    end)
                    Library:MakeNotify({
                        Title       = "Auto Craft Charm",
                        Description = "Dihentikan. Tercrafted: " .. _charmCraft.crafted .. "/" .. _charmCraft.amount,
                        Color       = Color3.fromRGB(255, 100, 100),
                        Delay       = 3,
                    })
                end
            end,
        })
        CharmCraftSection:AddInput({
            Title    = "Delay Antar Craft (detik)",
            Default  = 2,
            Callback = function(v)
                _charmCraft.delay = v
            end,
        })
        CharmCraftSection:AddButton({
            Title    = "Refresh Charm List",
            Callback = function()
                _buildCharmList()
                if charmDropdownRef and charmDropdownRef.SetOptions then
                    charmDropdownRef:SetOptions(#_charmList > 0 and _charmList or {"No Items Found"})
                end
                Library:MakeNotify({
                    Title       = "Auto Craft Charm",
                    Description = "List diperbarui: " .. #_charmList .. " charm.",
                    Color       = Color3.fromRGB(255, 140, 0),
                    Delay       = 2,
                })
            end,
        })
    end

    do
        local AtlantisSection = AutoTab:AddSection("Auto Atlantis Machine")
        _atlantis = {
            enabled     = false,
            thread      = nil,
            delay       = 0.5,
            savedPos    = nil,
            selling     = false,
            replion     = nil,
            dataReplion = nil,
            config      = nil,
            machinePos  = nil,
        }
        local function _atlantisInit()
            if _atlantis.replion and _atlantis.dataReplion and _atlantis.config then return true end
            local ok = pcall(function()
                local ReplionClient = getCachedReplion().Client
                _atlantis.config      = cachedRequire(ReplicatedStorage.Shared.AtlantisMachineConfig)
                _atlantis.replion     = ReplionClient:WaitReplion(_atlantis.config.Channel)
                _atlantis.dataReplion = ReplionClient:WaitReplion("Data")
            end)
            return ok and _atlantis.replion and _atlantis.dataReplion and _atlantis.config
        end
        local function _getMachinePos()
            if _atlantis.machinePos then return _atlantis.machinePos end
            local ok, pos = pcall(function()
                local city    = workspace.Islands:FindFirstChild("Underwater City")
                local machine = city and city:FindFirstChild("Atlantis Machine")
                local part    = machine and machine:FindFirstChildWhichIsA("BasePart")
                return part and part.Position
            end)
            if ok and pos then
                _atlantis.machinePos = CFrame.new(pos + Vector3.new(0, 3, 0))
            end
            return _atlantis.machinePos
        end
        local function _getCurrentPoints()
            local ok, v = pcall(function() return _atlantis.replion:Get("CurrentPoints") or 0 end)
            return ok and v or 0
        end
        local function _getMaxPoints()
            return _atlantis.config.MaxPoints or 1000
        end
        local function _isBoostActive()
            local ok, boostId = pcall(function() return _atlantis.replion:Get("ActiveBoostId") end)
            if not ok or not boostId or boostId == "" then return false end
            local ok2, endsAt = pcall(function() return _atlantis.replion:Get("ActiveBoostEndsAt") or 0 end)
            return ok2 and endsAt and (endsAt > workspace:GetServerTimeNow())
        end
        local function _buildEntries()
            local ok, items = pcall(function()
                return _atlantis.dataReplion:Get({ "Inventory", "Items" }) or {}
            end)
            if not ok then return {} end
            local ok2, entries = pcall(function()
                return _atlantis.config:BuildEligibleEntries(items)
            end)
            return ok2 and entries or {}
        end
        local function _calcInventoryPoints()
            local entries = _buildEntries()
            local total   = 0
            for _, entry in ipairs(entries) do
                total = total + (entry.Points or 0)
            end
            return total, entries
        end
        local function _teleportBack()
            if not _atlantis.savedPos then return end
            for i = 1, 5 do
                local char = LocalPlayer.Character
                local hrp = char and char:FindFirstChild("HumanoidRootPart")
                if hrp then
                    hrp.CFrame = _atlantis.savedPos
                end
                task.wait(0.15)
            end
        end
        local function _doSacrifice()
            local char = LocalPlayer.Character
            local hrp = char and char:FindFirstChild("HumanoidRootPart")
            if not hrp then return end
            if _classicMachineBusy then return end
            _atlantis.savedPos = hrp.CFrame
            local pos = _getMachinePos()
            if not pos then return end
            for i = 1, 3 do hrp.CFrame = pos; task.wait(0.15) end
            task.wait(0.3)
            _atlantis.selling = true
            for attempt = 1, 3 do
                local _okAll, _resultAll = pcall(function()
                    return NetEvents.RF_SacrificeAtlantisSellAll:InvokeServer()
                end)
                if _okAll and _resultAll and _resultAll.Success then
                    Library:MakeNotify({ Title = "Atlantis", Description = "Sacrifice All berhasil!", Delay = 2 })
                    break
                end
                task.wait(1)
            end
            task.wait(0.3)
            _atlantis.selling = false
            _teleportBack()
        end
        AtlantisSection:AddParagraph({
            Title   = "Info",
            Content = "Otomatis sacrifice ikan ke Atlantis Machine di Underwater City.\n" ..
                    "• Kumpulkan poin dulu dari hasil mancing\n" ..
                    "• Kalau inventory sudah cukup untuk isi mesin → baru teleport\n" ..
                    "• Sacrifice sekaligus → langsung balik ke posisi mancing\n" ..
                    "• Boost sedang aktif → idle, tunggu selesai\n" ..
                    "• Mesin penuh → idle, cek ulang tiap 10 detik\n" ..
                    "• Toggle OFF → langsung balik ke posisi terakhir",
        })
        AtlantisSection:AddToggle({
            Title    = "Auto Atlantis Machine",
            Default  = false,
            NoSave   = true,
            Callback = function(on)
                _atlantis.enabled = on
                if _atlantis.thread then
                    task.cancel(_atlantis.thread)
                    _atlantis.thread = nil
                end
                if not on then
                    _atlantis.selling = false
                    _teleportBack()
                    _atlantis.savedPos = nil
                    return
                end
                _atlantis.thread = task.spawn(function()
                    if not _atlantisInit() then return end
                    while _atlantis.enabled do
                        if _classicMachineBusy then task.wait(1) continue end
                        if _isBoostActive() then task.wait(10) continue end
                        local currentPts = _getCurrentPoints()
                        local needed     = _getMaxPoints() - currentPts
                        if needed <= 0 then task.wait(10) continue end
                        local inventoryPts = _calcInventoryPoints()
                        if inventoryPts < needed then task.wait(5) continue end
                        _doSacrifice()
                        task.wait(3)
                    end
                end)
            end,
        })
        AtlantisSection:AddButton({
            Title    = "Sacrifice Now",
            Callback = function()
                task.spawn(function()
                    if not _atlantisInit() then return end
                    _doSacrifice()
                end)
            end,
        })
    end
    do
        local autoAdsRunning = false
        local autoAdsThread  = nil
        local WatchAdsSection = AutoTab:AddSection("Auto Watch Ads", false)
        WatchAdsSection:AddParagraph({
            Title   = "Info",
            Content = "Otomatis menonton iklan untuk mendapatkan Token Shards.",
        })
        WatchAdsSection:AddToggle({
            Title    = "Auto Watch Ads",
            Content  = "Automatically watches rewarded video ads to earn Token Shards.",
            Default  = false,
            Callback = function(on)
                autoAdsRunning = on
                if autoAdsThread then
                    task.cancel(autoAdsThread)
                    autoAdsThread = nil
                end
                if not on then return end
                autoAdsThread = task.spawn(function()
                    local AdsUtility  = cachedRequire(ReplicatedStorage.Shared.Products.AdsUtility)
                    local rep         = getCachedReplion()
                    local DataReplion = rep and rep.Client:WaitReplion("Data") or nil
                    while autoAdsRunning do
                        local adsWatched = DataReplion:GetExpect("AdsWatched")
                        if adsWatched >= AdsUtility.Ads then
                            autoAdsRunning = false
                            Library:MakeNotify({ Title="Auto Watch Ads", Description="Limit harian tercapai.", Delay=4 })
                            break
                        end
                        local available = AdsUtility:GetAdAvailability():await()
                        if not available then
                            task.wait(30)
                            continue
                        end
                        NetEvents.RE_PlayVideoAd:FireServer(3577497029)
                        local done = false
                        local conn = NetEvents.RE_RelayVideoAd.OnClientEvent:Connect(function()
                            done = true
                        end)
                        local elapsed = 0
                        while not done and elapsed < 60 do
                            task.wait(1)
                            elapsed += 1
                        end
                        conn:Disconnect()
                        task.wait(3)
                    end
                end)
            end,
        })
    end
    do
        local BuyCharmSection = AutoTab:AddSection("Auto Buy Charm", false)
        local _charmState = {
            charmList    = {},
            selectedId   = nil,
            selectedName = nil,
            selectedPrice= nil,
            amount       = 1,
            delay        = 0.5,
            isBuying     = false,
            loaded       = false,
        }
        local _charmPriceParagraph = BuyCharmSection:AddParagraph({
            Title   = "Charm Info",
            Content = "Memuat daftar charm...",
        })
        local _charmDropdown = BuyCharmSection:AddDropdown({
            Title    = "Charm Type",
            Options  = { "Memuat..." },
            Default  = "Memuat...",
            Callback = function(selected)
                if not _charmState.loaded then
                    if _loadCharmList then task.spawn(_loadCharmList) end
                    return
                end
                for _, entry in ipairs(_charmState.charmList) do
                    if entry.Name == selected then
                        _charmState.selectedId    = entry.Id
                        _charmState.selectedName  = entry.Name
                        _charmState.selectedPrice = entry.Price
                        _charmPriceParagraph:SetContent(
                            "Name: " .. entry.Name .. "\nPrice: " .. tostring(entry.Price) .. " coins"
                        )
                        break
                    end
                end
            end,
        })
        local function _loadCharmList()
            _charmPriceParagraph:SetContent("Memuat daftar charm...")
            pcall(function()
                local charmsFolder = ReplicatedStorage:FindFirstChild("Charms")
                if not charmsFolder then
                    local ok2, res = pcall(function() return ReplicatedStorage:WaitForChild("Charms", 5) end)
                    if ok2 and res then charmsFolder = res end
                end
                if not charmsFolder then return end
                local newList      = {}
                for _, mod in ipairs(charmsFolder:GetChildren()) do
                    if mod:IsA("ModuleScript") then
                        local ok, data = pcall(function() return require(mod) end)
                        if ok and type(data) == "table" and data.Data then
                            local price = data.Price or 0
                            if price > 0 then
                                table.insert(newList, {
                                    Name  = tostring(data.Data.Name or mod.Name),
                                    Id    = data.Data.Id,
                                    Price = price,
                                })
                            end
                        end
                    end
                end
                table.sort(newList, function(a, b) return (a.Id or 9999) < (b.Id or 9999) end)
                _charmState.charmList = newList
                _charmState.loaded    = true
                local names = {}
                for _, e in ipairs(newList) do table.insert(names, e.Name) end
                if #names > 0 then
                    if _charmDropdown and _charmDropdown.SetOptions then
                        _charmDropdown:SetOptions(names)
                    end
                    local first = newList[1]
                    _charmState.selectedId    = first.Id
                    _charmState.selectedName  = first.Name
                    _charmState.selectedPrice = first.Price
                    _charmPriceParagraph:SetContent(
                        "Name: " .. first.Name .. "\nPrice: " .. tostring(first.Price) .. " coins"
                    )
                else
                    _charmPriceParagraph:SetContent("Tidak ada charm ditemukan di game.")
                end
            end)
        end
        local function _ensureCharmLoaded()
            if not _charmState.loaded then _loadCharmList() end
        end
        local _buyCharmContainer = BuyCharmSection._container or BuyCharmSection
        BuyCharmSection:AddInput({
            Title    = "Amount",
            Default  = "1",
            Callback = function(value)
                local n = tonumber(value)
                if n and n > 0 and n <= 1000 then
                    _charmState.amount = math.floor(n)
                end
            end,
        })
        BuyCharmSection:AddInput({
            Title    = "Delay (Seconds)",
            Default  = "0.5",
            Callback = function(value)
                local n = tonumber(value)
                if n and n >= 0 and n <= 10 then
                    _charmState.delay = n
                end
            end,
        })
        local function _findTextBoxes()
            local boxes = {}
            pcall(function()
                local container = _buyCharmContainer
                if container and container.GetDescendants then
                    for _, desc in ipairs(container:GetDescendants()) do
                        if desc:IsA("TextBox") then
                            table.insert(boxes, desc)
                        end
                    end
                end
            end)
            return boxes
        end
        local function _readAmountFromUI()
            local boxes = _findTextBoxes()
            local amountBox = boxes[1]
            local delayBox  = boxes[2]
            local amount = _charmState.amount or 1
            local delay  = _charmState.delay or 0.5
            if amountBox then
                local n = tonumber(amountBox.Text)
                if n and n > 0 and n <= 1000 then
                    amount = math.floor(n)
                end
            end
            if delayBox then
                local n = tonumber(delayBox.Text)
                if n and n >= 0 and n <= 10 then
                    delay = n
                end
            end
            return amount, delay
        end
        BuyCharmSection:AddButton({
            Title    = "Buy Charm",
            Callback = function()
                _ensureCharmLoaded()
                if _charmState.isBuying then return end
                if not _charmState.selectedId then
                    _charmPriceParagraph:SetContent("Pilih charm terlebih dahulu!")
                    return
                end
                local remote = NetEvents.RF_PurchaseCharm
                if not remote then
                    Library:MakeNotify({
                        Title       = "Auto Buy Charm",
                        Description = "Remote RF_PurchaseCharm tidak ditemukan!",
                        Color       = Color3.fromRGB(255, 80, 80),
                        Delay       = 3,
                    })
                    return
                end
                local total, delayTime = _readAmountFromUI()
                local id        = _charmState.selectedId
                local charmName = _charmState.selectedName or "Unknown"
                _charmState.amount = total
                _charmState.delay  = delayTime
                _charmState.isBuying = true
                Library:MakeNotify({
                    Title       = "Auto Buy Charm",
                    Description = "Mulai membeli " .. total .. "x " .. charmName .. "...",
                    Color       = Color3.fromRGB(255, 200, 50),
                    Delay       = 3,
                })
                task.spawn(function()
                    local success = 0
                    local failed  = 0
                    for i = 1, total do
                        if not _charmState.isBuying then break end
                        local ok, result = pcall(function()
                            return remote:InvokeServer(id)
                        end)
                        if ok then
                            success = success + 1
                        else
                            failed = failed + 1
                        end
                        if i % 5 == 0 or i == total then
                            _charmPriceParagraph:SetContent(
                                "Buying: " .. charmName ..
                                "\nProgress: " .. i .. "/" .. total ..
                                " (OK: " .. success .. ", Fail: " .. failed .. ")"
                            )
                        end
                        if i < total and _charmState.isBuying then
                            task.wait(delayTime)
                        end
                    end
                    _charmState.isBuying = false
                    Library:MakeNotify({
                        Title       = "Auto Buy Charm",
                        Description = "Selesai! Berhasil: " .. success .. "/" .. total .. " " .. charmName,
                        Color       = success > 0 and Color3.fromRGB(34, 197, 94) or Color3.fromRGB(255, 80, 80),
                        Delay       = 4,
                    })
                    _charmPriceParagraph:SetContent(
                        "Name: " .. charmName ..
                        "\nPrice: " .. tostring(_charmState.selectedPrice or "?") .. " coins" ..
                        "\nLast Buy: " .. success .. "/" .. total .. " berhasil"
                    )
                end)
            end,
        })
        BuyCharmSection:AddButton({
            Title    = "Stop Buying",
            Callback = function()
                _charmState.isBuying = false
            end,
        })
        BuyCharmSection:AddButton({
            Title    = "Refresh Charm List [Buy]",
            Callback = function()
                if _charmState.isBuying then return end
                task.spawn(_loadCharmList)
            end,
        })
    end
    do
        local ClaimSection = AutoTab:AddSection("Auto Claim Pirate Chest", false)
        local _claimState = { enabled = false, task = nil, watcher = nil }
        local function claimChest(chestName)
            pcall(function()
                local r = NetEvents.RE_ClaimPirateChest
                if r then r:FireServer(chestName) end
            end)
        end
        ClaimSection:AddToggle({
            Title    = "Enable Auto Claim",
            Default  = false,
            Callback = function(on)
                if on then
                    if _claimState.enabled then return end
                    _claimState.enabled = true
                    _claimState.task = task.spawn(function()
                        while _claimState.enabled do
                            pcall(function()
                                local chestStorage = Workspace:FindFirstChild("PirateChestStorage")
                                if chestStorage then
                                    for _, chest in pairs(chestStorage:GetChildren()) do
                                        if not _claimState.enabled then break end
                                        if chest:IsA("Model") then
                                            claimChest(chest.Name)
                                            task.wait(1.0)
                                        end
                                    end
                                end
                            end)
                            task.wait(0.3)
                        end
                    end)
                    _claimState.watcher = (function()
                        local pirateStorage = Workspace:FindFirstChild("PirateChestStorage")
                        if not pirateStorage then return nil end
                        return pirateStorage.ChildAdded:Connect(function(d)
                            if not _claimState.enabled then return end
                            task.wait(0.2)
                            if d:IsA("Model") then
                                claimChest(d.Name)
                            end
                        end)
                    end)()
                else
                    _claimState.enabled = false
                    if _claimState.task    then task.cancel(_claimState.task);    _claimState.task    = nil end
                    if _claimState.watcher then _claimState.watcher:Disconnect(); _claimState.watcher = nil end
                end
            end,
        })
    end
    do
        local PotionSection = AutoTab:AddSection("Auto Use Potion", false)
        local _potionState = {
            enabled  = false,
            task     = nil,
            selected = {},
        }
        local POTIONS        = {}
        local POTION_NAMES   = {}
        local POTION_BY_NAME = {}
        pcall(function()
            local PotionsModule = cachedRequire(ReplicatedStorage:FindFirstChild("Potions"))
            for name, data in pairs(PotionsModule) do
                if typeof(data) == "table" and typeof(data.Data) == "table" then
                    local inner      = data.Data
                    local potionId   = inner.Id
                    local potionName = inner.Name
                    if potionId and potionName
                        and not potionName:find("Totem")
                        and not potionName:find("TESTING")
                    then
                        table.insert(POTIONS, { Name = potionName, Id = potionId })
                    end
                end
            end
        end)
        table.sort(POTIONS, function(a, b) return a.Id < b.Id end)
        for _, p in ipairs(POTIONS) do
            table.insert(POTION_NAMES, p.Name)
            POTION_BY_NAME[p.Name] = p
        end
        if #POTION_NAMES == 0 then
            warn("[AutoPotion] Gagal load RS.Potions, pakai fallback list.")
            POTIONS = {
                { Name = "Luck I Potion",     Id = 1  },
                { Name = "Coin I Potion",     Id = 2  },
                { Name = "Mutation I Potion", Id = 4  },
                { Name = "Luck II Potion",    Id = 6  },
                { Name = "Love I Potion",     Id = 15 },
                { Name = "Carrot I Potion",   Id = 16 },
                { Name = "Easter I Potion",   Id = 17 },
                { Name = "Cave Crystal",      Id = 99 },
            }
            for _, p in ipairs(POTIONS) do
                table.insert(POTION_NAMES, p.Name)
                POTION_BY_NAME[p.Name] = p
            end
        end
        PotionSection:AddDropdown({
            Title    = "Select Potions",
            Options  = POTION_NAMES,
            Multi    = true,
            Default  = {},
            Callback = function(selected)
                _potionState.selected = selected or {}
            end,
        })
        PotionSection:AddToggle({
            Title    = "Auto Use Potions",
            Default  = false,
            Callback = function(on)
                if on then
                    if _potionState.enabled then return end
                    if #_potionState.selected == 0 then
                        warn("[AutoPotion] Select potion first before enabling!")
                        return
                    end
                    local Data = nil
                    pcall(function()
                        Data = getCachedReplionData()
                    end)
                    if not Data then
                        warn("[AutoPotion] Failed to connect to Replion Data.")
                        return
                    end
                    _potionState.enabled = true
                    _potionState.task = task.spawn(function()
                        while _potionState.enabled do
                            pcall(function()
                                for _, potionName in ipairs(_potionState.selected) do
                                    local potion = POTION_BY_NAME[potionName]
                                    if potion then
                                        if potionName == "Cave Crystal" then
                                            pcall(function()
                                                NetEvents.RF_ConsumeCaveCrystal:InvokeServer()
                                            end)
                                        else
                                            local inventory = Data:GetExpect({ "Inventory", "Potions" })
                                            if inventory then
                                                for _, item in ipairs(inventory) do
                                                    if item.Id == potion.Id then
                                                        pcall(function()
                                                            NetEvents.RF_ConsumePotion:InvokeServer(item.UUID, 1)
                                                        end)
                                                        break
                                                    end
                                                end
                                            end
                                        end
                                    end
                                end
                            end)
                            task.wait(1)
                        end
                    end)
                else
                    _potionState.enabled = false
                    if _potionState.task then
                        task.cancel(_potionState.task)
                        _potionState.task = nil
                    end
                end
            end,
        })
    end
    do
        local EnchantSection = AutoTab:AddSection("Enchant Features", false)
        local _enchantState = {
            enabled              = false,
            task                 = nil,
            statusTask           = nil,
            rollCount            = 0,
            targetEnchantId      = 10,
            targetEnchantName    = "XPerienced I",
            enchantType          = 1,
            enchantStoneItemId   = 10,
            waitingForUpdate     = false,
            listenerConnected    = false,
            replionUpdateConn    = nil,
            atAltar              = false,
            savedPos             = nil,
            lastRolledEnchantId  = nil,
            rollGeneration       = 0,
        }
        local enchantMapping = {}
        local enchantNames   = {}
        pcall(function()
            local enchantFolder = ReplicatedStorage:FindFirstChild("Enchants")
            if not enchantFolder then
                local ok2, res = pcall(function() return ReplicatedStorage:WaitForChild("Enchants", 5) end)
                if ok2 and res then enchantFolder = res end
            end
            if not enchantFolder then return end
            for _, child in ipairs(enchantFolder:GetChildren()) do
                if child:IsA("ModuleScript") then
                    local ok, data = pcall(function() return require(child) end)
                    if ok and data and data.Data and data.Data.Name and data.Data.Id then
                        enchantMapping[data.Data.Name] = data.Data.Id
                        table.insert(enchantNames, data.Data.Name)
                    end
                end
            end
            table.sort(enchantNames)
        end)
        local _enchantData = nil
        LocalPlayer.CharacterAdded:Connect(function()
            _enchantState.atAltar = false
            _enchantState.savedPos = nil
            _enchantData = nil
        end)
        local function getCurrentRodEnchantId()
            if not _enchantData then return nil end
            local enchantId = nil
            pcall(function()
                local equippedItems = _enchantData:Get("EquippedItems") or {}
                local fishingRods   = _enchantData:Get({"Inventory", "Fishing Rods"}) or {}
                for _, uuid in pairs(equippedItems) do
                    for _, rod in ipairs(fishingRods) do
                        if rod.UUID == uuid then
                            if rod.Metadata then
                                if _enchantState.enchantType == 2 then
                                    enchantId = rod.Metadata.EnchantId2
                                else
                                    enchantId = rod.Metadata.EnchantId
                                end
                            end
                            return
                        end
                    end
                end
            end)
            return enchantId
        end
        local EnchantStatusParagraph = EnchantSection:AddParagraph({
            Title   = "Enchant Status",
            Content = "Current Rod : None\nEnchant 1 : None\nEnchant 2 : None\nEnchant Stones Left : 0",
        })
        local function startStatusLoop()
            if _enchantState.statusTask then
                pcall(function() task.cancel(_enchantState.statusTask) end)
                _enchantState.statusTask = nil
            end
            _enchantState.statusTask = task.spawn(function()
                local ItemUtility = nil
                pcall(function() ItemUtility = require(ReplicatedStorage.Shared.ItemUtility) end)
                while _enchantState.enabled do
                    task.wait(2)
                    if not _enchantData or not ItemUtility then continue end
                    pcall(function()
                        local rodName      = "None"
                        local enchant1Name = "None"
                        local enchant2Name = "None"
                        local stoneCount   = 0
                        local equippedItems = _enchantData:Get("EquippedItems") or {}
                        local fishingRods   = _enchantData:Get({"Inventory", "Fishing Rods"}) or {}
                        for _, uuid in pairs(equippedItems) do
                            for _, rod in ipairs(fishingRods) do
                                if rod.UUID == uuid then
                                    local itemData = ItemUtility:GetItemData(rod.Id)
                                    rodName = itemData and itemData.Data.Name or "None"
                                    if rod.Metadata then
                                        if rod.Metadata.EnchantId then
                                            local eData = ItemUtility:GetEnchantData(rod.Metadata.EnchantId)
                                            if eData and eData.Data and eData.Data.Name then
                                                enchant1Name = eData.Data.Name
                                            end
                                        end
                                        if rod.Metadata.EnchantId2 then
                                            local eData = ItemUtility:GetEnchantData(rod.Metadata.EnchantId2)
                                            if eData and eData.Data and eData.Data.Name then
                                                enchant2Name = eData.Data.Name
                                            end
                                        end
                                    end
                                    break
                                end
                            end
                        end
                        for _, item in pairs(_enchantData:GetExpect({"Inventory", "Items"})) do
                            if item.Id == _enchantState.enchantStoneItemId then
                                stoneCount = stoneCount + 1
                            end
                        end
                        EnchantStatusParagraph:SetContent(
                            ("Current Rod : %s\nEnchant 1 : %s\nEnchant 2 : %s\nEnchant Stones Left : %d"):format(
                                rodName, enchant1Name, enchant2Name, stoneCount
                            )
                        )
                    end)
                end
                _enchantState.statusTask = nil
            end)
        end
        local function disconnectEnchantReplionListener()
            if _enchantState.replionUpdateConn then
                pcall(function() _enchantState.replionUpdateConn:Disconnect() end)
                _enchantState.replionUpdateConn = nil
            end
            _enchantState.listenerConnected = false
        end
        local function connectUpdateListener()
            if _enchantState.listenerConnected and _enchantState.replionUpdateConn then return end
            pcall(function()
                local UpdateRemote = ReplicatedStorage.Packages._Index["ytrev_replion@2.0.0-rc.3"].replion.Remotes.Update
                if UpdateRemote and not _enchantState.replionUpdateConn then
                    _enchantState.replionUpdateConn = UpdateRemote.OnClientEvent:Connect(function(_, path, data)
                        if not _enchantState.enabled or not _enchantState.waitingForUpdate then return end
                        if not (path and type(path) == "table" and #path >= 4) then return end
                        if not (path[1] == "Inventory" and path[2] == "Fishing Rods" and path[4] == "Metadata") then return end

                        local rolledEnchantId = nil

                        -- Handle direct field path: {"Inventory", "Fishing Rods", <idx>, "Metadata", "EnchantId"/"EnchantId2"}
                        if #path >= 5 then
                            local fieldName = path[5]
                            if _enchantState.enchantType == 2 and fieldName == "EnchantId2" then
                                rolledEnchantId = data
                            elseif _enchantState.enchantType ~= 2 and fieldName == "EnchantId" then
                                rolledEnchantId = data
                            end
                        end

                        -- Handle table-level Metadata update
                        if not rolledEnchantId and type(data) == "table" then
                            if _enchantState.enchantType == 2 then
                                rolledEnchantId = data.EnchantId2
                            else
                                rolledEnchantId = data.EnchantId
                            end
                        elseif not rolledEnchantId and type(data) == "number" then
                            rolledEnchantId = data
                        end

                        if not rolledEnchantId then
                            local fallbackId = getCurrentRodEnchantId()
                            if fallbackId then
                                rolledEnchantId = fallbackId
                            end
                        end

                        if not rolledEnchantId then return end

                        _enchantState.rollCount           = _enchantState.rollCount + 1
                        _enchantState.lastRolledEnchantId = rolledEnchantId
                        _enchantState.waitingForUpdate    = false
                    end)
                    _enchantState.listenerConnected = _enchantState.replionUpdateConn ~= nil
                end
            end)
        end
        local function checkAndHandleTargetReached()
            if not _enchantState.enabled then return true end

            local rolledId = _enchantState.lastRolledEnchantId

            if not rolledId then
                rolledId = getCurrentRodEnchantId()
            end

            if rolledId and rolledId == _enchantState.targetEnchantId then
                _enchantState.enabled = false
                disconnectEnchantReplionListener()

                if _enchantState.savedPos then
                    task.wait(0.5)
                    pcall(function()
                        local char = LocalPlayer.Character
                        local hrp  = char and char:FindFirstChild("HumanoidRootPart")
                        if hrp then hrp.CFrame = _enchantState.savedPos end
                    end)
                    _enchantState.savedPos = nil
                    _enchantState.atAltar  = false
                end

                pcall(function()
                    Library:MakeNotify({
                        Title       = "Auto Enchant",
                        Description = "Successfully obtained enchant: " .. tostring(_enchantState.targetEnchantName),
                        Color       = Color3.fromRGB(100, 255, 100),
                        Delay       = 5,
                    })
                end)
                return true
            end

            return false
        end
        EnchantSection:AddDropdown({
            Title    = "Enchant Type",
            Options  = { "Normal Enchant", "Second Enchant", "Evolved Enchant", "Candy Enchant", "Eggy Enchant" },
            Default  = "Normal Enchant",
            Callback = function(value)
                if value == "Evolved Enchant" then
                    _enchantState.enchantStoneItemId = 558
                    _enchantState.enchantType        = 1
                elseif value == "Second Enchant" then
                    _enchantState.enchantStoneItemId = 246
                    _enchantState.enchantType        = 2
                elseif value == "Candy Enchant" then
                    _enchantState.enchantStoneItemId = 714
                    _enchantState.enchantType        = 1
                elseif value == "Eggy Enchant" then
                    _enchantState.enchantStoneItemId = 873
                    _enchantState.enchantType        = 1
                else
                    _enchantState.enchantStoneItemId = 10
                    _enchantState.enchantType        = 1
                end
            end,
        })
        EnchantSection:AddDropdown({
            Title    = "Target Enchant",
            Options  = enchantNames,
            Default  = "XPerienced I",
            Callback = function(value)
                local id = enchantMapping[value]
                if id then
                    _enchantState.targetEnchantId   = id
                    _enchantState.targetEnchantName = value
                end
            end,
        })
        EnchantSection:AddToggle({
            Title    = "Auto Enchant Reroll",
            Default  = false,
            NoSave   = true,
            Callback = function(on)
                if on then
                    if _enchantState.enabled then return end
                    if not _enchantData then
                        pcall(function()
                            _enchantData = getCachedReplionData()
                        end)
                    end

                    local currentEnchant = getCurrentRodEnchantId()
                    if currentEnchant and currentEnchant == _enchantState.targetEnchantId then
                        pcall(function()
                            Library:MakeNotify({
                                Title       = "Auto Enchant",
                                Description = "Rod already has enchant: " .. tostring(_enchantState.targetEnchantName),
                                Color       = Color3.fromRGB(100, 255, 100),
                                Delay       = 3,
                            })
                        end)
                        return
                    end

                    _enchantState.enabled             = true
                    _enchantState.rollCount           = 0
                    _enchantState.waitingForUpdate    = false
                    _enchantState.lastRolledEnchantId = nil

                    startStatusLoop()
                    connectUpdateListener()

                    _enchantState.task = task.spawn(function()
                        while _enchantState.enabled do
                            local character = LocalPlayer.Character
                            if not character or not character:FindFirstChild("HumanoidRootPart") then
                                task.wait(1)
                                continue
                            end

                            if not _enchantState.atAltar then
                                pcall(function()
                                    local hrp = character:FindFirstChild("HumanoidRootPart")
                                    if hrp and not _enchantState.savedPos then _enchantState.savedPos = hrp.CFrame end
                                end)
                                if _enchantState.enchantType == 2 then
                                    character.HumanoidRootPart.CFrame = CFrame.new(
                                        1479.35742, 124.582748, -604.037476,
                                        -0.171021342, 0.0301617607, 0.984805524,
                                        0.173656046, 0.984806359, -4.67896461e-06,
                                        -0.969842851, 0.171016648, -0.173660636
                                    )
                                else
                                    character.HumanoidRootPart.CFrame = CFrame.new(3245, -1301, 1394)
                                end
                                task.wait(1.5)
                                _enchantState.atAltar = true
                            end

                            if not _enchantState.enabled then break end

                            local stoneUUID = nil
                            pcall(function()
                                for _, item in pairs(_enchantData:GetExpect({"Inventory", "Items"})) do
                                    if item.Id == _enchantState.enchantStoneItemId then
                                        stoneUUID = item.UUID
                                        break
                                    end
                                end
                            end)

                            if not stoneUUID then
                                _enchantState.enabled = false
                                disconnectEnchantReplionListener()
                                pcall(function()
                                    Library:MakeNotify({
                                        Title       = "Auto Enchant",
                                        Description = "Out of enchant stones!",
                                        Color       = Color3.fromRGB(255, 100, 100),
                                        Delay       = 4,
                                    })
                                end)
                                break
                            end

                            local slotKey = nil
                            local equipTimeout = tick()
                            while tick() - equipTimeout < 5 do
                                if not _enchantState.enabled then break end

                                -- Re-verify stone still exists in inventory (prevents infinite loop if consumed)
                                local stoneStillExists = false
                                pcall(function()
                                    for _, item in pairs(_enchantData:GetExpect({"Inventory", "Items"})) do
                                        if item.UUID == stoneUUID and item.Id == _enchantState.enchantStoneItemId then
                                            stoneStillExists = true
                                            break
                                        end
                                    end
                                end)
                                if not stoneStillExists then
                                    stoneUUID = nil
                                    break
                                end

                                local equippedItems = _enchantData:Get("EquippedItems") or {}
                                for key, uuid in pairs(equippedItems) do
                                    if uuid == stoneUUID then slotKey = key end
                                end
                                if slotKey then
                                    break
                                else
                                    pcall(function() NetEvents.RE_EquipItem:FireServer(stoneUUID, "Enchant Stones") end)
                                    task.wait(0.5)
                                end
                            end

                            if not stoneUUID then continue end
                            if not slotKey or not _enchantState.enabled then
                                task.wait(1)
                                continue
                            end

                            pcall(function() NetEvents.RF_EquipToolFromHotbar:FireServer(slotKey) end)
                            task.wait(0.4)

                            if not _enchantState.enabled then break end

                            pcall(function()
                                if _enchantState.enchantType == 2 then
                                    NetEvents.RE_ActivateSecondEnchantingAltar:FireServer()
                                else
                                    NetEvents.RE_ActivateEnchantingAltar:FireServer()
                                end
                            end)
                            task.wait(0.6)

                            if not _enchantState.enabled then break end

                            local preRollEnchantId = getCurrentRodEnchantId()
                            _enchantState.rollGeneration      = _enchantState.rollGeneration + 1
                            _enchantState.waitingForUpdate    = true
                            _enchantState.lastRolledEnchantId = nil
                            pcall(function() NetEvents.RE_RollEnchant:FireServer() end)

                            local rollTimeout = tick()
                            while _enchantState.waitingForUpdate and _enchantState.enabled and tick() - rollTimeout < 5 do
                                task.wait(0.1)
                            end

                            if _enchantState.waitingForUpdate then
                                _enchantState.waitingForUpdate = false

                                local fallbackId = getCurrentRodEnchantId()
                                -- Only count as new roll if enchant actually changed
                                if fallbackId and fallbackId ~= preRollEnchantId then
                                    _enchantState.lastRolledEnchantId = fallbackId
                                    _enchantState.rollCount = _enchantState.rollCount + 1
                                else
                                    _enchantState.atAltar = false
                                    task.wait(1.5)
                                    continue
                                end
                            end

                            if checkAndHandleTargetReached() then break end

                            -- Interruptible cooldown matching server's 8s ProximityPrompt disable
                            local cooldownEnd = tick() + 8.5
                            while _enchantState.enabled and tick() < cooldownEnd do
                                task.wait(0.5)
                            end
                        end
                    end)
                else
                    _enchantState.enabled             = false
                    _enchantState.waitingForUpdate    = false
                    _enchantState.atAltar             = false
                    _enchantState.savedPos            = nil
                    _enchantState.lastRolledEnchantId = nil

                    if _enchantState.task then
                        pcall(function() task.cancel(_enchantState.task) end)
                        _enchantState.task = nil
                    end
                    if _enchantState.statusTask then
                        pcall(function() task.cancel(_enchantState.statusTask) end)
                        _enchantState.statusTask = nil
                    end

                    disconnectEnchantReplionListener()
                end
            end,
        })
        EnchantSection:AddButton({
            Title    = "Teleport to Altar 1",
            Callback = function()
                local character = LocalPlayer.Character
                if character and character:FindFirstChild("HumanoidRootPart") then
                    character.HumanoidRootPart.CFrame = CFrame.new(3245, -1301, 1394)
                end
            end,
        })
        EnchantSection:AddButton({
            Title    = "Teleport to Altar 2",
            Callback = function()
                local character = LocalPlayer.Character
                if character and character:FindFirstChild("HumanoidRootPart") then
                    character.HumanoidRootPart.CFrame = CFrame.new(
                        1479.35742, 124.582748, -604.037476,
                        -0.171021342, 0.0301617607, 0.984805524,
                        0.173656046, 0.984806359, -4.67896461e-06,
                        -0.969842851, 0.171016648, -0.173660636
                    )
                end
            end,
        })
    end
    do
        local TotemSection = AutoTab:AddSection("Auto Spawn Totem", false)
        local _totemUUIDMap = {}
        local _totemState = {
            enabled           = false,
            task              = nil,
            selectedTotem     = nil,
            data              = nil,
            totemMap          = {},
            totemNames        = {},
            totemCreatedConn  = nil,
            ancestryConns     = {},
        }
        local function _disconnectAutoTotemListeners()
            if _totemState.totemCreatedConn then
                pcall(function() _totemState.totemCreatedConn:Disconnect() end)
                _totemState.totemCreatedConn = nil
            end
            for _, ac in ipairs(_totemState.ancestryConns) do
                pcall(function() ac:Disconnect() end)
            end
            table.clear(_totemState.ancestryConns)
        end
        local _totemDropdownRef = nil
        local function _scanTotems()
            _totemState.totemMap   = {}
            _totemState.totemNames = {}
            pcall(function()
                local folder = ReplicatedStorage:FindFirstChild("Totems")
                if not folder then return end
                for _, mod in ipairs(folder:GetChildren()) do
                    if mod:IsA("ModuleScript") then
                        local ok, data = pcall(function() return require(mod) end)
                        if ok and type(data) == "table" and data.Data and data.Data.Id then
                            local name = data.Data.Name or mod.Name
                            _totemState.totemMap[name] = data.Data.Id
                            table.insert(_totemState.totemNames, name)
                        end
                    end
                end
                table.sort(_totemState.totemNames)
            end)
        end
        task.spawn(function()
            _scanTotems()
            _totemState.selectedTotem = _totemState.totemNames[1]
            if _totemDropdownRef and _totemDropdownRef.SetOptions then
                _totemDropdownRef:SetOptions(
                    #_totemState.totemNames > 0 and _totemState.totemNames or { "No Totems Found" }
                )
            end
        end)
        _totemDropdownRef = TotemSection:AddDropdown({
            Title    = "Totem Type",
            Options  = #_totemState.totemNames > 0 and _totemState.totemNames or { "Loading..." },
            Default  = nil,
            Callback = function(selected)
                _totemState.selectedTotem = selected
            end,
        })
        TotemSection:AddButton({
            Title    = "Refresh Totem List",
            Callback = function()
                _scanTotems()
                if _totemDropdownRef and _totemDropdownRef.SetOptions then
                    _totemDropdownRef:SetOptions(
                        #_totemState.totemNames > 0 and _totemState.totemNames or { "No Totems Found" }
                    )
                end
            end,
        })
        TotemSection:AddToggle({
            Title    = "Enable Auto Spawn",
            Default  = false,
            NoSave   = true,
            Callback = function(on)
                if on then
                    if _totemState.enabled then return end
                    if not _totemState.data then
                        pcall(function() _totemState.data = getCachedReplionData() end)
                        if not _totemState.data then
                            local rep = getCachedReplion()
                            if rep then _totemState.data = rep.Client:WaitReplion("Data") end
                        end
                    end
                    if not _totemState.data then
                        warn("[AutoSpawn] Data belum siap!"); return
                    end
                    if not NetEvents.IsInitialized then
                        warn("[AutoSpawn] EventResolver belum siap!"); return
                    end
                    _disconnectAutoTotemListeners()
                    pcall(function()
                        local ev = NetEvents.RE_TotemCreated
                        if not ev then return end
                        _totemState.totemCreatedConn = ev.OnClientEvent:Connect(function(model, uuid)
                            if not _totemState.enabled or not model or not uuid then return end
                            _totemUUIDMap[model] = uuid
                            local anc = model.AncestryChanged:Connect(function()
                                if not model.Parent then
                                    _totemUUIDMap[model] = nil
                                    pcall(function() anc:Disconnect() end)
                                end
                            end)
                            table.insert(_totemState.ancestryConns, anc)
                        end)
                    end)
                    _totemState.enabled = true
                    _totemState.task = task.spawn(function()
                        while _totemState.enabled do
                            local underEffect = false
                            pcall(function()
                                local ok, boosts = pcall(function()
                                    return _totemState.data:Get("TotemBoosts")
                                end)
                                if ok and boosts and #boosts > 0 then
                                    underEffect = true
                                end
                            end)
                            if not underEffect then
                                local char = LocalPlayer.Character
                                local hrp  = char and char:FindFirstChild("HumanoidRootPart")
                                if hrp then
                                    local closestUUID = nil
                                    local closestDist = math.huge
                                    for model, uuid in pairs(_totemUUIDMap) do
                                        if model and model.Parent then
                                            local handle = model:FindFirstChild("Handle") or model.PrimaryPart
                                            if handle then
                                                local dist = (handle.Position - hrp.Position).Magnitude
                                                if dist < closestDist then
                                                    closestDist = dist
                                                    closestUUID = uuid
                                                end
                                            end
                                        else
                                            _totemUUIDMap[model] = nil
                                        end
                                    end
                                    if closestUUID then
                                        safeFire(function()
                                            NetEvents.RE_TotemPickup:FireServer(closestUUID)
                                        end)
                                        task.wait(2)
                                    else
                                        local totemUUID = nil
                                        pcall(function()
                                            local targetId = _totemState.totemMap[_totemState.selectedTotem]
                                            if not targetId then return end
                                            local ok, inv = pcall(function()
                                                return _totemState.data:Get("Inventory")
                                            end)
                                            if ok and inv and inv.Totems then
                                                for _, item in pairs(inv.Totems) do
                                                    if item and item.UUID and tonumber(item.Id) == targetId then
                                                        if (item.Count or 1) >= 1 then
                                                            totemUUID = item.UUID
                                                            break
                                                        end
                                                    end
                                                end
                                            end
                                        end)
                                        if totemUUID then
                                            pcall(function()
                                                NetEvents.RE_SpawnTotem:FireServer(totemUUID)
                                            end)
                                        end
                                    end
                                end
                            end
                            task.wait(3)
                        end
                    end)
                    Library:MakeNotify({ Title = "Auto Spawn Totem", Description = "Aktif.", Delay = 2 })
                else
                    _totemState.enabled = false
                    _disconnectAutoTotemListeners()
                    table.clear(_totemUUIDMap)
                    if _totemState.task then
                        task.cancel(_totemState.task)
                        _totemState.task = nil
                    end
                    Library:MakeNotify({ Title = "Auto Spawn Totem", Description = "Dihentikan.", Delay = 2 })
                end
            end,
        })
        TotemSection:AddButton({
            Title    = "Spawn Now",
            Callback = function()
                if not _totemState.data then
                    pcall(function() _totemState.data = getCachedReplionData() end)
                end
                if not _totemState.data then return end
                local totemUUID = nil
                pcall(function()
                    local targetId = _totemState.totemMap[_totemState.selectedTotem]
                    if not targetId then return end
                    local ok, inv = pcall(function()
                        return _totemState.data:Get("Inventory")
                    end)
                    if ok and inv and inv.Totems then
                        for _, item in pairs(inv.Totems) do
                            if item and item.UUID and tonumber(item.Id) == targetId then
                                if (item.Count or 1) >= 1 then
                                    totemUUID = item.UUID
                                    break
                                end
                            end
                        end
                    end
                end)
                if totemUUID then
                    pcall(function()
                        NetEvents.RE_SpawnTotem:FireServer(totemUUID)
                    end)
                end
            end,
        })
    end
    do
        local TotemSection = AutoTab:AddSection("Auto Spawn 4X Totem(Mix)[BETA]", false)
        _totem = {
            active = false, thread = nil, monitorThread = nil,
            stateConn = nil, holdConn = nil, noclipConn = nil, physicsSession = 0,
            totemMap = {}, totemNames = {}, selectedSlots = { nil, nil, nil, nil }, data = nil,
        }
        _totemOriginal = { States = {}, AnimateEnabled = true, CFrame = nil, CanCollide = {} }
        _dropdownRefs  = { nil, nil, nil, nil }
        local SLOT4_NONE = "None (Skip)"
        local REF_CENTER = Vector3.new(93.932, 9.532, 2684.134)
        local REF_SPOTS  = {
            Vector3.new(45.0468979, 9.51625347, 2730.19067),
            Vector3.new(45.0468979, 110.516253, 2730.19067),
            Vector3.new(84.6406631, 10.2174253, 2636.05786),
            Vector3.new(84.6406631, 111.217425, 2636.05786),
        }
        local ALL_STATES = {
            Enum.HumanoidStateType.Running, Enum.HumanoidStateType.Swimming,
            Enum.HumanoidStateType.Jumping, Enum.HumanoidStateType.GettingUp,
            Enum.HumanoidStateType.Freefall, Enum.HumanoidStateType.Landed,
            Enum.HumanoidStateType.Climbing, Enum.HumanoidStateType.FallingDown,
            Enum.HumanoidStateType.Physics, Enum.HumanoidStateType.Ragdoll,
            Enum.HumanoidStateType.PlatformStanding, Enum.HumanoidStateType.RunningNoPhysics,
            Enum.HumanoidStateType.StrafingNoPhysics, Enum.HumanoidStateType.Seated,
            Enum.HumanoidStateType.Flying,
        }
        local function _scanTotems()
            _totem.totemMap, _totem.totemNames = {}, {}
            pcall(function()
                local folder = ReplicatedStorage:FindFirstChild("Totems")
                if not folder then return end
                for _, mod in ipairs(folder:GetChildren()) do
                    if mod:IsA("ModuleScript") then
                        local ok, data = pcall(function() return require(mod) end)
                        if ok and type(data) == "table" and data.Data and data.Data.Id then
                            local name = data.Data.Name or mod.Name
                            _totem.totemMap[name] = data.Data.Id
                            table.insert(_totem.totemNames, name)
                        end
                    end
                end
                table.sort(_totem.totemNames)
            end)
        end
        local function _updateDropdowns()
            local options = #_totem.totemNames > 0 and _totem.totemNames or { "No Totems Found" }
            for i = 1, 3 do
                if _dropdownRefs[i] and _dropdownRefs[i].SetOptions then _dropdownRefs[i]:SetOptions(options) end
            end
            if _dropdownRefs[4] and _dropdownRefs[4].SetOptions then
                local slot4Opts = { SLOT4_NONE }
                for _, name in ipairs(_totem.totemNames) do table.insert(slot4Opts, name) end
                _dropdownRefs[4]:SetOptions(slot4Opts)
            end
            for i = 1, 3 do
                if not _totem.selectedSlots[i] then
                    _totem.selectedSlots[i] = _totem.totemNames[i] or _totem.totemNames[1]
                end
            end
        end
        local function getTotemUUID(totemName)
            if not _totem.data or not totemName then return nil end
            local targetId = _totem.totemMap[totemName]
            if not targetId then return nil end
            local uuid = nil
            pcall(function()
                local ok, inv = pcall(function() return _totem.data:Get("Inventory") end)
                if ok and inv and inv.Totems then
                    for _, item in pairs(inv.Totems) do
                        if item and item.UUID and tonumber(item.Id) == targetId and (item.Count or 1) >= 1 then
                            uuid = item.UUID; break
                        end
                    end
                end
            end)
            return uuid
        end
        local function getActiveBoostIds()
            local ids = {}
            pcall(function()
                local ok, boosts = pcall(function() return _totem.data:Get("TotemBoosts") end)
                if ok and boosts then
                    for _, b in pairs(boosts) do
                        if b and b.Id then ids[tonumber(b.Id)] = true end
                    end
                end
            end)
            return ids
        end
        _scanTotems()
        TotemSection:AddParagraph({
            Title = "Auto Totem Info",
            Content = "[EN] Select different totems for each slot. Slot 4 is optional (for event totems). "
                .. "If a totem effect expires (15s), it will auto re-spawn.\n"
                .. "[ID] Pilih totem yang berbeda di setiap slot. Slot 4 opsional (untuk totem event). "
                .. "Jika efek totem habis (15 detik), otomatis pasang ulang.",
        })
        for i = 1, 3 do
            local idx = i
            _dropdownRefs[idx] = TotemSection:AddDropdown({
                Title    = ("Totem Slot %d"):format(idx),
                Options  = #_totem.totemNames > 0 and _totem.totemNames or { "No Totems Found" },
                Default  = _totem.totemNames[idx] or _totem.totemNames[1],
                Callback = function(sel) _totem.selectedSlots[idx] = sel end,
            })
            _totem.selectedSlots[i] = _totem.totemNames[i] or _totem.totemNames[1]
        end
        do
            local slot4Options = { SLOT4_NONE }
            for _, name in ipairs(_totem.totemNames) do table.insert(slot4Options, name) end
            _dropdownRefs[4] = TotemSection:AddDropdown({
                Title    = "Slot 4 Event Totem (optional)",
                Options  = slot4Options,
                Default  = SLOT4_NONE,
                Callback = function(sel)
                    _totem.selectedSlots[4] = (sel ~= SLOT4_NONE) and sel or nil
                end,
            })
            _totem.selectedSlots[4] = nil
        end
        TotemSection:AddButton({
            Title = "Refresh Totem List [Mix]",
            Callback = function() _scanTotems(); _updateDropdowns() end,
        })
        TotemSection:AddToggle({
            Title = "Enable Spawn Totem Mix", Default = false, NoSave = true,
            Callback = function(on)
                local function getFlyPart()
                    local c = LocalPlayer.Character
                    if not c then return nil end
                    return c:FindFirstChild("HumanoidRootPart") or c:FindFirstChild("Torso") or c:FindFirstChild("UpperTorso")
                end
                local function equipO2()   pcall(function() if NetEvents.RF_EquipOxygenTank   then NetEvents.RF_EquipOxygenTank:InvokeServer(575) end end) end
                local function unequipO2() pcall(function() if NetEvents.RF_UnequipOxygenTank then NetEvents.RF_UnequipOxygenTank:InvokeServer()  end end) end
                local function saveOriginalState(cf)
                    local char = LocalPlayer.Character
                    local hum  = char and char:FindFirstChild("Humanoid")
                    if not hum then return end
                    _totemOriginal.CFrame = cf
                    _totemOriginal.States, _totemOriginal.CanCollide = {}, {}
                    _totemOriginal.AnimateEnabled = true
                    if char:FindFirstChild("Animate") then
                        _totemOriginal.AnimateEnabled = (char.Animate.Disabled == false)
                    end
                    for _, st in ipairs(ALL_STATES) do
                        _totemOriginal.States[st] = hum:GetStateEnabled(st)
                    end
                    for _, part in ipairs(char:GetDescendants()) do
                        if part:IsA("BasePart") then _totemOriginal.CanCollide[part] = part.CanCollide end
                    end
                end
                local function restoreOriginalState()
                    local char     = LocalPlayer.Character
                    local hum      = char and char:FindFirstChild("Humanoid")
                    local mainPart = char and char:FindFirstChild("HumanoidRootPart")
                    local cf = _totemOriginal.CFrame or (mainPart and mainPart.CFrame)
                    if mainPart then
                        pcall(function()
                            mainPart.AssemblyLinearVelocity  = Vector3.zero
                            mainPart.AssemblyAngularVelocity = Vector3.zero
                            local bv = mainPart:FindFirstChild("FlyGuiVelocity")
                            local bg = mainPart:FindFirstChild("FlyGuiGyro")
                            if bv then bv.velocity = Vector3.zero; bv.maxForce = Vector3.new(9e9,9e9,9e9) end
                            if bg then bg.maxTorque = Vector3.new(9e9,9e9,9e9); if cf then bg.CFrame = cf end end
                            if cf then mainPart.CFrame = cf end
                        end)
                    end
                    if hum then pcall(function()
                        hum:SetStateEnabled(Enum.HumanoidStateType.Swimming, false)
                        hum:ChangeState(Enum.HumanoidStateType.Freefall)
                    end) end
                    if _totem.holdConn  then _totem.holdConn:Disconnect();  _totem.holdConn  = nil end
                    if _totem.stateConn then _totem.stateConn:Disconnect(); _totem.stateConn = nil end
                    if _totem.noclipConn then _totem.noclipConn:Disconnect(); _totem.noclipConn = nil end
                    _totem.physicsSession = _totem.physicsSession + 1
                    task.wait(0.15)
                    if char then pcall(function()
                        for part, was in pairs(_totemOriginal.CanCollide) do
                            if part and part.Parent then part.CanCollide = was end
                        end
                    end) end
                    if hum then
                        for st, en in pairs(_totemOriginal.States) do pcall(function() hum:SetStateEnabled(st, en) end) end
                    end
                    if char then pcall(function()
                        if char:FindFirstChild("Animate") then char.Animate.Disabled = not _totemOriginal.AnimateEnabled end
                    end) end
                    if hum then
                        hum.PlatformStand = false
                        pcall(function() hum:ChangeState(Enum.HumanoidStateType.Freefall) end)
                    end
                    task.wait(0.1)
                    if mainPart then pcall(function()
                        mainPart.AssemblyLinearVelocity = Vector3.zero; mainPart.AssemblyAngularVelocity = Vector3.zero
                        if cf then mainPart.CFrame = cf end
                    end) end
                    if mainPart then pcall(function()
                        for _, v in ipairs(mainPart:GetChildren()) do
                            if v.Name == "FlyGuiGyro" or v.Name == "FlyGuiVelocity" then v:Destroy() end
                        end
                    end) end
                    if mainPart then pcall(function()
                        mainPart.AssemblyLinearVelocity = Vector3.zero; mainPart.AssemblyAngularVelocity = Vector3.zero
                    end) end
                    if mainPart then task.spawn(function()
                        for _ = 1, 30 do
                            pcall(function()
                                if mainPart and mainPart.Parent then
                                    mainPart.AssemblyLinearVelocity = Vector3.zero; mainPart.AssemblyAngularVelocity = Vector3.zero
                                end
                            end)
                            RunService.Heartbeat:Wait()
                        end
                    end) end
                end
                local function enablePhysics()
                    local char = LocalPlayer.Character
                    local hum  = char and char:FindFirstChild("Humanoid")
                    local mp   = getFlyPart()
                    if not mp or not hum then return end
                    _totem.physicsSession = _totem.physicsSession + 1
                    local ses = _totem.physicsSession
                    pcall(function() if char:FindFirstChild("Animate") then char.Animate.Disabled = true end end)
                    hum.PlatformStand = true
                    pcall(function() for _, st in ipairs(ALL_STATES) do hum:SetStateEnabled(st, false) end end)
                    if not _totem.stateConn then
                        _totem.stateConn = RunService.Heartbeat:Connect(function()
                            if hum and hum.Parent and _totem.active then
                                pcall(function() hum:ChangeState(Enum.HumanoidStateType.Swimming); hum:SetStateEnabled(Enum.HumanoidStateType.Swimming, true) end)
                            end
                        end)
                    end
                    local bg = mp:FindFirstChild("FlyGuiGyro") or Instance.new("BodyGyro", mp)
                    bg.Name = "FlyGuiGyro"; bg.P = 9e4; bg.maxTorque = Vector3.new(9e9,9e9,9e9); bg.CFrame = mp.CFrame
                    local bv = mp:FindFirstChild("FlyGuiVelocity") or Instance.new("BodyVelocity", mp)
                    bv.Name = "FlyGuiVelocity"; bv.velocity = Vector3.new(0,0.1,0); bv.maxForce = Vector3.new(9e9,9e9,9e9)
                    local sChar, sHum = char, hum
                    local noclipParts = {}
                    local function setNoCollide(part)
                        if part and part:IsA("BasePart") then
                            part.CanCollide = false
                            noclipParts[part] = true
                        end
                    end
                    for _, p in ipairs(sChar:GetDescendants()) do setNoCollide(p) end
                    if _totem.noclipConn then _totem.noclipConn:Disconnect(); _totem.noclipConn = nil end
                    _totem.noclipConn = sChar.DescendantAdded:Connect(function(desc)
                        if _totem.active and _totem.physicsSession == ses then
                            setNoCollide(desc)
                        end
                    end)
                    task.spawn(function()
                        while _totem.active and _totem.physicsSession == ses and sChar and sChar.Parent do
                            for part in pairs(noclipParts) do
                                if part and part.Parent then
                                    part.CanCollide = false
                                else
                                    noclipParts[part] = nil
                                end
                            end
                            task.wait(0.25)
                        end
                    end)
                    task.spawn(function()
                        while _totem.active and _totem.physicsSession == ses and sHum and sHum.Parent do
                            sHum.Health = sHum.MaxHealth; task.wait(1)
                        end
                    end)
                end
                local function holdPosition(cf)
                    local mp = getFlyPart(); if not mp then return end
                    if _totem.holdConn then _totem.holdConn:Disconnect(); _totem.holdConn = nil end
                    _totem.holdConn = RunService.Heartbeat:Connect(function()
                        if mp and mp.Parent then mp.CFrame = cf; mp.Velocity = Vector3.zero; mp.AssemblyAngularVelocity = Vector3.zero end
                    end)
                end
                local function stopHold()
                    if _totem.holdConn then _totem.holdConn:Disconnect(); _totem.holdConn = nil end
                end
                local function flyTo(pos)
                    local mp = getFlyPart(); if not mp then return end
                    local bv = mp:FindFirstChild("FlyGuiVelocity")
                    local bg = mp:FindFirstChild("FlyGuiGyro")
                    if not bv or not bg then enablePhysics(); bv = mp:FindFirstChild("FlyGuiVelocity"); bg = mp:FindFirstChild("FlyGuiGyro") end
                    if not bv or not bg then return end
                    while _totem.active do
                        local diff = pos - mp.Position; local dist = diff.Magnitude
                        bg.CFrame = CFrame.lookAt(mp.Position, pos)
                        if dist < 1.0 then bv.velocity = Vector3.new(0,0.1,0); break
                        else bv.velocity = diff.Unit * 80 end
                        RunService.Heartbeat:Wait()
                    end
                end
                local function isOtherFeatureBusy()
                    return _classicMachineBusy or _atlantis.selling
                end
                local function waitForOtherFeatures()
                    if not isOtherFeatureBusy() then return true end
                    Library:MakeNotify({ Title = "3x Totem Mix", Description = "Menunggu fitur lain selesai...", Delay = 3 })
                    while _totem.active and isOtherFeatureBusy() do task.wait(1) end
                    if not _totem.active then return false end
                    task.wait(5)
                    return _totem.active
                end
                local function spawnMissingSlots(startCF, slots)
                    if not waitForOtherFeatures() then return false end
                    local char = LocalPlayer.Character
                    local hrp  = char and char:FindFirstChild("HumanoidRootPart")
                    if not hrp then return false end
                    local any = false
                    _totemSpawning = true
                    saveOriginalState(hrp.CFrame)
                    equipO2(); task.wait(0.3)
                    enablePhysics(); task.wait(0.5)
                    for _, si in ipairs(slots) do
                        if not _totem.active then break end
                        local name = _totem.selectedSlots[si]; if not name then continue end
                        local uuid = getTotemUUID(name); if not uuid then continue end
                        local tpos = startCF.Position + (REF_SPOTS[si] - REF_CENTER)
                        flyTo(tpos); holdPosition(CFrame.new(tpos)); task.wait(1.5)
                        safeFire(function() NetEvents.RE_SpawnTotem:FireServer(uuid) end)
                        any = true; task.wait(0.3); stopHold(); task.wait(0.2)
                    end
                    stopHold(); unequipO2(); task.wait(0.2)
                    restoreOriginalState()
                    _totemSpawning = false
                    return any
                end
                local function startMonitor()
                    if _totem.monitorThread then pcall(task.cancel, _totem.monitorThread); _totem.monitorThread = nil end
                    _totem.monitorThread = task.spawn(function()
                        local timers = { 0, 0, 0, 0 }
                        while _totem.active do
                            task.wait(1); if not _totem.active then break end
                            local char = LocalPlayer.Character
                            local hrp  = char and char:FindFirstChild("HumanoidRootPart")
                            if not hrp then timers = { 0, 0, 0, 0 }; continue end
                            local boosts = getActiveBoostIds()
                            for i = 1, 4 do
                                local name = _totem.selectedSlots[i]
                                if not name then timers[i] = 0; continue end
                                local tid = _totem.totemMap[name]
                                if not tid then timers[i] = 0; continue end
                                timers[i] = boosts[tid] and 0 or (timers[i] + 1)
                            end
                            local toSpawn = {}
                            for i = 1, 4 do
                                if timers[i] >= 15 then
                                    local n = _totem.selectedSlots[i]
                                    if n and getTotemUUID(n) then table.insert(toSpawn, i) end
                                end
                            end
                            if #toSpawn == 0 then continue end
                            for _, idx in ipairs(toSpawn) do timers[idx] = 0 end
                            local ns = {}
                            for _, idx in ipairs(toSpawn) do table.insert(ns, _totem.selectedSlots[idx] or "?") end
                            Library:MakeNotify({ Title = "3x Totem Mix", Description = "Re-spawn: " .. table.concat(ns, ", "), Delay = 3 })
                            spawnMissingSlots(hrp.CFrame, toSpawn)
                        end
                    end)
                end
                if on then
                    if _totem.active then return end
                    if not _totem.data then warn("[3xTotem] Data belum siap!"); return end
                    if not NetEvents.IsInitialized then warn("[3xTotem] EventResolver belum siap!"); return end
                    _totem.active = true
                    _totem.thread = task.spawn(function()
                        if not waitForOtherFeatures() then _totem.active = false; return end
                        local uuids = {}
                        local activeSlots = {}
                        local skipped = {}
                        for i = 1, 4 do
                            local name = _totem.selectedSlots[i]
                            if not name or not _totem.totemMap[name] then continue end
                            local uuid = getTotemUUID(name)
                            if uuid then
                                uuids[i] = uuid
                                table.insert(activeSlots, i)
                            else
                                table.insert(skipped, name)
                            end
                        end
                        if #activeSlots == 0 then
                            warn("[3xTotem] Tidak ada totem yang tersedia di inventory!")
                            Library:MakeNotify({ Title = "3x Totem Mix", Description = "Gagal: tidak ada totem di inventory!", Delay = 4 })
                            _totem.active = false; return
                        end
                        if #skipped > 0 then
                            Library:MakeNotify({ Title = "3x Totem Mix", Description = "Skip (tidak di tas): " .. table.concat(skipped, ", "), Delay = 4 })
                        end
                        local char = LocalPlayer.Character
                        local hrp  = char and char:FindFirstChild("HumanoidRootPart")
                        if not hrp then _totem.active = false; return end
                        local startCF = hrp.CFrame
                        saveOriginalState(startCF)
                        local hum = char:FindFirstChild("Humanoid")
                        if hum then hum.Health = hum.MaxHealth end
                        _totemSpawning = true
                        equipO2(); task.wait(0.3)
                        enablePhysics(); task.wait(0.5)
                        for _, si in ipairs(activeSlots) do
                            if not _totem.active then break end
                            local tpos = startCF.Position + (REF_SPOTS[si] - REF_CENTER)
                            flyTo(tpos); holdPosition(CFrame.new(tpos)); task.wait(1.5)
                            if uuids[si] and NetEvents.RE_SpawnTotem then
                                safeFire(function() NetEvents.RE_SpawnTotem:FireServer(uuids[si]) end)
                            end
                            task.wait(0.3); stopHold(); task.wait(0.2)
                        end
                        stopHold(); unequipO2(); task.wait(0.2)
                        restoreOriginalState()
                        _totemSpawning = false
                        local count = #activeSlots
                        Library:MakeNotify({ Title = "3x Totem Mix", Description = ("Selesai! %d totem berhasil di-spawn."):format(count), Delay = 3 })
                        startMonitor()
                    end)
                    local desc = ("Dimulai: %s | %s | %s"):format(
                        _totem.selectedSlots[1] or "?", _totem.selectedSlots[2] or "?", _totem.selectedSlots[3] or "?"
                    )
                    if _totem.selectedSlots[4] then desc = desc .. " | " .. _totem.selectedSlots[4] end
                    Library:MakeNotify({ Title = "3x Totem Mix", Description = desc, Delay = 3 })
                else
                    _totem.active = false
                    _totemSpawning = false
                    task.wait()
                    if _totem.stateConn     then _totem.stateConn:Disconnect();     _totem.stateConn     = nil end
                    if _totem.holdConn      then _totem.holdConn:Disconnect();      _totem.holdConn      = nil end
                    if _totem.noclipConn    then _totem.noclipConn:Disconnect();    _totem.noclipConn    = nil end
                    if _totem.thread        then pcall(task.cancel, _totem.thread);        _totem.thread        = nil end
                    if _totem.monitorThread then pcall(task.cancel, _totem.monitorThread); _totem.monitorThread = nil end
                    if not _totemOriginal.CFrame then
                        local hrp = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
                        if hrp then _totemOriginal.CFrame = hrp.CFrame end
                    end
                    task.spawn(function() unequipO2(); task.wait(0.3); restoreOriginalState() end)
                    Library:MakeNotify({ Title = "3x Totem Mix", Description = "Dihentikan.", Delay = 2 })
                end
            end,
        })
        task.spawn(function()
            pcall(function() _totem.data = getCachedReplionData() end)
            if not _totem.data then
                local rep = getCachedReplion()
                if rep then _totem.data = rep.Client:WaitReplion("Data") end
            end
        end)
    end
    do
        local deps = nil
        local function getDeps()
            if deps then return deps end
            local ok, result = pcall(function()
                return workspace:WaitForChild("!!! DEPENDENCIES", 60)
            end)
            if ok and result then
                deps = result
                return deps
            end
            return nil
        end

        local EVENT_LIST = {
            {
                Name         = "Ancient Lochness Monster",
                Position     = Vector3.new(6096.14, -585.92, 4669.50),
                LookDirection= Vector3.new(-0.8317, -0.4007, 0.3842),
                GetStats     = function()
                    local d = getDeps()
                    if not d then return nil end
                    local ok, stats = pcall(function()
                        return d["Event Tracker"].Main.Gui.Content.Items.Stats
                    end)
                    return ok and stats or nil
                end,
                GetCountdownText = function()
                    local d = getDeps()
                    if not d then return "?" end
                    local ok, text = pcall(function()
                        return d["Event Tracker"].Main.Gui.Content.Items.Countdown.Label.Text
                    end)
                    return ok and text or "?"
                end,
            },
            {
                Name         = "Mutant Runic Koi",
                Position     = Vector3.new(-3140.3860, -643.4843, -10451.0654),
                LookDirection= Vector3.new(1.0000, 0.0000, -0.0054),
                GetStats     = function()
                    local d = getDeps()
                    if not d then return nil end
                    local ok, stats = pcall(function()
                        return d["UnderwaterCity Event Tracker"].Main.Gui.Content.Items.Stats
                    end)
                    return ok and stats or nil
                end,
                GetCountdownText = function()
                    local d = getDeps()
                    if not d then return "?" end
                    local ok, text = pcall(function()
                        return d["UnderwaterCity Event Tracker"].Main.Gui.Content.Items.Countdown.Label.Text
                    end)
                    return ok and text or "?"
                end,
            },
        }

        local function RequestStream(position)
            task.spawn(function()
                pcall(function()
                    LocalPlayer:RequestStreamAroundAsync(position, 1000)
                end)
            end)
        end

        local function IsEventActive(cfg)
            local stats = cfg.GetStats()
            if not stats then return false end
            return stats.Visible == true
        end

        local function GetTimerText(cfg)
            local ok, text = pcall(function()
                return cfg.GetStats().Timer.Label.Text
            end)
            return ok and text or "?"
        end

        local function EvTeleport(targetCFrame)
            local char = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
            local hrp  = char:FindFirstChild("HumanoidRootPart")
            if not hrp then return false end
            for _ = 1, 8 do
                pcall(function()
                    hrp.Anchored = true
                    hrp.CFrame   = targetCFrame
                    if char.PrimaryPart then char:PivotTo(targetCFrame) end
                end)
                task.wait(0.15)
                pcall(function()
                    hrp.Anchored = false
                    hrp.AssemblyLinearVelocity  = Vector3.zero
                    hrp.AssemblyAngularVelocity = Vector3.zero
                end)
                task.wait(0.3)
                local hrp2 = LocalPlayer.Character
                    and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
                if hrp2 and (hrp2.Position - targetCFrame.Position).Magnitude < 50 then
                    return true
                end
            end
            return false
        end

        for _, cfg in ipairs(EVENT_LIST) do
            local _ev = {
                enabled       = false,
                thread        = nil,
                statusThread  = nil,
                depsThread    = nil,
                respawnConn   = nil,
                savedPos      = nil,
                isAtEvent     = false,
                lastWasActive = false,
                depsReady     = false,
            }
            local _eventCF = CFrame.lookAt(cfg.Position, cfg.Position + cfg.LookDirection)
            local EventSection    = AutoTab:AddSection("Auto " .. cfg.Name, false)
            local StatusParagraph = EventSection:AddParagraph({
                Title   = "Status",
                Content = "Idle",
            })

            EventSection:AddParagraph({
                Title   = "Info",
                Content = "Saves current position before TP to event\nAuto return after event ends\n6 events per day",
            })

            EventSection:AddButton({
                Title    = "Teleport to " .. cfg.Name,
                Callback = function()
                    local char = LocalPlayer.Character
                    local hrp  = char and char:FindFirstChild("HumanoidRootPart")
                    if hrp then _ev.savedPos = hrp.CFrame end
                    EvTeleport(_eventCF)
                end,
            })

            EventSection:AddButton({
                Title    = "Return to Saved Pos (" .. cfg.Name .. ")",
                Callback = function()
                    if not _ev.savedPos then
                        Library:MakeNotify({
                            Title       = cfg.Name,
                            Description = "No saved position!",
                            Color       = Color3.fromRGB(255, 179, 71),
                            Delay       = 2,
                        })
                        return
                    end
                    EvTeleport(_ev.savedPos)
                    _ev.savedPos  = nil
                    _ev.isAtEvent = false
                end,
            })

            EventSection:AddToggle({
                Title    = "Auto " .. cfg.Name .. " Teleport",
                Default  = false,
                NoSave   = true,
                Callback = function(on)
                    _ev.enabled = on

                    if _ev.statusThread then pcall(task.cancel, _ev.statusThread); _ev.statusThread = nil end
                    if _ev.thread       then pcall(task.cancel, _ev.thread);       _ev.thread       = nil end
                    if _ev.depsThread   then pcall(task.cancel, _ev.depsThread);   _ev.depsThread   = nil end
                    if _ev.respawnConn  then
                        pcall(function() _ev.respawnConn:Disconnect() end)
                        _ev.respawnConn = nil
                    end

                    if not on then
                        StatusParagraph:SetTitle("Status")
                        StatusParagraph:SetContent("Idle")
                        _ev.isAtEvent     = false
                        _ev.lastWasActive = false
                        return
                    end

                    _ev.depsThread = task.spawn(function()
                        if not getDeps() then
                            StatusParagraph:SetTitle("Waiting...")
                            StatusParagraph:SetContent("Waiting for DEPENDENCIES to load...")
                            local timeout = tick()
                            while not getDeps() and tick() - timeout < 120 do
                                task.wait(1)
                                if not _ev.enabled then return end
                            end
                            if not getDeps() then
                                StatusParagraph:SetTitle("Error")
                                StatusParagraph:SetContent("DEPENDENCIES not found after 120s.\nTry re-enabling the toggle.")
                                _ev.enabled = false
                                return
                            end
                        end

                        _ev.depsReady = true

                        _ev.statusThread = task.spawn(function()
                            while _ev.enabled do
                                task.wait(1)
                                pcall(function()
                                    RequestStream(cfg.Position)
                                    local active = IsEventActive(cfg)
                                    if active then
                                        StatusParagraph:SetTitle("EVENT ACTIVE")
                                        StatusParagraph:SetContent(
                                            "Time left: " .. GetTimerText(cfg) ..
                                            "\nStatus: " .. (_ev.isAtEvent and "At event location" or "Teleporting...")
                                        )
                                    else
                                        StatusParagraph:SetTitle("Waiting for Event")
                                        StatusParagraph:SetContent("Starts in: " .. cfg.GetCountdownText())
                                    end
                                end)
                            end
                            StatusParagraph:SetTitle("Status")
                            StatusParagraph:SetContent("Idle")
                        end)

                        _ev.respawnConn = LocalPlayer.CharacterAdded:Connect(function()
                            if not _ev.enabled then return end
                            task.wait(3)
                            if IsEventActive(cfg) and _ev.isAtEvent then
                                task.wait(1)
                                EvTeleport(_eventCF)
                            end
                        end)

                        _ev.thread = task.spawn(function()
                            while _ev.enabled do
                                task.wait(1)
                                pcall(function()
                                    RequestStream(cfg.Position)
                                    local active = IsEventActive(cfg)
                                    if active and not _ev.lastWasActive then
                                        _ev.lastWasActive = true
                                        local char = LocalPlayer.Character
                                        local hrp  = char and char:FindFirstChild("HumanoidRootPart")
                                        if hrp then _ev.savedPos = hrp.CFrame end
                                        task.wait(0.5)
                                        local ok = EvTeleport(_eventCF)
                                        if ok then
                                            _ev.isAtEvent = true
                                            Library:MakeNotify({
                                                Title       = cfg.Name,
                                                Description = "Event active! Teleporting to location.",
                                                Color       = Color3.fromRGB(100, 200, 255),
                                                Delay       = 3,
                                            })
                                            repeat
                                                task.wait(1)
                                                RequestStream(cfg.Position)
                                            until not IsEventActive(cfg) or not _ev.enabled
                                            if _ev.enabled and _ev.savedPos then
                                                task.wait(2)
                                                EvTeleport(_ev.savedPos)
                                                _ev.isAtEvent     = false
                                                _ev.lastWasActive = false
                                                _ev.savedPos      = nil
                                                Library:MakeNotify({
                                                    Title       = cfg.Name,
                                                    Description = "Event ended! Returned to original position.",
                                                    Color       = Color3.fromRGB(123, 239, 178),
                                                    Delay       = 3,
                                                })
                                            end
                                        end
                                    elseif not active then
                                        _ev.lastWasActive = false
                                        _ev.isAtEvent     = false
                                    end
                                end)
                            end

                            if _ev.respawnConn then
                                pcall(function() _ev.respawnConn:Disconnect() end)
                                _ev.respawnConn = nil
                            end
                            _ev.isAtEvent     = false
                            _ev.lastWasActive = false
                        end)
                    end)
                end,
            })
        end
    end
end

-- [Events Tab]
do
    local EventTab = MainWindow:AddTab({ Name = "Events", Icon = "menu" })
end

-- [Trade Tab]
do
    local TradeTab = MainWindow:AddTab({ Name = "Trade", Icon = "payment" })
    local Replion, ItemUtility, VendorUtility, PlayerStatsUtility, TradeData
    local Data
    pcall(function()
        Replion              = getCachedReplion()
        ItemUtility          = cachedRequire(ReplicatedStorage.Shared.ItemUtility)
        VendorUtility        = cachedRequire(ReplicatedStorage.Shared.VendorUtility)
        PlayerStatsUtility   = cachedRequire(ReplicatedStorage.Shared.PlayerStatsUtility)
        TradeData            = cachedRequire(ReplicatedStorage.Shared.Trading.TradeData)
        Data                 = getCachedReplionData()
    end)
    local TIER_FISH = {
        [1]="Common",[2]="Uncommon",[3]="Rare",
        [4]="Epic",[5]="Legendary",[6]="Mythic",[7]="Secret",
    }
    local ENCHANT_STONE_IDS = {
        ["Normal"] = 10, ["Double"] = 246, ["Evolved"] = 558, ["EggyEnchantStone"] = 873, ["Runic"] = 929,
    }
    local MAX_ITEMS_PER_TRADE = 20
    local _tradeState = {
        enabled               = false,
        task                  = nil,
        targetPlayer          = nil,
        playerManuallySelected = false,
        tradeMode             = "ByName",
        selectedItem          = nil,
        itemAmount            = 1,
        targetCoins           = 0,
        selectedRarity        = "Common",
        rarityAmount          = 1,
        selectedStoneType     = "Normal",
        stoneAmount           = 1,
        totalAttempted        = 0,
        totalSuccess          = 0,
        totalFailed           = 0,
        targetAmount          = 0,
        status                = "Idle",
        lastTradedItem        = "",
        coinTraded            = 0,
        totalItemsSent        = 0,
    }
    local _activeMonitorParagraph = nil
    local _activeToggleRef        = nil
    local function updateMonitor()
        if not _activeMonitorParagraph then return end
        local coinInfo = _tradeState.coinTraded > 0
            and ("\nCoins Traded: %d"):format(_tradeState.coinTraded)
            or ""
        pcall(function()
            _activeMonitorParagraph:SetContent(
                ("%s\nItems Sent: %d | Trades: %d/%d | Success: %d | Failed: %d%s"):format(
                    _tradeState.status or "?",
                    _tradeState.totalItemsSent,
                    _tradeState.totalAttempted,
                    _tradeState.targetAmount,
                    _tradeState.totalSuccess,
                    _tradeState.totalFailed,
                    coinInfo
                )
            )
        end)
    end
    local function setStatus(s)
        _tradeState.status = s
        updateMonitor()
    end
    local function executeTradeMulti(itemList, totalCoinValue)
        if not _tradeState.enabled then return false end
        if not itemList or #itemList == 0 then return false end
        local targetPlayer = Players:FindFirstChild(_tradeState.targetPlayer)
        if not targetPlayer then
            setStatus("Error: Player tidak ditemukan")
            return false
        end
        task.wait(1)
        do
            local _drain
            _drain = TradeData.Remotes.TradeCompleted.OnClientEvent:Connect(function() end)
            local _drain2
            _drain2 = TradeData.Remotes.TradeEnded.OnClientEvent:Connect(function() end)
            task.wait(0.5)
            pcall(function() _drain:Disconnect() end)
            pcall(function() _drain2:Disconnect() end)
        end
        if not _tradeState.enabled then return false end
        _tradeState.totalAttempted += 1
        local label = #itemList == 1
            and itemList[1].Name
            or ("%d items"):format(#itemList)
        setStatus(("Sending offer: %s (%d/%d)"):format(
            label, _tradeState.totalAttempted, _tradeState.targetAmount
        ))
        local tradeResult  = nil
        local tradeReplion = nil
        local tradeActive  = true
        local connCompleted = TradeData.Remotes.TradeCompleted.OnClientEvent:Connect(function()
            if tradeActive and tradeResult == nil then tradeResult = true end
        end)
        local connEnded = TradeData.Remotes.TradeEnded.OnClientEvent:Connect(function()
            if tradeActive and tradeResult == nil then tradeResult = false end
        end)
        local connStarted = TradeData.Remotes.TradeStarted.OnClientEvent:Connect(function(replionId)
            if not tradeActive then return end
            if not Replion or not Replion.Client then return end
            local rep = Replion.Client:GetReplion(replionId)
            if rep then tradeReplion = rep end
        end)
        local function cleanupConns()
            tradeActive = false
            pcall(function() connCompleted:Disconnect() end)
            pcall(function() connEnded:Disconnect() end)
            pcall(function() connStarted:Disconnect() end)
        end
        local function failTrade(reason)
            pcall(function() TradeData.Remotes.CancelTrade:InvokeServer() end)
            cleanupConns()
            _tradeState.totalFailed += 1
            setStatus(reason)
            updateMonitor(); task.wait(1)
            return false
        end
        local function isTradeAlive()
            return _tradeState.enabled and tradeResult == nil
                and (not tradeReplion or not tradeReplion.Destroyed)
        end
        local sendOk, sendErr = pcall(function()
            TradeData.Remotes.SendTradeOffer:InvokeServer(targetPlayer)
        end)
        if not sendOk then
            cleanupConns()
            _tradeState.totalFailed += 1
            setStatus("Error: Gagal kirim offer - " .. tostring(sendErr))
            updateMonitor(); task.wait(1)
            return false
        end
        local t0 = tick()
        while not tradeReplion and tick() - t0 < 15 do
            if not _tradeState.enabled then cleanupConns(); return false end
            if tradeResult ~= nil then cleanupConns(); _tradeState.totalFailed += 1; return false end
            task.wait(0.1)
        end
        pcall(function() connStarted:Disconnect() end)
        if not tradeReplion then
            return failTrade("Error: Target tidak accept offer")
        end
        setStatus(("Offer accepted! Adding %d item(s)..."):format(#itemList))
        for _, item in ipairs(itemList) do
            if not isTradeAlive() then
                if tradeResult == nil then
                    pcall(function() TradeData.Remotes.CancelTrade:InvokeServer() end)
                end
                cleanupConns()
                if tradeResult == nil then _tradeState.totalFailed += 1 end
                return false
            end
            local addOk, addErr = pcall(function()
                TradeData.Remotes.AddItem:InvokeServer(item.Type, item.UUID)
            end)
            if not addOk then
                return failTrade("Error: Gagal add item - " .. tostring(addErr))
            end
            task.wait(0.05)
        end
        if tradeResult ~= nil then
            cleanupConns()
            if tradeResult then
                _tradeState.totalSuccess   += 1
                _tradeState.totalItemsSent += #itemList
                _tradeState.lastTradedItem  = itemList[#itemList].Name
                _tradeState.coinTraded     += (totalCoinValue or 0)
                setStatus(("Success: %s - %d items sent (%d/%d)"):format(label, _tradeState.totalItemsSent, _tradeState.totalSuccess, _tradeState.targetAmount))
                updateMonitor(); task.wait(1.5)
                return true
            else
                _tradeState.totalFailed += 1
                setStatus(("Failed: %s"):format(label))
                updateMonitor(); task.wait(1)
                return false
            end
        end
        local lockDuration = TradeData.ConfirmCountdownTime or 5
        local tLock = tick()
        while tick() - tLock < lockDuration do
            if not isTradeAlive() then
                if tradeResult == nil then
                    pcall(function() TradeData.Remotes.CancelTrade:InvokeServer() end)
                end
                cleanupConns()
                if tradeResult == nil then _tradeState.totalFailed += 1 end
                return tradeResult == true
            end
            task.wait(0.1)
        end
        if tradeResult ~= nil then
            cleanupConns()
            if tradeResult then
                _tradeState.totalSuccess   += 1
                _tradeState.totalItemsSent += #itemList
                _tradeState.lastTradedItem  = itemList[#itemList].Name
                _tradeState.coinTraded     += (totalCoinValue or 0)
                setStatus(("Success: %s - %d items sent (%d/%d)"):format(label, _tradeState.totalItemsSent, _tradeState.totalSuccess, _tradeState.targetAmount))
                updateMonitor(); task.wait(1.5)
                return true
            else
                _tradeState.totalFailed += 1
                setStatus(("Failed (cancel): %s"):format(label))
                updateMonitor(); task.wait(1)
                return false
            end
        end
        if not _tradeState.enabled then
            pcall(function() TradeData.Remotes.CancelTrade:InvokeServer() end)
            cleanupConns()
            return false
        end
        setStatus("Setting ready...")
        local readyOk, readyErr = pcall(function()
            TradeData.Remotes.SetReady:InvokeServer(true)
        end)
        if not readyOk then
            return failTrade("Error: SetReady gagal - " .. tostring(readyErr))
        end
        local t1 = tick()
        local playersReady = false
        while tick() - t1 < 15 do
            if not isTradeAlive() then break end
            if tradeResult ~= nil then break end
            local d = tradeReplion and not tradeReplion.Destroyed and tradeReplion.Data
            if d then
                if d.PlayersReady == true then
                    playersReady = true; break
                end
                if type(d.PlayersReady) == "table" then
                    local allReady = true
                    for _, v in pairs(d.PlayersReady) do
                        if not v then allReady = false; break end
                    end
                    if allReady then playersReady = true; break end
                end
            end
            task.wait(0.1)
        end
        if tradeResult ~= nil then
            cleanupConns()
            if tradeResult then
                _tradeState.totalSuccess   += 1
                _tradeState.totalItemsSent += #itemList
                _tradeState.lastTradedItem  = itemList[#itemList].Name
                _tradeState.coinTraded     += (totalCoinValue or 0)
                setStatus(("Success: %s - %d items sent (%d/%d)"):format(label, _tradeState.totalItemsSent, _tradeState.totalSuccess, _tradeState.targetAmount))
                updateMonitor(); task.wait(1.5)
                return true
            else
                _tradeState.totalFailed += 1
                setStatus(("Failed: %s"):format(label))
                updateMonitor(); task.wait(1)
                return false
            end
        end
        if not playersReady then
            return failTrade("Error: Lawan tidak ready")
        end
        setStatus("Confirming trade...")
        pcall(function() TradeData.Remotes.ConfirmTrade:InvokeServer() end)
        local t2 = tick()
        while tradeResult == nil and tick() - t2 < 10 do
            if not _tradeState.enabled then break end
            if tradeReplion and tradeReplion.Destroyed then break end
            task.wait(0.1)
        end
        cleanupConns()
        if tradeResult == true then
            _tradeState.totalSuccess   += 1
            _tradeState.totalItemsSent += #itemList
            _tradeState.lastTradedItem  = itemList[#itemList].Name
            _tradeState.coinTraded     += (totalCoinValue or 0)
            setStatus(("Success: %s - %d items sent (%d/%d)"):format(label, _tradeState.totalItemsSent, _tradeState.totalSuccess, _tradeState.targetAmount))
            updateMonitor(); task.wait(1.5)
            return true
        else
            _tradeState.totalFailed += 1
            setStatus(("Failed: %s"):format(label))
            updateMonitor(); task.wait(1)
            return false
        end
    end
    local function getFreshFishByName(name)
        local result = {}
        local inventory = Data:Get({"Inventory", "Items"})
        if not inventory or typeof(inventory) ~= "table" then return result end
        for _, item in ipairs(inventory) do
            if not item.Favorited then
                local d = ItemUtility:GetItemData(item.Id)
                if d and d.Data and d.Data.Type == "Fish" and d.Data.Name == name then
                    table.insert(result, { UUID=item.UUID, Type="Fish", Name=name, CoinValue=0 })
                end
            end
        end
        return result
    end
    local function getFreshFishByRarity(rarity)
        local result = {}
        local inventory = Data:Get({"Inventory", "Items"})
        if not inventory or typeof(inventory) ~= "table" then return result end
        for _, item in ipairs(inventory) do
            if not item.Favorited then
                local d = ItemUtility:GetItemData(item.Id)
                if d and d.Data and d.Data.Type == "Fish" then
                    if TIER_FISH[d.Data.Tier] == rarity then
                        table.insert(result, {
                            UUID=item.UUID,
                            Name=d.Data.Name or "Unknown",
                            Type=d.Data.Type,
                            CoinValue=0,
                        })
                    end
                end
            end
        end
        return result
    end
    local function runByName()
        local initialFish = getFreshFishByName(_tradeState.selectedItem)
        if #initialFish == 0 then setStatus("Error: Item tidak ada di inventory"); return end
        local total = math.min(_tradeState.itemAmount, #initialFish)
        _tradeState.targetAmount = math.ceil(total / MAX_ITEMS_PER_TRADE)
        local traded = 0
        while traded < total and _tradeState.enabled do
            local fresh = getFreshFishByName(_tradeState.selectedItem)
            if #fresh == 0 then setStatus("Error: Inventory habis"); break end
            local batchSize = math.min(MAX_ITEMS_PER_TRADE, total - traded, #fresh)
            local batch = {}
            for i = 1, batchSize do table.insert(batch, fresh[i]) end
            if #batch == 0 then break end
            setStatus(("Trade %d/%d - Sending %d item(s)..."):format(
                _tradeState.totalSuccess + 1, _tradeState.targetAmount, #batch
            ))
            local ok = executeTradeMulti(batch, 0)
            if ok then
                traded += #batch
                if traded < total and _tradeState.enabled then
                    setStatus(("Batch done (%d/%d traded). Waiting before next trade..."):format(traded, total))
                    task.wait(2)
                end
            else
                if not _tradeState.enabled then break end
                setStatus("Trade failed, retrying in 3s...")
                task.wait(3)
            end
        end
    end
    local function runByCoin()
        if _tradeState.targetCoins <= 0 then setStatus("Error: Target coins harus > 0"); return end
        local function getFreshBatchForCoins(maxCoins)
            local fishList = {}
            local ok, err = pcall(function()
                local inventory = Data:Get({"Inventory", "Items"})
                if not inventory or typeof(inventory) ~= "table" then return end
                local playerMods = nil
                pcall(function() playerMods = PlayerStatsUtility:GetPlayerModifiers(LP) end)
                for _, item in ipairs(inventory) do
                    if not item.Favorited then
                        local d = nil
                        pcall(function() d = ItemUtility:GetItemData(item.Id) end)
                        if d and d.Data and d.Data.Type == "Fish" then
                            local sellPrice = 0
                            pcall(function() sellPrice = VendorUtility:GetSellPrice(item) or d.SellPrice or 0 end)
                            if sellPrice == 0 then sellPrice = d.SellPrice or 0 end
                            local finalPrice = math.ceil(sellPrice * (playerMods and playerMods.CoinMultiplier or 1))
                            if finalPrice > 0 then
                                table.insert(fishList, {
                                    UUID=item.UUID, Name=d.Data.Name,
                                    Price=finalPrice, Type=d.Data.Type,
                                })
                            end
                        end
                    end
                end
            end)
            if not ok then return {}, 0 end
            if #fishList == 0 then return {}, 0 end
            table.sort(fishList, function(a, b) return a.Price < b.Price end)
            local selected = {}
            local totalValue = 0
            for _, fish in ipairs(fishList) do
                if #selected >= MAX_ITEMS_PER_TRADE then break end
                if totalValue >= maxCoins then break end
                table.insert(selected, { UUID=fish.UUID, Type=fish.Type, Name=fish.Name, CoinValue=fish.Price })
                totalValue += fish.Price
            end
            return selected, totalValue
        end
        local ok, initialBatch, initialValue = pcall(getFreshBatchForCoins, _tradeState.targetCoins)
        if not ok or not initialBatch then
            setStatus("Error: Gagal baca inventory - " .. tostring(initialBatch or "unknown"))
            return
        end
        if #initialBatch == 0 then setStatus("Error: Tidak ada ikan di inventory"); return end
        _tradeState.targetAmount = math.max(1, math.ceil(#initialBatch / MAX_ITEMS_PER_TRADE))
        local remainingCoins = _tradeState.targetCoins
        setStatus(("Starting ByCoin: target ~%d coins (~%d available)"):format(
            _tradeState.targetCoins, initialValue
        ))
        while remainingCoins > 0 and _tradeState.enabled do
            local callOk, batch, batchValue = pcall(getFreshBatchForCoins, remainingCoins)
            if not callOk or not batch then
                setStatus("Error: Gagal baca inventory - " .. tostring(batch or "unknown"))
                break
            end
            if #batch == 0 then setStatus("Error: Inventory habis"); break end
            setStatus(("Trade %d - Sending %d item(s) ~%d coins..."):format(
                _tradeState.totalSuccess + 1, #batch, batchValue
            ))
            local ok = executeTradeMulti(batch, batchValue)
            if ok then
                remainingCoins -= batchValue
                if remainingCoins > 0 and _tradeState.enabled then
                    setStatus(("Batch done (~%d coins remaining). Waiting..."):format(math.max(0, remainingCoins)))
                    task.wait(2)
                end
            else
                if not _tradeState.enabled then break end
                setStatus("Trade failed, retrying in 3s...")
                task.wait(3)
            end
        end
    end

    local function runByRarity()
        local initialFish = getFreshFishByRarity(_tradeState.selectedRarity)
        if #initialFish == 0 then
            setStatus("Error: Tidak ada ikan rarity " .. _tradeState.selectedRarity); return
        end
        local total = math.min(_tradeState.rarityAmount, #initialFish)
        _tradeState.targetAmount = math.ceil(total / MAX_ITEMS_PER_TRADE)
        local traded = 0
        while traded < total and _tradeState.enabled do
            local fresh = getFreshFishByRarity(_tradeState.selectedRarity)
            if #fresh == 0 then
                setStatus("Error: Inventory habis / tidak ada lagi ikan " .. _tradeState.selectedRarity); break
            end
            local remaining  = total - traded
            local batchSize  = math.min(MAX_ITEMS_PER_TRADE, remaining, #fresh)
            local batch = {}
            for i = 1, batchSize do
                table.insert(batch, { UUID=fresh[i].UUID, Type=fresh[i].Type, Name=fresh[i].Name, CoinValue=0 })
            end
            if #batch == 0 then break end
            setStatus(("Trade %d/%d - Sending %d item(s)..."):format(
                _tradeState.totalSuccess + 1, _tradeState.targetAmount, #batch
            ))
            local ok = executeTradeMulti(batch, 0)
            if ok then
                traded += #batch
                if traded < total and _tradeState.enabled then
                    setStatus(("Batch done (%d/%d traded). Waiting before next trade..."):format(traded, total))
                    task.wait(2)
                end
            else
                if not _tradeState.enabled then break end
                setStatus("Trade failed, retrying in 3s...")
                task.wait(3)
            end
        end
    end

    local function runByEnchantStone()
        local stoneItemId = ENCHANT_STONE_IDS[_tradeState.selectedStoneType]
        if not stoneItemId then setStatus("Error: Stone type tidak valid"); return end
        local stoneName = _tradeState.selectedStoneType .. " Enchant Stone"
        local stoneType = "Enchant Stones"
        pcall(function()
            local inventory = Data:GetExpect({"Inventory", "Items"})
            for _, item in ipairs(inventory) do
                if item.Id == stoneItemId then
                    local d = ItemUtility:GetItemData(item.Id)
                    if d then
                        stoneName = d.Data.Name or stoneName
                        stoneType = d.Data.Type or "Enchant Stones"
                    end
                    break
                end
            end
        end)
        local total = _tradeState.stoneAmount
        _tradeState.targetAmount = math.ceil(total / MAX_ITEMS_PER_TRADE)
        setStatus(("Starting EnchantStone: %s x%d"):format(stoneName, total))
        local traded = 0
        while traded < total and _tradeState.enabled do
            local availableUUIDs = {}
            pcall(function()
                local inventory = Data:GetExpect({"Inventory", "Items"})
                for _, item in ipairs(inventory) do
                    if item.Id == stoneItemId then
                        table.insert(availableUUIDs, item.UUID)
                    end
                end
            end)
            if #availableUUIDs == 0 then
                setStatus("Error: Tidak ada lagi " .. stoneName .. " di inventory")
                break
            end
            local remaining = total - traded
            local batchSize = math.min(MAX_ITEMS_PER_TRADE, remaining, #availableUUIDs)
            local batch = {}
            for i = 1, batchSize do
                table.insert(batch, { UUID = availableUUIDs[i], Type = stoneType, Name = stoneName, CoinValue = 0 })
            end
            setStatus(("Trade %d/%d - Sending %d item(s)..."):format(
                _tradeState.totalSuccess + 1, _tradeState.targetAmount, #batch
            ))
            local ok = executeTradeMulti(batch, 0)
            if ok then
                traded += #batch
                if traded < total and _tradeState.enabled then
                    setStatus(("Batch done (%d/%d traded). Waiting before next trade..."):format(traded, total))
                    task.wait(2)
                end
            else
                if not _tradeState.enabled then break end
                setStatus("Trade failed, retrying in 3s...")
                task.wait(3)
            end
        end
    end

    local function startTrade()
        if _tradeState.enabled then
            _tradeState.enabled = false
            pcall(function() TradeData.Remotes.CancelTrade:InvokeServer() end)
            if _activeToggleRef and _activeToggleRef.SetValue then
                pcall(function() _activeToggleRef:SetValue(false) end)
            end
            task.wait(1.5)
        end
        if not _tradeState.targetPlayer or not _tradeState.playerManuallySelected then
            setStatus("Error: Target player belum dipilih"); return
        end
        if not Players:FindFirstChild(_tradeState.targetPlayer) then
            setStatus("Error: Target player tidak ditemukan"); return
        end
        _tradeState.enabled        = true
        _tradeState.totalAttempted = 0
        _tradeState.totalSuccess   = 0
        _tradeState.totalFailed    = 0
        _tradeState.targetAmount   = 0
        _tradeState.status         = "Starting..."
        _tradeState.lastTradedItem = ""
        _tradeState.coinTraded     = 0
        _tradeState.totalItemsSent = 0
        updateMonitor()
        _tradeState.task = task.spawn(function()
            if     _tradeState.tradeMode == "ByName"         then runByName()
            elseif _tradeState.tradeMode == "ByCoin"         then runByCoin()
            elseif _tradeState.tradeMode == "ByRarity"       then runByRarity()
            elseif _tradeState.tradeMode == "ByEnchantStone" then runByEnchantStone()
            end
            if _tradeState.enabled then
                _tradeState.enabled = false
                if _tradeState.totalAttempted == 0 and _tradeState.totalSuccess == 0 then
                    setStatus("Completed: No trades executed")
                else
                    setStatus(("Completed! %d/%d sukses | %d items sent"):format(
                        _tradeState.totalSuccess, _tradeState.targetAmount,
                        _tradeState.totalItemsSent
                    ))
                end
                if _activeToggleRef and _activeToggleRef.SetValue then
                    pcall(function() _activeToggleRef:SetValue(false) end)
                end
            else
                setStatus(("Stopped: %d/%d sukses | %d items sent"):format(
                    _tradeState.totalSuccess, _tradeState.targetAmount,
                    _tradeState.totalItemsSent
                ))
            end
        end)
    end
    local function stopTrade()
        if not _tradeState.enabled then return end
        _tradeState.enabled = false
        pcall(function() TradeData.Remotes.CancelTrade:InvokeServer() end)
        setStatus(("Stopped: %d/%d sukses | %d items sent"):format(
            _tradeState.totalSuccess, _tradeState.targetAmount,
            _tradeState.totalItemsSent
        ))
    end
    local function resetStats(paragraphRef)
        _tradeState.totalAttempted = 0
        _tradeState.totalSuccess   = 0
        _tradeState.totalFailed    = 0
        _tradeState.targetAmount   = 0
        _tradeState.status         = "Idle"
        _tradeState.lastTradedItem = ""
        _tradeState.coinTraded     = 0
        _tradeState.totalItemsSent = 0
        if paragraphRef and paragraphRef.SetContent then
            pcall(function() paragraphRef:SetContent("Idle") end)
        end
    end

    local PlayerSection = TradeTab:AddSection("Select Player", false)
    local _playerDropdown = PlayerSection:AddDropdown({
        Title    = "Target Player",
        Options  = {},
        Default  = nil,
        NoSave   = true,
        Callback = function(value)
            _tradeState.targetPlayer           = value
            _tradeState.playerManuallySelected = true
        end,
    })

    PlayerSection:AddButton({
        Title    = "Refresh Players",
        Callback = function()
            local list = {}
            for _, p in ipairs(Players:GetPlayers()) do
                if p ~= LP then table.insert(list, p.Name) end
            end
            if _playerDropdown and _playerDropdown.SetOptions then
                _playerDropdown:SetOptions(list)
            end
        end,
    })

    local ByNameSection = TradeTab:AddSection("Trade By Name", false)
    local ByNameMonitor = ByNameSection:AddParagraph({
        Title   = "Status",
        Content = "Idle",
    })

    local _itemDropdown = ByNameSection:AddDropdown({
        Title    = "Select Item",
        Options  = {},
        Default  = nil,
        Callback = function(value)
            if value then
                _tradeState.selectedItem = value:match("^(.-) x") or value
            end
        end,
    })

    ByNameSection:AddButton({
        Title    = "Refresh Fish Items",
        Callback = function()
            if not Data then return end
            local grouped = {}
            pcall(function()
                local inventory = Data:GetExpect({"Inventory", "Items"})
                for _, item in ipairs(inventory) do
                    if not item.Favorited then
                        local d = ItemUtility:GetItemData(item.Id)
                        if d and d.Data and d.Data.Type == "Fish" then
                            local name = d.Data.Name
                            grouped[name] = (grouped[name] or 0) + 1
                        end
                    end
                end
            end)
            local display = {}
            for name, count in pairs(grouped) do
                table.insert(display, ("%s x%d"):format(name, count))
            end
            if _itemDropdown and _itemDropdown.SetOptions then
                _itemDropdown:SetOptions(display)
            end
        end,
    })

    ByNameSection:AddInput({
        Title    = "Amount Fish Name",
        Default  = "1",
        Callback = function(value)
            _tradeState.itemAmount = tonumber(value) or 1
        end,
    })

    local _byNameToggle
    _byNameToggle = ByNameSection:AddToggle({
        Title    = "Start Trade ByName",
        Default  = false,
        NoSave   = true,
        Callback = function(on)
            if on then
                _activeMonitorParagraph = ByNameMonitor
                _activeToggleRef        = _byNameToggle
                _tradeState.tradeMode   = "ByName"
                startTrade()
            else
                stopTrade()
            end
        end,
    })

    ByNameSection:AddButton({
        Title    = "Reset Stats By Name",
        Callback = function() resetStats(ByNameMonitor) end,
    })

    local ByCoinSection = TradeTab:AddSection("Trade By Coin", false)
    local ByCoinMonitor = ByCoinSection:AddParagraph({
        Title   = "Status",
        Content = "Idle",
    })

    ByCoinSection:AddInput({
        Title    = "Target Coins",
        Default  = "0",
        Callback = function(value)
            _tradeState.targetCoins = tonumber(value) or 0
        end,
    })

    local _byCoinToggle
    _byCoinToggle = ByCoinSection:AddToggle({
        Title    = "Start Trade ByCoin",
        Default  = false,
        NoSave   = true,
        Callback = function(on)
            if on then
                _activeMonitorParagraph = ByCoinMonitor
                _activeToggleRef        = _byCoinToggle
                _tradeState.tradeMode   = "ByCoin"
                startTrade()
            else
                stopTrade()
            end
        end,
    })

    ByCoinSection:AddButton({
        Title    = "Reset Stats By Coin",
        Callback = function() resetStats(ByCoinMonitor) end,
    })

    local ByRaritySection = TradeTab:AddSection("Trade By Rarity", false)
    local ByRarityMonitor = ByRaritySection:AddParagraph({
        Title   = "Status",
        Content = "Idle",
    })

    ByRaritySection:AddDropdown({
        Title    = "Select Rarity",
        Options  = { "Common","Uncommon","Rare","Epic","Legendary","Mythic","Secret" },
        Default  = "Common",
        Callback = function(value)
            _tradeState.selectedRarity = value
        end,
    })

    ByRaritySection:AddInput({
        Title    = "Amount Fish Rarity",
        Default  = "1",
        Callback = function(value)
            _tradeState.rarityAmount = tonumber(value) or 1
        end,
    })

    local _byRarityToggle
    _byRarityToggle = ByRaritySection:AddToggle({
        Title    = "Start Trade ByRarity",
        Default  = false,
        NoSave   = true,
        Callback = function(on)
            if on then
                _activeMonitorParagraph = ByRarityMonitor
                _activeToggleRef        = _byRarityToggle
                _tradeState.tradeMode   = "ByRarity"
                startTrade()
            else
                stopTrade()
            end
        end,
    })

    ByRaritySection:AddButton({
        Title    = "Reset Stats By Rarity",
        Callback = function() resetStats(ByRarityMonitor) end,
    })

    local ByStoneSection = TradeTab:AddSection("Trade Enchant Stone", false)
    local ByStoneMonitor = ByStoneSection:AddParagraph({
        Title   = "Status",
        Content = "Idle",
    })

    ByStoneSection:AddDropdown({
        Title    = "Stone Type",
        Options  = { "Normal", "Double", "Evolved", "EggyEnchantStone", "Runic" },
        Default  = "Normal",
        Callback = function(value)
            _tradeState.selectedStoneType = value
        end,
    })

    ByStoneSection:AddInput({
        Title    = "Amount Enchant Stone",
        Default  = "1",
        Callback = function(value)
            _tradeState.stoneAmount = tonumber(value) or 1
        end,
    })

    ByStoneSection:AddButton({
        Title    = "Check Enchant Stones",
        Callback = function()
            if not Data then return end
            local display = {}
            pcall(function()
                local inventory = Data:Get({"Inventory", "Items"})
                if not inventory or typeof(inventory) ~= "table" then return end
                for stoneType, stoneId in pairs(ENCHANT_STONE_IDS) do
                    local count = 0
                    for _, item in ipairs(inventory) do
                        if item.Id == stoneId then count += 1 end
                    end
                    if count > 0 then
                        table.insert(display, ("%s x%d"):format(stoneType, count))
                    end
                end
            end)
            table.sort(display)
            ByStoneMonitor:SetContent(
                #display > 0
                and ("Inventory:\n" .. table.concat(display, "\n"))
                or "No enchant stones found"
            )
        end,
    })

    local _byStoneToggle
    _byStoneToggle = ByStoneSection:AddToggle({
        Title    = "Start Trade EnchantStone",
        Default  = false,
        NoSave   = true,
        Callback = function(on)
            if on then
                _activeMonitorParagraph = ByStoneMonitor
                _activeToggleRef        = _byStoneToggle
                _tradeState.tradeMode   = "ByEnchantStone"
                startTrade()
            else
                stopTrade()
            end
        end,
    })
    ByStoneSection:AddButton({
        Title    = "Reset Stats Enchant Stone",
        Callback = function() resetStats(ByStoneMonitor) end,
    })

    local AcceptSection = TradeTab:AddSection("Auto Accept Trade", false)
    local _acceptState = {
        enabled     = false,
        hooked      = false,
        connections = {},
        origFire    = nil,
    }
    AcceptSection:AddParagraph({
        Title   = "Info",
        Content = "Hook ke PromptController.\nOtomatis accept semua trade request masuk tanpa klik.",
    })
    AcceptSection:AddToggle({
        Title    = "Enable Auto Accept Trade",
        Default  = false,
        NoSave   = true,
        Callback = function(on)
            if on then
                if _acceptState.enabled then return end
                if not _acceptState.hooked then
                    pcall(function()
                        local ctrl = require(ReplicatedStorage.Controllers.PromptController)
                        _acceptState.origFire = ctrl.FirePrompt
                        ctrl.FirePrompt = function(self, message, ...)
                            if _acceptState.enabled then
                                local msg = tostring(message or ""):lower()
                                if msg:find("trade request") or msg:find("do you want to accept") then
                                    local Promise = require(ReplicatedStorage.Packages.Promise)
                                    return Promise.resolve(true)
                                end
                            end
                            return _acceptState.origFire(self, message, ...)
                        end
                        _acceptState.hooked = true
                    end)
                end
                _acceptState.enabled = true
                local conn = TradeData.Remotes.TradeStarted.OnClientEvent:Connect(function(replionId)
                    if not _acceptState.enabled then return end
                    task.spawn(function()
                        task.wait(0.5)
                        if not Replion or not Replion.Client then return end
                        local tradeReplion = Replion.Client:GetReplion(replionId)
                        if not tradeReplion then return end
                        local lockDuration = TradeData.ConfirmCountdownTime or 5
                        while _acceptState.enabled and not tradeReplion.Destroyed do
                            local d1 = tick() + 120
                            while tick() < d1 do
                                if not _acceptState.enabled or tradeReplion.Destroyed then return end
                                local lmt = tradeReplion.Data and tradeReplion.Data.LastModifiedTime
                                if lmt and lmt > 0 then break end
                                task.wait(0.2)
                            end
                            if not _acceptState.enabled or tradeReplion.Destroyed then return end
                            local lastSeen, stableStart = nil, nil
                            local d2 = tick() + 120
                            while tick() < d2 do
                                if not _acceptState.enabled or tradeReplion.Destroyed then return end
                                local current = tradeReplion.Data and tradeReplion.Data.LastModifiedTime
                                if current ~= lastSeen then
                                    lastSeen = current; stableStart = tick()
                                elseif stableStart and (tick() - stableStart) >= 0.5 then
                                    break
                                end
                                task.wait(0.1)
                            end
                            if not _acceptState.enabled or tradeReplion.Destroyed then return end
                            local d3 = tick() + 30
                            while tick() < d3 do
                                if not _acceptState.enabled or tradeReplion.Destroyed then return end
                                local data = tradeReplion.Data
                                if not data or not data.LastModifiedTime then break end
                                local remaining = data.LastModifiedTime + lockDuration - workspace:GetServerTimeNow()
                                if remaining <= 0 then break end
                                task.wait(0.05)
                            end
                            if not _acceptState.enabled or tradeReplion.Destroyed then return end
                            local readyOk = false
                            for _ = 1, 10 do
                                if not _acceptState.enabled or tradeReplion.Destroyed then return end
                                local s, r = pcall(function()
                                    return TradeData.Remotes.SetReady:InvokeServer(true)
                                end)
                                if s and r then readyOk = true; break end
                                task.wait(0.3)
                            end
                            if not readyOk then return end
                            local lmtBeforeReady = tradeReplion.Data and tradeReplion.Data.LastModifiedTime
                            local itemsChanged = false
                            local d4 = tick() + 30
                            while tick() < d4 do
                                if not _acceptState.enabled or tradeReplion.Destroyed then return end
                                local data = tradeReplion.Data
                                local currentLmt = data and data.LastModifiedTime
                                if currentLmt and currentLmt ~= lmtBeforeReady then
                                    itemsChanged = true
                                    break
                                end
                                if data then
                                    if data.PlayersReady == true then break end
                                    if type(data.PlayersReady) == "table" then
                                        local allReady = true
                                        for _, v in pairs(data.PlayersReady) do
                                            if not v then allReady = false; break end
                                        end
                                        if allReady then break end
                                    end
                                end
                                task.wait(0.1)
                            end
                            if itemsChanged then
                                task.wait(0.3)
                                continue
                            end
                            if not _acceptState.enabled or tradeReplion.Destroyed then return end
                            local data = tradeReplion.Data
                            local isPlayersReady = false
                            if data then
                                if data.PlayersReady == true then
                                    isPlayersReady = true
                                elseif type(data.PlayersReady) == "table" then
                                    isPlayersReady = true
                                    for _, v in pairs(data.PlayersReady) do
                                        if not v then isPlayersReady = false; break end
                                    end
                                end
                            end
                            if not isPlayersReady then return end
                            pcall(function() TradeData.Remotes.ConfirmTrade:InvokeServer() end)
                            break
                        end
                    end)
                end)
                table.insert(_acceptState.connections, conn)
                Library:MakeNotify({
                    Title       = "Auto Accept Trade",
                    Description = "Auto Accept Trade dimulai",
                    Delay       = 2,
                })
            else
                _acceptState.enabled = false
                if _acceptState.hooked then
                    pcall(function()
                        local ctrl = require(ReplicatedStorage.Controllers.PromptController)
                        if _acceptState.origFire then
                            ctrl.FirePrompt = _acceptState.origFire
                        end
                    end)
                    _acceptState.origFire = nil
                    _acceptState.hooked   = false
                end
                for _, c in ipairs(_acceptState.connections) do
                    c:Disconnect()
                end
                _acceptState.connections = {}
                Library:MakeNotify({
                    Title       = "Auto Accept Trade",
                    Description = "Auto Accept Trade dihentikan",
                    Delay       = 2,
                })
            end
        end,
    })
end

-- [Webhook Tab]
do
    local _httpFnCache = nil
    local function getHTTP()
        if _httpFnCache then return _httpFnCache end
        local candidates = { "request", "http_request" }
        for _, name in ipairs(candidates) do
            local f = rawget(getfenv and getfenv(0) or _G, name)
                   or rawget(getgenv and getgenv() or {}, name)
            if type(f) == "function" then _httpFnCache = f; return f end
        end
        local tables = { syn, fluxus, solara, http }
        for _, tbl in ipairs(tables) do
            if type(tbl) == "table" and type(tbl.request) == "function" then
                _httpFnCache = tbl.request; return tbl.request
            end
        end
        return nil
    end

    local HttpService = game:GetService("HttpService")
    local function encodePayload(payload)
        -- Add allowed_mentions if content has mentions
        if payload.content and payload.content:find("<@%d+>") then
            payload.allowed_mentions = payload.allowed_mentions or { parse = {"users"} }
        end
        local json = HttpService:JSONEncode(payload)
        return json
    end
    local function cleanStr(v)
        return tostring(v):gsub("^%s*(.-)%s*$", "%1")
    end
    local function cleanId(v)
        if type(v) == "number" then
            return string.format("%.0f", v)
        end
        return tostring(v):gsub("%D", ""):gsub("^%s*(.-)%s*$", "%1")
    end

    local _webhookQueue = {}
    local _webhookProcessing = false
    local _webhookMinInterval = 1.5

    local function processWebhookQueue()
        if _webhookProcessing then return end
        _webhookProcessing = true
        task.spawn(function()
            while #_webhookQueue > 0 do
                local entry = table.remove(_webhookQueue, 1)
                if entry then
                    pcall(function()
                        local httpFn = getHTTP()
                        if httpFn and entry.url and entry.url ~= "" then
                            httpFn({
                                Url     = entry.url,
                                Method  = "POST",
                                Headers = { ["Content-Type"] = "application/json" },
                                Body    = encodePayload(entry.payload),
                            })
                        end
                    end)
                    if #_webhookQueue > 0 then
                        task.wait(_webhookMinInterval)
                    end
                end
            end
            _webhookProcessing = false
        end)
    end

    local function queueWebhook(url, payload)
        if not url or url == "" then return false end
        if not getHTTP() then return false end
        table.insert(_webhookQueue, { url = url, payload = payload })
        processWebhookQueue()
        return true
    end

    local function sendHTTP(url, payload)
        local httpFn = getHTTP()
        if not httpFn or not url or url == "" then return false end
        local ok, err = pcall(function()
            httpFn({
                Url     = url,
                Method  = "POST",
                Headers = { ["Content-Type"] = "application/json" },
                Body    = encodePayload(payload),
            })
        end)
        if not ok then warn("[Webhook] Failed to send request:", err) end
        return ok
    end

    local AVATAR_URL  = "https://raw.githubusercontent.com/habibrodriguez7-art/kontol/refs/heads/main/majesticons--planet-ring-2.png"
    local BOT_NAME    = "Lynx"
    local TIER_NAMES  = { [1]="Common",[2]="Uncommon",[3]="Rare",[4]="Epic",[5]="Legendary",[6]="Mythic",[7]="SECRET",[8]="FORGOTTEN" }
    local TIER_COLORS = { [1]=9807270,[2]=3066993,[3]=3447003,[4]=10181046,[5]=15844367,[6]=16711680,[7]=65535,[8]=8355711 }

    local function formatPrice(n)
        return tostring(math.floor(n)):reverse():gsub("(%d%d%d)", "%1,"):reverse():gsub("^,", "")
    end

    local Items, Variants
    local _itemsLoading = false
    local function loadItems()
        if Items and Variants then return true end
        if _itemsLoading then return false end
        _itemsLoading = true
        local ok = pcall(function()
            local itemsMod = ReplicatedStorage:FindFirstChild("Items")
            local variantsMod = ReplicatedStorage:FindFirstChild("Variants")
            if itemsMod then Items = require(itemsMod) end
            if variantsMod then Variants = require(variantsMod) end
        end)
        _itemsLoading = false
        return ok and Items ~= nil
    end

    local function getFish(itemId)
        if not Items then loadItems() end
        if not Items then return nil end
        for _, f in pairs(Items) do
            if f.Data and f.Data.Id == itemId then return f end
        end
        return nil
    end

    local function getVariant(id)
        if not Variants then return nil end
        local idStr = tostring(id)
        for _, v in pairs(Variants) do
            if v.Data and (tostring(v.Data.Id) == idStr or tostring(v.Data.Name) == idStr) then return v end
        end
        return nil
    end

    local _imageUrlCache = {}
    local function getDiscordImageUrl(assetId)
        if not assetId then return nil end
        local cacheKey = tostring(assetId)
        if _imageUrlCache[cacheKey] ~= nil then
            return _imageUrlCache[cacheKey]
        end
        local httpFn = getHTTP()
        if not httpFn then return nil end
        local success, result = pcall(function()
            local response = httpFn({
                Url    = string.format("https://thumbnails.roblox.com/v1/assets?assetIds=%s&returnPolicy=PlaceHolder&size=420x420&format=Png&isCircular=false", cacheKey),
                Method = "GET",
            })
            if response and response.Body then
                local data = game:GetService("HttpService"):JSONDecode(response.Body)
                if data and data.data and data.data[1] then return data.data[1].imageUrl end
            end
        end)
        local url = (success and result) or nil
        _imageUrlCache[cacheKey] = url or false
        return url
    end

    local function getFishImageUrl(fish)
        if not fish or not fish.Data then return "https://i.imgur.com/UMWNYK7.png" end
        local assetId = nil
        if     fish.Data.Icon    then assetId = tostring(fish.Data.Icon):match("%d+")
        elseif fish.Data.ImageId then assetId = tostring(fish.Data.ImageId)
        elseif fish.Data.Image   then assetId = tostring(fish.Data.Image):match("%d+")
        end
        if assetId then local url = getDiscordImageUrl(assetId); if url then return url end end
        return "https://i.imgur.com/UMWNYK7.png"
    end

    local WebhookTab = MainWindow:AddTab({ Name = "Webhook", Icon = "send" })

    local FishSection = WebhookTab:AddSection("Fish Caught Webhook")
    local _fishState  = { url = "", id = "", hide = "", rarities = {}, filterNames = {}, filterVariants = {}, running = false, conn = nil }
    local _fishDebounce = {}
    local FISH_DEBOUNCE_TIME = 0.5
    local _fishDebounceCleanup = 0
    local FISH_DEBOUNCE_CLEANUP_INTERVAL = 30

    FishSection:AddInput({
        Title       = "Webhook URL (Fish)",
        Default     = "",
        Placeholder = "https://discord.com/api/webhooks/...",
        Callback    = function(value) _fishState.url = cleanStr(value) end,
    })
    FishSection:AddInput({
        Title       = "Discord User ID (Fish)",
        Default     = "",
        Placeholder = "123456789012345678",
        Callback    = function(value)
            _fishState.id = cleanId(value)
        end,
    })
    FishSection:AddInput({
        Title       = "Hide Identity (Fish)",
        Default     = "",
        Placeholder = "Enter custom name...",
        Callback    = function(value) _fishState.hide = cleanStr(value) end,
    })
    FishSection:AddParagraph({
        Title   = "Filter Logic (AND)",
        Content = "All active filters work as AND.\n\n" ..
                "• Name only          → fish matches name\n" ..
                "• Rarity only        → fish matches rarity\n" ..
                "• Variant only       → fish matches variant\n" ..
                "• Name + Rarity      → fish matches name AND rarity\n" ..
                "• Name + Variant     → fish matches name AND variant\n" ..
                "• Rarity + Variant   → fish matches rarity AND variant\n" ..
                "• Name+Rarity+Variant → fish matches all three\n\n" ..
                "Empty filters are ignored.\n" ..
                "Example: Mythic + Corrupt → only Mythic fish with Corrupt variant.",
    })
    FishSection:AddDropdown({
        Title    = "Rarity Filter (empty = all)",
        Options  = { "Common", "Uncommon", "Rare", "Epic", "Legendary", "Mythic", "SECRET", "FORGOTTEN" },
        Multi    = true,
        Default  = {},
        Callback = function(selected)
            _fishState.rarities = type(selected) == "table" and selected or {}
        end,
    })

    local _whFishList = {}
    local _whVariantList = {}
    local _whListsBuilt = false
    local function _buildWhFilterLists()
        if _whListsBuilt then return end
        _whListsBuilt = true
        pcall(function()
            local itemsFolder = ReplicatedStorage:FindFirstChild("Items")
            if not itemsFolder then return end
            local function scanFolder(folder)
                for _, child in ipairs(folder:GetChildren()) do
                    if child:IsA("ModuleScript") then
                        local ok2, data = pcall(require, child)
                        if ok2 and data and data.Data then
                            local name = data.Data.DisplayName or data.Data.Name
                            if name and not table.find(_whFishList, name) then
                                _whFishList[#_whFishList + 1] = name
                            end
                        end
                    elseif child:IsA("Folder") then
                        scanFolder(child)
                    end
                end
            end
            scanFolder(itemsFolder)
        end)
        table.sort(_whFishList)
        pcall(function()
            local variantsFolder = ReplicatedStorage:FindFirstChild("Variants")
            if not variantsFolder then return end
            for _, m in ipairs(variantsFolder:GetChildren()) do
                if m:IsA("ModuleScript") and m.Name ~= "1x1x1x1" and not table.find(_whVariantList, m.Name) then
                    _whVariantList[#_whVariantList + 1] = m.Name
                end
            end
        end)
        table.sort(_whVariantList)
    end

    local _whNameDropdown = FishSection:AddDropdown({
        Title    = "Name Filter (empty = all)",
        Options  = _whFishList,
        Multi    = true,
        Default  = {},
        Callback = function(selected)
            if type(selected) == "table" then
                local set = {}
                for _, v in ipairs(selected) do set[v] = true end
                _fishState.filterNames = set
            else
                _fishState.filterNames = {}
            end
        end,
    })
    local _whVariantDropdown = FishSection:AddDropdown({
        Title    = "Variant Filter (empty = all)",
        Options  = _whVariantList,
        Multi    = true,
        Default  = {},
        Callback = function(selected)
            if type(selected) == "table" then
                local set = {}
                for _, v in ipairs(selected) do set[v] = true end
                _fishState.filterVariants = set
            else
                _fishState.filterVariants = {}
            end
        end,
    })

    task.spawn(function()
        task.wait(3)
        _buildWhFilterLists()
        local savedNames = _G.GetConfigValue and _G.GetConfigValue("MultiDropdowns.Name_Filter_(empty_=_all)", {}) or {}
        local savedVariants = _G.GetConfigValue and _G.GetConfigValue("MultiDropdowns.Variant_Filter_(empty_=_all)", {}) or {}
        if type(savedNames) ~= "table" then savedNames = {} end
        if type(savedVariants) ~= "table" then savedVariants = {} end
        if _whNameDropdown and _whNameDropdown.SetOptions then
            _whNameDropdown:SetOptions(_whFishList)
        end
        if _whVariantDropdown and _whVariantDropdown.SetOptions then
            _whVariantDropdown:SetOptions(_whVariantList)
        end
        task.wait(0.1)
        if #savedNames > 0 then
            local nameFlag = Library.flags and Library.flags["Name_Filter_(empty_=_all)"]
            if nameFlag and nameFlag.Set then nameFlag:Set(savedNames) end
            local set = {}
            for _, v in ipairs(savedNames) do set[v] = true end
            _fishState.filterNames = set
        end
        if #savedVariants > 0 then
            local variantFlag = Library.flags and Library.flags["Variant_Filter_(empty_=_all)"]
            if variantFlag and variantFlag.Set then variantFlag:Set(savedVariants) end
            local set = {}
            for _, v in ipairs(savedVariants) do set[v] = true end
            _fishState.filterVariants = set
        end
    end)

    FishSection:AddToggle({
        Title    = "Enable Fish Webhook",
        Default  = false,
        Callback = function(on)
            if on then
                if _fishState.running then return end
                if _fishState.url == "" then warn("[Webhook] Fish URL is not set!"); return end
                if not getHTTP() then warn("[Webhook] Executor does not support HTTP requests!"); return end
                task.spawn(loadItems)
                task.spawn(_buildWhFilterLists)
                local re = NetEvents.RE_ObtainedNewFishNotification
                if not re then warn("[Webhook] Event not found!"); return end
                _fishState.running = true
                _fishState.conn    = re.OnClientEvent:Connect(function(itemId, metadata, extraData)
                    local now = tick()
                    if _fishDebounce[itemId] and (now - _fishDebounce[itemId]) < FISH_DEBOUNCE_TIME then return end
                    _fishDebounce[itemId] = now
                    if now - _fishDebounceCleanup > FISH_DEBOUNCE_CLEANUP_INTERVAL then
                        _fishDebounceCleanup = now
                        for k, t in pairs(_fishDebounce) do
                            if now - t > 10 then _fishDebounce[k] = nil end
                        end
                    end
                    task.spawn(function()
                        if not Items then
                            local t0 = tick()
                            while not Items and tick() - t0 < 3 do task.wait(0.3) end
                            if not Items then pcall(loadItems) end
                        end
                        local fish = getFish(itemId)
                        if not fish then return end
                        local meta  = metadata  or {}
                        local extra = extraData  or {}
                        local tier  = TIER_NAMES[fish.Data and fish.Data.Tier]  or "Unknown"
                        local color = TIER_COLORS[fish.Data and fish.Data.Tier] or 3447003
                        local filter = _fishState.rarities
                        local hasRarityFilter  = filter and next(filter)
                        local hasNameFilter    = next(_fishState.filterNames) ~= nil
                        local hasVariantFilter = next(_fishState.filterVariants) ~= nil
                        local rarityOk  = true
                        local nameOk    = true
                        local variantOk = true
                        if hasRarityFilter then
                            rarityOk = false
                            for _, v in ipairs(filter) do if v == tier then rarityOk = true; break end end
                        end
                        if hasNameFilter then
                            local fn = (fish.Data and (fish.Data.DisplayName or fish.Data.Name)) or ""
                            nameOk = _fishState.filterNames[fn] == true
                        end
                        local needVariantCheck = hasVariantFilter
                        if not rarityOk or not nameOk then return end
                        local variantId  = extra.Variant or extra.Mutation or extra.VariantId
                                        or meta.Variant  or meta.Mutation  or meta.VariantId
                        local isShiny    = meta.Shiny or extra.Shiny
                        local mutText    = "None"
                        local finalPrice = fish.SellPrice or 0
                        if isShiny then mutText = "Shiny"; finalPrice = finalPrice * 2 end
                        if variantId then
                            local v = getVariant(variantId)
                            if v then
                                local variantName = v.Data and v.Data.Name or tostring(variantId)
                                mutText    = variantName .. " (" .. tostring(v.SellMultiplier or "?") .. "x)"
                                finalPrice = finalPrice * (v.SellMultiplier or 1)
                                if needVariantCheck then
                                    variantOk = _fishState.filterVariants[variantName] == true
                                            or _fishState.filterVariants[tostring(variantId)] == true
                                end
                            else
                                mutText = tostring(variantId)
                                if needVariantCheck then
                                    variantOk = _fishState.filterVariants[tostring(variantId)] == true
                                end
                            end
                        else
                            if needVariantCheck then variantOk = false end
                        end
                        if not variantOk then return end
                        local playerName = (_fishState.hide ~= "") and _fishState.hide
                                        or (LocalPlayer.DisplayName or LocalPlayer.Name)
                        local fishName   = (fish.Data and (fish.Data.Name or fish.Data.DisplayName)) or "Unknown"
                        local cleanId    = _fishState.id
                        
                        -- Create mention - Discord will show "unknown user" if bot not in server
                        -- But notification will still work!
                        local mention    = (cleanId ~= "" and #cleanId >= 17) and ("<@" .. cleanId .. ">") or ""
                        local content_text = mention ~= "" and (mention .. " New fish caught!") or "New fish caught!"
                        
                        local payload = {
                            content          = content_text,
                            username         = BOT_NAME,
                            avatar_url       = AVATAR_URL,
                            embeds = {{
                                author      = { name = BOT_NAME .. " Webhook | Fish Caught", icon_url = AVATAR_URL },
                                description = string.format("**||%s||** You have obtained a new **%s** fish!", playerName, tier),
                                color       = color,
                                fields = {
                                    { name = "\227\128\162Fish Name :",  value = fishName,                                    inline = false },
                                    { name = "\227\128\162Fish Tier :",  value = tier,                                        inline = false },
                                    { name = "\227\128\162Weight :",     value = string.format("%.2f Kg", meta.Weight or 0), inline = false },
                                    { name = "\227\128\162Mutation :",   value = mutText,                                     inline = false },
                                    { name = "\227\128\162Sell Price :", value = formatPrice(finalPrice),                     inline = false },
                                },
                                image     = { url = "https://i.imgur.com/UMWNYK7.png" },
                                footer    = { text = BOT_NAME .. " Webhook • " .. os.date("%m/%d/%Y %I:%M"), icon_url = AVATAR_URL },
                                timestamp = os.date("!%Y-%m-%dT%H:%M:%SZ"),
                            }},
                        }
                        local imageOk, imageUrl = pcall(getFishImageUrl, fish)
                        if imageOk and imageUrl then
                            payload.embeds[1].image = { url = imageUrl }
                        end
                        queueWebhook(_fishState.url, payload)
                    end)
                end)
            else
                _fishState.running = false
                if _fishState.conn then _fishState.conn:Disconnect(); _fishState.conn = nil end
            end
        end,
    })

    FishSection:AddButton({
        Title    = "Test Fish Webhook",
        Callback = function()
            if _fishState.url == "" then
                Library:MakeNotify({ Title = "Webhook", Description = "Webhook URL is not set!", Delay = 3 })
                return
            end
            local playerName = (_fishState.hide ~= "") and _fishState.hide
                            or (LocalPlayer.DisplayName or LocalPlayer.Name)
            local cleanId = _fishState.id
            local mention = (cleanId ~= "" and #cleanId >= 17) and ("<@" .. cleanId .. ">") or ""
            local content_text = mention ~= "" and (mention .. " New fish caught!") or "New fish caught!"
            local ok = pcall(function()
                sendHTTP(_fishState.url, {
                    content          = content_text,
                    username         = BOT_NAME,
                    avatar_url       = AVATAR_URL,
                    embeds = {{
                        author      = { name = BOT_NAME .. " Webhook | Fish Caught", icon_url = AVATAR_URL },
                        description = string.format("**||%s||** You have obtained a new **Legendary** fish!", playerName),
                        color       = 15844367,
                        fields = {
                            { name = "\227\128\162Fish Name :",  value = "Webhook Test", inline = false },
                            { name = "\227\128\162Fish Tier :",  value = "FORGOTTEN",    inline = false },
                            { name = "\227\128\162Weight :",     value = "12.50 Kg",     inline = false },
                            { name = "\227\128\162Mutation :",   value = "None",         inline = false },
                            { name = "\227\128\162Sell Price :", value = "10,000",       inline = false },
                        },
                        image     = { url = "https://i.imgur.com/UMWNYK7.png" },
                        footer    = { text = BOT_NAME .. " Webhook • " .. os.date("%m/%d/%Y %I:%M"), icon_url = AVATAR_URL },
                        timestamp = os.date("!%Y-%m-%dT%H:%M:%SZ"),
                    }},
                })
            end)
            Library:MakeNotify({
                Title       = "Webhook",
                Description = ok and "Test message sent to Discord!" or "Failed to send! Check executor / URL.",
                Delay       = ok and 3 or 4,
            })
        end,
    })

    local DisconnectSection = WebhookTab:AddSection("Disconnect Webhook")
    local _dcState = {
        url = "", id = "", hide = "", enabled = false, setup = false, fired = false,
        errorConn = nil, overlayConn = nil,
    }

    local function _disconnectWebhookListeners()
        if _dcState.errorConn then
            pcall(function() _dcState.errorConn:Disconnect() end)
            _dcState.errorConn = nil
        end
        if _dcState.overlayConn then
            pcall(function() _dcState.overlayConn:Disconnect() end)
            _dcState.overlayConn = nil
        end
        _dcState.setup = false
    end

    DisconnectSection:AddParagraph({
        Title   = "Info",
        Content = "Sends a notification to Discord when Roblox disconnects, then auto-rejoins.",
    })
    DisconnectSection:AddInput({
        Title       = "Webhook URL (Disconnect)",
        Default     = "",
        Placeholder = "https://discord.com/api/webhooks/...",
        Callback    = function(value) _dcState.url = cleanStr(value) end,
    })
    DisconnectSection:AddInput({
        Title       = "Discord User ID (Disconnect)",
        Default     = "",
        Placeholder = "123456789012345678",
        Callback    = function(value)
            _dcState.id = cleanId(value)
        end,
    })
    DisconnectSection:AddInput({
        Title       = "Hide Identity (Disconnect)",
        Default     = "",
        Placeholder = "Enter custom name...",
        Callback    = function(value) _dcState.hide = cleanStr(value) end,
    })

    DisconnectSection:AddToggle({
        Title    = "Enable Disconnect Webhook",
        Default  = false,
        Callback = function(on)
            _dcState.enabled = on
            if not on then
                _disconnectWebhookListeners()
                return
            end
            _disconnectWebhookListeners()
            _dcState.setup = true
            _dcState.fired = false
            local function onDisconnect(reason)
                if _dcState.fired or not _dcState.enabled then return end
                if not _dcState.url or _dcState.url == "" then return end
                _dcState.fired = true
                local playerName = (_dcState.hide ~= "") and _dcState.hide
                                or (LocalPlayer and LocalPlayer.Name) or "Unknown"
                local uid     = _dcState.id
                local mention = (uid ~= "" and #uid >= 17) and ("<@" .. uid .. ">") or ""
                local content_text = mention ~= "" and (mention .. " Your account got disconnected from the server!") or "Your account got disconnected from the server!"
                sendHTTP(_dcState.url, {
                    content          = content_text,
                    username         = BOT_NAME,
                    avatar_url       = AVATAR_URL,
                    embeds = {{
                        author      = { name = BOT_NAME .. " | Disconnect Alert" },
                        title       = "Connection Lost",
                        description = "**Your Roblox session was disconnected.**\n\nAttempting to rejoin...",
                        color       = 16711680,
                        fields = {
                            { name = "Account", value = "```" .. playerName .. "```",                       inline = true  },
                            { name = "Time",    value = "```" .. os.date("%m/%d/%Y at %I:%M %p") .. "```", inline = true  },
                            { name = "Reason",  value = "```" .. (reason or "Disconnected") .. "```",      inline = false },
                        },
                        footer    = { text = BOT_NAME .. " • Auto-rejoin enabled", icon_url = AVATAR_URL },
                        timestamp = os.date("!%Y-%m-%dT%H:%M:%SZ"),
                    }},
                })
                task.wait(2)
                pcall(function()
                    game:GetService("TeleportService"):Teleport(game.PlaceId, LocalPlayer)
                end)
            end
            pcall(function()
                local GuiService = game:GetService("GuiService")
                _dcState.errorConn = GuiService.ErrorMessageChanged:Connect(function(msg)
                    if msg and msg ~= "" then onDisconnect(msg) end
                end)
            end)
            pcall(function()
                local promptGui = game:GetService("CoreGui"):FindFirstChild("RobloxPromptGui")
                if promptGui then
                    local overlay = promptGui:FindFirstChild("promptOverlay")
                    if overlay then
                        _dcState.overlayConn = overlay.ChildAdded:Connect(function(child)
                            if child.Name == "ErrorPrompt" then
                                task.wait(1)
                                local lbl = child:FindFirstChildWhichIsA("TextLabel", true)
                                onDisconnect(lbl and lbl.Text or "Disconnected")
                            end
                        end)
                    end
                end
            end)
        end,
    })

    DisconnectSection:AddButton({
        Title    = "Test Disconnect Webhook",
        Callback = function()
            if _dcState.url == "" then
                Library:MakeNotify({ Title = "Webhook", Description = "Disconnect URL is not set!", Delay = 3 })
                return
            end
            local playerName = (_dcState.hide ~= "") and _dcState.hide
                            or (LocalPlayer and LocalPlayer.Name) or "Unknown"
            local cleanId = _dcState.id
            local mention = (cleanId ~= "" and #cleanId >= 17) and ("<@" .. cleanId .. ">") or ""
            local content_text = mention ~= "" and (mention .. " Your account got disconnected from the server!") or "Your account got disconnected from the server!"
            local ok = pcall(function()
                sendHTTP(_dcState.url, {
                    content          = content_text,
                    username         = BOT_NAME,
                    avatar_url       = AVATAR_URL,
                    embeds = {{
                        author      = { name = BOT_NAME .. " | Disconnect Alert" },
                        title       = "Connection Lost",
                        description = "**Your Roblox session was disconnected.**\n\nAttempting to rejoin...",
                        color       = 16711680,
                        fields = {
                            { name = "Account", value = "```" .. playerName .. "```",                       inline = true  },
                            { name = "Time",    value = "```" .. os.date("%m/%d/%Y at %I:%M %p") .. "```", inline = true  },
                            { name = "Reason",  value = "```Test Successfully :3```",                       inline = false },
                        },
                        footer    = { text = BOT_NAME .. " • Auto-rejoin enabled", icon_url = AVATAR_URL },
                        timestamp = os.date("!%Y-%m-%dT%H:%M:%SZ"),
                    }},
                })
            end)
            Library:MakeNotify({
                Title       = "Webhook",
                Description = ok and "Disconnect test sent!" or "Failed to send! Check executor / URL.",
                Delay       = ok and 3 or 4,
            })
        end,
    })

    local WebhookServerSection = WebhookTab:AddSection("Webhook Server")
    local _wsState = {
        url          = "",
        customName   = "",
        enabled      = false,
        trackJoin    = true,
        trackLeave   = true,
        selectedTiers = {
            ["Epic"]      = false,
            ["Legendary"] = false,
            ["Mythic"]    = false,
            ["SECRET"]    = false,
            ["FORGOTTEN"] = false,
        },
        joinConn  = nil,
        leaveConn = nil,
    }

    local WS_TIER_DATA = {
        { name = "Epic",      discordColor = 10181046, r = 179, g = 115, b = 248 },
        { name = "Legendary", discordColor = 15844367, r = 255, g = 185, b = 43  },
        { name = "Mythic",    discordColor = 16711680, r = 255, g = 25,  b = 25  },
        { name = "SECRET",    discordColor = 65535,    r = 24,  g = 255, b = 152 },
        { name = "FORGOTTEN", discordColor = 8421504,  r = 0,   g = 0,   b = 0   },
    }

    local TextChatService
    pcall(function() TextChatService = game:GetService("TextChatService") end)

    local function wsTierFromRGB(text)
        local allColors = {}
        for cr, cg, cb in text:gmatch("rgb%((%d+),%s*(%d+),%s*(%d+)%)") do
            table.insert(allColors, {tonumber(cr), tonumber(cg), tonumber(cb)})
        end
        if #allColors == 0 then return nil end
        local closest, closestDist = nil, math.huge
        for _, c in ipairs(allColors) do
            local r, g, b = c[1], c[2], c[3]
            for _, t in ipairs(WS_TIER_DATA) do
                local d = math.sqrt((r - t.r)^2 + (g - t.g)^2 + (b - t.b)^2)
                if d < closestDist then
                    closest = t
                    closestDist = d
                end
            end
        end
        return (closestDist < 55) and closest or nil
    end

    local WS_VARIANT_NAMES = {
        "Fairy Dust", "Galaxy", "Corrupt", "Gemstone", "Ghost",
        "Lightning", "Gold", "Midnight", "Radioactive", "Stone",
        "Holographic", "Albino", "Sandy",
    }

    local function wsParseFishLog(text)
        local clean = text:gsub("<[^>]+>", "")
        local isServer = clean:find("%[Server%]")
        if not isServer or not clean:find("obtained") then return nil end
        local player = clean:match("%[Server%]:%s*(.-)%s+obtained")
        local fish   = clean:match("obtained a?n?%s+(.-)%s+with a") or clean:match("obtained a?n?%s+(.-)%s+%(.*%)")
        local chance = clean:match("with a (1 in [%d%.,KkMmBb]+) chance") or "Unknown"
        if not player or not fish then return nil end
        local weight = nil
        local fishClean = fish
        local w = fish:match("%((.-[Kk][Gg])%)")
        if w then
            weight = w
            fishClean = fish:gsub("%s*%b()%s*$", ""):gsub("%s+$", "")
        end
        local variant = nil
        local fishLower = fishClean:lower()
        for _, v in ipairs(WS_VARIANT_NAMES) do
            local vLower = v:lower()
            if fishLower:sub(1, #vLower + 1) == vLower .. " " then
                variant = v
                fishClean = fishClean:sub(#v + 2):gsub("^%s+", "")
                break
            end
        end
        return {
            player  = player:gsub("%s+$", ""),
            fish    = fishClean:gsub("%s+$", ""),
            weight  = weight,
            variant = variant,
            chance  = chance,
            prefix  = "[Server]",
        }
    end

    local _wsImageCache = {}
    local function wsGetFishImageUrl(fishName)
        if _wsImageCache[fishName] then return _wsImageCache[fishName] end
        if not Items then pcall(loadItems) end
        if not Items then
            _wsImageCache[fishName] = "https://i.imgur.com/UMWNYK7.png"
            return _wsImageCache[fishName]
        end
        local cleanName = fishName:gsub("%s*%b()%s*$", ""):gsub("^%s*(.-)%s*$", "%1")
        local targetLower = cleanName:lower():gsub("%s+", " ")
        local bestMatch, bestScore = nil, 0
        for _, fish in pairs(Items) do
            local data = fish.Data
            if data then
                local names = { data.Name, data.DisplayName, data.InternalName, data.ShortName }
                for _, n in ipairs(names) do
                    if n then
                        local nLower = tostring(n):lower():gsub("%s+", " "):gsub("^%s*(.-)%s*$", "%1")
                        if nLower == targetLower then
                            bestMatch = fish; bestScore = 100; break
                        end
                        local score = 0
                        if nLower:find(targetLower, 1, true) then
                            score = math.floor((#targetLower / #nLower) * 90)
                        elseif targetLower:find(nLower, 1, true) then
                            score = math.floor((#nLower / #targetLower) * 70)
                        end
                        if score > bestScore then bestScore = score; bestMatch = fish end
                    end
                end
                if bestScore == 100 then break end
            end
        end
        local url = "https://i.imgur.com/UMWNYK7.png"
        if bestMatch and bestScore >= 30 then
            local data = bestMatch.Data
            local assetId = nil
            if     data.Icon      then assetId = tostring(data.Icon):match("%d+")
            elseif data.ImageId   then assetId = tostring(data.ImageId):match("%d+")
            elseif data.Image     then assetId = tostring(data.Image):match("%d+")
            elseif data.Thumbnail then assetId = tostring(data.Thumbnail):match("%d+")
            elseif data.AssetId   then assetId = tostring(data.AssetId):match("%d+")
            end
            if assetId and assetId ~= "" then
                local fetched = getDiscordImageUrl(assetId)
                if fetched and fetched ~= "" then url = fetched end
            end
        end
        _wsImageCache[fishName] = url
        return url
    end

    local function wsSetupChatListener()
        if _wsState.chatConn then return end
        if not TextChatService then return end
        _wsState.chatConn = TextChatService.MessageReceived:Connect(function(message)
            if not _wsState.enabled or _wsState.url == "" or not message.Text then return end
            local tierData = wsTierFromRGB(message.Text)
            if not tierData or not _wsState.selectedTiers[tierData.name] then return end
            local info = wsParseFishLog(message.Text)
            if not info then return end
            task.spawn(function()
                local imageUrl    = wsGetFishImageUrl(info.fish)
                local displayName = (_wsState.customName ~= "") and _wsState.customName or info.player
                local wsFields = {
                    { name = "\227\128\162Fish Name :", value = info.fish,     inline = false },
                    { name = "\227\128\162Fish Tier :", value = tierData.name, inline = false },
                }
                if info.variant then
                    table.insert(wsFields, { name = "\227\128\162Variant :", value = info.variant, inline = false })
                end
                if info.weight then
                    table.insert(wsFields, { name = "\227\128\162Weight :", value = info.weight, inline = false })
                end
                table.insert(wsFields, { name = "\227\128\162Scope :",  value = info.prefix, inline = false })
                table.insert(wsFields, { name = "\227\128\162Chance :", value = info.chance, inline = false })
                queueWebhook(_wsState.url, {
                    username         = BOT_NAME,
                    avatar_url       = AVATAR_URL,
                    allowed_mentions = { parse = { "users" } },
                    embeds = {{
                        author      = { name = BOT_NAME .. " Webhook | Fish Caught", icon_url = AVATAR_URL },
                        description = string.format("**||%s||** You have obtained a new **%s** fish!", displayName, tierData.name),
                        color       = tierData.discordColor,
                        fields      = wsFields,
                        image       = { url = imageUrl },
                        footer      = { text = BOT_NAME .. " Webhook • " .. os.date("%m/%d/%Y %I:%M"), icon_url = AVATAR_URL },
                        timestamp   = os.date("!%Y-%m-%dT%H:%M:%SZ"),
                    }},
                })
            end)
        end)
    end

    local function wsSendJoinLeaveNotif(player, isJoin)
        if not _wsState.enabled or _wsState.url == "" then return end
        if isJoin     and not _wsState.trackJoin  then return end
        if not isJoin and not _wsState.trackLeave then return end
        local displayName = player.DisplayName or player.Name
        queueWebhook(_wsState.url, {
            username         = BOT_NAME,
            avatar_url       = AVATAR_URL,
            allowed_mentions = { parse = { "users" } },
            embeds = {{
                author      = { name = BOT_NAME .. " Webhook | " .. (isJoin and "Player Joined" or "Player Left"), icon_url = AVATAR_URL },
                description = string.format("**||%s||** has %s the server.", displayName, isJoin and "joined" or "left"),
                color       = isJoin and 0x55FF55 or 0xFF5555,
                fields = {
                    { name = "\227\128\162Display Name :", value = "||" .. displayName .. "||",     inline = false },
                    { name = "\227\128\162Status :",       value = isJoin and "Joined" or "Left",   inline = false },
                },
                footer    = { text = BOT_NAME .. " Webhook • " .. os.date("%m/%d/%Y %I:%M"), icon_url = AVATAR_URL },
                timestamp = os.date("!%Y-%m-%dT%H:%M:%SZ"),
            }},
        })
    end

    WebhookServerSection:AddParagraph({
        Title   = "Info",
        Content = "Monitors [Server] chat for fish catch logs and sends notifications to Discord.\n" ..
                  "Also tracks player join/leave events.",
    })
    WebhookServerSection:AddInput({
        Title       = "Webhook URL (Server)",
        Default     = "",
        Placeholder = "https://discord.com/api/webhooks/...",
        Callback    = function(value) _wsState.url = cleanStr(value) end,
    })
    WebhookServerSection:AddInput({
        Title    = "Custom Display Name",
        Default  = "",
        Callback = function(value) _wsState.customName = cleanStr(value) end,
    })
    WebhookServerSection:AddDropdown({
        Title    = "Select Tiers to Log",
        Options  = {"Epic", "Legendary", "Mythic", "SECRET", "FORGOTTEN"},
        Multi    = true,
        Default  = {},
        Callback = function(selected)
            for k in pairs(_wsState.selectedTiers) do _wsState.selectedTiers[k] = false end
            if type(selected) == "table" then
                for _, v in ipairs(selected) do _wsState.selectedTiers[v] = true end
            end
        end,
    })
    WebhookServerSection:AddToggle({
        Title    = "Track Player Join",
        Default  = true,
        Callback = function(val) _wsState.trackJoin = val end,
    })
    WebhookServerSection:AddToggle({
        Title    = "Track Player Leave",
        Default  = true,
        Callback = function(val) _wsState.trackLeave = val end,
    })
    WebhookServerSection:AddToggle({
        Title    = "Enable Webhook Server",
        Default  = false,
        Callback = function(on)
            _wsState.enabled = on
            if on then
                if _wsState.url == "" then
                    Library:MakeNotify({ Title = "Webhook", Description = "Server webhook URL is not set!", Delay = 3 })
                    return
                end
                if not getHTTP() then warn("[Webhook] Executor does not support HTTP requests!"); return end
                task.spawn(loadItems)
                wsSetupChatListener()
                if not _wsState.joinConn then
                    _wsState.joinConn = Players.PlayerAdded:Connect(function(player)
                        wsSendJoinLeaveNotif(player, true)
                    end)
                end
                if not _wsState.leaveConn then
                    _wsState.leaveConn = Players.PlayerRemoving:Connect(function(player)
                        wsSendJoinLeaveNotif(player, false)
                    end)
                end
            else
                if _wsState.chatConn  then _wsState.chatConn:Disconnect();  _wsState.chatConn  = nil end
                if _wsState.joinConn  then _wsState.joinConn:Disconnect();  _wsState.joinConn  = nil end
                if _wsState.leaveConn then _wsState.leaveConn:Disconnect(); _wsState.leaveConn = nil end
            end
        end,
    })
    WebhookServerSection:AddButton({
        Title    = "Test Webhook Server",
        Callback = function()
            if _wsState.url == "" then
                Library:MakeNotify({ Title = "Webhook", Description = "Server webhook URL is not set!", Delay = 3 })
                return
            end
            local ok = pcall(function()
                sendHTTP(_wsState.url, {
                    username         = BOT_NAME,
                    avatar_url       = AVATAR_URL,
                    allowed_mentions = { parse = { "users" } },
                    embeds = {{
                        author      = { name = BOT_NAME .. " Webhook | Fish Caught", icon_url = AVATAR_URL },
                        description = "**Lynx** You have obtained a new **FORGOTTEN** fish!",
                        color       = 0x55AAFF,
                        fields = {
                            { name = "\227\128\162Fish Name :", value = "Webhook Test",   inline = false },
                            { name = "\227\128\162Fish Tier :", value = "FORGOTTEN",      inline = false },
                            { name = "\227\128\162Variant :",   value = "Corrupt",        inline = false },
                            { name = "\227\128\162Weight :",    value = "471.10Kg",       inline = false },
                            { name = "\227\128\162Scope :",     value = "[Server]",       inline = false },
                            { name = "\227\128\162Chance :",    value = "1 in 1,000,000", inline = false },
                        },
                        image     = { url = "https://i.imgur.com/UMWNYK7.png" },
                        footer    = { text = BOT_NAME .. " Webhook • " .. os.date("%m/%d/%Y %I:%M"), icon_url = AVATAR_URL },
                        timestamp = os.date("!%Y-%m-%dT%H:%M:%SZ"),
                    }},
                })
            end)
            Library:MakeNotify({
                Title       = "Webhook",
                Description = ok and "Server webhook test sent!" or "Failed to send! Check executor / URL.",
                Delay       = ok and 3 or 4,
            })
        end,
    })
end

-- [Skin Tab]
do
    local SkinTab = MainWindow:AddTab({ Name = "Skin Features", Icon = "user" })
    do
        local AccessorySection = SkinTab:AddSection("Accessory Changer")
        local _accessory = {
            selected = nil,
            enabled  = false,
            folder   = nil,
        }
        local function _getAccessoryFolder()
            if _accessory.folder then return _accessory.folder end
            local ok, folder = pcall(function()
                return game.ReplicatedStorage
                    :WaitForChild("Controllers", 10)
                    :WaitForChild("AccessoryReplicationController", 5)
                    :WaitForChild("Accessory", 5)
            end)
            if ok and folder then
                _accessory.folder = folder
                return folder
            end
            return nil
        end
        local function _getAccessoryList()
            local folder = _getAccessoryFolder()
            if not folder then return {} end
            local list = {}
            for _, v in ipairs(folder:GetChildren()) do
                table.insert(list, v.Name)
            end
            table.sort(list)
            return list
        end
        local function _applyAccessory()
            if not _accessory.selected then return false end
            local ok = pcall(function()
                LocalPlayer:SetAttribute("FishingRodSkin", _accessory.selected)
            end)
            return ok
        end
        local function _removeAccessory()
            pcall(function()
                LocalPlayer:SetAttribute("FishingRodSkin", nil)
            end)
        end
        local function _notify(desc, delay)
            Library:MakeNotify({
                Title       = "Accessory",
                Description = desc,
                Delay       = delay or 3,
            })
        end
        local _accList = {}
        local _accDropdownRef = nil
        _accDropdownRef = AccessorySection:AddDropdown({
            Title    = "Pilih Accessory",
            Options  = _accList,
            NoSave   = false,
            Callback = function(v)
                _accessory.selected = v
                if _accessory.enabled then
                    local ok = _applyAccessory()
                    _notify(ok and ("Accessory aktif: " .. v) or "Gagal apply accessory!")
                end
            end,
        })
        AccessorySection:AddButton({
            Title    = "Refresh Accessory List",
            Callback = function()
                task.spawn(function()
                    local list = _getAccessoryList()
                    _accList = list
                    if _accDropdownRef then
                        pcall(function()
                            if _accDropdownRef.Refresh then
                                _accDropdownRef:Refresh(list, true)
                            elseif _accDropdownRef.SetOptions then
                                _accDropdownRef:SetOptions(list)
                            end
                        end)
                    end
                    _notify(#list > 0 and ("Loaded " .. #list .. " accessories.") or "Accessory folder tidak ditemukan!", 2)
                end)
            end,
        })
        AccessorySection:AddToggle({
            Title    = "Enable Accessory",
            Default  = false,
            NoSave   = true,
            Callback = function(on)
                if on then
                    if not _accessory.selected then
                        _notify("Pilih accessory dulu dari dropdown!", 2)
                        _accessory.enabled = false
                        return
                    end
                    if not _getAccessoryFolder() then
                        _notify("Gagal akses AccessoryFolder!", 3)
                        _accessory.enabled = false
                        return
                    end
                    _accessory.enabled = true
                    local ok = _applyAccessory()
                    _notify(ok and ("Accessory aktif: " .. _accessory.selected) or "Gagal apply accessory!")
                else
                    _accessory.enabled = false
                    _removeAccessory()
                    _notify("Accessory dilepas.", 2)
                end
            end,
        })
        AccessorySection:AddButton({
            Title    = "Remove Accessory",
            Callback = function()
                _accessory.enabled = false
                _removeAccessory()
                _notify("Accessory dilepas.", 2)
            end,
        })
    end
    do
        local AvatarSection = SkinTab:AddSection("Avatar Changer")
        local _avatar = {
            enabled      = false,
            selectedId   = nil,
            selectedName = "",
            applyConn    = nil,
            currentDesc  = nil,
        }
        local _originalDesc = nil
        local AVATAR_LIST = {
            { Id = 7077243300,  Label = "TV_TIKMAN" },
            { Id = 6010134024,  Label = "Ninjaso02YT" },
            { Id = 1105009763,  Label = "s1mple" },
            { Id = 3232392707,  Label = "G0DG0MER" },
            { Id = 8673396266,  Label = "spiderman" },
            { Id = 9939245108,  Label = "ApiqqStoreeX8" },
            { Id = 8849874931,  Label = "SnoopDogs" },
            { Id = 495215054,   Label = "SnoopDog" },
            { Id = 3658593465,  Label = "CFIDxMuell" },
            { Id = 8723543936,  Label = "Izyy" },
            { Id = 9068204572,  Label = "Cero" },
            { Id = 1922874709,  Label = "StanniBunny" },
            { Id = 3853262070,  Label = "S4INTRL" },
            { Id = 1718757907,  Label = "1_PFT" },
            { Id = 8343523,     Label = "Neko_Overlord" },
            { Id = 925872199,   Label = "gamer" },
            { Id = 9758684471,  Label = "Azure" },
            { Id = 776077949,   Label = "DuckXander" },
            { Id = 293229095,   Label = "SinisterUGC" },
            { Id = 3622565596,  Label = "Bluff_006" },
            { Id = 77696047,    Label = "caIIdrops" },
            { Id = 32958887,    Label = "Juno" },
            { Id = 63578527,    Label = "MistyPhantom" },
            { Id = 293215507,   Label = "LoneWalker_L" },
            { Id = 178596165,   Label = "LilDisquit" },
            { Id = 7712365803,  Label = "TATA" },
            { Id = 9331384193,  Label = "Ficha_NR" },
            { Id = 8898545773,  Label = "Gracee" },
            { Id = 8997690084,  Label = "3quinox" },
            { Id = 9273180503,  Label = "Your_Miffy" },
            { Id = 425367613,   Label = "QueenChroma" },
            { Id = 147302717,   Label = "Hoshiko" },
            { Id = 8476353635,  Label = "kify168" },
            { Id = 40397833,    Label = "WILDES" },
            { Id = 75974130,    Label = "TALON" },
            { Id = 7909420830,  Label = "ZAER" },
            { Id = 111233359,   Label = "EA_GAMES" },
            { Id = 56602747,    Label = "Stealthy" },
            { Id = 47058434,    Label = "RZXTL" },
        }
        local BODY_PARTS = {
            "Head", "Torso", "Left Arm", "Right Arm", "Left Leg", "Right Leg",
            "UpperTorso", "LowerTorso", "LeftUpperArm", "RightUpperArm",
            "LeftLowerArm", "RightLowerArm", "LeftHand", "RightHand",
            "LeftUpperLeg", "RightUpperLeg", "LeftLowerLeg", "RightLowerLeg",
            "LeftFoot", "RightFoot",
        }
        local function _getAvatarOptions()
            local list = {}
            for _, v in ipairs(AVATAR_LIST) do
                table.insert(list, v.Label)
            end
            return list
        end
        local function _getIdByLabel(label)
            for _, v in ipairs(AVATAR_LIST) do
                if v.Label == label then return v.Id end
            end
            return nil
        end
        local function _copyDummyToChar(dummyChar, char, desc)
            for _, obj in ipairs(char:GetChildren()) do
                if obj:IsA("Accessory") or obj:IsA("Hat")
                or obj:IsA("Shirt")     or obj:IsA("Pants")
                or obj:IsA("ShirtGraphic") or obj:IsA("CharacterMesh") then
                    obj:Destroy()
                end
            end
            for _, obj in ipairs(dummyChar:GetChildren()) do
                if obj:IsA("Accessory") or obj:IsA("Hat") then
                    pcall(function()
                        local clone  = obj:Clone()
                        clone.Parent = char
                        local handle = clone:FindFirstChild("Handle")
                        if not handle then return end
                        local oldWeld = handle:FindFirstChild("AccessoryWeld")
                        if oldWeld then oldWeld:Destroy() end
                        local attName = nil
                        for _, child in ipairs(handle:GetChildren()) do
                            if child:IsA("Attachment") then attName = child.Name; break end
                        end
                        local targetPart, targetAtt = nil, nil
                        for _, part in ipairs(char:GetDescendants()) do
                            if part:IsA("Attachment") and part.Name == attName and part.Parent ~= handle then
                                targetPart = part.Parent
                                targetAtt  = part
                                break
                            end
                        end
                        if targetPart and targetPart:IsA("BasePart") then
                            local weld      = Instance.new("Weld")
                            weld.Name       = "AccessoryWeld"
                            weld.Part0      = targetPart
                            weld.Part1      = handle
                            weld.C0         = targetAtt.CFrame
                            local handleAtt = handle:FindFirstChild(attName)
                            weld.C1         = handleAtt and handleAtt.CFrame or CFrame.new()
                            weld.Parent     = handle
                        else
                            local root = char:FindFirstChild("Head") or char:FindFirstChild("HumanoidRootPart")
                            if root then
                                local weld  = Instance.new("Weld")
                                weld.Name   = "AccessoryWeld"
                                weld.Part0  = root
                                weld.Part1  = handle
                                weld.Parent = handle
                            end
                        end
                    end)
                elseif obj:IsA("Shirt") or obj:IsA("Pants")
                or obj:IsA("ShirtGraphic") or obj:IsA("CharacterMesh") then
                    pcall(function()
                        local clone = obj:Clone()
                        clone.Parent = char
                    end)
                end
            end
            if not char:FindFirstChildOfClass("Shirt") and desc and desc.Shirt and desc.Shirt ~= 0 then
                pcall(function()
                    local shirt = Instance.new("Shirt")
                    shirt.ShirtTemplate = "rbxassetid://" .. tostring(desc.Shirt)
                    shirt.Parent = char
                end)
            end
            if not char:FindFirstChildOfClass("Pants") and desc and desc.Pants and desc.Pants ~= 0 then
                pcall(function()
                    local pants = Instance.new("Pants")
                    pants.PantsTemplate = "rbxassetid://" .. tostring(desc.Pants)
                    pants.Parent = char
                end)
            end
            if desc and desc.GraphicTShirt and desc.GraphicTShirt ~= 0 then
                if not char:FindFirstChildOfClass("ShirtGraphic") then
                    pcall(function()
                        local tshirt = Instance.new("ShirtGraphic")
                        tshirt.Graphic = "rbxassetid://" .. tostring(desc.GraphicTShirt)
                        tshirt.Parent  = char
                    end)
                end
            end
            local dummyBC = dummyChar:FindFirstChildOfClass("BodyColors")
            local myBC    = char:FindFirstChildOfClass("BodyColors")
            if dummyBC and myBC then
                myBC.HeadColor3     = dummyBC.HeadColor3
                myBC.TorsoColor3    = dummyBC.TorsoColor3
                myBC.LeftArmColor3  = dummyBC.LeftArmColor3
                myBC.RightArmColor3 = dummyBC.RightArmColor3
                myBC.LeftLegColor3  = dummyBC.LeftLegColor3
                myBC.RightLegColor3 = dummyBC.RightLegColor3
            end
            local dummyHead = dummyChar:FindFirstChild("Head")
            local myHead    = char:FindFirstChild("Head")
            if dummyHead and myHead then
                local dummyMesh = dummyHead:FindFirstChild("Mesh") or dummyHead:FindFirstChildOfClass("SpecialMesh")
                local myMesh    = myHead:FindFirstChild("Mesh")    or myHead:FindFirstChildOfClass("SpecialMesh")
                if dummyMesh then
                    if not myMesh then
                        myMesh        = Instance.new("SpecialMesh")
                        myMesh.Name   = "Mesh"
                        myMesh.Parent = myHead
                    end
                    pcall(function()
                        myMesh.MeshType  = dummyMesh.MeshType
                        myMesh.MeshId    = dummyMesh.MeshId    or ""
                        myMesh.TextureId = dummyMesh.TextureId or ""
                        myMesh.Scale     = dummyMesh.Scale
                        myMesh.Offset    = dummyMesh.Offset
                    end)
                end
                local myFace = myHead:FindFirstChild("face") or myHead:FindFirstChildOfClass("Decal")
                if desc and desc.Face and desc.Face ~= 0 then
                    if not myFace then
                        myFace        = Instance.new("Decal")
                        myFace.Name   = "face"
                        myFace.Face   = Enum.NormalId.Front
                        myFace.Parent = myHead
                    end
                    pcall(function() myFace.Texture = "rbxassetid://" .. tostring(desc.Face) end)
                end
                pcall(function() myHead.Color = dummyHead.Color end)
            end
            for _, partName in ipairs(BODY_PARTS) do
                local dummyPart = dummyChar:FindFirstChild(partName)
                local myPart    = char:FindFirstChild(partName)
                if dummyPart and myPart then
                    pcall(function() myPart.Color = dummyPart.Color end)
                    local dummySA = dummyPart:FindFirstChildOfClass("SurfaceAppearance")
                    local mySA    = myPart:FindFirstChildOfClass("SurfaceAppearance")
                    if dummySA then
                        if not mySA then
                            mySA        = Instance.new("SurfaceAppearance")
                            mySA.Parent = myPart
                        end
                        pcall(function()
                            mySA.ColorMap     = dummySA.ColorMap
                            mySA.NormalMap    = dummySA.NormalMap
                            mySA.RoughnessMap = dummySA.RoughnessMap
                            mySA.MetalnessMap = dummySA.MetalnessMap
                        end)
                    elseif mySA then
                        mySA:Destroy()
                    end
                end
            end
        end

        local function _spawnDummyAndCopy(desc, char)
            local dummyChar = nil
            local ok = pcall(function()
                dummyChar = Players:CreateHumanoidModelFromDescription(desc, Enum.HumanoidRigType.R6)
            end)
            if not ok or not dummyChar then return false end
            pcall(function()
                dummyChar.Parent = workspace
                if dummyChar.PrimaryPart then
                    dummyChar:SetPrimaryPartCFrame(CFrame.new(0, -99999, 0))
                end
            end)
            task.wait(3)
            local success = pcall(function()
                _copyDummyToChar(dummyChar, char, desc)
                local myHumanoid = char:FindFirstChildOfClass("Humanoid")
                if myHumanoid then
                    pcall(function()
                        myHumanoid.BodyDepthScale.Value  = desc.DepthScale
                        myHumanoid.BodyHeightScale.Value = desc.HeightScale
                        myHumanoid.BodyWidthScale.Value  = desc.WidthScale
                        myHumanoid.HeadScale.Value       = desc.HeadScale
                    end)
                end
            end)
            pcall(function() dummyChar:Destroy() end)
            return success
        end
        local function _applyAvatarDirect(userId)
            local char    = LocalPlayer.Character
            if not char then return false end

            local ok, desc = pcall(function()
                return Players:GetHumanoidDescriptionFromUserId(userId)
            end)
            if not ok or not desc then return false end

            local success = _spawnDummyAndCopy(desc, char)
            if success then _avatar.currentDesc = desc end
            return success
        end
        local function _removeAvatar()
            local char    = LocalPlayer.Character
            if not char then return end
            local descToUse = _originalDesc
            if not descToUse then
                local ok, freshDesc = pcall(function()
                    return Players:GetHumanoidDescriptionFromUserId(LocalPlayer.UserId)
                end)
                if not ok or not freshDesc then return end
                descToUse = freshDesc
            end
            _spawnDummyAndCopy(descToUse, char)
            _avatar.currentDesc = nil
        end
        AvatarSection:AddDropdown({
            Title    = "Select Avatar",
            Options  = _getAvatarOptions(),
            Default  = nil,
            NoSave   = true,
            Callback = function(selected)
                local id = _getIdByLabel(selected)
                _avatar.selectedId   = id
                _avatar.selectedName = selected
                if not _avatar.enabled or not id then return end
                task.spawn(function()
                    local ok = _applyAvatarDirect(id)
                    Library:MakeNotify({
                        Title       = "Avatar Changer",
                        Description = ok and ("Avatar: " .. selected) or "Gagal apply avatar!",
                        Color       = ok and Color3.fromRGB(100, 200, 255) or Color3.fromRGB(255, 100, 100),
                        Delay       = 2,
                    })
                end)
            end,
        })
        AvatarSection:AddToggle({
            Title    = "Enable Avatar Changer",
            Default  = false,
            NoSave   = true,
            Callback = function(on)
                _avatar.enabled = on
                if _avatar.applyConn then
                    _avatar.applyConn:Disconnect()
                    _avatar.applyConn = nil
                end
                if not on then
                    task.spawn(function()
                        _removeAvatar()
                        Library:MakeNotify({
                            Title       = "Avatar Changer",
                            Description = "Avatar dikembalikan ke asli.",
                            Delay       = 2,
                        })
                    end)
                    return
                end
                if not _avatar.selectedId then
                    Library:MakeNotify({
                        Title       = "Avatar Changer",
                        Description = "Pilih avatar dari dropdown dulu!",
                        Delay       = 2,
                    })
                    return
                end
                task.spawn(function()
                    if not _originalDesc then
                        local ok, desc = pcall(function()
                            return Players:GetHumanoidDescriptionFromUserId(LocalPlayer.UserId)
                        end)
                        if ok and desc then _originalDesc = desc end
                    end
                    local ok = _applyAvatarDirect(_avatar.selectedId)
                    Library:MakeNotify({
                        Title       = "Avatar Changer",
                        Description = ok
                            and ("Avatar aktif: " .. _avatar.selectedName)
                            or  "Gagal apply avatar!",
                        Color = ok
                            and Color3.fromRGB(100, 200, 255)
                            or  Color3.fromRGB(255, 100, 100),
                        Delay = 3,
                    })
                end)
                _avatar.applyConn = LocalPlayer.CharacterAdded:Connect(function(newChar)
                    if not _avatar.enabled or not _avatar.selectedId then return end
                    task.wait(2)
                    local ok, desc = pcall(function()
                        return Players:GetHumanoidDescriptionFromUserId(_avatar.selectedId)
                    end)
                    if not ok or not desc then return end
                    _spawnDummyAndCopy(desc, newChar)
                end)
            end,
        })
        AvatarSection:AddButton({
            Title    = "Apply Now",
            Callback = function()
                if not _avatar.selectedId then
                    Library:MakeNotify({
                        Title       = "Avatar Changer",
                        Description = "Pilih avatar dari dropdown dulu!",
                        Delay       = 2,
                    })
                    return
                end
                task.spawn(function()
                    local ok = _applyAvatarDirect(_avatar.selectedId)
                    Library:MakeNotify({
                        Title       = "Avatar Changer",
                        Description = ok
                            and ("Applied: " .. _avatar.selectedName)
                            or  "Gagal apply avatar!",
                        Color = ok
                            and Color3.fromRGB(100, 200, 255)
                            or  Color3.fromRGB(255, 100, 100),
                        Delay = 2,
                    })
                end)
            end,
        })

        AvatarSection:AddButton({
            Title    = "Reset to Original",
            Callback = function()
                _avatar.enabled = false
                if _avatar.applyConn then
                    _avatar.applyConn:Disconnect()
                    _avatar.applyConn = nil
                end
                task.spawn(function()
                    _removeAvatar()
                    Library:MakeNotify({
                        Title       = "Avatar Changer",
                        Description = "Avatar dikembalikan ke asli.",
                        Delay       = 2,
                    })
                end)
            end,
        })
    end
    do
        local AuraSection  = SkinTab:AddSection("Aura Skin")
        local _aura        = { current = nil, enabled = false, autoReapply = false, charConn = nil }
        local AurasFolder  = (function()
            local assets = ReplicatedStorage:FindFirstChild("Assets")
            return assets and assets:FindFirstChild("Auras") or nil
        end)()
        local function _getAuraList()
            if not AurasFolder then
                local assets = ReplicatedStorage:FindFirstChild("Assets")
                AurasFolder = assets and assets:FindFirstChild("Auras") or nil
            end
            if not AurasFolder then return {} end
            local list = {}
            for _, v in ipairs(AurasFolder:GetChildren()) do
                table.insert(list, v.Name)
            end
            table.sort(list)
            return list
        end
        local function _applyAura(auraName)
            local char = LocalPlayer.Character
            if not char or not auraName then return end
            if not AurasFolder then return end
            local aura = AurasFolder:FindFirstChild(auraName)
            if not aura then return end
            for _, part in ipairs(char:GetChildren()) do
                for _, effect in ipairs(part:GetChildren()) do
                    if effect:GetAttribute("IsAura") then effect:Destroy() end
                end
            end
            for _, auraPart in ipairs(aura:GetChildren()) do
                local charPart = char:FindFirstChild(auraPart.Name)
                if charPart then
                    for _, effect in ipairs(auraPart:GetChildren()) do
                        local clone = effect:Clone()
                        clone:SetAttribute("IsAura", true)
                        clone.Parent = charPart
                    end
                end
            end
        end
        local function _removeAura()
            local char = LocalPlayer.Character
            if not char then return end
            for _, part in ipairs(char:GetChildren()) do
                for _, effect in ipairs(part:GetChildren()) do
                    if effect:GetAttribute("IsAura") then effect:Destroy() end
                end
            end
        end
        local _auraList = {}
        local _auraDropdownRef = nil
        _auraDropdownRef = AuraSection:AddDropdown({
            Title    = "Pilih Aura",
            Options  = _auraList,
            NoSave   = false,
            Callback = function(v)
                _aura.current = v
                if _aura.enabled then
                    _applyAura(v)
                end
            end,
        })
        AuraSection:AddButton({
            Title    = "Refresh Aura List",
            Callback = function()
                local list = _getAuraList()
                _auraList = list
                if _auraDropdownRef then
                    pcall(function()
                        if _auraDropdownRef.Refresh then
                            _auraDropdownRef:Refresh(list, true)
                        elseif _auraDropdownRef.SetOptions then
                            _auraDropdownRef:SetOptions(list)
                        end
                    end)
                end
                Library:MakeNotify({
                    Title       = "Aura",
                    Description = #list > 0 and ("Loaded " .. #list .. " auras.") or "Aura folder tidak ditemukan!",
                    Delay       = 2,
                })
            end,
        })
        AuraSection:AddToggle({
            Title    = "Enable Aura",
            Default  = false,
            NoSave   = true,
            Callback = function(on)
                _aura.enabled = on
                if on then
                    if _aura.current then
                        _applyAura(_aura.current)
                    end
                else
                    _removeAura()
                end
            end,
        })
        AuraSection:AddToggle({
            Title    = "Auto Re-apply saat Respawn",
            Default  = false,
            NoSave   = true,
            Callback = function(on)
                _aura.autoReapply = on
                if on then
                    if _aura.charConn then return end
                    _aura.charConn = LocalPlayer.CharacterAdded:Connect(function()
                        task.wait(1)
                        if _aura.autoReapply and _aura.enabled and _aura.current then
                            _applyAura(_aura.current)
                        end
                    end)
                else
                    if _aura.charConn then
                        _aura.charConn:Disconnect()
                        _aura.charConn = nil
                    end
                end
            end,
        })

        AuraSection:AddButton({
            Title    = "Remove Aura",
            Callback = function()
                _aura.enabled = false
                _removeAura()
                Library:MakeNotify({
                    Title       = "Aura",
                    Description = "Aura berhasil dihapus.",
                    Delay       = 2,
                })
            end,
        })
    end
    do
        local SkinSection = SkinTab:AddSection("Skin Animation")
        local _skinAnim = {
            enabled   = false,
            current   = "",
            conns     = {},
            pools     = {},
            poolIdx   = {},
            killed    = setmetatable({}, {__mode = "k"}),
            active    = {},
            replacing = {},
            charConn  = nil,
        }
        local char, humanoid, Animator = nil, nil, nil
        local function _resolveCharacter()
            char     = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
            humanoid = char:WaitForChild("Humanoid")
            Animator = humanoid:FindFirstChildOfClass("Animator")
                    or Instance.new("Animator", humanoid)
        end
        local ANIM_DB  = { FishCaught={}, EquipIdle={}, RodThrow={}, ReelStart={}, ReelingIdle={}, ReelIntermission={} }
        local LOOPED   = { EquipIdle=true, ReelingIdle=true }
        local PRIORITY = {
            FishCaught       = Enum.AnimationPriority.Action4,
            EquipIdle        = Enum.AnimationPriority.Action3,
            RodThrow         = Enum.AnimationPriority.Action4,
            ReelStart        = Enum.AnimationPriority.Action4,
            ReelingIdle      = Enum.AnimationPriority.Action3,
            ReelIntermission = Enum.AnimationPriority.Action4,
        }
        local PATTERNS = {
            ReelingIdle      = { "reelingidle", "reeling idle" },
            ReelIntermission = { "reelintermission", "reel intermission" },
            ReelStart        = { "reelstart", "reel start" },
            RodThrow         = { "rodthrow", "rod throw" },
            FishCaught       = { "fishcaught", "fish caught" },
            EquipIdle        = { "equipidle", "equip idle" },
        }
        local DETECT_ORDER = { "ReelingIdle","ReelIntermission","ReelStart","RodThrow","FishCaught","EquipIdle" }
        local skinNames  = {}
        local _dbScanned = false
        local function _scanAnimDB()
            if _dbScanned then return end
            _dbScanned = true
            local ok, AnimsModule = pcall(function()
                return require(ReplicatedStorage.Modules.Animations)
            end)
            if not ok or not AnimsModule then return end
            for animKey, animData in pairs(AnimsModule) do
                if type(animKey) ~= "string" or type(animData) ~= "table" then continue end
                if animData.Disabled then continue end
                local nameLower    = string.lower(animKey)
                local detectedType = nil
                for _, t in ipairs(DETECT_ORDER) do
                    for _, p in ipairs(PATTERNS[t]) do
                        if string.find(nameLower, p, 1, true) then
                            detectedType = t
                            break
                        end
                    end
                    if detectedType then break end
                end
                if not detectedType then continue end
                local skinName = string.match(animKey, "^(.-)%s*%-")
                if not skinName or skinName == "" then continue end
                skinName = skinName:match("^%s*(.-)%s*$")
                local animId = nil
                if animData.Animation and animData.Animation.AnimationId then
                    animId = animData.Animation.AnimationId
                elseif animData.AnimationId then
                    animId = animData.AnimationId
                end
                if not animId or animId == "" then continue end
                ANIM_DB[detectedType][skinName] = animId
                local found = false
                for _, v in ipairs(skinNames) do if v == skinName then found = true; break end end
                if not found then table.insert(skinNames, skinName) end
            end
        end
        local function _isCustom(track)
            if not track then return false end
            local n = string.lower(track.Name or "")
            return string.find(n, "_pool_") ~= nil
        end
        local function _detectType(track)
            if not track then return nil end
            if _isCustom(track) then return nil end
            local sources = {
                string.lower(track.Name or ""),
            }
            if track.Animation then
                table.insert(sources, string.lower(track.Animation.Name or ""))
            end
            for _, src in ipairs(sources) do
                for _, t in ipairs(DETECT_ORDER) do
                    for _, p in ipairs(PATTERNS[t]) do
                        if string.find(src, p, 1, true) then return t end
                    end
                end
            end
            return nil
        end
        local function _loadPool(animType, skinName)
            local animId = ANIM_DB[animType] and ANIM_DB[animType][skinName]
            if not animId then return false end
            if _skinAnim.pools[animType] then
                for _, t in ipairs(_skinAnim.pools[animType]) do
                    pcall(function() t:Stop(0); t:Destroy() end)
                end
            end
            _skinAnim.pools[animType]     = {}
            _skinAnim.poolIdx[animType]   = 1
            _skinAnim.active[animType]    = nil
            _skinAnim.replacing[animType] = false
            local isLooped = LOOPED[animType] or false
            local priority = PRIORITY[animType] or Enum.AnimationPriority.Action4
            local anim = Instance.new("Animation")
            anim.AnimationId = animId
            anim.Name        = "CUSTOM_" .. animType:upper()
            local poolSize = isLooped and 1 or 3
            for i = 1, poolSize do
                local ok, track = pcall(function() return Animator:LoadAnimation(anim) end)
                if ok and track then
                    track.Priority = priority
                    track.Looped   = isLooped
                    track.Name     = animType .. "_POOL_" .. i
                    table.insert(_skinAnim.pools[animType], track)
                end
            end
            anim:Destroy()
            return #_skinAnim.pools[animType] > 0
        end
        local function _loadAllPools(skinName)
            local any = false
            for t in pairs(ANIM_DB) do
                if _loadPool(t, skinName) then any = true end
            end
            return any
        end
        local function _stopCustomExcept(except)
            for t, track in pairs(_skinAnim.active) do
                if t ~= except and track and track.IsPlaying then
                    pcall(function() track:Stop(0.1) end)
                    _skinAnim.active[t] = nil
                end
            end
        end
        local function _replace(origTrack, animType)
            if _skinAnim.replacing[animType] then
                _skinAnim.killed[origTrack] = tick()
                pcall(function() origTrack:Stop(0); origTrack:AdjustSpeed(0) end)
                return
            end
            local current = _skinAnim.active[animType]
            if current and current.IsPlaying then
                _skinAnim.killed[origTrack] = tick()
                pcall(function() origTrack:Stop(0); origTrack:AdjustSpeed(0) end)
                return
            end
            local pool = _skinAnim.pools[animType]
            if not pool or #pool == 0 then return end
            _skinAnim.replacing[animType] = true
            _skinAnim.killed[origTrack]   = tick()
            pcall(function()
                origTrack:Stop(0)
                origTrack:AdjustSpeed(0)
                origTrack.TimePosition = 0
            end)
            if animType == "FishCaught" then
                _stopCustomExcept("FishCaught")
                for _, t in ipairs(humanoid:GetPlayingAnimationTracks()) do
                    if not _isCustom(t) and not _skinAnim.killed[t] then
                        _skinAnim.killed[t] = tick()
                        pcall(function() t:Stop(0); t:AdjustSpeed(0) end)
                    end
                end
            elseif not LOOPED[animType] then
                for ot, ot2 in pairs(_skinAnim.active) do
                    if ot ~= animType and not LOOPED[ot] and ot ~= "FishCaught" and ot2 and ot2.IsPlaying then
                        pcall(function() ot2:Stop(0.1) end)
                        _skinAnim.active[ot] = nil
                    end
                end
            end
            local nextTrack = nil
            for _, t in ipairs(pool) do
                if not t.IsPlaying then nextTrack = t; break end
            end
            if not nextTrack then
                local idx = (_skinAnim.poolIdx[animType] or 1) % #pool + 1
                _skinAnim.poolIdx[animType] = idx
                nextTrack = pool[idx]
                pcall(function() nextTrack:Stop(0) end)
            end
            pcall(function()
                nextTrack.Looped = LOOPED[animType] or false
                nextTrack:Play(0, 1, 1)
                nextTrack:AdjustSpeed(1)
            end)
            _skinAnim.active[animType] = nextTrack
            local conn; conn = nextTrack.Stopped:Connect(function()
                if _skinAnim.active[animType] == nextTrack then
                    _skinAnim.active[animType] = nil
                end
                if conn then conn:Disconnect(); conn = nil end
            end)
            _skinAnim.replacing[animType] = false
            task.delay(2, function() _skinAnim.killed[origTrack] = nil end)
        end
        local function _disconnectConns()
            for _, c in pairs(_skinAnim.conns) do
                if typeof(c) == "RBXScriptConnection" then c:Disconnect() end
            end
            _skinAnim.conns = {}
        end
        local function _setupConns()
            if next(_skinAnim.conns) then _disconnectConns() end
            _skinAnim.conns.animPlayed = humanoid.AnimationPlayed:Connect(function(track)
                if not _skinAnim.enabled or _isCustom(track) then return end
                local t = _detectType(track)
                if t and _skinAnim.pools[t] and #_skinAnim.pools[t] > 0 then
                    task.spawn(function() _replace(track, t) end)
                end
            end)
            local _hbSkip = 0
            _skinAnim.conns.heartbeat = RunService.Heartbeat:Connect(function()
                if not _skinAnim.enabled then return end
                _hbSkip += 1
                if _hbSkip < 45 then return end
                _hbSkip = 0
                local tracks = humanoid:GetPlayingAnimationTracks()
                for i = 1, #tracks do
                    local track = tracks[i]
                    if _isCustom(track) or not track.IsPlaying then continue end
                    if _skinAnim.killed[track] then
                        pcall(function() track:Stop(0); track:AdjustSpeed(0) end)
                        continue
                    end
                    local t = _detectType(track)
                    if not t or not (_skinAnim.pools[t] and #_skinAnim.pools[t] > 0) then continue end
                    local cur = _skinAnim.active[t]
                    if not cur or not cur.IsPlaying then
                        task.spawn(function() _replace(track, t) end)
                    else
                        _skinAnim.killed[track] = tick()
                        pcall(function() track:Stop(0); track:AdjustSpeed(0) end)
                    end
                end
            end)
        end
        local function _fullReset()
            _skinAnim.killed    = setmetatable({}, {__mode = "k"})
            _skinAnim.active    = {}
            _skinAnim.replacing = {}
        end
        local function _stopAllPools()
            for _, pool in pairs(_skinAnim.pools) do
                for _, t in ipairs(pool) do
                    pcall(function() t:Stop(0) end)
                end
            end
        end
        local function _ensureAnimDB()
            if not _dbScanned then
                _scanAnimDB()
                if #skinNames > 0 then
                    _skinAnim.current = skinNames[1]
                end
            end
        end
        local _skinDropdownRef = nil
        _skinDropdownRef = SkinSection:AddDropdown({
            Title    = "Select Skin",
            Options  = skinNames,
            Default  = "",
            NoSave   = false,
            Callback = function(selected)
                _ensureAnimDB()
                _skinAnim.current = selected
                if _skinAnim.enabled then
                    _fullReset()
                    _loadAllPools(selected)
                end
            end,
        })
        SkinSection:AddButton({
            Title    = "Refresh Skin List",
            Callback = function()
                _dbScanned = false
                skinNames = {}
                _scanAnimDB()
                if _skinDropdownRef then
                    pcall(function()
                        if _skinDropdownRef.Refresh then
                            _skinDropdownRef:Refresh(skinNames, true)
                        elseif _skinDropdownRef.SetOptions then
                            _skinDropdownRef:SetOptions(skinNames)
                        end
                    end)
                end
                Library:MakeNotify({
                    Title       = "Skin Anim",
                    Description = #skinNames > 0 and ("Loaded " .. #skinNames .. " skins.") or "Skin database kosong!",
                    Delay       = 2,
                })
            end,
        })
        SkinSection:AddToggle({
            Title    = "Enable Skin Animation",
            Default  = false,
            NoSave   = true,
            Callback = function(on)
                _skinAnim.enabled = on
                if on then
                    if _skinAnim.current == "" then
                        Library:MakeNotify({ Title = "Skin Anim", Description = "Pilih skin dulu!", Delay = 3 })
                        return
                    end
                    if not char or not char.Parent then
                        _resolveCharacter()
                    end
                    local ok = _loadAllPools(_skinAnim.current)
                    if not ok then
                        Library:MakeNotify({ Title = "Skin Anim", Description = "Skin tidak ditemukan di database!", Delay = 3 })
                        return
                    end
                    _fullReset()
                    _setupConns()
                    if not _skinAnim.charConn then
                        _skinAnim.charConn = LocalPlayer.CharacterAdded:Connect(function(newChar)
                            task.wait(1.5)
                            char     = newChar
                            humanoid = char:WaitForChild("Humanoid")
                            Animator = humanoid:FindFirstChildOfClass("Animator")
                                    or Instance.new("Animator", humanoid)
                            _fullReset()
                            if _skinAnim.enabled and _skinAnim.current ~= "" then
                                task.wait(0.5)
                                _loadAllPools(_skinAnim.current)
                                _disconnectConns()
                                _setupConns()
                            end
                        end)
                    end
                    Library:MakeNotify({ Title = "Skin Anim", Description = "Skin Animation aktif!", Delay = 2 })
                else
                    _disconnectConns()
                    _stopAllPools()
                    _fullReset()
                    if _skinAnim.charConn then
                        _skinAnim.charConn:Disconnect()
                        _skinAnim.charConn = nil
                    end
                    Library:MakeNotify({ Title = "Skin Anim", Description = "Skin Animation dihentikan.", Delay = 2 })
                end
            end,
        })
    end
    do
        local EmoteSection = SkinTab:AddSection("Emote", false)
        local _emote = {
            selected = "",
            enabled  = false,
            charConn = nil,
            loopTask = nil,
            track    = nil,
            loaded   = {},
            dataMap  = {},
            list     = {},
        }
        local _emoteLoaded = false
        local _emoteDropdownRef = nil
        local function _loadEmoteList()
            if _emoteLoaded then return end
            _emoteLoaded = true
            local emotesFolder = ReplicatedStorage:FindFirstChild("Emotes")
            if not emotesFolder then return end
            for _, moduleScript in ipairs(emotesFolder:GetChildren()) do
                local ok, data = pcall(function() return require(moduleScript) end)
                if ok and type(data) == "table" and data.Data and data.Data.Name and data.AnimationId then
                    local displayName = data.Data.Name
                    _emote.list[#_emote.list + 1] = displayName
                    _emote.dataMap[displayName] = {
                        AnimationId = data.AnimationId,
                        Priority    = data.AnimationPriority or Enum.AnimationPriority.Action3,
                        Looped      = data.Looped           or false,
                        Speed       = data.PlaybackSpeed    or 1,
                    }
                end
            end
            table.sort(_emote.list)
            _emote.selected = _emote.list[1] or ""
            if _emoteDropdownRef and _emoteDropdownRef.Refresh then
                pcall(function() _emoteDropdownRef:Refresh(_emote.list, true) end)
            elseif _emoteDropdownRef and _emoteDropdownRef.SetOptions then
                pcall(function() _emoteDropdownRef:SetOptions(_emote.list) end)
            end
            if _emote.selected ~= "" and _emoteDropdownRef and _emoteDropdownRef.SetValue then
                pcall(function() _emoteDropdownRef:SetValue(_emote.selected) end)
            end
        end
        _emoteDropdownRef = EmoteSection:AddDropdown({
            Title    = "Select Emote",
            Options  = _emote.list,
            Default  = _emote.selected,
            NoSave   = false,
            Callback = function(v)
                _emote.selected = v
            end,
        })
        EmoteSection:AddButton({
            Title    = "Refresh Emote List",
            Callback = function()
                _emoteLoaded = false
                _emote.list = {}
                _emote.dataMap = {}
                _loadEmoteList()
                Library:MakeNotify({
                    Title       = "Emote",
                    Description = #_emote.list > 0 and ("Loaded " .. #_emote.list .. " emotes.") or "Emote folder tidak ditemukan!",
                    Delay       = 2,
                })
            end,
        })
        EmoteSection:AddToggle({
            Title    = "Enable Emote",
            Default  = false,
            NoSave   = true,
            Callback = function(on)
                _emote.enabled = on
                if on then
                    if _emote.selected == "" then
                        _loadEmoteList()
                    end
                    if _emote.selected == "" then
                        Library:MakeNotify({ Title = "Emote", Description = "Pilih emote dari dropdown dulu!", Delay = 2 })
                        _emote.enabled = false
                        return
                    end

                    local function getAnimator()
                        local char = LocalPlayer.Character
                        if not char then return nil end
                        local humanoid = char:FindFirstChildOfClass("Humanoid")
                        if not humanoid then return nil end
                        return humanoid:FindFirstChildOfClass("Animator")
                            or Instance.new("Animator", humanoid)
                    end

                    local function stopEmote()
                        if _emote.track and _emote.track.IsPlaying then
                            pcall(function() _emote.track:Stop(0.2) end)
                        end
                        _emote.track = nil
                    end

                    local function playEmote(emoteName)
                        if not _emote.enabled then return end
                        local data = _emote.dataMap[emoteName]
                        if not data then return end
                        local animator = getAnimator()
                        if not animator then return end
                        stopEmote()
                        if not _emote.loaded[emoteName] then
                            local anim       = Instance.new("Animation")
                            anim.AnimationId = data.AnimationId
                            local ok, track  = pcall(function() return animator:LoadAnimation(anim) end)
                            if not ok or not track then return end
                            _emote.loaded[emoteName] = track
                        end
                        local track    = _emote.loaded[emoteName]
                        track.Priority = data.Priority
                        track.Looped   = data.Looped
                        pcall(function() track:Play(0.1, 1, data.Speed) end)
                        _emote.track = track
                    end

                    playEmote(_emote.selected)

                    if _emote.charConn then _emote.charConn:Disconnect(); _emote.charConn = nil end
                    _emote.charConn = LocalPlayer.CharacterAdded:Connect(function()
                        _emote.loaded = {}
                        _emote.track  = nil
                        if _emote.enabled and _emote.selected ~= "" then
                            task.wait(1)
                            playEmote(_emote.selected)
                        end
                    end)

                    if _emote.loopTask then pcall(task.cancel, _emote.loopTask); _emote.loopTask = nil end
                    _emote.loopTask = task.spawn(function()
                        while _emote.enabled do
                            task.wait(0.5)
                            if not _emote.track or not _emote.track.IsPlaying then
                                playEmote(_emote.selected)
                            end
                        end
                    end)
                else
                    if _emote.charConn then _emote.charConn:Disconnect(); _emote.charConn = nil end
                    if _emote.loopTask then pcall(task.cancel, _emote.loopTask); _emote.loopTask = nil end
                    if _emote.track and _emote.track.IsPlaying then
                        pcall(function() _emote.track:Stop(0.2) end)
                    end
                    _emote.track  = nil
                    _emote.loaded = {}
                end
            end,
        })
    end
end

-- [Quest Tab]
do
    local _data = nil
    pcall(function()
        _data = require(ReplicatedStorage.Packages.Replion).Client:WaitReplion("Data")
    end)
    local _CollService = game:GetService("CollectionService")
    local _jungleCache = nil
    local function _getJungle()
        if _jungleCache and _jungleCache.Parent then return _jungleCache end
        _jungleCache = workspace:FindFirstChild("JUNGLE INTERACTIONS")
        return _jungleCache
    end
    local function _getRoot()
        local char = LocalPlayer.Character
        return char and char:FindFirstChild("HumanoidRootPart")
    end
    local _artifactPositions = {
        ["Arrow Artifact"]             = CFrame.new(875,  3,   -368) * CFrame.Angles(0, math.rad(90),   0),
        ["Crescent Artifact"]          = CFrame.new(1403, 3,    123) * CFrame.Angles(0, math.rad(180),  0),
        ["Hourglass Diamond Artifact"] = CFrame.new(1487, 3,   -842) * CFrame.Angles(0, math.rad(180),  0),
        ["Diamond Artifact"]           = CFrame.new(1844, 3,   -287) * CFrame.Angles(0, math.rad(-90),  0),
    }
    local _artifactOrder = {
        "Arrow Artifact", "Crescent Artifact",
        "Hourglass Diamond Artifact", "Diamond Artifact",
    }
    local _artifactIds = {
        ["Arrow Artifact"]             = 265,
        ["Crescent Artifact"]          = 266,
        ["Diamond Artifact"]           = 267,
        ["Hourglass Diamond Artifact"] = 271,
    }
    local _fishTargetIds = {
        ["Freshwater Piranha"]    = 284,
        ["Goliath Tiger"]         = 270,
        ["Sacred Guardian Squid"] = 283,
        ["Crocodile"]             = 263,
    }
    local _ruinTiers = {
        "Freshwater Piranha",
        "Goliath Tiger",
        "Sacred Guardian Squid",
        "Crocodile",
    }
    local _TP_MIN_DIST = 5
    local function _tp(cf, force)
        local root = _getRoot()
        if not root then return end
        local targetCF  = typeof(cf) == "Vector3" and CFrame.new(cf) or cf
        local targetPos = targetCF.Position
        if not force then
            if (root.Position - targetPos).Magnitude <= _TP_MIN_DIST then return end
        end
        local rng    = Random.new()
        local jitter = Vector3.new(rng:NextNumber(-2, 2), 0, rng:NextNumber(-2, 2))
        root.CFrame  = CFrame.new(targetPos + jitter) * (targetCF - targetCF.Position)
    end
    local function _isQuestCompleted(questName)
        if not _data then return false end
        local ok, cq = pcall(function() return _data:Get({"CompletedQuests"}) end)
        if not ok or type(cq) ~= "table" then return false end
        for _, v in pairs(cq) do
            if tostring(v) == questName then return true end
        end
        return false
    end
    local function _getElemData()
        if not _data then return nil end
        local ok, eq = pcall(function()
            return _data:Get({"Quests", "Mainline", "Element Quest"})
        end)
        if not ok or type(eq) ~= "table" then return nil end
        return eq
    end
    local function _getElemStage()
        if _isQuestCompleted("Element Quest") then return "DONE" end
        local eq = _getElemData()
        if not eq then return "STAGE1" end
        _ELEM_GOALS = { 1, 1, 1, 3 }
        local function _getObjProg(idx)
            if not eq.Objectives then return 0, _ELEM_GOALS[idx] end
            local obj = eq.Objectives[idx]
            if not obj then return 0, _ELEM_GOALS[idx] end
            return obj.Progress or 0, _ELEM_GOALS[idx]
        end
        local p1, g1 = _getObjProg(1)
        local p2, g2 = _getObjProg(2)
        local p3, g3 = _getObjProg(3)
        local p4, g4 = _getObjProg(4)
        if p4 >= g4 then return "DONE"
        elseif p3 >= g3 then return "STAGE3"
        elseif p2 >= g2 then return "STAGE2"
        else return "STAGE1" end
    end
    local function _getDeepStage()
        if _isQuestCompleted("Deep Sea Quest") then return "DONE" end
        if not _data then return "SISYPHUS" end
        local ok, dq = pcall(function()
            return _data:Get({"Quests", "Mainline", "Deep Sea Quest"})
        end)
        if not ok or type(dq) ~= "table" then return "SISYPHUS" end
        _DEEP_GOALS = { 300, 3, 1, 1000000 }
        local function _getObjProg(idx)
            if not dq.Objectives then return 0, _DEEP_GOALS[idx] end
            local obj = dq.Objectives[idx]
            if not obj then return 0, _DEEP_GOALS[idx] end
            return obj.Progress or 0, _DEEP_GOALS[idx]
        end
        local p1, g1 = _getObjProg(1)
        local p2, g2 = _getObjProg(2)
        local p3, g3 = _getObjProg(3)
        local p4, g4 = _getObjProg(4)
        if p4 >= g4 then return "DONE"
        elseif p3 >= g3 and p2 >= g2 and p1 >= g1 then return "COINS"
        elseif p3 >= g3 and p2 >= g2 then return "TREASURE"
        else return "SISYPHUS"
        end
    end
    local function _hasArtifactInInventory(artifactName)
        if not _data then return false end
        local targetId = _artifactIds[artifactName]
        if not targetId then return false end
        local ok, inv = pcall(function() return _data:Get({"Inventory"}) end)
        if not ok or not inv then return false end
        for _, bucket in ipairs({ inv.Items, inv.Gears, inv.Artifacts }) do
            if bucket then
                for _, item in pairs(bucket) do
                    if item and tonumber(item.Id) == targetId then return true end
                end
            end
        end
        return false
    end
    local function _triggerLeverByType(leverType)
        local remote = NetEvents.RE_PlaceLeverItem
        if remote then
            local ok = pcall(function() remote:FireServer(leverType) end)
            if ok then return true end
        end
        local ji = _getJungle()
        if not ji then return false end
        for _, v in ipairs(ji:GetDescendants()) do
            if v:IsA("Model") and v.Name == "TempleLever"
                and v:GetAttribute("Type") == leverType
            then
                local prompt = v:FindFirstChild("RootPart")
                    and v.RootPart:FindFirstChildWhichIsA("ProximityPrompt")
                if prompt then fireproximityprompt(prompt); return true end
            end
        end
        return false
    end
    local function _leverIsDoneByType(leverType)
        if _data then
            local ok, tl = pcall(function() return _data:GetExpect({"TempleLevers"}) end)
            if ok and tl and tl[leverType] then return true end
            ok, tl = pcall(function() return _data:Get({"TempleLevers"}) end)
            if ok and tl and tl[leverType] then return true end
        end
        local ji = _getJungle()
        if not ji then return false end
        for _, v in ipairs(ji:GetDescendants()) do
            if v:IsA("Model") and v.Name == "TempleLever"
                and v:GetAttribute("Type") == leverType
            then
                local prompt = v:FindFirstChild("RootPart")
                    and v.RootPart:FindFirstChildWhichIsA("ProximityPrompt")
                return (prompt == nil)
            end
        end
        return false
    end
    local function _artifactIsDone(name) return _leverIsDoneByType(name) end
    local _plateCache = nil
    local function _buildPlateCache()
        _plateCache = {}
        for _, part in ipairs(_CollService:GetTagged("PressurePlate")) do
            local t = part.Parent and part.Parent:GetAttribute("Type")
            if t then _plateCache[t] = part end
        end
    end
    local _plateAddedConn = nil
    local _plateRemovedConn = nil
    local function _connectPlateListeners()
        if _plateAddedConn then return end
        _plateAddedConn = _CollService:GetInstanceAddedSignal("PressurePlate"):Connect(function(part)
            local t = part.Parent and part.Parent:GetAttribute("Type")
            if t then
                if not _plateCache then _plateCache = {} end
                _plateCache[t] = part
            end
        end)
        _plateRemovedConn = _CollService:GetInstanceRemovedSignal("PressurePlate"):Connect(function(part)
            if not _plateCache then return end
            local t = part.Parent and part.Parent:GetAttribute("Type")
            if t then _plateCache[t] = nil end
        end)
    end
    local function _disconnectPlateListeners()
        if _plateAddedConn then _plateAddedConn:Disconnect(); _plateAddedConn = nil end
        if _plateRemovedConn then _plateRemovedConn:Disconnect(); _plateRemovedConn = nil end
        _plateCache = nil
    end
    local function _getPlateStatus()
        if not _data then return {} end
        local ok, rpp = pcall(function() return _data:Get({"RuinPressurePlates"}) end)
        return (ok and type(rpp) == "table" and rpp) or {}
    end
    local function _allRuinDone(status)
        for _, tier in ipairs(_ruinTiers) do
            if not status[tier] then return false end
        end
        return true
    end
    _art = _art or { enabled = false }
    _deep = _deep or { enabled = false }
    _elem = _elem or { enabled = false }
    _ruin = _ruin or { enabled = false }
    local function _qMark(ok)
        return ok
            and '<font color="rgb(123,239,178)">[●]</font>'
            or '<font color="rgb(255,100,100)">[●]</font>'
    end
    local function _qLine(ok, label, detail)
        if detail and detail ~= "" then
            return ("%s %s <font color=\"rgb(170,170,170)\">(%s)</font>"):format(_qMark(ok), label, detail)
        end
        return ("%s %s"):format(_qMark(ok), label)
    end
    local _displayRefs = {}
    local _dashboardThread = nil
    local function _anyQuestDashActive()
        return (_art and _art.enabled) or (_deep and _deep.enabled) or (_elem and _elem.enabled) or (_ruin and _ruin.enabled)
    end
    local function _stopQuestDashboardIfIdle()
        if _anyQuestDashActive() then return end
        if _dashboardThread then pcall(task.cancel, _dashboardThread); _dashboardThread = nil end
    end
    local function _startQuestDashboard()
        if _dashboardThread then return end
        _dashboardThread = task.spawn(function()
            while _anyQuestDashActive() do
                local artOn = _art and _art.enabled
                local deepOn = _deep and _deep.enabled
                local elemOn = _elem and _elem.enabled
                local ruinOn = _ruin and _ruin.enabled
                local interval = 2
                pcall(function()
                local artRef = _displayRefs.artifact
                if artOn and artRef and artRef.SetContent then
                    local lines = {}
                    for _, name in ipairs(_artifactOrder) do
                        local label = name:gsub(" Artifact", "")
                        table.insert(lines, _qLine(_artifactIsDone(name), label))
                    end
                    artRef:SetContent(table.concat(lines, "\n"))
                end

                local deepRef = _displayRefs.deepSea
                if deepOn and deepRef and deepRef.SetContent then
                    if not _data then
                        deepRef:SetContent("Menunggu data...")
                    elseif _isQuestCompleted("Deep Sea Quest") then
                        deepRef:SetContent(_qLine(true, "Deep Sea Quest selesai"))
                    else
                        local ok, dq = pcall(function()
                            return _data:Get({"Quests", "Mainline", "Deep Sea Quest"})
                        end)
                        if ok and type(dq) == "table" then
                            local _DEEP_GOALS = { 300, 3, 1, 1000000 }
                            local function _getObjProg(idx)
                                if not dq.Objectives then return 0, _DEEP_GOALS[idx] end
                                local obj = dq.Objectives[idx]
                                if not obj then return 0, _DEEP_GOALS[idx] end
                                return obj.Progress or 0, _DEEP_GOALS[idx]
                            end
                            local objNames = {
                                "Catch 300 Rare/Epic @ Treasure Room",
                                "Catch 3 Mythic @ Sisyphus Statue",
                                "Catch 1 SECRET @ Sisyphus Statue",
                                "Earn 1M Coins",
                            }
                            local lines = {}
                            for i, name in ipairs(objNames) do
                                local prog, goal = _getObjProg(i)
                                local done = prog >= goal
                                table.insert(lines, _qLine(done, name, done and "DONE" or ("%d/%d"):format(prog, goal)))
                            end
                            deepRef:SetContent(table.concat(lines, "\n"))
                        else
                            deepRef:SetContent("Menunggu data quest...")
                        end
                    end
                end

                local elemRef = _displayRefs.element
                if elemOn and elemRef and elemRef.SetContent then
                    if not _data then
                        elemRef:SetContent("Menunggu data...")
                    elseif _isQuestCompleted("Element Quest") then
                        elemRef:SetContent(_qLine(true, "Element Quest selesai"))
                    else
                        local eq = _getElemData()
                        if eq then
                            local _ELEM_GOALS = { 1, 1, 1, 3 }
                            local function _getObjProg(idx)
                                if not eq.Objectives then return 0, _ELEM_GOALS[idx] end
                                local obj = eq.Objectives[idx]
                                if not obj then return 0, _ELEM_GOALS[idx] end
                                return obj.Progress or 0, _ELEM_GOALS[idx]
                            end
                            local objNames = {
                                "Own Ghostfinn Rod",
                                "Catch SECRET @ Ancient Jungle",
                                "Catch SECRET @ Sacred Temple",
                                "Create Transcended Stones",
                            }
                            local lines = {}
                            for i, name in ipairs(objNames) do
                                local prog, goal = _getObjProg(i)
                                local done = prog >= goal
                                table.insert(lines, _qLine(done, name, done and "DONE" or ("%d/%d"):format(prog, goal)))
                            end
                            elemRef:SetContent(table.concat(lines, "\n"))
                        else
                            elemRef:SetContent("Menunggu data quest...")
                        end
                    end
                end

                local ruinRef = _displayRefs.ruin
                if ruinOn and ruinRef and ruinRef.SetContent then
                    if not _data then
                        ruinRef:SetContent("Menunggu data sync...")
                    else
                        local status = _getPlateStatus()
                        if _allRuinDone(status) then
                            ruinRef:SetContent(_qLine(true, "Semua plate selesai"))
                        else
                            local lines = {}
                            for _, tier in ipairs(_ruinTiers) do
                                table.insert(lines, _qLine(status[tier], tier))
                            end
                            ruinRef:SetContent(table.concat(lines, "\n"))
                        end
                    end
                end

                local hasParagraph = false
                local allQuestIdle = true
                if artOn and artRef and artRef.SetContent then
                    hasParagraph = true
                    for _, name in ipairs(_artifactOrder) do
                        if not _artifactIsDone(name) then allQuestIdle = false break end
                    end
                end
                if deepOn and deepRef and deepRef.SetContent then
                    hasParagraph = true
                    if not _isQuestCompleted("Deep Sea Quest") then allQuestIdle = false end
                end
                if elemOn and elemRef and elemRef.SetContent then
                    hasParagraph = true
                    if not _isQuestCompleted("Element Quest") then allQuestIdle = false end
                end
                if ruinOn and ruinRef and ruinRef.SetContent then
                    hasParagraph = true
                    local st = _getPlateStatus()
                    if not _allRuinDone(st) then allQuestIdle = false end
                end
                if hasParagraph and allQuestIdle then
                    interval = 60
                elseif not hasParagraph then
                    interval = 15
                end
                end)
                task.wait(interval)
            end
            _dashboardThread = nil
        end)
    end

    local QuestTab = MainWindow:AddTab({ Name = "Quest", Icon = "scroll" })

    do
        _art = { enabled = false, thread = nil, fishConn = nil }
        local ArtSection = QuestTab:AddSection("Artifact Lever", false)
        local _artPara   = ArtSection:AddParagraph({
            Title = "Artifact Status",
            Content = "Nyalakan Auto Artifact Progress untuk memuat status.",
        })
        _displayRefs.artifact = _artPara
        ArtSection:AddToggle({
            Title    = "Auto Artifact Progress",
            Default  = false,
            Callback = function(on)
                _art.enabled = on
                if _art.fishConn then _art.fishConn:Disconnect(); _art.fishConn = nil end
                if _art.thread   then task.cancel(_art.thread);   _art.thread   = nil end
                if not on then
                    pcall(function()
                        _artPara:SetContent("Nyalakan Auto Artifact Progress untuk memuat status.")
                    end)
                    _stopQuestDashboardIfIdle()
                    return
                end
                _startQuestDashboard()
                _art.thread = task.spawn(function()
                    while _art.enabled do
                        local allDone = true
                        for _, name in ipairs(_artifactOrder) do
                            if not _artifactIsDone(name) then
                                allDone = false
                                if _hasArtifactInInventory(name) then
                                    local root = _getRoot()
                                    if root and _artifactPositions[name] then
                                        root.CFrame = _artifactPositions[name]
                                        task.wait(1.5)
                                    end
                                    local triggered = _triggerLeverByType(name)
                                    if not triggered then task.wait(1.5); _triggerLeverByType(name) end
                                    local dl = tick() + 10
                                    repeat task.wait(0.5) until _artifactIsDone(name) or tick() > dl
                                else
                                    local root = _getRoot()
                                    if root and _artifactPositions[name] then
                                        root.CFrame = _artifactPositions[name]
                                    end
                                    local got = false
                                    local fishEvent = NetEvents.RE_FishCaught
                                    if fishEvent then
                                        local conn
                                        conn = fishEvent.OnClientEvent:Connect(function()
                                            if not _art.enabled then conn:Disconnect(); return end
                                            if _hasArtifactInInventory(name) then
                                                got = true; conn:Disconnect()
                                            end
                                        end)
                                        _art.fishConn = conn
                                    end
                                    local dl = tick() + 90
                                    repeat
                                        task.wait(2)
                                        if _hasArtifactInInventory(name) then got = true end
                                    until got or not _art.enabled or tick() > dl
                                    if _art.fishConn then
                                        _art.fishConn:Disconnect(); _art.fishConn = nil
                                    end
                                    if got and _art.enabled then
                                        local root2 = _getRoot()
                                        if root2 and _artifactPositions[name] then
                                            root2.CFrame = _artifactPositions[name]
                                            task.wait(1.5)
                                        end
                                        local triggered = _triggerLeverByType(name)
                                        if not triggered then task.wait(1.5); _triggerLeverByType(name) end
                                        local dl2 = tick() + 10
                                        repeat task.wait(0.5) until _artifactIsDone(name) or tick() > dl2
                                    end
                                end
                                break
                            end
                        end
                        if allDone then
                            _art.enabled = false
                            Library:MakeNotify({
                                Title = "Artifact", Description = "Semua artifact selesai!",
                                Color = Color3.fromRGB(123, 239, 178), Delay = 3,
                            })
                            break
                        end
                        task.wait(1)
                    end
                    if _art.fishConn then _art.fishConn:Disconnect(); _art.fishConn = nil end
                end)
            end,
        })
        ArtSection:AddButton({ Title = "TP: Arrow Artifact",
            Callback = function() _tp(_artifactPositions["Arrow Artifact"]) end })
        ArtSection:AddButton({ Title = "TP: Crescent Artifact",
            Callback = function() _tp(_artifactPositions["Crescent Artifact"]) end })
        ArtSection:AddButton({ Title = "TP: Hourglass Diamond Artifact",
            Callback = function() _tp(_artifactPositions["Hourglass Diamond Artifact"]) end })
        ArtSection:AddButton({ Title = "TP: Diamond Artifact",
            Callback = function() _tp(_artifactPositions["Diamond Artifact"]) end })
    end

    do
        _deep = { enabled = false, thread = nil }
        local _lastDeepStage = nil
        local DeepSection = QuestTab:AddSection("Deep Sea Quest", false)
        local _deepPara   = DeepSection:AddParagraph({
            Title = "Deep Sea Tracker",
            Content = "Nyalakan Auto Deep Sea Quest untuk memuat status.",
        })
        _displayRefs.deepSea = _deepPara
        local _DEEP_LOCS = {
            treasure = CFrame.lookAt(Vector3.new(-3599, -276, -1641), Vector3.new(-3722.606, -275.674, -1558.736)),
            sisyphus = CFrame.lookAt(Vector3.new(-3763, -135, -995),  Vector3.new(-3698, -135, -1008)),
        }
        DeepSection:AddToggle({
            Title    = "Auto Deep Sea Quest",
            Default  = false,
            NoSave   = true,
            Callback = function(on)
                _deep.enabled = on
                if _deep.thread then task.cancel(_deep.thread); _deep.thread = nil end
                if not on then
                    _lastDeepStage = nil
                    pcall(function()
                        _deepPara:SetContent("Nyalakan Auto Deep Sea Quest untuk memuat status.")
                    end)
                    _stopQuestDashboardIfIdle()
                    return
                end
                _startQuestDashboard()
                _deep.thread = task.spawn(function()
                    while _deep.enabled do
                        pcall(function()
                            local stage = _getDeepStage()
                            if stage == "DONE" then
                                _deep.enabled = false
                                Library:MakeNotify({
                                    Title       = "Deep Sea Quest",
                                    Description = "Deep Sea Quest selesai!",
                                    Color       = Color3.fromRGB(123, 239, 178),
                                    Delay       = 3,
                                })
                                return
                            end
                            if _lastDeepStage and _lastDeepStage ~= stage then
                                Library:MakeNotify({
                                    Title       = "Deep Sea Quest",
                                    Description = "Stage berubah! Pindah lokasi...",
                                    Color       = Color3.fromRGB(100, 180, 255),
                                    Delay       = 3,
                                })
                            end
                            _lastDeepStage = stage
                            local targetCF = nil
                            if stage == "SISYPHUS" then
                                targetCF = _DEEP_LOCS.sisyphus
                            elseif stage == "TREASURE" then
                                targetCF = _DEEP_LOCS.treasure
                            elseif stage == "COINS" then
                                targetCF = nil
                            end
                            if targetCF then
                                local root = _getRoot()
                                if root and (root.Position - targetCF.Position).Magnitude > 10 then
                                    _tp(targetCF, true)
                                end
                            end
                        end)
                        task.wait(1)
                    end
                end)
            end,
        })
        DeepSection:AddButton({ Title = "TP: Treasure Room",
            Callback = function() _tp(_DEEP_LOCS.treasure, true) end })
        DeepSection:AddButton({ Title = "TP: Sisyphus Statue",
            Callback = function() _tp(_DEEP_LOCS.sisyphus, true) end })
    end

    do
        _elem = { enabled = false, thread = nil }
        local ElemSection = QuestTab:AddSection("Element Quest", false)
        local _elemPara   = ElemSection:AddParagraph({
            Title = "Element Tracker",
            Content = "Nyalakan Auto Element Quest untuk memuat status.",
        })
        _displayRefs.element = _elemPara
        local _ELEM_LOCS = {
            stage1 = CFrame.new(1484, 3, -336) * CFrame.Angles(0, math.rad(180), 0),
            stage2 = CFrame.new(1453, -22, -636),
            stage3 = CFrame.new(1480, 128, -593),
        }
        local _lastStage = nil
        ElemSection:AddToggle({
            Title    = "Auto Element Quest",
            Default  = false,
            NoSave   = true,
            Callback = function(on)
                _elem.enabled = on
                if _elem.thread then task.cancel(_elem.thread); _elem.thread = nil end
                if not on then
                    _lastStage = nil
                    pcall(function()
                        _elemPara:SetContent("Nyalakan Auto Element Quest untuk memuat status.")
                    end)
                    _stopQuestDashboardIfIdle()
                    return
                end
                _startQuestDashboard()
                _elem.thread = task.spawn(function()
                    while _elem.enabled do
                        pcall(function()
                            local stage = _getElemStage()
                            if stage == "DONE" then
                                _elem.enabled = false
                                Library:MakeNotify({
                                    Title       = "Element Quest",
                                    Description = "Element Quest selesai!",
                                    Color       = Color3.fromRGB(123, 239, 178),
                                    Delay       = 3,
                                })
                                return
                            end
                            if _lastStage and _lastStage ~= stage then
                                Library:MakeNotify({
                                    Title       = "Element Quest",
                                    Description = "Stage berubah! Pindah lokasi...",
                                    Color       = Color3.fromRGB(100, 180, 255),
                                    Delay       = 3,
                                })
                            end
                            _lastStage = stage
                            local targetCF = nil
                            if stage == "STAGE1" then
                                targetCF = _ELEM_LOCS.stage1
                            elseif stage == "STAGE2" then
                                targetCF = _ELEM_LOCS.stage2
                            elseif stage == "STAGE3" then
                                targetCF = _ELEM_LOCS.stage3
                            end
                            if targetCF then
                                local root = _getRoot()
                                if root and (root.Position - targetCF.Position).Magnitude > 10 then
                                    _tp(targetCF, true)
                                end
                            end
                        end)
                        task.wait(1)
                    end
                end)
            end,
        })
        ElemSection:AddButton({ Title = "TP: Ancient Jungle (Stage 1)",
            Callback = function() _tp(_ELEM_LOCS.stage1, true) end })
        ElemSection:AddButton({ Title = "TP: Sacred Temple (Stage 2)",
            Callback = function() _tp(_ELEM_LOCS.stage2, true) end })
        ElemSection:AddButton({ Title = "TP: Transcended Stones (Stage Final)",
            Callback = function() _tp(_ELEM_LOCS.stage3, true) end })
        ElemSection:AddButton({ Title = "TP: Underground Cellar",
            Callback = function() _tp(CFrame.new(2136, -91, -701), true) end })
    end

    do
        local _diamond = { enabled = false, thread = nil, paraThread = nil }
        local _DIAMOND_NPC_CF = CFrame.new(
            -1775.255, -222.634995, 23922.1328,
            0.707134247, -0, -0.707079291,
            0, 1, -0,
            0.707079291, 0, 0.707134247
        )
        local _DIAMOND_NPC_NAMES = { "Diamond Researcher", "Lary the Scientist", "Lary" }
        local _DIAMOND_FISH_IDS = {
            ruby     = { Id = 243, Metadata = { VariantId = 3 } },
            lochness = { Id = 228 },
        }
        local _DIAMOND_LOCS = {
            coral         = CFrame.lookAt(Vector3.new(-2921.858, 3.250, 2083.297),  Vector3.new(-3068.679, 3.250, 2052.582)),
            tropical      = CFrame.lookAt(Vector3.new(-2140.796, 53.487, 3622.714), Vector3.new(-2216.205, 53.487, 3752.381)),
            treasure_room = CFrame.lookAt(Vector3.new(-3597.324, -275.674, -1641.224), Vector3.new(-3722.606, -275.674, -1558.736)),
            kohana        = CFrame.lookAt(Vector3.new(-655.469, 17.245, 501.038), Vector3.new(-511.246, 17.245, 542.266)),
        }
        local _DIAMOND_GOALS = { 1, 1, 1, 1, 1, 1000 }
        local DiamondSection  = QuestTab:AddSection("Diamond Researcher Quest", false)
        local _diamondParaRef = DiamondSection:AddParagraph({
            Title = "Diamond Quest Status",
            Content = "Nyalakan Auto Diamond Researcher untuk memuat status.",
        })
        local function _getDiamondQuestData()
            if not _data then return nil end
            local ok, q = pcall(function()
                return _data:Get({"Quests", "Mainline", "Diamond Researcher"})
            end)
            return (ok and q) or nil
        end
        local function _isDiamondDone()
            if not _data then return false end
            local cq = _data:Get({"CompletedQuests"}) or {}
            for _, v in ipairs(cq) do
                if v == "Diamond Researcher" then return true end
            end
            return false
        end
        local function _getObjProgress(q, idx)
            if not q or not q.Objectives then return 0, _DIAMOND_GOALS[idx] or 1 end
            local obj = q.Objectives[idx]
            if not obj then return 0, _DIAMOND_GOALS[idx] or 1 end
            return obj.Progress or 0, _DIAMOND_GOALS[idx] or 1
        end
        local function _hasItemInInventory(itemId, metadata)
            if not _data then return false end
            local ok, inv = pcall(function() return _data:Get({"Inventory"}) end)
            if not ok or not inv then return false end
            local buckets = { inv.Items, inv.Gears, inv.Artifacts, inv.Fish }
            for _, bucket in ipairs(buckets) do
                if bucket then
                    for _, item in pairs(bucket) do
                        if item and tonumber(item.Id) == itemId then
                            if metadata then
                                if item.Metadata and item.Metadata.VariantId == metadata.VariantId then
                                    return true
                                end
                            else
                                return true
                            end
                        end
                    end
                end
            end
            return false
        end
        local function _teleportTo(cf)
            local char = LocalPlayer.Character
            if not char then return end
            local root = char:FindFirstChild("HumanoidRootPart")
            if not root then return end
            if (root.Position - cf.Position).Magnitude > 10 then
                for i = 1, 3 do
                    root.CFrame = cf
                    task.wait(0.1)
                end
            end
        end
        local function _triggerNpcDialogue(path, index)
            local npcFolder = workspace:FindFirstChild("NPC")
            local triggered = false
            if npcFolder then
                for _, name in ipairs(_DIAMOND_NPC_NAMES) do
                    local npc = npcFolder:FindFirstChild(name)
                    if npc then
                        local prompt = npc:FindFirstChildWhichIsA("ProximityPrompt", true)
                        if prompt then
                            pcall(fireproximityprompt, prompt)
                            triggered = true
                            break
                        end
                    end
                end
            end
            if not triggered then
                for _, name in ipairs(_DIAMOND_NPC_NAMES) do
                    local npc = workspace:FindFirstChild(name, true)
                    if npc then
                        local prompt = npc:FindFirstChildWhichIsA("ProximityPrompt", true)
                        if prompt then
                            pcall(fireproximityprompt, prompt)
                            triggered = true
                            break
                        end
                    end
                end
            end
            if not triggered then return false end
            task.wait(1)
            pcall(function()
                NetEvents.RE_DialogueEnded:FireServer("Diamond Researcher", path, index)
            end)
            task.wait(1)
            return true
        end
        local function _stopDiamondParaLoop()
            if _diamond.paraThread then
                task.cancel(_diamond.paraThread)
                _diamond.paraThread = nil
            end
        end
        local function _startDiamondParaLoop()
            _stopDiamondParaLoop()
            _diamond.paraThread = task.spawn(function()
                while _diamond.enabled do
                    task.wait(2)
                    pcall(function()
                        if not (_diamondParaRef and _diamondParaRef.SetContent) then return end
                        if not _data then
                            _diamondParaRef:SetContent("Menunggu data...")
                            return
                        end
                        if _isDiamondDone() then
                            _diamondParaRef:SetContent(_qLine(true, "Diamond Researcher Quest selesai"))
                            _stopDiamondParaLoop()
                            return
                        end
                        local q = _getDiamondQuestData()
                        if not q then
                            _diamondParaRef:SetContent("Quest belum dimulai / data belum tersedia")
                            return
                        end
                        local lines = {}
                        local objNames = {
                            "Own Element Rod",
                            "Catch SECRET @ Coral Reefs",
                            "Catch SECRET @ Tropical Grove",
                            "Submit Ruby Mutated",
                            "Submit Lochness Monster",
                            "Catch 1000 PERFECT fish",
                        }
                        for i, name in ipairs(objNames) do
                            local prog, goal = _getObjProgress(q, i)
                            local done = prog >= goal
                            table.insert(lines, _qLine(done, name, done and "DONE" or ("%d/%d"):format(prog, goal)))
                        end
                        _diamondParaRef:SetContent(table.concat(lines, "\n"))
                    end)
                end
                _diamond.paraThread = nil
            end)
        end
        DiamondSection:AddToggle({
            Title    = "Auto Diamond Researcher Quest",
            Default  = false,
            NoSave   = true,
            Callback = function(on)
                _diamond.enabled = on
                if on then
                    if _diamond.thread then
                        task.cancel(_diamond.thread)
                        _diamond.thread = nil
                    end
                    _startDiamondParaLoop()
                    _diamond.thread = task.spawn(function()
                        while _diamond.enabled do
                            pcall(function()
                                if not _data then task.wait(3); return end
                                if _isDiamondDone() then
                                    _diamond.enabled = false
                                    _stopDiamondParaLoop()
                                    pcall(function()
                                        _diamondParaRef:SetContent(_qLine(true, "Diamond Researcher Quest selesai"))
                                    end)
                                    Library:MakeNotify({
                                        Title       = "Diamond Researcher",
                                        Description = "Quest selesai!",
                                        Color       = Color3.fromRGB(123, 239, 178),
                                        Delay       = 3,
                                    })
                                    return
                                end
                                local q = _getDiamondQuestData()
                                if not q then
                                    _teleportTo(_DIAMOND_NPC_CF)
                                    task.wait(2)
                                    _triggerNpcDialogue(1, 1)
                                    task.wait(2)
                                    return
                                end
                                local p1, g1 = _getObjProgress(q, 1)
                                local p2, g2 = _getObjProgress(q, 2)
                                local p3, g3 = _getObjProgress(q, 3)
                                local p4, g4 = _getObjProgress(q, 4)
                                local p5, g5 = _getObjProgress(q, 5)
                                local p6, g6 = _getObjProgress(q, 6)
                                local obj2done = p2 >= g2
                                local obj3done = p3 >= g3
                                local obj4done = p4 >= g4
                                local obj5done = p5 >= g5
                                local obj6done = p6 >= g6
                                if not obj2done then
                                    _teleportTo(_DIAMOND_LOCS.coral)
                                elseif not obj3done then
                                    _teleportTo(_DIAMOND_LOCS.tropical)
                                elseif not obj4done then
                                    if _hasItemInInventory(_DIAMOND_FISH_IDS.ruby.Id, _DIAMOND_FISH_IDS.ruby.Metadata) then
                                        _teleportTo(_DIAMOND_NPC_CF)
                                        task.wait(2)
                                        _triggerNpcDialogue(2, 1)
                                    else
                                        _teleportTo(_DIAMOND_LOCS.treasure_room)
                                    end
                                elseif not obj5done then
                                    if _hasItemInInventory(_DIAMOND_FISH_IDS.lochness.Id) then
                                        _teleportTo(_DIAMOND_NPC_CF)
                                        task.wait(2)
                                        _triggerNpcDialogue(2, 2)
                                    else
                                        _teleportTo(_DIAMOND_LOCS.kohana)
                                    end
                                elseif not obj6done then
                                    _teleportTo(_DIAMOND_LOCS.coral)
                                else
                                    _teleportTo(_DIAMOND_NPC_CF)
                                    task.wait(2)
                                    _triggerNpcDialogue(1, 2)
                                end
                            end)
                            task.wait(2)
                        end
                    end)
                else
                    if _diamond.thread then task.cancel(_diamond.thread); _diamond.thread = nil end
                    _stopDiamondParaLoop()
                    pcall(function()
                        _diamondParaRef:SetContent("Nyalakan Auto Diamond Researcher untuk memuat status.")
                    end)
                end
            end,
        })
        DiamondSection:AddButton({
            Title    = "TP: Diamond Researcher NPC",
            Callback = function() _teleportTo(_DIAMOND_NPC_CF) end,
        })
        DiamondSection:AddButton({
            Title    = "TP: Coral Reefs",
            Callback = function() _teleportTo(_DIAMOND_LOCS.coral) end,
        })
        DiamondSection:AddButton({
            Title    = "TP: Tropical Grove",
            Callback = function() _teleportTo(_DIAMOND_LOCS.tropical) end,
        })
        DiamondSection:AddButton({
            Title    = "TP: Treasure Room",
            Callback = function() _teleportTo(_DIAMOND_LOCS.treasure_room) end,
        })
        DiamondSection:AddButton({
            Title    = "TP: Kohana (Lochness)",
            Callback = function() _teleportTo(_DIAMOND_LOCS.kohana) end,
        })
        DiamondSection:AddButton({
            Title    = "Manual: Submit Ruby Mutated",
            Callback = function()
                _teleportTo(_DIAMOND_NPC_CF)
                task.wait(2)
                _triggerNpcDialogue(2, 1)
            end,
        })
        DiamondSection:AddButton({
            Title    = "Manual: Submit Lochness Monster",
            Callback = function()
                _teleportTo(_DIAMOND_NPC_CF)
                task.wait(2)
                _triggerNpcDialogue(2, 2)
            end,
        })
    end

    do
        _ruin = { enabled = false, thread = nil }
        local RuinSection = QuestTab:AddSection("Auto Ancient Ruin", false)
        local _ruinPara   = RuinSection:AddParagraph({
            Title = "Ancient Ruin Status",
            Content = "Nyalakan Auto Ancient Ruin untuk memuat status.",
        })
        _displayRefs.ruin = _ruinPara
        RuinSection:AddToggle({
            Title    = "Auto Ancient Ruin",
            Default  = false,
            NoSave   = true,
            Callback = function(on)
                _ruin.enabled = on
                if _ruin.thread then task.cancel(_ruin.thread); _ruin.thread = nil end
                if not on then
                    _disconnectPlateListeners()
                    pcall(function()
                        _ruinPara:SetContent("Nyalakan Auto Ancient Ruin untuk memuat status.")
                    end)
                    _stopQuestDashboardIfIdle()
                    return
                end
                _buildPlateCache()
                _connectPlateListeners()
                _startQuestDashboard()
                _ruin.thread = task.spawn(function()
                    while _ruin.enabled do
                        pcall(function()
                            if not _data then return end
                            local status = _getPlateStatus()
                            if _allRuinDone(status) then
                                _ruin.enabled = false
                                Library:MakeNotify({
                                    Title = "Ancient Ruin", Description = "Semua pressure plate selesai!",
                                    Color = Color3.fromRGB(123, 239, 178), Delay = 3,
                                })
                                return
                            end
                            local ok, inv = pcall(function() return _data:Get({"Inventory"}) end)
                            local items   = (ok and inv and inv.Items) or {}
                            for _, tier in ipairs(_ruinTiers) do
                                if status[tier] then continue end
                                local targetId = _fishTargetIds[tier]
                                local hasIt    = false
                                for _, v in ipairs(items) do
                                    if tonumber(v.Id) == targetId then hasIt = true; break end
                                end
                                if hasIt then
                                    local part = _plateCache and _plateCache[tier]
                                    if part then
                                        local root = _getRoot()
                                        if root then
                                            root.CFrame = CFrame.new(part.Position + Vector3.new(0, 3, 0))
                                            task.wait(0.6)
                                        end
                                    end
                                    local remote = NetEvents.RE_PlacePressureItem
                                    if remote then
                                        pcall(function() remote:FireServer(tier) end)
                                        task.wait(0.5)
                                    end
                                end
                            end
                        end)
                        task.wait(1.5)
                    end
                end)
            end,
        })
    end

    do
        local _crys = { enabled = false, thread = nil, paraThread = nil }
        local _CRYS_LOCS = {
            crystal_depths = CFrame.lookAt(
                Vector3.new(5729.334, -904.818, 15408.078),
                Vector3.new(5691.893, -904.818, 15262.826)
            ),
            npc = CFrame.new(
                5700.34424, -894.733459, 15299.3174,
                0.943476617, 0, 0.331439078,
                0, 1, 0,
                -0.331439078, 0, 0.943476617
            ),
        }
        local _CRYS_GOALS = { 1, 1, 1, 1, 1 }
        local _CRYS_OBJ_NAMES = {
            "Own an Element Rod",
            "Own a Singularity Bait",
            "Exchange a Cursed Kraken",
            "Catch an Elpirate Gran Maja",
            "Catch Legendary Crystalized @ Crystal Depths",
        }
        local _CRYS_ITEM_IDS = {
            cursed_kraken = { Id = 589 },
            elpirate      = { Id = 661 },
        }
        local function _getCrysQuestData()
            if not _data then return nil end
            local ok, q = pcall(function()
                return _data:Get({"Quests", "Mainline", "Crystalline Secrets"})
            end)
            return (ok and q) or nil
        end
        local function _isCrysDone()
            if not _data then return false end
            local ok, cq = pcall(function() return _data:Get({"CompletedQuests"}) end)
            if not ok or type(cq) ~= "table" then return false end
            for _, v in pairs(cq) do
                if tostring(v) == "Crystalline Secrets" then return true end
            end
            return false
        end
        local function _getCrysObjProgress(q, idx)
            if not q or not q.Objectives then return 0, _CRYS_GOALS[idx] or 1 end
            local obj = q.Objectives[idx]
            if not obj then return 0, _CRYS_GOALS[idx] or 1 end
            return obj.Progress or 0, _CRYS_GOALS[idx] or 1
        end
        local function _hasItemInInventoryCrys(itemId, metadata)
            if not _data then return false end
            local ok, inv = pcall(function() return _data:Get({"Inventory"}) end)
            if not ok or not inv then return false end
            for _, bucket in ipairs({ inv.Items, inv.Gears, inv.Artifacts, inv.Fish, inv.Baits }) do
                if bucket then
                    for _, item in pairs(bucket) do
                        if item and tonumber(item.Id) == itemId then
                            if metadata then
                                if item.Metadata and item.Metadata.VariantId == metadata.VariantId then
                                    return true
                                end
                            else
                                return true
                            end
                        end
                    end
                end
            end
            return false
        end
        local function _teleportToCrys(cf)
            local char = LocalPlayer.Character
            if not char then return end
            local root = char:FindFirstChild("HumanoidRootPart")
            if not root then return end
            if (root.Position - cf.Position).Magnitude > 10 then
                for i = 1, 3 do
                    root.CFrame = cf
                    task.wait(0.1)
                end
            end
        end
        local function _triggerExchangeCrys()
            local remote = NetEvents.RE_DialogueEnded or NetEvents.RE_ExchangeItem
            if remote then
                pcall(function()
                    remote:FireServer("Crystalline Secret", 3, 1)
                end)
            end
        end
        local CrysSection = QuestTab:AddSection("Crystalline Secret Quest", false)

        local _crysParaRef = CrysSection:AddParagraph({
            Title   = "Crystalline Secret Status",
            Content = "Nyalakan Auto Crystalline Secret Quest untuk memuat status.",
        })
        local function _stopCrysParaLoop()
            if _crys.paraThread then
                task.cancel(_crys.paraThread)
                _crys.paraThread = nil
            end
        end
        local function _startCrysParaLoop()
            _stopCrysParaLoop()
            _crys.paraThread = task.spawn(function()
                while _crys.enabled do
                    task.wait(2)
                    pcall(function()
                        if not (_crysParaRef and _crysParaRef.SetContent) then return end
                        if not _data then
                            _crysParaRef:SetContent("Menunggu data...")
                            return
                        end
                        if _isCrysDone() then
                            _crysParaRef:SetContent(_qLine(true, "Crystalline Secret Quest selesai"))
                            _stopCrysParaLoop()
                            return
                        end
                        local q = _getCrysQuestData()
                        if not q then
                            _crysParaRef:SetContent("Quest belum dimulai / data belum tersedia")
                            return
                        end
                        local lines = {}
                        for i, name in ipairs(_CRYS_OBJ_NAMES) do
                            local prog, goal = _getCrysObjProgress(q, i)
                            local done = prog >= goal
                            table.insert(lines, _qLine(done, name, done and "DONE" or ("%d/%d"):format(prog, goal)))
                        end
                        _crysParaRef:SetContent(table.concat(lines, "\n"))
                    end)
                end
                _crys.paraThread = nil
            end)
        end
        CrysSection:AddToggle({
            Title    = "Auto Crystalline Secret Quest",
            Default  = false,
            NoSave   = true,
            Callback = function(on)
                _crys.enabled = on
                if on then
                    if _crys.thread then
                        task.cancel(_crys.thread)
                        _crys.thread = nil
                    end
                    _startCrysParaLoop()
                    _crys.thread = task.spawn(function()
                        while _crys.enabled do
                            pcall(function()
                                if not _data then task.wait(3); return end
                                if _isCrysDone() then
                                    _crys.enabled = false
                                    _stopCrysParaLoop()
                                    pcall(function()
                                        _crysParaRef:SetContent(_qLine(true, "Crystalline Secret Quest selesai"))
                                    end)
                                    Library:MakeNotify({
                                        Title       = "Crystalline Secret",
                                        Description = "Quest selesai!",
                                        Color       = Color3.fromRGB(123, 239, 178),
                                        Delay       = 3,
                                    })
                                    return
                                end
                                local q = _getCrysQuestData()
                                if not q then
                                    _teleportToCrys(_CRYS_LOCS.crystal_depths)
                                    task.wait(3)
                                    return
                                end
                                local p1, g1 = _getCrysObjProgress(q, 1)
                                local p2, g2 = _getCrysObjProgress(q, 2)
                                local p3, g3 = _getCrysObjProgress(q, 3)
                                local p4, g4 = _getCrysObjProgress(q, 4)
                                local p5, g5 = _getCrysObjProgress(q, 5)
                                if p3 < g3 then
                                    if _hasItemInInventoryCrys(_CRYS_ITEM_IDS.cursed_kraken.Id) then
                                        _teleportToCrys(_CRYS_LOCS.npc)
                                        task.wait(2)
                                        _triggerExchangeCrys()
                                    else
                                        _teleportToCrys(_CRYS_LOCS.crystal_depths)
                                    end
                                elseif p4 < g4 then
                                    _teleportToCrys(_CRYS_LOCS.crystal_depths)
                                elseif p5 < g5 then
                                    _teleportToCrys(_CRYS_LOCS.crystal_depths)
                                else
                                    _teleportToCrys(_CRYS_LOCS.crystal_depths)
                                end
                            end)
                            task.wait(2)
                        end
                    end)
                else
                    if _crys.thread then task.cancel(_crys.thread); _crys.thread = nil end
                    _stopCrysParaLoop()
                    pcall(function()
                        _crysParaRef:SetContent("Nyalakan Auto Crystalline Secret Quest untuk memuat status.")
                    end)
                end
            end,
        })

        CrysSection:AddButton({
            Title    = "TP: Crystal Depths",
            Callback = function() _teleportToCrys(_CRYS_LOCS.crystal_depths) end,
        })

        CrysSection:AddButton({
            Title    = "TP: NPC (Exchange)",
            Callback = function() _teleportToCrys(_CRYS_LOCS.npc) end,
        })

        CrysSection:AddButton({
            Title    = "Manual: Exchange Cursed Kraken",
            Callback = function()
                _teleportToCrys(_CRYS_LOCS.npc)
                task.wait(2)
                _triggerExchangeCrys()
            end,
        })
    end

    do
        local _levi = { enabled = false, thread = nil, paraThread = nil }

        local _LEVI_NPC_CF = CFrame.new(3435.933, -287.845, 3411.405)

        local _SCALE_LOC = CFrame.lookAt(
            Vector3.new(-655.469, 17.245, 501.038),
            Vector3.new(-511.246, 17.245, 542.266)
        )

        local _LEVI_PLATE_LOCS = {
            CFrame.new(3443.019, -290.466, 3390.035),
            CFrame.new(3431.017, -290.466, 3396.531),
            CFrame.new(3456.389, -290.466, 3387.298),
        }

        local _LEVI_RELICS = {
            { index = 1, name = "Sunken Eye Relic" },
            { index = 2, name = "Blacktide Relic"  },
            { index = 3, name = "Burntflame Relic" },
        }

        local _SCALE_GOALS    = { 1, 1, 1, 200 }
        local _SCALE_OBJ_NAMES = {
            "Catch Magma Core",
            "Catch Leviathan Essence",
            "Catch Ocean Core",
            "Catch 200 PERFECT fish",
        }

        local function _getLeviathanReplion()
            local ok, rep = pcall(function()
                return require(game:GetService("ReplicatedStorage").Packages.Replion).Client:GetReplion("LeviathanEvent")
            end)
            return (ok and rep) or nil
        end

        local function _getScaleQuestData()
            if not _data then return nil end
            local ok, q = pcall(function() return _data:Get({"Quests", "Mainline", "Forgotten Scale"}) end)
            return (ok and q) or nil
        end

        local function _isScaleDone()
            if not _data then return false end
            local ok, cq = pcall(function() return _data:Get({"CompletedQuests"}) end)
            if not ok or type(cq) ~= "table" then return false end
            for _, v in pairs(cq) do
                if tostring(v) == "Forgotten Scale" then return true end
            end
            return false
        end

        local function _getScaleObjProgress(q, idx)
            if not q or not q.Objectives then return 0, _SCALE_GOALS[idx] or 1 end
            local obj = q.Objectives[idx]
            if not obj then return 0, _SCALE_GOALS[idx] or 1 end
            return obj.Progress or 0, _SCALE_GOALS[idx] or 1
        end

        local function _getRelicUUID(identifier)
            if not _data then return nil end
            local ok, inv = pcall(function() return _data:Get({"Inventory"}) end)
            if not ok or not inv or not inv.Gears then return nil end
            for _, item in pairs(inv.Gears) do
                if item and item.Name == identifier then return item.UUID end
            end
            return nil
        end

        local function _hasAllRelics()
            for _, relic in ipairs(_LEVI_RELICS) do
                if not _getRelicUUID(relic.name) then return false end
            end
            return true
        end

        local function _isPlateActive(levReplion, idx)
            if not levReplion then return false end
            local ok, plates = pcall(function() return levReplion:GetExpect("PressurePlates") end)
            if not ok or not plates then return false end
            return table.find(plates, idx) ~= nil
        end

        local function _tpTo(cf)
            local hrp = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
            if not hrp then return end
            for i = 1, 3 do hrp.CFrame = cf; task.wait(0.1) end
        end

        local function _talkNpc()
            local npcFolder = workspace:FindFirstChild("NPC")
            if not npcFolder then return end
            local npc = npcFolder:FindFirstChild("Archaeologist")
            if not npc then return end
            local prompt = npc:FindFirstChildWhichIsA("ProximityPrompt", true)
            if prompt then pcall(fireproximityprompt, prompt) end
        end

        local function _hasLeviathanScale()
            if not _data then return false end
            local ok, inv = pcall(function() return _data:Get({"Inventory"}) end)
            if not ok or not inv then return false end
            for _, bucket in ipairs({ inv.Items, inv.Gears }) do
                if bucket then
                    for _, item in pairs(bucket) do
                        if item and item.Name == "Leviathan Scale" then return true, item.UUID end
                    end
                end
            end
            return false, nil
        end

        local function _consumeLeviathanScale()
            local has, uuid = _hasLeviathanScale()
            if not has then
                Library:MakeNotify({ Title = "Leviathan", Description = "Leviathan Scale tidak ada!", Color = Color3.fromRGB(255, 100, 100), Delay = 3 })
                return false
            end
            pcall(function() NetEvents.RF_ConsumeItem:InvokeServer(uuid) end)
            Library:MakeNotify({ Title = "Leviathan", Description = "Leviathan Scale dikonsumsi!", Color = Color3.fromRGB(123, 239, 178), Delay = 3 })
            return true
        end

        local LeviSection = QuestTab:AddSection("Leviathan Hunt", false)

        local _leviParaRef = LeviSection:AddParagraph({
            Title   = "Leviathan Status",
            Content = "Nyalakan Auto Leviathan Hunt untuk memuat status.",
        })

        local function _stopLeviParaLoop()
            if _levi.paraThread then
                task.cancel(_levi.paraThread)
                _levi.paraThread = nil
            end
        end
        local function _startLeviParaLoop()
            _stopLeviParaLoop()
            _levi.paraThread = task.spawn(function()
                while _levi.enabled do
                    local interval = 2
                    pcall(function()
                        if not (_leviParaRef and _leviParaRef.SetContent) then return end
                        if not _data then _leviParaRef:SetContent("Menunggu data..."); return end

                        local lines = {}

                        if not _isScaleDone() then
                            table.insert(lines, "<font color=\"rgb(200,200,200)\">== Forgotten Scale Quest ==</font>")
                            local q = _getScaleQuestData()
                            if not q then
                                table.insert(lines, "Quest belum dimulai (talk to Archaeologist)")
                            else
                                for i, name in ipairs(_SCALE_OBJ_NAMES) do
                                    local prog, goal = _getScaleObjProgress(q, i)
                                    local done = prog >= goal
                                    table.insert(lines, _qLine(done, name, done and "DONE" or ("%d/%d"):format(prog, goal)))
                                end
                            end
                        else
                            table.insert(lines, _qLine(true, "Forgotten Scale Quest"))

                            local hasScale = _hasLeviathanScale()
                            if hasScale then
                                table.insert(lines, _qLine(false, "Consume Leviathan Scale"))
                            else
                                table.insert(lines, "<font color=\"rgb(200,200,200)\">== Leviathan Hunt ==</font>")
                                if not _hasAllRelics() then
                                    table.insert(lines, "Farming relics @ Kohana Volcano")
                                    for _, relic in ipairs(_LEVI_RELICS) do
                                        local hasIt = _getRelicUUID(relic.name) ~= nil
                                        table.insert(lines, _qLine(hasIt, relic.name))
                                    end
                                else
                                    local levReplion = _getLeviathanReplion()
                                    if not levReplion then
                                        table.insert(lines, "Event tidak aktif")
                                    else
                                        for _, relic in ipairs(_LEVI_RELICS) do
                                            local done = _isPlateActive(levReplion, relic.index)
                                            table.insert(lines, _qLine(done, relic.name))
                                        end
                                    end
                                end
                            end
                        end

                        _leviParaRef:SetContent(table.concat(lines, "\n"))

                        if _isScaleDone() and not _hasLeviathanScale() then
                            if _hasAllRelics() then
                                local lr = _getLeviathanReplion()
                                if not lr then
                                    interval = 45
                                else
                                    local platesDone = true
                                    for _, relic in ipairs(_LEVI_RELICS) do
                                        if not _isPlateActive(lr, relic.index) then
                                            platesDone = false
                                            break
                                        end
                                    end
                                    if platesDone then interval = 120 end
                                end
                            end
                        end
                    end)
                    task.wait(interval)
                end
                _levi.paraThread = nil
            end)
        end

        LeviSection:AddToggle({
            Title    = "Auto Leviathan Hunt",
            Default  = false,
            NoSave   = true,
            Callback = function(on)
                _levi.enabled = on
                if on then
                    if _levi.thread then
                        task.cancel(_levi.thread)
                        _levi.thread = nil
                    end
                    _startLeviParaLoop()
                    _levi.thread = task.spawn(function()
                        while _levi.enabled do
                            pcall(function()
                                if not _data then task.wait(3); return end
                                if not _isScaleDone() then
                                    local q = _getScaleQuestData()
                                    if not q then
                                        _tpTo(_LEVI_NPC_CF)
                                        task.wait(1.5)
                                        _talkNpc()
                                        task.wait(3)
                                        return
                                    end
                                    local p1, g1 = _getScaleObjProgress(q, 1)
                                    local p2, g2 = _getScaleObjProgress(q, 2)
                                    local p3, g3 = _getScaleObjProgress(q, 3)
                                    local p4, g4 = _getScaleObjProgress(q, 4)
                                    if p1 < g1 or p2 < g2 or p3 < g3 or p4 < g4 then
                                        _tpTo(_SCALE_LOC)
                                    end
                                    return
                                end
                                local hasScale, uuid = _hasLeviathanScale()
                                if hasScale then
                                    _tpTo(_LEVI_NPC_CF)
                                    task.wait(1.5)
                                    _consumeLeviathanScale()
                                    task.wait(3)
                                    return
                                end
                                if not _hasAllRelics() then
                                    _tpTo(_SCALE_LOC)
                                    return
                                end
                                local levReplion = _getLeviathanReplion()
                                if not levReplion then task.wait(3); return end
                                local _, lobby = pcall(function() return levReplion:GetExpect("Lobby") end)
                                if not lobby then task.wait(3); return end
                                local allPlaced = true
                                for _, relic in ipairs(_LEVI_RELICS) do
                                    if not _isPlateActive(levReplion, relic.index) then
                                        allPlaced = false; break
                                    end
                                end
                                if allPlaced then
                                    Library:MakeNotify({ Title = "Leviathan", Description = "Semua relic terpasang! Leviathan Hunt dimulai!", Color = Color3.fromRGB(123, 239, 178), Delay = 3 })
                                    _levi.enabled = false
                                    _stopLeviParaLoop()
                                    pcall(function()
                                        _leviParaRef:SetContent("Semua relic terpasang — Leviathan Hunt dimulai.")
                                    end)
                                    return
                                end
                                for _, relic in ipairs(_LEVI_RELICS) do
                                    if not _levi.enabled then break end
                                    if _isPlateActive(levReplion, relic.index) then continue end
                                    local uuid = _getRelicUUID(relic.name)
                                    if not uuid then
                                        Library:MakeNotify({ Title = "Leviathan", Description = relic.name .. " tidak ada!", Color = Color3.fromRGB(255, 179, 71), Delay = 3 })
                                        continue
                                    end
                                    _tpTo(_LEVI_PLATE_LOCS[relic.index])
                                    task.wait(1)
                                    pcall(function()
                                        NetEvents.RE_PlaceLeviathanPressureItem:FireServer(uuid, relic.index)
                                    end)
                                    task.wait(1)
                                end
                            end)
                            task.wait(2)
                        end
                    end)
                else
                    if _levi.thread then task.cancel(_levi.thread); _levi.thread = nil end
                    _stopLeviParaLoop()
                    pcall(function()
                        _leviParaRef:SetContent("Nyalakan Auto Leviathan Hunt untuk memuat status.")
                    end)
                end
            end,
        })

        LeviSection:AddButton({
            Title    = "TP: Archaeologist NPC",
            Callback = function() _tpTo(_LEVI_NPC_CF) end,
        })
        LeviSection:AddButton({
            Title    = "TP: Kohana Volcano (Farming)",
            Callback = function() _tpTo(_SCALE_LOC) end,
        })
        LeviSection:AddButton({
            Title    = "TP: Plate 1 (Sunken Eye)",
            Callback = function() _tpTo(_LEVI_PLATE_LOCS[1]) end,
        })
        LeviSection:AddButton({
            Title    = "TP: Plate 2 (Blacktide)",
            Callback = function() _tpTo(_LEVI_PLATE_LOCS[2]) end,
        })
        LeviSection:AddButton({
            Title    = "TP: Plate 3 (Burntflame)",
            Callback = function() _tpTo(_LEVI_PLATE_LOCS[3]) end,
        })
        LeviSection:AddButton({
            Title    = "Manual: Talk to Archaeologist",
            Callback = function()
                _tpTo(_LEVI_NPC_CF)
                task.wait(1.5)
                _talkNpc()
            end,
        })
        LeviSection:AddButton({
            Title    = "Manual: Consume Leviathan Scale",
            Callback = function() _consumeLeviathanScale() end,
        })
    end
end

-- [Color Tab]
do
    local ColorTab     = MainWindow:AddTab({ Name = "Color Correction", Icon = "eyes" })
    local ColorSection = ColorTab:AddSection("Color Correction")
    local Lighting     = game:GetService("Lighting")
    local TweenService = game:GetService("TweenService")
    local _colorState = {
        enabled    = false,
        selected   = "Normal",
        correction = nil,
        tween      = nil,
    }
    local PRESETS = {
        ["Normal"]       = { Brightness = 0,     Contrast = 0,    Saturation = 0,    TintColor = Color3.fromRGB(255, 255, 255) },
        ["HD"]           = { Brightness = 0.02,  Contrast = 0.28, Saturation = 0.18, TintColor = Color3.fromRGB(250, 250, 255) },
        ["4K"]           = { Brightness = 0.03,  Contrast = 0.32, Saturation = 0.22, TintColor = Color3.fromRGB(252, 252, 255) },
        ["HDR"]          = { Brightness = 0.05,  Contrast = 0.38, Saturation = 0.28, TintColor = Color3.fromRGB(255, 252, 248) },
        ["Crisp"]        = { Brightness = 0.01,  Contrast = 0.35, Saturation = 0.15, TintColor = Color3.fromRGB(255, 255, 255) },
        ["Golden"]       = { Brightness = 0.06,  Contrast = 0.22, Saturation = 0.2,  TintColor = Color3.fromRGB(255, 210, 160) },
        ["Sunset"]       = { Brightness = 0.04,  Contrast = 0.25, Saturation = 0.22, TintColor = Color3.fromRGB(255, 175, 110) },
        ["Warm"]         = { Brightness = 0.03,  Contrast = 0.18, Saturation = 0.12, TintColor = Color3.fromRGB(255, 225, 190) },
        ["Cool"]         = { Brightness = 0.02,  Contrast = 0.2,  Saturation = 0.1,  TintColor = Color3.fromRGB(190, 215, 255) },
        ["Arctic"]       = { Brightness = 0.05,  Contrast = 0.22, Saturation = -0.1, TintColor = Color3.fromRGB(205, 228, 255) },
        ["Ocean"]        = { Brightness = 0.0,   Contrast = 0.2,  Saturation = 0.15, TintColor = Color3.fromRGB(150, 200, 235) },
        ["Cinematic"]    = { Brightness = -0.02, Contrast = 0.3,  Saturation = -0.1, TintColor = Color3.fromRGB(225, 215, 200) },
        ["Teal & Orange"]= { Brightness = 0.02,  Contrast = 0.28, Saturation = 0.18, TintColor = Color3.fromRGB(205, 225, 210) },
        ["Matte"]        = { Brightness = 0.04,  Contrast = -0.08,Saturation = -0.12,TintColor = Color3.fromRGB(218, 212, 205) },
        ["Film"]         = { Brightness = 0.03,  Contrast = 0.2,  Saturation = 0.08, TintColor = Color3.fromRGB(255, 228, 195) },
        ["Night"]        = { Brightness = -0.15, Contrast = 0.22, Saturation = -0.1, TintColor = Color3.fromRGB(165, 185, 225) },
        ["Moody"]        = { Brightness = -0.08, Contrast = 0.3,  Saturation = 0.05, TintColor = Color3.fromRGB(190, 178, 168) },
        ["Vibrant"]      = { Brightness = 0.04,  Contrast = 0.2,  Saturation = 0.45, TintColor = Color3.fromRGB(255, 255, 255) },
        ["Anime"]        = { Brightness = 0.05,  Contrast = 0.22, Saturation = 0.38, TintColor = Color3.fromRGB(245, 240, 255) },
        ["Forest"]       = { Brightness = 0.02,  Contrast = 0.18, Saturation = 0.22, TintColor = Color3.fromRGB(195, 225, 190) },
        ["Tropical"]     = { Brightness = 0.05,  Contrast = 0.2,  Saturation = 0.3,  TintColor = Color3.fromRGB(200, 238, 220) },
        ["Dreamy"]       = { Brightness = 0.08,  Contrast = -0.06,Saturation = 0.12, TintColor = Color3.fromRGB(232, 218, 255) },
        ["Vintage"]      = { Brightness = 0.04,  Contrast = 0.12, Saturation = -0.2, TintColor = Color3.fromRGB(242, 222, 178) },
        ["Grayscale"]    = { Brightness = 0.0,   Contrast = 0.15, Saturation = -1.0, TintColor = Color3.fromRGB(255, 255, 255) },
    }
    local PRESET_NAMES = { "Normal" }
    for name in pairs(PRESETS) do
        if name ~= "Normal" then table.insert(PRESET_NAMES, name) end
    end
    table.sort(PRESET_NAMES, function(a, b)
        if a == "Normal" then return true end
        if b == "Normal" then return false end
        return a < b
    end)
    local function _ensureCC()
        if _colorState.correction and _colorState.correction.Parent then
            return _colorState.correction
        end
        local existing = Lighting:FindFirstChildOfClass("ColorCorrectionEffect")
        if existing and existing:GetAttribute("LynxCC") then
            _colorState.correction = existing
            return existing
        end
        local cc = Instance.new("ColorCorrectionEffect")
        cc.Name    = "LynxColorCorrection"
        cc.Enabled = true
        cc:SetAttribute("LynxCC", true)
        cc.Parent  = Lighting
        _colorState.correction = cc
        return cc
    end
    local function _applyPreset(name)
        local preset = PRESETS[name]
        if not preset then return end
        local cc = _ensureCC()
        if _colorState.tween then _colorState.tween:Cancel() end
        _colorState.tween = TweenService:Create(cc,
            TweenInfo.new(0.4, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
            { Brightness = preset.Brightness, Contrast = preset.Contrast, Saturation = preset.Saturation, TintColor = preset.TintColor }
        )
        _colorState.tween:Play()
    end
    local function _removeCorrection()
        if _colorState.tween then _colorState.tween:Cancel() end
        if _colorState.correction and _colorState.correction.Parent then
            local t = TweenService:Create(_colorState.correction,
                TweenInfo.new(0.4, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
                { Brightness = 0, Contrast = 0, Saturation = 0, TintColor = Color3.fromRGB(255, 255, 255) }
            )
            t:Play()
            t.Completed:Once(function()
                if _colorState.correction and _colorState.correction.Parent then
                    _colorState.correction:Destroy()
                    _colorState.correction = nil
                end
            end)
        end
    end
    ColorSection:AddDropdown({
        Title    = "Color Preset",
        Options  = PRESET_NAMES,
        Default  = "Normal",
        Callback = function(selected)
            _colorState.selected = selected
            if _colorState.enabled then _applyPreset(selected) end
        end,
    })
    ColorSection:AddToggle({
        Title    = "Enable Color Correction",
        Default  = false,
        NoSave   = true,
        Callback = function(on)
            _colorState.enabled = on
            if on then
                _applyPreset(_colorState.selected)
                Library:MakeNotify({ Title = "Color Correction", Content = "Preset: " .. _colorState.selected, Delay = 2 })
            else
                _removeCorrection()
                Library:MakeNotify({ Title = "Color Correction", Content = "Dimatikan.", Delay = 2 })
            end
        end,
    })
    
    local FullBrightSection = ColorTab:AddSection("Full Bright")
    local _fullBright = {
        enabled  = false,
        origAmb  = Lighting.Ambient,
        origOut  = Lighting.OutdoorAmbient,
        origBri  = Lighting.Brightness,
        origClockTime = Lighting.ClockTime,
        conn     = nil,
    }
    FullBrightSection:AddToggle({
        Title    = "Enable Full Bright",
        Default  = false,
        NoSave   = true,
        Callback = function(on)
            _fullBright.enabled = on
            if on then
                _fullBright.origAmb       = Lighting.Ambient
                _fullBright.origOut       = Lighting.OutdoorAmbient
                _fullBright.origBri       = Lighting.Brightness
                _fullBright.origClockTime = Lighting.ClockTime
                Lighting.Ambient        = Color3.fromRGB(255, 255, 255)
                Lighting.OutdoorAmbient = Color3.fromRGB(255, 255, 255)
                Lighting.Brightness     = 2
                Lighting.ClockTime      = 14
                _fullBright.conn = Lighting:GetPropertyChangedSignal("ClockTime"):Connect(function()
                    if not _fullBright.enabled then return end
                    Lighting.Ambient        = Color3.fromRGB(255, 255, 255)
                    Lighting.OutdoorAmbient = Color3.fromRGB(255, 255, 255)
                    Lighting.Brightness     = 2
                end)
                Library:MakeNotify({
                    Title   = "Full Bright",
                    Content = "Full Bright diaktifkan.",
                    Delay   = 2,
                })
            else
                if _fullBright.conn then
                    _fullBright.conn:Disconnect()
                    _fullBright.conn = nil
                end
                Lighting.Ambient        = _fullBright.origAmb
                Lighting.OutdoorAmbient = _fullBright.origOut
                Lighting.Brightness     = _fullBright.origBri
                Lighting.ClockTime      = _fullBright.origClockTime
                Library:MakeNotify({
                    Title   = "Full Bright",
                    Content = "Full Bright dimatikan.",
                    Delay   = 2,
                })
            end
        end,
    })

    local TimeSection = ColorTab:AddSection("Change Time")
    local TimeController = nil
    pcall(function()
        TimeController = require(game:GetService("ReplicatedStorage"):WaitForChild("Controllers", 3):WaitForChild("ClientTimeController", 3))
    end)
    local _changeTime = {
        enabled = false,
        profile = "Night",
    }
    TimeSection:AddToggle({
        Title    = "Change Time",
        Default  = false,
        Callback = function(on)
            _changeTime.enabled = on
            if on then
                if TimeController then TimeController:_forceUpdateAndOverride(_changeTime.profile) end
            else
                if TimeController then TimeController:_removeOverride() end
            end
        end,
    })
    TimeSection:AddDropdown({
        Title    = "Time Profile",
        Options  = { "Night", "Day", "Bloodmoon", "Purple Bloodmoon", "Galaxy" },
        Default  = "Night",
        Callback = function(selected)
            _changeTime.profile = selected
            if _changeTime.enabled and TimeController then
                TimeController:_forceUpdateAndOverride(selected)
            end
        end,
    })
end

-- [Settings Tab]
do
    local SettingsTab = MainWindow:AddTab({ Name = "Settings", Icon = "settings" })
    do
        local ProtectionSection = SettingsTab:AddSection("Protection")
        local _stayActive       = { enabled = false, conns = {}, task = nil }
        local _antiStaff = { enabled = false, task = nil }
        local GROUP_ID = 35102746
        local STAFF_RANKS = {
            [2]=true,[3]=true,[4]=true,[30]=true,[35]=true,[55]=true,
            [75]=true,[76]=true,[79]=true,[100]=true,[145]=true,
            [250]=true,[252]=true,[254]=true,[255]=true,
        }
        local RANK_NAMES = {
            [2]   = "Trial Moderator",
            [3]   = "Moderator",
            [4]   = "Senior Moderator",
            [30]  = "Trial Administrator",
            [35]  = "Administrator",
            [55]  = "Senior Administrator",
            [75]  = "Trial Manager",
            [76]  = "Manager",
            [79]  = "Senior Manager",
            [100] = "Director",
            [145] = "Trial Developer",
            [250] = "Developer",
            [252] = "Senior Developer",
            [254] = "Co-Owner",
            [255] = "Owner",
        }

        local PRIORITY_NAMES = {
            [2] = "Junior Staff",
            [3] = "Staff",
            [4] = "Senior Staff",
            [5] = "Admin",
        }

        ProtectionSection:AddToggle({
            Title    = "Stay Active (Anti-AFK)",
            Default  = true,
            Callback = function(on)
                if on then
                    if _stayActive.enabled then return end
                    _stayActive.enabled = true

                    if type(getconnections) == "function" then
                        pcall(function()
                            for _, c in ipairs(getconnections(LocalPlayer.Idled)) do
                                if c and c.Disable then
                                    pcall(c.Disable, c)
                                    table.insert(_stayActive.conns, c)
                                end
                            end
                        end)
                    end

                else
                    _stayActive.enabled = false

                    pcall(function()
                        for _, c in ipairs(_stayActive.conns) do
                            if c and c.Enable then pcall(c.Enable, c) end
                        end
                        _stayActive.conns = {}
                    end)
                end
            end,
        }):SetValue(true)

        ProtectionSection:AddToggle({
            Title    = "Anti Staff (Auto Kick)",
            Default  = false,
            Callback = function(on)
                _antiStaff.enabled = on
                if on then
                    if _antiStaff.task then return end
                    _antiStaff.task = task.spawn(function()
                        local UserPriority = nil
                        pcall(function()
                            UserPriority = require(game:GetService("ReplicatedStorage").Shared.UserPriority)
                        end)
                        while _antiStaff.enabled do
                            for _, player in ipairs(Players:GetPlayers()) do
                                if player ~= LocalPlayer then
                                    local detected   = false
                                    local detectedBy = ""
                                    local roleName   = ""
                                    local rank = 0
                                    pcall(function() rank = player:GetRankInGroup(GROUP_ID) end)
                                    if STAFF_RANKS[rank] then
                                        detected   = true
                                        detectedBy = "Group Rank"
                                        roleName   = RANK_NAMES[rank] or ("Rank " .. rank)
                                    end
                                    if not detected and UserPriority then
                                        local priority = 0
                                        pcall(function()
                                            priority = UserPriority:GetPriorityLevel(player)
                                        end)
                                        if priority >= 2 then
                                            detected   = true
                                            detectedBy = "Priority Level"
                                            roleName   = PRIORITY_NAMES[priority] or ("Priority " .. priority)
                                        end
                                    end
                                    if detected then
                                        local kickMsg = string.format(
                                            "Staff Detected!\nNama: %s\nRole: %s\nDeteksi: %s\nAuto Kicked for Safety.",
                                            player.Name,
                                            roleName,
                                            detectedBy
                                        )
                                        LocalPlayer:Kick(kickMsg)
                                        return
                                    end
                                end
                            end
                            task.wait(1)
                        end
                    end)
                else
                    if _antiStaff.task then
                        task.cancel(_antiStaff.task)
                        _antiStaff.task = nil
                    end
                end
            end,
        })
    end
    do
        local CameraSection = SettingsTab:AddSection("Camera")
        local Camera = workspace.CurrentCamera
        do
            CameraSection:AddParagraph({
                Title   = "Freecam",
                Content = "Gerakkan kamera bebas tanpa batas.\n• PC: Toggle via UI atau tekan [F3]\n• Gerak: WASD, E/Space = naik, Q/Shift = turun\n• Mobile: Jari kiri = gerak, jari kanan = rotasi",
            })
            local CAS = game:GetService("ContextActionService")
            local BLOCK_ACTION = "FreecamBlockMovement"
            local function blockCharacterInput()
                local noop = function() return Enum.ContextActionResult.Sink end
                CAS:BindActionAtPriority(BLOCK_ACTION, noop, false, 3000,
                    Enum.KeyCode.W, Enum.KeyCode.A, Enum.KeyCode.S, Enum.KeyCode.D,
                    Enum.KeyCode.Up, Enum.KeyCode.Down, Enum.KeyCode.Left, Enum.KeyCode.Right,
                    Enum.KeyCode.Space, Enum.KeyCode.LeftShift, Enum.KeyCode.RightShift,
                    Enum.PlayerActions.CharacterForward, Enum.PlayerActions.CharacterBackward,
                    Enum.PlayerActions.CharacterLeft, Enum.PlayerActions.CharacterRight,
                    Enum.PlayerActions.CharacterJump
                )
            end
            local function unblockCharacterInput()
                CAS:UnbindAction(BLOCK_ACTION)
            end
            local freecamToggle = CameraSection:AddToggle({
                Title    = "Freecam",
                Default  = false,
                NoSave   = true,
                Callback = function(on)
                    if not _G._Freecam then
                        _G._Freecam = {
                            enabled          = false,
                            camPos           = Vector3.new(),
                            camRot           = Vector3.new(),
                            speed            = 50,
                            sensitivity      = 0.3,
                            hiddenGuis       = {},
                            renderConn       = nil,
                            inputBegan       = nil,
                            inputChanged     = nil,
                            inputEnded       = nil,
                            freezeThread     = nil,
                            charConn         = nil,
                            character        = nil,
                            humanoid         = nil,
                            frozenCFrame     = nil,
                            isMobile         = UIS.TouchEnabled and not UIS.KeyboardEnabled,
                            joystickInput    = Vector3.new(),
                            cameraTouch      = nil,
                            cameraTouchStart = nil,
                            joystickTouch    = nil,
                            joystickOrigin   = nil,
                        }
                        local fc = _G._Freecam
                        fc.character = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
                        fc.humanoid  = fc.character:WaitForChild("Humanoid")
                        fc.charConn  = LocalPlayer.CharacterAdded:Connect(function(newChar)
                            fc.character = newChar
                            fc.humanoid  = newChar:WaitForChild("Humanoid")
                        end)
                    end

                    local fc                = _G._Freecam
                    local JOYSTICK_DEADZONE = 10
                    local JOYSTICK_MAX      = 80

                    local function freezeChar()
                        local char = fc.character
                        if not char then return end
                        local core = char:FindFirstChild("Core")
                        if core then
                            local bootstrapper = core:FindFirstChild("BOOTSTRAPPER")
                            if bootstrapper then
                                bootstrapper.Disabled = true
                            end
                        end
                        local hrp = char:FindFirstChild("HumanoidRootPart")
                        if hrp then
                            fc.frozenCFrame = hrp.CFrame
                            hrp.Anchored = true
                            hrp.AssemblyLinearVelocity  = Vector3.zero
                            hrp.AssemblyAngularVelocity = Vector3.zero
                        end
                        local hum = fc.humanoid
                        if hum then
                            hum.WalkSpeed  = 0
                            hum.JumpPower  = 0
                            hum.AutoRotate = false
                        end
                    end

                    local function unfreezeChar()
                        local char = fc.character
                        if not char then return end
                        local core = char:FindFirstChild("Core")
                        if core then
                            local bootstrapper = core:FindFirstChild("BOOTSTRAPPER")
                            if bootstrapper then
                                bootstrapper.Disabled = false
                            end
                        end
                        local hrp = char:FindFirstChild("HumanoidRootPart")
                        if hrp then
                            hrp.Anchored = false
                            hrp.AssemblyLinearVelocity  = Vector3.zero
                            hrp.AssemblyAngularVelocity = Vector3.zero
                        end
                        local hum = fc.humanoid
                        if hum then
                            hum.WalkSpeed  = 16
                            hum.JumpPower  = 50
                            hum.AutoRotate = true
                        end
                    end

                    fc.enabled = on

                    if on then
                        local cf = Camera.CFrame
                        fc.camPos = cf.Position
                        local x, y, z = cf:ToEulerAnglesYXZ()
                        fc.camRot = Vector3.new(x, y, z)

                        freezeChar()
                        blockCharacterInput()

                        fc.freezeThread = task.spawn(function()
                            while fc.enabled do
                                local hrp = fc.character and fc.character:FindFirstChild("HumanoidRootPart")
                                if hrp and fc.frozenCFrame then
                                    hrp.CFrame                  = fc.frozenCFrame
                                    hrp.AssemblyLinearVelocity  = Vector3.zero
                                    hrp.AssemblyAngularVelocity = Vector3.zero
                                end
                                task.wait(0.03)
                            end
                        end)

                        fc.hiddenGuis = {}
                        for _, gui in pairs(LocalPlayer.PlayerGui:GetChildren()) do
                            if gui:IsA("ScreenGui") and gui.Enabled then
                                table.insert(fc.hiddenGuis, gui)
                                gui.Enabled = false
                            end
                        end

                        Camera.CameraType = Enum.CameraType.Scriptable
                        task.wait()

                        if not fc.isMobile then
                            UIS.MouseBehavior    = Enum.MouseBehavior.LockCenter
                            UIS.MouseIconEnabled = false
                        else
                            local screenSizeX = Camera.ViewportSize.X

                            fc.inputBegan = UIS.InputBegan:Connect(function(input)
                                if not fc.enabled then return end
                                if input.UserInputType ~= Enum.UserInputType.Touch then return end
                                local pos = input.Position
                                if pos.X < screenSizeX / 2 then
                                    if not fc.joystickTouch then
                                        fc.joystickTouch  = input
                                        fc.joystickOrigin = Vector2.new(pos.X, pos.Y)
                                        fc.joystickInput  = Vector3.new()
                                    end
                                else
                                    if not fc.cameraTouch then
                                        fc.cameraTouch      = input
                                        fc.cameraTouchStart = Vector2.new(pos.X, pos.Y)
                                    end
                                end
                            end)

                            fc.inputChanged = UIS.InputChanged:Connect(function(input)
                                if not fc.enabled then return end
                                if input.UserInputType ~= Enum.UserInputType.Touch then return end
                                local pos = input.Position
                                if input == fc.joystickTouch and fc.joystickOrigin then
                                    local dx   = pos.X - fc.joystickOrigin.X
                                    local dz   = pos.Y - fc.joystickOrigin.Y
                                    local dist = math.sqrt(dx * dx + dz * dz)
                                    if dist < JOYSTICK_DEADZONE then
                                        fc.joystickInput = Vector3.new()
                                    else
                                        local clamped = math.min(dist, JOYSTICK_MAX)
                                        local nx = (dx / dist) * (clamped / JOYSTICK_MAX)
                                        local nz = (dz / dist) * (clamped / JOYSTICK_MAX)
                                        fc.joystickInput = Vector3.new(nx, 0, nz)
                                    end
                                elseif input == fc.cameraTouch and fc.cameraTouchStart then
                                    local cur   = Vector2.new(pos.X, pos.Y)
                                    local delta = cur - fc.cameraTouchStart
                                    fc.camRot = Vector3.new(
                                        math.clamp(
                                            fc.camRot.X - delta.Y * fc.sensitivity * 0.005,
                                            -math.pi / 2 + 0.05,
                                            math.pi / 2 - 0.05
                                        ),
                                        fc.camRot.Y - delta.X * fc.sensitivity * 0.005,
                                        0
                                    )
                                    fc.cameraTouchStart = cur
                                end
                            end)

                            fc.inputEnded = UIS.InputEnded:Connect(function(input)
                                if not fc.enabled then return end
                                if input.UserInputType ~= Enum.UserInputType.Touch then return end
                                if input == fc.joystickTouch then
                                    fc.joystickTouch  = nil
                                    fc.joystickOrigin = nil
                                    fc.joystickInput  = Vector3.new()
                                end
                                if input == fc.cameraTouch then
                                    fc.cameraTouch      = nil
                                    fc.cameraTouchStart = nil
                                end
                            end)
                        end

                        fc.renderConn = RunService.RenderStepped:Connect(function(dt)
                            if not fc.enabled then return end
                            if not fc.isMobile then
                                local delta = UIS:GetMouseDelta()
                                if delta.Magnitude > 0 then
                                    fc.camRot = Vector3.new(
                                        math.clamp(
                                            fc.camRot.X - delta.Y * fc.sensitivity * 0.01,
                                            -math.pi / 2 + 0.05,
                                            math.pi / 2 - 0.05
                                        ),
                                        fc.camRot.Y - delta.X * fc.sensitivity * 0.01,
                                        0
                                    )
                                end
                                local move = Vector3.zero
                                if UIS:IsKeyDown(Enum.KeyCode.W) then move += Vector3.new(0, 0,  1) end
                                if UIS:IsKeyDown(Enum.KeyCode.S) then move += Vector3.new(0, 0, -1) end
                                if UIS:IsKeyDown(Enum.KeyCode.A) then move += Vector3.new(-1, 0, 0) end
                                if UIS:IsKeyDown(Enum.KeyCode.D) then move += Vector3.new( 1, 0, 0) end
                                if UIS:IsKeyDown(Enum.KeyCode.Space) or UIS:IsKeyDown(Enum.KeyCode.E) then
                                    move += Vector3.new(0, 1, 0)
                                end
                                if UIS:IsKeyDown(Enum.KeyCode.LeftShift) or UIS:IsKeyDown(Enum.KeyCode.Q) then
                                    move += Vector3.new(0, -1, 0)
                                end
                                if move.Magnitude > 0 then
                                    move = move.Unit
                                    local cf2 = CFrame.new(fc.camPos) * CFrame.fromEulerAnglesYXZ(fc.camRot.X, fc.camRot.Y, fc.camRot.Z)
                                    local vel = cf2.LookVector  * move.Z
                                            + cf2.RightVector * move.X
                                            + cf2.UpVector    * move.Y
                                    fc.camPos += vel * fc.speed * dt
                                end
                            else
                                local ji = fc.joystickInput
                                if ji.Magnitude > 0 then
                                    local cf2 = CFrame.new(fc.camPos) * CFrame.fromEulerAnglesYXZ(fc.camRot.X, fc.camRot.Y, fc.camRot.Z)
                                    local vel = cf2.LookVector  * ji.Z
                                            + cf2.RightVector * ji.X
                                    fc.camPos += vel * fc.speed * dt
                                end
                            end
                            Camera.CFrame = CFrame.new(fc.camPos) * CFrame.fromEulerAnglesYXZ(fc.camRot.X, fc.camRot.Y, fc.camRot.Z)
                        end)
                    else
                        if fc.renderConn   then fc.renderConn:Disconnect();   fc.renderConn   = nil end
                        if fc.inputBegan   then fc.inputBegan:Disconnect();   fc.inputBegan   = nil end
                        if fc.inputChanged then fc.inputChanged:Disconnect(); fc.inputChanged = nil end
                        if fc.inputEnded   then fc.inputEnded:Disconnect();   fc.inputEnded   = nil end
                        if fc.freezeThread then task.cancel(fc.freezeThread); fc.freezeThread = nil end

                        unblockCharacterInput()
                        unfreezeChar()

                        if fc.frozenCFrame then
                            local hrp = fc.character and fc.character:FindFirstChild("HumanoidRootPart")
                            if hrp then
                                hrp.CFrame = fc.frozenCFrame
                            end
                            fc.frozenCFrame = nil
                        end

                        for _, gui in pairs(fc.hiddenGuis) do
                            if gui and gui:IsA("ScreenGui") then
                                gui.Enabled = true
                            end
                        end
                        fc.hiddenGuis = {}

                        Camera.CameraType    = Enum.CameraType.Custom
                        Camera.CameraSubject = fc.humanoid
                        UIS.MouseBehavior    = Enum.MouseBehavior.Default
                        UIS.MouseIconEnabled = true

                        fc.cameraTouch      = nil
                        fc.cameraTouchStart = nil
                        fc.joystickTouch    = nil
                        fc.joystickOrigin   = nil
                        fc.joystickInput    = Vector3.new()
                    end
                end,
            })

            if not (UIS.TouchEnabled and not UIS.KeyboardEnabled) then
                UIS.InputBegan:Connect(function(input, gp)
                    if gp then return end
                    if input.KeyCode == Enum.KeyCode.F3 then
                        freecamToggle:SetValue(not (_G._Freecam and _G._Freecam.enabled))
                    end
                end)
            end

            CameraSection:AddInput({
                Title    = "Freecam Speed",
                Default  = "50",
                Callback = function(value)
                    local n = tonumber(value)
                    if n then
                        if not _G._Freecam then _G._Freecam = {} end
                        _G._Freecam.speed = math.max(1, n)
                    end
                end,
            })

            CameraSection:AddInput({
                Title    = "Freecam Sensitivity",
                Default  = "0.3",
                Callback = function(value)
                    local n = tonumber(value)
                    if n then
                        if not _G._Freecam then _G._Freecam = {} end
                        _G._Freecam.sensitivity = math.clamp(n, 0.01, 5)
                    end
                end,
            })
        end
        do
            local _zoom = {
                originalMin = LocalPlayer.CameraMinZoomDistance,
                originalMax = LocalPlayer.CameraMaxZoomDistance,
            }
            CameraSection:AddToggle({
                Title    = "Unlimited Zoom",
                Default  = false,
                Callback = function(on)
                    if on then
                        LocalPlayer.CameraMinZoomDistance = 0.5
                        LocalPlayer.CameraMaxZoomDistance = 9999
                    else
                        LocalPlayer.CameraMinZoomDistance = _zoom.originalMin
                        LocalPlayer.CameraMaxZoomDistance = _zoom.originalMax
                    end
                end,
            })
        end
    end
    do
        local PlayerSection = SettingsTab:AddSection("Player Features")

        local function getChar()
            return LocalPlayer.Character
        end
        local function getHumanoid()
            local char = getChar()
            return char and char:FindFirstChildOfClass("Humanoid")
        end
        local function getRootPart()
            local char = getChar()
            return char and char:FindFirstChild("HumanoidRootPart")
        end

        local sprintState = {
            enabled  = false,
            value    = 50,
            conn     = nil,
            charConn = nil,
        }

        PlayerSection:AddToggle({
            Title    = "Enable Sprint",
            Default  = false,
            Callback = function(on)
                sprintState.enabled = on
                if sprintState.conn     then sprintState.conn:Disconnect();     sprintState.conn     = nil end
                if sprintState.charConn then sprintState.charConn:Disconnect(); sprintState.charConn = nil end
                if not on then
                    local hum = getHumanoid()
                    if hum then hum.WalkSpeed = 16 end
                    return
                end
                local hum = getHumanoid()
                if hum then hum.WalkSpeed = sprintState.value end
                local timer = 0
                sprintState.conn = RunService.Heartbeat:Connect(function(dt)
                    if not sprintState.enabled then return end
                    timer = timer + dt
                    if timer < 0.25 then return end
                    timer = 0
                    local h = getHumanoid()
                    if h and h.WalkSpeed ~= sprintState.value then
                        h.WalkSpeed = sprintState.value
                    end
                end)
                sprintState.charConn = LocalPlayer.CharacterAdded:Connect(function()
                    task.wait(0.5)
                    if not sprintState.enabled then return end
                    local h = getHumanoid()
                    if h then h.WalkSpeed = sprintState.value end
                end)
            end,
        })

        PlayerSection:AddInput({
            Title    = "Sprint Speed",
            Default  = "50",
            Callback = function(value)
                local n = tonumber(value)
                if not n then return end
                sprintState.value = n
                if sprintState.enabled then
                    local hum = getHumanoid()
                    if hum then hum.WalkSpeed = n end
                end
            end,
        })

        local infJumpState = {
            enabled = false,
            conn    = nil,
        }

        PlayerSection:AddToggle({
            Title    = "Infinite Jump",
            Default  = false,
            Callback = function(on)
                infJumpState.enabled = on
                if infJumpState.conn then infJumpState.conn:Disconnect(); infJumpState.conn = nil end
                if not on then return end
                infJumpState.conn = UIS.JumpRequest:Connect(function()
                    if not infJumpState.enabled then return end
                    local hum = getHumanoid()
                    if hum then hum:ChangeState(Enum.HumanoidStateType.Jumping) end
                end)
            end,
        })

        local flyState = {
            flying   = false,
            speed    = 50,
            isMobile = UIS.TouchEnabled and not UIS.KeyboardEnabled,
            keyDown  = nil,
            keyUp    = nil,
            loop     = nil,
            bg       = nil,
            bv       = nil,
        }

        local function stopFly()
            flyState.flying = false
            if flyState.keyDown then flyState.keyDown:Disconnect(); flyState.keyDown = nil end
            if flyState.keyUp   then flyState.keyUp:Disconnect();   flyState.keyUp   = nil end
            if flyState.loop    then flyState.loop:Disconnect();    flyState.loop    = nil end
            if flyState.bg      then flyState.bg:Destroy();         flyState.bg      = nil end
            if flyState.bv      then flyState.bv:Destroy();         flyState.bv      = nil end
            local hum = getHumanoid()
            if hum then hum.PlatformStand = false end
        end

        PlayerSection:AddToggle({
            Title    = "Enable Fly",
            Default  = false,
            NoSave   = true,
            Callback = function(on)
                if not on then
                    stopFly()
                    return
                end

                local char = getChar()
                local hum  = getHumanoid()
                local root = getRootPart()
                if not char or not hum or not root then
                    warn("[Fly] Character not ready")
                    return
                end

                flyState.flying       = true
                hum.PlatformStand     = true

                flyState.bg           = Instance.new("BodyGyro")
                flyState.bg.P         = 9e4
                flyState.bg.MaxTorque = Vector3.new(9e9, 9e9, 9e9)
                flyState.bg.CFrame    = root.CFrame
                flyState.bg.Parent    = root

                flyState.bv           = Instance.new("BodyVelocity")
                flyState.bv.Velocity  = Vector3.zero
                flyState.bv.MaxForce  = Vector3.new(9e9, 9e9, 9e9)
                flyState.bv.Parent    = root

                if not flyState.isMobile then
                    local CONTROL = {F=0, B=0, L=0, R=0, U=0, D=0}

                    flyState.keyDown = UIS.InputBegan:Connect(function(input, processed)
                        if processed then return end
                        if     input.KeyCode == Enum.KeyCode.W           then CONTROL.F = 1
                        elseif input.KeyCode == Enum.KeyCode.S           then CONTROL.B = 1
                        elseif input.KeyCode == Enum.KeyCode.A           then CONTROL.L = 1
                        elseif input.KeyCode == Enum.KeyCode.D           then CONTROL.R = 1
                        elseif input.KeyCode == Enum.KeyCode.Space       then CONTROL.U = 1
                        elseif input.KeyCode == Enum.KeyCode.E           then CONTROL.U = 1
                        elseif input.KeyCode == Enum.KeyCode.Q           then CONTROL.D = 1
                        elseif input.KeyCode == Enum.KeyCode.LeftControl then CONTROL.D = 1
                        end
                    end)

                    flyState.keyUp = UIS.InputEnded:Connect(function(input, processed)
                        if processed then return end
                        if     input.KeyCode == Enum.KeyCode.W           then CONTROL.F = 0
                        elseif input.KeyCode == Enum.KeyCode.S           then CONTROL.B = 0
                        elseif input.KeyCode == Enum.KeyCode.A           then CONTROL.L = 0
                        elseif input.KeyCode == Enum.KeyCode.D           then CONTROL.R = 0
                        elseif input.KeyCode == Enum.KeyCode.Space       then CONTROL.U = 0
                        elseif input.KeyCode == Enum.KeyCode.E           then CONTROL.U = 0
                        elseif input.KeyCode == Enum.KeyCode.Q           then CONTROL.D = 0
                        elseif input.KeyCode == Enum.KeyCode.LeftControl then CONTROL.D = 0
                        end
                    end)

                    flyState.loop = RunService.Heartbeat:Connect(function()
                        if not flyState.flying or not flyState.bv or not flyState.bv.Parent then return end
                        local cam     = workspace.CurrentCamera
                        local moveDir = Vector3.zero
                        moveDir += cam.CFrame.LookVector  * (CONTROL.F - CONTROL.B)
                        moveDir += cam.CFrame.RightVector * (CONTROL.R - CONTROL.L)
                        moveDir += Vector3.new(0, 1, 0)   * (CONTROL.U - CONTROL.D)
                        flyState.bv.Velocity = if moveDir.Magnitude > 0 then moveDir.Unit * flyState.speed else Vector3.zero
                        flyState.bg.CFrame   = cam.CFrame
                    end)
                else
                    local ok, controlModule = pcall(function()
                        return require(LocalPlayer.PlayerScripts:WaitForChild("PlayerModule"):WaitForChild("ControlModule"))
                    end)

                    flyState.loop = RunService.RenderStepped:Connect(function()
                        if not flyState.flying or not flyState.bv or not flyState.bv.Parent then return end
                        local c = getChar()
                        local h = getHumanoid()
                        if not c or not h then return end
                        local cam     = workspace.CurrentCamera
                        local moveDir = Vector3.zero
                        flyState.bg.CFrame = cam.CFrame
                        if ok and controlModule then
                            local dir = controlModule:GetMoveVector()
                            if dir.Magnitude > 0 then
                                local flat  = Vector3.new(cam.CFrame.LookVector.X,  0, cam.CFrame.LookVector.Z).Unit
                                local rflat = Vector3.new(cam.CFrame.RightVector.X, 0, cam.CFrame.RightVector.Z).Unit
                                moveDir -= flat  * dir.Z
                                moveDir += rflat * dir.X
                            end
                        else
                            local move = h.MoveDirection
                            if move.Magnitude > 0 then
                                local flat  = Vector3.new(cam.CFrame.LookVector.X,  0, cam.CFrame.LookVector.Z).Unit
                                local rflat = Vector3.new(cam.CFrame.RightVector.X, 0, cam.CFrame.RightVector.Z).Unit
                                moveDir += flat  * (-move.Z)
                                moveDir += rflat * move.X
                            end
                        end
                        flyState.bv.Velocity = if moveDir.Magnitude > 0 then moveDir.Unit * flyState.speed else Vector3.zero
                    end)
                end
            end,
        })

        PlayerSection:AddInput({
            Title    = "Fly Speed",
            Default  = "50",
            NoSave   = true,
            Callback = function(val)
                flyState.speed = math.clamp(tonumber(val) or 50, 1, 500)
            end,
        })

        local noclipState = {
            enabled  = false,
            conn     = nil,
            charConn = nil,
        }

        local function stopNoclip()
            noclipState.enabled = false
            if noclipState.conn     then noclipState.conn:Disconnect();     noclipState.conn     = nil end
            if noclipState.charConn then noclipState.charConn:Disconnect(); noclipState.charConn = nil end
            local char = getChar()
            if char then
                for _, part in ipairs(char:GetDescendants()) do
                    if part:IsA("BasePart") then
                        part.CanCollide = true
                    end
                end
            end
        end

        local function startNoclip()
            if noclipState.conn then noclipState.conn:Disconnect(); noclipState.conn = nil end
            noclipState.conn = RunService.Stepped:Connect(function()
                if not noclipState.enabled then return end
                local char = getChar()
                if not char then return end
                for _, part in ipairs(char:GetDescendants()) do
                    if part:IsA("BasePart") then
                        part.CanCollide = false
                    end
                end
            end)
        end

        PlayerSection:AddToggle({
            Title    = "No Clip",
            Default  = false,
            NoSave   = true,
            Callback = function(on)
                if noclipState.charConn then noclipState.charConn:Disconnect(); noclipState.charConn = nil end
                if not on then
                    stopNoclip()
                    return
                end
                noclipState.enabled = true
                startNoclip()
                noclipState.charConn = LocalPlayer.CharacterAdded:Connect(function()
                    task.wait(0.5)
                    if not noclipState.enabled then return end
                    startNoclip()
                end)
            end,
        })
    end
    do
        local PerformanceSection = SettingsTab:AddSection("Performance")
        local Terrain      = workspace:FindFirstChildOfClass("Terrain")
        local Lighting     = game:GetService("Lighting")
        local StarterGui   = game:GetService("StarterGui")
        local SoundService = game:GetService("SoundService")
        local E_SMOOTH    = Enum.SurfaceType.SmoothNoOutlines
        local E_PLASTIC   = Enum.Material.SmoothPlastic
        local E_LEGACY    = Enum.Technology.Legacy
        local E_LVL1      = Enum.QualityLevel.Level01
        local E_MESH1     = Enum.MeshPartDetailLevel.Level01
        local E_AUTO      = Enum.QualityLevel.Automatic
        local E_DISTBASE  = Enum.MeshPartDetailLevel.DistanceBased
        local E_SAVEDAUTO = Enum.SavedQualitySetting.Automatic
        local E_SAVEDQ1   = Enum.SavedQualitySetting.QualityLevel1
        local E_NOREVRB   = Enum.ReverbType.NoReverb
        local E_LISTCAM   = Enum.ListenerType.Camera
        local WHITE       = Color3.new(1, 1, 1)
        local SURFACES    = { "TopSurface","BottomSurface","LeftSurface","RightSurface","FrontSurface","BackSurface" }
        local DESTROY_SET = {
            ParticleEmitter=true, Trail=true, Beam=true, Fire=true,
            Smoke=true, Sparkles=true, ForceField=true, Explosion=true,
            BloomEffect=true, BlurEffect=true, ColorCorrectionEffect=true,
            SunRaysEffect=true, DepthOfFieldEffect=true, Atmosphere=true,
            Decal=true, Texture=true, SurfaceAppearance=true,
            SpecialMesh=true, BlockMesh=true, CylinderMesh=true,
            PointLight=true, SpotLight=true, SurfaceLight=true,
            Accessory=true, Hat=true, Shirt=true, Pants=true,
            ShirtGraphic=true, CharacterMesh=true, BodyColors=true,
            Clothing=true, HumanoidDescription=true,
        }
        local _potato = {
            enabled          = false,
            connections      = {},
            processedObjects = setmetatable({}, { __mode = "k" }),
            origStates       = { lighting = {}, water = {}, camera = {} },
        }
        local function _optimizeObj(obj)
            if _potato.processedObjects[obj] then return end
            _potato.processedObjects[obj] = true
            if DESTROY_SET[obj.ClassName] then
                obj:Destroy()
                return
            end
            if obj:IsA("BasePart") then
                obj.Material    = E_PLASTIC
                obj.CastShadow  = false
                obj.Reflectance = 0
                for i = 1, 6 do obj[SURFACES[i]] = E_SMOOTH end
            end
        end
        local function _optimizeChar(char)
            if not char or _potato.processedObjects[char] then return end
            _potato.processedObjects[char] = true
            pcall(function()
                local desc = char:GetDescendants()
                for i = 1, #desc do
                    local obj = desc[i]
                    if DESTROY_SET[obj.ClassName] then
                        obj:Destroy()
                    elseif obj:IsA("BasePart") then
                        if obj.Name == "Head" then obj.Transparency = 1 end
                        obj.Material    = E_PLASTIC
                        obj.CastShadow  = false
                        obj.Reflectance = 0
                        obj.CanCollide  = (obj.Name == "HumanoidRootPart" or obj.Name == "Head")
                        for s = 1, 6 do obj[SURFACES[s]] = E_SMOOTH end
                    elseif obj:IsA("Humanoid") then
                        local tracks = obj:GetPlayingAnimationTracks()
                        for t = 1, #tracks do tracks[t]:Stop(0) end
                        obj.HealthDisplayDistance = 0
                        obj.NameDisplayDistance   = 0
                    end
                end
            end)
        end
        local function _potatoCleanup()
            local conns = _potato.connections
            for i = 1, #conns do pcall(conns[i].Disconnect, conns[i]) end
            _potato.connections      = {}
            _potato.processedObjects = setmetatable({}, { __mode = "k" })
        end
        local function _applyWorldSettings()
            if Terrain then
                pcall(function()
                    _potato.origStates.water = {
                        WaterReflectance  = Terrain.WaterReflectance,
                        WaterWaveSize     = Terrain.WaterWaveSize,
                        WaterWaveSpeed    = Terrain.WaterWaveSpeed,
                        WaterTransparency = Terrain.WaterTransparency,
                    }
                    Terrain.WaterWaveSize     = 0
                    Terrain.WaterWaveSpeed    = 0
                    Terrain.WaterReflectance  = 0
                    Terrain.WaterTransparency = 1
                    Terrain.Decoration        = false
                end)
                local clouds = Terrain:FindFirstChildOfClass("Clouds")
                if clouds then clouds:Destroy() end
            end
            pcall(function()
                _potato.origStates.lighting = {
                    GlobalShadows = Lighting.GlobalShadows,
                    Brightness    = Lighting.Brightness,
                    Technology    = Lighting.Technology,
                }
                Lighting.GlobalShadows            = false
                Lighting.FogEnd                   = 9e9
                Lighting.Brightness               = 0
                Lighting.OutdoorAmbient           = WHITE
                Lighting.Ambient                  = WHITE
                Lighting.Technology               = E_LEGACY
                Lighting.EnvironmentDiffuseScale  = 0
                Lighting.EnvironmentSpecularScale = 0
                Lighting.ShadowSoftness           = 0
            end)
            local lchildren = Lighting:GetChildren()
            for i = 1, #lchildren do
                local c = lchildren[i]
                if c:IsA("PostEffect") or c:IsA("Atmosphere") then
                    pcall(c.Destroy, c)
                elseif c:IsA("Sky") then
                    pcall(function()
                        c.StarCount            = 0
                        c.SunAngularSize       = 0
                        c.MoonAngularSize      = 0
                        c.CelestialBodiesShown = false
                        c.SkyboxBk = ""; c.SkyboxDn = ""; c.SkyboxFt = ""
                        c.SkyboxLf = ""; c.SkyboxRt = ""; c.SkyboxUp = ""
                    end)
                end
            end
            pcall(function()
                SoundService.AmbientReverb = E_NOREVRB
                SoundService:SetListener(E_LISTCAM)
            end)
            pcall(function()
                local rs = settings().Rendering
                rs.QualityLevel        = E_LVL1
                rs.MeshPartDetailLevel = E_MESH1
                rs.EditQualityLevel    = E_LVL1
            end)
            pcall(function()
                local ugs = UserSettings():GetService("UserGameSettings")
                ugs.SavedQualityLevel    = E_SAVEDQ1
                ugs.GraphicsQualityLevel = 1
            end)
            pcall(function()
                local cam = workspace.CurrentCamera
                if cam then
                    _potato.origStates.camera = { FieldOfView = cam.FieldOfView }
                    cam.FieldOfView = 70
                end
            end)
            pcall(function()
                StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.PlayerList, false)
                StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.EmotesMenu, false)
            end)
        end
        local function _restoreWorldSettings()
            if Terrain and _potato.origStates.water.WaterReflectance ~= nil then
                pcall(function()
                    local w = _potato.origStates.water
                    Terrain.WaterReflectance  = w.WaterReflectance
                    Terrain.WaterWaveSize     = w.WaterWaveSize
                    Terrain.WaterWaveSpeed    = w.WaterWaveSpeed
                    Terrain.WaterTransparency = w.WaterTransparency
                    Terrain.Decoration        = true
                end)
            end
            pcall(function()
                local l = _potato.origStates.lighting
                if l.GlobalShadows ~= nil then
                    Lighting.GlobalShadows = l.GlobalShadows
                    Lighting.Brightness    = l.Brightness
                    Lighting.Technology    = l.Technology
                end
            end)
            pcall(function()
                local cam = workspace.CurrentCamera
                if cam and _potato.origStates.camera.FieldOfView then
                    cam.FieldOfView = _potato.origStates.camera.FieldOfView
                end
            end)
            pcall(function()
                local rs = settings().Rendering
                rs.QualityLevel        = E_AUTO
                rs.MeshPartDetailLevel = E_DISTBASE
            end)
            pcall(function()
                UserSettings():GetService("UserGameSettings").SavedQualityLevel = E_SAVEDAUTO
            end)
            pcall(function()
                StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.PlayerList, true)
                StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.EmotesMenu, true)
            end)
            _potato.origStates = { lighting = {}, water = {}, camera = {} }
        end
        PerformanceSection:AddToggle({
            Title    = "FPS Booster (Potato Mode)",
            Default  = false,
            Callback = function(on)
                _potato.enabled = on
                _potatoCleanup()
                if not on then
                    _restoreWorldSettings()
                    Library:MakeNotify({ Title="FPS Booster", Description="Dimatikan, grafik dikembalikan.", Delay=3 })
                    return
                end
                _applyWorldSettings()
                task.spawn(function()
                    while _potato.enabled do
                        _potato.processedObjects = setmetatable({}, { __mode = "k" })
                        local all   = workspace:GetDescendants()
                        local n     = #all
                        local BATCH = 50
                        for i = 1, n, BATCH do
                            if not _potato.enabled then break end
                            for j = i, math.min(i + BATCH - 1, n) do
                                _optimizeObj(all[j])
                            end
                            task.wait()
                        end
                        if not _potato.enabled then break end
                        for _, plr in ipairs(Players:GetPlayers()) do
                            if plr.Character then task.defer(_optimizeChar, plr.Character) end
                        end
                        local waitTime = 600
                        while waitTime > 0 and _potato.enabled do
                            task.wait(1)
                            waitTime = waitTime - 1
                        end
                        if _potato.enabled then
                            pcall(_applyWorldSettings)
                        end
                    end
                end)
                _potato.connections[#_potato.connections+1] = Players.PlayerAdded:Connect(function(plr)
                    _potato.connections[#_potato.connections+1] = plr.CharacterAdded:Connect(function(char)
                        if not _potato.enabled then return end
                        task.delay(0.2, function()
                            if _potato.enabled then _optimizeChar(char) end
                        end)
                    end)
                    if plr.Character then task.defer(_optimizeChar, plr.Character) end
                end)
                _potato.connections[#_potato.connections+1] = LocalPlayer.CharacterAdded:Connect(function(char)
                    if not _potato.enabled then return end
                    task.delay(0.2, function()
                        if _potato.enabled then _optimizeChar(char) end
                    end)
                end)
                _potato.connections[#_potato.connections+1] = workspace.DescendantAdded:Connect(function(obj)
                    if not _potato.enabled then return end
                    _optimizeObj(obj)
                end)
                Library:MakeNotify({ Title="FPS Booster", Description="Aktif! Grafik diringankan.", Delay=3 })
            end,
        })

        local _disableRender = {
            enabled  = false,
            charConn = nil,
        }
        PerformanceSection:AddToggle({
            Title    = "Disable 3D Rendering",
            Default  = false,
            Callback = function(on)
                _disableRender.enabled = on
                if _disableRender.charConn then
                    _disableRender.charConn:Disconnect()
                    _disableRender.charConn = nil
                end
                if not on then
                    pcall(function() RunService:Set3dRenderingEnabled(true) end)
                    Library:MakeNotify({ Title="Disable Rendering", Description="3D Rendering dinyalakan kembali.", Delay=3 })
                    return
                end
                local ok = pcall(function() RunService:Set3dRenderingEnabled(false) end)
                if not ok then
                    pcall(function()
                        local cam = workspace.CurrentCamera
                        if cam then cam.CameraType = Enum.CameraType.Scriptable end
                    end)
                end
                _disableRender.charConn = LocalPlayer.CharacterAdded:Connect(function()
                    if not _disableRender.enabled then return end
                    task.wait(0.3)
                    local ok2 = pcall(function() RunService:Set3dRenderingEnabled(false) end)
                    if not ok2 then
                        pcall(function()
                            local cam = workspace.CurrentCamera
                            if cam then cam.CameraType = Enum.CameraType.Scriptable end
                        end)
                    end
                end)
                Library:MakeNotify({ Title="Disable Rendering", Description="3D Rendering dinyalakan kembali.", Delay=3 })
            end,
        })

        PerformanceSection:AddToggle({
            Title    = "Disable Weather VFX",
            Default  = false,
            Callback = function(on)
                if not _G._WeatherVFX2 then _G._WeatherVFX2 = {} end
                local w = _G._WeatherVFX2
                if w.conns then
                    for _, c in ipairs(w.conns) do pcall(function() c:Disconnect() end) end
                end
                w.conns = {}
                local WEATHER_NAMES = {
                    "Storm", "Cloudy", "Snow", "Rain",
                    "Fog", "Galaxy", "Sandstorm", "Blizzard",
                }
                local nameSet = {}
                for _, name in ipairs(WEATHER_NAMES) do
                    nameSet[name] = true
                end
                local function isWeather(obj)
                    return nameSet[obj.Name] == true
                end
                local function destroyWeatherVFX()
                    for _, obj in ipairs(workspace:GetChildren()) do
                        if isWeather(obj) then
                            pcall(function() obj:Destroy() end)
                        end
                    end
                    local char = game:GetService("Players").LocalPlayer.Character
                    if char then
                        for _, obj in ipairs(char:GetChildren()) do
                            if isWeather(obj) then
                                pcall(function() obj:Destroy() end)
                            end
                        end
                    end
                end
                if on then
                    destroyWeatherVFX()
                    table.insert(w.conns, workspace.ChildAdded:Connect(function(child)
                        if isWeather(child) then
                            pcall(function() child:Destroy() end)
                        end
                    end))
                    local lp = game:GetService("Players").LocalPlayer
                    local function watchChar(char)
                        table.insert(w.conns, char.ChildAdded:Connect(function(child)
                            if isWeather(child) then
                                pcall(function() child:Destroy() end)
                            end
                        end))
                        destroyWeatherVFX()
                    end
                    if lp.Character then
                        watchChar(lp.Character)
                    end
                    table.insert(w.conns, lp.CharacterAdded:Connect(function(char)
                        watchChar(char)
                    end))
                end
            end,
        })

        local _unlockFPS = {
            enabled     = false,
            cap         = 240,
            originalCap = nil,
        }
        PerformanceSection:AddToggle({
            Title    = "Unlock FPS",
            Default  = false,
            Callback = function(on)
                _unlockFPS.enabled = on
                if not on then
                    if _unlockFPS.originalCap and setfpscap then
                        setfpscap(_unlockFPS.originalCap)
                    end
                    _unlockFPS.originalCap = nil
                    return
                end
                if not setfpscap then
                    Library:MakeNotify({ Title="Unlock FPS", Description="setfpscap() tidak tersedia di executor kamu.", Delay=3 })
                    return
                end
                _unlockFPS.originalCap = getfpscap and getfpscap() or nil
                setfpscap(_unlockFPS.cap)
                Library:MakeNotify({ Title="Unlock FPS", Description="FPS Cap diset ke " .. tostring(_unlockFPS.cap) .. " FPS.", Delay=3 })
            end,
        })
        PerformanceSection:AddDropdown({
            Title    = "FPS Cap",
            Options  = { "60", "90", "120", "144", "240" },
            Default  = "240",
            Callback = function(selected)
                _unlockFPS.cap = tonumber(selected) or 240
                if not _unlockFPS.enabled or not setfpscap then return end
                setfpscap(_unlockFPS.cap)
                Library:MakeNotify({ Title="FPS Cap", Description="FPS Cap diubah ke " .. selected .. " FPS.", Delay=2 })
            end,
        })
    end

    do
        local NotificationSection = SettingsTab:AddSection("Notification Position")
        local customPosEnabled = false
        local currentAlign = "Tengah"
        local origState = nil
        local function updatePosition()
            local pg = LocalPlayer:FindFirstChild("PlayerGui")
            if not pg then return end
            local tn = pg:FindFirstChild("Text Notifications")
            if not tn then return end
            local frame = tn:FindFirstChild("Frame")
            if not frame then return end
            local layout = frame:FindFirstChildOfClass("UIListLayout")
            if not origState then
                origState = {
                    AnchorPoint = frame.AnchorPoint,
                    Position = frame.Position,
                    HorizontalAlignment = layout and layout.HorizontalAlignment or Enum.HorizontalAlignment.Center
                }
            end
            if not customPosEnabled then
                if origState then
                    frame.AnchorPoint = origState.AnchorPoint
                    frame.Position = origState.Position
                    if layout then layout.HorizontalAlignment = origState.HorizontalAlignment end
                end
                return
            end
            if currentAlign == "Kiri" then
                frame.AnchorPoint = Vector2.new(0, 0)
                frame.Position = UDim2.new(0, 5, 0, 110)
                if layout then layout.HorizontalAlignment = Enum.HorizontalAlignment.Left end
            elseif currentAlign == "Tengah" then
                frame.AnchorPoint = Vector2.new(0.5, 0)
                frame.Position = UDim2.new(0.5, 0, 0, 110)
                if layout then layout.HorizontalAlignment = Enum.HorizontalAlignment.Center end
            elseif currentAlign == "Kanan" then
                frame.AnchorPoint = Vector2.new(1, 0)
                frame.Position = UDim2.new(1, -5, 0, 110)
                if layout then layout.HorizontalAlignment = Enum.HorizontalAlignment.Right end
            end
        end

        NotificationSection:AddToggle({
            Title    = "Enable Custom Notification Position",
            Default  = false,
            Callback = function(v)
                customPosEnabled = v
                updatePosition()
            end,
        })

        NotificationSection:AddDropdown({
            Title    = "Select Position",
            Options  = {"Kiri", "Tengah", "Kanan"},
            Default  = "Tengah",
            Callback = function(v)
                currentAlign = v
                updatePosition()
            end,
        })
    end
    do
        local HideStatsSection = SettingsTab:AddSection("Hide Stats")
        local PREMIUM_CHAR = ""
        local VERIFY_CHAR  = ""
        local _hideStats = {
            enabled         = false,
            showScriptLabel = true,
            premiumLogo     = false,
            verifyLogo      = false,
            fakeName        = "LynX",
            fakeLevel       = "501",
            scriptName      = "discord.gg/lynxx",
            origTexts       = {},
            origPLName      = nil,
            labelConns      = {},
            plRunning       = false,
            charConn        = nil,
        }

        local function _getBuiltName()
            local name = _hideStats.fakeName
            if _hideStats.premiumLogo then name = name .. PREMIUM_CHAR end
            if _hideStats.verifyLogo  then name = name .. VERIFY_CHAR  end
            return name
        end

        local function _getOverhead()
            local char = LocalPlayer.Character
            local hrp  = char and char:FindFirstChild("HumanoidRootPart")
            return hrp and hrp:FindFirstChild("Overhead")
        end

        local function _removeScriptLabel()
            local overhead = _getOverhead()
            if not overhead then return end
            local lynxFrame = overhead:FindFirstChild("LynxFrame")
            if not lynxFrame then return end
            local nameLabel = overhead:FindFirstChild("Header", true)
            if nameLabel then
                local nameFrame = nameLabel.Parent
                if nameFrame and nameFrame:IsA("Frame") then
                    local p = nameFrame.Position
                    nameFrame.Position = UDim2.new(p.X.Scale, p.X.Offset, p.Y.Scale - 0.25, p.Y.Offset)
                end
            end
            lynxFrame:Destroy()
        end

        local function _createScriptLabel(nameLabel, overhead)
            if not nameLabel or not overhead then return end
            if overhead:FindFirstChild("LynxFrame") then return end
            local nameFrame = nameLabel.Parent
            if not nameFrame or not nameFrame:IsA("Frame") then return end
            local origPos = nameFrame.Position
            nameFrame.Position = UDim2.new(origPos.X.Scale, origPos.X.Offset, origPos.Y.Scale + 0.25, origPos.Y.Offset)
            local lynxFrame                  = Instance.new("Frame")
            lynxFrame.Name                   = "LynxFrame"
            lynxFrame.Size                   = nameFrame.Size
            lynxFrame.Position               = origPos
            lynxFrame.BackgroundTransparency = 1
            lynxFrame.Parent                 = overhead
            local lbl                        = nameLabel:Clone()
            lbl.Name                         = "LynxLabel"
            lbl.Text                         = _hideStats.scriptName
            lbl.TextScaled                   = true
            lbl.Font                         = Enum.Font.GothamBold
            lbl.TextStrokeTransparency       = 0.5
            lbl.TextStrokeColor3             = Color3.fromRGB(0, 0, 0)
            lbl.TextColor3                   = Color3.fromRGB(255, 140, 0)
            lbl.Parent                       = lynxFrame
        end

        local function _applyToLabel(obj, overhead)
            if not obj:IsA("TextLabel") then return end
            local path = obj:GetFullName()
            if not _hideStats.origTexts[path] then
                _hideStats.origTexts[path] = obj.Text
            end
            local orig = _hideStats.origTexts[path]
            if not orig or orig == "" then return end
            if obj.Name == "Header" then
                if _hideStats.showScriptLabel then
                    _createScriptLabel(obj, overhead)
                end
                obj.Text = _getBuiltName()
            elseif string.find(string.lower(orig), "lvl") then
                obj.Text = string.gsub(orig, "%d+", _hideStats.fakeLevel)
            end
        end

        local function _disconnectLabelConns()
            for _, conn in ipairs(_hideStats.labelConns) do
                pcall(function() conn:Disconnect() end)
            end
            _hideStats.labelConns = {}
        end

        local function _watchOverhead()
            if not _hideStats.enabled then return end
            _disconnectLabelConns()
            local overhead = _getOverhead()
            if not overhead then return end
            if not _hideStats.showScriptLabel then
                _removeScriptLabel()
            end
            for _, obj in ipairs(overhead:GetDescendants()) do
                if obj:IsA("TextLabel") then
                    _applyToLabel(obj, overhead)
                    local conn = obj:GetPropertyChangedSignal("Text"):Connect(function()
                        if not _hideStats.enabled then return end
                        local path    = obj:GetFullName()
                        local current = obj.Text
                        if current ~= _getBuiltName()
                        and not string.find(current, _hideStats.fakeLevel) then
                            _hideStats.origTexts[path] = current
                        end
                        _applyToLabel(obj, overhead)
                    end)
                    table.insert(_hideStats.labelConns, conn)
                end
            end
        end

        local function _restoreOverhead()
            for path, origText in pairs(_hideStats.origTexts) do
                pcall(function()
                    local obj = game
                    for part in string.gmatch(path, "[^.]+") do
                        obj = obj and obj:FindFirstChild(part)
                    end
                    if obj and obj:IsA("TextLabel") then
                        obj.Text = origText
                    end
                end)
            end
            _hideStats.origTexts = {}
            _removeScriptLabel()
        end

        local function _getPlayerListLabel()
            local userId = tostring(LocalPlayer.UserId)
            local ok, result = pcall(function()
                local coreGui    = game:GetService("CoreGui")
                local playerList = coreGui:FindFirstChild("PlayerList", true)
                if not playerList then return nil end
                for _, obj in ipairs(playerList:GetDescendants()) do
                    if obj:IsA("TextLabel") and obj.Name == "PlayerName" then
                        if string.find(obj:GetFullName(), userId) then
                            return obj
                        end
                    end
                end
                return nil
            end)
            return ok and result or nil
        end

        local function _applyPlayerListName()
            if not _hideStats.enabled then return end
            local lbl = _getPlayerListLabel()
            if not lbl then return end
            if not _hideStats.origPLName and lbl.Text ~= _getBuiltName() then
                _hideStats.origPLName = lbl.Text
            end
            if lbl.Text ~= _getBuiltName() then
                lbl.Text = _getBuiltName()
            end
        end

        local function _restorePlayerListName()
            local lbl = _getPlayerListLabel()
            if lbl and _hideStats.origPLName then
                lbl.Text = _hideStats.origPLName
            end
            _hideStats.origPLName = nil
        end

        local function _startPlayerListWatch()
            if not _hideStats.enabled then return end
            if _hideStats.plRunning then return end
            _hideStats.plRunning = true
            task.spawn(function()
                while _hideStats.plRunning and _hideStats.enabled do
                    pcall(_applyPlayerListName)
                    task.wait(0.5)
                end
                _hideStats.plRunning = false
            end)
        end

        local function _stopPlayerListWatch()
            _hideStats.plRunning = false
            _restorePlayerListName()
        end

        local function _cleanupAll()
            _disconnectLabelConns()
            _stopPlayerListWatch()
            if _hideStats.charConn then
                _hideStats.charConn:Disconnect()
                _hideStats.charConn = nil
            end
            _restoreOverhead()
        end

        HideStatsSection:AddToggle({
            Title    = "Enable Hide Stats",
            Default  = false,
            Callback = function(on)
                _hideStats.enabled = on
                if not on then
                    _cleanupAll()
                    return
                end
                _watchOverhead()
                _startPlayerListWatch()
                if _hideStats.charConn then
                    _hideStats.charConn:Disconnect()
                    _hideStats.charConn = nil
                end
                _hideStats.charConn = LocalPlayer.CharacterAdded:Connect(function()
                    _hideStats.origTexts = {}
                    task.wait(1)
                    if not _hideStats.enabled then return end
                    _watchOverhead()
                    _startPlayerListWatch()
                end)
            end,
        })

        HideStatsSection:AddToggle({
            Title    = "Show Script Title",
            Default  = true,
            Callback = function(on)
                _hideStats.showScriptLabel = on
                if not _hideStats.enabled then return end
                if not on then _removeScriptLabel() end
                _watchOverhead()
            end,
        })

        HideStatsSection:AddToggle({
            Title    = "Enable Premium Logo",
            Default  = false,
            Callback = function(on)
                _hideStats.premiumLogo = on
                if not _hideStats.enabled then return end
                _watchOverhead()
                pcall(_applyPlayerListName)
            end,
        })

        HideStatsSection:AddToggle({
            Title    = "Enable Verification Logo",
            Default  = false,
            Callback = function(on)
                _hideStats.verifyLogo = on
                if not _hideStats.enabled then return end
                _watchOverhead()
                pcall(_applyPlayerListName)
            end,
        })

        HideStatsSection:AddInput({
            Title    = "Fake Name",
            Default  = "LynX",
            Callback = function(value)
                _hideStats.fakeName = value or "LynX"
                if not _hideStats.enabled then return end
                _watchOverhead()
                pcall(_applyPlayerListName)
            end,
        })

        HideStatsSection:AddInput({
            Title    = "Fake Level",
            Default  = "501",
            Callback = function(value)
                _hideStats.fakeLevel = tostring(value or "501")
                if not _hideStats.enabled then return end
                _watchOverhead()
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
    do
        local ReconnectSection = SettingsTab:AddSection("Auto Reconnect & Execute")
        local _reconnect = {
            enabled = false, setup = false, fired = false,
            errorConn = nil, overlayConn = nil,
        }

        local function _disconnectReconnectListeners()
            if _reconnect.errorConn then
                pcall(function() _reconnect.errorConn:Disconnect() end)
                _reconnect.errorConn = nil
            end
            if _reconnect.overlayConn then
                pcall(function() _reconnect.overlayConn:Disconnect() end)
                _reconnect.overlayConn = nil
            end
            _reconnect.setup = false
        end

        ReconnectSection:AddParagraph({
            Title   = "Info",
            Content = "Auto rejoin server on disconnect.\nUses Roblox ErrorPrompt detection.\nScript will auto execute after reconnect.",
        })

        ReconnectSection:AddToggle({
            Title    = "Enable Auto Reconnect",
            Default  = false,
            Callback = function(on)
                _reconnect.enabled = on

                if on then
                    _disconnectReconnectListeners()
                    _reconnect.setup  = true
                    _reconnect.fired  = false

                    local function handleReconnect(reason)
                        if not _reconnect.enabled or _reconnect.fired then return end
                        _reconnect.fired = true
                        sharedQueueAutoExecute()
                        task.wait(2)
                        pcall(function()
                            game:GetService("TeleportService"):Teleport(game.PlaceId, LocalPlayer)
                        end)
                    end

                    pcall(function()
                        local GuiService = game:GetService("GuiService")
                        _reconnect.errorConn = GuiService.ErrorMessageChanged:Connect(function(msg)
                            if msg and msg ~= "" then handleReconnect(msg) end
                        end)
                    end)

                    pcall(function()
                        local overlay = game:GetService("CoreGui")
                            :FindFirstChild("RobloxPromptGui")
                            and game:GetService("CoreGui").RobloxPromptGui:FindFirstChild("promptOverlay")
                        if overlay then
                            _reconnect.overlayConn = overlay.ChildAdded:Connect(function(child)
                                if child.Name == "ErrorPrompt" then
                                    task.wait(0.5)
                                    local lbl = child:FindFirstChildWhichIsA("TextLabel", true)
                                    handleReconnect(lbl and lbl.Text or "Disconnected")
                                end
                            end)
                        end
                    end)

                    Library:MakeNotify({
                        Title       = "Auto Reconnect",
                        Description = "Active — will auto rejoin and execute script on disconnect.",
                        Delay       = 2,
                    })
                else
                    _disconnectReconnectListeners()
                    Library:MakeNotify({
                        Title       = "Auto Reconnect",
                        Description = "Disabled.",
                        Delay       = 2,
                    })
                end
            end,
        })
    end
end

