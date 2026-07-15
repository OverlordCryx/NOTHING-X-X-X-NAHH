repeat
    task.wait(0.5);
	warn"NOTHING X _BEST"
	until game:IsLoaded();
Players = game:GetService("Players")
TweenService = game:GetService("TweenService")
UserInputService = game:GetService("UserInputService")
GuiService = game:GetService("GuiService")
_G.MasterLoopTasks = {}
_G.MasterRenderTasks = {}
_G.MasterSteppedTasks = {}
_G.MasterYieldingTasks = {}
_G.masterLoopCounter = 0
_G.masterYieldCounter = 0
local RealRunService = game:GetService("RunService")
RealRunService.Heartbeat:Connect(function(dt)
    for k, v in pairs(_G.MasterLoopTasks) do
        local success, err = pcall(v, dt)
        if not success then warn("MasterLoop Error (Heartbeat):", err) end
    end
end)
RealRunService.RenderStepped:Connect(function(dt)
    for k, v in pairs(_G.MasterRenderTasks) do
        local success, err = pcall(v, dt)
        if not success then warn("MasterLoop Error (RenderStepped):", err) end
    end
end)
RealRunService.Stepped:Connect(function(t, dt)
    for k, v in pairs(_G.MasterSteppedTasks) do
        local success, err = pcall(v, t, dt)
        if not success then warn("MasterLoop Error (Stepped):", err) end
    end
end)
task.spawn(function()
    while true do
        task.wait()
        for k, v in pairs(_G.MasterYieldingTasks) do
            local success, err = pcall(v)
            if not success then warn("MasterLoop Error (Yielding):", err) end
        end
    end
end)
local function createFakeEvent(taskTable, originalEvent)
    local FakeEvent = {}
    function FakeEvent:Connect(func)
        _G.masterLoopCounter = _G.masterLoopCounter + 1
        local id = tostring(_G.masterLoopCounter)
        taskTable[id] = func
        local conn = {}
        function conn:Disconnect()
            taskTable[id] = nil
        end
        return conn
    end
    function FakeEvent:Wait()
        return originalEvent:Wait()
    end
    setmetatable(FakeEvent, {
        __index = originalEvent
    })
    return FakeEvent
end
local FakeHeartbeat = createFakeEvent(_G.MasterLoopTasks, RealRunService.Heartbeat)
local FakeRenderStepped = createFakeEvent(_G.MasterRenderTasks, RealRunService.RenderStepped)
local FakeStepped = createFakeEvent(_G.MasterSteppedTasks, RealRunService.Stepped)
RunService = setmetatable({}, {
    __index = function(_, key)
        if key == "Heartbeat" then return FakeHeartbeat
        elseif key == "RenderStepped" then return FakeRenderStepped
        elseif key == "Stepped" then return FakeStepped
        else
            local val = RealRunService[key]
            if type(val) == "function" then
                return function(_, ...) return val(RealRunService, ...) end
            end
            return val
        end
    end
})
HttpService = game:GetService("HttpService")
Workspace = game:GetService("Workspace")
CoreGui = game:GetService("CoreGui")
function nextFrame()
        return RunService.Heartbeat:Wait()
end
local player = Players.LocalPlayer
local uiLoaded = false
local _nxLoadComplete = false
local queuedCallbacks = {}
local characterSpawnTime = os.clock()
local espOverlayConfig = {
    showCharacter = false,
    showUltimate = false,
    showHp = false,
    showEsp = false,
    showStreak = false,
    showDeath = false,
    showUlted = false,
}
local espOverlayState = {}
local refreshAllOverlays = function() end
function showExistingGuiInfo(gui, title, text, duration)
        local infoContainer = gui:FindFirstChild("InfoContainer")
        local infoTitle = infoContainer and infoContainer:FindFirstChild("InfoTitle")
        local infoText = infoContainer and infoContainer:FindFirstChild("InfoText")
        local infoStroke = infoContainer and infoContainer:FindFirstChildOfClass("UIStroke")
        if not infoContainer or not infoTitle or not infoText then
                return false
        end
        local currentToken = (gui:GetAttribute("InfoToken") or 0) + 1
        gui:SetAttribute("InfoToken", currentToken)
        infoTitle.Text = tostring(title or "")
        infoText.Text = tostring(text or "")
        infoContainer.Visible = true
        infoContainer.BackgroundTransparency = 0.2
        if infoStroke then
                infoStroke.Transparency = 0.1
        end
        infoTitle.TextTransparency = 0
        infoTitle.TextStrokeTransparency = 1
        infoText.TextTransparency = 0
        infoText.TextStrokeTransparency = 1
        task.delay(tonumber(duration) or 3, function()
                if currentToken ~= (gui:GetAttribute("InfoToken") or 0) then
                        return
                end
                if not infoContainer.Parent then
                        return
                end
                infoContainer.BackgroundTransparency = 1
                if infoStroke then
                        infoStroke.Transparency = 1
                end
                infoTitle.TextTransparency = 1
                infoTitle.TextStrokeTransparency = 1
                infoText.TextTransparency = 1
                infoText.TextStrokeTransparency = 1
                infoContainer.Visible = false
        end)
        return true
end
do
        local existingGui = CoreGui:FindFirstChild("NOTHING_X-000")
        if existingGui then
                showExistingGuiInfo(existingGui, "NOTHING X", "NOTHING_X Already Running...", 3)
                return
        end
end
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "NOTHING_X-000"
screenGui.ResetOnSpawn = false
screenGui.IgnoreGuiInset = true
screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
screenGui.DisplayOrder = 9999999
screenGui.Parent = CoreGui
local keybindFrame
local targetFrame
local keybindToggles = {
        BodyLock = "block",
        ComboLock = "block",
        Speed = "off",
        Fly = "off",
        CamLock = "off",
        AttackTP = "off",
        Target = "off",
        WalkFling = "off",
        SetBack = "off",
        Trash = "off",
        Void = "off",
        Places = "off",
        View = "off",
        Orbit = "off",
        AutoTPKey = "off",
        FlingKey = "off",
}
local hideNamesEnabled = false
local scaleRegistry = {}
local baseResolution = Vector2.new(1900, 1200)
function getViewportScale()
        local sizeX = screenGui and screenGui.AbsoluteSize.X or 1920
        local sizeY = screenGui and screenGui.AbsoluteSize.Y or 1080
        if sizeX < 10 or sizeY < 10 then
                local cam = workspace.CurrentCamera
                if cam then
                        local viewportSize = cam.ViewportSize
                        if viewportSize.X >= 10 and viewportSize.Y >= 10 then
                                sizeX = viewportSize.X
                                sizeY = viewportSize.Y
                        end
                end
        end
        if sizeX < 10 then sizeX = 1920 end
        if sizeY < 10 then sizeY = 1080 end
        local scaleX = sizeX / baseResolution.X
        local scaleY = sizeY / baseResolution.Y
        return math.min(scaleX, scaleY)
end
function getScaleFactorFor(guiObject)
        local viewportScale = getViewportScale()
        local current = guiObject
        while current do
                if current.Name == "WindowUI" then
                        local animVal = current:FindFirstChild("WindowAnimScale")
                        local animScale = animVal and animVal.Value or 1.0
                        return 1.2 * viewportScale * animScale
                elseif current.Name == "TargetFrame" then
                        return 1.6 * viewportScale
                elseif current.Name == "KeybindFrame" then
                        return 1.3 * viewportScale
                elseif current.Name == "InfoContainer" then
                        return 1.5 * viewportScale
                end
                current = current.Parent
        end
        return viewportScale
end
function registerObject(guiObject)
        if scaleRegistry[guiObject] then return end
        if guiObject.Name == "DropdownHolder" or guiObject.Name == "DropdownOptionsFrame" or guiObject.Name == "DropdownChoiceFrame" then
                return
        end
        local original = {}
        local shouldRegister = false
        if guiObject:IsA("GuiObject") then
                original.Size = guiObject.Size
                original.Position = guiObject.Position
                shouldRegister = true
        end
        if guiObject:IsA("TextLabel") or guiObject:IsA("TextButton") or guiObject:IsA("TextBox") then
                original.TextSize = guiObject.TextSize
                shouldRegister = true
        end
        if guiObject:IsA("UIPadding") then
                original.PaddingLeft = guiObject.PaddingLeft
                original.PaddingRight = guiObject.PaddingRight
                original.PaddingTop = guiObject.PaddingTop
                original.PaddingBottom = guiObject.PaddingBottom
                shouldRegister = true
        end
        if guiObject:IsA("UIListLayout") then
                original.Padding = guiObject.Padding
                shouldRegister = true
        end
        if guiObject:IsA("UICorner") then
                original.CornerRadius = guiObject.CornerRadius
                shouldRegister = true
        end
        if guiObject:IsA("UIStroke") then
                original.Thickness = guiObject.Thickness
                shouldRegister = true
        end
        if shouldRegister then
                scaleRegistry[guiObject] = original
        end
end
function applyScaleToObject(guiObject)
        local original = scaleRegistry[guiObject]
        if not original then return end
        local scaleFactor = getScaleFactorFor(guiObject)
        if guiObject:IsA("GuiObject") then
                local origSize = original.Size
                guiObject.Size = UDim2.new(
                        origSize.X.Scale, origSize.X.Offset * scaleFactor,
                        origSize.Y.Scale, origSize.Y.Offset * scaleFactor
                )
                local origPos = original.Position
                guiObject.Position = UDim2.new(
                        origPos.X.Scale, origPos.X.Offset * scaleFactor,
                        origPos.Y.Scale, origPos.Y.Offset * scaleFactor
                )
        end
        if guiObject:IsA("TextLabel") or guiObject:IsA("TextButton") or guiObject:IsA("TextBox") then
                guiObject.TextSize = math.max(1, math.floor(original.TextSize * scaleFactor + 0.5))
        end
        if guiObject:IsA("UIPadding") then
                guiObject.PaddingLeft = UDim.new(original.PaddingLeft.Scale, original.PaddingLeft.Offset * scaleFactor)
                guiObject.PaddingRight = UDim.new(original.PaddingRight.Scale, original.PaddingRight.Offset * scaleFactor)
                guiObject.PaddingTop = UDim.new(original.PaddingTop.Scale, original.PaddingTop.Offset * scaleFactor)
                guiObject.PaddingBottom = UDim.new(original.PaddingBottom.Scale, original.PaddingBottom.Offset * scaleFactor)
        end
        if guiObject:IsA("UIListLayout") then
                guiObject.Padding = UDim.new(original.Padding.Scale, original.Padding.Offset * scaleFactor)
        end
        if guiObject:IsA("UICorner") then
                guiObject.CornerRadius = UDim.new(original.CornerRadius.Scale, original.CornerRadius.Offset * scaleFactor)
        end
        if guiObject:IsA("UIStroke") then
                guiObject.Thickness = original.Thickness * scaleFactor
        end
end
function updateAllScales()
        local cam = workspace.CurrentCamera
        local w, h
        if cam then
                local vp = cam.ViewportSize
                w = vp.X
                h = vp.Y
        end
        if not w or w < 10 then
                w = screenGui and screenGui.AbsoluteSize.X or 1600
                h = screenGui and screenGui.AbsoluteSize.Y or 900
        end
        if w < 10 then w = 1600 end
        if h < 10 then h = 900 end
        local kfYScale
        if w <= 800 and h <= 600 then
                kfYScale = 0.74
        else
                local t2 = math.clamp((w - 800) / (1900 - 800), 0, 1)
                kfYScale = 0.74 - t2 * 0.14
        end
        local tOffset = math.clamp((w - 800) / (1900 - 800), 0, 1)
        local tfXOffset = -160 - tOffset * 190
        local newTFPos = targetFrame and UDim2.new(1, tfXOffset, 0, 10) or nil
        for guiObject, original in pairs(scaleRegistry) do
                if not guiObject.Parent then
                        scaleRegistry[guiObject] = nil
                else
                        if guiObject == keybindFrame or guiObject == targetFrame then
                        else
                                applyScaleToObject(guiObject)
                        end
                end
        end
        if targetFrame and newTFPos then
                targetFrame.Position = newTFPos
        end
        if infoContainer then
                local viewportScale = getViewportScale()
                local yPos = 0.08 + (1 - viewportScale) * 0.15
                local newPos = UDim2.fromScale(0.5, yPos)
                if scaleRegistry[infoContainer] then
                        scaleRegistry[infoContainer].Position = newPos
                end
                infoContainer.Position = newPos
        end
        if allDropdowns then
                for state in pairs(allDropdowns) do
                        if state.holder and state.holder.Parent then
                                state.setExpanded(state.isExpanded())
                        else
                                allDropdowns[state] = nil
                        end
                end
        end
end
task.spawn(function()
        local currentConnection = nil
        local function bindCamera()
                if currentConnection then currentConnection:Disconnect() end
                local cam = Workspace.CurrentCamera
                if cam then
                        currentConnection = cam:GetPropertyChangedSignal("ViewportSize"):Connect(updateAllScales)
                        updateAllScales()
                end
        end
        bindCamera()
        Workspace:GetPropertyChangedSignal("CurrentCamera"):Connect(bindCamera)
        if screenGui then
                screenGui:GetPropertyChangedSignal("AbsoluteSize"):Connect(updateAllScales)
        end
        task.delay(0, updateAllScales)
        task.delay(0, updateAllScales)
        task.delay(0, updateAllScales)
        task.delay(0, updateAllScales)
end)
screenGui.DescendantAdded:Connect(function(desc)
        task.defer(function()
                if desc.Parent then
                        registerObject(desc)
                        applyScaleToObject(desc)
                        if desc.Name == "WindowAnimScale" and desc:IsA("NumberValue") then
                                desc.Changed:Connect(updateAllScales)
                        end
                end
        end)
end)
for _, desc in ipairs(screenGui:GetDescendants()) do
        registerObject(desc)
end
updateAllScales()
task.defer(updateAllScales)
introFinished = true
local piNameLabel    = nil
local piHpLabel      = nil
local piCharLabel    = nil
local piStreakLabel  = nil
local piStreakSepObj = nil
local function updatePlayerInfoFrame()
        if not piNameLabel then return end
        local char = player.Character
        local humanoid = char and char:FindFirstChildOfClass("Humanoid")
        if not char or not humanoid then
                return
        end
        local displayName = player.DisplayName or player.Name
        local realName = player.Name
        if displayName ~= realName then
                piNameLabel.Text = displayName .. " (" .. realName .. ")"
        else
                piNameLabel.Text = realName
        end
        local maxHp = math.max(1, humanoid.MaxHealth)
        local hpPct = math.clamp((humanoid.Health / maxHp) * 100, 0, 100)
        piHpLabel.Text = string.format("%.1f%%", hpPct)
        if hpPct >= 66 then
                piHpLabel.TextColor3 = Color3.fromRGB(100, 220, 100)
        elseif hpPct >= 33 then
                piHpLabel.TextColor3 = Color3.fromRGB(255, 165, 0)
        else
                piHpLabel.TextColor3 = Color3.fromRGB(255, 80, 80)
        end
        local charAttr = char:GetAttribute("Character") or player:GetAttribute("Character") or ""
        piCharLabel.Text = tostring(charAttr)
        local streak = char:GetAttribute("CurrentStreak")
        local streakNum = tonumber(streak)
        if streakNum == nil or streakNum <= 0 then
                piStreakLabel.Visible = false
                if piStreakSepObj then piStreakSepObj.Visible = false end
        else
                piStreakLabel.Text = tostring(streakNum)
                piStreakLabel.Visible = true
                if piStreakSepObj then piStreakSepObj.Visible = true end
        end
end
task.spawn(function()
        while screenGui.Parent do
                pcall(updatePlayerInfoFrame)
                task.wait()
        end
end)
player.CharacterAdded:Connect(function()
        task.wait()
        pcall(updatePlayerInfoFrame)
end)
        keybindFrame = Instance.new("Frame")
        keybindFrame.Name = "KeybindFrame"
        keybindFrame.AnchorPoint = Vector2.new(0, 0)
        keybindFrame.Position = UDim2.new(0, 10, 0, 10)
        keybindFrame.Size = UDim2.fromScale(0, 0)
keybindFrame.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
keybindFrame.BackgroundTransparency = 0.2
keybindFrame.BorderSizePixel = 0
keybindFrame.ClipsDescendants = false
do
        local kfCorner = Instance.new("UICorner")
        kfCorner.CornerRadius = UDim.new(0, 6)
        kfCorner.Parent = keybindFrame
        local kfStroke = Instance.new("UIStroke")
        kfStroke.Color = Color3.fromRGB(255, 255, 255)
        kfStroke.Thickness = 1
        kfStroke.Transparency = 0.3
        kfStroke.Parent = keybindFrame
        local kfGradient = Instance.new("UIGradient")
        kfGradient.Color = ColorSequence.new(Color3.fromRGB(20, 20, 20), Color3.fromRGB(0, 0, 0))
        kfGradient.Rotation = 90
        kfGradient.Parent = keybindFrame
end
keybindFrame.Visible = false
keybindFrame.AutomaticSize = Enum.AutomaticSize.XY
local _nxSG = Instance.new("ScreenGui")
_nxSG.Name = "NX-LOAD"
_nxSG.ResetOnSpawn = false
_nxSG.IgnoreGuiInset = true
_nxSG.DisplayOrder = 100000000
_nxSG.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
_nxSG.Parent = CoreGui
local _nxFrame = Instance.new("Frame")
_nxFrame.Name = "LoadFrame"
_nxFrame.Size = UDim2.fromOffset(300, 200)
_nxFrame.AnchorPoint = Vector2.new(0.5, 0.5)
_nxFrame.Position = UDim2.new(0.5, 0, 0.5, 0)
_nxFrame.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
_nxFrame.BackgroundTransparency = 0.1
_nxFrame.BorderSizePixel = 0
_nxFrame.ZIndex = 10
_nxFrame.Parent = _nxSG
do
        local _nxCorner = Instance.new("UICorner")
        _nxCorner.CornerRadius = UDim.new(0, 10)
        _nxCorner.Parent = _nxFrame
        local _nxStroke = Instance.new("UIStroke")
        _nxStroke.Color = Color3.fromRGB(255, 255, 255)
        _nxStroke.Thickness = 1.5
        _nxStroke.Transparency = 0
        _nxStroke.Parent = _nxFrame
end
local _nxTitle = Instance.new("TextLabel")
_nxTitle.Name = "NXTitle"
_nxTitle.Size = UDim2.new(1, 0, 0.5, 0)
_nxTitle.Position = UDim2.fromScale(0, 0)
_nxTitle.BackgroundTransparency = 1
_nxTitle.Text = "NOTHING - X"
_nxTitle.TextColor3 = Color3.fromRGB(255, 255, 255)
_nxTitle.TextSize = 22
_nxTitle.Font = Enum.Font.GothamBold
_nxTitle.TextXAlignment = Enum.TextXAlignment.Center
_nxTitle.TextYAlignment = Enum.TextYAlignment.Center
_nxTitle.TextStrokeTransparency = 1
_nxTitle.ZIndex = 11
_nxTitle.Parent = _nxFrame
local _nxPct = Instance.new("TextLabel")
_nxPct.Name = "NXPercent"
_nxPct.Size = UDim2.new(1, 0, 0.5, 0)
_nxPct.Position = UDim2.fromScale(0, 0.5)
_nxPct.BackgroundTransparency = 1
_nxPct.Text = "0%"
_nxPct.TextColor3 = Color3.fromRGB(180, 180, 180)
_nxPct.TextSize = 18
_nxPct.Font = Enum.Font.Gotham
_nxPct.TextXAlignment = Enum.TextXAlignment.Center
_nxPct.TextYAlignment = Enum.TextYAlignment.Center
_nxPct.TextStrokeTransparency = 1
_nxPct.ZIndex = 11
_nxPct.Parent = _nxFrame
task.spawn(function()
        local _t0 = os.clock()
        local _simDur = 4.0
        while not uiLoaded do
                local _prog = math.min(0.9, (os.clock() - _t0) / _simDur)
                _nxPct.Text = tostring(math.floor(_prog * 100)) .. "%"
                task.wait(0.05)
        end
        _nxPct.Text = "100%"
        task.wait(0.35)
        _nxPct.Text = "_^"
        task.wait(0.55)
        _nxLoadComplete = true
        _nxSG:Destroy()
end)
local keybindPadding = Instance.new("UIPadding")
keybindPadding.PaddingTop = UDim.new(0, 10)
keybindPadding.PaddingBottom = UDim.new(0, 10)
keybindPadding.PaddingLeft = UDim.new(0, 10)
keybindPadding.PaddingRight = UDim.new(0, 10)
keybindPadding.Parent = keybindFrame
keybindFrame.Parent = screenGui
updateAllScales()
keybindText = Instance.new("TextLabel")
keybindText.Name = "KeybindText"
keybindText.AnchorPoint = Vector2.new(0, 0)
keybindText.Position = UDim2.fromScale(0, 0)
keybindText.Size = UDim2.new(0, 160, 0, 0)
keybindText.AutomaticSize = Enum.AutomaticSize.Y
keybindText.BackgroundTransparency = 1
keybindText.TextColor3 = Color3.fromRGB(255, 255, 255)
keybindText.TextStrokeTransparency = 1
keybindText.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
keybindText.Font = Enum.Font.GothamBold
keybindText.TextSize = 16
keybindText.Text = ""
keybindText.LineHeight = 1.5
keybindText.TextScaled = false
keybindText.TextWrapped = true
keybindText.TextYAlignment = Enum.TextYAlignment.Top
keybindText.TextXAlignment = Enum.TextXAlignment.Center
keybindText.Parent = keybindFrame
targetFrame = Instance.new("Frame")
targetFrame.Name = "TargetFrame"
targetFrame.AnchorPoint = Vector2.new(1, 0)
targetFrame.Position = UDim2.new(1, -350, 0, 10)
targetFrame.Size = UDim2.fromOffset(0, 0)
targetFrame.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
targetFrame.BackgroundTransparency = 0.25
targetFrame.ClipsDescendants = true
targetFrame.BorderSizePixel = 0
do
        local tfCorner = Instance.new("UICorner")
        tfCorner.CornerRadius = UDim.new(0, 4)
        tfCorner.Parent = targetFrame
        local tfStroke = Instance.new("UIStroke")
        tfStroke.Color = Color3.fromRGB(255, 255, 255)
        tfStroke.Thickness = 1
        tfStroke.Transparency = 0.4
        tfStroke.Parent = targetFrame
        local tfGradient = Instance.new("UIGradient")
        tfGradient.Color = ColorSequence.new(Color3.fromRGB(20, 20, 20), Color3.fromRGB(0, 0, 0))
        tfGradient.Rotation = 90
        tfGradient.Parent = targetFrame
end
targetFrame.Visible = false
targetFrame.AutomaticSize = Enum.AutomaticSize.XY
local function roundToTenth(value)
        return math.floor((value * 10) + 0.5) / 10
end
local function formatHPPercent(hum)
        if not hum then return "0" end
        local pct = (hum.Health / math.max(1, hum.MaxHealth)) * 100
        if pct ~= pct then pct = 0 end
        local str = string.format("%.1f", math.clamp(pct, 0, 999))
        if string.sub(str, -2) == ".0" then
                return string.sub(str, 1, -3)
        end
        return str
end
local function getSavedControlValue(key)
        if not key or key == "" then
                return nil
        end
        return controlSaveData[key]
end
local function setSavedControlValue(key, value)
        if not key or key == "" then
                return
        end
        controlSaveData[key] = value
        saveSliderSaveData()
end
function makeHubTog(parent, text, callback, saveKey, default, widthMult)
        local btn = Instance.new("TextButton")
        btn.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
        btn.BackgroundTransparency = 0
        btn.BorderSizePixel = 0
        btn.BorderColor3 = Color3.fromRGB(255, 255, 255)
        btn.Size = UDim2.new(widthMult or 0.25, 0, 1, 0)
        local corner = Instance.new("UICorner")
        corner.CornerRadius = UDim.new(0, 6)
        corner.Parent = btn
        btn.AutoButtonColor = false
        btn.Font = Enum.Font.GothamBold
        btn.Text = text
        btn.TextColor3 = Color3.fromRGB(255, 255, 255)
        btn.TextStrokeTransparency = 1
        btn.TextSize = 13
        btn.TextScaled = false
        btn.Parent = parent
        local enabled = default == true
        if saveKey and getSavedControlValue(saveKey) ~= nil then
                enabled = getSavedControlValue(saveKey) == true
        end
        local function render()
                btn.BackgroundColor3 = enabled and Color3.fromRGB(255, 255, 255) or Color3.fromRGB(0, 0, 0)
                btn.TextColor3 = enabled and Color3.fromRGB(0, 0, 0) or Color3.fromRGB(255, 255, 255)
        end
        local function setValue(val, skipCallback)
                enabled = val == true
                render()
                if saveKey then setSavedControlValue(saveKey, enabled) end
                if not skipCallback and callback then callback(enabled) end
        end
        btn.MouseButton1Click:Connect(function()
                setValue(not enabled)
        end)
        if enabled and callback then
                if uiLoaded then
                        task.spawn(callback, true)
                else
                        table.insert(queuedCallbacks, function()
                                task.spawn(callback, true)
                        end)
                end
        elseif not enabled and callback then
                if uiLoaded then
                        task.spawn(callback, false)
                else
                        table.insert(queuedCallbacks, function()
                                task.spawn(callback, false)
                        end)
                end
        end
        render()
        return {
                Button = btn,
                SetValue = setValue,
                GetValue = function() return enabled end,
                tog_change = setValue
        }
end
function makeHubTogKB(parent, text, callback, saveKey, default, widthMult)
        local btn = Instance.new("TextButton")
        btn.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
        btn.BackgroundTransparency = 0
        btn.BorderSizePixel = 0
        btn.BorderColor3 = Color3.fromRGB(255, 255, 255)
        btn.Size = UDim2.new(widthMult or 0.25, 0, 1, 0)
        local corner = Instance.new("UICorner")
        corner.CornerRadius = UDim.new(0, 6)
        corner.Parent = btn
        btn.AutoButtonColor = false
        btn.Font = Enum.Font.GothamBold
        btn.Text = text
        btn.TextColor3 = Color3.fromRGB(255, 255, 255)
        btn.TextStrokeTransparency = 1
        btn.TextSize = 13
        btn.TextScaled = false
        btn.Parent = parent
        local kbStates = { "off", "hide", "block" }
        local state = default or "off"
        if saveKey and getSavedControlValue(saveKey) ~= nil then
                local saved = getSavedControlValue(saveKey)
                if saved == "hide" or saved == "block" then
                        state = saved
                elseif saved == true then
                        state = "block"
                else
                        state = "off"
                end
        end
        local function render()
                if state == "hide" then
                        btn.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
                        btn.TextColor3 = Color3.fromRGB(0, 0, 0)
                        btn.Text = text .. " (H)"
                elseif state == "block" then
                        btn.BackgroundColor3 = Color3.fromRGB(80, 80, 80)
                        btn.TextColor3 = Color3.fromRGB(0, 0, 0)
                        btn.Text = text .. " (B)"
                else
                        btn.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
                        btn.TextColor3 = Color3.fromRGB(255, 255, 255)
                        btn.Text = text
                end
        end
        local function nextState()
                if state == "off" then
                        return "hide"
                elseif state == "hide" then
                        return "block"
                else
                        return "off"
                end
        end
        local function setValue(val, skipCallback)
                if val == "hide" or val == "block" then
                        state = val
                else
                        state = "off"
                end
                render()
                if saveKey then setSavedControlValue(saveKey, state) end
                if not skipCallback and callback then callback(state) end
        end
        btn.MouseButton1Click:Connect(function()
                setValue(nextState())
        end)
        if state ~= "off" and callback then
                if uiLoaded then
                        task.spawn(callback, state)
                else
                        local capturedState = state
                        table.insert(queuedCallbacks, function()
                                task.spawn(callback, capturedState)
                        end)
                end
        elseif state == "off" and callback then
                if uiLoaded then
                        task.spawn(callback, "off")
                else
                        table.insert(queuedCallbacks, function()
                                task.spawn(callback, "off")
                        end)
                end
        end
        render()
        return {
                Button = btn,
                SetValue = setValue,
                GetValue = function() return state end,
                tog_change = setValue
        }
end
function makeHubTogKBBlock(parent, text, callback, saveKey, default, widthMult)
        local btn = Instance.new("TextButton")
        btn.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
        btn.BackgroundTransparency = 0
        btn.BorderSizePixel = 0
        btn.BorderColor3 = Color3.fromRGB(255, 255, 255)
        btn.Size = UDim2.new(widthMult or 0.25, 0, 1, 0)
        local corner = Instance.new("UICorner")
        corner.CornerRadius = UDim.new(0, 6)
        corner.Parent = btn
        btn.AutoButtonColor = false
        btn.Font = Enum.Font.GothamBold
        btn.Text = text
        btn.TextColor3 = Color3.fromRGB(255, 255, 255)
        btn.TextStrokeTransparency = 1
        btn.TextSize = 13
        btn.TextScaled = false
        btn.Parent = parent
        local state = default or "off"
        if saveKey and getSavedControlValue(saveKey) ~= nil then
                local saved = getSavedControlValue(saveKey)
                if saved == "block" or saved == true then
                        state = "block"
                else
                        state = "off"
                end
        end
        local function render()
                if state == "block" then
                        btn.BackgroundColor3 = Color3.fromRGB(80, 80, 80)
                        btn.TextColor3 = Color3.fromRGB(0, 0, 0)
                        btn.Text = text .. " (B)"
                else
                        btn.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
                        btn.TextColor3 = Color3.fromRGB(255, 255, 255)
                        btn.Text = text
                end
        end
        local function nextState()
                if state == "off" then
                        return "block"
                else
                        return "off"
                end
        end
        local function setValue(val, skipCallback)
                if val == "block" then
                        state = "block"
                else
                        state = "off"
                end
                render()
                if saveKey then setSavedControlValue(saveKey, state) end
                if not skipCallback and callback then callback(state) end
        end
        btn.MouseButton1Click:Connect(function()
                setValue(nextState())
        end)
        if state ~= "off" and callback then
                if uiLoaded then
                        task.spawn(callback, state)
                else
                        local capturedState = state
                        table.insert(queuedCallbacks, function()
                                task.spawn(callback, capturedState)
                        end)
                end
        elseif state == "off" and callback then
                if uiLoaded then
                        task.spawn(callback, "off")
                else
                        table.insert(queuedCallbacks, function()
                                task.spawn(callback, "off")
                        end)
                end
        end
        render()
        return {
                Button = btn,
                SetValue = setValue,
                GetValue = function() return state end,
                tog_change = setValue
        }
end
local targetPadding = Instance.new("UIPadding")
targetPadding.PaddingLeft = UDim.new(0, 10)
targetPadding.PaddingRight = UDim.new(0, 10)
targetPadding.PaddingTop = UDim.new(0, 5)
targetPadding.PaddingBottom = UDim.new(0, 5)
targetPadding.Parent = targetFrame
targetFrame.Parent = screenGui
updateAllScales()
local targetLayout = Instance.new("UIListLayout")
targetLayout.FillDirection = Enum.FillDirection.Vertical
targetLayout.VerticalAlignment = Enum.VerticalAlignment.Top
targetLayout.HorizontalAlignment = Enum.HorizontalAlignment.Left
targetLayout.Padding = UDim.new(0, 2)
targetLayout.Parent = targetFrame
targetHPText = Instance.new("TextLabel")
targetHPText.Name = "TargetHPText"
targetHPText.BackgroundTransparency = 1
targetHPText.Size = UDim2.fromOffset(0, 0)
targetHPText.AutomaticSize = Enum.AutomaticSize.XY
targetHPText.Font = Enum.Font.GothamBold
targetHPText.Text = ""
targetHPText.TextColor3 = Color3.fromRGB(255, 255, 255)
targetHPText.TextStrokeTransparency = 1
targetHPText.TextSize = 13
targetHPText.TextScaled = false
targetHPText.TextWrapped = true
targetHPText.TextXAlignment = Enum.TextXAlignment.Left
targetHPText.TextYAlignment = Enum.TextYAlignment.Center
targetHPText.LayoutOrder = 1
targetHPText.Visible = false
targetHPText.Parent = targetFrame
targetValueText = Instance.new("TextLabel")
targetValueText.Name = "TargetValueText"
targetValueText.BackgroundTransparency = 1
targetValueText.Size = UDim2.fromOffset(0, 0)
targetValueText.AutomaticSize = Enum.AutomaticSize.XY
targetValueText.Font = Enum.Font.GothamBold
targetValueText.Text = ""
targetValueText.TextColor3 = Color3.fromRGB(255, 255, 255)
targetValueText.TextStrokeTransparency = 1
targetValueText.TextSize = 13
targetValueText.TextScaled = false
targetValueText.TextWrapped = true
targetValueText.TextXAlignment = Enum.TextXAlignment.Left
targetValueText.TextYAlignment = Enum.TextYAlignment.Center
targetValueText.LayoutOrder = 2
targetValueText.Visible = false
targetValueText.Parent = targetFrame
hpSeparator = Instance.new("TextLabel")
hpSeparator.Name = "Separator"
hpSeparator.BackgroundTransparency = 1
hpSeparator.Size = UDim2.fromOffset(0, 0)
hpSeparator.Font = Enum.Font.GothamBold
hpSeparator.Text = ""
hpSeparator.TextColor3 = Color3.fromRGB(255, 255, 255)
hpSeparator.TextSize = 13
hpSeparator.LayoutOrder = 99
hpSeparator.Visible = false
hpSeparator.Parent = targetFrame
infoContainer = Instance.new("Frame")
infoContainer.Name = "InfoContainer"
infoContainer.AnchorPoint = Vector2.new(0.5, 0)
infoContainer.Position = UDim2.fromScale(0.5, 0.08)
infoContainer.AutomaticSize = Enum.AutomaticSize.XY
infoContainer.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
infoContainer.BackgroundTransparency = 0.25
infoContainer.BorderSizePixel = 0
infoContainer.ClipsDescendants = true
local infoStroke = Instance.new("UIStroke")
infoStroke.Color = Color3.fromRGB(200, 200, 200)
infoStroke.Thickness = 1.5
infoStroke.Transparency = 0.3
infoStroke.Parent = infoContainer
do
        local icCorner = Instance.new("UICorner")
        icCorner.CornerRadius = UDim.new(0, 6)
        icCorner.Parent = infoContainer
        local icGradient = Instance.new("UIGradient")
        icGradient.Color = ColorSequence.new(Color3.fromRGB(20, 20, 20), Color3.fromRGB(0, 0, 0))
        icGradient.Rotation = 90
        icGradient.Parent = infoContainer
end
infoContainer.Visible = false
local infoPadding = Instance.new("UIPadding")
infoPadding.PaddingTop = UDim.new(0, 8)
infoPadding.PaddingBottom = UDim.new(0, 8)
infoPadding.PaddingLeft = UDim.new(0, 20)
infoPadding.PaddingRight = UDim.new(0, 20)
infoPadding.Parent = infoContainer
local infoListLayout = Instance.new("UIListLayout")
infoListLayout.FillDirection = Enum.FillDirection.Vertical
infoListLayout.Padding = UDim.new(0, 4)
infoListLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
infoListLayout.VerticalAlignment = Enum.VerticalAlignment.Top
infoListLayout.SortOrder = Enum.SortOrder.LayoutOrder
infoListLayout.Parent = infoContainer
infoContainer.Parent = screenGui
infoTitle = Instance.new("TextLabel")
infoTitle.Name = "InfoTitle"
infoTitle.AnchorPoint = Vector2.new(0, 0)
infoTitle.Position = UDim2.fromScale(0, 0)
infoTitle.Size = UDim2.fromScale(0, 0)
infoTitle.AutomaticSize = Enum.AutomaticSize.XY
infoTitle.TextXAlignment = Enum.TextXAlignment.Center
infoTitle.BackgroundTransparency = 1
infoTitle.Text = ""
infoTitle.TextColor3 = Color3.fromRGB(255, 255, 255)
infoTitle.TextStrokeTransparency = 1
infoTitle.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
infoTitle.Font = Enum.Font.GothamBold
infoTitle.TextSize = 22
infoTitle.TextScaled = false
infoTitle.TextWrapped = true
infoTitle.AutomaticSize = Enum.AutomaticSize.XY
infoTitle.LayoutOrder = 1
infoTitle.Parent = infoContainer
infoText = Instance.new("TextLabel")
infoText.Name = "InfoText"
infoText.AnchorPoint = Vector2.new(0, 0)
infoText.Position = UDim2.fromScale(0, 0)
infoText.Size = UDim2.fromScale(0, 0)
infoText.AutomaticSize = Enum.AutomaticSize.XY
infoText.TextXAlignment = Enum.TextXAlignment.Center
infoText.BackgroundTransparency = 1
infoText.Text = ""
infoText.TextColor3 = Color3.fromRGB(255, 255, 255)
infoText.TextStrokeTransparency = 1
infoText.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
infoText.Font = Enum.Font.GothamBold
infoText.TextSize = 20
infoText.TextScaled = false
infoText.TextWrapped = true
infoText.AutomaticSize = Enum.AutomaticSize.XY
infoText.LayoutOrder = 2
infoText.Parent = infoContainer
settingsWindow = Instance.new("Frame")
settingsWindow.Name = "WindowUI"
settingsWindow.AnchorPoint = Vector2.new(0.5, 0.5)
settingsWindow.Position = UDim2.fromScale(0.5, 0.57)
settingsWindow.Size = UDim2.fromOffset(422, 486)
settingsWindow.ClipsDescendants = true
do
        local windowAspectRatio = Instance.new("UIAspectRatioConstraint")
        windowAspectRatio.AspectRatio = 0.72
        windowAspectRatio.DominantAxis = Enum.DominantAxis.Height
        windowAspectRatio.Parent = settingsWindow
end
settingsWindow.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
settingsWindow.BackgroundTransparency = 0.1
settingsWindow.BorderSizePixel = 0
do
        local windowAnimScaleVal = Instance.new("NumberValue")
        windowAnimScaleVal.Name = "WindowAnimScale"
        windowAnimScaleVal.Value = 1.0
        windowAnimScaleVal.Parent = settingsWindow
        local swCorner = Instance.new("UICorner")
        swCorner.CornerRadius = UDim.new(0, 6)
        swCorner.Parent = settingsWindow
        local swGradient = Instance.new("UIGradient")
        swGradient.Color = ColorSequence.new(Color3.fromRGB(20, 20, 20), Color3.fromRGB(0, 0, 0))
        swGradient.Rotation = 90
        swGradient.Parent = settingsWindow
end
local settingsStroke
local windowOutlineStroke
do
        settingsStroke = Instance.new("UIStroke")
        settingsStroke.Color = Color3.fromRGB(255, 255, 255)
        settingsStroke.Thickness = 1.5
        settingsStroke.Transparency = 0.05
        settingsStroke.Parent = settingsWindow
end
settingsWindow.Visible = false
settingsWindow.Active = true
settingsWindow.ZIndex = 10
settingsWindow.Parent = screenGui
local windowOutline = Instance.new("Frame")
windowOutline.Name = "WindowOutline"
windowOutline.BackgroundTransparency = 1
windowOutline.Visible = true
windowOutline.Active = false
windowOutline.ZIndex = 9
windowOutline.Parent = settingsWindow
windowOutline.AnchorPoint = Vector2.new(0.5, 0.5)
windowOutline.Position = UDim2.fromScale(0.5, 0.5)
windowOutline.Size = UDim2.fromScale(1, 1)
windowOutline.ClipsDescendants = true
do
        local woCorner = Instance.new("UICorner")
        woCorner.CornerRadius = UDim.new(0, 6)
        woCorner.Parent = windowOutline
end
do
        windowOutlineStroke = Instance.new("UIStroke")
        windowOutlineStroke.Color = Color3.fromRGB(200, 200, 200)
        windowOutlineStroke.Thickness = 1.5
        windowOutlineStroke.Transparency = 0.05
        windowOutlineStroke.Parent = windowOutline
end
do
        local inputBlocker = Instance.new("TextButton")
        inputBlocker.Name = "InputBlocker"
        inputBlocker.Size = UDim2.fromScale(1, 1)
        inputBlocker.BackgroundTransparency = 1
        inputBlocker.BorderSizePixel = 1
inputBlocker.BorderColor3 = Color3.fromRGB(255, 255, 255)
        inputBlocker.Text = ""
        inputBlocker.AutoButtonColor = false
        inputBlocker.Visible = true
        inputBlocker.ZIndex = 10
        inputBlocker.Parent = settingsWindow
end
local headerDragArea = Instance.new("Frame")
headerDragArea.Name = "HeaderDragArea"
headerDragArea.Size = UDim2.fromScale(1, 0.18)
headerDragArea.BackgroundTransparency = 1
headerDragArea.Active = true
headerDragArea.ZIndex = 11
headerDragArea.Parent = settingsWindow
do
        local uiTitle = Instance.new("TextLabel")
        uiTitle.Name = "UI-Title"
        uiTitle.AnchorPoint = Vector2.new(0, 0)
        uiTitle.Position = UDim2.fromScale(0.05, 0.06)
        uiTitle.Size = UDim2.fromScale(0.52, 0.1)
        uiTitle.BackgroundTransparency = 1
        uiTitle.Text = "NOTHING _X                                                _^"
        uiTitle.TextColor3 = Color3.fromRGB(255, 255, 255)
        uiTitle.TextStrokeTransparency = 1
        uiTitle.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
        uiTitle.Font = Enum.Font.GothamBold
        uiTitle.TextSize = 16
        uiTitle.TextScaled = false
        uiTitle.TextXAlignment = Enum.TextXAlignment.Left
        uiTitle.ZIndex = 11
        uiTitle.Parent = settingsWindow
        local divider = Instance.new("Frame")
        divider.Name = "Divider"
        divider.AnchorPoint = Vector2.new(0.5, 0)
        divider.Position = UDim2.fromScale(0.5, 0.18)
        divider.Size = UDim2.fromScale(0.9, 0.006)
        divider.BackgroundColor3 = Color3.fromRGB(200, 200, 200)
        divider.BackgroundTransparency = 0.3
        divider.BorderSizePixel = 0
        divider.ZIndex = 11
        divider.Parent = settingsWindow
        local divGradient = Instance.new("UIGradient")
        divGradient.Color = ColorSequence.new({ColorSequenceKeypoint.new(0, Color3.fromRGB(0, 0, 0)), ColorSequenceKeypoint.new(0.5, Color3.fromRGB(255, 255, 255)), ColorSequenceKeypoint.new(1, Color3.fromRGB(0, 0, 0))})
        divGradient.Parent = divider
end
uiX = Instance.new("ScrollingFrame")
uiX.Name = "UI-x"
uiX.AnchorPoint = Vector2.new(0.5, 1)
uiX.Position = UDim2.fromScale(0.5, 0.95)
uiX.Size = UDim2.fromScale(0.92, 0.72)
uiX.BackgroundTransparency = 1
uiX.BorderSizePixel = 1
uiX.BorderColor3 = Color3.fromRGB(0, 0, 0)
uiX.CanvasSize = UDim2.fromOffset(0, 0)
uiX.AutomaticCanvasSize = Enum.AutomaticSize.Y
uiX.ElasticBehavior = Enum.ElasticBehavior.Never
uiX.ScrollBarImageTransparency = 1
uiX.ScrollBarThickness = 0
uiX.ScrollBarImageColor3 = Color3.fromRGB(255, 255, 255)
uiX.Active = true
uiX.ZIndex = 11
uiX.Parent = settingsWindow
do
        local settingsLayout = Instance.new("UIListLayout")
        settingsLayout.Padding = UDim.new(0, 10)
        settingsLayout.SortOrder = Enum.SortOrder.LayoutOrder
        settingsLayout.Parent = uiX
        local settingsPadding = Instance.new("UIPadding")
        settingsPadding.PaddingTop = UDim.new(0, 5)
        settingsPadding.PaddingBottom = UDim.new(0, 5)
        settingsPadding.PaddingLeft = UDim.new(0, 4)
        settingsPadding.PaddingRight = UDim.new(0, 4)
        settingsPadding.Parent = uiX
end
do
        local infoHub = Instance.new("Frame")
        infoHub.Name = "PlayerInfoHub"
        infoHub.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
        infoHub.BackgroundTransparency = 0.15
        infoHub.BorderSizePixel = 0
        infoHub.Size = UDim2.new(1, 0, 0, 38)
        infoHub.ClipsDescendants = true
        infoHub.LayoutOrder = -1
        do
                local c = Instance.new("UICorner")
                c.CornerRadius = UDim.new(0, 6)
                c.Parent = infoHub
                local g = Instance.new("UIGradient")
                g.Color = ColorSequence.new(Color3.fromRGB(20, 20, 20), Color3.fromRGB(0, 0, 0))
                g.Rotation = 90
                g.Parent = infoHub
        end
        infoHub.Parent = uiX
        local titleLbl = Instance.new("TextLabel")
        titleLbl.BackgroundTransparency = 1
        titleLbl.Position = UDim2.new(0, 10, 0, 2)
        titleLbl.Size = UDim2.new(1, -10, 0, 14)
        titleLbl.Font = Enum.Font.GothamBold
        titleLbl.Text = "Info"
        titleLbl.TextColor3 = Color3.fromRGB(180, 180, 180)
        titleLbl.TextStrokeTransparency = 1
        titleLbl.TextSize = 11
        titleLbl.TextScaled = false
        titleLbl.TextXAlignment = Enum.TextXAlignment.Left
        titleLbl.ZIndex = 12
        titleLbl.Parent = infoHub
        local rowFrame = Instance.new("Frame")
        rowFrame.BackgroundTransparency = 1
        rowFrame.Position = UDim2.new(0, 6, 0, 16)
        rowFrame.Size = UDim2.new(1, -12, 0, 20)
        rowFrame.ZIndex = 12
        rowFrame.Parent = infoHub
        local rowLayout = Instance.new("UIListLayout")
        rowLayout.FillDirection = Enum.FillDirection.Horizontal
        rowLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
        rowLayout.VerticalAlignment = Enum.VerticalAlignment.Center
        rowLayout.SortOrder = Enum.SortOrder.LayoutOrder
        rowLayout.Padding = UDim.new(0, 5)
        rowLayout.Parent = rowFrame
        local function makeIL(name, color)
                local lbl = Instance.new("TextLabel")
                lbl.Name = name
                lbl.BackgroundTransparency = 1
                lbl.Size = UDim2.fromOffset(0, 18)
                lbl.AutomaticSize = Enum.AutomaticSize.X
                lbl.Font = Enum.Font.GothamBold
                lbl.Text = "-"
                lbl.TextColor3 = color or Color3.fromRGB(255, 255, 255)
                lbl.TextStrokeTransparency = 1
                lbl.TextSize = 12
                lbl.TextScaled = false
                lbl.TextWrapped = false
                lbl.ZIndex = 12
                lbl.Parent = rowFrame
                return lbl
        end
        local function makeISep()
                local sep = Instance.new("TextLabel")
                sep.BackgroundTransparency = 1
                sep.Size = UDim2.fromOffset(6, 18)
                sep.Font = Enum.Font.GothamBold
                sep.Text = "|"
                sep.TextColor3 = Color3.fromRGB(90, 90, 90)
                sep.TextStrokeTransparency = 1
                sep.TextSize = 12
                sep.TextScaled = false
                sep.ZIndex = 12
                sep.Parent = rowFrame
                return sep
        end
        piNameLabel   = makeIL("PI_Name",   Color3.fromRGB(255, 255, 255))
        piNameLabel.LayoutOrder = 1
        local sep1 = makeISep(); sep1.LayoutOrder = 2
        piCharLabel   = makeIL("PI_Char",   Color3.fromRGB(255, 200, 80))
        piCharLabel.LayoutOrder = 3
        local sep2 = makeISep(); sep2.LayoutOrder = 4
        piHpLabel     = makeIL("PI_HP",     Color3.fromRGB(100, 220, 100))
        piHpLabel.LayoutOrder = 5
        local sep3    = makeISep(); sep3.LayoutOrder = 6
        piStreakLabel = makeIL("PI_Streak", Color3.fromRGB(100, 180, 255))
        piStreakLabel.LayoutOrder = 7
        piStreakSepObj = sep3
        piStreakLabel.Visible = false
        if piStreakSepObj then piStreakSepObj.Visible = false end
end
local otherPartsCache = {}
local friendCache = {}
local friendsList = {}
task.spawn(function()
        local success, pages = pcall(function()
                return Players:GetFriendsAsync(player.UserId)
        end)
        if success and pages and pages ~= Players and pcall(function() return pages.GetCurrentPage end) then
                while true do
                        local successItems, items = pcall(function() return pages:GetCurrentPage() end)
                        if not successItems or not items then break end
                        for _, item in ipairs(items) do
                                friendsList[item.Id] = true
                        end
                        local isFinished = false
                        pcall(function() isFinished = pages.IsFinished end)
                        if isFinished then
                                break
                        end
                        local advanceSuccess = pcall(function()
                                pages:AdvanceToNextPageAsync()
                        end)
                        if not advanceSuccess then break end
                end
        end
end)
local function updateFriendCache()
        for _, p in ipairs(Players:GetPlayers()) do
                if p ~= player and friendCache[p.UserId] ~= true then
                        if friendsList[p.UserId] then
                                friendCache[p.UserId] = true
                        else
                                task.spawn(function()
                                        local isFriend = false
                                        pcall(function()
                                                isFriend = player:IsFriendsWith(p.UserId)
                                        end)
                                        if not isFriend then
                                                pcall(function()
                                                        isFriend = p:IsFriendsWith(player.UserId)
                                                end)
                                        end
                                        if isFriend then
                                                friendCache[p.UserId] = true
                                        end
                                end)
                        end
                end
        end
end
task.spawn(function()
        Players.PlayerAdded:Connect(function(p)
                task.spawn(function()
                        if friendsList[p.UserId] then
                                friendCache[p.UserId] = true
                        else
                                local isFriend = false
                                pcall(function()
                                        isFriend = player:IsFriendsWith(p.UserId)
                                end)
                                if not isFriend then
                                        pcall(function()
                                                isFriend = p:IsFriendsWith(player.UserId)
                                        end)
                                end
                                if isFriend then
                                        friendCache[p.UserId] = true
                                end
                        end
                end)
        end)
        updateFriendCache()
        _G.masterYieldCounter = _G.masterYieldCounter + 1
        local lastFriendUpdate = 0
        _G.MasterYieldingTasks[tostring(_G.masterYieldCounter)] = function()
                local now = tick()
                if now - lastFriendUpdate >= 5 then
                        lastFriendUpdate = now
                        updateFriendCache()
                end
        end
end)
keybindEntries = {}
introFinished = true
pendingInfoCall = nil
settingsOpen = false
draggingWindow = false
dragStartPosition = nil
dragStartInputPosition = nil
openDropdowns = {}
allDropdowns = {}
sliderStates = {}
controlSaveData = {}
local NOTHING_X_UI_SAVE = "NOTHING_X/UI/NOTHING_X_0.file"
local NOTHING_X_UI_LOAD = "NOTHING_X/UI/NOTHING_X_0.file"
sliderSaveFile = NOTHING_X_UI_SAVE
Speed = 1.5
speedKeybind = Enum.KeyCode.E
flyKeybind = Enum.KeyCode.R
camLockKeybind = Enum.KeyCode.F1
bodyLockKeybind = Enum.KeyCode.F2
comboLockKeybind = Enum.KeyCode.F3
attackTpKeybind = Enum.KeyCode.T
orbitKeybind = Enum.KeyCode.H
viewKeybind = Enum.KeyCode.Five
autoTpKeybind = Enum.KeyCode.Y
flingKeybind = Enum.KeyCode.Six
targetSelectKeybind = Enum.KeyCode.C
setBackKeybind = Enum.KeyCode.N
voidDeadActive = false
voidDeadKeybind = Enum.KeyCode.Z
_G.SafeTeleportLock = false
dashBypassDuration = 0.35
local voidDeadLastCF = nil
local voidDeadConn = nil
local getTrashState = {
        keybind = Enum.KeyCode.LeftControl,
        running = false,
        returning = false,
        collisionState = nil,
        savedCFrame = nil,
        holdCFrame = nil,
        lastToggleAt = 0,
        toggleCooldown = 0.1,
        token = 0,
        keyHeld = false,
        blockSetBack = false,
        ["speed-get"] = 1100,
        ["speed-back"] = 155,
}
local function setTrashBlockEnabled(v)
        getTrashState.blockSetBack = v
        trashBlockEnabled = v
end
setBackSavedCFrame = nil
setBackCollisionState = nil
setBackPressToken = 0
setBackLastPressAt = 0
setBackPressCount = 0
setBackTravelToken = 0
lastDeathCFrame = nil
active = false
speedLoopRunning = false
holdingW = false
holdingS = false
holdingA = false
holdingD = false
local cam = Workspace.CurrentCamera
local char = player.Character
local hum = char and char:FindFirstChild("Humanoid")
local root = char and char:FindFirstChild("HumanoidRootPart")
local function updateLocalCharacterReferences(newChar)
        char = newChar
        characterSpawnTime = os.clock()
        hum = newChar:WaitForChild("Humanoid", 5)
        root = newChar:WaitForChild("HumanoidRootPart", 5)
end
if char then
        task.spawn(updateLocalCharacterReferences, char)
end
player.CharacterAdded:Connect(updateLocalCharacterReferences)
local localCharacterDiedConnection = nil
flying = false
bv = nil
bg = nil
flySpeed = 1.5
flySpeedMultiplier = 555
velocity = Vector3.zero
currentVel = Vector3.zero
local flyHoverPosition = nil
local targetDisplayAccumulator = 0
camLockEnabled = false
bodyLockEnabled = false
camLockTarget = nil
camLockWaiting = false
camLockAcquireRadius = 120
manualTargetAcquireRadius = 130
attackTpEnabled = false
attackTpTarget = nil
lastTargetDeathTime = 0
manualAttackTpTarget = nil
manualAttackTpPlayer = nil
attackTpHolding = false
attackTpMode = "Behind"
autoCustomDistance = 2.0
local isSelectablePlayerDropdownTarget
local syncModelDropdownSelectionToManualTarget
local stopView
local startView
local toggleView
attackTpBehindDistance = 2.0
attackTpAirBehindDistance = 0.85
attackTpLeadTime = 0
attackTpAirLeadTime = 0
attackTpMaxHorizontalLead = 8.0
attackTpVerticalLead = 0
attackTpMaxVerticalLead = 9999999
attackTpGroundVerticalOffset = 0
attackTpAirVerticalOffset = 0.25
local customOffsets = {}
for i = 1, 25 do
        customOffsets["Custom " .. tostring(i)] = { x = 0, y = 0, z = 0 }
end
local function getCustomDisplayName(i)
        local key = "Custom " .. tostring(i)
        local off = customOffsets[key] or { x = 0, y = 0, z = 0, flat = false, useRotation = false, rx = 0, ry = 0, rz = 0 }
        local name = string.format("Custom %s (%s,%s,%s)", tostring(i), tostring(off.z), tostring(off.y), tostring(off.x))
        if off.flat == "flat90" then
                name = name .. " (F90)"
        elseif off.flat then
                name = name .. " (F)"
        end
        if off.useRotation then
                name = name .. string.format(" (%s,%s,%s)", tostring(off.rz or 0), tostring(off.ry or 0), tostring(off.rx or 0))
        end
        return name
end
local worldUpVector = Vector3.new(0, 1, 0)
local placesTPs = {
	["Middle Of Map"] = CFrame.new(139, 440, 32),
	["Prison"] = CFrame.new(438, 439, -376),
	["Montain 1"] = CFrame.new(-15, 653, -388),
	["Montain 2"] = CFrame.new(322, 671, 446),
	["Montain 2 Left"] = CFrame.new(240, 699, 465),
	["Montain 2 Right"] = CFrame.new(398, 699, 404),
}
local function resolvePlaceCF(name)
	if not name or name == "" or name == "/\\" then
		return nil
	end
	local cf = placesTPs[name]
	if cf then
		return cf
	end
	local success, result = pcall(function()
		local cutscenes = workspace:FindFirstChild("Cutscenes")
		if not cutscenes then return nil end
		if name == "Counter" then
			local model = cutscenes:FindFirstChild("Death Cutscene")
			return model and (model:GetPivot() * CFrame.new(0, 0, -30))
		elseif name == "Counter Up" then
			local model = cutscenes:FindFirstChild("Death Cutscene")
			return model and (model:GetPivot() * CFrame.new(-16, 49, -15))
		elseif name == "Atomic Base" then
			local model = cutscenes:FindFirstChild("Atoms")
			return model and (model:GetPivot() * CFrame.new(0, -187, 0))
		elseif name == "Atomic Base Up" then
			local model = cutscenes:FindFirstChild("Atoms")
			return model and (model:GetPivot() * CFrame.new(0, 199, 0))
		elseif name == "Atomic Slash" then
			local atoms = cutscenes:FindFirstChild("Atoms")
			local model = atoms and atoms:FindFirstChild("sphere")
			return model and (model:GetPivot() * CFrame.new(0, 20, 0))
		elseif name == "Atomic Slash Up" then
			local atoms = cutscenes:FindFirstChild("Atoms")
			local model = atoms and atoms:FindFirstChild("sphere")
			return model and (model:GetPivot() * CFrame.new(0, 33, 0))
		end
		return nil
	end)
	if success and result then
		return result
	end
	return nil
end
local placesOrder = {
	"/\\", "Middle Of Map", "Prison",
	"Montain 1", "Montain 2", "Montain 2 Left", "Montain 2 Right",
	"Counter", "Counter Up", "Atomic Base", "Atomic Base Up",
	"Atomic Slash", "Atomic Slash Up"
}
local placesDropdown = nil
local movementPanel = nil
local selectedPlace = "/\\"
local afkEnabled = false
local afkSavedCFrame = nil
local afkConnection = nil
local afkCharacter = nil
local afkCharAddedConnection = nil
local safeZoneHPEnabled = false
local safeZoneHPSavedCFrame = nil
local safeZoneHPInSafeZone = false
local safeZoneHPCharacter = nil
local safeZoneRestoring = false
local safeZoneHPThresholdEnter = 33
local safeZoneHPThresholdExit = 37
local safeZoneCycleIndex = 0
local activeSafeZonePosition = nil
local function isSafeZoneActive()
        return afkEnabled or (safeZoneHPEnabled and safeZoneHPInSafeZone) or safeZoneRestoring
end
local safeZonePositions = {
        Vector3.new(9e9, -6666, 9e9),
        Vector3.new(-9e9, -6666, 9e9),
        Vector3.new(9e9, -6666, -9e9),
        Vector3.new(-9e9, -6666, -9e9),
        Vector3.new(0, -6666, 0)
}
autoTpEnabled = false
trashBlockEnabled = false
movementFlatState = false
flingEnabled = false
walkFlingEnabled = false
auraFlingEnabled = false
bHitEnabled = false
bHitHeartbeat = nil
clickFlingEnabled = false
flingAllEnabled = false
antiFlingEnabled = false
local FLING_INF_POWER = 1e30
walkFlingKeybind = Enum.KeyCode.X
walkFlingPower = 20000
flingPower = 20000
auraRange = 20
orbitEnabled = false
orbitSpeedH = 1.0
orbitSpeedV = 1.0
orbitDistance = 5.0
orbitAngleH = 0
orbitAngleV = 0
orbitCachedTarget = nil
orbitMode = "Horizontal"
orbitConnection = nil
WAIT_WALL_COMBO = 0.2
local wallComboBringCustomPos = nil
walkFlingUseNormal = false
local walkFlingBodyMode = true
walkFlingDirections = {
        Forward = true,
}
walkFlingTaskToken = 0
auraFlingHeartbeat = nil
auraFlingTaskToken = 0
clickFlingConnection = nil
clickFlingTaskToken = 0
clickFlingBusy = false
flingAllHeartbeat = nil
flingAllTaskToken = 0
targetActionHeartbeat = nil
local syncTargetActionControls
flingOrbitTime = 0
flingOrbitStepXZ = 0
flingOrbitStepY = 0
flingTargetIndex = 1
flingOrbitSpeed = 999999999999999
flingOrbitIncrement = 0.1
flingOrbitMax = 1.3
viewing = false
currentViewTarget = nil
currentViewPlayer = nil
viewDied = nil
viewChanged = nil
pendingTeleportToSelectedPlayer = false
targetActionControls = nil
flingModeControls = nil
orbitTogBtn = nil
function updateOrbitToggleButton()
        if not orbitTogBtn then return end
        if orbitEnabled then
                orbitTogBtn.Text = "Orbit"
                orbitTogBtn.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
                orbitTogBtn.TextColor3 = Color3.fromRGB(0, 0, 0)
        else
                orbitTogBtn.Text = "Orbit"
                orbitTogBtn.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
                orbitTogBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
        end
end
function resolveAttackTpTarget() end
function zeroLocalPlayerRoot()
	local character = player.Character
	if not character then return end
	for _, part in ipairs(character:GetDescendants()) do
		if part:IsA("BasePart") then
			pcall(function()
				part.AssemblyLinearVelocity = Vector3.zero
				part.AssemblyAngularVelocity = Vector3.zero
			end)
		end
	end
	local hrp = character:FindFirstChild("HumanoidRootPart")
	if hrp then
		pcall(function()
			hrp.AssemblyLinearVelocity = Vector3.zero
			hrp.AssemblyAngularVelocity = Vector3.zero
		end)
	end
end
function syncFlingModeControls() end
function runGetTrash() end
function applyTeleportRootState(rootPart, cframe, linearVelocity, angularVelocity)
        if not rootPart then return end
        rootPart:SetAttribute("IsAttackTP", true)
        if cframe then
                _G.NX_TP(cframe, "ApplyTeleportRootState", 4)
        end
        if linearVelocity then rootPart.AssemblyLinearVelocity = linearVelocity end
        if angularVelocity then rootPart.AssemblyAngularVelocity = angularVelocity end
        task.delay(0.1, function()
                pcall(function()
                        if not autoTpEnabled and not attackTpEnabled and not attackTpHolding then
                                rootPart:SetAttribute("IsAttackTP", false)
                        end
                end)
        end)
end
function overpowerRootState(rootPart, cframe, linearVelocity, angularVelocity)
        applyTeleportRootState(rootPart, cframe, linearVelocity, angularVelocity)
end
function predictedReturnCFrame(myRoot, roundTripFrames)
        if not myRoot or not myRoot.Parent then return nil end
        roundTripFrames = roundTripFrames or 2
        local ping = 0
        pcall(function()
                local stats = game:GetService("Stats")
                ping = (stats.Network.ServerStatsItem["Data Ping"]:GetValue() or 0) / 1000
        end)
        local frameTime = 1 / 60
        local totalTime = (roundTripFrames * frameTime) + (ping * 0.5)
        local vel = myRoot.AssemblyLinearVelocity
        local predictedPos = myRoot.Position + (vel * totalTime)
        return CFrame.new(predictedPos) * (myRoot.CFrame - myRoot.CFrame.Position)
end
function encodeKeybindValue(keyCode)
        if not keyCode then
                return ""
        end
        if keyCode == Enum.KeyCode.LeftAlt then
                return "Alt"
        end
        return keyCode.Name or ""
end
function decodeKeybindValue(value)
        if typeof(value) == "EnumItem" and value.EnumType == Enum.KeyCode then
                return value
        end
        if type(value) ~= "string" or value == "" then
                return nil
        end
        local success, result = pcall(function()
                return Enum.KeyCode[value]
        end)
        if success then
                return result
        end
        return nil
end
function loadSliderSaveData()
        if type(isfile) ~= "function" or type(readfile) ~= "function" then
                return
        end
        local success, exists = pcall(function()
                return isfile(NOTHING_X_UI_LOAD)
        end)
        if not success or not exists then
                return
        end
        local readSuccess, content = pcall(function()
                return readfile(NOTHING_X_UI_LOAD)
        end)
        if not readSuccess or content == "" then
                return
        end
        local decodeSuccess, decoded = pcall(function()
                return HttpService:JSONDecode(content)
        end)
        if decodeSuccess and type(decoded) == "table" then
                controlSaveData = decoded
        end
end
function saveSliderSaveData()
        if type(writefile) ~= "function" then
                return
        end
        controlSaveData.WalkFlingBodyMode = walkFlingBodyMode
        pcall(function()
                writefile(NOTHING_X_UI_SAVE, HttpService:JSONEncode(controlSaveData))
        end)
end
loadSliderSaveData()
do
        local _retryOk = (next(controlSaveData) ~= nil)
        if not _retryOk and type(isfile) == "function" then
                for _i = 1, 10 do
                        task.wait()
                        loadSliderSaveData()
                        if next(controlSaveData) ~= nil then break end
                end
        end
        local savedNoStunJump = controlSaveData["NoStunJumpEnabled"]
        if type(savedNoStunJump) == "boolean" then
                noStunJumpEnabled = savedNoStunJump
        end
end
if type(controlSaveData.KeybindHideNamesEnabled) == "boolean" then
        hideNamesEnabled = controlSaveData.KeybindHideNamesEnabled
end
if type(controlSaveData.Overlay4HP) == "boolean" then espOverlayConfig.showHp = controlSaveData.Overlay4HP end
if type(controlSaveData.Overlay4Character) == "boolean" then espOverlayConfig.showCharacter = controlSaveData.Overlay4Character end
if type(controlSaveData.Overlay4Ultimate) == "boolean" then espOverlayConfig.showUltimate = controlSaveData.Overlay4Ultimate end
if type(controlSaveData.Overlay4ESP) == "boolean" then espOverlayConfig.showEsp = controlSaveData.Overlay4ESP end
if type(controlSaveData.Overlay4Streak) == "boolean" then espOverlayConfig.showStreak = controlSaveData.Overlay4Streak end
if type(controlSaveData.Overlay4Death) == "boolean" then espOverlayConfig.showDeath = controlSaveData.Overlay4Death end
if type(controlSaveData.Overlay4Ulted) == "boolean" then espOverlayConfig.showUlted = controlSaveData.Overlay4Ulted end
if tonumber(controlSaveData.Speed) then
        Speed = tonumber(controlSaveData.Speed)
end
if tonumber(controlSaveData.DashBypassDuration) then
        dashBypassDuration = tonumber(controlSaveData.DashBypassDuration)
end
if tonumber(controlSaveData.WalkFlingPower) then
        walkFlingPower = tonumber(controlSaveData.WalkFlingPower)
end
if tonumber(controlSaveData.FlingPower) then
        flingPower = tonumber(controlSaveData.FlingPower)
end
if tonumber(controlSaveData.AuraRange) then
        auraRange = tonumber(controlSaveData.AuraRange)
end
if type(controlSaveData.WalkFlingUseNormal) == "boolean" then
        walkFlingUseNormal = controlSaveData.WalkFlingUseNormal
end
if controlSaveData.WalkFlingBodyMode ~= nil then
        local v = controlSaveData.WalkFlingBodyMode
        if v == "both" or v == true or v == false then
                walkFlingBodyMode = v
        end
end
if type(controlSaveData.BLClickTrash) == "boolean" then
        trashBlockEnabled = controlSaveData.BLClickTrash
end
if controlSaveData.MovementFlatState ~= nil then
        movementFlatState = controlSaveData.MovementFlatState
end
if controlSaveData.SelectedPlace then
        selectedPlace = controlSaveData.SelectedPlace
end
if type(controlSaveData.AttackTpMode) == "string" then
        attackTpMode = controlSaveData.AttackTpMode
end
if tonumber(controlSaveData.AutoCustomDistance) then
        autoCustomDistance = tonumber(controlSaveData.AutoCustomDistance)
end
if tonumber(controlSaveData.BehindDistance) then
        attackTpBehindDistance = tonumber(controlSaveData.BehindDistance)
end
if type(controlSaveData.CustomOffsets) == "table" then
        for k, v in pairs(controlSaveData.CustomOffsets) do
                local cleanKey = k:match("Custom %d+") or k
                if customOffsets[cleanKey] then
                        customOffsets[cleanKey].x = tonumber(v.x) or 0
                        customOffsets[cleanKey].y = tonumber(v.y) or 0
                        customOffsets[cleanKey].z = tonumber(v.z) or 0
                        if v.flat == "flat90" then
                                customOffsets[cleanKey].flat = "flat90"
                        else
                                customOffsets[cleanKey].flat = (v.flat == true)
                        end
                        customOffsets[cleanKey].useRotation = (v.useRotation == true)
                        customOffsets[cleanKey].rx = tonumber(v.rx) or 0
                        customOffsets[cleanKey].ry = tonumber(v.ry) or 0
                        customOffsets[cleanKey].rz = tonumber(v.rz) or 0
                end
        end
end
do
        local savedWalkFlingKeybind = decodeKeybindValue(controlSaveData.WalkFlingKeybind)
        if savedWalkFlingKeybind then
                walkFlingKeybind = savedWalkFlingKeybind
        end
end
do
        local savedGetTrashKeybind = decodeKeybindValue(controlSaveData.GetTrashKeybind)
        if savedGetTrashKeybind then
                getTrashState.keybind = savedGetTrashKeybind
        end
end
do
        local savedOrbitKeybind = decodeKeybindValue(controlSaveData.OrbitKeybind)
        if savedOrbitKeybind then
                orbitKeybind = savedOrbitKeybind
        end
end
do
        local savedViewKeybind = decodeKeybindValue(controlSaveData.ViewKeybind)
        if savedViewKeybind then
                viewKeybind = savedViewKeybind
        end
end
do
        local savedAutoTpKeybind = decodeKeybindValue(controlSaveData.AutoTPKeybind)
        if savedAutoTpKeybind then
                autoTpKeybind = savedAutoTpKeybind
        end
end
do
        local keybindToggleSaveKeys = {
                Speed    = "KeybindSpeedEnabled",
                Fly      = "KeybindFlyEnabled",
                CamLock  = "KeybindCamLockEnabled",
                AttackTP = "KeybindAttackTPEnabled",
                Target   = "KeybindTargetEnabled",
                WalkFling= "KeybindWalkFlingEnabled",
                SetBack  = "KeybindSetBackEnabled",
                Trash    = "KeybindTrashEnabled",
                Void     = "KeybindVoidEnabled",
                Orbit    = "KeybindOrbitEnabled",
                Places   = "KeybindPlacesEnabled",
                View     = "KeybindViewEnabled",
                AutoTPKey = "KeybindAutoTPKeyEnabled",
                FlingKey  = "KeybindFlingKeyEnabled",
        }
        for toggleKey, saveKey in pairs(keybindToggleSaveKeys) do
                local saved = controlSaveData[saveKey]
                if saved == "hide" or saved == "block" or saved == "off" then
                        keybindToggles[toggleKey] = saved
                elseif saved == true then
                        keybindToggles[toggleKey] = "block"
                elseif saved == false then
                        keybindToggles[toggleKey] = "off"
                else
                        keybindToggles[toggleKey] = "off"
                end
        end
end
function parseEnabledValue(value)
        if type(value) == "boolean" then
                return value
        elseif value == "true" or value == 1 then
                return true
        elseif value == "false" or value == 0 then
                return false
        end
        return nil
end
function updateKeybindText()
        local lines = {}
        if keybindEntries.Orbit then keybindEntries.Orbit.enabled = orbitEnabled end
        if keybindEntries.ViewKey then keybindEntries.ViewKey.enabled = viewing end
        if keybindEntries.AutoTPKey then keybindEntries.AutoTPKey.enabled = autoTpEnabled end
        if keybindEntries.FlingKey then keybindEntries.FlingKey.enabled = flingEnabled end
        local orderedKeys = { "Speed", "Fly", "CamLock", "BodyLock", "ComboLock", "AttackTP", "TargetPick", "WalkFling", "SetBack", "GetTrash", "VoidDead", "Custom", "Places", "ViewKey", "Orbit", "AutoTPKey", "FlingKey" }
        local toggleKeyMap = {
                TargetPick = "Target",
                VoidDead = "Void",
                GetTrash = "Trash",
                ViewKey = "View",
                Orbit = "Orbit",
                AutoTPKey = "AutoTPKey",
                FlingKey = "FlingKey",
        }
        local function appendEntry(entry, toggleState)
                if not entry then
                        return
                end
                if toggleState == "hide" then
                        return
                end
                local name = tostring(entry.name or "")
                local keybind = tostring(entry.keybind or "")
                if hideNamesEnabled then
                        name = ""
                end
                if entry.hideState == true then
                        if name ~= "" and keybind ~= "" then
                                lines[#lines + 1] = string.format("%s (%s)", name, keybind)
                        elseif name ~= "" then
                                lines[#lines + 1] = name
                        elseif keybind ~= "" then
                                lines[#lines + 1] = string.format("(%s)", keybind)
                        end
                        return
                end
                local stateText = tostring(entry.stateText or ((entry.enabled == true) and "ON" or "OFF"))
                if name ~= "" and keybind ~= "" then
                        lines[#lines + 1] = string.format("%s (%s) (%s)", name, keybind, stateText)
                elseif name ~= "" then
                        lines[#lines + 1] = string.format("%s (%s)", name, stateText)
                elseif keybind ~= "" then
                        lines[#lines + 1] = string.format("(%s) (%s)", keybind, stateText)
                end
        end
        for _, key in ipairs(orderedKeys) do
                local toggleKey = toggleKeyMap[key] or key
                local toggleState = keybindToggles[toggleKey]
                if key == "Places" then
                        if toggleState == "load" then
                                appendEntry(keybindEntries[key], "block")
                        elseif toggleState == "hide" then
                                appendEntry(keybindEntries[key], "hide")
                        end
                elseif toggleState == "off" or toggleState == nil then
                        appendEntry(keybindEntries[key], "block")
                elseif toggleState == "hide" then
                        appendEntry(keybindEntries[key], "hide")
                elseif key == "Custom" then
                        appendEntry(keybindEntries[key], "block")
                end
        end
        if #lines == 0 or not uiLoaded then
                keybindText.Text = ""
                if keybindFrame then
                        keybindFrame.Visible = false
                end
                return
        end
        keybindText.Text = table.concat(lines, "\n")
        if keybindFrame then
                keybindFrame.Visible = true
        end
end
function hasMapMainPart()
        if game.PlaceId ~= 10449761463 and game.PlaceId ~= 131048399685555 then return false end
        local map = workspace:FindFirstChild("Map")
        if not map then return false end
        return map:FindFirstChild("Floor/Roads") ~= nil
end
local mapDependentControls = {}
function syncMapDependentVisibility()
        local hasMain = hasMapMainPart()
        for _, control in ipairs(mapDependentControls) do
                if control and typeof(control) == "Instance" then
                        control.Visible = hasMain
                end
        end
end
local lastHasMainState = nil
local lastHasFloorState = nil
local floorOnlyPlaces = {
        ["Middle Of Map"] = true, ["Prison"] = true,
        ["Montain 1 Left"] = true, ["Montain 1 Right"] = true,
        ["Montain 2"] = true, ["Montain 2 Left"] = true, ["Montain 2 Right"] = true,
}
function syncPlacesKeybindDisplay()
        local hasMain = hasMapMainPart()
        local map = workspace:FindFirstChild("Map")
        local hasFloor = map and map:FindFirstChild("Floor/Roads") ~= nil
        if hasMain ~= lastHasMainState or hasFloor ~= lastHasFloorState then
                lastHasMainState = hasMain
                lastHasFloorState = hasFloor
                if game.GameId == 3808081382 then
                        local mapPlaces = { "Middle Of Map", "Prison", "Montain 1 Left", "Montain 1 Right", "Montain 2", "Montain 2 Left", "Montain 2 Right" }
                        local otherPlaces = { "Counter", "Counter Up", "Atomic Base", "Atomic Base Up", "Atomic Slash", "Atomic Slash Up" }
                        local currentItems = { "/\\" }
                        for _, v in ipairs(mapPlaces) do
                                if hasFloor or not floorOnlyPlaces[v] then
                                        table.insert(currentItems, v)
                                end
                        end
                        for _, v in ipairs(otherPlaces) do table.insert(currentItems, v) end
                        if placesDropdown then
                                local filtered = {}
                                for _, v in ipairs(currentItems) do
                                        if not v:find("View") then
                                                table.insert(filtered, v)
                                        end
                                end
                                placesDropdown.SetItems(filtered)
                                placesDropdown.Frame.Visible = true
                        end
                end
                syncMapDependentVisibility()
                syncGetTrashKeybindDisplay()
                syncMovementDisplay()
        end
        if game.GameId ~= 3808081382 then return end
        if placesDropdown then
                if selectedPlace then
                        local found = false
                        local items = placesDropdown.GetItems and placesDropdown.GetItems() or {}
                        for _, item in ipairs(items) do
                                if item == selectedPlace then
                                        found = true
                                        break
                                end
                        end
                        if not found then
                                selectedPlace = nil
                                placesDropdown.SetValue(nil, true)
                        end
                end
        end
        if not selectedPlace or selectedPlace == "" or selectedPlace == "/\\" then
                keybindEntries.Places = nil
                updateKeybindText()
                return
        end
        keybindEntries.Places = {
                name = "Places TP",
                keybind = "`",
                hideState = true,
        }
        updateKeybindText()
end
local lastHasMainMovementState = nil
function syncMovementDisplay()
        if not movementPanel then return end
        local hasMain = hasMapMainPart()
        if movementPanel.First and movementPanel.First.Button then movementPanel.First.Button.Visible = hasMain end
        if movementPanel.Second and movementPanel.Second.Button then movementPanel.Second.Button.Visible = hasMain end
        if movementPanel.Button and movementPanel.Button.Button then movementPanel.Button.Button.Visible = hasMain end
        if movementPanel.Button2 and movementPanel.Button2.Button then movementPanel.Button2.Button.Visible = hasMain end
        if movementPanel.Button3 and movementPanel.Button3.Button then movementPanel.Button3.Button.Visible = not hasMain end
end
function syncSetBackKeybindDisplay()
        keybindEntries.SetBack = {
                name = "Set back",
                keybind = encodeKeybindValue(setBackKeybind),
                stateText = setBackSavedCFrame and "S" or "-",
        }
        updateKeybindText()
end
local function syncSpeedKeybindDisplay()
        keybindEntries.Speed = {
                name = "Speed",
                keybind = encodeKeybindValue(speedKeybind),
                enabled = active,
        }
        updateKeybindText()
end
local function syncVoidDeadKeybindDisplay()
        keybindEntries.VoidDead = {
                name = "Void",
                keybind = encodeKeybindValue(voidDeadKeybind),
                enabled = voidDeadActive,
        }
        updateKeybindText()
end
local VoidDeadToggle = nil
function getUprightSetBackCFrame(position, sourceCFrame)
        local look = sourceCFrame and sourceCFrame.LookVector or Vector3.new(0, 0, -1)
        local flatLook = Vector3.new(look.X, 0, look.Z)
        if flatLook.Magnitude <= 0.001 then
                flatLook = Vector3.new(0, 0, -1)
        else
                flatLook = flatLook.Unit
        end
        return CFrame.lookAt(position, position + flatLook, Vector3.new(0, 1, 0))
end
local function canSaveSetBackPosition(character, rootPart, humanoid)
        if not character or not rootPart or not humanoid then
                return false
        end
        if humanoid.FloorMaterial ~= Enum.Material.Air then
                return true
        end
        local rayParams = RaycastParams.new()
        rayParams.FilterType = Enum.RaycastFilterType.Exclude
        rayParams.FilterDescendantsInstances = { character }
        rayParams.IgnoreWater = false
        local hit = Workspace:Raycast(rootPart.Position, Vector3.new(0, -8, 0), rayParams)
        return hit ~= nil
end
local function toggleVoidDead(state)
        local targetState = state
        if targetState == nil then
                targetState = not voidDeadActive
        end
        if targetState and isSafeZoneActive() then
                if VoidDeadToggle then VoidDeadToggle:SetValue(false, true) end
                return
        end
        if voidDeadActive == targetState then return end
        local plr = game:GetService("Players").LocalPlayer
        local character = plr.Character
        local humanoid = character and character:FindFirstChildOfClass("Humanoid")
        local hrp = character and character:FindFirstChild("HumanoidRootPart")
        if targetState == false then
                voidDeadActive = false
                if voidDeadConn then
                        voidDeadConn:Disconnect()
                        voidDeadConn = nil
                end
                if VoidDeadToggle then VoidDeadToggle:SetValue(false, true) end
                if voidDeadLastCF and hrp and humanoid and humanoid.Health > 0 then
                        applyTeleportRootState(hrp, voidDeadLastCF)
                end
                pcall(function()
                        workspace.Camera.CameraType = Enum.CameraType.Custom
                        workspace.Camera.CameraSubject = humanoid or character
                end)
                syncVoidDeadKeybindDisplay()
                return
        end
        if not (character and hrp and humanoid) then
                if VoidDeadToggle then VoidDeadToggle:SetValue(false, true) end
                return
        end
        if canSaveSetBackPosition(character, hrp, humanoid) then
                voidDeadLastCF = hrp.CFrame
        else
                voidDeadLastCF = hrp.CFrame
        end
        voidDeadActive = true
        syncVoidDeadKeybindDisplay()
        if VoidDeadToggle then VoidDeadToggle:SetValue(true, true) end
        pcall(function()
                workspace.Camera.CameraType = Enum.CameraType.Scriptable
        end)
        if voidDeadConn then voidDeadConn:Disconnect() end
        voidDeadConn = game:GetService("RunService").Heartbeat:Connect(function()
                if not voidDeadActive or not hrp.Parent or (humanoid and humanoid.Health <= 0) or isSafeZoneActive() then
                        if voidDeadConn then
                                voidDeadConn:Disconnect()
                                voidDeadConn = nil
                        end
                        if voidDeadActive and humanoid and humanoid.Health <= 0 then
                                toggleVoidDead(false)
                        end
                        return
                end
                _G.NX_TP(CFrame.new(hrp.Position.X, -6666, hrp.Position.Z), "Void-Dead", 4)
                hrp.AssemblyLinearVelocity = Vector3.zero
                hrp.AssemblyAngularVelocity = Vector3.zero
        end)
        local deathConn
        deathConn = humanoid.Died:Connect(function()
                if voidDeadActive then
                        toggleVoidDead(false)
                end
                deathConn:Disconnect()
        end)
end
local dVoidDeadActive = false
local dVoidDeadConn = nil
local function toggleDVoidDead(state)
        local targetState = state
        if targetState == nil then
                targetState = not dVoidDeadActive
        end
        if targetState and isSafeZoneActive() then
                if targetActionControls and targetActionControls.Fourth then
                        targetActionControls.Fourth.SetValue(false, true)
                end
                return
        end
        if dVoidDeadActive == targetState then return end
        local plr = game:GetService("Players").LocalPlayer
        local character = plr.Character
        local humanoid = character and character:FindFirstChildOfClass("Humanoid")
        local hrp = character and character:FindFirstChild("HumanoidRootPart")
        if targetState == false then
                dVoidDeadActive = false
                if dVoidDeadConn then
                        dVoidDeadConn:Disconnect()
                        dVoidDeadConn = nil
                end
                if targetActionControls and targetActionControls.Fourth then
                        targetActionControls.Fourth.SetValue(false, true)
                end
                if voidDeadLastCF and hrp and humanoid and humanoid.Health > 0 then
                        applyTeleportRootState(hrp, voidDeadLastCF)
                end
                pcall(function()
                        workspace.Camera.CameraType = Enum.CameraType.Custom
                        workspace.Camera.CameraSubject = humanoid or character
                end)
                return
        end
        if not (character and hrp and humanoid) then
                if targetActionControls and targetActionControls.Fourth then
                        targetActionControls.Fourth.SetValue(false, true)
                end
                return
        end
        if canSaveSetBackPosition(character, hrp, humanoid) then
                voidDeadLastCF = hrp.CFrame
        else
                voidDeadLastCF = hrp.CFrame
        end
        dVoidDeadActive = true
        if targetActionControls and targetActionControls.Fourth then
                targetActionControls.Fourth.SetValue(true, true)
        end
        pcall(function()
                workspace.Camera.CameraType = Enum.CameraType.Custom
                workspace.Camera.CameraSubject = humanoid or character
        end)
        if dVoidDeadConn then dVoidDeadConn:Disconnect() end
        dVoidDeadConn = game:GetService("RunService").Heartbeat:Connect(function()
                local targetModel = resolveAttackTpTarget()
                local targetHumanoid = targetModel and targetModel:FindFirstChildOfClass("Humanoid")
                if not dVoidDeadActive or not hrp.Parent or (humanoid and humanoid.Health <= 0) or isSafeZoneActive() then
                        if dVoidDeadConn then
                                dVoidDeadConn:Disconnect()
                                dVoidDeadConn = nil
                        end
                        if dVoidDeadActive and humanoid and humanoid.Health <= 0 then
                                toggleDVoidDead(false)
                        end
                        return
                end
                if targetModel and targetHumanoid and targetHumanoid.Health > 0 then
                        pcall(function()
                                workspace.Camera.CameraType = Enum.CameraType.Scriptable
                        end)
                        _G.NX_TP(CFrame.new(hrp.Position.X, -6666, hrp.Position.Z), "DVoid-Dead", 4)
                        hrp.AssemblyLinearVelocity = Vector3.zero
                        hrp.AssemblyAngularVelocity = Vector3.zero
                else
                        pcall(function()
                                if workspace.Camera.CameraType == Enum.CameraType.Scriptable then
                                        workspace.Camera.CameraType = Enum.CameraType.Custom
                                        workspace.Camera.CameraSubject = humanoid or character
                                end
                        end)
                        if hrp.Position.Y < -6000 then
                                if voidDeadLastCF then
                                        applyTeleportRootState(hrp, voidDeadLastCF)
                                end
                        else
                                voidDeadLastCF = hrp.CFrame
                        end
                end
        end)
        local deathConn
        deathConn = humanoid.Died:Connect(function()
                if dVoidDeadActive then
                        toggleDVoidDead(false)
                end
                deathConn:Disconnect()
        end)
end
local antiFlingEnabled = false
local antiFlingConnection = nil
local antiFlingDescConn = {}
local function toggleAntiFling(enabled)
        antiFlingEnabled = enabled
        if antiFlingConnection then
                antiFlingConnection:Disconnect()
                antiFlingConnection = nil
        end
        for _, c in ipairs(antiFlingDescConn) do pcall(function() c:Disconnect() end) end
        antiFlingDescConn = {}
        if antiFlingEnabled then
                local characterPartsCache = setmetatable({}, { __mode = "k" })
                local function registerPart(char, part)
                        if part:IsA("BasePart") then
                                if not characterPartsCache[char] then
                                        characterPartsCache[char] = {}
                                end
                                characterPartsCache[char][part] = true
                                pcall(function() part.CanCollide = false end)
                        end
                end
                local function hookCharacter(char)
                        if not char then return end
                        characterPartsCache[char] = {}
                        for _, part in ipairs(char:GetDescendants()) do
                                registerPart(char, part)
                        end
                        local c = char.DescendantAdded:Connect(function(part)
                                task.defer(function()
                                        if antiFlingEnabled then
                                                registerPart(char, part)
                                        end
                                end)
                        end)
                        antiFlingDescConn[#antiFlingDescConn + 1] = c
                end
                for _, p in ipairs(game:GetService("Players"):GetPlayers()) do
                        if p ~= player then
                                hookCharacter(p.Character)
                                local ca = p.CharacterAdded:Connect(function(char)
                                        task.defer(function() if antiFlingEnabled then hookCharacter(char) end end)
                                end)
                                antiFlingDescConn[#antiFlingDescConn + 1] = ca
                        end
                end
                local pa = game:GetService("Players").PlayerAdded:Connect(function(p)
                        if p == player then return end
                        hookCharacter(p.Character)
                        local ca = p.CharacterAdded:Connect(function(char)
                                task.defer(function() if antiFlingEnabled then hookCharacter(char) end end)
                        end)
                        antiFlingDescConn[#antiFlingDescConn + 1] = ca
                end)
                antiFlingDescConn[#antiFlingDescConn + 1] = pa
                antiFlingConnection = game:GetService("RunService").Stepped:Connect(function()
                        for char, parts in pairs(characterPartsCache) do
                                if char and char.Parent then
                                        for part in pairs(parts) do
                                                if part and part.Parent then
                                                        if part.CanCollide then
                                                                pcall(function() part.CanCollide = false end)
                                                        end
                                                else
                                                        parts[part] = nil
                                                end
                                        end
                                else
                                        characterPartsCache[char] = nil
                                end
                        end
                end)
        end
end
function syncFlyKeybindDisplay()
        keybindEntries.Fly = {
                name = "Fly",
                keybind = encodeKeybindValue(flyKeybind),
                enabled = flying,
        }
        updateKeybindText()
end
function syncCamLockKeybindDisplay()
syncBodyLockKeybindDisplay()
syncComboLockKeybindDisplay()
        keybindEntries.CamLock = {
                name = "CamLock",
                keybind = encodeKeybindValue(camLockKeybind),
                enabled = camLockEnabled,
                stateText = camLockEnabled and "ON" or "OFF",
        }
        updateKeybindText()
end
function syncBodyLockKeybindDisplay()
        keybindEntries.BodyLock = {
                name = "CamBody",
                keybind = encodeKeybindValue(bodyLockKeybind),
                enabled = bodyLockEnabled,
                stateText = bodyLockEnabled and "ON" or "OFF",
        }
        updateKeybindText()
end
function syncComboLockKeybindDisplay()
        keybindEntries.ComboLock = {
                name = "Cam B/L",
                keybind = encodeKeybindValue(comboLockKeybind),
                enabled = bodyLockEnabled and camLockEnabled,
                stateText = (bodyLockEnabled and camLockEnabled) and "ON" or "OFF",
        }
        updateKeybindText()
end
function syncAttackTpKeybindDisplay()
        keybindEntries.AttackTP = {
                name = "Attack TP",
                keybind = encodeKeybindValue(attackTpKeybind),
                enabled = attackTpEnabled,
        }
        updateKeybindText()
end
function syncTargetPickKeybindDisplay()
        keybindEntries.TargetPick = {
                name = "Target",
                keybind = encodeKeybindValue(targetSelectKeybind),
                hideState = true,
        }
        updateKeybindText()
end
function syncWalkFlingKeybindDisplay()
        keybindEntries.WalkFling = {
                name = "WalkFling",
                keybind = encodeKeybindValue(walkFlingKeybind),
                enabled = walkFlingEnabled,
        }
        updateKeybindText()
end
function syncGetTrashKeybindDisplay()
        if not hasMapMainPart() then
                keybindEntries.GetTrash = nil
                updateKeybindText()
                return
        end
        keybindEntries.GetTrash = {
                name = "Trash",
                keybind = getTrashState.keybind == Enum.KeyCode.LeftControl and "LeftCtrl" or encodeKeybindValue(getTrashState.keybind),
                enabled = getTrashState.running,
        }
        updateKeybindText()
end
function syncOrbitKeybindDisplay()
        keybindEntries.Orbit = {
                name = "Orbit",
                keybind = encodeKeybindValue(orbitKeybind or ""),
                enabled = orbitEnabled,
        }
        updateKeybindText()
end
function syncViewKeybindDisplay()
        keybindEntries.ViewKey = {
                name = "View",
                keybind = encodeKeybindValue(viewKeybind),
                enabled = viewing,
        }
        updateKeybindText()
end
function syncAutoTpKeybindDisplay()
        keybindEntries.AutoTPKey = {
                name = "Auto TP",
                keybind = encodeKeybindValue(autoTpKeybind),
                enabled = autoTpEnabled,
        }
        updateKeybindText()
end
function syncFlingKeybindDisplay()
        keybindEntries.FlingKey = {
                name = "Fling",
                keybind = encodeKeybindValue(flingKeybind),
                enabled = flingEnabled,
        }
        updateKeybindText()
end
function getRootUniversal(character)
        if not character then
                return nil
        end
        return character:FindFirstChild("HumanoidRootPart")
                or character:FindFirstChild("Torso")
                or character:FindFirstChild("UpperTorso")
end
function getOtherPlayers()
        local result = {}
        for _, otherPlayer in ipairs(Players:GetPlayers()) do
                if otherPlayer ~= player then
                        result[#result + 1] = otherPlayer
                end
        end
        return result
end
function parseWalkFlingDirectionSelection(value)
        local parsed = {}
        if type(value) == "table" then
                for key, enabled in pairs(value) do
                        if type(key) == "number" then
                                parsed[tostring(enabled)] = true
                        elseif enabled == true then
                                parsed[tostring(key)] = true
                        end
                end
        elseif type(value) == "string" and value ~= "" then
                parsed[value] = true
        end
        if next(parsed) == nil then
                parsed.Forward = true
        end
        walkFlingDirections = parsed
end
function getWalkFlingDirectionVector(rootPart)
        if not rootPart then
                return nil
        end
        local direction = Vector3.zero
        local lookVector
        if walkFlingBodyMode == "both" then
                lookVector = (rootPart.CFrame.LookVector + workspace.CurrentCamera.CFrame.LookVector) * 0.5
        elseif walkFlingBodyMode then
                lookVector = rootPart.CFrame.LookVector
        else
                lookVector = workspace.CurrentCamera.CFrame.LookVector
        end
        if walkFlingDirections.Forward then
                direction += lookVector
        end
        if walkFlingDirections.Backward then
                direction -= lookVector
        end
        if walkFlingDirections.Right then
                direction += rootPart.CFrame.RightVector
        end
        if walkFlingDirections.Left then
                direction -= rootPart.CFrame.RightVector
        end
        if walkFlingDirections.Upward then
                direction += Vector3.yAxis
        end
        if walkFlingDirections.Downward then
                direction -= Vector3.yAxis
        end
        if direction.Magnitude <= 0.001 then
                return nil
        end
        return direction.Unit
end
function resetGlobalFlingMotion()
        flingOrbitTime = 0
        flingOrbitStepXZ = 0
        flingOrbitStepY = 0
        flingTargetIndex = 1
        clickFlingBusy = false
        zeroLocalPlayerRoot()
end
function applyOrbitFlingStep(myRoot, targetRoot, dt, power)
        if not myRoot or not targetRoot then
                return
        end
        local effectivePower = math.max(math.abs(power or 0), FLING_INF_POWER)
        flingOrbitTime += dt * flingOrbitSpeed
        flingOrbitStepXZ += flingOrbitIncrement
        flingOrbitStepY += flingOrbitIncrement
        if flingOrbitStepXZ > flingOrbitMax then
                flingOrbitStepXZ = 0
        end
        if flingOrbitStepY > flingOrbitMax then
                flingOrbitStepY = 0
        end
        local offset = Vector3.new(
                math.cos(flingOrbitTime) * flingOrbitStepXZ,
                flingOrbitStepY,
                math.sin(flingOrbitTime) * flingOrbitStepXZ
        )
        local targetCFrame = targetRoot.CFrame + offset
        local targetAngularVelocity = Vector3.new(effectivePower, effectivePower, effectivePower)
        local targetLinearVelocity = targetRoot.CFrame.LookVector * effectivePower + Vector3.new(0, effectivePower * 0.5, 0)
        overpowerRootState(myRoot, targetCFrame, targetLinearVelocity, targetAngularVelocity)
end
function setWalkFlingEnabled(enabled)
        local nextState = (enabled == nil and not walkFlingEnabled) or (enabled == true)
        if nextState and isSafeZoneActive() then
                syncWalkFlingKeybindDisplay()
                return "OFF"
        end
        walkFlingEnabled = nextState
        if walkFlingEnabled then
                walkFlingTaskToken += 1
                local currentToken = walkFlingTaskToken
                task.spawn(function()
                        local moveOffset = 0.1
                        while walkFlingEnabled and walkFlingTaskToken == currentToken do
                                RunService.Heartbeat:Wait()
                                if isSafeZoneActive() then continue end
                                local currentCharacter = player.Character
                                local rootPart = getRootUniversal(currentCharacter)
                                if currentCharacter and rootPart then
                                        if not walkFlingUseNormal then
                                                local vel = rootPart.Velocity
                                                local direction = getWalkFlingDirectionVector(rootPart)
                                                if direction then
                                                        rootPart.Velocity = direction * walkFlingPower
                                                end
                                                RunService.RenderStepped:Wait()
                                                if walkFlingEnabled and walkFlingTaskToken == currentToken and rootPart.Parent then
                                                        rootPart.Velocity = vel
                                                end
                                        else
                                                local vel = rootPart.Velocity
                                                rootPart.Velocity = vel * walkFlingPower + Vector3.new(0, walkFlingPower, 0)
                                                RunService.RenderStepped:Wait()
                                                if walkFlingEnabled and walkFlingTaskToken == currentToken and rootPart.Parent then
                                                        rootPart.Velocity = vel
                                                end
                                                RunService.Stepped:Wait()
                                                if walkFlingEnabled and walkFlingTaskToken == currentToken and rootPart.Parent then
                                                        rootPart.Velocity = vel + Vector3.new(0, moveOffset, 0)
                                                        moveOffset = moveOffset * -1
                                                end
                                        end
                                end
                        end
                end)
        else
                walkFlingTaskToken += 1
                zeroLocalPlayerRoot()
        end
        syncWalkFlingKeybindDisplay()
        syncFlingModeControls()
        return walkFlingEnabled and "ON" or "OFF"
end
function setAuraFlingEnabled(enabled)
        local nextState = (enabled == nil and not auraFlingEnabled) or (enabled == true)
        if nextState and isSafeZoneActive() then
                syncFlingModeControls()
                return "OFF"
        end
        auraFlingEnabled = nextState
        if auraFlingHeartbeat then
                pcall(function()
                        auraFlingHeartbeat:Disconnect()
                end)
                auraFlingHeartbeat = nil
        end
        if auraFlingEnabled then
                auraFlingHeartbeat = task.spawn(function()
                        while auraFlingEnabled do
                                if isSafeZoneActive() then
                                        nextFrame()
                                        continue
                                end
                                local myCharacter = player.Character
                                local myRoot = getRootUniversal(myCharacter)
                                if myRoot then
                                        local returnCFrame = predictedReturnCFrame(myRoot, 2)
                                        local myPosition = myRoot.Position
                                        local touchedAny = false
                                        for _, targetModel in ipairs(getSelectableTargetModels()) do
                                                if not isTargetBlacklisted(targetModel, Players:GetPlayerFromCharacter(targetModel)) then
                                                        local targetRoot = getRootUniversal(targetModel)
                                                        if targetRoot and (targetRoot.Position - myPosition).Magnitude <= auraRange then
                                                                touchedAny = true
                                                                pcall(function() myRoot:SetAttribute("IsAttackTP", true) end)
                                                                overpowerRootState(myRoot, targetRoot.CFrame, Vector3.zero, Vector3.zero)
                                                                nextFrame()
                                                                if not auraFlingEnabled or not myRoot.Parent then
                                                                        break
                                                                end
                                                                local flingDir = (targetRoot.CFrame.Position - myPosition)
                                                                if flingDir.Magnitude < 0.001 then
                                                                        flingDir = targetRoot.CFrame.LookVector
                                                                else
                                                                        flingDir = flingDir.Unit
                                                                end
                                                                overpowerRootState(
                                                                        myRoot,
                                                                        targetRoot.CFrame,
                                                                        flingDir * flingPower + Vector3.new(0, flingPower * 0.5, 0),
                                                                        Vector3.new(flingPower, flingPower, flingPower)
                                                                )
                                                                nextFrame()
                                                                if not auraFlingEnabled or not myRoot.Parent then
                                                                        pcall(function() myRoot:SetAttribute("IsAttackTP", false) end)
                                                                        break
                                                                end
                                                        end
                                                end
                                        end
                                        if touchedAny and myRoot.Parent then
                                                overpowerRootState(myRoot, returnCFrame or myRoot.CFrame, Vector3.zero, Vector3.zero)
                                        end
                                end
                                nextFrame()
                        end
                end)
        end
        syncFlingModeControls()
        return auraFlingEnabled and "ON" or "OFF"
end
function toggleBHit(state)
        local nextState = (state == nil and not bHitEnabled) or (state == true)
        if nextState then
                if isSafeZoneActive() then
                        if targetActionControls and targetActionControls.Fifth then
                                targetActionControls.Fifth.SetValue(false, true)
                        end
                        return
                end
                local targetModel = resolveAttackTpTarget()
                if not targetModel then
                        if targetActionControls and targetActionControls.Fifth then
                                targetActionControls.Fifth.SetValue(false, true)
                        end
                        return
                end
        end
        bHitEnabled = nextState
        if bHitHeartbeat then
                pcall(function()
                        bHitHeartbeat:Disconnect()
                end)
                bHitHeartbeat = nil
        end
        if targetActionControls and targetActionControls.Fifth then
                targetActionControls.Fifth.SetValue(bHitEnabled, true)
        end
        if bHitEnabled then
                bHitHeartbeat = task.spawn(function()
                        local localPlayerInComboAreaStartTick = nil
                        while bHitEnabled do
                                if isSafeZoneActive() then
                                        nextFrame()
                                        continue
                                end
                                local myCharacter = player.Character
                                local myRoot = getRootUniversal(myCharacter)
                                local shouldDisable = false
                                if not manualAttackTpPlayer and not manualAttackTpTargetName and not manualAttackTpTarget then
                                        shouldDisable = true
                                elseif manualAttackTpPlayer and not manualAttackTpPlayer:IsDescendantOf(Players) then
                                        shouldDisable = true
                                end
                                if shouldDisable then
                                        toggleBHit(false)
                                        nextFrame()
                                        continue
                                end
                                local targetModel = resolveAttackTpTarget()
                                if targetModel and isTargetBlacklisted and isTargetBlacklisted(targetModel, Players:GetPlayerFromCharacter(targetModel)) then
                                        targetModel = nil
                                end
                                if myRoot and targetModel then
                                        local targetRoot = getRootUniversal(targetModel)
                                        local targetHumanoid = targetModel:FindFirstChildOfClass("Humanoid")
                                        if targetRoot then
                                                if targetHumanoid and targetHumanoid.Health > 0 then
                                                        local isBypassingTargetDistance = false
                                                        if _G.BringWallComboEnabled then
                                                                local comboPos = nil
                                                                if wallComboBringCustomPos then
                                                                        comboPos = wallComboBringCustomPos
                                                                elseif selectedPlace ~= "/\\" then
                                                                        local cf = resolvePlaceCF(selectedPlace)
                                                                        if cf then
                                                                                comboPos = cf.Position
                                                                        end
                                                                end
                                                                if comboPos then
                                                                        local playerDistToCombo = (myRoot.Position - comboPos).Magnitude
                                                                        if playerDistToCombo <= 33 then
                                                                                if not localPlayerInComboAreaStartTick then
                                                                                        localPlayerInComboAreaStartTick = tick()
                                                                                end
                                                                                if tick() - localPlayerInComboAreaStartTick <= 1.1 then
                                                                                        isBypassingTargetDistance = true
                                                                                end
                                                                        else
                                                                                localPlayerInComboAreaStartTick = nil
                                                                        end
                                                                else
                                                                        localPlayerInComboAreaStartTick = nil
                                                                end
                                                        else
                                                                localPlayerInComboAreaStartTick = nil
                                                        end
                                                        local distToTarget = (myRoot.Position - targetRoot.Position).Magnitude
                                                        if distToTarget > 155 and not isBypassingTargetDistance then
                                                                local angle = math.random() * math.pi * 2
                                                                local dist = 150 + (math.random() * 5)
                                                                local randomDir = Vector3.new(math.cos(angle), 0, math.sin(angle)).Unit
                                                                local baseSafePos = targetRoot.Position + (randomDir * dist) + Vector3.new(0, 50, 0)
                                                                local raycastParams = RaycastParams.new()
                                                                raycastParams.FilterType = Enum.RaycastFilterType.Exclude
                                                                raycastParams.FilterDescendantsInstances = {myCharacter, targetModel}
                                                                local raycastResult = workspace:Raycast(baseSafePos + Vector3.new(0, 50, 0), Vector3.new(0, -150, 0), raycastParams)
                                                                local orbitCF
                                                                if raycastResult then
                                                                        orbitCF = CFrame.lookAt(raycastResult.Position + Vector3.new(0, 3.5, 0), targetRoot.Position)
                                                                else
                                                                        orbitCF = CFrame.lookAt(baseSafePos, targetRoot.Position)
                                                                end
                                                                overpowerRootState(myRoot, orbitCF, Vector3.zero, Vector3.zero)
                                                                nextFrame()
                                                        end
                                                        local returnCF = predictedReturnCFrame(myRoot, 2) or myRoot.CFrame
                                                        local vel = Vector3.zero
                                                        local rot = Vector3.zero
                                                        if flingEnabled then
                                                                local flingDir = (targetRoot.CFrame.Position - myRoot.Position)
                                                                if flingDir.Magnitude < 0.001 then
                                                                        flingDir = targetRoot.CFrame.LookVector
                                                                else
                                                                        flingDir = flingDir.Unit
                                                                end
                                                                vel = flingDir * flingPower + Vector3.new(0, flingPower * 0.2, 0)
                                                                rot = Vector3.new(flingPower, flingPower, flingPower)
                                                        end
                                                        pcall(function() myRoot:SetAttribute("IsAttackTP", true) end)
                                                        local hitCF = CFrame.lookAt(targetRoot.Position + targetRoot.CFrame.LookVector * 3, targetRoot.Position)
                                                        overpowerRootState(myRoot, hitCF, vel, rot)
                                                        nextFrame()
                                                        pcall(function() myRoot:SetAttribute("IsAttackTP", false) end)
                                                        if myRoot.Parent then
                                                                overpowerRootState(myRoot, returnCF, Vector3.zero, Vector3.zero)
                                                        end
                                                end
                                        end
                                end
                                nextFrame()
                        end
                end)
        end
end
function clickFlingTargetModel(targetModel)
        if isSafeZoneActive() then return end
        if isTargetBlacklisted and isTargetBlacklisted(targetModel, Players:GetPlayerFromCharacter(targetModel)) then
                return
        end
        if clickFlingBusy then
                return
        end
        clickFlingBusy = true
        task.spawn(function()
                local myCharacter = player.Character
                local myRoot = getRootUniversal(myCharacter)
                if not myRoot then
                        clickFlingBusy = false
                        return
                end
                local savedCFrame = myRoot.CFrame
                local startedAt = tick()
                resetGlobalFlingMotion()
                while tick() - startedAt < 5 do
                        if not clickFlingEnabled or isSafeZoneActive() then
                                break
                        end
                        local targetRoot = getRootUniversal(targetModel)
                        if not targetRoot or not targetRoot.Parent or not myRoot.Parent then
                                break
                        end
                        local dt = RunService.Heartbeat:Wait()
                        applyOrbitFlingStep(myRoot, targetRoot, dt, flingPower)
                end
                if myRoot and myRoot.Parent then
                        myRoot.AssemblyAngularVelocity = Vector3.zero
                        myRoot.AssemblyLinearVelocity = Vector3.zero
                        _G.NX_TP(savedCFrame, "ClickFling-Return", 5)
                        task.wait()
                        _G.NX_TP(savedCFrame, "ClickFling-Return", 5)
                end
                clickFlingBusy = false
        end)
end
function getTargetModelFromClickedPart(part)
        local current = part
        while current do
                if current:IsA("Model") then
                        if current == player.Character then return nil end
                        local hum = current:FindFirstChildOfClass("Humanoid")
                        if hum and hum.Health > 0 then
                                return current
                        end
                end
                current = current.Parent
        end
        return nil
end
function setClickFlingEnabled(enabled)
        local nextState = (enabled == nil and not clickFlingEnabled) or (enabled == true)
        if nextState and isSafeZoneActive() then
                syncFlingModeControls()
                return "OFF"
        end
        clickFlingEnabled = nextState
        if clickFlingConnection then
                clickFlingConnection:Disconnect()
                clickFlingConnection = nil
        end
        if clickFlingEnabled then
                local mouse = player:GetMouse()
                clickFlingConnection = mouse.Button1Down:Connect(function()
                        if not clickFlingEnabled then
                                return
                        end
                        local targetModel = getTargetModelFromClickedPart(mouse.Target)
                        if targetModel then
                                clickFlingTargetModel(targetModel)
                        end
                end)
        else
                resetGlobalFlingMotion()
        end
        syncFlingModeControls()
        return clickFlingEnabled and "ON" or "OFF"
end
function setFlingAllEnabled(enabled)
        local nextState = enabled == nil and not flingAllEnabled or enabled == true
        if nextState and isSafeZoneActive() then
                syncFlingModeControls()
                return "OFF"
        end
        flingAllEnabled = nextState
        if flingAllHeartbeat then
                flingAllHeartbeat:Disconnect()
                flingAllHeartbeat = nil
        end
        if flingAllEnabled then
                resetGlobalFlingMotion()
                flingTargetIndex = 1
                flingAllHeartbeat = RunService.Heartbeat:Connect(function(dt)
                        if not flingAllEnabled then
                                if flingAllHeartbeat then
                                        flingAllHeartbeat:Disconnect()
                                        flingAllHeartbeat = nil
                                end
                                resetGlobalFlingMotion()
                                return
                        end
                        if isSafeZoneActive() then
                                return
                        end
                        local myRoot = getRootUniversal(player.Character)
                        if not myRoot then
                                return
                        end
                        local targetRoots = {}
                        for _, targetModel in ipairs(getSelectableTargetModels()) do
                                if not isTargetBlacklisted(targetModel, Players:GetPlayerFromCharacter(targetModel)) then
                                        local targetRoot = getRootUniversal(targetModel)
                                        if targetRoot then
                                                targetRoots[#targetRoots + 1] = targetRoot
                                        end
                                end
                        end
                        if #targetRoots == 0 then
                                return
                        end
                        if flingTargetIndex > #targetRoots then
                                flingTargetIndex = 1
                        end
                        local targetRoot = targetRoots[flingTargetIndex]
                        applyOrbitFlingStep(myRoot, targetRoot, dt, flingPower)
                        flingTargetIndex += 1
                end)
        else
                resetGlobalFlingMotion()
        end
        syncFlingModeControls()
        return flingAllEnabled and "ON" or "OFF"
end
function disableConflictingFeatures()
        if walkFlingEnabled then setWalkFlingEnabled(false) end
        if auraFlingEnabled then setAuraFlingEnabled(false) end
        if clickFlingEnabled then setClickFlingEnabled(false) end
        if flingAllEnabled then setFlingAllEnabled(false) end
        if voidDeadActive then toggleVoidDead(false) end
        if dVoidDeadActive then toggleDVoidDead(false) end
        stopSetBackTravel()
end
function restorePosition(savedCFrame)
        safeZoneRestoring = true
        local character = player.Character
        local hrp = character and character:FindFirstChild("HumanoidRootPart")
        if hrp and savedCFrame then
                hrp.Anchored = false
                _G.NX_TP(CFrame.new(0, -6666, 0), "SafeZone-Restore", 3)
                hrp.AssemblyLinearVelocity = Vector3.zero
                hrp.AssemblyAngularVelocity = Vector3.zero
                task.wait()
                if hrp.Parent then
                        _G.NX_TP(CFrame.new(savedCFrame.Position.X, -6666, savedCFrame.Position.Z), "SafeZone-Restore", 3)
                        hrp.AssemblyLinearVelocity = Vector3.zero
                        hrp.AssemblyAngularVelocity = Vector3.zero
                        task.wait()
                end
                if hrp.Parent then
                        _G.NX_TP(savedCFrame, "SafeZone-Restore", 3)
                        hrp.AssemblyLinearVelocity = Vector3.zero
                        hrp.AssemblyAngularVelocity = Vector3.zero
                end
                task.delay(0, function()
                        pcall(function() hrp:SetAttribute("IsAttackTP", false) end)
                end)
        end
        safeZoneRestoring = false
end
function WalkFling_bind(value)
        local decoded = decodeKeybindValue(value)
        if decoded == nil then
                return encodeKeybindValue(walkFlingKeybind)
        end
        walkFlingKeybind = decoded
        setSavedControlValue("WalkFlingKeybind", encodeKeybindValue(walkFlingKeybind))
        syncWalkFlingKeybindDisplay()
        return encodeKeybindValue(walkFlingKeybind)
end
function WalkFling_key(value)
        return WalkFling_bind(value)
end
function WalkFling_tog(value)
        return setWalkFlingEnabled(if value == nil then nil else parseEnabledValue(value))
end
function WalkFling_on()
        return setWalkFlingEnabled(true)
end
function WalkFling_off()
        return setWalkFlingEnabled(false)
end
function WalkFling_toggle()
        return setWalkFlingEnabled()
end
function GetTrash_bind(value)
        local decoded = decodeKeybindValue(value)
        if decoded == nil then
                return encodeKeybindValue(getTrashState.keybind)
        end
        getTrashState.keybind = decoded
        setSavedControlValue("GetTrashKeybind", encodeKeybindValue(getTrashState.keybind))
        syncGetTrashKeybindDisplay()
        return encodeKeybindValue(getTrashState.keybind)
end
function GetTrash_key(value)
        return GetTrash_bind(value)
end
function GetTrash_use()
        return runGetTrash()
end
function AuraFling_tog(value)
        return setAuraFlingEnabled(if value == nil then nil else parseEnabledValue(value))
end
function NormalWalkFling_tog(value)
        if value == nil then
                return walkFlingUseNormal and "ON" or "OFF"
        end
        walkFlingUseNormal = parseEnabledValue(value)
        syncFlingModeControls()
        return walkFlingUseNormal and "ON" or "OFF"
end
function ClickFling_tog(value)
        return setClickFlingEnabled(if value == nil then nil else parseEnabledValue(value))
end
function FlingAll_tog(value)
        return setFlingAllEnabled(if value == nil then nil else parseEnabledValue(value))
end
function WalkFlingPower_set(value)
        if value == nil then
                return walkFlingPower
        end
        walkFlingPower = tonumber(value) or walkFlingPower
        setSavedControlValue("WalkFlingPower", walkFlingPower)
        return walkFlingPower
end
function FlingsPower_set(value)
        if value == nil then
                return flingPower
        end
        flingPower = tonumber(value) or flingPower
        setSavedControlValue("FlingPower", flingPower)
        return flingPower
end
function AuraRange_set(value)
        if value == nil then
                return auraRange
        end
        auraRange = tonumber(value) or auraRange
        setSavedControlValue("AuraRange", auraRange)
        return auraRange
end
function WalkFlingDirection_set(value)
        if value == nil then
                return walkFlingDirections
        end
        parseWalkFlingDirectionSelection(value)
        setSavedControlValue("WalkFlingDirection", type(value) == "table" and value or { tostring(value) })
        return walkFlingDirections
end
function updateMovement()
        if not active then
                return
        end
        local hrp = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
        if not hrp then
                return
        end
        local moveVector = Vector3.zero
        if holdingW then
                moveVector += Vector3.new(0, 0, -Speed)
        end
        if holdingS then
                moveVector += Vector3.new(0, 0, Speed)
        end
        if holdingA then
                moveVector += Vector3.new(-Speed, 0, 0)
        end
        if holdingD then
                moveVector += Vector3.new(Speed, 0, 0)
        end
        if moveVector.Magnitude > 0 then
                local vel = hrp.AssemblyLinearVelocity
                hrp.CFrame = hrp.CFrame * CFrame.new(moveVector)
                hrp.AssemblyLinearVelocity = vel
        end
end
function toggleSpeed(nextState)
        if (nextState == nil or nextState == true) and (_G.SafeTeleportLock == true) then
                return active and "ON" or "OFF"
        end
        if nextState == nil then
                active = not active
        else
                active = nextState
        end
        if active and not speedLoopRunning then
                speedLoopRunning = true
                task.spawn(function()
                        while active do
                                nextFrame()
                                updateMovement()
                        end
                        speedLoopRunning = false
                end)
        end
        syncSpeedKeybindDisplay()
        return active and "ON" or "OFF"
end
function toggleAFK(enabled)
        afkEnabled = enabled
        if afkConnection then
                afkConnection:Disconnect()
                afkConnection = nil
        end
        if afkCharAddedConnection then
                afkCharAddedConnection:Disconnect()
                afkCharAddedConnection = nil
        end
        if afkEnabled then
                local character = player.Character
                local hrp = character and character:FindFirstChild("HumanoidRootPart")
                if hrp then
                        afkSavedCFrame = hrp.CFrame
                        afkCharacter = character
                else
                        afkSavedCFrame = nil
                        afkCharacter = nil
                end
                disableConflictingFeatures()
                if hrp then
                        hrp.Anchored = false
                        _G.NX_TP(CFrame.new(hrp.Position.X, -6666, hrp.Position.Z), "SafeZoneN-Start", 3)
                        hrp.AssemblyLinearVelocity = Vector3.zero
                        hrp.AssemblyAngularVelocity = Vector3.zero
                end
                local loopIndex = 1
                local loopPositions = {
                        Vector3.new(0, -6666, 0),
                        Vector3.new(10000, -6666, 0),
                        Vector3.new(0, -6666, 10000)
                }
                local isFirstTp = false
                local afkLastRun = 0
                afkConnection = RunService.Heartbeat:Connect(function()
                        local now = os.clock()
                        if now - afkLastRun < 0.05 then return end
                        afkLastRun = now
                        local char = player.Character
                        local root = char and char:FindFirstChild("HumanoidRootPart")
                        if not root then return end
                        if char ~= afkCharacter then
                                afkCharacter = char
                        end
                        if not afkSavedCFrame then
                                afkSavedCFrame = root.CFrame
                        end
                        root.Anchored = false
                        if isFirstTp then
                                isFirstTp = false
                                if afkSavedCFrame then
                                        _G.NX_TP(CFrame.new(afkSavedCFrame.Position.X, -6666, afkSavedCFrame.Position.Z), "SafeZoneN-Loop", 3)
                                else
                                        _G.NX_TP(CFrame.new(root.Position.X, -6666, root.Position.Z), "SafeZoneN-Loop", 3)
                                end
                        else
                                _G.NX_TP(CFrame.new(loopPositions[loopIndex]), "SafeZoneN-Loop", 3)
                                loopIndex = (loopIndex % #loopPositions) + 1
                        end
                        root.AssemblyLinearVelocity = Vector3.zero
                        root.AssemblyAngularVelocity = Vector3.zero
                end)
                afkCharAddedConnection = player.CharacterAdded:Connect(function(newChar)
                        afkSavedCFrame = nil
                        afkCharacter = newChar
                        task.spawn(function()
                                local newRoot = newChar:WaitForChild("HumanoidRootPart", 5)
                                if newRoot and afkEnabled then
                                        newRoot.Anchored = false
                                        _G.NX_TP(CFrame.new(newRoot.Position.X, -6666, newRoot.Position.Z), "SafeZoneN-Respawn", 3)
                                        newRoot.AssemblyLinearVelocity = Vector3.zero
                                        newRoot.AssemblyAngularVelocity = Vector3.zero
                                        isFirstTp = true
                                end
                        end)
                end)
        else
                if afkSavedCFrame then
                        task.spawn(restorePosition, afkSavedCFrame)
                end
                afkSavedCFrame = nil
                afkCharacter = nil
        end
        return afkEnabled and "ON" or "OFF"
end
local safeZoneHPConnection = nil
local safeZoneHPCharAddedConnection = nil
function toggleSafeZoneHP(enabled)
        safeZoneHPEnabled = enabled
        if safeZoneHPConnection then
                safeZoneHPConnection:Disconnect()
                safeZoneHPConnection = nil
        end
        if safeZoneHPCharAddedConnection then
                safeZoneHPCharAddedConnection:Disconnect()
                safeZoneHPCharAddedConnection = nil
        end
        if not enabled and safeZoneHPInSafeZone then
                if safeZoneHPSavedCFrame then
                        task.spawn(restorePosition, safeZoneHPSavedCFrame)
                end
                safeZoneHPInSafeZone = false
                safeZoneHPCharacter = nil
                safeZoneHPSavedCFrame = nil
        end
        if enabled then
                local loopIndex = 1
                local loopPositions = {
                        Vector3.new(0, -6666, 0),
                        Vector3.new(100000, -6666, 0),
                        Vector3.new(0, -6666, 100000),
                        Vector3.new(100000, -6666, 100000),
                        Vector3.new(-100000, -6666, 0),
                        Vector3.new(0, -6666, -100000),
                        Vector3.new(-100000, -6666, -100000)
                }
                local isFirstTp = false
                safeZoneHPConnection = RunService.Heartbeat:Connect(function()
                        if not safeZoneHPEnabled or afkEnabled then return end
                        local character = player.Character
                        local humanoid = character and character:FindFirstChildOfClass("Humanoid")
                        local hrp = character and character:FindFirstChild("HumanoidRootPart")
                        if not humanoid or not hrp then return end
                        local hp = humanoid.Health
                        local maxHp = humanoid.MaxHealth
                        if hp <= 0 then
                                if safeZoneHPInSafeZone then
                                        safeZoneHPInSafeZone = false
                                        safeZoneHPCharacter = nil
                                        safeZoneHPSavedCFrame = nil
                                end
                                return
                        end
                        if safeZoneHPInSafeZone and safeZoneHPCharacter and character ~= safeZoneHPCharacter then
                                safeZoneHPInSafeZone = false
                                safeZoneHPCharacter = nil
                                safeZoneHPSavedCFrame = nil
                                return
                        end
                        if safeZoneHPInSafeZone then
                                if hp >= 40 then
                                        if safeZoneHPSavedCFrame then
                                                task.spawn(restorePosition, safeZoneHPSavedCFrame)
                                        end
                                        safeZoneHPInSafeZone = false
                                        safeZoneHPCharacter = nil
                                        safeZoneHPSavedCFrame = nil
                                else
                                        hrp.Anchored = false
                                        if isFirstTp then
                                                isFirstTp = false
                                                if safeZoneHPSavedCFrame then
                                                        _G.NX_TP(CFrame.new(safeZoneHPSavedCFrame.Position.X, -6666, safeZoneHPSavedCFrame.Position.Z), "SafeZoneHP-Loop", 3)
                                                else
                                                        _G.NX_TP(CFrame.new(hrp.Position.X, -6666, hrp.Position.Z), "SafeZoneHP-Loop", 3)
                                                end
                                        else
                                                _G.NX_TP(CFrame.new(loopPositions[loopIndex]), "SafeZoneHP-Loop", 3)
                                                loopIndex = (loopIndex % #loopPositions) + 1
                                        end
                                        hrp.AssemblyLinearVelocity = Vector3.zero
                                        hrp.AssemblyAngularVelocity = Vector3.zero
                                end
                        else
                                if hp <= 30 then
                                        disableConflictingFeatures()
                                        safeZoneHPSavedCFrame = hrp.CFrame
                                        safeZoneHPCharacter = character
                                        safeZoneHPInSafeZone = true
                                        hrp.Anchored = false
                                        _G.NX_TP(CFrame.new(hrp.Position.X, -6666, hrp.Position.Z), "SafeZoneHP-Start", 3)
                                        hrp.AssemblyLinearVelocity = Vector3.zero
                                        hrp.AssemblyAngularVelocity = Vector3.zero
                                        isFirstTp = false
                                        loopIndex = 1
                                end
                        end
                end)
                safeZoneHPCharAddedConnection = player.CharacterAdded:Connect(function(newChar)
                        characterSpawnTime = os.clock()
                        safeZoneHPInSafeZone = false
                        safeZoneHPCharacter = nil
                        safeZoneHPSavedCFrame = nil
                end)
        end
        return safeZoneHPEnabled and "ON" or "OFF"
end
do
        local savedAFK = controlSaveData.AFKEnabled
        local savedHP = controlSaveData.HPSafeZoneEnabled
        if savedAFK == true then
                task.defer(function()
                        local char = player.Character
                        if not char then
                                char = player.CharacterAdded:Wait()
                        end
                        local hrp = char:WaitForChild("HumanoidRootPart", 5)
                        if hrp then
                                toggleAFK(true)
                        end
                end)
        end
        if savedHP == true then
                task.defer(function()
                        toggleSafeZoneHP(true)
                end)
        end
end
function stopFly()
        flying = false
        flyLockedPosition = nil
        if hum then
                hum.PlatformStand = false
                hum.WalkSpeed = 16
        end
        flyHoverPosition = nil
        if bv then
                bv:Destroy()
                bv = nil
        end
        if bg then
                bg:Destroy()
                bg = nil
        end
        velocity = Vector3.zero
        currentVel = Vector3.zero
        syncFlyKeybindDisplay()
end
function stopSetBackTravel()
        setBackTravelToken = (setBackTravelToken or 0) + 1
        if setBackTravelConn then
                setBackTravelConn:Disconnect()
                setBackTravelConn = nil
        end
        if setBackCollisionState then
                for part, canCollide in pairs(setBackCollisionState) do
                        if part and part.Parent then
                                part.CanCollide = canCollide
                        end
                end
                setBackCollisionState = nil
        end
end
function setSetBackNoclipEnabled(enabled)
        local currentCharacter = player.Character
        if not currentCharacter then
                return
        end
        if enabled then
                setBackCollisionState = {}
                for _, obj in ipairs(currentCharacter:GetDescendants()) do
                        if obj:IsA("BasePart") then
                                setBackCollisionState[obj] = obj.CanCollide
                                obj.CanCollide = false
                        end
                end
                return
        end
        if setBackCollisionState then
                for part, canCollide in pairs(setBackCollisionState) do
                        if part and part.Parent then
                                part.CanCollide = canCollide
                        end
                end
                setBackCollisionState = nil
        end
end
function hasLocalTrashcan()
        local currentCharacter = player.Character
        local playerAttribute = player:GetAttribute("HasTrashcan")
        local characterAttribute = currentCharacter and currentCharacter:GetAttribute("HasTrashcan")
        if playerAttribute ~= nil then
                return playerAttribute ~= false
        end
        if characterAttribute ~= nil then
                return characterAttribute ~= false
        end
        return false
end
function clickTrashcan()
        local virtualInputManager = game:GetService("VirtualInputManager")
        virtualInputManager:SendMouseButtonEvent(0, 0, 0, true, game, 0)
        virtualInputManager:SendMouseButtonEvent(0, 0, 0, false, game, 0)
end
function setGetTrashNoclipEnabled(enabled)
        local currentCharacter = player.Character
        if not currentCharacter then return end
        if enabled then
                if getTrashState.collisionState then
                        return
                end
                getTrashState.collisionState = {}
                for _, obj in ipairs(currentCharacter:GetDescendants()) do
                        if obj:IsA("BasePart") then
                                getTrashState.collisionState[obj] = obj.CanCollide
                                obj.CanCollide = false
                        end
                end
                return
        end
        if not getTrashState.collisionState then
                return
        end
        for part, canCollide in pairs(getTrashState.collisionState) do
                if part and part.Parent then
                        part.CanCollide = canCollide
                end
        end
        getTrashState.collisionState = nil
end
function getTrashTravelCFrame(position, targetPosition)
        local lookTarget = Vector3.new(targetPosition.X, position.Y, targetPosition.Z)
        if (lookTarget - position).Magnitude <= 0.01 then
                lookTarget = position + Vector3.new(0, 0, -1)
        end
        return CFrame.lookAt(position, lookTarget, Vector3.new(0, 1, 0)) * CFrame.Angles(math.rad(-90), 0, 0)
end
function startGetTrashHoldLoop(runToken)
        task.spawn(function()
                while getTrashState.running and getTrashState.token == runToken do
                        task.wait()
                        local currentCharacter = player.Character
                        local rootPart = currentCharacter and currentCharacter:FindFirstChild("HumanoidRootPart")
                        if rootPart and rootPart.Parent and getTrashState.holdCFrame then
                                rootPart.AssemblyLinearVelocity = Vector3.zero
                                rootPart.AssemblyAngularVelocity = Vector3.zero
                                _G.NX_TP(getTrashState.holdCFrame, "GetTrash", 4)
                        end
                end
        end)
end
function getTrashTargetParts()
        local map = Workspace:FindFirstChild("Map")
        local trashFolder = map and map:FindFirstChild("Trash")
        local targets = {}
        if not trashFolder then
                return targets
        end
        for _, obj in ipairs(trashFolder:GetDescendants()) do
                if obj:IsA("MeshPart") and obj.Name == "Trashcan" then
                        local ownerModel = obj:FindFirstAncestorOfClass("Model")
                        if ownerModel and ownerModel:IsDescendantOf(trashFolder) and ownerModel:GetAttribute("Broken") ~= true then
                                targets[#targets + 1] = {
                                        part = obj,
                                        model = ownerModel,
                                }
                        end
                end
        end
        return targets
end
function getRandomTrashTarget(ignoredModels)
        local availableTargets = {}
        local allParts = getTrashTargetParts()
        for _, entry in ipairs(allParts) do
                local targetPart = entry.part
                local targetModel = entry.model
                local ignoredUntil = ignoredModels[targetModel]
                if ignoredUntil and tick() >= ignoredUntil then
                        ignoredModels[targetModel] = nil
                        ignoredUntil = nil
                end
                if targetPart and targetPart.Parent and not ignoredUntil then
                        availableTargets[#availableTargets + 1] = entry
                end
        end
        if #availableTargets == 0 then
                return nil
        end
        local otherPlayers = getOtherPlayers()
        local sortedOptions = {}
        for _, entry in ipairs(availableTargets) do
                local pos = entry.part.Position
                local count = 0
                for _, oPlr in ipairs(otherPlayers) do
                        local char = oPlr.Character
                        local hrp = char and char:FindFirstChild("HumanoidRootPart")
                        if hrp then
                                if (hrp.Position - pos).Magnitude <= 45 then
                                        count = count + 1
                                end
                        end
                end
                table.insert(sortedOptions, {
                        entry = entry,
                        count = count
                })
        end
        table.sort(sortedOptions, function(a, b)
                return a.count < b.count
        end)
        for i = 1, math.min(3, #sortedOptions) do
        end
        local best = sortedOptions[1]
        return best.entry
end
function isValidTrashTarget(entry)
        if type(entry) ~= "table" then
                return false
        end
        local targetPart = entry.part
        local targetModel = entry.model
        if not targetPart or not targetPart.Parent or not targetModel or not targetModel.Parent then
                return false
        end
        if targetModel:GetAttribute("Broken") == true then
                return false
        end
        return true
end
function hasTrashcanAfterChecks(attempts, delayTime)
        local checkCount = attempts or 3
        local waitTime = delayTime or 0.08
        for index = 1, checkCount do
                if hasLocalTrashcan() then
                        return true
                end
                if index < checkCount then
                        task.wait(waitTime)
                end
        end
        return false
end
function getTrashTravelCFrame(position, targetPosition)
        local lookTarget = Vector3.new(targetPosition.X, position.Y, targetPosition.Z)
        if (lookTarget - position).Magnitude <= 0.01 then
                lookTarget = position + Vector3.new(0, 0, -1)
        end
        return CFrame.lookAt(position, lookTarget, Vector3.new(0, 1, 0)) * CFrame.Angles(math.rad(-90), 0, 0)
end
local function flyAlongPath(rootPart, fromPos, toPos, speed, runToken, lookTarget)
        local currentPos = fromPos
        local totalDist = (toPos - fromPos).Magnitude
        if totalDist < 0.05 then
                getTrashState.holdCFrame = getTrashTravelCFrame(toPos, lookTarget or (toPos + rootPart.CFrame.LookVector))
                rootPart.CFrame = getTrashState.holdCFrame
                return true
        end
        local traveled = 0
        while traveled < totalDist do
                if not getTrashState.running or getTrashState.token ~= runToken or not rootPart.Parent then
                        return false
                end
                local dt = task.wait()
                local step = speed * dt
                traveled = traveled + step
                if traveled > totalDist then
                        traveled = totalDist
                end
                local alpha = traveled / totalDist
                currentPos = fromPos:Lerp(toPos, alpha)
                getTrashState.holdCFrame = getTrashTravelCFrame(currentPos, lookTarget or toPos)
                _G.NX_TP(getTrashState.holdCFrame, "GetTrash", 4)
        end
        return true
end
function moveRootToTrashTarget(rootPart, targetPart, runToken)
        if not rootPart or not rootPart.Parent or not targetPart or not targetPart.Parent then
                return false
        end
        local startPos = rootPart.Position
        local targetPos = targetPart.Position
        local speed = getTrashState["speed-get"] or 120
        local p1 = startPos + Vector3.new(0, -6.5, 0)
        if not flyAlongPath(rootPart, startPos, p1, speed, runToken, p1) then
                return false
        end
        local p2 = Vector3.new(targetPos.X, p1.Y, targetPos.Z)
        if not flyAlongPath(rootPart, p1, p2, speed, runToken, p2) then
                return false
        end
        if not flyAlongPath(rootPart, p2, targetPos, speed, runToken, targetPos) then
                return false
        end
        return true
end
function moveRootToSavedTrashCFrame(rootPart, targetCFrame, runToken)
        if not rootPart or not rootPart.Parent or not targetCFrame then
                return false
        end
        local startPos = rootPart.Position
        local targetPos = targetCFrame.Position
        local speed = getTrashState["speed-back"] or 120
        local p1 = startPos + Vector3.new(0, -6.5, 0)
        if not flyAlongPath(rootPart, startPos, p1, speed, runToken, p1) then
                return false
        end
        local p2 = Vector3.new(targetPos.X, p1.Y, targetPos.Z)
        if not flyAlongPath(rootPart, p1, p2, speed, runToken, p2) then
                return false
        end
        local totalDist = (targetPos - p2).Magnitude
        local traveled = 0
        local startCFrame = getTrashTravelCFrame(p2, targetPos)
        while traveled < totalDist do
                if not getTrashState.running or getTrashState.token ~= runToken or not rootPart.Parent then
                        return false
                end
                local dt = task.wait()
                local step = speed * dt
                traveled = traveled + step
                if traveled > totalDist then
                        traveled = totalDist
                end
                local alpha = traveled / totalDist
                local currentPos = p2:Lerp(targetPos, alpha)
                getTrashState.holdCFrame = startCFrame:Lerp(targetCFrame, alpha)
                _G.NX_TP(getTrashState.holdCFrame, "GetTrash", 4)
        end
        return true
end
function returnFromTrashRun(runToken)
        local currentCharacter = player.Character
        local rootPart = currentCharacter and currentCharacter:FindFirstChild("HumanoidRootPart")
        local savedCF = getTrashState.savedCFrame
        if not rootPart or not savedCF then
                setGetTrashNoclipEnabled(false)
                getTrashState.blockSetBack = false
                return
        end
        moveRootToSavedTrashCFrame(rootPart, savedCF, runToken)
        if getTrashState.token == runToken then
                getTrashState.holdCFrame = nil
                setGetTrashNoclipEnabled(false)
                getTrashState.blockSetBack = false
        end
end
function liftOutOfTrashRun()
        local currentCharacter = player.Character
        local rootPart = currentCharacter and currentCharacter:FindFirstChild("HumanoidRootPart")
        if not rootPart or not rootPart.Parent then
                return
        end
        rootPart.AssemblyLinearVelocity = Vector3.zero
        rootPart.AssemblyAngularVelocity = Vector3.zero
        _G.NX_TP(rootPart.CFrame + Vector3.new(0, 17, 0), "GetTrash", 4)
end
function teleportBackToSavedTrashPositionInstant()
        local currentCharacter = player.Character
        local rootPart = currentCharacter and currentCharacter:FindFirstChild("HumanoidRootPart")
        if not rootPart or not rootPart.Parent or not getTrashState.savedCFrame then
                return
        end
        rootPart.AssemblyLinearVelocity = Vector3.zero
        rootPart.AssemblyAngularVelocity = Vector3.zero
        _G.NX_TP(getTrashState.savedCFrame, "GetTrash", 4)
end
function stopGetTrashImmediate()
        getTrashState.running = false
        getTrashState.returning = false
        getTrashState.blockSetBack = false
        getTrashState.holdCFrame = nil
        getTrashState.savedCFrame = nil
        _G.SafeTeleportLock = false
        task.spawn(function()
                for _ = 1, 10 do
                        if getTrashState.running then
                                break
                        end
                        setGetTrashNoclipEnabled(false)
                        task.wait()
                end
        end)
        syncGetTrashKeybindDisplay()
end
function finishGetTrashRun()
        getTrashState.running = false
        getTrashState.returning = false
        getTrashState.blockSetBack = false
        _G.SafeTeleportLock = false
        setGetTrashNoclipEnabled(false)
        getTrashState.holdCFrame = nil
        syncGetTrashKeybindDisplay()
end
runGetTrash = function()
        if not hasMapMainPart() then
                return "OFF"
        end
        local now = tick()
        if now - (getTrashState.lastToggleAt or 0) < (getTrashState.toggleCooldown or 0.35) then
                return getTrashState.running and "ON" or "OFF"
        end
        getTrashState.lastToggleAt = now
        if getTrashState.running then
                local stopToken = (getTrashState.token or 0) + 1
                getTrashState.token = stopToken
                if getTrashState.returning or getTrashState.holdCFrame ~= nil then
                        teleportBackToSavedTrashPositionInstant()
                end
                stopGetTrashImmediate()
                return "OFF"
        end
        local currentCharacter = player.Character
        local humanoid = currentCharacter and currentCharacter:FindFirstChildOfClass("Humanoid")
        local rootPart = currentCharacter and currentCharacter:FindFirstChild("HumanoidRootPart")
        if not currentCharacter or not humanoid or humanoid.Health <= 0 or not rootPart then
                return "OFF"
        end
        getTrashState.running = true
        getTrashState.returning = false
        getTrashState.blockSetBack = true
        local runToken = (getTrashState.token or 0) + 1
        getTrashState.token = runToken
        getTrashState.holdCFrame = nil
        setGetTrashNoclipEnabled(true)
        syncGetTrashKeybindDisplay()
        startGetTrashHoldLoop(runToken)
        local function captureGetTrashSavePosition(rp)
                getTrashState.savedCFrame = nil
                local saved = nil
                for i = 1, 3 do
                        local cf = rp and rp.CFrame
                        if cf and cf.Position.X == cf.Position.X then
                                saved = cf + Vector3.new(0, 1.3, 0)
                                getTrashState.savedCFrame = saved
                                if getTrashState.savedCFrame == saved then
                                        break
                                end
                        end
                end
                if not getTrashState.savedCFrame and rp then
                        getTrashState.savedCFrame = rp.CFrame + Vector3.new(0, 1.3, 0)
                end
        end
        task.spawn(function()
                local ignoredModels = {}
                local switchedTargets = 0
                captureGetTrashSavePosition(rootPart)
                while getTrashState.running and getTrashState.token == runToken do
                        currentCharacter = player.Character
                        rootPart = currentCharacter and currentCharacter:FindFirstChild("HumanoidRootPart")
                        humanoid = currentCharacter and currentCharacter:FindFirstChildOfClass("Humanoid")
                        if not currentCharacter or not rootPart or not humanoid or humanoid.Health <= 0 then
                                break
                        end
                        if hasTrashcanAfterChecks(11, 0.05) then
                                getTrashState.returning = true
                                setGetTrashNoclipEnabled(true)
                                getTrashState.blockSetBack = true
                                returnFromTrashRun(runToken)
                                if getTrashState.token ~= runToken or not getTrashState.running then
                                        break
                                end
                                getTrashState.returning = false
                                getTrashState.holdCFrame = nil
                                getTrashState.blockSetBack = false
                                while getTrashState.running and getTrashState.token == runToken and hasLocalTrashcan() do
                                        setGetTrashNoclipEnabled(false)
                                        getTrashState.blockSetBack = false
                                        task.wait()
                                end
                                setGetTrashNoclipEnabled(true)
                                getTrashState.blockSetBack = true
                                currentCharacter = player.Character
                                rootPart = currentCharacter and currentCharacter:FindFirstChild("HumanoidRootPart")
                                captureGetTrashSavePosition(rootPart)
                                ignoredModels = {}
                                switchedTargets = 0
                                continue
                        end
                        if switchedTargets >= 40 then
                                ignoredModels = {}
                                switchedTargets = 0
                                task.wait()
                                continue
                        end
                        task.wait()
                        if not getTrashState.running or getTrashState.returning or getTrashState.token ~= runToken then
                                break
                        end
                        currentCharacter = player.Character
                        rootPart = currentCharacter and currentCharacter:FindFirstChild("HumanoidRootPart")
                        humanoid = currentCharacter and currentCharacter:FindFirstChildOfClass("Humanoid")
                        if not currentCharacter or not rootPart or not humanoid or humanoid.Health <= 0 then
                                break
                        end
                        local targetEntry = getRandomTrashTarget(ignoredModels)
                        if not isValidTrashTarget(targetEntry) then
                                ignoredModels = {}
                                switchedTargets = 0
                                task.wait()
                                continue
                        end
                        if not moveRootToTrashTarget(rootPart, targetEntry.part, runToken) then
                                break
                        end
                        local clickAttempts = 0
                        while getTrashState.running and not getTrashState.returning and getTrashState.token == runToken and clickAttempts < 500 and not hasLocalTrashcan() do
                                if not isValidTrashTarget(targetEntry) or not rootPart.Parent then
                                        break
                                end
                                local distanceToTarget = (targetEntry.part.Position - rootPart.Position).Magnitude
                                if distanceToTarget > 5 then
                                        if not moveRootToTrashTarget(rootPart, targetEntry.part, runToken) then
                                                break
                                        end
                                else
                                        local closePosition = targetEntry.part.Position
                                        getTrashState.holdCFrame = getTrashTravelCFrame(closePosition, targetEntry.part.Position + rootPart.CFrame.LookVector)
                                        rootPart.AssemblyLinearVelocity = Vector3.zero
                                        rootPart.AssemblyAngularVelocity = Vector3.zero
                                        _G.NX_TP(getTrashState.holdCFrame, "GetTrash", 4)
                                        clickTrashcan()
                                        clickAttempts += 1
                                        task.wait()
                                end
                        end
                        if hasTrashcanAfterChecks(11, 0.05) then
                                continue
                        end
                        ignoredModels[targetEntry.model] = tick() + 0.5
                        switchedTargets += 1
                        task.wait()
                end
                if getTrashState.token == runToken and getTrashState.running then
                        getTrashState.returning = true
                        returnFromTrashRun(runToken)
                        finishGetTrashRun()
                end
        end)
        return "ON"
end
function saveSetBackPosition()
        if isSafeZoneActive() then return false end
        local currentCharacter = player.Character
        local currentHumanoid = currentCharacter and currentCharacter:FindFirstChildOfClass("Humanoid")
        local currentRoot = currentCharacter and currentCharacter:FindFirstChild("HumanoidRootPart")
        if not currentHumanoid or not currentRoot then
                return false
        end
        if not canSaveSetBackPosition(currentCharacter, currentRoot, currentHumanoid) then
                return false
        end
        setBackSavedCFrame = getUprightSetBackCFrame(currentRoot.Position, currentRoot.CFrame)
        syncSetBackKeybindDisplay()
        return true
end
function clearSetBackPosition()
        stopSetBackTravel()
        setBackSavedCFrame = nil
        syncSetBackKeybindDisplay()
        return true
end
function getSetBackTravelPosition(currentRoot, destination, step)
        local direction = destination.Position - currentRoot.Position
        local distance = direction.Magnitude
        if distance <= 0.001 then
                return destination.Position
        end
        local travelDirection = direction.Unit
        local desiredPosition = currentRoot.Position + (travelDirection * math.min(step, distance))
        local rayParams = RaycastParams.new()
        rayParams.FilterType = Enum.RaycastFilterType.Exclude
        rayParams.FilterDescendantsInstances = { player.Character }
        rayParams.IgnoreWater = true
        local hit = Workspace:Raycast(currentRoot.Position, desiredPosition - currentRoot.Position, rayParams)
        if not hit or not hit.Instance or not hit.Instance.CanCollide then
                return desiredPosition
        end
        local hitPart = hit.Instance
        local clearance = 6
        if hitPart:IsA("BasePart") then
                clearance = math.max(hitPart.Size.X, hitPart.Size.Y, hitPart.Size.Z) + 3
        end
        local side = Vector3.new(-travelDirection.Z, 0, travelDirection.X)
        if side.Magnitude > 0.001 then
                side = side.Unit
        end
        local blockedAbove = Workspace:Raycast(currentRoot.Position, Vector3.new(0, 6, 0), rayParams) ~= nil
        local horizontalDelta = Vector3.new(direction.X, 0, direction.Z)
        local horizontalDistance = horizontalDelta.Magnitude
        local verticalDistance = math.abs(direction.Y)
        local forwardStep = travelDirection * math.min(step * 0.6, distance)
        local sideStep = side * clearance
        local candidates
        if blockedAbove and horizontalDistance <= 4 and verticalDistance > 3 then
                candidates = {
                        currentRoot.Position + sideStep,
                        currentRoot.Position - sideStep,
                        currentRoot.Position + (sideStep * 1.6),
                        currentRoot.Position - (sideStep * 1.6),
                        currentRoot.Position + sideStep + Vector3.new(0, -(clearance * 0.7), 0),
                        currentRoot.Position - sideStep + Vector3.new(0, -(clearance * 0.7), 0),
                        currentRoot.Position + sideStep + forwardStep,
                        currentRoot.Position - sideStep + forwardStep,
                        currentRoot.Position + Vector3.new(0, -clearance, 0),
                }
        elseif blockedAbove then
                candidates = {
                        currentRoot.Position + sideStep + forwardStep,
                        currentRoot.Position - sideStep + forwardStep,
                        currentRoot.Position + Vector3.new(0, -(clearance * 0.7), 0) + forwardStep,
                        currentRoot.Position + Vector3.new(0, -(clearance * 0.7), 0) + sideStep + forwardStep,
                        currentRoot.Position + Vector3.new(0, -(clearance * 0.7), 0) - sideStep + forwardStep,
                        currentRoot.Position + Vector3.new(0, -clearance, 0),
                        currentRoot.Position + Vector3.new(0, clearance, 0) + sideStep + forwardStep,
                        currentRoot.Position + Vector3.new(0, clearance, 0) - sideStep + forwardStep,
                        currentRoot.Position + Vector3.new(0, clearance + 2, 0),
                }
        else
                candidates = {
                        currentRoot.Position + Vector3.new(0, clearance, 0) + forwardStep,
                        currentRoot.Position + sideStep + forwardStep,
                        currentRoot.Position - sideStep + forwardStep,
                        currentRoot.Position + Vector3.new(0, -(clearance * 0.7), 0) + forwardStep,
                        currentRoot.Position + Vector3.new(0, clearance, 0) + sideStep + forwardStep,
                        currentRoot.Position + Vector3.new(0, clearance, 0) - sideStep + forwardStep,
                        currentRoot.Position + Vector3.new(0, -(clearance * 0.7), 0) + sideStep + forwardStep,
                        currentRoot.Position + Vector3.new(0, -(clearance * 0.7), 0) - sideStep + forwardStep,
                        currentRoot.Position + Vector3.new(0, clearance + 2, 0),
                        currentRoot.Position + Vector3.new(0, -clearance, 0),
                }
        end
        for _, candidate in ipairs(candidates) do
                local candidateHit = Workspace:Raycast(currentRoot.Position, candidate - currentRoot.Position, rayParams)
                if not candidateHit or not candidateHit.Instance or not candidateHit.Instance.CanCollide then
                        return candidate
                end
        end
        return currentRoot.Position + Vector3.new(0, 8, 0)
end
function startSetBackTravel()
        if (_G.SafeTeleportLock == true) or isSafeZoneActive() then
                return false
        end
        local character = player.Character
        local rootPart = character and character:FindFirstChild("HumanoidRootPart")
        if not rootPart or not setBackSavedCFrame then
                return false
        end
        stopSetBackTravel()
        local runToken = setBackTravelToken
        local startCF = rootPart.CFrame
        local destCF = setBackSavedCFrame
        task.spawn(function()
                if setBackTravelToken ~= runToken then return end
                applyTeleportRootState(rootPart, destCF, Vector3.zero, Vector3.zero)
                local humanoid = character:FindFirstChildOfClass("Humanoid")
                if humanoid then
                        humanoid.PlatformStand = false
                        humanoid.Sit = false
                        humanoid:ChangeState(Enum.HumanoidStateType.GettingUp)
                end
        end)
        return true
end
local setBackHoldToken = 0
local setBackKeyDown = false
function handleSetBackKeybind()
        if isSafeZoneActive() then return end
        if getTrashState.blockSetBack
                and not getTrashState.running
                and not getTrashState.returning
                and getTrashState.holdCFrame == nil
                and not hasLocalTrashcan()
        then
                getTrashState.blockSetBack = false
                setGetTrashNoclipEnabled(false)
                syncGetTrashKeybindDisplay()
        end
        if getTrashState.blockSetBack then
                return
        end
        if (_G.SafeTeleportLock == true) then
                return
        end
        if setBackKeyDown then return end
        setBackKeyDown = true
        setBackHoldToken = (setBackHoldToken or 0) + 1
        local myToken = setBackHoldToken
        local pressTime = tick()
        task.delay(1.1, function()
                if myToken ~= setBackHoldToken then return end
                if not setBackKeyDown then return end
                if setBackSavedCFrame then
                        clearSetBackPosition()
                else
                        saveSetBackPosition()
                end
                setBackHoldToken = setBackHoldToken + 1
        end)
end
function handleSetBackKeybindReleased()
        if not setBackKeyDown then return end
        setBackKeyDown = false
        local myToken = setBackHoldToken
        if myToken == setBackHoldToken then
                setBackHoldToken = setBackHoldToken + 1
                if setBackSavedCFrame then
                        startSetBackTravel()
                end
        end
end
function toggleFly(nextState)
        if (nextState == nil or nextState == true) and (_G.SafeTeleportLock == true) then
                return flying and "ON" or "OFF"
        end
        if nextState == nil then
                flying = not flying
        else
                flying = nextState
        end
        if flying then
                if not hum or not root then
                        flying = false
                        return "OFF"
                end
                hum.PlatformStand = true
                hum.WalkSpeed = 0
                if bv then
                        bv:Destroy()
                end
                bv = Instance.new("BodyPosition")
                bv:SetAttribute("IsLocalMover", true)
                bv.MaxForce = Vector3.new(1e7, 1e7, 1e7)
                bv.Position = root.Position
                flyLockedPosition = root.Position
                bv.D = 2000
                bv.P = 18000
                bv.Parent = root
                if bg then
                        bg:Destroy()
                end
                bg = Instance.new("BodyGyro")
                bg:SetAttribute("IsLocalMover", true)
                bg.MaxTorque = Vector3.new(1e7, 1e7, 1e7)
                bg.P = 28000
                bg.D = 2200
                bg.Parent = root
        else
                stopFly()
        end
        syncFlyKeybindDisplay()
        return flying and "ON" or "OFF"
end
function handleCharacterDeath()
        if active then
                toggleSpeed(false)
        else
                syncSpeedKeybindDisplay()
        end
        if flying then
                stopFly()
        else
                syncFlyKeybindDisplay()
        end
        stopSetBackTravel()
        camLockEnabled = false
bodyLockEnabled = false
        camLockTarget = nil
        camLockWaiting = false
        syncCamLockKeybindDisplay()
        stopView()
        autoTpEnabled = false
        attackTpEnabled = false
        attackTpTarget = nil
        manualAttackTpTarget = nil
        manualAttackTpPlayer = nil
        pendingTeleportToSelectedPlayer = false
        walkFlingTaskToken += 1
        if auraFlingHeartbeat then
                pcall(function()
                        auraFlingHeartbeat:Disconnect()
                end)
                auraFlingHeartbeat = nil
        end
        if bHitEnabled then
                toggleBHit(false)
        end
        if clickFlingConnection then
                clickFlingConnection:Disconnect()
                clickFlingConnection = nil
        end
        if flingAllHeartbeat then
                flingAllHeartbeat:Disconnect()
                flingAllHeartbeat = nil
        end
        if targetActionHeartbeat then
                targetActionHeartbeat:Disconnect()
                targetActionHeartbeat = nil
        end
        flingEnabled = false
        walkFlingEnabled = false
        auraFlingEnabled = false
        clickFlingEnabled = false
        flingAllEnabled = false
        if syncModelDropdownSelectionToManualTarget then
                syncModelDropdownSelectionToManualTarget()
        end
        attackTpHolding = false
        syncAttackTpKeybindDisplay()
        syncTargetPickKeybindDisplay()
        syncSetBackKeybindDisplay()
        targetHPText.Text = ""
        targetHPText.Visible = false
        targetValueText.Text = ""
        targetValueText.Visible = false
        targetFrame.Visible = false
        syncTargetActionControls()
end
function bindLocalCharacter(newChar)
        char = newChar
        hum = newChar and newChar:FindFirstChildOfClass("Humanoid")
        root = newChar and newChar:FindFirstChild("HumanoidRootPart")
        cam = Workspace.CurrentCamera
        if localCharacterDiedConnection then
                localCharacterDiedConnection:Disconnect()
                localCharacterDiedConnection = nil
        end
        if hum then
                localCharacterDiedConnection = hum.Died:Connect(function()
                        if root and root.Position.Y >= 0 then
                                lastDeathCFrame = root.CFrame
                        end
                        _G.NOTHINGX_PendingFlyRespawn = flying == true
                        attackTpHolding = false
                        stopSetBackTravel()
                        if bv then
                                bv:Destroy()
                                bv = nil
                        end
                        if bg then
                                bg:Destroy()
                                bg = nil
                        end
                        velocity = Vector3.zero
                        currentVel = Vector3.zero
                end)
        end
end
function isTargetSafe(model)
        return true
end
function isValidCamLockTarget(model)
        if not model or model == char then
                return false
        end
        if isTargetBlacklisted and isTargetBlacklisted(model, Players:GetPlayerFromCharacter(model)) then
                return false
        end
        if not isTargetSafe(model) then
                return false
        end
        local modelHumanoid = model:FindFirstChildOfClass("Humanoid")
        local modelRoot = model:FindFirstChild("HumanoidRootPart")
        return modelHumanoid and modelRoot ~= nil
end
function isValidAttackTpTarget(model)
        if not isValidCamLockTarget(model) then
                return false
        end
        return model:FindFirstChild("HumanoidRootPart") ~= nil
end
function isDeadTargetModel(model)
        if not model or model == char or model.Parent == nil then
                return true
        end
        local targetPlayer = Players:GetPlayerFromCharacter(model)
        if targetPlayer == player then
                return true
        end
        local modelHumanoid = model:FindFirstChildOfClass("Humanoid")
        if modelHumanoid then
                return false
        end
        return false
end
function hasLiveStoredTarget(model)
        return model ~= nil and model.Parent ~= nil
end
_G.lastValidTrashTime = 0
function isTpBlocked(targetModel)
        if not trashBlockEnabled or _G.SafeTeleportLock then
                return false
        end
        local character = player.Character
        if not character then
                return false
        end
        if character:GetAttribute("HasTrashcan") then
                return true
        end
        local rootPart = character:FindFirstChild("HumanoidRootPart")
        if not rootPart then
                return false
        end
        local map = Workspace:FindFirstChild("Map")
        local trashFolder = map and map:FindFirstChild("Trash")
        local currentlyNearValid = false
        if trashFolder then
                for _, trashcan in ipairs(trashFolder:GetChildren()) do
                        if trashcan:IsA("Model") and not trashcan:GetAttribute("Broken") then
                                local part = trashcan:FindFirstChildWhichIsA("BasePart", true)
                                if part and (part.Position - rootPart.Position).Magnitude < 9.5 then
                                        currentlyNearValid = true
                                        break
                                end
                        end
                end
        end
        if currentlyNearValid then
                _G.lastValidTrashTime = tick()
                return true
        end
        if tick() - (_G.lastValidTrashTime or 0) < 1.1 then
                return true
        end
        if targetModel and trashFolder then
                local targetRoot = targetModel:FindFirstChild("HumanoidRootPart")
                if targetRoot then
                        local isTargetNormal = true
                        if targetModel:FindFirstChild("RagdollSim") or targetModel:FindFirstChild("Ragdoll") then
                                isTargetNormal = false
                        elseif targetModel:GetAttribute("Ragdolled") or targetModel:GetAttribute("Downed") or targetModel:GetAttribute("Lie") then
                                isTargetNormal = false
                        end
                        if isTargetNormal then
                                for _, trashcan in ipairs(trashFolder:GetChildren()) do
                                        if trashcan:IsA("Model") and not trashcan:GetAttribute("Broken") then
                                                local part = trashcan:FindFirstChildWhichIsA("BasePart", true)
                                                if part and (part.Position - targetRoot.Position).Magnitude < 12.0 then
                                                        return true
                                                end
                                        end
                                end
                        end
                end
        end
        return false
end
function getTrackedPlayerTargetModel(targetPlayer)
        if not targetPlayer or targetPlayer == player or targetPlayer.Parent ~= Players then
                return nil
        end
        local targetCharacter = targetPlayer.Character
        if targetCharacter and targetCharacter ~= char then
                return targetCharacter
        end
        return nil
end
function getSelectablePlayerForTargetModel(model)
        local targetPlayer = model and Players:GetPlayerFromCharacter(model)
        if isSelectablePlayerDropdownTarget(targetPlayer) then
                return targetPlayer
        end
        return nil
end
local manualAttackTpTargetName = nil
function resolveManualAttackTpTargetModel()
        if manualAttackTpPlayer then
                if isTargetBlacklisted and isTargetBlacklisted(nil, manualAttackTpPlayer) then
                        return nil
                end
                local trackedTarget = getTrackedPlayerTargetModel(manualAttackTpPlayer)
                if trackedTarget then
                        manualAttackTpTarget = trackedTarget
                end
        elseif manualAttackTpTarget then
                if manualAttackTpTarget.Parent == nil then
                        local targetName = manualAttackTpTargetName or manualAttackTpTarget.Name
                        for _, model in ipairs(getSelectableTargetModels()) do
                                if model.Name == targetName and model:FindFirstChildOfClass("Humanoid") then
                                        manualAttackTpTarget = model
                                        if syncModelDropdownSelectionToManualTarget then
                                                syncModelDropdownSelectionToManualTarget()
                                        end
                                        break
                                end
                        end
                end
                if manualAttackTpTarget and isTargetBlacklisted and isTargetBlacklisted(manualAttackTpTarget, nil) then
                        return nil
                end
        end
        return manualAttackTpTarget
end
function hasTrackedSelectedPlayer()
        return manualAttackTpPlayer ~= nil and manualAttackTpPlayer ~= player and manualAttackTpPlayer.Parent == Players
end
function isWaitingForSelectedTargetRespawn()
        if hasTrackedSelectedPlayer() and isDeadTargetModel(resolveManualAttackTpTargetModel()) then
                return true
        end
        if manualAttackTpTargetName ~= nil and isDeadTargetModel(resolveManualAttackTpTargetModel()) then
                return true
        end
        return false
end
function hasManualAttackTpSelection()
        if manualAttackTpPlayer then
                return hasTrackedSelectedPlayer()
        end
        return hasLiveStoredTarget(manualAttackTpTarget)
end
function hasActiveSelectedTarget()
        if hasLiveStoredTarget(camLockTarget) then
                return true
        end
        local resolvedManualTarget = resolveManualAttackTpTargetModel()
        if hasLiveStoredTarget(resolvedManualTarget) then
                return true
        end
        if manualAttackTpTargetName then
                return true
        end
        return false
end
function hasSelectedTargetOrPendingPlayer()
        return hasActiveSelectedTarget() or isWaitingForSelectedTargetRespawn() or manualAttackTpTargetName ~= nil
end
syncTargetActionControls = function()
        if not targetActionControls then
                return
        end
        targetActionControls.First.SetValue(viewing, true)
        targetActionControls.Second.SetValue(autoTpEnabled, true)
        targetActionControls.Third.SetValue(flingEnabled, true)
        if targetActionControls.Fourth then
                targetActionControls.Fourth.SetValue(dVoidDeadActive, true)
        end
        if targetActionControls.Fifth then
                targetActionControls.Fifth.SetValue(bHitEnabled, true)
        end
end
syncFlingModeControls = function()
        if not flingModeControls then
                return
        end
        flingModeControls.First.SetValue(walkFlingUseNormal, true)
        flingModeControls.Second.SetValue(auraFlingEnabled, true)
        flingModeControls.Third.SetValue(clickFlingEnabled, true)
        flingModeControls.Fourth.SetValue(flingAllEnabled, true)
end
function getDisplayedTargetModel()
        if camLockTarget then
                if not isDeadTargetModel(camLockTarget) or Players:GetPlayerFromCharacter(camLockTarget) then
                        return camLockTarget
                end
        end
        local currentTarget = resolveManualAttackTpTargetModel()
        if currentTarget then
                if not isDeadTargetModel(currentTarget) or Players:GetPlayerFromCharacter(currentTarget) then
                        return currentTarget
                end
        end
        if (autoTpEnabled or flingEnabled or viewing) and not manualAttackTpPlayer and not manualAttackTpTarget then
                local actionTarget = getCurrentActionTargetModel(false)
                if hasLiveStoredTarget(actionTarget) then
                        return actionTarget
                end
        end
        return nil
end
function updateTargetDisplay()
        local targetStateChanged = false
        if manualAttackTpPlayer then
                local trackedTarget = getTrackedPlayerTargetModel(manualAttackTpPlayer)
                if manualAttackTpPlayer == player or manualAttackTpPlayer.Parent ~= Players then
                        manualAttackTpPlayer = nil
                        manualAttackTpTarget = nil
                        pendingTeleportToSelectedPlayer = false
                        if syncModelDropdownSelectionToManualTarget then
                                syncModelDropdownSelectionToManualTarget()
                        end
                        targetStateChanged = true
                else
                        manualAttackTpTarget = trackedTarget
                end
        elseif manualAttackTpTarget and (manualAttackTpTarget.Parent == nil) then
                if not manualAttackTpTargetName then
                        manualAttackTpTarget = nil
                        pendingTeleportToSelectedPlayer = false
                        if syncModelDropdownSelectionToManualTarget then
                                syncModelDropdownSelectionToManualTarget()
                        end
                        targetStateChanged = true
                end
        end
        if camLockTarget and isDeadTargetModel(camLockTarget) and not manualAttackTpPlayer then
                local camPlayer = Players:GetPlayerFromCharacter(camLockTarget)
                if camPlayer and camPlayer.Parent ~= Players then
                        camLockTarget = nil
                        camLockWaiting = false
                        camLockEnabled = false
bodyLockEnabled = false
                        syncCamLockKeybindDisplay()
                        targetStateChanged = true
                end
        end
        if targetStateChanged then
                syncTargetPickKeybindDisplay()
        end
        local displayedTarget = getDisplayedTargetModel()
        local line1 = ""
        local line2 = ""
        if displayedTarget then
                local plr = game:GetService("Players"):GetPlayerFromCharacter(displayedTarget)
                local baseName = plr and plr.Name or displayedTarget.Name
                local isHPEnabled = getSavedControlValue("TargetHPEnabled") == true
                if isHPEnabled then
                        local hum = displayedTarget:FindFirstChildOfClass("Humanoid")
                        if hum then
                                line1 = string.format("| %s%% | %s", formatHPPercent(hum), baseName)
                        else
                                line1 = "| " .. baseName
                        end
                else
                        line1 = "| " .. baseName
                end
                if plr then
                        local dispName = plr.DisplayName or ""
                        if dispName ~= "" and dispName ~= baseName then
                                line2 = "| " .. dispName
                        end
                end
        elseif manualAttackTpPlayer then
                local baseName = manualAttackTpPlayer.Name
                line1 = "| " .. baseName
                local dispName = manualAttackTpPlayer.DisplayName or ""
                if dispName ~= "" and dispName ~= baseName then
                        line2 = "| " .. dispName
                end
        end
        targetHPText.Text = line1
        targetHPText.Visible = line1 ~= ""
        targetValueText.Text = line2
        targetValueText.Visible = line2 ~= ""
        hpSeparator.Visible = false
        targetFrame.Visible = line1 ~= ""
        if targetStateChanged and not hasSelectedTargetOrPendingPlayer() then
                if attackTpEnabled then
                        attackTpEnabled = false
                        attackTpTarget = nil
                        syncAttackTpKeybindDisplay()
                end
                if autoTpEnabled then
                        autoTpEnabled = false
                end
                if flingEnabled then
                        flingEnabled = false
                end
                if viewing then
                        stopView()
                else
                        syncTargetActionControls()
                end
        end
end
function getClosestAliveTarget()
        local currentCharacter = player.Character
        local currentRoot = currentCharacter and currentCharacter:FindFirstChild("HumanoidRootPart")
        if not currentRoot then
                return nil
        end
        local bestModel = nil
        local bestDistance = math.huge
        for _, model in ipairs(getSelectableTargetModels()) do
                local modelRoot = model:FindFirstChild("HumanoidRootPart")
                if modelRoot and model ~= currentCharacter then
                        local distance = (modelRoot.Position - currentRoot.Position).Magnitude
                        if distance < bestDistance then
                                bestDistance = distance
                                bestModel = model
                        end
                end
        end
        return bestModel
end
local lastSelectableModelsUpdate = 0
local lastWorkspaceScan = 0
local cachedSelectableModels = {}
function getSelectableTargetModels()
        local now = tick()
        if now - lastSelectableModelsUpdate < 0.2 then
                return cachedSelectableModels
        end
        lastSelectableModelsUpdate = now
        local currentCharacter = player.Character
        local models = {}
        local seenModels = {}
        for _, p in ipairs(Players:GetPlayers()) do
                if p ~= player and p.Character then
                        local model = p.Character
                        local modelRoot = model:FindFirstChild("HumanoidRootPart")
                        local hum = model:FindFirstChildOfClass("Humanoid")
                        if modelRoot and hum then
                                seenModels[model] = true
                                models[#models + 1] = model
                        end
                end
        end
        local function scanFolder(folder)
                if not folder then return end
                for _, model in ipairs(folder:GetChildren()) do
                        if model:IsA("Model") and model ~= currentCharacter and not Players:GetPlayerFromCharacter(model) and not Players:FindFirstChild(model.Name) and not offlinePlayers[model.Name] then
                                local hum = model:FindFirstChildOfClass("Humanoid")
                                local modelRoot = model:FindFirstChild("HumanoidRootPart")
                                if hum and modelRoot then
                                        if not seenModels[model] then
                                                seenModels[model] = true
                                                models[#models + 1] = model
                                        end
                                end
                        end
                end
        end
        scanFolder(Workspace:FindFirstChild("Live"))
        if now - lastWorkspaceScan > 1.5 then
                lastWorkspaceScan = now
                _G._cachedWorkspaceDummies = {}
                for _, model in ipairs(Workspace:GetChildren()) do
                        if model:IsA("Model") and model ~= currentCharacter and not Players:GetPlayerFromCharacter(model) and not Players:FindFirstChild(model.Name) and not offlinePlayers[model.Name] then
                                local hum = model:FindFirstChildOfClass("Humanoid")
                                local modelRoot = model:FindFirstChild("HumanoidRootPart")
                                if hum and modelRoot then
                                        table.insert(_G._cachedWorkspaceDummies, model)
                                end
                        end
                end
        end
        for _, model in ipairs(_G._cachedWorkspaceDummies or {}) do
                if model.Parent == Workspace then
                        if not seenModels[model] then
                                seenModels[model] = true
                                models[#models + 1] = model
                        end
                end
        end
        cachedSelectableModels = models
        return models
end
function getClosestAlivePlayerTarget()
        local currentCharacter = player.Character
        local currentRoot = currentCharacter and currentCharacter:FindFirstChild("HumanoidRootPart")
        if not currentRoot then
                return nil
        end
        local bestModel = nil
        local bestDistance = math.huge
        for _, model in ipairs(getSelectableTargetModels()) do
                if not (isTargetBlacklisted and isTargetBlacklisted(model, Players:GetPlayerFromCharacter(model))) then
                        local modelRoot = model:FindFirstChild("HumanoidRootPart")
                        if modelRoot and model ~= currentCharacter then
                                local distance = (modelRoot.Position - currentRoot.Position).Magnitude
                                if distance < bestDistance then
                                        bestDistance = distance
                                        bestModel = model
                                end
                        end
                end
        end
        return bestModel
end
function getPreferredAttackTpTarget()
        if hasLiveStoredTarget(camLockTarget) then
                return camLockTarget
        end
        local resolvedManualTarget = resolveManualAttackTpTargetModel()
        if hasLiveStoredTarget(resolvedManualTarget) then
                return resolvedManualTarget
        end
        return getClosestAlivePlayerTarget()
end
function getCurrentActionTargetModel(allowClosestFallback)
        if hasLiveStoredTarget(camLockTarget) then
                if not (isTargetBlacklisted and isTargetBlacklisted(camLockTarget, Players:GetPlayerFromCharacter(camLockTarget))) then
                        return camLockTarget
                end
        end
        local resolvedManualTarget = resolveManualAttackTpTargetModel()
        if hasLiveStoredTarget(resolvedManualTarget) then
                return resolvedManualTarget
        end
        if manualAttackTpPlayer or manualAttackTpTarget then
                return nil
        end
        if allowClosestFallback == true then
                local closestTarget = getClosestAlivePlayerTarget()
                if hasLiveStoredTarget(closestTarget) then
                        return closestTarget
                end
        end
        if hasLiveStoredTarget(attackTpTarget) then
                return attackTpTarget
        end
        return nil
end
resolveAttackTpTarget = function()
        return getCurrentActionTargetModel(attackTpEnabled == true)
end
function getHorizontalUnit(vector)
        local flattened = Vector3.new(vector.X, 0, vector.Z)
        local magnitude = flattened.Magnitude
        if magnitude <= 0.001 then
                return nil
        end
        return flattened / magnitude
end
function getRotationOnlyCFrame(sourceCFrame)
        if not sourceCFrame then
                return CFrame.new()
        end
        return CFrame.lookAt(Vector3.new(), sourceCFrame.LookVector, sourceCFrame.UpVector)
end
zeroLocalPlayerRoot = function()
	local character = player.Character
	if not character then return end
	for _, part in ipairs(character:GetDescendants()) do
		if part:IsA("BasePart") then
			pcall(function()
				part.AssemblyLinearVelocity = Vector3.zero
				part.AssemblyAngularVelocity = Vector3.zero
			end)
		end
	end
	local hrp = character:FindFirstChild("HumanoidRootPart")
	if hrp then
		pcall(function()
			hrp.AssemblyLinearVelocity = Vector3.zero
			hrp.AssemblyAngularVelocity = Vector3.zero
		end)
	end
end
function getAppliedFlySpeed()
        return flySpeed * flySpeedMultiplier
end
function isAirborneHumanoid(modelHumanoid)
        if not modelHumanoid then
                return false
        end
        local state = modelHumanoid:GetState()
        return state == Enum.HumanoidStateType.Freefall
                or state == Enum.HumanoidStateType.Jumping
                or state == Enum.HumanoidStateType.FallingDown
                or state == Enum.HumanoidStateType.Flying
                or state == Enum.HumanoidStateType.Physics
                or state == Enum.HumanoidStateType.PlatformStanding
end
function isAliveHumanoid(humanoid)
        return humanoid ~= nil
                and humanoid.Health > 0
                and humanoid:GetState() ~= Enum.HumanoidStateType.Dead
end
function getAttackTpPlacement(characterRoot, targetModel, modeOverride)
        if not characterRoot or not targetModel then
                return nil, nil
        end
        local targetRoot = targetModel:FindFirstChild("HumanoidRootPart")
        local targetHumanoid = targetModel:FindFirstChildOfClass("Humanoid")
        if not targetRoot or not isAliveHumanoid(targetHumanoid) then
                return nil, nil
        end
        local characterHumanoid = characterRoot.Parent and characterRoot.Parent:FindFirstChildOfClass("Humanoid")
        if not isAliveHumanoid(characterHumanoid) then
                return nil, nil
        end
        local amFlying = flying or (_G.NOTHINGX_FlyActive == true)
        local isTargetAir = isAirborneHumanoid(targetHumanoid)
        local useAirTracking = isTargetAir or isAirborneHumanoid(characterHumanoid) or amFlying
        local targetVelocity = targetRoot.AssemblyLinearVelocity
        local baseLeadTime = useAirTracking and attackTpAirLeadTime or attackTpLeadTime
        if baseLeadTime == 0 then
                local ping = 0
                pcall(function()
                        local stats = game:GetService("Stats")
                        ping = (stats.Network.ServerStatsItem["Data Ping"]:GetValue() or 0) / 1000
                end)
                baseLeadTime = (ping > 0 and (ping * 1.5) or 0.12) + 0.05
        end
        local speed = targetVelocity.Magnitude
        local speedScale = 1
        local leadTime = baseLeadTime * speedScale
        local horizontalVelocity = Vector3.new(targetVelocity.X, 0, targetVelocity.Z)
        local horizontalLead = horizontalVelocity * leadTime
        if horizontalLead.Magnitude > attackTpMaxHorizontalLead then
                horizontalLead = horizontalLead.Unit * attackTpMaxHorizontalLead
        end
        local verticalVel = targetVelocity.Y
        local gravityCompensation = 0
        if isTargetAir and verticalVel < -2 then
                local g = (Workspace.Gravity or 196.2)
                gravityCompensation = -0.5 * g * (leadTime * leadTime)
                gravityCompensation = math.clamp(gravityCompensation, -attackTpMaxVerticalLead, 0)
        end
        local verticalLead = (verticalVel * leadTime)
                + (isTargetAir and attackTpVerticalLead or 0)
                + gravityCompensation
        verticalLead = math.clamp(verticalLead, -attackTpMaxVerticalLead, attackTpMaxVerticalLead)
        local predictedTargetPosition = targetRoot.Position + horizontalLead + Vector3.new(0, verticalLead, 0)
        local isRagdoll = targetModel:FindFirstChild("RagdollSim") or targetModel:FindFirstChild("Ragdoll")
        local mode = modeOverride or attackTpMode or "Behind"
        local finalCFrame = nil
        local verticalOffset = useAirTracking and attackTpAirVerticalOffset or attackTpGroundVerticalOffset
        if mode == "Above" then
                local dist = isRagdoll and 4.2 or 6.8
                finalCFrame = CFrame.lookAt(predictedTargetPosition + Vector3.new(0, dist + verticalOffset, 0), predictedTargetPosition, worldUpVector)
        elseif mode == "Under" then
                finalCFrame = CFrame.lookAt(predictedTargetPosition + Vector3.new(0, -6.5 + verticalOffset, 0), predictedTargetPosition, worldUpVector)
        elseif mode == "Behind" then
                local followDirection = getHorizontalUnit(targetVelocity)
                        or getHorizontalUnit(targetRoot.CFrame.LookVector)
                        or getHorizontalUnit(targetRoot.Position - characterRoot.Position)
                        or Vector3.new(0, 0, -1)
                local dist = isRagdoll and 1.2 or 1.15
                if useAirTracking then dist = 0.85 end
                finalCFrame = CFrame.lookAt(predictedTargetPosition - (followDirection * dist) + Vector3.new(0, verticalOffset, 0), predictedTargetPosition, worldUpVector)
        elseif mode == "Behind Custom" then
                local followDirection = getHorizontalUnit(targetVelocity)
                        or getHorizontalUnit(targetRoot.CFrame.LookVector)
                        or getHorizontalUnit(targetRoot.Position - characterRoot.Position)
                        or Vector3.new(0, 0, -1)
                local dist = isRagdoll and (attackTpBehindDistance * 0.8) or attackTpBehindDistance
                finalCFrame = CFrame.lookAt(predictedTargetPosition - (followDirection * dist) + Vector3.new(0, verticalOffset, 0), predictedTargetPosition, worldUpVector)
        elseif mode == "Aggressive" then
                local followDirection = getHorizontalUnit(targetVelocity)
                        or getHorizontalUnit(targetRoot.CFrame.LookVector)
                        or getHorizontalUnit(targetRoot.Position - characterRoot.Position)
                        or Vector3.new(0, 0, -1)
                finalCFrame = CFrame.lookAt(predictedTargetPosition - (followDirection * 0.6) + Vector3.new(0, 1.2 + verticalOffset, 0), predictedTargetPosition, worldUpVector)
        elseif mode == "Auto" then
                local followDirection = getHorizontalUnit(targetVelocity)
                        or getHorizontalUnit(targetRoot.CFrame.LookVector)
                        or getHorizontalUnit(targetRoot.Position - characterRoot.Position)
                        or Vector3.new(0, 0, -1)
                local dist = isRagdoll and 0.6 or 1.4
                local height = isRagdoll and 1.0 or 1.2
                finalCFrame = CFrame.lookAt(predictedTargetPosition - (followDirection * dist) + Vector3.new(0, height + verticalOffset, 0), predictedTargetPosition, worldUpVector)
        elseif mode == "Auto Custom" then
                local followDirection = getHorizontalUnit(targetVelocity)
                        or getHorizontalUnit(targetRoot.CFrame.LookVector)
                        or getHorizontalUnit(targetRoot.Position - characterRoot.Position)
                        or Vector3.new(0, 0, -1)
                local dist = isRagdoll and (autoCustomDistance * 0.5) or autoCustomDistance
                finalCFrame = CFrame.lookAt(predictedTargetPosition - (followDirection * dist) + Vector3.new(0, 1.2 + verticalOffset, 0), predictedTargetPosition, worldUpVector)
        elseif mode == "Front" then
                local followDirection = getHorizontalUnit(targetRoot.CFrame.LookVector) or Vector3.new(0, 0, 1)
                local dist = isRagdoll and 2.5 or 4.0
                finalCFrame = CFrame.lookAt(predictedTargetPosition + (followDirection * dist) + Vector3.new(0, verticalOffset, 0), predictedTargetPosition, worldUpVector)
        elseif mode == "Middle" then
                finalCFrame = CFrame.lookAt(predictedTargetPosition + Vector3.new(0, verticalOffset + 0.05, 0), predictedTargetPosition + Vector3.new(0, 1, 0), worldUpVector)
        elseif string.find(tostring(mode), "Custom") then
                local cleanMode = tostring(mode):match("Custom %d+")
                local offsets = customOffsets[cleanMode] or { x = 0, y = 0, z = 0, flat = false, useRotation = false, rx = 0, ry = 0, rz = 0 }
                local offsetVec = Vector3.new(offsets.x, offsets.y, offsets.z)
                if offsetVec.Magnitude < 0.1 then
                        offsetVec = Vector3.new(0, 0.1, 0)
                end
                local rotatedOffset = targetRoot.CFrame:VectorToWorldSpace(offsetVec)
                local targetPos = predictedTargetPosition + rotatedOffset + Vector3.new(0, verticalOffset, 0)
                if offsets.useRotation then
                        local rx = math.rad(offsets.rx or 0)
                        local ry = math.rad(offsets.ry or 0)
                        local rz = math.rad(offsets.rz or 0)
                        local targetLook = targetRoot.CFrame.LookVector
                        local flatTargetLook = Vector3.new(targetLook.X, 0, targetLook.Z)
                        local baseRotCF
                        if flatTargetLook.Magnitude > 0.01 then
                                baseRotCF = CFrame.lookAt(targetPos, targetPos + flatTargetLook.Unit, worldUpVector)
                        else
                                baseRotCF = CFrame.new(targetPos)
                        end
                        finalCFrame = baseRotCF * CFrame.fromEulerAnglesXYZ(rx, ry, rz)
                else
                        local lookAtCF = CFrame.lookAt(targetPos, predictedTargetPosition, worldUpVector)
                        if offsets.flat == "flat90" then
                                local targetLook = targetRoot.CFrame.LookVector
                                local flatLookVector = Vector3.new(targetLook.X, 0, targetLook.Z).Unit
                                if flatLookVector.Magnitude > 0 then
                                        local flatCF = CFrame.lookAt(targetPos, targetPos + flatLookVector, worldUpVector)
                                        finalCFrame = flatCF * CFrame.Angles(math.rad(90), 0, 0)
                                else
                                        finalCFrame = lookAtCF * CFrame.Angles(math.rad(90), 0, 0)
                                end
                        elseif offsets.flat then
                                local targetLook = targetRoot.CFrame.LookVector
                                local flatLookVector = Vector3.new(targetLook.X, 0, targetLook.Z).Unit
                                if flatLookVector.Magnitude > 0 then
                                        finalCFrame = CFrame.lookAt(targetPos, targetPos + flatLookVector, worldUpVector)
                                else
                                        finalCFrame = lookAtCF
                                end
                        else
                                finalCFrame = lookAtCF
                        end
                end
        end
        if not finalCFrame then
                finalCFrame = CFrame.lookAt(predictedTargetPosition + Vector3.new(0, 6.8, 0), predictedTargetPosition, worldUpVector)
        end
        return finalCFrame, targetVelocity
end
function getCamLockTarget()
        cam = Workspace.CurrentCamera or cam
        if not cam then
                return nil
        end
        local viewportCenter = cam.ViewportSize / 2
        local mousePosition = UserInputService:GetMouseLocation()
        local bestModel = nil
        local bestDistance = math.huge
        for _, model in ipairs(getSelectableTargetModels()) do
                if not (isTargetBlacklisted and isTargetBlacklisted(model, Players:GetPlayerFromCharacter(model))) then
                        local modelRoot = model:FindFirstChild("HumanoidRootPart")
                        if modelRoot then
                                local screenPoint, visible = cam:WorldToViewportPoint(modelRoot.Position)
                                if visible then
                                        local screenVector = Vector2.new(screenPoint.X, screenPoint.Y)
                                        local centerDistance = (screenVector - viewportCenter).Magnitude
                                        local mouseDistance = (screenVector - mousePosition).Magnitude
                                        local distance = math.min(centerDistance, mouseDistance)
                                        if distance < bestDistance then
                                                bestDistance = distance
                                                bestModel = model
                                        end
                                end
                        end
                end
        end
        if bestDistance > camLockAcquireRadius then
                return nil
        end
        return bestModel
end
function getClosestMouseTarget()
        cam = Workspace.CurrentCamera or cam
        if not cam then
                return nil
        end
        local mousePosition = UserInputService:GetMouseLocation()
        local bestModel = nil
        local bestDistance = math.huge
        for _, model in ipairs(getSelectableTargetModels()) do
                if not (isTargetBlacklisted and isTargetBlacklisted(model, Players:GetPlayerFromCharacter(model))) then
                        local modelRoot = model:FindFirstChild("HumanoidRootPart")
                        if modelRoot then
                                local screenPoint, visible = cam:WorldToViewportPoint(modelRoot.Position)
                                if visible then
                                        local screenVector = Vector2.new(screenPoint.X, screenPoint.Y)
                                        local mouseDistance = (screenVector - mousePosition).Magnitude
                                        if mouseDistance < bestDistance then
                                                bestDistance = mouseDistance
                                                bestModel = model
                                        end
                                end
                        end
                end
        end
        if bestDistance > manualTargetAcquireRadius then
                return nil
        end
        return bestModel
end
function clearManualAttackTpTarget()
        manualAttackTpPlayer = nil
        manualAttackTpTarget = nil
        manualAttackTpTargetName = nil
        pendingTeleportToSelectedPlayer = false
        if syncModelDropdownSelectionToManualTarget then
                syncModelDropdownSelectionToManualTarget()
        end
        syncTargetPickKeybindDisplay()
        updateTargetDisplay()
        return nil
end
function clearCamLockTarget(disableCamLock)
        camLockTarget = nil
        camLockWaiting = false
        if disableCamLock == true then
                camLockEnabled = false
bodyLockEnabled = false
                clearManualAttackTpTarget()
        end
        syncCamLockKeybindDisplay()
        syncTargetPickKeybindDisplay()
        updateTargetDisplay()
        return nil
end
function setManualAttackTpTarget(model, targetPlayer)
        local resolvedTargetPlayer = targetPlayer
        if not isSelectablePlayerDropdownTarget(resolvedTargetPlayer) then
                resolvedTargetPlayer = getSelectablePlayerForTargetModel(model)
        end
        if isSelectablePlayerDropdownTarget(resolvedTargetPlayer) then
                manualAttackTpPlayer = resolvedTargetPlayer
                manualAttackTpTarget = getTrackedPlayerTargetModel(resolvedTargetPlayer)
                manualAttackTpTargetName = nil
        elseif isValidAttackTpTarget(model) then
                manualAttackTpPlayer = nil
                manualAttackTpTarget = model
                manualAttackTpTargetName = model.Name
        else
                manualAttackTpPlayer = nil
                manualAttackTpTarget = nil
                manualAttackTpTargetName = nil
        end
        pendingTeleportToSelectedPlayer = false
        if not isValidAttackTpTarget(camLockTarget) then
                attackTpTarget = resolveManualAttackTpTargetModel()
        end
        if syncModelDropdownSelectionToManualTarget then
                syncModelDropdownSelectionToManualTarget()
        end
        syncTargetPickKeybindDisplay()
        updateTargetDisplay()
        return manualAttackTpTarget
end
function toggleMouseTargetSelection()
        local mouseTarget = getClosestMouseTarget()
        local currentTarget = resolveManualAttackTpTargetModel()
        local currentPlayer = manualAttackTpPlayer
        if hasManualAttackTpSelection() or isWaitingForSelectedTargetRespawn() then
                local clickedSamePlayer = currentPlayer
                        and mouseTarget
                        and getSelectablePlayerForTargetModel(mouseTarget) == currentPlayer
                local clickedSameModel = currentTarget and mouseTarget == currentTarget
                if not isValidAttackTpTarget(mouseTarget) or clickedSamePlayer or clickedSameModel then
                        return clearManualAttackTpTarget()
                end
        end
        return setManualAttackTpTarget(mouseTarget)
end
function toggleCamLock(nextState)
        if nextState == nil then
                camLockEnabled = not camLockEnabled
        else
                camLockEnabled = nextState
        end
        if camLockEnabled or bodyLockEnabled then
                camLockTarget = getCamLockTarget()
                camLockWaiting = camLockTarget == nil
                if camLockTarget then
                        local camLockPlayer = Players:GetPlayerFromCharacter(camLockTarget)
                        if isSelectablePlayerDropdownTarget(camLockPlayer) then
                                manualAttackTpPlayer = camLockPlayer
                                manualAttackTpTarget = camLockTarget
                                if syncModelDropdownSelectionToManualTarget then
                                        syncModelDropdownSelectionToManualTarget()
                                end
                        end
                end
        else
                camLockTarget = nil
                camLockWaiting = false
                clearManualAttackTpTarget()
        end
        syncCamLockKeybindDisplay()
        syncBodyLockKeybindDisplay()
        syncComboLockKeybindDisplay()
        syncTargetPickKeybindDisplay()
        updateTargetDisplay()
        return camLockEnabled and "ON" or "OFF"
end
function toggleAttackTp(nextState)
        local shouldEnable = nextState
        local nextTarget = nil
        if shouldEnable == nil then
                shouldEnable = not attackTpEnabled
        end
        if shouldEnable then
                nextTarget = getPreferredAttackTpTarget()
        end
        attackTpEnabled = shouldEnable == true
        if attackTpEnabled then
                attackTpTarget = nextTarget
        else
                attackTpTarget = nil
        end
        syncAttackTpKeybindDisplay()
        updateTargetDisplay()
        syncTargetActionControls()
        return attackTpEnabled and "ON" or "OFF"
end
function getMovementInput()
        local z = (UserInputService:IsKeyDown(Enum.KeyCode.W) and 1 or 0) - (UserInputService:IsKeyDown(Enum.KeyCode.S) and 1 or 0)
        local x = (UserInputService:IsKeyDown(Enum.KeyCode.D) and 1 or 0) - (UserInputService:IsKeyDown(Enum.KeyCode.A) and 1 or 0)
        return z, x
end
function setSettingsVisible(visible)
        if not settingsWindow or not windowOutline then return end
        settingsOpen = visible
        settingsWindow.Visible = visible
        windowOutline.Visible = visible
        if visible then
                local animVal = settingsWindow:FindFirstChild("WindowAnimScale")
                if animVal then
                        animVal.Value = 1.0
                end
                settingsWindow.BackgroundTransparency = 0.18
                if settingsStroke then settingsStroke.Transparency = 0.05 end
                if windowOutlineStroke then windowOutlineStroke.Transparency = 0.05 end
        else
                settingsWindow.BackgroundTransparency = 1
                if settingsStroke then settingsStroke.Transparency = 1 end
                if windowOutlineStroke then windowOutlineStroke.Transparency = 1 end
        end
end
function applySliderValue(state, rawValue, triggerCallback)
        local minValue = tonumber(state.min) or 0
        local maxValue = math.max(minValue, tonumber(state.max) or 100)
        local clamped = math.clamp(roundToTenth(tonumber(rawValue) or minValue), minValue, maxValue)
        local displayValue = roundToTenth(clamped)
        state.value = clamped
        if state.valueLabel then
                if tostring(state.showName or "") ~= "" then
                        state.valueLabel.Text = string.format("%s: %.1f", state.showName, displayValue)
                else
                        state.valueLabel.Text = string.format("%.1f", displayValue)
                end
        end
        if state.editBox then
                state.editBox.Text = string.format("%.1f", displayValue)
        end
        state.fill.Size = UDim2.new((clamped - minValue) / math.max(maxValue - minValue, 0.001), 0, 1, 0)
        if state.saveKey then
                setSavedControlValue(state.saveKey, clamped)
        end
        if (triggerCallback or state.applyCallbackOnLoad) and state.callback then
                state.callback(clamped)
        end
end
function makeControlFrame(heightScale)
        local holder = Instance.new("Frame")
        holder.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
        holder.BackgroundTransparency = 0.4
        holder.Size = UDim2.new(1, -4, 0, heightScale)
        holder.BorderSizePixel = 0
        holder.Active = true
        holder.ClipsDescendants = true
        local cfCorner = Instance.new("UICorner")
        cfCorner.CornerRadius = UDim.new(0, 4)
        cfCorner.Parent = holder
        local cfGradient = Instance.new("UIGradient")
        cfGradient.Color = ColorSequence.new(Color3.fromRGB(20, 20, 20), Color3.fromRGB(20, 20, 20))
        cfGradient.Rotation = 0
        cfGradient.Parent = holder
        local cfStroke = Instance.new("UIStroke")
        cfStroke.Color = Color3.fromRGB(255, 255, 255)
        cfStroke.Thickness = 1
        cfStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
        cfStroke.LineJoinMode = Enum.LineJoinMode.Round
        cfStroke.Parent = holder
        return holder
end
function showInfo(title, text, time)
        if not introFinished then
                pendingInfoCall = {
                        title = title,
                        text = text,
                        time = time,
                }
                return
        end
        showExistingGuiInfo(screenGui, title, text, time)
end
function INFO(title, text, time)
        if not introFinished then
                pendingInfoCall = {
                        title = title,
                        text = text,
                        time = time,
                }
                return
        end
        showInfo(title, text, time)
end
local SeriousModeTrackerEnabled = false
SeriousModeTrackerActive = false
local SM_playerState = {}
local SM_activeTimers = {}
local SM_playerConnections = {}
local SM_PlayersAddedConn = nil
function toggleSeriousModeTrackerInternal(state)
        SeriousModeTrackerActive = state == true
        local Players = game:GetService("Players")
        local SERIOUS_MODE_STATE_ATTRIBUTE = "NX_SeriousModeState"
        if not SeriousModeTrackerActive then
                if SM_PlayersAddedConn then SM_PlayersAddedConn:Disconnect(); SM_PlayersAddedConn = nil end
                for plr, tracker in pairs(SM_playerConnections) do
                        if tracker and tracker.Disconnect then
                                pcall(function() tracker.Disconnect() end)
                        end
                end
                SM_playerConnections = {}
                SM_playerState = {}
                for _, plr in ipairs(Players:GetPlayers()) do
                        local char = plr.Character
                        if char then
                                if char:GetAttribute(SERIOUS_MODE_STATE_ATTRIBUTE) ~= nil then
                                        char:SetAttribute(SERIOUS_MODE_STATE_ATTRIBUTE, nil)
                                end
                        end
                end
                return
        end
        local SHARED_HIGHLIGHT_NAME = "NOTHING-X"
        local strongSkills = {
                ["Omni Directional Punch"] = true,
                ["Death Counter"] = true,
                ["Serious Punch"] = true,
                ["Table Flip"] = true
        }
        local weakSkills = {
                ["Consecutive Punches"] = true,
                ["Normal Punch"] = true,
                ["Shove"] = true,
                ["Uppercut"] = true
        }
        local function callInfo(title, text, duration)
                if type(INFO) == "function" then
                        pcall(function() INFO(title, text, duration or 5) end)
                end
        end
        local function getSkillType(backpack, character)
                if backpack then
                        for _, tool in ipairs(backpack:GetChildren()) do
                                if strongSkills[tool.Name] then return "strong" end
                                if weakSkills[tool.Name] then return "weak" end
                        end
                end
                if character then
                        for _, tool in ipairs(character:GetChildren()) do
                                if tool:IsA("Tool") then
                                        if strongSkills[tool.Name] then return "strong" end
                                        if weakSkills[tool.Name] then return "weak" end
                                end
                        end
                end
                return nil
        end
        local function updatePlayer(plr)
                local char = plr.Character
                if not char then return end
                local backpack = plr:FindFirstChild("Backpack")
                local humanoid = char:FindFirstChildOfClass("Humanoid")
                if not humanoid or humanoid.Health <= 0 then
                        SM_playerState[plr] = nil
                        if char:GetAttribute(SERIOUS_MODE_STATE_ATTRIBUTE) ~= nil then
                                char:SetAttribute(SERIOUS_MODE_STATE_ATTRIBUTE, nil)
                                pcall(updatePlayerOverlay, plr)
                        end
                        return
                end
                local skill = getSkillType(backpack, char)
                local currentState = SM_playerState[plr]
                if skill == "strong" and currentState ~= "strong" then
                        SM_playerState[plr] = "strong"
                        char:SetAttribute(SERIOUS_MODE_STATE_ATTRIBUTE, "strong")
                        pcall(updatePlayerOverlay, plr)
                        callInfo("SERIOUS MODE", plr.Name .. " - ACTIVE", 5)
                elseif currentState == "strong" and skill ~= "strong" then
                        SM_playerState[plr] = "weak"
                        char:SetAttribute(SERIOUS_MODE_STATE_ATTRIBUTE, "weak")
                        pcall(updatePlayerOverlay, plr)
                        callInfo("SERIOUS MODE", plr.Name .. " - DEATH", 7)
                        local timerId = tick()
                        SM_activeTimers[plr] = timerId
                        task.delay(9.45, function()
                                if SM_activeTimers[plr] == timerId and SM_playerState[plr] == "weak" then
                                        SM_playerState[plr] = nil
                                        if char and char.Parent then
                                                if char:GetAttribute(SERIOUS_MODE_STATE_ATTRIBUTE) ~= nil then
                                                        char:SetAttribute(SERIOUS_MODE_STATE_ATTRIBUTE, nil)
                                                        pcall(updatePlayerOverlay, plr)
                                                end
                                        end
                                        callInfo("SERIOUS MODE", plr.Name .. " - END", 5)
                                end
                        end)
                end
        end
        local function startGlobalChecker()
                task.spawn(function()
                        local lastCheck = 0
                        while SeriousModeTrackerActive do
                                local now = tick()
                                if now - lastCheck >= 0.15 then
                                        lastCheck = now
                                        for _, plr in ipairs(Players:GetPlayers()) do
                                                if plr ~= Players.LocalPlayer then
                                                        pcall(updatePlayer, plr)
                                                end
                                        end
                                end
                                task.wait()
                        end
                end)
        end
        local function setupPlayer(plr)
                if plr == Players.LocalPlayer then return end
                local playerConns = {}
                local charConns = {}
                local function disconnectCharConnections()
                        for _, conn in ipairs(charConns) do
                                if conn and conn.Disconnect then conn:Disconnect() end
                        end
                        table.clear(charConns)
                end
                local function disconnectAllConnections()
                        disconnectCharConnections()
                        for _, conn in ipairs(playerConns) do
                                if conn and conn.Disconnect then conn:Disconnect() end
                        end
                        table.clear(playerConns)
                        SM_playerConnections[plr] = nil
                end
                SM_playerConnections[plr] = {
                        Disconnect = disconnectAllConnections
                }
                local function onCharacterAdded(char)
                        SM_playerState[plr] = nil
                        if char and char.Parent then
                                if char:GetAttribute(SERIOUS_MODE_STATE_ATTRIBUTE) ~= nil then
                                        char:SetAttribute(SERIOUS_MODE_STATE_ATTRIBUTE, nil)
                                end
                        end
                        disconnectCharConnections()
                        task.spawn(function()
                                local backpack = plr:WaitForChild("Backpack", 10)
                                if not backpack or plr.Character ~= char then return end
                                local cAdded = backpack.ChildAdded:Connect(function()
                                        task.defer(function()
                                                if plr.Parent and SeriousModeTrackerActive then updatePlayer(plr) end
                                        end)
                                end)
                                local cRemoved = backpack.ChildRemoved:Connect(function()
                                        task.defer(function()
                                                if plr.Parent and SeriousModeTrackerActive then updatePlayer(plr) end
                                        end)
                                end)
                                local charAdded = char.ChildAdded:Connect(function(child)
                                        if child:IsA("Tool") then
                                                task.defer(function()
                                                        if plr.Parent and SeriousModeTrackerActive then updatePlayer(plr) end
                                                end)
                                        end
                                end)
                                local charRemoved = char.ChildRemoved:Connect(function(child)
                                        if child:IsA("Tool") then
                                                task.defer(function()
                                                        if plr.Parent and SeriousModeTrackerActive then updatePlayer(plr) end
                                                end)
                                        end
                                end)
                                table.insert(charConns, cAdded)
                                table.insert(charConns, cRemoved)
                                table.insert(charConns, charAdded)
                                table.insert(charConns, charRemoved)
                                local hum = char:FindFirstChildOfClass("Humanoid") or char:WaitForChild("Humanoid", 5)
                                if hum and plr.Character == char then
                                        local diedConn = hum.Died:Connect(function()
                                                SM_playerState[plr] = nil
                                                if char and char.Parent then
                                                        if char:GetAttribute(SERIOUS_MODE_STATE_ATTRIBUTE) ~= nil then
                                                                char:SetAttribute(SERIOUS_MODE_STATE_ATTRIBUTE, nil)
                                                        end
                                                end
                                        end)
                                        table.insert(charConns, diedConn)
                                end
                                if SeriousModeTrackerActive then updatePlayer(plr) end
                        end)
                end
                if plr.Character then onCharacterAdded(plr.Character) end
                local cAdded = plr.CharacterAdded:Connect(onCharacterAdded)
                local aChanged = plr.AncestryChanged:Connect(function(_, parent)
                        if parent == nil then
                                disconnectAllConnections()
                                SM_playerState[plr] = nil
                        end
                end)
                table.insert(playerConns, cAdded)
                table.insert(playerConns, aChanged)
        end
        startGlobalChecker()
        for _, plr in ipairs(Players:GetPlayers()) do
                setupPlayer(plr)
        end
        SM_PlayersAddedConn = Players.PlayerAdded:Connect(setupPlayer)
end
function syncSeriousModeTracker()
        local shouldActive = SeriousModeTrackerEnabled or espOverlayConfig.showDeath
        toggleSeriousModeTrackerInternal(shouldActive)
end
function toggleSeriousModeTracker(state)
        SeriousModeTrackerEnabled = state == true
        syncSeriousModeTracker()
end
local CharacterCleanupEnabled = false
local antiZeroEnabled = false
local ModConnections = {}
local _nxDefenseActing = false
local _nxDefenseActingUntil = 0
local function _nxMarkDefenseActing()
        _nxDefenseActing = true
        _nxDefenseActingUntil = os.clock() + 0.18
        task.delay(0.2, function()
                if os.clock() >= _nxDefenseActingUntil then
                        _nxDefenseActing = false
                end
        end)
end
local function _nxIsDefenseActing()
        if _nxDefenseActing and os.clock() < _nxDefenseActingUntil then
                return true
        end
        _nxDefenseActing = false
        return false
end
local hooksRegistered = false
local lastLocalActionTime = 0
local lastQActionType = nil
local flyLockedPosition = nil
local characterMotor6DsByChar = {}
local _cleanupDescConn = nil
local _cleanupHumanoidConns = {}
local function _isBadMover(v)
        if v:GetAttribute("IsLocalMover") then return false end
        local name = v.Name
        if name == "moveme" or name == "dodgevelocity" then
                local isDashing = (os.clock() - lastLocalActionTime < dashBypassDuration)
                if isDashing and lastQActionType == name then return false end
        end
        return v:IsA("BodyVelocity") or v:IsA("BodyAngularVelocity")
                or v:IsA("LinearVelocity") or v:IsA("AngularVelocity")
                or v:IsA("BodyPosition") or v:IsA("BodyGyro")
                or v:IsA("VectorForce") or v:IsA("AlignPosition")
                or v:IsA("AlignOrientation")
end
local _badValueClasses = {
        BoolValue = true,
        CFrameValue = true,
        Color3Value = true,
        DoubleConstrainedValue = true,
        IntConstrainedValue = true,
        IntValue = true,
        NumberValue = true,
        ObjectValue = true,
        RayValue = true,
		WeldConstraint = true,
		Weld = true,
		ManualWeld = true,
        Vector3Value = true,
        ForceField = true,
        StringValue = true,
        Glue = true,
        Snap = true,
        RigidConstraint = true,
        HingeConstraint = true,
        SpringConstraint = true,
        RocketPropulsion = true,
        BodyThrust = true,
        BodyForce = true,
}
local function _isBadWeld(v, char)
        if not (v:IsA("WeldConstraint") or v:IsA("Weld") or v:IsA("ManualWeld") or v:IsA("Glue") or v:IsA("Snap")) then return false end
        local p0, p1 = v.Part0, v.Part1
        local extP0 = p0 and not p0:IsDescendantOf(char)
        local extP1 = p1 and not p1:IsDescendantOf(char)
        return extP0 or extP1
end
local function _isProtectedWeld(v, char)
        if not char then return false end
        local p0, p1
        if v:IsA("RigidConstraint") then
                local ok0, a0 = pcall(function() return v.Attachment0 end)
                local ok1, a1 = pcall(function() return v.Attachment1 end)
                p0 = ok0 and a0 and a0.Parent
                p1 = ok1 and a1 and a1.Parent
        else
                local ok0, part0 = pcall(function() return v.Part0 end)
                local ok1, part1 = pcall(function() return v.Part1 end)
                p0 = ok0 and part0
                p1 = ok1 and part1
        end
        if p0 and p0:IsA("MeshPart") then return true end
        if p1 and p1:IsA("MeshPart") then return true end
        if v.Parent and v.Parent:IsA("MeshPart") then return true end
        local ancestor = v.Parent
        while ancestor and ancestor ~= char do
                if ancestor:IsA("Model") then return true end
                ancestor = ancestor.Parent
        end
        for _, part in ipairs({p0, p1}) do
                if part then
                        local anc = part.Parent
                        while anc and anc ~= char do
                                if anc:IsA("Model") then return true end
                                anc = anc.Parent
                        end
                end
        end
        return false
end
local function _handleNewDesc(v, char)
        if v:IsA("BodyVelocity") then
                local name = v.Name
                local isDashing = (os.clock() - lastLocalActionTime < dashBypassDuration)
                if isDashing and lastQActionType == name then
                        if name == "moveme" then
                                pcall(function()
                                        v.MaxForce = Vector3.new(40000, 0, 40000)
                                        v.P = 1250
                                        v:SetAttribute("Fallout", 0.95)
                                end)
                                return
                        elseif name == "dodgevelocity" then
                                pcall(function()
                                        v.MaxForce = Vector3.new(50000, 0, 50000)
                                        v.P = 1250
                                end)
                                return
                        end
                end
        end
        if not CharacterCleanupEnabled and not antiZeroEnabled then return end
        local isSelfFlinging = walkFlingEnabled or flingEnabled or clickFlingEnabled or auraFlingEnabled or flingAllEnabled
        if isSelfFlinging then return end
        if antiZeroEnabled then
                if _isBadMover(v) then
                        pcall(function() v:Destroy() end)
                        local hrp = char:FindFirstChild("HumanoidRootPart")
                        if hrp then
                                hrp.AssemblyLinearVelocity  = Vector3.zero
                                hrp.AssemblyAngularVelocity = Vector3.zero
                                _nxMarkDefenseActing()
                                pcall(function() hrp:SetAttribute("IsTrashOperation", true) end)
                                task.delay(0.15, function()
                                        pcall(function()
                                                if hrp and hrp.Parent then
                                                        hrp:SetAttribute("IsTrashOperation", false)
                                                end
                                        end)
                                end)
                        end
                        return
                end
                if _isBadWeld(v, char) or v:IsA("RigidConstraint") then
                        if not _isProtectedWeld(v, char) then
                                pcall(function() v:Destroy() end)
                                _nxMarkDefenseActing()
                        end
                        return
                end
                local cn = v.ClassName
                if _badValueClasses[cn] then
                        local par = v.Parent
                        if par and (par:IsA("Script") or par:IsA("LocalScript") or par:IsA("ModuleScript")) then return end
                        if cn == "ObjectValue" and v.Name == "WallCombo" then
                        elseif (cn == "WeldConstraint" or cn == "Weld" or cn == "ManualWeld" or cn == "RigidConstraint" or cn == "Glue" or cn == "Snap") and _isProtectedWeld(v, char) then
                        else
                                pcall(function() v:Destroy() end)
                        end
                        return
                end
        end
        if CharacterCleanupEnabled then
                if v:IsA("BallSocketConstraint") or v:IsA("NoCollisionConstraint") then
                        pcall(function() v:Destroy() end)
                        _nxMarkDefenseActing()
                        local hrp2 = char and char:FindFirstChild("HumanoidRootPart")
                        if hrp2 then
                                pcall(function() hrp2:SetAttribute("IsTrashOperation", true) end)
                                task.delay(0.15, function()
                                        pcall(function()
                                                if hrp2 and hrp2.Parent then
                                                        hrp2:SetAttribute("IsTrashOperation", false)
                                                end
                                        end)
                                end)
                        end
                end
        end
end
local function _setupHumanoidEvents(char)
        for _, c in ipairs(_cleanupHumanoidConns) do pcall(function() c:Disconnect() end) end
        _cleanupHumanoidConns = {}
        local human = char:FindFirstChildOfClass("Humanoid")
        if not human then return end
        local function fixPlatformStand()
                if CharacterCleanupEnabled and human and human.Parent then
                        if human.PlatformStand then human.PlatformStand = false end
                end
        end
        table.insert(_cleanupHumanoidConns, human:GetPropertyChangedSignal("PlatformStand"):Connect(fixPlatformStand))
end
local function _bindCleanupEvents(char)
        if _cleanupDescConn then pcall(function() _cleanupDescConn:Disconnect() end) end
        _cleanupDescConn = char.DescendantAdded:Connect(function(v)
                task.defer(function()
                        if v and v.Parent then
                                _handleNewDesc(v, char)
                        end
                end)
        end)
        for _, v in ipairs(char:GetDescendants()) do
                _handleNewDesc(v, char)
        end
        _setupHumanoidEvents(char)
        char.ChildAdded:Connect(function(child)
                if child:IsA("Humanoid") then
                        _setupHumanoidEvents(char)
                end
        end)
end
local function _cleanBadValues(char)
        if not char then return end
        for _, part in ipairs(char:GetDescendants()) do
                local cn = part.ClassName
                if _badValueClasses[cn] then
                        local par = part.Parent
                        if par and (par:IsA("Script") or par:IsA("LocalScript") or par:IsA("ModuleScript")) then continue end
                        if cn == "ObjectValue" and part.Name == "WallCombo" then continue end
                        if cn == "WeldConstraint" or cn == "Weld" or cn == "ManualWeld" or cn == "RigidConstraint" or cn == "Glue" or cn == "Snap" then
                                if _isProtectedWeld(part, char) then continue end
                        end
                        pcall(function() part:Destroy() end)
                end
        end
end
local function runCleanupTick(char)
	local isSelfFlinging = walkFlingEnabled or flingEnabled or clickFlingEnabled or auraFlingEnabled or flingAllEnabled
	if isSelfFlinging then return end
	if not char then return end
	if antiZeroEnabled then
		local humanoid = char:FindFirstChildOfClass("Humanoid")
		local animator = humanoid and humanoid:FindFirstChildOfClass("Animator")
		if animator then
			for _, track in ipairs(animator:GetPlayingAnimationTracks()) do
				if _isGrabAnim and _isGrabAnim(track.Name) then
					pcall(function() track:Stop(0) end)
				end
			end
		end
		_cleanBadValues(char)
	end
	if CharacterCleanupEnabled then
		local myMotor6Ds = characterMotor6DsByChar[char]
		if myMotor6Ds then
			for i = 1, #myMotor6Ds do
				local m = myMotor6Ds[i]
				if m and m.Parent and not m.Enabled then
					pcall(function() m.Enabled = true end)
				end
			end
		end
	end
end
local _antiZeroCharAddedConn = nil
local _antiZeroGlobalHeartbeat = nil
function toggleAntiZero(state)
        antiZeroEnabled = state == true
        if _antiZeroCharAddedConn then
                pcall(function() _antiZeroCharAddedConn:Disconnect() end)
                _antiZeroCharAddedConn = nil
        end
        if _antiZeroGlobalHeartbeat then
                pcall(function() _antiZeroGlobalHeartbeat:Disconnect() end)
                _antiZeroGlobalHeartbeat = nil
        end
        if antiZeroEnabled then
                local lp = game:GetService("Players").LocalPlayer
                task.spawn(function()
                        while antiZeroEnabled do
                                pcall(function() runCleanupTick(lp.Character) end)
                                RunService.Heartbeat:Wait()
                        end
                end)
                _antiZeroCharAddedConn = lp.CharacterAdded:Connect(function(char)
                        if not antiZeroEnabled then return end
                        task.spawn(function()
                                task.wait(0.25)
                                if antiZeroEnabled and char and char.Parent then
                                        _bindCleanupEvents(char)
                                end
                        end)
                end)
        end
end
local antiGrabEnabled   = false
local antiGrabZeroEnabled = false
local _grabAnimConns    = {}
local _grabCharConn     = nil
local _grabCharAddedConn = nil
local _grabZeroCharAddedConn = nil
local function _isGrabAnim(name)
        local low = name:lower()
        return low:find("grab") or low:find("caught") or low:find("held")
                or low:find("carry") or low:find("drag") or low:find("grapple")
                or low:find("push") or low:find("shove") or low:find("knockback")
                or low:find("knock") or low:find("flung") or low:find("launch")
                or low:find("throw") or low:find("slam") or low:find("bump")
                or low:find("stun") or low:find("ragdoll") or low:find("trip")
                or low:find("toss") or low:find("airborne") or low:find("impact")
end
local function _killGrabTrack(track, char)
        pcall(function() track:Stop(0) end)
        if antiGrabZeroEnabled and char then
                local hrp = char:FindFirstChild("HumanoidRootPart")
                if hrp then
                        hrp.AssemblyLinearVelocity  = Vector3.zero
                        hrp.AssemblyAngularVelocity = Vector3.zero
                end
        end
end
local function _setupGrabOnChar(char)
        for _, c in ipairs(_grabAnimConns) do pcall(function() c:Disconnect() end) end
        _grabAnimConns = {}
        if _grabCharConn then pcall(function() _grabCharConn:Disconnect() end) end
        if not char then return end
        local function watchAnimator(animator)
                if not animator then return end
                local conn = animator.AnimationPlayed:Connect(function(track)
                        if not (antiGrabEnabled or antiGrabZeroEnabled) then return end
                        if _isGrabAnim(track.Name) then
                                _killGrabTrack(track, char)
                        end
                end)
                table.insert(_grabAnimConns, conn)
                for _, track in ipairs(animator:GetPlayingAnimationTracks()) do
                        if _isGrabAnim(track.Name) then
                                _killGrabTrack(track, char)
                        end
                end
        end
        local function findAndWatchAnimator()
                local hum = char:FindFirstChildOfClass("Humanoid")
                if hum then
                        local anim = hum:FindFirstChildOfClass("Animator")
                        if anim then
                                watchAnimator(anim)
                        else
                                local c = hum.ChildAdded:Connect(function(child)
                                        if child:IsA("Animator") then
                                                watchAnimator(child)
                                        end
                                end)
                                table.insert(_grabAnimConns, c)
                        end
                end
        end
        findAndWatchAnimator()
        _grabCharConn = char.ChildAdded:Connect(function(child)
                if child:IsA("Humanoid") then
                        findAndWatchAnimator()
                end
        end)
end
function toggleAntiGrab(state)
        antiGrabEnabled = state == true
        if _grabCharAddedConn then pcall(function() _grabCharAddedConn:Disconnect() end); _grabCharAddedConn = nil end
        if antiGrabEnabled then
                local lp = game:GetService("Players").LocalPlayer
                if lp.Character then _setupGrabOnChar(lp.Character) end
                _grabCharAddedConn = lp.CharacterAdded:Connect(function(char)
                        task.wait()
                        if antiGrabEnabled or antiGrabZeroEnabled then
                                _setupGrabOnChar(char)
                        end
                end)
        else
                if not antiGrabZeroEnabled then
                        for _, c in ipairs(_grabAnimConns) do pcall(function() c:Disconnect() end) end
                        _grabAnimConns = {}
                        if _grabCharConn then pcall(function() _grabCharConn:Disconnect() end); _grabCharConn = nil end
                end
        end
end
function toggleAntiGrabZero(state)
        antiGrabZeroEnabled = state == true
        if _grabZeroCharAddedConn then pcall(function() _grabZeroCharAddedConn:Disconnect() end); _grabZeroCharAddedConn = nil end
        if antiGrabZeroEnabled then
                local lp = game:GetService("Players").LocalPlayer
                if lp.Character then _setupGrabOnChar(lp.Character) end
                _grabZeroCharAddedConn = lp.CharacterAdded:Connect(function(char)
                        task.wait()
                        if antiGrabEnabled or antiGrabZeroEnabled then
                                _setupGrabOnChar(char)
                        end
                end)
        else
                if not antiGrabEnabled then
                        for _, c in ipairs(_grabAnimConns) do pcall(function() c:Disconnect() end) end
                        _grabAnimConns = {}
                        if _grabCharConn then pcall(function() _grabCharConn:Disconnect() end); _grabCharConn = nil end
                end
        end
end
local _noTpEnabled = false
local _noTpCharConn = nil
local _noTpHeartbeat = nil
local _noTpLastCF = nil
local _noTpStopRevert = false
local _noTpLastPriority = 99
local _noTpLastPriorityTick = 0
_G.NX_TP = function(targetCFrame, sourceName, priority)
    priority = priority or 5
    if priority > _noTpLastPriority and tick() - _noTpLastPriorityTick < 0.1 then
        return false
    end
    _noTpLastPriority = priority
    _noTpLastPriorityTick = tick()
    local plr = game:GetService("Players").LocalPlayer
    local char = plr.Character
    local hrp = char and char:FindFirstChild("HumanoidRootPart")
    if not hrp then return false end
    if targetCFrame.X ~= targetCFrame.X or targetCFrame.Y ~= targetCFrame.Y or targetCFrame.Z ~= targetCFrame.Z then
        return false
    end
    _noTpStopRevert = true
    hrp:SetAttribute("IsAttackTP", true)
    _noTpLastCF = targetCFrame
    hrp.CFrame = targetCFrame
    task.delay(0, function()
        if hrp and hrp.Parent then
            hrp:SetAttribute("IsAttackTP", false)
        end
        _noTpStopRevert = false
    end)
    return true
end
local function _noTpStop()
    _noTpEnabled = false
    _noTpLastCF = nil
    if _noTpHeartbeat then pcall(function() _noTpHeartbeat:Disconnect() end); _noTpHeartbeat = nil end
end
local function _noTpStart()
    _noTpStop()
    _noTpEnabled = true
    local lp = game:GetService("Players").LocalPlayer
    local char = lp.Character
    if not char then return end
    local humanoid = char:FindFirstChildOfClass("Humanoid")
    if not humanoid then return end
    local rootPart = humanoid.RootPart
    if not rootPart then return end
    _noTpLastCF = rootPart.CFrame
    
    local function revertTp()
        _noTpStopRevert = true
        pcall(function()
            rootPart.Anchored = false
            humanoid.Sit = false
            rootPart.CFrame = _noTpLastCF
            char:PivotTo(_noTpLastCF)
            rootPart.AssemblyLinearVelocity = Vector3.zero
            rootPart.AssemblyAngularVelocity = Vector3.zero
        end)
        game:GetService("RunService").Heartbeat:Wait()
        _noTpStopRevert = false
    end

    _noTpHeartbeat = game:GetService("RunService").Heartbeat:Connect(function()
        if not _noTpEnabled or not rootPart or not rootPart.Parent then return end
        if _noTpStopRevert or rootPart:GetAttribute("IsAttackTP") or _G.BypassNoTp then
            _noTpLastCF = rootPart.CFrame
            return
        end
        if _noTpLastCF then
            local dist = (rootPart.Position - _noTpLastCF.Position).Magnitude
            if dist > 35 then
                revertTp()
                return
            end
        end
        _noTpLastCF = rootPart.CFrame
    end)
    
    local torso = char:FindFirstChild("Torso") or char:FindFirstChild("LowerTorso")
    local function hookPart(part)
        if not part then return end
        part:GetPropertyChangedSignal("CFrame"):Connect(function()
            if not _noTpEnabled or _noTpStopRevert or rootPart:GetAttribute("IsAttackTP") or _G.BypassNoTp then return end
            revertTp()
        end)
        part:GetPropertyChangedSignal("Position"):Connect(function()
            if not _noTpEnabled or _noTpStopRevert or rootPart:GetAttribute("IsAttackTP") or _G.BypassNoTp then return end
            revertTp()
        end)
    end
    
    hookPart(rootPart)
    hookPart(torso)
    
    humanoid.Died:Connect(function()
        _noTpStop()
    end)
end
local _antiVoidEnabled = false
local _antiVoidHeartbeat = nil
local _antiVoidLastSafeCF = nil
local _antiVoidCharConn = nil
local function isPointSafe(pos)
    local rayOrigin = pos
    local rayDirection = Vector3.new(0, -15, 0)
    local raycastParams = RaycastParams.new()
    local char = game:GetService("Players").LocalPlayer.Character
    local trash = workspace:FindFirstChild("Map") and workspace.Map:FindFirstChild("Trash")
    local ignoreList = {}
    if char then table.insert(ignoreList, char) end
    if trash then table.insert(ignoreList, trash) end
    raycastParams.FilterDescendantsInstances = ignoreList
    raycastParams.FilterType = Enum.RaycastFilterType.Exclude
    local raycastResult = workspace:Raycast(rayOrigin, rayDirection, raycastParams)
    return raycastResult ~= nil
end
local _antiVoidPart = nil
local function _antiVoidStart()
    if _antiVoidHeartbeat then pcall(function() _antiVoidHeartbeat:Disconnect() end) end
    _antiVoidEnabled = true
    _antiVoidHeartbeat = game:GetService("RunService").Heartbeat:Connect(function()
        local lp = game:GetService("Players").LocalPlayer
        local char = lp.Character
        local hrp = char and char:FindFirstChild("HumanoidRootPart")
        if not hrp then return end
        
        local destroyHeight = workspace.FallenPartsDestroyHeight + 50
        
        if not _antiVoidPart or not _antiVoidPart.Parent then
            _antiVoidPart = Instance.new("Part")
            _antiVoidPart.Name = "NX_AntiVoid_Boundary"
            _antiVoidPart.Size = Vector3.new(2048, 5, 2048)
            _antiVoidPart.Anchored = true
            _antiVoidPart.CanCollide = true
            _antiVoidPart.Transparency = 1
            _antiVoidPart.Parent = workspace
        end
        
        _antiVoidPart.Position = Vector3.new(hrp.Position.X, destroyHeight - 2.5, hrp.Position.Z)
        
        if isPointSafe(hrp.Position) then
            _antiVoidLastSafeCF = hrp.CFrame
        end
        if hrp.Position.Y < destroyHeight - 5 then
            if _antiVoidLastSafeCF then
                _G.NX_TP(_antiVoidLastSafeCF, "Anti-Void", 1)
                hrp.AssemblyLinearVelocity = Vector3.zero
                hrp.AssemblyAngularVelocity = Vector3.zero
            else
                _G.NX_TP(CFrame.new(hrp.Position.X, destroyHeight + 50, hrp.Position.Z), "Anti-Void", 1)
                hrp.AssemblyLinearVelocity = Vector3.zero
                hrp.AssemblyAngularVelocity = Vector3.zero
            end
        end
    end)
end
local function _antiVoidStop()
    _antiVoidEnabled = false
    if _antiVoidHeartbeat then pcall(function() _antiVoidHeartbeat:Disconnect() end); _antiVoidHeartbeat = nil end
    if _antiVoidPart then pcall(function() _antiVoidPart:Destroy() end); _antiVoidPart = nil end
end
function toggleAntiVoid(state)
    if state then
        _antiVoidStart()
        local lp = game:GetService("Players").LocalPlayer
        if _antiVoidCharConn then pcall(function() _antiVoidCharConn:Disconnect() end) end
        _antiVoidCharConn = lp.CharacterAdded:Connect(function(char)
            if not _antiVoidEnabled then return end
            _antiVoidLastSafeCF = nil
        end)
    else
        _antiVoidStop()
        if _antiVoidCharConn then pcall(function() _antiVoidCharConn:Disconnect() end); _antiVoidCharConn = nil end
    end
end
function toggleNoTp(state)
    if state then
        local lp = game:GetService("Players").LocalPlayer
        if _noTpCharConn then pcall(function() _noTpCharConn:Disconnect() end); _noTpCharConn = nil end
        _noTpCharConn = lp.CharacterAdded:Connect(function(char)
            if not _noTpEnabled and not state then return end
            repeat game:GetService("RunService").Heartbeat:Wait() until char:FindFirstChildOfClass("Humanoid")
            repeat game:GetService("RunService").Heartbeat:Wait() until char:FindFirstChildOfClass("Humanoid").RootPart
            if _noTpEnabled or state then _noTpStart() end
        end)
        _noTpStart()
    else
        _noTpStop()
        if _noTpCharConn then pcall(function() _noTpCharConn:Disconnect() end); _noTpCharConn = nil end
    end
end
if hookmetamethod then
    local oldNamecall
    oldNamecall = hookmetamethod(game, "__namecall", newcclosure(function(self, ...)
        local method = getnamecallmethod()
        if method == "FireServer" and _noTpEnabled and typeof(self) == "Instance" and self.ClassName == "UnreliableRemoteEvent" and string.find(self.Name, "replicatemovement") then
            local args = {...}
            if typeof(args[1]) == "CFrame" and _noTpLastCF then
                return oldNamecall(self, _noTpLastCF)
            end
        end
        return oldNamecall(self, ...)
    end))
end
local NoDashCDEnabled = false
local noDashCDHeartbeat = nil
local noDashCDCharConn = nil
local _origForwardCD = nil
local _origSideCD = nil
local _origNoDashCooldown = nil
local _origEffectAffects = nil
local _gcUpvalueTable = nil
local function enforceDash(char)
        if not char then return end
        char:SetAttribute("CustomForwardDashCooldown", 0)
        char:SetAttribute("CustomSideDashCooldown", 0)
end
local function restoreChar(char)
        if not char then return end
        if _origForwardCD ~= nil then
                char:SetAttribute("CustomForwardDashCooldown", _origForwardCD)
        else
                char:SetAttribute("CustomForwardDashCooldown", nil)
        end
        if _origSideCD ~= nil then
                char:SetAttribute("CustomSideDashCooldown", _origSideCD)
        else
                char:SetAttribute("CustomSideDashCooldown", nil)
        end
end
function toggleNoDashCD(state)
        NoDashCDEnabled = state == true
        if noDashCDHeartbeat then
                pcall(function() noDashCDHeartbeat:Disconnect() end)
                noDashCDHeartbeat = nil
        end
        if noDashCDCharConn then
                pcall(function() noDashCDCharConn:Disconnect() end)
                noDashCDCharConn = nil
        end
        local lp = Players.LocalPlayer
        if NoDashCDEnabled then
                local rawNoDash = workspace:GetAttribute("NoDashCooldown")
                local rawEffect = workspace:GetAttribute("EffectAffects")
                _origNoDashCooldown = (type(rawNoDash) == "boolean") and rawNoDash or false
                _origEffectAffects = (type(rawEffect) == "number" and rawEffect == rawEffect) and rawEffect or 0
                local function safeCD(v)
                        return (type(v) == "number" and v == v) and v or nil
                end
                local char = lp.Character
                if char then
                        _origForwardCD = safeCD(char:GetAttribute("CustomForwardDashCooldown"))
                        _origSideCD = safeCD(char:GetAttribute("CustomSideDashCooldown"))
                        enforceDash(char)
                end
                noDashCDCharConn = lp.CharacterAdded:Connect(function(c)
                        if not NoDashCDEnabled then return end
                        _origForwardCD = safeCD(c:GetAttribute("CustomForwardDashCooldown"))
                        _origSideCD = safeCD(c:GetAttribute("CustomSideDashCooldown"))
                        enforceDash(c)
                end)
                noDashCDHeartbeat = RunService.Heartbeat:Connect(function()
                        if not NoDashCDEnabled then return end
                        local c = lp.Character
                        if c then enforceDash(c) end
                        workspace:SetAttribute("NoDashCooldown", true)
                        workspace:SetAttribute("EffectAffects", 1)
                        workspace:SetAttribute("VIPServerOwner", lp.Name)
                end)
                task.spawn(function()
                        if not getgc then return end
                        local gc = getgc(true)
                        for _, func in ipairs(gc) do
                                if type(func) == "function" then
                                        local ok, upvalues = pcall(debug.getupvalues, func)
                                        if ok and upvalues then
                                                for _, uv in ipairs(upvalues) do
                                                        if type(uv) == "table" and uv.forwardDashCooldown ~= nil then
                                                                _gcUpvalueTable = uv
                                                                uv.forwardDashCooldown = 0
                                                                uv.sideDashCooldown = 0
                                                                return
                                                        end
                                                end
                                        end
                                end
                        end
                end)
        else
                workspace:SetAttribute("NoDashCooldown", _origNoDashCooldown)
                workspace:SetAttribute("EffectAffects", _origEffectAffects)
                local char = lp.Character
                if char then restoreChar(char) end
                if _gcUpvalueTable then
                        _gcUpvalueTable.forwardDashCooldown = 0
                        _gcUpvalueTable.sideDashCooldown = 0
                        _gcUpvalueTable = nil
                end
        end
end
local _jumpHeld = false
local _jumpHeartbeatConn = nil
local _jumpCharAddedConn = nil
local _jumpHumanoid = nil
local noStunJumpEnabled = true
local _autoReturnDeathConn = nil
local _autoReturnCharConn = nil
local _autoReturnCharRemovingConn = nil
local _autoReturnLastDeathCF = nil
local function _autoReturnStart()
    local lp = game:GetService("Players").LocalPlayer
    local function setupChar(char)
        if _autoReturnDeathConn then pcall(function() _autoReturnDeathConn:Disconnect() end) end
        local hrp = char:WaitForChild("HumanoidRootPart", 5)
        local hum = char:WaitForChild("Humanoid", 5)
        if not hum or not hrp then return end
        if _autoReturnLastDeathCF then
            local savedCF = _autoReturnLastDeathCF
            _autoReturnLastDeathCF = nil
            task.delay(0.5, function()
                if hrp and hrp.Parent then
                    _G.NX_TP(savedCF, "Auto-Return", 4)
                end
            end)
        end
        _autoReturnDeathConn = hum.Died:Connect(function()
            if hrp and hrp.Parent then
                _autoReturnLastDeathCF = hrp.CFrame + Vector3.new(0, 3, 0)
            end
        end)
    end
    if lp.Character then
        task.spawn(function() setupChar(lp.Character) end)
    end
    if _autoReturnCharConn then pcall(function() _autoReturnCharConn:Disconnect() end) end
    _autoReturnCharConn = lp.CharacterAdded:Connect(function(char)
        setupChar(char)
    end)
    if _autoReturnCharRemovingConn then pcall(function() _autoReturnCharRemovingConn:Disconnect() end) end
    _autoReturnCharRemovingConn = lp.CharacterRemoving:Connect(function(char)
        local hrp = char:FindFirstChild("HumanoidRootPart")
        if hrp and not _autoReturnLastDeathCF then
            _autoReturnLastDeathCF = hrp.CFrame + Vector3.new(0, 3, 0)
        end
    end)
end
_autoReturnStart()
function NULL(v)
	toggleCharacterCleanupRuntime(v)
	toggleAntiZero(v)
	toggleAntiGrab(v)
	toggleAntiGrabZero(v)
	toggleNoTp(v)
end
toggleAntiVoid(true)
function toggleCharacterCleanupRuntime(state)
        CharacterCleanupEnabled = state == true
        if CharacterCleanupEnabled then
                task.spawn(function()
                        local Players = game:GetService("Players")
                        local lp = Players.LocalPlayer
                        local function onChar(char)
                                if not char then return end
                                task.spawn(function()
                                        task.wait(0.25)
                                        if CharacterCleanupEnabled and char and char.Parent then
                                                _bindCleanupEvents(char)
                                        end
                                end)
                        end
                        if lp.Character then onChar(lp.Character) end
                        if ModConnections.bindCleanupCharAdded then
                                pcall(function() ModConnections.bindCleanupCharAdded:Disconnect() end)
                        end
                        ModConnections.bindCleanupCharAdded = lp.CharacterAdded:Connect(onChar)
                        repeat
                                CharacterCleanupEnabled = true
                                pcall(function()
                                        local isSelfFlinging = walkFlingEnabled or flingEnabled or clickFlingEnabled or auraFlingEnabled or flingAllEnabled
                                        if isSelfFlinging then
                                                return
                                        end
                                        local char = lp.Character
                                        if char then
                                                runCleanupTick(char)
                                        end
                                end)
                                task.wait()
                        until not CharacterCleanupEnabled
                end)
                local lp2 = game:GetService("Players").LocalPlayer
                _jumpHumanoid = lp2.Character and lp2.Character:FindFirstChildWhichIsA("Humanoid")
                local function jumpAction(actionName, inputState, inputObject)
                        if inputState == Enum.UserInputState.Begin then
                                _jumpHeld = true
                                if noStunJumpEnabled and _jumpHumanoid and _jumpHumanoid.Health > 0 then
                                        local st = _jumpHumanoid:GetState()
                                        if st ~= Enum.HumanoidStateType.Jumping and st ~= Enum.HumanoidStateType.Freefall then
                                                _jumpHumanoid:ChangeState(Enum.HumanoidStateType.Jumping)
                                        end
                                end
                        elseif inputState == Enum.UserInputState.End then
                                _jumpHeld = false
                        end
                        return noStunJumpEnabled and Enum.ContextActionResult.Sink or Enum.ContextActionResult.Pass
                end
                game:GetService("ContextActionService"):BindAction("NothingXNoStunJump", jumpAction, false, Enum.KeyCode.Space)
                if _jumpHeartbeatConn then _jumpHeartbeatConn:Disconnect() end
                _jumpHeartbeatConn = RunService.Heartbeat:Connect(function()
                        if not CharacterCleanupEnabled then
                                _jumpHeartbeatConn:Disconnect()
                                _jumpHeartbeatConn = nil
                                return
                        end
                        if _jumpHeld and noStunJumpEnabled and _jumpHumanoid and _jumpHumanoid.Health > 0 then
                                if _jumpHumanoid.FloorMaterial ~= Enum.Material.Air then
                                        local st = _jumpHumanoid:GetState()
                                        if st ~= Enum.HumanoidStateType.Jumping and st ~= Enum.HumanoidStateType.Freefall then
                                                _jumpHumanoid:ChangeState(Enum.HumanoidStateType.Jumping)
                                        end
                                end
                        end
                end)
                if _jumpCharAddedConn then _jumpCharAddedConn:Disconnect() end
                _jumpCharAddedConn = lp2.CharacterAdded:Connect(function(newChar)
                        _jumpHumanoid = nil
                        _jumpHeld = false
                        task.spawn(function()
                                local hum = newChar:FindFirstChildWhichIsA("Humanoid")
                                        or newChar:WaitForChild("Humanoid", 10)
                                if hum and CharacterCleanupEnabled then
                                        _jumpHumanoid = hum
                                end
                        end)
                end)
        end
        if state == true and not hooksRegistered then
hooksRegistered = true
pcall(function()
        local actionKeys = {
                [Enum.KeyCode.Q] = true,
        }
        UserInputService.InputBegan:Connect(function(input, processed)
                if processed then return end
                if actionKeys[input.KeyCode] then
                        lastLocalActionTime = os.clock()
                        if holdingA or holdingS or holdingD then
                                lastQActionType = "dodgevelocity"
                        else
                                lastQActionType = "moveme"
                        end
                end
        end)
end)
                task.spawn(function()
                        pcall(function()
                                local STUN_EFFECTS = {
                                        ["Velocity Up"] = true,
                                        ["StunCheck"]   = true,
                                        ["Wavey Velocity"]  = true,
                                        ["Velocity Aerial"] = true,
                                        ["RagdollCheck"]    = true,
                                        ["Stay Velocity"]   = true,
                                        ["MechStun"]        = true,
                                }
                                local C_list = {
                                        ["moveme"] = true,
                                        ["Slowed"] = true,
                                        ["Freeze"] = true,
                                        ["RagdollCheck"] = true,
                                        ["Ragdoll"] = true,
                                        ["StunCheck"] = true,
                                        ["Fallout"] = true,
                                        ["Position"] = true,
                                        ["pairs"] = true,
                                        ["Side"] = true,
                                        ["SideInversion"] = true,
                                        ["rightVector"] = true,
                                        ["SideFallout"] = true,
                                }
                                local replicationEvent = game:GetService("ReplicatedStorage"):WaitForChild("Replication", 10)
                                if replicationEvent then
                                        local rbxSignal = replicationEvent.OnClientEvent
                                        local function shouldBlockEffect(tbl)
                                                if typeof(tbl) ~= "table" then return false end
                                                local success, eff = pcall(function() return tbl.Effect end)
                                                if not success or eff == nil then return false end
                                                if STUN_EFFECTS[eff] ~= true then return false end
                                                if eff == "Velocity Up" then
                                                        local successK, k1 = pcall(next, tbl)
                                                        if not successK then return false end
                                                        local successK2, k2 = pcall(next, tbl, k1)
                                                        return successK and k1 ~= nil and successK2 and k2 == nil
                                                end
                                                return true
                                        end
                                        local function shouldBlockCommunicate(tbl)
                                                if typeof(tbl) ~= "table" then return false end
                                                local success, goal = pcall(function() return tbl.Goal end)
                                                if not success or goal == nil then return false end
                                                if C_list[goal] ~= true then return false end
                                                return true
                                        end
                                        local activeCommunicateSignals = setmetatable({}, { __mode = "k" })
                                        local activeCommunicateEvents = setmetatable({}, { __mode = "k" })
                                        local function registerCommunicate(instance)
                                                if instance.Name == "Communicate" and instance:IsA("RemoteEvent") then
                                                        activeCommunicateEvents[instance] = true
                                                        local success, signal = pcall(function() return instance.OnClientEvent end)
                                                        if success and signal then
                                                                activeCommunicateSignals[signal] = true
                                                        end
                                                end
                                        end
                                        game.DescendantAdded:Connect(registerCommunicate)
                                        task.spawn(function()
                                                for _, service in ipairs({game:GetService("Workspace"), game:GetService("ReplicatedStorage"), game:GetService("Players")}) do
                                                        for _, desc in ipairs(service:GetDescendants()) do
                                                                registerCommunicate(desc)
                                                        end
                                                end
                                        end)
                                        if hookfunction then
                                                local oldConnect
                                                oldConnect = hookfunction(rbxSignal.Connect, function(self, callback)
                                                        if CharacterCleanupEnabled then
                                                                if rawequal(self, rbxSignal) then
                                                                        return oldConnect(self, function(data, ...)
                                                                                if typeof(data) == "table" and data.Effect and shouldBlockEffect(data) then
                                                                                        return
                                                                                end
                                                                                return callback(data, ...)
                                                                        end)
                                                                elseif activeCommunicateSignals[self] then
                                                                        return oldConnect(self, function(data, ...)
                                                                                if typeof(data) == "table" and data.Goal and C_list[data.Goal] then
                                                                                        return
                                                                                end
                                                                                return callback(data, ...)
                                                                        end)
                                                                end
                                                        end
                                                        return oldConnect(self, callback)
                                                end)
                                        end
                                        if getconnections and hookfunction then
                                                for _, conn in ipairs(getconnections(rbxSignal)) do
                                                        local oldConn; oldConn = hookfunction(conn.Function, function(data, ...)
                                                                if CharacterCleanupEnabled and typeof(data) == "table" and data.Effect and shouldBlockEffect(data) then
                                                                        return
                                                                end
                                                                return oldConn(data, ...)
                                                        end)
                                                end
                                        end
                                        if hookmetamethod then
                                                local oldNamecall; oldNamecall = hookmetamethod(game, "__namecall", newcclosure(function(self, ...)
                                                        if CharacterCleanupEnabled and getnamecallmethod() == "FireServer" then
                                                                if rawequal(self, replicationEvent) then
                                                                        if shouldBlockEffect((...)) then return end
                                                                elseif activeCommunicateEvents[self] then
                                                                        if shouldBlockCommunicate((...)) then return end
                                                                end
                                                        end
                                                        return oldNamecall(self, ...)
                                                end))
                                        elseif hookfunction then
                                                local remoteEventClass = Instance.new("RemoteEvent")
                                                local oldFireServer
                                                oldFireServer = hookfunction(remoteEventClass.FireServer, function(self, arg1, ...)
                                                        if CharacterCleanupEnabled then
                                                                if rawequal(self, replicationEvent) and shouldBlockEffect(arg1) then return end
                                                                if activeCommunicateEvents[self] and shouldBlockCommunicate(arg1) then return end
                                                        end
                                                        return oldFireServer(self, arg1, ...)
                                                end)
                                        end
                                        task.spawn(function()
                                                local lp = game:GetService("Players").LocalPlayer
                                                local hookedComm = {}
                                                local function setupComm(char)
                                                        local Communicate = char:WaitForChild("Communicate", 9e9)
                                                        registerCommunicate(Communicate)
                                                        if getconnections and hookfunction then
                                                                for _, connection in ipairs(getconnections(Communicate.OnClientEvent)) do
                                                                        local func = connection.Function
                                                                        if func and not hookedComm[func] then
                                                                                hookedComm[func] = true
                                                                                local oldConn; oldConn = hookfunction(func, function(data, ...)
                                                                                        if CharacterCleanupEnabled and typeof(data) == "table" and data.Goal and C_list[data.Goal] then
                                                                                                return
                                                                                        end
                                                                                        return oldConn(data, ...)
                                                                                end)
                                                                        end
                                                                end
                                                        end
                                                end
                                                if lp.Character then setupComm(lp.Character) end
                                                lp.CharacterAdded:Connect(setupComm)
                                        end)
                                end
                        end)
                end)
        end
        if not CharacterCleanupEnabled then
                if ModConnections.wsLoop then ModConnections.wsLoop:Disconnect(); ModConnections.wsLoop = nil end
                if ModConnections.jpLoop then ModConnections.jpLoop:Disconnect(); ModConnections.jpLoop = nil end
                if ModConnections.hrpLoop then ModConnections.hrpLoop:Disconnect(); ModConnections.hrpLoop = nil end
                if ModConnections.CharacterAdded then ModConnections.CharacterAdded:Disconnect(); ModConnections.CharacterAdded = nil end
                if ModConnections.descAdded then ModConnections.descAdded:Disconnect(); ModConnections.descAdded = nil end
                if ModConnections.bindCleanupCharAdded then ModConnections.bindCleanupCharAdded:Disconnect(); ModConnections.bindCleanupCharAdded = nil end
                _jumpHeld = false
                _jumpHumanoid = nil
                if _jumpHeartbeatConn then _jumpHeartbeatConn:Disconnect(); _jumpHeartbeatConn = nil end
                if _jumpCharAddedConn then _jumpCharAddedConn:Disconnect(); _jumpCharAddedConn = nil end
                game:GetService("ContextActionService"):UnbindAction("NothingXNoStunJump")
                return
        end
        local Players = game:GetService("Players")
        local speaker = Players.LocalPlayer
        local speed = 26.50
        local jpower = 50.50
        local function SetupHumanoid(Char, Human)
                if not Human or not Human.Parent then return end
                if ModConnections.wsLoop then ModConnections.wsLoop:Disconnect() end
                if ModConnections.jpLoop then ModConnections.jpLoop:Disconnect() end
                local function UpdateWalkSpeed()
                        if Human and Human.Parent and CharacterCleanupEnabled then
                                Human.WalkSpeed = flying and 0 or speed
                        end
                end
                UpdateWalkSpeed()
                ModConnections.wsLoop = Human:GetPropertyChangedSignal("WalkSpeed"):Connect(UpdateWalkSpeed)
                local function UpdateJumpPower()
                        if Human and Human.Parent and CharacterCleanupEnabled then
                                if Human.UseJumpPower then
                                        Human.JumpPower = jpower
                                else
                                        Human.JumpHeight = jpower
                                end
                        end
                end
                UpdateJumpPower()
                local propertyToWatch = Human.UseJumpPower and "JumpPower" or "JumpHeight"
                ModConnections.jpLoop = Human:GetPropertyChangedSignal(propertyToWatch):Connect(UpdateJumpPower)
                task.spawn(function()
                        local hrp = Char:WaitForChild("HumanoidRootPart", 5)
                        if hrp then
                                if ModConnections.hrpLoop then ModConnections.hrpLoop:Disconnect() end
                                local function unanchor()
                                        if CharacterCleanupEnabled then hrp.Anchored = false end
                                end
                                unanchor()
                                ModConnections.hrpLoop = hrp:GetPropertyChangedSignal("Anchored"):Connect(unanchor)
                        end
                end)
        end
        local function isCounter(acc)
                if not acc or not acc:IsA("Accessory") then return false end
                return acc.Name:lower():find("counter") ~= nil
        end
        local function usunPusteAccessory(char)
                if not char then return end
                for _, obj in ipairs(char:GetChildren()) do
                        if obj:IsA("Accessory") then
                                if isCounter(obj) then
                                        continue
                                end
                                if #obj:GetChildren() == 0 then
                                        pcall(function()
                                                for attrName, attrValue in pairs(obj:GetAttributes()) do
                                                        if type(attrValue) == "boolean" then obj:SetAttribute(attrName, false)
                                                        elseif type(attrValue) == "number" then obj:SetAttribute(attrName, 0) end
                                                        obj:SetAttribute(attrName, nil)
                                                end
                                                obj:Destroy()
                                        end)
                                end
                        end
                end
        end
        local function SetupCharacterCleanup(Char)
                if ModConnections.descAdded then ModConnections.descAdded:Disconnect(); ModConnections.descAdded = nil end
                characterMotor6DsByChar[Char] = {}
                local myMotor6Ds = characterMotor6DsByChar[Char]
                for _, v in ipairs(Char:GetDescendants()) do
                        if v:IsA("Motor6D") then
                                table.insert(myMotor6Ds, v)
                        end
                end
                local function handleObj(v)
                        if v:IsA("BodyVelocity") then
                                local name = v.Name
                                local isDashing = (os.clock() - lastLocalActionTime < dashBypassDuration)
                                if isDashing and lastQActionType == name then
                                        if name == "moveme" then
                                                pcall(function()
                                                        v.MaxForce = Vector3.new(40000, 40000, 40000)
                                                        v.P = 1250
                                                        v:SetAttribute("Fallout", 0.95)
                                                end)
                                                return
                                        elseif name == "dodgevelocity" then
                                                pcall(function()
                                                        v.MaxForce = Vector3.new(50000, 50000, 50000)
                                                        v.P = 1250
                                                end)
                                                return
                                        end
                                end
                        end
                        local isSelfFlinging = walkFlingEnabled or flingEnabled or clickFlingEnabled or auraFlingEnabled or flingAllEnabled
                        if v:IsA("Motor6D") then
                                table.insert(myMotor6Ds, v)
                        end
                        if not isSelfFlinging then
                                if CharacterCleanupEnabled then
                                        if v:IsA("BallSocketConstraint") or v:IsA("NoCollisionConstraint") then
                                                pcall(function() v:Destroy() end)
                                                _nxMarkDefenseActing()
                                                local human = Char:FindFirstChildOfClass("Humanoid")
                                                if human then
                                                        human.PlatformStand = false
                                                end
                                                local myMotor6Ds = characterMotor6DsByChar[Char]
                                                if myMotor6Ds then
                                                        for i = 1, #myMotor6Ds do
                                                                local m = myMotor6Ds[i]
                                                                if m and m.Parent then m.Enabled = true end
                                                        end
                                                end
                                                local hrp = Char:FindFirstChild("HumanoidRootPart")
                                                if hrp then
                                                        pcall(function() hrp:SetAttribute("IsTrashOperation", true) end)
                                                        task.delay(0.15, function()
                                                                pcall(function()
                                                                        if hrp and hrp.Parent then
                                                                                hrp:SetAttribute("IsTrashOperation", false)
                                                                        end
                                                                end)
                                                        end)
                                                end
                                        end
                                end
                        end
                        if not isSelfFlinging and antiZeroEnabled then
                                if _isBadMover(v) then
                                        local hrp = Char:FindFirstChild("HumanoidRootPart")
                                        if hrp then
                                                pcall(function()
                                                        hrp.AssemblyLinearVelocity = Vector3.zero
                                                        hrp.AssemblyAngularVelocity = Vector3.zero
                                                end)
                                                _nxMarkDefenseActing()
                                                pcall(function() hrp:SetAttribute("IsTrashOperation", true) end)
                                                task.delay(0.15, function()
                                                        pcall(function()
                                                                if hrp and hrp.Parent then
                                                                        hrp:SetAttribute("IsTrashOperation", false)
                                                                end
                                                        end)
                                                end)
                                        end
                                        pcall(function() v:Destroy() end)
                                        local Communicate = Char:FindFirstChild("Communicate") or Char:WaitForChild("Communicate", 2)
                                        if Communicate then
                                                pcall(function()
                                                        Communicate:FireServer({ Goal = "delete bv", BV = v })
                                                end)
                                        end
                                end
                        end
                end
                for _, v in ipairs(Char:GetDescendants()) do
                        handleObj(v)
                end
                ModConnections.descAdded = Char.DescendantAdded:Connect(handleObj)
        end
        local function OnCharacterAdded(Char)
                characterMotor6DsByChar[Char] = {}
                local Human = Char:WaitForChild("Humanoid", 5)
                if Human then SetupHumanoid(Char, Human) end
                SetupCharacterCleanup(Char)
                if antiGrabEnabled or antiGrabZeroEnabled then
                        task.spawn(function()
                                task.wait()
                                _setupGrabOnChar(Char)
                        end)
                end
                task.wait()
                if CharacterCleanupEnabled then usunPusteAccessory(Char) end
                speaker.CharacterRemoving:Connect(function(oldChar)
                        characterMotor6DsByChar[oldChar] = nil
                end)
        end
        if ModConnections.CharacterAdded then
                ModConnections.CharacterAdded:Disconnect()
                ModConnections.CharacterAdded = nil
        end
        if speaker.Character then
                characterMotor6DsByChar[speaker.Character] = {}
                OnCharacterAdded(speaker.Character)
        end
        ModConnections.CharacterAdded = speaker.CharacterAdded:Connect(OnCharacterAdded)
        if ModConnections.accessoryHeartbeat then
                ModConnections.accessoryHeartbeat:Disconnect()
                ModConnections.accessoryHeartbeat = nil
        end
        local _lastAccessoryScanTime = 0
        local ACCESSORY_SCAN_INTERVAL = 0.12
        ModConnections.accessoryHeartbeat = game:GetService("RunService").Heartbeat:Connect(function()
                if not CharacterCleanupEnabled then
                        ModConnections.accessoryHeartbeat:Disconnect()
                        ModConnections.accessoryHeartbeat = nil
                        return
                end
                local char = speaker.Character
                if char then
                        local hrp = char:FindFirstChild("HumanoidRootPart")
                        if hrp then hrp.Anchored = false end
                        local now2 = os.clock()
                        if now2 - _lastAccessoryScanTime >= ACCESSORY_SCAN_INTERVAL then
                                _lastAccessoryScanTime = now2
                                usunPusteAccessory(char)
                        end
                end
        end)
        task.spawn(function()
                while CharacterCleanupEnabled do
                        local args = { { Goal = "delete bv", BV = Instance.new("BodyVelocity", nil) } }
                        pcall(function() speaker.Character:WaitForChild("Communicate"):FireServer(unpack(args)) end)
                        task.wait()
                end
        end)
end
function initInvisibleBorderCleanup()
        task.spawn(function()
                local map = workspace:FindFirstChild("Map")
                local folder = map and map:FindFirstChild("InvisibleBorder")
                if not folder then return end
                local function fixPart(v)
                        if v:IsA("BasePart") then
                                if v.CanCollide ~= false then v.CanCollide = false end
                                if v.CanTouch ~= false then v.CanTouch = false end
                                if v.CanQuery ~= false then v.CanQuery = false end
                        end
                end
                for _, v in pairs(folder:GetDescendants()) do
                        fixPart(v)
                end
                folder.DescendantAdded:Connect(function(v)
                        fixPart(v)
                end)
                folder.DescendantAdded:Connect(function(v)
                        if v:IsA("BasePart") then
                                v:GetPropertyChangedSignal("CanCollide"):Connect(function()
                                        if v.CanCollide ~= false then v.CanCollide = false end
                                end)
                                v:GetPropertyChangedSignal("CanTouch"):Connect(function()
                                        if v.CanTouch ~= false then v.CanTouch = false end
                                end)
                                v:GetPropertyChangedSignal("CanQuery"):Connect(function()
                                        if v.CanQuery ~= false then v.CanQuery = false end
                                end)
                        end
                end)
        end)
end
initInvisibleBorderCleanup()
StayToggle = nil
DashToggle = nil
stayPos = nil
stayConn = nil
stayGyro = nil
isActive = false
directions = {
    Enum.KeyCode.A,
    Enum.KeyCode.D,
    Enum.KeyCode.S,
}
DashBlockRunning = false
DashThread = nil
communicate = nil
autoFixCamEnabled = false
antiDeathEnabled = false
noclipEnabled = false
noclipConnection = nil
isProcessingAntiDeath = false
localAnimConn = nil
task.spawn(function()
    stayPos = nil
    stayConn = nil
    stayGyro = nil
    isActive = false
    directions = {
        Enum.KeyCode.A,
        Enum.KeyCode.D,
        Enum.KeyCode.S,
    }
    DashBlockRunning = false
    DashThread = nil
    communicate = nil
    local function fixCamera()
        local character = player.Character
        if not character then
            return
        end
        local humanoid = character:FindFirstChildOfClass("Humanoid")
        if not humanoid then
            return
        end
        humanoid.CameraOffset = Vector3.new(0, 0, 0)
        local camera = Workspace.CurrentCamera
        if camera then
            camera.CameraType = Enum.CameraType.Custom
            camera.CameraSubject = humanoid
        end
        task.delay(0, function()
            if humanoid and humanoid.Parent then
                humanoid.CameraOffset = Vector3.new(0, 0, 0)
            end
        end)
    end
    autoFixCamEnabled = false
    antiDeathEnabled = false
    noclipEnabled = false
    noclipConnection = nil
    local noclipExtraConns = {}
    local function toggleNoclip(enabled)
        noclipEnabled = enabled
        if noclipConnection then
            noclipConnection:Disconnect()
            noclipConnection = nil
        end
        for _, c in ipairs(noclipExtraConns) do pcall(function() c:Disconnect() end) end
        noclipExtraConns = {}
        if enabled then
            local function disablePart(part)
                if part:IsA("BasePart") and part.CanCollide then
                    part.CanCollide = false
                end
            end
            local charDescConn = nil
            local function hookChar(char)
                if charDescConn then pcall(function() charDescConn:Disconnect() end) end
                if not char then return end
                for _, part in ipairs(char:GetDescendants()) do disablePart(part) end
                charDescConn = char.DescendantAdded:Connect(function(part)
                    task.defer(function() if noclipEnabled then disablePart(part) end end)
                end)
                noclipExtraConns[#noclipExtraConns + 1] = charDescConn
            end
            hookChar(game:GetService("Players").LocalPlayer.Character)
            local caConn = game:GetService("Players").LocalPlayer.CharacterAdded:Connect(function(newChar)
                task.defer(function() if noclipEnabled then hookChar(newChar) end end)
            end)
            noclipExtraConns[#noclipExtraConns + 1] = caConn
            noclipConnection = game:GetService("RunService").Stepped:Connect(function()
                local c = game:GetService("Players").LocalPlayer.Character
                if c then
                    for _, part in ipairs(c:GetDescendants()) do
                        if part:IsA("BasePart") and part.CanCollide then
                            part.CanCollide = false
                        end
                    end
                end
            end)
        end
    end
    isProcessingAntiDeath = false
    local function isDeathCounterActive()
        local character = player.Character
        local humanoid = character and character:FindFirstChildOfClass("Humanoid")
        local animator = humanoid and humanoid:FindFirstChildOfClass("Animator")
        if animator then
            for _, track in ipairs(animator:GetPlayingAnimationTracks()) do
                if track.Animation and track.Animation.AnimationId == "rbxassetid://11343250001" then
                    return true
                end
            end
        end
        return false
    end
    local function bypassDeathCounter()
        if isProcessingAntiDeath then return end
        isProcessingAntiDeath = true
        local character = player.Character
        local humanoid = character and character:FindFirstChildOfClass("Humanoid")
        local animator = humanoid and humanoid:FindFirstChildOfClass("Animator")
        if not animator then
            isProcessingAntiDeath = false
            return
        end
        local startTime = tick()
        repeat
            task.wait()
            pcall(function()
                for _, track in ipairs(animator:GetPlayingAnimationTracks()) do
                    if track.Animation and track.Animation.AnimationId == "rbxassetid://11343250001" then
                        track:AdjustSpeed(0)
                        track:Stop(0)
                    end
                end
            end)
        until (tick() - startTime) > 2.8 or not isDeathCounterActive()
        isProcessingAntiDeath = false
    end
    _G.masterYieldCounter = _G.masterYieldCounter + 1
    _G.MasterYieldingTasks[tostring(_G.masterYieldCounter)] = function()
        if not antiDeathEnabled or isProcessingAntiDeath then return end
        if isDeathCounterActive() then
            bypassDeathCounter()
        end
    end
    local lastKillsCount = 0
    local function runAutoFixCamCheck()
        local currentKills = 0
        local ls = player:FindFirstChild("leaderstats")
        local kVal = ls and ls:FindFirstChild("Kills")
        if kVal then
            currentKills = kVal.Value
        else
            currentKills = player:GetAttribute("Kills") or 0
        end
        if currentKills ~= lastKillsCount then
            if autoFixCamEnabled then
                fixCamera()
            end
        end
        lastKillsCount = currentKills
    end
    task.spawn(function()
        local ls = player:WaitForChild("leaderstats", 10)
        local kVal = ls and ls:WaitForChild("Kills", 10)
        if kVal then
            lastKillsCount = kVal.Value
            kVal.Changed:Connect(runAutoFixCamCheck)
        else
            lastKillsCount = player:GetAttribute("Kills") or 0
            player:GetAttributeChangedSignal("Kills"):Connect(runAutoFixCamCheck)
        end
    end)
    local flatLayConn = nil
    local flatOriginalC0 = nil
    local flatOriginalC1 = nil
    local flatCapturedChar = nil
    local function getRootJoint(char)
        if not char then return nil end
        local hrp = char:FindFirstChild("HumanoidRootPart")
        if hrp then
            local rj = hrp:FindFirstChild("RootJoint") or hrp:FindFirstChild("Root Joint")
            if rj then return rj end
        end
        local lower = char:FindFirstChild("LowerTorso")
        if lower then
            local rj = lower:FindFirstChild("RootJoint") or lower:FindFirstChild("Root Joint")
            if rj then return rj end
        end
        return nil
    end
    local function updateFlatLayState()
        if flatLayConn then flatLayConn:Disconnect(); flatLayConn = nil end
        if movementFlatState then
            flatLayConn = RunService.Heartbeat:Connect(function()
                local char = player.Character
                if not char then return end
                local rj = getRootJoint(char)
                if rj then
                    if flatCapturedChar ~= char or not flatOriginalC0 then
                        flatOriginalC0 = rj.C0
                        flatOriginalC1 = rj.C1
                        flatCapturedChar = char
                    end
                    rj.C0 = CFrame.new(0, -2.15, 0) * flatOriginalC0 * CFrame.Angles(-math.pi * 0.5, 0, 0)
                end
            end)
        else
            local char = player.Character
            local rj = getRootJoint(char)
            if rj and flatOriginalC0 and (flatCapturedChar == char or rj.Parent.Parent == char or rj.Parent == char) then
                rj.C0 = flatOriginalC0
                if flatOriginalC1 then
                    rj.C1 = flatOriginalC1
                end
            end
            flatOriginalC0 = nil
            flatOriginalC1 = nil
            flatCapturedChar = nil
        end
    end
    task.spawn(function()
        task.wait()
        updateFlatLayState()
    end)
    local function cleanupStay()
        if stayConn then
            stayConn:Disconnect()
            stayConn = nil
        end
        if stayGyro then
            stayGyro:Destroy()
            stayGyro = nil
        end
        stayPos = nil
    end
    local function setStayState(state)
        if (state == nil or state == true) and (_G.SafeTeleportLock == true) then
            return
        end
        isActive = state == true
        local char = player.Character
        if not char then
            return
        end
        local root = char:FindFirstChild("HumanoidRootPart")
        if not root then
            return
        end
        if isActive then
            stayPos = root.Position
            stayGyro = Instance.new("BodyGyro")
            stayGyro:SetAttribute("IsLocalMover", true)
            stayGyro.MaxTorque = Vector3.new(1e9, 9e9, 9e9)
            stayGyro.P = 9e9
            stayGyro.CFrame = root.CFrame
            stayGyro.Parent = root
            stayConn = RunService.Heartbeat:Connect(function()
                if root and stayPos and not isProcessingAntiDeath then
                    root.AssemblyLinearVelocity = Vector3.zero
                    root.AssemblyAngularVelocity = Vector3.zero
                    _G.NX_TP(CFrame.new(stayPos) * CFrame.Angles(
                        0,
                        math.rad(root.Orientation.Y),
                        0
                    ), "Stay", 5)
                    if stayGyro then
                        stayGyro.CFrame = root.CFrame
                    end
                end
            end)
        else
            cleanupStay()
        end
    end
    local function setDashBlockRuntime(state)
        DashBlockRunning = state == true
        if DashThread then
            task.cancel(DashThread)
            DashThread = nil
        end
        if not DashBlockRunning then
            return
        end
        if not communicate then
            DashBlockRunning = false
            return
        end
        DashThread = task.spawn(function()
            while DashBlockRunning do
                if communicate then
                    for _, dashKey in ipairs(directions) do
                        communicate:FireServer({
                            Dash = dashKey,
                            Key = Enum.KeyCode.Q,
                            Goal = "KeyPress"
                        })
                    end
                end
                task.wait()
            end
        end)
    end
    localAnimConn = nil
    local function setupCharacter(char)
        local comm = char:FindFirstChild("Communicate")
        if comm then
            communicate = comm
        end
        if DashToggle and DashToggle.SetValue then
            DashToggle:SetValue(DashBlockRunning, true)
        end
        char.ChildAdded:Connect(function(child)
            if child.Name == "Communicate" then
                communicate = child
            end
        end)
        if localAnimConn then pcall(function() localAnimConn:Disconnect() end); localAnimConn = nil end
        task.spawn(function()
            local humanoid = char:WaitForChild("Humanoid", 10)
            local animator = humanoid and humanoid:WaitForChild("Animator", 10)
            if animator and char.Parent then
                localAnimConn = animator.AnimationPlayed:Connect(function(track)
                    if antiDeathEnabled and not isProcessingAntiDeath and track.Animation and track.Animation.AnimationId == "rbxassetid://11343250001" then
                        task.spawn(bypassDeathCounter)
                    end
                end)
            end
        end)
    end
    local supportsDashBlock = game.GameId == 3808081382
    local isTSB = supportsDashBlock
    local createMovementPanel = _G["2tog_on_one_button"]
    local movementHub = makeControlFrame(isTSB and 214 or 124)
    movementHub.Parent = uiX
    movementHub.LayoutOrder = 1
    movementHub.ClipsDescendants = true
    local hubTitle = Instance.new("TextLabel")
    hubTitle.BackgroundTransparency = 1
    hubTitle.Position = UDim2.new(0, 16, 0, 8)
    hubTitle.Size = UDim2.new(1, -32, 0, 18)
    hubTitle.Font = Enum.Font.GothamBold
    hubTitle.Text = "Movement & System"
    hubTitle.TextColor3 = Color3.fromRGB(255, 255, 255)
    hubTitle.TextStrokeTransparency = 1
    hubTitle.TextSize = 14
    hubTitle.TextXAlignment = Enum.TextXAlignment.Left
    hubTitle.Parent = movementHub
    local function makeRow(yPos)
        local row = Instance.new("Frame")
        row.BackgroundTransparency = 1
        row.BorderSizePixel = 0
        row.Position = UDim2.new(0, 4, 0, yPos)
        row.Size = UDim2.new(1, -8, 0, 26)
        row.Parent = movementHub
        local layout = Instance.new("UIListLayout")
        layout.FillDirection = Enum.FillDirection.Horizontal
        layout.HorizontalAlignment = Enum.HorizontalAlignment.Center
        layout.VerticalAlignment = Enum.VerticalAlignment.Center
        layout.Padding = UDim.new(0, 4)
        layout.Parent = row
        return row
    end
    local function makeHubBtn(parent, text, callback, widthMult)
        local btn = Instance.new("TextButton")
        btn.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
        btn.BackgroundTransparency = 0
        btn.BorderSizePixel = 0
        btn.BorderColor3 = Color3.fromRGB(255, 255, 255)
        btn.Size = UDim2.new(widthMult or 0.25, 0, 1, 0)
        local corner = Instance.new("UICorner")
        corner.CornerRadius = UDim.new(0, 6)
        corner.Parent = btn
        btn.AutoButtonColor = false
        btn.Font = Enum.Font.GothamBold
        btn.Text = text
        btn.TextColor3 = Color3.fromRGB(255, 255, 255)
        btn.TextStrokeTransparency = 1
        btn.TextSize = 13
        btn.Parent = parent
        btn.MouseButton1Click:Connect(function()
            if callback then callback() end
        end)
        return btn
    end
    local row1 = makeRow(30)
    StayToggle = makeHubTog(row1, "Stay", setStayState, "StayEnabled", false, isTSB and 1/4 or 1/3)
    if isTSB then
        DashToggle = makeHubTog(row1, "Dash Block", setDashBlockRuntime, "DashBlockEnabled", false, 1/4)
    end
    makeHubBtn(row1, "Fix Cam", fixCamera, isTSB and 1/4 or 1/3)

    if isTSB then
        local r = makeRow(60)
        makeHubTog(r, "Whirlwind", function(v) _G.WhirlwindEnabled = v end, "AutoWhirlwind", false)
        makeHubTog(r, "Auto Combo", function(v) _G.WallComboEnabled = v end, "AutoCombo", false)
        makeHubTog(r, "No Dash CD", function(v)
            _G.NoDashCD_Enabled = v
            toggleNoDashCD(v)
        end, "NoDashCD", false)
        makeHubTog(r, "BL Trash", function(v) setTrashBlockEnabled(v) end, "BLClickTrash", false)
        r = makeRow(90)
        makeHubTog(r, "Safe Zone (N)", function(v) toggleAFK(v) end, "AFKEnabled", false, 1/3)
        makeHubTog(r, "Safe Zone (HP)", function(v) toggleSafeZoneHP(v) end, "HPSafeZoneEnabled", false, 1/3)
        makeHubTog(r, "HP Target", function(v) updateTargetDisplay() end, "TargetHPEnabled", false, 1/3)
        r = makeRow(120)
        makeHubTog(r, "Auto Fix Cam", function(v) autoFixCamEnabled = v end, "AutoFixCamEnabled", false, 1/2)
        makeHubTog(r, "Noclip", function(v) toggleNoclip(v) end, "NoclipEnabled", false, 1/2)
        r = makeRow(150)
        makeHubTog(r, "Anti-Fling", function(v) toggleAntiFling(v) end, "AntiFlingEnabled", false, 1/2)
        makeHubTog(r, "Null", function(v) NULL(v) end, "NullEnabled", false, 1/2)
    else
        local r = makeRow(60)
        makeHubTog(r, "Safe Zone (N)", function(v) toggleAFK(v) end, "AFKEnabled", false, 1/3)
        makeHubTog(r, "Safe Zone (HP)", function(v) toggleSafeZoneHP(v) end, "HPSafeZoneEnabled", false, 1/3)
        makeHubTog(r, "HP Target", function(v) updateTargetDisplay() end, "TargetHPEnabled", false, 1/3)
        r = makeRow(90)
        makeHubTog(r, "Null", function(v) NULL(v) end, "NullEnabled", false, 1/3)
    end
    do
        local rowJump = makeRow(isTSB and 180 or 150)
        makeHubTog(rowJump, "Jump (Emote)", function(v)
            noStunJumpEnabled = v
            setSavedControlValue("NoStunJumpEnabled", v)
        end, "NoStunJumpEnabled", false, 1)
    end
    local espHub = makeControlFrame(isTSB and 184 or 124)
    espHub.Parent = uiX
    espHub.LayoutOrder = 2
    espHub.ClipsDescendants = true
    local espTitle = Instance.new("TextLabel")
    espTitle.BackgroundTransparency = 1
    espTitle.Position = UDim2.new(0, 16, 0, 8)
    espTitle.Size = UDim2.new(1, -32, 0, 18)
    espTitle.Font = Enum.Font.GothamBold
    espTitle.Text = "ESP / Billboard"
    espTitle.TextColor3 = Color3.fromRGB(255, 255, 255)
    espTitle.TextStrokeTransparency = 1
    espTitle.TextSize = 14
    espTitle.TextXAlignment = Enum.TextXAlignment.Left
    espTitle.Parent = espHub
    local function makeEspRow(yPos)
        local row = Instance.new("Frame")
        row.BackgroundTransparency = 1
        row.BorderSizePixel = 0
        row.Position = UDim2.new(0, 4, 0, yPos)
        row.Size = UDim2.new(1, -8, 0, 26)
        row.Parent = espHub
        local layout = Instance.new("UIListLayout")
        layout.FillDirection = Enum.FillDirection.Horizontal
        layout.HorizontalAlignment = Enum.HorizontalAlignment.Center
        layout.VerticalAlignment = Enum.VerticalAlignment.Center
        layout.Padding = UDim.new(0, 4)
        layout.Parent = row
        return row
    end
    local rEsp = makeEspRow(30)
    makeHubTog(rEsp, "HP %", function(v) espOverlayConfig.showHp = v; refreshAllOverlays() end, "Overlay4HP", false, 1/4)
    makeHubTog(rEsp, "Name (CH)", function(v) espOverlayConfig.showCharacter = v; refreshAllOverlays() end, "Overlay4Character", false, 1/4)
    makeHubTog(rEsp, "ULT %", function(v) espOverlayConfig.showUltimate = v; refreshAllOverlays() end, "Overlay4Ultimate", false, 1/4)
    makeHubTog(rEsp, "Streak", function(v) espOverlayConfig.showStreak = v; refreshAllOverlays() end, "Overlay4Streak", false, 1/4)
    rEsp = makeEspRow(60)
    makeHubTog(rEsp, "ULT ESP", function(v) espOverlayConfig.showEsp = v; refreshAllOverlays() end, "Overlay4ESP", false, 1/2)
    makeHubTog(rEsp, "Death Cntr ESP", function(v) toggleSeriousModeTracker(v); refreshAllOverlays() end, "DeathCounterESPEnabled", false, 1/2)
    rEsp = makeEspRow(90)
    makeHubTog(rEsp, "Death Cntr", function(v) espOverlayConfig.showDeath = v; syncSeriousModeTracker(); refreshAllOverlays() end, "Overlay4Death", false, 1/2)
    makeHubTog(rEsp, "Ulted Info", function(v) espOverlayConfig.showUlted = v; refreshAllOverlays() end, "Overlay4Ulted", false, 1/2)
    rEsp = makeEspRow(120)
    makeHubTog(rEsp, "Anti Death Cntr", function(v) antiDeathEnabled = v end, "AntiDeathCounterEnabled", false, 1/2)
    local fakerPingHub = makeControlFrame(68)
    fakerPingHub.Parent = uiX
    fakerPingHub.LayoutOrder = 2
    fakerPingHub.ClipsDescendants = true
    local fpTitle = Instance.new("TextLabel")
    fpTitle.BackgroundTransparency = 1
    fpTitle.Position = UDim2.new(0, 16, 0, 8)
    fpTitle.Size = UDim2.new(1, -32, 0, 18)
    fpTitle.Font = Enum.Font.GothamBold
    fpTitle.Text = "Faker Ping"
    fpTitle.TextColor3 = Color3.fromRGB(255, 255, 255)
    fpTitle.TextStrokeTransparency = 1
    fpTitle.TextSize = 14
    fpTitle.TextXAlignment = Enum.TextXAlignment.Left
    fpTitle.Parent = fakerPingHub
    local fpLabel = Instance.new("TextLabel")
    fpLabel.BackgroundTransparency = 1
    fpLabel.Position = UDim2.new(0, 16, 0, 32)
    fpLabel.Size = UDim2.new(0.5, -16, 0, 24)
    fpLabel.Font = Enum.Font.GothamBold
    fpLabel.Text = "Ping"
    fpLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
    fpLabel.TextStrokeTransparency = 1
    fpLabel.TextSize = 13
    fpLabel.TextXAlignment = Enum.TextXAlignment.Left
    fpLabel.Parent = fakerPingHub
    local fpBox = Instance.new("TextBox")
    fpBox.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
    fpBox.BackgroundTransparency = 0.5
    fpBox.BorderSizePixel = 0
    fpBox.BorderColor3 = Color3.fromRGB(255, 255, 255)
    fpBox.Position = UDim2.new(0.5, 0, 0, 32)
    fpBox.Size = UDim2.new(0.45, -16, 0, 24)
    fpBox.ClearTextOnFocus = false
    fpBox.Font = Enum.Font.GothamBold
    fpBox.PlaceholderText = "Ping (0-5000)"
    fpBox.PlaceholderColor3 = Color3.fromRGB(187, 187, 187)
    fpBox.Text = ""
    fpBox.TextColor3 = Color3.fromRGB(255, 255, 255)
    fpBox.TextStrokeTransparency = 1
    fpBox.TextSize = 13
    fpBox.Parent = fakerPingHub
    local fpBoxConstraint = Instance.new("UITextSizeConstraint")
    fpBoxConstraint.MinTextSize = 10
    fpBoxConstraint.MaxTextSize = 14
    fpBoxConstraint.Parent = fpBox
    fpBox:GetPropertyChangedSignal("Text"):Connect(function()
        local text = fpBox.Text
        local filtered = text:gsub("[^0-9]", "")
        if filtered ~= text then fpBox.Text = filtered end
    end)
    local lastValidPing = getSavedControlValue("FakerPingValue")
    if lastValidPing ~= nil then
        fpBox.Text = tostring(lastValidPing)
    end
    fpBox.Focused:Connect(function()
        fpBox.Text = ""
    end)
    fpBox.FocusLost:Connect(function()
        local rawText = fpBox.Text
        if rawText == "" then
            lastValidPing = nil
            setSavedControlValue("FakerPingValue", nil)
            return
        end
        local num = tonumber(rawText)
        if num then
            num = math.clamp(num, 0, 5000)
            fpBox.Text = tostring(num)
            lastValidPing = num
            setSavedControlValue("FakerPingValue", num)
        else
            fpBox.Text = ""
            lastValidPing = nil
            setSavedControlValue("FakerPingValue", nil)
        end
    end)
    _G.masterYieldCounter = _G.masterYieldCounter + 1
    local lastPingReport = 0
    _G.MasterYieldingTasks[tostring(_G.masterYieldCounter)] = function()
        local now = tick()
        if now - lastPingReport >= 1 then
                lastPingReport = now
                if lastValidPing ~= nil then
                    local comm = player.Character and player.Character:FindFirstChild("Communicate")
                    if comm then
                        pcall(function()
                            comm:FireServer({ Goal = "ReportPing", ms = lastValidPing })
                        end)
                    end
                end
        end
    end
    if player.Character then
        setupCharacter(player.Character)
    end
    player.CharacterAdded:Connect(setupCharacter)
if game.GameId == 3808081382 then
    local WhirlwindDunkID = "rbxassetid://12296113986"
    local WallComboIDs = {
        ["rbxassetid://17325537719"] = true,
        ["rbxassetid://10469643643"] = true,
        ["rbxassetid://13294471966"] = true,
        ["rbxassetid://13295936866"] = true,
        ["rbxassetid://13378708199"] = true,
        ["rbxassetid://14136436157"] = true,
        ["rbxassetid://15162694192"] = true,
        ["rbxassetid://16552234590"] = true,
        ["rbxassetid://17889290569"] = true,
    }
    local displacedClient
    local function getClientModule(char)
        local handler = char:FindFirstChild("CharacterHandler")
        local client =
            (handler and handler:FindFirstChild("Client"))
            or (displacedClient and displacedClient.Parent ~= handler and displacedClient)
        return client
    end
    local function FireWallCombo(char)
        local client = getClientModule(char)
        local fired = false
        if client then
            local ok, env = pcall(function()
                return getsenv and getsenv(client)
            end)
            if ok and type(env) == "table" then
                local f19 = rawget(env, "f19")
                if not f19 then
                    for _, v in pairs(env) do
                        if type(v) == "function" then
                            f19 = v
                            break
                        end
                    end
                end
                if f19 then
                    pcall(f19, {Goal = "Wall Combo"})
                    fired = true
                end
            end
        end
        if not fired then
            local communicate = char:FindFirstChild("Communicate")
            if communicate and communicate:IsA("RemoteEvent") then
			for i = 1, 15 do
                communicate:FireServer({Goal = "Wall Combo"})
end
            end
        end
    end
     local function HandleWallComboTilt(track, combatChar)
        if not _G.WallComboEnabled then return end
        if not track.Animation then return end
        if not WallComboIDs[track.Animation.AnimationId] then return end
        local hrp = combatChar:FindFirstChild("HumanoidRootPart")
        if not hrp then return end
        local start = tick()
        local conn
        conn = RunService.Heartbeat:Connect(function()
            if not _G.WallComboEnabled or tick() - start >= 0.3 then
                conn:Disconnect()
                return
            end
            local pos = hrp.Position
            local look = hrp.CFrame.LookVector
            local flat = Vector3.new(look.X,0,look.Z)
            flat = flat.Magnitude > 0.001 and flat.Unit or Vector3.new(0,0,-1)
for i = 1, 10 do
    hrp:SetAttribute("IsAttackTP", true)
    hrp.CFrame = CFrame.lookAt(pos, pos + flat) * CFrame.Angles(math.rad(-25), 0, 0)
    hrp:SetAttribute("IsAttackTP", false)
end
			if _G.BringWallComboEnabled then
				local targetCF = nil
				if wallComboBringCustomPos then
					targetCF = CFrame.new(wallComboBringCustomPos)
				elseif selectedPlace ~= "/\\" then
					targetCF = resolvePlaceCF(selectedPlace)
				end
				if targetCF then
					local waitTime = WAIT_WALL_COMBO
					if _G.AutoWaitWallComboEnabled then
						local localPing = 0
						pcall(function()
							local stats = game:GetService("Stats")
							localPing = (stats.Network.ServerStatsItem["Data Ping"]:GetValue() or 0) / 1000
						end)
						local targetPing = 0
						local closestTargetPlayer = nil
						pcall(function()
							local myPos = hrp.Position
							local closestDist = math.huge
							for _, p in ipairs(Players:GetPlayers()) do
								if p ~= player and p.Character then
									local tHrp = p.Character:FindFirstChild("HumanoidRootPart")
									if tHrp then
										local dist = (tHrp.Position - myPos).Magnitude
										if dist < closestDist then
											closestDist = dist
											closestTargetPlayer = p
											local pPing = p:GetAttribute("Ping")
											if typeof(pPing) == "number" then
												targetPing = pPing > 1 and pPing / 1000 or pPing
											end
										end
									end
								end
							end
						end)
						local localOneWay = localPing / 2
						local targetOneWay = targetPing / 2
						local autoWait = math.max(0, (targetOneWay - localOneWay) + localOneWay)
						waitTime = autoWait + WAIT_WALL_COMBO
						if _G._bwWaitBoxRef then
							local displayMs = math.floor(autoWait * 1000 + 0.5)
							_G._bwWaitBoxRef.Text = "~" .. displayMs .. "ms"
						end
					end
					task.wait(waitTime)
					if _G.NX_TP then
					    _G.NX_TP(targetCF, "WallCombo", 5)
					else
					    hrp.CFrame = targetCF
					end
				end
			end
        end)
    end
    local function SetupCombatCharacter(combatChar)
        local handler = combatChar:FindFirstChild("CharacterHandler")
        if handler and handler:FindFirstChild("Client") then
            displacedClient = handler.Client
        end
        local humanoid = combatChar:WaitForChild("Humanoid", 5)
        local animator = humanoid and humanoid:WaitForChild("Animator", 5)
        animator.AnimationPlayed:Connect(function(track)
            if _G.WhirlwindEnabled
                and track.Animation
                and track.Animation.AnimationId == WhirlwindDunkID then
                task.wait()
                local hrp = combatChar:FindFirstChild("HumanoidRootPart")
                if hrp then
                    hrp.CFrame = hrp.CFrame * CFrame.new(0,100,0)
                end
            end
            HandleWallComboTilt(track, combatChar)
        end)
        combatChar.DescendantAdded:Connect(function(desc)
            if not _G.WallComboEnabled then return end
            if desc:IsA("ObjectValue")
            and desc.Name:lower() == "wallcombo" then
                local startTime = tick()
                local timeout = desc:GetAttribute("DeleteMe") or 0.6
                repeat
                    task.spawn(FireWallCombo, combatChar)
                    task.spawn(FireWallCombo, combatChar)
                    task.spawn(FireWallCombo, combatChar)
                    task.wait()
                until
                    not desc.Parent
                    or desc.Parent ~= combatChar
                    or tick() - startTime >= timeout
            end
        end)
    end
    if player.Character then
        task.spawn(SetupCombatCharacter, player.Character)
    end
    player.CharacterAdded:Connect(function(char)
        task.spawn(SetupCombatCharacter, char)
    end)
end
end)
task.spawn(function()
    local flingState = {
        localPlayer = Players.LocalPlayer,
        taskToken = 0,
        runnerActive = false,
        runnerConnection = nil,
        flingPower = flingPower,
        orbitSpeed = flingOrbitSpeed,
        orbitStepXZ = 0,
        orbitStepY = 0,
        orbitIncrement = flingOrbitIncrement,
        orbitMax = flingOrbitMax,
    }
    local function getRoot(char)
        if not char then
            return nil
        end
        return char:FindFirstChild("HumanoidRootPart") or char:FindFirstChild("Torso") or char:FindFirstChild("UpperTorso")
    end
    local flingSavedCFrame = nil
    local flingTargetTime = 0
    local function stopFlingRuntime()
        flingState.taskToken += 1
        flingState.runnerActive = false
        if flingState.runnerConnection then
            flingState.runnerConnection:Disconnect()
            flingState.runnerConnection = nil
        end
        local myChar = flingState.localPlayer.Character
        local myRoot = getRoot(myChar)
        if myRoot and flingSavedCFrame and myRoot.Parent then
            myRoot.CFrame = flingSavedCFrame
        end
        flingSavedCFrame = nil
        flingTargetTime = 0
        flingState.orbitStepXZ = 0
        flingState.orbitStepY = 3
    end
    local function startFlingRuntime()
        stopFlingRuntime()
        flingState.runnerActive = true
        local taskToken = flingState.taskToken + 1
        flingState.taskToken = taskToken
        task.spawn(function()
            while flingEnabled and flingState.taskToken == taskToken do
                local myChar = flingState.localPlayer.Character
                local targetModel = resolveAttackTpTarget and resolveAttackTpTarget() or nil
                if not (myChar and targetModel) then
                    break
                end
                local myRoot = getRoot(myChar)
                local targetRoot = getRoot(targetModel)
                if not (myRoot and targetRoot) then
                    break
                end
                if not flingSavedCFrame then
                    flingSavedCFrame = myRoot.CFrame
                end
                local dt = RunService.Heartbeat:Wait()
                applyOrbitFlingStep(myRoot, targetRoot, dt, FLING_INF_POWER)
            end
            flingState.runnerActive = false
        end)
    end
    local flingFlagLastCheck = 0
    RunService.Heartbeat:Connect(function()
        local now = os.clock()
        if now - flingFlagLastCheck < 0.1 then return end
        flingFlagLastCheck = now
        if flingEnabled then
            if not flingState.runnerActive then
                startFlingRuntime()
            end
        else
            stopFlingRuntime()
        end
    end)
end)
do
        local Workspace = game:GetService("Workspace")
        local Players = game:GetService("Players")
        local StarterPack = game:GetService("StarterPack")
        local LocalPlayer = Players.LocalPlayer
        pcall(function()
                Workspace.FallenPartsDestroyHeight = 0/0
                Workspace.FallenPartsDestroyHeight = 0/0
        end)
        local BOUNDARY_X = 200000
        local BOUNDARY_Z = 200000
        local BOUNDARY_Y_DOWN = -10000
        local CLIENT_MOVE_Y = -450
        local safePositions = {}
        local MAX_SAFE_POSITIONS = 10
        local displacedClient = nil
        local originalParent = nil
        ;(function()
                local function forceClientDisplace(char, pos, isExtremeFling)
                        if pos.Y <= CLIENT_MOVE_Y or isExtremeFling then
                                local charHandler = char:FindFirstChild("CharacterHandler")
                                local clientModule = charHandler and charHandler:FindFirstChild("Client") or (displacedClient and displacedClient.Parent ~= charHandler and displacedClient)
                                if clientModule then
                                        if not displacedClient then
                                                originalParent = clientModule.Parent
                                                displacedClient = clientModule
                                        end
        pcall(function()
                Workspace.FallenPartsDestroyHeight = 0/0
                Workspace.FallenPartsDestroyHeight = 0/0
        end)
                                        pcall(function()
                                                for _ = 1, 8 do
                                                        clientModule.Parent = StarterPack
                                                end
                                        end)
                                end
                        end
                end
                local function updateMonitoring()
                        local char = LocalPlayer.Character
                        if not char then
                                                                displacedClient = nil
                                originalParent = nil
                                return
                        end
                        local hrp = char:FindFirstChild("HumanoidRootPart")
                        if not hrp then return end
                        local pos = hrp.Position
                        local humanoid = char:FindFirstChildOfClass("Humanoid")
                        local alive = humanoid and humanoid.Health > 0
                        if alive and humanoid.FloorMaterial ~= Enum.Material.Air and pos.Y > CLIENT_MOVE_Y then
                                local lastSafe = safePositions[1]
                                if not lastSafe or (lastSafe.Position - pos).Magnitude > 5 then
                                        table.insert(safePositions, 1, hrp.CFrame)
                                        if #safePositions > MAX_SAFE_POSITIONS then
                                                table.remove(safePositions, #safePositions)
                                        end
                                end
                        end
                        local isNanPos = pos.X ~= pos.X or pos.Y ~= pos.Y or pos.Z ~= pos.Z
                        local vel = hrp.AssemblyLinearVelocity
                        local isNanVel = vel.X ~= vel.X or vel.Y ~= vel.Y or vel.Z ~= vel.Z
                        local isSelfFlinging = walkFlingEnabled or flingEnabled or clickFlingEnabled or auraFlingEnabled or flingAllEnabled or bHitEnabled
                        local isHugeVel = not isNanVel and not isSelfFlinging and (math.abs(vel.X) > 1e6 or math.abs(vel.Y) > 1e6 or math.abs(vel.Z) > 1e6)
                        local isExtremeFling = isNanPos or isNanVel or isHugeVel
                        local isFar = (not isNanPos and (math.abs(pos.X) >= BOUNDARY_X or math.abs(pos.Z) >= BOUNDARY_Z)) or isNanPos
                        local isVoid = not isNanPos and pos.Y <= BOUNDARY_Y_DOWN
                        local isMidHitCycle = auraFlingEnabled or flingAllEnabled or bHitEnabled
                        if ((isFar and not _G.SafeTeleportLock and not (attackTpEnabled and attackTpHolding) and not isMidHitCycle) or (isVoid and not isMidHitCycle) or isNanVel or isHugeVel) and alive then
                                for i = 1, #safePositions do
                                        local targetCF = safePositions[i]
                                        if targetCF then
                                                pcall(function()
                                                        for _ = 1, 5 do
                                                                hrp.AssemblyLinearVelocity = Vector3.zero
                                                                hrp.AssemblyAngularVelocity = Vector3.zero
                                                                hrp.CFrame = targetCF
                                                        end
                                                end)
                                                break
                                        end
                                end
                        end
                        forceClientDisplace(char, pos, isExtremeFling)
                        if not isExtremeFling and (not isNanPos and pos.Y > CLIENT_MOVE_Y) and displacedClient and originalParent then
                                pcall(function()
                                        if displacedClient.Parent == StarterPack and originalParent and originalParent.Parent then
                                                displacedClient.Parent = originalParent
                                        end
                                end)
                                                                displacedClient = nil
                                originalParent = nil
                        end
                        if isVoid and displacedClient and originalParent then
                                local hasPlace = selectedPlace and selectedPlace ~= "" and selectedPlace ~= "/\\" and resolvePlaceCF(selectedPlace) ~= nil
                                if not hasPlace then
                                        pcall(function()
                                                if displacedClient.Parent == StarterPack and originalParent and originalParent.Parent then
                                                        displacedClient.Parent = originalParent
                                                end
                                        end)
                                        displacedClient = nil
                                        originalParent = nil
                                end
                        end
                        if not alive and displacedClient then
                                pcall(function()
                                        if displacedClient.Parent == StarterPack then
                                                displacedClient:Destroy()
                                        end
                                end)
                                                                displacedClient = nil
                                originalParent = nil
                        end
                end
                local function setupHrpListeners(hrp, char)
                        if not hrp then return end
                        local function fastCheck()
                                local pos = hrp.Position
                                local isNanPos = pos.X ~= pos.X or pos.Y ~= pos.Y or pos.Z ~= pos.Z
                                local vel = hrp.AssemblyLinearVelocity
                                local isNanVel = vel.X ~= vel.X or vel.Y ~= vel.Y or vel.Z ~= vel.Z
                                local isSelfFlinging = walkFlingEnabled or flingEnabled or clickFlingEnabled or auraFlingEnabled or flingAllEnabled or bHitEnabled
                                local isHugeVel = not isNanVel and not isSelfFlinging and (math.abs(vel.X) > 1e6 or math.abs(vel.Y) > 1e6 or math.abs(vel.Z) > 1e6)
                                forceClientDisplace(char, pos, isNanPos or isNanVel or isHugeVel)
                        end
                        hrp:GetPropertyChangedSignal("CFrame"):Connect(fastCheck)
                        hrp:GetPropertyChangedSignal("Position"):Connect(fastCheck)
                end
                LocalPlayer.CharacterAdded:Connect(function(char)
                        local hrp = char:WaitForChild("HumanoidRootPart", 5)
                        setupHrpListeners(hrp, char)
                end)
                if LocalPlayer.Character then
                        setupHrpListeners(LocalPlayer.Character:FindFirstChild("HumanoidRootPart"), LocalPlayer.Character)
                end
                RunService.Heartbeat:Connect(updateMonitoring)
        end)()
end
function Keybind_add(text)
        if text == nil then
                return keybindEntries.Custom and keybindEntries.Custom.name or ""
        end
        local currentName = keybindEntries.Custom and keybindEntries.Custom.name or ""
        keybindEntries.Custom = keybindEntries.Custom or { keybind = "", enabled = false }
        keybindEntries.Custom.name = currentName .. tostring(text)
        updateKeybindText()
        return keybindEntries.Custom.name
end
function Keybind_bind(text)
        if text == nil then
                return keybindEntries.Custom and keybindEntries.Custom.keybind or ""
        end
        keybindEntries.Custom = keybindEntries.Custom or { name = "", enabled = false }
        keybindEntries.Custom.keybind = tostring(text)
        updateKeybindText()
        return keybindEntries.Custom.keybind
end
function Keybind_tog(text)
        if text == nil then
                return keybindEntries.Custom and (keybindEntries.Custom.enabled and "ON" or "OFF") or "OFF"
        end
        keybindEntries.Custom = keybindEntries.Custom or { name = "", keybind = "" }
        keybindEntries.Custom.enabled = parseEnabledValue(text)
        updateKeybindText()
        return keybindEntries.Custom.enabled and "ON" or "OFF"
end
function Slider(data)
        data = data or {}
        local state = {
                name = tostring(data.nameSlider or data.nameSilder or data.name or "Slider"),
                showName = tostring(data.nameshow or data.nameShow or data.show or "Value"),
                max = tonumber(data.max or data.size) or 100,
                min = tonumber(data.min) or 0,
                callback = data.fun,
                value = 0,
                saveKey = tostring(data.saveKey or data.nameSlider or data.nameSilder or data.name or "Slider"),
                applyCallbackOnLoad = true,
        }
        local holder = makeControlFrame(72)
        holder.Parent = uiX
        local nameLabel = Instance.new("TextLabel")
        nameLabel.BackgroundTransparency = 1
        nameLabel.Position = UDim2.fromScale(0.05, 0.12)
        nameLabel.Size = UDim2.fromScale(0.55, 0.25)
        nameLabel.Font = Enum.Font.GothamBold
        nameLabel.Text = state.name
        nameLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
        nameLabel.TextStrokeTransparency = 1
        nameLabel.TextSize = 13
        nameLabel.TextScaled = false
        nameLabel.TextWrapped = true
        nameLabel.TextXAlignment = Enum.TextXAlignment.Left
        nameLabel.Parent = holder
        local editBox = Instance.new("TextBox")
        editBox.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
        editBox.BackgroundTransparency = 0.5
        editBox.BorderSizePixel = 0
        editBox.BorderColor3 = Color3.fromRGB(255, 255, 255)
        editBox.Position = UDim2.fromScale(0.66, 0.3)
        editBox.Size = UDim2.fromScale(0.24, 0.24)
        editBox.ClearTextOnFocus = false
        editBox.Font = Enum.Font.GothamMedium
        editBox.PlaceholderText = "set"
        editBox.PlaceholderColor3 = Color3.fromRGB(187, 187, 187)
        editBox.Text = "0"
        editBox.TextColor3 = Color3.fromRGB(255, 255, 255)
        editBox.TextStrokeTransparency = 1
        editBox.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
        editBox.Font = Enum.Font.GothamBold
        editBox.TextSize = 13
        editBox.TextScaled = false
        editBox.TextWrapped = true
        editBox.Parent = holder
        do
                local ebCorner = Instance.new("UICorner")
                ebCorner.CornerRadius = UDim.new(0, 3)
                ebCorner.Parent = editBox
        end
        editBox:GetPropertyChangedSignal("Text"):Connect(function()
                local text = editBox.Text
                local filtered = text:gsub("[^-0-9%.eE+]", "")
                if filtered ~= text then editBox.Text = filtered end
        end)
        local bar = Instance.new("Frame")
        bar.BackgroundColor3 = Color3.fromRGB(35, 35, 35)
        bar.Position = UDim2.fromScale(0.05, 0.68)
        bar.Size = UDim2.fromScale(0.9, 0.14)
        bar.Active = true
        bar.BorderSizePixel = 0
        bar.Parent = holder
        do
                local barCorner = Instance.new("UICorner")
                barCorner.CornerRadius = UDim.new(0, 3)
                barCorner.Parent = bar
        end
        local fill = Instance.new("Frame")
        fill.BackgroundColor3 = Color3.fromRGB(150, 150, 150)
        fill.BorderSizePixel = 0
        fill.Size = UDim2.fromScale(0, 1)
        fill.Parent = bar
        do
                local fillCorner = Instance.new("UICorner")
                fillCorner.CornerRadius = UDim.new(0, 3)
                fillCorner.Parent = fill
                local fillGradient = Instance.new("UIGradient")
                fillGradient.Color = ColorSequence.new(Color3.fromRGB(100, 100, 100), Color3.fromRGB(255, 255, 255))
                fillGradient.Rotation = 0
                fillGradient.Parent = fill
        end
        state.editBox = editBox
        state.fill = fill
        sliderStates[#sliderStates + 1] = state
        local draggingSlider = false
        local function updateFromInput(inputPositionX)
                local relative = inputPositionX - bar.AbsolutePosition.X
                local percent = math.clamp(relative / math.max(bar.AbsoluteSize.X, 1), 0, 1)
                applySliderValue(state, state.min + (percent * (state.max - state.min)), true)
        end
        bar.InputBegan:Connect(function(input)
                if input.UserInputType ~= Enum.UserInputType.MouseButton1 then
                        return
                end
                draggingSlider = true
                updateFromInput(input.Position.X)
        end)
        bar.InputEnded:Connect(function(input)
                if input.UserInputType == Enum.UserInputType.MouseButton1 then
                        draggingSlider = false
                end
        end)
        UserInputService.InputChanged:Connect(function(input)
                if draggingSlider and input.UserInputType == Enum.UserInputType.MouseMovement then
                        updateFromInput(input.Position.X)
                end
        end)
        editBox.Focused:Connect(function()
                editBox.Text = ""
        end)
        editBox.FocusLost:Connect(function()
                local rawText = editBox.Text
                local typedValue = tonumber(rawText)
                if rawText == "" or typedValue == nil then
                        editBox.Text = string.format("%.1f", roundToTenth(state.value))
                        return
                end
                if typedValue > (tonumber(state.max) or 100) then
                        state.value = typedValue
                        editBox.Text = tostring(typedValue)
                        if state.saveKey then
                                setSavedControlValue(state.saveKey, typedValue)
                        end
                        if state.callback then
                                state.callback(typedValue)
                        end
                        state.fill.Size = UDim2.new(1, 0, 1, 0)
                else
                        applySliderValue(state, typedValue, true)
                end
        end)
        local initialValue = getSavedControlValue(state.saveKey)
        if initialValue == nil then
                initialValue = data.default or 0
        end
        applySliderValue(state, initialValue, false)
        state.applyCallbackOnLoad = false
        return holder
end
function Textbox(data)
        data = data or {}
        local textTitle = tostring(data.Text or data.text or "Textbox")
        local callback = data.fun
        local holder = makeControlFrame(88)
        holder.Parent = uiX
        local titleLabel = Instance.new("TextLabel")
        titleLabel.BackgroundTransparency = 1
        titleLabel.Position = UDim2.fromScale(0.05, 0.1)
        titleLabel.Size = UDim2.fromScale(0.9, 0.18)
        titleLabel.Font = Enum.Font.GothamBold
        titleLabel.Text = textTitle
        titleLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
        titleLabel.TextStrokeTransparency = 1
        titleLabel.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
        titleLabel.TextSize = 13
        titleLabel.TextScaled = false
        titleLabel.TextWrapped = true
        titleLabel.TextXAlignment = Enum.TextXAlignment.Left
        titleLabel.Parent = holder
        local inputBox = Instance.new("TextBox")
        inputBox.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
        inputBox.BackgroundTransparency = 0.5
        inputBox.BorderSizePixel = 0
        inputBox.Position = UDim2.fromScale(0.05, 0.42)
        inputBox.Size = UDim2.fromScale(0.9, 0.38)
        inputBox.ClearTextOnFocus = false
        inputBox.Font = Enum.Font.GothamBold
        inputBox.PlaceholderText = "type here"
        inputBox.PlaceholderColor3 = Color3.fromRGB(187, 187, 187)
        inputBox.Text = ""
        inputBox.TextColor3 = Color3.fromRGB(255, 255, 255)
        inputBox.TextSize = 13
        inputBox.TextScaled = false
        inputBox.TextWrapped = true
        inputBox.Parent = holder
        do
                local ibCorner = Instance.new("UICorner")
                ibCorner.CornerRadius = UDim.new(0, 3)
                ibCorner.Parent = inputBox
        end
        inputBox:GetPropertyChangedSignal("Text"):Connect(function()
                local text = inputBox.Text
                local filtered = text:gsub("[^-0-9%.]", "")
                if filtered ~= text then inputBox.Text = filtered end
        end)
        inputBox.FocusLost:Connect(function(enterPressed)
                if callback then
                        callback(inputBox.Text, enterPressed)
                end
        end)
        return holder
end
_G["2textbox_on_one_frame"] = function(data)
        data = data or {}
        local holder = makeControlFrame(110)
        holder.Parent = uiX
        local titleLabel = Instance.new("TextLabel")
        titleLabel.BackgroundTransparency = 1
        titleLabel.Position = UDim2.fromScale(0.05, 0.08)
        titleLabel.Size = UDim2.fromScale(0.9, 0.16)
        titleLabel.Font = Enum.Font.GothamBold
        titleLabel.Text = tostring(data.title or "Inputs")
        titleLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
        titleLabel.TextStrokeTransparency = 1
        titleLabel.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
        titleLabel.TextSize = 13
        titleLabel.TextScaled = false
        titleLabel.TextWrapped = true
        titleLabel.TextXAlignment = Enum.TextXAlignment.Left
        titleLabel.Parent = holder
        local rowFrame = Instance.new("Frame")
        rowFrame.BackgroundTransparency = 1
        rowFrame.Position = UDim2.fromScale(0.05, 0.38)
        rowFrame.Size = UDim2.fromScale(0.9, 0.38)
        rowFrame.Parent = holder
        local rowLayout = Instance.new("UIListLayout")
        rowLayout.FillDirection = Enum.FillDirection.Horizontal
        rowLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
        rowLayout.VerticalAlignment = Enum.VerticalAlignment.Center
        rowLayout.Padding = UDim.new(0, 10)
        rowLayout.Parent = rowFrame
        local function createInputBox(labelText, defaultValue, saveKey, callback)
                local container = Instance.new("Frame")
                container.BackgroundTransparency = 1
                container.Size = UDim2.new(0.5, -5, 1, 0)
                container.Parent = rowFrame
                local label = Instance.new("TextLabel")
                label.BackgroundTransparency = 1
                label.Position = UDim2.fromScale(0, 0.05)
                label.Size = UDim2.fromScale(1, 0.4)
                label.Font = Enum.Font.GothamBold
                label.Text = tostring(labelText or "")
                label.TextColor3 = Color3.fromRGB(255, 255, 255)
                label.TextStrokeTransparency = 1
                label.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
                label.TextSize = 13
                label.TextScaled = false
                label.TextWrapped = true
                label.ClipsDescendants = true
                label.TextXAlignment = Enum.TextXAlignment.Left
                label.Parent = container
                local inputBox = Instance.new("TextBox")
                inputBox.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
                inputBox.BackgroundTransparency = 0.5
                inputBox.BorderSizePixel = 0
                inputBox.Position = UDim2.fromScale(0, 0.5)
                inputBox.Size = UDim2.fromScale(1, 0.45)
                inputBox.ClearTextOnFocus = false
                inputBox.Font = Enum.Font.GothamBold
                inputBox.PlaceholderText = "set"
                inputBox.PlaceholderColor3 = Color3.fromRGB(187, 187, 187)
                inputBox.Text = tostring(defaultValue or "")
                inputBox.TextColor3 = Color3.fromRGB(255, 255, 255)
                inputBox.TextSize = 13
                inputBox.TextScaled = false
                inputBox.ClipsDescendants = true
                inputBox.Parent = container
                do
                        local ib2Corner = Instance.new("UICorner")
                        ib2Corner.CornerRadius = UDim.new(0, 3)
                        ib2Corner.Parent = inputBox
                end
                local lastAllowedText = tostring(defaultValue or "")
                local syncingText = false
                local function isAllowedTextboxValue(text)
                        if text == "" then
                                return true
                        end
                        local lowered = string.lower(text)
                        if lowered == "i" or lowered == "in" or lowered == "inf" or lowered == "inf+" or lowered == "inf++" or lowered == "inf+++" then
                                return true
                        end
                        if string.find(lowered, "[^0-9eE%+%-%.]") then
                                return false
                        end
                        return true
                end
                inputBox:GetPropertyChangedSignal("Text"):Connect(function()
                        if syncingText then
                                return
                        end
                        local currentText = tostring(inputBox.Text or "")
                        if isAllowedTextboxValue(currentText) then
                                lastAllowedText = currentText
                                return
                        end
                        syncingText = true
                        inputBox.Text = lastAllowedText
                        syncingText = false
                end)
                inputBox.Focused:Connect(function()
                        inputBox.Text = ""
                end)
                inputBox.FocusLost:Connect(function()
                        local rawText = tostring(inputBox.Text or ""):match("^%s*(.-)%s*$")
                        local loweredText = string.lower(rawText)
                        if loweredText == "inf" then
                                rawText = "20e20"
                        elseif loweredText == "inf+" then
                                rawText = "50e50"
                        elseif loweredText == "inf++" then
                                rawText = "99e99"
                        elseif loweredText == "inf+++" then
                                rawText = "999e999"
                        end
                        local parsed = tonumber(rawText)
                        if parsed == nil then
                                syncingText = true
                                inputBox.Text = tostring(defaultValue or "")
                                syncingText = false
                                lastAllowedText = inputBox.Text
                                return
                        end
                        defaultValue = parsed
                        syncingText = true
                        inputBox.Text = tostring(parsed)
                        syncingText = false
                        lastAllowedText = inputBox.Text
                        if saveKey and saveKey ~= "" then
                                setSavedControlValue(saveKey, parsed)
                        end
                        if callback then
                                callback(parsed)
                        end
                end)
                return inputBox
        end
        local firstDefault = getSavedControlValue(data.saveKey1)
        if firstDefault == nil then
                firstDefault = data.default1
        end
        local secondDefault = getSavedControlValue(data.saveKey2)
        if secondDefault == nil then
                secondDefault = data.default2
        end
        local firstInput = createInputBox(data.name1, firstDefault, data.saveKey1, data.fun1)
        local secondInput = createInputBox(data.name2, secondDefault, data.saveKey2, data.fun2)
        if data.fun1 and tonumber(firstDefault) ~= nil then
                data.fun1(tonumber(firstDefault))
        end
        if data.fun2 and tonumber(secondDefault) ~= nil then
                data.fun2(tonumber(secondDefault))
        end
        return {
                Frame = holder,
                First = firstInput,
                Second = secondInput,
        }
end
function Dropdown(data)
        data = data or {}
        local dropdownName = tostring(data.namedropdown or data.nameDropdown or data.name or "Dropdown")
        local rawItems = data.inside or data.items or data.values or {}
        local defaultValue = data.deffultin or data.defaultin or data.default
        local initialDefault = defaultValue
        local multi = data.multi == true
        local allowDeselect = data.allowDeselect == true
        local hideSelectionText = data.hideSelectionText == true
        local callback = data.fun
        local saveKey = tostring(data.saveKey or data.namedropdown or data.nameDropdown or data.name or "")
        local items = {}
        local itemLookup = {}
        local itemDisplayNames = data.itemDisplayNames or {}
        local disabledItems = {}
        local selected = {}
        local expanded = false
        local collapsedHeight = 88
        local expandedTopOffset = 40
        local maxVisibleOptions = 6
        local optionHeight = 28
        local optionPadding = 6
        local function normalizeValues(value)
                local result = {}
                local seen = {}
                local function appendValue(entry)
                        local textValue = tostring(entry)
                        if textValue ~= "" and not seen[textValue] then
                                seen[textValue] = true
                                result[#result + 1] = textValue
                        end
                end
                if type(value) == "table" then
                        for _, entry in ipairs(value) do
                                appendValue(entry)
                        end
                elseif type(value) == "string" then
                        for entry in string.gmatch(value, "[^,]+") do
                                local cleaned = string.gsub(entry, "^%s*(.-)%s*$", "%1")
                                if cleaned ~= "" then
                                        appendValue(cleaned)
                                end
                        end
                elseif value ~= nil then
                        appendValue(value)
                end
                return result
        end
        local function rebuildItemLookup()
                table.clear(itemLookup)
                for _, item in ipairs(items) do
                        itemLookup[item] = true
                end
        end
        local function normalizeDefaultValues(value)
                return normalizeValues(value)
        end
        local function getSelectedList()
                local result = {}
                for _, item in ipairs(items) do
                        if selected[item] then
                                result[#result + 1] = item
                        end
                end
                return result
        end
        local function hasSelectionChanged(previousSelection, currentSelection)
                if #previousSelection ~= #currentSelection then
                        return true
                end
                for index, value in ipairs(previousSelection) do
                        if currentSelection[index] ~= value then
                                return true
                        end
                end
                return false
        end
        local function areListsEqual(left, right)
                if #left ~= #right then
                        return false
                end
                for index, value in ipairs(left) do
                        if right[index] ~= value then
                                return false
                        end
                end
                return true
        end
        local function getCallbackValue()
                local selectedList = getSelectedList()
                if multi then
                        return selectedList
                end
                return selectedList[1]
        end
        items = normalizeValues(rawItems)
        rebuildItemLookup()
        local function setSelectedValue(value, enabled)
                local textValue = tostring(value)
                if not itemLookup[textValue] then
                        return
                end
                if multi then
                        if enabled then
                                selected[textValue] = true
                        else
                                selected[textValue] = nil
                        end
                else
                        table.clear(selected)
                        if enabled then
                                selected[textValue] = true
                        end
                end
        end
        local function pruneSelectedValues()
                for value in pairs(selected) do
                        if not itemLookup[value] then
                                selected[value] = nil
                        end
                end
        end
        local function getSelectedSaveValue()
                local selectedList = getSelectedList()
                if multi then
                        return selectedList
                end
                return selectedList[1]
        end
        local function saveDropdownSelection()
                if saveKey ~= "" then
                        setSavedControlValue(saveKey, getSelectedSaveValue())
                end
        end
        local savedValue = getSavedControlValue(saveKey)
        if savedValue ~= nil then
                defaultValue = savedValue
        end
        if multi then
                for _, entry in ipairs(normalizeDefaultValues(defaultValue)) do
                        setSelectedValue(entry, true)
                end
        elseif defaultValue ~= nil then
                local normalizedDefaults = normalizeDefaultValues(defaultValue)
                if normalizedDefaults[1] ~= nil then
                        setSelectedValue(normalizedDefaults[1], true)
                end
        end
        if not next(selected) then
                if initialDefault ~= nil then
                        local normalized = normalizeDefaultValues(initialDefault)
                        if normalized[1] ~= nil then
                                setSelectedValue(normalized[1], true)
                        end
                end
                if not next(selected) and #items > 0 then
                        setSelectedValue(items[1], true)
                end
        end
        local holder = makeControlFrame(88)
        holder.Name = "DropdownHolder"
        holder.Parent = uiX
        local titleLabel = Instance.new("TextLabel")
        titleLabel.BackgroundTransparency = 1
        titleLabel.Position = UDim2.new(0, 10, 0, 8)
        titleLabel.Size = UDim2.new(1, -20, 0, 18)
        titleLabel.Font = Enum.Font.GothamBold
        titleLabel.Text = dropdownName
        titleLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
        titleLabel.TextStrokeTransparency = 1
        titleLabel.TextSize = 13
        titleLabel.TextScaled = false
        titleLabel.TextWrapped = true
        titleLabel.ClipsDescendants = true
        titleLabel.TextXAlignment = Enum.TextXAlignment.Left
        titleLabel.Parent = holder
        local toggleButton = Instance.new("TextButton")
        toggleButton.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
        toggleButton.BackgroundTransparency = 0
        toggleButton.BorderSizePixel = 0
        toggleButton.BorderColor3 = Color3.fromRGB(255, 255, 255)
        toggleButton.Position = UDim2.new(0, 10, 0, 32)
        toggleButton.Size = UDim2.new(1, -20, 0, 24)
        toggleButton.AutoButtonColor = false
        toggleButton.Font = Enum.Font.GothamBold
        toggleButton.TextColor3 = Color3.fromRGB(255, 255, 255)
        toggleButton.TextStrokeTransparency = 1
        toggleButton.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
        toggleButton.TextSize = 13
        toggleButton.TextScaled = false
        toggleButton.TextWrapped = true
        toggleButton.ClipsDescendants = true
        toggleButton.Parent = holder
        do
                local tbCorner = Instance.new("UICorner")
                tbCorner.CornerRadius = UDim.new(0, 6)
                tbCorner.Parent = toggleButton
        end
        local expandedTopOffset = 36
        local optionsFrame = Instance.new("Frame")
        optionsFrame.Name = "DropdownOptionsFrame"
        optionsFrame.BackgroundTransparency = 1
        optionsFrame.Position = UDim2.new(0, 0, 0, expandedTopOffset)
        optionsFrame.Size = UDim2.new(1, 0, 0, 0)
        optionsFrame.ClipsDescendants = true
        optionsFrame.Visible = false
        optionsFrame.ZIndex = 1
        optionsFrame.Parent = holder
        local choiceFrame = Instance.new("ScrollingFrame")
        choiceFrame.Name = "DropdownChoiceFrame"
        choiceFrame.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
        choiceFrame.BackgroundTransparency = 0.5
        choiceFrame.BorderSizePixel = 0
        choiceFrame.AnchorPoint = Vector2.new(0.5, 0)
        choiceFrame.Position = UDim2.fromScale(0.5, 0)
        choiceFrame.Size = UDim2.new(0.94, 0, 0, 0)
        choiceFrame.CanvasSize = UDim2.new(0, 0, 0, 0)
        choiceFrame.AutomaticCanvasSize = Enum.AutomaticSize.Y
        choiceFrame.ElasticBehavior = Enum.ElasticBehavior.Never
        choiceFrame.ScrollBarThickness = 0
        choiceFrame.ScrollBarImageTransparency = 1
        choiceFrame.ScrollingDirection = Enum.ScrollingDirection.Y
        choiceFrame.VerticalScrollBarInset = Enum.ScrollBarInset.None
        choiceFrame.TopImage = ""
        choiceFrame.MidImage = ""
        choiceFrame.BottomImage = ""
        choiceFrame.Active = true
        choiceFrame.ZIndex = 1
        choiceFrame.ClipsDescendants = true
        choiceFrame.Parent = optionsFrame
        do
                local cfDDCorner = Instance.new("UICorner")
                cfDDCorner.CornerRadius = UDim.new(0, 4)
                cfDDCorner.Parent = choiceFrame
        end
        local optionsLayout = Instance.new("UIListLayout")
        optionsLayout.Padding = UDim.new(0, optionPadding)
        optionsLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
        optionsLayout.Parent = choiceFrame
        local optionButtons = {}
        local dropdownState = {}
        local function refreshLabels()
                local selectedList = getSelectedList()
                local displayList = {}
                for _, val in ipairs(selectedList) do
                        table.insert(displayList, itemDisplayNames[val] or val)
                end
                local displayText = "-"
                if #displayList > 0 then
                        if hideSelectionText then
                                displayText = "(~~~)"
                        else
                                displayText = table.concat(displayList, ", ")
                        end
                end
                toggleButton.Text = displayText
                for item, button in pairs(optionButtons) do
                        local isOn = selected[item] == true
                        local isDsb = disabledItems[item] == true
                        local display = itemDisplayNames[item] or item
                        if isDsb then
                                button.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
                                button.BackgroundTransparency = 0
                                button.TextColor3 = Color3.fromRGB(150, 150, 150)
                                button.Text = display
                        else
                                button.BackgroundColor3 = isOn and Color3.fromRGB(255, 255, 255) or Color3.fromRGB(0, 0, 0)
                                button.BackgroundTransparency = 0
                                button.TextColor3 = isOn and Color3.fromRGB(0, 0, 0) or Color3.fromRGB(255, 255, 255)
                                button.Text = isOn and ("> " .. display) or display
                        end
                end
        end
        local function clearOptionButtons()
                local toDestroy = {}
                for item, button in pairs(optionButtons) do
                        toDestroy[#toDestroy + 1] = {item = item, button = button}
                end
                for _, entry in ipairs(toDestroy) do
                        optionButtons[entry.item] = nil
                        if entry.button then
                                entry.button:Destroy()
                        end
                end
        end
        local setExpanded
        local function rebuildOptionButtons()
                clearOptionButtons()
                for _, item in ipairs(items) do
                        local optionButton = Instance.new("TextButton")
                        optionButton.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
                        optionButton.BackgroundTransparency = 0
                        optionButton.BorderSizePixel = 0
                        optionButton.Size = UDim2.new(0.9, 0, 0, optionHeight)
                        optionButton.AutoButtonColor = false
                        optionButton.Font = Enum.Font.GothamMedium
                        optionButton.TextColor3 = Color3.fromRGB(255, 255, 255)
                        optionButton.TextStrokeTransparency = 1
                        optionButton.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
                        optionButton.TextSize = 13
                        optionButton.TextScaled = false
                        optionButton.TextWrapped = true
                        optionButton.ClipsDescendants = true
                        optionButton.ZIndex = 1
                        optionButton.Parent = choiceFrame
                        do
                                local obCorner = Instance.new("UICorner")
                                obCorner.CornerRadius = UDim.new(0, 6)
                                obCorner.Parent = optionButton
                        end
                        optionButtons[item] = optionButton
                        optionButton.MouseButton1Click:Connect(function()
                                if disabledItems[item] then return end
                                if not multi and selected[item] and not allowDeselect then return end
                                setSelectedValue(item, not selected[item])
                                refreshLabels()
                                saveDropdownSelection()
                                if callback then
                                        callback(getCallbackValue())
                                end
                        end)
                end
                refreshLabels()
        end
        setExpanded = function(nextState)
                local wasExpanded = expanded
                expanded = nextState == true
                optionsFrame.Visible = expanded
                toggleButton.Visible = not expanded
                local scale = getScaleFactorFor(holder)
                local optionsHeight = 0
                local visibleOptionsHeight = 0
                if expanded then
                        local visibleCount = math.min(#items, maxVisibleOptions)
                        visibleOptionsHeight = (visibleCount * optionHeight + math.max(visibleCount - 1, 0) * optionPadding) * scale
                end
                optionsFrame.Size = UDim2.new(1, 0, 0, visibleOptionsHeight)
                optionsFrame.Position = UDim2.new(0, 0, 0, expandedTopOffset * scale)
                choiceFrame.Size = UDim2.new(0.94, 0, 0, visibleOptionsHeight)
                if expanded and not wasExpanded then
                        choiceFrame.CanvasPosition = Vector2.new(0, 0)
                elseif not expanded then
                        choiceFrame.CanvasPosition = Vector2.new(0, 0)
                end
                holder.Size = UDim2.new(1, -4, 0, expanded and ((expandedTopOffset + 8) * scale + visibleOptionsHeight) or (collapsedHeight * scale))
                if expanded then
                        openDropdowns[dropdownState] = true
                else
                        openDropdowns[dropdownState] = nil
                end
                refreshLabels()
        end
        toggleButton.Activated:Connect(function()
                setExpanded(not expanded)
        end)
        dropdownState = {
                holder = holder,
                optionsFrame = optionsFrame,
                choiceFrame = choiceFrame,
                optionButtons = optionButtons,
                setExpanded = setExpanded,
                isExpanded = function()
                        return expanded
                end,
        }
        allDropdowns[dropdownState] = true
        local dropdownControl = {
                Frame = holder,
        }
        function dropdownControl.GetItems()
                return items
        end
        function dropdownControl.SetItems(newItems, preferredValue, suppressCallback)
                local previousSelectedList = getSelectedList()
                local normalizedItems = normalizeValues(newItems)
                local itemsChanged = not areListsEqual(items, normalizedItems)
                items = normalizedItems
                rebuildItemLookup()
                pruneSelectedValues()
                if #getSelectedList() == 0 and preferredValue ~= nil then
                        if multi then
                                for _, entry in ipairs(normalizeDefaultValues(preferredValue)) do
                                        setSelectedValue(entry, true)
                                end
                        else
                                local normalizedDefaults = normalizeDefaultValues(preferredValue)
                                if normalizedDefaults[1] ~= nil then
                                        setSelectedValue(normalizedDefaults[1], true)
                                end
                        end
                end
                if itemsChanged then
                        rebuildOptionButtons()
                        setExpanded(expanded)
                else
                        refreshLabels()
                end
                saveDropdownSelection()
                if not suppressCallback then
                        local currentSelectedList = getSelectedList()
                        if hasSelectionChanged(previousSelectedList, currentSelectedList) and callback then
                                callback(getCallbackValue())
                        end
                end
                return getCallbackValue()
        end
        function dropdownControl.SetItemDisplayNames(newMapping)
                itemDisplayNames = newMapping or {}
                refreshLabels()
        end
        function dropdownControl.SetDisabledItems(mapping)
                disabledItems = mapping or {}
                local changed = false
                for item in pairs(disabledItems) do
                        if selected[item] then
                                setSelectedValue(item, false)
                                changed = true
                        end
                end
                refreshLabels()
                if changed then
                        saveDropdownSelection()
                        if callback then
                                callback(getCallbackValue())
                        end
                end
        end
        function dropdownControl.SetValue(value, suppressCallback)
                local previousSelectedList = getSelectedList()
                table.clear(selected)
                if multi then
                        for _, entry in ipairs(normalizeDefaultValues(value)) do
                                setSelectedValue(entry, true)
                        end
                elseif value ~= nil then
                        local normalizedDefaults = normalizeDefaultValues(value)
                        if normalizedDefaults[1] ~= nil then
                                setSelectedValue(normalizedDefaults[1], true)
                        end
                end
                refreshLabels()
                saveDropdownSelection()
                if not suppressCallback then
                        local currentSelectedList = getSelectedList()
                        if hasSelectionChanged(previousSelectedList, currentSelectedList) and callback then
                                callback(getCallbackValue())
                        end
                end
                return getCallbackValue()
        end
        function dropdownControl.GetValue()
                return getCallbackValue()
        end
        function dropdownControl.SetExpanded(nextState)
                setExpanded(nextState)
        end
        function dropdownControl.IsExpanded()
                return expanded
        end
        rebuildOptionButtons()
        refreshLabels()
        setExpanded(false)
        saveDropdownSelection()
        if callback then
                callback(getCallbackValue())
        end
        return dropdownControl
end
dropdown = Dropdown
modelDropdownLookup = {}
modelDropdownControl = nil
blPlayersDropdownControl = nil
blacklistedTargets = {}
blacklistedPlayers = {}
blacklistedModels = {}
blacklistedModelNames = {}
offlinePlayers = {}
offlineDeletionTimers = {}
offlineModels = {}
offlineModelDeletionTimers = {}
if type(controlSaveData.OfflinePlayers) == "table" then
        for name, data in pairs(controlSaveData.OfflinePlayers) do
                if type(data) == "table" and data.name then
                        offlinePlayers[name] = data
                        local lbl = "[P] " .. name .. " (Offline)"
                        blacklistedTargets[lbl] = true
                end
        end
end
if controlSaveData.BLFriends == nil then
        controlSaveData.BLFriends = false
end
if controlSaveData.BLFriends == true then
        blacklistedTargets["Friends"] = true
end
local savedBLPlayerNames = {}
if type(controlSaveData.BLPlayerNames) == "table" then
        for _, name in ipairs(controlSaveData.BLPlayerNames) do
                savedBLPlayerNames[tostring(name)] = true
        end
end
applyModelDropdownSelection = nil
isTargetBlacklisted = function(model, targetPlayer)
        if blacklistedTargets["Friends"] and targetPlayer and friendCache[targetPlayer.UserId] then
                return true
        end
        if targetPlayer then
                return blacklistedPlayers[targetPlayer] == true
        end
        if blacklistedModels[model] == true then
                return true
        end
        if model and blacklistedModelNames[model.Name] then
                return true
        end
        return false
end
do
        isSelectablePlayerDropdownTarget = function(targetPlayer)
                return targetPlayer and targetPlayer ~= player and targetPlayer.Parent == Players
        end
        isSelectableModelDropdownTarget = function(model)
                if not model then
                        return false
                end
                if Players:GetPlayerFromCharacter(model) or Players:FindFirstChild(model.Name) or offlinePlayers[model.Name] then
                        return false
                end
                return model:FindFirstChild("HumanoidRootPart") ~= nil
        end
        getModelDropdownLabelForSelection = function(model, targetPlayer)
                if not model and not targetPlayer and not manualAttackTpTargetName then
                        return nil
                end
                local modelName = model and model.Name or manualAttackTpTargetName
                for label, mappedTarget in pairs(modelDropdownLookup) do
                        if targetPlayer and mappedTarget.player == targetPlayer then
                                return label
                        end
                        if not targetPlayer then
                                if model and mappedTarget.model == model then
                                        return label
                                end
                                if modelName and mappedTarget.isOfflineModel and mappedTarget.baseNameStr == modelName then
                                        return label
                                end
                        end
                end
                return nil
        end
        buildPlayerModelDropdownItems = function()
                local playerEntries = {}
                local modelEntries = {}
                local seenModels = {}
                for _, targetPlayer in ipairs(Players:GetPlayers()) do
                        if targetPlayer ~= player and targetPlayer.Parent == Players then
                                local targetModel = getTrackedPlayerTargetModel(targetPlayer)
                                if targetPlayer.Character then
                                        seenModels[targetPlayer.Character] = true
                                end
                                if not targetModel and targetPlayer.Character then
                                        local hum = targetPlayer.Character:FindFirstChildOfClass("Humanoid")
                                        if hum and hum.Health > 0 then
                                                targetModel = targetPlayer.Character
                                        end
                                end
                                if targetModel then
                                        seenModels[targetModel] = true
                                end
                                playerEntries[#playerEntries + 1] = {
                                        baseName = tostring(targetPlayer.Name ~= "" and targetPlayer.Name or "Player"),
                                        fullName = targetPlayer:GetFullName(),
                                        player = targetPlayer,
                                        model = targetModel,
                                }
                        end
                end
                for _, targetModel in ipairs(getSelectableTargetModels()) do
                        if not seenModels[targetModel] and isSelectableModelDropdownTarget(targetModel) then
                                modelEntries[#modelEntries + 1] = {
                                        baseName = tostring(targetModel.Name ~= "" and targetModel.Name or "Model"),
                                        fullName = targetModel:GetFullName(),
                                        player = nil,
                                        model = targetModel,
                                }
                        end
                end
                for offName in pairs(offlineModels) do
                        local found = false
                        for _, entry in ipairs(modelEntries) do
                                if entry.baseName == offName then
                                        found = true
                                        break
                                end
                        end
                        if not found then
                                modelEntries[#modelEntries + 1] = {
                                        baseName = offName,
                                        fullName = offName,
                                        player = nil,
                                        model = nil,
                                        isOfflineModel = true,
                                }
                        end
                end
                table.sort(playerEntries, function(left, right)
                        local leftName = string.lower(left.baseName)
                        local rightName = string.lower(right.baseName)
                        if leftName == rightName then
                                return left.fullName < right.fullName
                        end
                        return leftName < rightName
                end)
                table.sort(modelEntries, function(left, right)
                        local leftName = string.lower(left.baseName)
                        local rightName = string.lower(right.baseName)
                        if leftName == rightName then
                                return left.fullName < right.fullName
                        end
                        return leftName < rightName
                end)
                table.clear(modelDropdownLookup)
                local usedLabels = {}
                local allItems = { "Friends" }
                local selectableItems = {}
                local displayNames = {}
                local function appendEntries(entries, prefix)
                        for _, entry in ipairs(entries) do
                                local label = string.format("%s %s", prefix, entry.baseName)
                                local suffix = 1
                                local originalLabel = label
                                while usedLabels[label] do
                                        suffix = suffix + 1
                                        label = string.format("%s (%d)", originalLabel, suffix)
                                end
                                usedLabels[label] = true
                                allItems[#allItems + 1] = label
                                if entry.player and offlinePlayers[entry.baseName] then
                                        blacklistedTargets[label] = true
                                end
                                local isFriend = entry.player and friendCache[entry.player.UserId]
                                if not blacklistedTargets[label] and not (isFriend and blacklistedTargets["Friends"]) then
                                        selectableItems[#selectableItems + 1] = label
                                end
                                local pOrM = prefix:gsub("[%[%]]", "")
                                local hpStr = "0"
                                if entry.model then
                                        local hum = entry.model:FindFirstChildOfClass("Humanoid")
                                        if hum then
                                                hpStr = formatHPPercent(hum)
                                        end
                                end
                                local baseNameStr = string.sub(entry.baseName, 1, 12)
                                local dispNameStr = nil
                                local isFriend = entry.player and friendCache[entry.player.UserId]
                                local fStr = isFriend and "F|" or ""
                                if entry.player then
                                        local rawDisp = entry.player.DisplayName or entry.baseName
                                        dispNameStr = string.sub(rawDisp, 1, 12)
                                        if dispNameStr == baseNameStr then
                                                displayNames[label] = string.format("@%s | %s%% | %s%s", baseNameStr, hpStr, fStr, pOrM)
                                        else
                                                displayNames[label] = string.format("@%s|%s | %s%% | %s%s", baseNameStr, dispNameStr, hpStr, fStr, pOrM)
                                        end
                                else
                                        displayNames[label] = string.format("%s | %s%% | %s", baseNameStr, hpStr, pOrM)
                                end
                                modelDropdownLookup[label] = {
                                        player = entry.player,
                                        model = entry.model,
                                        baseNameStr = baseNameStr,
                                        dispNameStr = dispNameStr,
                                        pOrM = pOrM,
                                        isOfflineModel = entry.isOfflineModel,
                                }
                        end
                end
                appendEntries(playerEntries, "[P]")
                appendEntries(modelEntries, "[M]")
                for offName, offData in pairs(offlinePlayers) do
                        if not Players:FindFirstChild(offName) then
                                local label = "[P] " .. offName .. " (Offline)"
                                local truncName = string.sub(offName, 1, 12)
                                local dispStr = offData == true and truncName or string.sub(tostring(offData.displayName or offName), 1, 12)
                                if not usedLabels[label] then
                                        usedLabels[label] = true
                                        allItems[#allItems + 1] = label
                                        modelDropdownLookup[label] = {
                                                player = nil,
                                                model = nil,
                                                baseNameStr = truncName,
                                                dispNameStr = dispStr,
                                                pOrM = "P",
                                                isOffline = true,
                                                offlineName = offName,
                                        }
                                        displayNames[label] = string.format("%s | P | Offline", truncName)
                                        blacklistedTargets[label] = true
                                end
                        end
                end
                return allItems, selectableItems, displayNames
        end
        applyModelDropdownSelection = function(selectedValue)
                local resolvedValue = tostring(selectedValue or "")
                if resolvedValue == "" then
                        setManualAttackTpTarget(nil)
                        return
                end
                local selectedEntry = modelDropdownLookup[resolvedValue]
                if not selectedEntry then
                        setManualAttackTpTarget(nil)
                        return
                end
                if isSelectablePlayerDropdownTarget(selectedEntry.player) then
                        setManualAttackTpTarget(selectedEntry.model, selectedEntry.player)
                elseif selectedEntry.model or selectedEntry.isOfflineModel then
                        manualAttackTpPlayer = nil
                        manualAttackTpTarget = selectedEntry.model
                        manualAttackTpTargetName = selectedEntry.baseNameStr
                        pendingTeleportToSelectedPlayer = false
                        if not isValidAttackTpTarget(camLockTarget) then
                                attackTpTarget = resolveManualAttackTpTargetModel()
                        end
                        if syncModelDropdownSelectionToManualTarget then
                                syncModelDropdownSelectionToManualTarget()
                        end
                        syncTargetPickKeybindDisplay()
                        updateTargetDisplay()
                else
                        setManualAttackTpTarget(nil)
                end
        end
        syncModelDropdownSelectionToManualTarget = function()
                if not modelDropdownControl or not modelDropdownControl.SetValue then
                        return
                end
                modelDropdownControl.SetValue(getModelDropdownLabelForSelection(resolveManualAttackTpTargetModel(), manualAttackTpPlayer), true)
        end
        refreshModelDropdown = function(preferredValue)
                if not modelDropdownControl or not modelDropdownControl.SetItems then
                        return
                end
                local allItems, _, displayNames = buildPlayerModelDropdownItems()
                if blPlayersDropdownControl then
                        if blPlayersDropdownControl.SetItemDisplayNames then
                                blPlayersDropdownControl.SetItemDisplayNames(displayNames)
                        end
                        blPlayersDropdownControl.SetItems(allItems, nil, true)
                        local blToCheck = {}
                        for lbl in pairs(blacklistedTargets) do
                                blToCheck[#blToCheck + 1] = lbl
                        end
                        if blPlayersDropdownControl.SetValue then
                                blPlayersDropdownControl.SetValue(blToCheck, true)
                        end
                        local newBLPlayers = {}
                        local newBLModels = {}
                        local newBLModelNames = {}
                        for lbl in pairs(blacklistedTargets) do
                                local entry = modelDropdownLookup[lbl]
                                if entry then
                                        if entry.player then
                                                newBLPlayers[entry.player] = true
                                        end
                                        if entry.model then
                                                newBLModels[entry.model] = true
                                                if not entry.player then
                                                        newBLModelNames[entry.model.Name] = true
                                                end
                                        end
                                end
                        end
                        blacklistedPlayers = newBLPlayers
                        blacklistedModels = newBLModels
                        blacklistedModelNames = newBLModelNames
                end
                local modelItems = {}
                for _, item in ipairs(allItems) do
                        local entry = modelDropdownLookup[item]
                        if item ~= "Friends" and not (entry and entry.isOffline) then
                                table.insert(modelItems, item)
                        end
                end
                local onlineBlacklist = {}
                for lbl, v in pairs(blacklistedTargets) do
                        local e = modelDropdownLookup[lbl]
                        if not (e and e.isOffline) then
                                onlineBlacklist[lbl] = v
                        end
                end
                if blacklistedTargets["Friends"] then
                        for lbl, e in pairs(modelDropdownLookup) do
                                if e and e.player and friendCache[e.player.UserId] then
                                        onlineBlacklist[lbl] = true
                                end
                        end
                end
                local nextPreferredValue = preferredValue
                if blacklistedTargets[nextPreferredValue] then
                        nextPreferredValue = nil
                end
                if hasManualAttackTpSelection() then
                        nextPreferredValue = getModelDropdownLabelForSelection(resolveManualAttackTpTargetModel(), manualAttackTpPlayer)
                elseif nextPreferredValue == nil and modelDropdownControl.GetValue then
                        nextPreferredValue = modelDropdownControl.GetValue()
                end
                if modelDropdownControl.SetItemDisplayNames then
                        modelDropdownControl.SetItemDisplayNames(displayNames)
                end
                if modelDropdownControl.SetDisabledItems then
                        modelDropdownControl.SetDisabledItems(onlineBlacklist)
                end
                modelDropdownControl.SetItems(modelItems, nil, true)
                if modelDropdownControl.SetValue then
                        modelDropdownControl.SetValue(nextPreferredValue, true)
                end
                syncModelDropdownSelectionToManualTarget()
        end
end
function updateDynamicDropdownDisplays()
        if not modelDropdownControl or not blPlayersDropdownControl then return end
        local displayNames = {}
        for label, entry in pairs(modelDropdownLookup) do
                if entry.isOffline then
                        displayNames[label] = string.format("%s | P | Offline", entry.baseNameStr)
                else
                        local hpStr = "0"
                        if entry.model then
                                local hum = entry.model:FindFirstChildOfClass("Humanoid")
                                if hum then
                                        hpStr = formatHPPercent(hum)
                                end
                        end
                        local isFriend = entry.player and friendCache[entry.player.UserId]
                        local fStr = isFriend and "F|" or ""
                        if entry.player then
                                if entry.dispNameStr and entry.dispNameStr ~= entry.baseNameStr then
                                        displayNames[label] = string.format("@%s|%s | %s%% | %s%s", entry.baseNameStr, entry.dispNameStr, hpStr, fStr, entry.pOrM)
                                else
                                        displayNames[label] = string.format("@%s | %s%% | %s%s", entry.baseNameStr, hpStr, fStr, entry.pOrM)
                                end
                        else
                                displayNames[label] = string.format("%s | %s%% | %s", entry.baseNameStr, hpStr, entry.pOrM)
                        end
                end
        end
        if blPlayersDropdownControl.SetItemDisplayNames then
                blPlayersDropdownControl.SetItemDisplayNames(displayNames)
        end
        if modelDropdownControl.SetItemDisplayNames then
                modelDropdownControl.SetItemDisplayNames(displayNames)
        end
end
stopView = function()
        viewing = false
        currentViewTarget = nil
        currentViewPlayer = nil
        if viewDied then
                viewDied:Disconnect()
                viewDied = nil
        end
        if viewChanged then
                viewChanged:Disconnect()
                viewChanged = nil
        end
        cam = Workspace.CurrentCamera or cam
        if player.Character and cam then
                local localHumanoid = player.Character:FindFirstChildOfClass("Humanoid")
                if localHumanoid then
                        cam.CameraType = Enum.CameraType.Custom
                        cam.CameraSubject = localHumanoid
                end
        end
        syncTargetActionControls()
        if syncViewKeybindDisplay then syncViewKeybindDisplay() end
end
startView = function()
        cam = Workspace.CurrentCamera or cam
        if not cam then
                return false
        end
        if viewDied then
                viewDied:Disconnect()
                viewDied = nil
        end
        if viewChanged then
                viewChanged:Disconnect()
                viewChanged = nil
        end
        local targetModel = resolveAttackTpTarget()
        local targetPlayer = hasTrackedSelectedPlayer() and manualAttackTpPlayer or Players:GetPlayerFromCharacter(targetModel)
        cam.CameraType = Enum.CameraType.Custom
        currentViewTarget = targetModel
        currentViewPlayer = targetPlayer
        viewing = true
        if currentViewPlayer then
                local viewedPlayer = currentViewPlayer
                viewDied = currentViewPlayer.CharacterAdded:Connect(function(newCharacter)
                        repeat
                                task.wait()
                        until not viewing or currentViewPlayer ~= viewedPlayer or newCharacter:FindFirstChildOfClass("Humanoid")
                        if viewing and currentViewPlayer == viewedPlayer and viewedPlayer.Character == newCharacter then
                                local newHumanoid = newCharacter:FindFirstChildOfClass("Humanoid")
                                if newHumanoid and cam then
                                        currentViewTarget = newCharacter
                                        cam.CameraType = Enum.CameraType.Custom
                                        cam.CameraSubject = newHumanoid
                                end
                        end
                end)
        end
        viewChanged = cam:GetPropertyChangedSignal("CameraSubject"):Connect(function()
                if not viewing then
                        return
                end
                local activeTarget = currentViewTarget
                if isDeadTargetModel(activeTarget) then
                        if currentViewPlayer and currentViewPlayer.Parent == Players then
                                local newTarget = getTrackedPlayerTargetModel(currentViewPlayer)
                                if isValidCamLockTarget(newTarget) then
                                        currentViewTarget = newTarget
                                        local newHumanoid = newTarget:FindFirstChildOfClass("Humanoid")
                                        if newHumanoid and cam.CameraSubject ~= newHumanoid then
                                                cam.CameraSubject = newHumanoid
                                        end
                                end
                        else
                                local hasDropdown = manualAttackTpPlayer or manualAttackTpTarget or manualAttackTpTargetName
                                if not hasDropdown then
                                        stopView()
                                else
                                        local activeHumanoid = activeTarget and activeTarget:FindFirstChildOfClass("Humanoid")
                                        if activeHumanoid and cam.CameraSubject ~= activeHumanoid then
                                                cam.CameraSubject = activeHumanoid
                                        end
                                end
                        end
                        return
                end
                local activeHumanoid = activeTarget and activeTarget:FindFirstChildOfClass("Humanoid")
                if activeHumanoid and cam.CameraSubject ~= activeHumanoid then
                        cam.CameraSubject = activeHumanoid
                end
        end)
        if not isValidCamLockTarget(targetModel) then
                local deadHum = targetModel and targetModel:FindFirstChildOfClass("Humanoid")
                if deadHum then
                        cam.CameraType = Enum.CameraType.Custom
                        cam.CameraSubject = deadHum
                end
                return true
        end
        local targetHumanoid = targetModel:FindFirstChildOfClass("Humanoid")
        if not targetHumanoid then
                local deadHum = targetModel and targetModel:FindFirstChildOfClass("Humanoid")
                if deadHum then
                        cam.CameraType = Enum.CameraType.Custom
                        cam.CameraSubject = deadHum
                end
                return true
        end
        cam.CameraType = Enum.CameraType.Custom
        cam.CameraSubject = targetHumanoid
        if syncViewKeybindDisplay then syncViewKeybindDisplay() end
        return true
end
toggleView = function(nextState)
        local shouldEnable = nextState
        if shouldEnable == nil then
                shouldEnable = not viewing
        end
        if shouldEnable then
                local hasDropdownSelection = manualAttackTpPlayer or manualAttackTpTarget or manualAttackTpTargetName
                if not hasDropdownSelection then
                        stopView()
                else
                        startView()
                end
        else
                stopView()
        end
        syncTargetActionControls()
        if syncViewKeybindDisplay then syncViewKeybindDisplay() end
        return viewing and "ON" or "OFF"
end
function teleportToSelectedTarget(modeOverride)
        if (_G.SafeTeleportLock == true) or isSafeZoneActive() then
                return
        end
        if not hasSelectedTargetOrPendingPlayer() then
                return
        end
        local character = player.Character
        local characterRoot = character and character:FindFirstChild("HumanoidRootPart")
        local characterHumanoid = character and character:FindFirstChildOfClass("Humanoid")
        local targetModel = resolveAttackTpTarget()
        if not characterRoot or not isAliveHumanoid(characterHumanoid) or isTpBlocked(targetModel) then
                return
        end
        if not isValidAttackTpTarget(targetModel) then
                if isWaitingForSelectedTargetRespawn() then
                        pendingTeleportToSelectedPlayer = true
                end
                return
        end
        pendingTeleportToSelectedPlayer = false
        local targetCFrame, targetVelocity = getAttackTpPlacement(characterRoot, targetModel, modeOverride)
        if not targetCFrame and targetModel and targetModel.Parent ~= nil then
                local targetRoot = targetModel:FindFirstChild("HumanoidRootPart")
                if targetRoot then
                        targetCFrame = CFrame.lookAt(targetRoot.Position + Vector3.new(0, 3, 0), targetRoot.Position, worldUpVector)
                        targetVelocity = Vector3.zero
                end
        end
        if not targetCFrame then
                return
        end
        applyTeleportRootState(characterRoot, targetCFrame, targetVelocity or Vector3.zero)
        if flying and bv and bg then
                bv.Position = characterRoot.Position
                bg.CFrame = getRotationOnlyCFrame(targetCFrame)
        end
end
function tog(data)
        data = data or {}
        local toggleName = tostring(data.name or "Toggle")
        local callback = data.fun
        local saveKey = tostring(data.saveKey or "")
        local enabled = data.default == true
        if saveKey ~= "" then
                local savedValue = getSavedControlValue(saveKey)
                if type(savedValue) == "boolean" then
                        enabled = savedValue
                end
        end
        local holder = makeControlFrame(48)
        holder.Parent = uiX
        local switchButton = Instance.new("TextButton")
        switchButton.BorderSizePixel = 0
        switchButton.Position = UDim2.fromScale(0.05, 0.15)
        switchButton.Size = UDim2.fromScale(0.9, 0.7)
        switchButton.AutoButtonColor = false
        switchButton.Font = Enum.Font.GothamBold
        switchButton.Text = toggleName
        switchButton.TextSize = 13
        switchButton.TextWrapped = true
        switchButton.ClipsDescendants = true
        switchButton.Parent = holder
        do
                local sbCorner = Instance.new("UICorner")
                sbCorner.CornerRadius = UDim.new(0, 6)
                sbCorner.Parent = switchButton
        end
        local function render()
                switchButton.BackgroundColor3 = enabled and Color3.fromRGB(255, 255, 255) or Color3.fromRGB(0, 0, 0)
                switchButton.BackgroundTransparency = 0
                switchButton.TextColor3 = enabled and Color3.fromRGB(0, 0, 0) or Color3.fromRGB(255, 255, 255)
        end
        switchButton.MouseButton1Click:Connect(function()
                enabled = not enabled
                render()
                if saveKey ~= "" then
                        setSavedControlValue(saveKey, enabled)
                end
                if callback then
                        callback(enabled)
                end
        end)
        render()
        return {
                Frame = holder,
                SetValue = function(nextState, suppressCallback)
                        enabled = nextState == true
                        render()
                        if not suppressCallback and callback then
                                callback(enabled)
                        end
                end,
                GetValue = function()
                        return enabled
                end,
        }
end
_G["3tog_on_one_one_button"] = function(data)
        data = data or {}
        local titleText = tostring(data.title or "Target")
        local firstName = tostring(data.name1 or "View")
        local secondName = tostring(data.name2 or "Auto TP")
        local thirdName = tostring(data.name3 or "Fling")
        local buttonName = tostring(data.buttonName or data.name4 or "TP")
        local toggle4Name = data.name4Tog
        local toggle4Callback = data.fun4Tog
        local toggle4Enabled = data.default4Tog == true
        local toggle5Name = data.name5Tog
        local toggle5Callback = data.fun5Tog
        local toggle5Enabled = data.default5Tog == true
        local firstCallback = data.fun1
        local secondCallback = data.fun2
        local thirdCallback = data.fun3
        local buttonCallback = data.buttonfun or data.fun4
        local firstEnabled = data.default1 == true
        local secondEnabled = data.default2 == true
        local thirdEnabled = data.default3 == true
        local holder = makeControlFrame(76)
        holder.Parent = uiX
        local titleLabel = Instance.new("TextLabel")
        titleLabel.BackgroundTransparency = 1
        titleLabel.Position = UDim2.new(0, 16, 0, 8)
        titleLabel.Size = UDim2.new(1, -32, 0, 18)
        titleLabel.Font = Enum.Font.GothamBold
        titleLabel.Text = titleText
        titleLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
        titleLabel.TextStrokeTransparency = 1
        titleLabel.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
        titleLabel.TextSize = 13
        titleLabel.TextScaled = false
        titleLabel.TextWrapped = true
        titleLabel.TextXAlignment = Enum.TextXAlignment.Left
        titleLabel.Parent = titleLabel.Parent or holder
        local rowFrame = Instance.new("Frame")
        rowFrame.BackgroundTransparency = 1
        rowFrame.Position = UDim2.new(0, 10, 0, 32)
        rowFrame.Size = UDim2.new(1, -20, 0, 32)
        rowFrame.Parent = holder
        local rowLayout = Instance.new("UIListLayout")
        rowLayout.FillDirection = Enum.FillDirection.Horizontal
        rowLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
        rowLayout.VerticalAlignment = Enum.VerticalAlignment.Center
        rowLayout.Padding = UDim.new(0, 6)
        rowLayout.Parent = rowFrame
        local segmentCount = 4
        if toggle4Name then segmentCount = segmentCount + 1 end
        if toggle5Name then segmentCount = segmentCount + 1 end
        local function createSegment(text, isToggle, initialState, callback)
                local segmentButton = Instance.new("TextButton")
                segmentButton.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
                segmentButton.BackgroundTransparency = 0
                segmentButton.BorderSizePixel = 0
                segmentButton.Size = UDim2.new(1/segmentCount, -5, 1, 0)
                segmentButton.AutoButtonColor = not isToggle
                segmentButton.Font = Enum.Font.GothamBold
                segmentButton.Text = tostring(text)
                segmentButton.TextStrokeTransparency = 1
                segmentButton.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
                segmentButton.TextSize = 13
                segmentButton.TextScaled = false
                segmentButton.TextWrapped = true
                segmentButton.Parent = rowFrame
                do
                        local sbCorner = Instance.new("UICorner")
                        sbCorner.CornerRadius = UDim.new(0, 6)
                        sbCorner.Parent = segmentButton
                end
                local enabled = initialState == true
                local function render()
                        if isToggle and enabled then
                                segmentButton.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
                                segmentButton.TextColor3 = Color3.fromRGB(0, 0, 0)
                                segmentButton.TextStrokeTransparency = 1
                        else
                                segmentButton.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
                                segmentButton.TextColor3 = Color3.fromRGB(255, 255, 255)
                                segmentButton.TextStrokeTransparency = 1
                        end
                end
                segmentButton.MouseButton1Click:Connect(function()
                        if isToggle then
                                enabled = not enabled
                                render()
                                if callback then
                                    callback(enabled)
                                end
                        else
                                if callback then
                                    callback()
                                end
                        end
                end)
                render()
                return {
                        Button = segmentButton,
                        SetValue = function(nextState, suppressCallback)
                                if not isToggle then
                                        return
                                end
                                enabled = nextState == true
                                render()
                                if not suppressCallback and callback then
                                        callback(enabled)
                                end
                        end,
                        GetValue = function()
                                return enabled
                        end,
                }
        end
        local firstControl = createSegment(firstName, true, firstEnabled, firstCallback)
        local secondControl = createSegment(secondName, true, secondEnabled, secondCallback)
        local thirdControl = createSegment(thirdName, true, thirdEnabled, thirdCallback)
        local fourthControl = nil
        if toggle4Name then
                fourthControl = createSegment(toggle4Name, true, toggle4Enabled, toggle4Callback)
        end
        local fifthControl = nil
        if toggle5Name then
                fifthControl = createSegment(toggle5Name, true, toggle5Enabled, toggle5Callback)
        end
        local buttonControl = createSegment(buttonName, false, false, buttonCallback)
        return {
                Frame = holder,
                First = firstControl,
                Second = secondControl,
                Third = thirdControl,
                Fourth = fourthControl,
                Fifth = fifthControl,
                Button = buttonControl,
        }
end
three_tog_on_one_one_button = _G["3tog_on_one_one_button"]
_G["4tog_on_one_frame"] = function(data)
        data = data or {}
        local titleText = tostring(data.title or "Fling")
        local saveKeys = {
                tostring(data.saveKey1 or ""),
                tostring(data.saveKey2 or ""),
                tostring(data.saveKey3 or ""),
                tostring(data.saveKey4 or ""),
        }
        local names = {
                tostring(data.name1 or "One"),
                tostring(data.name2 or "Two"),
                tostring(data.name3 or "Three"),
                tostring(data.name4 or "Four"),
        }
        local callbacks = {
                data.fun1,
                data.fun2,
                data.fun3,
                data.fun4,
        }
        local defaults = {
                data.default1 == true,
                data.default2 == true,
                data.default3 == true,
                data.default4 == true,
        }
        for index = 1, 4 do
                local saveKey = saveKeys[index]
                if saveKey ~= "" and type(controlSaveData[saveKey]) == "boolean" then
                        defaults[index] = controlSaveData[saveKey]
                end
        end
        local holder = makeControlFrame(76)
        holder.Parent = uiX
        local titleLabel = Instance.new("TextLabel")
        titleLabel.BackgroundTransparency = 1
        titleLabel.Position = UDim2.new(0, 16, 0, 8)
        titleLabel.Size = UDim2.new(1, -32, 0, 18)
        titleLabel.Font = Enum.Font.GothamBold
        titleLabel.Text = titleText
        titleLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
        titleLabel.TextStrokeTransparency = 1
        titleLabel.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
        titleLabel.TextSize = 13
        titleLabel.TextScaled = false
        titleLabel.TextWrapped = true
        titleLabel.TextXAlignment = Enum.TextXAlignment.Left
        titleLabel.Parent = holder
        local rowFrame = Instance.new("Frame")
        rowFrame.BackgroundTransparency = 1
        rowFrame.Position = UDim2.new(0, 10, 0, 32)
        rowFrame.Size = UDim2.new(1, -20, 0, 32)
        rowFrame.Parent = holder
        local rowLayout = Instance.new("UIListLayout")
        rowLayout.FillDirection = Enum.FillDirection.Horizontal
        rowLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
        rowLayout.VerticalAlignment = Enum.VerticalAlignment.Center
        rowLayout.Padding = UDim.new(0, 6)
        rowLayout.Parent = rowFrame
        local function createToggle(text, initialState, callback, saveKey)
                local button = Instance.new("TextButton")
                button.BackgroundTransparency = 0
                button.BorderSizePixel = 0
                button.Size = UDim2.new(0.25, -5, 1, 0)
                button.AutoButtonColor = false
                button.Font = Enum.Font.GothamBold
                button.Text = tostring(text)
                button.TextColor3 = Color3.fromRGB(255, 255, 255)
                button.TextStrokeTransparency = 1
                button.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
                button.TextSize = 13
                button.TextScaled = false
                button.TextWrapped = true
                button.Parent = rowFrame
                do
                        local btCorner = Instance.new("UICorner")
                        btCorner.CornerRadius = UDim.new(0, 6)
                        btCorner.Parent = button
                end
                local enabled = initialState == true
                local function render()
                        button.BackgroundColor3 = enabled and Color3.fromRGB(255, 255, 255) or Color3.fromRGB(0, 0, 0)
                        button.TextColor3 = enabled and Color3.fromRGB(0, 0, 0) or Color3.fromRGB(255, 255, 255)
                        button.TextStrokeTransparency = 1
                end
                local control = {}
                function control.SetValue(nextState, suppressCallback)
                        enabled = nextState == true
                        render()
                        if saveKey ~= "" then
                                controlSaveData[saveKey] = enabled
                                saveSliderSaveData()
                        end
                        if not suppressCallback and callback then
                                callback(enabled)
                        end
                end
                function control.GetValue()
                        return enabled
                end
                button.MouseButton1Click:Connect(function()
                        control.SetValue(not enabled)
                end)
                render()
                return control
        end
        local controls = {}
        for index = 1, 4 do
                controls[index] = createToggle(names[index], defaults[index], callbacks[index], saveKeys[index])
                if callbacks[index] then
                        callbacks[index](defaults[index])
                end
        end
        return {
                Frame = holder,
                First = controls[1],
                Second = controls[2],
                Third = controls[3],
                Fourth = controls[4],
        }
end
four_tog_on_one_frame = _G["4tog_on_one_frame"]
_G["5tog_on_one_frame"] = function(data)
        data = data or {}
        local titleText = tostring(data.title or "Overlay")
        local saveKeys = {
                tostring(data.saveKey1 or ""),
                tostring(data.saveKey2 or ""),
                tostring(data.saveKey3 or ""),
                tostring(data.saveKey4 or ""),
                tostring(data.saveKey5 or ""),
        }
        local names = {
                tostring(data.name1 or "One"),
                tostring(data.name2 or "Two"),
                tostring(data.name3 or "Three"),
                tostring(data.name4 or "Four"),
                tostring(data.name5 or "Five"),
        }
        local callbacks = {
                data.fun1,
                data.fun2,
                data.fun3,
                data.fun4,
                data.fun5,
        }
        local defaults = {
                data.default1 == true,
                data.default2 == true,
                data.default3 == true,
                data.default4 == true,
                data.default5 == true,
        }
        for index = 1, 5 do
                local saveKey = saveKeys[index]
                if saveKey ~= "" and type(controlSaveData[saveKey]) == "boolean" then
                        defaults[index] = controlSaveData[saveKey]
                end
        end
        local holder = makeControlFrame(82)
        holder.Parent = uiX
        local titleLabel = Instance.new("TextLabel")
        titleLabel.BackgroundTransparency = 1
        titleLabel.Position = UDim2.new(0, 16, 0, 8)
        titleLabel.Size = UDim2.new(1, -32, 0, 18)
        titleLabel.Font = Enum.Font.GothamBold
        titleLabel.Text = titleText
        titleLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
        titleLabel.TextStrokeTransparency = 1
        titleLabel.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
        titleLabel.TextSize = 13
        titleLabel.TextScaled = false
        titleLabel.TextWrapped = true
        titleLabel.TextXAlignment = Enum.TextXAlignment.Left
        titleLabel.Parent = holder
        local rowFrame = Instance.new("Frame")
        rowFrame.BackgroundTransparency = 1
        rowFrame.Position = UDim2.new(0, 8, 0, 34)
        rowFrame.Size = UDim2.new(1, -16, 0, 34)
        rowFrame.Parent = holder
        local rowLayout = Instance.new("UIListLayout")
        rowLayout.FillDirection = Enum.FillDirection.Horizontal
        rowLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
        rowLayout.VerticalAlignment = Enum.VerticalAlignment.Center
        rowLayout.Padding = UDim.new(0, 4)
        rowLayout.Parent = rowFrame
        local function createToggle(text, initialState, callback, saveKey)
                local button = Instance.new("TextButton")
                button.BackgroundTransparency = 0
                button.BorderSizePixel = 0
                button.Size = UDim2.new(0.2, -4, 1, 0)
                button.AutoButtonColor = false
                button.Font = Enum.Font.GothamBold
                button.Text = tostring(text)
                button.TextColor3 = Color3.fromRGB(255, 255, 255)
                button.TextStrokeTransparency = 1
                button.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
                button.TextSize = 13
                button.TextScaled = false
                button.TextWrapped = true
                button.Parent = rowFrame
                do
                        local bt5Corner = Instance.new("UICorner")
                        bt5Corner.CornerRadius = UDim.new(0, 6)
                        bt5Corner.Parent = button
                end
                local enabled = initialState == true
                local control = {}
                local function render()
                        button.BackgroundColor3 = enabled and Color3.fromRGB(255, 255, 255) or Color3.fromRGB(0, 0, 0)
                        button.TextColor3 = enabled and Color3.fromRGB(0, 0, 0) or Color3.fromRGB(255, 255, 255)
                        button.TextStrokeTransparency = 1
                end
                function control.SetValue(nextState, suppressCallback)
                        enabled = nextState == true
                        render()
                        if saveKey ~= "" then
                                controlSaveData[saveKey] = enabled
                                saveSliderSaveData()
                        end
                        if not suppressCallback and callback then
                                callback(enabled)
                        end
                end
                function control.GetValue()
                        return enabled
                end
                button.MouseButton1Click:Connect(function()
                        control.SetValue(not enabled)
                end)
                render()
                return control
        end
        local controls = {}
        for index = 1, 5 do
                controls[index] = createToggle(names[index], defaults[index], callbacks[index], saveKeys[index])
        end
        return {
                Frame = holder,
                First = controls[1],
                Second = controls[2],
                Third = controls[3],
                Fourth = controls[4],
                Fifth = controls[5],
        }
end
five_tog_on_one_frame = _G["5tog_on_one_frame"]
_G["2tog_on_one_button"] = function(data)
        data = data or {}
        local titleText = tostring(data.title or "Actions")
        local firstName = tostring(data.name1 or "First")
        local secondName = data.name2
        local buttonName = tostring(data.buttonName or data.name3 or "Run")
        local buttonName2 = data.buttonName2 or data.name4
        local buttonName3 = data.buttonName3 or data.name5
        local firstCallback = data.fun1
        local secondCallback = data.fun2
        local buttonCallback = data.buttonfun or data.fun3
        local buttonCallback2 = data.buttonfun2 or data.fun4
        local buttonCallback3 = data.buttonfun3 or data.fun5
        local firstEnabled = data.default1 == true
        local secondEnabled = data.default2 == true
        local hasSecondToggle = secondName ~= nil or secondCallback ~= nil or data.default2 ~= nil
        local hasSecondButton = buttonName2 ~= nil or buttonCallback2 ~= nil
        local hasThirdButton = buttonName3 ~= nil or buttonCallback3 ~= nil
        local segmentCount = 2
        if hasSecondToggle then
                segmentCount = segmentCount + 1
        end
        if hasSecondButton then
                segmentCount = segmentCount + 1
        end
        if hasThirdButton then
                segmentCount = segmentCount + 1
        end
        local holder = makeControlFrame(76)
        holder.Parent = uiX
        local titleLabel = Instance.new("TextLabel")
        titleLabel.BackgroundTransparency = 1
        titleLabel.Position = UDim2.new(0, 16, 0, 8)
        titleLabel.Size = UDim2.new(1, -32, 0, 18)
        titleLabel.Font = Enum.Font.GothamBold
        titleLabel.Text = titleText
        titleLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
        titleLabel.TextStrokeTransparency = 1
        titleLabel.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
        titleLabel.TextSize = 13
        titleLabel.TextScaled = false
        titleLabel.TextWrapped = true
        titleLabel.TextXAlignment = Enum.TextXAlignment.Left
        titleLabel.Parent = holder
        local rowFrame = Instance.new("Frame")
        rowFrame.BackgroundTransparency = 1
        rowFrame.Position = UDim2.new(0, 10, 0, 32)
        rowFrame.Size = UDim2.new(1, -20, 0, 32)
        rowFrame.Parent = holder
        local rowLayout = Instance.new("UIListLayout")
        rowLayout.FillDirection = Enum.FillDirection.Horizontal
        rowLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
        rowLayout.VerticalAlignment = Enum.VerticalAlignment.Center
        rowLayout.Padding = UDim.new(0, 6)
        rowLayout.Parent = rowFrame
        local function createSegment(text, isToggle, initialState, callback)
                local segmentButton = Instance.new("TextButton")
                segmentButton.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
                segmentButton.BackgroundTransparency = 0
                segmentButton.BorderSizePixel = 0
                segmentButton.Size = UDim2.new(1 / segmentCount, -5, 1, 0)
                segmentButton.AutoButtonColor = not isToggle
                segmentButton.Font = Enum.Font.GothamBold
                segmentButton.Text = tostring(text)
                segmentButton.TextColor3 = Color3.fromRGB(255, 255, 255)
                segmentButton.TextStrokeTransparency = 1
                segmentButton.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
                segmentButton.TextSize = 13
                segmentButton.TextScaled = false
                segmentButton.TextWrapped = true
                segmentButton.Parent = rowFrame
                do
                        local sb2Corner = Instance.new("UICorner")
                        sb2Corner.CornerRadius = UDim.new(0, 6)
                        sb2Corner.Parent = segmentButton
                end
                local enabled = initialState == true
                local function render()
                        if isToggle and enabled then
                                segmentButton.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
                                segmentButton.TextColor3 = Color3.fromRGB(0, 0, 0)
                                segmentButton.TextStrokeTransparency = 1
                        else
                                segmentButton.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
                                segmentButton.TextColor3 = Color3.fromRGB(255, 255, 255)
                                segmentButton.TextStrokeTransparency = 1
                        end
                end
                segmentButton.MouseButton1Click:Connect(function()
                        if isToggle then
                                enabled = not enabled
                                render()
                                if callback then
                                        callback(enabled)
                                end
                        elseif callback then
                                callback()
                        end
                end)
                render()
                return {
                        Button = segmentButton,
                        SetValue = function(nextState, suppressCallback)
                                if not isToggle then
                                        return
                                end
                                enabled = nextState == true
                                render()
                                if not suppressCallback and callback then
                                        callback(enabled)
                                end
                        end,
                        GetValue = function()
                                return enabled
                        end,
                        tog_change = function(_, nextState, suppressCallback)
                                if nextState == nil then
                                        enabled = not enabled
                                else
                                        enabled = nextState == true
                                end
                                render()
                                if not suppressCallback and callback then
                                        callback(enabled)
                                end
                                return enabled
                        end,
                }
        end
        local firstControl = createSegment(firstName, true, firstEnabled, firstCallback)
        local secondControl = hasSecondToggle and createSegment(tostring(secondName or "Second"), true, secondEnabled, secondCallback) or nil
        local buttonControl = createSegment(buttonName, false, false, buttonCallback)
        local buttonControl2 = hasSecondButton and createSegment(tostring(buttonName2 or "Run 2"), false, false, buttonCallback2) or nil
        local buttonControl3 = hasThirdButton and createSegment(tostring(buttonName3 or "Run 3"), false, false, buttonCallback3) or nil
        return {
                Frame = holder,
                First = firstControl,
                Second = secondControl,
                Button = buttonControl,
                Button2 = buttonControl2,
                Button3 = buttonControl3,
        }
end
two_tog_on_one_button = _G["2tog_on_one_button"]
function button(data)
        data = data or {}
        local buttonName = tostring(data.name or data.button or "Button")
        local callback = data.fun
        local holder = makeControlFrame(60)
        holder.Parent = uiX
        local actionButton = Instance.new("TextButton")
        actionButton.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
        actionButton.BackgroundTransparency = 0
        actionButton.BorderSizePixel = 0
        actionButton.Position = UDim2.fromScale(0.05, 0.16)
        actionButton.Size = UDim2.fromScale(0.9, 0.56)
        actionButton.AutoButtonColor = false
        actionButton.Font = Enum.Font.GothamBold
        actionButton.Text = buttonName
        actionButton.TextColor3 = Color3.fromRGB(255, 255, 255)
        actionButton.TextStrokeTransparency = 1
        actionButton.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
        actionButton.TextSize = 13
        actionButton.TextScaled = false
        actionButton.TextWrapped = true
        actionButton.Parent = holder
        do
                local btnCorner = Instance.new("UICorner")
                btnCorner.CornerRadius = UDim.new(0, 6)
                btnCorner.Parent = actionButton
        end
        actionButton.MouseButton1Click:Connect(function()
                if callback then
                        callback()
                end
        end)
        return holder
end
function Speed_bind(value)
        local decoded = decodeKeybindValue(value)
        if decoded == nil then
                return encodeKeybindValue(speedKeybind)
        end
        speedKeybind = decoded
        syncSpeedKeybindDisplay()
        return encodeKeybindValue(speedKeybind)
end
function Speed_tog(value)
        if value == nil then
                return active and "ON" or "OFF"
        end
        return toggleSpeed(parseEnabledValue(value))
end
function Speed_set(value)
        if value == nil then
                return Speed
        end
        Speed = math.max(0, tonumber(value) or Speed)
        return Speed
end
function Speed_key(value)
        return Speed_bind(value)
end
function Speed_value(value)
        return Speed_set(value)
end
function Speed_on()
        return toggleSpeed(true)
end
function Speed_off()
        return toggleSpeed(false)
end
function Speed_toggle()
        return toggleSpeed()
end
function CFrame_key(value)
        return Speed_bind(value)
end
function CFrame_value(value)
        return Speed_set(value)
end
function CFrame_on()
        return Speed_on()
end
function CFrame_off()
        return Speed_off()
end
function CFrame_toggle()
        return Speed_toggle()
end
function Fly_bind(value)
        local decoded = decodeKeybindValue(value)
        if decoded == nil then
                return encodeKeybindValue(flyKeybind)
        end
        flyKeybind = decoded
        syncFlyKeybindDisplay()
        return encodeKeybindValue(flyKeybind)
end
function Fly_tog(value)
        if value == nil then
                return flying and "ON" or "OFF"
        end
        return toggleFly(parseEnabledValue(value))
end
function Fly_set(value)
        if value == nil then
                return flySpeed
        end
        flySpeed = math.max(0, tonumber(value) or flySpeed)
        return flySpeed
end
function Fly_on()
        return toggleFly(true)
end
function Fly_off()
        return toggleFly(false)
end
function Fly_toggle()
        return toggleFly()
end
function CamLock_bind(value)
        local decoded = decodeKeybindValue(value)
        if decoded == nil then
                return encodeKeybindValue(camLockKeybind)
        end
        camLockKeybind = decoded
        syncCamLockKeybindDisplay()
        return encodeKeybindValue(camLockKeybind)
end
function CamLock_tog(value)
        if value == nil then
                return camLockEnabled and "ON" or "OFF"
        end
        return toggleCamLock(parseEnabledValue(value))
end
function CamLock_on()
        return toggleCamLock(true)
end
function CamLock_off()
        return toggleCamLock(false)
end
function CamLock_toggle()
        return toggleCamLock()
end
function AttackTP_bind(value)
        local decoded = decodeKeybindValue(value)
        if decoded == nil then
                return encodeKeybindValue(attackTpKeybind)
        end
        attackTpKeybind = decoded
        syncAttackTpKeybindDisplay()
        return encodeKeybindValue(attackTpKeybind)
end
function AttackTP_tog(value)
        if value == nil then
                return attackTpEnabled and "ON" or "OFF"
        end
        return toggleAttackTp(parseEnabledValue(value))
end
function AttackTP_on()
        return toggleAttackTp(true)
end
function AttackTP_off()
        return toggleAttackTp(false)
end
function AttackTP_toggle()
        return toggleAttackTp()
end
function Orbit_bind(value)
        local decoded = decodeKeybindValue(value)
        if decoded == nil then
                return encodeKeybindValue(orbitKeybind or "")
        end
        orbitKeybind = decoded
        setSavedControlValue("OrbitKeybind", encodeKeybindValue(orbitKeybind))
        syncOrbitKeybindDisplay()
        return encodeKeybindValue(orbitKeybind)
end
function Orbit_tog(value)
        if value == nil then
                return orbitEnabled and "ON" or "OFF"
        end
        if parseEnabledValue(value) then
                startOrbit()
        else
                stopOrbit()
        end
        return orbitEnabled and "ON" or "OFF"
end
function Orbit_key(value)
        return Orbit_tog(value)
end
function Orbit_toggle()
        if orbitEnabled then
                stopOrbit()
        else
                startOrbit()
        end
        return orbitEnabled and "ON" or "OFF"
end
function View_bind(value)
        local decoded = decodeKeybindValue(value)
        if decoded == nil then
                return encodeKeybindValue(viewKeybind)
        end
        viewKeybind = decoded
        setSavedControlValue("ViewKeybind", encodeKeybindValue(viewKeybind))
        syncViewKeybindDisplay()
        return encodeKeybindValue(viewKeybind)
end
function View_key(value)
        return View_bind(value)
end
function View_tog(value)
        if value == nil then
                return viewing and "ON" or "OFF"
        end
        toggleView(parseEnabledValue(value))
        syncViewKeybindDisplay()
        return viewing and "ON" or "OFF"
end
function View_on()
        toggleView(true)
        syncViewKeybindDisplay()
        return viewing and "ON" or "OFF"
end
function View_off()
        toggleView(false)
        syncViewKeybindDisplay()
        return viewing and "ON" or "OFF"
end
function View_toggle()
        toggleView()
        syncViewKeybindDisplay()
        return viewing and "ON" or "OFF"
end
function AutoTP_bind(value)
        local decoded = decodeKeybindValue(value)
        if decoded == nil then
                return encodeKeybindValue(autoTpKeybind)
        end
        autoTpKeybind = decoded
        setSavedControlValue("AutoTPKeybind", encodeKeybindValue(autoTpKeybind))
        syncAutoTpKeybindDisplay()
        return encodeKeybindValue(autoTpKeybind)
end
function AutoTP_key(value)
        return AutoTP_bind(value)
end
function AutoTP_tog(value)
        if value == nil then
                return autoTpEnabled and "ON" or "OFF"
        end
        local nextState = parseEnabledValue(value)
        if nextState and not (manualAttackTpPlayer or manualAttackTpTarget or manualAttackTpTargetName) then
                syncAutoTpKeybindDisplay()
                return "OFF"
        end
        local wasEnabled = autoTpEnabled
        autoTpEnabled = nextState == true
        if wasEnabled and not autoTpEnabled then
                zeroLocalPlayerRoot()
        end
        syncTargetActionControls()
        syncAutoTpKeybindDisplay()
        return autoTpEnabled and "ON" or "OFF"
end
function AutoTP_on()
        return AutoTP_tog(true)
end
function AutoTP_off()
        return AutoTP_tog(false)
end
function AutoTP_toggle()
        local nextState = not autoTpEnabled
        if nextState and not (manualAttackTpPlayer or manualAttackTpTarget or manualAttackTpTargetName) then
                syncAutoTpKeybindDisplay()
                return "OFF"
        end
        local wasEnabled = autoTpEnabled
        autoTpEnabled = nextState
        if wasEnabled and not autoTpEnabled then
                zeroLocalPlayerRoot()
        end
        syncTargetActionControls()
        syncAutoTpKeybindDisplay()
        return autoTpEnabled and "ON" or "OFF"
end
function Stay_tog(value)
        if not StayToggle or not StayToggle.GetValue then
                return "OFF"
        end
        if value == nil then
                return StayToggle:GetValue() and "ON" or "OFF"
        end
        return StayToggle:SetValue(parseEnabledValue(value)) and "ON" or "OFF"
end
function Stay_on()
        return Stay_tog(true)
end
function Stay_off()
        return Stay_tog(false)
end
function Stay_toggle()
        if not StayToggle or not StayToggle.tog_change then
                return "OFF"
        end
        return StayToggle:tog_change() and "ON" or "OFF"
end
function DashBlockFE_tog(value)
        if not DashToggle or not DashToggle.GetValue then
                return "OFF"
        end
        if value == nil then
                return DashToggle:GetValue() and "ON" or "OFF"
        end
        return DashToggle:SetValue(parseEnabledValue(value)) and "ON" or "OFF"
end
function DashBlockFE_on()
        return DashBlockFE_tog(true)
end
function DashBlockFE_off()
        return DashBlockFE_tog(false)
end
function DashBlockFE_toggle()
        if not DashToggle or not DashToggle.tog_change then
                return "OFF"
        end
        return DashToggle:tog_change() and "ON" or "OFF"
end
function Target_bind(value)
        local decoded = decodeKeybindValue(value)
        if decoded == nil then
                return encodeKeybindValue(targetSelectKeybind)
        end
        targetSelectKeybind = decoded
        syncTargetPickKeybindDisplay()
        return encodeKeybindValue(targetSelectKeybind)
end
updateKeybindText()
syncSpeedKeybindDisplay()
syncFlyKeybindDisplay()
syncCamLockKeybindDisplay()
syncAttackTpKeybindDisplay()
syncTargetPickKeybindDisplay()
syncWalkFlingKeybindDisplay()
syncSetBackKeybindDisplay()
syncGetTrashKeybindDisplay()
syncViewKeybindDisplay()
syncAutoTpKeybindDisplay()
syncOrbitKeybindDisplay()
updateTargetDisplay()
bindLocalCharacter(char)
Slider({
        nameSilder = "Speed",
        nameshow = "",
        max = 25,
        min = 0.1,
        default = Speed,
        saveKey = "Speed",
        fun = function(value)
                Speed = value
        end,
})
Slider({
        nameSilder = "Fly",
        nameshow = "",
        max = 25,
        min = 0.1,
        default = flySpeed,
        saveKey = "FlySpeed",
        fun = function(value)
                flySpeed = value
        end,
})
modelDropdownControl = Dropdown({
        namedropdown = "Players",
        saveKey = "",
        inside = {},
        multi = false,
        allowDeselect = true,
        deffultin = nil,
        fun = function(value)
                applyModelDropdownSelection(value)
        end,
})
blPlayersDropdownControl = Dropdown({
        namedropdown = "BL Players",
        saveKey = "",
        inside = {},
        multi = true,
        hideSelectionText = true,
        deffultin = nil,
        fun = function(value)
                if not blPlayersDropdownControl then return end
                local newBlacklist = {}
                local newBLPlayers = {}
                local newBLModels = {}
                local newBLModelNames = {}
                if type(value) == "table" then
                        for _, label in ipairs(value) do
                                newBlacklist[label] = true
                                local entry = modelDropdownLookup[label]
                                if entry then
                                        if entry.player then
                                                newBLPlayers[entry.player] = true
                                        end
                                        if entry.model then
                                                newBLModels[entry.model] = true
                                                if not entry.player then
                                                        newBLModelNames[entry.model.Name] = true
                                                end
                                        end
                                end
                        end
                end
                blacklistedTargets = newBlacklist
                blacklistedPlayers = newBLPlayers
                blacklistedModels = newBLModels
                blacklistedModelNames = newBLModelNames
                for label, entry in pairs(modelDropdownLookup) do
                        if entry.player and not entry.isOffline and not newBlacklist[label] then
                                if offlinePlayers[entry.baseNameStr] then
                                        offlinePlayers[entry.baseNameStr] = nil
                                end
                        end
                end
                do
                        local blNames = {}
                        for label in pairs(newBlacklist) do
                                local entry = modelDropdownLookup[label]
                                if entry and entry.player and not entry.isOffline and entry.baseNameStr then
                                        blNames[#blNames + 1] = entry.baseNameStr
                                end
                        end
                        controlSaveData.BLPlayerNames = blNames
                        controlSaveData.BLFriends = newBlacklist["Friends"] == true
                        controlSaveData.OfflinePlayers = offlinePlayers
                        saveSliderSaveData()
                end
                local currentTargetLabel = getModelDropdownLabelForSelection(manualAttackTpTarget, manualAttackTpPlayer)
                if currentTargetLabel and blacklistedTargets[currentTargetLabel] then
                        setManualAttackTpTarget(nil)
                        if modelDropdownControl and modelDropdownControl.SetValue then
                                modelDropdownControl.SetValue(nil, true)
                        end
                end
                if blacklistedTargets["Friends"] and manualAttackTpPlayer and friendCache[manualAttackTpPlayer.UserId] then
                        setManualAttackTpTarget(nil)
                        if modelDropdownControl and modelDropdownControl.SetValue then
                                modelDropdownControl.SetValue(nil, true)
                        end
                end
                if modelDropdownControl and modelDropdownControl.SetDisabledItems then
                        modelDropdownControl.SetDisabledItems(blacklistedTargets)
                end
                if type(value) == "table" then
                        local checkedSet = {}
                        for _, lbl in ipairs(value) do checkedSet[lbl] = true end
                        for label, entry in pairs(modelDropdownLookup) do
                                if entry.isOffline and not checkedSet[label] then
                                        if not offlineDeletionTimers[label] then
                                                offlineDeletionTimers[label] = true
                                                local capturedLabel = label
                                                local capturedName = entry.offlineName
                                                task.delay(0, function()
                                                        if offlineDeletionTimers[capturedLabel] then
                                                                offlineDeletionTimers[capturedLabel] = nil
                                                                offlinePlayers[capturedName] = nil
                                                                blacklistedTargets[capturedLabel] = nil
                                                                local blNames = {}
                                                                for lbl in pairs(blacklistedTargets) do
                                                                        local e = modelDropdownLookup[lbl]
                                                                        if e and e.player and not e.isOffline and e.baseNameStr then
                                                                                blNames[#blNames + 1] = e.baseNameStr
                                                                        end
                                                                end
                                                                controlSaveData.BLPlayerNames = blNames
                                                                controlSaveData.OfflinePlayers = offlinePlayers
                                                                saveSliderSaveData()
                                                                if refreshModelDropdown then refreshModelDropdown() end
                                                        end
                                                end)
                                        end
                                elseif entry.isOffline and checkedSet[label] then
                                        offlineDeletionTimers[label] = nil
                                end
                        end
                        for label, entry in pairs(modelDropdownLookup) do
                                if not entry.isOffline and not checkedSet[label] then
                                        if entry.player and not (entry.player.Parent == Players) then
                                                if not offlineDeletionTimers[label] then
                                                        offlineDeletionTimers[label] = true
                                                        local capturedLabel = label
                                                        task.delay(0, function()
                                                                if offlineDeletionTimers[capturedLabel] then
                                                                        offlineDeletionTimers[capturedLabel] = nil
                                                                        blacklistedTargets[capturedLabel] = nil
                                                                        local blNames = {}
                                                                        for lbl in pairs(blacklistedTargets) do
                                                                                local e = modelDropdownLookup[lbl]
                                                                                if e and e.player and not e.isOffline and e.baseNameStr then
                                                                                        blNames[#blNames + 1] = e.baseNameStr
                                                                                end
                                                                        end
                                                                        controlSaveData.BLPlayerNames = blNames
                                                                        controlSaveData.OfflinePlayers = offlinePlayers
                                                                        saveSliderSaveData()
                                                                        if refreshModelDropdown then refreshModelDropdown() end
                                                                end
                                                        end)
                                                end
                                        end
                                end
                        end
                end
        end,
})
do
        local offlineInputHolder = makeControlFrame(78)
        offlineInputHolder.Parent = uiX
        local offlineLabel = Instance.new("TextLabel")
        offlineLabel.BackgroundTransparency = 1
        offlineLabel.Position = UDim2.new(0, 10, 0, 5)
        offlineLabel.Size = UDim2.new(1, -20, 0, 16)
        offlineLabel.Font = Enum.Font.GothamBold
        offlineLabel.Text = "BL Offline"
        offlineLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
        offlineLabel.TextStrokeTransparency = 1
        offlineLabel.TextSize = 13
        offlineLabel.TextXAlignment = Enum.TextXAlignment.Left
        offlineLabel.Parent = offlineInputHolder
        local offlineBox = Instance.new("TextBox")
        offlineBox.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
        offlineBox.BackgroundTransparency = 0.5
        offlineBox.BorderSizePixel = 0
        offlineBox.Position = UDim2.new(0, 10, 0, 26)
        offlineBox.Size = UDim2.new(1, -70, 0, 26)
        offlineBox.Font = Enum.Font.GothamBold
        offlineBox.TextColor3 = Color3.fromRGB(255, 255, 255)
        offlineBox.TextSize = 13
        offlineBox.Text = ""
        offlineBox.PlaceholderText = "user id..."
        offlineBox.PlaceholderColor3 = Color3.fromRGB(120, 120, 120)
        offlineBox.ClearTextOnFocus = true
        offlineBox.Parent = offlineInputHolder
        do
                local boxCorner = Instance.new("UICorner")
                boxCorner.CornerRadius = UDim.new(0, 4)
                boxCorner.Parent = offlineBox
        end
        offlineBox:GetPropertyChangedSignal("Text"):Connect(function()
                local raw = offlineBox.Text
                local filtered = raw:gsub("[^%d]", "")
                if #filtered > 21 then filtered = filtered:sub(1, 21) end
                if filtered ~= raw then
                        offlineBox.Text = filtered
                end
        end)
        local statusLabel = Instance.new("TextLabel")
        statusLabel.BackgroundTransparency = 1
        statusLabel.Position = UDim2.new(0, 10, 0, 56)
        statusLabel.Size = UDim2.new(1, -70, 0, 16)
        statusLabel.Font = Enum.Font.GothamBold
        statusLabel.Text = ""
        statusLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
        statusLabel.TextStrokeTransparency = 1
        statusLabel.TextTransparency = 1
        statusLabel.TextSize = 12
        statusLabel.TextXAlignment = Enum.TextXAlignment.Center
        statusLabel.Parent = offlineInputHolder
        local function showStatus(text, duration)
                statusLabel.Text = text
                statusLabel.TextTransparency = 0
                if duration then
                        task.delay(duration, function()
                                if statusLabel.Text == text then
                                        statusLabel.TextTransparency = 1
                                end
                        end)
                end
        end
        local addBtn = Instance.new("TextButton")
        addBtn.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
        addBtn.BackgroundTransparency = 0
        addBtn.BorderSizePixel = 0
        addBtn.Position = UDim2.new(1, -56, 0, 26)
        addBtn.Size = UDim2.new(0, 50, 0, 26)
        addBtn.Font = Enum.Font.GothamBold
        addBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
        addBtn.TextSize = 13
        addBtn.Text = "Add"
        addBtn.AutoButtonColor = false
        addBtn.Parent = offlineInputHolder
        do
                local btnCorner = Instance.new("UICorner")
                btnCorner.CornerRadius = UDim.new(0, 6)
                btnCorner.Parent = addBtn
        end
        local function doAddOffline()
                local raw = offlineBox.Text:gsub("[^%d]", "")
                if #raw == 0 then return end
                if #raw > 21 then raw = raw:sub(1, 21) end
                offlineBox.Text = ""
                showStatus("Analyzing . . .")
                addBtn.Active = false
                task.spawn(function()
                        local HttpService = game:GetService("HttpService")
                        local userId = tonumber(raw)
                        local realName, displayName
                        if not userId then
                                showStatus("Not Found (404)", 3)
                                addBtn.Active = true
                                return
                        end
                        if userId == Players.LocalPlayer.UserId then
                                showStatus("Is You", 3)
                                addBtn.Active = true
                                return
                        end
                        local ok, name = pcall(function()
                                return Players:GetNameFromUserIdAsync(userId)
                        end)
                        if ok and name then
                                realName = name
                                displayName = name
                        else
                                showStatus("Not Found (404)", 3)
                                addBtn.Active = true
                                return
                        end
                        local lblOnline = "[P] " .. realName
                        local lblOffline = lblOnline .. " (Offline)"
                        if blacklistedTargets[lblOnline] or blacklistedTargets[lblOffline] or offlinePlayers[realName] then
                                showStatus("Already Added", 3)
                                addBtn.Active = true
                                return
                        end
                        showStatus("Adding . . .")
                        local okHttp, result = pcall(function()
                                return game:HttpGet("https://users.roblox.com/v1/users/" .. tostring(userId))
                        end)
                        if not okHttp then
                                okHttp, result = pcall(function()
                                        return HttpService:GetAsync("https://users.roblox.com/v1/users/" .. tostring(userId))
                                end)
                        end
                        if okHttp and result then
                                local ok2, data = pcall(function() return HttpService:JSONDecode(result) end)
                                if ok2 and data and data.displayName then
                                        displayName = data.displayName
                                end
                        end
                        offlinePlayers[realName] = { name = realName, displayName = displayName, userId = userId }
                        local label = "[P] " .. realName .. " (Offline)"
                        blacklistedTargets[label] = true
                        offlineDeletionTimers[label] = nil
                        controlSaveData.OfflinePlayers = offlinePlayers
                        saveSliderSaveData()
                        showStatus("Added", 2)
                        addBtn.Active = true
                        if refreshModelDropdown then refreshModelDropdown() end
                        if blPlayersDropdownControl and blPlayersDropdownControl.SetValue then
                                local toCheck = {}
                                for lbl in pairs(blacklistedTargets) do
                                        toCheck[#toCheck + 1] = lbl
                                end
                                blPlayersDropdownControl.SetValue(toCheck, false)
                        end
                end)
        end
        addBtn.MouseButton1Click:Connect(doAddOffline)
        offlineBox.FocusLost:Connect(function(enterPressed)
                if enterPressed then doAddOffline() end
        end)
end
targetActionControls = _G["3tog_on_one_one_button"]({
        title = "Function",
        name1 = "View",
        name2 = "Auto TP",
        name3 = "Fling",
        name4Tog = "(V)",
        name5Tog = "(B)",
        buttonName = "TP",
        default1 = viewing,
        default2 = autoTpEnabled,
        default3 = flingEnabled,
        default4Tog = dVoidDeadActive,
        default5Tog = bHitEnabled,
        fun1 = function(enabled)
                if enabled and not (manualAttackTpPlayer or manualAttackTpTarget) then
                        targetActionControls.First.SetValue(false, true)
                        return
                end
                toggleView(enabled)
                if syncViewKeybindDisplay then syncViewKeybindDisplay() end
        end,
        fun2 = function(enabled)
                if enabled and not (manualAttackTpPlayer or manualAttackTpTarget) then
                        targetActionControls.Second.SetValue(false, true)
                        return
                end
                local wasEnabled = autoTpEnabled
                autoTpEnabled = enabled
                if wasEnabled and not enabled then
                        zeroLocalPlayerRoot()
                end
                syncTargetActionControls()
                if syncAutoTpKeybindDisplay then syncAutoTpKeybindDisplay() end
        end,
        fun3 = function(enabled)
                if enabled and not (manualAttackTpPlayer or manualAttackTpTarget) then
                        targetActionControls.Third.SetValue(false, true)
                        return
                end
                local wasEnabled = flingEnabled
                flingEnabled = enabled
                if wasEnabled and not enabled then
                        zeroLocalPlayerRoot()
                end
                syncTargetActionControls()
        end,
        fun4Tog = function(enabled)
                toggleDVoidDead(enabled)
        end,
        fun5Tog = function(enabled)
                toggleBHit(enabled)
        end,
        buttonfun = function()
                if not (manualAttackTpPlayer or manualAttackTpTarget) then
                        return
                end
                teleportToSelectedTarget("Front")
        end,
})
do
        local wfHolder = makeControlFrame(76)
        wfHolder.Parent = uiX
        local wfTitle = Instance.new("TextLabel")
        wfTitle.BackgroundTransparency = 1
        wfTitle.Position = UDim2.new(0, 16, 0, 8)
        wfTitle.Size = UDim2.new(1, -32, 0, 18)
        wfTitle.Font = Enum.Font.GothamBold
        wfTitle.Text = "Walk Fling"
        wfTitle.TextColor3 = Color3.fromRGB(255, 255, 255)
        wfTitle.TextStrokeTransparency = 1
        wfTitle.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
        wfTitle.TextSize = 13
        wfTitle.TextScaled = false
        wfTitle.TextWrapped = true
        wfTitle.TextXAlignment = Enum.TextXAlignment.Left
        wfTitle.Parent = wfHolder
        local wfRow = Instance.new("Frame")
        wfRow.BackgroundTransparency = 1
        wfRow.Position = UDim2.new(0, 10, 0, 32)
        wfRow.Size = UDim2.new(1, -20, 0, 32)
        wfRow.Parent = wfHolder
        local wfLayout = Instance.new("UIListLayout")
        wfLayout.FillDirection = Enum.FillDirection.Horizontal
        wfLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
        wfLayout.VerticalAlignment = Enum.VerticalAlignment.Center
        wfLayout.Padding = UDim.new(0, 6)
        wfLayout.Parent = wfRow
        local wfAllCtrls = {}
        local function makeWFTog(text, startEnabled, onSelect)
                local btn = Instance.new("TextButton")
                btn.BackgroundTransparency = 0
                btn.BorderSizePixel = 0
                btn.Size = UDim2.new(1/3, -5, 1, 0)
                btn.AutoButtonColor = false
                btn.Font = Enum.Font.GothamBold
                btn.Text = text
                btn.TextSize = 13
                btn.TextScaled = false
                btn.TextWrapped = true
                btn.TextStrokeTransparency = 1
                btn.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
                btn.Parent = wfRow
                local corner = Instance.new("UICorner")
                corner.CornerRadius = UDim.new(0, 6)
                corner.Parent = btn
                local enabled = startEnabled == true
                local ctrl = {}
                local function render()
                        btn.BackgroundColor3 = enabled and Color3.fromRGB(255, 255, 255) or Color3.fromRGB(0, 0, 0)
                        btn.TextColor3 = enabled and Color3.fromRGB(0, 0, 0) or Color3.fromRGB(255, 255, 255)
                end
                function ctrl.SetValue(v)
                        enabled = v == true
                        render()
                end
                btn.MouseButton1Click:Connect(function()
                        for _, c in pairs(wfAllCtrls) do c.SetValue(false) end
                        ctrl.SetValue(true)
                        onSelect()
                        saveSliderSaveData()
                end)
                render()
                return ctrl
        end
        wfAllCtrls[1] = makeWFTog("Body",   walkFlingBodyMode == true,   function() walkFlingBodyMode = true   end)
        wfAllCtrls[2] = makeWFTog("Camera", walkFlingBodyMode == false,  function() walkFlingBodyMode = false  end)
        wfAllCtrls[3] = makeWFTog("C+B",    walkFlingBodyMode == "both", function() walkFlingBodyMode = "both" end)
end
Dropdown({
        namedropdown = "Direction",
        saveKey = "WalkFlingDirection",
        inside = { "Forward", "Backward", "Upward", "Downward", "Right", "Left" },
        multi = true,
        deffultin = { "Forward" },
        fun = function(value)
                parseWalkFlingDirectionSelection(value)
        end,
})
_G["2textbox_on_one_frame"]({
        title = "Powers",
        name1 = "Power Walkfling",
        name2 = "Power Flings",
        default1 = walkFlingPower,
        default2 = flingPower,
        saveKey1 = "WalkFlingPower",
        saveKey2 = "FlingPower",
        fun1 = function(value)
                walkFlingPower = value
        end,
        fun2 = function(value)
                flingPower = value
        end,
})
Slider({
        nameSilder = "Aura Range",
        nameshow = "",
        max = 5000,
        min = 1,
        default = auraRange,
        saveKey = "AuraRange",
        fun = function(value)
                auraRange = value
        end,
})
flingModeControls = _G["4tog_on_one_frame"]({
        title = "Flings System",
        name1 = "Normal Walkfling",
        name2 = "Aura Fling",
        name3 = "Click Fling",
        name4 = "Fling All",
        default1 = walkFlingUseNormal,
        default2 = auraFlingEnabled,
        default3 = clickFlingEnabled,
        default4 = flingAllEnabled,
        fun1 = function(enabled)
                walkFlingUseNormal = enabled
                setSavedControlValue("WalkFlingUseNormal", walkFlingUseNormal)
                syncFlingModeControls()
        end,
        fun2 = function(enabled)
                setAuraFlingEnabled(enabled)
        end,
        fun3 = function(enabled)
                setClickFlingEnabled(enabled)
        end,
        fun4 = function(enabled)
                setFlingAllEnabled(enabled)
        end,
})
task.spawn(function()
        local savedOD = getSavedControlValue("OrbitDistance")
        if savedOD ~= nil then orbitDistance = savedOD end
        local savedSH = getSavedControlValue("OrbitSpeedH")
        if savedSH ~= nil then orbitSpeedH = savedSH end
        local savedSV = getSavedControlValue("OrbitSpeedV")
        if savedSV ~= nil then orbitSpeedV = savedSV end
        local savedOM = getSavedControlValue("OrbitMode")
        if savedOM ~= nil then orbitMode = savedOM end
        for i = 1, 16 do
                local prefix = "OrbitC" .. i
                local function ls(key, default)
                        local v = getSavedControlValue(prefix .. key)
                        return v ~= nil and v or default
                end
                _G["__orbitPresetLoad" .. i] = { Left=ls("Left",0), Right=ls("Right",0), Up=ls("Up",0), Down=ls("Down",0), Front=ls("Front",0), Back=ls("Back",0), Speed=ls("Speed",1) }
        end
        local savedACP = getSavedControlValue("OrbitActiveCustomPreset")
        local savedACPNum = tonumber(savedACP) or 0
        function stopOrbit()
                orbitEnabled = false
                orbitCachedTarget = nil
                if orbitConnection then
                        orbitConnection:Disconnect()
                        orbitConnection = nil
                end
                updateOrbitToggleButton()
                syncOrbitKeybindDisplay()
        end
        orbitCustomEnabled = false
        orbitCustomLeft  = 0
        orbitCustomRight = 0
        orbitCustomUp    = 0
        orbitCustomDown  = 0
        orbitCustomFront = 0
        orbitCustomBack  = 0
        orbitCustomSpeed = 1
        orbitAdaptBody = false
        orbitAdaptPosition = false
        orbitAdaptRotation = false
        local function hasValidSelectedOrbitTarget()
                if manualAttackTpPlayer then
                        return manualAttackTpPlayer.Parent == Players
                end
                if manualAttackTpTargetName ~= nil or manualAttackTpTarget ~= nil then
                        local targetName = manualAttackTpTargetName or (manualAttackTpTarget and manualAttackTpTarget.Name)
                        if targetName then
                                local wasPlayer = false
                                for _, p in ipairs(Players:GetPlayers()) do
                                        if p.Name == targetName then
                                                wasPlayer = true
                                                break
                                        end
                                end
                                if wasPlayer then
                                        local p = Players:FindFirstChild(targetName)
                                        return p ~= nil and p.Parent == Players
                                end
                        end
                        return true
                end
                return false
        end
        function resolveOrbitTarget()
                local model = resolveManualAttackTpTargetModel()
                if model and model.Parent ~= nil then
                        return model
                end
                return nil
        end
        function startOrbit()
                stopOrbit()
                if not hasValidSelectedOrbitTarget() then
                        updateOrbitToggleButton()
                        syncOrbitKeybindDisplay()
                        return
                end
                orbitEnabled = true
                orbitAngleH = 0
                orbitAngleV = 0
                orbitCachedTarget = resolveOrbitTarget()
                updateOrbitToggleButton()
                syncOrbitKeybindDisplay()
                orbitConnection = RunService.Heartbeat:Connect(function(dt)
                        if not orbitEnabled then
                                if orbitConnection then orbitConnection:Disconnect(); orbitConnection = nil end
                                return
                        end
                        if not hasValidSelectedOrbitTarget() then
                                stopOrbit()
                                return
                        end
                        local character = player.Character
                        local myRoot = character and character:FindFirstChild("HumanoidRootPart")
                        if not myRoot then return end
                        orbitCachedTarget = resolveOrbitTarget()
                        local targetModel = orbitCachedTarget
                        if not targetModel or targetModel.Parent == nil then
                                return
                        end
                        local targetRoot = targetModel:FindFirstChild("HumanoidRootPart")
                        if not targetRoot then
                                return
                        end
                        local targetPos = targetRoot.Position
                        local targetCF  = targetRoot.CFrame
                        if orbitAdaptBody then
                                targetPos = targetCF.Position
                        end
                        if orbitAdaptPosition then
                                targetPos = targetRoot.Position
                        end
                        local dist = math.max(0, orbitDistance)
                        local ox, oy, oz
                        if orbitCustomEnabled then
                                orbitAngleV = orbitAngleV + orbitCustomSpeed * dt
                                local s = math.sin(orbitAngleV)
                                local c = math.cos(orbitAngleV)
                                local centreUD = (orbitCustomUp    - orbitCustomDown)  * 0.5
                                local radiusUD = (orbitCustomUp    + orbitCustomDown)  * 0.5
                                local centreLR = (orbitCustomRight - orbitCustomLeft)  * 0.5
                                local radiusLR = (orbitCustomRight + orbitCustomLeft)  * 0.5
                                local centreFB = (orbitCustomFront - orbitCustomBack)  * 0.5
                                local radiusFB = (orbitCustomFront + orbitCustomBack)  * 0.5
                                local ampUp    = centreUD + radiusUD * s
                                local ampRight = centreLR + radiusLR * c
                                local ampFront = centreFB + radiusFB * s
                                local tRight = targetCF.RightVector
                                local tUp    = targetCF.UpVector
                                local tFront = targetCF.LookVector
                                local worldOff = tRight * ampRight + tUp * ampUp + tFront * ampFront
                                ox = worldOff.X; oy = worldOff.Y; oz = worldOff.Z
                        elseif orbitMode == "Horizontal" then
                                orbitAngleH = orbitAngleH + orbitSpeedH * dt
                                ox = math.cos(orbitAngleH) * dist
                                oy = 0
                                oz = math.sin(orbitAngleH) * dist
                        elseif orbitMode == "Vertical" then
                                orbitAngleV = orbitAngleV + orbitSpeedV * dt
                                local cosV = math.cos(orbitAngleV)
                                local sinV = math.sin(orbitAngleV)
                                local localFront = Vector3.new(0, sinV, cosV) * dist
                                local worldOff = targetCF:VectorToWorldSpace(localFront)
                                ox = worldOff.X; oy = worldOff.Y; oz = worldOff.Z
                        elseif orbitMode == "Both" then
                                orbitAngleH = orbitAngleH + orbitSpeedH * dt
                                orbitAngleV = orbitAngleV + orbitSpeedV * dt
                                local cosV = math.cos(orbitAngleV)
                                local sinV = math.sin(orbitAngleV)
                                local cosH = math.cos(orbitAngleH)
                                local sinH = math.sin(orbitAngleH)
                                local localOff = Vector3.new(sinH * cosV, sinV, cosH * cosV) * dist
                                local worldOff = targetCF:VectorToWorldSpace(localOff)
                                ox = worldOff.X; oy = worldOff.Y; oz = worldOff.Z
                        elseif orbitMode == "Random" then
                                local angleH = math.random() * math.pi * 2
                                local angleV = (math.random() - 0.5) * math.pi
                                local cosV = math.cos(angleV)
                                local sinV = math.sin(angleV)
                                local cosH = math.cos(angleH)
                                local sinH = math.sin(angleH)
                                local localOff = Vector3.new(sinH * cosV, sinV, cosH * cosV) * dist
                                local worldOff = targetCF:VectorToWorldSpace(localOff)
                                ox = worldOff.X; oy = worldOff.Y; oz = worldOff.Z
                        else
                                orbitAngleH = orbitAngleH + orbitSpeedH * dt
                                ox = math.cos(orbitAngleH) * dist
                                oy = 0
                                oz = math.sin(orbitAngleH) * dist
                        end
                        local newPos = targetPos + Vector3.new(ox, oy, oz)
                        local lookDir = (targetPos - newPos)
                        if lookDir.Magnitude < 0.01 then return end
                        local upVec = Vector3.new(0, 1, 0)
                        if orbitAdaptRotation then
                                upVec = targetCF.UpVector
                        end
                        local newCF = CFrame.lookAt(newPos, targetPos, upVec)
                        if walkFlingEnabled then
                                local power = walkFlingPower or 20000
                                local direction = getWalkFlingDirectionVector and getWalkFlingDirectionVector(myRoot) or myRoot.CFrame.LookVector
                                local resolvedLinear = direction * power
                                local resolvedAngular = Vector3.new(power * 2, power * 2, power * 2)
                                applyTeleportRootState(myRoot, newCF, resolvedLinear, resolvedAngular)
                        else
                                applyTeleportRootState(myRoot, newCF, Vector3.zero, Vector3.zero)
                        end
                end)
        end
        local orbitHub = makeControlFrame(486)
        orbitHub.Parent = uiX
        orbitHub.ClipsDescendants = true
        orbitHub.LayoutOrder = 999997
        local orbitTitle = Instance.new("TextLabel")
        orbitTitle.BackgroundTransparency = 1
        orbitTitle.Position = UDim2.new(0, 16, 0, 8)
        orbitTitle.Size = UDim2.new(1, -32, 0, 18)
        orbitTitle.Font = Enum.Font.GothamBold
        orbitTitle.Text = "Orbit"
        orbitTitle.TextColor3 = Color3.fromRGB(255, 255, 255)
        orbitTitle.TextStrokeTransparency = 1
        orbitTitle.TextSize = 14
        orbitTitle.TextXAlignment = Enum.TextXAlignment.Left
        orbitTitle.Parent = orbitHub
        local function makeOrbitInput(yPos, labelText, defVal, saveKey, onChanged, allowInf)
                local lbl = Instance.new("TextLabel")
                lbl.BackgroundTransparency = 1
                lbl.Position = UDim2.new(0, 10, 0, yPos)
                lbl.Size = UDim2.new(0.54, -12, 0, 22)
                lbl.Font = Enum.Font.GothamBold
                lbl.Text = labelText
                lbl.TextColor3 = Color3.fromRGB(220, 220, 220)
                lbl.TextSize = 12
                lbl.TextScaled = false
                lbl.TextWrapped = true
                lbl.TextXAlignment = Enum.TextXAlignment.Left
                lbl.Parent = orbitHub
                local box = Instance.new("TextBox")
                box.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
                box.BackgroundTransparency = 0.5
                box.BorderSizePixel = 0
                box.Position = UDim2.new(0.56, 0, 0, yPos)
                box.Size = UDim2.new(0.4, -4, 0, 22)
                box.ClearTextOnFocus = false
                box.Font = Enum.Font.GothamBold
                box.Text = tostring(defVal)
                box.TextColor3 = Color3.fromRGB(255, 255, 255)
                box.TextSize = 12
                box.TextScaled = false
                box.Parent = orbitHub
                local bc = Instance.new("UICorner")
                bc.CornerRadius = UDim.new(0, 4)
                bc.Parent = box
                box:GetPropertyChangedSignal("Text"):Connect(function()
                        local t = box.Text
                        local f = allowInf
                                and t:gsub("[^0-9%-%.eEiInNfF%+]", "")
                                or  t:gsub("[^0-9%-%.eE]", "")
                        if f ~= t then box.Text = f end
                end)
                box.Focused:Connect(function() box.Text = "" end)
                box.FocusLost:Connect(function()
                        local rawText = tostring(box.Text or ""):match("^%s*(.-)%s*$")
                        if allowInf then
                                local loweredText = string.lower(rawText)
                                if loweredText == "inf" then
                                        rawText = "20e20"
                                elseif loweredText == "inf+" then
                                        rawText = "50e50"
                                elseif loweredText == "inf++" then
                                        rawText = "99e99"
                                elseif loweredText == "inf+++" then
                                        rawText = "999e999"
                                end
                        end
                        local v = tonumber(rawText)
                        if v then
                                box.Text = tostring(v)
                                if saveKey then setSavedControlValue(saveKey, v) end
                                if onChanged then onChanged(v) end
                        else
                                box.Text = tostring(defVal)
                        end
                end)
                return box
        end
        makeOrbitInput(34,  "Horizontal (speed)", orbitSpeedH,  "OrbitSpeedH",   function(v) orbitSpeedH = v end,   true)
        makeOrbitInput(62,  "Vertical (speed)",   orbitSpeedV,  "OrbitSpeedV",   function(v) orbitSpeedV = v end,   true)
        makeOrbitInput(90,  "Distance",           orbitDistance,"OrbitDistance", function(v) orbitDistance = v end, false)
        local dirLabel = Instance.new("TextLabel")
        dirLabel.BackgroundTransparency = 1
        dirLabel.Position = UDim2.new(0, 10, 0, 118)
        dirLabel.Size = UDim2.new(1, -20, 0, 14)
        dirLabel.Font = Enum.Font.GothamBold
        dirLabel.Text = "Direction"
        dirLabel.TextColor3 = Color3.fromRGB(180, 180, 180)
        dirLabel.TextSize = 11
        dirLabel.TextXAlignment = Enum.TextXAlignment.Left
        dirLabel.Parent = orbitHub
        local dirRow = Instance.new("Frame")
        dirRow.BackgroundTransparency = 1
        dirRow.Position = UDim2.new(0, 6, 0, 134)
        dirRow.Size = UDim2.new(1, -12, 0, 28)
        dirRow.Parent = orbitHub
        local dirLayout = Instance.new("UIListLayout")
        dirLayout.FillDirection = Enum.FillDirection.Horizontal
        dirLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
        dirLayout.VerticalAlignment = Enum.VerticalAlignment.Center
        dirLayout.Padding = UDim.new(0, 4)
        dirLayout.Parent = dirRow
        local dirBtns = {}
        local modeList   = {"Horizontal", "Vertical", "Both", "Random"}
        local modeLabels = {"H",          "V",        "V+H",  "Rnd"}
        local customPresets = {
                { Left=0, Right=0, Up=0, Down=0, Front=0, Back=0, Speed=1 },
                { Left=0, Right=0, Up=0, Down=0, Front=0, Back=0, Speed=1 },
                { Left=0, Right=0, Up=0, Down=0, Front=0, Back=0, Speed=1 },
                { Left=0, Right=0, Up=0, Down=0, Front=0, Back=0, Speed=1 },
                { Left=0, Right=0, Up=0, Down=0, Front=0, Back=0, Speed=1 },
                { Left=0, Right=0, Up=0, Down=0, Front=0, Back=0, Speed=1 },
                { Left=0, Right=0, Up=0, Down=0, Front=0, Back=0, Speed=1 },
                { Left=0, Right=0, Up=0, Down=0, Front=0, Back=0, Speed=1 },
                { Left=0, Right=0, Up=0, Down=0, Front=0, Back=0, Speed=1 },
                { Left=0, Right=0, Up=0, Down=0, Front=0, Back=0, Speed=1 },
                { Left=0, Right=0, Up=0, Down=0, Front=0, Back=0, Speed=1 },
                { Left=0, Right=0, Up=0, Down=0, Front=0, Back=0, Speed=1 },
                { Left=0, Right=0, Up=0, Down=0, Front=0, Back=0, Speed=1 },
                { Left=0, Right=0, Up=0, Down=0, Front=0, Back=0, Speed=1 },
                { Left=0, Right=0, Up=0, Down=0, Front=0, Back=0, Speed=1 },
                { Left=0, Right=0, Up=0, Down=0, Front=0, Back=0, Speed=1 },
        }
        for i = 1, 16 do
                local ld = _G["__orbitPresetLoad" .. i]
                if ld then customPresets[i] = ld; _G["__orbitPresetLoad" .. i] = nil end
        end
        local activeCustomPreset = 0
        local customBoxRefs = {}
        local function loadPresetToBoxes(idx)
                local p = customPresets[idx]
                if not p then return end
                orbitCustomLeft  = p.Left
                orbitCustomRight = p.Right
                orbitCustomUp    = p.Up
                orbitCustomDown  = p.Down
                orbitCustomFront = p.Front
                orbitCustomBack  = p.Back
                orbitCustomSpeed = p.Speed
                if customBoxRefs.Left   then customBoxRefs.Left.Text   = tostring(p.Left)   end
                if customBoxRefs.Right  then customBoxRefs.Right.Text  = tostring(p.Right)  end
                if customBoxRefs.Up     then customBoxRefs.Up.Text     = tostring(p.Up)     end
                if customBoxRefs.Down   then customBoxRefs.Down.Text   = tostring(p.Down)   end
                if customBoxRefs.Front  then customBoxRefs.Front.Text  = tostring(p.Front)  end
                if customBoxRefs.Back   then customBoxRefs.Back.Text   = tostring(p.Back)   end
                if customBoxRefs.Speed  then customBoxRefs.Speed.Text  = tostring(p.Speed)  end
        end
        local function saveBoxesToPreset(idx)
                local p = customPresets[idx]
                if not p then return end
                p.Left  = orbitCustomLeft
                p.Right = orbitCustomRight
                p.Up    = orbitCustomUp
                p.Down  = orbitCustomDown
                p.Front = orbitCustomFront
                p.Back  = orbitCustomBack
                p.Speed = orbitCustomSpeed
                local prefix = "OrbitC" .. idx
                setSavedControlValue(prefix .. "Left",  p.Left)
                setSavedControlValue(prefix .. "Right", p.Right)
                setSavedControlValue(prefix .. "Up",    p.Up)
                setSavedControlValue(prefix .. "Down",  p.Down)
                setSavedControlValue(prefix .. "Front", p.Front)
                setSavedControlValue(prefix .. "Back",  p.Back)
                setSavedControlValue(prefix .. "Speed", p.Speed)
        end
        local presetBtns = {}
        local function renderAllModeBtns()
                local isCustomActive = (activeCustomPreset ~= 0)
                for _, e in ipairs(dirBtns) do
                        local on = (not isCustomActive) and (e.mode == orbitMode)
                        e.btn.BackgroundColor3 = on and Color3.fromRGB(255,255,255) or Color3.fromRGB(0,0,0)
                        e.btn.TextColor3       = on and Color3.fromRGB(0,0,0)       or Color3.fromRGB(255,255,255)
                end
                for i, btn in ipairs(presetBtns) do
                        local on = (activeCustomPreset == i)
                        btn.BackgroundColor3 = on and Color3.fromRGB(255,255,255) or Color3.fromRGB(0,0,0)
                        btn.TextColor3       = on and Color3.fromRGB(0,0,0)       or Color3.fromRGB(255,255,255)
                end
                for _, box in pairs(customBoxRefs) do
                        if isCustomActive then
                                box.TextEditable = true
                                box.BackgroundTransparency = 0.5
                                box.TextColor3 = Color3.fromRGB(255, 255, 255)
                        else
                                box.TextEditable = false
                                box.BackgroundTransparency = 0.75
                                box.TextColor3 = Color3.fromRGB(100, 100, 100)
                        end
                end
        end
        for idx = 1, 4 do
                local m = modeList[idx]
                local btn = Instance.new("TextButton")
                btn.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
                btn.BackgroundTransparency = 0
                btn.BorderSizePixel = 0
                btn.Size = UDim2.new(1/4, -4, 1, 0)
                btn.Font = Enum.Font.GothamBold
                btn.Text = modeLabels[idx]
                btn.TextColor3 = Color3.fromRGB(255, 255, 255)
                btn.TextStrokeTransparency = 1
                btn.TextSize = 11
                btn.TextScaled = false
                btn.TextWrapped = true
                btn.AutoButtonColor = false
                btn.Parent = dirRow
                local bc2 = Instance.new("UICorner")
                bc2.CornerRadius = UDim.new(0, 6)
                bc2.Parent = btn
                dirBtns[idx] = {btn = btn, mode = m}
                btn.MouseButton1Click:Connect(function()
                        if activeCustomPreset ~= 0 then
                                saveBoxesToPreset(activeCustomPreset)
                        end
                        activeCustomPreset = 0
                        orbitCustomEnabled = false
                        orbitMode = m
                        setSavedControlValue("OrbitMode", m)
                        setSavedControlValue("OrbitActiveCustomPreset", 0)
                        renderAllModeBtns()
                end)
        end
        local customPresetLabel = Instance.new("TextLabel")
        customPresetLabel.BackgroundTransparency = 1
        customPresetLabel.Position = UDim2.new(0, 10, 0, 168)
        customPresetLabel.Size = UDim2.new(1, -20, 0, 14)
        customPresetLabel.Font = Enum.Font.GothamBold
        customPresetLabel.Text = "Custom"
        customPresetLabel.TextColor3 = Color3.fromRGB(180, 180, 180)
        customPresetLabel.TextSize = 11
        customPresetLabel.TextXAlignment = Enum.TextXAlignment.Left
        customPresetLabel.Parent = orbitHub
        local function makePresetRow(yOff, startIdx, endIdx)
                local pRow = Instance.new("Frame")
                pRow.BackgroundTransparency = 1
                pRow.Position = UDim2.new(0, 6, 0, yOff)
                pRow.Size = UDim2.new(1, -12, 0, 24)
                pRow.Parent = orbitHub
                local pLayout = Instance.new("UIListLayout")
                pLayout.FillDirection = Enum.FillDirection.Horizontal
                pLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
                pLayout.VerticalAlignment = Enum.VerticalAlignment.Center
                pLayout.Padding = UDim.new(0, 3)
                pLayout.Parent = pRow
                local count = endIdx - startIdx + 1
                for i = startIdx, endIdx do
                        local pbtn = Instance.new("TextButton")
                        pbtn.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
                        pbtn.BackgroundTransparency = 0
                        pbtn.BorderSizePixel = 0
                        pbtn.Size = UDim2.new(1/count, -3, 1, 0)
                        pbtn.Font = Enum.Font.GothamBold
                        pbtn.Text = "C" .. i
                        pbtn.TextColor3 = Color3.fromRGB(255, 255, 255)
                        pbtn.TextStrokeTransparency = 1
                        pbtn.TextSize = 10
                        pbtn.TextScaled = false
                        pbtn.TextWrapped = true
                        pbtn.AutoButtonColor = false
                        pbtn.Parent = pRow
                        local pbc = Instance.new("UICorner")
                        pbc.CornerRadius = UDim.new(0, 6)
                        pbc.Parent = pbtn
                        presetBtns[i] = pbtn
                        local idx = i
                        pbtn.MouseButton1Click:Connect(function()
                                if activeCustomPreset ~= 0 then
                                        saveBoxesToPreset(activeCustomPreset)
                                end
                                activeCustomPreset = idx
                                orbitCustomEnabled = true
                                loadPresetToBoxes(idx)
                                setSavedControlValue("OrbitActiveCustomPreset", idx)
                                renderAllModeBtns()
                        end)
                end
        end
        makePresetRow(184, 1, 8)
        makePresetRow(211, 9, 16)
        renderAllModeBtns()
        if savedACPNum >= 1 and savedACPNum <= 16 then
                activeCustomPreset = savedACPNum
                orbitCustomEnabled = true
                loadPresetToBoxes(savedACPNum)
                renderAllModeBtns()
        end
        orbitTogBtn = Instance.new("TextButton")
        orbitTogBtn.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
        orbitTogBtn.BackgroundTransparency = 0
        orbitTogBtn.BorderSizePixel = 0
        orbitTogBtn.Position = UDim2.new(0.05, 0, 0, 244)
        orbitTogBtn.Size = UDim2.new(0.9, 0, 0, 24)
        orbitTogBtn.Font = Enum.Font.GothamBold
        orbitTogBtn.Text = "Orbit"
        orbitTogBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
        orbitTogBtn.TextStrokeTransparency = 1
        orbitTogBtn.TextSize = 13
        orbitTogBtn.AutoButtonColor = false
        orbitTogBtn.Parent = orbitHub
        local bc3 = Instance.new("UICorner")
        bc3.CornerRadius = UDim.new(0, 6)
        bc3.Parent = orbitTogBtn
        orbitTogBtn.MouseButton1Click:Connect(function()
                Orbit_toggle()
        end)
        local customLabel = Instance.new("TextLabel")
        customLabel.BackgroundTransparency = 1
        customLabel.Position = UDim2.new(0, 10, 0, 274)
        customLabel.Size = UDim2.new(1, -20, 0, 14)
        customLabel.Font = Enum.Font.GothamBold
        customLabel.Text = "Custom Offset"
        customLabel.TextColor3 = Color3.fromRGB(220, 220, 220)
        customLabel.TextSize = 13
        customLabel.TextXAlignment = Enum.TextXAlignment.Left
        customLabel.Parent = orbitHub
        local function makeCustomSingleBox(yPos, labelText, refKey, getter, setter, allowInf)
                local lbl = Instance.new("TextLabel")
                lbl.BackgroundTransparency = 1
                lbl.Position = UDim2.new(0, 10, 0, yPos)
                lbl.Size = UDim2.new(0.48, -12, 0, 22)
                lbl.Font = Enum.Font.GothamBold
                lbl.Text = labelText
                lbl.TextColor3 = Color3.fromRGB(200, 200, 200)
                lbl.TextSize = 12
                lbl.TextScaled = false
                lbl.TextXAlignment = Enum.TextXAlignment.Left
                lbl.Parent = orbitHub
                local box = Instance.new("TextBox")
                box.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
                box.BackgroundTransparency = 0.5
                box.BorderSizePixel = 0
                box.Position = UDim2.new(0.52, 2, 0, yPos)
                box.Size = UDim2.new(0.44, -6, 0, 22)
                box.ClearTextOnFocus = false
                box.Font = Enum.Font.GothamBold
                box.Text = tostring(getter())
                box.TextColor3 = Color3.fromRGB(255, 255, 255)
                box.TextSize = 12
                box.TextScaled = false
                box.Parent = orbitHub
                local bc = Instance.new("UICorner")
                bc.CornerRadius = UDim.new(0, 4)
                bc.Parent = box
                box:GetPropertyChangedSignal("Text"):Connect(function()
                        local t = box.Text
                        local f = allowInf
                                and t:gsub("[^0-9%-%.iInNfFeE%+]", "")
                                or  t:gsub("[^0-9%-%.]", "")
                        if f ~= t then box.Text = f end
                end)
                box.Focused:Connect(function()
                        if not box.TextEditable then
                                box:ReleaseFocus()
                                return
                        end
                        box.Text = ""
                end)
                box.FocusLost:Connect(function()
                        local rawText = tostring(box.Text or ""):match("^%s*(.-)%s*$")
                        if allowInf then
                                local loweredText = string.lower(rawText)
                                if loweredText == "inf" then
                                        rawText = "20e20"
                                elseif loweredText == "inf+" then
                                        rawText = "50e50"
                                elseif loweredText == "inf++" then
                                        rawText = "99e99"
                                elseif loweredText == "inf+++" then
                                        rawText = "999e999"
                                end
                        end
                        local v = tonumber(rawText)
                        if v then
                                setter(v)
                                box.Text = tostring(v)
                                if activeCustomPreset ~= 0 then
                                        saveBoxesToPreset(activeCustomPreset)
                                end
                        else
                                box.Text = tostring(getter())
                        end
                end)
                if refKey then customBoxRefs[refKey] = box end
                return box
        end
        makeCustomSingleBox(296, "Left",  "Left",
                function() return orbitCustomLeft  end, function(v) orbitCustomLeft  = v end, false)
        makeCustomSingleBox(322, "Right", "Right",
                function() return orbitCustomRight end, function(v) orbitCustomRight = v end, false)
        makeCustomSingleBox(348, "Up",    "Up",
                function() return orbitCustomUp    end, function(v) orbitCustomUp    = v end, false)
        makeCustomSingleBox(374, "Down",  "Down",
                function() return orbitCustomDown  end, function(v) orbitCustomDown  = v end, false)
        makeCustomSingleBox(400, "Front", "Front",
                function() return orbitCustomFront end, function(v) orbitCustomFront = v end, false)
        makeCustomSingleBox(426, "Back",  "Back",
                function() return orbitCustomBack  end, function(v) orbitCustomBack  = v end, false)
        makeCustomSingleBox(452, "Speed", "Speed",
                function() return orbitCustomSpeed end, function(v) orbitCustomSpeed = v end, true)
        renderAllModeBtns()
end)
if game.GameId == 3808081382 then
        placesDropdown = Dropdown({
                namedropdown = "Places",
                inside = placesOrder,
                multi = false,
                deffultin = selectedPlace,
                fun = function(value)
                        local isMainMap = not (game.PlaceId ~= 10449761463 and game.PlaceId ~= 131048399685555)
                        if not isMainMap then
                                local map = workspace:FindFirstChild("Map")
                                local hasFloor = map and map:FindFirstChild("Floor/Roads") ~= nil
                                if not hasFloor then
                                        if value ~= "/\\"
                                           and value ~= "Middle Of Map"
                                           and value ~= "Prison"
                                           and value ~= "Montain 1"
                                           and value ~= "Montain 2"
                                           and value ~= "Montain 2 Left"
                                           and value ~= "Montain 2 Right" then
                                            placesDropdown.SetValue("/\\", true)
                                            selectedPlace = "/\\"
                                            return
                                        end
                                end
                        end
                        selectedPlace = value
                        setSavedControlValue("SelectedPlace", value)
                        syncPlacesKeybindDisplay()
                end,
        })
        placesDropdown.Frame.LayoutOrder = 999998
        local function setupBringWallCombo()
                local bringWallHub = makeControlFrame(208)
                bringWallHub.Parent = uiX
                bringWallHub.LayoutOrder = 999997
                bringWallHub.ClipsDescendants = true
        local bwTitle = Instance.new("TextLabel")
        bwTitle.BackgroundTransparency = 1
        bwTitle.Position = UDim2.new(0, 16, 0, 4)
        bwTitle.Size = UDim2.new(1, -32, 0, 16)
        bwTitle.Font = Enum.Font.GothamBold
        bwTitle.Text = "Places Bring"
        bwTitle.TextColor3 = Color3.fromRGB(255, 255, 255)
        bwTitle.TextStrokeTransparency = 1
        bwTitle.TextSize = 13
        bwTitle.TextXAlignment = Enum.TextXAlignment.Left
        bwTitle.Parent = bringWallHub
        local savedWWC = getSavedControlValue("WaitWallCombo")
        if savedWWC ~= nil then WAIT_WALL_COMBO = savedWWC end
        local bwWaitLabel = Instance.new("TextLabel")
        bwWaitLabel.BackgroundTransparency = 1
        bwWaitLabel.Position = UDim2.new(0, 8, 0, 24)
        bwWaitLabel.Size = UDim2.new(0.55, -12, 0, 26)
        bwWaitLabel.Font = Enum.Font.GothamBold
        bwWaitLabel.Text = "Wait Before Tp"
        bwWaitLabel.TextColor3 = Color3.fromRGB(220, 220, 220)
        bwWaitLabel.TextSize = 12
        bwWaitLabel.TextScaled = false
        bwWaitLabel.TextWrapped = true
        bwWaitLabel.TextXAlignment = Enum.TextXAlignment.Left
        bwWaitLabel.Parent = bringWallHub
        local bwWaitBox = Instance.new("TextBox")
        bwWaitBox.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
        bwWaitBox.BackgroundTransparency = 0.5
        bwWaitBox.BorderSizePixel = 0
        bwWaitBox.Position = UDim2.new(0.57, 0, 0, 28)
        bwWaitBox.Size = UDim2.new(0.39, -4, 0, 22)
        bwWaitBox.ClearTextOnFocus = false
        bwWaitBox.Font = Enum.Font.GothamBold
        bwWaitBox.Text = tostring(WAIT_WALL_COMBO)
        bwWaitBox.TextColor3 = Color3.fromRGB(255, 255, 255)
        bwWaitBox.TextSize = 12
        bwWaitBox.TextScaled = false
        bwWaitBox.Parent = bringWallHub
        _G._bwWaitBoxRef = bwWaitBox
        local bwWaitCorner = Instance.new("UICorner")
        bwWaitCorner.CornerRadius = UDim.new(0, 4)
        bwWaitCorner.Parent = bwWaitBox
        bwWaitBox:GetPropertyChangedSignal("Text"):Connect(function()
                if _G.AutoWaitWallComboEnabled then return end
                local t = bwWaitBox.Text
                local f = t:gsub("[^0-9%.]", "")
                if f ~= t then bwWaitBox.Text = f end
        end)
        bwWaitBox.Focused:Connect(function()
                if _G.AutoWaitWallComboEnabled then
                        bwWaitBox:ReleaseFocus()
                        return
                end
                bwWaitBox.Text = ""
        end)
        bwWaitBox.FocusLost:Connect(function()
                if _G.AutoWaitWallComboEnabled then return end
                local v = tonumber(bwWaitBox.Text)
                if v ~= nil then
                        v = math.clamp(v, 0, 100)
                        WAIT_WALL_COMBO = v
                        setSavedControlValue("WaitWallCombo", v)
                        bwWaitBox.Text = tostring(v)
                else
                        bwWaitBox.Text = tostring(WAIT_WALL_COMBO)
                end
        end)
        local function updateBwWaitBoxState()
                if _G.AutoWaitWallComboEnabled then
                        bwWaitBox.Active = false
                        bwWaitBox.TextEditable = false
                        bwWaitBox.TextColor3 = Color3.fromRGB(100, 220, 120)
                        bwWaitBox.Text = "Auto"
                elseif _G.PingWaitWallComboEnabled then
                        bwWaitBox.Active = true
                        bwWaitBox.TextEditable = true
                        bwWaitBox.TextColor3 = Color3.fromRGB(220, 180, 100)
                        bwWaitBox.Text = tostring(WAIT_WALL_COMBO)
                else
                        bwWaitBox.Active = true
                        bwWaitBox.TextEditable = true
                        bwWaitBox.TextColor3 = Color3.fromRGB(255, 255, 255)
                        bwWaitBox.Text = tostring(WAIT_WALL_COMBO)
                end
        end
        local bwAutoRow = Instance.new("Frame")
        bwAutoRow.BackgroundTransparency = 1
        bwAutoRow.BorderSizePixel = 0
        bwAutoRow.Position = UDim2.new(0, 4, 0, 54)
        bwAutoRow.Size = UDim2.new(1, -8, 0, 26)
        bwAutoRow.Parent = bringWallHub
        local bwAutoLayout = Instance.new("UIListLayout")
        bwAutoLayout.FillDirection = Enum.FillDirection.Horizontal
        bwAutoLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
        bwAutoLayout.VerticalAlignment = Enum.VerticalAlignment.Center
        bwAutoLayout.Padding = UDim.new(0, 4)
        bwAutoLayout.Parent = bwAutoRow
        local toggleAuto, togglePing
        local initialAutoVal = true
        local savedAutoVal = getSavedControlValue("AutoWaitWallComboEnabled")
        if savedAutoVal ~= nil then initialAutoVal = savedAutoVal == true end
        _G.AutoWaitWallComboEnabled = initialAutoVal
        local initialPingVal = false
        local savedPingVal = getSavedControlValue("PingWaitWallComboEnabled")
        if savedPingVal ~= nil then initialPingVal = savedPingVal == true end
        _G.PingWaitWallComboEnabled = initialPingVal
        if initialAutoVal and initialPingVal then
                initialPingVal = false
        end
        toggleAuto = makeHubTog(bwAutoRow, "~ Auto ~", function(v)
                _G.AutoWaitWallComboEnabled = v
                if v and togglePing then
                        _G.PingWaitWallComboEnabled = false
                        togglePing.SetValue(false, true)
                end
                updateBwWaitBoxState()
        end, "AutoWaitWallComboEnabled", initialAutoVal, 1/2)
        togglePing = makeHubTog(bwAutoRow, "~ Ping ~", function(v)
                _G.PingWaitWallComboEnabled = v
                if v and toggleAuto then
                        _G.AutoWaitWallComboEnabled = false
                        toggleAuto.SetValue(false, true)
                end
                updateBwWaitBoxState()
        end, "PingWaitWallComboEnabled", initialPingVal, 1/2)
        local bwRow = Instance.new("Frame")
        bwRow.BackgroundTransparency = 1
        bwRow.BorderSizePixel = 0
        bwRow.Position = UDim2.new(0, 4, 0, 84)
        bwRow.Size = UDim2.new(1, -8, 0, 26)
        bwRow.Parent = bringWallHub
        local bwLayout = Instance.new("UIListLayout")
        bwLayout.FillDirection = Enum.FillDirection.Horizontal
        bwLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
        bwLayout.VerticalAlignment = Enum.VerticalAlignment.Center
        bwLayout.Padding = UDim.new(0, 4)
        bwLayout.Parent = bwRow
        makeHubTog(bwRow, "Bring Wall Combo ##", function(v)
                _G.BringWallComboEnabled = v
        end, "BringWallComboEnabled", false, 1)
        local bwPosLabel = Instance.new("TextLabel")
        bwPosLabel.BackgroundTransparency = 1
        bwPosLabel.Position = UDim2.new(0, 8, 0, 116)
        bwPosLabel.Size = UDim2.new(1, -16, 0, 14)
        bwPosLabel.Font = Enum.Font.GothamBold
        bwPosLabel.Text = "Bring Position"
        bwPosLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
        bwPosLabel.TextSize = 11
        bwPosLabel.TextXAlignment = Enum.TextXAlignment.Left
        bwPosLabel.Parent = bringWallHub
        local bwAxisBoxes = {}
        local function updateWallComboBringPos()
                local z = tonumber(bwAxisBoxes["Z"] and bwAxisBoxes["Z"].Text)
                local y = tonumber(bwAxisBoxes["Y"] and bwAxisBoxes["Y"].Text)
                local x = tonumber(bwAxisBoxes["X"] and bwAxisBoxes["X"].Text)
                if x and y and z then
                        wallComboBringCustomPos = Vector3.new(x, y, z)
                else
                        wallComboBringCustomPos = nil
                end
        end
        local function applyBringPos(pos)
                bwAxisBoxes["X"].Text = tostring(math.floor(pos.X * 10 + 0.5) / 10)
                bwAxisBoxes["Y"].Text = tostring(math.floor(pos.Y * 10 + 0.5) / 10)
                bwAxisBoxes["Z"].Text = tostring(math.floor(pos.Z * 10 + 0.5) / 10)
                for _, axis in ipairs({"X","Y","Z"}) do
                        setSavedControlValue("BringWallPos" .. axis, tonumber(bwAxisBoxes[axis].Text))
                end
                updateWallComboBringPos()
        end
        local axisLabels = {"Z", "Y", "X"}
        local totalW = 1
        local boxW = (totalW - 0.04) / 3
        for i, axis in ipairs(axisLabels) do
                local xStart = (i - 1) * (boxW + 0.02)
                local axLabel = Instance.new("TextLabel")
                axLabel.BackgroundTransparency = 1
                axLabel.Position = UDim2.new(xStart + 0.01, 0, 0, 132)
                axLabel.Size = UDim2.new(boxW, -2, 0, 12)
                axLabel.Font = Enum.Font.GothamBold
                axLabel.Text = axis
                axLabel.TextColor3 = Color3.fromRGB(180, 180, 180)
                axLabel.TextSize = 11
                axLabel.TextXAlignment = Enum.TextXAlignment.Center
                axLabel.Parent = bringWallHub
                local savedVal = getSavedControlValue("BringWallPos" .. axis)
                local initText = (savedVal ~= nil and tostring(savedVal)) or ""
                local axBox = Instance.new("TextBox")
                axBox.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
                axBox.BackgroundTransparency = 0.5
                axBox.BorderSizePixel = 0
                axBox.Position = UDim2.new(xStart + 0.01, 0, 0, 144)
                axBox.Size = UDim2.new(boxW, -2, 0, 22)
                axBox.ClearTextOnFocus = false
                axBox.Font = Enum.Font.GothamBold
                axBox.PlaceholderText = axis
                axBox.Text = initText
                axBox.TextColor3 = Color3.fromRGB(255, 255, 255)
                axBox.TextSize = 11
                axBox.TextScaled = false
                axBox.Parent = bringWallHub
                local axCorner = Instance.new("UICorner")
                axCorner.CornerRadius = UDim.new(0, 4)
                axCorner.Parent = axBox
                axBox:GetPropertyChangedSignal("Text"):Connect(function()
                        local t = axBox.Text
                        local f = t:gsub("[^0-9%.%-]", "")
                        if f ~= t then axBox.Text = f end
                end)
                local savedAxisText = initText
                axBox.Focused:Connect(function()
                        savedAxisText = axBox.Text
                        axBox.Text = ""
                end)
                axBox.FocusLost:Connect(function()
                        local t = axBox.Text
                        local v = tonumber(t)
                        if t == "" or v == nil then
                                axBox.Text = savedAxisText
                        else
                                savedAxisText = t
                                setSavedControlValue("BringWallPos" .. axis, v)
                        end
                        updateWallComboBringPos()
                end)
                bwAxisBoxes[axis] = axBox
        end
        updateWallComboBringPos()
        local function makeBwBtn(xScale, wScale, label, onClick)
                local btn = Instance.new("TextButton")
                btn.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
                btn.BackgroundTransparency = 0
                btn.BorderSizePixel = 0
                btn.Position = UDim2.new(xScale, 2, 0, 172)
                btn.Size = UDim2.new(wScale, -4, 0, 26)
                btn.AutoButtonColor = false
                btn.Font = Enum.Font.GothamBold
                btn.Text = label
                btn.TextColor3 = Color3.fromRGB(255, 255, 255)
                btn.TextStrokeTransparency = 1
                btn.TextSize = 12
                btn.Parent = bringWallHub
                local c = Instance.new("UICorner")
                c.CornerRadius = UDim.new(0, 6)
                c.Parent = btn
                btn.MouseButton1Click:Connect(onClick)
                return btn
        end
        makeBwBtn(0, 0.5, "Current", function()
                pcall(function()
                        local char = player.Character
                        local hrp = char and char:FindFirstChild("HumanoidRootPart")
                        if hrp then applyBringPos(hrp.Position) end
                end)
        end)
        makeBwBtn(0.5, 0.5, "Place", function()
                pcall(function()
                        local cf = resolvePlaceCF(selectedPlace)
                        if cf then applyBringPos(cf.Position) end
                end)
        end)
        end
        setupBringWallCombo()
end
syncVoidDeadKeybindDisplay()
syncPlacesKeybindDisplay()
local customOffsetFrame = makeControlFrame(215)
customOffsetFrame.Visible = false
local CustomUI = {}
local function getTPModeItems()
        local items = { "Above", "Under", "Behind", "Middle", "Aggressive" }
        for i = 1, 25 do
                table.insert(items, getCustomDisplayName(i))
        end
        return items
end
local tpModesDropdown = nil
do
        function getTPModeCleanItems()
                local items = { "Above", "Under", "Behind", "Behind Custom", "Middle", "Aggressive", "Auto", "Auto Custom" }
                for i = 1, 25 do
                        items[#items + 1] = "Custom " .. i
                end
                return items
        end
        function getTPModeDisplayNames()
                local names = {
                        ["Auto Custom"] = string.format("Auto Custom (%s)", tostring(autoCustomDistance)),
                        ["Behind Custom"] = string.format("Behind Custom (%s)", tostring(attackTpBehindDistance))
                }
                for i = 1, 25 do
                        names["Custom " .. i] = getCustomDisplayName(i)
                end
                return names
        end
        local autoCustomFrame = makeControlFrame(45)
        autoCustomFrame.Visible = false
        function createAutoCustomInput(label, position)
                local labelObj = Instance.new("TextLabel")
                labelObj.BackgroundTransparency = 1
                labelObj.Position = UDim2.fromScale(0.05, 0)
                labelObj.Size = UDim2.fromScale(0.4, 1)
                labelObj.Font = Enum.Font.GothamBold
                labelObj.Text = label
                labelObj.TextColor3 = Color3.fromRGB(255, 255, 255)
                labelObj.TextSize = 13
                labelObj.TextScaled = false
                labelObj.TextWrapped = true
                labelObj.TextXAlignment = Enum.TextXAlignment.Left
                labelObj.Parent = autoCustomFrame
                local box = Instance.new("TextBox")
                box.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
                box.BackgroundTransparency = 0.5
                box.BorderSizePixel = 0
                box.Position = UDim2.fromScale(0.55, 0.15)
                box.Size = UDim2.fromScale(0.35, 0.7)
                box.Font = Enum.Font.GothamMedium
                box.TextColor3 = Color3.fromRGB(255, 255, 255)
                box.TextSize = 13
                box.TextScaled = false
                box.ClearTextOnFocus = false
                box.Text = tostring(autoCustomDistance)
                box.Parent = autoCustomFrame
                box.Focused:Connect(function() box.Text = "" end)
                box:GetPropertyChangedSignal("Text"):Connect(function()
                        local text = box.Text
                        local filtered = text:gsub("[^-0-9%.]", "")
                        if filtered ~= text then box.Text = filtered end
                end)
                box.FocusLost:Connect(function()
                        local val = tonumber(box.Text)
                        if val ~= nil then
                                autoCustomDistance = val
                                setSavedControlValue("AutoCustomDistance", val)
                                if tpModesDropdown then
                                        tpModesDropdown.SetItemDisplayNames(getTPModeDisplayNames())
                                        tpModesDropdown.SetValue(attackTpMode, true)
                                end
                        else
                                box.Text = tostring(autoCustomDistance)
                        end
                        if tpModesDropdown then
                                tpModesDropdown.SetItemDisplayNames(getTPModeDisplayNames())
                                tpModesDropdown.SetValue(attackTpMode, true)
                        end
                end)
                return box
        end
        autoCustomInput = createAutoCustomInput("Distance", 0.375)
        autoCustomFrame.LayoutOrder = 1001
        local behindCustomFrame = makeControlFrame(45)
        behindCustomFrame.Visible = false
        local function createBehindCustomInput(label)
                local labelObj = Instance.new("TextLabel")
                labelObj.BackgroundTransparency = 1
                labelObj.Position = UDim2.fromScale(0.05, 0)
                labelObj.Size = UDim2.fromScale(0.4, 1)
                labelObj.Font = Enum.Font.GothamBold
                labelObj.Text = label
                labelObj.TextColor3 = Color3.fromRGB(255, 255, 255)
                labelObj.TextSize = 13
                labelObj.TextXAlignment = Enum.TextXAlignment.Left
                labelObj.Parent = behindCustomFrame
                local box = Instance.new("TextBox")
                box.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
                box.BackgroundTransparency = 0.5
                box.BorderSizePixel = 0
                box.Position = UDim2.fromScale(0.55, 0.15)
                box.Size = UDim2.fromScale(0.35, 0.7)
                box.Font = Enum.Font.GothamMedium
                box.TextColor3 = Color3.fromRGB(255, 255, 255)
                box.TextSize = 13
                box.ClearTextOnFocus = false
                box.Text = tostring(attackTpBehindDistance)
                box.Parent = behindCustomFrame
                box.Focused:Connect(function() box.Text = "" end)
                box:GetPropertyChangedSignal("Text"):Connect(function()
                        local text = box.Text
                        local filtered = text:gsub("[^-0-9%.]", "")
                        if filtered ~= text then box.Text = filtered end
                end)
                box.FocusLost:Connect(function()
                        local val = tonumber(box.Text)
                        if val ~= nil then
                                attackTpBehindDistance = val
                                setSavedControlValue("BehindDistance", val)
                                if tpModesDropdown then
                                        tpModesDropdown.SetItemDisplayNames(getTPModeDisplayNames())
                                        tpModesDropdown.SetValue(attackTpMode, true)
                                end
                        else
                                box.Text = tostring(attackTpBehindDistance)
                        end
                        if tpModesDropdown then
                                tpModesDropdown.SetItemDisplayNames(getTPModeDisplayNames())
                                tpModesDropdown.SetValue(attackTpMode, true)
                        end
                end)
                return box
        end
        local behindCustomInput = createBehindCustomInput("Distance")
        behindCustomFrame.LayoutOrder = 1002
        local function makeCustomRow(yPos, height)
                local row = Instance.new("Frame")
                row.BackgroundTransparency = 1
                row.BorderSizePixel = 0
                row.Position = UDim2.new(0, 5, 0, yPos)
                row.Size = UDim2.new(1, -10, 0, height or 26)
                row.Parent = customOffsetFrame
                local layout = Instance.new("UIListLayout")
                layout.FillDirection = Enum.FillDirection.Horizontal
                layout.HorizontalAlignment = Enum.HorizontalAlignment.Center
                layout.VerticalAlignment = Enum.VerticalAlignment.Center
                layout.Padding = UDim.new(0, 4)
                layout.Parent = row
                return row
        end
        function updateCustomUI()
                local currentMode = tostring(attackTpMode)
                local isAutoCustom = (currentMode == "Auto Custom")
                local isBehindCustom = (currentMode == "Behind Custom")
                local isCustom = (string.find(currentMode, "Custom") ~= nil) and not isAutoCustom and not isBehindCustom
                customOffsetFrame.Visible = isCustom
                autoCustomFrame.Visible = isAutoCustom
                behindCustomFrame.Visible = isBehindCustom
                if isCustom then
                        local cleanMode = tostring(attackTpMode):match("Custom %d+")
                        local off = customOffsets[cleanMode] or { x = 0, y = 0, z = 0, flat = false, useRotation = false, rx = 0, ry = 0, rz = 0 }
                        CustomUI.zInput.Text = tostring(off.z or 0)
                        CustomUI.yInput.Text = tostring(off.y or 0)
                        CustomUI.xInput.Text = tostring(off.x or 0)
                        if CustomUI.applyFlatState then
                                CustomUI.applyFlatState(off.flat, true)
                        end
                        if CustomUI.rotTog and CustomUI.rotTog.SetValue then
                                CustomUI.rotTog.SetValue(off.useRotation == true, true)
                        end
                        if CustomUI.rotZInput then CustomUI.rotZInput.Text = tostring(off.rz or 0) end
                        if CustomUI.rotYInput then CustomUI.rotYInput.Text = tostring(off.ry or 0) end
                        if CustomUI.rotXInput then CustomUI.rotXInput.Text = tostring(off.rx or 0) end
                end
                if isAutoCustom then
                        autoCustomInput.Text = tostring(autoCustomDistance)
                end
                if isBehindCustom then
                        behindCustomInput.Text = tostring(attackTpBehindDistance)
                end
        end
        function createOffsetInput(label, axis, position)
                local labelObj = Instance.new("TextLabel")
                labelObj.BackgroundTransparency = 1
                labelObj.Position = UDim2.new(position, 0, 0, 25)
                labelObj.Size = UDim2.new(0.1, 0, 0, 15)
                labelObj.Font = Enum.Font.GothamBold
                labelObj.Text = label
                labelObj.TextColor3 = Color3.fromRGB(255, 255, 255)
                labelObj.TextSize = 13
                labelObj.TextScaled = false
                labelObj.TextWrapped = true
                labelObj.Parent = customOffsetFrame
                local box = Instance.new("TextBox")
                box.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
                box.BackgroundTransparency = 0.5
                box.BorderSizePixel = 0
                box.Position = UDim2.new(position, 0, 0, 42)
                box.Size = UDim2.new(0.25, 0, 0, 22)
                box.Font = Enum.Font.GothamMedium
                box.TextColor3 = Color3.fromRGB(255, 255, 255)
                box.TextSize = 13
                box.TextScaled = false
                box.ClearTextOnFocus = false
                box.Text = "0"
                box.Parent = customOffsetFrame
                box.Focused:Connect(function()
                        box.Text = ""
                end)
                box:GetPropertyChangedSignal("Text"):Connect(function()
                        local text = box.Text
                        local filtered = text:gsub("[^-0-9%.]", "")
                        if filtered ~= text then
                                box.Text = filtered
                        end
                end)
                box.FocusLost:Connect(function()
                        local val = tonumber(box.Text)
                        local cleanMode = tostring(attackTpMode):match("Custom %d+")
                        if not cleanMode then return end
                        if val == nil then
                                box.Text = tostring(customOffsets[cleanMode][axis] or 0)
                        else
                                box.Text = tostring(val)
                                customOffsets[cleanMode][axis] = val
                                controlSaveData.CustomOffsets = customOffsets
                                saveSliderSaveData()
                                if tpModesDropdown then
                                        tpModesDropdown.SetItemDisplayNames(getTPModeDisplayNames())
                                end
                        end
                end)
                return box
        end
        function createRotationInput(label, axis, position)
                local labelObj = Instance.new("TextLabel")
                labelObj.BackgroundTransparency = 1
                labelObj.Position = UDim2.new(position, 0, 0, 158)
                labelObj.Size = UDim2.new(0.1, 0, 0, 15)
                labelObj.Font = Enum.Font.GothamBold
                labelObj.Text = label
                labelObj.TextColor3 = Color3.fromRGB(255, 255, 255)
                labelObj.TextSize = 13
                labelObj.TextScaled = false
                labelObj.TextWrapped = true
                labelObj.Parent = customOffsetFrame
                local box = Instance.new("TextBox")
                box.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
                box.BackgroundTransparency = 0.5
                box.BorderSizePixel = 0
                box.Position = UDim2.new(position, 0, 0, 175)
                box.Size = UDim2.new(0.25, 0, 0, 22)
                box.Font = Enum.Font.GothamMedium
                box.TextColor3 = Color3.fromRGB(255, 255, 255)
                box.TextSize = 13
                box.TextScaled = false
                box.ClearTextOnFocus = false
                box.Text = "0"
                box.Parent = customOffsetFrame
                box.Focused:Connect(function()
                        box.Text = ""
                end)
                box:GetPropertyChangedSignal("Text"):Connect(function()
                        local text = box.Text
                        local filtered = text:gsub("[^-0-9%.]", "")
                        if filtered ~= text then
                                box.Text = filtered
                        end
                end)
                box.FocusLost:Connect(function()
                        local val = tonumber(box.Text)
                        local cleanMode = tostring(attackTpMode):match("Custom %d+")
                        if not cleanMode then return end
                        if val == nil then
                                box.Text = tostring(customOffsets[cleanMode][axis] or 0)
                        else
                                box.Text = tostring(val)
                                customOffsets[cleanMode][axis] = val
                                controlSaveData.CustomOffsets = customOffsets
                                saveSliderSaveData()
                                if tpModesDropdown then
                                        tpModesDropdown.SetItemDisplayNames(getTPModeDisplayNames())
                                end
                        end
                end)
                return box
        end
        local posTitleLbl = Instance.new("TextLabel")
        posTitleLbl.BackgroundTransparency = 1
        posTitleLbl.Position = UDim2.new(0, 0, 0, 7)
        posTitleLbl.Size = UDim2.new(1, 0, 0, 15)
        posTitleLbl.Font = Enum.Font.GothamBold
        posTitleLbl.Text = "Position"
        posTitleLbl.TextColor3 = Color3.fromRGB(200, 200, 200)
        posTitleLbl.TextSize = 12
        posTitleLbl.TextXAlignment = Enum.TextXAlignment.Center
        posTitleLbl.Parent = customOffsetFrame
        CustomUI.zInput = createOffsetInput("Z", "z", 0.05)
        CustomUI.yInput = createOffsetInput("Y", "y", 0.375)
        CustomUI.xInput = createOffsetInput("X", "x", 0.7)
        CustomUI.flatStates = { true, "flat90", false }
        CustomUI.flatLabels = { "Flat: ON", "Flat: 90", "Flat: OFF" }
        CustomUI.flatColors = {
                [true]     = Color3.fromRGB(255, 255, 255),
                ["flat90"] = Color3.fromRGB(80, 80, 80),
                [false]    = Color3.fromRGB(0, 0, 0),
        }
        CustomUI.flatTextColors = {
                [true]     = Color3.fromRGB(0, 0, 0),
                ["flat90"] = Color3.fromRGB(0, 0, 0),
                [false]    = Color3.fromRGB(255, 255, 255),
        }
        CustomUI.flatBtn = Instance.new("TextButton")
        CustomUI.flatBtn.BackgroundColor3 = CustomUI.flatColors[false]
        CustomUI.flatBtn.TextColor3 = CustomUI.flatTextColors[false]
        CustomUI.flatBtn.BorderSizePixel = 0
        CustomUI.flatBtn.Size = UDim2.new(0.9, 0, 0, 22)
        CustomUI.flatBtn.Position = UDim2.new(0.05, 0, 0, 70)
        CustomUI.flatBtn.Font = Enum.Font.GothamBold
        CustomUI.flatBtn.Text = "Flat"
        CustomUI.flatBtn.TextSize = 12
        CustomUI.flatCorner = Instance.new("UICorner")
        CustomUI.flatCorner.CornerRadius = UDim.new(0, 6)
        CustomUI.flatCorner.Parent = CustomUI.flatBtn
        CustomUI.flatBtn.Parent = customOffsetFrame
        function CustomUI.getFlatStateIndex(val)
                if val == true then return 1
                elseif val == "flat90" then return 2
                else return 3 end
        end
        function CustomUI.applyFlatState(val, silent)
                if val == nil then val = false end
                CustomUI.flatBtn.Text = "Flat"
                CustomUI.flatBtn.BackgroundColor3 = CustomUI.flatColors[val] or CustomUI.flatColors[false]
                CustomUI.flatBtn.TextColor3 = CustomUI.flatTextColors[val] or CustomUI.flatTextColors[false]
                if silent then return end
                local cleanMode = tostring(attackTpMode):match("Custom %d+")
                if not cleanMode then return end
                customOffsets[cleanMode].flat = val
                if val then
                        customOffsets[cleanMode].useRotation = false
                        if CustomUI.rotTog and CustomUI.rotTog.SetValue then
                                CustomUI.rotTog.SetValue(false, true)
                        end
                end
                controlSaveData.CustomOffsets = customOffsets
                saveSliderSaveData()
                if tpModesDropdown then
                        tpModesDropdown.SetItemDisplayNames(getTPModeDisplayNames())
                end
        end
        CustomUI.flatBtn.MouseButton1Click:Connect(function()
                local cleanMode = tostring(attackTpMode):match("Custom %d+")
                if not cleanMode then return end
                local cur = customOffsets[cleanMode].flat
                local idx = CustomUI.getFlatStateIndex(cur)
                local next = CustomUI.flatStates[(idx % #CustomUI.flatStates) + 1]
                CustomUI.applyFlatState(next)
        end)
        CustomUI.rotTitleRow = makeCustomRow(100, 15)
        CustomUI.rotTitle = Instance.new("TextLabel")
        CustomUI.rotTitle.BackgroundTransparency = 1
        CustomUI.rotTitle.Size = UDim2.new(1, 0, 1, 0)
        CustomUI.rotTitle.Font = Enum.Font.GothamBold
        CustomUI.rotTitle.Text = "Rotation"
        CustomUI.rotTitle.TextColor3 = Color3.fromRGB(255, 255, 255)
        CustomUI.rotTitle.TextSize = 13
        CustomUI.rotTitle.TextXAlignment = Enum.TextXAlignment.Center
        CustomUI.rotTitle.Parent = CustomUI.rotTitleRow
        CustomUI.rotTogRow = makeCustomRow(120, 26)
        CustomUI.rotTog = makeHubTog(CustomUI.rotTogRow, "Use Custom Rotation", function(enabled)
                local cleanMode = tostring(attackTpMode):match("Custom %d+")
                if cleanMode then
                        customOffsets[cleanMode].useRotation = enabled
                        if enabled then
                                customOffsets[cleanMode].flat = false
                                if CustomUI.applyFlatState then
                                        CustomUI.applyFlatState(false, true)
                                end
                        end
                        controlSaveData.CustomOffsets = customOffsets
                        saveSliderSaveData()
                        if tpModesDropdown then
                                tpModesDropdown.SetItemDisplayNames(getTPModeDisplayNames())
                        end
                end
        end, nil, false, 0.9)
        CustomUI.rotZInput = createRotationInput("Z", "rz", 0.05)
        CustomUI.rotYInput = createRotationInput("Y", "ry", 0.375)
        CustomUI.rotXInput = createRotationInput("X", "rx", 0.7)
        autoCustomFrame.Parent = uiX
        behindCustomFrame.Parent = uiX
        tpModesDropdown = Dropdown({
                namedropdown = "TP Modes",
                inside = getTPModeCleanItems(),
                itemDisplayNames = getTPModeDisplayNames(),
                multi = false,
                deffultin = attackTpMode or "Behind",
                fun = function(value)
                        attackTpMode = value
                        controlSaveData.AttackTpMode = value
                        saveSliderSaveData()
                        updateCustomUI()
                end,
        })
        tpModesDropdown.Frame.LayoutOrder = 1000
        customOffsetFrame.LayoutOrder = 1002
end
customOffsetFrame.Parent = uiX
updateCustomUI()
do
        local charSaveKey = "SelectedCharacter"
        local characterList = { "Bald", "Hunter", "Monster", "Cyborg", "Ninja", "Batter", "Blade", "Esper", "Purple", "Tech", "Zombie", "KJ", "Sorcerer" }
        local function getCharacterFromAttr()
                local char = player.Character
                if char then
                        local attr = char:GetAttribute("Character")
                        if attr and tostring(attr) ~= "" then
                                return tostring(attr)
                        end
                end
                return characterList[1]
        end
        local charCallbackReady = false
        local characterDropdown
        local charPendingValue = nil
        local charPendingToken = 0
        characterDropdown = Dropdown({
                namedropdown = "Character",
                inside = characterList,
                multi = false,
                deffultin = getCharacterFromAttr(),
                fun = function(value)
                        if not charCallbackReady then return end
                        if not value or value == "" then return end
                        local char = player.Character
                        local currentAttr = char and char:GetAttribute("Character")
                        if currentAttr and tostring(currentAttr) == value then return end
                        task.spawn(function()
                                local retryToken = (characterDropdown and characterDropdown._retryToken or 0) + 1
                                if characterDropdown then characterDropdown._retryToken = retryToken end
                                charPendingValue = value
                                charPendingToken = retryToken
                                local previousChar = (function()
                                        local c = player.Character
                                        local a = c and c:GetAttribute("Character")
                                        return (a and tostring(a) ~= "") and tostring(a) or nil
                                end)()
                                local attempts = 0
                                local maxAttempts = 19
                                while true do
                                        if characterDropdown and characterDropdown._retryToken ~= retryToken then
                                                charPendingValue = nil
                                                break
                                        end
                                        local c = player.Character
                                        local attr = c and c:GetAttribute("Character")
                                        if attr and tostring(attr) == value then
                                                charPendingValue = nil
                                                if characterDropdown then
                                                        characterDropdown.SetValue(tostring(attr), true)
                                                end
                                                break
                                        end
                                        attempts = attempts + 1
                                        if attempts > maxAttempts then
                                                charPendingValue = nil
                                                local actualChar = (function()
                                                        local c2 = player.Character
                                                        local a2 = c2 and c2:GetAttribute("Character")
                                                        return (a2 and tostring(a2) ~= "") and tostring(a2) or previousChar
                                                end)()
                                                if actualChar and characterDropdown then
                                                        characterDropdown.SetValue(actualChar, true)
                                                end
                                                while true do
                                                        if characterDropdown and characterDropdown._retryToken ~= retryToken then break end
                                                        task.wait(0.6)
                                                        local c2 = player.Character
                                                        local a2 = c2 and c2:GetAttribute("Character")
                                                        if a2 and tostring(a2) ~= "" then
                                                                local current = tostring(a2)
                                                                if characterDropdown then
                                                                        characterDropdown.SetValue(current, true)
                                                                end
                                                                if current == value then break end
                                                        end
                                                end
                                                break
                                        end
                                        pcall(function()
                                                local communicate = player.Character and player.Character:WaitForChild("Communicate", 3)
                                                if communicate then
                                                        communicate:FireServer({ Goal = "Change Character", Character = value })
                                                end
                                        end)
                                        task.wait(0.15)
                                end
                        end)
                end,
        })
        characterDropdown.Frame.LayoutOrder = 999999
        local function syncCharDropdown()
                if not characterDropdown then return end
                if charPendingValue ~= nil then return end
                local char = player.Character
                if not char then return end
                local attr = char:GetAttribute("Character")
                if attr and tostring(attr) ~= "" then
                        characterDropdown.SetValue(tostring(attr), true)
                end
        end
        local function watchCharacterAttrs(char)
                if not char then return end
                char:GetAttributeChangedSignal("Character"):Connect(function()
                        pcall(syncCharDropdown)
                end)
        end
        player.CharacterAdded:Connect(function(newChar)
                task.wait()
                pcall(syncCharDropdown)
                watchCharacterAttrs(newChar)
        end)
        if player.Character then
                watchCharacterAttrs(player.Character)
        end
        task.defer(function()
                pcall(syncCharDropdown)
                charCallbackReady = true
        end)
end
do
        local keybindHub = makeControlFrame(310)
        keybindHub.Name = "KeybindSystemHub"
        keybindHub.Parent = uiX
        keybindHub.LayoutOrder = 1000000
        keybindHub.ClipsDescendants = false
        local hubTitle = Instance.new("TextLabel")
        hubTitle.BackgroundTransparency = 1
        hubTitle.Position = UDim2.new(0, 16, 0, 8)
        hubTitle.Size = UDim2.new(1, -32, 0, 18)
        hubTitle.Font = Enum.Font.GothamBold
        hubTitle.Text = "Keybind System"
        hubTitle.TextColor3 = Color3.fromRGB(255, 255, 255)
        hubTitle.TextStrokeTransparency = 1
        hubTitle.TextSize = 14
        hubTitle.TextXAlignment = Enum.TextXAlignment.Left
        hubTitle.Parent = keybindHub
        local function makeRow(yPos)
                local row = Instance.new("Frame")
                row.BackgroundTransparency = 1
                row.BorderSizePixel = 0
                row.Position = UDim2.new(0, 4, 0, yPos)
                row.Size = UDim2.new(1, -8, 0, 26)
                row.Parent = keybindHub
                local layout = Instance.new("UIListLayout")
                layout.FillDirection = Enum.FillDirection.Horizontal
                layout.HorizontalAlignment = Enum.HorizontalAlignment.Center
                layout.VerticalAlignment = Enum.VerticalAlignment.Center
                layout.Padding = UDim.new(0, 4)
                layout.Parent = row
                return row
        end
        do
                local r = makeRow(30)
                makeHubTog(r, "Hide Names", function(v) hideNamesEnabled = v; updateKeybindText() end, "KeybindHideNamesEnabled", false, 1.0)
                r = makeRow(60)
                makeHubTogKB(r, "Speed KB", function(v) keybindToggles.Speed = v; updateKeybindText() end, "KeybindSpeedEnabled", "off", 1/2)
                makeHubTogKB(r, "Fly KB", function(v) keybindToggles.Fly = v; updateKeybindText() end, "KeybindFlyEnabled", "off", 1/2)
                r = makeRow(90)
                makeHubTogKB(r, "cam lock KB", function(v) keybindToggles.CamLock = v; updateKeybindText() end, "KeybindCamLockEnabled", "block", 1/3)
                makeHubTogKB(r, "Attack TP KB", function(v) keybindToggles.AttackTP = v; updateKeybindText() end, "KeybindAttackTPEnabled", "off", 1/3)
                makeHubTogKB(r, "Target KB", function(v) keybindToggles.Target = v; updateKeybindText() end, "KeybindTargetEnabled", "hide", 1/3)
                r = makeRow(120)
                makeHubTogKB(r, "cam body KB", function(v) keybindToggles.BodyLock = v; updateKeybindText() end, "KeybindBodyLockEnabled", "block", 1/2)
                makeHubTogKB(r, "cam B/L KB", function(v) keybindToggles.ComboLock = v; updateKeybindText() end, "KeybindComboLockEnabled", "block", 1/2)
                r = makeRow(150)
                makeHubTogKB(r, "WalkFling KB", function(v) keybindToggles.WalkFling = v; updateKeybindText() end, "KeybindWalkFlingEnabled", "off", 1/3)
                makeHubTogKB(r, "SetBack KB", function(v) keybindToggles.SetBack = v; updateKeybindText() end, "KeybindSetBackEnabled", "off", 1/3)
                makeHubTogKB(r, "Trash KB", function(v) keybindToggles.Trash = v; updateKeybindText() end, "KeybindTrashEnabled", "off", 1/3)
                r = makeRow(180)
                makeHubTogKB(r, "Void KB", function(v) keybindToggles.Void = v; updateKeybindText() end, "KeybindVoidEnabled", "off", 1/2)
                makeHubTogKB(r, "Places TP KB", function(v) keybindToggles.Places = v; updateKeybindText() end, "KeybindPlacesEnabled", "off", 1/2)
                r = makeRow(210)
                makeHubTogKB(r, "View KB", function(v) keybindToggles.View = v; updateKeybindText() end, "KeybindViewEnabled", "block", 1/3)
                makeHubTogKB(r, "Orbit KB", function(v) keybindToggles.Orbit = v; updateKeybindText() end, "KeybindOrbitEnabled", "block", 1/3)
                makeHubTogKB(r, "Auto TP KB", function(v) keybindToggles.AutoTPKey = v; updateKeybindText() end, "KeybindAutoTPKeyEnabled", "block", 1/3)
                r = makeRow(240)
                makeHubTogKB(r, "Fling KB", function(v) keybindToggles.FlingKey = v; updateKeybindText() end, "KeybindFlingKeyEnabled", "block", 1.0)
        end
        task.defer(updateKeybindText)
        task.defer(syncFlingKeybindDisplay)
end
task.spawn(function()
        if game.GameId ~= 3808081382 then
                return
        end
        while not introFinished and screenGui.Parent do
                task.wait()
        end
        if not screenGui.Parent then
                return
        end
        local ESP_BILLBOARD_NAME = "NOTHING_X_OverlayBillboard"
        local ESP_HIGHLIGHT_NAME = "NOTHING-X"
        local TextService = game:GetService("TextService")
        local BILLBOARD_MIN_WIDTH = 72
        local BILLBOARD_PADDING_TOP = 4
        local BILLBOARD_PADDING_BOTTOM = 4
        local BILLBOARD_PADDING_LEFT = 8
        local BILLBOARD_PADDING_RIGHT = 8
        local BILLBOARD_LINE_HEIGHT = 16
        local BILLBOARD_ITEM_PADDING = 4
        local function clampPercent(value)
                local numericValue = tonumber(value) or 0
                if numericValue ~= numericValue then
                        numericValue = 0
                end
                return math.clamp(math.floor(numericValue + 0.5), 0, 999)
        end
        local function getCharacterNameColor(characterName)
                return Color3.fromRGB(255, 255, 255)
        end
        local function getUltimateColor(ultimatePercent)
                local value = clampPercent(ultimatePercent)
                if value <= 0 then
                        return Color3.fromRGB(255, 255, 0)
                end
                if value >= 100 then
                        return Color3.fromRGB(255, 255, 255)
                end
                return Color3.fromRGB(255, 165, 0)
        end
        local function getHpColor(hpPercent)
                local value = clampPercent(hpPercent)
                if value <= 0 then
                        return Color3.fromRGB(255, 255, 255)
                end
                if value >= 100 then
                        return Color3.fromRGB(0, 255, 0)
                end
                if value >= 50 then
                        return Color3.fromRGB(255, 165, 0)
                end
                return Color3.fromRGB(255, 255, 0)
        end
        local function getUltDetectColor(isUlted)
                if isUlted then
                        return Color3.fromRGB(255, 165, 0)
                end
                return Color3.fromRGB(170, 170, 170)
        end
        local function createBillboardLine(parent, name, defaultColor)
                local line = Instance.new("TextLabel")
                line.Name = name
                line.BackgroundTransparency = 1
                line.Size = UDim2.fromOffset(0, BILLBOARD_LINE_HEIGHT)
                line.Font = Enum.Font.GothamBold
                line.Text = ""
                line.TextColor3 = defaultColor or Color3.fromRGB(255, 255, 255)
                line.TextStrokeTransparency = 1
                line.TextScaled = false
                line.TextSize = 14
                line.TextWrapped = false
                line.TextTruncate = Enum.TextTruncate.None
                line.TextXAlignment = Enum.TextXAlignment.Left
                line.TextYAlignment = Enum.TextYAlignment.Center
                line.Visible = false
                line.Parent = parent
                return line
        end
        local function ensureOverlayBillboard(model)
                local rootPart = model and model:FindFirstChild("HumanoidRootPart")
                if not rootPart then
                        return nil
                end
                local billboard = model:FindFirstChild(ESP_BILLBOARD_NAME)
                if billboard and billboard:IsA("BillboardGui") then
                        return billboard
                end
                if billboard then
                        billboard:Destroy()
                end
                billboard = Instance.new("BillboardGui")
                billboard.Name = ESP_BILLBOARD_NAME
                billboard.Adornee = rootPart
                billboard.AlwaysOnTop = true
                billboard.ExtentsOffsetWorldSpace = Vector3.new(0, 6.7, 0)
                billboard.Size = UDim2.fromOffset(BILLBOARD_MIN_WIDTH, 0)
                billboard.MaxDistance = 333
                billboard.Parent = model
                local frame = Instance.new("Frame")
                frame.Name = "Root"
                frame.Size = UDim2.new(1, 0, 0, 0)
                frame.BackgroundColor3 = Color3.fromRGB(15, 15, 15)
                frame.BackgroundTransparency = 0.2
                frame.BorderSizePixel = 0
                frame.ClipsDescendants = true
                frame.Parent = billboard
                local corner = Instance.new("UICorner")
                corner.CornerRadius = UDim.new(0, 6)
                corner.Parent = frame
                local stroke = Instance.new("UIStroke")
                stroke.Color = Color3.fromRGB(255, 255, 255)
                stroke.Transparency = 0
                stroke.Thickness = 1
                stroke.Parent = frame
                local padding = Instance.new("UIPadding")
                padding.PaddingLeft = UDim.new(0, 8)
                padding.PaddingRight = UDim.new(0, 8)
                padding.PaddingTop = UDim.new(0, 4)
                padding.PaddingBottom = UDim.new(0, 4)
                padding.Parent = frame
                local list = Instance.new("UIListLayout")
                list.Padding = UDim.new(0, 4)
                list.FillDirection = Enum.FillDirection.Horizontal
                list.HorizontalAlignment = Enum.HorizontalAlignment.Center
                list.VerticalAlignment = Enum.VerticalAlignment.Center
                list.SortOrder = Enum.SortOrder.LayoutOrder
                list.Parent = frame
                createBillboardLine(frame, "HpLine").LayoutOrder = 1
                createBillboardLine(frame, "SepOne", Color3.fromRGB(255, 255, 255)).LayoutOrder = 2
                createBillboardLine(frame, "CharacterLine").LayoutOrder = 3
                createBillboardLine(frame, "SepTwo", Color3.fromRGB(255, 255, 255)).LayoutOrder = 4
                createBillboardLine(frame, "UltimateLine").LayoutOrder = 5
                createBillboardLine(frame, "SepThree", Color3.fromRGB(255, 255, 255)).LayoutOrder = 6
                createBillboardLine(frame, "StreakLine", Color3.fromRGB(100, 180, 255)).LayoutOrder = 7
                createBillboardLine(frame, "SepFour", Color3.fromRGB(255, 255, 255)).LayoutOrder = 8
                createBillboardLine(frame, "DeathStateLine", Color3.fromRGB(0, 255, 0)).LayoutOrder = 9
                createBillboardLine(frame, "SepFive", Color3.fromRGB(255, 255, 255)).LayoutOrder = 10
                createBillboardLine(frame, "UltedTextLine", Color3.fromRGB(255, 255, 0)).LayoutOrder = 11
                return billboard
        end
        local function getSharedHighlightColors(model, ultedAttr, canUseUltedHighlight)
                local seriousModeState = model and model:GetAttribute("NX_SeriousModeState") or nil
                if SeriousModeTrackerEnabled then
                        if seriousModeState == "strong" then
                                return {
                                        fill = Color3.fromRGB(0, 0, 0),
                                        fillTransparency = 0.6,
                                        outline = Color3.fromRGB(255, 255, 255),
                                        enabled = true,
                                }
                        elseif seriousModeState == "weak" then
                                return {
                                        fill = Color3.fromRGB(0, 0, 0),
                                        fillTransparency = 0.6,
                                        outline = Color3.fromRGB(150, 150, 150),
                                        enabled = true,
                                }
                        end
                end
                if canUseUltedHighlight and ultedAttr == true then
                        return {
                                fill = Color3.fromRGB(0, 0, 0),
                                fillTransparency = 0.6,
                                outline = Color3.fromRGB(255, 255, 0),
                                enabled = true,
                        }
                end
                return nil
        end
        local HIGHLIGHT_DESTROY_TOKEN_ATTRIBUTE = "NOTHING_X_X_X"
        local HIGHLIGHT_DESTROY_TOKEN_VALUE = 500
        local function cancelHighlightDestroy(highlight)
                if not highlight or not highlight:IsA("Highlight") then
                        return
                end
                highlight:SetAttribute(HIGHLIGHT_DESTROY_TOKEN_ATTRIBUTE, nil)
        end
        local function scheduleHighlightDestroy(model)
                local highlight = model and model:FindFirstChild(ESP_HIGHLIGHT_NAME)
                if not highlight or not highlight:IsA("Highlight") then
                        return
                end
                local destroyCounter = highlight:GetAttribute(HIGHLIGHT_DESTROY_TOKEN_ATTRIBUTE)
                if type(destroyCounter) ~= "number" then
                        highlight:SetAttribute(HIGHLIGHT_DESTROY_TOKEN_ATTRIBUTE, 0)
                        task.spawn(function()
                                while highlight.Parent do
                                        if highlight.Enabled then
                                                highlight:SetAttribute(HIGHLIGHT_DESTROY_TOKEN_ATTRIBUTE, nil)
                                                return
                                        end
                                        local currentValue = highlight:GetAttribute(HIGHLIGHT_DESTROY_TOKEN_ATTRIBUTE)
                                        if type(currentValue) ~= "number" then
                                                return
                                        end
                                        currentValue = currentValue + 1
                                        highlight:SetAttribute(HIGHLIGHT_DESTROY_TOKEN_ATTRIBUTE, currentValue)
                                        if currentValue >= HIGHLIGHT_DESTROY_TOKEN_VALUE then
                                                highlight:Destroy()
                                                return
                                        end
                                        nextFrame()
                                end
                        end)
                end
        end
        local function ensureHighlight(model, startEnabled)
                local highlight = model and model:FindFirstChild(ESP_HIGHLIGHT_NAME)
                if highlight and not highlight:IsA("Highlight") then
                        highlight:Destroy()
                        highlight = nil
                end
                if highlight then
                        cancelHighlightDestroy(highlight)
                        return highlight
                end
                highlight = Instance.new("Highlight")
                highlight.Name = ESP_HIGHLIGHT_NAME
                highlight.Adornee = model
                highlight.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
                highlight.FillColor = Color3.fromRGB(0, 0, 0)
                highlight.FillTransparency = 0.6
                highlight.OutlineTransparency = 0
                highlight.OutlineColor = startEnabled and Color3.fromRGB(255, 255, 0) or Color3.fromRGB(128, 128, 128)
                highlight.Enabled = startEnabled == true
                highlight.Parent = model
                cancelHighlightDestroy(highlight)
                return highlight
        end
        local function measureTextWidth(text)
                local str = tostring(text or "")
                local width = 0
                for i = 1, #str do
                        local char = string.sub(str, i, i)
                        if char == "%" then
                                width = width + 12
                        elseif char == "M" or char == "W" then
                                width = width + 11
                        elseif char == "/" then
                                width = width + 7
                        elseif string.match(char, "%u") then
                                width = width + 9
                        else
                                width = width + 7.5
                        end
                end
                return math.max(math.ceil(width + 4), 1)
        end
        local function updateLine(line, isVisible, text, color)
                if not line then
                        return false
                end
                line.Visible = isVisible == true
                if not isVisible then
                        line.Text = ""
                        line.Size = UDim2.new(1, 0, 0, 0)
                        return false
                end
                local displayText = tostring(text or "")
                line.Text = displayText
                line.TextColor3 = color
                line.Size = UDim2.fromOffset(measureTextWidth(displayText), BILLBOARD_LINE_HEIGHT)
                return true
        end
        local function updateBillboardVisibility(billboard, frame, visibleCount, contentWidth)
                if not billboard or not frame then
                        return
                end
                local hasVisibleRows = (visibleCount or 0) > 0
                local contentHeight = hasVisibleRows and (BILLBOARD_PADDING_TOP + BILLBOARD_PADDING_BOTTOM + BILLBOARD_LINE_HEIGHT) or 0
                local finalWidth = hasVisibleRows and math.max(BILLBOARD_MIN_WIDTH, (contentWidth or 0) + BILLBOARD_PADDING_LEFT + BILLBOARD_PADDING_RIGHT) or 0
                billboard.Size = UDim2.fromOffset(finalWidth, contentHeight)
                frame.Size = UDim2.new(1, 0, 0, contentHeight)
                frame.Visible = hasVisibleRows
                billboard.Enabled = hasVisibleRows
        end
        local function updatePlayerOverlay(targetPlayer)
                if targetPlayer == player or targetPlayer.Parent ~= Players then
                        return
                end
                local model = getTrackedPlayerTargetModel(targetPlayer)
                if not model then
                        return
                end
                local humanoid = model:FindFirstChildOfClass("Humanoid")
                local head = model:FindFirstChild("Head")
                local rootPart = model:FindFirstChild("HumanoidRootPart")
                if not humanoid or not head or not rootPart then
                        return
                end
                local attributes = {
                        Character = model:GetAttribute("Character"),
                        Ultimate = targetPlayer:GetAttribute("Ultimate"),
                        Ulted = model:GetAttribute("Ulted"),
                        Streak = model:GetAttribute("CurrentStreak"),
                }
                local characterAttr = attributes.Character
                local ultimateAttr = attributes.Ultimate
                local hasUltimateAttr = ultimateAttr ~= nil
                local ultedAttr = attributes.Ulted == true
                local streakAttr = attributes.Streak
                local isBald = tostring(characterAttr or "") == "Bald"
                local hpPercent = humanoid.MaxHealth > 0 and ((humanoid.Health / humanoid.MaxHealth) * 100) or 0
                local hpValue = clampPercent(hpPercent)
                local ultimateValue = clampPercent(ultimateAttr)
                local smState = model:GetAttribute("NX_SeriousModeState")
                local showDeathState = espOverlayConfig.showDeath and (smState == "strong" or smState == "weak")
                local showUltedText = espOverlayConfig.showUlted and ultedAttr and not showDeathState
                local showBillboard = espOverlayConfig.showHp or espOverlayConfig.showCharacter or espOverlayConfig.showUltimate or espOverlayConfig.showStreak or showDeathState or showUltedText
                local billboard = model:FindFirstChild(ESP_BILLBOARD_NAME)
                if not showBillboard then
                        if billboard then
                                billboard:Destroy()
                        end
                else
                        billboard = ensureOverlayBillboard(model)
                        if billboard then
                                billboard.Enabled = true
                                billboard.Adornee = rootPart
                                local frame = billboard:FindFirstChild("Root")
                                local hpLine = frame and frame:FindFirstChild("HpLine")
                                local sepOne = frame and frame:FindFirstChild("SepOne")
                                local characterLine = frame and frame:FindFirstChild("CharacterLine")
                                local sepTwo = frame and frame:FindFirstChild("SepTwo")
                                local ultimateLine = frame and frame:FindFirstChild("UltimateLine")
                                local sepThree = frame and frame:FindFirstChild("SepThree")
                                local streakLine = frame and frame:FindFirstChild("StreakLine")
                                local sepFour = frame and frame:FindFirstChild("SepFour")
                                local deathStateLine = frame and frame:FindFirstChild("DeathStateLine")
                                local sepFive = frame and frame:FindFirstChild("SepFive")
                                local ultedTextLine = frame and frame:FindFirstChild("UltedTextLine")
                                local visibleCount = 0
                                local contentWidth = 0
                                local visibleGuiCount = 0
                                local hpVisible = updateLine(
                                        hpLine,
                                        espOverlayConfig.showHp,
                                        formatHPPercent(humanoid) .. "%", Color3.fromRGB(150, 150, 150)
                                )
                                local characterVisible = updateLine(
                                        characterLine,
                                        espOverlayConfig.showCharacter and tostring(characterAttr or "") ~= "",
                                        tostring(characterAttr or ""),
                                        getCharacterNameColor(characterAttr)
                                )
                                local hideUltimateForBaldUlted = ultedAttr or showDeathState
                                local ultimateVisible = updateLine(
                                        ultimateLine,
                                        espOverlayConfig.showUltimate and hasUltimateAttr and not hideUltimateForBaldUlted,
                                        string.format("%d%%", ultimateValue), Color3.fromRGB(255, 255, 255)
                                )
                                local streakNum = tonumber(streakAttr)
                                local streakVisible = false
                                if espOverlayConfig.showStreak and streakNum ~= nil and streakNum > 0 then
                                        streakVisible = updateLine(
                                                streakLine,
                                                true,
                                                tostring(streakNum),
                                                Color3.fromRGB(100, 180, 255)
                                        )
                                else
                                        updateLine(streakLine, false, "", Color3.fromRGB(100, 180, 255))
                                end
                                local deathStateText = ""
                                local deathStateColor = Color3.fromRGB(255, 255, 255)
                                if smState == "strong" then
                                        deathStateText = "-"
                                        deathStateColor = Color3.fromRGB(255, 255, 255)
                                elseif smState == "weak" then
                                        deathStateText = "DEATH"
                                        deathStateColor = Color3.fromRGB(150, 150, 150)
                                end
                                local deathStateVisible = updateLine(
                                        deathStateLine,
                                        showDeathState,
                                        deathStateText,
                                        deathStateColor
                                )
                                local ultedTextVisible = updateLine(
                                        ultedTextLine,
                                        showUltedText,
                                        "ULT",
                                        Color3.fromRGB(255, 255, 0)
                                )
                                if hpVisible then
                                        visibleCount = visibleCount + 1
                                end
                                if characterVisible then
                                        visibleCount = visibleCount + 1
                                end
                                if ultimateVisible then
                                        visibleCount = visibleCount + 1
                                end
                                if streakVisible then
                                        visibleCount = visibleCount + 1
                                end
                                if deathStateVisible then
                                        visibleCount = visibleCount + 1
                                end
                                if ultedTextVisible then
                                        visibleCount = visibleCount + 1
                                end
                                local showSepOne = hpVisible and characterVisible
                                local showSepTwo = (hpVisible or characterVisible) and ultimateVisible
                                local showSepThree = (hpVisible or characterVisible or ultimateVisible) and streakVisible
                                local showSepFour = (hpVisible or characterVisible or ultimateVisible or streakVisible) and deathStateVisible
                                local showSepFive = (hpVisible or characterVisible or ultimateVisible or streakVisible or deathStateVisible) and ultedTextVisible
                                updateLine(sepOne, showSepOne, "//", Color3.fromRGB(255, 255, 255))
                                updateLine(sepTwo, showSepTwo, "//", Color3.fromRGB(255, 255, 255))
                                updateLine(sepThree, showSepThree, "//", Color3.fromRGB(255, 255, 255))
                                updateLine(sepFour, showSepFour, "//", Color3.fromRGB(255, 255, 255))
                                updateLine(sepFive, showSepFive, "//", Color3.fromRGB(255, 255, 255))
                                for _, guiObject in ipairs({ hpLine, sepOne, characterLine, sepTwo, ultimateLine, sepThree, streakLine, sepFour, deathStateLine, sepFive, ultedTextLine }) do
                                        if guiObject and guiObject.Visible then
                                                visibleGuiCount = visibleGuiCount + 1
                                                contentWidth = contentWidth + guiObject.Size.X.Offset
                                        end
                                end
                                if visibleGuiCount > 1 then
                                        contentWidth = contentWidth + ((visibleGuiCount - 1) * BILLBOARD_ITEM_PADDING)
                                end
                                updateBillboardVisibility(billboard, frame, visibleCount, contentWidth)
                        end
                end
                local state = espOverlayState[targetPlayer] or {}
                local canUseHighlight = espOverlayConfig.showEsp and not isBald
                local highlightSpec = getSharedHighlightColors(model, ultedAttr, canUseHighlight)
                if highlightSpec then
                        local highlight = ensureHighlight(model, highlightSpec.enabled)
                        cancelHighlightDestroy(highlight)
                        highlight.Enabled = highlightSpec.enabled
                        highlight.FillColor = highlightSpec.fill
                        highlight.FillTransparency = highlightSpec.fillTransparency or 0.6
                        highlight.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
                        highlight.OutlineColor = highlightSpec.outline
                else
                        local highlight = model:FindFirstChild(ESP_HIGHLIGHT_NAME)
                        if highlight and highlight:IsA("Highlight") then
                                highlight.Enabled = false
                                highlight.OutlineColor = Color3.fromRGB(128, 128, 128)
                                scheduleHighlightDestroy(model)
                        end
                end
                state.lastUlted = ultedAttr
                state.model = model
                espOverlayState[targetPlayer] = state
        end
        local playerOverlayConnections = {}
        local function disconnectOverlayConnections(targetPlayer)
                local conns = playerOverlayConnections[targetPlayer]
                if conns then
                        for _, conn in ipairs(conns) do
                                if conn and conn.Disconnect then
                                        pcall(function() conn:Disconnect() end)
                                end
                        end
                        playerOverlayConnections[targetPlayer] = nil
                end
        end
        local function cleanupPlayerOverlay(targetPlayer)
                disconnectOverlayConnections(targetPlayer)
                local state = espOverlayState[targetPlayer]
                local model = state and state.model
                if model and model.Parent then
                        local highlight = model:FindFirstChild(ESP_HIGHLIGHT_NAME)
                        if highlight and highlight:IsA("Highlight") then
                                highlight.Enabled = false
                                highlight.OutlineColor = Color3.fromRGB(128, 128, 128)
                                scheduleHighlightDestroy(model)
                        end
                        local billboard = model:FindFirstChild(ESP_BILLBOARD_NAME)
                        if billboard then
                                pcall(function() billboard:Destroy() end)
                        end
                end
                espOverlayState[targetPlayer] = nil
        end
        local function setupPlayerOverlay(targetPlayer)
                disconnectOverlayConnections(targetPlayer)
                if targetPlayer == player then return end
                local conns = {}
                playerOverlayConnections[targetPlayer] = conns
                local function onCharAdded(char)
                        pcall(updatePlayerOverlay, targetPlayer)
                        task.spawn(function()
                                local humanoid = char:WaitForChild("Humanoid", 10)
                                if humanoid and playerOverlayConnections[targetPlayer] == conns and char.Parent then
                                        local hpConn = humanoid:GetPropertyChangedSignal("Health"):Connect(function()
                                                pcall(updatePlayerOverlay, targetPlayer)
                                        end)
                                        local maxHpConn = humanoid:GetPropertyChangedSignal("MaxHealth"):Connect(function()
                                                pcall(updatePlayerOverlay, targetPlayer)
                                        end)
                                        table.insert(conns, hpConn)
                                        table.insert(conns, maxHpConn)
                                        pcall(updatePlayerOverlay, targetPlayer)
                                end
                        end)
                        local attrConn = char.AttributeChanged:Connect(function(attr)
                                if attr == "Character" or attr == "Ulted" or attr == "Ultimate" or attr == "CurrentStreak" or attr == "NX_SeriousModeState" then
                                        pcall(updatePlayerOverlay, targetPlayer)
                                end
                        end)
                        table.insert(conns, attrConn)
                        local childConn = char.ChildAdded:Connect(function(child)
                                if child:IsA("Humanoid") then
                                        local hpConn = child:GetPropertyChangedSignal("Health"):Connect(function()
                                                pcall(updatePlayerOverlay, targetPlayer)
                                        end)
                                        local maxHpConn = child:GetPropertyChangedSignal("MaxHealth"):Connect(function()
                                                pcall(updatePlayerOverlay, targetPlayer)
                                        end)
                                        table.insert(conns, hpConn)
                                        table.insert(conns, maxHpConn)
                                        pcall(updatePlayerOverlay, targetPlayer)
                                end
                        end)
                        table.insert(conns, childConn)
                        pcall(updatePlayerOverlay, targetPlayer)
                end
                if targetPlayer.Character then
                        task.spawn(onCharAdded, targetPlayer.Character)
                end
                local charAddedConn = targetPlayer.CharacterAdded:Connect(function(char)
                        task.spawn(onCharAdded, char)
                end)
                table.insert(conns, charAddedConn)
                local charRemovingConn = targetPlayer.CharacterRemoving:Connect(function()
                        cleanupPlayerOverlay(targetPlayer)
                end)
                table.insert(conns, charRemovingConn)
                local playerAttrConn = targetPlayer.AttributeChanged:Connect(function(attr)
                        if attr == "Ultimate" or attr == "Ulted" then
                                pcall(updatePlayerOverlay, targetPlayer)
                        end
                end)
                table.insert(conns, playerAttrConn)
        end
        refreshAllOverlays = function()
                for _, targetPlayer in ipairs(Players:GetPlayers()) do
                        if targetPlayer ~= player then
                                pcall(updatePlayerOverlay, targetPlayer)
                        end
                end
        end
        for _, targetPlayer in ipairs(Players:GetPlayers()) do
                setupPlayerOverlay(targetPlayer)
        end
        local playerAddedOverlayConn = Players.PlayerAdded:Connect(setupPlayerOverlay)
        local playerRemovingOverlayConn = Players.PlayerRemoving:Connect(cleanupPlayerOverlay)
        task.spawn(function()
                while screenGui.Parent do
                        local overlayEnabled = espOverlayConfig.showHp
                                or espOverlayConfig.showCharacter
                                or espOverlayConfig.showUltimate
                                or espOverlayConfig.showEsp
                                or espOverlayConfig.showStreak
                                or SeriousModeTrackerEnabled
                        if overlayEnabled then
                                for _, targetPlayer in ipairs(Players:GetPlayers()) do
                                        if targetPlayer ~= player then
                                                pcall(updatePlayerOverlay, targetPlayer)
                                        end
                                end
                        end
                        task.wait()
                end
        end)
        task.spawn(function()
                while screenGui.Parent do
                        task.wait()
                end
                pcall(function() playerAddedOverlayConn:Disconnect() end)
                pcall(function() playerRemovingOverlayConn:Disconnect() end)
                for _, targetPlayer in ipairs(Players:GetPlayers()) do
                        cleanupPlayerOverlay(targetPlayer)
                end
        end)
end)
parseWalkFlingDirectionSelection(getSavedControlValue("WalkFlingDirection") or { "Forward" })
syncFlingModeControls()
refreshModelDropdown()
task.defer(function()
        if blPlayersDropdownControl and blPlayersDropdownControl.SetValue then
                local toCheck = {}
                for label in pairs(blacklistedTargets) do
                        if modelDropdownLookup[label] or label == "Friends" then
                                toCheck[#toCheck + 1] = label
                        end
                end
                if #toCheck > 0 then
                        blPlayersDropdownControl.SetValue(toCheck, true)
                end
        end
end)
task.spawn(function()
        local updatePending = false
        local function updateDropdownsEvent()
                if updatePending then return end
                updatePending = true
                task.delay(0, function()
                        updatePending = false
                        if screenGui.Parent then
                                refreshModelDropdown()
                        end
                end)
        end
        local function setupCharacterSpawnCheck(char)
                task.spawn(function()
                        local elapsed = 0
                        local waitTime = 0.1
                        while elapsed < 10 and char.Parent do
                                local humanoid = char:FindFirstChild("Humanoid")
                                local hrp = char:FindFirstChild("HumanoidRootPart")
                                if humanoid and hrp then
                                        updateDropdownsEvent()
                                        break
                                end
                                task.wait(waitTime)
                                elapsed = elapsed + waitTime
                                if elapsed >= 1.0 then
                                        waitTime = 2.0
                                end
                        end
                end)
        end
        Players.PlayerAdded:Connect(function(p)
                updateDropdownsEvent()
                p.CharacterAdded:Connect(setupCharacterSpawnCheck)
                p.CharacterRemoving:Connect(updateDropdownsEvent)
        end)
        Players.PlayerRemoving:Connect(function(leavingPlayer)
                for label, entry in pairs(modelDropdownLookup) do
                        if entry.player == leavingPlayer and not entry.isOffline then
                                if blacklistedTargets[label] then
                                        local leavingName = leavingPlayer.Name
                                        if not offlinePlayers[leavingName] then
                                                offlinePlayers[leavingName] = {
                                                        name = leavingName,
                                                        displayName = leavingPlayer.DisplayName or leavingName,
                                                        userId = leavingPlayer.UserId,
                                                }
                                                local blNames = {}
                                                for lbl in pairs(blacklistedTargets) do
                                                        local e = modelDropdownLookup[lbl]
                                                        if e and e.player and not e.isOffline and e.baseNameStr then
                                                                blNames[#blNames + 1] = e.baseNameStr
                                                        end
                                                end
                                                blNames[#blNames + 1] = leavingName
                                                controlSaveData.BLPlayerNames = blNames
                                                controlSaveData.OfflinePlayers = offlinePlayers
                                                saveSliderSaveData()
                                        end
                                end
                                break
                        end
                end
                updateDropdownsEvent()
        end)
        for _, p in ipairs(Players:GetPlayers()) do
                p.CharacterAdded:Connect(setupCharacterSpawnCheck)
                p.CharacterRemoving:Connect(updateDropdownsEvent)
        end
        while screenGui.Parent do
                task.wait()
                updateDropdownsEvent()
        end
end)
local targetDragPosition = nil
local dragConnection = nil
local function startDragLoop()
        if dragConnection then return end
        dragConnection = RunService.RenderStepped:Connect(function(dt)
                if not settingsWindow or not targetDragPosition then
                        if dragConnection then
                                dragConnection:Disconnect()
                                dragConnection = nil
                        end
                        return
                end
                local currentPos = settingsWindow.Position
                local dist = (currentPos.X.Offset - targetDragPosition.X.Offset)^2 + (currentPos.Y.Offset - targetDragPosition.Y.Offset)^2
                if dist < 0.1 and not draggingWindow then
                        settingsWindow.Position = targetDragPosition
                        targetDragPosition = nil
                        if dragConnection then
                                dragConnection:Disconnect()
                                dragConnection = nil
                        end
                else
                        local alpha = 1
                        settingsWindow.Position = currentPos:Lerp(targetDragPosition, alpha)
                end
        end)
end
headerDragArea.InputBegan:Connect(function(input)
        if input.UserInputType ~= Enum.UserInputType.MouseButton1 then
                return
        end
        draggingWindow = true
        dragStartPosition = settingsWindow.Position
        dragStartInputPosition = input.Position
end)
headerDragArea.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
                draggingWindow = false
        end
end)
UserInputService.InputChanged:Connect(function(input)
        if draggingWindow and input.UserInputType == Enum.UserInputType.MouseMovement then
                local delta = input.Position - dragStartInputPosition
                local viewportSize = Workspace.CurrentCamera.ViewportSize
                local scale = getScaleFactorFor(settingsWindow)
                local original = scaleRegistry[settingsWindow]
                if not original then return end
                local guiViewportSize = viewportSize / scale
                local guiWindowSize = Vector2.new(original.Size.X.Offset, original.Size.Y.Offset)
                local startX = dragStartPosition.X.Offset / scale
                local startY = dragStartPosition.Y.Offset / scale
                local newOffsetUX = startX + (delta.X / scale)
                local newOffsetUY = startY + (delta.Y / scale)
                local anchor = settingsWindow.AnchorPoint
                local minUX = (guiWindowSize.X * anchor.X) - (guiViewportSize.X * dragStartPosition.X.Scale)
                local maxUX = (guiViewportSize.X * (1 - dragStartPosition.X.Scale)) - (guiWindowSize.X * (1 - anchor.X))
                local minUY = (guiWindowSize.Y * anchor.Y) - (guiViewportSize.Y * dragStartPosition.Y.Scale)
                local maxUY = (guiViewportSize.Y * (1 - dragStartPosition.Y.Scale)) - (guiWindowSize.Y * (1 - anchor.Y))
                local clampedUX = math.clamp(newOffsetUX, minUX, maxUX)
                local clampedUY = math.clamp(newOffsetUY, minUY, maxUY)
                original.Position = UDim2.new(
                        dragStartPosition.X.Scale, clampedUX,
                        dragStartPosition.Y.Scale, clampedUY
                )
                targetDragPosition = UDim2.new(
                        dragStartPosition.X.Scale, clampedUX * scale,
                        dragStartPosition.Y.Scale, clampedUY * scale
                )
                startDragLoop()
        end
end)
UserInputService.InputBegan:Connect(function(input, gameProcessed)
        if not introFinished or not _nxLoadComplete then
                return
        end
        local key = input.KeyCode
        if not UserInputService:GetFocusedTextBox() then
                if key == Enum.KeyCode.W then
                        holdingW = true
                elseif key == Enum.KeyCode.S then
                        holdingS = true
                elseif key == Enum.KeyCode.A then
                        holdingA = true
                elseif key == Enum.KeyCode.D then
                        holdingD = true
                end
        end
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
                local mousePosition = UserInputService:GetMouseLocation()
                local guiInset = GuiService:GetGuiInset()
                mousePosition = Vector2.new(mousePosition.X - guiInset.X, mousePosition.Y - guiInset.Y)
                local function isPointInsideFrame(frame)
                        if not frame or not frame.Visible then
                                return false
                        end
                        local position = frame.AbsolutePosition
                        local size = frame.AbsoluteSize
                        return mousePosition.X >= position.X
                                and mousePosition.X <= position.X + size.X
                                and mousePosition.Y >= position.Y
                                and mousePosition.Y <= position.Y + size.Y
                end
                for dropdownState in pairs(openDropdowns) do
                        if dropdownState.isExpanded() then
                                local insideChoiceFrame = isPointInsideFrame(dropdownState.choiceFrame)
                                local insideOptionsFrame = isPointInsideFrame(dropdownState.optionsFrame)
                                local clickedOptionButton = false
                                if not insideChoiceFrame then
                                        for _, optionButton in pairs(dropdownState.optionButtons or {}) do
                                                if isPointInsideFrame(optionButton) then
                                                        clickedOptionButton = true
                                                        break
                                                end
                                        end
                                end
                                if not insideChoiceFrame and not insideOptionsFrame and not clickedOptionButton then
                                        dropdownState.setExpanded(false)
                                end
                        end
                end
        end
        local key = input.KeyCode
        local isBacktick = (key.Name == "BackQuote" or key.Name == "Backquote" or key == Enum.KeyCode.Tilde or key.Value == 96 or key.Value == 126)
        if game.GameId == 3808081382 and input.UserInputType == Enum.UserInputType.Keyboard and isBacktick and keybindToggles.Places ~= "block" then
                if isSafeZoneActive() then return end
                if not selectedPlace or selectedPlace == "" or selectedPlace == "/\\" then
                        return
                end
                local isMapLocation = selectedPlace == "Middle Of Map" or selectedPlace == "Prison" or selectedPlace == "Montain 1 Left" or selectedPlace == "Montain 1 Right" or selectedPlace == "Montain 2" or selectedPlace == "Montain 2 Left" or selectedPlace == "Montain 2 Right"
                if isMapLocation then
                        if game.PlaceId ~= 10449761463 and game.PlaceId ~= 131048399685555 then
                                return
                        end
                end
                local cf = resolvePlaceCF(selectedPlace)
                if cf then
                        local character = player.Character
                        local characterRoot = character and character:FindFirstChild("HumanoidRootPart")
                        if characterRoot then
                                applyTeleportRootState(characterRoot, cf, Vector3.zero, Vector3.zero)
                        end
                end
                return
        end
        if gameProcessed or UserInputService:GetFocusedTextBox() then
                return
        end
        if key == Enum.KeyCode.LeftAlt then
                setSettingsVisible(not settingsOpen)
                return
        end
        if key == voidDeadKeybind and keybindToggles.Void ~= "block" then
                toggleVoidDead()
                return
        end
        if key == speedKeybind and keybindToggles.Speed ~= "block" then
                toggleSpeed()
                return
        end
        if key == flyKeybind and keybindToggles.Fly ~= "block" then
                toggleFly()
                return
        end
        if key == bodyLockKeybind then
                bodyLockEnabled = not bodyLockEnabled
                return
        end
        if key == comboLockKeybind then
                camLockEnabled = not camLockEnabled
                bodyLockEnabled = camLockEnabled
                if camLockEnabled or bodyLockEnabled then
                    toggleCamLock(true)
                else
                    toggleCamLock(false)
                end
                return
        end
        if key == camLockKeybind and keybindToggles.CamLock ~= "block" then
                toggleCamLock()
                return
        end
        if key == attackTpKeybind and keybindToggles.AttackTP ~= "block" then
                toggleAttackTp()
                return
        end
        if key == orbitKeybind and keybindToggles.Orbit ~= "block" then
                Orbit_toggle()
                return
        end
        if key == viewKeybind and keybindToggles.View ~= "block" then
                if viewing then
                        toggleView(false)
                elseif manualAttackTpPlayer or manualAttackTpTarget or manualAttackTpTargetName then
                        toggleView(true)
                end
                syncViewKeybindDisplay()
                return
        end
        if key == autoTpKeybind and keybindToggles.AutoTPKey ~= "block" then
                if targetActionControls and targetActionControls.Second then
                        local nextState = not autoTpEnabled
                        if nextState and not (manualAttackTpPlayer or manualAttackTpTarget or manualAttackTpTargetName) then
                                return
                        end
                        targetActionControls.Second.SetValue(nextState)
                else
                        AutoTP_toggle()
                end
                syncAutoTpKeybindDisplay()
                return
        end
        if key == flingKeybind and keybindToggles.FlingKey ~= "block" then
                if targetActionControls and targetActionControls.Third then
                        local nextFling = not flingEnabled
                        if nextFling and not (manualAttackTpPlayer or manualAttackTpTarget or manualAttackTpTargetName) then
                        else
                                targetActionControls.Third.SetValue(nextFling)
                                if not nextFling then
                                        zeroLocalPlayerRoot()
                                end
                                syncTargetActionControls()
                                syncFlingKeybindDisplay()
                        end
                else
                        local nextFling = not flingEnabled
                        if nextFling and not (manualAttackTpPlayer or manualAttackTpTarget or manualAttackTpTargetName) then
                        else
                                local wasEnabled = flingEnabled
                                flingEnabled = nextFling
                                if wasEnabled and not flingEnabled then
                                        zeroLocalPlayerRoot()
                                end
                                syncTargetActionControls()
                                syncFlingKeybindDisplay()
                        end
                end
                return
        end
        if key == targetSelectKeybind and keybindToggles.Target ~= "block" then
                toggleMouseTargetSelection()
                return
        end
        if key == walkFlingKeybind and keybindToggles.WalkFling ~= "block" then
                setWalkFlingEnabled()
                return
        end
        if key == setBackKeybind and keybindToggles.SetBack ~= "block" then
                handleSetBackKeybind()
                return
        end
        if key == getTrashState.keybind and keybindToggles.Trash ~= "block" then
                if getTrashState.keyHeld then
                        return
                end
                getTrashState.keyHeld = true
                runGetTrash()
                return
        end
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
                attackTpHolding = true
                return
        end
end)
player.CharacterRemoving:Connect(function(removingChar)
        if removingChar ~= char then
                return
        end
        if mainLoopConnection then
                mainLoopConnection:Disconnect()
                mainLoopConnection = nil
        end
        _G.NOTHINGX_PendingFlyRespawn = flying == true
        attackTpHolding = false
        stopSetBackTravel()
        if hum then
                hum.PlatformStand = false
                hum.WalkSpeed = 16
        end
        if bv then
                bv:Destroy()
                bv = nil
        end
        if bg then
                bg:Destroy()
                bg = nil
        end
        velocity = Vector3.zero
        currentVel = Vector3.zero
        if voidDeadActive then
                toggleVoidDead()
        end
        if orbitEnabled then
                stopOrbit()
        end
        if viewing then
                stopView()
                if syncViewKeybindDisplay then syncViewKeybindDisplay() end
        end
        if autoTpEnabled then
                autoTpEnabled = false
                if syncAutoTpKeybindDisplay then syncAutoTpKeybindDisplay() end
        end
        updateOrbitToggleButton()
        char = nil
        hum = nil
        root = nil
        cam = Workspace.CurrentCamera
        if localCharacterDiedConnection then
                localCharacterDiedConnection:Disconnect()
                localCharacterDiedConnection = nil
        end
end)
player.CharacterAdded:Connect(function(newChar)
        if getTrashState.running then
                getTrashState.running = false
                getTrashState.returning = false
                getTrashState.blockSetBack = false
                _G.SafeTeleportLock = false
                setGetTrashNoclipEnabled(false)
                syncGetTrashKeybindDisplay()
        end
        getTrashState.keyHeld = false
        getTrashState.savedCFrame = nil
        getTrashState.holdCFrame = nil
        bindLocalCharacter(newChar)
        if not hum then
                hum = newChar:WaitForChild("Humanoid", 5)
        end
        if not root then
                root = newChar:WaitForChild("HumanoidRootPart", 5)
        end
        bindLocalCharacter(newChar)
        attackTpHolding = false
        if flying or _G.NOTHINGX_PendingFlyRespawn == true then
                _G.NOTHINGX_PendingFlyRespawn = nil
                toggleFly(true)
        else
                syncFlyKeybindDisplay()
        end
        if syncTargetActionControls then
                syncTargetActionControls()
        end
        syncSpeedKeybindDisplay()
        syncCamLockKeybindDisplay()
        syncAttackTpKeybindDisplay()
        syncTargetPickKeybindDisplay()
        syncSetBackKeybindDisplay()
        syncGetTrashKeybindDisplay()
        if syncViewKeybindDisplay then syncViewKeybindDisplay() end
        if syncAutoTpKeybindDisplay then syncAutoTpKeybindDisplay() end
        if syncOrbitKeybindDisplay then syncOrbitKeybindDisplay() end
        updateOrbitToggleButton()
        updateTargetDisplay()
        if lastDeathCFrame then
                task.delay(0, function()
                        local r = newChar:FindFirstChild("HumanoidRootPart")
                        if r and lastDeathCFrame then
                                r:SetAttribute("IsAttackTP", true)
                                r.CFrame = lastDeathCFrame
                                task.delay(0.1, function() pcall(function() r:SetAttribute("IsAttackTP", false) end) end)
                        end
                end)
        end
end)
task.spawn(function()
        while true do
                local dt = nextFrame()
                if flying and bv and bg and root and root.Parent then
                        local attackTpControlling = attackTpEnabled and attackTpHolding
                        if attackTpControlling then
                                flyHoverPosition = nil
                                velocity = velocity:Lerp(Vector3.zero, dt * 18)
                                currentVel = currentVel:Lerp(Vector3.zero, dt * 20)
                                bv.Position = root.Position
                                bg.CFrame = getRotationOnlyCFrame(root.CFrame)
                        else
                                cam = Workspace.CurrentCamera or cam
                        end
                        if not attackTpControlling and cam then
                                local z, x = getMovementInput()
                                local isMoving = (holdingW or holdingS or holdingA or holdingD)
                                if not isMoving then
                                        if not flyHoverPosition then
                                                flyHoverPosition = root.Position
                                        end
                                        velocity = Vector3.zero
                                        currentVel = Vector3.zero
                                        bv.Position = flyHoverPosition
                                        pcall(function()
                                                root.AssemblyLinearVelocity = Vector3.zero
                                                root.AssemblyAngularVelocity = Vector3.zero
                                        end)
                                else
                                        flyHoverPosition = nil
                                        local inputDir = (cam.CFrame.LookVector * z) + (cam.CFrame.RightVector * x)
                                        local targetVel = inputDir.Magnitude > 0.01 and inputDir.Unit * getAppliedFlySpeed() or Vector3.zero
                                        velocity = velocity:Lerp(targetVel, dt * 16)
                                        currentVel = currentVel:Lerp(velocity, dt * 22)
                                        bv.Position = root.Position + currentVel * dt * 65
                                end
                                if currentVel.Magnitude > 3 then
                                        local moveDir = currentVel.Unit
                                        local tilt = -x * math.rad(14)
                                        local targetCF = CFrame.lookAt(Vector3.new(), moveDir) * CFrame.Angles(0, 0, tilt)
                                        bg.CFrame = bg.CFrame:Lerp(targetCF, dt * 16)
                                else
                                        bg.CFrame = bg.CFrame:Lerp(CFrame.lookAt(Vector3.new(), cam.CFrame.LookVector), dt * 11)
                                end
                        end
                end
        end
end)
do
        if targetActionHeartbeat then
                targetActionHeartbeat:Disconnect()
                targetActionHeartbeat = nil
        end
        targetActionHeartbeat = RunService.Heartbeat:Connect(function(dt)
        local shouldRefreshTargetDisplay = false
        if camLockEnabled or bodyLockEnabled then
                cam = Workspace.CurrentCamera or cam
                if cam then
                        local previousTarget = camLockTarget
                        local previousWaiting = camLockWaiting
                        if not isValidCamLockTarget(camLockTarget) then
                                local manualTarget = resolveManualAttackTpTargetModel()
                                if isValidCamLockTarget(manualTarget) then
                                        camLockTarget = manualTarget
                                elseif not manualAttackTpPlayer and tick() - lastTargetDeathTime > 0.5 then
                                        camLockTarget = getCamLockTarget()
                                end
                        end
                        local nextTarget = camLockTarget
                        if nextTarget and isDeadTargetModel(nextTarget) then
                                local nextPlayer = Players:GetPlayerFromCharacter(nextTarget)
                                if nextPlayer and nextPlayer.Parent ~= Players then
                                        clearCamLockTarget(false)
                                        shouldRefreshTargetDisplay = true
                                        camLockTarget = nil
                                        lastTargetDeathTime = tick()
                                elseif not nextPlayer and nextTarget.Parent == nil then
                                        local foundReplacement = false
                                        for _, model in ipairs(getSelectableTargetModels()) do
                                                if model.Name == nextTarget.Name and model:FindFirstChildOfClass("Humanoid") then
                                                        camLockTarget = model
                                                        foundReplacement = true
                                                        shouldRefreshTargetDisplay = true
                                                        break
                                                end
                                        end
                                        if not foundReplacement then
                                                camLockWaiting = true
                                        end
                                else
                                        camLockWaiting = true
                                end
                        end
                        camLockWaiting = camLockTarget == nil or not isValidCamLockTarget(camLockTarget)
                        if camLockTarget then
                                local targetRoot = camLockTarget:FindFirstChild("HumanoidRootPart")
                                if not targetRoot then
                                        camLockWaiting = true
                                else
                                        local cameraPosition = cam.CFrame.Position
                                        if camLockEnabled then
                                            cam.CFrame = CFrame.lookAt(cameraPosition, targetRoot.Position, targetRoot.CFrame.UpVector)
                                        end
                                        if bodyLockEnabled and Players.LocalPlayer.Character and Players.LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then
                                            local charRoot = Players.LocalPlayer.Character.HumanoidRootPart
                                            charRoot.CFrame = CFrame.lookAt(charRoot.Position, Vector3.new(targetRoot.Position.X, charRoot.Position.Y, targetRoot.Position.Z))
                                        end
                                end
                        end
                        if previousTarget ~= camLockTarget or previousWaiting ~= camLockWaiting then
                                syncCamLockKeybindDisplay()
                                syncTargetPickKeybindDisplay()
                                shouldRefreshTargetDisplay = true
                        end
                end
        end
        if attackTpEnabled and not camLockEnabled and not manualAttackTpPlayer and not manualAttackTpTarget then
                local previousAttackTarget = attackTpTarget
                if not isValidAttackTpTarget(attackTpTarget) then
                        attackTpTarget = nil
                end
                if not attackTpTarget and tick() - lastTargetDeathTime > 0.5 then
                        local nextAttackTarget = getClosestAlivePlayerTarget()
                        attackTpTarget = hasLiveStoredTarget(nextAttackTarget) and nextAttackTarget or nil
                end
                if previousAttackTarget ~= attackTpTarget then
                        shouldRefreshTargetDisplay = true
                end
        end
        targetDisplayAccumulator = (targetDisplayAccumulator or 0) + dt
        if shouldRefreshTargetDisplay or targetDisplayAccumulator >= 0.15 then
                targetDisplayAccumulator = 0
                updateTargetDisplay()
                local seenCurrentModels = {}
                for _, targetModel in ipairs(getSelectableTargetModels()) do
                        if isSelectableModelDropdownTarget(targetModel) then
                                local name = targetModel.Name ~= "" and targetModel.Name or "Model"
                                seenCurrentModels[name] = true
                                offlineModels[name] = true
                                offlineModelDeletionTimers[name] = nil
                        end
                end
                for name in pairs(offlineModels) do
                        if not seenCurrentModels[name] then
                                if not offlineModelDeletionTimers[name] then
                                        offlineModelDeletionTimers[name] = tick()
                                elseif tick() - offlineModelDeletionTimers[name] >= 10 then
                                        offlineModels[name] = nil
                                        offlineModelDeletionTimers[name] = nil
                                        if manualAttackTpTargetName == name then
                                                clearManualAttackTpTarget()
                                        end
                                        if camLockTarget and camLockTarget.Name == name then
                                                camLockTarget = nil
                                                camLockWaiting = false
                                                camLockEnabled = false
bodyLockEnabled = false
                                                syncCamLockKeybindDisplay()
                                        end
                                        blacklistedModelNames[name] = nil
                                        local prefixLabel = "[M] " .. name
                                        blacklistedTargets[prefixLabel] = nil
                                        local i = 2
                                        while blacklistedTargets[prefixLabel .. " (" .. i .. ")"] do
                                                blacklistedTargets[prefixLabel .. " (" .. i .. ")"] = nil
                                                i = i + 1
                                        end
                                end
                        end
                end
                if updateDynamicDropdownDisplays then
                        updateDynamicDropdownDisplays()
                end
        end
        local isTeleportLocked = (_G.SafeTeleportLock == true)
        local hasDropdown = manualAttackTpPlayer or manualAttackTpTarget or manualAttackTpTargetName
        if viewing and not hasDropdown then
                stopView()
        end
        if (autoTpEnabled or flingEnabled) and not manualAttackTpPlayer and not hasSelectedTargetOrPendingPlayer() then
                autoTpEnabled = false
                flingEnabled = false
                syncTargetActionControls()
        end
        if viewing then
                local desiredViewTarget = resolveAttackTpTarget()
                local desiredViewPlayer = hasTrackedSelectedPlayer() and manualAttackTpPlayer or Players:GetPlayerFromCharacter(desiredViewTarget)
                if isValidCamLockTarget(desiredViewTarget) and desiredViewTarget ~= currentViewTarget then
                        currentViewTarget = desiredViewTarget
                        currentViewPlayer = desiredViewPlayer
                        local desiredHumanoid = desiredViewTarget:FindFirstChildOfClass("Humanoid")
                        if desiredHumanoid and cam then
                                cam.CameraSubject = desiredHumanoid
                        end
                elseif isDeadTargetModel(currentViewTarget) or not isValidCamLockTarget(currentViewTarget) then
                        if currentViewPlayer and currentViewPlayer.Parent == Players then
                                local newViewTarget = getTrackedPlayerTargetModel(currentViewPlayer)
                                if isValidCamLockTarget(newViewTarget) then
                                        currentViewTarget = newViewTarget
                                        local newViewHumanoid = newViewTarget:FindFirstChildOfClass("Humanoid")
                                        if newViewHumanoid and cam then
                                                cam.CameraSubject = newViewHumanoid
                                        end
                                elseif isWaitingForSelectedTargetRespawn() then
                                        if hasTrackedSelectedPlayer() then
                                                currentViewPlayer = manualAttackTpPlayer
                                        else
                                                currentViewTarget = nil
                                        end
                                else
                                        if not hasDropdown then stopView() end
                                end
                        elseif isWaitingForSelectedTargetRespawn() then
                                if hasTrackedSelectedPlayer() then
                                        currentViewPlayer = manualAttackTpPlayer
                                else
                                        currentViewTarget = nil
                                end
                        else
                                if not hasDropdown then stopView() end
                        end
                        if viewing and currentViewTarget then
                                local currHum = currentViewTarget:FindFirstChildOfClass("Humanoid")
                                if currHum and cam and cam.CameraSubject ~= currHum then
                                        cam.CameraSubject = currHum
                                end
                        end
                elseif currentViewTarget then
                        local currentViewHumanoid = currentViewTarget:FindFirstChildOfClass("Humanoid")
                        if currentViewHumanoid and cam and cam.CameraSubject ~= currentViewHumanoid then
                                cam.CameraSubject = currentViewHumanoid
                        end
                end
        end
        local function performGodTP(target, allowFling)
                if isSafeZoneActive() then return end
                local character = player.Character
                local characterRoot = character and character:FindFirstChild("HumanoidRootPart")
                local characterHumanoid = character and character:FindFirstChildOfClass("Humanoid")
                if characterRoot and isAliveHumanoid(characterHumanoid) and not isTpBlocked(target) then
                        local targetCFrame, targetVelocity = getAttackTpPlacement(characterRoot, target)
                        if not targetCFrame and target and target.Parent ~= nil then
                                local targetRoot = target:FindFirstChild("HumanoidRootPart")
                                if targetRoot then
                                        targetCFrame = CFrame.lookAt(targetRoot.Position + Vector3.new(0, 3, 0), targetRoot.Position, worldUpVector)
                                        targetVelocity = Vector3.zero
                                end
                        end
                        if targetCFrame then
                                local amFlinging = allowFling and (walkFlingEnabled or flingEnabled or clickFlingEnabled or auraFlingEnabled)
                                local resolvedLinear = targetVelocity or Vector3.zero
                                local resolvedAngular = Vector3.zero
                                if amFlinging then
                                        local power = (walkFlingEnabled and walkFlingPower) or (flingEnabled and flingPower) or (clickFlingEnabled and flingPower) or (auraFlingEnabled and flingPower) or 20000
                                        resolvedAngular = Vector3.new(power * 2, power * 2, power * 2)
                                        resolvedLinear = resolvedLinear + (characterRoot.CFrame.LookVector * power * 0.5)
                                elseif (attackTpMode == "Middle") then
                                        resolvedLinear = targetVelocity or Vector3.zero
                                        resolvedAngular = Vector3.zero
                                end
                                applyTeleportRootState(characterRoot, targetCFrame, resolvedLinear, resolvedAngular)
                                if flying and bv and bg then
                                        bv.Position = characterRoot.Position
                                        bg.CFrame = getRotationOnlyCFrame(targetCFrame)
                                end
                        end
                end
        end
        if autoTpEnabled and not isTeleportLocked then
                local targetModel = resolveAttackTpTarget()
                if isValidAttackTpTarget(targetModel) then
                        performGodTP(targetModel, true)
                end
        end
        if attackTpEnabled and attackTpHolding then
                if manualAttackTpPlayer and manualAttackTpPlayer.Parent ~= Players then
                        clearManualAttackTpTarget()
                end
                if not manualAttackTpPlayer and manualAttackTpTarget and manualAttackTpTarget.Parent == nil and not manualAttackTpTargetName then
                        clearManualAttackTpTarget()
                end
                if isDeadTargetModel(attackTpTarget) and not manualAttackTpPlayer and not manualAttackTpTargetName then
                        attackTpTarget = nil
                end
                local preferredTarget = resolveAttackTpTarget()
                if preferredTarget then
                        attackTpTarget = preferredTarget
                end
                if isValidAttackTpTarget(attackTpTarget) then
                        performGodTP(attackTpTarget, false)
                end
        end
        if pendingTeleportToSelectedPlayer and isValidAttackTpTarget(resolveAttackTpTarget()) then
                teleportToSelectedTarget()
                pendingTeleportToSelectedPlayer = false
        end
        end)
end
UserInputService.InputEnded:Connect(function(input)
        local key = input.KeyCode
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
                attackTpHolding = false
                return
        end
        if key == setBackKeybind then
                handleSetBackKeybindReleased()
        end
        if key == getTrashState.keybind then
                getTrashState.keyHeld = false
                return
        end
        if key == Enum.KeyCode.W then
                holdingW = false
        elseif key == Enum.KeyCode.S then
                holdingS = false
        elseif key == Enum.KeyCode.A then
                holdingA = false
        elseif key == Enum.KeyCode.D then
                holdingD = false
        end
end)
uiLoaded = true
for _, cb in ipairs(queuedCallbacks) do
        pcall(cb)
end
task.defer(function()
        pcall(updateKeybindText)
        pcall(syncSpeedKeybindDisplay)
        pcall(syncFlyKeybindDisplay)
        pcall(syncCamLockKeybindDisplay)
        pcall(syncBodyLockKeybindDisplay)
        pcall(syncComboLockKeybindDisplay)
        pcall(syncAttackTpKeybindDisplay)
        pcall(syncWalkFlingKeybindDisplay)
        pcall(syncSetBackKeybindDisplay)
        pcall(syncGetTrashKeybindDisplay)
        pcall(syncVoidDeadKeybindDisplay)
        pcall(syncOrbitKeybindDisplay)
        pcall(syncViewKeybindDisplay)
        pcall(syncAutoTpKeybindDisplay)
        pcall(syncFlingKeybindDisplay)
        pcall(syncPlacesKeybindDisplay)
        pcall(updateKeybindText)
end)
task.spawn(function()
if game.GameId ~= 3808081382 then
    return
end
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")
local NORMAL_TRANSPARENCY = 0.66
local ULT_TRANSPARENCY = 0.55
local function Hide(Object)
        if not Object then
                return
        end
        pcall(function()
                if Object.Visible then
                        Object.Visible = false
                end
        end)
end
local BLACK = Color3.fromRGB(0,0,0)
local function SetBlack(Object)
        if not Object then
                return
        end
        pcall(function()
                if Object:IsA("Frame") then
                        if Object.BackgroundColor3 ~= BLACK then
                                Object.BackgroundColor3 = BLACK
                        end
                end
        end)
        pcall(function()
                if Object.ImageColor3 ~= BLACK then
                        Object.ImageColor3 = BLACK
                end
        end)
end
local Cooldowns = {}
local function RegisterHotbar(Hotbar)
        for _,v in ipairs(Hotbar:GetDescendants()) do
                if v.Name == "Cooldown" then
                        Cooldowns[v] = true
                        SetBlack(v)
                end
        end
        Hotbar.DescendantAdded:Connect(function(v)
                if v.Name == "Cooldown" then
                        Cooldowns[v] = true
                        SetBlack(v)
                end
        end)
end
local HiddenObjects = {}
local function AddHide(Object)
        if Object then
                table.insert(HiddenObjects,Object)
                Hide(Object)
        end
end
local function RegisterGui()
        pcall(function()
                AddHide(PlayerGui.Bar.MagicHealth.ImageButton)
                AddHide(PlayerGui.Bar.MagicHealth.TextLabel)
                AddHide(PlayerGui.Bar.MagicHealth.Ult)
                AddHide(PlayerGui.Gifting)
                AddHide(PlayerGui.MobileJunk)
                AddHide(PlayerGui.Version)
                AddHide(PlayerGui.Emotes.ImageLabel.GamepassTwo)
                AddHide(PlayerGui.Emotes.ImageLabel.Gamepass)
                AddHide(PlayerGui.Emotes.ImageLabel.Limited)
                AddHide(PlayerGui.Emotes.ImageLabel.Bulk)
                AddHide(PlayerGui.Cosmetics.Frame.Bulk)
        end)
        pcall(function()
                for _,v in ipairs(PlayerGui.Emotes.ImageLabel:GetDescendants()) do
                        if v.Name == "fake" then
                                AddHide(v)
                        end
                end
                PlayerGui.Emotes.ImageLabel.DescendantAdded:Connect(function(v)
                        if v.Name == "fake" then
                                AddHide(v)
                        end
                end)
        end)
        pcall(function()
                for _,v in ipairs(PlayerGui.Cosmetics.Frame:GetDescendants()) do
                        if v.Name == "fake" then
                                AddHide(v)
                        end
                end
                PlayerGui.Cosmetics.Frame.DescendantAdded:Connect(function(v)
                        if v.Name == "fake" then
                                AddHide(v)
                        end
                end)
        end)
        pcall(function()
                local Container = PlayerGui.TopbarPlus.TopbarContainer
                local function Check(v)
                        if v.Name ~= "UnnamedIcon" then
                                return
                        end
                        local IconButton = v:FindFirstChild("IconButton")
                        if not IconButton then
                                return
                        end
                        local IconImage = IconButton:FindFirstChild("IconImage")
                        if not IconImage then
                                return
                        end
                        if string.find(tostring(IconImage.Image),"14471730934") then
                                AddHide(v)
                        end
                end
                for _,v in ipairs(Container:GetDescendants()) do
                        Check(v)
                end
                Container.DescendantAdded:Connect(Check)
        end)
end
local function UpdateBar()
        pcall(function()
                local Bar = PlayerGui.Bar.MagicHealth.Health.Bar.Bar
                if Bar.ImageColor3 ~= BLACK then
                        Bar.ImageColor3 = BLACK
                end
                local NeedTransparency =
                        LocalPlayer:GetAttribute("Ultimate") == 100
                        and ULT_TRANSPARENCY
                        or NORMAL_TRANSPARENCY
                if Bar.ImageTransparency ~= NeedTransparency then
                        Bar.ImageTransparency = NeedTransparency
                end
        end)
end
task.spawn(function()
        pcall(function()
                RegisterHotbar(PlayerGui:WaitForChild("Hotbar"))
        end)
        RegisterGui()
        UpdateBar()
end)
PlayerGui.ChildAdded:Connect(function(v)
        task.wait()
        if v.Name == "Hotbar" then
                RegisterHotbar(v)
        end
        RegisterGui()
        UpdateBar()
end)
LocalPlayer:GetAttributeChangedSignal("Ultimate"):Connect(UpdateBar)
local chatConnectionPos = nil
local chatConnectionSize = nil
local chatConnectionParent = nil
local screenConnectionSize = nil
local function disconnectChatListeners()
        if chatConnectionPos then chatConnectionPos:Disconnect(); chatConnectionPos = nil end
        if chatConnectionSize then chatConnectionSize:Disconnect(); chatConnectionSize = nil end
        if chatConnectionParent then chatConnectionParent:Disconnect(); chatConnectionParent = nil end
end
local function disconnectScreenListener()
        if screenConnectionSize then screenConnectionSize:Disconnect(); screenConnectionSize = nil end
end
local function updateKeybindPosition(chatInputBar)
        if not keybindFrame or not keybindFrame.Parent then return end
        if not chatInputBar or not chatInputBar.Parent then return end
        local chatAbsPos = chatInputBar.AbsolutePosition
        local chatAbsSize = chatInputBar.AbsoluteSize
        local chatBottomY = chatAbsPos.Y + chatAbsSize.Y + 80
        local screenSize = screenGui.AbsoluteSize
        local newPos
        if screenSize.Y > 0 then
                local yScale = chatBottomY / screenSize.Y
                newPos = UDim2.new(0, 10, yScale, 0)
        else
                newPos = UDim2.new(0, 10, 0, chatAbsPos.Y + chatAbsSize.Y + 10)
        end
        if keybindFrame.Position ~= newPos then
                keybindFrame.Position = newPos
        end
end
local function startChatInputBarTracking()
        disconnectChatListeners()
        disconnectScreenListener()
        local chatInputBar = nil
        task.spawn(function()
                while true do
                        if not keybindFrame or not keybindFrame.Parent then
                                task.wait()
                                continue
                        end
                        pcall(function()
                                chatInputBar = CoreGui:FindFirstChild("ExperienceChat")
                                        and CoreGui.ExperienceChat:FindFirstChild("appLayout")
                                        and CoreGui.ExperienceChat.appLayout:FindFirstChild("chatInputBar")
                        end)
                        if chatInputBar then
                                break
                        end
                        task.wait()
                end
                updateKeybindPosition(chatInputBar)
                chatConnectionPos = chatInputBar:GetPropertyChangedSignal("AbsolutePosition"):Connect(function()
                        updateKeybindPosition(chatInputBar)
                end)
                chatConnectionSize = chatInputBar:GetPropertyChangedSignal("AbsoluteSize"):Connect(function()
                        updateKeybindPosition(chatInputBar)
                end)
                chatConnectionParent = chatInputBar:GetPropertyChangedSignal("Parent"):Connect(function()
                        if not chatInputBar.Parent then
                                startChatInputBarTracking()
                        end
                end)
                if screenGui then
                        screenConnectionSize = screenGui:GetPropertyChangedSignal("AbsoluteSize"):Connect(function()
                                updateKeybindPosition(chatInputBar)
                        end)
                end
        end)
end
startChatInputBarTracking()
task.spawn(function()
        while true do
                task.wait()
                for _,v in ipairs(HiddenObjects) do
                        pcall(function()
                                if v.Visible then
                                        v.Visible = false
                                end
                        end)
                end
                for v,_ in pairs(Cooldowns) do
                        if v and v.Parent then
                                SetBlack(v)
                        end
                end
                UpdateBar()
        end
end)
task.spawn(function()
        while true do
                task.wait()
                syncPlacesKeybindDisplay()
        end
end)
end)
