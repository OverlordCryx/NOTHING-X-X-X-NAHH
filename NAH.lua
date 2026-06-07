repeat
    task.wait();
until game:IsLoaded();

warn("NOTHING _X -X_X-")
Players = game:GetService("Players")
TweenService = game:GetService("TweenService")
UserInputService = game:GetService("UserInputService")
GuiService = game:GetService("GuiService")
RunService = game:GetService("RunService")
HttpService = game:GetService("HttpService")
Workspace = game:GetService("Workspace")
CoreGui = game:GetService("CoreGui")
function nextFrame()
	return RunService.Heartbeat:Wait()
end
local player = Players.LocalPlayer
local uiLoaded = false
local queuedCallbacks = {}
local characterSpawnTime = os.clock()
local espOverlayConfig = {
    showCharacter = false,
    showUltimate = false,
    showHp = false,
    showEsp = false,
    showStreak = false,
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
	TweenService:Create(infoContainer, TweenInfo.new(0.25, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
		BackgroundTransparency = 0.2,
	}):Play()
	if infoStroke then
		TweenService:Create(infoStroke, TweenInfo.new(0.25, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
			Transparency = 0.1,
		}):Play()
	end
	TweenService:Create(infoTitle, TweenInfo.new(0.25, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
		TextTransparency = 0,
		TextStrokeTransparency = 1,
	}):Play()
	TweenService:Create(infoText, TweenInfo.new(0.25, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
		TextTransparency = 0,
		TextStrokeTransparency = 1,
	}):Play()
	task.delay(tonumber(duration) or 3, function()
		if currentToken ~= (gui:GetAttribute("InfoToken") or 0) then
			return
		end
		if not infoContainer.Parent then
			return
		end
		local fadeTweenInfo = TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
		TweenService:Create(infoContainer, fadeTweenInfo, {
			BackgroundTransparency = 1,
		}):Play()
		if infoStroke then
			TweenService:Create(infoStroke, fadeTweenInfo, {
				Transparency = 1,
			}):Play()
		end
		TweenService:Create(infoTitle, fadeTweenInfo, {
			TextTransparency = 1,
			TextStrokeTransparency = 1,
		}):Play()
		local fadeText = TweenService:Create(infoText, fadeTweenInfo, {
			TextTransparency = 1,
			TextStrokeTransparency = 1,
		})
		fadeText:Play()
		fadeText.Completed:Connect(function()
			if currentToken ~= (gui:GetAttribute("InfoToken") or 0) then
				return
			end
			if infoContainer.Parent then
				infoContainer.Visible = false
			end
		end)
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
	Speed = "off",
	Fly = "off",
	CamLock = "off",
	AttackTP = "off",
	Target = "off",
	WalkFling = "off",
	SetBack = "off",
	Trash = "off",
	Void = "off",
	Places = "off"
}
local hideNamesEnabled = false
local scaleRegistry = {}
local baseResolution = Vector2.new(1900, 1200)
local function getViewportScale()
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
local function getScaleFactorFor(guiObject)
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
local function registerObject(guiObject)
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
local function applyScaleToObject(guiObject)
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
local function updateAllScales()
	local w = screenGui and screenGui.AbsoluteSize.X or 1600
	local h = screenGui and screenGui.AbsoluteSize.Y or 900
	if w < 10 then
		local cam = workspace.CurrentCamera
		if cam then
			w = cam.ViewportSize.X
			h = cam.ViewportSize.Y
		end
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
	local newKFPos = keybindFrame and UDim2.new(0, 10, kfYScale, 0) or nil
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
	if keybindFrame and newKFPos then
		keybindFrame.Position = newKFPos
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
		task.wait(0.25)
	end
end)
player.CharacterAdded:Connect(function()
	task.wait(1)
	pcall(updatePlayerInfoFrame)
end)
	keybindFrame = Instance.new("Frame")
	keybindFrame.Name = "KeybindFrame"
	keybindFrame.AnchorPoint = Vector2.new(0, 1)
	keybindFrame.Position = UDim2.new(0, 10, 0.9, 0)
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
targetFrame.Position = UDim2.new(1, -240, 0, 10)
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
		-- Also queue callback for false so keybindToggles stay in sync
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
			btn.BackgroundColor3 = Color3.fromRGB(100, 100, 100)
			btn.TextColor3 = Color3.fromRGB(255, 255, 255)
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
	settingsStroke.Color = Color3.fromRGB(200, 200, 200)
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
	if success and pages then
		while true do
			local items = pages:GetCurrentPage()
			for _, item in ipairs(items) do
				friendsList[item.Id] = true
			end
			if pages.IsFinished then
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
	while task.wait(2) do
		updateFriendCache()
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
sliderSaveFile = "NOTHING_X/UI/NOTHING_X_0.file"
Speed = 1.5
speedKeybind = Enum.KeyCode.E
flyKeybind = Enum.KeyCode.R
camLockKeybind = Enum.KeyCode.V
attackTpKeybind = Enum.KeyCode.T
targetSelectKeybind = Enum.KeyCode.C
setBackKeybind = Enum.KeyCode.N
voidDeadActive = false
voidDeadKeybind = Enum.KeyCode.Z
_G.SafeTeleportLock = false
local voidDeadLastCF = nil
local voidDeadConn = nil
local getTrashState = {
	keybind = Enum.KeyCode.LeftControl,
	running = false,
	returning = false,
	collisionState = nil,
	savedCFrame = nil,
	holdCFrame = nil,
	stepDistance = 150,
	stepDelay = 0.001,
	returnStepDistance = 10,
	returnStepDelay = 0.046,
	lastToggleAt = 0,
	toggleCooldown = 0.35,
	token = 0,
	keyHeld = false,
	blockSetBack = false,
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
	hum = newChar:WaitForChild("Humanoid")
	root = newChar:WaitForChild("HumanoidRootPart")
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
velocity = Vector3.new()
currentVel = Vector3.new()
local targetDisplayAccumulator = 0
camLockEnabled = false
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
attackTpLeadTime = 0.012
attackTpAirLeadTime = 0.025
attackTpMaxHorizontalLead = 8.0
attackTpVerticalLead = 0.015
attackTpMaxVerticalLead = 3.0
attackTpGroundVerticalOffset = 0
attackTpAirVerticalOffset = 0.25
local customOffsets = {}
for i = 1, 25 do
	customOffsets["Custom " .. tostring(i)] = { x = 0, y = 0, z = 0 }
end
local function getCustomDisplayName(i)
	local key = "Custom " .. tostring(i)
	local off = customOffsets[key] or { x = 0, y = 0, z = 0 }
	return string.format("Custom %s (%s,%s,%s)", tostring(i), tostring(off.z), tostring(off.y), tostring(off.x))
end
local worldUpVector = Vector3.new(0, 1, 0)
local function getMountainViewCF(index)
	local map = workspace:FindFirstChild("Map")
	local summer = map and map:FindFirstChild("Summer")
	if not summer then return nil end
	local views = {}
	for _, obj in ipairs(summer:GetChildren()) do
		if obj.Name == "ViewingBlock" then
			table.insert(views, obj)
		end
	end
	local function getTopGrass(model)
		local best = nil
		for _, part in ipairs(model:GetChildren()) do
			if part.Name == "Grass" then
				if best == nil or part.Position.Y > best.Position.Y then
					best = part
				end
			end
		end
		return best
	end
	local grasses = {}
	for _, model in ipairs(views) do
		local grass = getTopGrass(model)
		if grass then
			table.insert(grasses, grass)
		end
	end
	table.sort(grasses, function(a, b)
		return a.Position.Y > b.Position.Y
	end)
	local grass = grasses[index]
	if grass then
		return CFrame.new(grass.Position + Vector3.new(0, 5, 0))
	end
	return nil
end
local placesTPs = {
	["Middle Of Map"] = CFrame.new(139, 440, 32),
	["Montain 1 Left"] = CFrame.new(-351, 619, -81),
	["Montain 1 Right"] = CFrame.new(190, 650, -515),
	["Montain 2"] = CFrame.new(297, 671, 397),
	["Montain 2 Left"] = CFrame.new(201, 684, 439),
	["Montain 2 Right"] = CFrame.new(379, 699, 360),
}
local function resolvePlaceCF(name)
	if not name or name == "" or name == "/\\" then
		return nil
	end
	local cf = placesTPs[name]
	if cf then
		return cf
	end
	if name:find("^Montain %d View$") then
		local num = tonumber(name:match("%d+"))
		if num then
			return getMountainViewCF(num)
		end
	end
	local success, result = pcall(function()
		local cutscenes = workspace:FindFirstChild("Cutscenes")
		if not cutscenes then return nil end
		if name == "Counter" then
			local model = cutscenes:FindFirstChild("Death Cutscene")
			return model and (model:GetPivot() * CFrame.new(0, 0, 0))
		elseif name == "Counter Up" then
			local model = cutscenes:FindFirstChild("Death Cutscene")
			return model and (model:GetPivot() * CFrame.new(-20, 55, -33))
		elseif name == "Atomic Base" then
			local model = cutscenes:FindFirstChild("Atoms")
			return model and (model:GetPivot() * CFrame.new(0, -187, 0))
		elseif name == "Atomic Base Up" then
			local model = cutscenes:FindFirstChild("Atoms")
			return model and (model:GetPivot() * CFrame.new(0, 199, 0))
		elseif name == "Atomic Slash" then
			local atoms = cutscenes:FindFirstChild("Atoms")
			local model = atoms and atoms:FindFirstChild("sphere")
			return model and (model:GetPivot() * CFrame.new(0, 0, 0))
		elseif name == "Atomic Slash Up" then
			local atoms = cutscenes:FindFirstChild("Atoms")
			local model = atoms and atoms:FindFirstChild("sphere")
			return model and (model:GetPivot() * CFrame.new(0, 45, 0))
		end
	end)
	if success and result then
		return result
	end
	return nil
end
local placesOrder = {
	"/\\", "Middle Of Map",
	"Montain 1 Left", "Montain 1 Right",
	"Montain 2", "Montain 2 Left", "Montain 2 Right",
	"Montain 1 View", "Montain 2 View", "Montain 3 View", "Montain 4 View",
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
flingEnabled = false
walkFlingEnabled = false
auraFlingEnabled = false
clickFlingEnabled = false
flingAllEnabled = false
local FLING_INF_POWER = 1e12
walkFlingKeybind = Enum.KeyCode.X
walkFlingPower = 20000
flingPower = 20000
auraRange = 20
walkFlingUseNormal = false
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
function resolveAttackTpTarget() end 
function zeroLocalPlayerRoot() end
function syncFlingModeControls() end
function runGetTrash() end
function applyTeleportRootState(rootPart, cframe, linearVelocity, angularVelocity)
	if not rootPart then return end
	if cframe then rootPart.CFrame = cframe end
	if linearVelocity then rootPart.AssemblyLinearVelocity = linearVelocity end
	if angularVelocity then rootPart.AssemblyAngularVelocity = angularVelocity end
end
function overpowerRootState(rootPart, cframe, linearVelocity, angularVelocity)
	applyTeleportRootState(rootPart, cframe, linearVelocity, angularVelocity)
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
		return isfile(sliderSaveFile)
	end)
	if not success or not exists then
		return
	end
	local readSuccess, content = pcall(function()
		return readfile(sliderSaveFile)
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
	pcall(function()
		writefile(sliderSaveFile, HttpService:JSONEncode(controlSaveData))
	end)
end
loadSliderSaveData()
if type(controlSaveData.KeybindHideNamesEnabled) == "boolean" then
	hideNamesEnabled = controlSaveData.KeybindHideNamesEnabled
end
if type(controlSaveData.Overlay4HP) == "boolean" then espOverlayConfig.showHp = controlSaveData.Overlay4HP end
if type(controlSaveData.Overlay4Character) == "boolean" then espOverlayConfig.showCharacter = controlSaveData.Overlay4Character end
if type(controlSaveData.Overlay4Ultimate) == "boolean" then espOverlayConfig.showUltimate = controlSaveData.Overlay4Ultimate end
if type(controlSaveData.Overlay4ESP) == "boolean" then espOverlayConfig.showEsp = controlSaveData.Overlay4ESP end
if type(controlSaveData.Overlay4Streak) == "boolean" then espOverlayConfig.showStreak = controlSaveData.Overlay4Streak end
if tonumber(controlSaveData.Speed) then
	Speed = tonumber(controlSaveData.Speed)
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
if type(controlSaveData.BLClickTrash) == "boolean" then
	trashBlockEnabled = controlSaveData.BLClickTrash
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
-- Restore keybindToggles from saved data (Auto Load fix)
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
		Places   = "KeybindPlacesEnabled",
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
	local orderedKeys = { "Speed", "Fly", "CamLock", "AttackTP", "TargetPick", "WalkFling", "SetBack", "GetTrash", "VoidDead", "Custom", "Places" }
	-- Map keybindEntries keys to keybindToggles keys
	local toggleKeyMap = {
		TargetPick = "Target",
		VoidDead = "Void",
		GetTrash = "Trash",
	}
	local function appendEntry(entry, toggleState)
		if not entry then
			return
		end
		local name = tostring(entry.name or "")
		local keybind = tostring(entry.keybind or "")
		if hideNamesEnabled then
			name = ""
		end
		-- In "hide" mode: show name and keybind but hide the state text
		if toggleState == "hide" or entry.hideState == true then
			if name ~= "" and keybind ~= "" then
				lines[#lines + 1] = string.format("%s (%s)", name, keybind)
			elseif name ~= "" then
				lines[#lines + 1] = name
			elseif keybind ~= "" then
				lines[#lines + 1] = string.format("(%s)", keybind)
			end
			return
		end
		-- In "block" mode: show name, keybind, and state text
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
		-- Under the new rules:
		-- "off" state (default) -> shown in the keybind frame (with state text, i.e., "block" style).
		-- "hide" or "block" -> hidden from the keybind frame.
		if toggleState == "off" or toggleState == nil then
			appendEntry(keybindEntries[key], "block")
		elseif key == "Custom" then
			-- Custom entries are always shown if they exist
			appendEntry(keybindEntries[key], "block")
		end
	end
	if #lines == 0 then
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
function syncPlacesKeybindDisplay()
	local hasMain = hasMapMainPart()
	if hasMain ~= lastHasMainState then
		lastHasMainState = hasMain
		if game.GameId == 3808081382 then
			local mapPlaces = { 	"Middle Of Map", "Montain 1 Left", "Montain 1 Right", "Montain 2", "Montain 2 Left", "Montain 2 Right", "Montain 1 View", "Montain 2 View", "Montain 3 View", "Montain 4 View", }
			local otherPlaces = { "Counter", "Counter Up", "Atomic Base", "Atomic Base Up", "Atomic Slash", "Atomic Slash Up" }
			local currentItems = { "/\\" }
			for _, v in ipairs(mapPlaces) do table.insert(currentItems, v) end
			for _, v in ipairs(otherPlaces) do table.insert(currentItems, v) end
			if placesDropdown then
				placesDropdown.SetItems(currentItems)
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
		hrp.CFrame = CFrame.new(hrp.Position.X, -6666, hrp.Position.Z)
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
local DVoidDeadToggle = nil
local function toggleDVoidDead(state)
	local targetState = state
	if targetState == nil then
		targetState = not dVoidDeadActive
	end
	if targetState and isSafeZoneActive() then
		if DVoidDeadToggle then DVoidDeadToggle.SetValue(false, true) end
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
		if DVoidDeadToggle then DVoidDeadToggle.SetValue(false, true) end
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
		if DVoidDeadToggle then DVoidDeadToggle.SetValue(false, true) end
		return
	end
	if canSaveSetBackPosition(character, hrp, humanoid) then
		voidDeadLastCF = hrp.CFrame
	else
		voidDeadLastCF = hrp.CFrame
	end
	dVoidDeadActive = true
	if DVoidDeadToggle then DVoidDeadToggle.SetValue(true, true) end
	pcall(function()
		workspace.Camera.CameraType = Enum.CameraType.Scriptable
	end)
	if dVoidDeadConn then dVoidDeadConn:Disconnect() end
	dVoidDeadConn = game:GetService("RunService").Heartbeat:Connect(function()
		local targetModel = resolveAttackTpTarget()
		local targetPlayer = targetModel and game:GetService("Players"):GetPlayerFromCharacter(targetModel)
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
		if targetPlayer and targetHumanoid and targetHumanoid.Health > 0 then
			hrp.CFrame = CFrame.new(hrp.Position.X, -6666, hrp.Position.Z)
			hrp.AssemblyLinearVelocity = Vector3.zero
			hrp.AssemblyAngularVelocity = Vector3.zero
		else
			if dVoidDeadActive then
				toggleDVoidDead(false)
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
local function toggleAntiFling(enabled)
	antiFlingEnabled = enabled
	if antiFlingConnection then
		antiFlingConnection:Disconnect()
		antiFlingConnection = nil
	end
	if antiFlingEnabled then
		antiFlingConnection = game:GetService("RunService").Stepped:Connect(function()
			for _, p in ipairs(game:GetService("Players"):GetPlayers()) do
				if p ~= player and p.Character then
					for _, part in ipairs(p.Character:GetDescendants()) do
						if part:IsA("BasePart") and part.CanCollide then
							part.CanCollide = false
						end
					end
				end
			end
			for _, model in ipairs(getSelectableTargetModels()) do
				if model ~= player.Character then
					for _, part in ipairs(model:GetDescendants()) do
						if part:IsA("BasePart") and part.CanCollide then
							part.CanCollide = false
						end
					end
				end
			end
		end)
	end
end
local function syncFlyKeybindDisplay()
	keybindEntries.Fly = {
		name = "Fly",
		keybind = encodeKeybindValue(flyKeybind),
		enabled = flying,
	}
	updateKeybindText()
end
local function syncCamLockKeybindDisplay()
	keybindEntries.CamLock = {
		name = "CamLock",
		keybind = encodeKeybindValue(camLockKeybind),
		enabled = camLockEnabled,
		stateText = camLockEnabled and "ON" or "OFF",
	}
	updateKeybindText()
end
local function syncAttackTpKeybindDisplay()
	keybindEntries.AttackTP = {
		name = "Attack TP",
		keybind = encodeKeybindValue(attackTpKeybind),
		enabled = attackTpEnabled,
	}
	updateKeybindText()
end
local function syncTargetPickKeybindDisplay()
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
	if walkFlingDirections.Forward then
		direction += rootPart.CFrame.LookVector
	end
	if walkFlingDirections.Backward then
		direction -= rootPart.CFrame.LookVector
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
	local nextState = enabled == nil and not walkFlingEnabled or enabled == true
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
	local nextState = enabled == nil and not auraFlingEnabled or enabled == true
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
					local savedCFrame = myRoot.CFrame
					local myPosition = myRoot.Position
					local touchedAny = false
					for _, targetModel in ipairs(getSelectableTargetModels()) do
						if not isTargetBlacklisted(targetModel, Players:GetPlayerFromCharacter(targetModel)) then
							local targetRoot = getRootUniversal(targetModel)
							if targetRoot and (targetRoot.Position - myPosition).Magnitude <= auraRange then
								touchedAny = true
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
									break
								end
							end
						end
					end
					if touchedAny and myRoot.Parent then
						overpowerRootState(myRoot, savedCFrame, Vector3.zero, Vector3.zero)
					end
				end
				nextFrame()
			end
		end)
	end
	syncFlingModeControls()
	return auraFlingEnabled and "ON" or "OFF"
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
			myRoot.CFrame = savedCFrame
			task.wait(0.1)
			myRoot.CFrame = savedCFrame
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
	local nextState = enabled == nil and not clickFlingEnabled or enabled == true
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
local function disableConflictingFeatures()
	if walkFlingEnabled then setWalkFlingEnabled(false) end
	if auraFlingEnabled then setAuraFlingEnabled(false) end
	if clickFlingEnabled then setClickFlingEnabled(false) end
	if flingAllEnabled then setFlingAllEnabled(false) end
	if voidDeadActive then toggleVoidDead(false) end
	if dVoidDeadActive then toggleDVoidDead(false) end
	stopSetBackTravel()
end
local function restorePosition(savedCFrame)
	safeZoneRestoring = true
	local character = player.Character
	local hrp = character and character:FindFirstChild("HumanoidRootPart")
	if hrp and savedCFrame then
		hrp.Anchored = false
		
		-- Step 1: Teleport to 0, -6666, 0
		hrp.CFrame = CFrame.new(0, -6666, 0)
		hrp.AssemblyLinearVelocity = Vector3.zero
		hrp.AssemblyAngularVelocity = Vector3.zero
		task.wait()
		
		-- Step 2: Teleport to saved X/Z, Y -6666
		if hrp.Parent then
			hrp.CFrame = CFrame.new(savedCFrame.Position.X, -6666, savedCFrame.Position.Z)
			hrp.AssemblyLinearVelocity = Vector3.zero
			hrp.AssemblyAngularVelocity = Vector3.zero
			task.wait()
		end
		
		-- Step 3: Teleport to saved X/Y/Z
		if hrp.Parent then
			hrp.CFrame = savedCFrame
			hrp.AssemblyLinearVelocity = Vector3.zero
			hrp.AssemblyAngularVelocity = Vector3.zero
		end
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
	return setWalkFlingEnabled(value == nil and nil or parseEnabledValue(value))
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
	return setAuraFlingEnabled(value == nil and nil or parseEnabledValue(value))
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
	return setClickFlingEnabled(value == nil and nil or parseEnabledValue(value))
end
function FlingAll_tog(value)
	return setFlingAllEnabled(value == nil and nil or parseEnabledValue(value))
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
	auraRange = math.clamp(tonumber(value) or auraRange, 10, 5e9)
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
local function updateMovement()
	if not active then
		return
	end
	local hrp = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
	if not hrp then
		return
	end
	local moveVector = Vector3.new(0, 0, 0)
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
		hrp.CFrame = hrp.CFrame * CFrame.new(moveVector)
	end
end
local function toggleSpeed(nextState)
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
				task.wait()
				updateMovement()
			end
			speedLoopRunning = false
		end)
	end
	syncSpeedKeybindDisplay()
	return active and "ON" or "OFF"
end
local function toggleAFK(enabled)
	afkEnabled = enabled
	-- Disconnect old connections
	if afkConnection then
		afkConnection:Disconnect()
		afkConnection = nil
	end
	if afkCharAddedConnection then
		afkCharAddedConnection:Disconnect()
		afkCharAddedConnection = nil
	end
	if afkEnabled then
		-- Save current position instantly
		local character = player.Character
		local hrp = character and character:FindFirstChild("HumanoidRootPart")
		if hrp then
			afkSavedCFrame = hrp.CFrame
			afkCharacter = character
		else
			afkSavedCFrame = nil
			afkCharacter = nil
		end
		-- Turn off conflicting features
		disableConflictingFeatures()
		-- Teleport instantly to same X/Z, Y -6666
		if hrp then
			hrp.Anchored = false
			hrp.CFrame = CFrame.new(hrp.Position.X, -6666, hrp.Position.Z)
			hrp.AssemblyLinearVelocity = Vector3.zero
			hrp.AssemblyAngularVelocity = Vector3.zero
		end
		-- Heartbeat loop: keep player looping under map every frame
		local loopIndex = 1
		local loopPositions = {
			Vector3.new(0, -6666, 0),
			Vector3.new(10000, -6666, 0),
			Vector3.new(0, -6666, 10000)
		}
		local isFirstTp = false -- already teleported initially above
		afkConnection = RunService.Heartbeat:Connect(function()
			local char = player.Character
			local root = char and char:FindFirstChild("HumanoidRootPart")
			if not root then return end
			-- If character changed, update tracking
			if char ~= afkCharacter then
				afkCharacter = char
			end
			-- Save position if we don't have one yet (new character)
			if not afkSavedCFrame then
				afkSavedCFrame = root.CFrame
			end
			-- Force unanchor and teleport
			root.Anchored = false
			if isFirstTp then
				isFirstTp = false
				if afkSavedCFrame then
					root.CFrame = CFrame.new(afkSavedCFrame.Position.X, -6666, afkSavedCFrame.Position.Z)
				else
					root.CFrame = CFrame.new(root.Position.X, -6666, root.Position.Z)
				end
			else
				root.CFrame = CFrame.new(loopPositions[loopIndex])
				loopIndex = (loopIndex % #loopPositions) + 1
			end
			root.AssemblyLinearVelocity = Vector3.zero
			root.AssemblyAngularVelocity = Vector3.zero
		end)
		-- Handle respawn: save no position, just keep teleporting
		afkCharAddedConnection = player.CharacterAdded:Connect(function(newChar)
			afkSavedCFrame = nil
			afkCharacter = newChar
			task.spawn(function()
				local newRoot = newChar:WaitForChild("HumanoidRootPart", 5)
				if newRoot and afkEnabled then
					newRoot.Anchored = false
					newRoot.CFrame = CFrame.new(newRoot.Position.X, -6666, newRoot.Position.Z)
					newRoot.AssemblyLinearVelocity = Vector3.zero
					newRoot.AssemblyAngularVelocity = Vector3.zero
					isFirstTp = true
				end
			end)
		end)
	else
		-- Toggle OFF: restore saved position
		if afkSavedCFrame then
			task.spawn(restorePosition, afkSavedCFrame)
		end
		afkSavedCFrame = nil
		afkCharacter = nil
	end
	return afkEnabled and "ON" or "OFF"
end
-- Safe Zone HP variables
local safeZoneHPConnection = nil
local safeZoneHPCharAddedConnection = nil
local function toggleSafeZoneHP(enabled)
	safeZoneHPEnabled = enabled
	-- Disconnect old connections
	if safeZoneHPConnection then
		safeZoneHPConnection:Disconnect()
		safeZoneHPConnection = nil
	end
	if safeZoneHPCharAddedConnection then
		safeZoneHPCharAddedConnection:Disconnect()
		safeZoneHPCharAddedConnection = nil
	end
	-- If turning off while in safe zone, restore position
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
			Vector3.new(10000, -6666, 0),
			Vector3.new(0, -6666, 10000)
		}
		local isFirstTp = false
		-- Heartbeat loop: check HP every frame
		safeZoneHPConnection = RunService.Heartbeat:Connect(function()
			if not safeZoneHPEnabled or afkEnabled then return end
			local character = player.Character
			local humanoid = character and character:FindFirstChildOfClass("Humanoid")
			local hrp = character and character:FindFirstChild("HumanoidRootPart")
			if not humanoid or not hrp then return end
			local hp = humanoid.Health
			local maxHp = humanoid.MaxHealth
			if hp <= 0 then
				-- Player died while in safe zone, reset state
				if safeZoneHPInSafeZone then
					safeZoneHPInSafeZone = false
					safeZoneHPCharacter = nil
					safeZoneHPSavedCFrame = nil
				end
				return
			end
			-- If character changed while in safe zone, reset
			if safeZoneHPInSafeZone and safeZoneHPCharacter and character ~= safeZoneHPCharacter then
				safeZoneHPInSafeZone = false
				safeZoneHPCharacter = nil
				safeZoneHPSavedCFrame = nil
				return
			end
			if safeZoneHPInSafeZone then
				-- Currently in safe zone, check if HP >= 40 to exit
				if hp >= 40 then
					-- Restore saved position
					if safeZoneHPSavedCFrame then
						task.spawn(restorePosition, safeZoneHPSavedCFrame)
					end
					safeZoneHPInSafeZone = false
					safeZoneHPCharacter = nil
					safeZoneHPSavedCFrame = nil
				else
					-- Stay in safe zone: keep teleporting every frame
					hrp.Anchored = false
					if isFirstTp then
						isFirstTp = false
						if safeZoneHPSavedCFrame then
							hrp.CFrame = CFrame.new(safeZoneHPSavedCFrame.Position.X, -6666, safeZoneHPSavedCFrame.Position.Z)
						else
							hrp.CFrame = CFrame.new(hrp.Position.X, -6666, hrp.Position.Z)
						end
					else
						hrp.CFrame = CFrame.new(loopPositions[loopIndex])
						loopIndex = (loopIndex % #loopPositions) + 1
					end
					hrp.AssemblyLinearVelocity = Vector3.zero
					hrp.AssemblyAngularVelocity = Vector3.zero
				end
			else
				-- Not in safe zone, check if HP <= 30 to enter
				if hp <= 30 then
					-- Turn off conflicting features
					disableConflictingFeatures()
					-- Save current position
					safeZoneHPSavedCFrame = hrp.CFrame
					safeZoneHPCharacter = character
					safeZoneHPInSafeZone = true
					-- Teleport instantly to same X/Z, Y -6666
					hrp.Anchored = false
					hrp.CFrame = CFrame.new(hrp.Position.X, -6666, hrp.Position.Z)
					hrp.AssemblyLinearVelocity = Vector3.zero
					hrp.AssemblyAngularVelocity = Vector3.zero
					isFirstTp = false -- already did first teleport here
					loopIndex = 1
				end
			end
		end)
		-- Handle respawn: reset safe zone HP state cleanly
		safeZoneHPCharAddedConnection = player.CharacterAdded:Connect(function(newChar)
			characterSpawnTime = os.clock()
			safeZoneHPInSafeZone = false
			safeZoneHPCharacter = nil
			safeZoneHPSavedCFrame = nil
		end)
	end
	return safeZoneHPEnabled and "ON" or "OFF"
end
-- Auto-enable from saved settings on load
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
local function stopFly()
	flying = false
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
	velocity = Vector3.new()
	currentVel = Vector3.new()
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
local function hasLocalTrashcan()
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
local function clickTrashcan()
	local virtualInputManager = game:GetService("VirtualInputManager")
	virtualInputManager:SendMouseButtonEvent(0, 0, 0, true, game, 0)
	virtualInputManager:SendMouseButtonEvent(0, 0, 0, false, game, 0)
end
local function setGetTrashNoclipEnabled(enabled)
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
local function getTrashTravelCFrame(position, targetPosition)
	local lookTarget = Vector3.new(targetPosition.X, position.Y, targetPosition.Z)
	if (lookTarget - position).Magnitude <= 0.01 then
		lookTarget = position + Vector3.new(0, 0, -1)
	end
	return CFrame.lookAt(position, lookTarget, Vector3.new(0, 1, 0)) * CFrame.Angles(math.rad(-90), 0, 0)
end
local function startGetTrashHoldLoop(runToken)
	task.spawn(function()
		while getTrashState.running and getTrashState.token == runToken do
			task.wait()
			local currentCharacter = player.Character
			local rootPart = currentCharacter and currentCharacter:FindFirstChild("HumanoidRootPart")
			if rootPart and rootPart.Parent and getTrashState.holdCFrame then
				rootPart.AssemblyLinearVelocity = Vector3.zero
				rootPart.AssemblyAngularVelocity = Vector3.zero
				rootPart.CFrame = getTrashState.holdCFrame
			end
		end
	end)
end
local function getTrashTargetParts()
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
local function getRandomTrashTarget(ignoredModels)
	local availableTargets = {}
	for _, entry in ipairs(getTrashTargetParts()) do
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
	return availableTargets[math.random(1, #availableTargets)]
end
local function isValidTrashTarget(entry)
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
local function hasTrashcanAfterChecks(attempts, delayTime)
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
local function moveRootToTrashTarget(rootPart, targetPart, runToken)
	if not rootPart or not rootPart.Parent or not targetPart or not targetPart.Parent then
		return false
	end
	local startPosition = rootPart.Position
	local targetDistance = (targetPart.Position - startPosition).Magnitude
	local yOffset = targetDistance <= 21 and -1 or -15
	local destination = targetPart.Position + Vector3.new(0, yOffset, 0)
	local totalDistance = (destination - startPosition).Magnitude
	local stepCount = math.max(1, math.ceil(totalDistance / getTrashState.stepDistance))
	for stepIndex = 1, stepCount do
		if not getTrashState.running or getTrashState.returning or getTrashState.token ~= runToken or not rootPart.Parent or not targetPart.Parent then
			return false
		end
		local nextPosition = startPosition:Lerp(destination, stepIndex / stepCount)
		getTrashState.holdCFrame = getTrashTravelCFrame(nextPosition, targetPart.Position)
		task.wait(getTrashState.stepDelay)
	end
	return true
end
local function moveRootToSavedTrashCFrame(rootPart, targetCFrame, runToken)
	if not rootPart or not rootPart.Parent or not targetCFrame then
		return false
	end
	local startPosition = rootPart.Position
	local destination = targetCFrame.Position
	local loweredStart = Vector3.new(startPosition.X, startPosition.Y - 10, startPosition.Z)
	local loweredDestination = Vector3.new(destination.X, startPosition.Y - 10, destination.Z)
	local function travelBetween(fromPosition, toPosition, lookTarget, finalCFrame)
		local totalDistance = (toPosition - fromPosition).Magnitude
		local stepCount = math.max(1, math.ceil(totalDistance / getTrashState.returnStepDistance))
		for stepIndex = 1, stepCount do
			if not getTrashState.running or getTrashState.token ~= runToken or not rootPart.Parent then
				return false
			end
			local alpha = stepIndex / stepCount
			local nextPosition = fromPosition:Lerp(toPosition, alpha)
			if finalCFrame and stepIndex >= stepCount then
				getTrashState.holdCFrame = finalCFrame
			else
				getTrashState.holdCFrame = getTrashTravelCFrame(nextPosition, lookTarget)
			end
			task.wait(getTrashState.returnStepDelay)
		end
		return true
	end
	rootPart.AssemblyLinearVelocity = Vector3.zero
	rootPart.AssemblyAngularVelocity = Vector3.zero
	rootPart.CFrame = getTrashTravelCFrame(startPosition, loweredStart)
	getTrashState.holdCFrame = rootPart.CFrame
	if not travelBetween(startPosition, loweredStart, loweredStart, nil) then
		return false
	end
	if not travelBetween(loweredStart, loweredDestination, destination, nil) then
		return false
	end
	if not travelBetween(loweredDestination, destination, destination, targetCFrame) then
		return false
	end
	return true
end
local function returnFromTrashRun(runToken)
	local currentCharacter = player.Character
	local rootPart = currentCharacter and currentCharacter:FindFirstChild("HumanoidRootPart")
	if not rootPart or not getTrashState.savedCFrame then
		setGetTrashNoclipEnabled(false)
		getTrashState.blockSetBack = false
		return
	end
	moveRootToSavedTrashCFrame(rootPart, getTrashState.savedCFrame, runToken)
	if getTrashState.token == runToken then
		getTrashState.holdCFrame = nil
		setGetTrashNoclipEnabled(false)
		getTrashState.blockSetBack = false
	end
end
local function liftOutOfTrashRun()
	local currentCharacter = player.Character
	local rootPart = currentCharacter and currentCharacter:FindFirstChild("HumanoidRootPart")
	if not rootPart or not rootPart.Parent then
		return
	end
	rootPart.AssemblyLinearVelocity = Vector3.zero
	rootPart.AssemblyAngularVelocity = Vector3.zero
	rootPart.CFrame = rootPart.CFrame + Vector3.new(0, 17, 0)
end
local function teleportBackToSavedTrashPositionInstant()
	local currentCharacter = player.Character
	local rootPart = currentCharacter and currentCharacter:FindFirstChild("HumanoidRootPart")
	if not rootPart or not rootPart.Parent or not getTrashState.savedCFrame then
		return
	end
	rootPart.AssemblyLinearVelocity = Vector3.zero
	rootPart.AssemblyAngularVelocity = Vector3.zero
	rootPart.CFrame = getTrashState.savedCFrame
end
local function stopGetTrashImmediate()
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
			task.wait(0.05)
		end
	end)
	syncGetTrashKeybindDisplay()
end
local function finishGetTrashRun()
	getTrashState.running = false
	getTrashState.returning = false
	getTrashState.blockSetBack = false
	_G.SafeTeleportLock = false
	setGetTrashNoclipEnabled(false)
	getTrashState.savedCFrame = nil
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
	getTrashState.savedCFrame = rootPart.CFrame
	getTrashState.holdCFrame = nil
	setGetTrashNoclipEnabled(true)
	syncGetTrashKeybindDisplay()
	startGetTrashHoldLoop(runToken)
	task.spawn(function()
		local ignoredModels = {}
		local switchedTargets = 0
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
					task.wait(0.2)
				end
				setGetTrashNoclipEnabled(true)
				getTrashState.blockSetBack = true
				ignoredModels = {}
				switchedTargets = 0
				continue
			end
			if switchedTargets >= 40 then
				ignoredModels = {}
				switchedTargets = 0
				task.wait(0.15)
				continue
			end
			task.wait(0.15)
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
				task.wait(0.2)
				continue
			end
			if not moveRootToTrashTarget(rootPart, targetEntry.part, runToken) then
				break
			end
			local clickAttempts = 0
			while getTrashState.running and not getTrashState.returning and getTrashState.token == runToken and clickAttempts < 4 and not hasLocalTrashcan() do
				if not isValidTrashTarget(targetEntry) or not rootPart.Parent then
					break
				end
				local distanceToTarget = (targetEntry.part.Position - rootPart.Position).Magnitude
				if distanceToTarget > 5 then
					if not moveRootToTrashTarget(rootPart, targetEntry.part, runToken) then
						break
					end
				else
					local closePosition = targetEntry.part.Position + Vector3.new(0, -1, 0)
					getTrashState.holdCFrame = getTrashTravelCFrame(closePosition, targetEntry.part.Position)
					rootPart.AssemblyLinearVelocity = Vector3.zero
					rootPart.AssemblyAngularVelocity = Vector3.zero
					rootPart.CFrame = getTrashState.holdCFrame
					clickTrashcan()
					clickAttempts += 1
					task.wait(0.2)
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
		local dist = (destCF.Position - startCF.Position).Magnitude
		if dist < 250 then
			applyTeleportRootState(rootPart, destCF, Vector3.zero, Vector3.zero)
		else
			applyTeleportRootState(rootPart, startCF:Lerp(destCF, 0.25), Vector3.zero, Vector3.zero)
			task.wait(0.05)
			if setBackTravelToken ~= runToken then return end
			applyTeleportRootState(rootPart, startCF:Lerp(destCF, 0.50), Vector3.zero, Vector3.zero)
			task.wait(0.05)
			if setBackTravelToken ~= runToken then return end
			applyTeleportRootState(rootPart, startCF:Lerp(destCF, 0.75), Vector3.zero, Vector3.zero)
			task.wait(0.05)
			if setBackTravelToken ~= runToken then return end
			applyTeleportRootState(rootPart, destCF, Vector3.zero, Vector3.zero)
		end
		local humanoid = character:FindFirstChildOfClass("Humanoid")
		if humanoid then
			humanoid.PlatformStand = false
			humanoid.Sit = false
			humanoid:ChangeState(Enum.HumanoidStateType.GettingUp)
		end
	end)
	return true
end
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
	local now = tick()
	local timeSinceLast = now - setBackLastPressAt
	if timeSinceLast > 0.4 then
		setBackPressCount = 0
	end
	if timeSinceLast > 0.05 then
		setBackPressCount = math.min(setBackPressCount + 1, 4)
	end
	setBackLastPressAt = now
	setBackPressToken = (setBackPressToken or 0) + 1
	local currentToken = setBackPressToken
	if setBackPressCount == 1 then
		task.delay(0.25, function()
			if setBackPressToken == currentToken then
				if setBackSavedCFrame then
					startSetBackTravel()
				end
				setBackPressCount = 0
			end
		end)
	elseif setBackPressCount == 2 then
		if setBackSavedCFrame then
			clearSetBackPosition()
		else
			saveSetBackPosition()
		end
	elseif setBackPressCount == 3 then
		saveSetBackPosition()
	elseif setBackPressCount == 4 then
		if setBackSavedCFrame then
			startSetBackTravel()
		end
	end
end
local function toggleFly(nextState)
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
		bv.MaxForce = Vector3.new(1e7, 1e7, 1e7)
		bv.Position = root.Position
		bv.D = 2000
		bv.P = 18000
		bv.Parent = root
		if bg then
			bg:Destroy()
		end
		bg = Instance.new("BodyGyro")
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
local function handleCharacterDeath()
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
local function bindLocalCharacter(newChar)
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
			velocity = Vector3.new()
			currentVel = Vector3.new()
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
local function isDeadTargetModel(model)
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
local function hasLiveStoredTarget(model)
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
local function getSelectablePlayerForTargetModel(model)
	local targetPlayer = model and Players:GetPlayerFromCharacter(model)
	if isSelectablePlayerDropdownTarget(targetPlayer) then
		return targetPlayer
	end
	return nil
end
local manualAttackTpTargetName = nil
local function resolveManualAttackTpTargetModel()
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
local function hasManualAttackTpSelection()
	if manualAttackTpPlayer then
		return hasTrackedSelectedPlayer()
	end
	return hasLiveStoredTarget(manualAttackTpTarget)
end
local function hasActiveSelectedTarget()
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
local function getDisplayedTargetModel()
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
local function updateTargetDisplay()
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
		local baseName = string.sub(plr and plr.Name or displayedTarget.Name, 1, 20)
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
			local dispName = string.sub(plr.DisplayName or "", 1, 20)
			if dispName ~= "" and dispName ~= baseName then
				line2 = "| " .. dispName
			end
		end
	elseif manualAttackTpPlayer then
		local baseName = string.sub(manualAttackTpPlayer.Name, 1, 20)
		line1 = "| " .. baseName
		local dispName = string.sub(manualAttackTpPlayer.DisplayName or "", 1, 20)
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
local function getClosestAliveTarget()
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
	scanFolder(Workspace)
	cachedSelectableModels = models
	return models
end
local function getClosestAlivePlayerTarget()
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
local function getPreferredAttackTpTarget()
	if hasLiveStoredTarget(camLockTarget) then
		return camLockTarget
	end
	local resolvedManualTarget = resolveManualAttackTpTargetModel()
	if hasLiveStoredTarget(resolvedManualTarget) then
		return resolvedManualTarget
	end
	return getClosestAlivePlayerTarget()
end
local function getCurrentActionTargetModel(allowClosestFallback)
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
local function getHorizontalUnit(vector)
	local flattened = Vector3.new(vector.X, 0, vector.Z)
	local magnitude = flattened.Magnitude
	if magnitude <= 0.001 then
		return nil
	end
	return flattened / magnitude
end
local function getRotationOnlyCFrame(sourceCFrame)
	if not sourceCFrame then
		return CFrame.new()
	end
	return CFrame.lookAt(Vector3.new(), sourceCFrame.LookVector, sourceCFrame.UpVector)
end
zeroLocalPlayerRoot = function()
	local character = player.Character
	local hrp = character and character:FindFirstChild("HumanoidRootPart")
	if not hrp then
		return
	end
	hrp.AssemblyLinearVelocity = Vector3.zero
	hrp.AssemblyAngularVelocity = Vector3.zero
end
local function getAppliedFlySpeed()
	return flySpeed * flySpeedMultiplier
end
local function isAirborneHumanoid(modelHumanoid)
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
local function isAliveHumanoid(humanoid)
	return humanoid ~= nil
		and humanoid.Health > 0
		and humanoid:GetState() ~= Enum.HumanoidStateType.Dead
end
local function getAttackTpPlacement(characterRoot, targetModel, modeOverride)
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
	local leadTime = useAirTracking and attackTpAirLeadTime or attackTpLeadTime
	local horizontalVelocity = Vector3.new(targetVelocity.X, 0, targetVelocity.Z)
	local horizontalLead = horizontalVelocity * leadTime
	if horizontalLead.Magnitude > attackTpMaxHorizontalLead then
		horizontalLead = horizontalLead.Unit * attackTpMaxHorizontalLead
	end
	local verticalVel = targetVelocity.Y
	local verticalLead = (verticalVel * leadTime) + (isTargetAir and attackTpVerticalLead or 0)
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
		finalCFrame = CFrame.lookAt(predictedTargetPosition + Vector3.new(0, verticalOffset + 0.1, 0), predictedTargetPosition, worldUpVector)
	elseif string.find(tostring(mode), "Custom") then
		local cleanMode = tostring(mode):match("Custom %d+")
		local offsets = customOffsets[cleanMode] or { x = 0, y = 0, z = 0 }
		local offsetVec = Vector3.new(offsets.x, offsets.y, offsets.z)
		if offsetVec.Magnitude < 0.1 then
			offsetVec = Vector3.new(0, 0.1, 0)
		end
		finalCFrame = CFrame.lookAt(predictedTargetPosition + offsetVec + Vector3.new(0, verticalOffset, 0), predictedTargetPosition, worldUpVector)
	end
	if not finalCFrame then
		finalCFrame = CFrame.lookAt(predictedTargetPosition + Vector3.new(0, 6.8, 0), predictedTargetPosition, worldUpVector)
	end
	return finalCFrame, targetVelocity
end
local function getCamLockTarget()
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
local function getClosestMouseTarget()
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
local function clearManualAttackTpTarget()
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
local function clearCamLockTarget(disableCamLock)
	camLockTarget = nil
	camLockWaiting = false
	if disableCamLock == true then
		camLockEnabled = false
		clearManualAttackTpTarget()
	end
	syncCamLockKeybindDisplay()
	syncTargetPickKeybindDisplay()
	updateTargetDisplay()
	return nil
end
local function setManualAttackTpTarget(model, targetPlayer)
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
local function toggleMouseTargetSelection()
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
local function toggleCamLock(nextState)
	if nextState == nil then
		camLockEnabled = not camLockEnabled
	else
		camLockEnabled = nextState
	end
	if camLockEnabled then
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
	syncTargetPickKeybindDisplay()
	updateTargetDisplay()
	return camLockEnabled and "ON" or "OFF"
end
local function toggleAttackTp(nextState)
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
local function getMovementInput()
	local z = (UserInputService:IsKeyDown(Enum.KeyCode.W) and 1 or 0) - (UserInputService:IsKeyDown(Enum.KeyCode.S) and 1 or 0)
	local x = (UserInputService:IsKeyDown(Enum.KeyCode.D) and 1 or 0) - (UserInputService:IsKeyDown(Enum.KeyCode.A) and 1 or 0)
	return z, x
end
local function setSettingsVisible(visible)
	if not settingsWindow or not windowOutline then return end
	settingsOpen = visible
	settingsWindow.Visible = visible
	windowOutline.Visible = visible
	if visible then
		local animVal = settingsWindow:FindFirstChild("WindowAnimScale")
		if animVal then
			animVal.Value = 0.95
			TweenService:Create(animVal, TweenInfo.new(0.25, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
				Value = 1.0,
			}):Play()
		end
		TweenService:Create(settingsWindow, TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
			BackgroundTransparency = 0.18,
		}):Play()
		TweenService:Create(settingsStroke, TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
			Transparency = 0.05,
		}):Play()
		TweenService:Create(windowOutlineStroke, TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
			Transparency = 0.05,
		}):Play()
	else
		settingsWindow.BackgroundTransparency = 1
		if settingsStroke then settingsStroke.Transparency = 1 end
		if windowOutlineStroke then windowOutlineStroke.Transparency = 1 end
	end
end
local function applySliderValue(state, rawValue, triggerCallback)
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
local function makeControlFrame(heightScale)
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
	return holder
end
local function showInfo(title, text, time)
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
local SM_playerState = {}     
local SM_activeTimers = {}
local SM_playerConnections = {}
local SM_PlayersAddedConn = nil
local function toggleSeriousModeTracker(state)
	SeriousModeTrackerEnabled = state == true
	local Players = game:GetService("Players")
	local SERIOUS_MODE_STATE_ATTRIBUTE = "NX_SeriousModeState"
	if not SeriousModeTrackerEnabled then
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
	local RunService = game:GetService("RunService")
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
		elseif skill == "weak" and currentState == "strong" then
			SM_playerState[plr] = "weak"
			char:SetAttribute(SERIOUS_MODE_STATE_ATTRIBUTE, "weak")
			pcall(updatePlayerOverlay, plr)
			callInfo("SERIOUS MODE", plr.Name .. " - DEATH", 7)
			local timerId = tick()
			SM_activeTimers[plr] = timerId
			task.delay(9.4, function()
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
		elseif skill == nil and (currentState == "strong" or currentState == "weak") then
			SM_playerState[plr] = nil
			if char:GetAttribute(SERIOUS_MODE_STATE_ATTRIBUTE) ~= nil then
				char:SetAttribute(SERIOUS_MODE_STATE_ATTRIBUTE, nil)
				pcall(updatePlayerOverlay, plr)
			end
		end
	end
	local function startGlobalChecker()
		task.spawn(function()
			while SeriousModeTrackerEnabled do
				for _, plr in ipairs(Players:GetPlayers()) do
					if plr ~= Players.LocalPlayer then
						pcall(updatePlayer, plr)
					end
				end
				task.wait(0) 
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
						if plr.Parent and SeriousModeTrackerEnabled then updatePlayer(plr) end
					end)
				end)
				local cRemoved = backpack.ChildRemoved:Connect(function()
					task.defer(function()
						if plr.Parent and SeriousModeTrackerEnabled then updatePlayer(plr) end
					end)
				end)
				local charAdded = char.ChildAdded:Connect(function(child)
					if child:IsA("Tool") then
						task.defer(function()
							if plr.Parent and SeriousModeTrackerEnabled then updatePlayer(plr) end
						end)
					end
				end)
				local charRemoved = char.ChildRemoved:Connect(function(child)
					if child:IsA("Tool") then
						task.defer(function()
							if plr.Parent and SeriousModeTrackerEnabled then updatePlayer(plr) end
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
				if SeriousModeTrackerEnabled then updatePlayer(plr) end
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
local CharacterCleanupEnabled = false
local ModConnections = {}
local function toggleCharacterCleanupRuntime(state)
	CharacterCleanupEnabled = state == true
	if not CharacterCleanupEnabled then
		if ModConnections.wsLoop then ModConnections.wsLoop:Disconnect(); ModConnections.wsLoop = nil end
		if ModConnections.jpLoop then ModConnections.jpLoop:Disconnect(); ModConnections.jpLoop = nil end
		if ModConnections.hrpLoop then ModConnections.hrpLoop:Disconnect(); ModConnections.hrpLoop = nil end
		if ModConnections.CharacterAdded then ModConnections.CharacterAdded:Disconnect(); ModConnections.CharacterAdded = nil end
		return
	end
	local Players = game:GetService("Players")
	local speaker = Players.LocalPlayer
	local speed = 25.50
	local jpower = 50.50
	local function SetupHumanoid(Char, Human)
		if not Human or not Human.Parent then return end
		if ModConnections.wsLoop then ModConnections.wsLoop:Disconnect() end
		if ModConnections.jpLoop then ModConnections.jpLoop:Disconnect() end
		local function UpdateWalkSpeed()
			if Human and Human.Parent and CharacterCleanupEnabled then
				Human.WalkSpeed = speed
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
	local function OnCharacterAdded(Char)
		local Human = Char:WaitForChild("Humanoid", 5)
		if Human then SetupHumanoid(Char, Human) end
		task.wait(0.25)
		if CharacterCleanupEnabled then usunPusteAccessory(Char) end
	end
	if speaker.Character then OnCharacterAdded(speaker.Character) end
	ModConnections.CharacterAdded = speaker.CharacterAdded:Connect(OnCharacterAdded)
	task.spawn(function()
		while CharacterCleanupEnabled do
			task.wait()
			local char = speaker.Character
			if char then
				usunPusteAccessory(char)
				local hrp = char:FindFirstChild("HumanoidRootPart")
				if hrp then hrp.Anchored = false end
			end
		end
	end)
	task.spawn(function()
		while CharacterCleanupEnabled do 
			local args = { { Goal = "delete bv", BV = Instance.new("BodyVelocity", nil) } }
			pcall(function() speaker.Character:WaitForChild("Communicate"):FireServer(unpack(args)) end)
			task.wait(0.15)
		end
	end)
end
local function initInvisibleBorderCleanup()
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
local StayToggle = nil
local DashToggle = nil
task.spawn(function()
    local stayPos = nil
    local stayConn = nil
    local stayGyro = nil
    local isActive = false
    local directions = {
        Enum.KeyCode.A,
        Enum.KeyCode.D,
        Enum.KeyCode.S,
    }
    local DashBlockRunning = false
    local DashThread = nil
    local communicate = nil
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
        task.delay(0.15, function()
            if humanoid and humanoid.Parent then
                humanoid.CameraOffset = Vector3.new(0, 0, 0)
            end
        end)
    end
    local autoFixCamEnabled = false
    local antiDeathEnabled = false
    local noclipEnabled = false
    local noclipConnection = nil
    local function toggleNoclip(enabled)
        noclipEnabled = enabled
        if noclipConnection then
            noclipConnection:Disconnect()
            noclipConnection = nil
        end
        if enabled then
            noclipConnection = game:GetService("RunService").Stepped:Connect(function()
                local char = game:GetService("Players").LocalPlayer.Character
                if char then
                    for _, part in ipairs(char:GetDescendants()) do
                        if part:IsA("BasePart") then
                            part.CanCollide = false
                        end
                    end
                end
            end)
        end
    end
    local isProcessingAntiDeath = false
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
        local hrp = character and character:FindFirstChild("HumanoidRootPart")
        local humanoid = character and character:FindFirstChild("Humanoid")
        if not (hrp and humanoid) then
            isProcessingAntiDeath = false
            return
        end
        local savedCFrame = hrp.CFrame
        workspace.Camera.CameraType = Enum.CameraType.Scriptable
        workspace.Camera.CameraSubject = nil
        local startTime = tick()
        local connection
        connection = game:GetService("RunService").Heartbeat:Connect(function()
            if not hrp or not hrp.Parent then return end
            hrp.CFrame = CFrame.new(savedCFrame.X, -6666, savedCFrame.Z)
            hrp.AssemblyLinearVelocity = Vector3.zero
            hrp.AssemblyAngularVelocity = Vector3.zero
        end)
        repeat
            task.wait()
        until (tick() - startTime) > 2.8 or not isDeathCounterActive()
        if connection then connection:Disconnect() end
        if hrp and hrp.Parent then
            hrp.CFrame = savedCFrame
            hrp.AssemblyLinearVelocity = Vector3.zero
            hrp.AssemblyAngularVelocity = Vector3.zero
        end
        workspace.Camera.CameraType = Enum.CameraType.Custom
        workspace.Camera.CameraSubject = humanoid
        task.wait(0.1)
        if humanoid and humanoid.Parent then
            workspace.Camera.CameraSubject = humanoid
        end
        isProcessingAntiDeath = false
    end
    task.spawn(function()
        while true do
            task.wait()
            if not antiDeathEnabled or isProcessingAntiDeath then continue end
            if isDeathCounterActive() then
                bypassDeathCounter()
            end
        end
    end)
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
    local function layCharacter()
        local character = player.Character
        if not character then
            return
        end
        local humanoid = character:FindFirstChildWhichIsA("Humanoid")
        if not humanoid then
            return
        end
        humanoid.Sit = true
        task.wait(0.1)
        local root = character:FindFirstChild("HumanoidRootPart")
        if root then
            root.CFrame = root.CFrame * CFrame.Angles(math.pi * 0.5, 0, 0)
        end
        for _, track in ipairs(humanoid:GetPlayingAnimationTracks()) do
            track:Stop()
        end
    end
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
            stayGyro.MaxTorque = Vector3.new(1e9, 9e9, 9e9)
            stayGyro.P = 9e9
            stayGyro.CFrame = root.CFrame
            stayGyro.Parent = root
            stayConn = RunService.Heartbeat:Connect(function()
                if root and stayPos then
                    root.AssemblyLinearVelocity = Vector3.zero
                    root.AssemblyAngularVelocity = Vector3.zero
                    root.CFrame = CFrame.new(stayPos) * CFrame.Angles(
                        0,
                        math.rad(root.Orientation.Y),
                        0
                    )
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
                task.wait(0.05)
            end
        end)
    end
    local localAnimConn = nil
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
    local movementHub = makeControlFrame(isTSB and 184 or 94)
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
        btn.AutoButtonColor = true
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
    makeHubBtn(row1, "Lay", layCharacter, isTSB and 1/4 or 1/3)
    if isTSB then
        local row2 = makeRow(60)
        makeHubTog(row2, "Whirlwind", function(v) _G.WhirlwindEnabled = v end, "AutoWhirlwind", false)
        makeHubTog(row2, "Auto Combo", function(v) _G.WallComboEnabled = v end, "AutoCombo", false)
        makeHubTog(row2, "No Dash CD", function(v) 
            _G.NoDashCD_Enabled = v
            workspace:SetAttribute("EffectAffects", v and 1 or 0)
            workspace:SetAttribute("NoDashCooldown", v)
        end, "NoDashCD", false)
        makeHubTog(row2, "BL Trash", function(v) setTrashBlockEnabled(v) end, "BLClickTrash", false)
        local row3 = makeRow(90)
        makeHubTog(row3, "Safe Zone (N)", function(v) toggleAFK(v) end, "AFKEnabled", false, 1/3)
        makeHubTog(row3, "Safe Zone (HP)", function(v) toggleSafeZoneHP(v) end, "HPSafeZoneEnabled", false, 1/3)
        makeHubTog(row3, "HP Target", function(v) updateTargetDisplay() end, "TargetHPEnabled", false, 1/3)
        local row4 = makeRow(120)
        makeHubTog(row4, "Anti Death Cntr", function(v) antiDeathEnabled = v end, "AntiDeathCounterEnabled", false, 1/3)
        makeHubTog(row4, "Auto Fix Cam", function(v) autoFixCamEnabled = v end, "AutoFixCamEnabled", false, 1/3)
        makeHubTog(row4, "Noclip", function(v) toggleNoclip(v) end, "NoclipEnabled", false, 1/3)
        local row5 = makeRow(150)
        makeHubTog(row5, "Anti-Fling", function(v) toggleAntiFling(v) end, "AntiFlingEnabled", false, 1/3)
        makeHubTog(row5, "No Stun", function(v) toggleCharacterCleanupRuntime(v) end, "NoStunEnabled", false, 1/3)
    else
        local row2 = makeRow(60)
        makeHubTog(row2, "Safe Zone (N)", function(v) toggleAFK(v) end, "AFKEnabled", false, 1/3)
        makeHubTog(row2, "Safe Zone (HP)", function(v) toggleSafeZoneHP(v) end, "HPSafeZoneEnabled", false, 1/3)
        makeHubTog(row2, "HP Target", function(v) updateTargetDisplay() end, "TargetHPEnabled", false, 1/3)
        local row3 = makeRow(90)
        makeHubTog(row3, "No Stun", function(v) toggleCharacterCleanupRuntime(v) end, "NoStunEnabled", false, 1/2)
    end
    local espHub = makeControlFrame(isTSB and 124 or 94)
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
    local espRow1 = makeEspRow(30)
    makeHubTog(espRow1, "HP %", function(v) espOverlayConfig.showHp = v; refreshAllOverlays() end, "Overlay4HP", false, 1/4)
    makeHubTog(espRow1, "Name (CH)", function(v) espOverlayConfig.showCharacter = v; refreshAllOverlays() end, "Overlay4Character", false, 1/4)
    makeHubTog(espRow1, "ULT %", function(v) espOverlayConfig.showUltimate = v; refreshAllOverlays() end, "Overlay4Ultimate", false, 1/4)
    makeHubTog(espRow1, "Streak", function(v) espOverlayConfig.showStreak = v; refreshAllOverlays() end, "Overlay4Streak", false, 1/4)
    local espRow2 = makeEspRow(60)
    makeHubTog(espRow2, "ULT ESP", function(v) espOverlayConfig.showEsp = v; refreshAllOverlays() end, "Overlay4ESP", false, 1/2) 
    makeHubTog(espRow2, "Death Cntr ESP", function(v) toggleSeriousModeTracker(v); refreshAllOverlays() end, "DeathCounterESPEnabled", false, 1/2)
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
    task.spawn(function()
        while true do
            if lastValidPing ~= nil then
                local comm = player.Character and player.Character:FindFirstChild("Communicate")
                if comm then
                    pcall(function()
                        comm:FireServer({ Goal = "ReportPing", ms = lastValidPing })
                    end)
                end
            end
            task.wait(0.5)
        end
    end)
    if player.Character then
        setupCharacter(player.Character)
    end
    player.CharacterAdded:Connect(setupCharacter)
    if game.GameId == 3808081382 then
        local VIM = game:GetService("VirtualInputManager")
        local WhirlwindDunkID = "rbxassetid://12296113986"
        local WallComboIDs = {
            ["rbxassetid://17325537719"]=true,["rbxassetid://10469643643"]=true,
            ["rbxassetid://13294471966"]=true,["rbxassetid://13295936866"]=true,
            ["rbxassetid://13378708199"]=true,["rbxassetid://14136436157"]=true,
            ["rbxassetid://15162694192"]=true,["rbxassetid://16552234590"]=true,
            ["rbxassetid://17889290569"]=true,
        }
        local function SpamQ()
            VIM:SendKeyEvent(true, Enum.KeyCode.Q, false, game)
            VIM:SendKeyEvent(false, Enum.KeyCode.Q, false, game)
        end
        local function HandleWallComboTilt(track, combatChar)
            if not _G.WallComboEnabled or not track.Animation then return end
            if WallComboIDs[track.Animation.AnimationId] then
                local hrp = combatChar:FindFirstChild("HumanoidRootPart")
                if hrp then
                    local startCFrame = hrp.CFrame
                    local startTime = tick()
                    local conn
                    conn = RunService.Heartbeat:Connect(function()
                        if not _G.WallComboEnabled or tick() - startTime >= 0.3 then
                            if hrp and hrp.Parent then hrp.CFrame = startCFrame end
                            conn:Disconnect()
                        elseif hrp and hrp.Parent then
                            hrp.CFrame = startCFrame * CFrame.Angles(math.rad(-25), 0, 0)
                        end
                    end)
                end
            end
        end
        local function SetupCombatCharacter(combatChar)
            local combatHumanoid = combatChar:WaitForChild("Humanoid")
            local combatAnimator = combatHumanoid:WaitForChild("Animator")
            combatAnimator.AnimationPlayed:Connect(function(track)
                if _G.WhirlwindEnabled and track.Animation and track.Animation.AnimationId == WhirlwindDunkID then
                    task.wait(1.2)
                    local hrp = combatChar:FindFirstChild("HumanoidRootPart")
                    if hrp then hrp.CFrame = hrp.CFrame * CFrame.new(0, 100, 0) end
                end
                HandleWallComboTilt(track, combatChar)
            end)
            combatChar.DescendantAdded:Connect(function(desc)
                if desc:IsA("ObjectValue") and desc.Name:lower() == "wallcombo" and _G.WallComboEnabled then
                    local startTime = tick()
                    local duration = desc:GetAttribute("DeleteMe") or 0.6
                    repeat SpamQ(); task.wait(0.01)
                    until not desc.Parent or desc.Parent ~= combatChar or tick() - startTime >= duration
                end
            end)
        end
        if player.Character then task.spawn(SetupCombatCharacter, player.Character) end
        player.CharacterAdded:Connect(function(c) task.spawn(SetupCombatCharacter, c) end)
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
    RunService.Heartbeat:Connect(function()
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
	local RunService = game:GetService("RunService")
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
					for _ = 1, 5 do
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
		local isSelfFlinging = walkFlingEnabled or flingEnabled or clickFlingEnabled or auraFlingEnabled or flingAllEnabled
		local isHugeVel = not isNanVel and not isSelfFlinging and (math.abs(vel.X) > 1e6 or math.abs(vel.Y) > 1e6 or math.abs(vel.Z) > 1e6)
		local isExtremeFling = isNanPos or isNanVel or isHugeVel
		local isFar = (not isNanPos and (math.abs(pos.X) >= BOUNDARY_X or math.abs(pos.Z) >= BOUNDARY_Z)) or isNanPos
		local isVoid = not isNanPos and pos.Y <= BOUNDARY_Y_DOWN
		if ((isFar and not _G.SafeTeleportLock and not (attackTpEnabled and attackTpHolding)) or isVoid or isNanVel or isHugeVel) and alive then
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
			local isSelfFlinging = walkFlingEnabled or flingEnabled or clickFlingEnabled or auraFlingEnabled or flingAllEnabled
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
	RunService.Stepped:Connect(updateMonitoring)
	RunService.Heartbeat:Connect(updateMonitoring)
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
		local filtered = text:gsub("[^-0-9%.]", "")
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
		if rawText == "" or not string.match(rawText, "^%d*%.?%d+$") then
			editBox.Text = string.format("%.1f", roundToTenth(state.value))
			return
		end
		local typedValue = tonumber(rawText)
		applySliderValue(state, typedValue, true)
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
local function updateDynamicDropdownDisplays()
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
	local segmentCount = toggle4Name and 5 or 4
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
	local buttonControl = createSegment(buttonName, false, false, buttonCallback)
	return {
		Frame = holder,
		First = firstControl,
		Second = secondControl,
		Third = thirdControl,
		Fourth = fourthControl,
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
	actionButton.AutoButtonColor = true
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
						task.delay(5, function()
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
							task.delay(5, function()
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
	local TweenService = game:GetService("TweenService")
	local fadeInfo = TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
	local function showStatus(text, duration)
		statusLabel.Text = text
		TweenService:Create(statusLabel, fadeInfo, { TextTransparency = 0 }):Play()
		if duration then
			task.delay(duration, function()
				if statusLabel.Text == text then
					TweenService:Create(statusLabel, fadeInfo, { TextTransparency = 1 }):Play()
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
	buttonName = "TP",
	default1 = viewing,
	default2 = autoTpEnabled,
	default3 = flingEnabled,
	default4Tog = dVoidDeadActive,
	fun1 = function(enabled)
		if enabled and not (manualAttackTpPlayer or manualAttackTpTarget) then
			targetActionControls.First.SetValue(false, true)
			return
		end
		toggleView(enabled)
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
		if enabled and not manualAttackTpPlayer then
			targetActionControls.Fourth.SetValue(false, true)
			return
		end
		toggleDVoidDead(enabled)
	end,
	buttonfun = function()
		if not (manualAttackTpPlayer or manualAttackTpTarget) then
			return
		end
		teleportToSelectedTarget("Front")
	end,
})
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
	max = 500,
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
if game.GameId == 3808081382 then
	placesDropdown = Dropdown({
		namedropdown = "Places",
		inside = placesOrder,
		multi = false,
		deffultin = selectedPlace,
		fun = function(value)
			selectedPlace = value
			setSavedControlValue("SelectedPlace", value)
			syncPlacesKeybindDisplay()
		end,
	})
	placesDropdown.Frame.LayoutOrder = 999998
end
syncVoidDeadKeybindDisplay()
syncPlacesKeybindDisplay()
local customOffsetFrame = makeControlFrame(75)
customOffsetFrame.Visible = false
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
			local off = customOffsets[cleanMode] or { x = 0, y = 0, z = 0 }
			zInput.Text = tostring(off.z)
			yInput.Text = tostring(off.y)
			xInput.Text = tostring(off.x)
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
		labelObj.Position = UDim2.fromScale(position, 0.2)
		labelObj.Size = UDim2.fromScale(0.1, 0.3)
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
		box.Position = UDim2.fromScale(position, 0.5)
		box.Size = UDim2.fromScale(0.25, 0.4)
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
				box.Text = tostring(customOffsets[cleanMode][axis])
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
	zInput = createOffsetInput("Z", "z", 0.05)
	yInput = createOffsetInput("Y", "y", 0.375)
	xInput = createOffsetInput("X", "x", 0.7)
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
		local saved = getSavedControlValue(charSaveKey)
		if saved and saved ~= "" then return saved end
		return characterList[1]
	end
	local charCallbackReady = false
	local characterDropdown
	characterDropdown = Dropdown({
		namedropdown = "Character",
		inside = characterList,
		multi = false,
		deffultin = getCharacterFromAttr(),
		saveKey = charSaveKey,
		fun = function(value)
			if not charCallbackReady then return end
			if not value or value == "" then return end
			local char = player.Character
			local currentAttr = char and char:GetAttribute("Character")
			if currentAttr and tostring(currentAttr) == value then return end
			task.spawn(function()
				local retryToken = (characterDropdown and characterDropdown._retryToken or 0) + 1
				if characterDropdown then characterDropdown._retryToken = retryToken end
				while true do
					pcall(function()
						local communicate = player.Character and player.Character:WaitForChild("Communicate", 3)
						if communicate then
							communicate:FireServer({ Goal = "Change Character", Character = value })
						end
					end)
					task.wait(0.88)
					if characterDropdown and characterDropdown._retryToken ~= retryToken then break end
					local char = player.Character
					local attr = char and char:GetAttribute("Character")
					if attr and tostring(attr) == value then break end
				end
			end)
		end,
	})
	characterDropdown.Frame.LayoutOrder = 999999
	local function syncCharDropdown()
		if not characterDropdown then return end
		local char = player.Character
		if not char then return end
		local attr = char:GetAttribute("Character")
		if attr and tostring(attr) ~= "" then
			characterDropdown.SetValue(tostring(attr), true) 
			setSavedControlValue(charSaveKey, tostring(attr))
		end
	end
	player.CharacterAdded:Connect(function(_newChar)
		task.wait(1.5)
		pcall(syncCharDropdown)
	end)
	task.defer(function()
		pcall(syncCharDropdown)
		charCallbackReady = true
	end)
end
do
	local keybindHub = makeControlFrame(200)
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
	local rowHideNames = makeRow(30)
	makeHubTog(rowHideNames, "Hide Names", function(v) hideNamesEnabled = v; updateKeybindText() end, "KeybindHideNamesEnabled", false, 1.0)
	local row1 = makeRow(60)
	makeHubTogKB(row1, "Speed KB", function(v) keybindToggles.Speed = v; updateKeybindText() end, "KeybindSpeedEnabled", "off", 1/2)
	makeHubTogKB(row1, "Fly KB", function(v) keybindToggles.Fly = v; updateKeybindText() end, "KeybindFlyEnabled", "off", 1/2)
	local row2 = makeRow(90)
	makeHubTogKB(row2, "CamLock KB", function(v) keybindToggles.CamLock = v; updateKeybindText() end, "KeybindCamLockEnabled", "off", 1/3)
	makeHubTogKB(row2, "Attack TP KB", function(v) keybindToggles.AttackTP = v; updateKeybindText() end, "KeybindAttackTPEnabled", "off", 1/3)
	makeHubTogKB(row2, "Target KB", function(v) keybindToggles.Target = v; updateKeybindText() end, "KeybindTargetEnabled", "off", 1/3)
	local row3 = makeRow(120)
	makeHubTogKB(row3, "WalkFling KB", function(v) keybindToggles.WalkFling = v; updateKeybindText() end, "KeybindWalkFlingEnabled", "off", 1/3)
	makeHubTogKB(row3, "SetBack KB", function(v) keybindToggles.SetBack = v; updateKeybindText() end, "KeybindSetBackEnabled", "off", 1/3)
	makeHubTogKB(row3, "Trash KB", function(v) keybindToggles.Trash = v; updateKeybindText() end, "KeybindTrashEnabled", "off", 1/3)
	local row4 = makeRow(150)
	makeHubTogKB(row4, "Void KB", function(v) keybindToggles.Void = v; updateKeybindText() end, "KeybindVoidEnabled", "off", 1/2)
	makeHubTogKB(row4, "Places TP KB", function(v) keybindToggles.Places = v; updateKeybindText() end, "KeybindPlacesEnabled", "off", 1/2)
	-- Sync keybind display with restored toggle states (fixes auto-load hide/off/block)
	task.defer(updateKeybindText)
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
		line.TextTruncate = Enum.TextTruncate.AtEnd
		line.TextXAlignment = Enum.TextXAlignment.Left
		line.TextYAlignment = Enum.TextYAlignment.Center
		line.Visible = false
		line.Parent = parent
		return line
	end
	local function ensureOverlayBillboard(model)
		local head = model and model:FindFirstChild("Head")
		if not head then
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
		billboard.Adornee = head
		billboard.AlwaysOnTop = true
		billboard.ExtentsOffsetWorldSpace = Vector3.new(0, 5.2, 0)
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
		return billboard
	end
	local function getSharedHighlightColors(model, ultedAttr, canUseUltedHighlight)
		local seriousModeState = model and model:GetAttribute("NX_SeriousModeState") or nil
		if seriousModeState == "strong" then
			return {
				fill = Color3.fromRGB(0, 0, 0),
				outline = Color3.fromRGB(255, 255, 255),
				enabled = true,
			}
		end
		if seriousModeState == "weak" then
			return {
				fill = Color3.fromRGB(0, 0, 0),
				outline = Color3.fromRGB(255, 0, 0),
				enabled = true,
			}
		end
		if canUseUltedHighlight and ultedAttr == true then
			return {
				fill = Color3.fromRGB(0, 0, 0),
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
		local textSize = TextService:GetTextSize(tostring(text or ""), 14, Enum.Font.GothamBold, Vector2.new(1000, BILLBOARD_LINE_HEIGHT))
		return math.max(textSize.X + 2, 1)
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
		local showBillboard = espOverlayConfig.showHp or espOverlayConfig.showCharacter or espOverlayConfig.showUltimate or espOverlayConfig.showStreak
		local billboard = model:FindFirstChild(ESP_BILLBOARD_NAME)
		if not showBillboard then
			if billboard then
				billboard:Destroy()
			end
		else
			billboard = ensureOverlayBillboard(model)
			if billboard then
				billboard.Enabled = true
				billboard.Adornee = head
				local frame = billboard:FindFirstChild("Root")
				local hpLine = frame and frame:FindFirstChild("HpLine")
				local sepOne = frame and frame:FindFirstChild("SepOne")
				local characterLine = frame and frame:FindFirstChild("CharacterLine")
				local sepTwo = frame and frame:FindFirstChild("SepTwo")
				local ultimateLine = frame and frame:FindFirstChild("UltimateLine")
				local sepThree = frame and frame:FindFirstChild("SepThree")
				local streakLine = frame and frame:FindFirstChild("StreakLine")
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
				local hideUltimateForBaldUlted = ultedAttr
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
				local showSepOne = hpVisible and characterVisible
				local showSepTwo = (hpVisible or characterVisible) and ultimateVisible
				local showSepThree = (hpVisible or characterVisible or ultimateVisible) and streakVisible
				updateLine(sepOne, showSepOne, "//", Color3.fromRGB(255, 255, 255))
				updateLine(sepTwo, showSepTwo, "//", Color3.fromRGB(255, 255, 255))
				updateLine(sepThree, showSepThree, "//", Color3.fromRGB(255, 255, 255))
				for _, guiObject in ipairs({ hpLine, sepOne, characterLine, sepTwo, ultimateLine, sepThree, streakLine }) do
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
			highlight.FillTransparency = 0.6
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

			-- Wait for humanoid and listen to changes
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

			-- Attribute changes on Character
			local attrConn = char.AttributeChanged:Connect(function(attr)
				if attr == "Character" or attr == "Ulted" or attr == "Ultimate" or attr == "CurrentStreak" or attr == "NX_SeriousModeState" then
					pcall(updatePlayerOverlay, targetPlayer)
				end
			end)
			table.insert(conns, attrConn)

			-- Check for humanoid recreation/child addition
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

		-- Attribute changes on Player object
		local playerAttrConn = targetPlayer.AttributeChanged:Connect(function(attr)
			if attr == "Ultimate" or attr == "Ulted" then
				pcall(updatePlayerOverlay, targetPlayer)
			end
		end)
		table.insert(conns, playerAttrConn)
	end

	-- Expose refresh function to other scopes
	refreshAllOverlays = function()
		for _, targetPlayer in ipairs(Players:GetPlayers()) do
			if targetPlayer ~= player then
				pcall(updatePlayerOverlay, targetPlayer)
			end
		end
	end

	-- Initialize overlays for existing players
	for _, targetPlayer in ipairs(Players:GetPlayers()) do
		setupPlayerOverlay(targetPlayer)
	end

	-- Listen for new and departing players
	local playerAddedOverlayConn = Players.PlayerAdded:Connect(setupPlayerOverlay)
	local playerRemovingOverlayConn = Players.PlayerRemoving:Connect(cleanupPlayerOverlay)

	-- Slow backup loop to handle Roblox character quirks and highlight desyncs
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
			task.wait(0)
		end
	end)

	-- Cleanup when UI is destroyed
	task.spawn(function()
		while screenGui.Parent do
			task.wait(1.5)
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
		task.delay(0.1, function()
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
		task.wait(10)
		updateDropdownsEvent()
	end
end)
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
		settingsWindow.Position = UDim2.new(
			dragStartPosition.X.Scale, clampedUX * scale,
			dragStartPosition.Y.Scale, clampedUY * scale
		)
	end
end)
UserInputService.InputBegan:Connect(function(input, gameProcessed)
	if not introFinished then
		return
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
		local isMapLocation = selectedPlace == "Middle Of Map" or selectedPlace == "Montain 1 Left" or selectedPlace == "Montain 1 Right" or selectedPlace:find("^Montain %d View") or selectedPlace == "Montain 2" or selectedPlace == "Montain 2 Left" or selectedPlace == "Montain 2 Right"
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
				local startCF = characterRoot.CFrame
				local dist = (cf.Position - startCF.Position).Magnitude
				if dist < 250 then
					applyTeleportRootState(characterRoot, cf, Vector3.zero, Vector3.zero)
				else
					applyTeleportRootState(characterRoot, startCF:Lerp(cf, 0.25), Vector3.zero, Vector3.zero)
					task.wait(0.05)
					applyTeleportRootState(characterRoot, startCF:Lerp(cf, 0.50), Vector3.zero, Vector3.zero)
					task.wait(0.05)
					applyTeleportRootState(characterRoot, startCF:Lerp(cf, 0.75), Vector3.zero, Vector3.zero)
					task.wait(0.05)
					applyTeleportRootState(characterRoot, cf, Vector3.zero, Vector3.zero)
				end
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
	if key == camLockKeybind and keybindToggles.CamLock ~= "block" then
		toggleCamLock()
		return
	end
	if key == attackTpKeybind and keybindToggles.AttackTP ~= "block" then
		toggleAttackTp()
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
	if key == Enum.KeyCode.W then
		holdingW = true
	elseif key == Enum.KeyCode.S then
		holdingS = true
	elseif key == Enum.KeyCode.A then
		holdingA = true
	elseif key == Enum.KeyCode.D then
		holdingD = true
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
	velocity = Vector3.new()
	currentVel = Vector3.new()
	if voidDeadActive then
		toggleVoidDead()
	end
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
		hum = newChar:WaitForChild("Humanoid")
	end
	if not root then
		root = newChar:WaitForChild("HumanoidRootPart")
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
	updateTargetDisplay()
	if lastDeathCFrame then
		task.delay(0.35, function()
			local r = newChar:FindFirstChild("HumanoidRootPart")
			if r and lastDeathCFrame then
				r.CFrame = lastDeathCFrame
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
				velocity = velocity:Lerp(Vector3.new(), dt * 18)
				currentVel = currentVel:Lerp(Vector3.new(), dt * 20)
				bv.Position = root.Position
				bg.CFrame = getRotationOnlyCFrame(root.CFrame)
			else
				cam = Workspace.CurrentCamera or cam
			end
			if not attackTpControlling and cam then
				local z, x = getMovementInput()
				local inputDir = (cam.CFrame.LookVector * z) + (cam.CFrame.RightVector * x)
				local targetVel = inputDir.Magnitude > 0.01 and inputDir.Unit * getAppliedFlySpeed() or Vector3.new()
				velocity = velocity:Lerp(targetVel, dt * 16)
				currentVel = currentVel:Lerp(velocity, dt * 22)
				bv.Position = root.Position + currentVel * dt * 65
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
	if camLockEnabled then
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
					cam.CFrame = CFrame.lookAt(cameraPosition, targetRoot.Position, targetRoot.CFrame.UpVector)
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
			if targetCFrame then
				local amFlinging = allowFling and (walkFlingEnabled or flingEnabled or clickFlingEnabled or auraFlingEnabled)
				local resolvedLinear = targetVelocity or Vector3.zero
				local resolvedAngular = Vector3.zero
				if amFlinging then
					local power = (walkFlingEnabled and walkFlingPower) or (flingEnabled and flingPower) or (clickFlingEnabled and flingPower) or (auraFlingEnabled and flingPower) or 20000
					resolvedAngular = Vector3.new(power * 2, power * 2, power * 2)
					resolvedLinear = resolvedLinear + (characterRoot.CFrame.LookVector * power * 0.5)
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
	task.spawn(function()
		local steppedConn
		steppedConn = RunService.Stepped:Connect(function()
			if not targetActionHeartbeat or not targetActionHeartbeat.Connected then
				steppedConn:Disconnect()
				return
			end
			local function fastPerform(target, allowFling)
				if isSafeZoneActive() then return end
				local character = player.Character
				local characterRoot = character and character:FindFirstChild("HumanoidRootPart")
				if characterRoot and not isTpBlocked(target) then
					local targetCFrame, targetVelocity = getAttackTpPlacement(characterRoot, target)
					if targetCFrame then
						local amFlinging = allowFling and (walkFlingEnabled or flingEnabled or clickFlingEnabled or auraFlingEnabled)
						local resolvedLinear = targetVelocity or Vector3.zero
						local resolvedAngular = Vector3.zero
						if amFlinging then
							local power = (walkFlingEnabled and walkFlingPower) or (flingEnabled and flingPower) or (clickFlingEnabled and flingPower) or (auraFlingEnabled and flingPower) or 20000
							resolvedAngular = Vector3.new(power * 2.1, power * 2.1, power * 2.1)
						end
						applyTeleportRootState(characterRoot, targetCFrame, resolvedLinear, resolvedAngular)
					end
				end
			end
			if autoTpEnabled then
				local targetModel = resolveAttackTpTarget()
				if isValidAttackTpTarget(targetModel) then
					fastPerform(targetModel, true)
				end
			end
			if attackTpEnabled and attackTpHolding then
				local attackTarget = resolveAttackTpTarget()
				if isValidAttackTpTarget(attackTarget) then
					fastPerform(attackTarget, false)
				end
			end
		end)
	end)
end
UserInputService.InputEnded:Connect(function(input)
	local key = input.KeyCode
	if input.UserInputType == Enum.UserInputType.MouseButton1 then
		attackTpHolding = false
		return
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
task.spawn(function()
if game.GameId ~= 3808081382 then
    return
end
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
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
	task.wait(0.1)
	if v.Name == "Hotbar" then
		RegisterHotbar(v)
	end
	RegisterGui()
	UpdateBar()
end)
LocalPlayer:GetAttributeChangedSignal("Ultimate"):Connect(UpdateBar)
task.spawn(function()
	while true do
		task.wait(0.01)
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
		task.wait(1)
		syncPlacesKeybindDisplay()
	end
end)
end)
