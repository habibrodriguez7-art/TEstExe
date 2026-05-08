do
    local autoSkill = false
    local isMobile  = UserInputService.TouchEnabled and not UserInputService.KeyboardEnabled

    local s = SurTab:AddSection("Generator")
    s:AddToggle({
        Title    = "Auto SkillCheck (Perfect)",
        Default  = false,
        NoSave   = true,
        Callback = function(v)
            autoSkill = v
            if not v then return end

            task.spawn(function()
                local Remotes   = ReplicatedStorage:WaitForChild("Remotes")
                local genEvent  = Remotes:WaitForChild("Generator"):WaitForChild("SkillCheckEvent")
                local healEvent = Remotes:WaitForChild("Healing"):WaitForChild("SkillCheckEvent")

                local pg = LocalPlayer:WaitForChild("PlayerGui")
                local promptGui = pg:WaitForChild("SkillCheckPromptGui", 15)
                if not promptGui then return end
                local check = promptGui:WaitForChild("Check", 10)
                if not check then return end
                local line = check:WaitForChild("Line", 10)
                local goal = check:WaitForChild("Goal", 10)
                if not line or not goal then return end

                -- Path button mobile sama persis seperti ZarVD
                local ActionPath = "Survivor-mob.Controls.action.check"
                local TouchID    = 8822

                local function getMobileButton()
                    local cur = pg
                    for seg in string.gmatch(ActionPath, "[^%.]+") do
                        cur = cur and cur:FindFirstChild(seg)
                    end
                    return cur
                end

                local function triggerInput()
                    if isMobile then
                        local btn = getMobileButton()
                        if btn and btn:IsA("GuiObject") then
                            local pos    = btn.AbsolutePosition
                            local sz     = btn.AbsoluteSize
                            local inset  = game:GetService("GuiService"):GetGuiInset()
                            local cx     = pos.X + sz.X / 2 + inset.X
                            local cy     = pos.Y + sz.Y / 2 + inset.Y
                            pcall(function()
                                VirtualInputManager:SendTouchEvent(TouchID, 0, cx, cy)
                                task.wait(0.01)
                                VirtualInputManager:SendTouchEvent(TouchID, 2, cx, cy)
                            end)
                        end
                    else
                        pcall(function()
                            VirtualInputManager:SendKeyEvent(true,  Enum.KeyCode.Space, false, game)
                            task.wait(0.03)
                            VirtualInputManager:SendKeyEvent(false, Enum.KeyCode.Space, false, game)
                        end)
                    end
                end

                local heartbeatConn = nil

                local function handleSkillCheck()
                    if not autoSkill then return end

                    local waitStart = tick()
                    while not check.Visible do
                        if not autoSkill then return end
                        if tick() - waitStart > 3 then return end
                        task.wait(0.016)
                    end

                    if heartbeatConn then heartbeatConn:Disconnect(); heartbeatConn = nil end

                    local fired = false
                    heartbeatConn = RunService.Heartbeat:Connect(function()
                        if fired or not autoSkill then
                            if heartbeatConn then heartbeatConn:Disconnect(); heartbeatConn = nil end
                            return
                        end
                        if not check.Visible then
                            if heartbeatConn then heartbeatConn:Disconnect(); heartbeatConn = nil end
                            return
                        end

                        local lr = line.Rotation % 360
                        local gr = goal.Rotation % 360
                        local ss = (gr + 101) % 360
                        local se = (gr + 115) % 360

                        local inZone = ss > se
                            and (lr >= ss or lr <= se)
                            or  (lr >= ss and lr <= se)

                        if inZone then
                            fired = true
                            if heartbeatConn then heartbeatConn:Disconnect(); heartbeatConn = nil end
                            triggerInput()
                        end
                    end)
                end

                local genConn  = genEvent.OnClientEvent:Connect(function()
                    task.spawn(handleSkillCheck)
                end)
                local healConn = healEvent.OnClientEvent:Connect(function()
                    task.spawn(handleSkillCheck)
                end)

                while autoSkill do task.wait(0.2) end

                genConn:Disconnect()
                healConn:Disconnect()
                if heartbeatConn then heartbeatConn:Disconnect(); heartbeatConn = nil end
            end)
        end,
    })
end
