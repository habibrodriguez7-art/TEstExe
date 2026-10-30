loadstring([[ function LPH_NO_VIRTUALIZE(f) return f end ]])()
local LYNX_KEY = key
local LYNX_SCRIPT_URL = getgenv().LYNX_SCRIPT_URL or "https://raw.githubusercontent.com/4LynxX/Game-list/refs/heads/main/steal-an-egg.lua"
do
    local previous = rawget(_G, "LynxSAE")
    if type(previous) == "table" and type(previous.Stop) == "function" then
        pcall(previous.Stop)
    end
    local containers = {}
    local function collect(getter)
        local ok, value = pcall(getter)
        if ok and typeof(value) == "Instance" then
            containers[#containers + 1] = value
        end
    end
    collect(function() return game:GetService("CoreGui") end)
    collect(function() return gethui and gethui() or nil end)
    collect(function()
        local player = game:GetService("Players").LocalPlayer
        return player and player:FindFirstChild("PlayerGui")
    end)
    for _, container in ipairs(containers) do
        if container then
            for _, name in ipairs({ "LynxGui", "LynxEggPredict" }) do
                local oldGui = container:FindFirstChild(name)
                while oldGui do
                    pcall(function() oldGui:Destroy() end)
                    oldGui = container:FindFirstChild(name)
                end
            end
        end
    end
    _G.LynxSAE = { Stoppers = {} }
    _G.LynxSAE.Stop = function()
        for _, fn in ipairs(_G.LynxSAE.Stoppers) do pcall(fn) end
    end
end
local Library = loadstring(game:HttpGet("https://raw.githubusercontent.com/habibrodriguez7-art/MainLib/refs/heads/main/rewrite.lua"))()
-- the library redraws a paragraph only while it is on screen and can miss the redraw when it comes back into view,
-- which left some live statuses on "Loading...": write the label too when it fell behind
local function setParagraph(paragraph, text)
    paragraph:SetContent(text)
    local label = rawget(paragraph, "_contentLabel")
    if typeof(label) == "Instance" and label.Text ~= text then
        label.Text = text
        label.Visible = text ~= ""
    end
end
local ReplicatedStorage, RunService, Players, UserInputService =
    game:GetService("ReplicatedStorage"), game:GetService("RunService"),
    game:GetService("Players"), game:GetService("UserInputService")
local LocalPlayer = Players.LocalPlayer
local Game = {}
do
    local cache = {}
    local function grab(instance)
        if not instance then return nil end
        local hit = cache[instance]
        if hit ~= nil then return hit end
        local ok, result = pcall(require, instance)
        if not ok then return nil end
        if result ~= nil then cache[instance] = result end
        return result
    end
    local function node(...)
        local current = ReplicatedStorage
        for _, name in ipairs({ ... }) do
            if not current then return nil end
            current = current:FindFirstChild(name)
        end
        return current
    end
    local MODULES = {
        { "EggState",      "Client", "EggState" },
        { "PlotState",     "Client", "PlotState" },
        { "ResetWall",     "Client", "AreaEggResetWall" },
        { "EggCycle",      "Shared", "Util", "AreaEggCycle" },
        { "Ragdoll",       "Shared", "Modules", "Ragdoll" },
        { "EggRecords",    "Shared", "Util", "EggRecords" },
        { "Save",          "Shared", "Save" },
        { "Remotes",       "Shared", "Remotes" },
        { "AssetItems",    "Shared", "Util", "AssetItems" },
        { "AssetRoster",   "Client", "AssetRoster" },
        { "AssetEarnings", "Shared", "Util", "AssetEarnings" },
        { "SlotIdentity",  "Shared", "Util", "AreaEggSlotIdentity" },
        { "Assets",        "Data", "Assets" },
        { "Areas",         "Data", "Areas" },
        { "Guards",        "Data", "Guards" },
        { "Gears",         "Data", "Gears" },
        { "Mutations",     "Shared", "Modules", "Mutations" },
        { "GuardGeometry", "Shared", "Util", "GuardAreaGeometry" },
        { "EscapePredict", "Shared", "Modules", "GuardAreas", "GuardEscapePrediction" },
        { "ChasePolicy",   "Shared", "Modules", "GuardAreas", "GuardChasePolicy" },
        { "FuseKernel",    "Shared", "Util", "FuseKernel" },
        { "Balance",       "Shared", "Flags", "GameplayBalance" },
    }
    local REQUIRED = {
        "EggState", "PlotState", "EggRecords", "Assets", "Save", "Remotes",
    }
    local MEMBERS = {
        Save          = { "Get", "FieldChanged" },
        EggState      = { "SyncFieldEggs", "ReadFieldEgg", "CarryFieldEgg", "DropFieldEgg",
                          "CarryChanged", "FieldClaimed" },
        EggRecords    = { "Decode", "WeightKg", "SellPrice", "ToAssetItemData" },
        AssetItems    = { "Decode", "WeightKg" },
        AssetEarnings = { "RatePerSecond" },
        PlotState     = { "ResolvePlot" },
        SlotIdentity  = { "SlotKey", "FirstAreaOwnerUserId" },
        GuardGeometry = { "IsPastLine" },
        Ragdoll       = { "IsRagdolled" },
        Assets        = { "Directory" },
        Areas         = { "Directory" },
        Balance       = { "EggInventory" },
    }
    local ADAPT = {
        Save = function(mod)
            if type(mod) ~= "table" then return mod end
            if mod.Get and mod.FieldChanged then return mod end
            local shim = {
                Get          = mod.Get or mod.Peek,
                FieldChanged = mod.FieldChanged or mod.Changed,
            }
            if not (shim.Get and shim.FieldChanged) then return mod end
            return setmetatable(shim, { __index = mod })
        end,
    }
    local function lacks(key)
        local mod = Game[key]
        if mod == nil then return true end
        for _, member in ipairs(MEMBERS[key] or {}) do
            if mod[member] == nil then return member end
        end
        return false
    end
    local function topUp()
        local complete = true
        for _, entry in ipairs(MODULES) do
            local key = entry[1]
            if lacks(key) then
                local value = grab(node(table.unpack(entry, 2)))
                local fix = ADAPT[key]
                if fix and value ~= nil then value = fix(value) end
                Game[key] = value
                if lacks(key) then complete = false end
            end
        end
        for _, key in ipairs(REQUIRED) do
            if lacks(key) then return false, complete end
        end
        return true, complete
    end
    function Game.Missing()
        local list = {}
        for _, entry in ipairs(MODULES) do
            local key = entry[1]
            local gap = lacks(key)
            if gap == true then
                list[#list + 1] = key
            elseif gap then
                list[#list + 1] = key .. "." .. tostring(gap)
            end
        end
        return list
    end
    function Game.MissingText()
        local list = Game.Missing()
        if #list == 0 then return "nothing" end
        return table.concat(list, ", ")
    end
    function Game.Init(seconds)
        local ready, complete = topUp()
        if ready and complete then return true end
        local deadline = os.clock() + (tonumber(seconds) or 3)
        repeat
            task.wait(0.25)
            ready, complete = topUp()
        until (ready and complete) or os.clock() > deadline
        return ready
    end
    task.spawn(function()
        local deadline = os.clock() + 120
        repeat
            local ready, complete = topUp()
            if ready and complete then return end
            task.wait(1)
        until os.clock() > deadline
    end)
end
local function toSet(list)
    local set = {}
    if type(list) ~= "table" then return set end
    for _, value in ipairs(list) do set[tostring(value)] = true end
    return set
end
local function isSetEmpty(set)
    for _ in pairs(set) do return false end
    return true
end
local function notify(title, desc, color, delay)
    pcall(function()
        Library:MakeNotify({
            Title       = title,
            Description = desc,
            Color       = color,
            Delay       = delay or 2,
        })
    end)
end
-- the library fires saved toggles in random order: a feature toggle can come before its filter
-- toggles, so features wait until every saved setting has been applied before acting
local function afterConfigLoad()
    while not Library._initialized do task.wait() end
    task.wait()
end
local function getCharacter()
    local character = LocalPlayer.Character
    if not character then return nil end
    local root     = character:FindFirstChild("HumanoidRootPart")
    local humanoid = character:FindFirstChildOfClass("Humanoid")
    if not root or not humanoid or humanoid.Health <= 0 then return nil end
    return character, root, humanoid
end
local function waitCharacter(timeout)
    local deadline = os.clock() + (timeout or 15)
    repeat
        local character, root, humanoid = getCharacter()
        if character then return character, root, humanoid end
        task.wait(0.2)
    until os.clock() > deadline
    return nil
end
local function worldFolder()
    return workspace:FindFirstChild("World") or workspace:FindFirstChild("__OBJECTS")
end
local function fieldEggs()
    local state = Game.EggState
    if not state then return nil end
    local okHas, has = pcall(function() return state.HasFieldSnapshot() end)
    if okHas and has then
        local okRead, rows = pcall(state.ReadFieldEggs)
        if okRead and type(rows) == "table" then return rows end
    end
    local ok, rows = pcall(state.SyncFieldEggs)
    return ok and type(rows) == "table" and rows or nil
end
local Bat = {}
do
    local gears, config = nil, nil
    local swingSeq = 0
    local function gearDirectory()
        if gears == nil then
            local ok, result = pcall(function() return require(ReplicatedStorage.Data.Gears) end)
            gears = ok and type(result) == "table" and (result.Directory or result) or false
        end
        return gears or nil
    end
    local function batConfig()
        if config == nil then
            local ok, result = pcall(function()
                return require(ReplicatedStorage.Shared.Modules.BatController.Config)
            end)
            config = ok and type(result) == "table" and result or false
        end
        return config or nil
    end
    local function data(tool)
        local directory = gearDirectory()
        local entry = directory and directory[tool:GetAttribute("GearName")]
        return entry and entry.BatControllerData or nil
    end
    function Bat.Score(tool)
        local stats = data(tool)
        if not stats then return 0 end
        return (tonumber(stats.RangeBonus) or 0) * 1000 + (tonumber(stats.Force) or 0)
    end
    function Bat.Best()
        local best, bestHeld, bestScore = nil, false, -1
        local function scan(container, held)
            if not container then return end
            for _, tool in ipairs(container:GetChildren()) do
                if tool:IsA("Tool") and tool:GetAttribute("IsBat") == true then
                    local score = Bat.Score(tool)
                    if score > bestScore then best, bestHeld, bestScore = tool, held, score end
                end
            end
        end
        scan(LocalPlayer.Character, true)
        scan(LocalPlayer:FindFirstChild("Backpack"), false)
        return best, bestHeld
    end
    function Bat.ServerRange()
        local settings = batConfig()
        if not settings then return 17 end
        local scalar = 1
        if type(settings.GetHitboxScalar) == "function" then
            local ok, value = pcall(settings.GetHitboxScalar)
            if ok and type(value) == "number" and value > 0 then scalar = value end
        end
        local bonus = 0
        local tool = Bat.Best()
        local stats = tool and data(tool)
        if stats and tonumber(stats.RangeBonus) then bonus = tonumber(stats.RangeBonus) end
        return ((tonumber(settings.Range) or 15) + bonus + (tonumber(settings.HitTolerance) or 0)) * scalar
    end
    function Bat.Equip()
        local tool, held = Bat.Best()
        if not tool then return nil end
        if held then return tool, false end
        local character = LocalPlayer.Character
        local humanoid  = character and character:FindFirstChildOfClass("Humanoid")
        if not humanoid then return nil end
        pcall(function() humanoid:EquipTool(tool) end)
        Bat.equippedAt = os.clock()
        local fresh, nowHeld = Bat.Best()
        return nowHeld and fresh or nil, true
    end
    function Bat.Doff()
        local character = LocalPlayer.Character
        local backpack  = LocalPlayer:FindFirstChild("Backpack")
        if not (character and backpack) then return end
        for _, tool in ipairs(character:GetChildren()) do
            if tool:IsA("Tool") and tool:GetAttribute("IsBat") == true then
                pcall(function() tool.Parent = backpack end)
            end
        end
    end
    local function ping()
        local ok, value = pcall(function() return LocalPlayer:GetNetworkPing() end)
        return ok and tonumber(value) or 0.1
    end
    -- the server locks the bat for 0.7 s from the moment a swing reaches it (CooldownEndTime, in server time);
    -- a swing that lands earlier is dropped. Send so it lands just after the lock ends, half a ping ahead.
    function Bat.Ready(tool)
        if not tool then return false end
        local endsAt = tonumber(tool:GetAttribute("CooldownEndTime")) or 0
        return workspace:GetServerTimeNow() + ping() * 0.5 >= endsAt + 0.02
    end
    -- a swing is in flight until the server answers with a new lock (or it was dropped: 2 pings later)
    function Bat.Busy()
        local pending = Bat.pending
        if not pending then return false end
        local endsAt = pending.tool.Parent and tonumber(pending.tool:GetAttribute("CooldownEndTime")) or 0
        if endsAt > pending.endsAt or os.clock() - pending.at > 2 * ping() + 0.15 then
            Bat.pending = nil
            return false
        end
        return true
    end
    -- the swing animation is played by the server, so it shows up a full ping late: play it here right away and
    -- drop the late copy from the server when it arrives
    local localSwing = setmetatable({}, { __mode = "k" })
    local function showSwing(tool)
        local character = LocalPlayer.Character
        local humanoid = character and character:FindFirstChildOfClass("Humanoid")
        local animator = humanoid and humanoid:FindFirstChildOfClass("Animator")
        local anim = tool:FindFirstChild("HitAnim")
        if not (animator and anim and anim:IsA("Animation")) then return end
        local entry = localSwing[animator]
        if not entry then
            entry = { tracks = {}, at = 0 }
            localSwing[animator] = entry
            entry.conn = animator.AnimationPlayed:Connect(function(track)
                if entry.tracks[track] or not track.Animation then return end
                if track.Animation.AnimationId == anim.AnimationId and os.clock() - entry.at < 1 then
                    track:Stop(0)
                end
            end)
        end
        local ok, track = pcall(function() return animator:LoadAnimation(anim) end)
        if not ok then return end
        entry.tracks[track], entry.at = true, os.clock()
        track.Priority = Enum.AnimationPriority.Action
        track:Play(0)
        track.Stopped:Once(function() entry.tracks[track] = nil end)
    end
    function Bat.Swing(victim)
        if Bat.Busy() then return false, "cooldown" end
        local tool, justEquipped = Bat.Equip()
        if not tool then return false, "no Bat in the backpack." end
        if justEquipped then return false, "equipping" end
        if os.clock() - (Bat.equippedAt or 0) < 0.1 + ping() then return false, "equipping" end
        if not Bat.Ready(tool) then return false, "cooldown" end
        local ok, remotes = pcall(function() return require(ReplicatedStorage.Shared.Remotes) end)
        local net = ok and remotes and remotes.BatSwing
        if not net then return false, "the Bat remote is missing." end
        swingSeq = swingSeq + 1
        local tag = string.format("%d:%d:%d", LocalPlayer.UserId, swingSeq,
            math.floor(workspace:GetServerTimeNow() * 1000))
        Bat.pending = { tool = tool, at = os.clock(), endsAt = tonumber(tool:GetAttribute("CooldownEndTime")) or 0 }
        pcall(function() net.Trigger:FireServer(victim, tag) end)
        pcall(showSwing, tool)
        return true
    end
end
local Filter = {
    antiGuard      = true,
    useRate        = false,
    minRate        = 0,
    useWeight      = false,
    minWeight      = 0,
    useRarity      = false,
    selectedRarity = {},
    useArea        = false,
    selectedArea   = {},
    useEggName     = false,
    selectedEgg    = {},
    useMutation    = false,
    selectedMut    = {},
    indexAreas     = {},
}
local Status = {
    stealBusy   = false,
    onTreadmill = false,
    hatching    = false,
    starDueAt   = nil,
}
local Control = {}
local Treadmill = {}
do
    local beltCache, beltLookAt = nil, 0
    function Treadmill.Belt()
        if beltCache and beltCache:IsDescendantOf(workspace) then return beltCache end
        if os.clock() < beltLookAt then return nil end
        beltLookAt = os.clock() + 2
        local ok, plot = pcall(function()
            return require(ReplicatedStorage.Client.PlotState).ResolvePlot()
        end)
        if not ok or not plot or not plot.PlotFolder then return nil end
        local part = plot.PlotFolder:FindFirstChild("TreadmillBottom", true)
        beltCache = part and part:IsA("BasePart") and part or nil
        return beltCache
    end
    local MOUNT_RANGE = 10
    local assignedBelt, beltKnown = nil, false
    local function movingElsewhere()
        return not Status.onTreadmill and Control.OtherMover("treadmill") ~= nil
    end
    pcall(function()
        local remote = require(ReplicatedStorage.Shared.Remotes).Treadmill.AssignedBeltShifted
        local conn = remote.OnClientEvent:Connect(function(belt)
            assignedBelt = belt
            beltKnown    = true
            if belt ~= nil and movingElsewhere() then
                task.spawn(function() Treadmill.Dismount() end)
            end
        end)
        table.insert(_G.LynxSAE.Stoppers, function() conn:Disconnect() end)
    end)
    function Treadmill.IsMounted()
        local character = LocalPlayer.Character
        local root = character and character:FindFirstChild("HumanoidRootPart")
        if not root then return false end
        local belt = Treadmill.Belt()
        local near = true
        if belt then
            local a = Vector3.new(belt.Position.X, 0, belt.Position.Z)
            local b = Vector3.new(root.Position.X, 0, root.Position.Z)
            near = (a - b).Magnitude <= MOUNT_RANGE
        end
        if beltKnown then return assignedBelt ~= nil and near end
        return root.Anchored and belt ~= nil and near
    end
    function Treadmill.Assigned()
        if beltKnown then return assignedBelt ~= nil end
        return Treadmill.IsMounted()
    end
    local function clearEggHold()
        local character = LocalPlayer.Character
        if not character then return end
        for _, tool in ipairs(character:GetChildren()) do
            if tool:IsA("Tool") and tool:GetAttribute("ItemType") == "AssetEgg" then
                pcall(function()
                    require(ReplicatedStorage.Client.EggState).DoffEggTool()
                end)
                task.wait(0.2)
                return
            end
        end
    end
    function Treadmill.Mount()
        clearEggHold()
        local ok, accepted, reason = pcall(function()
            return require(ReplicatedStorage.Shared.Remotes).Treadmill.AskWearStill:InvokeServer()
        end)
        if not ok then return false, tostring(accepted) end
        return accepted == true, reason
    end
    function Treadmill.Dismount()
        local ok = pcall(function()
            require(ReplicatedStorage.Shared.Remotes).Treadmill.AskDoff:InvokeServer()
        end)
        return ok
    end
    function Treadmill.Leave(timeout)
        local character = LocalPlayer.Character
        local root = character and character:FindFirstChild("HumanoidRootPart")
        local wasOn = Status.onTreadmill or Treadmill.Assigned() or (root ~= nil and root.Anchored)
        Status.onTreadmill = false
        if Treadmill.Assigned() then
            local deadline = os.clock() + (timeout or 4)
            repeat
                Treadmill.Dismount()
                task.wait(0.15)
            until not Treadmill.Assigned() or os.clock() >= deadline
        end
        if root and root.Anchored then
            pcall(function() root.Anchored = false end)
        end
        if wasOn and not Treadmill.Assigned() then
            local okPing, ping = pcall(function() return LocalPlayer:GetNetworkPing() end)
            local calm, need = 0, 0.3 + 2 * (okPing and tonumber(ping) or 0.1)
            local frames = 0
            while calm < need or frames < 2 do
                local _, liveRoot = getCharacter()
                if not liveRoot then break end
                liveRoot.AssemblyLinearVelocity = Vector3.zero
                calm = calm + RunService.Heartbeat:Wait()
                frames = frames + 1
            end
        end
        return not Treadmill.Assigned()
    end
end
do
    local owner    = nil
    local preempt  = false
    local firm     = false
    local usingPriority = false
    local FEATURES = {
        { key = "hollowrace", label = "Hollow Race" },
        { key = "star",      label = "Auto Collect Star" },
        { key = "steal",     label = "Auto Steal" },
        { key = "hweggs",    label = "Steal Halloween Eggs" },
        { key = "pumpkinking", label = "Pumpkin King" },
        { key = "train",     label = "Phantom Express" },
        { key = "enchanted", label = "Enchanted Tree" },
        { key = "halloween", label = "Halloween Monsters & Pumpkin Moon" },
        { key = "index",     label = "Auto Steal Full Index" },
        { key = "sell",      label = "Auto Sell Egg" },
        { key = "place",     label = "Auto Place Egg" },
        { key = "mutate",    label = "Auto Mutation Egg" },
        { key = "fishing",   label = "Instant Fishing" },
        { key = "treadmill", label = "Auto Treadmill" },
    }
    local STILL = { sell = true }
    local DEFAULT_PRIORITY = {}
    for index, feature in ipairs(FEATURES) do
        DEFAULT_PRIORITY[feature.key] = #FEATURES + 1 - index
    end
    local priority = {}
    local wants    = {}
    function Control.Features()
        return FEATURES
    end
    function Control.DefaultPriority(name)
        return DEFAULT_PRIORITY[name] or 0
    end
    function Control.SetPriorityEnabled(enabled)
        usingPriority = enabled == true
    end
    function Control.SetPriority(name, value)
        priority[name] = tonumber(value)
    end
    function Control.GetPriority(name)
        return priority[name] or DEFAULT_PRIORITY[name] or 0
    end
    function Control.ResetPriority()
        priority = {}
    end
    function Control.Rank(name)
        if usingPriority then return Control.GetPriority(name) end
        return Control.DefaultPriority(name)
    end
    local busyAt = {}
    function Control.Want(name, seconds)
        wants[name] = os.clock() + (seconds or 1.5)
        if (seconds or 1.5) > 0 then busyAt[name] = os.clock() end
    end
    local idleSince = {}
    local IDLE_CONFIRM = 0.5
    function Control.Idle(name)
        local since = idleSince[name]
        if not since or (busyAt[name] or 0) >= since then idleSince[name] = os.clock() end
    end
    local function confirmedIdle(name, now)
        local since = idleSince[name]
        return since ~= nil and since > (busyAt[name] or 0) and now - since >= IDLE_CONFIRM
    end
    function Control.BusyRecently(name, seconds, ignore)
        local mine, now = Control.Rank(name), os.clock()
        if owner ~= nil then busyAt[owner] = now end
        for other, at in pairs(busyAt) do
            if other ~= name and now - at < seconds and Control.Rank(other) > mine
                and not STILL[other] and not (ignore and ignore[other]) and not confirmedIdle(other, now) then
                return other
            end
        end
        return nil
    end
    function Control.Wanted(name)
        return (wants[name] or 0) > os.clock()
    end
    function Control.Blocker(name, moversOnly)
        local mine, now = Control.Rank(name), os.clock()
        if owner ~= nil and owner ~= name and Control.Rank(owner) > mine
            and not (moversOnly and STILL[owner]) then
            return owner
        end
        for other, untilAt in pairs(wants) do
            if other ~= name and untilAt > now and Control.Rank(other) > mine
                and not (moversOnly and STILL[other]) then
                return other
            end
        end
        return nil
    end
    local gates = {}
    function Control.AddGate(fn)
        gates[#gates + 1] = fn
    end
    function Control.IsStill(name)
        return STILL[name] == true
    end
    local function gatesAllow(name)
        for _, gate in ipairs(gates) do
            local ok, allowed = pcall(gate, name)
            if ok and allowed == false then return false end
        end
        return true
    end
    local groupOf = {}
    function Control.SetGroup(set)
        for name in pairs(set) do groupOf[name] = set end
    end
    local GAP_GRACE = 3
    function Control.Acquire(name, force)
        if owner == name then return true end
        if not force and Control.Blocker(name) then return false end
        if not force and owner == nil and not STILL[name]
            and Control.BusyRecently(name, GAP_GRACE, groupOf[name]) then
            return false
        end
        if owner == nil then
            if not gatesAllow(name) then return false end
            owner, preempt, firm = name, false, false
            return true
        end
        if not firm and Control.Rank(name) > Control.Rank(owner) then preempt = true end
        return false
    end
    function Control.Release(name)
        if owner == name then
            owner, preempt, firm = nil, false, false
        end
    end
    function Control.SetFirm(name)
        if owner == name then firm = true end
    end
    function Control.Hold(name)
        if owner == name then firm, preempt = true, false end
    end
    function Control.Owns(name)
        return owner == name and not preempt
    end
    function Control.Holder()
        return owner
    end
    function Control.OtherMover(name)
        if owner ~= nil and owner ~= name and not STILL[owner] then return owner end
        return nil
    end
    local guards = setmetatable({}, { __mode = "k" })
    function Control.SetGuard(fn)
        guards[coroutine.running()] = fn
    end
    function Control.Active()
        local guard = guards[coroutine.running()]
        return guard ~= nil and guard() == true
    end
end
local Movement = {}
do
    local SWAP_TAG  = "LynxStealHum"
    local MAX_DELTA = 0.2
    local STAND_HEIGHT = 3
    local SPEED_CEILING = 1000
    local kept      = setmetatable({}, { __mode = "k" })
    local jumpConn, lastJump = nil, 0
    local function currentHumanoid()
        local character = LocalPlayer.Character
        return character and character:FindFirstChildOfClass("Humanoid")
    end
    local reboundHumanoids = setmetatable({}, { __mode = "k" })
    local function rebindControls(character, humanoid)
        local ok = pcall(function()
            local scripts  = LocalPlayer:FindFirstChild("PlayerScripts")
            local module   = scripts and scripts:FindFirstChild("PlayerModule")
            local controls = module and module:FindFirstChild("ControlModule")
            if not controls then return end
            local control = require(controls)
            if type(control) ~= "table" or type(control.OnCharacterAdded) ~= "function" then return end
            if control.humanoid ~= humanoid then control:OnCharacterAdded(character) end
            if control.humanoid == humanoid then reboundHumanoids[humanoid] = true end
        end)
        return ok and reboundHumanoids[humanoid] == true
    end
    local function followCamera(from, to)
        local camera = workspace.CurrentCamera
        if camera and camera.CameraSubject == from then camera.CameraSubject = to end
    end
    local function bindJump()
        if jumpConn then return end
        jumpConn = UserInputService.JumpRequest:Connect(function()
            local humanoid = currentHumanoid()
            if not humanoid then return end
            if not humanoid:GetAttribute(SWAP_TAG) then return end
            if reboundHumanoids[humanoid] then return end
            if os.clock() - lastJump < 0.25 then return end
            lastJump = os.clock()
            pcall(function() humanoid:ChangeState(Enum.HumanoidStateType.Jumping) end)
        end)
        pcall(function() Library:AddConnection("SAE_StealJump", jumpConn) end)
    end
    local deathWatched = setmetatable({}, { __mode = "k" })
    local reviving = false
    local function realHumanoid()
        local character = LocalPlayer.Character
        if not character then return nil end
        local humanoid = kept[character] or character:FindFirstChildOfClass("Humanoid")
        return humanoid, character
    end
    function Movement.RealHealth()
        local humanoid = realHumanoid()
        if not humanoid or humanoid.MaxHealth <= 0 then return 1 end
        return humanoid.Health / humanoid.MaxHealth
    end
    local brokenSince, hiddenAt = nil, nil
    local function reviveIfDead()
        if reviving then return end
        local character = LocalPlayer.Character
        if not character then brokenSince = nil return end
        local humanoid = kept[character] or character:FindFirstChildOfClass("Humanoid")
        local current   = character:FindFirstChildOfClass("Humanoid")
        local root      = character:FindFirstChild("HumanoidRootPart")
        local dead   = (humanoid and humanoid.Health <= 0) or (current and current.Health <= 0)
        local broken = character.Parent == nil or root == nil or current == nil
        if root and root.Position.Y < -100000 then hiddenAt = os.clock() end
        if broken then
            brokenSince = brokenSince or os.clock()
            local grace = os.clock() - (hiddenAt or -math.huge) < 10 and 10 or 3
            if os.clock() - brokenSince < grace then return end
        else
            brokenSince = nil
        end
        if not (dead or broken) then return end
        Movement.Respawn()
    end
    function Movement.Respawn()
        if reviving then return false end
        local character = LocalPlayer.Character
        if not character then return false end
        reviving = true
        task.spawn(function()
            Movement.RestoreHumanoid()
            local deadline = os.clock() + 30
            while LocalPlayer.Character == character and os.clock() < deadline do
                pcall(function()
                    require(ReplicatedStorage.Shared.Remotes).RigSync.AskRigWipe:FireServer(character)
                end)
                task.wait(2)
            end
            reviving = false
        end)
        return true
    end
    local function watchDeath(_, original)
        if deathWatched[original] then return end
        deathWatched[original] = true
        original:GetPropertyChangedSignal("Health"):Connect(reviveIfDead)
    end
    do
        local watching = true
        table.insert(_G.LynxSAE.Stoppers, function() watching = false end)
        task.spawn(function()
            while watching do
                task.wait(1)
                pcall(reviveIfDead)
            end
        end)
    end
    local animBound = setmetatable({}, { __mode = "k" })
    function Movement.SwapHumanoid()
        local character = LocalPlayer.Character
        if not character then return nil end
        local humanoid = character:FindFirstChildOfClass("Humanoid")
        if not humanoid then return nil end
        if humanoid:GetAttribute(SWAP_TAG) then
            if not rebindControls(character, humanoid) then bindJump() end
            if not animBound[humanoid] then
                animBound[humanoid] = true
                task.spawn(Movement.RestartAnimate)
            end
            return humanoid
        end
        local root = character:FindFirstChild("HumanoidRootPart")
        local airborne = function() return humanoid.FloorMaterial == Enum.Material.Air end
        local landBy = os.clock() + 1.5
        while airborne() and os.clock() < landBy do RunService.Heartbeat:Wait() end
        if airborne() and root then
            character:PivotTo(CFrame.new(Movement.StandSpot(root.Position)))
            landBy = os.clock() + 0.5
            repeat RunService.Heartbeat:Wait() until not airborne() or os.clock() > landBy
        end
        local okPing, ping = pcall(function() return LocalPlayer:GetNetworkPing() end)
        task.wait(0.15 + (okPing and tonumber(ping) or 0))
        if LocalPlayer.Character ~= character or currentHumanoid() ~= humanoid then
            return currentHumanoid()
        end
        local ok, result = pcall(function()
            local clone = humanoid:Clone()
            clone:SetAttribute(SWAP_TAG, true)
            humanoid.Parent = nil
            clone.Parent    = character
            kept[character] = humanoid
            return clone
        end)
        if not ok then return humanoid end
        followCamera(humanoid, result)
        watchDeath(character, humanoid)
        watchDeath(character, result)
        local speedLink
        speedLink = humanoid:GetPropertyChangedSignal("WalkSpeed"):Connect(function()
            if result.Parent == nil then speedLink:Disconnect() return end
            result.WalkSpeed = humanoid.WalkSpeed
        end)
        result.WalkSpeed = humanoid.WalkSpeed
        if not rebindControls(character, result) then bindJump() end
        animBound[result] = true
        task.spawn(Movement.RestartAnimate)
        return result
    end
    function Movement.RestoreHumanoid()
        local character = LocalPlayer.Character
        local original  = character and kept[character]
        local current   = currentHumanoid()
        if not (original and current and current ~= original) then return false end
        local ok = pcall(function()
            current.Parent  = nil
            original.Parent = character
            followCamera(current, original)
            current:Destroy()
        end)
        if not ok then return false end
        kept[character] = nil
        rebindControls(character, original)
        task.spawn(Movement.RestartAnimate)
        return true
    end
    table.insert(_G.LynxSAE.Stoppers, function() Movement.RestoreHumanoid() end)
    function Movement.RealHumanoidReady()
        Movement.RestoreHumanoid()
        local humanoid = currentHumanoid()
        if humanoid and humanoid:GetAttribute(SWAP_TAG) then
            Movement.Respawn()
            return false
        end
        return true
    end
    local HARDEN_TAG    = "LynxHardHum"
    local HARDEN_JOINTS = "LynxPriorBreakJoints"
    local HARDEN_STATES = {
        { attr = "LynxPriorDead",        state = Enum.HumanoidStateType.Dead },
        { attr = "LynxPriorFallingDown", state = Enum.HumanoidStateType.FallingDown },
        { attr = "LynxPriorRagdoll",     state = Enum.HumanoidStateType.Ragdoll },
        { attr = "LynxPriorPhysics",     state = Enum.HumanoidStateType.Physics },
    }
    function Movement.HardenHumanoid()
        local humanoid = currentHumanoid()
        if not humanoid then return nil end
        pcall(function()
            local fresh = not humanoid:GetAttribute(HARDEN_TAG)
            if fresh then
                humanoid:SetAttribute(HARDEN_JOINTS, humanoid.BreakJointsOnDeath)
            end
            for _, entry in ipairs(HARDEN_STATES) do
                if fresh then
                    humanoid:SetAttribute(entry.attr, humanoid:GetStateEnabled(entry.state))
                end
                humanoid:SetStateEnabled(entry.state, false)
            end
            humanoid.BreakJointsOnDeath = false
            humanoid:SetAttribute(HARDEN_TAG, true)
        end)
        return humanoid
    end
    function Movement.SoftenHumanoid()
        local humanoid = currentHumanoid()
        if not humanoid or not humanoid:GetAttribute(HARDEN_TAG) then return end
        pcall(function()
            for _, entry in ipairs(HARDEN_STATES) do
                local prior = humanoid:GetAttribute(entry.attr)
                if prior ~= nil then humanoid:SetStateEnabled(entry.state, prior) end
                humanoid:SetAttribute(entry.attr, nil)
            end
            local joints = humanoid:GetAttribute(HARDEN_JOINTS)
            if joints ~= nil then humanoid.BreakJointsOnDeath = joints end
            humanoid:SetAttribute(HARDEN_JOINTS, nil)
            humanoid:SetAttribute(HARDEN_TAG, nil)
        end)
    end
    function Movement.RestartAnimate()
        local character = LocalPlayer.Character
        local animate   = character and character:FindFirstChild("Animate")
        if not animate then return false end
        return (pcall(function()
            animate.Disabled = true
            task.wait(0.1)
            animate.Disabled = false
        end))
    end
    local groundParams = RaycastParams.new()
    groundParams.FilterType = Enum.RaycastFilterType.Exclude
    pcall(function() groundParams.RespectCanCollide = true end)
    local function refreshFilter()
        local character = LocalPlayer.Character
        groundParams.FilterDescendantsInstances = character and { character } or {}
    end
    local function groundHeight(position)
        refreshFilter()
        -- guards and other characters are not ground: the Titan Temple guard's collider stands over its eggs
        for _ = 1, 4 do
            local hit = workspace:Raycast(
                position + Vector3.new(0, 40, 0),
                Vector3.new(0, -320, 0),
                groundParams
            )
            if not hit then return nil end
            local model = hit.Instance:FindFirstAncestorOfClass("Model")
            local body = model and (model:FindFirstChildOfClass("Humanoid") and model
                or model.Name == "Guard" and model or model:FindFirstAncestor("Guard"))
            if not body then return hit.Position.Y end
            groundParams:AddToFilter(body)
        end
        return nil
    end
    function Movement.Grounded()
        local character = LocalPlayer.Character
        local root = character and character:FindFirstChild("HumanoidRootPart")
        if not root then return false end
        local floor = groundHeight(root.Position)
        return floor ~= nil and (root.Position.Y - floor) <= STAND_HEIGHT + 2
    end
    function Movement.StandSpot(position, fallback)
        local floor = groundHeight(position)
        if not floor then
            return position + Vector3.new(0, fallback or 4, 0)
        end
        return Vector3.new(position.X, floor + STAND_HEIGHT, position.Z)
    end
    function Movement.To(targetPosition, arriveRange, speed, keepGoing, safePath)
        arriveRange = arriveRange or 6
        speed = math.min(speed or 620, SPEED_CEILING)
        local deadline = os.clock() + 45
        while os.clock() < deadline do
            if keepGoing and not keepGoing() then return false end
            local delta = RunService.Heartbeat:Wait()
            local _, root = waitCharacter(10)
            if not root then return false end
            local origin    = root.Position
            local offset    = targetPosition - origin
            local remaining = offset.Magnitude
            local upward    = root.AssemblyLinearVelocity.Y
            root.AssemblyLinearVelocity = Vector3.new(0, upward > 0 and upward or -3, 0)
            if remaining <= arriveRange then return true end
            local nextSpot = origin + offset.Unit * math.min(speed * math.min(delta, MAX_DELTA), remaining)
            if safePath then
                local travel  = nextSpot - origin
                local blocked = travel.Magnitude > 0.01 and workspace:Blockcast(
                    CFrame.new(origin + Vector3.new(0, 0.4, 0)), Vector3.new(2.8, 4, 2.8), travel, safePath)
                if blocked or not workspace:Raycast(nextSpot, Vector3.new(0, -8, 0), safePath) then
                    return false
                end
            end
            root.CFrame = CFrame.new(nextSpot)
        end
        return false
    end
    local function separationLine()
        local objects = worldFolder()
        local areas   = objects and objects:FindFirstChild("Areas")
        local line    = areas and areas:FindFirstChild("SeparationLine")
        if line and line:IsA("BasePart") then return line end
        return nil
    end
    function Movement.SafeZone()
        local line = separationLine()
        if not line then return nil end
        return line.Position - line.CFrame.LookVector * 30 + Vector3.new(0, 3, 0)
    end
    function Movement.FieldClosed(ahead)
        local wall = Game.ResetWall
        if wall and type(wall.IsSealed) == "function" then
            local ok, sealed = pcall(wall.IsSealed)
            if ok and sealed == true then return true end
        end
        local cycle = Game.EggCycle
        if not (cycle and type(cycle.IsNightPhase) == "function") then return false end
        local now = workspace:GetServerTimeNow()
        local ok, night = pcall(function()
            if cycle.IsNightPhase(now) then return true end
            for t = 1, math.max(ahead or 2, 1) do
                if cycle.IsNightPhase(now + t) then return true end
            end
            return false
        end)
        return ok and night == true
    end
    function Movement.GateWaypoints(from, to)
        local line = separationLine()
        if not line then return {} end
        local look      = line.CFrame.LookVector
        local fromField = (from - line.Position):Dot(look) > 0
        local toField   = (to - line.Position):Dot(look) > 0
        if fromField == toField then return {} end
        local lift  = Vector3.new(0, 3, 0)
        local base  = line.Position - look * 30 + lift
        local field = line.Position + look * 30 + lift
        if fromField then return { field, base } end
        return { base, field }
    end
    Movement.Legit = false
    local function halt(root, humanoid)
        local velocity = root.AssemblyLinearVelocity
        root.AssemblyLinearVelocity = Vector3.new(0, velocity.Y, 0)
        pcall(function() humanoid:MoveTo(root.Position) end)
    end
    function Movement.Walk(target, reach, keepGoing)
        local deadline, reissue = os.clock() + 60, 0
        while (not keepGoing or keepGoing()) and os.clock() < deadline do
            local _, root, humanoid = getCharacter()
            if not (root and humanoid) then return false end
            local offset = target - root.Position
            local gap    = Vector3.new(offset.X, 0, offset.Z).Magnitude
            if gap <= reach then
                halt(root, humanoid)
                return true
            end
            local dt = RunService.Heartbeat:Wait()
            if gap <= humanoid.WalkSpeed * math.min(dt, 0.1) * 2 then
                root.CFrame = CFrame.new(target.X, root.Position.Y, target.Z) * root.CFrame.Rotation
                halt(root, humanoid)
                return true
            end
            if os.clock() >= reissue then
                reissue = os.clock() + 0.5
                humanoid:MoveTo(target)
            end
        end
        return false
    end
    function Movement.ToVia(targetPosition, arriveRange, speed, keepGoing, safePath)
        if Movement.Legit then
            Movement.RestoreHumanoid()
            return Movement.Walk(targetPosition, arriveRange or 6, keepGoing)
        end
        local _, root = waitCharacter(10)
        if not root then return false end
        for _, point in ipairs(Movement.GateWaypoints(root.Position, targetPosition)) do
            if not Movement.To(point, 4, speed, keepGoing, safePath) then return false end
        end
        return Movement.To(targetPosition, arriveRange, speed, keepGoing, safePath)
    end
end
Game.Init()
local MainWindow = Library:Window({
    Title  = "Lynx",
    Footer = "Steal An Egg - Premium",
})
task.wait()
do
    local MainTab = MainWindow:AddTab({ Name = "Main", Icon = "home" })
    do
        local Stats = game:GetService("Stats")
        local _guard = {
            conn = nil, ref = nil,
            trapConn = nil, trapAdded = nil, trapRef = nil,
        }
        local _ping = { enabled = false, gui = nil, thread = nil, probe = nil, ref = nil,
            token = 0, frameConn = nil, dragConn = nil }
        local PROBE_EVERY   = 5
        local PROBE_MIN_FPS = 30
        local FRAME_SLACK   = 2
        local PING_GOOD, PING_WARN = 80, 150
        local function probeRemote()
            local ok, remotes = pcall(require, ReplicatedStorage.Shared.Remotes)
            local banner = ok and type(remotes) == "table" and remotes.SeasonBanner
            local fetch  = type(banner) == "table" and banner.FetchState
            if typeof(fetch) == "Instance" and fetch:IsA("RemoteFunction") then return fetch end
            return nil
        end
        local PING_THEME = {
            Good = Color3.fromRGB(80, 255, 140),
            Warn = Color3.fromRGB(255, 220, 90),
            Bad  = Color3.fromRGB(255, 90, 90),
        }
        local function stopAntiKnockback()
            if _guard.conn then
                pcall(function() _guard.conn:Disconnect() end)
                _guard.conn = nil
            end
        end
        local function stopAntiTrapped()
            for _, key in ipairs({ "trapConn", "trapAdded" }) do
                if _guard[key] then
                    pcall(function() _guard[key]:Disconnect() end)
                    _guard[key] = nil
                end
            end
        end
        local function stopPingPanel()
            _ping.enabled = false
            _ping.token   = _ping.token + 1
            for _, key in ipairs({ "thread", "probe" }) do
                if _ping[key] then
                    pcall(task.cancel, _ping[key])
                    _ping[key] = nil
                end
            end
            for _, key in ipairs({ "frameConn", "dragConn" }) do
                if _ping[key] then
                    pcall(function() _ping[key]:Disconnect() end)
                    _ping[key] = nil
                end
            end
            if _ping.gui then
                pcall(function() _ping.gui:Destroy() end)
                _ping.gui = nil
            end
        end
        table.insert(_G.LynxSAE.Stoppers, stopAntiKnockback)
        table.insert(_G.LynxSAE.Stoppers, stopAntiTrapped)
        table.insert(_G.LynxSAE.Stoppers, stopPingPanel)
        local TRAP_FOLDERS = { "Transient", "__DEBRIS" }
        local function defuseTrap(instance)
            if instance.Name ~= "PlayerTrap" and instance:GetAttribute("TrapActive") == nil then return end
            pcall(function()
                if instance:IsA("BasePart") then instance.CanTouch = false end
                local hitbox = instance:FindFirstChild("Hitbox")
                if hitbox then
                    hitbox.CanTouch   = false
                    hitbox.CanCollide = false
                end
            end)
        end
        local function sweepTraps()
            for _, name in ipairs(TRAP_FOLDERS) do
                local folder = workspace:FindFirstChild(name)
                if folder then
                    for _, child in ipairs(folder:GetChildren()) do defuseTrap(child) end
                end
            end
        end
        local function colorTag(value, good, warn, higherIsBetter)
            local color
            if higherIsBetter then
                color = (value >= good and PING_THEME.Good)
                    or (value >= warn and PING_THEME.Warn) or PING_THEME.Bad
            else
                color = (value <= good and PING_THEME.Good)
                    or (value <= warn and PING_THEME.Warn) or PING_THEME.Bad
            end
            return string.format('<font color="rgb(%d,%d,%d)">',
                math.floor(color.R * 255), math.floor(color.G * 255), math.floor(color.B * 255))
        end
        local function buildPingGui()
            local playerGui = LocalPlayer:WaitForChild("PlayerGui")
            local stale = playerGui:FindFirstChild("LynxPingPanel")
            if stale then pcall(function() stale:Destroy() end) end
            local gui = Instance.new("ScreenGui")
            gui.Name           = "LynxPingPanel"
            gui.ResetOnSpawn   = false
            gui.ZIndexBehavior = Enum.ZIndexBehavior.Global
            gui.DisplayOrder   = 999999
            gui.IgnoreGuiInset = true
            gui.Parent         = playerGui
            local container = Instance.new("Frame")
            container.Size                   = UDim2.new(0, 0, 0, 30)
            container.Position               = UDim2.new(0.5, 0, 0, 14)
            container.AnchorPoint            = Vector2.new(0.5, 0)
            container.AutomaticSize          = Enum.AutomaticSize.X
            container.BackgroundColor3       = Color3.fromRGB(18, 8, 2)
            container.BackgroundTransparency = 0.45
            container.BorderSizePixel        = 0
            container.Active                 = true
            container.Parent                 = gui
            Instance.new("UICorner", container).CornerRadius = UDim.new(1, 0)
            local gradient = Instance.new("UIGradient")
            gradient.Color = ColorSequence.new({
                ColorSequenceKeypoint.new(0,    Color3.fromRGB(8, 4, 1)),
                ColorSequenceKeypoint.new(0.25, Color3.fromRGB(30, 12, 2)),
                ColorSequenceKeypoint.new(0.5,  Color3.fromRGB(70, 28, 4)),
                ColorSequenceKeypoint.new(0.75, Color3.fromRGB(30, 12, 2)),
                ColorSequenceKeypoint.new(1,    Color3.fromRGB(8, 4, 1)),
            })
            gradient.Rotation = 0
            gradient.Parent   = container
            local padding = Instance.new("UIPadding")
            padding.PaddingLeft  = UDim.new(0, 14)
            padding.PaddingRight = UDim.new(0, 14)
            padding.Parent       = container
            local shine = Instance.new("Frame")
            shine.Size                   = UDim2.new(0.7, 0, 0, 1)
            shine.Position               = UDim2.new(0.15, 0, 0, 1)
            shine.BackgroundColor3       = Color3.fromRGB(255, 160, 60)
            shine.BackgroundTransparency = 0.5
            shine.BorderSizePixel        = 0
            shine.Parent                 = container
            Instance.new("UICorner", shine).CornerRadius = UDim.new(1, 0)
            local shineGradient = Instance.new("UIGradient")
            shineGradient.Transparency = NumberSequence.new({
                NumberSequenceKeypoint.new(0,   1),
                NumberSequenceKeypoint.new(0.2, 0.3),
                NumberSequenceKeypoint.new(0.5, 0.2),
                NumberSequenceKeypoint.new(0.8, 0.3),
                NumberSequenceKeypoint.new(1,   1),
            })
            shineGradient.Parent = shine
            local statsLabel = Instance.new("TextLabel")
            statsLabel.Size                   = UDim2.new(0, 0, 1, 0)
            statsLabel.AutomaticSize          = Enum.AutomaticSize.X
            statsLabel.BackgroundTransparency = 1
            statsLabel.Text                   = "-- ms  \u{B7}  CPU --  \u{B7}  -- fps"
            statsLabel.TextColor3             = Color3.fromRGB(210, 150, 80)
            statsLabel.TextSize               = 11
            statsLabel.Font                   = Enum.Font.GothamBold
            statsLabel.TextXAlignment         = Enum.TextXAlignment.Center
            statsLabel.RichText               = true
            statsLabel.Parent                 = container
            local drag = { active = false, input = nil, startPos = nil, startAt = nil, changed = nil }
            container.InputBegan:Connect(function(input)
                if input.UserInputType ~= Enum.UserInputType.MouseButton1
                    and input.UserInputType ~= Enum.UserInputType.Touch then return end
                drag.active   = true
                drag.startPos = input.Position
                drag.startAt  = container.Position
                if drag.changed then drag.changed:Disconnect() end
                drag.changed = input.Changed:Connect(function()
                    if input.UserInputState == Enum.UserInputState.End then
                        drag.active = false
                        if drag.changed then
                            drag.changed:Disconnect()
                            drag.changed = nil
                        end
                    end
                end)
            end)
            container.InputChanged:Connect(function(input)
                if input.UserInputType == Enum.UserInputType.MouseMovement
                    or input.UserInputType == Enum.UserInputType.Touch then
                    drag.input = input
                end
            end)
            local dragConn = UserInputService.InputChanged:Connect(function(input)
                if input ~= drag.input or not drag.active then return end
                local delta = input.Position - drag.startPos
                container.Position = UDim2.new(
                    drag.startAt.X.Scale, drag.startAt.X.Offset + delta.X,
                    drag.startAt.Y.Scale, drag.startAt.Y.Offset + delta.Y
                )
            end)
            return gui, statsLabel, dragConn
        end
        local SupportSection = MainTab:AddSection("Support Features")
        _ping.ref = SupportSection:AddToggle({
            Title    = "Ping Panel",
            Default  = false,
            Callback = function(on)
                stopPingPanel()
                if not on then return end
                _ping.enabled = true
                _ping.token   = _ping.token + 1
                local token   = _ping.token
                local gui, statsLabel, dragConn = buildPingGui()
                _ping.gui      = gui
                _ping.dragConn = dragConn
                local perf     = Stats:FindFirstChild("PerformanceStats")
                local pingItem = perf and perf:FindFirstChild("Ping")
                local cpuItem  = perf and perf:FindFirstChild("CPU")
                local acc = { frames = 0, elapsed = 0, cpuMs = 0, frame = 1 / 60, serverMs = 0,
                    lastText = nil }
                local function networkPing()
                    if pingItem then return pingItem:GetValue() end
                    local ok, value = pcall(function() return LocalPlayer:GetNetworkPing() * 1000 end)
                    return ok and value or 0
                end
                local remote = probeRemote()
                if remote then
                    _ping.probe = task.spawn(function()
                        local pause, probed = 1, false
                        while _ping.enabled and _ping.token == token do
                            task.wait(pause)
                            pause = PROBE_EVERY
                            if acc.frame <= 1 / PROBE_MIN_FPS then
                                local network, frameMs = networkPing(), acc.frame * 1000
                                local sentAt = os.clock()
                                local ok = pcall(function() remote:InvokeServer() end)
                                local took = (os.clock() - sentAt) * 1000
                                if ok then
                                    local server = math.clamp(took - network - FRAME_SLACK * frameMs, 0, 1000)
                                    acc.serverMs = probed and acc.serverMs * 0.6 + server * 0.4 or server
                                    probed = true
                                end
                            end
                        end
                    end)
                end
                _ping.frameConn = RunService.Heartbeat:Connect(function(dt)
                    acc.frames  = acc.frames + 1
                    acc.elapsed = acc.elapsed + dt
                    acc.frame   = acc.frame * 0.9 + math.min(dt, 1) * 0.1
                end)
                _ping.thread = task.spawn(function()
                    while true do
                        task.wait(1)
                        if not _ping.enabled or _ping.token ~= token then break end
                        if not statsLabel.Parent then break end
                        local fps = acc.elapsed > 0 and math.floor(acc.frames / acc.elapsed) or 0
                        acc.frames  = 0
                        acc.elapsed = 0
                        local ping = math.max(math.floor(networkPing() + acc.serverMs + 0.5), 0)
                        local cpu = math.floor(math.clamp(
                            cpuItem and cpuItem:GetValue() or acc.frame * 1000, 0, 999))
                        local sep  = '<font color="rgb(90,40,10)"> \u{B7} </font>'
                        local text = string.format(
                            "%s%d ms</font>%sCPU %s%d ms</font>%s%s%d fps</font>",
                            colorTag(ping, PING_GOOD, PING_WARN, false), ping, sep,
                            colorTag(cpu, 33, 50, false), cpu, sep,
                            colorTag(fps, 50, 30, true), fps
                        )
                        if text ~= acc.lastText then
                            acc.lastText    = text
                            statsLabel.Text = text
                        end
                    end
                end)
            end,
        })
        local antiGuard = { on = false, installed = false, bodyOn = false, original = {}, conns = {},
            states = setmetatable({}, { __mode = "k" }), token = 0, forest = nil, hits = 0, recarries = 0 }
        local KNOCK_STATES = {
            [Enum.HumanoidStateType.Physics]     = true,
            [Enum.HumanoidStateType.FallingDown] = true,
            [Enum.HumanoidStateType.Ragdoll]     = true,
        }
        local function agBody() return antiGuard.on and not Status.stealBusy end
        local function agRagdollParts(character)
            for _, part in ipairs(character:GetDescendants()) do
                if part:IsA("Motor6D") then
                    if not part.Enabled then part.Enabled = true end
                elseif (part:IsA("BallSocketConstraint") or part:IsA("HingeConstraint"))
                    and (part.Name:find("Ragdoll", 1, true) or part:GetAttribute("RagdollConstraint")) then
                    pcall(part.Destroy, part)
                end
            end
        end
        local function agRestore()
            for humanoid, saved in pairs(antiGuard.states) do
                if humanoid.Parent then
                    pcall(function()
                        for state, enabled in pairs(saved) do humanoid:SetStateEnabled(state, enabled) end
                    end)
                end
            end
            antiGuard.states = setmetatable({}, { __mode = "k" })
        end
        local function agRecover(sweep)
            local character = LocalPlayer.Character
            local humanoid = character and character:FindFirstChildOfClass("Humanoid")
            local root = character and character:FindFirstChild("HumanoidRootPart")
            if not (humanoid and root) then return end
            if not antiGuard.states[humanoid] then
                local saved = {}
                for state in pairs(KNOCK_STATES) do saved[state] = humanoid:GetStateEnabled(state) end
                antiGuard.states[humanoid] = saved
            end
            local knocked = KNOCK_STATES[humanoid:GetState()] == true
            pcall(function()
                for state in pairs(KNOCK_STATES) do humanoid:SetStateEnabled(state, false) end
                if knocked then
                    humanoid:ChangeState(Enum.HumanoidStateType.GettingUp)
                    humanoid:ChangeState(Enum.HumanoidStateType.Running)
                end
            end)
            if Control.Holder() == nil then
                if humanoid.PlatformStand then humanoid.PlatformStand, knocked = false, true end
                local v = root.AssemblyLinearVelocity
                if knocked or Vector3.new(v.X, 0, v.Z).Magnitude > math.max(340, humanoid.WalkSpeed * 1.5)
                    or math.abs(v.Y) > 240 then
                    root.AssemblyLinearVelocity = Vector3.zero
                    root.AssemblyAngularVelocity = Vector3.zero
                end
            end
            if sweep or knocked then agRagdollParts(character) end
        end
        local function agHookForest()
            local current = antiGuard.forest
            if current and rawget(current.comp, "_attackHandler") == current.handler then return end
            local okGc, all = pcall(getgc, true)
            if not okGc or type(all) ~= "table" then return end
            for index, value in ipairs(all) do
                if index % 20000 == 0 then RunService.Heartbeat:Wait() end
                if type(value) == "table" and rawget(value, "_areaId") == "Forest"
                    and type(rawget(value, "_attackHandler")) == "function" then
                    local original = rawget(value, "_attackHandler")
                    local handler = function(...)
                        if not antiGuard.on then return original(...) end
                        antiGuard.hits = antiGuard.hits + 1
                    end
                    rawset(value, "_attackHandler", handler)
                    antiGuard.forest = { comp = value, original = original, handler = handler }
                    return
                end
            end
        end
        local function agInstall()
            if antiGuard.installed then return end
            antiGuard.installed = true
            pcall(Game.Init)
            local okModule, Ragdoll = pcall(require, ReplicatedStorage.Shared.Modules.Ragdoll)
            if okModule and type(Ragdoll) == "table" then
                antiGuard.ragdoll = Ragdoll
                for _, name in ipairs({ "ApplyClientRagdoll", "Ragdoll", "TimedRagdoll", "TimedRagdollAsync" }) do
                    local original = Ragdoll[name]
                    if type(original) == "function" then
                        antiGuard.original[name] = original
                        Ragdoll[name] = function(character, ...)
                            if agBody() and character == LocalPlayer.Character then
                                antiGuard.hits = antiGuard.hits + 1
                                task.defer(agRecover, true)
                                return
                            end
                            return original(character, ...)
                        end
                    end
                end
                local isRagdolled = Ragdoll.IsRagdolled
                if type(isRagdolled) == "function" then
                    antiGuard.original.IsRagdolled = isRagdolled
                    Ragdoll.IsRagdolled = function(character, ...)
                        if agBody() and character == LocalPlayer.Character then return false end
                        return isRagdolled(character, ...)
                    end
                end
            end
            task.spawn(function()
                while antiGuard.installed do
                    if antiGuard.on then pcall(agHookForest) end
                    task.wait(30)
                end
            end)
            local function watch(character)
                antiGuard.conns[#antiGuard.conns + 1] = character.DescendantAdded:Connect(function(part)
                    if not agBody() then return end
                    if (part:IsA("BallSocketConstraint") or part:IsA("HingeConstraint"))
                        and (part.Name:find("Ragdoll", 1, true) or part:GetAttribute("RagdollConstraint")) then
                        pcall(part.Destroy, part)
                        task.defer(agRecover, true)
                    elseif part:IsA("Motor6D") and not part.Enabled then
                        part.Enabled = true
                    end
                end)
            end
            if LocalPlayer.Character then watch(LocalPlayer.Character) end
            antiGuard.conns[#antiGuard.conns + 1] = LocalPlayer.CharacterAdded:Connect(watch)
            local nextSweep = 0
            antiGuard.conns[#antiGuard.conns + 1] = RunService.Stepped:Connect(function()
                local body = agBody()
                if body ~= antiGuard.bodyOn then
                    antiGuard.bodyOn = body
                    if not body then agRestore() end
                end
                if not body then return end
                local now = os.clock()
                agRecover(now >= nextSweep)
                if now >= nextSweep then nextSweep = now + 0.25 end
            end)
            local held
            if Game.EggState and Game.EggState.CarryChanged then
                antiGuard.conns[#antiGuard.conns + 1] = Game.EggState.CarryChanged:Connect(function(state)
                    if type(state) ~= "table" then return end
                    if state.IsCarrying and type(state.Uid) == "string" then
                        held, antiGuard.token = state.Uid, antiGuard.token + 1
                        return
                    end
                    local uid = state.Uid or held
                    held = nil
                    if not (antiGuard.on and uid) or Status.stealBusy or Control.Holder() ~= nil then return end
                    antiGuard.token = antiGuard.token + 1
                    local token = antiGuard.token
                    task.spawn(function()
                        local deadline = os.clock() + 5
                        while antiGuard.on and token == antiGuard.token and os.clock() < deadline do
                            local okRead, record = pcall(Game.EggState.ReadFieldEgg, uid)
                            if okRead and type(record) == "table" then
                                if record.State == "Carried" then return end
                                local lying = record.BottomCFrame or record.BoundsCFrame
                                local _, root = getCharacter()
                                if record.State == "Dropped" and root and lying
                                    and (root.Position - lying.Position).Magnitude <= 10
                                    and pcall(Game.EggState.CarryFieldEgg, uid) then
                                    local okNow, now = pcall(Game.EggState.ReadFieldEgg, uid)
                                    if okNow and type(now) == "table" and now.State == "Carried" then
                                        antiGuard.recarries = antiGuard.recarries + 1
                                        return
                                    end
                                end
                            end
                            RunService.Heartbeat:Wait()
                        end
                    end)
                end)
            end
        end
        function antiGuard.setEnabled(on)
            antiGuard.on = on
            if on then
                agInstall()
                task.spawn(function() pcall(agHookForest) end)
            else
                antiGuard.token = antiGuard.token + 1
                agRestore()
            end
        end
        table.insert(_G.LynxSAE.Stoppers, function()
            antiGuard.on, antiGuard.installed = false, false
            antiGuard.token = antiGuard.token + 1
            agRestore()
            for _, conn in ipairs(antiGuard.conns) do pcall(function() conn:Disconnect() end) end
            antiGuard.conns = {}
            local Ragdoll = antiGuard.ragdoll
            if Ragdoll then
                for name, original in pairs(antiGuard.original) do Ragdoll[name] = original end
            end
            local forest = antiGuard.forest
            if forest and rawget(forest.comp, "_attackHandler") == forest.handler then
                rawset(forest.comp, "_attackHandler", forest.original)
            end
        end)
        SupportSection:AddToggle({
            Title    = "Anti Guard",
            Default  = true,
            Callback = function(on)
                Filter.antiGuard = on
                antiGuard.setEnabled(on == true)
            end,
        })
        local hitGuard = { on = false, running = false, conn = nil }
        local SAFE_SPOT = CFrame.new(544.76, 71.5, -416.48)
        local function guardOf(record)
            local areas = worldFolder() and worldFolder():FindFirstChild("Areas")
            local guardAreas = areas and areas:FindFirstChild("GuardAreas")
            local area = guardAreas and record and record.AreaId and guardAreas:FindFirstChild(tostring(record.AreaId))
            return area and area:FindFirstChild("Guard")
        end
        local function lookAlike(character)
            local camera = workspace.CurrentCamera
            local view, cameraType = camera and camera.CFrame, camera and camera.CameraType
            local clone
            pcall(function()
                character.Archivable = true
                clone = character:Clone()
                clone.Name = "LynxAntiHitGhost"
                for _, part in ipairs(clone:GetDescendants()) do
                    if part:IsA("LuaSourceContainer") or part:IsA("Sound") then
                        part:Destroy()
                    elseif part:IsA("BasePart") then
                        part.CanCollide, part.Anchored = false, true
                    end
                end
                clone.Parent = workspace
            end)
            local hidden = {}
            for _, part in ipairs(character:GetDescendants()) do
                if part:IsA("BasePart") and part.Name ~= "HumanoidRootPart" then hidden[#hidden + 1] = part end
            end
            local function hold()
                if camera then
                    camera.CameraType = Enum.CameraType.Scriptable
                    camera.CFrame = view
                end
                for _, part in ipairs(hidden) do
                    if part.Parent then part.LocalTransparencyModifier = 1 end
                end
            end
            local function undo()
                pcall(function()
                    if clone then clone:Destroy() end
                    for _, part in ipairs(hidden) do
                        if part.Parent then part.LocalTransparencyModifier = 0 end
                    end
                    if camera then
                        camera.CameraType = cameraType ~= Enum.CameraType.Scriptable and cameraType or Enum.CameraType.Custom
                        local humanoid = character:FindFirstChildOfClass("Humanoid")
                        if humanoid then camera.CameraSubject = humanoid end
                        camera.CFrame = view
                    end
                end)
            end
            return undo, hold
        end
        local function shieldCarry(uid)
            if hitGuard.running then return end
            local okRead, record = pcall(Game.EggState.ReadFieldEgg, uid)
            if not (okRead and type(record) == "table") or tostring(record.AreaId) == "Forest" then return end
            local character, root = getCharacter()
            if not (character and root) then return end
            hitGuard.running = true
            local guard = guardOf(record)
            local undo, hold = lookAlike(character)
            local started, woke = os.clock(), false
            pcall(function()
                while true do
                    local _, body = getCharacter()
                    if not body then break end
                    body.CFrame = SAFE_SPOT
                    body.AssemblyLinearVelocity = Vector3.zero
                    body.AssemblyAngularVelocity = Vector3.zero
                    hold()
                    local state = guard and guard:GetAttribute("GuardState")
                    local elapsed = os.clock() - started
                    if state == "Waking" or state == "Chasing" then
                        woke = true
                    elseif woke and state == "Sleeping" and elapsed > 0.2 then
                        break
                    end
                    if elapsed >= (woke and 1.6 or 0.9) then break end
                    RunService.Heartbeat:Wait()
                end
            end)
            undo()
            hitGuard.running = false
        end
        Status.antiHitGuard = function() return hitGuard.on and SAFE_SPOT or nil end
        local function setHitGuard(on)
            hitGuard.on = on
            if hitGuard.conn or not on then return end
            pcall(Game.Init)
            if not (Game.EggState and Game.EggState.CarryChanged) then return end
            hitGuard.conn = Game.EggState.CarryChanged:Connect(function(state)
                if not (hitGuard.on and type(state) == "table" and state.IsCarrying and type(state.Uid) == "string") then return end
                if Status.stealEnabled or Status.stealBusy or Control.Holder() ~= nil then return end
                task.spawn(shieldCarry, state.Uid)
            end)
        end
        table.insert(_G.LynxSAE.Stoppers, function()
            hitGuard.on = false
            if hitGuard.conn then pcall(function() hitGuard.conn:Disconnect() end) hitGuard.conn = nil end
        end)
        SupportSection:AddToggle({
            Title    = "Anti Hit Guard",
            Default  = true,
            Callback = function(on) setHitGuard(on == true) end,
        })
        _guard.ref = SupportSection:AddToggle({
            Title    = "Anti Knockback",
            Default  = false,
            Callback = function(on)
                stopAntiKnockback()
                if not on then return end
                if not Game.Init() or not Game.Ragdoll
                    or type(Game.Ragdoll.IsRagdolled) ~= "function"
                    or type(Game.Ragdoll.ClearClientRagdoll) ~= "function" then
                    notify("Anti Knockback", "Game ragdoll module not found.",
                        Color3.fromRGB(255, 90, 90), 3)
                    if _guard.ref then pcall(function() _guard.ref:SetValue(false) end) end
                    return
                end
                _guard.conn = RunService.Heartbeat:Connect(function()
                    local character = LocalPlayer.Character
                    if not character then return end
                    local ok, ragdolled = pcall(Game.Ragdoll.IsRagdolled, character)
                    if not ok or not ragdolled then return end
                    pcall(Game.Ragdoll.ClearClientRagdoll, character)
                    local root = character:FindFirstChild("HumanoidRootPart")
                    if root then
                        local vy = root.AssemblyLinearVelocity.Y
                        root.AssemblyLinearVelocity = Vector3.new(0, math.min(vy, 0), 0)
                        root.AssemblyAngularVelocity = Vector3.zero
                    end
                end)
                pcall(function()
                    Library:AddConnection("SAE_AntiKnockback", _guard.conn)
                end)
            end,
        })
        _guard.trapRef = SupportSection:AddToggle({
            Title    = "Anti Trapped",
            Default  = false,
            Callback = function(on)
                stopAntiTrapped()
                if not on then return end
                sweepTraps()
                _guard.trapAdded = workspace.DescendantAdded:Connect(function(v)
                    if v.Name ~= "PlayerTrap" and v.Name ~= "Hitbox" then return end
                    task.wait(0.1)
                    defuseTrap(v)
                    if v.Parent then defuseTrap(v.Parent) end
                end)
                local nextSweep = 0
                _guard.trapConn = RunService.Heartbeat:Connect(function()
                    if os.clock() >= nextSweep then
                        nextSweep = os.clock() + 1
                        sweepTraps()
                    end
                    local character = LocalPlayer.Character
                    if not character then return end
                    local root     = character:FindFirstChild("HumanoidRootPart")
                    local humanoid = character:FindFirstChildOfClass("Humanoid")
                    if root and root.Anchored and character:GetAttribute("IsTrapped") == true then
                        root.Anchored = false
                    end
                    if humanoid and humanoid.PlatformStand then humanoid.PlatformStand = false end
                    if Game.Ragdoll and type(Game.Ragdoll.IsRagdolled) == "function" then
                        local ok, ragdolled = pcall(Game.Ragdoll.IsRagdolled, character)
                        if ok and ragdolled then
                            pcall(Game.Ragdoll.ClearClientRagdoll, character)
                        end
                    end
                end)
                pcall(function()
                    Library:AddConnection("SAE_AntiTrapped", _guard.trapConn)
                    Library:AddConnection("SAE_AntiTrappedAdded", _guard.trapAdded)
                end)
            end,
        })
    end
    do
        local BAT_AURA_YIELDS = { place = true, enchanted = true, mutate = true, halloween = true, hweggs = true, train = true, fishing = true, hollowrace = true, pumpkinking = true }
        local _bat = {
            enabled = false, conn = nil, ref = nil,
            range = nil, hitAnyone = false,
            nextRangeSync = 0, history = {},
        }
        local VIEW_MIN, VIEW_MAX, VIEW_PAD = 0.14, 0.35, 0.05
        local okGuard, toolGuard = pcall(require, ReplicatedStorage.Client.ToolGameplayGuard)
        if not okGuard then toolGuard = nil end
        local function serverMaxRange()
            return Bat.ServerRange()
        end
        local function findBat()
            return Bat.Best()
        end
        local function effectiveRange()
            return math.min(_bat.range or math.huge, serverMaxRange())
        end
        local function recordSelf(now, position)
            local history = _bat.history
            history[#history + 1] = { at = now, position = position }
            while #history > 2 and history[2].at < now - VIEW_MAX - 0.1 do
                table.remove(history, 1)
            end
        end
        local function selfAt(when)
            local history = _bat.history
            local first, last = history[1], history[#history]
            if not (first and last) or when < first.at or when > last.at then return nil end
            for index = 2, #history do
                local sample = history[index]
                if when <= sample.at then
                    local prior = history[index - 1]
                    local span  = sample.at - prior.at
                    if span <= 0 then return sample.position end
                    return prior.position:Lerp(sample.position, (when - prior.at) / span)
                end
            end
            return nil
        end
        local function hittable(player, character)
            if workspace:GetAttribute("PvPDisabled") == true then return false end
            if LocalPlayer:GetAttribute("InBossArena") or player:GetAttribute("InBossArena") then
                return false
            end
            if Game.Ragdoll then
                local ok, limp = pcall(Game.Ragdoll.IsRagdolled, character)
                if ok and limp then return false end
            end
            if toolGuard and type(toolGuard.IsInsideArena) == "function" then
                local ok, inside = pcall(toolGuard.IsInsideArena, player)
                if ok and inside == false then return false end
            end
            return true
        end
        local function batUsableHere()
            if not toolGuard then return true end
            local okInside, inside = pcall(toolGuard.IsLocalInsideArena)
            if okInside and inside == false then return false end
            local okSafe, safe = pcall(toolGuard.IsInsideSafeZone, LocalPlayer)
            if okSafe and safe == true then return false end
            if workspace:GetAttribute("Event_MonsterEvent") then
                local _, root = getCharacter()
                if root and root.Position.Z > -268 then return false end
            end
            return true
        end
        local function serverAccepts(victimRoot, reach, now)
            local ping = LocalPlayer:GetNetworkPing()
            local past = selfAt(now - math.clamp(VIEW_MIN + ping, VIEW_MIN, VIEW_MAX))
            if not past then return false end
            if (victimRoot.Position - past).Magnitude <= reach then return true end
            local lead = math.clamp(ping + VIEW_PAD, VIEW_PAD, VIEW_MAX)
            return (victimRoot.Position + victimRoot.AssemblyLinearVelocity * lead - past).Magnitude <= reach
        end
        local function carriesEgg(character)
            if not character then return false end
            for _, tool in ipairs(character:GetChildren()) do
                if tool:IsA("Tool") then
                    local itemType = tool:GetAttribute("ItemType")
                    if itemType == "AssetEgg" then return true end
                    if itemType ~= "Gear" and tool:GetAttribute("UID") ~= nil then return true end
                end
            end
            return false
        end
        local function pickVictim(root, now)
            local reach = effectiveRange()
            local best, bestDistance = nil, math.huge
            for _, player in ipairs(Players:GetPlayers()) do
                if player ~= LocalPlayer then
                    local character  = player.Character
                    local victimRoot = character and character:FindFirstChild("HumanoidRootPart")
                    local humanoid   = character and character:FindFirstChildOfClass("Humanoid")
                    local eligible = victimRoot ~= nil and humanoid ~= nil and humanoid.Health > 0
                        and (_bat.hitAnyone or carriesEgg(character))
                        and hittable(player, character)
                        and serverAccepts(victimRoot, reach, now)
                    if eligible then
                        local distance = (victimRoot.Position - root.Position).Magnitude
                        if distance < bestDistance then
                            best, bestDistance = player, distance
                        end
                    end
                end
            end
            return best, bestDistance
        end
        local function ensureEquipped()
            return (Bat.Equip())
        end
        local function swing(victim)
            return (Bat.Swing(victim))
        end
        local function stopBatAura()
            _bat.enabled       = false
            _bat.nextRangeSync = 0
            for _, key in ipairs({ "conn", "carryConn" }) do
                if _bat[key] then
                    pcall(function() _bat[key]:Disconnect() end)
                    _bat[key] = nil
                end
            end
            _bat.carrying = false
            Bat.Doff()
        end
        table.insert(_G.LynxSAE.Stoppers, stopBatAura)
        local BatSection = MainTab:AddSection("Bat Aura")
        BatSection:AddInput({
            Title       = "Bat Aura Range (0 = max)",
            Default     = "0",
            Placeholder = "0 = full bat range",
            Callback    = function(value)
                local range = tonumber((tostring(value):gsub("%s", "")))
                if not range or range < 0 then return end
                _bat.range = range > 0 and math.clamp(range, 1, 1000) or nil
                _bat.nextRangeSync = 0
            end,
        })
        BatSection:AddToggle({
            Title    = "Bat Aura Hit Anyone",
            Default  = false,
            Callback = function(on) _bat.hitAnyone = on end,
        })
        _bat.ref = BatSection:AddToggle({
            Title    = "Bat Aura",
            Default  = false,
            Callback = function(on)
                stopBatAura()
                if not on then return end
                if not findBat() then
                    notify("Bat Aura", "No bat in your inventory.",
                        Color3.fromRGB(255, 90, 90), 3)
                    if _bat.ref then pcall(function() _bat.ref:SetValue(false) end) end
                    return
                end
                _bat.enabled = true
                ensureEquipped()
                _bat.history  = {}
                _bat.carrying = false
                pcall(function()
                    _bat.carryConn = Game.EggState.CarryChanged:Connect(function(state)
                        _bat.carrying = type(state) == "table" and state.IsCarrying == true
                    end)
                end)
                _bat.conn = RunService.Heartbeat:Connect(function()
                    if not _bat.enabled then return end
                    local _, root = getCharacter()
                    if not root then return end
                    local now = workspace:GetServerTimeNow()
                    recordSelf(now, root.Position)
                    if _bat.carrying then return end
                    if BAT_AURA_YIELDS[Control.Holder() or ""] or Status.hatching then return end
                    if not batUsableHere() then return end
                    if os.clock() >= (_bat.nextGrip or 0) then
                        _bat.nextGrip = os.clock() + 0.3
                        local tool, held = Bat.Best()
                        _bat.tool = tool
                        if not held then ensureEquipped() end
                    end
                    if Bat.Busy() or not Bat.Ready(_bat.tool) then return end
                    local victim = pickVictim(root, now)
                    if not victim then return end
                    swing(victim)
                end)
                pcall(function()
                    Library:AddConnection("SAE_BatAura", _bat.conn)
                end)
            end,
        })
    end
    do
        local function gameData(key)
            if not Game[key] then
                local data   = ReplicatedStorage:FindFirstChild("Data")
                local module = data and data:FindFirstChild(key)
                if module then
                    local ok, result = pcall(require, module)
                    if ok and type(result) == "table" and result.Directory then Game[key] = result end
                end
            end
            local directory = Game[key] and Game[key].Directory
            return type(directory) == "table" and directory or nil
        end
        local function buildAreaOptions()
            local directory = gameData("Areas")
            local options = {}
            for areaId, entry in pairs(directory or {}) do
                local label = type(entry) == "table" and entry.DisplayName or areaId
                table.insert(options, { Label = tostring(label), Value = tostring(areaId) })
            end
            table.sort(options, function(a, b) return a.Label < b.Label end)
            if #options == 0 then options = { "Loading..." } end
            return options
        end
        local function buildEggNameOptions()
            local seen, options = {}, {}
            local directory = gameData("Assets")
            if directory then
                for _, data in pairs(directory) do
                    local eggName = data.Egg and data.Egg.DisplayName
                    if eggName and not seen[eggName] then
                        seen[eggName] = true
                        table.insert(options, eggName)
                    end
                end
            end
            table.sort(options)
            if #options == 0 then options = { "Loading..." } end
            return options
        end
        local function buildRarityOptions()
            local seen, ranked = {}, {}
            local directory = gameData("Assets")
            if directory then
                for _, data in pairs(directory) do
                    local rarity = data.Rarity
                    local name   = rarity and rarity.DisplayName
                    if name and not seen[name] then
                        seen[name] = true
                        table.insert(ranked, { name = name, rank = rarity.Rank or 0 })
                    end
                end
            end
            table.sort(ranked, function(a, b)
                if a.rank == b.rank then return a.name < b.name end
                return a.rank < b.rank
            end)
            local options = {}
            for _, entry in ipairs(ranked) do table.insert(options, entry.name) end
            if #options == 0 then options = { "Loading..." } end
            return options
        end
        local function buildMutationOptions()
            local options = { "None" }
            if Game.Mutations and Game.Mutations.All then
                local labels = {}
                for id in pairs(Game.Mutations.All()) do
                    table.insert(labels, tostring(Game.Mutations.LabelOf(id) or id))
                end
                table.sort(labels)
                for _, label in ipairs(labels) do table.insert(options, label) end
            end
            return options
        end
        local FilterSection = MainTab:AddSection("Target Filter")
        FilterSection:AddToggle({
            Title    = "Filter Target $/s",
            Default  = false,
            Callback = function(on) Filter.useRate = on end,
        })
        FilterSection:AddInput({
            Title       = "Target $/s (Minimum)",
            Default     = "0",
            Callback    = function(value)
                local rate = tonumber(value)
                if rate and rate >= 0 then Filter.minRate = rate end
            end,
        })
        FilterSection:AddToggle({
            Title    = "Filter Minimum Weight",
            Default  = false,
            Callback = function(on) Filter.useWeight = on end,
        })
        FilterSection:AddInput({
            Title       = "Minimum Weight (kg)",
            Default     = "0",
            Callback    = function(value)
                local weight = tonumber(value)
                if weight and weight >= 0 then Filter.minWeight = weight end
            end,
        })
        FilterSection:AddToggle({
            Title    = "Filter Rarities",
            Default  = false,
            Callback = function(on) Filter.useRarity = on end,
        })
        local rarityDropdown = FilterSection:AddDropdown({
            Title    = "Rarities",
            Multi    = true,
            Options  = buildRarityOptions(),
            Default  = {},
            Callback = function(selected)
                Filter.selectedRarity = toSet(type(selected) == "table" and selected or {})
            end,
        })
        FilterSection:AddToggle({
            Title    = "Filter Areas",
            Default  = false,
            Callback = function(on) Filter.useArea = on end,
        })
        local areaDropdown  = FilterSection:AddDropdown({
            Title    = "Areas",
            Multi    = true,
            Options  = buildAreaOptions(),
            Default  = {},
            Callback = function(selected)
                Filter.selectedArea = toSet(type(selected) == "table" and selected or {})
            end,
        })
        FilterSection:AddToggle({
            Title    = "Filter Egg Names",
            Default  = false,
            Callback = function(on) Filter.useEggName = on end,
        })
        local eggNameDropdown = FilterSection:AddDropdown({
            Title    = "Egg Names",
            Multi    = true,
            Options  = buildEggNameOptions(),
            Default  = {},
            Callback = function(selected)
                Filter.selectedEgg = toSet(type(selected) == "table" and selected or {})
            end,
        })
        FilterSection:AddToggle({
            Title    = "Steal Filter Mutation",
            Default  = false,
            Callback = function(on) Filter.useMutation = on end,
        })
        local mutationDropdown = FilterSection:AddDropdown({
            Title    = "Steal Mutation",
            Multi    = true,
            Options  = buildMutationOptions(),
            Default  = {},
            Callback = function(selected)
                Filter.selectedMut = toSet(type(selected) == "table" and selected or {})
            end,
        })
        local listWatch = task.spawn(function()
            afterConfigLoad()
            local pending = {
                { dropdown = rarityDropdown, build = buildRarityOptions, key = "selectedRarity" },
                { dropdown = eggNameDropdown, build = buildEggNameOptions, key = "selectedEgg" },
                { dropdown = mutationDropdown, build = buildMutationOptions, key = "selectedMut", min = 2 },
                { dropdown = areaDropdown, build = buildAreaOptions, key = "selectedArea" },
            }
            local deadline = os.clock() + 300
            while #pending > 0 and os.clock() < deadline do
                pcall(Game.Init, 0)
                for i = #pending, 1, -1 do
                    local entry = pending[i]
                    local options = entry.build()
                    if #options >= (entry.min or 1) and options[1] ~= "Loading..." then
                        pcall(function()
                            entry.dropdown:SetOptions(options)
                            local selected = entry.dropdown:GetValue()
                            Filter[entry.key] = toSet(type(selected) == "table" and selected or {})
                        end)
                        table.remove(pending, i)
                    end
                end
                if #pending > 0 then task.wait(2) end
            end
        end)
        table.insert(_G.LynxSAE.Stoppers, function()
            pcall(task.cancel, listWatch)
        end)
    end
    do
        local FLAG_SLOT = 28
        local check = { flag = nil, index = 1, state = nil, conn = nil, looked = 0, character = nil }
        local holdSeenAt = -math.huge
        local function findState()
            for _, f in ipairs(getgc and getgc(false) or {}) do
                if type(f) == "function" and islclosure(f) and (debug.info(f, "s") or ""):find("^ReplicatedFirst%.UGI") then
                    local ok, ups = pcall(debug.getupvalues, f)
                    for _, u in pairs(ok and ups or {}) do
                        if type(u) == "table" and rawget(u, "ThreatLevel") ~= nil and rawget(u, "MovementMode") ~= nil
                            and rawget(u, "Character") == LocalPlayer.Character then
                            return u
                        end
                    end
                end
            end
            return nil
        end
        local function findFlag()
            local ok, conns = pcall(getconnections, RunService.PostSimulation)
            for _, c in ipairs(ok and conns or {}) do
                local f = c.Function
                if f and debug.info(f, "s") == "ReplicatedFirst.UGI.ContentCatalog" then
                    local box = debug.getupvalues(f)[FLAG_SLOT]
                    if type(box) == "table" then
                        if type(rawget(box, 1)) == "boolean" and rawget(box, 2) == 1 and type(rawget(box, 3)) == "table" then
                            return box, 1
                        elseif rawget(box, 1) == 3 and type(rawget(box, 2)) == "table" and type(rawget(box, 3)) == "boolean" then
                            return box, 3
                        end
                    end
                end
            end
            return nil
        end
        function Status.movementTrusted()
            local state = check.state
            if type(state) ~= "table" or check.character ~= LocalPlayer.Character then return nil end
            return state.ThreatLevel == "Trusted" and state.MovementMode == "Grounded"
        end
        local function holdWanted()
            if Status.inHalloween and Status.inHalloween() then return false end
            if Status.hwEntering then return false end
            local crossed = os.clock() - (Status.hwCrossedAt or -math.huge)
            if crossed < 4 and (crossed < 1 or not Status.movementTrusted()) then return false end
            if Status.stealEnabled and not Movement.Legit then return true end
            local holder = Control.Holder()
            if holder == "enchanted" or holder == "star" or holder == "train" then holdSeenAt = os.clock() return true end
            return os.clock() - holdSeenAt < 3
        end
        function Status.movementHeld()
            return check.character == LocalPlayer.Character and check.conn ~= nil and check.conn.Connected and holdWanted()
        end
        function Status.HoldMovementCheck(force)
            if check.character ~= LocalPlayer.Character then
                if check.conn then pcall(function() check.conn:Disconnect() end) end
                check.conn, check.flag, check.state, check.looked = nil, nil, nil, 0
                check.character = LocalPlayer.Character
            end
            if check.conn and check.conn.Connected then return true end
            if not check.flag then
                if not force and os.clock() - check.looked < 5 then return false end
                check.looked = os.clock()
                local okState, state = pcall(findState)
                local okFlag, flag, at = false, nil, nil
                if okState and state then okFlag, flag, at = pcall(findFlag) end
                if not (okFlag and flag) then return false end
                check.flag, check.index, check.state = flag, at, state
            end
            local flag, at = check.flag, check.index
            local conn
            conn = RunService.PreSimulation:Connect(function()
                if holdWanted() then flag[at] = true else conn:Disconnect() end
            end)
            check.conn = conn
            return true
        end
        local watching = true
        task.spawn(function()
            while watching do
                if holdWanted() then pcall(Status.HoldMovementCheck) end
                task.wait(0.25)
            end
        end)
        table.insert(_G.LynxSAE.Stoppers, function()
            watching = false
            if check.conn then pcall(function() check.conn:Disconnect() end) end
        end)
    end
    do
        local C = {
            BAIT_AREA          = "Forest",
            LAND_REACH         = 6,
            LAND_PAD           = 4,
            RAID_WINDOW        = 15,
            GLIDE_SPEED        = 6000,
            GLIDE_FRAME        = 0.1,
            CHICKEN_GAP        = 250,
            CHICKEN_HOLD       = 6,
            CHICKEN_MARGIN     = 10,
            RELOCATE_SETTLE    = 0.4,
            RELOCATE_CALM      = 0.3,
            HOP_STEP           = 500,
            HOP_CLEAR          = 90,
            HOME_GLIDE         = 5000,
            GLIDE_PULLED       = 60,
            GLIDE_SETTLE       = 0.15,
            STAGE_SPOT         = Vector3.new(567, 70.6, -386),
            SAFE_SPOT          = Vector3.new(546, 70.6, -432),
            WALK_PACE          = 90,
            HOME_SPOT          = Vector3.new(515, 73, -363),
            RECOVER_REACH      = 300,
            PACE_LOW           = 1.0,
            LOW_STALL          = 0.4,
        }
        local TAKEN         = "someone else took that egg."
        local CARRIER_FIRST = "a carrier comes first."
        local S = {
            enabled = false, generation = 0, thread = nil, conns = {}, refs = {}, switching = false,
            mode = nil, speedMode = "instant", index = false, wisp = false,
            fromCarriers = false, carriersOnly = false,
            indexDone = false, indexWaiting = nil,
            claims = {},
            carrying = nil, carryHeard = nil, relocated = nil,
            stickTo = nil,
            spawnedAt = 0, fullWarned = false, ungrounded = 0,
            uncover = nil,
            holding = nil, standbyUntil = nil,
            resumeHere = false, resumeFrom = nil, vanishedAt = nil,
        }
        local run = nil
        local function trace(text, ...)
            local sink = rawget(_G, "LynxStealTrace")
            if type(sink) == "function" then pcall(sink, string.format(text, ...)) end
        end
        local frameTime = 1 / 60
        do
            local conn = RunService.Heartbeat:Connect(function(dt)
                frameTime = frameTime * 0.9 + math.min(dt, 1) * 0.1
            end)
            table.insert(_G.LynxSAE.Stoppers, function() conn:Disconnect() end)
        end
        local function frameStep()
            return math.min(RunService.RenderStepped:Wait(), math.max(1 / 30, frameTime * 1.5))
        end
        local function ping()
            local ok, value = pcall(function() return LocalPlayer:GetNetworkPing() end)
            return ok and tonumber(value) or 0
        end
        local function flat(a, b)
            return Vector3.new(a.X - b.X, 0, a.Z - b.Z).Magnitude
        end
        local function myRoot()
            local _, root = getCharacter()
            return root
        end
        local function pin(cf)
            local body, root = getCharacter()
            if not body then return false end
            body:PivotTo(cf)
            root.AssemblyLinearVelocity = Vector3.zero
            return true
        end
        local function waitFor(done, seconds, keepGoing)
            local deadline = os.clock() + seconds
            while os.clock() < deadline and not done() do
                if keepGoing and not keepGoing() then return false end
                task.wait(0.1)
            end
            return done()
        end
        local function newRun()
            local legit = Movement.Legit
            return {
                generation = S.generation,
                legit      = legit,
                normal     = not legit and S.speedMode == "normal",
                filter     = S.mode == "filter",
                steal      = S.mode ~= nil,
                index      = S.index,
                lock       = "steal",
                startedAt  = os.clock(),
            }
        end
        local function active()
            local r = run
            return r ~= nil and S.enabled and r.generation == S.generation
                and LocalPlayer.Character == r.character and Control.Owns(r.lock)
                and (r.delivering or not Movement.FieldClosed()) and getCharacter() ~= nil
        end
        local function inactiveReason(r)
            if not (r and S.enabled and r.generation == S.generation) then return "stopped" end
            if LocalPlayer.Character ~= r.character then return "respawned" end
            if not Control.Owns(r.lock) then return "lock taken by " .. tostring(Control.Holder()) end
            if not r.delivering and Movement.FieldClosed() then return "field closed" end
            if getCharacter() == nil then return "character dead" end
            return "active"
        end
        local function holdingEgg(uid)
            return function() return active() and S.carrying == uid and not (S.ragdoll and os.clock() < S.ragdoll.untilAt) end
        end
        local function onCarryChanged(state)
            if type(state) ~= "table" then return end
            if state.IsCarrying and state.Uid then
                S.carrying = state.Uid
                S.carryHeard = { uid = state.Uid, at = os.clock() }
            elseif state.Uid == nil or state.Uid == S.carrying then
                S.carrying = nil
            end
        end
        local function onRefresh(payload)
            if type(payload) == "string" then
                if not (payload:find("Relocate", 1, true) or payload:find("Ragdoll", 1, true)) then return end
                local ok, decoded = pcall(function() return game:GetService("HttpService"):JSONDecode(payload) end)
                payload = ok and decoded or nil
            end
            if type(payload) ~= "table" then return end
            if payload.Action == "BeginRagdoll" then
                local a = payload.Arguments
                local seconds = type(a) == "table" and tonumber(a[1]) or 2.5
                S.ragdoll = { at = os.clock(), untilAt = os.clock() + seconds }
                return
            elseif payload.Action == "EndRagdoll" then
                if S.ragdoll then S.ragdoll.untilAt = os.clock() end
                return
            end
            if payload.Action ~= "Relocate" then return end
            local a, cf = payload.Arguments, nil
            if type(a) == "table" and #a >= 12 then
                local ok, value = pcall(CFrame.new, table.unpack(a, 1, 12))
                cf = ok and value or nil
            elseif type(a) == "table" and #a >= 3 then
                cf = CFrame.new(a[1], a[2], a[3])
            end
            S.relocated = { at = os.clock(), cf = cf }
        end
        local function onClaimed(payload)
            local claims = S.claims
            claims[#claims + 1] = { at = os.clock(), category = type(payload) == "table" and payload.AssetCategory or nil }
            if #claims > 8 then table.remove(claims, 1) end
        end
        local function claimedSince(record, since)
            for _, claim in ipairs(S.claims) do
                if claim.at >= since and (claim.category == nil or claim.category == record.AssetCategory) then
                    return true
                end
            end
            return false
        end
        local function relocatedSince(since)
            local moved = S.relocated
            return moved ~= nil and moved.at >= since and moved or nil
        end
        local function guardModelOf(areaId)
            local objects    = worldFolder()
            local areas      = objects and objects:FindFirstChild("Areas")
            local guardAreas = areas and areas:FindFirstChild("GuardAreas")
            local areaModel  = guardAreas and guardAreas:FindFirstChild(tostring(areaId))
            return areaModel and areaModel:FindFirstChild("Guard")
        end
        local function guardRootOf(areaId)
            local guard = guardModelOf(areaId)
            return guard and guard:FindFirstChild("HumanoidRootPart")
        end
        local function separationLine()
            local objects = worldFolder()
            local areas   = objects and objects:FindFirstChild("Areas")
            local line    = areas and areas:FindFirstChild("SeparationLine")
            return line and line:IsA("BasePart") and line or nil
        end
        local function borderX()
            local line = separationLine()
            return line and line.Position.X or 552
        end
        local function safeCenter()
            local line = separationLine()
            if not line then return Vector3.new(544.7, 70.6, -364.8) end
            return Movement.StandSpot(line.Position - line.CFrame.LookVector * 7.5)
        end
        local function stealable(state) return state == "Slot" or state == "Dropped" end
        local function eggStill(uid, wantState)
            local ok, live = pcall(Game.EggState.ReadFieldEgg, uid)
            if not (ok and type(live) == "table") then return nil end
            local state = tostring(live.State)
            if state == wantState or (wantState == "Field" and stealable(state)) then return live end
            return nil
        end
        local function knockdownLeft()
            local finish = LocalPlayer:GetAttribute("RagdollEndTime")
            local left = type(finish) == "number" and finish > 0 and finish - workspace:GetServerTimeNow() or 0
            return math.max(left, S.ragdoll and S.ragdoll.untilAt - os.clock() or 0)
        end
        local inventoryCap = nil
        local function inventoryFull()
            if not inventoryCap then
                local ok, eggs = pcall(require, ReplicatedStorage.Shared.Types.Eggs)
                inventoryCap = ok and type(eggs) == "table" and tonumber(eggs.MAX_INVENTORY) or nil
            end
            local save = Game.Save and Game.Save.Get()
            if not (inventoryCap and save and type(save.EggInventory) == "table") then return false end
            local count = 0
            for _ in pairs(save.EggInventory) do count = count + 1 end
            return count >= inventoryCap
        end
        local function portalParts()
            local build = worldFolder() and worldFolder():FindFirstChild("Build")
            local lanes = build and build:FindFirstChild("FuseBiomeLanePortals")
            local zone  = build and build:FindFirstChild("FuseBiomeZone")
            return lanes and lanes:FindFirstChildWhichIsA("BasePart"), zone and zone:FindFirstChild("ExitPart")
        end
        local function stuckInZone()
            local _, exit = portalParts()
            local root = myRoot()
            return exit ~= nil and root ~= nil and (root.Position - exit.Position).Magnitude < 300
        end
        local escapeCache = {}
        local function escapeWalkSpeedFor(areaId)
            local cached = escapeCache[areaId]
            if cached and os.clock() < cached.expires then return cached.value end
            local ok, requirement = pcall(function()
                local guardModel = guardModelOf(areaId)
                local areaModel  = guardModel and guardModel.Parent
                local line       = separationLine()
                local areaData   = Game.Areas.Directory[areaId]
                local guard      = Game.Guards.Directory[areaData and areaData.GuardId]
                local bounds     = areaModel and areaModel:FindFirstChild("Bounds")
                local exitPoint  = areaModel and areaModel:FindFirstChild("ClosestExitPoint")
                if not (guard and line and bounds and exitPoint and guardModel:FindFirstChild("HumanoidRootPart")) then
                    return nil
                end
                local exitDirection = -line.CFrame.LookVector
                return Game.EscapePredict.ResolvePlayerWalkSpeedRequirement({
                    BaseGuardWalkSpeed  = guard.WalkSpeed,
                    ExitDirection       = exitDirection,
                    ExitDistance        = Game.EscapePredict.ResolveExitDistance(
                        bounds.CFrame, bounds.Size, exitPoint.Position, exitDirection
                    ),
                    FlatRadius          = guard.FlatRadius,
                    GuardStartPosition  = guardModel.HumanoidRootPart.Position,
                    HitDistance         = Game.ChasePolicy.ResolveHitDistance(guard.HitDistance),
                    PlayerStartPosition = exitPoint.Position,
                }, 1)
            end)
            local value = ok and type(requirement) == "number" and requirement or false
            escapeCache[areaId] = { value = value, expires = os.clock() + 20 }
            return value
        end
        local function guardSafe(info, r)
            if not Filter.antiGuard or not r.legit then return true end
            local areaId = tostring(info.Record.AreaId)
            local _, _, humanoid = getCharacter()
            local mySpeed  = humanoid and humanoid.WalkSpeed or 0
            local required = escapeWalkSpeedFor(areaId)
            if required then return mySpeed > required * 1.05 end
            local guard = Game.Guards and Game.Guards.Directory and Game.Guards.Directory[areaId]
            return not (guard and guard.WalkSpeed) or mySpeed > guard.WalkSpeed * 4
        end
        local infoCache = {}
        local function describeRecord(record)
            local uid       = record.Uid
            local mutations = type(record.Mutations) == "table" and record.Mutations or {}
            local cached    = uid and infoCache[uid]
            if cached and cached.category == record.AssetCategory and cached.mutations == #mutations then
                cached.info.Record = record
                return cached.info
            end
            local data = Game.Assets and Game.Assets.Directory and Game.Assets.Directory[record.AssetCategory]
            local weight, rate = 0, 0
            pcall(function()
                weight = Game.EggRecords.WeightKg(record) or 0
                rate   = Game.AssetEarnings.RatePerSecond(Game.EggRecords.ToAssetItemData(record)) or 0
            end)
            local labels = {}
            if Game.Mutations then
                for _, id in ipairs(mutations) do
                    labels[#labels + 1] = tostring(Game.Mutations.LabelOf(id) or id)
                end
            end
            local info = {
                Record     = record,
                EggName    = (data and data.Egg and data.Egg.DisplayName) or record.AssetCategory,
                Rarity     = (data and data.Rarity and data.Rarity.DisplayName) or "?",
                RarityRank = tonumber(data and data.Rarity and data.Rarity.Rank) or 0,
                Weight     = weight,
                Rate       = rate,
                MutLabels  = labels,
            }
            if uid then infoCache[uid] = { category = record.AssetCategory, mutations = #mutations, info = info } end
            return info
        end
        local function better(a, b)
            return not b or a.RarityRank > b.RarityRank or (a.RarityRank == b.RarityRank and a.Rate > b.Rate)
        end
        local function allows(on, set, ...)
            if not on or isSetEmpty(set) then return true end
            for _, value in ipairs({ ... }) do
                if set[value] then return true end
            end
            return false
        end
        local function passesFilter(info, r)
            if r.filter then
                local labels = #info.MutLabels > 0 and info.MutLabels or { "None" }
                if (Filter.useRate and info.Rate < Filter.minRate)
                    or (Filter.useWeight and info.Weight < Filter.minWeight)
                    or not allows(Filter.useRarity, Filter.selectedRarity, info.Rarity)
                    or not allows(Filter.useArea, Filter.selectedArea, tostring(info.Record.AreaId))
                    or not allows(Filter.useEggName, Filter.selectedEgg, info.EggName)
                    or not allows(Filter.useMutation, Filter.selectedMut, table.unpack(labels)) then
                    return false
                end
            end
            return guardSafe(info, r)
        end
        local function indexNeeds()
            local save   = Game.Save and Game.Save.Get()
            local index  = save and save.Index
            local areas  = Game.Areas and Game.Areas.Directory
            local assets = Game.Assets and Game.Assets.Directory
            if type(index) ~= "table" or type(areas) ~= "table" or type(assets) ~= "table" then return nil end
            local owned = {}
            for _, entry in pairs(save.EggInventory or {}) do
                if entry.AssetCategory then owned[entry.AssetCategory] = true end
            end
            local wanted, missing = {}, {}
            for areaId, area in pairs(areas) do
                areaId = tostring(areaId)
                if isSetEmpty(Filter.indexAreas) or Filter.indexAreas[areaId] then
                    for _, drop in ipairs(area.DropTable or {}) do
                        local category = drop[1]
                        if (tonumber(drop[2]) or 0) > 0 and assets[category] and index[category] ~= true then
                            missing[areaId] = (missing[areaId] or 0) + 1
                            if not owned[category] then wanted[category] = areaId end
                        end
                    end
                end
            end
            return wanted, missing
        end
        local function pickIndexTarget(candidates, r)
            local wanted, missing = indexNeeds()
            if not wanted then return nil end
            if next(missing) == nil then
                if not S.indexDone then
                    S.indexDone = true
                    notify("Auto Full Index", "Selected areas are complete.", Color3.fromRGB(50, 200, 100), 4)
                end
                return nil
            end
            S.indexDone = false
            local best, bestMissing
            for _, candidate in ipairs(candidates) do
                local areaId = wanted[candidate.Record.AssetCategory]
                if areaId and (not best or missing[areaId] < bestMissing) then
                    local info = describeRecord(candidate.Record)
                    if guardSafe(info, r) then best, bestMissing = info, missing[areaId] end
                end
            end
            if best then
                S.indexWaiting = nil
                return best
            end
            local names = {}
            for category in pairs(wanted) do names[#names + 1] = category end
            table.sort(names)
            local waiting = #names > 0 and table.concat(names, ", ")
                or "nothing new to steal: the missing pets are already in your egg inventory (place & hatch them)"
            if waiting ~= S.indexWaiting then
                S.indexWaiting = waiting
                notify("Auto Full Index", "Waiting for: " .. waiting, Color3.fromRGB(255, 170, 60), 6)
            end
            return nil
        end
        local function pickCarrier(r)
            if not ((S.fromCarriers or S.carriersOnly) and r.steal and not r.legit) then return nil end
            local me = myRoot()
            if not me or me.Position.X > borderX() + 300 then return nil end
            if Status.inHalloween and Status.inHalloween() then return nil end
            local snapshot = fieldEggs()
            if type(snapshot) ~= "table" then return nil end
            local edge, best = borderX(), nil
            for _, record in ipairs(snapshot.Records or snapshot) do
                if tostring(record.State) == "Carried" then
                    local okLive, live = pcall(Game.EggState.ReadFieldEgg, record.Uid)
                    live = okLive and type(live) == "table" and live or record
                    local player = live.CarrierUserId ~= LocalPlayer.UserId and Players:GetPlayerByUserId(live.CarrierUserId or 0)
                    local theirs = player and player.Character and player.Character:FindFirstChild("HumanoidRootPart")
                    if theirs and theirs.Position.X > edge + 8 and player:GetAttribute("InBossArena") ~= true then
                        local info = describeRecord(live)
                        if passesFilter(info, r) and better(info, best) then
                            best = setmetatable({ Carrier = player }, { __index = info })
                        end
                    end
                end
            end
            return best
        end
        local function pickTarget(r)
            if S.carriersOnly then return nil end
            local snapshot = fieldEggs()
            if type(snapshot) ~= "table" then return nil end
            local _, root = waitCharacter(10)
            if not root then return nil end
            local candidates, forest, seen, now = {}, {}, {}, os.clock()
            for _, record in ipairs(snapshot.Records or snapshot) do
                if record.Uid ~= nil then
                    seen[record.Uid] = true
                    local state = tostring(record.State)
                    if state == "Slot" or (state == "Dropped" and not tostring(record.Uid):find("^FirstAreaEgg")) then
                        local list = record.AreaId == C.BAIT_AREA and forest or candidates
                        list[#list + 1] = { Record = record, Distance = (record.BoundsCFrame.Position - root.Position).Magnitude }
                    end
                end
            end
            for uid in pairs(infoCache) do
                if not seen[uid] then infoCache[uid] = nil end
            end
            table.sort(candidates, function(a, b) return a.Distance < b.Distance end)
            local function best(accept)
                local pick
                for _, candidate in ipairs(candidates) do
                    local info = describeRecord(candidate.Record)
                    if accept(info) and better(info, pick) then pick = info end
                end
                return pick
            end
            if S.stickTo and r.steal then
                local stuckRecord
                for _, record in ipairs(snapshot.Records or snapshot) do
                    if record.Uid == S.stickTo then stuckRecord = record break end
                end
                local state = stuckRecord and tostring(stuckRecord.State)
                if state == "Carried" then
                    local okLive, live = pcall(Game.EggState.ReadFieldEgg, S.stickTo)
                    local carrier = okLive and type(live) == "table" and live.CarrierUserId or stuckRecord.CarrierUserId
                    if carrier == LocalPlayer.UserId then state = "ours" end
                end
                if stealable(state) then
                    S.stuckSince = nil
                    local stuck = describeRecord(stuckRecord)
                    if state == "Dropped" or passesFilter(stuck, r) then return stuck, "steal" end
                elseif state and state ~= "Carried" then
                    S.stuckSince = S.stuckSince or now
                    if now - S.stuckSince < 30 then return nil, "steal", true end
                end
                S.stickTo, S.stuckSince = nil, nil
            end
            if S.resumeHere and r.steal then
                S.resumeHere = false
                local pick = best(function(info)
                    return passesFilter(info, r)
                        and (info.Record.BoundsCFrame.Position - root.Position).Magnitude < 800
                end)
                if pick then
                    S.resumeFrom, S.resumeFor = os.clock(), pick.Record.Uid
                    return pick, "steal"
                end
            end
            local questWants = Status.WispSteal and Status.WispSteal()
            local function guardAsleep(info)
                if r.legit or r.normal then return true end
                local guardModel = guardModelOf(info.Record.AreaId)
                local state = guardModel and guardModel:GetAttribute("GuardState")
                return state == nil or state == "" or state == "Sleeping"
            end
            local pick = questWants and best(function(info) return questWants(info.Record) and guardSafe(info, r) end)
                or r.steal and (best(function(info) return passesFilter(info, r) and guardAsleep(info) end)
                    or best(function(info) return passesFilter(info, r) end))
            if pick then return pick, "steal" end
            if r.index then
                if not r.legit then
                    for _, candidate in ipairs(forest) do candidates[#candidates + 1] = candidate end
                end
                local target = pickIndexTarget(candidates, r)
                if target then return target, "index" end
            end
            return nil
        end
        local function glideTo(target, speed, keepGoing)
            keepGoing = keepGoing or active
            local character, root = getCharacter()
            if not root then return false end
            local at = Vector3.new(root.Position.X, target.Y, root.Position.Z)
            local dt = math.min(frameTime, C.GLIDE_FRAME)
            while (target - at).Magnitude > 1 do
                if not keepGoing() then return false end
                at = at + (target - at).Unit * math.min((target - at).Magnitude, (speed or C.GLIDE_SPEED) * math.min(dt, C.GLIDE_FRAME))
                character:PivotTo(CFrame.new(at))
                root.AssemblyLinearVelocity = Vector3.zero
                dt = RunService.Heartbeat:Wait()
            end
            character:PivotTo(CFrame.new(target))
            root.AssemblyLinearVelocity = Vector3.zero
            return true
        end
        local function holdStill(spot, need, seconds, keepGoing, lag)
            keepGoing = keepGoing or active
            local deadline, calm = os.clock() + seconds, 0
            while os.clock() < deadline and keepGoing() do
                local root = myRoot()
                if not root then return false end
                if (root.Position - spot.Position).Magnitude > 20 then calm = 0 end
                if calm >= need + (lag or 2) * ping() then return true end
                pin(spot)
                local dt = RunService.Heartbeat:Wait()
                calm = dt > math.max(0.25, frameTime * 2.5) and 0 or calm + dt
            end
            return false
        end
        local function outboundPace()
            local fps = 1 / math.max(frameTime, 1 / 240)
            return C.PACE_LOW + (1.2 - C.PACE_LOW) * math.clamp((fps - 20) / 10, 0, 1)
        end
        local function lowStep(root, direction, speed, low)
            local position = root.Position
            local ahead = position + direction * math.max(speed * 0.15, 8)
            local floor = math.max(Movement.StandSpot(position, 0).Y, Movement.StandSpot(ahead, 0).Y)
            if os.clock() >= low.checkAt then
                if flat(position, low.from) < speed * C.LOW_STALL * 0.25 then low.hopUntil = os.clock() + 0.5 end
                low.from, low.checkAt = position, os.clock() + C.LOW_STALL
            end
            local cruise = floor + (os.clock() < low.hopUntil and 12 or 0)
            root.CFrame = CFrame.lookAt(position, position + direction)
            root.AssemblyLinearVelocity = Vector3.new(direction.X * speed,
                math.clamp((cruise - position.Y) * 10, -speed, speed), direction.Z * speed)
        end
        local function flyTo(target, keepGoing)
            local character, root = getCharacter()
            if not root then return false end
            local land    = Movement.StandSpot(target)
            local low     = { from = root.Position, checkAt = os.clock() + C.LOW_STALL, hopUntil = 0 }
            local started = os.clock()
            trace("flying out %.0f studs at %.2fx WalkSpeed", (target - root.Position).Magnitude, outboundPace())
            character:PivotTo(CFrame.new(root.Position.X, Movement.StandSpot(root.Position, 0).Y, root.Position.Z))
            while os.clock() - started < 60 do
                local pulled = relocatedSince(started)
                if not keepGoing() or pulled then
                    local stopRoot = myRoot()
                    if stopRoot then stopRoot.AssemblyLinearVelocity = Vector3.zero end
                    if pulled then trace("server pulled the flight back: stopping") end
                    return false
                end
                RunService.Heartbeat:Wait()
                local _, liveRoot, humanoid = getCharacter()
                if not liveRoot then return false end
                local gap = Vector3.new(target.X - liveRoot.Position.X, 0, target.Z - liveRoot.Position.Z)
                if gap.Magnitude <= 3 then
                    pin(CFrame.new(land))
                    holdStill(CFrame.new(land), 2 * frameTime + 2 * ping(), 4, keepGoing)
                    return true
                end
                lowStep(liveRoot, gap.Unit, math.min(humanoid.WalkSpeed * outboundPace(), math.max(gap.Magnitude * 6, 90)), low)
            end
            return false
        end
        local function halloweenPortal()
            local world = worldFolder()
            local model = world and world:FindFirstChild("HalloweenDimensionPortal")
            local hitbox = model and model:FindFirstChild("Hitbox")
            return hitbox and hitbox:IsA("BasePart") and hitbox or nil
        end
        local function walkTo(target, reach, keepGoing)
            local root, hitbox = myRoot(), halloweenPortal()
            if not root then return false end
            if hitbox then
                pcall(function() hitbox.CanTouch = false end)
                local from = Vector3.new(root.Position.X, 0, root.Position.Z)
                local portalAt = Vector3.new(hitbox.Position.X, 0, hitbox.Position.Z)
                local path = Vector3.new(target.X, 0, target.Z) - from
                if path.Magnitude > 1 then
                    local closest = from + path * math.clamp((portalAt - from):Dot(path) / path:Dot(path), 0, 1)
                    if (portalAt - closest).Magnitude < 15 then
                        local away = closest - portalAt
                        if away.Magnitude < 1 then away = Vector3.new(-1, 0, 0) end
                        local via = portalAt + away.Unit * 22
                        if via.X > borderX() - 6 then via = portalAt + Vector3.new(-22, 0, 0) end
                        trace("walking around the Halloween portal")
                        if not Movement.Walk(Vector3.new(via.X, root.Position.Y, via.Z), 4, keepGoing) then return false end
                    end
                end
            end
            return Movement.Walk(target, reach, keepGoing)
        end
        local function travel(target, reach, keepGoing, walkOnly)
            local root = myRoot()
            if not root then return false end
            if root.Position.X < borderX() and target.X >= borderX() then
                local center = safeCenter()
                if not walkTo(Vector3.new(center.X, root.Position.Y, center.Z), 4, keepGoing) then return false end
                root = myRoot()
                if not root then return false end
            end
            if walkOnly or flat(target, root.Position) < 60 then return Movement.Walk(target, reach, keepGoing) end
            return flyTo(target, keepGoing)
        end
        function Status.Travel(target, keepGoing) return travel(target, 4, keepGoing) end
        local function respawnAndWait(keepGoing)
            local body = LocalPlayer.Character
            if not Movement.Respawn() then return end
            local deadline = os.clock() + 15
            while LocalPlayer.Character == body and os.clock() < deadline and keepGoing() do task.wait(0.2) end
        end
        local followers = nil
        local function promptFollowers()
            if followers then return followers end
            local ok, loop = pcall(require, ReplicatedStorage.Client.SmartProximityPrompt.FollowerLoop)
            if not ok or type(loop) ~= "table" or type(debug.getupvalues) ~= "function" then return nil end
            for _, fn in pairs(loop) do
                local okUp, upvalues = pcall(debug.getupvalues, fn)
                for _, value in pairs(type(fn) == "function" and okUp and upvalues or {}) do
                    if type(value) == "table" then
                        for key, entry in pairs(value) do
                            if typeof(key) == "Instance" and key:IsA("ProximityPrompt") and type(entry) == "table" and entry.model then
                                followers = value
                                return followers
                            end
                        end
                    end
                end
            end
            return nil
        end
        local function eggPrompt(uid)
            for prompt, entry in pairs(promptFollowers() or {}) do
                if prompt.Name == "CarryAreaEgg" and prompt.Enabled and prompt.Parent ~= nil and entry.model
                    and entry.model.Parent ~= nil and entry.model.Name == uid then
                    return prompt
                end
            end
            local folder = workspace:FindFirstChild("AreaEggSlotsClient")
            local model  = folder and folder:FindFirstChild(uid)
            if not (model and model:IsA("Model")) then return nil end
            local box, size = model:GetBoundingBox()
            local half = size / 2 + Vector3.new(1.5, 1.5, 1.5)
            for _, part in ipairs(workspace:GetChildren()) do
                local prompt = part.Name == "SmartPromptPart" and part:FindFirstChild("CarryAreaEgg")
                if prompt and prompt.Enabled then
                    local inside = box:PointToObjectSpace(part.Position)
                    if math.abs(inside.X) <= half.X and math.abs(inside.Y) <= half.Y and math.abs(inside.Z) <= half.Z then
                        return prompt
                    end
                end
            end
            return nil
        end
        local function firePrompt(prompt)
            pcall(function()
                prompt.HoldDuration = 0
                if type(fireproximityprompt) == "function" then
                    fireproximityprompt(prompt)
                else
                    prompt:InputHoldBegin()
                    prompt:InputHoldEnd()
                end
            end)
        end
        local function watchEgg(uid, wantState)
            local watch, nextLook, nextCarrier = {}, 0, 0
            function watch.carrierFirst()
                if watch.carrier then return true end
                local r = run
                if not (wantState == "Field" and S.fromCarriers and r and not r.delivering) or uid == S.stickTo
                    or os.clock() < nextCarrier then
                    return false
                end
                nextCarrier = os.clock() + 0.1
                if pickCarrier(r) then
                    trace("a carrier showed up: dropping this trip")
                    watch.carrier = true
                end
                return watch.carrier == true
            end
            function watch.ok()
                if not active() or watch.carrierFirst() then return false end
                if os.clock() >= nextLook then
                    nextLook = os.clock() + 0.2
                    if not eggStill(uid, wantState) then watch.taken = true return false end
                end
                return true
            end
            function watch.why()
                return watch.taken and TAKEN or watch.carrier and CARRIER_FIRST or nil
            end
            return watch
        end
        local function askCarry(uid, seconds)
            local answer
            task.spawn(function() answer = table.pack(pcall(Game.EggState.CarryFieldEgg, uid)) end)
            local deadline = os.clock() + seconds
            while not answer and os.clock() < deadline and S.carrying ~= uid do RunService.Heartbeat:Wait() end
            if S.carrying == uid then return true, true end
            if not answer then return true, false, "no answer from the server" end
            return table.unpack(answer, 1, answer.n)
        end
        local function grab(uid, wantState, window, reach, spot)
            local r = run
            reach = reach or 4
            local live = eggStill(uid, wantState)
            if not live then return false, TAKEN end
            local watch = watchEgg(uid, wantState)
            if not travel(spot or live.BoundsCFrame.Position, spot and 2 or reach, watch.ok, r.legit) then
                return false, watch.why()
            end
            local deadline, distrustSince = os.clock() + (window or 5), nil
            while os.clock() < deadline and active() do
                if S.carrying == uid then return true end
                if S.carrying then
                    pcall(Game.EggState.DropFieldEgg)
                    task.wait(0.2)
                end
                local egg = eggStill(uid, wantState)
                if not egg then return S.carrying == uid, TAKEN end
                local retryIn, knocked = 0.4, knockdownLeft()
                if knocked > 0 then
                    deadline = math.max(deadline, os.clock() + knocked + 1)
                    retryIn = knocked
                else
                    local at, root = egg.BoundsCFrame.Position, myRoot()
                    if root and flat(at, root.Position) > reach + 2 then Movement.Walk(at, reach, watch.ok) end
                    local asked = os.clock()
                    local ok, took, refused = askCarry(uid, 1.5)
                    if ok and took == true then
                        S.carrying = uid
                        if r.normal then
                            local heardBy = os.clock() + 2 * ping() + 2 * frameTime
                            while os.clock() < heardBy and not (S.carryHeard and S.carryHeard.uid == uid
                                and S.carryHeard.at >= asked) do
                                RunService.Heartbeat:Wait()
                            end
                        end
                        return true
                    end
                    local why = tostring(ok and refused or took)
                    trace("carry refused: %s", why)
                    if why:find("trusted") or why:find("gameplay area") or why:find("knocked") then retryIn = 0.1 end
                    if why:find("trusted") then
                        distrustSince = distrustSince or os.clock()
                        deadline = math.max(deadline, math.min(os.clock() + 1, distrustSince + 12))
                    end
                    local prompt = eggPrompt(uid)
                    if prompt then firePrompt(prompt) end
                end
                local settle = os.clock() + retryIn
                while os.clock() < settle and S.carrying ~= uid do task.wait(0.05) end
            end
            return S.carrying == uid
        end
        local function standIn()
            local camera = workspace.CurrentCamera
            local statue
            pcall(function()
                local character  = LocalPlayer.Character
                local archivable = character.Archivable
                character.Archivable = true
                statue = character:Clone()
                character.Archivable = archivable
                for _, item in ipairs(statue:GetDescendants()) do
                    if item:IsA("BasePart") then
                        item.Anchored, item.CanCollide, item.CanTouch, item.CanQuery = true, false, false, false
                        item.LocalTransparencyModifier = 0
                    elseif item:IsA("Decal") then
                        item.LocalTransparencyModifier = 0
                    elseif item:IsA("LuaSourceContainer") then
                        item:Destroy()
                    elseif item:IsA("Humanoid") then
                        item.DisplayDistanceType = Enum.HumanoidDisplayDistanceType.None
                    end
                end
                statue.Name   = "LynxPortalCover"
                statue.Parent = workspace
            end)
            local focus = statue and (statue:FindFirstChildOfClass("Humanoid") or statue:FindFirstChild("HumanoidRootPart"))
            if not focus then
                camera.CameraType = Enum.CameraType.Scriptable
                return statue, nil
            end
            camera.CameraSubject = focus
            return statue, camera:GetPropertyChangedSignal("CameraSubject"):Connect(function()
                if camera.CameraSubject ~= focus then camera.CameraSubject = focus end
            end)
        end
        local function portalCover()
            local remote = Game.Remotes and Game.Remotes.FuseBiome and Game.Remotes.FuseBiome.PortalTransition
            local camera = workspace.CurrentCamera
            if not (remote and camera and type(getconnections) == "function") then return nil end
            local ok, conns = pcall(getconnections, remote.OnClientEvent)
            local muted, finished = {}, {}
            for _, conn in ipairs(ok and conns or {}) do
                if pcall(function() conn:Disable() end) then muted[#muted + 1] = conn end
            end
            local relay = remote.OnClientEvent:Connect(function(fade, id, done)
                trace("portal transition: fade %s id %s done %s", tostring(fade), tostring(id), tostring(done))
                if not id then return end
                if done then finished[id] = true return end
                task.wait(tonumber(fade) or 0)
                if not finished[id] then pcall(function() remote:FireServer(id) end) end
            end)
            local priorType, priorSubject = camera.CameraType, camera.CameraSubject
            local statue, hold = standIn()
            local function restore(now)
                if S.uncover == restore then S.uncover = nil end
                relay:Disconnect()
                for _, conn in ipairs(muted) do pcall(function() conn:Enable() end) end
                task.spawn(function()
                    local deadline = os.clock() + 10
                    while not now and os.clock() < deadline do
                        local root = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
                        if not (root and root.Position.Y > 1000) then break end
                        task.wait(0.1)
                    end
                    if hold then hold:Disconnect() end
                    if statue then statue:Destroy() end
                    if S.uncover then return end
                    local character = LocalPlayer.Character
                    camera.CameraSubject = character and character:FindFirstChildOfClass("Humanoid") or priorSubject
                    camera.CameraType = priorType
                end)
            end
            S.uncover = restore
            return restore
        end
        Status.PortalCover = portalCover
        local function backToBase()
            local root = myRoot()
            if not root then return false end
            local base = safeCenter()
            if flat(root.Position, base) <= 6 then return true end
            if (root.Position.X >= 2200 or stuckInZone()) and not S.carrying then
                respawnAndWait(active)
                return false
            end
            if root.Position.X >= borderX() and not flyTo(base, active) then return false end
            if run.legit then return walkTo(base, 4, active) end
            local hitbox = halloweenPortal()
            if hitbox then pcall(function() hitbox.CanTouch = false end) end
            if not pin(CFrame.new(base)) then return false end
            holdStill(CFrame.new(base), 2 * frameTime + ping(), 3, active, 1)
            return active()
        end
        local function landingSpot(record)
            local egg  = record.BoundsCFrame.Position
            local home = guardRootOf(record.AreaId)
            if not home then return Movement.StandSpot(egg) end
            local radius = 20
            pcall(function()
                local area = Game.Areas.Directory[tostring(record.AreaId)]
                radius = tonumber(Game.Guards.Directory[area.GuardId].FlatRadius) or radius
            end)
            local away = Vector3.new(egg.X - home.Position.X, 0, egg.Z - home.Position.Z)
            local gap  = away.Magnitude
            if gap >= radius + C.LAND_PAD or gap < 0.1 then return Movement.StandSpot(egg) end
            return Movement.StandSpot(egg + away.Unit * math.min(radius + C.LAND_PAD - gap, 5))
        end
        local function pinFor(cf, seconds, stop)
            local started = os.clock()
            repeat
                if not pin(cf) then return false end
                if stop and stop() then return true end
                RunService.Heartbeat:Wait()
            until os.clock() - started >= seconds
            return true
        end
        local CollectionService = game:GetService("CollectionService")
        local function lethalPart(part)
            if CollectionService:HasTag(part, "CollisionPart") then return true end
            local full = part:GetFullName():upper()
            if full:find("KILL", 1, true) then return true end
            return full:find("COLLISIONS", 1, true) ~= nil and not full:find("NO COLLIDE", 1, true)
                and not full:find("COLL GUARD", 1, true)
        end
        local function killPartOnPath(a, b)
            local ignore = { LocalPlayer.Character }
            local params = RaycastParams.new()
            params.FilterType = Enum.RaycastFilterType.Exclude
            local from = a
            for _ = 1, 60 do
                params.FilterDescendantsInstances = ignore
                local hit = workspace:Raycast(from, b - from, params)
                if not hit then return nil end
                if lethalPart(hit.Instance) then return hit.Instance end
                ignore[#ignore + 1] = hit.Instance
                from = hit.Position
            end
            return nil
        end
        local routeCache = {}
        local function routeToTree(from, to)
            local key = string.format("%d,%d,%d", math.floor(from.X), math.floor(from.Y), math.floor(from.Z))
            local cached = routeCache[key]
            if cached ~= nil then return cached or nil end
            local found
            local function tryFrom(side)
                for _, height in ipairs({ to.Y, 250, 1800, 5000 }) do
                    local top = Vector3.new(side.X, height, side.Z)
                    if not killPartOnPath(from, side) and not killPartOnPath(side, top) and not killPartOnPath(top, to) then
                        found = { side, top }
                        return true
                    end
                end
                return false
            end
            if not killPartOnPath(from, to) then
                found = {}
            else
                for _, gap in ipairs({ 0, 20, 40, 80, 160 }) do
                    for step = 0, gap == 0 and 0 or 11 do
                        local angle = math.rad(step * 30)
                        if tryFrom(Vector3.new(from.X + math.cos(angle) * gap, from.Y + 3, from.Z + math.sin(angle) * gap)) then break end
                    end
                    if found then break end
                end
                for along = 50, found and 0 or 1000, 50 do
                    if tryFrom(Vector3.new(from.X + along, from.Y + 3, from.Z))
                        or tryFrom(Vector3.new(from.X - along, from.Y + 3, from.Z)) then
                        break
                    end
                end
            end
            routeCache[key] = found or false
            return found
        end
        local function killStamp() return tostring(LocalPlayer:GetAttribute("LastKillPartPosition")) end
        local function settleAfterHit(why)
            trace("settling after %s", why)
            local started, body, calmSince = os.clock(), LocalPlayer.Character, nil
            while S.enabled and os.clock() - started < 10 do
                local character = getCharacter()
                if character and knockdownLeft() <= 0 and LocalPlayer:GetAttribute("InEnchantedTree") ~= true then
                    calmSince = calmSince or os.clock()
                    if os.clock() - calmSince >= (character ~= body and 2.5 or 1.5) then return end
                else
                    calmSince = nil
                end
                task.wait(0.1)
            end
        end
        local cover = nil
        local function coverHide(body, value)
            for _, item in ipairs(body and body:GetDescendants() or {}) do
                if item:IsA("BasePart") or item:IsA("Decal") then item.LocalTransparencyModifier = value end
            end
        end
        local function coverEnsure()
            if cover then return end
            local character, camera = LocalPlayer.Character, workspace.CurrentCamera
            if not (character and camera) then return end
            local idleId
            pcall(function()
                local idle = character.Animate.idle:FindFirstChildOfClass("Animation")
                idleId = idle and idle.AnimationId
            end)
            local ok, copy = pcall(function()
                local was = character.Archivable
                character.Archivable = true
                local clone = character:Clone()
                character.Archivable = was
                return clone
            end)
            if not (ok and copy) then return end
            for _, item in ipairs(copy:GetDescendants()) do
                if item:IsA("LuaSourceContainer") or item:IsA("Sound") or item:IsA("ForceField") or item:IsA("Tool") then
                    item:Destroy()
                elseif item:IsA("BasePart") then
                    item.Anchored = item.Name == "HumanoidRootPart"
                    item.CanCollide, item.CanTouch, item.CanQuery = false, false, false
                    item.Massless = true
                    item.LocalTransparencyModifier = 0
                elseif item:IsA("Decal") then
                    item.LocalTransparencyModifier = 0
                elseif item:IsA("Humanoid") then
                    item.DisplayDistanceType = Enum.HumanoidDisplayDistanceType.None
                    item.HealthDisplayType = Enum.HumanoidHealthDisplayType.AlwaysOff
                    pcall(function() item.EvaluateStateMachine = false end)
                end
            end
            local onLine = Vector3.new(borderX() - 3, C.SAFE_SPOT.Y, C.SAFE_SPOT.Z)
            local stand = CFrame.lookAt(onLine, onLine + Vector3.new(1, 0, 0))
            pcall(function() copy:PivotTo(stand) end)
            copy.Name = "LynxCover"
            copy.Parent = workspace
            if idleId then
                pcall(function()
                    local humanoid = copy:FindFirstChildOfClass("Humanoid")
                    local animator = humanoid:FindFirstChildOfClass("Animator") or Instance.new("Animator", humanoid)
                    local animation = Instance.new("Animation")
                    animation.AnimationId = idleId
                    local track = animator:LoadAnimation(animation)
                    track.Looped = true
                    track:Play(0)
                end)
            end
            local anchor = copy:FindFirstChild("Head") or copy:FindFirstChild("HumanoidRootPart")
            local bound = "LynxCover" .. tostring(math.random(1000, 9999))
            RunService:BindToRenderStep(bound, Enum.RenderPriority.Camera.Value - 1, function()
                local cam = workspace.CurrentCamera
                if not cam or not anchor then return end
                if cam.CameraSubject ~= anchor then cam.CameraSubject = anchor end
                coverHide(LocalPlayer.Character, 1)
            end)
            cover = { model = copy, bound = bound }
            trace("cover up: camera and the character's copy on the safe zone")
        end
        local function coverTearDown(held)
            pcall(function() RunService:UnbindFromRenderStep(held.bound) end)
            pcall(function() held.model:Destroy() end)
            local body = LocalPlayer.Character
            coverHide(body, 0)
            local humanoid = body and body:FindFirstChildOfClass("Humanoid")
            local camera = workspace.CurrentCamera
            if camera and humanoid then camera.CameraSubject = humanoid end
        end
        local function coverRelease()
            local held = cover
            if not held then return end
            local function finish()
                if cover ~= held then return end
                cover = nil
                coverTearDown(held)
            end
            if getCharacter() ~= nil and Movement.RealHealth() > 0 then
                finish()
                return
            end
            local added
            added = LocalPlayer.CharacterAdded:Connect(function()
                added:Disconnect()
                task.wait(0.5)
                finish()
            end)
            task.delay(15, function()
                if added.Connected then added:Disconnect() end
                finish()
            end)
        end
        S.releaseCover = coverRelease
        table.insert(_G.LynxSAE.Stoppers, function()
            local held = cover
            cover = nil
            if held then coverTearDown(held) end
        end)
        local function paceTo(spot, speed)
            local root = myRoot()
            if not root then return false end
            local from = root.Position
            local line = Vector3.new(spot.X - from.X, Movement.StandSpot(spot, 0).Y - from.Y, spot.Z - from.Z)
            local length = Vector3.new(line.X, 0, line.Z).Magnitude
            if length < 2 then return true end
            local dir = Vector3.new(line.X, 0, line.Z).Unit
            local facing = CFrame.lookAt(from, from + dir).Rotation
            local gone = 0
            while gone < length do
                local dt = frameStep()
                if not active() then return false end
                gone = math.min(gone + speed * dt, length)
                root = myRoot()
                if not root then return false end
                root.CFrame = CFrame.new(from + line * (gone / length)) * facing
                root.AssemblyLinearVelocity = gone < length and dir * speed or Vector3.zero
            end
            return true
        end
        local function tweenTo(spot, speed)
            local root = myRoot()
            if not root then return false end
            local from = root.Position
            local to = Vector3.new(spot.X, Movement.StandSpot(spot, 0).Y, spot.Z)
            local length = flat(from, to)
            if length < 2 then return true end
            local facing = CFrame.lookAt(from, Vector3.new(to.X, from.Y, to.Z)).Rotation
            local tween = game:GetService("TweenService"):Create(root,
                TweenInfo.new(length / speed, Enum.EasingStyle.Linear), { CFrame = CFrame.new(to) * facing })
            local finished = false
            tween.Completed:Once(function() finished = true end)
            tween:Play()
            local deadline = os.clock() + length / speed + 1
            while not finished and os.clock() < deadline do
                if not active() then tween:Cancel() return false end
                local body = myRoot()
                if not body then tween:Cancel() return false end
                body.AssemblyLinearVelocity = Vector3.zero
                RunService.Heartbeat:Wait()
            end
            if not finished then tween:Cancel() end
            return finished
        end
        local function walkPace()
            local _, _, walker = getCharacter()
            return math.max(walker and walker.WalkSpeed or 16, 16)
        end
        local function treeSkip(target, watch)
            local holdBy = os.clock() + 3
            while not Status.movementHeld() and os.clock() < holdBy and watch.ok() do
                pcall(Status.HoldMovementCheck, true)
                if Status.movementHeld() then break end
                task.wait(0.25)
            end
            if not Status.movementHeld() then
                trace("tree skip: the movement hold is not on yet: not flipping")
                return false
            end
            local _, _, humanoid = getCharacter()
            if humanoid then pcall(function() humanoid:UnequipTools() end) end
            local spot = CFrame.new(target)
            local home = CFrame.new(C.SAFE_SPOT)
            if S.inStep ~= LocalPlayer.Character then
                local pace = walkPace()
                trace("tree skip: a walk to the stage and back first (getting in step with the server)")
                local root = myRoot()
                if root and flat(root.Position, C.SAFE_SPOT) > 6 then paceTo(C.SAFE_SPOT, pace) end
                paceTo(C.STAGE_SPOT, pace)
                paceTo(C.SAFE_SPOT, pace)
                S.inStep = LocalPlayer.Character
            end
            local graceLeft = 10.5 - (os.clock() - (S.spawnedAt or -math.huge))
            if graceLeft > 0 then
                trace("tree skip: %.1f s of spawn grace left: waiting at home", graceLeft)
                pinFor(home, graceLeft, function() return not watch.ok() end)
                if not watch.ok() then return false end
            end
            local arrivedAt = os.clock()
            local quietSince, deadline = os.clock(), os.clock() + 3
            while os.clock() < deadline and watch.ok() do
                pinFor(home, 0.05)
                if relocatedSince(quietSince) then quietSince = os.clock() end
                if os.clock() - quietSince >= 0.25 + ping() and os.clock() - arrivedAt >= 0.5 + 2 * ping() then break end
            end
            if os.clock() - quietSince < 0.25 + ping() then
                trace("tree skip: the server keeps correcting us at home")
                return false
            end
            local since = os.clock()
            local killSeen = killStamp()
            local function killed() return killStamp() ~= killSeen end
            local function hold(cf, seconds, stop)
                pinFor(cf, seconds, function() return killed() or (stop ~= nil and stop()) end)
                return not killed()
            end
            local function hitKillPart()
                trace("tree skip: a kill part went off (%s): letting go", tostring(LocalPlayer:GetAttribute("LastKillPartPosition")))
                settleAfterHit("a kill part")
                return false
            end
            hold(spot, 0.6 + ping(), function() return relocatedSince(since) ~= nil or not watch.ok() end)
            if killed() then return hitKillPart() end
            if not watch.ok() then return false end
            if not relocatedSince(since) then
                hold(spot, 0.25, function() return relocatedSince(since) ~= nil or not watch.ok() end)
                if killed() then return hitKillPart() end
                if not relocatedSince(since) then
                    trace("tree skip: no pull back")
                    S.keepStep = true
                    return false
                end
            end
            local pull = relocatedSince(since)
            local pulledAt = pull.at
            if pull.cf then
                local at = pull.cf.Position
                local out = spot.Position - C.SAFE_SPOT
                local along = math.clamp((at - C.SAFE_SPOT):Dot(out) / out:Dot(out), 0, 1)
                local offLine = flat(at, C.SAFE_SPOT + out * along)
                local cutShort = along > 0 and offLine < 40
                if cutShort and flat(at, C.SAFE_SPOT) > 120 then
                    trace("tree skip: the first jump was cut short at %.0f: going on from there", at.X)
                end
                local grounded = math.abs(at.Y - Movement.StandSpot(at, 0).Y) <= 0.6
                local fromHome = flat(at, C.SAFE_SPOT)
                local legit = fromHome <= 15 or (cutShort and fromHome > 200)
                if not grounded or not legit then
                    trace("tree skip: that pull was not the one (%s): going along with it", tostring(at))
                    pinFor(CFrame.new(Movement.StandSpot(at, 0)), 0.3)
                    return false
                end
            end
            if not hold(spot, 0.08) then return hitKillPart() end
            local interior = CFrame.new(Movement.StandSpot(Vector3.new(5846, 17010, 15699), 0))
            local route = routeToTree(spot.Position, interior.Position)
            if route == nil then
                trace("tree skip: no way up to the interior clear of the kill parts: the straight line")
                route = {}
            elseif #route > 0 then
                trace("tree skip: the straight line goes through a kill part: up by way of %s", tostring(route[1]))
            end
            local dwell = 0.08 + ping()
            for _, point in ipairs(route) do
                if not hold(CFrame.new(point), dwell) then return hitKillPart() end
            end
            local function agreed()
                local moved = S.relocated
                return moved ~= nil and moved.at > pulledAt and moved.cf ~= nil and (moved.cf.Position - target).Magnitude < 40
            end
            if not hold(interior, 0.12) then return hitKillPart() end
            local waitUntil = os.clock() + 1.2
            while not agreed() and watch.ok() and os.clock() < waitUntil and not killed() do
                if not pin(interior) then break end
                RunService.Heartbeat:Wait()
            end
            if killed() then return hitKillPart() end
            local function onTheWay()
                local moved = S.relocated
                if not (route[1] and moved and moved.at > pulledAt and moved.cf) then return nil end
                local at, out = moved.cf.Position, route[1] - target
                local along = (at - target):Dot(out) / out:Dot(out)
                if along < 0 or along > 1 or flat(at, target + out * along) > 10 then return nil end
                return at
            end
            local short = not agreed() and onTheWay()
            if agreed() then
                hold(S.relocated.cf, 0.05)
            elseif short then
                trace("tree skip: the server put us %.0f studs short on the way up: walking back to the egg", flat(short, target))
                if not hold(CFrame.new(short), 0.05) then return hitKillPart() end
                return paceTo(target, walkPace())
            else
                for index = #route, 1, -1 do
                    if not hold(CFrame.new(route[index]), dwell) then return hitKillPart() end
                end
            end
            hold(spot, 1.2, function() return agreed() or not watch.ok() end)
            if killed() then return hitKillPart() end
            local moved = S.relocated
            trace("tree skip: the server %s the egg spot (last pull %s, %.0f studs off)", agreed() and "took" or "did not take",
                moved and moved.cf and tostring(moved.cf.Position) or "none",
                moved and moved.cf and (moved.cf.Position - target).Magnitude or -1)
            return agreed()
        end
        local function guardRoots()
            local roots = {}
            local objects    = worldFolder()
            local areas      = objects and objects:FindFirstChild("Areas")
            local guardAreas = areas and areas:FindFirstChild("GuardAreas")
            for _, area in ipairs(guardAreas and guardAreas:GetChildren() or {}) do
                local guard = area:FindFirstChild("Guard")
                local part = guard and guard:FindFirstChild("HumanoidRootPart")
                if part then roots[#roots + 1] = part.Position end
            end
            return roots
        end
        local function clearance(spot, roots)
            local nearest = math.huge
            for _, position in ipairs(roots) do nearest = math.min(nearest, flat(spot, position)) end
            return nearest
        end
        local function glideAlong(stage, speed, keepGoing)
            local root = myRoot()
            if not root then return false end
            local since, from = os.clock(), root.Position
            local line = stage - from
            local length = Vector3.new(line.X, 0, line.Z).Magnitude
            if length < 1 then return keepGoing() end
            local facing = CFrame.lookAt(from, from + Vector3.new(line.X, 0, line.Z)).Rotation
            local gone, killSeen = 0, killStamp()
            while gone < length do
                local dt = frameStep()
                if not keepGoing() then return false end
                if killStamp() ~= killSeen then
                    trace("glide: a kill part went off: stopping")
                    return false
                end
                local moved = relocatedSince(since)
                local at = from + line * (gone / length)
                if moved and moved.cf and flat(moved.cf.Position, at) > C.GLIDE_PULLED then return false, moved end
                gone = math.min(gone + speed * dt, length)
                root = myRoot()
                if not root then return false end
                root.CFrame = CFrame.new(from + line * (gone / length)) * facing
                root.AssemblyLinearVelocity = Vector3.zero
            end
            return keepGoing()
        end
        local function hopAlong(stage, keepGoing)
            local root = myRoot()
            if not root then return false end
            local at = root.Position
            while flat(stage, at) > C.HOP_STEP + 20 do
                if not keepGoing() then return false end
                local roots = guardRoots()
                local best, bestGap
                for _, step in ipairs({ C.HOP_STEP, C.HOP_STEP - 60, C.HOP_STEP - 120, C.HOP_STEP - 180 }) do
                    local x = at.X + (stage.X - at.X) / flat(stage, at) * step
                    local z = at.Z + (stage.Z - at.Z) / flat(stage, at) * step
                    local spot = Vector3.new(x, at.Y, z)
                    local gap = clearance(spot, roots)
                    if not bestGap or gap > bestGap then best, bestGap = spot, gap end
                    if gap >= C.HOP_CLEAR then break end
                end
                at = Movement.StandSpot(best, 0)
                pinFor(CFrame.new(at), 0.15)
            end
            return keepGoing()
        end
        local function glideHome(stage, keepGoing)
            return glideAlong(stage, C.HOME_GLIDE, keepGoing)
        end
        local function hopBack()
            local root = myRoot()
            if root and root.Position.X - borderX() > 30 and not S.carrying and active() then
                trace("gliding back home from %.0f", root.Position.X)
                local glided, pull = glideHome(C.SAFE_SPOT, active)
                if not glided and active() then
                    if pull and pull.cf then pinFor(CFrame.new(Movement.StandSpot(pull.cf.Position, 0)), 0.1) end
                    hopAlong(C.SAFE_SPOT, active)
                end
                pinFor(CFrame.new(C.SAFE_SPOT), 0.2)
            end
            local hitbox = halloweenPortal()
            if hitbox then pcall(function() hitbox.CanTouch = false end) end
            root = myRoot()
            if root and flat(root.Position, C.SAFE_SPOT) > 6 and active() then paceTo(C.SAFE_SPOT, walkPace()) end
            if not pinFor(CFrame.new(C.SAFE_SPOT), 0.1) then return false end
            return active()
        end
        local function hopHome(uid)
            local stage = C.STAGE_SPOT
            local holding = function() return S.carrying == uid and active() end
            local started = os.clock()
            local area = { left = LocalPlayer:GetAttribute("AreaId") ~= C.BAIT_AREA }
            area.conn = LocalPlayer:GetAttributeChangedSignal("AreaId"):Connect(function()
                if LocalPlayer:GetAttribute("AreaId") == C.BAIT_AREA then
                    if area.left then area.back = true end
                else
                    area.left, area.back = true, nil
                end
            end)
            task.delay(15, function() area.conn:Disconnect() end)
            local root = myRoot()
            if root and clearance(root.Position, guardRoots()) >= C.HOP_CLEAR then
                local since = os.clock()
                pinFor(CFrame.new(root.Position), C.GLIDE_SETTLE + ping(), function() return relocatedSince(since) ~= nil end)
                local late = relocatedSince(since)
                if late and late.cf then pinFor(CFrame.new(Movement.StandSpot(late.cf.Position, 0)), 0.1) end
            end
            local function farPull(since)
                local moved = relocatedSince(since)
                return moved and moved.cf and flat(moved.cf.Position, stage) > C.GLIDE_PULLED and moved or nil
            end
            for round = 1, 2 do
                local glided, pull
                for try = 1, 3 do
                    glided, pull = glideHome(stage, holding)
                    if glided or not holding() then break end
                    trace("glide home pulled back to %s (try %d)", pull and pull.cf and tostring(pull.cf.Position) or "?", try)
                    if pull and pull.cf then pinFor(CFrame.new(Movement.StandSpot(pull.cf.Position, 0)), C.GLIDE_SETTLE + ping()) end
                end
                if glided then
                    trace("glided home in %.2f s at %.0f studs/s", os.clock() - started, C.HOME_GLIDE)
                else
                    if not holding() then area.conn:Disconnect() return false end
                    trace("glide home kept being pulled back: hopping the rest")
                    if not hopAlong(stage, holding) then area.conn:Disconnect() return false end
                end
                local arrived = os.clock()
                local deadline = arrived + 2.5
                repeat
                    pinFor(CFrame.new(stage), 0.05, function() return farPull(arrived) ~= nil end)
                    local here = LocalPlayer:GetAttribute("AreaId") == C.BAIT_AREA
                    local settled = here and (area.back or (not area.left and os.clock() - arrived > 0.6))
                until settled or farPull(arrived) or os.clock() > deadline
                local quietSince = os.clock()
                deadline = os.clock() + 1.5
                while not farPull(arrived) and os.clock() - quietSince < 0.2 + ping() and os.clock() < deadline do
                    pinFor(CFrame.new(stage), 0.05, function() return farPull(arrived) ~= nil end)
                    if relocatedSince(quietSince) then quietSince = os.clock() end
                end
                local late = farPull(arrived)
                if not (late and holding()) then break end
                trace("pulled back to %s after the glide: gliding home again", tostring(late.cf.Position))
                area.left, area.back = true, nil
                pinFor(CFrame.new(Movement.StandSpot(late.cf.Position, 0)), C.GLIDE_SETTLE + ping())
            end
            area.conn:Disconnect()
            trace("hopped home with the egg (server area %s)", tostring(LocalPlayer:GetAttribute("AreaId")))
            return S.carrying == uid and LocalPlayer:GetAttribute("AreaId") == C.BAIT_AREA
        end
        local function awaitClaim(record)
            local since = run.startedAt
            local deadline, nextLook = os.clock() + 6, os.clock() + 0.5
            while not claimedSince(record, since) and os.clock() < deadline and active() do
                if os.clock() >= nextLook then
                    nextLook = os.clock() + 0.3
                    if eggStill(record.Uid, "Dropped") then break end
                    if S.carrying ~= record.Uid and eggStill(record.Uid, "Slot") then break end
                end
                task.wait(0.1)
            end
            return claimedSince(record, since)
        end
        local function walkClaim(record)
            local uid = record.Uid
            task.spawn(pcall, Game.EggState.DropFieldEgg)
            local lying
            waitFor(function() lying = eggStill(uid, "Dropped") return lying ~= nil end, 2)
            if not lying then return false, "the egg did not land at the chicken." end
            trace("dropped at the chicken")
            if flat(lying.BoundsCFrame.Position, C.SAFE_SPOT) > 120 then
                return false, "the egg landed too far out (the server still had us further back)."
            end
            pinFor(CFrame.new(C.SAFE_SPOT), 0.1)
            local deadline = os.clock() + 5
            while active() and S.carrying ~= uid and os.clock() < deadline do
                local live = eggStill(uid, "Dropped")
                if not live then break end
                tweenTo(live.BoundsCFrame.Position, C.WALK_PACE)
                task.spawn(pcall, Game.EggState.CarryFieldEgg, uid)
                waitFor(function() return S.carrying == uid end, 0.3)
            end
            if S.carrying ~= uid then return false, "could not take the egg again at the chicken." end
            trace("took the dropped egg again")
            tweenTo(C.SAFE_SPOT, C.WALK_PACE)
            if awaitClaim(record) then return true end
            return false, "the egg never made it home."
        end
        local function raidEgg(record)
            local uid = record.Uid
            if S.resumeFrom and os.clock() - S.resumeFrom < 5 and S.resumeFor == uid then
                S.resumeFrom = nil
                trace("taking a near egg from out here instead of a respawn")
                return grab(uid, "Field", C.RAID_WINDOW, C.LAND_REACH, landingSpot(record))
            end
            local target = landingSpot(record)
            local watch  = watchEgg(uid, "Field")
            run.treeSkip = nil
            if not hopBack() then return false, "could not get back to the safe zone first." end
            if watch.carrierFirst() then return false, CARRIER_FIRST end
            if target.X - borderX() <= 1000 then
                trace("near egg: going straight there")
                return grab(uid, "Field", C.RAID_WINDOW, C.LAND_REACH, target)
            end
            local egg = record.BoundsCFrame.Position
            local guard = guardRootOf(record.AreaId)
            local away = guard and Vector3.new(egg.X - guard.Position.X, 0, egg.Z - guard.Position.Z)
            away = (away and away.Magnitude > 0.5) and away.Unit or Vector3.new(0, 0, 1)
            local nest = Movement.StandSpot(egg + away * 6)
            local guardModel = guardModelOf(record.AreaId)
            trace("%s: tree skip onto the egg (guard %s, %.1f studs from the egg)", tostring(record.AreaId),
                tostring(guardModel and guardModel:GetAttribute("GuardState")), guard and flat(guard.Position, egg) or -1)
            if treeSkip(nest, watch) then
                run.treeSkip = true
                if S.carrying ~= uid then grab(uid, "Field", 2.5, C.LAND_REACH) end
                if S.carrying == uid then return true end
            end
            run.treeSkip = nil
            hopBack()
            if watch.why() then return false, watch.why() end
            return false, "the server did not take the jump to the egg: trying again."
        end
        local function treadmillPulse()
            local belt = Treadmill.Belt()
            if not belt then return end
            local spot = belt.Position + Vector3.new(0, 3, 0)
            if not glideTo(spot, C.GLIDE_SPEED) then return end
            holdStill(CFrame.new(spot), 0.1, 1, nil, 0.5)
            local deadline, ungrounded = os.clock() + 1, false
            while os.clock() < deadline and active() do
                local mounted, why = Treadmill.Mount()
                if mounted then
                    Treadmill.Dismount()
                    trace("treadmill pulse")
                    ungrounded = false
                    S.ungrounded = 0
                    break
                end
                trace("treadmill refused: %s", tostring(why))
                ungrounded = tostring(why):lower():find("not grounded") ~= nil
                if not pin(CFrame.new(spot)) then break end
                task.wait(0.1)
            end
            if ungrounded then S.ungrounded = S.ungrounded + 1 end
            Status.onTreadmill = false
            local root = myRoot()
            if root and root.Anchored then pcall(function() root.Anchored = false end) end
        end
        local function recoverDropped(uid, droppedAt)
            local r = run
            local lying = eggStill(uid, "Dropped")
            local settle = os.clock() + 2 * ping() + 0.5
            while not lying and os.clock() < settle and eggStill(uid, "Carried") do
                RunService.Heartbeat:Wait()
                lying = eggStill(uid, "Dropped")
            end
            if not lying then return S.carrying == uid end
            if droppedAt then
                local deadline = os.clock() + 2 * ping() + 0.3
                while lying and os.clock() < deadline and (lying.BoundsCFrame.Position - droppedAt).Magnitude > C.RECOVER_REACH do
                    RunService.Heartbeat:Wait()
                    lying = eggStill(uid, "Dropped")
                end
                if not lying then return S.carrying == uid end
                if (lying.BoundsCFrame.Position - droppedAt).Magnitude > C.RECOVER_REACH then
                    trace("the server still had us out there: back to the egg")
                    pin(CFrame.new(Movement.StandSpot(lying.BoundsCFrame.Position)))
                end
            end
            local tries = 0
            while active() do
                lying = eggStill(uid, "Dropped")
                if not lying then break end
                local spot = Movement.StandSpot(lying.BoundsCFrame.Position)
                if knockdownLeft() > 0 then
                    trace("knocked down: waiting %.1f s beside the egg to take it again", knockdownLeft())
                    while knockdownLeft() > 0 and active() and eggStill(uid, "Dropped") do
                        if not pin(CFrame.new(spot)) then break end
                        RunService.Heartbeat:Wait()
                    end
                else
                    if not r.legit then glideTo(spot, C.GLIDE_SPEED) end
                    if S.carrying == uid or grab(uid, "Dropped") then
                        trace("took the dropped egg again")
                        return true
                    end
                    tries = tries + 1
                    local nearHome = lying.BoundsCFrame.Position.X <= borderX() + C.RECOVER_REACH
                    if nearHome and not r.normal and tries % 2 == 1 and eggStill(uid, "Dropped") then treadmillPulse() end
                end
            end
            return S.carrying == uid
        end
        local function chickenStage()
            local guard  = guardModelOf(C.BAIT_AREA)
            local bounds = guard and guard.Parent and guard.Parent:FindFirstChild("Bounds")
            if not (bounds and bounds:IsA("BasePart")) then
                local chicken = guardRootOf(C.BAIT_AREA)
                return chicken and Movement.StandSpot(chicken.Position + Vector3.new(3.4, 0, -8)) or Vector3.new(600, 71.3, -325)
            end
            local spanZ = math.max(bounds.Size.Z / 2 - C.CHICKEN_MARGIN, 0)
            local others = {}
            for _, player in ipairs(Players:GetPlayers()) do
                local theirs = player ~= LocalPlayer and player.Character and player.Character:FindFirstChild("HumanoidRootPart")
                if theirs then others[#others + 1] = theirs.Position end
            end
            local best, bestGap = nil, -1
            for _ = 1, #others > 0 and 8 or 1 do
                local spot = Vector3.new(borderX() + C.CHICKEN_MARGIN + math.random() * 20, bounds.Position.Y,
                    bounds.Position.Z + (math.random() * 2 - 1) * spanZ)
                local gap = math.huge
                for _, at in ipairs(others) do gap = math.min(gap, flat(at, spot)) end
                if gap > bestGap then best, bestGap = spot, gap end
            end
            return Movement.StandSpot(best)
        end
        local function dropAndRegrab(uid, stage)
            if LocalPlayer:GetAttribute("AreaId") ~= C.BAIT_AREA then
                local deadline = os.clock() + C.CHICKEN_HOLD
                while LocalPlayer:GetAttribute("AreaId") ~= C.BAIT_AREA and os.clock() < deadline and active() do
                    pin(CFrame.new(stage))
                    RunService.Heartbeat:Wait()
                end
                trace("server placed us in %s before the drop", tostring(LocalPlayer:GetAttribute("AreaId")))
            end
            pcall(Game.EggState.DropFieldEgg)
            trace("dropped at the chicken")
            local deadline = os.clock() + 3
            while os.clock() < deadline and S.carrying == uid do
                if not active() then return false end
                task.wait(0.05)
            end
            if S.carrying == uid then return true end
            if eggStill(uid, "Slot") then
                trace("carry did not count: the egg went back to its nest")
                return false
            end
            if not run.normal and glideTo(C.HOME_SPOT, C.GLIDE_SPEED) then
                holdStill(CFrame.new(C.HOME_SPOT), 0.1, 1, nil, 1)
            end
            deadline = os.clock() + 8
            while os.clock() < deadline and eggStill(uid, "Carried") do
                if not active() then return false end
                task.wait(0.05)
            end
            return recoverDropped(uid, stage)
        end
        local function viaChicken(uid)
            local r = run
            while active() do
                if S.carrying ~= uid then
                    trace("carry lost before the drop")
                    if not recoverDropped(uid) then return false end
                end
                local stage, root = chickenStage(), myRoot()
                if not root then return false end
                if (root.Position - stage).Magnitude < C.CHICKEN_GAP then return true end
                local calm = S.relocated
                if calm and os.clock() - calm.at < C.RELOCATE_CALM then
                    holdStill(CFrame.new(root.Position), C.RELOCATE_CALM - (os.clock() - calm.at), 2, nil, 1)
                end
                local glided, glideStart = false, os.clock()
                for attempt = 1, 3 do
                    local started = os.clock()
                    glideStart = started
                    if glideTo(stage, C.GLIDE_SPEED, function()
                        return active() and S.carrying == uid and not relocatedSince(started) and knockdownLeft() <= 0
                    end) then
                        glided = true
                        break
                    end
                    if S.carrying ~= uid then break end
                    local moved = relocatedSince(started)
                    if not (active() and moved) then return false end
                    trace("server pulled us back mid-glide (try %d): flying again", attempt)
                    r.pulledBack = true
                    holdStill(moved.cf or CFrame.new(root.Position), C.RELOCATE_SETTLE * (attempt - 1),
                        C.RELOCATE_SETTLE * attempt + 2, nil, 1)
                    if S.carrying ~= uid then break end
                end
                if not glided then
                    if S.carrying == uid then return false end
                else
                    local lag = r.normal and 2 or 1
                    local settle = math.max(0.3, 0.6 - lag * ping())
                    if not holdStill(CFrame.new(stage), settle, C.CHICKEN_HOLD, nil, lag) and not active() then
                        return false
                    end
                    local late = relocatedSince(glideStart)
                    if late and late.cf and (late.cf.Position - stage).Magnitude > 50 and S.carrying == uid then
                        trace("server pulled us back after the glide: flying again")
                        holdStill(late.cf, C.RELOCATE_SETTLE, C.RELOCATE_SETTLE + 2, nil, 1)
                    elseif S.carrying == uid and not dropAndRegrab(uid, stage) then
                        return false
                    end
                end
            end
            return S.carrying == uid
        end
        local function robCarrier(info)
            local uid, victim = info.Record.Uid, info.Carrier
            if not Bat.Best() then return false, "no Bat in your inventory." end
            Bat.Equip()
            local history, closeSince = {}, nil
            local deadline = os.clock() + 20
            local noclip = RunService.Stepped:Connect(function()
                for _, part in ipairs(LocalPlayer.Character and LocalPlayer.Character:GetDescendants() or {}) do
                    if part:IsA("BasePart") then part.CanCollide = false end
                end
            end)
            local function finish(...)
                noclip:Disconnect()
                return ...
            end
            trace("waiting in the Forest for %s (%s)", victim.Name, tostring(info.EggName))
            while os.clock() < deadline and active() do
                if eggStill(uid, "Dropped") or S.carrying == uid then break end
                local live = eggStill(uid, "Carried")
                if not live then return finish(false, "the egg was banked or reset before we got to it.") end
                victim = Players:GetPlayerByUserId(live.CarrierUserId or 0) or victim
                local theirs = victim.Character and victim.Character:FindFirstChild("HumanoidRootPart")
                local body, root = getCharacter()
                if not (theirs and body) then return finish(false, "lost sight of the carrier.") end
                local edge = borderX() + 8
                if theirs.Position.X <= edge then return finish(false, victim.Name .. " got the egg home first.") end
                local lag = math.clamp(0.14 + ping(), 0.14, 0.35)
                local now = workspace:GetServerTimeNow()
                local seen = S.carrierSeen
                local velocity = Vector3.zero
                if seen and seen.player == victim and now - seen.at > 0.02 and now - seen.at < 0.5 then
                    velocity = (theirs.Position - seen.position) * Vector3.new(1, 0, 1) / (now - seen.at)
                end
                S.carrierSeen = { player = victim, position = theirs.Position, at = now }
                local spot
                if theirs.Position.X - edge > 150 then
                    spot = Vector3.new(edge + 12, root.Position.Y, math.clamp(theirs.Position.Z, -430, -299))
                    closeSince = nil
                else
                    local ahead = theirs.Position + velocity * lag
                    local side = root.Position.Z >= ahead.Z and 3 or -3
                    spot = Vector3.new(math.max(ahead.X, edge), ahead.Y, ahead.Z + side)
                    closeSince = closeSince or os.clock()
                end
                local stand = Movement.StandSpot(spot)
                body:PivotTo(CFrame.lookAt(stand, Vector3.new(theirs.Position.X, stand.Y, theirs.Position.Z)))
                root.AssemblyLinearVelocity = Vector3.zero
                now = workspace:GetServerTimeNow()
                history[#history + 1] = { at = now, position = stand }
                while #history > 2 and history[2].at < now - 0.5 do table.remove(history, 1) end
                if closeSince and os.clock() - closeSince >= lag + 0.05 then
                    local past
                    for index = #history, 1, -1 do
                        if history[index].at <= now - lag then past = history[index].position break end
                    end
                    local reach = Bat.ServerRange()
                    if past and ((theirs.Position - past).Magnitude <= reach
                        or (theirs.Position + velocity * lag - past).Magnitude <= reach) then
                        Bat.Swing(victim)
                    end
                end
                RunService.Heartbeat:Wait()
            end
            finish()
            local lying = eggStill(uid, "Dropped")
            if S.carrying ~= uid and not lying then return false, "never got close enough to " .. victim.Name .. "." end
            if lying and lying.BoundsCFrame.Position.X > borderX() + 200 then
                return false, victim.Name .. " dropped it out in the field (their guard): left to the guard."
            end
            trace("knocked the egg out of %s's hands", victim.Name)
            Bat.Doff()
            if S.carrying ~= uid and not recoverDropped(uid) then return false, "someone else took the dropped egg." end
            run.delivering = true
            Control.SetFirm(run.lock)
            local root = myRoot()
            if root and root.Position.X > borderX() + C.CHICKEN_GAP and not viaChicken(uid) then
                return false, "lost the egg on the way back."
            end
            glideTo(C.HOME_SPOT, C.GLIDE_SPEED, holdingEgg(uid))
            if awaitClaim(info.Record) then return true end
            return false, "the egg never made it home."
        end
        local function shieldClaim(record, spot)
            local uid, r = record.Uid, run
            local root = myRoot()
            if not root then return false end
            local nest, lostAt = root.CFrame, nil
            local deadline = os.clock() + 1 + 4 * ping()
            while active() and os.clock() < deadline and not claimedSince(record, r.startedAt) do
                if S.carrying ~= uid then
                    lostAt = lostAt or os.clock()
                    if os.clock() - lostAt > 2 * ping() + 2 * frameTime then break end
                end
                local body = myRoot()
                if not body then break end
                body.CFrame = spot
                body.AssemblyLinearVelocity = Vector3.zero
                body.AssemblyAngularVelocity = Vector3.zero
                RunService.Heartbeat:Wait()
            end
            if claimedSince(record, r.startedAt) then
                trace("anti hit guard: claimed on the safe zone spot")
                return true
            end
            local body = myRoot()
            if body then body.CFrame = nest end
            trace("anti hit guard: not claimed (carrying %s), going the usual way", tostring(S.carrying == uid))
            return false
        end
        local function prepareHumanoid(r)
            if r.legit then
                if not Movement.RealHumanoidReady() then return false end
                Movement.SoftenHumanoid()
            elseif Status.HoldMovementCheck() then
                if not Movement.RealHumanoidReady() then return false end
                Movement.HardenHumanoid()
            else
                pcall(Status.HoldMovementCheck)
                Movement.SwapHumanoid()
                Movement.HardenHumanoid()
            end
            return true
        end
        local function takeEgg(info, r, forestHome)
            local record = info.Record
            if r.normal and not forestHome then
                local resume = S.vanishedAt and os.clock() - S.vanishedAt < 10
                S.vanishedAt = nil
                if not resume and not backToBase() then return false, "could not get back to the safe zone first." end
                S.resumeFrom = nil
                return grab(record.Uid, "Field", nil, C.LAND_REACH, landingSpot(record))
            elseif r.legit or r.normal or forestHome then
                return grab(record.Uid, "Field")
            end
            return raidEgg(record)
        end
        local function deliver(info, r, forestHome)
            local record = info.Record
            local uid = record.Uid
            local holding = holdingEgg(uid)
            if r.legit then
                local root = myRoot()
                if not root then return false, "the character is gone." end
                Movement.Walk(Vector3.new(borderX() - 25, root.Position.Y, math.clamp(root.Position.Z, -430, -299)), 3, holding)
                if awaitClaim(record) then return true end
                return false, "the egg never made it home."
            end
            if forestHome then
                glideTo(C.HOME_SPOT, C.GLIDE_SPEED, holding)
                if awaitClaim(record) then return true end
                return false, "the egg never made it home."
            end
            if r.treeSkip then
                if not hopHome(uid) then return false, "lost the egg on the hops home." end
                return walkClaim(record)
            end
            local shieldSpot = Status.antiHitGuard and Status.antiHitGuard()
            if shieldSpot and (record.BoundsCFrame.Position - shieldSpot.Position).Magnitude <= 750
                and shieldClaim(record, shieldSpot) then
                return true
            end
            if S.carrying == uid then
                if not hopHome(uid) then return false, "lost the egg on the way home." end
                return walkClaim(record)
            end
            if not viaChicken(uid) then
                if r.pulledBack then return false, "pulled back on the way: trying that egg again." end
                return false, "lost the egg on the way back."
            end
            while active() do
                glideTo(C.HOME_SPOT, C.GLIDE_SPEED, holding)
                if awaitClaim(record) then return true end
                local okLive, live = pcall(Game.EggState.ReadFieldEgg, uid)
                local root = myRoot()
                trace("not claimed at home: egg %s, carrying %s, at %s", tostring(okLive and live and live.State),
                    tostring(S.carrying == uid), root and tostring(root.Position) or "?")
                if not (eggStill(uid, "Dropped") and recoverDropped(uid)) then break end
            end
            return false, "the egg never made it home."
        end
        local function stealOne(info)
            local r = run
            if not active() then return false, "stopped." end
            local instant = not r.legit and not r.normal
            if instant and not Status.movementHeld() then
                trace("waiting for the movement hold (the game's movement check)")
                waitFor(Status.movementHeld, 6, active)
                if not active() then return false, "stopped." end
            end
            if not prepareHumanoid(r) then return false, "resetting the character (cloned Humanoid left by an older run)." end
            if instant then coverEnsure() else coverRelease() end
            if not waitFor(function() return knockdownLeft() <= 0 end, math.huge, active) then return false, "stopped." end
            if info.Carrier then return robCarrier(info) end
            local forestHome = info.Record.AreaId == C.BAIT_AREA and not r.legit
            local took, why = takeEgg(info, r, forestHome)
            if not took then
                return false, why or ("could not take " .. tostring(info.EggName) .. ".")
            end
            trace("carrying %s (%s)", tostring(info.EggName), tostring(info.Record.AreaId))
            r.delivering = true
            Control.SetFirm(r.lock)
            return deliver(info, r, forestHome)
        end
        local function holdOn(lock, seconds)
            S.holding = lock
            Control.Want(lock, seconds or 2)
        end
        local function letGo()
            S.holding = nil
            for _, lock in ipairs({ "steal", "index" }) do
                Control.Want(lock, 0)
                if run == nil then Control.Release(lock) end
                Control.Idle(lock)
            end
        end
        local function idle(seconds)
            letGo()
            task.wait(seconds)
        end
        local function respawnFirst(why)
            trace(why)
            holdOn(S.holding or "steal", 16)
            respawnAndWait(function() return S.enabled end)
        end
        local function waitForOpening()
            local cycle = Game.EggCycle
            if Movement.Legit or not (cycle and type(cycle.IsNightPhase) == "function") then return false end
            local now = workspace:GetServerTimeNow()
            local opensIn
            for ahead = 0, 30, 0.25 do
                local ok, night = pcall(cycle.IsNightPhase, now + ahead)
                if ok and not night then opensIn = ahead break end
            end
            if not (opensIn and opensIn <= 8) then return false end
            local rival = Status.hwBestEggRank and Status.hwBestEggRank()
            if rival and rival > (Status.stealBestRank() or 0) then
                S.standbyUntil = nil
                return false
            end
            S.standbyUntil = os.clock() + opensIn + 1
            holdOn("steal", 3)
            if Control.Acquire("steal") and not (Status.inHalloween and Status.inHalloween()) then
                Treadmill.Leave()
                local root = myRoot()
                if root and root.Position.X < borderX() and flat(root.Position, C.SAFE_SPOT) > 6 then pin(CFrame.new(C.SAFE_SPOT)) end
            end
            task.wait(0.05)
            return true
        end
        local function parkAtStart()
            if Status.inHalloween and Status.inHalloween() then return end
            local holder = Control.Holder()
            if holder ~= nil and holder ~= "steal" then return end
            local root = myRoot()
            if not root then return end
            local spot = C.SAFE_SPOT
            if flat(root.Position, spot) <= 6 then return end
            holdOn("steal", 3)
            if not Control.Acquire("steal") then return end
            Treadmill.Leave()
            if Movement.Legit then
                Movement.Walk(spot, 3, function() return S.enabled and Movement.FieldClosed() end)
            elseif flat(root.Position, spot) > 400 then
                if root.Position.X >= borderX() then flyTo(spot, function() return S.enabled end) end
                pin(CFrame.new(spot))
            else
                pin(CFrame.new(spot))
            end
            trace("egg reset: waiting at the start spot")
        end
        local function readyToSteal()
            local full = inventoryFull()
            if full and not S.fullWarned then
                notify(Movement.Legit and "Legit Steal Egg" or "Auto Steal",
                    "Egg inventory is full. Stealing pauses until there is room (place, sell or hatch eggs).",
                    Color3.fromRGB(255, 170, 60), 5)
            end
            S.fullWarned = full
            if S.ungrounded >= 3 then
                S.ungrounded = 0
                respawnFirst("treadmill keeps saying Not grounded: respawning")
                return false
            end
            if full then
                idle(1)
                return false
            end
            if Movement.FieldClosed() then
                if not waitForOpening() then
                    parkAtStart()
                    idle(1)
                end
                return false
            end
            if os.clock() - S.spawnedAt < 1 then
                if S.holding then holdOn(S.holding) end
                task.wait(0.3)
                return false
            end
            return true
        end
        function Status.stealBestRank()
            if not (S.enabled and S.mode) or S.carriersOnly or inventoryFull() then return nil end
            local cycle = Game.EggCycle
            if not (cycle and type(cycle.IsNightPhase) == "function") then return nil end
            local ok, night = pcall(cycle.IsNightPhase, workspace:GetServerTimeNow())
            if not ok or night then return nil end
            local snapshot = fieldEggs()
            if type(snapshot) ~= "table" then return nil end
            local r, best = newRun(), nil
            for _, record in ipairs(snapshot.Records or snapshot) do
                if record.Uid ~= nil and record.AreaId ~= C.BAIT_AREA
                    and (stealable(tostring(record.State)) or record.Uid == S.stickTo) then
                    local info = describeRecord(record)
                    if (not best or info.RarityRank > best) and passesFilter(info, r) then
                        best = info.RarityRank
                    end
                end
            end
            return best
        end
        local function endRun(r)
            if run == r then run = nil end
            Status.stealBusy = false
            if r then Control.Release(r.lock) end
        end
        local function afterFailure(r, ok, why, record)
            if S.carrying then pcall(Game.EggState.DropFieldEgg) end
            if r.legit or not S.enabled then return end
            local root = myRoot()
            local knocked = knockdownLeft() > 0.4
            local out = root and root.Position.X - borderX() or 0
            if record and S.stickTo == record.Uid and out > 0 then
                local spot, since = CFrame.new(landingSpot(record)), os.clock()
                if knocked then
                    while knockdownLeft() > 0 and S.enabled and pin(spot) do RunService.Heartbeat:Wait() end
                    holdStill(spot, 2 * ping() + 0.1, 2, function() return S.enabled end, 1)
                end
                local after = myRoot()
                if after and flat(after.Position, spot.Position) < C.RECOVER_REACH and not relocatedSince(since) then
                    trace(knocked and "rode the knockdown to the egg: taking it again from here"
                        or "still beside the egg: taking it again from here")
                    S.resumeFrom, S.resumeFor, S.vanishedAt = os.clock(), record.Uid, os.clock()
                    return
                end
                if knocked then
                    trace("the server did not take the ride to the egg")
                    return
                end
            end
            if ok and why == TAKEN and not S.carrying then
                if r.normal then
                    S.vanishedAt = os.clock()
                    return
                end
                if not knocked and out > C.RECOVER_REACH then
                    S.resumeHere = true
                    return
                end
            end
            if not r.normal or not root or S.carrying or out <= (knocked and 0 or 1500) then return end
            local since, home = os.clock(), CFrame.new(safeCenter())
            while knockdownLeft() > 0 and S.enabled and pin(home) do RunService.Heartbeat:Wait() end
            if knocked then holdStill(home, 2 * ping() + 0.1, 2, function() return S.enabled end, 1) end
            local after = myRoot()
            if knocked and after and after.Position.X <= borderX() and not relocatedSince(since) then
                trace("rode the knockdown home from %.0f studs out", out)
            else
                trace("left %.0f studs out in the field: respawning home", out)
                pcall(respawnAndWait, function() return S.enabled end)
            end
        end
        local function stealCycle()
            if not readyToSteal() then return end
            if S.carrying and not run then
                local ok, live = pcall(Game.EggState.ReadFieldEgg, S.carrying)
                if not (ok and type(live) == "table" and tostring(live.State) == "Carried"
                    and live.CarrierUserId == LocalPlayer.UserId) then
                    trace("the game has us carrying nothing: clearing the old carry")
                    S.carrying = nil
                end
            end
            if S.holding then holdOn(S.holding) end
            local r = newRun()
            local info, lock, waiting = not S.stickTo and pickCarrier(r) or nil, "steal", nil
            if not info then info, lock, waiting = pickTarget(r) end
            if not info then
                if waiting then
                    trace("the failed egg is not back in its nest yet: waiting for it")
                    holdOn(lock)
                    task.wait(0.2)
                    return
                end
                if S.standbyUntil and os.clock() < S.standbyUntil then
                    holdOn("steal", 3)
                    task.wait(0.05)
                    return
                end
                idle((S.fromCarriers or S.carriersOnly) and 0.1 or 0.5)
                return
            end
            local rival = Status.hwBestEggRank and Status.hwBestEggRank()
            local mine = Status.stealBestRank() or info.RarityRank or 0
            if rival and rival > mine then
                trace("a rarer Halloween egg goes first (rank %d over %d)", rival, mine)
                idle(0.3)
                return
            end
            if Movement.FieldClosed() then
                trace("field closed (egg reset): waiting")
                idle(1)
                return
            end
            r.lock = lock
            Control.Want(lock, 1.5)
            if not Control.Acquire(lock) then
                task.wait(0.3)
                return
            end
            r.character = LocalPlayer.Character
            run = r
            Status.stealBusy = true
            trace("target %s (%s, %s) [%s, %s]", tostring(info.EggName), tostring(info.Rarity), tostring(info.Record.AreaId),
                r.legit and "legit" or r.normal and "normal" or "instant", lock)
            local ok, took, why = xpcall(function()
                Treadmill.Leave()
                return stealOne(info)
            end, debug.traceback)
            if ok and took then
                if S.stickTo == info.Record.Uid then S.stickTo = nil end
                trace("claimed %s", tostring(info.EggName))
                S.inStep, S.keepStep = LocalPlayer.Character, nil
            else
                if not S.keepStep then S.inStep = nil end
                S.keepStep = nil
                if not info.Carrier and not (ok and (why == TAKEN or why == CARRIER_FIRST)) then S.stickTo = info.Record.Uid end
                trace("failed: %s [%s]", tostring(ok and (why or "stopped.") or took), inactiveReason(r))
                afterFailure(r, ok, why, not info.Carrier and info.Record or nil)
            end
            endRun(r)
            task.delay(0.6, function()
                if run == nil and S.releaseCover then pcall(S.releaseCover) end
            end)
            holdOn(lock, 3)
            task.wait(0.05)
        end
        local function stopSteal()
            S.enabled           = false
            S.generation        = S.generation + 1
            Status.stealEnabled = false
            local thread = S.thread
            S.thread = nil
            if thread and thread ~= coroutine.running() then pcall(task.cancel, thread) end
            endRun(run)
            letGo()
            if S.uncover then pcall(S.uncover, true) end
            if S.releaseCover then pcall(S.releaseCover) end
            for _, conn in ipairs(S.conns) do pcall(function() conn:Disconnect() end) end
            S.conns    = {}
            S.carrying = nil
            Movement.SoftenHumanoid()
            Movement.RestoreHumanoid()
            local _, root, humanoid = getCharacter()
            if root and humanoid then pcall(function() humanoid:MoveTo(root.Position) end) end
        end
        local function startEngine()
            if S.enabled then return true end
            if not Game.Init() then return false end
            S.enabled           = true
            Status.stealEnabled = true
            S.generation        = S.generation + 1
            S.claims = {}
            S.carrying, S.stickTo, S.holding = nil, nil, nil
            S.resumeHere, S.resumeFrom, S.standbyUntil = false, nil, nil
            local generation = S.generation
            local refresh
            pcall(function() refresh = require(ReplicatedStorage.Shared.Remotes).RigSync.Refresh.OnClientEvent end)
            S.conns = {}
            for _, pair in ipairs({
                { Game.EggState.CarryChanged, onCarryChanged },
                { Game.EggState.FieldClaimed, onClaimed },
                { refresh, onRefresh },
                { LocalPlayer.CharacterAdded, function() S.spawnedAt = os.clock() end },
            }) do
                local ok, conn = pcall(function() return pair[1]:Connect(pair[2]) end)
                if ok then S.conns[#S.conns + 1] = conn end
            end
            S.thread = task.spawn(function()
                afterConfigLoad()
                while S.enabled and S.generation == generation do
                    local ok, err = pcall(stealCycle)
                    if not ok then
                        trace("cycle error: %s", tostring(err))
                        endRun(run)
                        task.wait(0.5)
                    end
                end
            end)
            return true
        end
        local function setToggle(ref, value)
            if not ref then return end
            S.switching = true
            pcall(function() ref:SetValue(value) end)
            S.switching = false
        end
        local function stopIfUnused()
            if not (S.mode or S.index or S.wisp) then stopSteal() end
        end
        local function onMode(legit, mode, on)
            if S.switching then return end
            local mine = S.refs[(legit and "legit" or "fast") .. mode]
            if not on then
                if S.mode ~= mode or Movement.Legit ~= legit then return end
                S.mode = nil
                stopIfUnused()
                return
            end
            for _, ref in pairs(S.refs) do
                if ref ~= mine then setToggle(ref, false) end
            end
            Movement.Legit = legit
            S.mode = mode
            if not startEngine() then
                S.mode = nil
                notify(legit and "Legit Steal Egg" or "Auto Steal", "Belum siap: " .. Game.MissingText(), Color3.fromRGB(255, 90, 90), 3)
                setToggle(mine, false)
            end
        end
        function Status.SetIndexSteal(on)
            S.index     = on == true
            S.indexDone = false
            if S.index then return startEngine() end
            stopIfUnused()
            return true
        end
        function Status.SetWispSteal(on)
            S.wisp = on == true
            if S.wisp then return startEngine() end
            stopIfUnused()
            return true
        end
        function Status.IndexAreaOptions()
            local areas = Game.Areas and Game.Areas.Directory
            if type(areas) ~= "table" then
                local ok, result = pcall(require, ReplicatedStorage.Data.Areas)
                areas = ok and type(result) == "table" and result.Directory or nil
            end
            local options, rank = {}, {}
            for areaId, area in pairs(areas or {}) do
                areaId = tostring(areaId)
                rank[areaId] = tonumber(area.Rarity and area.Rarity.Rank) or 0
                options[#options + 1] = { Label = tostring(area.DisplayName or areaId), Value = areaId }
            end
            table.sort(options, function(a, b)
                if rank[a.Value] ~= rank[b.Value] then return rank[a.Value] < rank[b.Value] end
                return a.Value < b.Value
            end)
            return options
        end
        table.insert(_G.LynxSAE.Stoppers, stopSteal)
        local StealSection = MainTab:AddSection("Auto Steal")
        StealSection:AddDropdown({
            Title    = "Steal Mode",
            Options  = { "Instant", "Normal" },
            Default  = "Instant",
            Callback = function(value)
                local pick = tostring(type(value) == "table" and value[1] or value)
                S.speedMode = pick == "Normal" and "normal" or "instant"
            end,
        })
        S.refs.fastfilter = StealSection:AddToggle({
            Title    = "Steal Filter Selected",
            Default  = false,
            Callback = function(on) onMode(false, "filter", on) end,
        })
        S.refs.fastall = StealSection:AddToggle({
            Title    = "Steal All",
            Default  = false,
            Callback = function(on) onMode(false, "all", on) end,
        })
        StealSection:AddToggle({
            Title    = "Steal From Carriers",
            Default  = false,
            Callback = function(on) S.fromCarriers = on == true end,
        })
        StealSection:AddToggle({
            Title    = "Only Steal From Carriers",
            Default  = false,
            Callback = function(on) S.carriersOnly = on == true end,
        })
        local LegitSection = MainTab:AddSection("Legit Steal Egg")
        S.refs.legitfilter = LegitSection:AddToggle({
            Title    = "Legit Selected",
            Default  = false,
            Callback = function(on) onMode(true, "filter", on) end,
        })
        S.refs.legitall = LegitSection:AddToggle({
            Title    = "Legit Steal All",
            Default  = false,
            Callback = function(on) onMode(true, "all", on) end,
        })
    end
    do
        local _sell = {
            enabled        = false,
            thread         = nil,
            selectedRarity = {},
            ref            = nil,
            rejected       = {},
        }
        local SELL_BATCH      = 512
        local SELL_WAIT       = 3
        local REJECT_COOLDOWN = 60
        local function buildRarityOptions()
            local seen, ranked = {}, {}
            if Game.Assets and Game.Assets.Directory then
                for _, data in pairs(Game.Assets.Directory) do
                    local rarity = data.Rarity
                    local name   = rarity and rarity.DisplayName
                    if name and not seen[name] then
                        seen[name] = true
                        table.insert(ranked, { name = name, rank = rarity.Rank or 0 })
                    end
                end
            end
            table.sort(ranked, function(a, b)
                if a.rank == b.rank then return a.name < b.name end
                return a.rank < b.rank
            end)
            local options = {}
            for _, entry in ipairs(ranked) do table.insert(options, entry.name) end
            if #options == 0 then options = { "Loading..." } end
            return options
        end
        local function rarityOf(rec, entry)
            local category = rec and (rec.AssetCategory or rec.Category) or entry.AssetCategory
            local data = category and Game.Assets and Game.Assets.Directory
                and Game.Assets.Directory[category]
            return data and data.Rarity and data.Rarity.DisplayName or nil
        end
        local SCAN_SLICE = 0.002
        local function listSellable()
            local out = {}
            if isSetEmpty(_sell.selectedRarity) then return out end
            local save = Game.Save and Game.Save.Get()
            if not save or type(save.EggInventory) ~= "table" then return out end
            local now = os.clock()
            local wisp = Status.WispFuseWants
            local sliceEnd = os.clock() + SCAN_SLICE
            for uid, entry in pairs(save.EggInventory) do
                if os.clock() >= sliceEnd then
                    task.wait()
                    sliceEnd = os.clock() + SCAN_SLICE
                end
                local rejectedUntil = _sell.rejected[uid]
                if rejectedUntil and rejectedUntil <= now then
                    _sell.rejected[uid] = nil
                    rejectedUntil = nil
                end
                local rarity = entry.Placement == nil and not rejectedUntil and rarityOf(nil, entry)
                if rarity and _sell.selectedRarity[rarity] and not (wisp and wisp(entry.AssetCategory)) then
                    out[#out + 1] = uid
                end
            end
            return out
        end
        local function heldEggUid()
            local character = LocalPlayer.Character
            local tool = character and character:FindFirstChildOfClass("Tool")
            return tool and tool:GetAttribute("UID") or nil
        end
        local function sellBatch(eggs)
            local held, uids = heldEggUid(), {}
            for _, uid in ipairs(eggs) do
                if uid ~= held then uids[#uids + 1] = uid end
            end
            if #uids == 0 then return 0, 0 end
            for first = 1, #uids, SELL_BATCH do
                local chunk = table.move(uids, first, math.min(first + SELL_BATCH - 1, #uids), 1, {})
                local fired = pcall(function()
                    Game.Remotes.PetSatchel.SellSelection:FireServer({ Assets = {}, Eggs = chunk })
                end)
                if not fired then break end
            end
            task.wait(SELL_WAIT)
            local save = Game.Save.Get()
            local inventory = save and save.EggInventory or {}
            local sold, retryAt = 0, os.clock() + REJECT_COOLDOWN
            for _, uid in ipairs(uids) do
                if inventory[uid] == nil then sold = sold + 1 else _sell.rejected[uid] = retryAt end
            end
            return sold, #uids
        end
        local function stopSell()
            _sell.enabled      = false
            Control.Want("sell", 0)
            if _sell.conn then
                pcall(function() _sell.conn:Disconnect() end)
                _sell.conn = nil
            end
            if _sell.thread then
                pcall(task.cancel, _sell.thread)
                _sell.thread = nil
            end
        end
        table.insert(_G.LynxSAE.Stoppers, stopSell)
        local SellSection = MainTab:AddSection("Auto Sell Egg")
        SellSection:AddDropdown({
            Title    = "Rarities To Sell",
            Multi    = true,
            Options  = buildRarityOptions(),
            Default  = {},
            Callback = function(selected)
                _sell.selectedRarity = toSet(type(selected) == "table" and selected or {})
            end,
        })
        _sell.ref = SellSection:AddToggle({
            Title    = "Auto Sell Egg",
            Default  = false,
            Callback = function(on)
                if not on then
                    stopSell()
                    return
                end
                if not Game.Init() or not Game.Save or not Game.Remotes then
                    notify("Auto Sell Egg", "Belum siap: " .. Game.MissingText(), Color3.fromRGB(255, 90, 90), 3)
                    if _sell.ref then pcall(function() _sell.ref:SetValue(false) end) end
                    return
                end
                if isSetEmpty(_sell.selectedRarity) then
                    notify("Auto Sell Egg", "Pick a rarity in the dropdown first.",
                        Color3.fromRGB(255, 170, 60), 3)
                    if _sell.ref then pcall(function() _sell.ref:SetValue(false) end) end
                    return
                end
                _sell.enabled  = true
                _sell.rejected = {}
                _sell.dirty = true
                _sell.conn = Game.Save.FieldChanged:Connect(function(field)
                    if field == "EggInventory" then _sell.dirty = true end
                end)
                _sell.thread = task.spawn(function()
                    while _sell.enabled do
                        _sell.dirty = false
                        pcall(function()
                            local eggs = listSellable()
                            if #eggs > 0 then
                                sellBatch(eggs)
                                _sell.dirty = false 
                            end
                        end)
                        local recheck = os.clock() + 10
                        repeat task.wait(1) until not _sell.enabled or _sell.dirty or os.clock() >= recheck
                    end
                end)
            end,
        })
    end
    do
        local _pets = {
            mode        = nil,
            conn        = nil,
            filterRef   = nil,
            allRef      = nil,
            switching   = false,
            pending     = false,
            debounce    = 1.5,
            selectedName = {}, selectedVar = {}, selectedRarity = {}, maxWeight = 0,
        }
        local function petInventory()
            local save = Game.Save and Game.Save.Get()
            if not save or type(save.Inventory) ~= "table" then return nil, nil end
            local equipped = {}
            for _, uid in pairs(save.EquippedAssets or {}) do equipped[uid] = true end
            return save.Inventory, equipped
        end
        local function describePet(entry)
            local ok, data = pcall(Game.AssetItems.Decode, entry)
            if not ok or not data then return nil end
            if data.IsFavorite == true or data.InFuse then return nil end
            local directory = Game.Assets and Game.Assets.Directory
            local info = data.Category and directory and directory[data.Category]
            if not info then return nil end
            local labels = {}
            if Game.Mutations then
                for _, id in ipairs(data.Mutations or {}) do
                    labels[#labels + 1] = tostring(Game.Mutations.LabelOf(id) or id)
                end
            end
            local weight = select(2, pcall(Game.AssetItems.WeightKg, data))
            return {
                name    = info.DisplayName or tostring(data.Category),
                rarity  = info.Rarity and info.Rarity.DisplayName or "?",
                variant = labels,
                weight  = type(weight) == "number" and weight or 0,
            }
        end
        local function anyFilterActive()
            return not isSetEmpty(_pets.selectedName)
                or not isSetEmpty(_pets.selectedVar)
                or not isSetEmpty(_pets.selectedRarity)
                or _pets.maxWeight > 0
        end
        local function passesPetFilter(info)
            if not isSetEmpty(_pets.selectedName)
                and not _pets.selectedName[info.name] then
                return false
            end
            if not isSetEmpty(_pets.selectedRarity)
                and not _pets.selectedRarity[info.rarity] then
                return false
            end
            if not isSetEmpty(_pets.selectedVar) then
                local matched = false
                if #info.variant == 0 then
                    matched = _pets.selectedVar["None"] == true
                else
                    for _, label in ipairs(info.variant) do
                        if _pets.selectedVar[label] then matched = true break end
                    end
                end
                if not matched then return false end
            end
            if _pets.maxWeight > 0 and info.weight > _pets.maxWeight then
                return false
            end
            return true
        end
        local SELL_BATCH = 512
        local function sellablePets(filtered)
            local inventory, equipped = petInventory()
            if not inventory then return {} end
            local list = {}
            for uid, entry in pairs(inventory) do
                if not equipped[uid] and not (Status.WispFuseWants and Status.WispFuseWants(entry.Category)) then
                    local info = describePet(entry)
                    if info and (not filtered or passesPetFilter(info)) then
                        list[#list + 1] = uid
                    end
                end
            end
            return list
        end
        local function sellPets(uids)
            for first = 1, #uids, SELL_BATCH do
                local chunk = table.move(uids, first, math.min(first + SELL_BATCH - 1, #uids), 1, {})
                pcall(function()
                    Game.Remotes.PetSatchel.SellSelection:FireServer({ Assets = chunk, Eggs = {} })
                end)
            end
        end
        local function runSell()
            local mode = _pets.mode
            if mode ~= "all" and mode ~= "filter" then return end
            if mode == "filter" and not anyFilterActive() then return end
            local uids = sellablePets(mode == "filter")
            if #uids > 0 then sellPets(uids) end
        end
        local function stopSellPets()
            _pets.mode    = nil
            _pets.pending = false
            if _pets.conn then
                pcall(function() _pets.conn:Disconnect() end)
                _pets.conn = nil
            end
        end
        table.insert(_G.LynxSAE.Stoppers, stopSellPets)
        local function buildPetNameOptions()
            local seen, options = {}, {}
            if Game.Assets and Game.Assets.Directory then
                for _, data in pairs(Game.Assets.Directory) do
                    local name = data.DisplayName
                    if name and not seen[name] then
                        seen[name] = true
                        table.insert(options, name)
                    end
                end
            end
            table.sort(options)
            if #options == 0 then options = { "Loading..." } end
            return options
        end
        local function buildPetVariantOptions()
            local options = { "None" }
            if Game.Mutations and Game.Mutations.All then
                local labels = {}
                for id in pairs(Game.Mutations.All()) do
                    table.insert(labels, tostring(Game.Mutations.LabelOf(id) or id))
                end
                table.sort(labels)
                for _, label in ipairs(labels) do table.insert(options, label) end
            end
            return options
        end
        local function buildPetRarityOptions()
            local seen, ranked = {}, {}
            if Game.Assets and Game.Assets.Directory then
                for _, data in pairs(Game.Assets.Directory) do
                    local rarity = data.Rarity
                    local name   = rarity and rarity.DisplayName
                    if name and not seen[name] then
                        seen[name] = true
                        table.insert(ranked, { name = name, rank = rarity.Rank or 0 })
                    end
                end
            end
            table.sort(ranked, function(a, b)
                if a.rank == b.rank then return a.name < b.name end
                return a.rank < b.rank
            end)
            local options = {}
            for _, entry in ipairs(ranked) do table.insert(options, entry.name) end
            if #options == 0 then options = { "Loading..." } end
            return options
        end
        local PetSellSection = MainTab:AddSection("Auto Sell Pets")
        PetSellSection:AddDropdown({
            Title    = "Name",
            Multi    = true,
            Options  = buildPetNameOptions(),
            Default  = {},
            Callback = function(selected)
                _pets.selectedName = toSet(type(selected) == "table" and selected or {})
            end,
        })
        PetSellSection:AddDropdown({
            Title    = "Variant",
            Multi    = true,
            Options  = buildPetVariantOptions(),
            Default  = {},
            Callback = function(selected)
                _pets.selectedVar = toSet(type(selected) == "table" and selected or {})
            end,
        })
        PetSellSection:AddDropdown({
            Title    = "Pet Rarity",
            Multi    = true,
            Options  = buildPetRarityOptions(),
            Default  = {},
            Callback = function(selected)
                _pets.selectedRarity = toSet(type(selected) == "table" and selected or {})
            end,
        })
        PetSellSection:AddInput({
            Title    = "Maximum Weight (kg)",
            Default  = "0",
            Callback = function(value)
                local weight = tonumber(value)
                if weight and weight >= 0 then _pets.maxWeight = weight end
            end,
        })
        local function setPetToggle(ref, value)
            if not ref then return end
            _pets.switching = true
            pcall(function() ref:SetValue(value) end)
            _pets.switching = false
        end
        local function startPetSell(mode)
            _pets.mode = mode
            runSell()
            _pets.conn = Game.Save.FieldChanged:Connect(function(field)
                if _pets.mode ~= mode then return end
                if field ~= "Inventory" then return end
                if _pets.pending then return end
                _pets.pending = true
                task.delay(_pets.debounce, function()
                    _pets.pending = false
                    if _pets.mode == mode then runSell() end
                end)
            end)
            pcall(function()
                Library:AddConnection("SAE_AutoSellPets", _pets.conn)
            end)
        end
        local function onPetMode(mode, on)
            if _pets.switching then return end
            if not on then
                if _pets.mode ~= mode then return end
                stopSellPets()
                return
            end
            if not Game.Init() or not Game.Save or not Game.AssetItems or not Game.Remotes
                or type(Game.Save.FieldChanged) ~= "table" then
                notify("Auto Sell Pets", "Belum siap: " .. Game.MissingText(),
                    Color3.fromRGB(255, 90, 90), 3)
                setPetToggle(mode == "all" and _pets.allRef or _pets.filterRef, false)
                return
            end
            if mode == "filter" and not anyFilterActive() then
                notify("Auto Sell Pets", "Enable at least one filter first.",
                    Color3.fromRGB(255, 170, 60), 3)
                setPetToggle(_pets.filterRef, false)
                return
            end
            setPetToggle(mode == "all" and _pets.filterRef or _pets.allRef, false)
            stopSellPets()
            startPetSell(mode)
        end
        _pets.filterRef = PetSellSection:AddToggle({
            Title    = "Auto Sell Filter Selected",
            Default  = false,
            Callback = function(on) onPetMode("filter", on) end,
        })
        _pets.allRef = PetSellSection:AddToggle({
            Title    = "Sell All Pets",
            Default  = false,
            Callback = function(on) onPetMode("all", on) end,
        })
        local _fav = {
            enabled = false, ref = nil, conn = nil, pending = false,
            busy = false, debounce = 1,
            selectedName = {}, selectedVar = {}, selectedRarity = {}, minWeight = 0,
        }
        local function favRemote()
            local net = Game.Remotes and Game.Remotes.PetSatchel
            return net and net.WriteFavourite or nil
        end
        local function favFilterActive()
            return not isSetEmpty(_fav.selectedName)
                or not isSetEmpty(_fav.selectedVar)
                or not isSetEmpty(_fav.selectedRarity)
                or _fav.minWeight > 0
        end
        local function favCandidate(entry)
            local ok, data = pcall(Game.AssetItems.Decode, entry)
            if not ok or not data or data.IsFavorite == true then return nil end
            local directory = Game.Assets and Game.Assets.Directory
            local info = data.Category and directory and directory[data.Category]
            if not info then return nil end
            local labels = {}
            if Game.Mutations then
                for _, id in ipairs(data.Mutations or {}) do
                    labels[#labels + 1] = tostring(Game.Mutations.LabelOf(id) or id)
                end
            end
            local weight = select(2, pcall(Game.AssetItems.WeightKg, data))
            return {
                name    = info.DisplayName or tostring(data.Category),
                rarity  = info.Rarity and info.Rarity.DisplayName or "?",
                variant = labels,
                weight  = type(weight) == "number" and weight or 0,
            }
        end
        local function favMatches(info)
            if not isSetEmpty(_fav.selectedName) and not _fav.selectedName[info.name] then
                return false
            end
            if not isSetEmpty(_fav.selectedRarity) and not _fav.selectedRarity[info.rarity] then
                return false
            end
            if not isSetEmpty(_fav.selectedVar) then
                local matched = false
                if #info.variant == 0 then
                    matched = _fav.selectedVar["None"] == true
                else
                    for _, label in ipairs(info.variant) do
                        if _fav.selectedVar[label] then matched = true break end
                    end
                end
                if not matched then return false end
            end
            if _fav.minWeight > 0 and info.weight < _fav.minWeight then return false end
            return true
        end
        local function favoriteSweep()
            if _fav.busy or not _fav.enabled or not favFilterActive() then return 0 end
            local remote = favRemote()
            local inventory = petInventory()
            if not remote or not inventory then return 0 end
            _fav.busy = true
            local count = 0
            for uid, entry in pairs(inventory) do
                if not _fav.enabled then break end
                local info = favCandidate(entry)
                if info and favMatches(info) then
                    if pcall(function() remote:FireServer(uid, true) end) then
                        count = count + 1
                        task.wait(0.05)
                    end
                end
            end
            _fav.busy = false
            return count
        end
        local function stopFavorite()
            _fav.enabled = false
            _fav.pending = false
            if _fav.conn then
                pcall(function() _fav.conn:Disconnect() end)
                _fav.conn = nil
            end
        end
        table.insert(_G.LynxSAE.Stoppers, stopFavorite)
        local FavoriteSection = MainTab:AddSection("Auto Favorite")
        FavoriteSection:AddDropdown({
            Title    = "Favorite Name",
            Multi    = true,
            Options  = buildPetNameOptions(),
            Default  = {},
            Callback = function(selected)
                _fav.selectedName = toSet(type(selected) == "table" and selected or {})
            end,
        })
        FavoriteSection:AddDropdown({
            Title    = "Favorite Variant",
            Multi    = true,
            Options  = buildPetVariantOptions(),
            Default  = {},
            Callback = function(selected)
                _fav.selectedVar = toSet(type(selected) == "table" and selected or {})
            end,
        })
        FavoriteSection:AddDropdown({
            Title    = "Favorite Rarity",
            Multi    = true,
            Options  = buildPetRarityOptions(),
            Default  = {},
            Callback = function(selected)
                _fav.selectedRarity = toSet(type(selected) == "table" and selected or {})
            end,
        })
        FavoriteSection:AddInput({
            Title       = "Favorite Minimum Weight (kg)",
            Default     = "0",
            Placeholder = "0 = off",
            Callback    = function(value)
                local weight = tonumber((tostring(value):gsub("%s", "")))
                if weight and weight >= 0 then _fav.minWeight = weight end
            end,
        })
        _fav.ref = FavoriteSection:AddToggle({
            Title    = "Enable Auto Favorite",
            Default  = false,
            Callback = function(on)
                if not on then stopFavorite() return end
                if not Game.Init() or not Game.Save or not Game.AssetItems
                    or type(Game.Save.FieldChanged) ~= "table" or not favRemote() then
                    notify("Auto Favorite", "Belum siap: " .. Game.MissingText(),
                        Color3.fromRGB(255, 90, 90), 3)
                    if _fav.ref then pcall(function() _fav.ref:SetValue(false) end) end
                    return
                end
                _fav.enabled = true
                if not favFilterActive() then
                    notify("Auto Favorite",
                        "Pick a Name, Variant, Rarity or Minimum Weight first.",
                        Color3.fromRGB(255, 170, 60), 4)
                end
                task.spawn(favoriteSweep)
                _fav.conn = Game.Save.FieldChanged:Connect(function(field)
                    if not _fav.enabled or field ~= "Inventory" then return end
                    if _fav.pending then return end
                    _fav.pending = true
                    task.delay(_fav.debounce, function()
                        _fav.pending = false
                        if _fav.enabled then favoriteSweep() end
                    end)
                end)
                pcall(function() Library:AddConnection("SAE_AutoFavorite", _fav.conn) end)
            end,
        })
    end
end
task.wait()
do
    local EventTab = MainWindow:AddTab({ Name = "Events", Icon = "star" })
    local function touchPart(part)
        local _, root = getCharacter()
        if not (root and part and type(firetouchinterest) == "function") then return end
        pcall(firetouchinterest, root, part, 0)
        task.wait()
        pcall(firetouchinterest, root, part, 1)
    end
    -- Halloween Dimension, Phantom Express and Instant Fishing: one scheduler, one portal.
    do
        local HW_SAFE         = Vector3.new(-5808, -200, -7377)
        local HW_ZONES        = { "Graveyard (Zone 1)", "Haunted Swamp (Zone 2)", "Abandoned Manor (Zone 3)" }
        local HW_SIZES        = { "Small", "Medium", "Large" }
        local HW_RARITY_ORDER = { "Common", "Uncommon", "Rare", "Epic", "Legendary", "Mythic", "Cosmic", "Secret", "Eternal", "Divine" }
        local HW_RARITY_RANK  = {}
        for index, name in ipairs(HW_RARITY_ORDER) do HW_RARITY_RANK[name] = index end
        local HW_LOCKS = { halloween = true, hweggs = true, train = true, fishing = true, pumpkinking = true }
        Control.SetGroup(HW_LOCKS)
        local hw = {
            eggs = false, monsters = false, pumpkin = false, buy = false, live = true,
            eggZones = { true, true, true }, monsterZones = { true, true, true },
            sizes = { Small = true, Medium = true, Large = true }, rarities = {},
            state = "Off", workAt = 0, buyPauseUntil = 0, pickPin = 0.3, topRank = nil,
            warned = {}, badMonster = {}, rarityCache = setmetatable({}, { __mode = "k" }),
            delivered = 0, failed = 0, kills = 0, deposits = 0, bought = 0,
        }
        local tr = { quest = false, ride = false, trade = false, state = nil, stateAt = 0, status = "Off", rides = 0, trades = 0, sucking = false }
        local fs = { enabled = false, perfect = true, casts = 0, catches = 0, misses = 0, status = "Off",
            ghost = true, ghosts = 0, phantom = false, phantomStatus = "Off", withMonsters = false }
        local pk = {
            enabled = false, cannons = true, minions = true, dodge = true, status = "Off",
            fights = 0, wins = 0, tokens = 0, shots = 0, hazards = {}, drops = {}, shotId = 0, nextShot = 0, retryAt = 0,
        }
        local portal = { busy = false, entering = false, exiting = false, exitPart = nil }

        -- helpers
        local function ping()
            local ok, value = pcall(function() return LocalPlayer:GetNetworkPing() end)
            return ok and tonumber(value) or 0.2
        end
        local function roundTrip() return 0.05 + ping() * 2 end
        local function waitFor(condition, timeout)
            local deadline = os.clock() + timeout + ping() * 2
            while not condition() do
                if os.clock() >= deadline then return false end
                RunService.Heartbeat:Wait()
            end
            return true
        end
        local function remotes(name)
            local ok, all = pcall(require, ReplicatedStorage.Shared.Remotes)
            return ok and type(all) == "table" and all[name or "HalloweenDimension"] or nil
        end
        local function save()
            local data = Game.Save and Game.Save.Get()
            return type(data) == "table" and data or {}
        end
        local function flag(name, fallback)
            local ok, value = pcall(function()
                return require(ReplicatedStorage.Shared.Flags.HalloweenDimensionFlags)[name].Value
            end)
            return ok and value ~= nil and value or fallback
        end
        local function counter(name) return tonumber(LocalPlayer:GetAttribute(name)) or 0 end
        local function tokens() return tonumber(save().HalloweenTokens) or 0 end
        local function eggPrice()
            local ok, data = pcall(require, ReplicatedStorage.Data.HalloweenDimensionEgg)
            return ok and type(data) == "table" and tonumber(data.Price) or 2250
        end
        local function eligible()
            return (tonumber(save().SpeedPower) or 0) >= flag("SpeedPowerRequirement", 2.5e6)
        end
        local function alert(key, text)
            if (hw.warned[key] or 0) > os.clock() then return end
            hw.warned[key] = os.clock() + 30
            notify("Halloween Dimension", text, Color3.fromRGB(255, 140, 0), 4)
        end
        local function findTool(attribute)
            for _, holder in ipairs({ LocalPlayer.Character, LocalPlayer:FindFirstChild("Backpack") }) do
                for _, item in ipairs(holder and holder:GetChildren() or {}) do
                    if item:IsA("Tool") and item:GetAttribute(attribute) == true then return item end
                end
            end
            return nil
        end
        local function equip(item)
            local character, _, humanoid = getCharacter()
            if not (item and humanoid) then return false end
            if item.Parent ~= character then pcall(function() humanoid:EquipTool(item) end) end
            return waitFor(function() return item.Parent == character end, 1)
        end
        local function realHumanoid()
            pcall(Movement.SoftenHumanoid)
            pcall(Movement.RestoreHumanoid)
        end
        local function flatGap(a, b) return Vector3.new(a.X - b.X, 0, a.Z - b.Z).Magnitude end

        -- where we are
        local function hwMap()
            local model = workspace:FindFirstChild("HalloweenDimension")
            return model and model:IsA("Model") and model or nil
        end
        local function inside() return LocalPlayer:GetAttribute("InHalloweenDimension") == true end
        local function carrying() return LocalPlayer:GetAttribute("HalloweenCarrying") == true end
        local function zoneAt(position)
            local model = hwMap()
            local zones = model and model:FindFirstChild("Zones")
            for _, part in ipairs(zones and zones:GetChildren() or {}) do
                if part:IsA("BasePart") then
                    local offset = part.CFrame:PointToObjectSpace(position)
                    if math.abs(offset.X) <= part.Size.X / 2 and math.abs(offset.Z) <= part.Size.Z / 2 then
                        if part.Name == "SafeZone" then return 0 end
                        return tonumber(part.Name:match("^Zone(%d)$"))
                    end
                end
            end
            return nil
        end
        local function inMap()
            local _, root = getCharacter()
            return root ~= nil and zoneAt(root.Position) ~= nil
        end
        local function inDimension() return inside() or inMap() end
        Status.inHalloween = inDimension
        task.spawn(function()
            local was = inDimension()
            while hw.live do
                local now = inDimension()
                if now ~= was then was, Status.hwCrossedAt = now, os.clock() end
                RunService.Heartbeat:Wait()
            end
        end)
        local function insideMap(position)
            return position ~= nil and position.Y >= -235 and position.Y <= -20 and zoneAt(position) ~= nil
        end
        local function hidden()
            local _, root = getCharacter()
            return root ~= nil and root.Position.Y < -100000
        end
        local function inNormalWorld()
            local _, root = getCharacter()
            return root ~= nil and not hidden() and flatGap(root.Position, HW_SAFE) > 3500
        end
        -- the dimension resets with the night only: the normal field's start wall (still up for the 3-2-1
        -- countdown after the night) does not stand in here, and the new eggs are already out by then
        local function resetting(ahead)
            local cycle = Game.EggCycle
            if not (cycle and type(cycle.IsNightPhase) == "function") then return false end
            local now = workspace:GetServerTimeNow()
            local ok, night = pcall(function()
                for t = 0, math.max(ahead or 2, 1) do
                    if cycle.IsNightPhase(now + t) then return true end
                end
                return false
            end)
            return ok and night == true
        end
        local function eventSoon(lock, ahead)
            local mine = Control.Rank(lock)
            local landAt = Status.starDueAt
            if landAt and Control.Rank("star") > mine and workspace:GetServerTimeNow() >= landAt - 20 - (ahead or 0) then
                return "Shooting Star"
            end
            return nil
        end

        -- moving: every move is one teleport onto the floor; the server sometimes pulls a jump back
        local ray = RaycastParams.new()
        ray.FilterType = Enum.RaycastFilterType.Exclude
        ray.RespectCanCollide = true
        local function groundY(position, anyHeight)
            local skip = { LocalPlayer.Character }
            local model = hwMap()
            for _, name in ipairs({ "Monsters", "WorldEggs", "Ghosts", "RunawayPumpkins" }) do
                local folder = model and model:FindFirstChild(name)
                if folder then skip[#skip + 1] = folder end
            end
            for _, player in ipairs(Players:GetPlayers()) do
                if player ~= LocalPlayer and player.Character then skip[#skip + 1] = player.Character end
            end
            ray.FilterDescendantsInstances = skip
            for _, above in ipairs({ 12, 60 }) do
                local hit = workspace:Raycast(position + Vector3.new(0, above, 0), Vector3.new(0, -220, 0), ray)
                local y = hit and hit.Position.Y
                if y and (anyHeight or (y >= -215 and y <= -60)) then return y end
            end
            return nil
        end
        local function pulledOut() return os.clock() - (hw.pulledOutAt or -math.huge) < 6 end
        local function jump(position, face, anyHeight)
            local character, root = getCharacter()
            if not character or pulledOut() then return nil end
            local ground = groundY(position, anyHeight)
            local spot = Vector3.new(position.X, ground and ground + 3 or position.Y, position.Z)
            character:PivotTo(face and CFrame.lookAt(spot, Vector3.new(face.X, spot.Y, face.Z)) or CFrame.new(spot))
            root.AssemblyLinearVelocity = Vector3.zero
            return spot
        end
        local function beside(target, gap, from)
            local _, root = getCharacter()
            from = from or (root and root.Position) or target
            local side = Vector3.new(from.X - target.X, 0, from.Z - target.Z)
            side = side.Magnitude > 0.5 and side.Unit * gap or Vector3.new(gap, 0, 0)
            return target + side
        end
        local function pin(cf, seconds, keepGoing)
            local untilAt = os.clock() + seconds
            while true do
                if keepGoing and not keepGoing() then return false end
                local character, root = getCharacter()
                if not character or pulledOut() then return false end
                character:PivotTo(cf)
                root.AssemblyLinearVelocity = Vector3.zero
                if os.clock() >= untilAt then return true end
                RunService.Heartbeat:Wait()
            end
        end
        do
            local okRefresh, refresh = pcall(function() return require(ReplicatedStorage.Shared.Remotes).RigSync.Refresh end)
            if okRefresh and refresh then
                local HttpService = game:GetService("HttpService")
                local conn = refresh.OnClientEvent:Connect(function(payload)
                    local ok, data = pcall(function() return typeof(payload) == "string" and HttpService:JSONDecode(payload) or payload end)
                    local at = ok and type(data) == "table" and data.Action == "Relocate" and type(data.Arguments) == "table" and data.Arguments
                    if not (at and tonumber(at[1])) then return end
                    local position = Vector3.new(at[1], at[2], at[3])
                    hw.relocated = { at = os.clock(), pos = position }
                    if inside() and zoneAt(position) == nil then
                        hw.pulledOutAt = os.clock()
                        hw.state = "Pulled out by the server: going along"
                    end
                end)
                table.insert(_G.LynxSAE.Stoppers, function() conn:Disconnect() end)
            end
        end
        -- the server pulls a jump back now and then; standing on the spot every frame (instead of going
        -- along) wins: stay there and keep asking, in the background so the pin never pauses
        local function holdAndAsk(spot, seconds, ask, keepGoing, every, firstAfter)
            local cf = typeof(spot) == "CFrame" and spot or CFrame.new(spot)
            local started = os.clock()
            local nextAsk, asking, result = started + (firstAfter or 0), false, nil
            while not result and os.clock() - started < seconds do
                if keepGoing and not keepGoing() then break end
                local character, root = getCharacter()
                if not character or pulledOut() then break end
                character:PivotTo(cf)
                root.AssemblyLinearVelocity = Vector3.zero
                if ask and not asking and os.clock() >= nextAsk then
                    asking, nextAsk = true, os.clock() + (every or 0.25)
                    task.spawn(function()
                        local got = { pcall(ask) }
                        if got[1] and got[2] then result = { table.unpack(got, 2) } end
                        asking = false
                    end)
                end
                RunService.Heartbeat:Wait()
            end
            if result then return table.unpack(result) end
            return false
        end
        local function holdUntilCalm(spot, keepGoing, seconds)
            local started = os.clock()
            holdAndAsk(spot, seconds or 3, nil, function()
                if keepGoing and not keepGoing() then return false end
                local quietSince = math.max(started, hw.relocated and hw.relocated.at or 0)
                return os.clock() - quietSince < 0.35 + ping() * 2
            end)
        end
        local function facing(spot, target)
            return target and CFrame.lookAt(spot, Vector3.new(target.X, spot.Y, target.Z)) or CFrame.new(spot)
        end
        local function arrive(position, face, seconds, keepGoing)
            local spot = jump(position, face)
            if not (spot and pin(facing(spot, face), seconds, keepGoing)) then return nil end
            return spot
        end
        -- the server only takes a jump of a few hundred studs at a time (a 1300-stud jump is pulled back and
        -- it then answers "Get a little closer" forever): far spots are reached in 350-stud hops with a short
        -- rest at each, following the server whenever it pulls a hop back
        local HOP_STEP = 350
        local function stepTo(position, keepGoing)
            for _ = 1, 60 do
                local _, root, humanoid = getCharacter()
                if not root or pulledOut() or (keepGoing and not keepGoing()) then return false end
                local gap = Vector3.new(position.X - root.Position.X, 0, position.Z - root.Position.Z)
                if gap.Magnitude <= HOP_STEP then return true end
                local rest = math.max(0.5, HOP_STEP / math.max((humanoid and humanoid.WalkSpeed or 100) * 1.3, 50))
                local since = os.clock()
                local spot = jump(root.Position + gap.Unit * HOP_STEP)
                if not (spot and pin(CFrame.new(spot), rest, keepGoing)) then return false end
                local moved = hw.relocated
                if moved and moved.at >= since and (moved.pos - spot).Magnitude > 20 then
                    if not pin(CFrame.new(moved.pos), rest, keepGoing) then return false end
                end
            end
            return false
        end
        local function tryAt(spot, seconds, try, keepGoing)
            local cf = typeof(spot) == "CFrame" and spot or CFrame.new(spot)
            if not stepTo(cf.Position, keepGoing) then return false end
            return holdAndAsk(cf, seconds, try, keepGoing, 0.5)
        end
        local function goSafe(seconds)
            local _, root = getCharacter()
            if not root then return end
            local spot = flatGap(root.Position, HW_SAFE) > 30 and jump(HW_SAFE) or root.Position
            if spot then pin(CFrame.new(spot), seconds or roundTrip()) end
        end
        local function recover()
            local _, root = getCharacter()
            if not (root and inside()) then hw.worldSince, hw.outSince = nil, nil return end
            if inNormalWorld() then
                hw.worldSince = hw.worldSince or os.clock()
                hw.state = "Back in the normal world: waiting for the server"
                if os.clock() - hw.worldSince > 10 then hw.worldSince = nil Movement.Respawn() end
                return
            end
            hw.worldSince = nil
            local isHidden = hidden()
            if zoneAt(root.Position) ~= nil and not isHidden then hw.outSince = nil return end
            hw.outSince = hw.outSince or os.clock()
            if os.clock() - hw.outSince < (isHidden and 6 or 1) then return end
            hw.outSince = nil
            hw.state = "Out of the map: back to the safe zone"
            pin(CFrame.new(HW_SAFE), roundTrip())
        end
        local function heal(keepGoing)
            local _, _, humanoid = getCharacter()
            if not humanoid or humanoid.Health > humanoid.MaxHealth * 0.35 then return true end
            hw.state = "Healing in the safe zone"
            goSafe()
            waitFor(function()
                local _, _, h = getCharacter()
                return not keepGoing() or not h or h.Health >= h.MaxHealth * 0.9
            end, 20)
            return keepGoing()
        end

        -- portal: entering and leaving never overlap
        local function entryPortal()
            local world = worldFolder()
            local model = world and world:FindFirstChild("HalloweenDimensionPortal")
            local hitbox = model and model:FindFirstChild("Hitbox")
            return hitbox and hitbox:IsA("BasePart") and hitbox or nil
        end
        local function exitPortal()
            if portal.exitPart and portal.exitPart.Parent then return portal.exitPart end
            local model = hwMap()
            local assets = model and model:FindFirstChild("ZonesAssets")
            local home = assets and assets:FindFirstChild("PortalHome", true)
            local part = home and home:FindFirstChild("Portal", true)
            portal.exitPart = part and part:IsA("BasePart") and part or nil
            return portal.exitPart
        end
        local function withPortal(fn, ...)
            local deadline = os.clock() + 15
            while portal.busy and os.clock() < deadline do task.wait(0.1) end
            if portal.busy then return false end
            portal.busy = true
            local ok, result = pcall(fn, ...)
            portal.busy, portal.entering, portal.exiting, Status.hwEntering = false, false, false, false
            return ok and result == true
        end
        local function enterNow(keepGoing)
            realHumanoid()
            if inMap() and not inside() then waitFor(function() return inside() or not inMap() end, 8) end
            if inside() then return true end
            if inMap() then
                hw.state = "Out of the dimension but still on its map: respawning"
                Movement.Respawn()
                return false
            end
            if not eligible() then
                alert("power", "Needs " .. tostring(flag("SpeedPowerRequirement", 2.5e6)) .. " Speed Power to enter.")
                return false
            end
            local hitbox = entryPortal()
            if not hitbox then alert("portal", "The Halloween Dimension portal is not in the map.") return false end
            if not Treadmill.Leave(3) then return false end
            portal.entering = true
            local look = hitbox.CFrame.LookVector * Vector3.new(1, 0, 1)
            look = look.Magnitude > 0.1 and look.Unit or Vector3.zAxis
            local front = Movement.StandSpot(hitbox.Position + look * 14)
            local through = hitbox.Position - look * 15
            local function grounded()
                local _, _, humanoid = getCharacter()
                return humanoid ~= nil and humanoid.FloorMaterial ~= Enum.Material.Air
            end
            for _ = 1, 3 do
                if inside() or not keepGoing() then break end
                local _, root = getCharacter()
                if not root then return false end
                hw.state = "Going to the portal"
                if flatGap(root.Position, front) > 80 and not (Status.Travel and Status.Travel(front, keepGoing)) then return false end
                local walkBy = os.clock() + 4
                Movement.Walk(front, 2, function() return keepGoing() and os.clock() < walkBy end)
                local _, here = getCharacter()
                if here and flatGap(here.Position, front) > 6 then
                    pin(CFrame.lookAt(front, Vector3.new(through.X, front.Y, through.Z)), 0.3 + ping() * 2, keepGoing)
                end
                waitFor(grounded, 1)
                hw.state = "Entering the dimension"
                Status.hwEntering = true
                local touchBy = os.clock() + 0.8 + ping() * 2
                while not inside() and os.clock() < touchBy and keepGoing() do
                    touchPart(hitbox)
                    task.wait(0.1)
                end
                if inside() then break end
                hw.state = "Entering the dimension (walking through the portal)"
                local _, near, humanoid = getCharacter()
                if not (near and humanoid) then break end
                humanoid:MoveTo(Vector3.new(through.X, near.Position.Y, through.Z))
                local walkUntil = os.clock() + 2.5 + ping() * 2
                while not inside() and os.clock() < walkUntil and keepGoing() do
                    local _, live = getCharacter()
                    if live and (live.Position - hitbox.Position).Magnitude < 15 then touchPart(hitbox) end
                    RunService.Heartbeat:Wait()
                end
                waitFor(inside, 0.5)
            end
            if not inside() then return false end
            if waitFor(inMap, 4) then
                local _, arrived = getCharacter()
                if arrived then pin(arrived.CFrame, 0.5 + ping() * 2) end
            end
            return inside()
        end
        local function leaveNow()
            if not inDimension() then return true end
            if inNormalWorld() then recover() return false end
            local exit = exitPortal()
            if not exit then return false end
            hw.state = "Leaving the dimension"
            portal.exiting = true
            pcall(function() exit.CanTouch = true end)
            local deadline, tries = os.clock() + 6 + ping() * 4, 0
            while (inside() or tries < 3) and os.clock() < deadline and getCharacter() do
                touchPart(exit)
                tries = tries + 1
                waitFor(function() return not inside() end, 0.3)
            end
            if inside() or not waitFor(function() return not inMap() end, 8) then return false end
            waitFor(function()
                return os.clock() - (Status.hwCrossedAt or -math.huge) >= 1 and Status.movementTrusted() ~= false
            end, 4)
            return true
        end
        local function enter(keepGoing)
            if inside() then realHumanoid() return true end
            if hw.leaveArena and hw.leaveArena() then return false end
            -- the server still has us in Forgotten Town: no way in from here (the town ends with the train home)
            if Status.inForgottenTown and Status.inForgottenTown() then return false end
            -- the trip home is over but the body was left behind in town: a flight from there to the portal never makes it
            local _, root = getCharacter()
            local okTown, town = pcall(function() return workspace.TrainEventAssets.Map.EventMarkers.TownBounds end)
            if root and okTown and town and LocalPlayer:GetAttribute("InSewerCave") ~= true and not (tr.state and tr.state.Phase == "Town")
                and ((root.Position - town.Position) * Vector3.new(1, 0, 1)).Magnitude < 1500 then
                hw.state = "Left behind in Forgotten Town after the train: respawning"
                Movement.Respawn()
                return false
            end
            return withPortal(enterNow, keepGoing)
        end
        local function leave()
            if not inDimension() then return true end
            return withPortal(leaveNow)
        end
        task.spawn(function()
            while hw.live do
                local holder = Control.Holder()
                local entry = entryPortal()
                if entry then
                    local shut = not portal.entering and holder ~= nil and not HW_LOCKS[holder] and not Control.IsStill(holder)
                    if entry.CanTouch == shut then pcall(function() entry.CanTouch = not shut end) end
                end
                local exit = exitPortal()
                if exit then
                    local shut = not portal.exiting and holder ~= nil and HW_LOCKS[holder] == true
                    if exit.CanTouch == shut then pcall(function() exit.CanTouch = not shut end) end
                end
                local model = hwMap()
                local boss = model and model:FindFirstChild("BossPortal")
                local bossHit = boss and boss:FindFirstChild("Hitbox")
                if bossHit and bossHit:IsA("BasePart") and bossHit.CanTouch ~= pk.enabled then
                    pcall(function() bossHit.CanTouch = pk.enabled end)
                end
                task.wait(0.2)
            end
        end)
        table.insert(_G.LynxSAE.Stoppers, function()
            local entry = entryPortal()
            if entry then pcall(function() entry.CanTouch = true end) end
            if portal.exitPart then pcall(function() portal.exitPart.CanTouch = true end) end
            pcall(function() hwMap().BossPortal.Hitbox.CanTouch = true end)
        end)
        Control.AddGate(function(name)
            if Control.IsStill(name) then return true end
            -- Forgotten Town and the Sewer Cave are only left by the train home and the pipe: a teleport out from there is
            -- pulled back (the body and the server apart, the character killed), and the way back in is the next train
            if name ~= "train" and (LocalPlayer:GetAttribute("InSewerCave") == true
                or (Status.inForgottenTown and Status.inForgottenTown())) then
                return false
            end
            if portal.busy then return false end
            if HW_LOCKS[name] then return true end
            if hw.topRank and hw.topRank > Control.Rank(name) then return false end
            if not inside() then
                if not inMap() then hw.strandedSince = nil return true end
                hw.strandedSince = hw.strandedSince or os.clock()
                if os.clock() - hw.strandedSince < 8 then return false end
            end
            hw.strandedSince = nil
            if not getCharacter() or carrying() then return false end
            task.spawn(function()
                hw.state = "Leaving the dimension for " .. tostring(name)
                leave()
            end)
            return false
        end)

        -- eggs
        local function meshKey(model)
            local ids = {}
            for _, part in ipairs(model:GetDescendants()) do
                if part:IsA("MeshPart") and part.MeshId ~= "" then ids[#ids + 1] = part.MeshId:match("%d+") or part.MeshId end
            end
            table.sort(ids)
            return table.concat(ids, ",")
        end
        local function rarer(a, b)
            if not (a and b) then return a or b end
            return (HW_RARITY_RANK[b] or 0) > (HW_RARITY_RANK[a] or 0) and b or a
        end
        local function rarityIndex()
            if hw.bySource then return hw.bySource, hw.byMesh end
            local bySource, byMesh = {}, {}
            local ok = pcall(function()
                local models = ReplicatedStorage.Assets.Models.Eggs
                for _, spec in pairs(require(ReplicatedStorage.Data.HalloweenPets).Specs) do
                    if type(spec) == "table" and spec.Rarity then
                        local zone = tonumber(spec.Zone)
                        if zone then
                            if spec.EggSource then bySource[spec.EggSource] = spec.Rarity end
                            if spec.Source and bySource[spec.Source] == nil then bySource[spec.Source] = spec.Rarity end
                        end
                        local model = spec.EggModel and models:FindFirstChild(spec.EggModel)
                        local key = model and meshKey(model)
                        if key and key ~= "" then
                            local entry = byMesh[key] or {}
                            byMesh[key] = entry
                            entry.any = rarer(entry.any, spec.Rarity)
                            if zone then entry[zone] = rarer(entry[zone], spec.Rarity) end
                        end
                    end
                end
            end)
            if ok then hw.bySource, hw.byMesh = bySource, byMesh end
            return bySource, byMesh
        end
        local function eggRarity(egg)
            local bySource, byMesh = rarityIndex()
            local source = egg:GetAttribute("PreparedSourceName")
            if source and bySource[source] then return bySource[source] end
            if hw.rarityCache[egg] then return hw.rarityCache[egg] end
            local entry = byMesh[meshKey(egg)]
            local zone = tonumber(egg:GetAttribute("Zone"))
            local rarity = entry and (zone and entry[zone] or entry.any)
            hw.rarityCache[egg] = rarity
            return rarity
        end
        local function rarityOptions()
            local present = {}
            for _, rarity in pairs((rarityIndex())) do present[rarity] = true end
            local options = {}
            for _, name in ipairs(HW_RARITY_ORDER) do
                if present[name] then options[#options + 1] = name end
            end
            return #options > 0 and options or { "Epic", "Legendary", "Mythic", "Cosmic", "Secret", "Eternal", "Divine" }
        end
        local function zoneOpen(zone, position)
            if zone ~= 3 or flag("ManorGateTimerEnabled", false) ~= true then return true end
            if workspace:GetServerTimeNow() >= (tonumber(flag("ManorGateUnlockTime", 0)) or 0) then return true end
            local manor = type(save().HalloweenDimension) == "table" and save().HalloweenDimension.Manor
            if type(manor) == "table" and manor.GateUnlocked == true then return true end
            local model = hwMap()
            local gate = model and model:FindFirstChild("CastleGate")
            if not gate then return true end
            local gateZ = gate:GetPivot().Position.Z
            return position ~= nil and (position.Z - gateZ) * (HW_SAFE.Z - gateZ) > 0 and math.abs(position.Z - gateZ) > 5
        end
        local function takeEgg(egg)
            local net = remotes()
            local uid = egg:GetAttribute("HalloweenEggUid")
            if not (net and net.AskCarryEgg and type(uid) == "string") then return false end
            local ok, took = pcall(function() return net.AskCarryEgg:InvokeServer(uid) end)
            return ok and took and true or false
        end
        local function eggWanted(egg)
            local zone = tonumber(egg:GetAttribute("Zone"))
            local position = zone and egg:GetPivot().Position
            if not (zone and hw.eggZones[zone] and insideMap(position) and zoneOpen(zone, position)) then return nil end
            local rarity = eggRarity(egg)
            if next(hw.rarities) ~= nil and rarity ~= nil and not hw.rarities[rarity] then return nil end
            return zone, rarity
        end
        local function pickEgg()
            local model = hwMap()
            local folder = model and model:FindFirstChild("WorldEggs")
            if not (folder and getCharacter()) then return nil end
            -- an egg we failed on stays the target until it is ours; it comes back as a new model with the
            -- same uid, so wait for it instead of moving on to another egg
            if hw.stickTo then
                local stuck
                for _, egg in ipairs(folder:GetChildren()) do
                    if egg:GetAttribute("HalloweenEggUid") == hw.stickTo then stuck = egg break end
                end
                if stuck and eggWanted(stuck) then
                    if stuck:GetAttribute("HalloweenEggCanPickUp") == true then
                        hw.stuckSince = nil
                        return stuck
                    end
                    hw.stuckSince = hw.stuckSince or os.clock()
                    if os.clock() - hw.stuckSince < 30 then return nil, true end
                end
                hw.stickTo, hw.stuckSince = nil, nil
            end
            local filtered = next(hw.rarities) ~= nil
            local best, bestScore
            for _, egg in ipairs(folder:GetChildren()) do
                local zone, rarity = eggWanted(egg)
                if zone and egg:GetAttribute("HalloweenEggCanPickUp") == true then
                    local tier = filtered and (rarity and HW_RARITY_RANK[rarity] or #HW_RARITY_ORDER + 1) or 0
                    local score = tier * 1000 + flag("TokensEggZone" .. zone, ({ 25, 50, 100 })[zone])
                    if not bestScore or score > bestScore then best, bestScore = egg, score end
                end
            end
            return best
        end
        local function findEgg(uid)
            local model = hwMap()
            local folder = model and model:FindFirstChild("WorldEggs")
            for _, egg in ipairs(folder and folder:GetChildren() or {}) do
                if egg:GetAttribute("HalloweenEggUid") == uid then return egg end
            end
            return nil
        end
        -- rarity of the best Halloween egg we would go for now (1..10 like Auto Steal; an egg we cannot
        -- name counts as special and outranks them all)
        function Status.hwBestEggRank()
            -- (same conditions as the egg job itself: when it would not go in, Auto Steal must not wait for it)
            if not (hw.eggs and eligible()) or resetting() or eventSoon("hweggs") then return nil end
            if not inDimension() and resetting(20) then return nil end
            local egg = hw.stickTo and findEgg(hw.stickTo)
            if not (egg and eggWanted(egg)) then egg = pickEgg() end
            if not egg then return nil end
            local rarity = eggRarity(egg)
            return rarity and HW_RARITY_RANK[rarity] or #HW_RARITY_ORDER + 1
        end
        local function relaySpots()
            local model = hwMap()
            local zones = model and model:FindFirstChild("Zones")
            local safe = zones and zones:FindFirstChild("SafeZone")
            local first = zones and zones:FindFirstChild("Zone1")
            if not (safe and first) then return nil end
            local sign = first.Position.Z > safe.Position.Z and 1 or -1
            local edgeZ = safe.Position.Z + sign * safe.Size.Z / 2
            return Vector3.new(HW_SAFE.X, HW_SAFE.Y, edgeZ + sign * 15), Vector3.new(HW_SAFE.X, HW_SAFE.Y, edgeZ - sign * 18)
        end
        -- a carry the server counts has to take about as long as walking it: an egg from another zone is dropped just
        -- outside the safe zone and taken again (the last stretch is short); a zone 1 egg would go back to its nest
        -- when dropped in its own zone, so it waits at the edge for the walk time instead
        local function relayHome(uid, zone, from, done)
            local out, safeSpot = relaySpots()
            local net = remotes()
            if not (out and uid and net and net.AskDropEgg) then return end
            if zone == zoneAt(out) then
                hw.state = "Bringing the egg home (at walking pace)"
                local _, _, humanoid = getCharacter()
                local walkTime = flatGap(from, safeSpot) / math.max(humanoid and humanoid.WalkSpeed or 16, 16)
                local spot = jump(out)
                if not (spot and pin(CFrame.new(spot), walkTime + 0.3, function() return carrying() and inside() end)) then return end
                spot = jump(safeSpot)
                if spot then holdAndAsk(spot, 2.5, nil, function() return inside() and not done() end) end
                return
            end
            hw.state = "Bringing the egg home (drop at the safe zone, take again)"
            local deadline, dropped = os.clock() + 15, false
            while hw.live and inside() and os.clock() < deadline do
                if carrying() then
                    if dropped then break end
                    local spot = jump(out)
                    if not spot then return end
                    local holding = function() return carrying() and inside() end
                    holdUntilCalm(spot, holding)
                    holdAndAsk(spot, 3, function() net.AskDropEgg:InvokeServer() end, holding)
                    dropped = not carrying()
                else
                    local egg = findEgg(uid)
                    if not (egg and waitFor(function() return egg.Parent ~= nil and egg:GetAttribute("HalloweenEggCanPickUp") == true end, 1)) then
                        return
                    end
                    local at = egg:GetPivot().Position
                    local spot = jump(beside(at, 3), at)
                    if not spot then return end
                    holdAndAsk(facing(spot, at), 3, function() return takeEgg(egg) end,
                        function() return not carrying() and inside() and egg.Parent ~= nil end)
                    waitFor(carrying, 0.25)
                    dropped = dropped and flatGap(at, out) < 12
                end
            end
            local spot = carrying() and inside() and jump(safeSpot)
            if spot then holdAndAsk(spot, 2.5, nil, function() return inside() and not done() end) end
        end
        local function stealEgg(egg, keepGoing)
            local zone = tonumber(egg:GetAttribute("Zone")) or 0
            local position = egg.Parent and egg:GetPivot().Position
            if not position then return false end
            if resetting(6) or eventSoon("hweggs", 6) then
                hw.state = "Egg reset / event soon: no new egg run"
                return false
            end
            local function stillThere()
                return keepGoing() and inside() and egg.Parent ~= nil and egg:GetAttribute("HalloweenEggCanPickUp") == true
            end
            hw.state = string.format("Taking a Zone %d egg", zone)
            hw.stickTo = egg:GetAttribute("HalloweenEggUid")
            local spot = jump(beside(position, 3), position)
            if not spot then return false end
            local pinFor = hw.pickPin
            holdAndAsk(facing(spot, position), 10, function() return takeEgg(egg) end,
                function() return stillThere() and not carrying() end, 0.25, pinFor)
            waitFor(carrying, 0.25)
            if not carrying() then return false end
            Control.SetFirm("hweggs")
            local function failures()
                return counter("HalloweenLost") + counter("HalloweenSeized") + counter("HalloweenKnocked") + counter("HalloweenDropped")
            end
            local delivered, failed, lost = counter("HalloweenDelivered"), failures(), counter("HalloweenLost")
            local function settled() return counter("HalloweenDelivered") ~= delivered or failures() ~= failed end
            relayHome(egg:GetAttribute("HalloweenEggUid"), zone, position, settled)
            waitFor(settled, 2)
            if counter("HalloweenDelivered") > delivered then
                hw.stickTo, hw.stuckSince = nil, nil
                hw.delivered = hw.delivered + 1
                hw.pickPin = math.max(0.3, pinFor - 0.1)
                return true
            end
            if counter("HalloweenLost") > lost then hw.pickPin = math.min(1.2, pinFor + 0.3) end
            hw.failed = hw.failed + 1
            return false
        end

        -- monsters, pumpkins, egg shop
        local function monsterAlive(monster)
            return monster.Parent ~= nil and monster:GetAttribute("KilledBy") == nil and monster:FindFirstChild("HumanoidRootPart") ~= nil
        end
        local function pickMonster(nearWater)
            local model = hwMap()
            local folder = model and model:FindFirstChild("Monsters")
            local _, root = getCharacter()
            if not (folder and root) then return nil end
            local best, bestGap
            for _, monster in ipairs(folder:GetChildren()) do
                if monsterAlive(monster) and hw.sizes[monster:GetAttribute("MonsterSize") or ""]
                    and (hw.badMonster[monster.Name] or 0) < os.clock() then
                    local position = monster.HumanoidRootPart.Position
                    local zone = insideMap(position) and zoneAt(position)
                    if zone and zone > 0 and hw.monsterZones[zone] and zoneOpen(zone, position)
                        and (not nearWater or fs.nearWater(position)) then
                        local gap = (position - root.Position).Magnitude
                        if not bestGap or gap < bestGap then best, bestGap = monster, gap end
                    end
                end
            end
            return best
        end
        do
            local conn = LocalPlayer.CharacterAdded:Connect(function()
                if hw.hunting and os.clock() - (hw.huntingAt or 0) < 15 then
                    hw.badMonster[hw.hunting.Name] = os.clock() + 90
                end
                hw.hunting = nil
            end)
            table.insert(_G.LynxSAE.Stoppers, function() conn:Disconnect() end)
        end
        do
            local side, rules, water = { phase = "idle", nextLook = 0 }, nil, { map = nil, points = {} }
            local function fishingRules()
                if rules == nil then
                    local ok, value = pcall(require, ReplicatedStorage.Shared.Util.Fishing)
                    rules = ok and type(value) == "table" and type(value.Probe) == "function" and value or false
                end
                return rules or nil
            end
            local function mapWater()
                local model = hwMap()
                if not model or water.map == model then return end
                water.map, water.points = model, {}
                task.spawn(function()
                    local points, seen, skip, probes = {}, {}, { LocalPlayer.Character }, 0
                    local tags = game:GetService("CollectionService")
                    local bossPortal = model:FindFirstChild("BossPortal")
                    local portalAt = bossPortal and bossPortal:GetPivot().Position
                    for _, part in ipairs(model:GetDescendants()) do
                        if part:IsA("BasePart") and (part:GetAttribute("TerrainRole") == "Basin"
                            or part:GetAttribute("FishingWater") == true or tags:HasTag(part, "FishingWater")) then
                            for x = -part.Size.X / 2, part.Size.X / 2, 20 do
                                for z = -part.Size.Z / 2, part.Size.Z / 2, 20 do
                                    local at = part.CFrame:PointToWorldSpace(Vector3.new(x, 0, z))
                                    local key = math.floor(at.X / 20) .. "," .. math.floor(at.Z / 20)
                                    if not seen[key] then
                                        seen[key] = true
                                        local ok, probe = pcall(rules.Probe, at, skip)
                                        if ok and type(probe) == "table" and probe.Water == true
                                            and not (portalAt and (probe.Point - portalAt).Magnitude < 60) then
                                            points[#points + 1] = { at = probe.Point, zone = zoneAt(probe.Point) }
                                        end
                                        probes = probes + 1
                                        if probes % 60 == 0 then task.wait() end
                                    end
                                end
                            end
                        end
                    end
                    if water.map == model then water.points = points end
                end)
            end
            local function nearestWater(at)
                local best, bestGap, far, farGap
                local zone = zoneAt(at)
                for _, point in ipairs(water.points) do
                    local gap = Vector3.new(point.at.X - at.X, 0, point.at.Z - at.Z).Magnitude
                    if gap <= 300 and (not bestGap or gap < bestGap) and (gap <= 36 or point.zone == zone) then
                        best, bestGap = point.at, gap
                    elseif point.zone ~= nil and gap <= 350 and (not farGap or gap < farGap) then
                        far, farGap = point.at, gap
                    end
                end
                if best then return best, bestGap end
                return far, farGap
            end
            function fs.nearWater(position)
                if not (fs.enabled and fs.withMonsters and findTool("GhostDogRod") and fishingRules()) then return true end
                mapWater()
                if #water.points == 0 then return true end
                return nearestWater(position) ~= nil
            end
            function fs.sideBusy() return side.phase == "arming" or side.phase == "casting" or side.phase == "reeling" end
            function fs.sideStep()
                if not (fs.enabled and fs.withMonsters) then return end
                local net, rod = remotes("Fishing"), findTool("GhostDogRod")
                local _, root, humanoid = getCharacter()
                if not (net and rod and root and humanoid and fishingRules()) then return end
                local now = os.clock()
                if side.phase == "idle" then
                    if now < side.nextLook then return end
                    side.phase, side.heldAt, side.nextLook = "charging", now, 0
                    pcall(function() net.Hold:FireServer() end)
                elseif side.phase == "charging" then
                    mapWater()
                    if now - side.heldAt > 1.45 then
                        side.heldAt = now
                        pcall(function() net.Hold:FireServer() end)
                        return
                    end
                    if now < side.nextLook then return end
                    side.nextLook = now + 0.05
                    local point, gap = nearestWater(root.Position)
                    if not point then return end
                    local delay = gap <= 36 and 0.14 or 0.35
                    local castAt = now - side.heldAt + delay
                    if castAt < 0.3 then return end
                    if fs.perfect then
                        local ok, perfect = pcall(function() return rules.IsPerfect(rules.ChargeAt(castAt)) end)
                        if not (ok and perfect) then return end
                    end
                    side.phase, side.point, side.delay, side.armedAt = "arming", point, delay, now
                    if gap > 36 then
                        local away = Vector3.new(root.Position.X - point.X, 0, root.Position.Z - point.Z)
                        jump(point + (away.Magnitude > 1 and away.Unit or Vector3.xAxis) * 24, point)
                    end
                    pcall(function() humanoid:EquipTool(rod) end)
                elseif side.phase == "arming" and now - side.armedAt >= side.delay then
                    side.phase = "casting"
                    task.spawn(function()
                        local ok, session, why = pcall(function() return net.Cast:InvokeServer(os.clock() - side.heldAt, side.point) end)
                        fs.casts = fs.casts + 1
                        if ok and type(session) == "table" and session.Id and session.Mode == "Fish" then
                            side.session, side.dueAt, side.phase = session, os.clock() + (tonumber(session.Wait) or 3) + 1.05, "waiting"
                            fs.status = "Fishing while hunting monsters"
                            return
                        end
                        if ok and type(session) == "table" and session.Id then
                            pcall(function() net.Cancel:FireServer(session.Id) end)
                        else
                            fs.status = "Cast refused: " .. tostring(why or session)
                        end
                        side.phase, side.nextLook = "idle", os.clock() + 1
                    end)
                elseif side.phase == "waiting" and now >= side.dueAt - 0.15 then
                    side.phase = "reeling"
                    pcall(function() humanoid:EquipTool(rod) end)
                    task.spawn(function()
                        task.wait(0.15)
                        local ok, caught, reward = pcall(function() return net.Reel:InvokeServer(side.session.Id, "Caught", 16) end)
                        if ok and caught == true and type(reward) == "table" and fs.note then
                            fs.note(reward)
                        else
                            fs.misses = fs.misses + 1
                        end
                        side.session, side.phase = nil, "idle"
                    end)
                end
            end
            function fs.sideFinish(keepGoing)
                if side.phase == "charging" then side.phase = "idle" end
                local deadline = os.clock() + 8
                while side.phase ~= "idle" and os.clock() < deadline and keepGoing() do
                    fs.sideStep()
                    RunService.Heartbeat:Wait()
                end
                if side.phase == "waiting" and side.session then
                    local net = remotes("Fishing")
                    local id = side.session.Id
                    if net then pcall(function() net.Cancel:FireServer(id) end) end
                    side.session, side.phase = nil, "idle"
                end
            end
        end
        local function killMonster(monster, keepGoing)
            local part = monster:FindFirstChild("HumanoidRootPart")
            if not part then return false end
            if not Bat.Best() then
                alert("bat", "Auto Kill Monsters needs a Bat in the backpack.")
                return false
            end
            hw.state = "Hunting " .. monster.Name
            hw.hunting, hw.huntingAt = monster, os.clock()
            local giveUp, nextHop = os.clock() + 8, 0
            while keepGoing() and monsterAlive(monster) and os.clock() < giveUp do
                local character, root = getCharacter()
                if not character or pulledOut() then break end
                if not hidden() then
                    local at = part.Position
                    if not insideMap(at) then break end
                    fs.sideStep()
                    local fishing = fs.sideBusy()
                    local reach = math.clamp(Bat.ServerRange() * 0.5, 5, 14)
                    if not fishing and (at - root.Position).Magnitude > reach + 2 and os.clock() >= nextHop then
                        nextHop = os.clock() + 0.35
                        jump(beside(at, reach), at)
                    else
                        character:PivotTo(CFrame.lookAt(root.Position, Vector3.new(at.X, root.Position.Y, at.Z)))
                        root.AssemblyLinearVelocity = Vector3.zero
                    end
                    if not fishing then Bat.Swing(nil) end
                end
                RunService.Heartbeat:Wait()
            end
            if monster:GetAttribute("KilledBy") == nil then return false end
            hw.hunting = nil
            hw.kills = hw.kills + 1
            return true
        end
        local function buyEgg()
            if not hw.buy or os.clock() < hw.buyPauseUntil or tokens() < eggPrice() then return end
            local net = remotes()
            if not (net and net.AskBuyEgg) then return end
            local ok, accepted, message = pcall(function() return net.AskBuyEgg:InvokeServer() end)
            if ok and accepted then
                hw.bought = hw.bought + 1
                notify("Halloween Dimension", "Bought a Halloween Dimension Egg.", Color3.fromRGB(255, 140, 0), 3)
                return
            end
            hw.buyPauseUntil = os.clock() + 30
            alert("buy", "Egg shop: " .. tostring(ok and message or accepted or "no answer"))
        end
        local function pumpkinMoon()
            if workspace:GetAttribute("HalloweenWorldEvent") ~= "PumpkinMoon" then return nil end
            local endsAt = tonumber(workspace:GetAttribute("HalloweenWorldEventEndsAt"))
            if endsAt and workspace:GetServerTimeNow() >= endsAt then return nil end
            local model = hwMap()
            return model and model:FindFirstChild("RunawayPumpkins") or nil
        end
        local function pumpkinAt(pumpkin)
            if not pumpkin.Parent then return nil end
            if pumpkin:IsA("Model") then return pumpkin:GetPivot().Position end
            return pumpkin:IsA("BasePart") and pumpkin.Position or nil
        end
        local function catchPrompt(pumpkin)
            local catch = pumpkin:FindFirstChild("CatchPrompt", true)
            if catch and catch:IsA("ProximityPrompt") then return catch.Enabled and catch or nil end
            return nil
        end
        local function pickPumpkin(folder)
            local _, root = getCharacter()
            if not root then return nil end
            local best, bestGap
            for _, pumpkin in ipairs(folder:GetChildren()) do
                local position = pumpkinAt(pumpkin)
                local free = position ~= nil and insideMap(position) and catchPrompt(pumpkin) ~= nil
                for _, player in ipairs(free and Players:GetPlayers() or {}) do
                    local body = player ~= LocalPlayer and player.Character
                    local other = body and body:FindFirstChild("HumanoidRootPart")
                    if other and (other.Position - position).Magnitude < 6 then free = false break end
                end
                local gap = free and (position - root.Position).Magnitude
                if gap and (not bestGap or gap < bestGap) then best, bestGap = pumpkin, gap end
            end
            return best
        end
        local function holdingPumpkin() return LocalPlayer:GetAttribute("HalloweenPumpkinCarrying") == true end
        local function catchPumpkin(folder, keepGoing)
            local pumpkin = pickPumpkin(folder)
            if not pumpkin then return false end
            hw.state = "Catching a runaway pumpkin"
            local deadline, nextFire, nextHop = os.clock() + 8, 0, 0
            local lastSpot, lastAt = pumpkinAt(pumpkin), os.clock()
            while keepGoing() and not holdingPumpkin() and os.clock() < deadline do
                local spot = pumpkinAt(pumpkin)
                local _, root = getCharacter()
                if not (spot and root and insideMap(spot)) then break end
                local now = os.clock()
                local velocity = Vector3.zero
                if lastSpot and now - lastAt > 1e-3 then
                    velocity = (spot - lastSpot) / (now - lastAt)
                    velocity = Vector3.new(velocity.X, 0, velocity.Z)
                end
                lastSpot, lastAt = spot, now
                local prompt = catchPrompt(pumpkin)
                if not prompt then
                    pumpkin = pickPumpkin(folder)
                    if not pumpkin then break end
                    lastSpot, nextHop = pumpkinAt(pumpkin), 0
                else
                    local range = prompt.MaxActivationDistance
                    if (spot - root.Position).Magnitude > range - 1 and now >= nextHop then
                        nextHop = now + 0.1
                        local ahead = spot + velocity * (0.1 + ping())
                        jump(beside(ahead, 2, velocity.Magnitude > 1 and ahead + velocity.Unit or nil), ahead)
                        local _, moved = getCharacter()
                        if moved then root = moved end
                    end
                    -- ask every 0.05 s: the first asks after a jump land before the server has our new spot
                    if now >= nextFire and (spot - root.Position).Magnitude <= range + 2 then
                        nextFire = now + 0.05
                        pcall(function() prompt.HoldDuration = 0 end)
                        pcall(fireproximityprompt, prompt)
                    end
                end
                RunService.Heartbeat:Wait()
            end
            return holdingPumpkin()
        end
        local function depositPumpkin(keepGoing)
            local model = hwMap()
            local altar = model and model:FindFirstChild("Altar")
            local deposit = altar and altar:FindFirstChild("PumpkinDeposit")
            if not deposit then return false end
            hw.state = "Bringing a pumpkin to the Altar"
            local before = counter("HalloweenPumpkins")
            Control.SetFirm("halloween")
            -- touch again every 0.1 s and watch every frame: the first touches after the jump land before the
            -- server has us at the Altar, and the deposit counts the moment one gets through
            local deadline, nextHop, nextTouch = os.clock() + 3, 0, 0
            while holdingPumpkin() and os.clock() < deadline and keepGoing() do
                local _, root = getCharacter()
                if not root then break end
                if os.clock() >= nextHop and (root.Position - deposit.Position).Magnitude > 10 then
                    nextHop = os.clock() + 0.25
                    jump(deposit.Position)
                end
                if os.clock() >= nextTouch then
                    nextTouch = os.clock() + 0.1
                    task.spawn(touchPart, deposit)
                end
                RunService.Heartbeat:Wait()
            end
            if counter("HalloweenPumpkins") > before or not holdingPumpkin() then
                hw.deposits = hw.deposits + 1
                return true
            end
            return false
        end
        local function pumpkinRun(folder, keepGoing)
            while keepGoing() and pumpkinMoon() do
                if inNormalWorld() then recover() return end
                if not (holdingPumpkin() or catchPumpkin(folder, keepGoing)) then return end
                if not depositPumpkin(keepGoing) then return end
            end
        end

        -- Pumpkin King: the Boss Portal in the dimension opens twice an hour for a few minutes and takes us to
        -- PumpkinArena (Brute, then the King). Both bosses are Bat targets (BatDamagable hitboxes, like monsters);
        -- the King's shield only breaks to cannon fire, and a cannon fires once its roots are batted away
        local PK_FIGHT = { BruteIntro = true, Brute = true, BruteDown = true, KingIntro = true, King = true, Shield = true, Stunned = true }
        local PK_BAT = { Brute = true, King = true, Stunned = true }
        local PK_FIGHT_SECONDS = 240
        local function pkRequire(...)
            local node = ReplicatedStorage
            for _, name in ipairs({ ... }) do node = node and node:FindFirstChild(name) end
            if not node then return nil end
            local ok, module = pcall(require, node)
            return ok and type(module) == "table" and module or nil
        end
        local function pkArena()
            local model = workspace:FindFirstChild("PumpkinArena")
            return model and model:IsA("Model") and model or nil
        end
        local function inArena() return LocalPlayer:GetAttribute("InPumpkinArena") == true end
        -- open: seconds until it closes; closed: nil and the seconds until it opens
        local function pkWindow()
            local schedule = pkRequire("Shared", "Util", "PumpkinBossSchedule")
            local now = workspace:GetServerTimeNow()
            local ok, open, closesAt, untilOpen = pcall(function()
                return schedule.IsOpen(now), schedule.ClosesAt(now), schedule.SecondsUntilOpen(now)
            end)
            if not ok then return nil, nil end
            -- ManorInterior.GateOpen strips the calling thread of the capability to touch our (CoreGui) UI: ask it from
            -- a throwaway thread, so the status loop and the scheduler can still write their labels and notifications
            local gate
            task.spawn(function()
                local manor = pkRequire("Shared", "Util", "ManorInterior")
                local okGate, value = pcall(function() return manor.GateOpen() end)
                gate = not okGate or value ~= false
            end)
            if open and gate ~= false then return closesAt - now, nil, closesAt end
            return nil, untilOpen
        end
        local function pkBossBox(arena)
            local name = arena:GetAttribute("Boss")
            local boss = type(name) == "string" and arena:FindFirstChild(name)
            local box = boss and boss:FindFirstChild("Hitbox")
            return box and box:IsA("BasePart") and box or nil
        end
        local function pkAlive(part)
            local health = part and part.Parent and part:GetAttribute("Health")
            return type(health) == "number" and health > 0
        end
        local function pkTrapped()
            local character = LocalPlayer.Character
            return character ~= nil and character:GetAttribute("IsTrapped") == true
        end
        local function pkCannons(arena)
            -- a ready cannon (ours first, then a free one nobody stands at) and the rooted cannon closest to free
            local folder = arena:FindFirstChild("Cannons")
            local mine, free, rooted, rootHealth
            for _, cannon in ipairs(folder and folder:GetChildren() or {}) do
                local zone = cannon:IsA("Model") and cannon:FindFirstChild("OperatorZone")
                if zone and zone:IsA("BasePart") then
                    local owner = cannon:GetAttribute("OwnerUserId")
                    if cannon:GetAttribute("Ready") == true then
                        if owner == LocalPlayer.UserId then
                            mine = cannon
                        elseif owner == 0 and not free then
                            free = cannon
                        end
                    else
                        local roots = cannon:FindFirstChild("RootHitbox")
                        local health = pkAlive(roots) and roots:GetAttribute("Health")
                        if health and (not rootHealth or health < rootHealth) then rooted, rootHealth = roots, health end
                    end
                end
            end
            return mine or free, rooted
        end
        local function pkMinion(arena, near)
            local folder = arena:FindFirstChild("Minions")
            local best, bestGap
            for _, minion in ipairs(folder and folder:GetChildren() or {}) do
                local box = minion:FindFirstChild("Hitbox")
                if box and box:IsA("BasePart") and pkAlive(box) then
                    local gap = flatGap(box.Position, near)
                    if gap < 70 and (not bestGap or gap < bestGap) then best, bestGap = box, gap end
                end
            end
            return best
        end
        do
            local net = remotes("PumpkinBoss")
            if net and net.Hazard and net.Drops and net.RemoveDrops and net.Fx then
                local conns = {
                    net.Hazard.OnClientEvent:Connect(function(spec)
                        if type(spec) == "table" and spec.Id ~= nil and typeof(spec.Origin) == "Vector3" and type(spec.At) == "number" then
                            pk.hazards[spec.Id] = spec
                        end
                    end),
                    net.Drops.OnClientEvent:Connect(function(list)
                        for _, drop in ipairs(type(list) == "table" and list or {}) do
                            if type(drop) == "table" and type(drop.Id) == "string" and drop.OwnerUserId == LocalPlayer.UserId
                                and typeof(drop.Position) == "Vector3" then
                                pk.drops[drop.Id] = drop
                                pk.dropsAt = os.clock()
                            end
                        end
                    end),
                    net.RemoveDrops.OnClientEvent:Connect(function(ids)
                        for _, id in ipairs(type(ids) == "table" and ids or {}) do pk.drops[id] = nil end
                    end),
                    net.Fx.OnClientEvent:Connect(function(kind, data)
                        if kind == "Currency" and type(data) == "table" and type(data.Amount) == "number" then
                            pk.tokens = pk.tokens + data.Amount
                        end
                    end),
                }
                table.insert(_G.LynxSAE.Stoppers, function()
                    for _, conn in ipairs(conns) do pcall(function() conn:Disconnect() end) end
                end)
            end
        end
        -- a spot is unsafe when a boss attack that lands within the next moment covers it (the hit is judged
        -- by our own client, with the same shapes)
        local function pkThreatened(spot)
            local rules = pk.dodge and pkRequire("Shared", "Util", "ScrambleBossHazards")
            if not rules then return false end
            local now, lead = workspace:GetServerTimeNow(), 0.5 + ping() * 2
            for id, spec in pairs(pk.hazards) do
                local okActive, active = pcall(rules.ActiveSeconds, spec)
                local elapsed = now - spec.At
                if not okActive or elapsed > active + 0.25 then
                    pk.hazards[id] = nil
                elseif elapsed > -lead then
                    local from = math.max(elapsed, 0)
                    for step = 0, 4 do
                        local ok, hit = pcall(rules.Contains, spec, from + (active - from) * step / 4, spot, false, 4)
                        if ok and hit then return true end
                    end
                end
            end
            return false
        end
        -- the closest safe spot `gap` studs out from a hitbox (it may hover: then we hover just under it)
        local function pkSpotNear(box, gap, floorY)
            local _, root = getCharacter()
            local cf, size = box.CFrame, box.Size
            local y = math.max(floorY + 3, cf.Position.Y - size.Y / 2 - 3)
            local best, bestScore
            for _, extra in ipairs({ 0, 25, 50 }) do
                for i = 0, 15 do
                    local dir = Vector3.new(math.cos(i * math.pi / 8), 0, math.sin(i * math.pi / 8))
                    local loc = cf:VectorToObjectSpace(dir)
                    local edge = math.min(
                        math.abs(loc.X) > 1e-3 and size.X / 2 / math.abs(loc.X) or math.huge,
                        math.abs(loc.Z) > 1e-3 and size.Z / 2 / math.abs(loc.Z) or math.huge)
                    local spot = Vector3.new(cf.X, y, cf.Z) + dir * (edge + gap + extra)
                    if not pkThreatened(spot) then
                        local score = root and (spot - root.Position).Magnitude or 0
                        if not bestScore or score < bestScore then best, bestScore = spot, score end
                    end
                end
                if best then return best, extra == 0 end
            end
            return nil, false
        end
        local function pkStand(spot, face)
            local character, root = getCharacter()
            if not (character and spot) then return end
            character:PivotTo(facing(spot, face))
            root.AssemblyLinearVelocity = Vector3.zero
        end
        local function pkBat(box, arena)
            local floorY = tonumber(arena:GetAttribute("FloorY")) or box.Position.Y
            local spot, inReach = pkSpotNear(box, math.clamp(Bat.ServerRange() * 0.3, 2, 6), floorY)
            if not spot then
                local spawn = arena:FindFirstChild("PlayerSpawn")
                spot = spawn and spawn.Position + Vector3.new(0, 3, 0)
            end
            pkStand(spot, box.Position)
            if inReach then Bat.Swing(nil) end
            return inReach
        end
        -- the server only takes a shot from someone standing on the pad (a hovering, falling operator is
        -- ignored): put the character down on the floor there once and leave it standing
        local function pkCannon(cannon, arena)
            local zone = cannon:FindFirstChild("OperatorZone")
            local floorY = tonumber(arena:GetAttribute("FloorY")) or zone.Position.Y - zone.Size.Y / 2
            local king = pkBossBox(arena)
            local spot = Vector3.new(zone.Position.X, floorY + 3, zone.Position.Z)
            local _, root = getCharacter()
            if root and (flatGap(root.Position, spot) > 3 or math.abs(root.Position.Y - spot.Y) > 2) then
                pkStand(spot, king and king.Position)
                pk.nextShot = math.max(pk.nextShot, os.clock() + 0.3 + ping())
                return
            end
            local owner = cannon:GetAttribute("OwnerUserId")
            if os.clock() < pk.nextShot or (owner ~= LocalPlayer.UserId and owner ~= 0) then return end
            local net = remotes("PumpkinBoss")
            local cooldown = 1
            pcall(function() cooldown = pkRequire("Shared", "Flags", "PumpkinBossFlags").CannonFireCooldown:Get() end)
            pk.nextShot = os.clock() + cooldown + 0.05
            pk.shotId = math.max(pk.shotId + 1, math.floor(os.clock() * 10))
            pk.shots = pk.shots + 1
            pcall(function() net.CannonFire:FireServer(pk.shotId) end)
        end
        -- our candy corn on the floor (the kill reward lands a few seconds after the boss falls); a drop the
        -- server keeps refusing is given up after a few tries
        local function pkDropsPending()
            local now = workspace:GetServerTimeNow()
            for id, drop in pairs(pk.drops) do
                if (tonumber(drop.ExpiresAt) or 0) < now or (drop.tries or 0) >= 3 then
                    pk.drops[id] = nil
                else
                    return true
                end
            end
            return false
        end
        local function pkCollect(keepGoing)
            local now, net = workspace:GetServerTimeNow(), remotes("PumpkinBoss")
            for id, drop in pairs(pk.drops) do
                if pkDropsPending() and pk.drops[id] and (tonumber(drop.CollectAfter) or 0) <= now
                    and keepGoing() and not pkThreatened(drop.Position) then
                    pk.status = "Picking up candy corn"
                    drop.tries = (drop.tries or 0) + 1
                    local deadline = os.clock() + 1 + ping() * 2
                    while pk.drops[id] and os.clock() < deadline and inArena() do
                        pkStand(drop.Position + Vector3.new(0, 3, 0))
                        pcall(function() net.Collect:FireServer({ id }) end)
                        task.wait(0.2)
                    end
                    return true
                end
            end
            return false
        end
        local function pkLeave(arena)
            local exit
            for _, part in ipairs(game:GetService("CollectionService"):GetTagged("PumpkinBossExit")) do
                if part:IsA("BasePart") and part:IsDescendantOf(arena) then exit = part break end
            end
            if not exit then return false end
            pk.status = "Leaving the arena"
            local deadline = os.clock() + 6 + ping() * 4
            while inArena() and os.clock() < deadline and getCharacter() do
                pkStand(exit.Position)
                touchPart(exit)
                task.wait(0.15)
            end
            return not inArena()
        end
        local function pkEnter(keepGoing)
            if inArena() then return true end
            if not enter(keepGoing) then return false end
            local model = hwMap()
            local portalModel = model and model:FindFirstChild("BossPortal")
            local hitbox = portalModel and portalModel:FindFirstChild("Hitbox")
            if not (hitbox and hitbox:IsA("BasePart")) then pk.status = "The Boss Portal is not in the map" return false end
            local look = hitbox.CFrame.LookVector * Vector3.new(1, 0, 1)
            look = look.Magnitude > 0.1 and look.Unit or Vector3.zAxis
            -- one jump straight to the portal (like the egg runs), then stand on the spot and keep touching it
            pk.status = "Entering the Pumpkin King arena"
            local spot = jump(hitbox.Position + look * 12, hitbox.Position)
            if not spot then return false end
            holdAndAsk(facing(spot, hitbox.Position), 4 + ping() * 2, function()
                touchPart(hitbox)
                return inArena()
            end, function() return keepGoing() and not inArena() and pkWindow() ~= nil end, 0.1)
            return waitFor(inArena, 1)
        end
        -- out of the arena (exit portal, time up, a kill) the server brings us back with a transition: the dimension
        -- attribute flips first and the character lands a moment later. The next job waits for the landing, or its
        -- first jump starts from the arena and gets pulled back
        local function pkSettle()
            local function atArena()
                local _, root = getCharacter()
                return root ~= nil and pk.center ~= nil and flatGap(root.Position, pk.center) < 1500
            end
            if not atArena() then return end
            pk.status = "Back to the dimension"
            waitFor(function() return not atArena() end, 10)
            waitFor(function()
                return os.clock() - (Status.hwCrossedAt or -math.huge) >= 1 and Status.movementTrusted() ~= false
            end, 4)
        end
        -- in the arena without Auto Pumpkin King (its portal touched on the way past): out, and still until the
        -- server has put us back in the dimension (moving on before that gets pulled back into the arena)
        function hw.leaveArena()
            local arena = inArena() and pkArena()
            if not arena or pk.enabled then return false end
            hw.state = "In the Pumpkin King arena by mistake: leaving"
            pk.center = arena:GetPivot().Position
            pkLeave(arena)
            pkSettle()
            return true
        end
        local function pkFight()
            Control.Hold("pumpkinking")
            pk.fights = pk.fights + 1
            -- every move in the arena is a teleport next to the boss: fight on a cloned, hardened humanoid
            -- (like Auto Steal) so the jumps and the hits do not kill the character
            local wasBoss, endedAt, swapAt = nil, nil, 0
            local function staying() return hw.live and pk.enabled and inArena() and getCharacter() ~= nil end
            while staying() do
                if os.clock() >= swapAt then
                    swapAt = os.clock() + 1
                    Movement.SwapHumanoid()
                    Movement.HardenHumanoid()
                end
                local arena = pkArena()
                local phase = arena and arena:GetAttribute("Phase")
                local _, root = getCharacter()
                if arena then pk.center = arena:GetPivot().Position end
                if not (arena and root) then
                    pk.status = "Waiting for the arena"
                elseif pkTrapped() then
                    pk.status = "Trapped in vines: breaking free"
                    Bat.Swing(nil)
                elseif PK_FIGHT[phase] then
                    endedAt = nil
                    wasBoss = arena:GetAttribute("BossName") or wasBoss
                    local cannon, roots = pkCannons(arena)
                    local boss = pkBossBox(arena)
                    local minion = pk.minions and pkMinion(arena, root.Position)
                    if phase == "Shield" and pk.cannons and cannon then
                        pk.status = "Firing a cannon at the King's shield"
                        pkCannon(cannon, arena)
                    elseif phase == "Shield" and pk.cannons and roots then
                        pk.status = "Clearing the roots off a cannon"
                        pkBat(roots, arena)
                    elseif PK_BAT[phase] and boss then
                        pk.status = string.format("Fighting %s (%s / %s)", tostring(wasBoss or phase),
                            tostring(math.ceil(tonumber(arena:GetAttribute("Health")) or 0)), tostring(arena:GetAttribute("MaxHealth") or "?"))
                        pkBat(boss, arena)
                    elseif minion then
                        pk.status = "Popping a Pumpkin Minion"
                        pkBat(minion, arena)
                    elseif not pkCollect(staying) then
                        pk.status = phase == "Shield" and "Waiting for a cannon" or ("Waiting: " .. tostring(phase))
                        local spawn = arena:FindFirstChild("PlayerSpawn")
                        if spawn and pkThreatened(root.Position) then pkStand(spawn.Position + Vector3.new(0, 3, 0)) end
                    end
                else
                    -- before the boss rises (Waiting) or after it fell: take our candy corn, then go home
                    local endsAt = tonumber(arena:GetAttribute("EndsAt")) or 0
                    local ended = phase == "Defeated" or (endsAt > 0 and workspace:GetServerTimeNow() > endsAt)
                        or (phase == "Waiting" and wasBoss ~= nil)
                    if phase == "Defeated" and endedAt == nil then pk.wins = pk.wins + 1 end
                    endedAt = ended and (endedAt or os.clock()) or nil
                    -- the kill reward is thrown a few seconds after the boss falls: wait for it (or give up on it
                    -- after a while), pick it all up, then go home
                    local rewarded = endedAt and pk.dropsAt and pk.dropsAt >= endedAt - 1
                    if not pkCollect(staying) then
                        if endedAt and os.clock() - endedAt > 4 and not pkDropsPending()
                            and (rewarded or os.clock() - endedAt > 12) then
                            if not pkLeave(arena) then task.wait(1) end
                        else
                            pk.status = ended and "Boss down: picking up the rewards" or "Waiting for the boss to rise"
                        end
                    end
                end
                RunService.Heartbeat:Wait()
            end
            local arena = pkArena()
            if arena and inArena() and hw.live and not pk.enabled then pkLeave(arena) end
            if not inArena() then
                realHumanoid()
                pkSettle()
            end
            -- the arena resets for the next fight a little after the boss falls
            pk.retryAt = os.clock() + 5
            pk.hazards = {}
        end

        -- Phantom Express and the Ghost Dog quest
        local function questStage()
            local quest = save().GhostDogQuest
            return type(quest) == "table" and tonumber(quest.Stage) or 0, quest
        end
        -- the Manor Key is fished out of the Sewer Cave under Forgotten Town (the Phantom Express stop): in through the
        -- whirlpool there, a word with Gus the worker, then cast into the cave's pool (2.5% a catch, once per player)
        local function manorState()
            local dimension = save().HalloweenDimension
            local manor = type(dimension) == "table" and dimension.Manor
            return type(manor) == "table" and manor or {}
        end
        local function keyClaimed() return manorState().KeyClaimed == true end
        local function phantomWanted() return fs.phantom and not keyClaimed() and findTool("GhostDogRod") ~= nil end
        local function trainUnlocked()
            local train = save().TrainEvent
            return (type(train) == "table" and train.AccessUnlocked == true) or (tr.state ~= nil and tr.state.AccessUnlocked == true)
        end
        local function trainRefresh(force)
            if not force and os.clock() - tr.stateAt < 8 then return tr.state end
            local net = remotes("TrainEvent")
            local ok, _, payload = pcall(function() return net.Action:InvokeServer("Status") end)
            if ok and type(payload) == "table" then tr.state, tr.stateAt = payload, os.clock() end
            return tr.state
        end
        do
            local net = remotes("TrainEvent")
            if net and net.State and net.CaptureState then
                local conns = {
                    net.State.OnClientEvent:Connect(function(payload)
                        if type(payload) == "table" and payload.Phase then tr.state, tr.stateAt = payload, os.clock() end
                    end),
                    net.CaptureState.OnClientEvent:Connect(function(payload)
                        if type(payload) == "table" and tr.state then tr.state.Invasion = payload end
                    end),
                }
                table.insert(_G.LynxSAE.Stoppers, function()
                    for _, conn in ipairs(conns) do pcall(function() conn:Disconnect() end) end
                end)
            end
        end
        local function townBounds()
            local assets = workspace:FindFirstChild("TrainEventAssets")
            local map = assets and assets:FindFirstChild("Map")
            local markers = map and map:FindFirstChild("EventMarkers")
            local bounds = markers and markers:FindFirstChild("TownBounds")
            return bounds and bounds:IsA("BasePart") and bounds or nil
        end
        -- in Forgotten Town for real: the server's word for it and the body actually there (right after a respawn
        -- the server can still say "town" with the body put in the dimension: anything done "in town" from there
        -- walks the body clean off the map)
        local function inTown()
            local character = LocalPlayer.Character
            local flagged = (tr.state and tr.state.Phase == "Town") or (character ~= nil and character:GetAttribute("TrainEventInForgottenTown") == true)
            if not flagged then return false end
            local root = character and character:FindFirstChild("HumanoidRootPart")
            local bounds = townBounds()
            if not (root and bounds) then return false end
            local reach = bounds.Size / 2 + Vector3.new(300, 0, 300)
            local gap = root.Position - bounds.Position
            return math.abs(gap.X) <= reach.X and math.abs(gap.Z) <= reach.Z and root.Position.Y > -60
                and LocalPlayer:GetAttribute("InHalloweenDimension") ~= true
        end
        Status.inForgottenTown = function()
            local character = LocalPlayer.Character
            return character ~= nil and character:GetAttribute("TrainEventInForgottenTown") == true
        end
        local function trainPrompt(action, name)
            for _, prompt in ipairs(workspace:GetDescendants()) do
                if prompt:IsA("ProximityPrompt") and prompt:GetAttribute("TrainEventAction") == action
                    and (not name or prompt.Name == name) and not prompt:GetAttribute("TrainLocalBoarding") then
                    local parent = prompt.Parent
                    local at = parent and (parent:IsA("BasePart") and parent.Position or (parent:IsA("Attachment") and parent.WorldPosition))
                    if at then return at, prompt end
                end
            end
            return nil
        end
        local function questChase(gd, markers, keepGoing)
            local rod = findTool("GhostDogRod")
            local castSpot, castTarget = markers.CastSpot, markers.CastTarget
            tr.status = "Quest: fishing at the pier"
            local spot = castSpot.Position + Vector3.new(0, 3, 0)
            local face = CFrame.lookAt(spot, Vector3.new(castTarget.Position.X, spot.Y, castTarget.Position.Z))
            if not stepTo(spot, keepGoing) then return end
            pin(face, 0)
            equip(rod)
            local cast, seed = tryAt(face, 8, function()
                local ok, value = pcall(function() return gd.Cast:InvokeServer() end)
                return ok and type(value) == "number", value
            end, keepGoing)
            if not cast then return end
            pin(face, 1.5, keepGoing)
            local okDive, dived = pcall(function() return gd.Dive:InvokeServer() end)
            if not (okDive and dived == true) then pcall(function() gd.Abort:InvokeServer() end) return end
            Control.SetFirm("train")
            local okData, data = pcall(require, ReplicatedStorage.Data.GhostDogQuest)
            local okFlags, flags = pcall(require, ReplicatedStorage.Shared.Flags.GhostDogQuestFlags)
            local function flagOf(name, fallback)
                local ok, value = pcall(function() return flags[name]:Get() end)
                return okFlags and ok and value or fallback
            end
            local seconds, speed = flagOf("ChaseSeconds", 50), flagOf("ChaseSpeed", 58)
            tr.status = string.format("Quest: the chase (%d s)", seconds)
            local _, _, humanoid = getCharacter()
            if humanoid then humanoid.PlatformStand = true end
            local start = os.clock()
            while okData and os.clock() - start < seconds + 2 do
                local body, root = getCharacter()
                if not body then break end
                local distance = math.min((os.clock() - start) * speed, seconds * speed + 30)
                body:PivotTo(data.ChaseFrame(seed, distance) * CFrame.Angles(-1.2566370614359172, 0, 0))
                root.AssemblyLinearVelocity = Vector3.zero
                RunService.Heartbeat:Wait()
            end
            local _, _, standUp = getCharacter()
            if standUp then standUp.PlatformStand = false end
            pcall(function() gd.Claim:InvokeServer() end)
            pcall(function() gd.Surface:InvokeServer() end)
            if not waitFor(function() return questStage() >= 4 end, 2) then pcall(function() gd.Abort:InvokeServer() end) end
        end
        local function questStep(keepGoing)
            local gd = remotes("GhostDogQuest")
            local stage, quest = questStage()
            if not gd or stage >= 4 then return end
            if not enter(keepGoing) then return end
            local model = hwMap()
            local folder = model and model:FindFirstChild("GhostDogQuest")
            local markers = folder and folder:FindFirstChild("Markers")
            if not markers then return end
            local function talk(who, npc)
                local at = npc:GetPivot().Position
                return tryAt(Vector3.new(at.X + 3, at.Y + 3, at.Z), 8, function()
                    local ok, line = pcall(function() return gd.Talk:InvokeServer(who) end)
                    return ok and type(line) == "string", line
                end, keepGoing)
            end
            local dog, fisher = workspace:FindFirstChild("GhostDog"), workspace:FindFirstChild("GhostFisherman")
            if stage == 0 and dog then
                tr.status = "Quest: talking to Echo"
                talk("Dog", dog)
            elseif stage == 1 then
                local artifacts = type(quest) == "table" and quest.Artifacts or {}
                for _, id in ipairs({ "Toy", "Bone", "Collar", "Photo" }) do
                    local marker = markers:FindFirstChild("Artifact_" .. id)
                    if not artifacts[id] and marker and keepGoing() then
                        tr.status = "Quest: finding the " .. id
                        tryAt(marker.Position + Vector3.new(2, 3, 0), 8, function()
                            local ok, took = pcall(function() return gd.Collect:InvokeServer(id) end)
                            return ok and took == true
                        end, keepGoing)
                    end
                end
                if dog and keepGoing() then
                    tr.status = "Quest: bringing them to Echo"
                    talk("Dog", dog)
                end
            elseif stage == 2 and fisher then
                tr.status = "Quest: the Ghost Fisherman"
                if talk("Fisherman", fisher) then talk("Rod", fisher) end
            elseif stage == 3 then
                if findTool("GhostDogRod") and markers:FindFirstChild("CastSpot") and markers:FindFirstChild("CastTarget") then
                    questChase(gd, markers, keepGoing)
                elseif fisher then
                    talk("Rod", fisher)
                end
            end
            if questStage() >= 4 then
                notify("Phantom Express", "Ghost Dog quest done: Conductor's Ticket unlocked!", Color3.fromRGB(150, 235, 255), 5)
            end
        end
        local function suction(on)
            local net = remotes("TrainEvent")
            if tr.sucking == on or not (net and net.Suction) then return end
            tr.sucking = on
            pcall(function() net.Suction:FireServer(on) end)
        end
        local function invasion()
            local value = tr.state and tr.state.Invasion
            return type(value) == "table" and value or nil
        end
        local function pickGhost()
            local visuals = workspace:FindFirstChild("TrainGhostVisuals")
            local _, root = getCharacter()
            local best, bestGap
            for _, ghost in ipairs(visuals and root and visuals:GetChildren() or {}) do
                if ghost:IsA("Model") and ghost:GetAttribute("TrainGhost") == true and ghost:GetAttribute("OwnerUserId") == LocalPlayer.UserId then
                    local gap = (ghost:GetPivot().Position - root.Position).Magnitude
                    if not bestGap or gap < bestGap then best, bestGap = ghost, gap end
                end
            end
            return best
        end
        local function fetchVacuum(keepGoing)
            local at, prompt = trainPrompt("PickupVacuum")
            if not (at and prompt) then return end
            tr.status = "Town: picking up the vacuum"
            tryAt(at + Vector3.new(0, 3, 0), 6, function()
                pcall(fireproximityprompt, prompt, prompt.HoldDuration)
                trainRefresh(true)
                local now = invasion()
                return now ~= nil and now.VacuumOwned == true
            end, keepGoing)
        end
        local function tradeSouls(keepGoing)
            local net = remotes("TrainEvent")
            local at = trainPrompt("OpenSoulShop")
            local function canTrade()
                local shop = trainRefresh(true) and tr.state.SoulShop
                return type(shop) == "table" and shop.Enabled ~= false and (tonumber(shop.Souls) or 0) >= (tonumber(shop.Cost) or 1e9) and shop
            end
            if not (net and at and canTrade()) then return end
            tr.status = "Town: trading souls"
            pin(CFrame.new(at + Vector3.new(0, 3, 0)), roundTrip(), keepGoing)
            for _ = 1, 20 do
                local shop = canTrade()
                if not shop then break end
                local ok, done = pcall(function() return net.Action:InvokeServer("TradeSouls", shop.Cost) end)
                if ok and done then tr.trades = tr.trades + 1 else task.wait(0.5) end
            end
        end
        local function townRun(keepGoing)
            local net = remotes("TrainEvent")
            trainRefresh(true)
            local now = invasion()
            if now and not now.VacuumOwned then fetchVacuum(keepGoing) end
            local refreshedAt, seenActive, arrived = 0, false, os.clock()
            while keepGoing() and inTown() do
                if os.clock() - refreshedAt > 2 then refreshedAt = os.clock() trainRefresh(true) end
                now = invasion()
                local active = now ~= nil and now.Phase == "Active"
                seenActive = seenActive or active
                local endsAt = now and tonumber(now.EndsAt) or 0
                if endsAt > 0 and workspace:GetServerTimeNow() >= endsAt + 1 then break end
                if (seenActive and not active) or (not seenActive and os.clock() - arrived > 120) then break end
                if active and now.VacuumOwned == false then
                    suction(false)
                    fetchVacuum(keepGoing)
                end
                local ghost = active and pickGhost()
                local character, root = getCharacter()
                if not character then break end
                if not ghost then
                    suction(false)
                    tr.status = active and "Town: looking for ghosts" or "Town: waiting for the ghosts"
                    task.wait(0.25)
                else
                    tr.status = "Town: vacuuming " .. ghost.Name
                    local gp = ghost:GetPivot().Position
                    local spot = beside(gp, 11, root.Position)
                    character:PivotTo(CFrame.lookAt(Vector3.new(spot.X, gp.Y, spot.Z), gp))
                    root.AssemblyLinearVelocity = Vector3.zero
                    local vacuum = findTool("GhostVacuum")
                    if vacuum and vacuum.Parent ~= character then equip(vacuum) end
                    suction(true)
                    RunService.Heartbeat:Wait()
                end
            end
            suction(false)
            if tr.trade and keepGoing() then tradeSouls(keepGoing) end
            if net and inTown() then
                tr.status = "Town: going home"
                local at = trainPrompt("Return", "TrainReturn")
                local _, root = getCharacter()
                tryAt((at and at + Vector3.new(0, 3, 0)) or (root and root.Position) or Vector3.zero, 15, function()
                    pcall(function() net.Action:InvokeServer("Return") end)
                    trainRefresh(true)
                    return not inTown()
                end, function() return hw.live and getCharacter() ~= nil end)
            end
        end
        local function board(keepGoing)
            local net = remotes("TrainEvent")
            local ticket = findTool("ConductorTicket")
            if not net then return false end
            if not ticket and not trainUnlocked() then
                tr.status = "No Conductor's Ticket (turn on Auto Ghost Dog Quest)"
                return false
            end
            if not enter(keepGoing) then return false end
            local at = trainPrompt("Board", "TrainBoard")
            if not at then return false end
            tr.status = "Boarding the Phantom Express"
            -- one jump straight onto the platform (like the Boss Portal), not hops through the monster zones
            local spot = jump(at, nil, true) or (at + Vector3.new(0, 3, 0))
            if not pin(CFrame.new(spot), 0.3 + roundTrip(), keepGoing) then return false end
            if ticket then equip(ticket) end
            local boarded = tryAt(spot, 12, function()
                if ticket and ticket.Parent and ticket.Parent ~= LocalPlayer.Character then equip(ticket) end
                local ok, accepted = pcall(function() return net.Action:InvokeServer("Board") end)
                return ok and accepted == true
            end, keepGoing)
            if not boarded then return false end
            tr.rides = tr.rides + 1
            Control.Hold("train")
            tr.status = "Riding to Forgotten Town"
            local deadline = os.clock() + 90
            while os.clock() < deadline and hw.live and not inTown() do
                trainRefresh(true)
                task.wait(1)
            end
            return inTown()
        end
        local function rideWanted()
            local state = tr.state
            if not (state and state.ArrivalOpen == true) and not inTown() then tr.rideDone = false end
            return (tr.ride or phantomWanted()) and (inTown() or (state and state.ArrivalOpen == true and state.Phase == "Home"
                and not tr.rideDone and (findTool("ConductorTicket") ~= nil or trainUnlocked()))) or false
        end
        local function questWanted() return tr.quest and questStage() < 4 and eligible() end

        -- Instant Fishing: the pond in the dimension's safe zone. The sewer pools in the normal world carry the same
        -- tag (and are bigger), so only water inside the dimension counts, the safe zone first
        -- a water point the game counts as water inside `model` (the biggest pool, `prefer` scoring extra) and a dry
        -- shore spot towards `home` well inside the cast range
        local function waterSpot(model, home, prefer)
            if not model then return nil end
            local best, bestScore
            local ok, tagged = pcall(function() return game:GetService("CollectionService"):GetTagged("FishingWater") end)
            for _, part in ipairs(ok and tagged or {}) do
                if part:IsA("BasePart") and part:IsDescendantOf(model) and math.min(part.Size.X, part.Size.Z) >= 8 then
                    local score = (prefer and prefer(part) and 1e6 or 0) + part.Size.X * part.Size.Z
                    if not bestScore or score > bestScore then best, bestScore = part, score end
                end
            end
            if not best then return nil end
            -- a point the game itself counts as water near the middle, and a shore spot towards the safe zone well
            -- inside the cast range
            local okRules, rules = pcall(require, ReplicatedStorage.Shared.Util.Fishing)
            if not (okRules and type(rules) == "table" and type(rules.Probe) == "function") then rules = nil end
            local skip = { LocalPlayer.Character }
            local function isWater(at)
                local okProbe, probe = pcall(rules.Probe, at, skip)
                return okProbe and type(probe) == "table" and probe.Water == true and probe.Point or nil
            end
            local center, water = best.Position, nil
            for _, offset in ipairs({ Vector3.zero, Vector3.new(-6, 0, 0), Vector3.new(6, 0, 0), Vector3.new(0, 0, -6),
                Vector3.new(0, 0, 6), Vector3.new(-6, 0, -6), Vector3.new(6, 0, 6) }) do
                water = rules and isWater(center + offset)
                if water then break end
            end
            water = water or Vector3.new(center.X, center.Y + best.Size.Y / 2, center.Z)
            local away = Vector3.new(home.X - water.X, 0, home.Z - water.Z)
            away = away.Magnitude > 1 and away.Unit or Vector3.xAxis
            for _, gap in ipairs({ 24, 28, 20, 32 }) do
                local stand = water + away * gap
                if not (rules and isWater(stand)) then return water, stand end
            end
            return water, water + away * 24
        end
        local function fishingSpot()
            return waterSpot(hwMap(), HW_SAFE, function(part) return zoneAt(part.Position) == 0 end)
        end
        local fishUi, revealing = nil, false
        local function revealCatch(reward)
            if revealing then return end
            if fishUi == nil then
                local ok, ui = pcall(function() return require(ReplicatedStorage.Controllers.Game.FishingController.Ui) end)
                fishUi = ok and type(ui) == "table" and type(ui.Reveal) == "function" and ui or false
            end
            if not fishUi then return end
            revealing = true
            pcall(function()
                local sound = ReplicatedStorage.Assets.Fishing.Sounds:FindFirstChild("Catch")
                if sound and sound:IsA("Sound") then
                    require(ReplicatedStorage.Shared.Audio).Play(sound, game:GetService("SoundService"), { SoundGroup = "SFX" })
                end
            end)
            task.spawn(function()
                local okAcquire, release = pcall(fishUi.Acquire)
                pcall(fishUi.Reveal, reward, reward.Kind == "Tokens" and 1.4 or 2.6)
                if okAcquire and type(release) == "function" then pcall(release) end
                revealing = false
            end)
        end
        local function noteCatch(reward)
            fs.catches = fs.catches + 1
            revealCatch(reward)
            if Status.FishCaught then pcall(Status.FishCaught, reward) end
            if reward.Kind == "ManorKey" then
                notify("Instant Fishing", "Fished up the Manor Key!", Color3.fromRGB(150, 235, 255), 6)
            end
        end
        fs.note = noteCatch
        -- Autopilot Ghost Fish: a bite in "GhostFish" mode hands over to the Ghost Dog chase (the rare Ghost Fish
        -- pet); the plain fishing loop used to throw it back. Run the way the game's own hand-off does (Cast with
        -- the bite's id, Dive, the chase, Claim, Surface, Abort), riding the chase line as the quest chase does:
        -- the sea mines are on this screen only, the server times the chase
        local function ghostFishChase(session, face, fishing, hold)
            local gd = remotes("GhostDogQuest")
            if not gd then return nil end
            local ok, seed, why, reward = pcall(function() return gd.Cast:InvokeServer(session.Id) end)
            if not (ok and type(seed) == "number") then
                fs.status = "Ghost Fish got away: " .. tostring(why)
                return nil
            end
            fs.status = "Ghost Fish on the line!"
            hold(face, 1.5, fishing)
            local okDive, dived = pcall(function() return gd.Dive:InvokeServer() end)
            if not (okDive and dived == true) then
                pcall(function() gd.Abort:InvokeServer() end)
                fs.status = "Ghost Fish: the dive was refused"
                return nil
            end
            local okData, data = pcall(require, ReplicatedStorage.Data.GhostDogQuest)
            local okFlags, flags = pcall(require, ReplicatedStorage.Shared.Flags.GhostDogQuestFlags)
            local function flagOf(name, fallback)
                local okGet, value = pcall(function() return flags[name]:Get() end)
                return okFlags and okGet and value or fallback
            end
            local seconds, speed = flagOf("FishChaseSeconds", 25), flagOf("ChaseSpeed", 58)
            local _, _, humanoid = getCharacter()
            if humanoid then humanoid.PlatformStand = true end
            local start = os.clock()
            while okData and os.clock() - start < seconds + 2 do
                local body, root = getCharacter()
                if not body then break end
                fs.status = string.format("Autopilot Ghost Fish: %d s left", math.max(0, math.ceil(seconds - (os.clock() - start))))
                local distance = math.min((os.clock() - start) * speed, seconds * speed + 30)
                body:PivotTo(data.ChaseFrame(seed, distance) * CFrame.Angles(-1.2566370614359172, 0, 0))
                root.AssemblyLinearVelocity = Vector3.zero
                RunService.Heartbeat:Wait()
            end
            local _, _, standUp = getCharacter()
            if standUp then standUp.PlatformStand = false end
            local okClaim, claimed = pcall(function() return gd.Claim:InvokeServer() end)
            pcall(function() gd.Surface:InvokeServer() end)
            pcall(function() gd.Abort:InvokeServer() end)
            if not (okClaim and claimed == true) then
                fs.status = "Ghost Fish: the claim was refused"
                return nil
            end
            fs.ghosts = fs.ghosts + 1
            return type(reward) == "table" and reward or { Kind = "Pet", DisplayName = "Ghost Fish", Amount = 1 }
        end
        -- one rod, one water point, cast after cast for as long as `fishing` holds; `hold` keeps the body on a
        -- CFrame for a while (false when it has to stop)
        local function castLoop(net, rod, point, face, fishing, hold, lock)
            equip(rod)
            while fishing() and not (lock and Control.Blocker(lock, true)) do
                if rod.Parent ~= LocalPlayer.Character then equip(rod) end
                pcall(function() net.Hold:FireServer() end)
                local held = os.clock()
                fs.status = "Fishing"
                if fs.perfect and not hold(face, 1.09, fishing) then return end
                local ok, session, why = pcall(function() return net.Cast:InvokeServer(os.clock() - held, point) end)
                fs.casts = fs.casts + 1
                if not (ok and type(session) == "table" and session.Id) then
                    fs.status = "Cast refused: " .. tostring(why or session)
                    if not hold(face, 1, fishing) then return end
                elseif session.Mode == "GhostFish" and fs.ghost then
                    -- the bite comes after the wait like any other
                    if not hold(face, (tonumber(session.Wait) or 3) + 0.5, fishing) then
                        pcall(function() net.Cancel:FireServer(session.Id) end)
                        return
                    end
                    local reward = ghostFishChase(session, face, fishing, hold)
                    if reward then noteCatch(reward) else fs.misses = fs.misses + 1 end
                    if not hold(face, 0.5, fishing) then return end
                elseif session.Mode ~= "Fish" then
                    pcall(function() net.Cancel:FireServer(session.Id) end)
                elseif not hold(face, (tonumber(session.Wait) or 3) + 1.05, fishing) then
                    pcall(function() net.Cancel:FireServer(session.Id) end)
                    return
                else
                    local okReel, caught, reward = pcall(function() return net.Reel:InvokeServer(session.Id, "Caught", 16) end)
                    if okReel and caught == true and type(reward) == "table" then
                        noteCatch(reward)
                    else
                        fs.misses = fs.misses + 1
                    end
                end
            end
        end
        -- set by the scheduler below: the label of a higher-ranked dimension job that has work now
        local higherWork
        local function fishSession(keepGoing)
            local net = remotes("Fishing")
            local rod = findTool("GhostDogRod")
            if not (net and rod) or not enter(keepGoing) then return end
            local point, stand = fishingSpot()
            if not point then fs.status = "No fishing pond found in the dimension" return end
            fs.status = "Going to the pond"
            -- fishing only fills idle time: an egg (or anything ranked above) showing up ends it within half a second,
            -- the scheduler is stuck in here until then
            local checkAt, outranked = 0, nil
            local function fishing()
                if os.clock() >= checkAt then
                    checkAt = os.clock() + 0.5
                    outranked = higherWork and higherWork("fishing")
                end
                return keepGoing() and inside() and not outranked
            end
            local spot = arrive(stand + Vector3.new(0, 6, 0), point, roundTrip(), fishing)
            if not spot then return end
            castLoop(net, rod, point, CFrame.lookAt(spot, Vector3.new(point.X, spot.Y, point.Z)), fishing, pin, "fishing")
        end
        -- monster after monster until there is none left (or the character is low); hands the character over within
        -- half a second when a higher-ranked dimension job (a Halloween egg) gets work, cancelling the bite it waits on
        function hw.huntRun(keepGoing, lock, nearWater)
            local monster = pickMonster(nearWater)
            if not monster then return false end
            local checkAt, outranked = 0, nil
            local function hunting()
                if os.clock() >= checkAt then
                    checkAt = os.clock() + 0.5
                    outranked = higherWork and higherWork(lock)
                end
                return keepGoing() and not outranked
            end
            repeat
                killMonster(monster, hunting)
                local _, _, humanoid = getCharacter()
                monster = hunting() and humanoid and humanoid.Health > humanoid.MaxHealth * 0.35
                    and not (hw.pumpkin and pumpkinMoon()) and pickMonster(nearWater)
            until not monster
            if outranked then hw.state = outranked .. " goes first" end
            fs.sideFinish(hunting)
            return true
        end

        -- Auto Fishing Phantom Location: the Sewer Cave under Forgotten Town. The dimension's pin gives up on any
        -- server move outside its zones, so out here the body is held plainly. (Its helpers live in a block of
        -- their own: this function is at the 200-local limit)
        local function inCave() return LocalPlayer:GetAttribute("InSewerCave") == true end
        local caveRun
        do
        local function townHold(cf, seconds, keepGoing)
            local untilAt = os.clock() + seconds
            while true do
                if keepGoing and not keepGoing() then return false end
                local character, root = getCharacter()
                if not character then return false end
                character:PivotTo(cf)
                root.AssemblyLinearVelocity = Vector3.zero
                if os.clock() >= untilAt then return true end
                RunService.Heartbeat:Wait()
            end
        end
        local function caveModel()
            local assets = workspace:FindFirstChild("TrainEventAssets")
            local cave = assets and assets:FindFirstChild("SewerCave")
            return cave and cave:IsA("Model") and cave or nil
        end
        local function caveMarker(name)
            local cave = caveModel()
            local markers = cave and cave:FindFirstChild("Markers")
            local part = markers and markers:FindFirstChild(name)
            return part and part:IsA("BasePart") and part or nil
        end
        local function whirlpool()
            local ok, tagged = pcall(function() return game:GetService("CollectionService"):GetTagged("SewerCaveWhirlpool") end)
            for _, item in ipairs(ok and tagged or {}) do
                if item:IsA("Model") or item:IsA("BasePart") then return item end
            end
            local assets = workspace:FindFirstChild("TrainEventAssets")
            local map = assets and assets:FindFirstChild("Map")
            local marks = map and map:FindFirstChild("Landmarks")
            return marks and marks:FindFirstChild("Steal an Egg Whirlpool") or nil
        end
        -- a server move that lands neither in town nor down in the cave
        local function thrownOut(position)
            local bounds = townBounds()
            if bounds then
                local reach = bounds.Size / 2 + Vector3.new(300, 0, 300)
                local gap = position - bounds.Position
                if math.abs(gap.X) <= reach.X and math.abs(gap.Z) <= reach.Z and position.Y > -60 then return false end
            end
            local cave = caveMarker("Bounds") or caveMarker("Spawn")
            if cave and (position - cave.Position).Magnitude < 250 then return false end
            return true
        end
        -- across town at a running pace (measured: hops at ~330 studs/s got us thrown out of town to the plots).
        -- A server move away from the line means we were thrown out: stop right there, never chase it (chasing a
        -- town spot from the plots or the dimension walks the body off the map)
        local function townStep(position, keepGoing)
            local _, root, humanoid = getCharacter()
            if not root then return false end
            local speed = math.clamp((humanoid and humanoid.WalkSpeed or 100) * 0.8, 60, 240)
            local from = root.Position
            local flatLine = Vector3.new(position.X - from.X, 0, position.Z - from.Z)
            local length = flatLine.Magnitude
            if length <= 6 then return true end
            local dir = flatLine.Unit
            local facing = CFrame.lookAt(from, from + dir).Rotation
            local since, gone = os.clock(), 0
            while gone < length do
                local dt = math.min(RunService.RenderStepped:Wait(), 1 / 30)
                if keepGoing and not keepGoing() then return false end
                local moved = hw.relocated
                if moved and moved.at >= since and thrownOut(moved.pos) then
                    fs.phantomStatus = "Thrown out of town by the server"
                    return false
                end
                local character, body = getCharacter()
                if not character then return false end
                gone = math.min(gone + speed * dt, length)
                local at = from + dir * gone
                at = Vector3.new(at.X, Movement.StandSpot(at, body.Position.Y - at.Y).Y, at.Z)
                body.CFrame = CFrame.new(at) * facing
                body.AssemblyLinearVelocity = gone < length and dir * speed or Vector3.zero
            end
            return true
        end
        function caveRun(keepGoing)
            local net, rod, gd = remotes("Fishing"), findTool("GhostDogRod"), remotes("SewerCave")
            if not (net and rod and gd) then return end
            -- 1) into the cave: standing in the whirlpool, the server sends us down (its own transition)
            if not inCave() then
                if not inTown() then return end
                local pool = whirlpool()
                if not pool then fs.phantomStatus = "No sewer whirlpool in town" return end
                local at = (pool:IsA("Model") and pool:GetPivot() or pool.CFrame).Position
                -- once the server starts its transition (it can start on the last step of the run there) the game moves
                -- the body down itself: holding it on the whirlpool after that drags it back up from the cave (snapback,
                -- the character killed)
                local travelling = false
                local okTravel, travel = pcall(function()
                    return gd.Travel.OnClientEvent:Connect(function(kind) if kind == "Enter" then travelling = true end end)
                end)
                fs.phantomStatus = "Going to the sewer whirlpool"
                if not townStep(at, function() return keepGoing() and not travelling end) and not travelling then
                    if okTravel and travel then travel:Disconnect() end
                    return
                end
                fs.phantomStatus = "Into the whirlpool"
                local deadline, since = os.clock() + 20, os.clock()
                while not inCave() and os.clock() < deadline do
                    local moved = hw.relocated
                    if moved and moved.at >= since and thrownOut(moved.pos) then
                        fs.phantomStatus = "Thrown out of town by the server"
                        break
                    end
                    if travelling then
                        fs.phantomStatus = "Going down the whirlpool"
                        task.wait(0.1)
                    elseif not townHold(CFrame.new(at + Vector3.new(0, 2, 0)), 0.1, keepGoing) then
                        break
                    end
                end
                if okTravel and travel then travel:Disconnect() end
                if not inCave() then fs.phantomStatus = "The whirlpool did not take us down" return end
                -- the transition puts us at the cave's spawn: let it land
                local settle = os.clock() + 8
                local spawn = caveMarker("Spawn")
                while os.clock() < settle and keepGoing() do
                    local _, root = getCharacter()
                    if root and spawn and (root.Position - spawn.Position).Magnitude < 40 then break end
                    task.wait(0.2)
                end
                task.wait(1)
            end
            local function stillHere() return keepGoing() and inCave() and fs.phantom and not keyClaimed() end
            -- out through the pipe (Gus: it goes back to the manor): with the key, or with the feature turned off.
            -- The cave outlasts the town (measured: still down there after the train went home), so nothing else
            -- brings us out
            local function leaveCave()
                local pipe = caveMarker("Pipe")
                if not (pipe and inCave()) then return end
                fs.phantomStatus = keyClaimed() and "Manor Key fished up! Out through the pipe" or "Out of the Sewer Cave through the pipe"
                local deadline, travelling = os.clock() + 15, false
                local okTravel, travel = pcall(function()
                    return gd.Travel.OnClientEvent:Connect(function(kind) if kind == "Exit" then travelling = true end end)
                end)
                while inCave() and os.clock() < deadline do
                    if travelling then
                        task.wait(0.1)
                    elseif not townHold(pipe.CFrame, 0.1, keepGoing) then
                        break
                    end
                end
                if okTravel and travel then travel:Disconnect() end
            end
            if not stillHere() then
                if keepGoing() then leaveCave() end
                return
            end
            -- 2) a word with Gus first: the key only comes up for a player who met him
            if manorState().Met ~= true then
                local npc = caveMarker("Npc")
                if npc then
                    fs.phantomStatus = "Talking to Gus"
                    townHold(CFrame.new(npc.Position + Vector3.new(3, 3, 0)), 0.6, stillHere)
                    pcall(function() gd.MetWorker:FireServer() end)
                    townHold(CFrame.new(npc.Position + Vector3.new(3, 3, 0)), 1, stillHere)
                end
            end
            -- 3) fish the cave's pool from its shore
            local home = (caveMarker("Spawn") or caveMarker("Npc"))
            local point, stand = waterSpot(caveModel(), home and home.Position or Vector3.zero)
            if not point then fs.phantomStatus = "No water found in the Sewer Cave" return end
            local spot = Movement.StandSpot(stand)
            local face = CFrame.lookAt(spot, Vector3.new(point.X, spot.Y, point.Z))
            fs.phantomStatus = "Fishing for the Manor Key"
            townHold(face, 0.3 + roundTrip(), stillHere)
            castLoop(net, rod, point, face, stillHere, townHold, nil)
            -- 4) done (the key, or turned off): out through the pipe
            if keepGoing() and not stillHere() then leaveCave() end
        end
        end

        -- scheduler: every loop picks the highest-ranked job with work and runs one step of it
        local function anyHalloween() return hw.eggs or hw.monsters or hw.pumpkin end
        local function mmss(seconds)
            seconds = math.max(0, math.ceil(seconds or 0))
            return string.format("%02d:%02d", seconds // 60, seconds % 60)
        end
        local JOBS = {
            {
                lock = "pumpkinking",
                setState = function(text) pk.status = text end,
                force = inArena,
                heldOffOk = function() return not inArena() end,
                -- the portal takes us again for a new fight as long as it is open; while the arena closes
                -- after a kill it refuses, so a refused entry waits a few seconds before the next try. A fight
                -- is never cut short (it holds the lock), so none starts with a Shooting Star about to land
                work = function()
                    if not pk.enabled then return false end
                    if inArena() then return true end
                    local left = pkWindow()
                    return eligible() and left ~= nil and left > 8 and os.clock() >= (pk.retryAt or 0)
                        and not eventSoon("pumpkinking", PK_FIGHT_SECONDS)
                end,
                step = function(keepGoing)
                    if not inArena() and not pkEnter(keepGoing) then
                        pk.retryAt = os.clock() + 4
                        return
                    end
                    pkFight()
                end,
                idleText = function()
                    if not pk.enabled then return "Off" end
                    if not eligible() then return "Needs 2.5M Speed Power for the Halloween Dimension" end
                    local left, untilOpen = pkWindow()
                    local event = left and eventSoon("pumpkinking", PK_FIGHT_SECONDS)
                    if event then return "Waiting: " .. event .. " goes first" end
                    if left and os.clock() < (pk.retryAt or 0) then return "Waiting for the arena to reset" end
                    if untilOpen then return "Boss Portal opens in " .. mmss(untilOpen) end
                    return nil
                end,
            },
            {
                lock = "hweggs",
                setState = function(text) hw.state = text end,
                work = function()
                    if not (hw.eggs and eligible()) or eventSoon("hweggs") or resetting() then return false end
                    if not inDimension() and resetting(20) then return false end
                    local egg, waiting = pickEgg()
                    if not (egg or waiting) then return false end
                    -- rarest egg first across both worlds: a rarer egg on the normal field goes first
                    local mine, theirs = Status.hwBestEggRank(), Status.stealBestRank and Status.stealBestRank()
                    if mine and theirs and theirs > mine then return false end
                    -- the normal field still behind its start wall: go in only with a strictly rarer egg, so
                    -- Auto Steal gives way when the wall drops instead of pulling us straight back out
                    if not inDimension() and Movement.FieldClosed() and theirs and not (mine and mine > theirs) then
                        return false
                    end
                    hw.workAt = os.clock()
                    return true
                end,
                step = function(keepGoing)
                    if not enter(keepGoing) then return end
                    recover()
                    if not heal(keepGoing) then return end
                    local egg, waiting = pickEgg()
                    if egg then
                        stealEgg(egg, keepGoing)
                    elseif waiting then
                        hw.state = "Waiting for the failed egg to come back"
                        goSafe(0.3)
                    end
                end,
                idleText = function() return nil end,
            },
            {
                lock = "halloween",
                setState = function(text) hw.state = text end,
                work = function()
                    if not (anyHalloween() and eligible()) then return false end
                    if eventSoon("halloween") then return inDimension() and not carrying() end
                    if resetting() then return inside() end
                    if not inDimension() and resetting(20) and not (hw.pumpkin and pumpkinMoon()) then return false end
                    if (hw.pumpkin and pumpkinMoon()) or (hw.monsters and pickMonster()) then
                        hw.workAt = os.clock()
                        return true
                    end
                    return hw.monsters and inside() and os.clock() - hw.workAt < 2
                end,
                step = function(keepGoing)
                    local event = eventSoon("halloween")
                    if event then
                        hw.state = event .. " goes first: leaving the dimension"
                        leave()
                        return
                    end
                    if resetting() then
                        hw.state = "Egg reset: waiting in the safe zone"
                        goSafe(0.5)
                        return
                    end
                    if not enter(keepGoing) then return end
                    recover()
                    if not heal(keepGoing) then return end
                    local pumpkins = hw.pumpkin and pumpkinMoon()
                    if pumpkins then pumpkinRun(pumpkins, keepGoing) return end
                    if hw.monsters and hw.huntRun(keepGoing, "halloween", false) then return end
                    hw.state = "Waiting for eggs / monsters"
                    goSafe(0.5)
                end,
                idleText = function()
                    local event = anyHalloween() and eventSoon("halloween")
                    return not (anyHalloween() or hw.buy) and "Off"
                        or (event and ("Waiting: " .. event .. " goes first"))
                        or (resetting() and "Egg reset: waiting")
                        or "Idle (nothing to do)"
                end,
            },
            {
                lock = "train",
                setState = function(text) tr.status = text end,
                force = function() return inTown() or inCave() end,
                heldOffOk = function() return questWanted() and not rideWanted() end,
                work = function()
                    if inCave() then return true end
                    if not (tr.quest or tr.ride or phantomWanted()) then return false end
                    pcall(trainRefresh)
                    return questWanted() or rideWanted()
                end,
                step = function(keepGoing)
                    if inCave() or inTown() or rideWanted() then
                        if inCave() or inTown() or board(keepGoing) then
                            realHumanoid()
                            Control.Hold("train")
                            local live = function() return hw.live and getCharacter() ~= nil end
                            -- Phantom Location fishing first (the Manor Key), the ghost invasion with what is left
                            if inCave() or phantomWanted() then caveRun(live) end
                            if inTown() and not inCave() then townRun(live) end
                            tr.rideDone = not inTown()
                        end
                    else
                        questStep(keepGoing)
                    end
                    suction(false)
                end,
                idleText = function()
                    local riding = tr.ride or phantomWanted()
                    return not (tr.quest or riding) and "Off"
                        or (riding and not findTool("ConductorTicket") and not trainUnlocked() and "No Conductor's Ticket left")
                        or (riding and tr.rideDone and "Rode this train already: waiting for the next one")
                        or (riding and "Waiting for the Phantom Express")
                        or (questStage() >= 4 and "Ghost Dog quest done")
                        or nil
                end,
            },
            {
                lock = "fishing",
                idleGap = 3,
                setState = function(text) fs.status = text end,
                work = function()
                    if not (fs.enabled and findTool("GhostDogRod") ~= nil and eligible()) then return false end
                    -- fishing only fills long idle time: from outside, never hop in around an egg reset while
                    -- Auto Steal is about to take the character back out
                    if not inDimension() and Status.stealEnabled
                        and (resetting(20) or os.clock() - (hw.fieldOpenedAt or -math.huge) < 15) then
                        return false
                    end
                    return true
                end,
                step = function(keepGoing)
                    if fs.withMonsters and Bat.Best() and enter(keepGoing) then
                        recover()
                        if not heal(keepGoing) then return end
                        if hw.huntRun(keepGoing, "fishing", true) then return end
                    end
                    fishSession(keepGoing)
                end,
                idleText = function()
                    return not fs.enabled and "Off"
                        or (findTool("GhostDogRod") == nil and "Needs the Haunted Rod (Phantom Express > Auto Ghost Dog Quest)")
                        or (not eligible() and "Needs 2.5M Speed Power for the Halloween Dimension")
                        or "Idle"
                end,
            },
        }
        local LABELS = { hweggs = "Steal Halloween Eggs", halloween = "Halloween Monsters", train = "Phantom Express", fishing = "Instant Fishing", pumpkinking = "Pumpkin King" }
        local OWNER = { hweggs = "hw", halloween = "hw", train = "tr", fishing = "fs", pumpkinking = "pk" }
        local ENABLED = {
            pumpkinking = function() return pk.enabled end,
            hweggs    = function() return hw.eggs end,
            halloween = anyHalloween,
            train     = function() return tr.quest or tr.ride or fs.phantom end,
            fishing   = function() return fs.enabled end,
        }
        higherWork = function(lock)
            local mine = Control.Rank(lock)
            for _, job in ipairs(JOBS) do
                if job.lock ~= lock and Control.Rank(job.lock) > mine then
                    local ok, work = pcall(job.work)
                    if ok and work == true then return LABELS[job.lock] end
                end
            end
            return nil
        end
        local function keepGoingFor(job)
            local lock, dimensionOnly = job.lock, OWNER[job.lock] == "hw"
            return function()
                return hw.live and ENABLED[lock]() and Control.Owns(lock) and getCharacter() ~= nil
                    and not (dimensionOnly and (resetting() or eventSoon(lock)))
            end
        end
        local function showIdle(best)
            local done = { [best and OWNER[best.lock] or ""] = true }
            for _, job in ipairs(JOBS) do
                local owner = OWNER[job.lock]
                if not done[owner] then
                    local text = job.hasWork and ("Waiting: " .. LABELS[best.lock] .. " goes first") or job.idleText()
                    if text then
                        done[owner] = true
                        job.setState(text)
                    end
                end
            end
        end
        local function turn(job)
            local lock = job.lock
            local force = job.force and job.force()
            Control.Want(lock, 3)
            if force then Control.Acquire(lock, true) end
            if (not force and Control.Blocker(lock, true)) or not Control.Acquire(lock, force) then
                job.setState("Waiting for " .. tostring(Control.Blocker(lock, true) or Control.Holder() or "another feature"))
                return false
            end
            local ok, err = pcall(job.step, keepGoingFor(job))
            if not ok then job.setState("Error: " .. tostring(err)) end
            local nextFeature = Control.Blocker(lock, true)
            if nextFeature and not HW_LOCKS[nextFeature] then leave() end
            Control.Release(lock)
            return true
        end
        task.spawn(function()
            afterConfigLoad()
            while hw.live do
                pcall(buyEgg)
                local closed = resetting()
                if hw.fieldWasClosed and not closed then hw.fieldOpenedAt = os.clock() end
                hw.fieldWasClosed = closed
                local best
                for _, job in ipairs(JOBS) do
                    local ok, work = pcall(job.work)
                    job.hasWork = ok and work == true
                    if job.hasWork and (not best or Control.Rank(job.lock) > Control.Rank(best.lock)) then best = job end
                end
                hw.topRank = best and Control.Rank(best.lock) or nil
                for _, job in ipairs(JOBS) do
                    if job ~= best then
                        Control.Want(job.lock, 0)
                        if not job.hasWork then Control.Idle(job.lock) end
                    end
                end
                showIdle(best)
                local ran = false
                if best then
                    local heldOff = (not best.heldOffOk or best.heldOffOk()) and not inDimension()
                        and Control.BusyRecently(best.lock, best.idleGap or 15, HW_LOCKS)
                    if heldOff then
                        Control.Want(best.lock, 3)
                        best.setState("Waiting: " .. tostring(heldOff) .. " is busy")
                    elseif Status.stealBusy and not (best.force and best.force()) then
                        Control.Want(best.lock, 0)
                        best.setState("Waiting: Auto Steal goes first")
                    else
                        ran = turn(best)
                    end
                end
                task.wait(ran and 0.05 or 0.25)
            end
        end)
        table.insert(_G.LynxSAE.Stoppers, function()
            hw.live = false
            pcall(suction, false)
            for lock in pairs(HW_LOCKS) do
                Control.Want(lock, 0)
                Control.Release(lock)
            end
        end)

        -- UI
        local function liveStatus(section, title, text)
            local paragraph = section:AddParagraph({ Title = title, Content = "Loading..." })
            task.spawn(function()
                local last
                while hw.live do
                    local ok, value = pcall(text)
                    if ok and value ~= last then
                        last = value
                        pcall(setParagraph, paragraph, value)
                    end
                    task.wait(1)
                end
            end)
        end
        local function zoneDropdown(section, title, target)
            section:AddDropdown({
                Title = title, Multi = true, Options = HW_ZONES, Default = HW_ZONES,
                Callback = function(selected)
                    local set = toSet(type(selected) == "table" and selected or {})
                    for index, name in ipairs(HW_ZONES) do target[index] = set[name] == true end
                end,
            })
        end
        local HalloweenSection = EventTab:AddSection("Halloween Dimension")
        liveStatus(HalloweenSection, "Halloween Dimension Status", function()
            local lines = {
                "Inside: " .. (inside() and "yes" or "no")
                    .. (eligible() and "" or "  (needs " .. tostring(flag("SpeedPowerRequirement", 2.5e6)) .. " Speed Power)"),
                "Candy Corn: " .. tostring(tokens()) .. "  |  Egg price: " .. tostring(eggPrice()),
            }
            if inside() then
                local model = hwMap()
                local folder = model and model:FindFirstChild("WorldEggs")
                local counts = {}
                for _, egg in ipairs(folder and folder:GetChildren() or {}) do
                    local rarity = eggRarity(egg) or "Unknown"
                    counts[rarity] = (counts[rarity] or 0) + 1
                end
                local parts = {}
                for _, rarity in ipairs(HW_RARITY_ORDER) do
                    if counts[rarity] then parts[#parts + 1] = rarity .. " " .. counts[rarity] end
                end
                if counts.Unknown then parts[#parts + 1] = "Unknown " .. counts.Unknown end
                lines[#lines + 1] = "Eggs now: " .. (#parts > 0 and table.concat(parts, ", ") or "none (next batch soon)")
            end
            lines[#lines + 1] = string.format("This session: %d delivered, %d lost, %d kills, %d pumpkins, %d eggs bought",
                hw.delivered, hw.failed, hw.kills, hw.deposits, hw.bought)
            local event = workspace:GetAttribute("HalloweenWorldEvent")
            if event then
                local endsAt = tonumber(workspace:GetAttribute("HalloweenWorldEventEndsAt"))
                local left = endsAt and math.max(0, math.floor(endsAt - workspace:GetServerTimeNow()))
                lines[#lines + 1] = "World event: " .. tostring(event) .. (left and string.format(" (%d s left)", left) or "")
            end
            lines[#lines + 1] = "State: " .. hw.state
            return table.concat(lines, "\n")
        end)
        HalloweenSection:AddParagraph({
            Title = "How It Works",
            Content = "Needs 2.5M Speed Power. Eggs: steals every egg in the filter (empty rarity list = all).\n"
                .. "Monsters: kills them with your Bat. Pumpkin Moon: brings pumpkins to the Altar.",
        })
        HalloweenSection:AddToggle({ Title = "Steal Halloween Eggs", Default = false, Callback = function(on) hw.eggs = on == true end })
        zoneDropdown(HalloweenSection, "Egg Zones", hw.eggZones)
        HalloweenSection:AddDropdown({
            Title = "Egg Rarities", Multi = true, Options = rarityOptions(), Default = {},
            Callback = function(selected) hw.rarities = toSet(type(selected) == "table" and selected or {}) end,
        })
        HalloweenSection:AddToggle({ Title = "Auto Kill Monsters", Default = false, Callback = function(on) hw.monsters = on == true end })
        zoneDropdown(HalloweenSection, "Monster Zones", hw.monsterZones)
        HalloweenSection:AddDropdown({
            Title = "Monster Sizes", Multi = true, Options = HW_SIZES, Default = HW_SIZES,
            Callback = function(selected)
                local set = toSet(type(selected) == "table" and selected or {})
                for _, name in ipairs(HW_SIZES) do hw.sizes[name] = set[name] == true end
            end,
        })
        HalloweenSection:AddToggle({ Title = "Auto Pumpkin Moon", Default = false, Callback = function(on) hw.pumpkin = on == true end })
        HalloweenSection:AddToggle({
            Title = "Auto Buy Halloween Dimension Egg", Default = false,
            Callback = function(on) hw.buy, hw.buyPauseUntil = on == true, 0 end,
        })
        HalloweenSection:AddButton({
            Title = "Leave Halloween Dimension",
            Callback = function()
                task.spawn(function()
                    if anyHalloween() then
                        notify("Halloween Dimension", "Turn off Steal Halloween Eggs, Auto Kill Monsters and Auto Pumpkin Moon first.", Color3.fromRGB(255, 140, 0), 3)
                    elseif not leave() then
                        notify("Halloween Dimension", "Could not leave, try again.", Color3.fromRGB(255, 90, 90), 3)
                    end
                end)
            end,
        })
        local TrainSection = EventTab:AddSection("Phantom Express")
        liveStatus(TrainSection, "Phantom Express Status", function()
            local quest = type(save().GhostDogQuest) == "table" and save().GhostDogQuest or {}
            local train = type(save().TrainEvent) == "table" and save().TrainEvent or {}
            local found = 0
            for _, got in pairs(type(quest.Artifacts) == "table" and quest.Artifacts or {}) do if got then found = found + 1 end end
            local stageNames = { [0] = "not started", [1] = "finding things (" .. found .. "/4)", [2] = "go to the Fisherman", [3] = "fishing", [4] = "done" }
            local state = tr.state or {}
            return table.concat({
                "Ghost Dog quest: " .. tostring(stageNames[tonumber(quest.Stage) or 0] or quest.Stage),
                string.format("Tickets: %s%s  |  Souls: %s  |  Ghosts caught: %s", tostring(train.Tickets or 0),
                    train.AccessUnlocked and " (train unlocked, no ticket needed)" or "", tostring(train.Souls or 0), tostring(train.TotalCaught or 0)),
                "Train: " .. tostring(state.Phase or "?") .. (state.ArrivalOpen and "  (boarding open!)" or ""),
                string.format("This session: %d rides, %d soul trades", tr.rides, tr.trades),
                "State: " .. tostring(tr.status),
            }, "\n")
        end)
        TrainSection:AddParagraph({
            Title = "How It Works",
            Content = "Ghost Dog Quest: unlocks the train ticket (once per account).\n"
                .. "Phantom Express: rides the train, vacuums your ghosts, comes home. Trade Souls: 500 Souls = 1 Spectral Mutation.",
        })
        TrainSection:AddToggle({ Title = "Auto Ghost Dog Quest", Default = false, Callback = function(on) tr.quest = on == true end })
        TrainSection:AddToggle({ Title = "Auto Phantom Express", Default = false, Callback = function(on) tr.ride = on == true end })
        TrainSection:AddToggle({ Title = "Auto Trade Souls", Default = false, Callback = function(on) tr.trade = on == true end })
        local FishSection = EventTab:AddSection("Instant Fishing")
        liveStatus(FishSection, "Instant Fishing Status", function()
            return "State: " .. tostring(fs.status)
                .. "\nCasts: " .. fs.casts .. "  |  Caught: " .. fs.catches .. "  |  Got away: " .. fs.misses
                .. "\nGhost Fish caught: " .. fs.ghosts
        end)
        liveStatus(FishSection, "Phantom Location Status", function()
            local manor = manorState()
            local state
            if not fs.phantom then
                state = "Off"
            elseif manor.KeyClaimed == true then
                state = "Manor Key already claimed"
            elseif findTool("GhostDogRod") == nil then
                state = "Needs the Haunted Rod (Phantom Express > Auto Ghost Dog Quest)"
            elseif inCave() or inTown() then
                state = fs.phantomStatus
            elseif findTool("ConductorTicket") == nil and not trainUnlocked() then
                state = "Needs the Train Pass (Phantom Express)"
            else
                state = "Waiting for the Phantom Express to Forgotten Town"
            end
            return "State: " .. tostring(state)
                .. "\nMet Gus: " .. (manor.Met == true and "yes" or "no")
                .. "  |  Manor Key: " .. (manor.KeyClaimed == true and "claimed" or "not yet")
        end)
        FishSection:AddToggle({ Title = "Enable Instant Fishing", Default = false, Callback = function(on) fs.enabled = on == true end })
        FishSection:AddToggle({ Title = "Farm Monsters While Fishing", Default = false, Callback = function(on) fs.withMonsters = on == true end })
        FishSection:AddToggle({ Title = "Perfect Cast (x1.5 luck)", Default = true, Callback = function(on) fs.perfect = on == true end })
        FishSection:AddToggle({ Title = "Auto Fishing Phantom Location (Manor Key)", Default = false,
            Callback = function(on) fs.phantom = on == true end })
        FishSection:AddToggle({ Title = "Autopilot Ghost Fish", Default = true, Callback = function(on) fs.ghost = on == true end })
        local KingSection = EventTab:AddSection("Pumpkin King")
        liveStatus(KingSection, "Pumpkin King Status", function()
            local left, untilOpen = pkWindow()
            local lines = {
                "Boss Portal: " .. (left and ("open, closes in " .. mmss(left)) or (untilOpen and ("opens in " .. mmss(untilOpen)) or "?")),
            }
            local arena = inArena() and pkArena()
            if arena then
                local shield = arena:GetAttribute("ShieldActive") == true
                    and string.format("  |  Shield %s / %s", tostring(arena:GetAttribute("ShieldHealth") or 0), tostring(arena:GetAttribute("ShieldMax") or "?")) or ""
                lines[#lines + 1] = string.format("%s: %s / %s HP (%s)%s", tostring(arena:GetAttribute("BossName") or "Boss"),
                    tostring(math.ceil(tonumber(arena:GetAttribute("Health")) or 0)), tostring(arena:GetAttribute("MaxHealth") or "?"),
                    tostring(arena:GetAttribute("Phase") or "?"), shield)
                local endsAt = tonumber(arena:GetAttribute("EndsAt")) or 0
                if endsAt > 0 then lines[#lines + 1] = "Time left: " .. mmss(endsAt - workspace:GetServerTimeNow()) end
            end
            lines[#lines + 1] = string.format("This session: %d fights, %d wins, %d cannon shots, +%d Candy Corn", pk.fights, pk.wins, pk.shots, pk.tokens)
            lines[#lines + 1] = "State: " .. tostring(pk.status)
            return table.concat(lines, "\n")
        end)
        KingSection:AddParagraph({
            Title = "How It Works",
            Content = "Needs 2.5M Speed Power and a Bat. The Boss Portal opens at :15 and :45 for 5 minutes: goes in, bats the Pumpkin Brute "
                .. "and the Pumpkin King, clears cannon roots and fires the cannons at the King's shield, breaks vine traps, dodges the attacks, "
                .. "picks up the Candy Corn and leaves.",
        })
        KingSection:AddToggle({
            Title = "Auto Pumpkin King", Default = false,
            Callback = function(on)
                pk.enabled = on == true
                if pk.enabled and not Bat.Best() then
                    notify("Pumpkin King", "No Bat in your inventory: the boss can only be hit with a Bat.", Color3.fromRGB(255, 140, 0), 4)
                end
            end,
        })
        KingSection:AddToggle({ Title = "Use Cannons (King's shield)", Default = true, Callback = function(on) pk.cannons = on == true end })
        KingSection:AddToggle({ Title = "Pop Pumpkin Minions", Default = true, Callback = function(on) pk.minions = on == true end })
        KingSection:AddToggle({ Title = "Dodge Attacks", Default = true, Callback = function(on) pk.dodge = on == true end })
    end
    -- Enchanted Tree: Wisp quest, butterflies, the two stations and the Mushroom Puzzle; one loop, one door
    do
        local WISP_SPEED  = 50e9
        local TREE_ENTER  = Vector3.new(6868.9, 74, -318)
        local TREE_SETTLE = 1.2
        local TIERS       = { "Green", "Blue", "Purple", "Golden" }
        local CATCH_SWING = 0.46
        local REMOTE_ONLY = { Claim = true, BeginReturn = true }
        local tree = { wisp = false, catch = false, trade = false, essence = false, banjo = false, live = true, door = false }

        -- helpers
        local function trace(text, ...)
            local sink = rawget(_G, "LynxTreeTrace")
            if type(sink) == "function" then pcall(sink, string.format(text, ...)) end
        end
        local function treeModule(name)
            local node = ReplicatedStorage.Data:FindFirstChild(name) or ReplicatedStorage.Shared.Modules:FindFirstChild(name)
            local ok, module = pcall(require, node)
            return ok and module or nil
        end
        local function treeSave()
            local save = Game.Save and Game.Save.Get()
            return type(save) == "table" and save or nil
        end
        local function build(name)
            local objects = worldFolder()
            local folder = objects and objects:FindFirstChild("Build")
            return folder and folder:FindFirstChild(name)
        end
        local function stationAnchor(name)
            local objects = worldFolder()
            local machines = objects and objects:FindFirstChild("Machines")
            local station = machines and machines:FindFirstChild("ButterflyStation")
            local machine = station and station:FindFirstChild(name)
            return machine and machine:FindFirstChild("Anchor")
        end
        local function marker(name)
            local interior = build("EnchantedTreeInterior")
            return interior and interior:FindFirstChild(name, true)
        end
        local function inTree() return LocalPlayer:GetAttribute("InEnchantedTree") == true end
        local function treeUnlocked()
            local save = treeSave()
            return LocalPlayer:GetAttribute("EnchantedTreeUnlocked") == true
                or (save and save.WispCompanion and save.WispCompanion.Unlocked == true)
        end
        local function anyOn() return tree.wisp or tree.catch or tree.trade or tree.essence or tree.banjo end
        local function active()
            return tree.live and anyOn() and Control.Owns("enchanted") and getCharacter() ~= nil
        end
        local function waitUntil(check, seconds)
            local deadline = os.clock() + seconds
            while os.clock() < deadline and active() do
                if check() then return true end
                task.wait(0.1)
            end
            return check()
        end
        local function standAt(position, seconds, look)
            local deadline = os.clock() + (seconds or TREE_SETTLE)
            local cf = look and CFrame.lookAt(position, Vector3.new(look.X, position.Y, look.Z)) or CFrame.new(position)
            while os.clock() < deadline do
                if not active() then return false end
                local body, root = getCharacter()
                if not body then return false end
                body:PivotTo(cf)
                root.AssemblyLinearVelocity = Vector3.zero
                RunService.Heartbeat:Wait()
            end
            return true
        end

        -- getting to the forest: a lane-portal hop for the long way, then on foot via Status.Travel
        local function hop(position)
            local lanes, zone = build("FuseBiomeLanePortals"), build("FuseBiomeZone")
            local lane = lanes and lanes:FindFirstChildWhichIsA("BasePart")
            local exit = zone and zone:FindFirstChild("ExitPart")
            if not (lane and exit) then return false end
            Movement.SwapHumanoid()
            Movement.HardenHumanoid()
            local function root()
                local _, part = getCharacter()
                return part
            end
            local okPing, ping = pcall(function() return LocalPlayer:GetNetworkPing() end)
            if not standAt(Movement.StandSpot(position), 2.5 + 2 * (okPing and ping or 0.1)) then return false end
            local uncover = Status.PortalCover and select(2, pcall(Status.PortalCover)) or nil
            local function done(result)
                if type(uncover) == "function" then pcall(uncover) end
                return result
            end
            local deadline = os.clock() + 6
            while os.clock() < deadline and active() do
                local part = root()
                if part and (part.Position - exit.Position).Magnitude < 60 then break end
                touchPart(lane)
                task.wait(0.4)
            end
            local part = root()
            if not (part and (part.Position - exit.Position).Magnitude < 60) then return done(false) end
            deadline = os.clock() + 12
            while os.clock() < deadline do
                part = root()
                if part and (part.Position - exit.Position).Magnitude > 1000 then return done(true) end
                if part then part.AssemblyLinearVelocity = Vector3.zero end
                touchPart(exit)
                task.wait(0.1)
            end
            return done(false)
        end
        local function travelTo(position, settle)
            local _, root = getCharacter()
            if not root then return false end
            if (root.Position - position).Magnitude > 1500 and position.X > 2200 and position.Y < 1000 then
                pcall(hop, position)
                _, root = getCharacter()
                if not root then return false end
            end
            if (root.Position - position).Magnitude > 20 and not (Status.Travel and Status.Travel(position, active)) then
                return false
            end
            return standAt(position, settle)
        end

        -- the tree door: entering and leaving never overlap
        local function withDoor(fn)
            local deadline = os.clock() + 15
            while tree.door and os.clock() < deadline do task.wait(0.1) end
            if tree.door then return false end
            tree.door = true
            local ok, result = pcall(fn)
            tree.door = false
            return ok and result == true
        end
        local function inSecretRoom()
            local spawn = marker("SecretRoomSpawn")
            local _, root = getCharacter()
            return inTree() and spawn ~= nil and root ~= nil and (root.Position - spawn.Position).Magnitude < 150
        end
        local function passThrough(name, arrived, keepGoing)
            local zone = marker(name)
            if not zone then return false end
            local deadline = os.clock() + 6
            while not arrived() and os.clock() < deadline and keepGoing() do
                local body, root = getCharacter()
                if not body then return false end
                body:PivotTo(zone.CFrame)
                root.AssemblyLinearVelocity = Vector3.zero
                touchPart(zone)
                task.wait(0.3)
            end
            return arrived()
        end
        local function enterTree()
            if inTree() then return true end
            return withDoor(function()
                local interior = build("EnchantedTreeInterior")
                local prompt = interior and interior:FindFirstChild("EnchantedTreePrompt", true)
                if not (prompt and type(fireproximityprompt) == "function" and travelTo(TREE_ENTER)) then return false end
                fireproximityprompt(prompt, prompt.HoldDuration)
                return waitUntil(inTree, 6)
            end)
        end
        local function leaveTree()
            if not inTree() then return true end
            return withDoor(function()
                if inSecretRoom() then
                    passThrough("SecretRoomExit", function() return not inSecretRoom() end, function() return getCharacter() ~= nil end)
                end
                local exit = marker("ExitTrigger")
                if not exit then return false end
                local deadline = os.clock() + 6
                while inTree() and os.clock() < deadline and getCharacter() do
                    touchPart(exit)
                    task.wait(0.5)
                end
                return not inTree()
            end)
        end
        Control.AddGate(function(name)
            if name == "enchanted" or Control.IsStill(name) or not inTree() then return true end
            if not tree.door and getCharacter() then task.spawn(leaveTree) end
            return false
        end)

        -- Wisp quest
        local function wispQuest()
            if not tree.wisp then return nil end
            local save, quests = treeSave(), treeModule("WispQuests")
            local wisp = save and save.WispCompanion
            if not (wisp and quests and wisp.Accepted) or wisp.Unlocked then return nil end
            local quest = quests.List[wisp.Stage]
            local progress = type(wisp.Progress) == "table" and wisp.Progress[quest and quest.Id] or 0
            if not quest or (wisp.Claimed or {})[quest.Id] or progress >= quest.Target then return nil end
            return quest, progress
        end
        local function dropsIn(areaId, category)
            local area = Game.Areas and Game.Areas.Directory and Game.Areas.Directory[areaId]
            for _, drop in ipairs(area and area.DropTable or {}) do
                if drop[1] == category then return true end
            end
            return false
        end
        local function questMatches(quest, areaId, category)
            for key, want in pairs(quest.Match) do
                if key == "AreaId" then
                    if areaId ~= nil and tostring(areaId) ~= want then return false end
                    if areaId == nil and not dropsIn(want, category) then return false end
                elseif key == "Rarity" then
                    local asset = Game.Assets and Game.Assets.Directory[category]
                    local rarity = asset and asset.Rarity
                    if not (rarity and (rarity._id == want or rarity.DisplayName == want)) then return false end
                else
                    return false
                end
            end
            return true
        end
        function Status.WispSteal()
            local quest = wispQuest()
            if not (quest and quest.Event == "EggSecured") then return nil end
            return function(record) return questMatches(quest, record.AreaId, record.AssetCategory) end
        end
        function Status.WispFuseWants(category)
            local quest = wispQuest()
            return quest ~= nil and quest.Event == "PetFused" and questMatches(quest, nil, category)
        end
        function Status.WispFuseActive()
            local quest = wispQuest()
            return quest ~= nil and quest.Event == "PetFused"
        end
        local function wispRequest(action, arg)
            local ok, done, why = pcall(function()
                return Game.Remotes.WispCompanion.Request:InvokeServer(action, arg)
            end)
            return ok and done == true, why
        end
        local function wispAction()
            local save, quests = treeSave(), treeModule("WispQuests")
            local wisp = save and save.WispCompanion
            if not (wisp and quests) or wisp.Unlocked or (tonumber(save.SpeedPower) or 0) < WISP_SPEED then return nil end
            if os.clock() < (tree.nextWisp or 0) then return nil end
            if not wisp.Accepted then return "Accept" end
            local quest = quests.List[wisp.Stage]
            if quest and not wisp.Claimed[quest.Id] and (wisp.Progress[quest.Id] or 0) >= quest.Target then
                return "Claim", quest.Id
            end
            if wisp.Stage < quests.StageCount then return nil end
            return wisp.Returning and "Return" or "BeginReturn"
        end
        local function wispNeeded()
            if not tree.wisp then return false end
            local action = wispAction()
            return action ~= nil and not REMOTE_ONLY[action]
        end
        local function wispRun()
            local action, arg = wispAction()
            if not action then return end
            tree.nextWisp = os.clock() + 5
            local zone = build("EnchantedForestZone")
            local spot = zone and zone:FindFirstChild(action == "Accept" and "WispSpawn" or "WispAnchor", true)
            local offset = action == "Accept" and Vector3.new(0, 4, 6) or Vector3.new(0, 3, 3)
            Control.SetFirm("enchanted")
            if spot and leaveTree() and travelTo(spot.Position + offset, 1.5) then wispRequest(action, arg) end
        end
        local function remoteChores()
            if not tree.wisp then return end
            local action, arg = wispAction()
            if REMOTE_ONLY[action] then
                tree.nextWisp = os.clock() + 5
                wispRequest(action, arg)
            end
            if Status.WispFuseActive() and Status.RunFuse and os.clock() >= (tree.nextFuse or 0) then
                tree.nextFuse = os.clock() + 10
                Status.RunFuse()
            end
        end

        -- butterflies
        local function netTool()
            for _, holder in ipairs({ LocalPlayer.Character, LocalPlayer:FindFirstChild("Backpack") }) do
                for _, item in ipairs(holder and holder:GetChildren() or {}) do
                    if item:IsA("Tool") and item:GetAttribute("ButterflyNet") == true then return item end
                end
            end
            return nil
        end
        local function butterflyWindow()
            -- the bloom now comes at random gaps (GapMinSeconds..GapMaxSeconds; Offset/IntervalSeconds are gone): the
            -- server flags the live one on the workspace
            local live, endsAt = workspace:GetAttribute("Event_ButterflyBloom"), workspace:GetAttribute("ButterflyBloomEndsAt")
            if live ~= nil or endsAt ~= nil then
                return live == true and (type(endsAt) ~= "number" or workspace:GetServerTimeNow() < endsAt)
            end
            local flags = treeModule("ButterflyFlags") or select(2, pcall(require, ReplicatedStorage.Shared.Flags.ButterflyFlags))
            local ok, open = pcall(function()
                if not flags.Enabled:Get() then return false end
                local into = (workspace:GetServerTimeNow() - flags.OffsetSeconds:Get()) % flags.IntervalSeconds:Get()
                return into < flags.DurationSeconds:Get()
            end)
            return ok and open == true
        end
        local function netClaimable()
            local save = treeSave()
            return netTool() == nil and treeUnlocked() and not (save and save.Butterflies and save.Butterflies.NetClaimed)
        end
        local function useStation(name, work)
            local anchor = stationAnchor(name)
            if not (anchor and enterTree() and standAt(anchor.Position + Vector3.new(0, 3, 5))) then return end
            work()
        end
        local function butterflyCounts()
            local save = treeSave()
            return save and save.Butterflies and save.Butterflies.Counts or {}
        end
        local function essenceRecipe()
            local catalog = treeModule("ButterflyCatalog")
            local ok, recipe = pcall(function() return catalog.EssenceRecipe() end)
            return ok and type(recipe) == "table" and recipe or nil
        end
        local function craftReady()
            local recipe = essenceRecipe()
            if not recipe or next(recipe) == nil then return false end
            local counts = butterflyCounts()
            for tier, need in pairs(recipe) do
                if (tonumber(counts[tier]) or 0) < (tonumber(need) or 0) then return false end
            end
            return true
        end
        local function tradeReady()
            local catalog, counts, recipe = treeModule("ButterflyCatalog"), butterflyCounts(), essenceRecipe()
            if not (catalog and recipe) then return nil end
            for index = #TIERS - 1, 1, -1 do
                local tier, upper = TIERS[index], TIERS[index + 1]
                local cost = tonumber(select(2, pcall(catalog.TradeUpCost, tier)))
                local spare = (tonumber(counts[tier]) or 0) - (tonumber(recipe[tier]) or 0)
                local short = (tonumber(counts[upper]) or 0) < (tonumber(recipe[upper]) or 0)
                if cost and cost > 0 and spare >= cost and short then return tier end
            end
            return nil
        end
        local function catchButterflies()
            local catalog = treeModule("ButterflyCatalog")
            if not (catalog and leaveTree()) then return end
            local SIDE, AHEAD, STEP, GLIDE, FAR, SETTLE = 10, 1.6, 0.05, 220, 400, 0.2
            local WORTH = { Golden = 1.5, Green = 1, Blue = 0.75, Purple = 0.45 }
            local net = Game.Remotes.Butterflies
            local character, userId = LocalPlayer.Character, LocalPlayer.UserId
            local function holdNet()
                local item = netTool()
                local humanoid = character and character:FindFirstChildOfClass("Humanoid")
                if not (item and humanoid) then return false end
                if item.Parent ~= character then pcall(function() humanoid:EquipTool(item) end) end
                return item.Parent == character
            end
            local function positionAt(flight, serverTime)
                local ok, at = pcall(catalog.PositionAt, flight, serverTime)
                return ok and typeof(at) == "Vector3" and at or nil
            end
            local function bloomCenter()
                local objects = worldFolder()
                local areas = objects and objects:FindFirstChild("Areas")
                local bloom = areas and areas:FindFirstChild("ButterflyBloom")
                local bounds = bloom and bloom:FindFirstChild("Bounds")
                return bounds and bounds:IsA("BasePart") and bounds.Position + Vector3.new(0, 7, 0) or nil
            end
            local live, flights, dirty, conns = {}, {}, true, {}
            local function flightList()
                if dirty then
                    flights, dirty = {}, false
                    for _, flight in pairs(live) do flights[#flights + 1] = flight end
                end
                return flights
            end
            local function track(flight)
                if type(flight) == "table" and flight.Id ~= nil then live[flight.Id], dirty = flight, true end
            end
            for _, pair in ipairs({
                { "Spawned", track },
                { "Escaped", function(flight)
                    track(flight)
                    trace("escaped: %s", tostring(type(flight) == "table" and flight.Tier))
                end },
                { "Removed", function(id, why, by)
                    if id ~= nil then live[id], dirty = nil, true end
                    if by == userId then trace("removed by us: %s", tostring(why)) end
                end },
            }) do
                local ok, conn = pcall(function() return net[pair[1]].OnClientEvent:Connect(pair[2]) end)
                if ok then conns[#conns + 1] = conn end
            end
            local function choose(here, earliest)
                local now, best, bestScore = workspace:GetServerTimeNow(), nil, 0
                for _, flight in ipairs(flightList()) do
                    local worth = WORTH[flight.Tier] or 0.5
                    for t = earliest, AHEAD, STEP do
                        local at = positionAt(flight, now + t)
                        local before, after = positionAt(flight, now + t - STEP), positionAt(flight, now + t + STEP)
                        if at and before and after then
                            local move = Vector3.new(after.X - before.X, 0, after.Z - before.Z)
                            if move.Magnitude > 0.01 then
                                local side = Vector3.new(-move.Unit.Z, 0, move.Unit.X) * SIDE
                                local spot = (at + side - here).Magnitude < (at - side - here).Magnitude and at + side or at - side
                                if (spot - here).Magnitude / GLIDE + SETTLE <= t then
                                    local score = worth / t
                                    if score > bestScore then
                                        best, bestScore = { id = flight.Id, flight = flight, spot = spot, at = now + t, tier = flight.Tier }, score
                                    end
                                    break
                                end
                            end
                        end
                    end
                end
                return best
            end
            local catchFx, swarmFx
            pcall(function()
                local events = ReplicatedStorage.Controllers.Game.AdminAbuseClientController.Events.ButterflyBloom
                local fx, flock = require(events.CatchFX), require(events.Swarm)
                if type(fx.Caught) == "function" then catchFx = fx end
                if type(flock.Take) == "function" then swarmFx = flock end
            end)
            local function showResult(id, tier, result)
                if not catchFx then return end
                if result == "Caught" then
                    local entry = swarmFx and select(2, pcall(swarmFx.Take, id)) or nil
                    local item = netTool()
                    local hoop = item and (item:FindFirstChild("Hoop") or item:FindFirstChild("Handle"))
                    local owned = (tonumber(butterflyCounts()[tier]) or 0) + 1
                    if not pcall(catchFx.Caught, entry, tier, owned, nil, hoop) then
                        pcall(catchFx.Caught, nil, tier, owned, nil, hoop)
                    end
                elseif result == "Escaped" and type(catchFx.Escaped) == "function" then
                    pcall(catchFx.Escaped, nil, tier)
                end
            end
            -- the net's own auto swing shares the server cooldown: hold it off while we catch
            local autoSwing
            if type(getgc) == "function" and type(debug.setupvalue) == "function" then
                for _, fn in ipairs(getgc()) do
                    if type(fn) == "function" and debug.info(fn, "n") == "autoSwing" and debug.info(fn, "s"):find("ButterflyBloom") then
                        autoSwing = fn
                        break
                    end
                end
            end
            local function holdAutoSwing(untilAt)
                if not autoSwing then return end
                pcall(function()
                    for index, value in ipairs(debug.getupvalues(autoSwing)) do
                        if type(value) == "number" then debug.setupvalue(autoSwing, index, untilAt) end
                    end
                end)
            end
            local plan, swinging, nextSwing, holdSpot, dt, settledAt, nextLook = nil, false, 0, nil, 0, nil, 0
            local function swingAt(id, tier, note)
                swinging, nextSwing = true, os.clock() + CATCH_SWING
                task.spawn(function()
                    local sent, result = pcall(function() return net.AskSwing:InvokeServer(id) end)
                    trace("swing %s (%s) -> %s", tostring(tier), note, tostring(sent and result))
                    if sent then showResult(id, tier, result) end
                    swinging = false
                end)
            end
            local ok, err = pcall(function()
                while active() and butterflyWindow() and LocalPlayer.Character == character do
                    local body, root = getCharacter()
                    if not body then break end
                    if os.clock() >= nextLook then
                        nextLook = os.clock() + 2
                        local okSwarm, list = pcall(function() return net.AskSwarm:InvokeServer() end)
                        list = okSwarm and type(list) == "table" and list or {}
                        if #list == 0 then break end
                        live, dirty = {}, true
                        for _, flight in ipairs(list) do live[flight.Id] = flight end
                    end
                    local center = bloomCenter()
                    if center and (root.Position - center).Magnitude > FAR + 300 then
                        if not travelTo(center, 0.3) then break end
                        holdSpot, dt, plan = nil, 0, nil
                        body, root = getCharacter()
                        if not body then break end
                    end
                    holdAutoSwing(os.clock() + 5)
                    local here = holdSpot or root.Position
                    local ping = LocalPlayer:GetNetworkPing()
                    local now = workspace:GetServerTimeNow()
                    if plan and (live[plan.id] ~= plan.flight or now > plan.at + 0.3) then
                        trace("plan dropped: %s", live[plan.id] == nil and "gone"
                            or live[plan.id] ~= plan.flight and "changed course" or "passed by")
                        plan = nil
                    end
                    if not plan then
                        plan = choose(here, math.max(0.15, nextSwing - os.clock()) + ping)
                        settledAt = nil
                        if plan then
                            trace("plan %s in %.2f s, %.0f studs away", tostring(plan.tier), plan.at - now, (plan.spot - here).Magnitude)
                        end
                    end
                    if plan then
                        local away = plan.spot - here
                        if away.Magnitude <= GLIDE * dt then
                            if here ~= plan.spot then settledAt = os.clock() end
                            here = plan.spot
                        else
                            here, settledAt = here + away.Unit * GLIDE * dt, nil
                        end
                        holdSpot = here
                        body:PivotTo(CFrame.new(here))
                        root.AssemblyLinearVelocity = Vector3.zero
                        local still = settledAt and os.clock() - settledAt >= SETTLE
                        if still and not swinging and os.clock() >= nextSwing and now + ping >= plan.at and holdNet() then
                            local at = positionAt(plan.flight, now)
                            if at and (Vector3.new(at.X - here.X, 0, at.Z - here.Z)).Magnitude > 0.1 then
                                body:PivotTo(CFrame.lookAt(here, Vector3.new(at.X, here.Y, at.Z)))
                            end
                            swingAt(plan.id, plan.tier, "intercept")
                            plan = nil
                        end
                    end
                    dt = RunService.Heartbeat:Wait()
                end
            end)
            for _, conn in ipairs(conns) do conn:Disconnect() end
            holdAutoSwing(0)
            if not ok then trace("catch error: %s", tostring(err)) end
        end
        local function catchNeeded() return tree.catch and (netClaimable() or (butterflyWindow() and netTool() ~= nil)) end
        local function catchRun()
            if netClaimable() then
                useStation("NetStand", function()
                    pcall(function() Game.Remotes.Butterflies.AskClaimNet:InvokeServer() end)
                    waitUntil(function() return netTool() ~= nil end, 3)
                end)
            elseif butterflyWindow() and netTool() then
                catchButterflies()
            end
        end
        local function stationNeeded()
            return treeUnlocked() and ((tree.essence and craftReady()) or (tree.trade and tradeReady() ~= nil))
        end
        local function stationRun()
            if tree.essence and craftReady() then
                useStation("MutationShrine", function()
                    while craftReady() and active() do
                        local ok, done = pcall(function() return Game.Remotes.Butterflies.AskCraftEssence:InvokeServer() end)
                        if not (ok and done == true) then break end
                        task.wait(0.3)
                    end
                end)
            elseif tree.trade and tradeReady() then
                useStation("ButterflyMachine", function()
                    local tier = tradeReady()
                    while tier and active() do
                        local ok, done = pcall(function() return Game.Remotes.Butterflies.AskTradeUp:InvokeServer(tier) end)
                        if not (ok and done == true) then break end
                        task.wait(0.3)
                        tier = tradeReady()
                    end
                end)
            end
        end

        -- Mushroom Puzzle (Banjo Cricket, once per account)
        local function banjoState()
            local save = treeSave()
            return save and save.BanjoCricket
        end
        local function banjoNeeded()
            local state = banjoState()
            return tree.banjo and treeUnlocked() and state ~= nil and not state.Claimed
        end
        local function banjoRun()
            if not inSecretRoom() and not (enterTree() and passThrough("SecretJumpZone", inSecretRoom, active)) then return end
            local net = Game.Remotes.BanjoCricket
            if banjoState().Solved then
                local npc = game:GetService("CollectionService"):GetTagged("BanjoCricketNpc")[1]
                local body = npc and (npc.PrimaryPart or npc:FindFirstChildWhichIsA("BasePart", true))
                if body and standAt(body.Position + Vector3.new(0, 0, -6), 1.2, body.Position) then
                    pcall(function() net.AskClaim:InvokeServer() end)
                    waitUntil(function() return banjoState().Claimed == true end, 3)
                end
                return
            end
            local okTargets, targets = pcall(function()
                return require(ReplicatedStorage.Controllers.Game.BanjoCricketController.Mushrooms).Targets()
            end)
            local data = treeModule("BanjoCricket")
            if not (okTargets and data and Bat.Best()) then return end
            local anchors = {}
            for _, target in ipairs(targets) do anchors[target.Index] = target.Anchor end
            local function hit(index)
                local anchor = anchors[index]
                if not anchor then return false end
                local spot = Vector3.new(anchor.Position.X, anchor.Position.Y - 0.3, anchor.Position.Z - 7)
                if not standAt(spot, 0.25, anchor.Position) then return false end
                pcall(function() net.Aim:FireServer(index) end)
                local deadline = os.clock() + 3
                while os.clock() < deadline and active() do
                    standAt(spot, 0.05, anchor.Position)
                    if Bat.Swing(nil) then return true end
                    task.wait(0.05)
                end
                return false
            end
            local queue, solved, restartAt = nil, false, 0
            local conn = net.Effect.OnClientEvent:Connect(function(effect)
                if type(effect) ~= "table" then return end
                if effect.Kind == "Playback" then
                    queue = { notes = effect.Notes, at = os.clock() + data.PlaybackSeconds(#effect.Notes) + 0.4 }
                elseif effect.Kind == "Solved" then
                    solved = true
                elseif effect.Kind == "Wrong" or effect.Kind == "Reset" then
                    queue, restartAt = nil, os.clock() + data.Timing.WrongPause + 1
                end
            end)
            local deadline = os.clock() + 150
            while not solved and os.clock() < deadline and active() and inSecretRoom() do
                if queue and os.clock() >= queue.at then
                    local notes = queue.notes
                    queue = nil
                    for _, index in ipairs(notes) do
                        if not hit(index) then break end
                    end
                    restartAt = os.clock() + data.Timing.ListenTimeout + 2
                elseif not queue and os.clock() >= restartAt then
                    restartAt = os.clock() + data.Timing.ListenTimeout + 2
                    hit(1)
                end
                task.wait(0.1)
            end
            conn:Disconnect()
            Bat.Doff()
        end

        -- loop: run the first job that has work; stay in the tree only while the next job is in there too
        local JOBS = {
            { needed = wispNeeded,    run = wispRun,    insideTree = false },
            { needed = catchNeeded,   run = catchRun,   insideTree = false },
            { needed = banjoNeeded,   run = banjoRun,   insideTree = true },
            { needed = stationNeeded, run = stationRun, insideTree = true },
        }
        local function nextJob()
            if not anyOn() or Movement.FieldClosed() then return nil end
            for _, job in ipairs(JOBS) do
                local ok, needed = pcall(job.needed)
                if ok and needed then return job end
            end
            return nil
        end
        local function stowNet()
            local item = netTool()
            if item and item.Parent == LocalPlayer.Character then
                pcall(function() item.Parent = LocalPlayer:FindFirstChild("Backpack") end)
            end
        end
        task.spawn(function()
            while tree.live do
                pcall(remoteChores)
                local job, ran = nextJob(), false
                if not job then
                    Control.Want("enchanted", 0)
                    Control.Idle("enchanted")
                elseif not Status.stealBusy then
                    Control.Want("enchanted", 3)
                    if not Control.Blocker("enchanted", true) and Control.Acquire("enchanted") then
                        ran = true
                        pcall(function()
                            if not Treadmill.Leave(3) then return end
                            Movement.SwapHumanoid()
                            Movement.HardenHumanoid()
                            job.run()
                        end)
                        local following = nextJob()
                        if not (following and following.insideTree and Control.Owns("enchanted")) then pcall(leaveTree) end
                        stowNet()
                        Control.Release("enchanted")
                    end
                end
                task.wait(ran and 0.2 or 0.5)
            end
        end)
        table.insert(_G.LynxSAE.Stoppers, function()
            tree.live = false
            Control.Want("enchanted", 0)
            Control.Release("enchanted")
        end)

        -- UI
        local function fmtPower(value)
            value = tonumber(value) or 0
            if value >= 1e9 then return string.format("%.1fB", value / 1e9) end
            if value >= 1e6 then return string.format("%.1fM", value / 1e6) end
            return tostring(math.floor(value))
        end
        local function treeStatus()
            local save, quests = treeSave(), treeModule("WispQuests")
            if not save then return "Loading..." end
            local wisp, flies = save.WispCompanion or {}, save.Butterflies or {}
            local counts = flies.Counts or {}
            local lines = { string.format("Speed Power: %s / %s", fmtPower(save.SpeedPower), fmtPower(WISP_SPEED)) }
            if wisp.Unlocked or treeUnlocked() then
                lines[#lines + 1] = "Wisp: done, tree unlocked"
            elseif not wisp.Accepted then
                lines[#lines + 1] = "Wisp: not met yet"
            else
                local quest = quests and quests.List[wisp.Stage]
                lines[#lines + 1] = quest and string.format("Wisp %d/%d: %s (%d/%d)", wisp.Stage, quests.StageCount,
                    quest.Title, wisp.Progress and wisp.Progress[quest.Id] or 0, quest.Target)
                    or (wisp.Returning and "Wisp: return it to the tree" or "Wisp: ready to return")
            end
            lines[#lines + 1] = "Net: " .. ((netTool() or flies.NetClaimed) and "claimed" or "not claimed")
            local recipe = essenceRecipe() or {}
            lines[#lines + 1] = string.format("Butterflies (recipe): green %d/%d, blue %d/%d, purple %d/%d, golden %d/%d",
                counts.Green or 0, recipe.Green or 0, counts.Blue or 0, recipe.Blue or 0,
                counts.Purple or 0, recipe.Purple or 0, counts.Golden or 0, recipe.Golden or 0)
            lines[#lines + 1] = "Essence: " .. tostring(flies.Essence or 0)
            local banjo = save.BanjoCricket or {}
            lines[#lines + 1] = "Mushroom Puzzle: " .. (banjo.Claimed and "reward claimed"
                or (banjo.Solved and "solved, reward not claimed" or "not solved"))
            return table.concat(lines, "\n")
        end
        local TreeSection = EventTab:AddSection("Enchanted Tree")
        local statusRef = TreeSection:AddParagraph({ Title = "Enchanted Tree Status", Content = "Loading..." })
        task.spawn(function()
            local last
            while tree.live do
                local ok, text = pcall(treeStatus)
                if ok and text ~= last then
                    last = text
                    pcall(setParagraph, statusRef, text)
                end
                task.wait(2)
            end
        end)
        TreeSection:AddParagraph({
            Title = "How It Works",
            Content = "Wisp Quest opens the tree (needs 50B Speed Power).\n"
                .. "Butterflies: catch, trade up, craft essence. Mushroom Puzzle: claims the Banjo once.",
        })
        for _, feature in ipairs({
            { key = "wisp",    title = "Auto Wisp Quest" },
            { key = "catch",   title = "Auto Catch Butterflies" },
            { key = "trade",   title = "Auto Trade Up Butterflies" },
            { key = "essence", title = "Auto Craft Essence" },
            { key = "banjo",   title = "Auto Mushroom Puzzle" },
        }) do
            TreeSection:AddToggle({
                Title    = feature.title,
                Default  = false,
                Callback = function(on)
                    tree[feature.key] = on == true
                    if feature.key == "wisp" and Status.SetWispSteal then Status.SetWispSteal(on == true) end
                end,
            })
        end
    end
    do
        local JUMP_CALM   = 1.5  
        local JUMP_SLIP   = 20   
        local JUMP_WINDOW = 8
        local STAND_GAP   = 5    
        local LAND_WAIT   = 1.5  
        local WAIT_SIDE   = 60
        local NOTICE_GIVEUP = 3
        local HOLD_SLACK  = 0.25
        local ANSWER_WAIT = 2.5
        local STATE_EVERY = 60
        local starRemotes = nil
        local star = {
            enabled = false, live = true, payload = nil, noticed = false,
            answers = {}, caught = 0, status = "Off", ref = nil, conns = {},
        }
        local function trace(text, ...)
            local sink = rawget(_G, "LynxStarTrace")
            if type(sink) == "function" then pcall(sink, string.format(text, ...)) end
        end
        local function remotes()
            if starRemotes then return starRemotes end
            local ok, all = pcall(require, ReplicatedStorage.Shared.Remotes)
            local group = ok and type(all) == "table" and all.ShootingStar
            if type(group) == "table" and group.Hold and group.Catch and group.Fall then starRemotes = group end
            return starRemotes
        end
        local function serverNow() return workspace:GetServerTimeNow() end
        local function ping()
            local ok, value = pcall(function() return LocalPlayer:GetNetworkPing() end)
            return ok and tonumber(value) or 0
        end
        local function validPayload(p)
            return type(p) == "table" and p.Id ~= nil and type(p.LandAt) == "number"
                and type(p.ExpiresAt) == "number" and typeof(p.Landing) == "CFrame"
        end
        local function setPayload(p, source)
            if not validPayload(p) or serverNow() >= p.ExpiresAt then return end
            if star.payload and star.payload.Id == p.Id then return end
            star.payload, star.noticed = p, p.Noticed == true
            star.answers[p.Id] = nil
            trace("star %s from %s: lands in %.1f s, gone in %.0f s", tostring(p.Id), source,
                p.LandAt - serverNow(), p.ExpiresAt - serverNow())
            if star.enabled then
                notify("Shooting Star", "A star is falling! Going to catch it.", Color3.fromRGB(255, 225, 0), 4)
            end
        end
        local function current()
            local p = star.payload
            if p and serverNow() >= p.ExpiresAt then
                star.payload, p = nil, nil
            end
            return p
        end
        local function starAt(p)
            local leg = p.Leg
            if type(leg) == "table" and typeof(leg.From) == "Vector3" and typeof(leg.To) == "Vector3"
                and type(leg.StartAt) == "number" and type(leg.ArriveAt) == "number" then
                local span = leg.ArriveAt - leg.StartAt
                if span <= 0 then return leg.To end
                return leg.From:Lerp(leg.To, math.clamp((serverNow() - leg.StartAt) / span, 0, 1))
            end
            return p.Landing.Position
        end
        local function owns(p)
            return function()
                return star.enabled and star.live and Control.Owns("star") and star.payload == p
                    and serverNow() < p.ExpiresAt and getCharacter() ~= nil
            end
        end
        local function jumpTo(target, keepGoing)
            local spot = Movement.StandSpot(target)
            local deadline, calm = os.clock() + JUMP_WINDOW, 0
            while os.clock() < deadline do
                if not keepGoing() then return false end
                local character, root = getCharacter()
                if not root then return false end
                if (root.Position - spot).Magnitude > JUMP_SLIP then calm = 0 end
                if calm >= JUMP_CALM + 2 * ping() then return true end
                character:PivotTo(CFrame.new(spot))
                root.AssemblyLinearVelocity = Vector3.zero
                calm = calm + RunService.Heartbeat:Wait()
            end
            return false
        end
        local function standBy(p)
            local character, root = getCharacter()
            if not root then return false end
            local at   = starAt(p)
            local away = Vector3.new(root.Position.X - at.X, 0, root.Position.Z - at.Z)
            local side = away.Magnitude > 0.5 and away.Unit or Vector3.xAxis
            local spot = Movement.StandSpot(at + side * STAND_GAP)
            character:PivotTo(CFrame.lookAt(spot, Vector3.new(at.X, spot.Y, at.Z)))
            root.AssemblyLinearVelocity = Vector3.zero
            return true
        end
        local function catchStar(p, keepGoing)
            local net = remotes()
            local holdHeld = p.HoldSeconds or 1.6
            local nearSince, holdAt, heldNoticed = os.clock(), nil, false
            while keepGoing() do
                if not standBy(p) then return false end
                local answer = star.answers[p.Id]
                if answer == "claimed" then return true end
                if answer == "expired" then return false end
                if not holdAt then
                    if star.noticed or os.clock() - nearSince >= NOTICE_GIVEUP + ping() then
                        star.answers[p.Id] = nil
                        pcall(function() net.Hold:FireServer(p.Id, true) end)
                        holdAt, heldNoticed = os.clock(), star.noticed
                        trace("holding (noticed=%s)", tostring(star.noticed))
                    end
                elseif heldNoticed and not star.noticed and not star.catchAt then
                    trace("lost notice while holding")
                    pcall(function() net.Hold:FireServer(p.Id, false) end)
                    holdAt, nearSince = nil, os.clock()
                elseif answer == "slipped" or (star.catchAt and os.clock() - star.catchAt >= ANSWER_WAIT) then
                    trace("catch %s, trying again", answer or "unanswered")
                    pcall(function() net.Hold:FireServer(p.Id, false) end)
                    star.answers[p.Id], star.catchAt, holdAt = nil, nil, nil
                    nearSince = os.clock()
                elseif not star.catchAt and os.clock() - holdAt >= holdHeld + HOLD_SLACK + ping() then
                    pcall(function() net.Catch:FireServer(p.Id) end)
                    star.catchAt = os.clock()
                    trace("catch sent")
                end
                RunService.Heartbeat:Wait()
            end
            return star.answers[p.Id] == "claimed"
        end
        local function goHome()
            local home = Movement.SafeZone()
            if home then jumpTo(home, function() return star.live end) end
        end
        local function runCatch(p)
            local keepGoing = owns(p)
            star.catchAt = nil
            if not Treadmill.Leave(3) then return end
            Movement.SwapHumanoid()
            Movement.HardenHumanoid()
            star.status = "Going to the star"
            local landing = p.Landing.Position
            local _, root0 = getCharacter()
            local from = root0 and Vector3.new(root0.Position.X - landing.X, 0, root0.Position.Z - landing.Z)
            local side = from and from.Magnitude > 1 and from.Unit or Vector3.xAxis
            local waitAt = landing + side * WAIT_SIDE
            if not jumpTo(waitAt, keepGoing) then
                trace("could not settle beside the landing spot")
                return
            end
            local waitSpot = Movement.StandSpot(waitAt)
            while keepGoing() and serverNow() < p.LandAt + LAND_WAIT do
                local character, root = getCharacter()
                if root then
                    character:PivotTo(CFrame.new(waitSpot))
                    root.AssemblyLinearVelocity = Vector3.zero
                end
                RunService.Heartbeat:Wait()
            end
            if not keepGoing() then return end
            star.status = "Catching the star"
            trace("dropping in next to the star (%.0f studs away)", (starAt(p) - waitAt).Magnitude)
            if catchStar(p, keepGoing) then
                star.caught = star.caught + 1
                star.payload = nil
                trace("claimed")
                notify("Shooting Star", "Star caught!", Color3.fromRGB(255, 225, 0), 4)
                goHome()
            elseif star.answers[p.Id] == nil then
                pcall(function() remotes().Hold:FireServer(p.Id, false) end)
            end
        end
        local function onAnswer(kind)
            return function(id)
                if id == nil then return end
                star.answers[id] = kind
                trace("server: %s", kind)
                if kind ~= "slipped" and star.payload and star.payload.Id == id then star.payload = nil end
            end
        end
        local function hook()
            local net = remotes()
            if not net or #star.conns > 0 then return net ~= nil end
            local function on(remote, fn)
                local ok, conn = pcall(function() return remote.OnClientEvent:Connect(fn) end)
                if ok then star.conns[#star.conns + 1] = conn end
            end
            on(net.Fall, function(p) setPayload(p, "Fall") end)
            on(net.Wander, function(id, leg, noticed)
                local p = star.payload
                if not (p and p.Id == id and type(leg) == "table") then return end
                p.Leg, star.noticed = leg, noticed == true
            end)
            on(net.Slipped, onAnswer("slipped"))
            on(net.Claimed, onAnswer("claimed"))
            on(net.Expired, onAnswer("expired"))
            return true
        end
        local function askState()
            local net = remotes()
            if not (net and net.AskState) then return end
            local ok, p = pcall(function() return net.AskState:InvokeServer() end)
            if ok then setPayload(p, "AskState") end
        end
        task.spawn(function()
            local nextAsk = 0
            while star.live do
                local busy = false
                if star.enabled then
                    if os.clock() >= nextAsk and not star.payload then
                        nextAsk = os.clock() + STATE_EVERY
                        askState()
                    end
                    local p = current()
                    Status.starDueAt = p and p.LandAt or nil
                    if not p then
                        star.status = "Waiting for a Star Drop"
                        Control.Want("star", 0)
                    elseif serverNow() < p.LandAt - 8 then
                        star.status = string.format("Star falling, lands in %d s", math.ceil(p.LandAt - serverNow()))
                        Control.Want("star", 0)
                    else
                        Control.Want("star", 3)
                        if not Control.Blocker("star", true) and Control.Acquire("star") then
                            busy = true
                            local ok, err = pcall(runCatch, p)
                            if not ok then trace("error: %s", tostring(err)) end
                            Control.Release("star")
                        else
                            star.status = "Waiting for " .. tostring(Control.Holder() or "another feature")
                        end
                    end
                else
                    star.status = "Off"
                    Status.starDueAt = nil
                    Control.Want("star", 0)
                end
                task.wait(busy and 0.2 or 0.5)
            end
        end)
        local StarSection = EventTab:AddSection("Shooting Star")
        star.statusRef = StarSection:AddParagraph({ Title = "Shooting Star Status", Content = "Off" })
        task.spawn(function()
            local last
            while star.live do
                local p = current()
                local text = star.status
                if p and serverNow() < p.ExpiresAt then
                    text = text .. string.format("\nStar leaves in %d s", math.ceil(p.ExpiresAt - serverNow()))
                end
                text = text .. "\nStars caught this session: " .. star.caught
                if text ~= last then
                    last = text
                    pcall(setParagraph, star.statusRef, text)
                end
                task.wait(1)
            end
        end)
        StarSection:AddParagraph({
            Title = "How It Works",
            Content = "Rare night event: your star lands in the Cosmic area for 2-5 min.\n"
                .. "Lynx flies there, catches it and comes back.",
        })
        star.ref = StarSection:AddToggle({
            Title    = "Auto Collect Star",
            Default  = false,
            Callback = function(on)
                if on and not hook() then
                    notify("Shooting Star", "Shooting Star remotes not found (event removed?).",
                        Color3.fromRGB(255, 90, 90), 3)
                    if star.ref then pcall(function() star.ref:SetValue(false) end) end
                    return
                end
                star.enabled = on == true
                if star.enabled then askState() end
            end,
        })
        table.insert(_G.LynxSAE.Stoppers, function()
            star.live, star.enabled = false, false
            for _, conn in ipairs(star.conns) do pcall(function() conn:Disconnect() end) end
            star.conns = {}
            Control.Want("star", 0)
            Status.starDueAt = nil
            Control.Release("star")
        end)
    end
    -- The Hollow (Halloween race): enter, autopilot along the track, use power-ups, leave at the finish.
    (function()
        local LOCK        = "hollowrace"
        local FLY_HEIGHT  = 7
        local FLY_AHEAD   = 20
        local FLY_DRIFT   = 25
        local FLY_BACK    = 15
        local FLY_REACH   = 250
        local SIDE_MAX    = 30
        local SIDE_RATE   = 55
        local SIDE_RAMP   = 160
        local SIDE_CHORD  = 25
        local CALM_BACK   = 150
        local CALM_AHEAD  = 250
        local HAZARD_LOOK = 1.3
        local HAZARD_BACK = 90
        local HAZARD_GAP  = 9
        local FIND_EVERY  = 2
        local USE_GAP     = 0.5
        local LEAVE_DELAY = 0.5
        local LEAVE_TRIES = 6
        local ENTER_WAIT  = 20
        local JOIN_RETRY  = 10
        local race = {
            live = true, drive = false, join = false, status = "Off",
            enterUntil = 0, nextJoin = 0, finished = false,
        }
        local mods = {}
        local function module(name, path)
            if mods[name] == nil then
                local ok, value = pcall(function() return require(path()) end)
                mods[name] = ok and value or false
            end
            return mods[name] or nil
        end
        local function mountData() return module("mount", function() return ReplicatedStorage.Data.MountRace end) end
        local function trackPathClass() return module("path", function() return ReplicatedStorage.Shared.Modules.RaceTrackPath end) end
        local function raceFlags() return module("flags", function() return ReplicatedStorage.Shared.Flags.MountRaceFlags end) end
        local function hollowFlags() return module("hollow", function() return ReplicatedStorage.Shared.Flags.TheHollowFlags end) end
        local function powerUps() return module("powerups", function() return ReplicatedStorage.Data.RacePowerUps end) end
        local function remotes() return module("remotes", function() return ReplicatedStorage.Shared.Remotes end) end
        local function trace(text, ...)
            local sink = rawget(_G, "LynxRaceTrace")
            if type(sink) == "function" then pcall(sink, string.format(text, ...)) end
        end
        local function serverNow() return workspace:GetServerTimeNow() end
        local function inRace() return LocalPlayer:GetAttribute("RaceId") ~= nil end
        local function track()
            local name = LocalPlayer:GetAttribute("RaceId")
            return workspace:FindFirstChild(type(name) == "string" and name or "TheHollowTrack")
        end
        local function raceState()
            local t = track()
            if not t then return nil end
            local heat = LocalPlayer:GetAttribute("RaceHeat")
            if type(heat) ~= "string" then return t end
            local heats = t:FindFirstChild("RaceHeats")
            return heats and heats:FindFirstChild(heat) or nil
        end
        local function phase()
            local state = raceState()
            return state and state:GetAttribute("RacePhase")
        end
        local function wins()
            local save = Game.Save and Game.Save.Get()
            local state = save and save.TheHollow
            return type(state) == "table" and tonumber(state.Wins) or 0
        end
        local function winsGoal()
            local ok, value = pcall(function() return hollowFlags().WinsForBadge:Get() end)
            return ok and tonumber(value) or 3
        end
        local function contentOn()
            local ok, value = pcall(function() return hollowFlags().ContentEnabled:Get() end)
            return ok and value == true
        end
        local pathCache, mountCtl, nextFind = nil, nil, 0
        local topCache, topAt = 120, -math.huge
        local function topSpeed()
            if os.clock() - topAt > 5 then
                topAt = os.clock()
                local ok, value = pcall(function() return raceFlags().TopSpeed:Get() end)
                topCache = ok and tonumber(value) or topCache
            end
            return topCache
        end
        local function racePath()
            local t = track()
            local points = t and t:FindFirstChild("AttachmentTrack")
            if not points then return nil end
            if pathCache and pathCache.folder == points then return pathCache end
            local class = trackPathClass()
            local ok, path = pcall(function() return class.new(points) end)
            pathCache = ok and { folder = points, path = path, pads = {}, boxes = {}, calm = {}, marksAt = 0 } or nil
            return pathCache
        end
        local function axesAt(path, s)
            local i, base = path:Locate(s)
            local j = i % path.Count + 1
            local t = math.clamp((s - base - path.Starts[i]) / path.Lengths[i], 0, 1)
            local pos = path.Points[i]:Lerp(path.Points[j], t)
            local chord = path:FrameAt(s + SIDE_CHORD).Position - path:FrameAt(s - SIDE_CHORD).Position
            local look = chord.Magnitude > 0.001 and chord.Unit or path:FrameAt(s).LookVector
            local up = path.Ups[i]:Lerp(path.Ups[j], t)
            up = up - look * up:Dot(look)
            up = up.Magnitude > 0.001 and up.Unit or Vector3.yAxis
            return pos, look:Cross(up).Unit, up, look
        end
        local function placeAt(path, s, side)
            local pos, right, up = axesAt(path, s)
            return pos + right * side + up * FLY_HEIGHT
        end
        local function sideOf(path, s, position)
            local pos, right = axesAt(path, s)
            return (position - pos):Dot(right)
        end
        local function gap(path, s1, s2)
            local d = (s2 - s1) % path.Length
            return d > path.Length / 2 and d - path.Length or d
        end
        local function trackMarks(cache)
            if #cache.pads > 0 or os.clock() < cache.marksAt then return end
            cache.marksAt = os.clock() + 5
            local t, data, flags = track(), mountData(), raceFlags()
            if not (t and data and flags) then return end
            local tags, path = game:GetService("CollectionService"), cache.path
            local half = path.Length / 2
            local function locate(position) return (path:Project(position, half, half, half)) end
            local function mark(model)
                local pad = model:IsDescendantOf(t) and model:FindFirstChild("Pad")
                if not (pad and pad:IsA("BasePart")) then return nil end
                local s = locate(pad.Position)
                return { model = model, part = pad, s = s, side = sideOf(path, s, pad.Position), half = math.max(pad.Size.X, pad.Size.Z) / 2 }
            end
            local pads, boxes, calm = {}, {}, {}
            for _, model in ipairs(tags:GetTagged(data.ComponentTags.BoostPad)) do
                local pad = mark(model)
                if pad then
                    pad.scale   = tonumber(model:GetAttribute("BoostMultiplier")) or flags.BoostPadMultiplier:Get()
                    pad.seconds = tonumber(model:GetAttribute("BoostSeconds")) or flags.BoostPadSeconds:Get()
                    table.insert(pads, pad)
                end
            end
            for _, model in ipairs(tags:GetTagged(data.ComponentTags.PowerUpSpawn)) do
                local box = mark(model)
                if box then table.insert(boxes, box) end
            end
            for _, tag in ipairs({ data.ComponentTags.Jump, data.ComponentTags.LoopTheLoop }) do
                for _, model in ipairs(tags:GetTagged(tag)) do
                    if model:IsDescendantOf(t) then
                        table.insert(calm, locate(model:IsA("Model") and model:GetPivot().Position or model.Position))
                    end
                end
            end
            cache.pads, cache.boxes, cache.calm = pads, boxes, calm
            trace("track marks: %d boost pads, %d item boxes, %d calm zones", #pads, #boxes, #calm)
        end
        local hazards, hazardConn = {}, nil
        local function watchHazards()
            if hazardConn then return end
            local net = remotes()
            local moment = net and net.MountRace and net.MountRace.PowerUpMoment
            local items = powerUps()
            if not (moment and items) then return end
            local tuning = items.Tuning
            hazardConn = moment.OnClientEvent:Connect(function(kind, id, owner, a, b, c)
                pcall(function()
                    if kind == "Egg" and typeof(a) == "CFrame" then
                        hazards[id] = { pos = a.Position, radius = tuning.EggRadius, untilAt = serverNow() + tuning.EggSeconds }
                    elseif kind == "Spike" and owner == LocalPlayer then
                        return
                    elseif kind == "Spike" and typeof(a) == "Vector3" and typeof(b) == "Vector3" and type(c) == "number" then
                        local trail = items.SpikePath(a, b, topSpeed() * tuning.SpikeSpeed, items.Params(track()))
                        hazards[id] = { trail = trail, start = c, radius = tuning.SpikeRadius, untilAt = c + tuning.SpikeSeconds }
                    elseif kind == "DrillaWarn" and typeof(a) == "Vector3" and type(b) == "number" then
                        hazards[id] = { pos = a, radius = tuning.DrillaRadius, untilAt = b + 1 }
                    elseif kind == "EggEnd" or kind == "SpikeEnd" or kind == "DrillaEnd" or kind == "Clear" then
                        hazards[id] = nil
                    end
                end)
            end)
        end
        -- Item boxes are picked up by the game when the mount crosses their pad, so steer over a ready one.
        local function boxSide(cache, s)
            if LocalPlayer:GetAttribute("RacePowerUp") ~= nil then return nil end
            local items = powerUps()
            local heat = LocalPlayer:GetAttribute("RaceHeat")
            local attr = items and items.BoxAttribute(type(heat) == "string" and heat or nil)
            local now, best = serverNow(), nil
            for _, box in ipairs(cache.boxes) do
                local d = gap(cache.path, box.s, s)
                if d > -(box.half + SIDE_RAMP) and d < box.half and box.part.Parent then
                    local readyAt = attr and box.model:GetAttribute(attr)
                    if not (type(readyAt) == "number" and readyAt > now)
                        and (not best or math.abs(box.side - cache.side) < math.abs(best - cache.side)) then
                        best = box.side
                    end
                end
            end
            return best and math.clamp(best, -SIDE_MAX, SIDE_MAX) or nil
        end
        local function lineSide(cache, s, speed)
            local path = cache.path
            for _, at in ipairs(cache.calm) do
                local d = gap(path, at, s)
                if d > -CALM_BACK and d < CALM_AHEAD then return 0 end
            end
            local want
            for _, pad in ipairs(cache.pads) do
                local d = gap(path, pad.s, s)
                if d > -(pad.half + SIDE_RAMP) and d < pad.half then
                    want = math.clamp(pad.side, -SIDE_MAX, SIDE_MAX)
                    break
                end
            end
            want = want or boxSide(cache, s) or 0
            local now, blocks, items = serverNow(), {}, powerUps()
            for id, hazard in pairs(hazards) do
                if now > hazard.untilAt then
                    hazards[id] = nil
                else
                    local pos = hazard.pos
                    if hazard.trail and items then pos = items.PathAt(hazard.trail, now - hazard.start) end
                    local hs, off = path:Project(pos, s, hazard.trail and HAZARD_BACK or 15, speed * HAZARD_LOOK)
                    if off < SIDE_MAX + hazard.radius + HAZARD_GAP then
                        local h, room = sideOf(path, hs, pos), hazard.radius + HAZARD_GAP
                        table.insert(blocks, { h - room, h + room })
                    end
                end
            end
            if #blocks == 0 then return want end
            local function free(x)
                if math.abs(x) > SIDE_MAX then return false end
                for _, block in ipairs(blocks) do
                    if x > block[1] and x < block[2] then return false end
                end
                return true
            end
            if free(want) then return want end
            local best
            for _, block in ipairs(blocks) do
                for _, x in ipairs(block) do
                    if free(x) and (not best or math.abs(x - want) < math.abs(best - want)) then best = x end
                end
            end
            return best or want
        end
        local function liveMount(value, root)
            if type(value) ~= "table" then return false end
            local rig, align = rawget(value, "Rig"), rawget(value, "Align")
            return type(rig) == "table" and rig.Root == root
                and typeof(align) == "Instance" and align.Parent ~= nil
        end
        local function findMount()
            local _, root = getCharacter()
            if not root then return nil end
            if liveMount(mountCtl, root) then return mountCtl end
            mountCtl = nil
            if os.clock() < nextFind or type(getgc) ~= "function" then return nil end
            nextFind = os.clock() + FIND_EVERY
            for _, value in ipairs(getgc(true)) do
                if type(value) == "table" and rawget(value, "Push") ~= nil and liveMount(value, root) then
                    mountCtl = value
                    if pathCache then pathCache.progress, pathCache.goal, pathCache.speed = nil, nil, nil end
                    trace("mount controller found")
                    break
                end
            end
            return mountCtl
        end
        -- Same idea as the game's Skywhale: ride the track spline instead of steering the mount.
        local function fly(ctl, dt)
            local cache = racePath()
            local root = ctl.Rig and ctl.Rig.Root
            if not (cache and root) then return end
            local path, top = cache.path, topSpeed()
            trackMarks(cache)
            if not cache.progress then
                local half = path.Length / 2
                cache.progress, cache.goal = path:Project(root.Position, half, half, half), nil
            elseif not cache.goal or (root.Position - cache.goal).Magnitude > FLY_DRIFT then
                cache.progress, cache.goal = path:Project(root.Position, cache.progress, FLY_BACK, FLY_REACH), nil
            end
            if not cache.goal then
                cache.side = math.clamp(sideOf(path, cache.progress, root.Position), -SIDE_MAX, SIDE_MAX)
            end
            local okScale, scale = pcall(function() return ctl:TopSpeedScale() end)
            local target = top * (okScale and tonumber(scale) or 1)
            local speed = cache.speed or target
            speed = target >= speed and target or math.max(target, speed - top / 3 * dt)
            cache.speed = speed
            local want = lineSide(cache, cache.progress, speed)
            local side = cache.side + math.clamp(want - cache.side, -SIDE_RATE * dt, SIDE_RATE * dt)
            local step = speed * dt
            local s = cache.progress + step
            local goal = placeAt(path, s, side)
            if cache.goal then
                local moved = (goal - cache.goal).Magnitude
                if moved > 0.001 then
                    s = cache.progress + step * math.min(step / moved, 1.5)
                    goal = placeAt(path, s, side)
                end
            end
            local before = cache.goal
            cache.progress, cache.side, cache.goal = s, side, goal
            local _, _, up, look = axesAt(path, s)
            local line = placeAt(path, s + FLY_AHEAD, side + (want - side) * 0.5) - goal
            local dir  = line.Magnitude > 0.001 and line.Unit or look
            for _, pad in ipairs(cache.pads) do
                local inside = false
                if pad.part.Parent then
                    local rel, size = pad.part.CFrame:PointToObjectSpace(goal), pad.part.Size / 2
                    inside = math.abs(rel.X) <= size.X + 1 and math.abs(rel.Z) <= size.Z + 1
                        and math.abs(rel.Y) <= size.Y + FLY_HEIGHT + 4
                end
                if inside and not pad.inside then
                    pcall(function() ctl:ApplyBoost(pad.scale, pad.seconds) end)
                    trace("boost pad at %.0f (side %.0f)", pad.s, side)
                end
                pad.inside = inside
            end
            ctl.Drive.Enabled = false
            ctl.Push.Force = Vector3.new(0, 1, 0) * root.AssemblyMass * workspace.Gravity
            ctl.Align.CFrame = CFrame.lookAt(Vector3.zero, dir, up)
            root.CFrame = CFrame.new(goal) * ctl.Align.CFrame
            root.AssemblyLinearVelocity  = before and dt > 0 and (goal - before) / dt or dir * speed
            root.AssemblyAngularVelocity = Vector3.zero
            ctl.Up, ctl.Heading, ctl.TravelDirection = up, dir, dir
            ctl.Speed, ctl.Grounded, ctl.AirSeconds, ctl.Launched = speed, false, 0, true
        end
        local function land(ctl)
            if not (ctl and ctl.Override == fly) then return end
            ctl.Override = nil
            pcall(function()
                local root = ctl.Rig.Root
                ctl.Push.Force = Vector3.zero
                ctl.Drive.Enabled = true
                root.AssemblyLinearVelocity = ctl.Heading * topSpeed()
                ctl.Speed, ctl.IgnoreGroundUntil = topSpeed(), 0
            end)
        end
        local function autopilotStep()
            local ctl = findMount()
            if not ctl then return end
            watchHazards()
            if ctl.Override ~= nil and ctl.Override ~= fly then
                -- Skywhale or a stun owns the mount for now; keep our progress with it.
                local cache = racePath()
                local root = ctl.Rig and ctl.Rig.Root
                if cache and cache.progress and root then
                    cache.progress = cache.path:Project(root.Position, cache.progress, FLY_BACK, FLY_REACH)
                    cache.goal = nil
                end
                return
            end
            if ctl.Override == nil then
                if pathCache then pathCache.goal, pathCache.speed = nil, nil end
                ctl.Override = fly
                trace("autopilot on")
            end
        end
        local nextUse = 0
        local function useItem()
            if os.clock() < nextUse then return end
            local item = LocalPlayer:GetAttribute("RacePowerUp")
            if type(item) ~= "string" then return end
            local now = serverNow()
            local function future(name)
                local value = LocalPlayer:GetAttribute(name)
                return type(value) == "number" and now < value
            end
            if future("RacePowerUpRollEndsAt") or future("RacePowerUpEffectEndsAt")
                or future("RacePowerUpStunEndsAt") then return end
            local net = remotes()
            local _, root = getCharacter()
            if not (net and net.MountRace and root) then return end
            nextUse = os.clock() + USE_GAP
            local heading = mountCtl and mountCtl.Heading or root.CFrame.LookVector
            pcall(function() net.MountRace.PowerUp:FireServer("Use", root.Position, heading) end)
            trace("used %s", item)
        end
        local function leaveRace()
            for _ = 1, LEAVE_TRIES do
                task.wait(LEAVE_DELAY)
                if not (race.drive and inRace() and race.finished) then return end
                local net = remotes()
                pcall(function() net.MountRace.AskLeave:FireServer() end)
                trace("asked to leave")
            end
        end
        local function enterRace()
            if not Treadmill.Leave(3) then return false, "Could not leave the treadmill" end
            Movement.SoftenHumanoid()
            Movement.RestoreHumanoid()
            race.status = "Entering The Hollow"
            local net = remotes()
            local ok, done, why = pcall(function() return net.TheHollow.AskEnter:InvokeServer() end)
            trace("AskEnter -> %s %s %s", tostring(ok), tostring(done), tostring(why))
            if not (ok and done) then return false, ok and why or "Request failed" end
            local deadline = os.clock() + 5
            while not inRace() and os.clock() < deadline do task.wait(0.1) end
            return inRace(), "Server did not put us in a race"
        end
        local function wantsJoin()
            if os.clock() < race.enterUntil then return true end
            return race.join and os.clock() >= race.nextJoin and wins() < winsGoal()
        end
        task.spawn(function()
            while race.live do
                if inRace() then
                    Control.Want(LOCK, 3)
                    if not Control.Owns(LOCK) then Control.Acquire(LOCK, true) end
                    Control.Hold(LOCK)
                    race.enterUntil = 0
                    local p = phase()
                    race.status = race.finished and "Finished, leaving the race"
                        or p == "Racing" and (race.drive and "Racing (autopilot)" or "Racing (autopilot off)")
                        or ("Waiting for the start (" .. tostring(p or "joining") .. ")")
                elseif wantsJoin() and contentOn() then
                    Control.Want(LOCK, 3)
                    if Control.Acquire(LOCK, true) then
                        local ok, inside, why = pcall(enterRace)
                        if not (ok and inside) then
                            local reason = tostring(ok and why or inside)
                            race.status = "Could not enter: " .. reason
                            if os.clock() < race.enterUntil then
                                notify("The Hollow", "Could not enter the race: " .. reason, Color3.fromRGB(255, 90, 90), 3)
                            end
                            race.enterUntil, race.nextJoin = 0, os.clock() + JOIN_RETRY
                            Control.Release(LOCK)
                        end
                    else
                        race.status = "Waiting for " .. tostring(Control.Holder() or "another feature")
                    end
                else
                    if race.enterUntil > 0 then
                        race.enterUntil = 0
                        notify("The Hollow", "Could not enter the race, try again.", Color3.fromRGB(255, 90, 90), 3)
                    end
                    if Control.Owns(LOCK) then Control.Release(LOCK) end
                    Control.Want(LOCK, 0)
                    race.status = not contentOn() and "The Hollow is not available"
                        or race.join and wins() >= winsGoal() and "All Hollow prizes earned"
                        or (race.drive or race.join) and "Waiting" or "Off"
                end
                task.wait(inRace() and 0.5 or 0.25)
            end
        end)
        local finishConn = LocalPlayer:GetAttributeChangedSignal("RaceFinishPlace"):Connect(function()
            if inRace() and LocalPlayer:GetAttribute("RaceFinishPlace") ~= nil then
                race.finished = true
                trace("finished in place %s", tostring(LocalPlayer:GetAttribute("RaceFinishPlace")))
                if race.drive then task.spawn(leaveRace) end
            end
        end)
        local raceIdConn = LocalPlayer:GetAttributeChangedSignal("RaceId"):Connect(function()
            race.finished = false
            if not inRace() then race.nextJoin = os.clock() + 3 end
        end)
        local driveConn = RunService.Heartbeat:Connect(function()
            local going = race.drive and inRace() and phase() == "Racing" and not race.finished
            if going then
                pcall(autopilotStep)
                pcall(useItem)
            elseif mountCtl and mountCtl.Override == fly then
                land(mountCtl)
            end
            if not going and pathCache then
                pathCache.progress, pathCache.goal, pathCache.speed, pathCache.side = nil, nil, nil, nil
            end
        end)
        local RaceSection = EventTab:AddSection("The Hollow Race")
        race.statusRef = RaceSection:AddParagraph({ Title = "Hollow Race Status", Content = "Off" })
        task.spawn(function()
            local last
            while race.live do
                local lines = { race.status }
                if inRace() then
                    lines[#lines + 1] = string.format("Lap %s, place %s",
                        tostring(LocalPlayer:GetAttribute("RaceLap") or "-"), tostring(LocalPlayer:GetAttribute("RacePlace") or "-"))
                end
                lines[#lines + 1] = string.format("Wins %d / %d", wins(), winsGoal())
                local text = table.concat(lines, "\n")
                if text ~= last then
                    last = text
                    pcall(setParagraph, race.statusRef, text)
                end
                task.wait(1)
            end
        end)
        RaceSection:AddParagraph({
            Title = "How It Works",
            Content = "Autopilot drives the track at normal top speed, takes boost pads and item boxes,\n"
                .. "dodges hazards, uses items and leaves when the race is over.\n"
                .. "Auto Join keeps entering until the 3-win grand prize.",
        })
        RaceSection:AddToggle({
            Title    = "Autopilot Hollow Race",
            Default  = false,
            Callback = function(on)
                race.drive = on == true
                if race.drive and race.finished and inRace() then task.spawn(leaveRace) end
            end,
        })
        RaceSection:AddToggle({
            Title    = "Auto Join Hollow Race",
            Default  = false,
            Callback = function(on) race.join, race.nextJoin = on == true, 0 end,
        })
        RaceSection:AddButton({
            Title    = "Enter Hollow Race",
            Callback = function()
                if inRace() then
                    notify("The Hollow", "Already in a race.", Color3.fromRGB(255, 196, 0), 2)
                elseif not contentOn() then
                    notify("The Hollow", "The Hollow is not available right now.", Color3.fromRGB(255, 90, 90), 3)
                else
                    race.enterUntil = os.clock() + ENTER_WAIT
                end
            end,
        })
        table.insert(_G.LynxSAE.Stoppers, function()
            race.live = false
            driveConn:Disconnect()
            finishConn:Disconnect()
            raceIdConn:Disconnect()
            if hazardConn then hazardConn:Disconnect() end
            pcall(land, mountCtl)
            Control.Want(LOCK, 0)
            Control.Release(LOCK)
        end)
    end)()
end
task.wait()
do
    local AutomationTab = MainWindow:AddTab({ Name = "Automation", Icon = "next" })
    do
        local _auto = {
            placeEnabled = false, placeThread = nil, placeRef = nil,
            hatchEnabled = false, hatchThread = nil, hatchRef = nil,
            moveSpeed    = 620, swapped     = false, generation = 0,
            useRarity    = false, selectedRarity = {},
            useMutation  = false, selectedMut    = {},
            useWeight    = false, minWeight      = 0,
        }
        local PLACE_STEP    = 3
        local PLACE_EDGE    = 4
        local function eggInventory()
            local save = Game.Save and Game.Save.Get()
            if not save or type(save.EggInventory) ~= "table" then return nil end
            return save.EggInventory
        end
        local function passesPlaceFilter(entry)
            if not (_auto.useRarity or _auto.useMutation or _auto.useWeight) then
                return true
            end
            local ok, record = pcall(Game.EggRecords.Decode, entry)
            if not ok or not record then return false end
            if _auto.useRarity and not isSetEmpty(_auto.selectedRarity) then
                local category = record.AssetCategory or record.Category
                local data = category and Game.Assets and Game.Assets.Directory
                    and Game.Assets.Directory[category]
                local rarity = data and data.Rarity and data.Rarity.DisplayName
                if not rarity or not _auto.selectedRarity[rarity] then return false end
            end
            if _auto.useMutation and not isSetEmpty(_auto.selectedMut) then
                local labels = {}
                if Game.Mutations then
                    for _, id in ipairs(record.Mutations or {}) do
                        labels[#labels + 1] = tostring(Game.Mutations.LabelOf(id) or id)
                    end
                end
                local matched = false
                if #labels == 0 then
                    matched = _auto.selectedMut["None"] == true
                else
                    for _, label in ipairs(labels) do
                        if _auto.selectedMut[label] then matched = true break end
                    end
                end
                if not matched then return false end
            end
            if _auto.useWeight then
                local okWeight, weight = pcall(Game.EggRecords.WeightKg, record)
                if not okWeight or type(weight) ~= "number" then return false end
                if weight < _auto.minWeight then return false end
            end
            return true
        end
        local function placementParams()
            local ok, plot = pcall(Game.PlotState.ResolvePlot)
            if not ok or not plot or not plot.CenterPoint or not plot.PetArea then return nil end
            local targets = { plot.PetArea }
            pcall(function()
                require(ReplicatedStorage.Shared.Eggs.PlacedEggRenderer)
                    .AppendRaycastTargets(targets, LocalPlayer.UserId)
            end)
            local params = RaycastParams.new()
            params.FilterType = Enum.RaycastFilterType.Include
            params.FilterDescendantsInstances = targets
            params.IgnoreWater = true
            return params, plot
        end
        local function placedPoints()
            local points = {}
            local inventory = eggInventory()
            for _, entry in pairs(inventory or {}) do
                if entry.Placement ~= nil then
                    local ok, decoded = pcall(Game.EggRecords.DecodePlacement, entry.Placement)
                    if ok and decoded and typeof(decoded.LocalCFrame) == "CFrame" then
                        points[#points + 1] =
                            Vector3.new(decoded.LocalCFrame.X, 0, decoded.LocalCFrame.Z)
                    end
                end
            end
            return points
        end
        local function candidateSpots()
            local params, plot = placementParams()
            if not params then return {} end
            local center, petArea = plot.CenterPoint, plot.PetArea
            local halfX = petArea.Size.X / 2 - PLACE_EDGE
            local halfZ = petArea.Size.Z / 2 - PLACE_EDGE
            if halfX <= 0 or halfZ <= 0 then return {} end
            local placed = placedPoints()
            local spots, rays = {}, 0
            for dx = -halfX, halfX, PLACE_STEP do
                for dz = -halfZ, halfZ, PLACE_STEP do
                    rays = rays + 1
                    if rays % 60 == 0 then task.wait() end
                    local world = petArea.Position + Vector3.new(dx, 0, dz)
                    local hit = workspace:Raycast(
                        world + Vector3.new(0, 40, 0), Vector3.new(0, -80, 0), params)
                    if hit and hit.Instance == petArea then
                        local point = center.CFrame:ToObjectSpace(CFrame.new(hit.Position))
                        local flat  = Vector3.new(point.X, 0, point.Z)
                        local near  = math.huge
                        for _, taken in ipairs(placed) do
                            local gap = (taken - flat).Magnitude
                            if gap < near then near = gap end
                        end
                        spots[#spots + 1] = { cframe = point, near = near }
                    end
                end
            end
            table.sort(spots, function(a, b) return a.near < b.near end)
            local ordered = {}
            for index, spot in ipairs(spots) do ordered[index] = spot.cframe end
            return ordered
        end
        local function moveToPlot()
            local ok, plot = pcall(Game.PlotState.ResolvePlot)
            if not ok or not plot or not plot.CenterPoint then return false end
            local _, root = getCharacter()
            local target  = plot.CenterPoint.Position + Vector3.new(0, 4, 0)
            if root and (target - root.Position).Magnitude <= 10 then return true end
            Movement.SwapHumanoid()
            _auto.swapped = true
            return Movement.ToVia(target, 10, _auto.moveSpeed, function()
                return Control.Active()
            end)
        end
        local function placeOne(uid)
            Treadmill.Leave()
            if not moveToPlot() then return false end
            if not pcall(Game.EggState.WearEggTool, uid) then return false end
            local function heldEgg()
                local character = LocalPlayer.Character
                if not character then return nil end
                for _, tool in ipairs(character:GetChildren()) do
                    if tool:IsA("Tool") and tool:GetAttribute("UID") == uid then return tool end
                end
                return nil
            end
            local function giveUp(why)
                pcall(Game.EggState.DoffEggTool)
                return false, why
            end
            local deadline = os.clock() + 2
            while not heldEgg() and os.clock() < deadline do
                if not Control.Active() then return giveUp() end
                task.wait(0.03)
            end
            if not heldEgg() then return giveUp() end
            local lastWhy = nil
            for index, spot in ipairs(candidateSpots()) do
                if not Control.Active() then return giveUp() end
                if index > 40 then break end
                local ok, accepted, why = pcall(Game.EggState.PlantEgg, uid, spot)
                if ok and accepted then return true end
                if ok and type(why) == "string" then
                    lastWhy = why
                    if why:lower():find("max") or why:lower():find("full")
                        or why:lower():find("limit") then
                        return giveUp("full")
                    end
                end
                task.wait(0.05)
            end
            return giveUp(lastWhy or "full")
        end
        local _placeRest = { untilAt = 0, placed = 0 }
        local function placedCount(inventory)
            local count = 0
            for _, entry in pairs(inventory) do
                if entry.Placement ~= nil then count = count + 1 end
            end
            return count
        end
        local function placeCap()
            local limits = Game.Balance and Game.Balance.EggInventory
            return tonumber(limits and limits.MAX_PLACED_EGGS) or 30
        end
        local function plotFull(inventory)
            local cap = placeCap()
            local placed = placedCount(inventory)
            return placed >= cap, placed, cap
        end
        local _placeFail, _placeSkip = {}, {}
        local function nextPending(inventory)
            local now, soonest = os.clock(), nil
            for uid, entry in pairs(inventory) do
                local questEgg = Status.WispFuseWants and Status.WispFuseWants(entry.AssetCategory)
                if entry.Placement == nil and (questEgg or passesPlaceFilter(entry)) then
                    local until_ = _placeSkip[uid]
                    if not until_ or now >= until_ then
                        return uid, false
                    end
                    if not soonest or until_ < soonest then soonest = until_ end
                end
            end
            return nil, soonest ~= nil
        end
        local function pendingCount(inventory)
            local count, now = 0, os.clock()
            for uid, entry in pairs(inventory) do
                local questEgg = Status.WispFuseWants and Status.WispFuseWants(entry.AssetCategory)
                if entry.Placement == nil and (questEgg or passesPlaceFilter(entry)) and now >= (_placeSkip[uid] or 0) then
                    count = count + 1
                end
            end
            return count
        end
        local function worthTheTrip(inventory)
            if not (Status.inHalloween and Status.inHalloween()) then return true end
            local _, placed, cap = plotFull(inventory)
            return math.min(pendingCount(inventory), cap - placed) >= math.min(5, cap)
        end
        local function noteResult(uid, ok)
            if ok then
                _placeFail[uid] = nil
                _placeSkip[uid] = nil
                return
            end
            local count = (_placeFail[uid] or 0) + 1
            _placeFail[uid] = count
            if count >= 2 then
                _placeSkip[uid] = os.clock() + 45
                _placeFail[uid] = 0
            end
        end
        local function stopPlace()
            _placeFail, _placeSkip = {}, {}
            _auto.placeEnabled = false
            _auto.generation   = _auto.generation + 1
            Control.Release("place")
            if _auto.placeThread then
                pcall(task.cancel, _auto.placeThread)
                _auto.placeThread = nil
            end
            if _auto.swapped then
                _auto.swapped = false
                task.spawn(Movement.RestartAnimate)
            end
        end
        local function stopHatch()
            _auto.hatchEnabled = false
            Status.hatching    = false
            if _auto.hatchThread then
                pcall(task.cancel, _auto.hatchThread)
                _auto.hatchThread = nil
            end
        end
        table.insert(_G.LynxSAE.Stoppers, stopPlace)
        table.insert(_G.LynxSAE.Stoppers, stopHatch)
        local function buildPlaceRarityOptions()
            local seen, ranked = {}, {}
            if Game.Assets and Game.Assets.Directory then
                for _, data in pairs(Game.Assets.Directory) do
                    local rarity = data.Rarity
                    local name   = rarity and rarity.DisplayName
                    if name and not seen[name] then
                        seen[name] = true
                        table.insert(ranked, { name = name, rank = rarity.Rank or 0 })
                    end
                end
            end
            table.sort(ranked, function(a, b)
                if a.rank == b.rank then return a.name < b.name end
                return a.rank < b.rank
            end)
            local options = {}
            for _, entry in ipairs(ranked) do table.insert(options, entry.name) end
            if #options == 0 then options = { "Loading..." } end
            return options
        end
        local function buildPlaceMutationOptions()
            local options = { "None" }
            if Game.Mutations and Game.Mutations.All then
                local labels = {}
                for id in pairs(Game.Mutations.All()) do
                    table.insert(labels, tostring(Game.Mutations.LabelOf(id) or id))
                end
                table.sort(labels)
                for _, label in ipairs(labels) do table.insert(options, label) end
            end
            return options
        end
        local PlaceFilterSection = AutomationTab:AddSection("Place Filter")
        PlaceFilterSection:AddToggle({
            Title    = "Place Filter Rarity",
            Default  = false,
            Callback = function(on) _auto.useRarity = on end,
        })
        PlaceFilterSection:AddDropdown({
            Title    = "Place Rarity",
            Multi    = true,
            Options  = buildPlaceRarityOptions(),
            Default  = {},
            Callback = function(selected)
                _auto.selectedRarity = toSet(type(selected) == "table" and selected or {})
            end,
        })
        PlaceFilterSection:AddToggle({
            Title    = "Place Filter Mutation",
            Default  = false,
            Callback = function(on) _auto.useMutation = on end,
        })
        PlaceFilterSection:AddDropdown({
            Title    = "Place Mutation",
            Multi    = true,
            Options  = buildPlaceMutationOptions(),
            Default  = {},
            Callback = function(selected)
                _auto.selectedMut = toSet(type(selected) == "table" and selected or {})
            end,
        })
        PlaceFilterSection:AddToggle({
            Title    = "Filter Minimum Place Weight",
            Default  = false,
            Callback = function(on) _auto.useWeight = on end,
        })
        PlaceFilterSection:AddInput({
            Title    = "Minimum Place Weight (kg)",
            Default  = "0",
            Callback = function(value)
                local weight = tonumber(value)
                if weight and weight >= 0 then _auto.minWeight = weight end
            end,
        })
        local AutomationSection = AutomationTab:AddSection("Egg Automation")
        _auto.placeRef = AutomationSection:AddToggle({
            Title    = "Auto Place Eggs",
            Default  = false,
            Callback = function(on)
                stopPlace()
                if not on then return end
                if not Game.Init() or not Game.Save or not Game.EggState then
                    notify("Auto Place Eggs", "Belum siap: " .. Game.MissingText(),
                        Color3.fromRGB(255, 90, 90), 3)
                    if _auto.placeRef then pcall(function() _auto.placeRef:SetValue(false) end) end
                    return
                end
                _auto.placeEnabled = true
                _auto.generation   = _auto.generation + 1
                local generation   = _auto.generation
                _auto.placeThread = task.spawn(function()
                    afterConfigLoad()
                    Control.SetGuard(function()
                        return _auto.placeEnabled
                            and _auto.generation == generation
                            and Control.Owns("place")
                    end)
                    while _auto.placeEnabled and _auto.generation == generation do
                        pcall(function()
                            local function rest(seconds)
                                Control.Idle("place")
                                task.wait(seconds)
                            end
                            local inventory = eggInventory()
                            if not inventory then rest(2) return end
                            if plotFull(inventory) then rest(3) return end
                            if os.clock() < _placeRest.untilAt then
                                if placedCount(inventory) >= _placeRest.placed then
                                    rest(1)
                                    return
                                end
                                _placeRest.untilAt = 0
                            end
                            local pending, allResting = nextPending(inventory)
                            if not pending then rest(allResting and 5 or 3) return end
                            if not worthTheTrip(inventory) then rest(2) return end
                            Control.Want("place", 1.5)
                            if not Control.Acquire("place") then
                                task.wait(0.5)
                                return
                            end
                            local ok, why = placeOne(pending)
                            noteResult(pending, ok)
                            if why == "full" then
                                _placeRest.untilAt = os.clock() + 45
                                _placeRest.placed  = placedCount(eggInventory() or inventory)
                            end
                            if Control.Active() then Control.Release("place") end
                            task.wait(ok and 0.4 or 1)
                        end)
                        if _auto.generation == generation then Control.Release("place") end
                        task.wait()
                    end
                end)
            end,
        })
        _auto.hatchRef = AutomationSection:AddToggle({
            Title    = "Auto Hatch Eggs",
            Default  = false,
            Callback = function(on)
                stopHatch()
                if not on then return end
                if not Game.Init() or not Game.Save or not Game.EggState then
                    notify("Auto Hatch Eggs", "Belum siap: " .. Game.MissingText(),
                        Color3.fromRGB(255, 90, 90), 3)
                    if _auto.hatchRef then pcall(function() _auto.hatchRef:SetValue(false) end) end
                    return
                end
                _auto.hatchEnabled = true
                _auto.hatchThread = task.spawn(function()
                    local MECHA_UPGRADED = "MechaUpgraded"
                    pcall(function()
                        local ok, eggs = pcall(function()
                            return require(ReplicatedStorage.Shared.Types.Eggs)
                        end)
                        if ok and type(eggs) == "table"
                            and type(eggs.HATCH_RESULT_MECHA_UPGRADED) == "string" then
                            MECHA_UPGRADED = eggs.HATCH_RESULT_MECHA_UPGRADED
                        end
                    end)
                    while _auto.hatchEnabled do
                        pcall(function()
                            local inventory = eggInventory()
                            if not inventory then task.wait(2) return end
                            local hatched = 0
                            for uid, entry in pairs(inventory) do
                                if not _auto.hatchEnabled then break end
                                if entry.Placement ~= nil then
                                    local ok, ready = pcall(Game.EggState.IsReadyToHatch, uid)
                                    if ok and ready then
                                        Status.hatching = true
                                        local sent, began, _, result =
                                            pcall(Game.EggState.BeginHatch, uid)
                                        if sent and began == true then
                                            if result ~= MECHA_UPGRADED then
                                                pcall(Game.EggState.FinishHatch, uid)
                                            end
                                            hatched = hatched + 1
                                            task.wait()
                                        end
                                    end
                                end
                            end
                            Status.hatching = false
                            task.wait(hatched > 0 and 0.05 or 3)
                        end)
                        Status.hatching = false
                        task.wait()
                    end
                end)
            end,
        })
    end
    ;(function()
        local USE_GAP     = 2.6   
        local IDLE_WAIT   = 3
        local REFUSE_SKIP = 60    
        local KNOWN = { "Nitro", "Enchanted", "Boss" }
        local CHANCE = {
            Nitro     = { "RaceRallyFlags", "NitroSuccessPercent" },
            Scrambled = { "ScrambleMutationFlags", "SuccessPercent" },
            Boss      = { "BossMasteryFlags", "MutationConsumableSuccessPercent" },
        }
        local mut = {
            enabled = false, live = true, kinds = {}, rarity = {}, names = {}, status = "Off",
            tries = 0, hits = 0, skip = {}, done = {},
        }
        local function chanceOf(id)
            if id == "Enchanted" then return 100 end
            local ok, value = pcall(function()
                local flags = ReplicatedStorage.Shared.Flags
                local where = CHANCE[id]
                if where then return require(flags[where[1]])[where[2]]:Get() end
                for _, module in ipairs(flags:GetChildren()) do  
                    local entry = module:IsA("ModuleScript") and require(module)[id .. "SuccessPercent"]
                    if entry then return entry:Get() end
                end
            end)
            return ok and tonumber(value) or nil
        end
        local function ownedTools()
            local tools = {}
            for _, holder in ipairs({ LocalPlayer.Character, LocalPlayer:FindFirstChildOfClass("Backpack") }) do
                for _, tool in ipairs(holder and holder:GetChildren() or {}) do
                    if tool:IsA("Tool") and tool:GetAttribute("ItemType") == "MutationConsumable" then
                        table.insert(tools, tool)
                    end
                end
            end
            return tools
        end
        local function kindIds()
            local ids, seen = {}, {}
            for _, id in ipairs(KNOWN) do ids[#ids + 1], seen[id] = id, true end
            local extra = {}
            for _, tool in ipairs(ownedTools()) do
                local id = tostring(tool:GetAttribute("MutationId") or "Boss")
                if not seen[id] then seen[id] = true table.insert(extra, id) end
            end
            table.sort(extra)
            for _, id in ipairs(extra) do ids[#ids + 1] = id end
            return ids
        end
        local function consumable(id)
            for _, tool in ipairs(ownedTools()) do
                if tostring(tool:GetAttribute("MutationId") or "Boss") == id then return tool end
            end
            return nil
        end
        local function usesOf(id)
            local tool = consumable(id)
            return tool and (tonumber(tool:GetAttribute("Uses")) or 1) or 0
        end
        local function assetOf(entry)
            return Game.Assets and Game.Assets.Directory and Game.Assets.Directory[entry.AssetCategory]
        end
        local function rarityOf(entry)
            local data = assetOf(entry)
            local rarity = data and data.Rarity
            return rarity and rarity.DisplayName, tonumber(rarity and rarity.Rank) or 0
        end
        local function eggNameOf(entry)
            local data = assetOf(entry)
            return data and data.Egg and data.Egg.DisplayName or tostring(entry.AssetCategory or "egg")
        end
        local function passesFilter(entry)
            local rarity = rarityOf(entry)
            if not isSetEmpty(mut.rarity) and not (rarity and mut.rarity[rarity]) then return false end
            return isSetEmpty(mut.names) or mut.names[eggNameOf(entry)] == true
        end
        local function hasMutation(uid, entry, mutation)
            if mut.done[uid .. ":" .. mutation] or entry.BaseMutation == mutation then return true end
            for _, id in ipairs(type(entry.Mutations) == "table" and entry.Mutations or {}) do
                if id == mutation then return true end
            end
            return false
        end
        local function nextJob()
            local save = Game.Save and Game.Save.Get()
            local inventory = type(save) == "table" and save.EggInventory
            if type(inventory) ~= "table" then return nil, "Waiting for the save" end
            local holding, now = false, os.clock()
            for _, id in ipairs(kindIds()) do
                local tool = mut.kinds[id] and consumable(id)
                if tool then
                    holding = true
                    local mutation = tool:GetAttribute("MutationTemplate") or id
                    local best, bestRank = nil, -math.huge
                    for uid, entry in pairs(inventory) do
                        if entry.Placement ~= nil and (mut.skip[uid] or 0) <= now
                            and not hasMutation(uid, entry, mutation) and passesFilter(entry) then
                            local _, rank = rarityOf(entry)
                            if rank > bestRank then best, bestRank = uid, rank end
                        end
                    end
                    if best then
                        return { id = id, mutation = mutation, uid = best, entry = inventory[best] }
                    end
                end
            end
            if holding then return nil, "Every placed egg in the filter already has it" end
            return nil, "None of the picked mutations left in your Backpack"
        end
        local function holdTool(tool)
            local character = LocalPlayer.Character
            local humanoid = character and character:FindFirstChildOfClass("Humanoid")
            if not (humanoid and tool) then return false end
            if tool.Parent == character then return true end
            pcall(function() humanoid:EquipTool(tool) end)
            local deadline = os.clock() + 2
            while tool.Parent ~= character and os.clock() < deadline do task.wait(0.05) end
            task.wait(0.2) 
            return tool.Parent == character
        end
        local function letGo()
            local character = LocalPlayer.Character
            local humanoid = character and character:FindFirstChildOfClass("Humanoid")
            if not humanoid then return end
            for _, tool in ipairs(character:GetChildren()) do
                if tool:IsA("Tool") and tool:GetAttribute("ItemType") == "MutationConsumable" then
                    pcall(function() humanoid:UnequipTools() end)
                    return
                end
            end
        end
        local function release()
            if Control.Holder() == "mutate" then letGo() end
            Control.Release("mutate")
        end
        local function owns()
            return mut.live and mut.enabled and Control.Owns("mutate") and getCharacter() ~= nil
        end
        -- the server only takes the item within ~40 studs of the plot: walk there first
        local function nearPlot()
            local ok, plot = pcall(Game.PlotState.ResolvePlot)
            local center = ok and plot and plot.CenterPoint and plot.CenterPoint.Position
            local _, root = getCharacter()
            if not (center and root) then return false end
            if (root.Position - center).Magnitude <= 30 then return true end
            mut.status = "Going to your plot"
            Treadmill.Leave()
            Movement.SwapHumanoid()
            return Movement.ToVia(center + Vector3.new(0, 4, 0), 10, 620, owns) and owns()
        end
        local function apply(job)
            local id = job.id
            if not holdTool(consumable(id)) then
                mut.status = "Could not hold the " .. id .. " tool"
                return
            end
            local ok, result = pcall(function()
                return Game.Remotes.BossMastery.AskUseMutationConsumable:InvokeServer(job.uid)
            end)
            local name = eggNameOf(job.entry)
            local message = ok and type(result) == "table" and tostring(result.Message or "") or ""
            if not ok or type(result) ~= "table" then
                mut.skip[job.uid] = os.clock() + 5
                mut.status = "No answer from the server, retrying"
            elseif result.Success ~= true and (message:lower():find("far") or message:lower():find("closer")) then
                mut.status = "Too far from the plot: going closer"
            elseif result.Success ~= true then
                mut.skip[job.uid] = os.clock() + REFUSE_SKIP
                mut.status = string.format("%s refused on %s: %s", id, name, message ~= "" and message or "?")
            elseif result.Mutated == true then
                mut.tries, mut.hits = mut.tries + 1, mut.hits + 1
                mut.done[job.uid .. ":" .. job.mutation] = true
                mut.status = string.format("%s applied to %s!", id, name)
                notify("Auto Mutation Egg", id .. " applied to " .. name .. "!", Color3.fromRGB(80, 220, 255), 4)
            else
                mut.tries = mut.tries + 1
                local chance = chanceOf(id)
                mut.status = string.format("%s missed on %s (%s%% chance), trying again",
                    id, name, chance and tostring(chance) or "?")
            end
        end
        task.spawn(function()
            while mut.live do
                local pause = IDLE_WAIT
                if mut.enabled then
                    pcall(function()
                        if Control.Holder() == "mutate" and not Control.Owns("mutate") then release() end
                        local job, why = nextJob()
                        if not job then
                            mut.status = why
                            return
                        end
                        Control.Want("mutate", 3)
                        if not (Control.Acquire("mutate") and Control.Owns("mutate")) then
                            mut.status = "Waiting for " .. tostring(Control.Blocker("mutate", true) or Control.Holder() or "another feature")
                            pause = 0.5
                            return
                        end
                        if not nearPlot() then
                            pause = 0.5
                            return
                        end
                        apply(job)
                        pause = USE_GAP
                    end)
                end
                if pause == IDLE_WAIT then
                    Control.Want("mutate", 0)
                    Control.Idle("mutate")
                    release()
                end
                task.wait(pause)
            end
        end)
        local MutateSection = AutomationTab:AddSection("Auto Mutation Egg")
        MutateSection:AddParagraph({
            Title   = "How it works",
            Content = "Uses the mutation items you pick (Nitro and any other "
                .. "mutation item you own) on your placed eggs, rarest first, until each egg has it. "
                .. "Rarity / name filters limit which eggs (none picked = all). "
                .. "Nitro lands 10% of the time; a miss still spends that use.",
        })
        local statusRef = MutateSection:AddParagraph({ Title = "Mutation Status", Content = "Off" })
        local kindsRef = MutateSection:AddDropdown({
            Title    = "Mutation To Use",
            Multi    = true,
            Options  = kindIds(),
            Default  = {},
            Callback = function(selected)
                mut.kinds = toSet(type(selected) == "table" and selected or {})
            end,
        })
        task.spawn(function()
            local last, listed, nextList = nil, table.concat(kindIds(), ","), 0
            while mut.live do
                if os.clock() >= nextList then
                    nextList = os.clock() + 5
                    local ids = kindIds()
                    if table.concat(ids, ",") ~= listed then
                        listed = table.concat(ids, ",")
                        pcall(function() kindsRef:SetOptions(ids) end)
                    end
                end
                local text = "Off"
                if mut.enabled then
                    local left = {}
                    for _, id in ipairs(kindIds()) do
                        if mut.kinds[id] then
                            local chance = chanceOf(id)
                            table.insert(left, string.format("%s %d (%s%%)", id, usesOf(id),
                                chance and tostring(chance) or "?"))
                        end
                    end
                    text = string.format("%s\nLeft: %s | Used: %d | Applied: %d", mut.status,
                        #left > 0 and table.concat(left, ", ") or "-", mut.tries, mut.hits)
                end
                if text ~= last then
                    last = text
                    pcall(setParagraph, statusRef, text)
                end
                task.wait(1)
            end
        end)
        local function rarityOptions()
            local seen, ranked = {}, {}
            for _, data in pairs(Game.Assets and Game.Assets.Directory or {}) do
                local rarity = data.Rarity
                local name = rarity and rarity.DisplayName
                if name and not seen[name] then
                    seen[name] = true
                    table.insert(ranked, { name = name, rank = rarity.Rank or 0 })
                end
            end
            table.sort(ranked, function(a, b)
                if a.rank == b.rank then return a.name < b.name end
                return a.rank < b.rank
            end)
            local options = {}
            for _, entry in ipairs(ranked) do table.insert(options, entry.name) end
            if #options == 0 then options = { "Loading..." } end
            return options
        end
        MutateSection:AddDropdown({
            Title    = "Mutation Egg Rarity",
            Multi    = true,
            Options  = rarityOptions(),
            Default  = {},
            Callback = function(selected)
                mut.rarity = toSet(type(selected) == "table" and selected or {})
            end,
        })
        local function eggNameOptions()
            local options, seen = {}, {}
            for _, data in pairs(Game.Assets and Game.Assets.Directory or {}) do
                local name = data.Egg and data.Egg.DisplayName
                if name and not seen[name] then
                    seen[name] = true
                    table.insert(options, name)
                end
            end
            table.sort(options)
            if #options == 0 then options = { "Loading..." } end
            return options
        end
        MutateSection:AddDropdown({
            Title    = "Mutation Egg Name",
            Multi    = true,
            Options  = eggNameOptions(),
            Default  = {},
            Callback = function(selected)
                mut.names = toSet(type(selected) == "table" and selected or {})
            end,
        })
        local mutateRef
        mutateRef = MutateSection:AddToggle({
            Title    = "Auto Mutation Egg",
            Default  = false,
            Callback = function(on)
                local function refuse(text)
                    notify("Auto Mutation Egg", text, Color3.fromRGB(255, 90, 90), 3)
                    if mutateRef then pcall(function() mutateRef:SetValue(false) end) end
                end
                if on and not Game.Init() then return refuse("Belum siap: " .. Game.MissingText()) end
                if on and isSetEmpty(mut.kinds) then return refuse("Pick a mutation to use first.") end
                mut.enabled = on == true
                mut.status = "Starting"
                if not mut.enabled then release() end
            end,
        })
        table.insert(_G.LynxSAE.Stoppers, function()
            mut.live, mut.enabled = false, false
            release()
        end)
    end)()
    do
        local IndexSection = AutomationTab:AddSection("Auto Full Index")
        IndexSection:AddParagraph({
            Title   = "How It Works",
            Content = "Steals eggs whose pet is not in your Index yet, finishing the area closest to done first.\n"
                .. "A pet joins the Index when its egg hatches: keep Auto Place Eggs and Auto Hatch Eggs on.\n"
                .. "Forest eggs are taken too (straight home, before the chicken can hit), except with Legit Steal. It walks when Legit Steal was the last steal mode you turned on, otherwise it tweens like Auto Steal. A notification says which pets it is waiting for when none are on the field. Auto Steal goes first (see the Priority tab).",
        })
        IndexSection:AddDropdown({
            Title    = "Index Areas",
            Multi    = true,
            Options  = Status.IndexAreaOptions(),
            Default  = {},
            Callback = function(selected)
                Filter.indexAreas = toSet(type(selected) == "table" and selected or {})
            end,
        })
        local indexRef
        indexRef = IndexSection:AddToggle({
            Title    = "Steal Index Only",
            Default  = false,
            Callback = function(on)
                if Status.SetIndexSteal(on) then return end
                Status.SetIndexSteal(false)
                notify("Auto Full Index", "Belum siap: " .. Game.MissingText(), Color3.fromRGB(255, 90, 90), 3)
                if indexRef then pcall(function() indexRef:SetValue(false) end) end
            end,
        })
    end
    do
        local _fuse = {
            enabled = false, conn = nil, ref = nil, token = 0,
            pending = false, busy = false, debounce = 0.8,
        }
        local function remotes()
            return Game.Remotes and Game.Remotes.Fusery
        end
        local function eggCap()
            local ok, eggs = pcall(function()
                return require(ReplicatedStorage.Shared.Types.Eggs)
            end)
            if ok and type(eggs) == "table" and tonumber(eggs.MAX_INVENTORY) then
                return tonumber(eggs.MAX_INVENTORY)
            end
            return nil
        end
        local function eggInventoryFull(save)
            local cap = eggCap()
            if not cap or type(save.EggInventory) ~= "table" then return false end
            local count = 0
            for _ in pairs(save.EggInventory) do count = count + 1 end
            return count >= cap
        end
        local function filledSlots(save)
            local slots = type(save.FusionSlots) == "table" and save.FusionSlots or {}
            local filled, category = 0, nil
            for index = 1, 3 do
                local uid = slots[index]
                local entry = uid and save.Inventory and save.Inventory[uid]
                if uid and entry then
                    filled = filled + 1
                    category = category or entry.Category
                end
            end
            return filled, category
        end
        local function candidates(save, category, questOnly)
            if not Game.FuseKernel or type(Game.FuseKernel.MayEnterFuse) ~= "function" then
                return {}
            end
            local slots = type(save.FusionSlots) == "table" and save.FusionSlots or {}
            local loaded = {}
            for index = 1, 3 do
                if slots[index] then loaded[slots[index]] = true end
            end
            local groups = {}
            for uid, entry in pairs(save.Inventory or {}) do
                if not loaded[uid] and not (questOnly and not Status.WispFuseWants(entry.Category)) then
                    local ok, may = pcall(Game.FuseKernel.MayEnterFuse, uid, entry, category, false)
                    if ok and may then
                        local key = entry.Category or "?"
                        groups[key] = groups[key] or {}
                        table.insert(groups[key], { uid = uid, entry = entry })
                    end
                end
            end
            if category then return groups[category] or {} end
            local best, bestCount = nil, 0
            for _, list in pairs(groups) do
                if #list > bestCount then best, bestCount = list, #list end
            end
            if not best or bestCount < 3 then return {} end
            return best
        end
        local function weightOf(entry)
            local ok, decoded = pcall(Game.AssetItems.Decode, entry)
            if not ok or not decoded then return math.huge end
            local okWeight, weight = pcall(Game.AssetItems.WeightKg, decoded)
            if okWeight and type(weight) == "number" then return weight end
            return math.huge
        end
        local function runCycle()
            local net = remotes()
            if not net or _fuse.busy then return end
            _fuse.busy = true
            local ok = pcall(function()
                local save = Game.Save and Game.Save.Get()
                if type(save) ~= "table" then return end
                if save.FusionEggReward ~= false and save.FusionEggReward ~= nil then
                    pcall(function() net.FinishReveal:InvokeServer() end)
                    return
                end
                if save.FusionLocked == true then return end
                if eggInventoryFull(save) then return end
                if save.FusionInfoAcknowledged ~= true then
                    pcall(function() net.ConfirmBriefing:InvokeServer() end)
                end
                local filled, category = filledSlots(save)
                local questOnly = Status.WispFuseActive and Status.WispFuseActive() or false
                if questOnly and category and not Status.WispFuseWants(category) then
                    for index = 1, 3 do
                        local uid = save.FusionSlots[index]
                        if uid then
                            pcall(function() net.EjectPet:InvokeServer(uid) end)
                            task.wait(0.15)
                        end
                    end
                    return
                end
                if filled < 3 then
                    local pool = candidates(save, category, questOnly)
                    if #pool + filled < 3 then return end
                    table.sort(pool, function(a, b) return weightOf(a.entry) < weightOf(b.entry) end)
                    local index = 1
                    while filled < 3 and pool[index] do
                        local loaded = select(2, pcall(function()
                            return net.LoadPet:InvokeServer(pool[index].uid, questOnly)
                        end))
                        if loaded == true then filled = filled + 1 end
                        index = index + 1
                        task.wait(0.15)
                    end
                    if filled < 3 then return end
                end
                local began = select(2, pcall(function()
                    return net.BeginFuse:InvokeServer()
                end))
                if began ~= true then return end
                task.wait(0.6)
                pcall(function() net.FinishReveal:InvokeServer() end)
            end)
            _fuse.busy = false
            if not ok then return end
        end
        Status.RunFuse = runCycle
        local function stopFuse()
            _fuse.enabled = false
            _fuse.token   = (_fuse.token or 0) + 1
            _fuse.pending = false
            if _fuse.conn then
                pcall(function() _fuse.conn:Disconnect() end)
                _fuse.conn = nil
            end
        end
        table.insert(_G.LynxSAE.Stoppers, stopFuse)
        local FuseSection = AutomationTab:AddSection("Fuse Machine")
        _fuse.ref = FuseSection:AddToggle({
            Title    = "Auto Fuse Machine",
            Default  = false,
            Callback = function(on)
                stopFuse()
                if not on then return end
                if not Game.Init() or not Game.Save
                    or type(Game.Save.FieldChanged) ~= "table"
                    or not Game.FuseKernel or not remotes() then
                    notify("Auto Fuse Machine", "Belum siap: " .. Game.MissingText(),
                        Color3.fromRGB(255, 90, 90), 3)
                    if _fuse.ref then pcall(function() _fuse.ref:SetValue(false) end) end
                    return
                end
                _fuse.enabled = true
                local token = _fuse.token
                task.spawn(runCycle)
                task.spawn(function()
                    while _fuse.enabled and _fuse.token == token do
                        task.wait(15)
                        if _fuse.enabled and _fuse.token == token then runCycle() end
                    end
                end)
                _fuse.conn = Game.Save.FieldChanged:Connect(function(field)
                    if not _fuse.enabled then return end
                    if field ~= "Inventory" and field ~= "FusionSlots"
                        and field ~= "FusionEggReward" and field ~= "FusionLocked"
                        and field ~= "EggInventory" then
                        return
                    end
                    if _fuse.pending then return end
                    _fuse.pending = true
                    task.delay(_fuse.debounce, function()
                        _fuse.pending = false
                        if _fuse.enabled then runCycle() end
                    end)
                end)
                pcall(function()
                    Library:AddConnection("SAE_AutoFuseMachine", _fuse.conn)
                end)
            end,
        })
    end
    do
        local _offline = {
            enabled = false, conn = nil, ref = nil,
            pending = false, debounce = 0.6, total = 0,
        }
        local function formatMoney(value)
            local whole = string.format("%.0f", math.floor(tonumber(value) or 0))
            return (whole:reverse():gsub("(%d%d%d)", "%1,"):reverse():gsub("^,", ""))
        end
        local function awayRemotes()
            return Game.Remotes and Game.Remotes.AwayEarnings
        end
        local function pendingAmount()
            local save = Game.Save and Game.Save.Get()
            local amount = save and tonumber(save.PendingOfflineMoney)
            return amount or 0
        end
        local function claimOnce()
            local net = awayRemotes()
            if not net or not net.AskCollect then return false, 0 end
            if pendingAmount() <= 0 then return false, 0 end
            local ok, success, _, result = pcall(function()
                return net.AskCollect:InvokeServer({ Kind = "Claim" })
            end)
            if not ok or success ~= true or type(result) ~= "table" then return false, 0 end
            return true, tonumber(result.AwardedAmount) or 0
        end
        local function stopOffline()
            _offline.enabled = false
            _offline.pending = false
            if _offline.conn then
                pcall(function() _offline.conn:Disconnect() end)
                _offline.conn = nil
            end
        end
        table.insert(_G.LynxSAE.Stoppers, stopOffline)
        local OfflineSection = AutomationTab:AddSection("Offline Cash")
        _offline.ref = OfflineSection:AddToggle({
            Title    = "Auto Claim Offline Cash",
            Default  = false,
            Callback = function(on)
                stopOffline()
                if not on then return end
                if not Game.Init() or not Game.Save
                    or type(Game.Save.FieldChanged) ~= "table"
                    or not awayRemotes() then
                    notify("Offline Cash", "Belum siap: " .. Game.MissingText(),
                        Color3.fromRGB(255, 90, 90), 3)
                    if _offline.ref then pcall(function() _offline.ref:SetValue(false) end) end
                    return
                end
                _offline.enabled = true
                local claimed, amount = claimOnce()
                if claimed then _offline.total = _offline.total + amount end
                _offline.conn = Game.Save.FieldChanged:Connect(function(field)
                    if not _offline.enabled then return end
                    if field ~= "PendingOfflineMoney" then return end
                    if pendingAmount() <= 0 then return end
                    if _offline.pending then return end
                    _offline.pending = true
                    task.delay(_offline.debounce, function()
                        _offline.pending = false
                        if not _offline.enabled then return end
                        local ok, got = claimOnce()
                        if ok then _offline.total = _offline.total + got end
                    end)
                end)
                pcall(function()
                    Library:AddConnection("SAE_AutoClaimOffline", _offline.conn)
                end)
            end,
        })
        OfflineSection:AddButton({
            Title    = "Claim Offline Cash Now",
            Callback = function()
                if not Game.Init() or not awayRemotes() then
                    notify("Offline Cash", "Belum siap: " .. Game.MissingText(),
                        Color3.fromRGB(255, 90, 90), 3)
                    return
                end
                local amount = pendingAmount()
                if amount <= 0 then
                    notify("Offline Cash", "No offline cash to claim yet.",
                        Color3.fromRGB(255, 170, 60), 3)
                    return
                end
                local ok, got = claimOnce()
                notify("Offline Cash",
                    ok and string.format("Claimed %s.", formatMoney(got)) or "Claim failed.",
                    ok and Color3.fromRGB(50, 200, 100) or Color3.fromRGB(255, 90, 90), 3)
            end,
        })
    end
    do
        local _upg = {
            treadmill = false, plot = false,
            thread = nil, token = 0, poll = 5,
            treadmillRef = nil, plotRef = nil,
        }
        local LABEL = { treadmill = "Auto Upgrade Treadmill", plot = "Auto Upgrade Plot" }
        local function saveNow()
            local ok, save = pcall(function() return Game.Save and Game.Save.Get() end)
            return (ok and type(save) == "table") and save or nil
        end
        local function dataModule(name)
            local ok, module = pcall(function() return require(ReplicatedStorage.Data[name]) end)
            return ok and type(module) == "table" and module or nil
        end
        local function nextTreadmill(save)
            local data = dataModule("Treadmills")
            if not data or type(data.GetByUpgradeLevel) ~= "function" then return nil end
            local level  = (tonumber(save.TreadmillUpgradeLevel) or 0) + 1
            local ok, cfg = pcall(data.GetByUpgradeLevel, level)
            if not ok or type(cfg) ~= "table" then return nil end
            return level, cfg, tonumber(cfg.Price) or math.huge,
                tostring(cfg.DisplayName or cfg._id or "next tier")
        end
        local function nextPlot(save)
            local data  = dataModule("Bases")
            local bases = data and data.BASES
            if type(bases) ~= "table" then return nil end
            local level = (tonumber(save.BaseUpgradeLevel) or 0) + 1
            local cfg   = bases[level]
            if type(cfg) ~= "table" then return nil end
            return level, cfg, tonumber(cfg.Cost) or math.huge,
                "Plot Level " .. level
        end
        local function askTreadmill(cfg)
            local net = Game.Remotes and Game.Remotes.Treadmill
            if not net or not net.AskTierRaise then return false, "Belum siap: " .. Game.MissingText() end
            local ok, accepted, reason = pcall(function()
                return net.AskTierRaise:InvokeServer(cfg._id)
            end)
            if not ok then return false, tostring(accepted) end
            return accepted == true, reason
        end
        local function askPlot(level)
            local net = Game.Remotes and Game.Remotes.Homestead
            if not net or not net.AskBaseTierRaise then return false, "Belum siap: " .. Game.MissingText() end
            if not pcall(function() net.AskBaseTierRaise:FireServer() end) then
                return false, "Request failed."
            end
            local deadline = os.clock() + 3
            while os.clock() < deadline do
                task.wait(0.2)
                local save = saveNow()
                if save and (tonumber(save.BaseUpgradeLevel) or 0) >= level then return true end
            end
            return false, "The server didn't confirm the upgrade."
        end
        local function disable(kind)
            _upg[kind] = false
            local ref = kind == "treadmill" and _upg.treadmillRef or _upg.plotRef
            if ref then pcall(function() ref:SetValue(false) end) end
        end
        local function runUpgrade(kind)
            local save = saveNow()
            if not save then return end
            local level, cfg, cost, name =
                (kind == "treadmill" and nextTreadmill or nextPlot)(save)
            if not cfg then
                notify(LABEL[kind], "Max level reached.", Color3.fromRGB(50, 200, 100), 3)
                disable(kind)
                return
            end
            if (tonumber(save.Money) or 0) < cost then return end
            if kind == "treadmill" then askTreadmill(cfg) else askPlot(level) end
        end
        local function startUpgrades()
            if _upg.thread then return end
            _upg.token = _upg.token + 1
            local token = _upg.token
            _upg.thread = task.spawn(function()
                while (_upg.treadmill or _upg.plot) and _upg.token == token do
                    if _upg.treadmill then pcall(runUpgrade, "treadmill") end
                    if _upg.plot then pcall(runUpgrade, "plot") end
                    task.wait(_upg.poll)
                end
                if _upg.token == token then _upg.thread = nil end
            end)
        end
        local function stopUpgrades()
            _upg.treadmill = false
            _upg.plot      = false
            _upg.token     = _upg.token + 1
            _upg.thread    = nil
        end
        table.insert(_G.LynxSAE.Stoppers, stopUpgrades)
        local UpgradeSection = AutomationTab:AddSection("Base Upgrades")
        local function toggleFor(kind, title)
            return UpgradeSection:AddToggle({
                Title    = title,
                Default  = false,
                Callback = function(on)
                    if not on then
                        _upg[kind] = false
                        return
                    end
                    if not Game.Init() or not Game.Save or not Game.Remotes then
                        notify(title, "Game data not ready yet.",
                            Color3.fromRGB(255, 90, 90), 3)
                        disable(kind)
                        return
                    end
                    _upg[kind] = true
                    startUpgrades()
                end,
            })
        end
        _upg.treadmillRef = toggleFor("treadmill", "Auto Upgrade Treadmill")
        _upg.plotRef      = toggleFor("plot", "Auto Upgrade Plot")
    end
    do
        local _wear = {
            trailOn = false, trailConn = nil, trailRef = nil, trailPending = false,
            gearOn = false, gearConns = {}, gearRef = nil, gearPending = false,
        }
        local function trailData()
            local ok, module = pcall(function() return require(ReplicatedStorage.Data.Trails) end)
            if not ok or type(module) ~= "table" then return nil end
            return module.Directory or module
        end
        local function gearData()
            local ok, module = pcall(function() return require(ReplicatedStorage.Data.Gears) end)
            if not ok or type(module) ~= "table" then return nil end
            return module.Directory or module
        end
        local function bestTrail()
            local directory = trailData()
            local save = Game.Save and Game.Save.Get()
            if not directory or not save or type(save.TrailInventory) ~= "table" then return nil end
            local bestId, bestScore = nil, -1
            for id, owned in pairs(save.TrailInventory) do
                if owned then
                    local entry = directory[id]
                    local score = entry and tonumber(entry.SpeedMultiplier) or 0
                    if score > bestScore then bestId, bestScore = id, score end
                end
            end
            return bestId, bestScore
        end
        local function applyTrail()
            local net = Game.Remotes and Game.Remotes.Trailwear
            if not net or not net.AskChoose then return false end
            local id = bestTrail()
            if not id then return false end
            local save = Game.Save and Game.Save.Get()
            if save and save.EquippedTrail == id then return false end
            local ok, result = pcall(function() return net.AskChoose:InvokeServer(id) end)
            return ok and result ~= false
        end
        local function batScore(gearId)
            local directory = gearData()
            local entry = directory and directory[gearId]
            local stats = entry and entry.BatControllerData
            if not stats then return -1 end
            return (tonumber(stats.RangeBonus) or 0) * 1000 + (tonumber(stats.Force) or 0)
        end
        local function areaIndexDone(area, index)
            local assets = Game.Assets and Game.Assets.Directory
            if type(assets) ~= "table" then return false end
            local counted = 0
            for _, drop in ipairs(area.DropTable or {}) do
                local category = drop[1]
                local data = category and assets[category]
                if (tonumber(drop[2]) or 0) > 0 and data and data.DontRoll ~= true then
                    if index[category] ~= true then return false end
                    counted = counted + 1
                end
            end
            return counted > 0
        end
        local function bestIndexBat()
            local areas = Game.Areas and Game.Areas.Directory
            local save  = Game.Save and Game.Save.Get()
            if type(areas) ~= "table" or type(save) ~= "table" then return nil end
            local index = type(save.Index) == "table" and save.Index or {}
            local bestArea, bestBat, bestScore = nil, nil, -1
            for areaId, area in pairs(areas) do
                local batId = type(area) == "table" and area.IndexBatGearId or nil
                if batId and areaIndexDone(area, index) then
                    local value = batScore(batId)
                    if value > bestScore then
                        bestArea, bestBat, bestScore = tostring(areaId), tostring(batId), value
                    end
                end
            end
            return bestArea, bestBat
        end
        local function applyIndexBat()
            local net = Game.Remotes and Game.Remotes.Codex
            if not net or not net.AskWearFieldBat then return false end
            local areaId, batId = bestIndexBat()
            if not areaId then return false end
            local save  = Game.Save and Game.Save.Get()
            local owned = type(save) == "table" and save.GearInventory or nil
            if type(owned) == "table" and owned[batId] then return false end
            local ok, accepted = pcall(function()
                return net.AskWearFieldBat:InvokeServer(areaId)
            end)
            return ok and accepted == true
        end
        local function stopTrail()
            _wear.trailOn = false
            _wear.trailPending = false
            if _wear.trailConn then
                pcall(function() _wear.trailConn:Disconnect() end)
                _wear.trailConn = nil
            end
        end
        local function stopGear()
            _wear.gearOn = false
            _wear.gearPending = false
            for _, conn in ipairs(_wear.gearConns) do
                pcall(function() conn:Disconnect() end)
            end
            _wear.gearConns = {}
        end
        table.insert(_G.LynxSAE.Stoppers, stopTrail)
        table.insert(_G.LynxSAE.Stoppers, stopGear)
        local WearSection = AutomationTab:AddSection("Trail & Gear")
        _wear.trailRef = WearSection:AddToggle({
            Title    = "Auto Equip Best Trail",
            Default  = false,
            Callback = function(on)
                stopTrail()
                if not on then return end
                if not Game.Init() or not Game.Save
                    or type(Game.Save.FieldChanged) ~= "table"
                    or not (Game.Remotes and Game.Remotes.Trailwear) then
                    notify("Trail & Gear", "Belum siap: " .. Game.MissingText(),
                        Color3.fromRGB(255, 90, 90), 3)
                    if _wear.trailRef then pcall(function() _wear.trailRef:SetValue(false) end) end
                    return
                end
                _wear.trailOn = true
                applyTrail()
                _wear.trailConn = Game.Save.FieldChanged:Connect(function(field)
                    if not _wear.trailOn then return end
                    if field ~= "TrailInventory" and field ~= "EquippedTrail" then return end
                    if _wear.trailPending then return end
                    _wear.trailPending = true
                    task.delay(0.6, function()
                        _wear.trailPending = false
                        if _wear.trailOn then applyTrail() end
                    end)
                end)
                pcall(function()
                    Library:AddConnection("SAE_AutoEquipTrail", _wear.trailConn)
                end)
            end,
        })
        _wear.gearRef = WearSection:AddToggle({
            Title    = "Auto Equip Best Index Bat",
            Default  = false,
            Callback = function(on)
                stopGear()
                if not on then return end
                if not Game.Init() or not Game.Save or not Game.Areas
                    or type(Game.Save.FieldChanged) ~= "table"
                    or not (Game.Remotes and Game.Remotes.Codex
                        and Game.Remotes.Codex.AskWearFieldBat) then
                    notify("Trail & Gear", "Belum siap: " .. Game.MissingText(),
                        Color3.fromRGB(255, 90, 90), 3)
                    if _wear.gearRef then pcall(function() _wear.gearRef:SetValue(false) end) end
                    return
                end
                _wear.gearOn = true
                task.spawn(applyIndexBat)
                _wear.gearConns[#_wear.gearConns + 1] =
                    Game.Save.FieldChanged:Connect(function(field)
                        if not _wear.gearOn then return end
                        if field ~= "Index" and field ~= "GearInventory" then return end
                        if _wear.gearPending then return end
                        _wear.gearPending = true
                        task.delay(1, function()
                            _wear.gearPending = false
                            if _wear.gearOn then applyIndexBat() end
                        end)
                    end)
                pcall(function()
                    Library:AddConnection("SAE_AutoEquipIndexBat", _wear.gearConns[1])
                end)
            end,
        })
    end
    do
        local _pet = {
            enabled  = false,
            conn     = nil,
            ref      = nil,
            pending  = false,
            debounce = 2,
        }
        local function wearBestRemote()
            local ok, remote = pcall(function()
                return Game.Remotes.Haul.WearBest
            end)
            if ok and remote then return remote end
            return ReplicatedStorage.Packages.Networking:FindFirstChild("RF/Haul/WearBest", true)
        end
        local function equipBest()
            pcall(function()
                local remote = wearBestRemote()
                if remote then remote:InvokeServer() end
            end)
        end
        local function stopEquip()
            _pet.enabled = false
            _pet.pending = false
            if _pet.conn then
                pcall(function() _pet.conn:Disconnect() end)
                _pet.conn = nil
            end
        end
        local _index = { enabled = false, conn = nil, ref = nil, pending = false, debounce = 0.6 }
        local function codexRemote()
            return Game.Remotes and Game.Remotes.Codex and Game.Remotes.Codex.AskRedeemAll
        end
        local function unclaimedCount()
            local save = Game.Save and Game.Save.Get()
            if not save or type(save.Index) ~= "table" then return 0 end
            local claimed = type(save.IndexClaimedCategories) == "table"
                and save.IndexClaimedCategories or {}
            local count = 0
            for category, discovered in pairs(save.Index) do
                if discovered == true and claimed[category] ~= true then count = count + 1 end
            end
            return count
        end
        local function claimIndex()
            local remote = codexRemote()
            if not remote then return false end
            if unclaimedCount() == 0 then return false end
            local ok, result = pcall(function() return remote:InvokeServer() end)
            return ok and result ~= false
        end
        local function stopIndexClaim()
            _index.enabled = false
            _index.pending = false
            if _index.conn then
                pcall(function() _index.conn:Disconnect() end)
                _index.conn = nil
            end
        end
        table.insert(_G.LynxSAE.Stoppers, stopIndexClaim)
        table.insert(_G.LynxSAE.Stoppers, stopEquip)
        local PetSection = AutomationTab:AddSection("Pet Automation")
        _index.ref = PetSection:AddToggle({
            Title    = "Auto Claim Pet Index",
            Default  = false,
            Callback = function(on)
                stopIndexClaim()
                if not on then return end
                if not Game.Init() or not Game.Save
                    or type(Game.Save.FieldChanged) ~= "table"
                    or not codexRemote() then
                    notify("Auto Claim Pet Index", "Belum siap: " .. Game.MissingText(),
                        Color3.fromRGB(255, 90, 90), 3)
                    if _index.ref then pcall(function() _index.ref:SetValue(false) end) end
                    return
                end
                _index.enabled = true
                claimIndex()
                _index.conn = Game.Save.FieldChanged:Connect(function(field)
                    if not _index.enabled then return end
                    if field ~= "Index" then return end
                    if _index.pending then return end
                    _index.pending = true
                    task.delay(_index.debounce, function()
                        _index.pending = false
                        if _index.enabled then claimIndex() end
                    end)
                end)
                pcall(function()
                    Library:AddConnection("SAE_AutoClaimPetIndex", _index.conn)
                end)
            end,
        })
        _pet.ref = PetSection:AddToggle({
            Title    = "Auto Equip Best Pets",
            Default  = false,
            Callback = function(on)
                stopEquip()
                if not on then return end
                if not Game.Init() or not Game.Save
                    or type(Game.Save.FieldChanged) ~= "table"
                    or not wearBestRemote() then
                    notify("Auto Equip Best Pets", "Belum siap: " .. Game.MissingText(),
                        Color3.fromRGB(255, 90, 90), 3)
                    if _pet.ref then pcall(function() _pet.ref:SetValue(false) end) end
                    return
                end
                _pet.enabled = true
                equipBest()
                _pet.conn = Game.Save.FieldChanged:Connect(function(field)
                    if not _pet.enabled then return end
                    if field ~= "Inventory" then return end
                    if _pet.pending then return end
                    _pet.pending = true
                    task.delay(_pet.debounce, function()
                        _pet.pending = false
                        if _pet.enabled then equipBest() end
                    end)
                end)
                pcall(function()
                    Library:AddConnection("SAE_AutoEquipBest", _pet.conn)
                end)
            end,
        })
    end
end
task.wait()
do
    local ShopTab = MainWindow:AddTab({ Name = "Shop", Icon = "cart" })
    do
        local _buytrail = { id = nil, note = nil, dropdown = nil }
        local function trailDirectory()
            local ok, module = pcall(function() return require(ReplicatedStorage.Data.Trails) end)
            if not ok or type(module) ~= "table" then return nil end
            return module.Directory or module
        end
        local function abbreviate(value)
            local number = tonumber(value) or 0
            local ok, text = pcall(function()
                return require(ReplicatedStorage.UserGenerated.Strings.FormatAbbreviated)(number)
            end)
            if ok and text then return tostring(text) end
            return string.format("%.0f", number)
        end
        local function withCommas(value)
            local whole = string.format("%.0f", math.floor(tonumber(value) or 0))
            return (whole:reverse():gsub("(%d%d%d)", "%1,"):reverse():gsub("^,", ""))
        end
        local function priceText(value)
            return abbreviate(value) .. " (" .. withCommas(value) .. ")"
        end
        local function trailList()
            local directory = trailDirectory()
            if not directory then return {} end
            local list = {}
            for id, entry in pairs(directory) do
                if type(entry) == "table" then
                    list[#list + 1] = {
                        id    = tostring(entry._id or id),
                        name  = tostring(entry.DisplayName or id),
                        price = tonumber(entry.Price) or 0,
                        speed = tonumber(entry.SpeedMultiplier),
                    }
                end
            end
            table.sort(list, function(a, b)
                if a.price == b.price then return a.name < b.name end
                return a.price < b.price
            end)
            return list
        end
        local function trailOptions()
            local options = {}
            for _, trail in ipairs(trailList()) do
                options[#options + 1] = {
                    Label = trail.name .. " - " .. abbreviate(trail.price),
                    Value = trail.id,
                }
            end
            return options
        end
        local function trailById(id)
            if not id then return nil end
            for _, trail in ipairs(trailList()) do
                if trail.id == id then return trail end
            end
            return nil
        end
        local function saveNow()
            local ok, save = pcall(function() return Game.Save and Game.Save.Get() end)
            return (ok and type(save) == "table") and save or nil
        end
        local function trailOwned(save, id)
            local inventory = save and save.TrailInventory
            return type(inventory) == "table" and inventory[id] == true
        end
        local function refreshNote()
            if not _buytrail.note then return end
            local trail = trailById(_buytrail.id)
            local text
            if not trail then
                text = "Pick a trail to see its price."
            else
                local save  = saveNow()
                local money = tonumber(save and save.Money) or 0
                local lines = {
                    trail.name,
                    "Price: " .. priceText(trail.price),
                }
                if trail.speed then
                    lines[#lines + 1] = "Speed: x" .. tostring(trail.speed)
                end
                lines[#lines + 1] = "Your money: " .. priceText(money)
                if trailOwned(save, trail.id) then
                    lines[#lines + 1] = "Status: already owned"
                elseif money >= trail.price then
                    lines[#lines + 1] = "Status: you can afford it"
                else
                    lines[#lines + 1] = "Status: short by " .. priceText(trail.price - money)
                end
                text = table.concat(lines, "\n")
            end
            pcall(setParagraph, _buytrail.note, text)
        end
        local BuyTrailSection = ShopTab:AddSection("Buy Trails")
        BuyTrailSection:AddParagraph({
            Title   = "How It Works",
            Content = "Pick a trail and press Buy Trail. The purchase is sent straight to the "
                .. "server, so it works from anywhere without walking to the trail shop.",
        })
        _buytrail.dropdown = BuyTrailSection:AddDropdown({
            Title    = "Trail",
            Options  = trailOptions(),
            Default  = nil,
            Callback = function(value)
                local id = type(value) == "table" and value[1] or value
                _buytrail.id = id and tostring(id) or nil
                refreshNote()
            end,
        })
        _buytrail.note = BuyTrailSection:AddParagraph({
            Title   = "Selected Trail",
            Content = "Pick a trail to see its price.",
        })
        BuyTrailSection:AddButton({
            Title    = "Buy Trail",
            Callback = function()
                task.spawn(function()
                    Game.Init()
                    local net = Game.Remotes and Game.Remotes.Trailwear
                    if not net or not net.AskPurchase then
                        notify("Buy Trails", "Belum siap: " .. Game.MissingText(),
                            Color3.fromRGB(255, 90, 90), 3)
                        return
                    end
                    local trail = trailById(_buytrail.id)
                    if not trail then
                        notify("Buy Trails", "Pick a trail first.",
                            Color3.fromRGB(255, 170, 60), 3)
                        return
                    end
                    if trailOwned(saveNow(), trail.id) then
                        notify("Buy Trails", trail.name .. " is already yours.",
                            Color3.fromRGB(255, 170, 60), 3)
                        refreshNote()
                        return
                    end
                    local ok, accepted, reason = pcall(function()
                        return net.AskPurchase:InvokeServer(trail.id)
                    end)
                    if not ok then
                        notify("Buy Trails", "The server refused: " .. tostring(accepted),
                            Color3.fromRGB(255, 90, 90), 4)
                        return
                    end
                    if accepted == true then
                        notify("Buy Trails", trail.name .. " bought for " .. abbreviate(trail.price)
                            .. ".", Color3.fromRGB(50, 200, 100), 4)
                    else
                        notify("Buy Trails", tostring(reason or "The purchase was rejected."),
                            Color3.fromRGB(255, 90, 90), 4)
                    end
                    task.wait(0.3)
                    refreshNote()
                end)
            end,
        })
        task.spawn(function()
            Game.Init()
            local options = trailOptions()
            if #options > 0 and _buytrail.dropdown then
                pcall(function() _buytrail.dropdown:SetOptions(options) end)
            end
            refreshNote()
        end)
    end
end
task.wait()
do
    local PriorityTab = MainWindow:AddTab({ Name = "Priority", Icon = "menu" })
    local FEATURES = Control.Features()
    local RANKS = {}
    for index = 1, #FEATURES do
        if index == 1 then
            RANKS[index] = "1 (First)"
        elseif index == #FEATURES then
            RANKS[index] = index .. " (Last)"
        else
            RANKS[index] = tostring(index)
        end
    end
    local function defaultRank(key)
        return (#RANKS + 1) - Control.DefaultPriority(key)
    end
    local chosen, changedAt, refs = {}, {}, {}
    local queued = false
    local function applyOrder()
        queued = false
        local order = {}
        for index, feature in ipairs(FEATURES) do
            order[index] = { key = feature.key, index = index }
        end
        table.sort(order, function(a, b)
            local ra, rb = chosen[a.key] or defaultRank(a.key), chosen[b.key] or defaultRank(b.key)
            if ra ~= rb then return ra < rb end
            local ta, tb = changedAt[a.key] or 0, changedAt[b.key] or 0
            if ta ~= tb then return ta > tb end
            return a.index < b.index
        end)
        for position, item in ipairs(order) do
            Control.SetPriority(item.key, (#RANKS + 1) - position)
            if chosen[item.key] ~= position then
                chosen[item.key] = position
                local ref = refs[item.key]
                if ref then pcall(function() ref:SetValue(RANKS[position]) end) end
            end
        end
    end
    local function queueOrder()
        if queued then return end
        queued = true
        task.defer(applyOrder)
    end
    local PrioritySection = PriorityTab:AddSection("Priority Settings")
    PrioritySection:AddParagraph({
        Title = "How It Works",
        Content = "Features take turns in order: one waits while any feature above it has work, "
            .. "and one above can stop one below it. A steal carrying its egg home is always "
            .. "finished first.\n"
            .. "Default order: Auto Collect Star, Auto Steal, Steal Halloween Eggs, Phantom Express, Enchanted Tree, Halloween Monsters & Pumpkin Moon, Auto Steal Full Index, "
            .. "Auto Sell Egg, Auto Place Egg, Auto Mutation Egg, Instant Fishing, Auto Treadmill.\n"
            .. "Turn the toggle ON to use your own order from the dropdowns below.",
    })
    PrioritySection:AddToggle({
        Title    = "Enable Priority",
        Default  = false,
        Callback = function(on)
            Control.SetPriorityEnabled(on)
            notify("Priority",
                on and "Custom priority enabled." or "Back to the default order.",
                on and Color3.fromRGB(50, 200, 100) or Color3.fromRGB(255, 170, 60), 3)
        end,
    })
    for _, feature in ipairs(FEATURES) do
        refs[feature.key] = PrioritySection:AddDropdown({
            Title    = "Priority " .. feature.label,
            Options  = RANKS,
            Default  = RANKS[defaultRank(feature.key)],
            Callback = function(value)
                local rank = tonumber(tostring(type(value) == "table" and value[1] or value):match("^(%d+)"))
                if not rank or rank == chosen[feature.key] then return end
                chosen[feature.key], changedAt[feature.key] = rank, os.clock()
                queueOrder()
            end,
        })
    end
    PrioritySection:AddButton({
        Title    = "Reset To Default",
        Callback = function()
            Control.ResetPriority()
            table.clear(changedAt)
            table.clear(chosen)
            queueOrder()
            notify("Priority", "Priority restored to defaults.",
                Color3.fromRGB(50, 200, 100), 3)
        end,
    })
    PrioritySection:AddButton({
        Title    = "Show Current Order",
        Callback = function()
            local list = {}
            for _, feature in ipairs(FEATURES) do
                list[#list + 1] = { label = feature.label, value = Control.Rank(feature.key) }
            end
            table.sort(list, function(a, b) return a.value > b.value end)
            local parts = {}
            for index, item in ipairs(list) do
                parts[#parts + 1] = index .. ". " .. item.label
            end
            local holder = Control.Holder()
            notify("Priority",
                table.concat(parts, "\n") .. "\n\nCurrently running: " .. (holder or "none"),
                Color3.fromRGB(50, 200, 100), 6)
        end,
    })
end
task.wait()
do
    local WebhookTab = MainWindow:AddTab({ Name = "Webhook", Icon = "send" })
    local HttpService = game:GetService("HttpService")
    local AVATAR_URL   = "https://raw.githubusercontent.com/habibrodriguez7-art/kontol/refs/heads/main/majesticons--planet-ring-2.png"
    local BOT_NAME     = "Lynx"
    local FALLBACK_IMG = "https://i.imgur.com/UMWNYK7.png"
    local _httpFn = nil
    local function getHTTP()
        if _httpFn then return _httpFn end
        for _, name in ipairs({ "request", "http_request" }) do
            local fn = rawget(getfenv and getfenv(0) or _G, name)
                or (getgenv and rawget(getgenv(), name))
            if type(fn) == "function" then _httpFn = fn return fn end
        end
        for _, tbl in ipairs({ syn, fluxus, http }) do
            if type(tbl) == "table" and type(tbl.request) == "function" then
                _httpFn = tbl.request
                return _httpFn
            end
        end
        return nil
    end
    local function cleanStr(value)
        return (tostring(value):gsub("^%s*(.-)%s*$", "%1"))
    end
    local function cleanId(value)
        return (tostring(value):gsub("%D", ""))
    end
    local function formatNumber(value)
        local whole = string.format("%.0f", math.floor(tonumber(value) or 0))
        return (whole:reverse():gsub("(%d%d%d)", "%1,"):reverse():gsub("^,", ""))
    end
    local function colorToInt(color)
        if typeof(color) ~= "Color3" then return 3447003 end
        return math.floor(color.R * 255) * 65536
            + math.floor(color.G * 255) * 256
            + math.floor(color.B * 255)
    end
    local thumbnailUrl
    local ATTACH_NAME = "egg.png"
    local _queue, _sending = {}, false
    local function pump()
        if _sending then return end
        _sending = true
        task.spawn(function()
            while #_queue > 0 do
                local entry = table.remove(_queue, 1)
                if entry then
                    pcall(function()
                        local fn = getHTTP()
                        if not fn or entry.url == "" then return end
                        local function postJson()
                            local payload = entry.payload
                            if entry.attachment then
                                local embed = payload.embeds and payload.embeds[1]
                                if embed and embed.image then
                                    embed.image = entry.linkIcon
                                        and { url = thumbnailUrl(entry.linkIcon) } or nil
                                end
                            end
                            return fn({
                                Url     = entry.url,
                                Method  = "POST",
                                Headers = { ["Content-Type"] = "application/json" },
                                Body    = HttpService:JSONEncode(payload),
                            })
                        end
                        if not entry.attachment then
                            postJson()
                            return
                        end
                        local boundary = "LynxBoundary" .. tostring(math.random(100000, 999999))
                        local okSend, response = pcall(fn, {
                            Url     = entry.url,
                            Method  = "POST",
                            Headers = { ["Content-Type"] = "multipart/form-data; boundary=" .. boundary },
                            Body    = table.concat({
                                "--" .. boundary,
                                'Content-Disposition: form-data; name="payload_json"',
                                "Content-Type: application/json",
                                "",
                                HttpService:JSONEncode(entry.payload),
                                "--" .. boundary,
                                'Content-Disposition: form-data; name="files[0]"; filename="' .. ATTACH_NAME .. '"',
                                "Content-Type: image/png",
                                "",
                                entry.attachment,
                                "--" .. boundary .. "--",
                                "",
                            }, "\r\n"),
                        })
                        local status = okSend and response and tonumber(response.StatusCode) or 0
                        if status >= 200 and status < 300 then return end
                        postJson()
                    end)
                    if #_queue > 0 then task.wait(1.5) end
                end
            end
            _sending = false
        end)
    end
    local function queueWebhook(url, payload, attachment, linkIcon)
        if type(url) ~= "string" or url == "" then return false end
        if not getHTTP() then return false end
        table.insert(_queue, { url = url, payload = payload, attachment = attachment,
            linkIcon = linkIcon })
        pump()
        return true
    end
    local function buildPayload(opts)
        local mention = ""
        if opts.userId and #opts.userId >= 17 then mention = "<@" .. opts.userId .. ">" end
        local content = opts.contentText
            or (mention ~= "" and (mention .. " " .. (opts.alertText or "")) or (opts.alertText or ""))
        local payload = {
            content          = content,
            username         = BOT_NAME,
            avatar_url       = AVATAR_URL,
            allowed_mentions = mention ~= "" and { parse = { "users" } } or nil,
            embeds = { {
                author      = { name = BOT_NAME .. " Webhook | " .. (opts.headerTitle or ""), icon_url = AVATAR_URL },
                description = opts.bodyText or "",
                color       = opts.color or 3447003,
                fields      = opts.fields or {},
                footer      = { text = BOT_NAME .. " Webhook \u{2022} " .. os.date("%m/%d/%Y %I:%M"), icon_url = AVATAR_URL },
                timestamp   = os.date("!%Y-%m-%dT%H:%M:%SZ"),
            } },
        }
        if opts.imageUrl then payload.embeds[1].image = { url = opts.imageUrl } end
        if opts.thumbnailUrl then payload.embeds[1].thumbnail = { url = opts.thumbnailUrl } end
        return payload
    end
    local AssetService  = game:GetService("AssetService")
    local ATTACH_MAX    = 256
    local PNG_CACHE_MAX = 8
    local _pngCache, _pngOrder = {}, {}
    local _crcTable
    local function crcTable()
        if _crcTable then return _crcTable end
        local table32 = {}
        for index = 0, 255 do
            local value = index
            for _ = 1, 8 do
                if value % 2 == 1 then
                    value = bit32.bxor(0xEDB88320, bit32.rshift(value, 1))
                else
                    value = bit32.rshift(value, 1)
                end
            end
            table32[index] = value
        end
        _crcTable = table32
        return table32
    end
    local function crc32(data, offset, length)
        local lookup = crcTable()
        local value  = 0xFFFFFFFF
        for index = offset, offset + length - 1 do
            value = bit32.bxor(lookup[bit32.band(bit32.bxor(value, buffer.readu8(data, index)), 0xFF)],
                bit32.rshift(value, 8))
        end
        return bit32.bxor(value, 0xFFFFFFFF)
    end
    local function adler32(data, length)
        local a, b, index = 1, 0, 0
        while index < length do
            local stop = math.min(index + 5552, length)
            while index < stop do
                a = a + buffer.readu8(data, index)
                b = b + a
                index = index + 1
            end
            a = a % 65521
            b = b % 65521
        end
        return bit32.bor(bit32.lshift(b, 16), a)
    end
    local function shrink(pixels, width, height)
        local step = math.max(1, math.ceil(math.max(width, height) / ATTACH_MAX))
        if step == 1 then return pixels, width, height end
        local outWidth  = math.max(1, math.floor(width / step))
        local outHeight = math.max(1, math.floor(height / step))
        local small = buffer.create(outWidth * outHeight * 4)
        for y = 0, outHeight - 1 do
            local srcRow = (y * step) * width * 4
            local dstRow = y * outWidth * 4
            for x = 0, outWidth - 1 do
                buffer.copy(small, dstRow + x * 4, pixels, srcRow + (x * step) * 4, 4)
            end
        end
        return small, outWidth, outHeight
    end
    local function encodePNG(pixels, width, height)
        local rawLength = height * (1 + width * 4)
        local raw = buffer.create(rawLength)
        local src, dst = 0, 0
        for _ = 1, height do
            buffer.writeu8(raw, dst, 0)
            dst = dst + 1
            buffer.copy(raw, dst, pixels, src, width * 4)
            src = src + width * 4
            dst = dst + width * 4
        end
        local blocks  = math.ceil(rawLength / 65535)
        local zLength = 2 + blocks * 5 + rawLength + 4
        local stream  = buffer.create(zLength)
        buffer.writeu8(stream, 0, 0x78)
        buffer.writeu8(stream, 1, 0x01)
        local at, from, left = 2, 0, rawLength
        while left > 0 do
            local size = math.min(left, 65535)
            buffer.writeu8(stream, at, (left == size) and 1 or 0)
            buffer.writeu16(stream, at + 1, size)
            buffer.writeu16(stream, at + 3, bit32.band(bit32.bnot(size), 0xFFFF))
            buffer.copy(stream, at + 5, raw, from, size)
            at   = at + 5 + size
            from = from + size
            left = left - size
        end
        local sum = adler32(raw, rawLength)
        buffer.writeu8(stream, at,     bit32.band(bit32.rshift(sum, 24), 0xFF))
        buffer.writeu8(stream, at + 1, bit32.band(bit32.rshift(sum, 16), 0xFF))
        buffer.writeu8(stream, at + 2, bit32.band(bit32.rshift(sum, 8), 0xFF))
        buffer.writeu8(stream, at + 3, bit32.band(sum, 0xFF))
        local png = buffer.create(8 + 25 + 12 + zLength + 12)
        local pos = 0
        local function writeByte(byte)
            buffer.writeu8(png, pos, byte)
            pos = pos + 1
        end
        local function writeBE32(value)
            writeByte(bit32.band(bit32.rshift(value, 24), 0xFF))
            writeByte(bit32.band(bit32.rshift(value, 16), 0xFF))
            writeByte(bit32.band(bit32.rshift(value, 8), 0xFF))
            writeByte(bit32.band(value, 0xFF))
        end
        for _, byte in ipairs({ 0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A }) do writeByte(byte) end
        local function chunk(kind, payload, payloadLength)
            writeBE32(payloadLength)
            local start = pos
            for index = 1, 4 do writeByte(string.byte(kind, index)) end
            if payload then
                buffer.copy(png, pos, payload, 0, payloadLength)
                pos = pos + payloadLength
            end
            writeBE32(crc32(png, start, 4 + payloadLength))
        end
        local header = buffer.create(13)
        for index = 0, 3 do
            buffer.writeu8(header, index, bit32.band(bit32.rshift(width, (3 - index) * 8), 0xFF))
            buffer.writeu8(header, index + 4, bit32.band(bit32.rshift(height, (3 - index) * 8), 0xFF))
        end
        buffer.writeu8(header, 8, 8)
        buffer.writeu8(header, 9, 6)
        buffer.writeu8(header, 10, 0)
        buffer.writeu8(header, 11, 0)
        buffer.writeu8(header, 12, 0)
        chunk("IHDR", header, 13)
        chunk("IDAT", stream, zLength)
        chunk("IEND", nil, 0)
        return buffer.tostring(png)
    end
    local function asExecutor(fn)
        local env    = (getgenv and getgenv()) or _G
        local getId  = rawget(env, "getthreadidentity") or rawget(env, "getidentity")
            or getthreadidentity or getidentity
        local setId  = rawget(env, "setthreadidentity") or rawget(env, "setidentity")
            or setthreadidentity or setidentity
        local before = nil
        if type(getId) == "function" and type(setId) == "function" then
            local okGet, value = pcall(getId)
            if okGet then before = value end
            pcall(setId, 8)
        end
        local ok, result = pcall(fn)
        if before ~= nil and type(setId) == "function" then pcall(setId, before) end
        return ok, result
    end
    local function eggPng(icon)
        local assetId = icon and tostring(icon):match("%d+")
        if not assetId then return nil end
        local cached = _pngCache[assetId]
        if type(cached) == "string" then return cached end
        if type(cached) == "number" and os.clock() - cached < 120 then return nil end
        local ok, png = asExecutor(function()
            local image  = AssetService:CreateEditableImageAsync(Content.fromAssetId(tonumber(assetId)))
            local size   = image.Size
            local pixels = image:ReadPixelsBuffer(Vector2.zero, size)
            local small, width, height = shrink(pixels, math.floor(size.X), math.floor(size.Y))
            return encodePNG(small, width, height)
        end)
        local result = (ok and type(png) == "string" and #png > 0) and png or nil
        _pngCache[assetId] = result or os.clock()
        _pngOrder[#_pngOrder + 1] = assetId
        while #_pngOrder > PNG_CACHE_MAX do
            local oldest = table.remove(_pngOrder, 1)
            if oldest ~= assetId then _pngCache[oldest] = nil end
        end
        return result
    end
    local _imageCache = {}
    local RETRY_AFTER = 600
    local function lookupThumbnail(assetId)
        local cached = _imageCache[assetId]
        if type(cached) == "string" then return cached end
        if type(cached) == "number" and os.clock() - cached < RETRY_AFTER then return nil end
        local fn = getHTTP()
        if not fn then return nil end
        local ok, url = pcall(function()
            local res = fn({
                Url = string.format(
                    "https://thumbnails.roblox.com/v1/assets?assetIds=%s&returnPolicy=PlaceHolder&size=420x420&format=Png&isCircular=false",
                    assetId),
                Method = "GET",
            })
            if res and res.Body then
                local data = HttpService:JSONDecode(res.Body)
                if data and data.data and data.data[1] then
                    local imageUrl = tostring(data.data[1].imageUrl)
                    if imageUrl:find("/Image/", 1, true) then return imageUrl end
                end
            end
            return nil
        end)
        local resolved = (ok and url) or nil
        _imageCache[assetId] = resolved or os.clock()
        return resolved
    end
    function thumbnailUrl(icon)
        local assetId = icon and tostring(icon):match("%d+")
        return (assetId and lookupThumbnail(assetId)) or FALLBACK_IMG
    end
    local _avatarCache = nil
    local function avatarUrl()
        if _avatarCache ~= nil then return _avatarCache or nil end
        local fn = getHTTP()
        if not fn then return nil end
        for _, endpoint in ipairs({ "avatar-headshot" }) do
            local ok, url = pcall(function()
                local res = fn({
                    Url = string.format(
                        "https://thumbnails.roblox.com/v1/users/%s?userIds=%d&size=420x420&format=Png&isCircular=false",
                        endpoint, LocalPlayer.UserId),
                    Method = "GET",
                })
                if res and res.Body then
                    local data = HttpService:JSONDecode(res.Body)
                    local first = data and data.data and data.data[1]
                    if first and tostring(first.state) == "Completed" then
                        local imageUrl = tostring(first.imageUrl)
                        if imageUrl ~= "" then return imageUrl end
                    end
                end
                return nil
            end)
            if ok and url then
                _avatarCache = url
                return url
            end
        end
        _avatarCache = false
        return nil
    end
    local function eggDetails(entry)
        local category = entry.AssetCategory or entry.Category
        local config   = category and Game.Assets and Game.Assets.Directory
            and Game.Assets.Directory[category]
        local variants = {}
        if Game.Mutations then
            if entry.BaseMutation then
                table.insert(variants, tostring(Game.Mutations.LabelOf(entry.BaseMutation) or entry.BaseMutation))
            end
            for _, id in ipairs(entry.Mutations or {}) do
                table.insert(variants, tostring(Game.Mutations.LabelOf(id) or id))
            end
        end
        local weight, price = 0, 0
        local okRecord, record = pcall(Game.EggRecords.Decode, entry)
        if okRecord and record then
            weight = select(2, pcall(Game.EggRecords.WeightKg, record)) or 0
            price  = select(2, pcall(Game.EggRecords.SellPrice, record)) or 0
        end
        return {
            category = category,
            name     = config and config.Egg and config.Egg.DisplayName or tostring(category),
            rarity   = config and config.Rarity and config.Rarity.DisplayName or "?",
            color    = colorToInt(config and config.Rarity and config.Rarity.Color),
            icon     = config and config.Egg and config.Egg.Icon,
            variants = variants,
            weight   = type(weight) == "number" and weight or 0,
            price    = type(price) == "number" and price or 0,
        }
    end
    do
        local _hook = {
            enabled = false, conn = nil, ref = nil,
            url = "", userId = "",
            useName = false, selectedName = {},
            useVariant = false, selectedVariant = {},
            useRarity = false, selectedRarity = {},
            known = nil, pending = false,
        }
        local function buildEggNameOptions()
            local options, seen = {}, {}
            if Game.Assets and Game.Assets.Directory then
                for _, data in pairs(Game.Assets.Directory) do
                    local name = data.Egg and data.Egg.DisplayName
                    if name and not seen[name] then
                        seen[name] = true
                        table.insert(options, name)
                    end
                end
            end
            table.sort(options)
            if #options == 0 then options = { "Loading..." } end
            return options
        end
        local function buildVariantOptions()
            local options = { "None" }
            if Game.Mutations and Game.Mutations.All then
                local labels = {}
                for id in pairs(Game.Mutations.All()) do
                    table.insert(labels, tostring(Game.Mutations.LabelOf(id) or id))
                end
                table.sort(labels)
                for _, label in ipairs(labels) do table.insert(options, label) end
            end
            return options
        end
        local function buildRarityOptions()
            local seen, ranked = {}, {}
            if Game.Assets and Game.Assets.Directory then
                for _, data in pairs(Game.Assets.Directory) do
                    local rarity = data.Rarity
                    local name   = rarity and rarity.DisplayName
                    if name and not seen[name] then
                        seen[name] = true
                        table.insert(ranked, { name = name, rank = rarity.Rank or 0 })
                    end
                end
            end
            table.sort(ranked, function(a, b) return a.rank < b.rank end)
            local options = {}
            for _, item in ipairs(ranked) do table.insert(options, item.name) end
            if #options == 0 then options = { "Loading..." } end
            return options
        end
        local function passesFilter(info)
            if _hook.useName and not isSetEmpty(_hook.selectedName)
                and not _hook.selectedName[info.name] then
                return false
            end
            if _hook.useRarity and not isSetEmpty(_hook.selectedRarity)
                and not _hook.selectedRarity[info.rarity] then
                return false
            end
            if _hook.useVariant and not isSetEmpty(_hook.selectedVariant) then
                local matched = false
                if #info.variants == 0 then
                    matched = _hook.selectedVariant["None"] == true
                else
                    for _, label in ipairs(info.variants) do
                        if _hook.selectedVariant[label] then matched = true break end
                    end
                end
                if not matched then return false end
            end
            return true
        end
        local function snapshotEggs()
            local known = {}
            local save = Game.Save and Game.Save.Get()
            if save and type(save.EggInventory) == "table" then
                for uid in pairs(save.EggInventory) do known[uid] = true end
            end
            return known
        end
        local function announce(entry)
            local info = eggDetails(entry)
            if not passesFilter(info) then return end
            local variantText = #info.variants > 0 and table.concat(info.variants, ", ") or "None"
            local playerName  = LocalPlayer.DisplayName or LocalPlayer.Name
            local attachment  = eggPng(info.icon)
            local payload = buildPayload({
                userId      = _hook.userId,
                alertText   = "New **" .. info.rarity .. "** egg stolen! **" .. info.name .. "**",
                headerTitle = "Steal Egg",
                bodyText    = string.format("**||%s||** You have obtained a new **%s** egg \u{2014} **%s**!",
                    playerName, info.rarity, info.name),
                color       = info.color,
                imageUrl    = (attachment and ("attachment://" .. ATTACH_NAME))
                    or thumbnailUrl(info.icon),
                fields = {
                    { name = "\u{2022} Egg Name :",  value = info.name,   inline = false },
                    { name = "\u{2022} Rarity :",    value = info.rarity, inline = false },
                    { name = "\u{2022} Variant :",   value = variantText, inline = false },
                    { name = "\u{2022} Weight :",    value = string.format("%.2f Kg", info.weight), inline = false },
                    { name = "\u{2022} Sell Price :", value = formatNumber(info.price), inline = false },
                },
            })
            queueWebhook(_hook.url, payload, attachment, info.icon)
        end
        local function scanNewEggs()
            local save = Game.Save and Game.Save.Get()
            if not save or type(save.EggInventory) ~= "table" then return end
            if not _hook.known then _hook.known = snapshotEggs() return end
            local fresh = {}
            for uid, entry in pairs(save.EggInventory) do
                if not _hook.known[uid] then
                    fresh[#fresh + 1] = entry
                end
                _hook.known[uid] = true
            end
            for uid in pairs(_hook.known) do
                if save.EggInventory[uid] == nil then _hook.known[uid] = nil end
            end
            for _, entry in ipairs(fresh) do
                announce(entry)
            end
        end
        local function stopStealHook()
            _hook.enabled = false
            _hook.pending = false
            _hook.known   = nil
            if _hook.conn then
                pcall(function() _hook.conn:Disconnect() end)
                _hook.conn = nil
            end
        end
        table.insert(_G.LynxSAE.Stoppers, stopStealHook)
        local StealHookSection = WebhookTab:AddSection("Steal Egg Webhook")
        StealHookSection:AddInput({
            Title       = "Webhook URL (Steal Egg)",
            Default     = "",
            Placeholder = "https://discord.com/api/webhooks/...",
            Callback    = function(value) _hook.url = cleanStr(value) end,
        })
        StealHookSection:AddInput({
            Title       = "Discord User ID (Steal Egg)",
            Default     = "",
            Placeholder = "optional, for mentions",
            Callback    = function(value) _hook.userId = cleanId(value) end,
        })
        StealHookSection:AddToggle({
            Title    = "Webhook Filter Name",
            Default  = false,
            Callback = function(on) _hook.useName = on end,
        })
        StealHookSection:AddDropdown({
            Title    = "Webhook Egg Name",
            Multi    = true,
            Options  = buildEggNameOptions(),
            Default  = {},
            Callback = function(selected)
                _hook.selectedName = toSet(type(selected) == "table" and selected or {})
            end,
        })
        StealHookSection:AddToggle({
            Title    = "Webhook Filter Variant",
            Default  = false,
            Callback = function(on) _hook.useVariant = on end,
        })
        StealHookSection:AddDropdown({
            Title    = "Webhook Variant",
            Multi    = true,
            Options  = buildVariantOptions(),
            Default  = {},
            Callback = function(selected)
                _hook.selectedVariant = toSet(type(selected) == "table" and selected or {})
            end,
        })
        StealHookSection:AddToggle({
            Title    = "Webhook Filter Rarity",
            Default  = false,
            Callback = function(on) _hook.useRarity = on end,
        })
        StealHookSection:AddDropdown({
            Title    = "Webhook Rarity",
            Multi    = true,
            Options  = buildRarityOptions(),
            Default  = {},
            Callback = function(selected)
                _hook.selectedRarity = toSet(type(selected) == "table" and selected or {})
            end,
        })
        _hook.ref = StealHookSection:AddToggle({
            Title    = "Enable Steal Egg Webhook",
            Default  = false,
            Callback = function(on)
                stopStealHook()
                if not on then return end
                if _hook.url == "" then
                    notify("Webhook", "Steal egg webhook URL is empty.",
                        Color3.fromRGB(255, 90, 90), 3)
                    if _hook.ref then pcall(function() _hook.ref:SetValue(false) end) end
                    return
                end
                if not getHTTP() then
                    notify("Webhook", "This executor doesn't support HTTP requests.",
                        Color3.fromRGB(255, 90, 90), 3)
                    if _hook.ref then pcall(function() _hook.ref:SetValue(false) end) end
                    return
                end
                if not Game.Init() or not Game.Save
                    or type(Game.Save.FieldChanged) ~= "table" then
                    notify("Webhook", "Belum siap: " .. Game.MissingText(),
                        Color3.fromRGB(255, 90, 90), 3)
                    if _hook.ref then pcall(function() _hook.ref:SetValue(false) end) end
                    return
                end
                _hook.enabled = true
                _hook.known   = snapshotEggs()
                _hook.conn = Game.Save.FieldChanged:Connect(function(field)
                    if not _hook.enabled then return end
                    if field ~= "EggInventory" then return end
                    if _hook.pending then return end
                    _hook.pending = true
                    task.delay(0.4, function()
                        _hook.pending = false
                        if _hook.enabled then pcall(scanNewEggs) end
                    end)
                end)
                pcall(function()
                    Library:AddConnection("SAE_StealEggWebhook", _hook.conn)
                end)
            end,
        })
        StealHookSection:AddButton({
            Title    = "Test Steal Egg Webhook",
            Callback = function()
                if _hook.url == "" then
                    notify("Webhook", "Steal egg webhook URL is empty.",
                        Color3.fromRGB(255, 90, 90), 3)
                    return
                end
                task.spawn(function()
                    Game.Init()
                    local playerName = LocalPlayer.DisplayName or LocalPlayer.Name
                    local save = Game.Save and Game.Save.Get()
                    local entry
                    for _, item in pairs((type(save) == "table" and save.EggInventory) or {}) do
                        entry = item
                        break
                    end
                    local info = entry and eggDetails(entry) or nil
                    local attachment = info and eggPng(info.icon) or nil
                    local sent = queueWebhook(_hook.url, buildPayload({
                        userId      = _hook.userId,
                        alertText   = "New **" .. (info and info.rarity or "Divine")
                            .. "** egg stolen! **" .. (info and info.name or "Webhook Test") .. "**",
                        headerTitle = "Steal Egg",
                        bodyText    = string.format("**||%s||** Test: %s", playerName,
                            attachment and "egg image read straight from the game."
                                or "no image, falling back to a link."),
                        color       = info and info.color or 16766720,
                        imageUrl    = (attachment and ("attachment://" .. ATTACH_NAME))
                            or (info and thumbnailUrl(info.icon) or FALLBACK_IMG),
                        fields = {
                            { name = "\u{2022} Egg Name :", value = info and info.name or "Webhook Test", inline = false },
                            { name = "\u{2022} Rarity :",   value = info and info.rarity or "Divine", inline = false },
                            { name = "\u{2022} Image :",    value = attachment and "attachment (real icon)" or "link", inline = false },
                        },
                    }), attachment, info and info.icon or nil)
                    notify("Webhook",
                        sent and (attachment and "Test sent with the real egg image."
                            or "Test sent, but the image had to fall back to a link.")
                            or "Failed, check the URL / executor.",
                        sent and Color3.fromRGB(50, 200, 100) or Color3.fromRGB(255, 90, 90), 4)
                end)
            end,
        })
    end
    do
        local _spawn = {
            enabled = false, conns = {}, ref = nil,
            url = "", userId = "",
            selectedRarity = {}, known = {},
            batch = {}, pending = false,
        }
        local BATCH_WINDOW  = 1.5
        local BATCH_LINES   = 20
        local ANNOUNCE_RANK = 8
        local function spawnRarityOptions()
            local seen, ranked = {}, {}
            if Game.Assets and Game.Assets.Directory then
                for _, data in pairs(Game.Assets.Directory) do
                    local rarity = data.Rarity
                    local name   = rarity and rarity.DisplayName
                    local rank   = tonumber(rarity and rarity.Rank) or 0
                    if name and not seen[name] and rank >= ANNOUNCE_RANK then
                        seen[name] = true
                        table.insert(ranked, { name = name, rank = rank })
                    end
                end
            end
            table.sort(ranked, function(a, b) return a.rank < b.rank end)
            local options = {}
            for _, item in ipairs(ranked) do table.insert(options, item.name) end
            if #options == 0 then options = { "Secret", "Eternal", "Divine" } end
            return options
        end
        local function areaName(areaId)
            local areas = Game.Areas and Game.Areas.Directory
            local area  = areas and areas[areaId]
            return tostring(area and area.DisplayName or areaId or "?")
        end
        local function describeSpawn(item)
            if not item.uid or item.uid == "" then return item end
            local record = select(2, pcall(Game.EggState.ReadFieldEgg, item.uid))
            if type(record) ~= "table" then return item end
            local info = eggDetails(record)
            item.name  = info.name
            item.color = info.color
            item.icon  = info.icon
            item.category = info.category
            item.area  = areaName(record.AreaId)
            return item
        end
        local function flushBatch()
            local items = _spawn.batch
            _spawn.batch = {}
            if #items == 0 then return end
            for _, item in ipairs(items) do describeSpawn(item) end
            local playerName = LocalPlayer.DisplayName or LocalPlayer.Name
            if #items == 1 then
                local item = items[1]
                local fields = {
                    { name = "\u{2022} Rarity :", value = item.rarity, inline = false },
                }
                if item.name then
                    table.insert(fields, 1,
                        { name = "\u{2022} Egg Name :", value = item.name, inline = false })
                end
                if item.area then
                    fields[#fields + 1] = { name = "\u{2022} Area :", value = item.area, inline = false }
                end
                local attachment = eggPng(item.icon)
                queueWebhook(_spawn.url, buildPayload({
                    userId      = _spawn.userId,
                    alertText   = "**" .. item.rarity .. "** egg spawned"
                        .. (item.name and (": **" .. item.name .. "**") or ""),
                    headerTitle = "Egg Spawn",
                    bodyText    = string.format("**||%s||** %s", playerName, item.message),
                    color       = item.color,
                    imageUrl    = (attachment and ("attachment://" .. ATTACH_NAME))
                        or (item.icon and thumbnailUrl(item.icon) or nil),
                    fields      = fields,
                }), attachment, item.icon)
                return
            end
            local lines, shown = {}, 0
            for _, item in ipairs(items) do
                shown = shown + 1
                if shown <= BATCH_LINES then
                    lines[#lines + 1] = item.message
                end
            end
            if #items > BATCH_LINES then
                lines[#lines + 1] = string.format("\u{2026} and %d more", #items - BATCH_LINES)
            end
            queueWebhook(_spawn.url, buildPayload({
                userId      = _spawn.userId,
                alertText   = string.format("**%d** matching eggs spawned", #items),
                headerTitle = "Egg Spawn",
                bodyText    = string.format("**||%s||** %d eggs matching your filter just spawned.",
                    playerName, #items),
                color       = items[1].color,
                fields = { { name = "\u{2022} Eggs :", value = table.concat(lines, "\n"), inline = false } },
            }))
        end
        local function stripTags(text)
            return (tostring(text or "")
                :gsub("<br%s*/?>", " ")
                :gsub("<[^>]->", "")
                :gsub("%s+", " ")
                :gsub("^%s*(.-)%s*$", "%1"))
        end
        local function announceSpawn(entry)
            local rarity = tostring(entry.RarityId or "?")
            if isSetEmpty(_spawn.selectedRarity) then return end
            if not _spawn.selectedRarity[rarity] then return end
            local uid = tostring(entry.EggUid or "")
            if uid ~= "" then
                if _spawn.known[uid] then return end
                _spawn.known[uid] = true
            end
            _spawn.batch[#_spawn.batch + 1] = {
                rarity  = rarity,
                uid     = uid,
                message = stripTags(entry.Message),
            }
            if _spawn.pending then return end
            _spawn.pending = true
            task.delay(BATCH_WINDOW, function()
                _spawn.pending = false
                if _spawn.enabled then pcall(flushBatch) end
            end)
        end
        local function readReveal(payload, announce)
            if type(payload) ~= "table" then return end
            for _, entry in ipairs(payload.RareSpawns or {}) do
                if type(entry) == "table" then
                    if announce then
                        announceSpawn(entry)
                    elseif entry.EggUid then
                        _spawn.known[tostring(entry.EggUid)] = true
                    end
                end
            end
        end
        local function seedSpawnKnown()
            _spawn.known = {}
            local ok, shown, payload = pcall(Game.EggState.FetchRarityShows)
            if ok and shown then readReveal(payload, false) end
        end
        local function stopSpawnHook()
            _spawn.enabled = false
            _spawn.known   = {}
            _spawn.batch   = {}
            _spawn.pending = false
            for _, conn in ipairs(_spawn.conns) do
                pcall(function() conn:Disconnect() end)
            end
            _spawn.conns = {}
        end
        table.insert(_G.LynxSAE.Stoppers, stopSpawnHook)
        local SpawnHookSection = WebhookTab:AddSection("Egg Spawn Webhook")
        SpawnHookSection:AddInput({
            Title       = "Webhook URL (Egg Spawn)",
            Default     = "",
            Placeholder = "https://discord.com/api/webhooks/...",
            Callback    = function(value) _spawn.url = cleanStr(value) end,
        })
        SpawnHookSection:AddInput({
            Title       = "Discord User ID (Egg Spawn)",
            Default     = "",
            Placeholder = "optional, for mentions",
            Callback    = function(value) _spawn.userId = cleanId(value) end,
        })
        SpawnHookSection:AddDropdown({
            Title    = "Spawn Rarity",
            Multi    = true,
            Options  = spawnRarityOptions(),
            Default  = {},
            Callback = function(selected)
                _spawn.selectedRarity = toSet(type(selected) == "table" and selected or {})
            end,
        })
        _spawn.ref = SpawnHookSection:AddToggle({
            Title    = "Enable Egg Spawn Webhook",
            Default  = false,
            Callback = function(on)
                stopSpawnHook()
                if not on then return end
                local function refuse(text)
                    notify("Webhook", text, Color3.fromRGB(255, 90, 90), 3)
                    if _spawn.ref then pcall(function() _spawn.ref:SetValue(false) end) end
                end
                if _spawn.url == "" then return refuse("Egg spawn webhook URL is empty.") end
                if not getHTTP() then
                    return refuse("This executor doesn't support HTTP requests.")
                end
                if not Game.Init() or not Game.EggState or not Game.Assets
                    or type(Game.EggState.RarityRevealed) ~= "table" then
                    return refuse("Belum siap: " .. Game.MissingText())
                end
                if isSetEmpty(_spawn.selectedRarity) then
                    return refuse("Pick at least one rarity first.")
                end
                _spawn.enabled = true
                seedSpawnKnown()
                local conn = Game.EggState.RarityRevealed:Connect(function(payload)
                    if not _spawn.enabled then return end
                    pcall(readReveal, payload, true)
                end)
                _spawn.conns[#_spawn.conns + 1] = conn
                pcall(function() Library:AddConnection("SAE_EggSpawnWebhook", conn) end)
            end,
        })
        SpawnHookSection:AddButton({
            Title    = "Test Egg Spawn Webhook",
            Callback = function()
                if _spawn.url == "" then
                    notify("Webhook", "Egg spawn webhook URL is empty.",
                        Color3.fromRGB(255, 90, 90), 3)
                    return
                end
                local playerName = LocalPlayer.DisplayName or LocalPlayer.Name
                local sent = queueWebhook(_spawn.url, buildPayload({
                    userId      = _spawn.userId,
                    alertText   = "**Divine** egg spawned: **Webhook Test**",
                    headerTitle = "Egg Spawn",
                    bodyText    = string.format("**||%s||** a **Divine** egg spawned in **Cosmic** \u{2014} **Webhook Test**!",
                        playerName),
                    color       = 16766720,
                    imageUrl    = FALLBACK_IMG,
                    fields = {
                        { name = "\u{2022} Egg Name :", value = "Webhook Test", inline = false },
                        { name = "\u{2022} Rarity :",   value = "Divine",       inline = false },
                        { name = "\u{2022} Area :",     value = "Cosmic",       inline = false },
                    },
                }))
                notify("Webhook", sent and "Test sent." or "Failed, check the URL / executor.",
                    sent and Color3.fromRGB(50, 200, 100) or Color3.fromRGB(255, 90, 90), 3)
            end,
        })
    end
    do
        local _stats = {
            enabled = false, thread = nil, ref = nil,
            url = "", userId = "", minutes = 60,
            startedAt = os.time(), generation = 0,
        }
        local function countOf(tbl)
            if type(tbl) ~= "table" then return 0 end
            local total = 0
            for _ in pairs(tbl) do total = total + 1 end
            return total
        end
        local function elapsedText()
            local seconds = os.time() - _stats.startedAt
            local hours   = math.floor(seconds / 3600)
            local minutes = math.floor((seconds % 3600) / 60)
            if hours > 0 then return string.format("%dh %dm", hours, minutes) end
            return string.format("%dm", minutes)
        end
        local function buildStatsPayload()
            local save = Game.Save and Game.Save.Get()
            if type(save) ~= "table" then return nil end
            local eggs    = countOf(save.EggInventory)
            local pets    = countOf(save.Inventory)
            local index   = countOf(save.Index)
            local claimed = countOf(save.IndexClaimedCategories)
            local playerName = LocalPlayer.DisplayName or LocalPlayer.Name
            return buildPayload({
                userId        = _stats.userId,
                alertText     = "Stats update",
                headerTitle   = "Stats",
                bodyText      = string.format("**||%s||** progress summary after **%s** of runtime.",
                    playerName, elapsedText()),
                color         = 3447003,
                thumbnailUrl  = avatarUrl(),
                fields = {
                    { name = "\u{2022} Player :",     value = string.format("%s (@%s)", playerName, LocalPlayer.Name), inline = false },
                    { name = "\u{2022} Money :",      value = formatNumber(save.Money or 0), inline = false },
                    { name = "\u{2022} Eggs :",       value = tostring(eggs),  inline = true },
                    { name = "\u{2022} Pets :",       value = tostring(pets),  inline = true },
                    { name = "\u{2022} Pet Index :",  value = string.format("%d discovered / %d claimed", index, claimed), inline = false },
                    { name = "\u{2022} Runtime :",    value = elapsedText(), inline = false },
                },
            })
        end
        local function stopStatsHook()
            _stats.enabled    = false
            _stats.generation = _stats.generation + 1
            if _stats.thread then
                pcall(task.cancel, _stats.thread)
                _stats.thread = nil
            end
        end
        table.insert(_G.LynxSAE.Stoppers, stopStatsHook)
        local StatsHookSection = WebhookTab:AddSection("Stats Webhook")
        StatsHookSection:AddInput({
            Title       = "Webhook URL (Stats)",
            Default     = "",
            Placeholder = "https://discord.com/api/webhooks/...",
            Callback    = function(value) _stats.url = cleanStr(value) end,
        })
        StatsHookSection:AddInput({
            Title       = "Discord User ID (Stats)",
            Default     = "",
            Placeholder = "optional, for mentions",
            Callback    = function(value) _stats.userId = cleanId(value) end,
        })
        StatsHookSection:AddInput({
            Title       = "Stats Interval (minutes)",
            Default     = "60",
            Placeholder = "60",
            Callback    = function(value)
                local minutes = tonumber(cleanStr(value))
                if minutes and minutes >= 1 then
                    _stats.minutes = minutes
                end
            end,
        })
        _stats.ref = StatsHookSection:AddToggle({
            Title    = "Enable Stats Webhook",
            Default  = false,
            Callback = function(on)
                stopStatsHook()
                if not on then return end
                if _stats.url == "" then
                    notify("Webhook", "Stats webhook URL is empty.",
                        Color3.fromRGB(255, 90, 90), 3)
                    if _stats.ref then pcall(function() _stats.ref:SetValue(false) end) end
                    return
                end
                if not getHTTP() then
                    notify("Webhook", "This executor doesn't support HTTP requests.",
                        Color3.fromRGB(255, 90, 90), 3)
                    if _stats.ref then pcall(function() _stats.ref:SetValue(false) end) end
                    return
                end
                if not Game.Init() then
                    notify("Webhook", "Belum siap: " .. Game.MissingText(),
                        Color3.fromRGB(255, 90, 90), 3)
                    if _stats.ref then pcall(function() _stats.ref:SetValue(false) end) end
                    return
                end
                _stats.enabled    = true
                _stats.generation = _stats.generation + 1
                local generation  = _stats.generation
                _stats.thread = task.spawn(function()
                    while _stats.enabled and _stats.generation == generation do
                        local waitSeconds = math.max(_stats.minutes, 1) * 60
                        for _ = 1, waitSeconds do
                            if not _stats.enabled or _stats.generation ~= generation then return end
                            task.wait(1)
                        end
                        local payload = buildStatsPayload()
                        if payload then queueWebhook(_stats.url, payload) end
                    end
                end)
            end,
        })
        StatsHookSection:AddButton({
            Title    = "Test Stats Webhook",
            Callback = function()
                if _stats.url == "" then
                    notify("Webhook", "Stats webhook URL is empty.",
                        Color3.fromRGB(255, 90, 90), 3)
                    return
                end
                if not Game.Init() then
                    notify("Webhook", "Belum siap: " .. Game.MissingText(),
                        Color3.fromRGB(255, 90, 90), 3)
                    return
                end
                local payload = buildStatsPayload()
                local sent = payload ~= nil and queueWebhook(_stats.url, payload)
                notify("Webhook", sent and "Test sent." or "Failed, check the URL / executor.",
                    sent and Color3.fromRGB(50, 200, 100) or Color3.fromRGB(255, 90, 90), 3)
            end,
        })
    end
    do
        local FISH_RARITIES = { "Common", "Uncommon", "Rare", "Epic", "Legendary", "Mythic", "Cosmic", "Secret", "Eternal", "Divine" }
        local RARITY_FALLBACK = {
            Common = 0xB4B4B4, Uncommon = 0x5AD25A, Rare = 0x3C8CFF, Epic = 0xA050F0, Legendary = 0xFFAA00,
            Mythic = 0xFF3C78, Cosmic = 0x50E6FF, Secret = 0x282828, Eternal = 0xFFFFFF, Divine = 0xFFE650,
        }
        local _fish = {
            enabled = false, ref = nil, url = "", userId = "",
            selected = {}, sent = 0,
        }
        local function fishGroup(reward)
            if reward.Kind == "Tokens" then return "Candy Corn" end
            if reward.Kind == "Mutation" then return "Mutation" end
            return tostring(reward.Rarity or "Unknown")
        end
        local function rarityColor(rarity)
            for _, data in pairs(Game.Assets and Game.Assets.Directory or {}) do
                local r = data.Rarity
                if r and r.DisplayName == rarity and typeof(r.Color) == "Color3" then return colorToInt(r.Color) end
            end
            return RARITY_FALLBACK[rarity] or 0xFF8C00
        end
        local function sendFish(reward, test)
            local group = fishGroup(reward)
            local name = tostring(reward.DisplayName or reward.Id or "?")
            local amount = tonumber(reward.Amount) or 1
            local fields = {
                { name = "\u{2022} Item :", value = name, inline = false },
                { name = "\u{2022} Type :", value = tostring(reward.Kind or "?"), inline = true },
                { name = "\u{2022} Rarity :", value = reward.Rarity and tostring(reward.Rarity) or "-", inline = true },
                { name = "\u{2022} Amount :", value = formatNumber(amount), inline = true },
            }
            if tonumber(reward.OneIn) and tonumber(reward.OneIn) > 1 then
                fields[#fields + 1] = { name = "\u{2022} Chance :", value = "1 in " .. formatNumber(reward.OneIn), inline = true }
            end
            local playerName = LocalPlayer.DisplayName or LocalPlayer.Name
            local icon = reward.Icon
            task.spawn(function()
                local attachment = icon and eggPng(icon)
                queueWebhook(_fish.url, buildPayload({
                    userId      = _fish.userId,
                    alertText   = string.format("Caught **%s**%s%s", name,
                        amount > 1 and (" x" .. formatNumber(amount)) or "", test and " (test)" or ""),
                    headerTitle = "Fish Caught",
                    bodyText    = string.format("**||%s||** fished up **%s**%s.", playerName, name,
                        reward.Rarity and (" (" .. tostring(reward.Rarity) .. ")") or ""),
                    color       = group == "Candy Corn" and 0xFF8C00 or group == "Mutation" and 0x8A2BE2 or rarityColor(group),
                    imageUrl    = (attachment and ("attachment://" .. ATTACH_NAME)) or (icon and thumbnailUrl(icon)) or nil,
                    fields      = fields,
                }), attachment, icon)
            end)
            return true
        end
        function Status.FishCaught(reward)
            if not (_fish.enabled and type(reward) == "table") then return end
            if not _fish.selected[fishGroup(reward)] then return end
            _fish.sent = _fish.sent + 1
            sendFish(reward)
        end
        local FishHookSection = WebhookTab:AddSection("Fish Caught Webhook")
        FishHookSection:AddInput({
            Title       = "Webhook URL (Fish Caught)",
            Default     = "",
            Placeholder = "https://discord.com/api/webhooks/...",
            Callback    = function(value) _fish.url = cleanStr(value) end,
        })
        FishHookSection:AddInput({
            Title       = "Discord User ID (Fish Caught)",
            Default     = "",
            Placeholder = "optional, for mentions",
            Callback    = function(value) _fish.userId = cleanId(value) end,
        })
        local fishOptions = { "Candy Corn", "Mutation" }
        for _, rarity in ipairs(FISH_RARITIES) do fishOptions[#fishOptions + 1] = rarity end
        FishHookSection:AddDropdown({
            Title    = "Fish Rarity",
            Multi    = true,
            Options  = fishOptions,
            Default  = {},
            Callback = function(selected)
                _fish.selected = toSet(type(selected) == "table" and selected or {})
            end,
        })
        _fish.ref = FishHookSection:AddToggle({
            Title    = "Enable Fish Caught Webhook",
            Default  = false,
            Callback = function(on)
                _fish.enabled = false
                if not on then return end
                local function refuse(text)
                    notify("Webhook", text, Color3.fromRGB(255, 90, 90), 3)
                    if _fish.ref then pcall(function() _fish.ref:SetValue(false) end) end
                end
                if _fish.url == "" then return refuse("Fish caught webhook URL is empty.") end
                if not getHTTP() then return refuse("This executor doesn't support HTTP requests.") end
                if isSetEmpty(_fish.selected) then return refuse("Pick at least one Fish Rarity first.") end
                _fish.enabled = true
            end,
        })
        FishHookSection:AddButton({
            Title    = "Test Fish Caught Webhook",
            Callback = function()
                if _fish.url == "" then
                    notify("Webhook", "Fish caught webhook URL is empty.", Color3.fromRGB(255, 90, 90), 3)
                    return
                end
                local sent = getHTTP() ~= nil and sendFish({
                    Kind = "Egg", Id = "Crowshade", DisplayName = "Crowshade Egg", Amount = 1,
                    Rarity = "Mythic", OneIn = 40, Icon = "rbxassetid://139947082132164",
                }, true)
                notify("Webhook", sent and "Test sent." or "Failed, check the URL / executor.",
                    sent and Color3.fromRGB(50, 200, 100) or Color3.fromRGB(255, 90, 90), 3)
            end,
        })
        table.insert(_G.LynxSAE.Stoppers, function()
            _fish.enabled = false
            Status.FishCaught = nil
        end)
    end
    do
        local RED, GREEN = Color3.fromRGB(255, 90, 90), Color3.fromRGB(50, 200, 100)
        local function serverNow() return workspace:GetServerTimeNow() end
        local function stamp(at, style) return string.format("<t:%d:%s>", math.floor(at), style or "R") end
        local function playerName() return LocalPlayer.DisplayName or LocalPlayer.Name end
        local function gameRemotes()
            local ok, all = pcall(require, ReplicatedStorage.Shared.Remotes)
            return ok and type(all) == "table" and all or nil
        end
        local function disconnectAll(list)
            for _, conn in ipairs(list) do pcall(function() conn:Disconnect() end) end
            table.clear(list)
        end
        local function refuseStart(ref, text)
            notify("Webhook", text, RED, 3)
            if ref then pcall(function() ref:SetValue(false) end) end
        end
        local function testDone(sent)
            notify("Webhook", sent and "Test sent." or "Failed, check the URL / executor.", sent and GREEN or RED, 3)
        end
        local function sendWithImage(url, opts, icon)
            if url == "" or not getHTTP() then return false end
            task.spawn(function()
                local attachment = icon and eggPng(icon)
                opts.imageUrl = (attachment and ("attachment://" .. ATTACH_NAME))
                    or (icon and thumbnailUrl(icon)) or nil
                queueWebhook(url, buildPayload(opts), attachment, icon)
            end)
            return true
        end
        local STAR_ICON = "rbxassetid://124403449190149"  
        local function starIcon()
            local ok, icon = pcall(function() return LocalPlayer.PlayerGui.ShootingStarUI.Reward.Icon.Image end)
            return ok and type(icon) == "string" and icon ~= "" and icon or STAR_ICON
        end
        local _starHook = {
            enabled = false, outcome = true, url = "", userId = "",
            ref = nil, conns = {}, sent = {},
        }
        local function starArea()
            local ok, area = pcall(function()
                return require(ReplicatedStorage.Shared.Flags.ShootingStarFlags).LandAreaId:Get()
            end)
            return ok and tostring(area) or "Cosmic"
        end
        local function sendStar(p, test)
            local fields = {
                { name = "\u{2022} Lands :", value = stamp(p.LandAt), inline = true },
                { name = "\u{2022} Gone :", value = stamp(p.ExpiresAt), inline = true },
                { name = "\u{2022} Area :", value = starArea(), inline = false },
            }
            if typeof(p.Landing) == "CFrame" then
                local at = p.Landing.Position
                fields[#fields + 1] = { name = "\u{2022} Landing Spot :",
                    value = string.format("%.0f, %.0f, %.0f", at.X, at.Y, at.Z), inline = false }
            end
            return sendWithImage(_starHook.url, {
                userId      = _starHook.userId,
                alertText   = "**Shooting Star** is falling" .. (test and " (test)" or "") .. "!",
                headerTitle = "Shooting Star",
                bodyText    = string.format("**||%s||** a Shooting Star is falling for you, it lands %s.",
                    playerName(), stamp(p.LandAt)),
                color       = 10181046,
                fields      = fields,
            }, starIcon())
        end
        local function announceStar(p)
            if not _starHook.enabled or type(p) ~= "table" or p.Id == nil then return end
            if type(p.LandAt) ~= "number" or type(p.ExpiresAt) ~= "number" or serverNow() >= p.ExpiresAt then return end
            if _starHook.sent[p.Id] then return end
            _starHook.sent[p.Id] = true
            sendStar(p)
        end
        local function starOutcome(text, color)
            return function(id, amount)
                if not (_starHook.enabled and _starHook.outcome and id ~= nil and _starHook.sent[id]) then return end
                _starHook.sent[id] = nil
                sendWithImage(_starHook.url, {
                    userId      = _starHook.userId,
                    alertText   = text,
                    headerTitle = "Shooting Star",
                    bodyText    = string.format("**||%s||** %s%s", playerName(), text,
                        tonumber(amount) and string.format(" (+%d)", tonumber(amount)) or ""),
                    color       = color,
                }, starIcon())
            end
        end
        local function stopStarHook()
            _starHook.enabled = false
            disconnectAll(_starHook.conns)
        end
        table.insert(_G.LynxSAE.Stoppers, stopStarHook)
        local StarHookSection = WebhookTab:AddSection("Shooting Star Webhook")
        StarHookSection:AddInput({
            Title       = "Webhook URL (Shooting Star)",
            Default     = "",
            Placeholder = "https://discord.com/api/webhooks/...",
            Callback    = function(value) _starHook.url = cleanStr(value) end,
        })
        StarHookSection:AddInput({
            Title       = "Discord User ID (Shooting Star)",
            Default     = "",
            Placeholder = "optional, for mentions",
            Callback    = function(value) _starHook.userId = cleanId(value) end,
        })
        StarHookSection:AddToggle({
            Title    = "Send Caught / Expired",
            Default  = true,
            Callback = function(on) _starHook.outcome = on == true end,
        })
        _starHook.ref = StarHookSection:AddToggle({
            Title    = "Enable Shooting Star Webhook",
            Default  = false,
            Callback = function(on)
                stopStarHook()
                if not on then return end
                if _starHook.url == "" then return refuseStart(_starHook.ref, "Shooting star webhook URL is empty.") end
                if not getHTTP() then return refuseStart(_starHook.ref, "This executor doesn't support HTTP requests.") end
                local all = gameRemotes()
                local net = all and all.ShootingStar
                if type(net) ~= "table" or not net.Fall then
                    return refuseStart(_starHook.ref, "Shooting Star remotes not found.")
                end
                _starHook.enabled = true
                local function on(remote, fn)
                    local ok, conn = pcall(function()
                        return remote.OnClientEvent:Connect(function(...) pcall(fn, ...) end)
                    end)
                    if ok then table.insert(_starHook.conns, conn) end
                end
                on(net.Fall, announceStar)
                if net.Claimed then on(net.Claimed, starOutcome("caught the Shooting Star!", 5763719)) end
                if net.Expired then on(net.Expired, starOutcome("missed the Shooting Star, it expired.", 15548997)) end
                pcall(function() Library:AddConnection("SAE_StarWebhook", _starHook.conns[1]) end)
                if net.AskState then
                    task.spawn(function()
                        local ok, p = pcall(function() return net.AskState:InvokeServer() end)
                        if ok then announceStar(p) end
                    end)
                end
            end,
        })
        StarHookSection:AddButton({
            Title    = "Test Shooting Star Webhook",
            Callback = function()
                if _starHook.url == "" then return notify("Webhook", "Shooting star webhook URL is empty.", RED, 3) end
                local now = serverNow()
                testDone(sendStar({
                    Id = "test", LandAt = now + 45, ExpiresAt = now + 245,
                    Landing = CFrame.new(3200, 70, -400),
                }, true))
            end,
        })
    end
end
task.wait()
do
    local ServerTab = MainWindow:AddTab({ Name = "Server", Icon = "web" })
    local TeleportService = game:GetService("TeleportService")
    local HttpService     = game:GetService("HttpService")
    local _server = { busy = false, plainRejoin = false }
    local function httpFn()
        for _, name in ipairs({ "request", "http_request" }) do
            local fn = rawget(getfenv and getfenv(0) or _G, name)
                or (getgenv and rawget(getgenv(), name))
            if type(fn) == "function" then return fn end
        end
        for _, tbl in ipairs({ syn, fluxus, http }) do
            if type(tbl) == "table" and type(tbl.request) == "function" then
                return tbl.request
            end
        end
        return nil
    end
    local function fetchServers(cursor)
        local fn = httpFn()
        if not fn then return nil end
        local ok, result = pcall(function()
            local url = string.format(
                "https://games.roblox.com/v1/games/%d/servers/Public?sortOrder=Asc&limit=100&excludeFullGames=true%s",
                game.PlaceId, cursor and ("&cursor=" .. cursor) or "")
            local res = fn({ Url = url, Method = "GET" })
            if not res or not res.Body then return nil end
            return HttpService:JSONDecode(res.Body)
        end)
        if ok then return result end
        return nil
    end
    local function findServers(fits, enough)
        local found, cursor, pages = {}, nil, 0
        repeat
            local page = fetchServers(cursor)
            if not page or type(page.data) ~= "table" then break end
            for _, entry in ipairs(page.data) do
                if entry.id ~= game.JobId and type(entry.playing) == "number" and type(entry.maxPlayers) == "number"
                    and entry.playing < entry.maxPlayers and fits(entry) then
                    found[#found + 1] = entry
                end
            end
            cursor = page.nextPageCursor
            pages = pages + 1
        until #found >= enough or not cursor or pages >= 3
        return found
    end
    local SectionServer = ServerTab:AddSection("Server")
    SectionServer:AddButton({
        Title    = "Rejoin",
        Callback = function()
            if _server.busy then return end
            _server.busy, _server.plainRejoin = true, true
            notify("Server", "Rejoining server...", Color3.fromRGB(50, 200, 100), 3)
            local ok = pcall(function()
                TeleportService:TeleportToPlaceInstance(game.PlaceId, game.JobId, LocalPlayer)
            end)
            if not ok then
                pcall(function() TeleportService:Teleport(game.PlaceId, LocalPlayer) end)
            end
            task.delay(6, function() _server.busy, _server.plainRejoin = false, false end)
        end,
    })
    SectionServer:AddButton({
        Title    = "Server Hop",
        Callback = function()
            if _server.busy then return end
            _server.busy = true
            task.spawn(function()
                if not httpFn() then
                    notify("Server", "This executor doesn't support HTTP requests.", Color3.fromRGB(255, 90, 90), 3)
                    _server.busy = false
                    return
                end
                notify("Server", "Looking for another server...", Color3.fromRGB(50, 200, 100), 3)
                local candidates = findServers(function() return true end, 30)
                if #candidates == 0 then
                    notify("Server", "No other server is available.", Color3.fromRGB(255, 90, 90), 4)
                    _server.busy = false
                    return
                end
                local target = candidates[math.random(1, #candidates)].id
                notify("Server", string.format("Hopping to another server (%d options).", #candidates), Color3.fromRGB(50, 200, 100), 3)
                local ok = pcall(function()
                    TeleportService:TeleportToPlaceInstance(game.PlaceId, target, LocalPlayer)
                end)
                if not ok then
                    notify("Server", "Failed to hop servers.", Color3.fromRGB(255, 90, 90), 4)
                end
                task.delay(6, function() _server.busy = false end)
            end)
        end,
    })
    local GuiService = game:GetService("GuiService")
    local _reconnect = { on = false, trying = false }
    local function reconnect()
        if _reconnect.trying then return end
        _reconnect.trying = true
        task.spawn(function()
            while _reconnect.on do
                pcall(function() TeleportService:Teleport(game.PlaceId, LocalPlayer) end)
                task.wait(5)
            end
            _reconnect.trying = false
        end)
    end
    local errorConn = GuiService.ErrorMessageChanged:Connect(function(message)
        if _reconnect.on and message ~= "" then reconnect() end
    end)
    pcall(function() Library:AddConnection("SAE_AutoReconnect", errorConn) end)
    table.insert(_G.LynxSAE.Stoppers, function()
        _reconnect.on = false
        errorConn:Disconnect()
    end)
    SectionServer:AddToggle({
        Title    = "Auto Reconnect",
        Default  = false,
        Callback = function(on)
            _reconnect.on = on
            if on and GuiService:GetErrorMessage() ~= "" then reconnect() end
        end,
    })
    local _autoExec = { on = true, queued = false }
    local queueOnTeleport = (type(queue_on_teleport) == "function" and queue_on_teleport)
        or (type(queueonteleport) == "function" and queueonteleport)
        or (type(syn) == "table" and type(syn.queue_on_teleport) == "function" and syn.queue_on_teleport)
        or (type(fluxus) == "table" and type(fluxus.queue_on_teleport) == "function" and fluxus.queue_on_teleport)
    local function queueLoader()
        if not (_autoExec.on and queueOnTeleport) or _autoExec.queued or _server.plainRejoin then return end
        if type(LYNX_KEY) ~= "string" or LYNX_KEY == "" or LYNX_SCRIPT_URL == "" then return end
        local source = string.format(
            "repeat task.wait() until game:IsLoaded()\n"
                .. "getgenv().SCRIPT_KEY = %q\n"
                .. "getgenv().LYNX_SCRIPT_URL = %q\n"
                .. "loadstring(game:HttpGet(%q))()\n",
            LYNX_KEY, LYNX_SCRIPT_URL, LYNX_SCRIPT_URL)
        if pcall(queueOnTeleport, source) then _autoExec.queued = true end
    end
    do
        local conns = {
            LocalPlayer.OnTeleport:Connect(function(state)
                if state == Enum.TeleportState.Started or state == Enum.TeleportState.InProgress then queueLoader() end
            end),
            TeleportService.TeleportInitFailed:Connect(function(player)
                if player == LocalPlayer then _autoExec.queued, _server.plainRejoin = false, false end
            end),
        }
        table.insert(_G.LynxSAE.Stoppers, function()
            for _, conn in ipairs(conns) do conn:Disconnect() end
        end)
    end
    SectionServer:AddToggle({
        Title    = "Auto Execute After Teleport",
        Default  = true,
        Callback = function(on)
            _autoExec.on = on == true
            if on and not queueOnTeleport then
                notify("Server", "This executor has no queue_on_teleport: Auto Execute can't work here.", Color3.fromRGB(255, 90, 90), 4)
            end
        end,
    })
    local Players = game:GetService("Players")
    local quiet = { max = 3, auto = false, live = true, state = "Off", tried = {}, joinedAt = os.clock() }
    local function serverCap() return math.max(2, Players.MaxPlayers) end
    local function playersHere() return #Players:GetPlayers() end
    local function midCarry()
        return Status.stealBusy == true or LocalPlayer:GetAttribute("HalloweenCarrying") == true
            or LocalPlayer:GetAttribute("HalloweenPumpkinCarrying") == true
    end
    local function hopToQuiet()
        if _server.busy then return false end
        if not httpFn() then
            quiet.state = "This executor doesn't support HTTP requests"
            return false
        end
        _server.busy = true
        quiet.state = "Looking for a quiet server..."
        local candidates = findServers(function(entry)
            return entry.playing + 1 <= quiet.max and not quiet.tried[entry.id]
        end, 20)
        if #candidates == 0 then
            quiet.state = string.format("No server with %d or fewer players right now", quiet.max - 1)
            _server.busy = false
            return false
        end
        table.sort(candidates, function(a, b) return a.playing < b.playing end)
        local least, pool = candidates[1].playing, {}
        for _, entry in ipairs(candidates) do
            if entry.playing == least then pool[#pool + 1] = entry end
        end
        local target = pool[math.random(1, #pool)]
        quiet.tried[target.id] = true
        quiet.state = string.format("Joining a server with %d player(s)", target.playing)
        notify("Lowest Player Server", string.format("Joining a server with %d player(s).", target.playing), Color3.fromRGB(50, 200, 100), 3)
        local ok = pcall(function()
            TeleportService:TeleportToPlaceInstance(game.PlaceId, target.id, LocalPlayer)
        end)
        task.delay(10, function() _server.busy = false end)
        return ok
    end
    do
        local conn = TeleportService.TeleportInitFailed:Connect(function(player, _, message)
            if player ~= LocalPlayer then return end
            _server.busy = false
            quiet.state = "Teleport failed (" .. tostring(message) .. "), trying another"
        end)
        table.insert(_G.LynxSAE.Stoppers, function() conn:Disconnect() end)
    end
    task.spawn(function()
        while quiet.live do
            if quiet.auto then
                local here = playersHere()
                if here <= quiet.max then
                    quiet.state = string.format("This server is fine (%d / %d players)", here, quiet.max)
                elseif os.clock() - quiet.joinedAt < 15 then
                    quiet.state = "Just joined: checking again in a moment"
                elseif midCarry() then
                    quiet.state = "Too many players: waiting for the carry to finish"
                else
                    hopToQuiet()
                end
            else
                quiet.state = "Off"
            end
            task.wait(5)
        end
    end)
    table.insert(_G.LynxSAE.Stoppers, function() quiet.live = false end)
    local QuietSection = ServerTab:AddSection("Lowest Player Server")
    local quietStatus = QuietSection:AddParagraph({ Title = "Lowest Player Server Status", Content = "Off" })
    task.spawn(function()
        local last
        while quiet.live do
            local text = string.format("Players here: %d / %d\nMax wanted: %d (you included)\nState: %s",
                playersHere(), serverCap(), quiet.max, quiet.state)
            if text ~= last then
                last = text
                pcall(setParagraph, quietStatus, text)
            end
            task.wait(1)
        end
    end)
    local maxOptions = {}
    for count = 2, serverCap() - 1 do maxOptions[#maxOptions + 1] = tostring(count) end
    QuietSection:AddDropdown({
        Title    = "Max Players Per Server",
        Options  = maxOptions,
        Default  = tostring(math.min(3, serverCap() - 1)),
        Callback = function(value)
            local count = tonumber(value)
            if count then quiet.max = count end
        end,
    })
    QuietSection:AddToggle({
        Title    = "Auto Join Lowest Player Server",
        Default  = false,
        Callback = function(on) quiet.auto = on == true end,
    })
    QuietSection:AddButton({
        Title    = "Server Hop Now",
        Callback = function()
            task.spawn(function()
                if not hopToQuiet() then
                    notify("Lowest Player Server", quiet.state, Color3.fromRGB(255, 90, 90), 4)
                end
            end)
        end,
    })
end
task.wait()
do
    local SettingsTab = MainWindow:AddTab({ Name = "Settings", Icon = "settings" })
    do
        local _tread = {
            antiEnabled = false, antiConn = nil, antiRef = nil,
            antiBusy    = false, antiNext = 0, misses = 0,
            autoEnabled = false, thread   = nil, autoRef = nil,
            mounted     = false, idleSince = nil, swapped = false,
            settle      = 1, stepSpeed = 200, stepClear = 15, refusals = 0, fixAt = 0,
        }
        local function othersBusy()
            return Control.Blocker("treadmill", true) or Control.OtherMover("treadmill")
                or Control.BusyRecently("treadmill", 3)
        end
        local function onBelt()
            _tread.mounted     = true
            _tread.misses      = 0
            Status.onTreadmill = true
        end
        local function dismount()
            _tread.mounted = false
            return Treadmill.Leave()
        end
        local function stepAway()
            local belt = Treadmill.Belt()
            local _, root = getCharacter()
            if not (belt and root) then return end
            local flat = Vector3.new(root.Position.X - belt.Position.X, 0, root.Position.Z - belt.Position.Z)
            if flat.Magnitude > _tread.stepClear then return end
            local ok, plot = pcall(Game.PlotState.ResolvePlot)
            local center = ok and plot and plot.CenterPoint
            if not center then return end
            Movement.To(center.Position + Vector3.new(0, 4, 0), 6, _tread.stepSpeed)
        end
        local function stopAntiTreadmill()
            _tread.antiEnabled = false
            if _tread.antiConn then
                pcall(function() _tread.antiConn:Disconnect() end)
                _tread.antiConn = nil
            end
        end
        local function stopAutoTreadmill()
            local wasOn = _tread.autoEnabled
            _tread.autoEnabled = false
            _tread.idleSince   = nil
            if _tread.thread then
                pcall(task.cancel, _tread.thread)
                _tread.thread = nil
            end
            Control.Release("treadmill")
            Status.onTreadmill = false
            local mounted = _tread.mounted
            _tread.mounted = false
            if wasOn and (mounted or Treadmill.Assigned()) then
                task.spawn(function()
                    Treadmill.Leave()
                    if not othersBusy() and Control.Acquire("treadmill", true) then
                        stepAway()
                        Control.Release("treadmill")
                    end
                end)
            end
            if _tread.swapped then
                _tread.swapped = false
                task.spawn(Movement.RestartAnimate)
            end
        end
        table.insert(_G.LynxSAE.Stoppers, stopAntiTreadmill)
        table.insert(_G.LynxSAE.Stoppers, stopAutoTreadmill)
        local TreadSection = SettingsTab:AddSection("Treadmill")
        _tread.antiRef = TreadSection:AddToggle({
            Title    = "Anti Treadmill",
            Default  = false,
            Callback = function(on)
                stopAntiTreadmill()
                if not on then return end
                _tread.antiEnabled = true
                _tread.antiConn = RunService.Heartbeat:Connect(function()
                    if not _tread.antiEnabled then return end
                    if Status.onTreadmill then return end
                    if _tread.autoEnabled and not othersBusy() then return end
                    if _tread.antiBusy or os.clock() < _tread.antiNext then return end
                    if not Treadmill.Assigned() then return end
                    _tread.antiBusy = true
                    _tread.antiNext = os.clock() + 0.3
                    task.spawn(function()
                        Treadmill.Dismount()
                        _tread.antiBusy = false
                    end)
                end)
                pcall(function()
                    Library:AddConnection("SAE_AntiTreadmill", _tread.antiConn)
                end)
            end,
        })
        _tread.autoRef = TreadSection:AddToggle({
            Title    = "Auto Treadmill When Idle",
            Default  = false,
            Callback = function(on)
                stopAutoTreadmill()
                if not on then return end
                if not Game.Init() then
                    notify("Auto Treadmill", "Belum siap: " .. Game.MissingText(),
                        Color3.fromRGB(255, 90, 90), 3)
                    if _tread.autoRef then pcall(function() _tread.autoRef:SetValue(false) end) end
                    return
                end
                _tread.autoEnabled = true
                _tread.thread = task.spawn(function()
                    while _tread.autoEnabled do
                        pcall(function()
                            local blocker = othersBusy()
                            if blocker then
                                if _tread.mounted or Treadmill.Assigned() then dismount() end
                                _tread.idleSince = nil
                                task.wait(0.5)
                                return
                            end
                            if _tread.mounted then
                                if Treadmill.IsMounted() then
                                    _tread.misses = 0
                                else
                                    _tread.misses = _tread.misses + 1
                                    if _tread.misses >= 2 then
                                        _tread.misses      = 0
                                        _tread.mounted     = false
                                        Status.onTreadmill = false
                                    end
                                end
                                task.wait(1)
                                return
                            end
                            if Treadmill.Assigned() and not Treadmill.IsMounted() then
                                Treadmill.Leave(1.5)
                            end
                            if Treadmill.IsMounted() then
                                onBelt()
                                task.wait(1)
                                return
                            end
                            _tread.idleSince = _tread.idleSince or os.clock()
                            if os.clock() - _tread.idleSince < _tread.settle then
                                task.wait(0.5)
                                return
                            end
                            local belt = Treadmill.Belt()
                            if not belt then task.wait(2) return end
                            local _, root = getCharacter()
                            if not root then task.wait(1) return end
                            Status.onTreadmill = true
                            if not Control.Acquire("treadmill", true) then
                                Status.onTreadmill = false
                                task.wait(0.5)
                                return
                            end
                            if (belt.Position - root.Position).Magnitude > 8 then
                                Movement.SwapHumanoid()
                                _tread.swapped = true
                                Movement.ToVia(belt.Position + Vector3.new(0, 4, 0), 6, 620, function()
                                    return _tread.autoEnabled
                                        and not othersBusy()
                                        and Control.Owns("treadmill")
                                end)
                            end
                            if othersBusy() or not Control.Owns("treadmill") then
                                Control.Release("treadmill")
                                dismount()
                                return
                            end
                            local accepted, reason = Treadmill.Mount()
                            if accepted then
                                _tread.refusals = 0
                            else
                                _tread.refusals = (_tread.refusals or 0) + 1
                                local desynced = tostring(reason):lower():find("not grounded") ~= nil
                                    and Movement.Grounded()
                                if (desynced or _tread.refusals >= 5)
                                    and os.clock() >= (_tread.fixAt or 0) then
                                    _tread.refusals = 0
                                    _tread.fixAt    = os.clock() + (desynced and 10 or 60)
                                    Movement.Respawn()
                                    task.wait(4)
                                    return
                                end
                            end
                            local confirmed = false
                            local deadline  = os.clock() + 2
                            while os.clock() < deadline and not othersBusy() do
                                if Treadmill.IsMounted() then
                                    confirmed = true
                                    break
                                end
                                task.wait(0.1)
                            end
                            Control.Release("treadmill")
                            if othersBusy() then
                                dismount()
                                return
                            end
                            if confirmed then
                                onBelt()
                            else
                                Status.onTreadmill = false
                            end
                            task.wait(1)
                        end)
                        Control.Release("treadmill")
                        task.wait(0.2)
                    end
                end)
            end,
        })
    end
    do
        local IDLE_HANDLER   = "AntiAFK"
        local IDLE_FLAG_SLOT = 1
        local RESCAN_EVERY   = 30
        local _afk = {
            enabled    = false,
            thread     = nil,
            generation = 0,
            muted      = {},
            pulse      = nil,
        }
        local function idleConnections()
            if type(getconnections) ~= "function" then return nil end
            local ok, conns = pcall(getconnections, LocalPlayer.Idled)
            if not ok or type(conns) ~= "table" then return nil end
            return conns
        end
        local function isGameHandler(conn)
            local handler = conn.Function
            if not handler then return false end
            local ok, src = pcall(debug.info, handler, "s")
            return ok and type(src) == "string" and src:find(IDLE_HANDLER) ~= nil
        end
        local function clearIdleFlag(conn)
            local handler = conn.Function
            if not handler then return end
            pcall(function() debug.setupvalue(handler, IDLE_FLAG_SLOT, false) end)
        end
        local function findActivityPulse()
            if type(getgc) ~= "function" then return nil end
            for _, fn in ipairs(getgc(false)) do
                if type(fn) == "function" then
                    local ok, src = pcall(debug.info, fn, "s")
                    if ok and type(src) == "string" and src:find(IDLE_HANDLER) then
                        local name = debug.info(fn, "n")
                        if name == "markActive" or name == "reportActiveFromInput" then return fn end
                    end
                end
            end
            return nil
        end
        local function reportActive()
            _afk.pulse = _afk.pulse or findActivityPulse()
            if _afk.pulse and pcall(_afk.pulse) then return end
            pcall(function()
                require(ReplicatedStorage.Shared.Remotes).Telemetry.SubmitIdleState:FireServer(false)
            end)
        end
        local function muteIdle()
            local conns = idleConnections()
            if not conns then return end
            for _, conn in ipairs(conns) do
                local enabled = select(2, pcall(function() return conn.Enabled end))
                if enabled ~= false then
                    if isGameHandler(conn) then clearIdleFlag(conn) end
                    if pcall(function() conn:Disable() end) then _afk.muted[conn] = true end
                end
            end
        end
        local function unmuteIdle()
            for conn in pairs(_afk.muted) do
                pcall(function() conn:Enable() end)
            end
            _afk.muted = {}
        end
        local function stopAntiAfk()
            _afk.enabled    = false
            _afk.generation = _afk.generation + 1
            if _afk.thread then
                pcall(task.cancel, _afk.thread)
                _afk.thread = nil
            end
            unmuteIdle()
        end
        table.insert(_G.LynxSAE.Stoppers, stopAntiAfk)
        local AfkSection = SettingsTab:AddSection("Anti AFK")
        AfkSection:AddToggle({
            Title    = "Anti AFK",
            Default  = true,
            Callback = function(on)
                stopAntiAfk()
                if not on then return end
                _afk.enabled    = true
                _afk.generation = _afk.generation + 1
                local generation = _afk.generation
                muteIdle()
                _afk.thread = task.spawn(function()
                    while _afk.enabled and _afk.generation == generation do
                        for _ = 1, RESCAN_EVERY do
                            if not _afk.enabled or _afk.generation ~= generation then return end
                            task.wait(1)
                        end
                        muteIdle()
                        reportActive()
                    end
                end)
            end,
        })
    end
    do
        local Lighting = game:GetService("Lighting")
        local EFFECT_CLASSES = {
            ParticleEmitter = true, Trail = true, Smoke = true, Fire = true,
            Sparkles = true, Beam = true, PointLight = true, SpotLight = true,
            SurfaceLight = true,
        }
        local SCREEN_CLASSES = { BillboardGui = true, SurfaceGui = true, Highlight = true }
        local SWEEP_EVERY = 600
        local _perf = {
            enabled   = false,
            ref       = nil,
            capRef    = nil,
            conns     = {},
            animConns = {},
            cap       = 240,
            no3d      = false,
            generation = 0,
        }
        local ANIMATED_GAMEPLAY = { "World", "__OBJECTS", "_Guards" }
        local function ownCharacter(instance)
            local character = LocalPlayer.Character
            return character ~= nil and instance:IsDescendantOf(character)
        end
        local function gameplayCritical(instance)
            for _, name in ipairs(ANIMATED_GAMEPLAY) do
                local root = workspace:FindFirstChild(name)
                if root and instance:IsDescendantOf(root) then return true end
            end
            return false
        end
        local function muteEffect(instance)
            if not EFFECT_CLASSES[instance.ClassName] then return end
            pcall(function() instance.Enabled = false end)
        end
        local function silenceAnimator(animator)
            if ownCharacter(animator) or gameplayCritical(animator) then return end
            local ok, tracks = pcall(function()
                return animator:GetPlayingAnimationTracks()
            end)
            if ok then
                for _, track in ipairs(tracks) do
                    pcall(function() track:Stop(0) end)
                end
            end
            if _perf.animConns[animator] then return end
            _perf.animConns[animator] = animator.AnimationPlayed:Connect(function(track)
                if not _perf.enabled then return end
                if ownCharacter(animator) or gameplayCritical(animator) then return end
                pcall(function() track:Stop(0) end)
            end)
        end
        local function stripMesh(instance)
            if instance:IsA("MeshPart") then
                instance.RenderFidelity = Enum.RenderFidelity.Performance
                if instance.TextureID ~= "" then instance.TextureID = "" end
            elseif instance:IsA("SpecialMesh") then
                if instance.TextureId ~= "" then instance.TextureId = "" end
            end
        end
        local function flatten(instance)
            if instance:FindFirstAncestor("LynxEggESP") then return end
            if ownCharacter(instance) then return end
            pcall(function()
                if instance:IsA("BasePart") then
                    instance.Material    = Enum.Material.SmoothPlastic
                    instance.Reflectance = 0
                    instance.CastShadow  = false
                    pcall(function() instance.MaterialVariant = "" end)
                    stripMesh(instance)
                elseif instance:IsA("SpecialMesh") then
                    stripMesh(instance)
                elseif instance:IsA("Decal") or instance:IsA("Texture")
                    or instance:IsA("SurfaceAppearance") then
                    instance:Destroy()
                elseif SCREEN_CLASSES[instance.ClassName] then
                    instance.Enabled = false
                elseif instance:IsA("Humanoid") then
                    instance.DisplayDistanceType = Enum.HumanoidDisplayDistanceType.None
                end
            end)
        end
        local function blankOutSky(sky)
            pcall(function()
                sky.SkyboxBk             = ""
                sky.SkyboxDn             = ""
                sky.SkyboxFt             = ""
                sky.SkyboxLf             = ""
                sky.SkyboxRt             = ""
                sky.SkyboxUp             = ""
                sky.StarCount            = 0
                sky.SunAngularSize       = 0
                sky.MoonAngularSize      = 0
                sky.CelestialBodiesShown = false
            end)
        end
        local function stripSky(child)
            pcall(function()
                if child:IsA("Sky") then
                    blankOutSky(child)
                elseif child:IsA("Atmosphere") or child:IsA("Clouds") then
                    child:Destroy()
                elseif child:IsA("PostEffect") then
                    child.Enabled = false
                end
            end)
        end
        local function stripLighting()
            pcall(function()
                Lighting.GlobalShadows            = false
                Lighting.EnvironmentDiffuseScale  = 0
                Lighting.EnvironmentSpecularScale = 0
                Lighting.Brightness               = 1
                Lighting.Ambient                  = Color3.fromRGB(150, 150, 150)
                Lighting.OutdoorAmbient           = Color3.fromRGB(150, 150, 150)
                Lighting.FogEnd                   = 1e6
            end)
            if typeof(sethiddenproperty) == "function" then
                pcall(function()
                    sethiddenproperty(Lighting, "Technology", Enum.Technology.Compatibility)
                end)
            end
            for _, child in ipairs(Lighting:GetDescendants()) do stripSky(child) end
            pcall(function()
                for _, child in ipairs(workspace.Terrain:GetChildren()) do
                    if child:IsA("Clouds") then child:Destroy() end
                end
            end)
        end
        local function stripSettings()
            pcall(function()
                settings().Rendering.QualityLevel = Enum.QualityLevel.Level01
            end)
            pcall(function()
                game:GetService("MaterialService").Use2022Materials = false
            end)
            pcall(function()
                settings().Rendering.MeshPartDetailLevel = Enum.MeshPartDetailLevel.Level04
            end)
            pcall(function()
                UserSettings():GetService("UserGameSettings").SavedQualityLevel =
                    Enum.SavedQualitySetting.QualityLevel1
            end)
            pcall(function()
                local terrain = workspace.Terrain
                terrain.WaterWaveSize, terrain.WaterWaveSpeed = 0, 0
                terrain.WaterReflectance, terrain.WaterTransparency = 0, 0
                pcall(function() terrain.Decoration = false end)
            end)
        end
        local function stripWorldTag(instance)
            pcall(function()
                if SCREEN_CLASSES[instance.ClassName] and instance.Adornee then
                    instance.Enabled = false
                end
            end)
        end
        local function playerGui()
            return LocalPlayer:FindFirstChildOfClass("PlayerGui")
        end
        local function sweep(generation)
            local scanned = 0
            local gui = playerGui()
            if gui then
                for _, instance in ipairs(gui:GetDescendants()) do stripWorldTag(instance) end
            end
            for _, instance in ipairs(workspace:GetDescendants()) do
                if not _perf.enabled or _perf.generation ~= generation then return end
                if EFFECT_CLASSES[instance.ClassName] then
                    muteEffect(instance)
                elseif instance:IsA("Animator") then
                    silenceAnimator(instance)
                else
                    flatten(instance)
                end
                scanned = scanned + 1
                if scanned % 600 == 0 then task.wait() end
            end
            for _, effect in ipairs(Lighting:GetDescendants()) do
                if EFFECT_CLASSES[effect.ClassName] then muteEffect(effect) end
            end
        end
        local function applyBoost()
            _perf.generation = _perf.generation + 1
            local generation = _perf.generation
            stripSettings()
            stripLighting()
            _perf.conns[#_perf.conns + 1] = workspace.DescendantAdded:Connect(function(instance)
                if not _perf.enabled then return end
                if EFFECT_CLASSES[instance.ClassName] then
                    task.defer(muteEffect, instance)
                elseif instance:IsA("Animator") then
                    task.defer(silenceAnimator, instance)
                else
                    task.defer(flatten, instance)
                end
            end)
            _perf.conns[#_perf.conns + 1] = Lighting.DescendantAdded:Connect(function(child)
                if not _perf.enabled then return end
                task.defer(stripSky, child)
            end)
            local gui = playerGui()
            if gui then
                _perf.conns[#_perf.conns + 1] = gui.DescendantAdded:Connect(function(child)
                    if not _perf.enabled then return end
                    task.defer(stripWorldTag, child)
                end)
            end
            task.spawn(function()
                while _perf.enabled and _perf.generation == generation do
                    sweep(generation)
                    for _ = 1, SWEEP_EVERY do
                        if not _perf.enabled or _perf.generation ~= generation then return end
                        task.wait(1)
                    end
                    stripSettings()
                    stripLighting()
                end
            end)
        end
        local function stopBooster()
            _perf.generation = _perf.generation + 1
            _perf.enabled = false
            for _, conn in ipairs(_perf.conns) do
                pcall(function() conn:Disconnect() end)
            end
            _perf.conns = {}
            for _, conn in pairs(_perf.animConns) do
                pcall(function() conn:Disconnect() end)
            end
            _perf.animConns = {}
        end
        table.insert(_G.LynxSAE.Stoppers, stopBooster)
        local PerformanceSection = SettingsTab:AddSection("Performance")
        PerformanceSection:AddParagraph({
            Title   = "FPS Booster",
            Content = "Flattens the look of the map to win frames: meshes lose detail, "
                .. "textures, decals, shadows, particles, billboards and name tags go, and "
                .. "lighting is simplified. Nothing is hidden or reshaped, so the ground, "
                .. "the eggs and your own character keep their shape. It runs again every 10 "
                .. "minutes for whatever the game streams in later. Turning it off only stops "
                .. "new objects from being stripped, so rejoin the server to get the full "
                .. "graphics back. To hide plots as well, use the two toggles below.",
        })
        _perf.ref = PerformanceSection:AddToggle({
            Title    = "FPS Booster",
            Default  = false,
            Callback = function(on)
                if not on then
                    stopBooster()
                    notify("FPS Booster", "Rejoin the server to get the graphics back.",
                        Color3.fromRGB(255, 170, 60), 5)
                    return
                end
                _perf.enabled = true
                applyBoost()
            end,
        })
        local function set3d(on)
            pcall(function() game:GetService("RunService"):Set3dRenderingEnabled(on) end)
        end
        table.insert(_G.LynxSAE.Stoppers, function()
            if _perf.no3d then set3d(true) end
            _perf.no3d = false
        end)
        PerformanceSection:AddToggle({
            Title    = "Disable 3D Rendering (AFK)",
            Default  = false,
            Callback = function(on)
                _perf.no3d = on == true
                set3d(not _perf.no3d)
            end,
        })
        _perf.capRef = PerformanceSection:AddDropdown({
            Title    = "FPS Unlock",
            Options  = { "5", "10", "30", "60", "75", "90", "120", "144", "165", "180", "240" },
            Default  = "60",
            Callback = function(value)
                local target = tonumber(type(value) == "table" and value[1] or value)
                if not target then return end
                _perf.cap = math.clamp(target, 5, 240)
                if type(setfpscap) ~= "function" then
                    notify("FPS Unlock", "This executor doesn't provide setfpscap.",
                        Color3.fromRGB(255, 90, 90), 3)
                    return
                end
                pcall(setfpscap, _perf.cap)
            end,
        })
        local _plots = {
            hideOthers = false,
            hideAll    = false,
            othersRef  = nil,
            allRef     = nil,
            hidden     = {},
            roots      = {},
            conns      = {},
            thread     = nil,
            token      = 0,
        }
        local PLOT_SOURCES = {
            {
                folder = "Plots",
                owner  = function(child) return "plot:" .. child.Name end,
            },
            {
                folder = "PlacedEggRenders",
                owner  = function(child)
                    local userId = child.Name:match("^(%d+)_")
                    return userId and ("user:" .. userId) or nil
                end,
            },
            {
                folder = "ClientRenderedAssets",
                owner  = function(child)
                    local userId = child:GetAttribute("OwnerUserId") or child.Name:match("^(%d+)_")
                    return userId and ("user:" .. tostring(userId)) or nil
                end,
            },
            {
                folder = "__ClientTreadmillRenders",
                owner  = function(child)
                    local plotName = child.Name:match("^TreadmillRender_(.+)$")
                    return plotName and ("plot:" .. plotName) or nil
                end,
            },
        }
        local function myPlotName()
            local ok, plot = pcall(function()
                return require(ReplicatedStorage.Client.PlotState).ResolvePlot()
            end)
            if ok and plot and plot.PlotFolder then return plot.PlotFolder.Name end
            return nil
        end
        local function myUserId()
            local player = Players.LocalPlayer
            return player and tostring(player.UserId) or nil
        end
        local function ownedByMe(tag, plotName, userId)
            if not tag then return false end
            local kind, value = tag:match("^(%a+):(.+)$")
            if kind == "plot" then return plotName ~= nil and value == plotName end
            if kind == "user" then return userId ~= nil and value == userId end
            return false
        end
        local function shouldHide(tag, plotName, userId)
            if _plots.hideAll then return true end
            if _plots.hideOthers then
                if not tag then return false end
                return not ownedByMe(tag, plotName, userId)
            end
            return false
        end
        local function hideInstance(instance)
            if _plots.hidden[instance] ~= nil then return end
            if instance:IsA("BasePart") then
                _plots.hidden[instance] = { k = "ltm", v = instance.LocalTransparencyModifier }
                instance.LocalTransparencyModifier = 1
            elseif instance:IsA("Decal") or instance:IsA("Texture") then
                _plots.hidden[instance] = { k = "transparency", v = instance.Transparency }
                instance.Transparency = 1
            elseif instance:IsA("BillboardGui") or instance:IsA("SurfaceGui")
                or instance:IsA("ParticleEmitter") or instance:IsA("Beam")
                or instance:IsA("Trail") or instance:IsA("Highlight")
                or instance:IsA("Light") then
                if instance.Enabled then
                    _plots.hidden[instance] = { k = "enabled", v = true }
                    instance.Enabled = false
                end
            end
        end
        local function showInstance(instance)
            local record = _plots.hidden[instance]
            if record == nil then return end
            _plots.hidden[instance] = nil
            if not instance.Parent then return end
            pcall(function()
                if record.k == "ltm" then
                    instance.LocalTransparencyModifier = record.v
                elseif record.k == "transparency" then
                    instance.Transparency = record.v
                else
                    instance.Enabled = record.v
                end
            end)
        end
        local function hideRoot(root)
            if _plots.roots[root] then return false end
            _plots.roots[root] = true
            hideInstance(root)
            for _, instance in ipairs(root:GetDescendants()) do
                hideInstance(instance)
            end
            return true
        end
        local function showRoot(root)
            if not _plots.roots[root] then return end
            _plots.roots[root] = nil
            showInstance(root)
            if root.Parent then
                for _, instance in ipairs(root:GetDescendants()) do
                    showInstance(instance)
                end
            end
        end
        local function restoreAll()
            for root in pairs(_plots.roots) do showRoot(root) end
            for instance in pairs(_plots.hidden) do showInstance(instance) end
            _plots.roots  = {}
            _plots.hidden = {}
        end
        local function applyPlotVisibility()
            local active   = _plots.hideAll or _plots.hideOthers
            local plotName = myPlotName()
            local userId   = myUserId()
            local seen, hiddenRoots = {}, 0
            for _, source in ipairs(PLOT_SOURCES) do
                local folder = workspace:FindFirstChild(source.folder)
                if folder then
                    for _, child in ipairs(folder:GetChildren()) do
                        seen[child] = true
                        local ok, tag = pcall(source.owner, child)
                        if active and ok and shouldHide(tag, plotName, userId) then
                            hideRoot(child)
                            hiddenRoots = hiddenRoots + 1
                        else
                            showRoot(child)
                        end
                    end
                end
            end
            for root in pairs(_plots.roots) do
                if not seen[root] then showRoot(root) end
            end
            for instance in pairs(_plots.hidden) do
                if not instance.Parent then _plots.hidden[instance] = nil end
            end
            if not active then restoreAll() end
            return hiddenRoots
        end
        local function watchSource(source, folder)
            local conn = folder.DescendantAdded:Connect(function(instance)
                if not (_plots.hideAll or _plots.hideOthers) then return end
                task.defer(function()
                    if not instance.Parent then return end
                    local root = instance
                    while root and root.Parent ~= folder do root = root.Parent end
                    if not root then return end
                    if _plots.roots[root] then
                        hideInstance(instance)
                        return
                    end
                    local ok, tag = pcall(source.owner, root)
                    if ok and shouldHide(tag, myPlotName(), myUserId()) then
                        hideRoot(root)
                    end
                end)
            end)
            _plots.conns[#_plots.conns + 1] = conn
            pcall(function() Library:AddConnection("SAE_HidePlots", conn) end)
        end
        local function disconnectPlots()
            for _, conn in ipairs(_plots.conns) do
                pcall(function() conn:Disconnect() end)
            end
            _plots.conns = {}
        end
        local function refreshPlots()
            local active = _plots.hideAll or _plots.hideOthers
            _plots.token = _plots.token + 1
            local token  = _plots.token
            disconnectPlots()
            if not active then
                _plots.thread = nil
                applyPlotVisibility()
                return
            end
            for _, source in ipairs(PLOT_SOURCES) do
                local folder = workspace:FindFirstChild(source.folder)
                if folder then watchSource(source, folder) end
            end
            applyPlotVisibility()
            _plots.thread = task.spawn(function()
                while _plots.token == token and (_plots.hideAll or _plots.hideOthers) do
                    task.wait(2)
                    if _plots.token ~= token then break end
                    pcall(applyPlotVisibility)
                end
            end)
        end
        local function stopHidePlots()
            _plots.hideOthers = false
            _plots.hideAll    = false
            _plots.token      = _plots.token + 1
            _plots.thread     = nil
            disconnectPlots()
            restoreAll()
        end
        table.insert(_G.LynxSAE.Stoppers, stopHidePlots)
        _plots.othersRef = PerformanceSection:AddToggle({
            Title    = "Hide Other Plots",
            Default  = false,
            Callback = function(on)
                _plots.hideOthers = on
                refreshPlots()
            end,
        })
        _plots.allRef = PerformanceSection:AddToggle({
            Title    = "Hide All Plots",
            Default  = false,
            Callback = function(on)
                _plots.hideAll = on
                refreshPlots()
            end,
        })
    end
    do
        local _esp = {
            enabled = false, thread = nil, ref = nil, folder = nil,
            token = 0, nodes = {},
            useName = false, selectedName = {},
            useVariant = false, selectedVariant = {},
            useRarity = false, selectedRarity = {},
        }
        local function espDetails(record)
            local data = Game.Assets and Game.Assets.Directory
                and Game.Assets.Directory[record.AssetCategory]
            local labels = {}
            if Game.Mutations then
                for _, id in ipairs(record.Mutations or {}) do
                    table.insert(labels, tostring(Game.Mutations.LabelOf(id) or id))
                end
            end
            return {
                name   = (data and data.Egg and data.Egg.DisplayName) or record.AssetCategory,
                rarity = (data and data.Rarity and data.Rarity.DisplayName) or "?",
                color  = (data and data.Rarity and data.Rarity.Color) or Color3.fromRGB(255, 255, 255),
                rank   = (data and data.Rarity and data.Rarity.Rank) or 0,
                labels = labels,
            }
        end
        local function passesEspFilter(info)
            if _esp.useName and not isSetEmpty(_esp.selectedName)
                and not _esp.selectedName[info.name] then
                return false
            end
            if _esp.useRarity and not isSetEmpty(_esp.selectedRarity)
                and not _esp.selectedRarity[info.rarity] then
                return false
            end
            if _esp.useVariant and not isSetEmpty(_esp.selectedVariant) then
                local matched = false
                if #info.labels == 0 then
                    matched = _esp.selectedVariant["None"] == true
                else
                    for _, label in ipairs(info.labels) do
                        if _esp.selectedVariant[label] then matched = true break end
                    end
                end
                if not matched then return false end
            end
            return true
        end
        local function espFolder()
            if _esp.folder and _esp.folder.Parent then return _esp.folder end
            local folder = Instance.new("Folder")
            folder.Name   = "LynxEggESP"
            folder.Parent = workspace
            _esp.folder   = folder
            return folder
        end
        local function makeNode(uid)
            local anchor = Instance.new("Part")
            anchor.Name         = "ESP_" .. uid
            anchor.Size         = Vector3.new(0.2, 0.2, 0.2)
            anchor.Transparency = 1
            anchor.Anchored     = true
            anchor.CanCollide   = false
            anchor.CanQuery     = false
            anchor.CanTouch     = false
            anchor.Massless     = true
            anchor.Parent       = espFolder()
            local billboard = Instance.new("BillboardGui")
            billboard.Name             = "Tag"
            billboard.Size             = UDim2.fromOffset(190, 44)
            billboard.StudsOffset      = Vector3.new(0, 2.2, 0)
            billboard.AlwaysOnTop      = true
            billboard.MaxDistance      = 2000
            billboard.LightInfluence   = 0
            billboard.Parent           = anchor
            local title = Instance.new("TextLabel")
            title.BackgroundTransparency = 1
            title.Size                   = UDim2.new(1, 0, 0, 16)
            title.Font                   = Enum.Font.GothamBold
            title.TextSize               = 13
            title.TextStrokeTransparency = 0.4
            title.TextColor3             = Color3.fromRGB(255, 255, 255)
            title.Parent                 = billboard
            local subtitle = Instance.new("TextLabel")
            subtitle.Name                   = "Sub"
            subtitle.BackgroundTransparency = 1
            subtitle.Position               = UDim2.new(0, 0, 0, 16)
            subtitle.Size                   = UDim2.new(1, 0, 0, 14)
            subtitle.Font                   = Enum.Font.Gotham
            subtitle.TextSize               = 11
            subtitle.TextStrokeTransparency = 0.5
            subtitle.TextColor3             = Color3.fromRGB(230, 230, 230)
            subtitle.Parent                 = billboard
            local dist = Instance.new("TextLabel")
            dist.Name                   = "Dist"
            dist.BackgroundTransparency = 1
            dist.Position               = UDim2.new(0, 0, 0, 30)
            dist.Size                   = UDim2.new(1, 0, 0, 13)
            dist.Font                   = Enum.Font.Gotham
            dist.TextSize               = 10
            dist.TextStrokeTransparency = 0.6
            dist.TextColor3             = Color3.fromRGB(190, 190, 190)
            dist.Parent                 = billboard
            return { anchor = anchor, title = title, sub = subtitle, dist = dist }
        end
        local function clearNodes()
            for _, node in pairs(_esp.nodes) do
                pcall(function() node.anchor:Destroy() end)
            end
            _esp.nodes = {}
            if _esp.folder then
                pcall(function() _esp.folder:Destroy() end)
                _esp.folder = nil
            end
        end
        local function refreshEsp()
            local snapshot = fieldEggs()
            local ok = snapshot ~= nil
            if not ok or type(snapshot) ~= "table" then return end
            local _, root = getCharacter()
            local origin = root and root.Position
            local seen = {}
            for _, record in ipairs(snapshot.Records or snapshot) do
                if tostring(record.State) == "Slot" then
                    local info = espDetails(record)
                    if passesEspFilter(info) then
                        local uid = tostring(record.Uid)
                        seen[uid] = true
                        local node = _esp.nodes[uid]
                        if not node or not node.anchor.Parent then
                            node = makeNode(uid)
                            _esp.nodes[uid] = node
                        end
                        local position = record.BoundsCFrame.Position
                        node.anchor.CFrame = CFrame.new(position)
                        node.title.Text       = info.name
                        node.title.TextColor3 = info.color
                        node.sub.Text = info.rarity
                            .. (#info.labels > 0 and (" \u{00B7} " .. table.concat(info.labels, ", ")) or "")
                            .. (record.HasParasite and " \u{00B7} Parasite" or "")
                        node.dist.Text = origin
                            and string.format("%.0f studs", (position - origin).Magnitude)
                            or ""
                    end
                end
            end
            for uid, node in pairs(_esp.nodes) do
                if not seen[uid] then
                    pcall(function() node.anchor:Destroy() end)
                    _esp.nodes[uid] = nil
                end
            end
        end
        local function stopEsp()
            _esp.enabled = false
            _esp.token   = _esp.token + 1
            if _esp.thread then
                pcall(task.cancel, _esp.thread)
                _esp.thread = nil
            end
            clearNodes()
        end
        table.insert(_G.LynxSAE.Stoppers, stopEsp)
        local EspSection = SettingsTab:AddSection("Egg ESP")
        EspSection:AddToggle({
            Title    = "ESP Filter Name",
            Default  = false,
            Callback = function(on) _esp.useName = on end,
        })
        EspSection:AddDropdown({
            Title    = "ESP Egg Name",
            Multi    = true,
            Options  = (function()
                local options, seen = {}, {}
                if Game.Assets and Game.Assets.Directory then
                    for _, data in pairs(Game.Assets.Directory) do
                        local name = data.Egg and data.Egg.DisplayName
                        if name and not seen[name] then
                            seen[name] = true
                            table.insert(options, name)
                        end
                    end
                end
                table.sort(options)
                if #options == 0 then options = { "Loading..." } end
                return options
            end)(),
            Default  = {},
            Callback = function(selected)
                _esp.selectedName = toSet(type(selected) == "table" and selected or {})
            end,
        })
        EspSection:AddToggle({
            Title    = "ESP Filter Variant",
            Default  = false,
            Callback = function(on) _esp.useVariant = on end,
        })
        EspSection:AddDropdown({
            Title    = "ESP Variant",
            Multi    = true,
            Options  = (function()
                local options = { "None" }
                if Game.Mutations and Game.Mutations.All then
                    local labels = {}
                    for id in pairs(Game.Mutations.All()) do
                        table.insert(labels, tostring(Game.Mutations.LabelOf(id) or id))
                    end
                    table.sort(labels)
                    for _, label in ipairs(labels) do table.insert(options, label) end
                end
                return options
            end)(),
            Default  = {},
            Callback = function(selected)
                _esp.selectedVariant = toSet(type(selected) == "table" and selected or {})
            end,
        })
        EspSection:AddToggle({
            Title    = "ESP Filter Rarity",
            Default  = false,
            Callback = function(on) _esp.useRarity = on end,
        })
        EspSection:AddDropdown({
            Title    = "ESP Rarity",
            Multi    = true,
            Options  = (function()
                local seen, ranked = {}, {}
                if Game.Assets and Game.Assets.Directory then
                    for _, data in pairs(Game.Assets.Directory) do
                        local rarity = data.Rarity
                        local name   = rarity and rarity.DisplayName
                        if name and not seen[name] then
                            seen[name] = true
                            table.insert(ranked, { name = name, rank = rarity.Rank or 0 })
                        end
                    end
                end
                table.sort(ranked, function(a, b) return a.rank < b.rank end)
                local options = {}
                for _, item in ipairs(ranked) do table.insert(options, item.name) end
                if #options == 0 then options = { "Loading..." } end
                return options
            end)(),
            Default  = {},
            Callback = function(selected)
                _esp.selectedRarity = toSet(type(selected) == "table" and selected or {})
            end,
        })
        _esp.ref = EspSection:AddToggle({
            Title    = "Egg ESP",
            Default  = false,
            Callback = function(on)
                stopEsp()
                if not on then return end
                if not Game.Init() or not Game.EggState
                    or type(Game.EggState.SyncFieldEggs) ~= "function" then
                    notify("Egg ESP", "Game egg module not found.",
                        Color3.fromRGB(255, 90, 90), 3)
                    if _esp.ref then pcall(function() _esp.ref:SetValue(false) end) end
                    return
                end
                _esp.enabled = true
                _esp.token   = _esp.token + 1
                local token  = _esp.token
                _esp.thread = task.spawn(function()
                    while _esp.enabled and _esp.token == token do
                        pcall(refreshEsp)
                        task.wait(1)
                    end
                end)
            end,
        })
    end
    do
        local _predict = { enabled = false, gui = nil, conn = nil, ref = nil, token = 0 }
        local SKIN = {
            window  = Color3.fromRGB(26, 13, 5),
            panel   = Color3.fromRGB(38, 19, 8),
            row     = Color3.fromRGB(53, 27, 12),
            track   = Color3.fromRGB(70, 36, 16),
            accent  = Color3.fromRGB(255, 105, 0),
            stroke  = Color3.fromRGB(90, 45, 20),
            text    = Color3.fromRGB(255, 250, 245),
            subtext = Color3.fromRGB(224, 205, 190),
            muted   = Color3.fromRGB(180, 160, 145),
        }
        local SLOTS_PER_AREA = 5
        local RESET_SECONDS  = 300
        local function corner(parent, radius)
            local c = Instance.new("UICorner")
            c.CornerRadius = UDim.new(0, radius or 6)
            c.Parent = parent
            return c
        end
        local function stroke(parent, color, transparency)
            local s = Instance.new("UIStroke")
            s.Color        = color or SKIN.stroke
            s.Thickness    = 1
            s.Transparency = transparency or 0.4
            s.Parent       = parent
            return s
        end
        local function label(parent, text, size, color, bold)
            local l = Instance.new("TextLabel")
            l.BackgroundTransparency = 1
            l.Font                   = bold and Enum.Font.GothamBold or Enum.Font.Gotham
            l.Text                   = text
            l.TextSize               = size
            l.TextColor3             = color
            l.TextXAlignment         = Enum.TextXAlignment.Left
            l.TextTruncate           = Enum.TextTruncate.AtEnd
            l.Parent                 = parent
            return l
        end
        local function formatWait(seconds)
            if seconds ~= seconds or seconds == math.huge then return "-" end
            local total   = math.floor(seconds + 0.5)
            local hours   = math.floor(total / 3600)
            local minutes = math.floor((total % 3600) / 60)
            local secs    = total % 60
            if hours > 0 then
                return string.format("%dj %02dm %02dd", hours, minutes, secs)
            elseif minutes > 0 then
                return string.format("%dm %02dd", minutes, secs)
            end
            return string.format("%dd", secs)
        end
        local function buildPredictions()
            local list = {}
            if not (Game.Areas and Game.Areas.Directory and Game.Assets and Game.Assets.Directory) then
                return list
            end
            for areaId, area in pairs(Game.Areas.Directory) do
                local total = 0
                for _, entry in pairs(area.DropTable or {}) do
                    local weight = tonumber(entry[2])
                    if weight then total = total + weight end
                end
                if total > 0 then
                    for _, entry in pairs(area.DropTable or {}) do
                        local category = entry[1]
                        local weight   = tonumber(entry[2])
                        local asset    = category and Game.Assets.Directory[category]
                        if asset and weight and weight > 0 then
                            local perSlot  = weight / total
                            local perCycle = 1 - (1 - perSlot) ^ SLOTS_PER_AREA
                            local cycles   = perCycle > 0 and (1 / perCycle) or math.huge
                            list[#list + 1] = {
                                name    = (asset.Egg and asset.Egg.DisplayName) or asset.DisplayName or category,
                                icon    = (asset.Egg and asset.Egg.Icon) or asset.Icon,
                                area    = areaId,
                                rarity  = asset.Rarity and asset.Rarity.DisplayName or "?",
                                rank    = asset.Rarity and asset.Rarity.Rank or 0,
                                color   = asset.Rarity and asset.Rarity.Color or SKIN.subtext,
                                chance  = perCycle,
                                cycles  = cycles,
                                waitSec = cycles * RESET_SECONDS,
                            }
                        end
                    end
                end
            end
            table.sort(list, function(a, b)
                if a.rank ~= b.rank then return a.rank > b.rank end
                return a.chance < b.chance
            end)
            return list
        end
        local function buildGui(items)
            local gui = Instance.new("ScreenGui")
            gui.Name           = "LynxEggPredict"
            gui.IgnoreGuiInset = true
            gui.ResetOnSpawn   = false
            gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
            gui.DisplayOrder   = 999
            local viewport = workspace.CurrentCamera and workspace.CurrentCamera.ViewportSize
                or Vector2.new(1366, 768)
            local width  = math.clamp(viewport.X * 0.20, 178, 236)
            local height = math.clamp(viewport.Y * 0.62, 230, 410)
            local main = Instance.new("Frame")
            main.Name                   = "Main"
            main.Size                   = UDim2.fromOffset(width, height)
            main.Position               = UDim2.new(0.5, -width / 2, 0.5, -height / 2)
            main.BackgroundColor3       = SKIN.window
            main.BackgroundTransparency = 0.05
            main.BorderSizePixel        = 0
            main.Active                 = true
            main.Parent                 = gui
            corner(main, 8)
            stroke(main)
            local header = Instance.new("Frame")
            header.Name                   = "Header"
            header.Size                   = UDim2.new(1, 0, 0, 30)
            header.BackgroundTransparency = 1
            header.Parent                 = main
            local mark = Instance.new("Frame")
            mark.Size             = UDim2.fromOffset(3, 12)
            mark.Position         = UDim2.new(0, 9, 0.5, -6)
            mark.BackgroundColor3 = SKIN.accent
            mark.BorderSizePixel  = 0
            mark.Parent           = header
            corner(mark, 2)
            local title = label(header, "Egg Predict", 11, SKIN.text, true)
            title.Position = UDim2.new(0, 18, 0, 0)
            title.Size     = UDim2.new(1, -80, 1, 0)
            local countdown = label(header, "--:--", 9, SKIN.accent, true)
            countdown.Name           = "Countdown"
            countdown.Position       = UDim2.new(1, -62, 0, 0)
            countdown.Size           = UDim2.new(0, 38, 1, 0)
            countdown.TextXAlignment = Enum.TextXAlignment.Right
            local close = Instance.new("TextButton")
            close.Name                   = "Close"
            close.Size                   = UDim2.fromOffset(18, 18)
            close.Position               = UDim2.new(1, -22, 0.5, -9)
            close.BackgroundColor3       = SKIN.row
            close.BackgroundTransparency = 0.35
            close.Text                   = "X"
            close.Font                   = Enum.Font.GothamBold
            close.TextSize               = 9
            close.TextColor3             = SKIN.subtext
            close.BorderSizePixel        = 0
            close.AutoButtonColor        = false
            close.Parent                 = header
            corner(close, 5)
            local divider = Instance.new("Frame")
            divider.Size                   = UDim2.new(1, -18, 0, 1)
            divider.Position               = UDim2.new(0, 9, 0, 30)
            divider.BackgroundColor3       = SKIN.stroke
            divider.BackgroundTransparency = 0.5
            divider.BorderSizePixel        = 0
            divider.Parent                 = main
            local scroll = Instance.new("ScrollingFrame")
            scroll.Size                   = UDim2.new(1, -12, 1, -40)
            scroll.Position               = UDim2.new(0, 6, 0, 36)
            scroll.BackgroundTransparency = 1
            scroll.BorderSizePixel        = 0
            scroll.ScrollBarThickness     = 2
            scroll.ScrollBarImageColor3   = SKIN.accent
            scroll.CanvasSize             = UDim2.new()
            scroll.AutomaticCanvasSize    = Enum.AutomaticSize.Y
            scroll.Parent                 = main
            local layout = Instance.new("UIListLayout")
            layout.Padding   = UDim.new(0, 4)
            layout.SortOrder = Enum.SortOrder.LayoutOrder
            layout.Parent    = scroll
            local slowest, fastest = 0, math.huge
            for _, item in ipairs(items) do
                if item.waitSec < math.huge then
                    if item.waitSec > slowest then slowest = item.waitSec end
                    if item.waitSec < fastest then fastest = item.waitSec end
                end
            end
            if fastest == math.huge or fastest <= 0 then fastest = 1 end
            if slowest <= fastest then slowest = fastest * 2 end
            local span = math.log(slowest / fastest)
            local rows = {}
            local function ratioFor(seconds)
                if seconds >= math.huge or span <= 0 then return 1 end
                return math.clamp(1 - math.log(math.max(seconds, 1) / fastest) / span, 0.05, 1)
            end
            for index, item in ipairs(items) do
                local row = Instance.new("Frame")
                row.Size                   = UDim2.new(1, -4, 0, 42)
                row.BackgroundColor3       = SKIN.row
                row.BackgroundTransparency = 0.4
                row.BorderSizePixel        = 0
                row.LayoutOrder            = index
                row.Parent                 = scroll
                corner(row, 5)
                local icon = Instance.new("ImageLabel")
                icon.Size                   = UDim2.fromOffset(24, 24)
                icon.Position               = UDim2.new(0, 5, 0, 4)
                icon.BackgroundTransparency = 1
                icon.Image                  = item.icon or ""
                icon.ScaleType              = Enum.ScaleType.Fit
                icon.Parent                 = row
                local name = label(row, item.name, 10, SKIN.text, true)
                name.Position = UDim2.new(0, 33, 0, 4)
                name.Size     = UDim2.new(1, -39, 0, 12)
                local rarity = label(row, item.rarity, 8, item.color, true)
                rarity.Position = UDim2.new(0, 33, 0, 16)
                rarity.Size     = UDim2.new(0, 62, 0, 11)
                local waited = label(row, formatWait(item.waitSec), 8, SKIN.subtext)
                waited.Position       = UDim2.new(1, -100, 0, 16)
                waited.Size           = UDim2.new(0, 94, 0, 11)
                waited.TextXAlignment = Enum.TextXAlignment.Right
                local track = Instance.new("Frame")
                track.Size                   = UDim2.new(1, -38, 0, 3)
                track.Position               = UDim2.new(0, 33, 0, 32)
                track.BackgroundColor3       = SKIN.track
                track.BackgroundTransparency = 0.3
                track.BorderSizePixel        = 0
                track.Parent                 = row
                corner(track, 2)
                local fill = Instance.new("Frame")
                fill.Size             = UDim2.new(ratioFor(item.waitSec), 0, 1, 0)
                fill.BackgroundColor3 = item.color
                fill.BorderSizePixel  = 0
                fill.Parent           = track
                corner(fill, 2)
                rows[#rows + 1] = { item = item, timer = waited, fill = fill }
            end
            local dragging, dragStart, startPos
            header.InputBegan:Connect(function(input)
                if input.UserInputType == Enum.UserInputType.MouseButton1
                    or input.UserInputType == Enum.UserInputType.Touch then
                    dragging  = true
                    dragStart = input.Position
                    startPos  = main.Position
                end
            end)
            header.InputEnded:Connect(function(input)
                if input.UserInputType == Enum.UserInputType.MouseButton1
                    or input.UserInputType == Enum.UserInputType.Touch then
                    dragging = false
                end
            end)
            UserInputService.InputChanged:Connect(function(input)
                if not dragging then return end
                if input.UserInputType ~= Enum.UserInputType.MouseMovement
                    and input.UserInputType ~= Enum.UserInputType.Touch then return end
                local delta = input.Position - dragStart
                main.Position = UDim2.new(
                    startPos.X.Scale, startPos.X.Offset + delta.X,
                    startPos.Y.Scale, startPos.Y.Offset + delta.Y
                )
            end)
            close.MouseButton1Click:Connect(function()
                if _predict.ref then pcall(function() _predict.ref:SetValue(false) end) end
            end)
            gui.Parent = LocalPlayer:WaitForChild("PlayerGui")
            local function refresh(secondsUntilReset)
                for _, entry in ipairs(rows) do
                    local remaining = entry.item.waitSec
                    if entry.item.cycles and entry.item.cycles < math.huge then
                        remaining = (entry.item.cycles - 1) * RESET_SECONDS + secondsUntilReset
                    end
                    entry.timer.Text = formatWait(remaining)
                    entry.fill.Size  = UDim2.new(ratioFor(remaining), 0, 1, 0)
                end
            end
            return gui, countdown, refresh
        end
        local function stopPredict()
            _predict.enabled = false
            _predict.token   = _predict.token + 1
            if _predict.conn then
                pcall(function() _predict.conn:Disconnect() end)
                _predict.conn = nil
            end
            if _predict.gui then
                pcall(function() _predict.gui:Destroy() end)
                _predict.gui = nil
            end
        end
        table.insert(_G.LynxSAE.Stoppers, stopPredict)
        local PredictSection = SettingsTab:AddSection("Egg Predict")
        _predict.ref = PredictSection:AddToggle({
            Title    = "Egg Predict",
            Default  = false,
            Callback = function(on)
                stopPredict()
                if not on then return end
                if not Game.Init() or not Game.Areas or not Game.Assets then
                    notify("Egg Predict", "Belum siap: " .. Game.MissingText(),
                        Color3.fromRGB(255, 90, 90), 3)
                    if _predict.ref then pcall(function() _predict.ref:SetValue(false) end) end
                    return
                end
                local items = buildPredictions()
                if #items == 0 then
                    notify("Egg Predict", "Egg data not found.",
                        Color3.fromRGB(255, 90, 90), 3)
                    if _predict.ref then pcall(function() _predict.ref:SetValue(false) end) end
                    return
                end
                _predict.enabled = true
                _predict.token   = _predict.token + 1
                local token      = _predict.token
                local gui, countdown, refresh = buildGui(items)
                _predict.gui = gui
                local okCycle, cycle = pcall(function()
                    return require(ReplicatedStorage.Shared.Util.AreaEggCycle)
                end)
                if not okCycle then cycle = nil end
                task.spawn(function()
                    while _predict.enabled and _predict.token == token and countdown.Parent do
                        if cycle then
                            local ok, seconds = pcall(cycle.SecondsUntilReset, workspace:GetServerTimeNow())
                            if ok and type(seconds) == "number" then
                                pcall(function()
                                    countdown.Text = string.format("%d:%02d",
                                        math.floor(seconds / 60), math.floor(seconds % 60))
                                end)
                                pcall(refresh, seconds)
                            end
                        end
                        task.wait(1)
                    end
                end)
            end,
        })
    end
end
task.wait()
Library:Init()
