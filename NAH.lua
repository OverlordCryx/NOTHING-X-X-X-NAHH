local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local GuiService = game:GetService("GuiService")
local RunService = game:GetService("RunService")
local HttpService = game:GetService("HttpService")
local Workspace = game:GetService("Workspace")
local CoreGui = game:GetService("CoreGui")

local player = Players.LocalPlayer
if not player then
	return
end

local function showExistingGuiInfo(gui, title, text, duration)
	local infoContainer = gui:FindFirstChild("InfoContainer")
	local infoTitle = infoContainer and infoContainer:FindFirstChild("InfoTitle")
	local infoText = infoContainer and infoContainer:FindFirstChild("InfoText")
	local infoStroke = infoContainer and infoContainer:FindFirstChildOfClass("UIStroke")

	if not infoContainer or not infoTitle or not infoText then
		return false
	end

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
		TextStrokeTransparency = 0,
	}):Play()

	TweenService:Create(infoText, TweenInfo.new(0.25, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
		TextTransparency = 0,
		TextStrokeTransparency = 0.2,
	}):Play()

	task.delay(tonumber(duration) or 3, function()
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
			if infoContainer.Parent then
				infoContainer.Visible = false
			end
		end)
	end)

	return true
end

local existingGui = CoreGui:FindFirstChild("NOTHING_X-000")
if existingGui then
	showExistingGuiInfo(existingGui, "NOTHING X", "NOTHING_X Already Running...", 3)
	return
end

local screenGui = Instance.new("ScreenGui")
screenGui.Name = "NOTHING_X-000"
screenGui.ResetOnSpawn = false
screenGui.IgnoreGuiInset = true
screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
screenGui.DisplayOrder = 9999999
screenGui.Parent = CoreGui

local background = Instance.new("Frame")
background.Name = "Background"
background.Size = UDim2.fromScale(1, 1)
background.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
background.BorderSizePixel = 0
background.Parent = screenGui

local keybindFrame = Instance.new("Frame")
keybindFrame.Name = "KeybindFrame"
keybindFrame.AnchorPoint = Vector2.new(0, 0.5)
keybindFrame.Position = UDim2.fromScale(0.03, 0.5)
keybindFrame.Size = UDim2.fromScale(0.09, 0.24)
keybindFrame.BackgroundColor3 = Color3.fromRGB(20, 0, 0)
keybindFrame.BackgroundTransparency = 1
keybindFrame.BorderSizePixel = 0
keybindFrame.Visible = false
keybindFrame.Parent = screenGui
local leftCorner = Instance.new("UICorner")
leftCorner.CornerRadius = UDim.new(0, 18)
leftCorner.Parent = keybindFrame

local leftStroke = Instance.new("UIStroke")
leftStroke.Color = Color3.fromRGB(255, 0, 0)
leftStroke.Thickness = 3
leftStroke.Transparency = 1
leftStroke.Parent = keybindFrame

local leftGradient = Instance.new("UIGradient")
leftGradient.Color = ColorSequence.new({
	ColorSequenceKeypoint.new(0, Color3.fromRGB(0, 0, 0)),
	ColorSequenceKeypoint.new(0.35, Color3.fromRGB(70, 0, 0)),
	ColorSequenceKeypoint.new(1, Color3.fromRGB(255, 0, 0)),
})
leftGradient.Rotation = 90
leftGradient.Parent = keybindFrame

local keybindText = Instance.new("TextLabel")
keybindText.Name = "KeybindText"
keybindText.AnchorPoint = Vector2.new(0.5, 0)
keybindText.Position = UDim2.fromScale(0.5, 0.08)
keybindText.Size = UDim2.fromScale(0.92, 0.72)
keybindText.BackgroundTransparency = 1
keybindText.TextColor3 = Color3.fromRGB(255, 110, 110)
keybindText.TextStrokeTransparency = 0.2
keybindText.TextStrokeColor3 = Color3.fromRGB(100, 0, 0)
keybindText.Font = Enum.Font.GothamBold
keybindText.TextScaled = true
keybindText.TextWrapped = true
keybindText.TextYAlignment = Enum.TextYAlignment.Top
keybindText.TextXAlignment = Enum.TextXAlignment.Center
keybindText.Parent = keybindFrame

local keybindTextConstraint = Instance.new("UITextSizeConstraint")
keybindTextConstraint.MinTextSize = 12
keybindTextConstraint.MaxTextSize = 24
keybindTextConstraint.Parent = keybindText

local targetFrame = Instance.new("Frame")
targetFrame.Name = "TargetFrame"
targetFrame.AnchorPoint = Vector2.new(0.5, 0)
targetFrame.Position = UDim2.fromScale(0.5, 0.025)
targetFrame.Size = UDim2.fromScale(0.1, 0.02)
targetFrame.BackgroundColor3 = Color3.fromRGB(20, 0, 0)
targetFrame.BackgroundTransparency = 0.5
targetFrame.BorderSizePixel = 0
targetFrame.Visible = false
targetFrame.Parent = screenGui

local targetCorner = Instance.new("UICorner")
targetCorner.CornerRadius = UDim.new(0, 18)
targetCorner.Parent = targetFrame

local targetStroke = Instance.new("UIStroke")
targetStroke.Color = Color3.fromRGB(255, 0, 0)
targetStroke.Thickness = 3
targetStroke.Transparency = 0.1
targetStroke.Parent = targetFrame

local targetGradient = Instance.new("UIGradient")
targetGradient.Color = ColorSequence.new({
	ColorSequenceKeypoint.new(0, Color3.fromRGB(0, 0, 0)),
	ColorSequenceKeypoint.new(0.35, Color3.fromRGB(70, 0, 0)),
	ColorSequenceKeypoint.new(1, Color3.fromRGB(255, 0, 0)),
})
targetGradient.Rotation = 90
targetGradient.Parent = targetFrame



local targetValueText = Instance.new("TextLabel")
targetValueText.Name = "TargetValue"
targetValueText.AnchorPoint = Vector2.new(0.5, 0.5)
targetValueText.Position = UDim2.fromScale(0.5, 0.5)
targetValueText.Size = UDim2.fromScale(0.88, 0.68)
targetValueText.BackgroundTransparency = 1
targetValueText.Text = ""
targetValueText.TextColor3 = Color3.fromRGB(255, 110, 110)
targetValueText.TextStrokeTransparency = 0.2
targetValueText.TextStrokeColor3 = Color3.fromRGB(100, 0, 0)
targetValueText.Font = Enum.Font.GothamBold
targetValueText.TextScaled = true
targetValueText.TextWrapped = true
targetValueText.TextXAlignment = Enum.TextXAlignment.Center
targetValueText.TextYAlignment = Enum.TextYAlignment.Center
targetValueText.Parent = targetFrame

local targetValueConstraint = Instance.new("UITextSizeConstraint")
targetValueConstraint.MinTextSize = 12
targetValueConstraint.MaxTextSize = 20
targetValueConstraint.Parent = targetValueText

local infoContainer = Instance.new("Frame")
infoContainer.Name = "InfoContainer"
infoContainer.AnchorPoint = Vector2.new(0.5, 0)
infoContainer.Position = UDim2.fromScale(0.5, 0.12)
infoContainer.Size = UDim2.fromScale(0.24, 0.12)
infoContainer.BackgroundColor3 = Color3.fromRGB(20, 0, 0)
infoContainer.BackgroundTransparency = 1
infoContainer.BorderSizePixel = 0
infoContainer.Visible = false
infoContainer.Parent = screenGui

local infoCorner = Instance.new("UICorner")
infoCorner.CornerRadius = UDim.new(0, 18)
infoCorner.Parent = infoContainer

local infoStroke = Instance.new("UIStroke")
infoStroke.Color = Color3.fromRGB(255, 0, 0)
infoStroke.Thickness = 3
infoStroke.Transparency = 1
infoStroke.Parent = infoContainer

local infoGradient = Instance.new("UIGradient")
infoGradient.Color = ColorSequence.new({
	ColorSequenceKeypoint.new(0, Color3.fromRGB(0, 0, 0)),
	ColorSequenceKeypoint.new(0.35, Color3.fromRGB(70, 0, 0)),
	ColorSequenceKeypoint.new(1, Color3.fromRGB(255, 0, 0)),
})
infoGradient.Rotation = 90
infoGradient.Parent = infoContainer

local infoTitle = Instance.new("TextLabel")
infoTitle.Name = "InfoTitle"
infoTitle.AnchorPoint = Vector2.new(0.5, 0)
infoTitle.Position = UDim2.fromScale(0.5, 0.08)
infoTitle.Size = UDim2.fromScale(0.88, 0.28)
infoTitle.BackgroundTransparency = 1
infoTitle.Text = ""
infoTitle.TextColor3 = Color3.fromRGB(255, 30, 30)
infoTitle.TextStrokeTransparency = 0
infoTitle.TextStrokeColor3 = Color3.fromRGB(120, 0, 0)
infoTitle.Font = Enum.Font.GothamBlack
infoTitle.TextScaled = true
infoTitle.TextWrapped = true
infoTitle.Parent = infoContainer

local infoTitleConstraint = Instance.new("UITextSizeConstraint")
infoTitleConstraint.MinTextSize = 14
infoTitleConstraint.MaxTextSize = 28
infoTitleConstraint.Parent = infoTitle

local infoText = Instance.new("TextLabel")
infoText.Name = "InfoText"
infoText.AnchorPoint = Vector2.new(0.5, 1)
infoText.Position = UDim2.fromScale(0.5, 0.9)
infoText.Size = UDim2.fromScale(0.88, 0.44)
infoText.BackgroundTransparency = 1
infoText.Text = ""
infoText.TextColor3 = Color3.fromRGB(255, 110, 110)
infoText.TextStrokeTransparency = 0.2
infoText.TextStrokeColor3 = Color3.fromRGB(100, 0, 0)
infoText.Font = Enum.Font.GothamBold
infoText.TextScaled = true
infoText.TextWrapped = true
infoText.Parent = infoContainer

local infoTextConstraint = Instance.new("UITextSizeConstraint")
infoTextConstraint.MinTextSize = 12
infoTextConstraint.MaxTextSize = 22
infoTextConstraint.Parent = infoText

local settingsWindow = Instance.new("Frame")
settingsWindow.Name = "WindowUI"
settingsWindow.AnchorPoint = Vector2.new(0.5, 0.5)
settingsWindow.Position = UDim2.fromScale(0.5, 0.57)
settingsWindow.Size = UDim2.fromScale(0.22, 0.42)
settingsWindow.BackgroundColor3 = Color3.fromRGB(12, 0, 0)
settingsWindow.BackgroundTransparency = 1
settingsWindow.BorderSizePixel = 0
settingsWindow.Visible = false
settingsWindow.Active = true
settingsWindow.ZIndex = 10
settingsWindow.Parent = screenGui

local windowOutline = Instance.new("Frame")
windowOutline.Name = "WindowOutline"
windowOutline.AnchorPoint = settingsWindow.AnchorPoint
windowOutline.Position = settingsWindow.Position
windowOutline.Size = settingsWindow.Size
windowOutline.BackgroundTransparency = 1
windowOutline.BorderSizePixel = 0
windowOutline.Visible = false
windowOutline.Active = false
windowOutline.ZIndex = 9
windowOutline.Parent = screenGui

local windowOutlineCorner = Instance.new("UICorner")
windowOutlineCorner.CornerRadius = UDim.new(0, 18)
windowOutlineCorner.Parent = windowOutline

local windowOutlineStroke = Instance.new("UIStroke")
windowOutlineStroke.Color = Color3.fromRGB(255, 0, 0)
windowOutlineStroke.Thickness = 3
windowOutlineStroke.Transparency = 1
windowOutlineStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
windowOutlineStroke.Parent = windowOutline

local inputBlocker = Instance.new("TextButton")
inputBlocker.Name = "InputBlocker"
inputBlocker.Size = UDim2.fromScale(1, 1)
inputBlocker.BackgroundTransparency = 1
inputBlocker.BorderSizePixel = 0
inputBlocker.Text = ""
inputBlocker.AutoButtonColor = false
inputBlocker.Visible = true
inputBlocker.ZIndex = 10
inputBlocker.Parent = settingsWindow

local settingsCorner = Instance.new("UICorner")
settingsCorner.CornerRadius = UDim.new(0, 18)
settingsCorner.Parent = settingsWindow

local settingsStroke = Instance.new("UIStroke")
settingsStroke.Color = Color3.fromRGB(255, 0, 0)
settingsStroke.Thickness = 3
settingsStroke.Transparency = 1
settingsStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
settingsStroke.Parent = settingsWindow

local settingsGradient = Instance.new("UIGradient")
settingsGradient.Color = ColorSequence.new({
	ColorSequenceKeypoint.new(0, Color3.fromRGB(0, 0, 0)),
	ColorSequenceKeypoint.new(0.45, Color3.fromRGB(55, 0, 0)),
	ColorSequenceKeypoint.new(1, Color3.fromRGB(155, 0, 0)),
})
settingsGradient.Rotation = 90
settingsGradient.Parent = settingsWindow

local headerDragArea = Instance.new("Frame")
headerDragArea.Name = "HeaderDragArea"
headerDragArea.Size = UDim2.fromScale(1, 0.18)
headerDragArea.BackgroundTransparency = 1
headerDragArea.Active = true
headerDragArea.ZIndex = 11
headerDragArea.Parent = settingsWindow

local uiTitle = Instance.new("TextLabel")
uiTitle.Name = "UI-Title"
uiTitle.AnchorPoint = Vector2.new(0, 0)
uiTitle.Position = UDim2.fromScale(0.05, 0.06)
uiTitle.Size = UDim2.fromScale(0.52, 0.1)
uiTitle.BackgroundTransparency = 1
uiTitle.Text = "NOTHING X"
uiTitle.TextColor3 = Color3.fromRGB(255, 35, 35)
uiTitle.TextStrokeTransparency = 0
uiTitle.TextStrokeColor3 = Color3.fromRGB(120, 0, 0)
uiTitle.Font = Enum.Font.GothamBlack
uiTitle.TextScaled = true
uiTitle.TextXAlignment = Enum.TextXAlignment.Left
uiTitle.ZIndex = 11
uiTitle.Parent = settingsWindow

local uiTitleConstraint = Instance.new("UITextSizeConstraint")
uiTitleConstraint.MinTextSize = 14
uiTitleConstraint.MaxTextSize = 28
uiTitleConstraint.Parent = uiTitle

local divider = Instance.new("Frame")
divider.Name = "Divider"
divider.AnchorPoint = Vector2.new(0.5, 0)
divider.Position = UDim2.fromScale(0.5, 0.18)
divider.Size = UDim2.fromScale(0.9, 0.006)
divider.BackgroundColor3 = Color3.fromRGB(255, 0, 0)
divider.BackgroundTransparency = 0.15
divider.BorderSizePixel = 0
divider.ZIndex = 11
divider.Parent = settingsWindow

local uiX = Instance.new("ScrollingFrame")
uiX.Name = "UI-x"
uiX.AnchorPoint = Vector2.new(0.5, 1)
uiX.Position = UDim2.fromScale(0.5, 0.95)
uiX.Size = UDim2.fromScale(0.92, 0.72)
uiX.BackgroundTransparency = 1
uiX.BorderSizePixel = 0
uiX.CanvasSize = UDim2.fromOffset(0, 0)
uiX.AutomaticCanvasSize = Enum.AutomaticSize.Y
uiX.ElasticBehavior = Enum.ElasticBehavior.Never
uiX.ScrollBarThickness = 0
uiX.ScrollBarImageColor3 = Color3.fromRGB(255, 0, 0)
uiX.Active = true
uiX.ZIndex = 11
uiX.Parent = settingsWindow

local settingsLayout = Instance.new("UIListLayout")
settingsLayout.Padding = UDim.new(0, 10)
settingsLayout.SortOrder = Enum.SortOrder.LayoutOrder
settingsLayout.Parent = uiX

local keybindEntries = {}
local introFinished = false
local pendingInfoCall = nil
local settingsOpen = false
local draggingWindow = false
local dragStartPosition = nil
local dragStartInputPosition = nil
local openDropdowns = {}
local sliderStates = {}
local controlSaveData = {}
local sliderSaveFile = "NOTHING_X_0.file"
local Speed = 1.5
local speedKeybind = Enum.KeyCode.E
local flyKeybind = Enum.KeyCode.R
local camLockKeybind = Enum.KeyCode.Z
local attackTpKeybind = Enum.KeyCode.T
local targetSelectKeybind = Enum.KeyCode.C
setBackKeybind = Enum.KeyCode.N
setBackSavedCFrame = nil
setBackTravelConn = nil
setBackPressToken = 0
setBackLastPressAt = 0
setBackCollisionState = nil
local active = false
local speedLoopRunning = false
local holdingW = false
local holdingS = false
local holdingA = false
local holdingD = false
local cam = Workspace.CurrentCamera
local char = player.Character or player.CharacterAdded:Wait()
local hum = char:WaitForChild("Humanoid")
local root = char:WaitForChild("HumanoidRootPart")
local flying = false
local bv = nil
local bg = nil
local flySpeed = 1.5
local flySpeedMultiplier = 555
local velocity = Vector3.new()
local currentVel = Vector3.new()
local safeZone = {
	enabled = false,
	pointStart = 3e3,
	pointAdd = 3e3,
	pointMax = 33e33,
	pointCurrent = 3e3,
	lowHp = 30,
	returnHp = 47,
	savedCFrame = nil,
	travelConn = nil,
	travelMode = nil,
	atDestination = false,
	toggleControl = nil,
}
local normalizeSafeZoneSigned
local normalizeSafeZonePositive
local camLockEnabled = false
local camLockTarget = nil
local camLockWaiting = false
local camLockAcquireRadius = 160
local attackTpEnabled = false
local attackTpTarget = nil
local manualAttackTpTarget = nil
local manualAttackTpPlayer = nil
local attackTpHolding = false
local isSelectablePlayerDropdownTarget
local syncModelDropdownSelectionToManualTarget
local stopView
local startView
local toggleView
local attackTpBehindDistance = 1.85
local attackTpAirBehindDistance = 1.15
local attackTpLeadTime = 0.03
local attackTpAirLeadTime = 0.06
local attackTpMaxHorizontalLead = 4.5
local attackTpVerticalLead = 0.04
local attackTpMaxVerticalLead = 1.35
local attackTpGroundVerticalOffset = 0
local attackTpAirVerticalOffset = 0.45
local worldUpVector = Vector3.new(0, 1, 0)
local autoTpEnabled = false
local flingEnabled = false
walkFlingEnabled = false
auraFlingEnabled = false
clickFlingEnabled = false
flingAllEnabled = false
walkFlingKeybind = Enum.KeyCode.X
walkFlingPower = 1000
flingPower = 1000
auraRange = 20
walkFlingUseNormal = false
walkFlingDirections = {
	Forward = true,
}
walkFlingTaskToken = 0
auraFlingTaskToken = 0
clickFlingConnection = nil
clickFlingBusy = false
flingAllTaskToken = 0
flingOrbitTime = 0
flingOrbitStepXZ = 0
flingOrbitStepY = 0
flingTargetIndex = 1
flingOrbitSpeed = 2e9
flingOrbitIncrement = 0.1
flingOrbitMax = 1.3
local viewing = false
local currentViewTarget = nil
local currentViewPlayer = nil
local viewDied = nil
local viewChanged = nil
pendingTeleportToSelectedPlayer = false
local targetActionControls = nil
local flingModeControls = nil
local zeroLocalPlayerRoot
local syncFlingModeControls

local function encodeKeybindValue(keyCode)
	return keyCode and keyCode.Name or ""
end

local function decodeKeybindValue(value)
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

normalizeSafeZoneSigned = function(value)
	local parsed = tonumber(value)
	if parsed == nil or parsed == 0 then
		return safeZone.step
	end

	local sign = parsed < 0 and -1 or 1
	local snapped = math.floor((math.abs(parsed) / safeZone.step) + 0.5) * safeZone.step
	snapped = math.clamp(snapped, safeZone.step, safeZone.maxValue)
	return snapped * sign
end

normalizeSafeZonePositive = function(value)
	local parsed = tonumber(value)
	if parsed == nil or parsed <= 0 then
		return safeZone.step
	end

	local snapped = math.floor((parsed / safeZone.step) + 0.5) * safeZone.step
	return math.clamp(snapped, safeZone.step, safeZone.maxValue)
end

local function loadSliderSaveData()
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

local function saveSliderSaveData()
	if type(writefile) ~= "function" then
		return
	end

	pcall(function()
		writefile(sliderSaveFile, HttpService:JSONEncode(controlSaveData))
	end)
end

loadSliderSaveData()

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

if type(controlSaveData.AutoSafeZone) == "boolean" then
	safeZone.enabled = controlSaveData.AutoSafeZone
end

do
	local savedWalkFlingKeybind = decodeKeybindValue(controlSaveData.WalkFlingKeybind)
	if savedWalkFlingKeybind then
		walkFlingKeybind = savedWalkFlingKeybind
	end
end

local function parseEnabledValue(value)
	if type(value) == "boolean" then
		return value
	end

	if value == nil then
		return farmEnabled
	end

	local normalized = string.lower(tostring(value))
	return normalized == "on" or normalized == "true" or normalized == "1"
end

local function updateKeybindText()
	local lines = {}
	local orderedKeys = { "Speed", "Fly", "CamLock", "AttackTP", "TargetPick", "WalkFling", "SetBack", "Custom" }

	local function appendEntry(entry)
		if not entry then
			return
		end

		local name = tostring(entry.name or "")
		local keybind = tostring(entry.keybind or "")
		local hideState = entry.hideState == true
		local stateText = tostring(entry.stateText or ((entry.enabled == true) and "ON" or "OFF"))

		if hideState then
			if name ~= "" and keybind ~= "" then
				lines[#lines + 1] = string.format("%s (%s)", name, keybind)
			elseif name ~= "" then
				lines[#lines + 1] = name
			elseif keybind ~= "" then
				lines[#lines + 1] = string.format("(%s)", keybind)
			end
			return
		end

		if name ~= "" and keybind ~= "" then
			lines[#lines + 1] = string.format("%s (%s) (%s)", name, keybind, stateText)
		elseif name ~= "" then
			lines[#lines + 1] = string.format("%s (%s)", name, stateText)
		elseif keybind ~= "" then
			lines[#lines + 1] = string.format("(%s) (%s)", keybind, stateText)
		end
	end

	for _, key in ipairs(orderedKeys) do
		appendEntry(keybindEntries[key])
	end

	if #lines == 0 then
		keybindText.Text = ""
		return
	end

	keybindText.Text = table.concat(lines, "\n")
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
		for _, directionName in ipairs(value) do
			parsed[tostring(directionName)] = true
		end
	elseif value ~= nil then
		parsed[tostring(value)] = true
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

	myRoot.CFrame = targetRoot.CFrame + offset
	myRoot.AssemblyAngularVelocity = Vector3.new(power, power, power)
	myRoot.AssemblyLinearVelocity = targetRoot.CFrame.LookVector * power + Vector3.new(0, power * 0.5, 0)
end

function setWalkFlingEnabled(enabled)
	local nextState = enabled == nil and not walkFlingEnabled or enabled == true
	if walkFlingEnabled == nextState then
		syncWalkFlingKeybindDisplay()
		return walkFlingEnabled and "ON" or "OFF"
	end

	walkFlingEnabled = nextState
	walkFlingTaskToken += 1

	if walkFlingEnabled then
		local moveOffset = 0.1
		local taskToken = walkFlingTaskToken
		task.spawn(function()
			while walkFlingEnabled and walkFlingTaskToken == taskToken do
				local currentCharacter = player.Character
				local rootPart = getRootUniversal(currentCharacter)
				if rootPart then
					local originalVelocity = rootPart.Velocity
					if walkFlingUseNormal then
						rootPart.Velocity = originalVelocity * walkFlingPower + Vector3.new(0, walkFlingPower, 0)
						task.wait()
						if rootPart.Parent then
							rootPart.Velocity = originalVelocity
						end
						task.wait()
						if rootPart.Parent then
							rootPart.Velocity = originalVelocity + Vector3.new(0, moveOffset, 0)
							moveOffset *= -1
						end
					else
						local direction = getWalkFlingDirectionVector(rootPart)
						if direction then
							rootPart.Velocity = direction * walkFlingPower
							task.wait()
							if rootPart.Parent then
								rootPart.Velocity = originalVelocity
							end
						end
					end
				end

				task.wait()
			end
		end)
	else
		zeroLocalPlayerRoot()
	end

	syncWalkFlingKeybindDisplay()
	syncFlingModeControls()
	return walkFlingEnabled and "ON" or "OFF"
end

function setAuraFlingEnabled(enabled)
	local nextState = enabled == nil and not auraFlingEnabled or enabled == true
	auraFlingEnabled = nextState
	auraFlingTaskToken += 1

	if not auraFlingEnabled then
		resetGlobalFlingMotion()
		syncFlingModeControls()
		return "OFF"
	end

	local taskToken = auraFlingTaskToken
	task.spawn(function()
		while auraFlingEnabled and auraFlingTaskToken == taskToken do
			local myCharacter = player.Character
			local myRoot = getRootUniversal(myCharacter)
			if myRoot then
				local savedCFrame = myRoot.CFrame
				local myPosition = myRoot.Position
				local touchedAny = false

				for _, otherPlayer in ipairs(getOtherPlayers()) do
					local targetRoot = getRootUniversal(otherPlayer.Character)
					if targetRoot and (targetRoot.Position - myPosition).Magnitude <= auraRange then
						touchedAny = true
						myRoot.AssemblyLinearVelocity = Vector3.zero
						myRoot.AssemblyAngularVelocity = Vector3.zero
						myCharacter:PivotTo(targetRoot.CFrame)
						task.wait()
						if not auraFlingEnabled or auraFlingTaskToken ~= taskToken or not myRoot.Parent then
							break
						end
						myRoot.AssemblyAngularVelocity = Vector3.new(flingPower, flingPower, flingPower)
						myRoot.AssemblyLinearVelocity = myRoot.CFrame.LookVector * flingPower + Vector3.new(0, flingPower * 0.5, 0)
					end
				end

				if touchedAny and myRoot.Parent then
					task.wait()
					myRoot.AssemblyAngularVelocity = Vector3.zero
					myRoot.AssemblyLinearVelocity = Vector3.zero
					myCharacter:PivotTo(savedCFrame)
				end
			end

			task.wait()
		end

		if not auraFlingEnabled then
			resetGlobalFlingMotion()
		end
	end)

	syncFlingModeControls()
	return "ON"
end

function clickFlingTargetPlayer(targetPlayer)
	if clickFlingBusy then
		return
	end

	clickFlingBusy = true
	task.spawn(function()
		local myCharacter = player.Character
		local myRoot = getRootUniversal(myCharacter)
		local targetRoot = getRootUniversal(targetPlayer and targetPlayer.Character)

		if myRoot and targetRoot then
			local savedCFrame = myRoot.CFrame
			local startedAt = tick()
			resetGlobalFlingMotion()

			while clickFlingEnabled and tick() - startedAt < 8 do
				targetRoot = getRootUniversal(targetPlayer and targetPlayer.Character)
				if not targetRoot or not targetRoot.Parent or not myRoot.Parent then
					break
				end

				local dt = task.wait()
				applyOrbitFlingStep(myRoot, targetRoot, dt, flingPower)
			end

			if myRoot.Parent then
				myRoot.AssemblyAngularVelocity = Vector3.zero
				myRoot.AssemblyLinearVelocity = Vector3.zero
				myRoot.CFrame = savedCFrame
			end
		end

		clickFlingBusy = false
	end)
end

function getPlayerFromClickedPart(part)
	local current = part
	while current do
		if current:IsA("Model") then
			local targetPlayer = Players:GetPlayerFromCharacter(current)
			if targetPlayer and targetPlayer ~= player then
				return targetPlayer
			end
		end
		current = current.Parent
	end
	return nil
end

function setClickFlingEnabled(enabled)
	local nextState = enabled == nil and not clickFlingEnabled or enabled == true
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

			local targetPlayer = getPlayerFromClickedPart(mouse.Target)
			if targetPlayer then
				clickFlingTargetPlayer(targetPlayer)
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
	flingAllEnabled = nextState
	flingAllTaskToken += 1

	if flingAllEnabled then
		resetGlobalFlingMotion()
		local taskToken = flingAllTaskToken
		task.spawn(function()
			while flingAllEnabled and flingAllTaskToken == taskToken do
				local dt = task.wait()
				local myRoot = getRootUniversal(player.Character)
				if not myRoot then
					continue
				end

				local targetRoots = {}
				for _, otherPlayer in ipairs(getOtherPlayers()) do
					local targetRoot = getRootUniversal(otherPlayer.Character)
					if targetRoot then
						targetRoots[#targetRoots + 1] = targetRoot
					end
				end

				if #targetRoots == 0 then
					continue
				end

				if flingTargetIndex > #targetRoots then
					flingTargetIndex = 1
				end

				local targetRoot = targetRoots[flingTargetIndex]
				applyOrbitFlingStep(myRoot, targetRoot, dt, flingPower)
				flingTargetIndex += 1
			end
		end)
	else
		resetGlobalFlingMotion()
	end

	syncFlingModeControls()
	return flingAllEnabled and "ON" or "OFF"
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

function saveSetBackPosition()
	local currentCharacter = player.Character
	local currentHumanoid = currentCharacter and currentCharacter:FindFirstChildOfClass("Humanoid")
	local currentRoot = currentCharacter and currentCharacter:FindFirstChild("HumanoidRootPart")
	if not currentHumanoid or not currentRoot then
		return false
	end

	if currentHumanoid.FloorMaterial == Enum.Material.Air then
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
	local currentCharacter = player.Character
	local currentRoot = currentCharacter and currentCharacter:FindFirstChild("HumanoidRootPart")
	if not currentRoot or not setBackSavedCFrame then
		return false
	end

	stopSetBackTravel()
	setSetBackNoclipEnabled(true)
	setBackTravelConn = RunService.Heartbeat:Connect(function(dt)
		local liveCharacter = player.Character
		local liveRoot = liveCharacter and liveCharacter:FindFirstChild("HumanoidRootPart")
		if not liveRoot or not setBackSavedCFrame then
			stopSetBackTravel()
			return
		end

		local destination = setBackSavedCFrame
		local delta = destination.Position - liveRoot.Position
		local distance = delta.Magnitude
		local liveHumanoid = liveCharacter and liveCharacter:FindFirstChildOfClass("Humanoid")
		if distance <= 2 then
			liveRoot.CFrame = getUprightSetBackCFrame(destination.Position, destination)
			liveRoot.AssemblyLinearVelocity = Vector3.zero
			liveRoot.AssemblyAngularVelocity = Vector3.zero
			if liveHumanoid then
				liveHumanoid.PlatformStand = false
				liveHumanoid.Sit = false
				liveHumanoid:ChangeState(Enum.HumanoidStateType.GettingUp)
			end
			stopSetBackTravel()
			return
		end

		local step = math.min(1000 * dt, distance)
		local nextPosition = getSetBackTravelPosition(liveRoot, destination, step)
		liveRoot.CFrame = getUprightSetBackCFrame(nextPosition, destination)
		liveRoot.AssemblyLinearVelocity = Vector3.zero
		liveRoot.AssemblyAngularVelocity = Vector3.zero
		if liveHumanoid then
			liveHumanoid.PlatformStand = false
			liveHumanoid.Sit = false
		end
	end)

	return true
end

local function stopSafeZoneTravel()
	if safeZone.travelConn then
		if safeZone.travelConn.Disconnect then
			safeZone.travelConn:Disconnect()
		end
		safeZone.travelConn = nil
	end

	safeZone.travelMode = nil

	local currentCharacter = player.Character
	local currentRoot = currentCharacter and currentCharacter:FindFirstChild("HumanoidRootPart")
	if currentRoot then
		currentRoot.AssemblyLinearVelocity = Vector3.zero
		currentRoot.AssemblyAngularVelocity = Vector3.zero
	end
end

local function getFlatUnitVector(vector, fallback)
	local flat = Vector3.new(vector.X, 0, vector.Z)
	if flat.Magnitude <= 0.001 then
		return fallback
	end

	return flat.Unit
end

local function getSafeZoneDestination(sourceCFrame)
	local forward = getFlatUnitVector(sourceCFrame.LookVector, Vector3.new(0, 0, -1))
	local right = getFlatUnitVector(sourceCFrame.RightVector, Vector3.new(1, 0, 0))
	local point = math.clamp(safeZone.pointCurrent or safeZone.pointStart, safeZone.pointStart, safeZone.pointMax)
	local offset = (right * point)
		+ (forward * point)
		+ Vector3.new(0, point, 0)

	return getUprightSetBackCFrame(sourceCFrame.Position + offset, sourceCFrame)
end

local function canSaveSafeZonePosition(character, rootPart, humanoid)
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

local function startSafeZoneTravel(destination, mode, onComplete)
	if not destination then
		return false
	end

	stopSafeZoneTravel()
	safeZone.travelMode = mode

	local liveCharacter = player.Character
	local liveRoot = liveCharacter and liveCharacter:FindFirstChild("HumanoidRootPart")
	local liveHumanoid = liveCharacter and liveCharacter:FindFirstChildOfClass("Humanoid")
	if not liveRoot then
		stopSafeZoneTravel()
		return false
	end

	zeroLocalPlayerRoot()
	liveRoot.CFrame = getUprightSetBackCFrame(destination.Position, destination)
	liveRoot.AssemblyLinearVelocity = Vector3.zero
	liveRoot.AssemblyAngularVelocity = Vector3.zero
	if liveHumanoid then
		liveHumanoid.PlatformStand = false
		liveHumanoid.Sit = false
		liveHumanoid:ChangeState(Enum.HumanoidStateType.GettingUp)
	end
	stopSafeZoneTravel()
	if onComplete then
		onComplete()
	end

	return true
end

function handleSetBackKeybind()
	if setBackTravelConn then
		stopSetBackTravel()
		return
	end

	local now = tick()
	setBackPressToken = setBackPressToken + 1
	local currentToken = setBackPressToken

	if now - setBackLastPressAt <= 0.35 then
		setBackLastPressAt = 0
		if setBackSavedCFrame then
			clearSetBackPosition()
		else
			saveSetBackPosition()
		end
		return
	end

	setBackLastPressAt = now
	task.delay(0.35, function()
		if currentToken ~= setBackPressToken or setBackLastPressAt ~= now then
			return
		end

		setBackLastPressAt = 0
		if setBackSavedCFrame then
			startSetBackTravel()
		end
	end)
end

local function toggleFly(nextState)
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
	flingEnabled = false
	if syncModelDropdownSelectionToManualTarget then
		syncModelDropdownSelectionToManualTarget()
	end
	attackTpHolding = false
	syncAttackTpKeybindDisplay()
	syncTargetPickKeybindDisplay()
	syncSetBackKeybindDisplay()
	targetValueText.Text = ""
	syncTargetActionControls()
end

local function isValidCamLockTarget(model)
	if not model or model == char then
		return false
	end

	local modelHumanoid = model:FindFirstChildOfClass("Humanoid")
	local modelRoot = model:FindFirstChild("HumanoidRootPart")
	return modelHumanoid and modelHumanoid.Health > 0 and modelRoot ~= nil
end

local function isValidAttackTpTarget(model)
	if not isValidCamLockTarget(model) then
		return false
	end

	local modelRoot = model:FindFirstChild("HumanoidRootPart")
	return modelRoot ~= nil and not modelRoot.Anchored
end

local function getTrackedPlayerTargetModel(targetPlayer)
	if not targetPlayer or targetPlayer == player or targetPlayer.Parent ~= Players then
		return nil
	end

	local targetCharacter = targetPlayer.Character
	if targetCharacter and targetCharacter ~= char then
		return targetCharacter
	end

	return nil
end

local function resolveManualAttackTpTargetModel()
	if manualAttackTpPlayer then
		manualAttackTpTarget = getTrackedPlayerTargetModel(manualAttackTpPlayer)
	end

	return manualAttackTpTarget
end

function hasTrackedSelectedPlayer()
	return manualAttackTpPlayer ~= nil and manualAttackTpPlayer ~= player and manualAttackTpPlayer.Parent == Players
end

function isWaitingForSelectedPlayerRespawn()
	return hasTrackedSelectedPlayer() and not isValidAttackTpTarget(resolveManualAttackTpTargetModel())
end

local function hasManualAttackTpSelection()
	if manualAttackTpPlayer then
		return hasTrackedSelectedPlayer()
	end

	return isValidAttackTpTarget(manualAttackTpTarget)
end

local function hasActiveSelectedTarget()
	if isValidAttackTpTarget(camLockTarget) then
		return true
	end

	local resolvedManualTarget = resolveManualAttackTpTargetModel()
	return isValidAttackTpTarget(resolvedManualTarget)
end

function hasSelectedTargetOrPendingPlayer()
	return hasActiveSelectedTarget() or isWaitingForSelectedPlayerRespawn()
end

local function syncTargetActionControls()
	if not targetActionControls then
		return
	end

	targetActionControls.First.SetValue(viewing, true)
	targetActionControls.Second.SetValue(autoTpEnabled, true)
	targetActionControls.Third.SetValue(flingEnabled, true)
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
	if isValidCamLockTarget(camLockTarget) then
		return camLockTarget
	end

	local resolvedManualTarget = resolveManualAttackTpTargetModel()
	if isValidAttackTpTarget(resolvedManualTarget) then
		return resolvedManualTarget
	end

	return nil
end

local function updateTargetDisplay()
	local targetStateChanged = false

	if manualAttackTpPlayer then
		if manualAttackTpPlayer == player or manualAttackTpPlayer.Parent ~= Players then
			manualAttackTpPlayer = nil
			manualAttackTpTarget = nil
			pendingTeleportToSelectedPlayer = false
			if syncModelDropdownSelectionToManualTarget then
				syncModelDropdownSelectionToManualTarget()
			end
			targetStateChanged = true
		else
			resolveManualAttackTpTargetModel()
		end
	elseif manualAttackTpTarget and not isValidAttackTpTarget(manualAttackTpTarget) then
		manualAttackTpTarget = nil
		pendingTeleportToSelectedPlayer = false
		if syncModelDropdownSelectionToManualTarget then
			syncModelDropdownSelectionToManualTarget()
		end
		targetStateChanged = true
	end

	if not camLockEnabled and camLockTarget and not isValidCamLockTarget(camLockTarget) then
		camLockTarget = nil
		targetStateChanged = true
	end

	if targetStateChanged then
		syncTargetPickKeybindDisplay()
	end

	local displayedTarget = getDisplayedTargetModel()
	local displayName = displayedTarget and displayedTarget.Name or (manualAttackTpPlayer and manualAttackTpPlayer.Name or "")
	targetValueText.Text = displayName

	if not hasSelectedTargetOrPendingPlayer() then
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

	local currentEntry = keybindEntries.TargetPick
	if not currentEntry or currentEntry.name ~= "Target" or currentEntry.keybind ~= encodeKeybindValue(targetSelectKeybind) or currentEntry.hideState ~= true then
		syncTargetPickKeybindDisplay()
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

	for _, instance in ipairs(Workspace:GetDescendants()) do
		if instance:IsA("Humanoid") and instance.Health > 0 then
			local model = instance.Parent
			local modelRoot = model and model:FindFirstChild("HumanoidRootPart")
			if model and model ~= currentCharacter and modelRoot and not modelRoot.Anchored then
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
	if isValidAttackTpTarget(camLockTarget) then
		return camLockTarget
	end

	local resolvedManualTarget = resolveManualAttackTpTargetModel()
	if isValidAttackTpTarget(resolvedManualTarget) then
		return resolvedManualTarget
	end

	if hasManualAttackTpSelection() then
		return nil
	end

	return getClosestAliveTarget()
end

local function resolveAttackTpTarget()
	if isValidAttackTpTarget(camLockTarget) then
		return camLockTarget
	end

	local resolvedManualTarget = resolveManualAttackTpTargetModel()
	if isValidAttackTpTarget(resolvedManualTarget) then
		return resolvedManualTarget
	end

	if hasManualAttackTpSelection() then
		return nil
	end

	if isValidAttackTpTarget(attackTpTarget) then
		return attackTpTarget
	end

	return getClosestAliveTarget()
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

local function getAttackTpPlacement(characterRoot, targetModel)
	if not characterRoot or not targetModel then
		return nil, nil
	end

	local targetRoot = targetModel:FindFirstChild("HumanoidRootPart")
	local targetHumanoid = targetModel:FindFirstChildOfClass("Humanoid")
	if not targetRoot or not targetHumanoid or targetHumanoid.Health <= 0 then
		return nil, nil
	end

	local characterHumanoid = characterRoot.Parent and characterRoot.Parent:FindFirstChildOfClass("Humanoid")
	local useAirTracking = isAirborneHumanoid(targetHumanoid) or isAirborneHumanoid(characterHumanoid)
	local targetVelocity = targetRoot.AssemblyLinearVelocity
	local horizontalVelocity = Vector3.new(targetVelocity.X, 0, targetVelocity.Z)
	local leadTime = useAirTracking and attackTpAirLeadTime or attackTpLeadTime
	local horizontalLead = horizontalVelocity * leadTime
	if horizontalLead.Magnitude > attackTpMaxHorizontalLead then
		horizontalLead = horizontalLead.Unit * attackTpMaxHorizontalLead
	end

	local followDirection = getHorizontalUnit(horizontalVelocity)
		or getHorizontalUnit(targetRoot.CFrame.LookVector)
		or getHorizontalUnit(targetRoot.Position - characterRoot.Position)
		or Vector3.new(0, 0, -1)
	local verticalLead = math.clamp(targetVelocity.Y * attackTpVerticalLead, -attackTpMaxVerticalLead, attackTpMaxVerticalLead)
	local behindDistance = useAirTracking and attackTpAirBehindDistance or attackTpBehindDistance
	local verticalOffset = useAirTracking and attackTpAirVerticalOffset or attackTpGroundVerticalOffset
	local predictedTargetPosition = targetRoot.Position + horizontalLead + Vector3.new(0, verticalLead, 0)
	local behindPosition = predictedTargetPosition - (followDirection * behindDistance) + Vector3.new(0, verticalOffset, 0)
	local lookPosition = predictedTargetPosition + Vector3.new(0, verticalOffset * 0.35, 0)

	return CFrame.lookAt(behindPosition, lookPosition, worldUpVector), targetVelocity
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

	for _, instance in ipairs(Workspace:GetDescendants()) do
		if instance:IsA("Humanoid") and instance.Health > 0 then
			local model = instance.Parent
			local modelRoot = model and model:FindFirstChild("HumanoidRootPart")
			if model and model ~= char and modelRoot then
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

	for _, instance in ipairs(Workspace:GetDescendants()) do
		if instance:IsA("Humanoid") and instance.Health > 0 then
			local model = instance.Parent
			local modelRoot = model and model:FindFirstChild("HumanoidRootPart")
			if model and model ~= char and modelRoot and not modelRoot.Anchored then
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

	if bestDistance > camLockAcquireRadius then
		return nil
	end

	return bestModel
end

local function setManualAttackTpTarget(model, targetPlayer)
	if isSelectablePlayerDropdownTarget(targetPlayer) then
		manualAttackTpPlayer = targetPlayer
		manualAttackTpTarget = getTrackedPlayerTargetModel(targetPlayer)
	elseif isValidAttackTpTarget(model) then
		manualAttackTpPlayer = nil
		manualAttackTpTarget = model
	else
		manualAttackTpPlayer = nil
		manualAttackTpTarget = nil
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

	if isValidAttackTpTarget(camLockTarget) then
		if isValidAttackTpTarget(mouseTarget) then
			return setManualAttackTpTarget(mouseTarget)
		end

		syncTargetPickKeybindDisplay()
		updateTargetDisplay()
		return manualAttackTpTarget
	end

	if hasManualAttackTpSelection() then
		return setManualAttackTpTarget(nil)
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
	else
		camLockTarget = nil
		camLockWaiting = false
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

	if shouldEnable and not isValidAttackTpTarget(nextTarget) then
		shouldEnable = false
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
	settingsOpen = visible
	settingsWindow.Visible = visible
	windowOutline.Visible = visible

	if visible then
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
		settingsStroke.Transparency = 1
		windowOutlineStroke.Transparency = 1
	end
end

local function roundToTenth(value)
	return math.floor((value * 10) + 0.5) / 10
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
	holder.BackgroundColor3 = Color3.fromRGB(8, 0, 0)
	holder.BackgroundTransparency = 0.2
	holder.Size = UDim2.new(1, -4, 0, heightScale)
	holder.BorderSizePixel = 0
	holder.Active = true

	local holderCorner = Instance.new("UICorner")
	holderCorner.CornerRadius = UDim.new(0, 14)
	holderCorner.Parent = holder

	local holderStroke = Instance.new("UIStroke")
	holderStroke.Color = Color3.fromRGB(120, 0, 0)
	holderStroke.Thickness = 1.5
	holderStroke.Transparency = 0.2
	holderStroke.Parent = holder

	return holder
end

local infoToken = 0

local function showInfo(title, text, time)
	infoToken = infoToken + 1

	local currentToken = infoToken
	local titleValue = tostring(title or "")
	local textValue = tostring(text or "")
	local duration = tonumber(time) or 5

	infoTitle.Text = titleValue
	infoText.Text = textValue
	infoContainer.Visible = true

	TweenService:Create(infoContainer, TweenInfo.new(0.25, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
		BackgroundTransparency = 0.2,
	}):Play()

	TweenService:Create(infoStroke, TweenInfo.new(0.25, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
		Transparency = 0.1,
	}):Play()

	TweenService:Create(infoTitle, TweenInfo.new(0.25, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
		TextTransparency = 0,
		TextStrokeTransparency = 0,
	}):Play()

	TweenService:Create(infoText, TweenInfo.new(0.25, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
		TextTransparency = 0,
		TextStrokeTransparency = 0.2,
	}):Play()

	task.delay(duration, function()
		if currentToken ~= infoToken then
			return
		end

		local fadeTweenInfo = TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)

		TweenService:Create(infoContainer, fadeTweenInfo, {
			BackgroundTransparency = 1,
		}):Play()

		TweenService:Create(infoStroke, fadeTweenInfo, {
			Transparency = 1,
		}):Play()

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
			if currentToken ~= infoToken then
				return
			end

			infoContainer.Visible = false
		end)
	end)
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
do
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
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
local playerState = {}     
local activeTimers = {}
local playerConnections = {}
local function callInfo(title, text, duration)
    if type(INFO) == "function" then
        pcall(function()
            INFO(title, text, duration or 5)
        end)
    end
end
local function addHighlight(model, color, enabled)
    if not model or not model:FindFirstChild("HumanoidRootPart") then return end
    local oldHl = model:FindFirstChild("NOTHING-X")
    if oldHl then
        oldHl:Destroy()
    end
    local hl = Instance.new("Highlight")
    hl.Name = "NOTHING-X"
    hl.Adornee = model
    hl.Parent = model
    hl.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
    hl.FillTransparency = 0.8
    hl.OutlineTransparency = 0
    hl.OutlineColor = Color3.fromRGB(0, 0, 0)
    hl.FillColor = color
    hl.Enabled = enabled
end
local function removeHighlight(model)
    if model then
        local hl = model:FindFirstChild("NOTHING-X")
        if hl then
            hl:Destroy()
        end
    end
end
local function getSkillType(backpack)
    for _, tool in ipairs(backpack:GetChildren()) do
        if strongSkills[tool.Name] then return "strong" end
        if weakSkills[tool.Name] then return "weak" end
    end
    return nil
end
local function updatePlayer(plr)
    local char = plr.Character
    if not char then return end
    local backpack = plr:FindFirstChild("Backpack")
    if not backpack then return end
    local humanoid = char:FindFirstChildOfClass("Humanoid")
    if not humanoid or humanoid.Health <= 0 then
        playerState[plr] = nil
        removeHighlight(char)
        return
    end
    local skill = getSkillType(backpack)
    local currentState = playerState[plr]
    if skill == "strong" and currentState ~= "strong" then
        playerState[plr] = "strong"
        addHighlight(char, Color3.fromRGB(255, 255, 255), true) 
        callInfo("SERIOUS MODE", plr.Name .. " - ACTIVE", 5)
    elseif skill == "weak" and currentState == "strong" then
        playerState[plr] = "weak"
        addHighlight(char, Color3.fromRGB(255, 0, 0), true) 
        callInfo("SERIOUS MODE", plr.Name .. " - DEATH", 5)
        local timerId = tick()
        activeTimers[plr] = timerId
        task.delay(9.4, function()
            if activeTimers[plr] == timerId and playerState[plr] == "weak" then
                playerState[plr] = nil
                removeHighlight(char)
                callInfo("SERIOUS MODE", plr.Name .. " - END", 5)
            end
        end)
    end
end
local function startGlobalChecker()
    RunService.Heartbeat:Connect(function()
        for _, plr in ipairs(Players:GetPlayers()) do
            if plr == Players.LocalPlayer then continue end
            local char = plr.Character
            if not char then continue end
            local shouldHaveState = playerState[plr]
            local hl = char:FindFirstChild("NOTHING-X")
            if shouldHaveState then
                if not hl then
                    if shouldHaveState == "strong" then
                        addHighlight(char, Color3.fromRGB(255, 255, 255), true)
                    else
                        addHighlight(char, Color3.fromRGB(255, 0, 0), true)
                    end
                end
            else
                if hl then
                    removeHighlight(char)
                end
            end
        end
    end)
end
local function setupPlayer(plr)
    if plr == Players.LocalPlayer then return end
    local function disconnectTrackedConnections()
        local tracked = playerConnections[plr]
        if not tracked then return end
        for _, conn in ipairs(tracked) do
            if conn and conn.Disconnect then
                conn:Disconnect()
            end
        end
        playerConnections[plr] = nil
    end
    local function onCharacterAdded(char)
        task.wait(0.4)
        playerState[plr] = nil
        char = char or plr.Character
        if not char or char ~= plr.Character then
            return
        end
        disconnectTrackedConnections()
        removeHighlight(char)
        local backpack = plr:WaitForChild("Backpack", 6)
        if not backpack then
            return
        end
        playerConnections[plr] = {
            backpack.ChildAdded:Connect(function()
                task.wait(0.1)
                if plr.Parent then
                    updatePlayer(plr)
                end
            end),
            backpack.ChildRemoved:Connect(function()
                task.wait(0.1)
                if plr.Parent then
                    updatePlayer(plr)
                end
            end)
        }
        local hum = char:FindFirstChild("Humanoid") or char:WaitForChild("Humanoid", 3)
        if hum and char == plr.Character then
            table.insert(playerConnections[plr], hum.Died:Connect(function()
                playerState[plr] = nil
                removeHighlight(char)
            end))
            updatePlayer(plr)
        end
    end
    if plr.Character then 
        onCharacterAdded(plr.Character) 
    end
    plr.CharacterAdded:Connect(onCharacterAdded)
    plr.AncestryChanged:Connect(function(_, parent)
        if parent == nil then
            disconnectTrackedConnections()
            playerState[plr] = nil
        end
    end)
end
startGlobalChecker()
for _, plr in ipairs(Players:GetPlayers()) do
    setupPlayer(plr)
end
Players.PlayerAdded:Connect(setupPlayer)
end

do
local Players = game:GetService("Players")
local speaker = Players.LocalPlayer
local speed = 25.66
local jpower = 50.66
local ModConnections = {}
local function SetupHumanoid(Char, Human)
	if not Human or not Human.Parent then return end
	if ModConnections.wsLoop then ModConnections.wsLoop:Disconnect() end
	if ModConnections.jpLoop then ModConnections.jpLoop:Disconnect() end
	local function UpdateWalkSpeed()
		if Human and Human.Parent then
			Human.WalkSpeed = speed
		end
	end
	UpdateWalkSpeed()
	ModConnections.wsLoop = Human:GetPropertyChangedSignal("WalkSpeed"):Connect(UpdateWalkSpeed)
	local function UpdateJumpPower()
		if Human and Human.Parent then
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
end
local function isCounter(acc)
	if not acc or not acc:IsA("Accessory") then return false end
	return acc.Name:lower():find("counter") ~= nil
end
local function isSmallDebris(acc)
	if not acc or not acc:IsA("Accessory") then return false end
	return acc.Name:lower():find("small debris") ~= nil
end
local function usunPusteAccessory(char)
	if not char then return end
	for _, obj in ipairs(char:GetChildren()) do
		if obj:IsA("Accessory") then
			if isCounter(obj) or isSmallDebris(obj) then
				continue
			end
			if #obj:GetChildren() == 0 then
				pcall(function()
					obj:Destroy()
				end)
			end
		end
	end
end
local function OnCharacterAdded(Char)
	local Human = Char:WaitForChild("Humanoid", 5)
	if Human then
		SetupHumanoid(Char, Human)
	end
	task.wait(0.25)
	usunPusteAccessory(Char)
end
if speaker.Character then
	task.spawn(function()
		OnCharacterAdded(speaker.Character)
	end)
end
ModConnections.CharacterAdded = speaker.CharacterAdded:Connect(OnCharacterAdded)
task.spawn(function()
	while true do
		task.wait()
		local char = speaker.Character
		if not char then continue end
		usunPusteAccessory(char)
		usunPusteAccessory(char)
	end
end)
task.spawn(function()
    local RunService = game:GetService("RunService")
    local Players = game:GetService("Players")
    local connection = RunService.Heartbeat:Connect(function()
        for _, player in ipairs(Players:GetPlayers()) do
            if player ~= Players.LocalPlayer and player.Character then
                for _, part in ipairs(player.Character:GetDescendants()) do
                    if part:IsA("BasePart") then
                        part.CanCollide = false
                        part.Velocity = Vector3.zero
                        part.AssemblyLinearVelocity = Vector3.zero
                        part.AssemblyAngularVelocity = Vector3.zero
                    end
                end
            end
        end
    end)
end)
end
local StayToggle = nil
local DashToggle = nil
task.spawn(function()
    task.wait(0.2)
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

local function teleportToWeakestDummy()
	local live = workspace:FindFirstChild("Live")
	if not live then return end
	local dummy = live:FindFirstChild("Weakest Dummy")
	if not dummy then 
		return 
	end
	local humanoid = dummy:FindFirstChildOfClass("Humanoid")
	local dummyRoot = dummy:FindFirstChild("HumanoidRootPart")
	local character = player.Character
	local hrp = character and character:FindFirstChild("HumanoidRootPart")
	if not humanoid or humanoid.Health <= 0 or not dummyRoot or not hrp then
		return
	end
	hrp.AssemblyLinearVelocity = Vector3.zero
	hrp.AssemblyAngularVelocity = Vector3.zero
	local forward = dummyRoot.CFrame.LookVector
	local teleportPos = dummyRoot.Position + (forward * 4.5) + Vector3.new(0, 3, 0)
	hrp.CFrame = CFrame.lookAt(teleportPos, dummyRoot.Position)
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
            stayGyro.MaxTorque = Vector3.new(9e9, 9e9, 9e9)
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
            DashThread:Disconnect()
            DashThread = nil
        end
        if not DashBlockRunning then
            return
        end
        if not communicate then
            DashBlockRunning = false
            return
        end
        DashThread = RunService.Heartbeat:Connect(function()
            if not DashBlockRunning or not communicate then
                return
            end
            for _, dashKey in ipairs(directions) do
                communicate:FireServer({
                    Dash = dashKey,
                    Key = Enum.KeyCode.Q,
                    Goal = "KeyPress"
                })
            end
        end)
    end

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
    end

    local hasDummyMainPart = workspace:FindFirstChild("Map") and workspace.Map:FindFirstChild("MainPart")
    local supportsDashBlock = game.GameId == 3808081382

    local panel = _G["2tog_on_one_button"]({
        title = "Movement",
        name1 = "Stay",
        name2 = supportsDashBlock and "Dash Block FE" or nil,
        buttonName = "Fix Camera",
        buttonName2 = "Lay",
        buttonName3 = hasDummyMainPart and "Dummy" or nil,
        default1 = false,
        default2 = supportsDashBlock and false or nil,
        fun1 = setStayState,
        fun2 = supportsDashBlock and setDashBlockRuntime or nil,
        buttonfun = fixCamera,
        buttonfun2 = layCharacter,
        buttonfun3 = hasDummyMainPart and teleportToWeakestDummy or nil,
    })
    StayToggle = panel.First
    DashToggle = panel.Second

    player.CharacterAdded:Connect(function()
        if isActive then
            cleanupStay()
            isActive = false
            if StayToggle and StayToggle.SetValue then
                StayToggle:SetValue(false, true)
            end
        end
        communicate = nil
    end)

    if player.Character then
        setupCharacter(player.Character)
    end
    player.CharacterAdded:Connect(setupCharacter)
end)
task.spawn(function()
    task.wait(0.3)
    local flingState = {
        localPlayer = Players.LocalPlayer,
        flingConn = nil,
        flingPower = 1e12,
        orbitSpeed = 1e9,
        orbitStepXZ = 0,
        orbitStepY = 8,
        orbitIncrement = 0.9,
        orbitMax = 3,
    }

    local function getRoot(char)
        if not char then
            return nil
        end

        return char:FindFirstChild("HumanoidRootPart") or char:FindFirstChild("Torso") or char:FindFirstChild("UpperTorso")
    end

    local function stopFlingRuntime()
        if flingState.flingConn then
            flingState.flingConn:Disconnect()
            flingState.flingConn = nil
        end
        flingState.orbitStepXZ = 0
        flingState.orbitStepY = 3
    end

    local function startFlingRuntime()
        stopFlingRuntime()
        flingState.flingConn = RunService.Heartbeat:Connect(function()
            if not flingEnabled then
                stopFlingRuntime()
                return
            end

            local myChar = flingState.localPlayer.Character
            local myRoot = getRoot(myChar)
            if not myRoot then
                return
            end

            local targetModel = getDisplayedTargetModel()
            if not targetModel then
                return
            end

            local targetRoot = getRoot(targetModel)
            if not targetRoot then
                return
            end

            flingState.orbitStepXZ = flingState.orbitStepXZ + flingState.orbitIncrement
            flingState.orbitStepY = flingState.orbitStepY + flingState.orbitIncrement
            if flingState.orbitStepXZ > flingState.orbitMax then
                flingState.orbitStepXZ = 0
            end
            if flingState.orbitStepY > flingState.orbitMax then
                flingState.orbitStepY = 0
            end

            local t = tick() * flingState.orbitSpeed
            local offset = Vector3.new(
                math.cos(t) * flingState.orbitStepXZ,
                flingState.orbitStepY,
                math.sin(t) * flingState.orbitStepXZ
            )

            myRoot.CFrame = targetRoot.CFrame + offset
            myRoot.AssemblyAngularVelocity = Vector3.new(flingState.flingPower, flingState.flingPower, flingState.flingPower)
            myRoot.AssemblyLinearVelocity = targetRoot.CFrame.LookVector * flingState.flingPower + Vector3.new(0, flingState.flingPower * 0.6, 0)
        end)
    end

    while true do
        task.wait()
        if flingEnabled then
            if not flingState.flingConn then
                startFlingRuntime()
            end
        else
            stopFlingRuntime()
        end
    end
end)

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
	nameLabel.TextColor3 = Color3.fromRGB(255, 55, 55)
	nameLabel.TextStrokeTransparency = 0.15
	nameLabel.TextStrokeColor3 = Color3.fromRGB(110, 0, 0)
	nameLabel.TextScaled = true
	nameLabel.TextWrapped = true
	nameLabel.TextXAlignment = Enum.TextXAlignment.Left
	nameLabel.Parent = holder

	local nameConstraint = Instance.new("UITextSizeConstraint")
	nameConstraint.MinTextSize = 12
	nameConstraint.MaxTextSize = 18
	nameConstraint.Parent = nameLabel

	local editBox = Instance.new("TextBox")
	editBox.BackgroundColor3 = Color3.fromRGB(22, 0, 0)
	editBox.BackgroundTransparency = 0.08
	editBox.BorderSizePixel = 0
	editBox.Position = UDim2.fromScale(0.66, 0.3)
	editBox.Size = UDim2.fromScale(0.24, 0.24)
	editBox.ClearTextOnFocus = false
	editBox.Font = Enum.Font.GothamMedium
	editBox.PlaceholderText = "set"
	editBox.PlaceholderColor3 = Color3.fromRGB(140, 70, 70)
	editBox.Text = "0"
	editBox.TextColor3 = Color3.fromRGB(255, 180, 180)
	editBox.TextScaled = true
	editBox.Parent = holder

	local editCorner = Instance.new("UICorner")
	editCorner.CornerRadius = UDim.new(0, 10)
	editCorner.Parent = editBox

	local editConstraint = Instance.new("UITextSizeConstraint")
	editConstraint.MinTextSize = 10
	editConstraint.MaxTextSize = 14
	editConstraint.Parent = editBox

	local bar = Instance.new("Frame")
	bar.BackgroundColor3 = Color3.fromRGB(35, 0, 0)
	bar.BorderSizePixel = 0
	bar.Position = UDim2.fromScale(0.05, 0.68)
	bar.Size = UDim2.fromScale(0.9, 0.14)
	bar.Active = true
	bar.Parent = holder

	local barCorner = Instance.new("UICorner")
	barCorner.CornerRadius = UDim.new(1, 0)
	barCorner.Parent = bar

	local fill = Instance.new("Frame")
	fill.BackgroundColor3 = Color3.fromRGB(255, 0, 0)
	fill.BorderSizePixel = 0
	fill.Size = UDim2.fromScale(0, 1)
	fill.Parent = bar

	local fillCorner = Instance.new("UICorner")
	fillCorner.CornerRadius = UDim.new(1, 0)
	fillCorner.Parent = fill

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
	titleLabel.TextColor3 = Color3.fromRGB(255, 55, 55)
	titleLabel.TextStrokeTransparency = 0.15
	titleLabel.TextStrokeColor3 = Color3.fromRGB(110, 0, 0)
	titleLabel.TextScaled = true
	titleLabel.TextWrapped = true
	titleLabel.TextXAlignment = Enum.TextXAlignment.Left
	titleLabel.Parent = holder

	local titleConstraint = Instance.new("UITextSizeConstraint")
	titleConstraint.MinTextSize = 12
	titleConstraint.MaxTextSize = 18
	titleConstraint.Parent = titleLabel

	local inputBox = Instance.new("TextBox")
	inputBox.BackgroundColor3 = Color3.fromRGB(22, 0, 0)
	inputBox.BackgroundTransparency = 0.1
	inputBox.BorderSizePixel = 0
	inputBox.Position = UDim2.fromScale(0.05, 0.42)
	inputBox.Size = UDim2.fromScale(0.9, 0.38)
	inputBox.ClearTextOnFocus = false
	inputBox.Font = Enum.Font.GothamMedium
	inputBox.PlaceholderText = "type here"
	inputBox.PlaceholderColor3 = Color3.fromRGB(140, 70, 70)
	inputBox.Text = ""
	inputBox.TextColor3 = Color3.fromRGB(255, 180, 180)
	inputBox.TextScaled = true
	inputBox.TextWrapped = true
	inputBox.Parent = holder

	local inputCorner = Instance.new("UICorner")
	inputCorner.CornerRadius = UDim.new(0, 12)
	inputCorner.Parent = inputBox

	local inputConstraint = Instance.new("UITextSizeConstraint")
	inputConstraint.MinTextSize = 12
	inputConstraint.MaxTextSize = 16
	inputConstraint.Parent = inputBox

	inputBox.FocusLost:Connect(function(enterPressed)
		if callback then
			callback(inputBox.Text, enterPressed)
		end
	end)

	return holder
end

_G["2textbox_on_one_frame"] = function(data)
	data = data or {}

	local holder = makeControlFrame(92)
	holder.Parent = uiX

	local titleLabel = Instance.new("TextLabel")
	titleLabel.BackgroundTransparency = 1
	titleLabel.Position = UDim2.fromScale(0.05, 0.08)
	titleLabel.Size = UDim2.fromScale(0.9, 0.16)
	titleLabel.Font = Enum.Font.GothamBold
	titleLabel.Text = tostring(data.title or "Inputs")
	titleLabel.TextColor3 = Color3.fromRGB(255, 55, 55)
	titleLabel.TextStrokeTransparency = 0.15
	titleLabel.TextStrokeColor3 = Color3.fromRGB(110, 0, 0)
	titleLabel.TextScaled = true
	titleLabel.TextWrapped = true
	titleLabel.TextXAlignment = Enum.TextXAlignment.Left
	titleLabel.Parent = holder

	local titleConstraint = Instance.new("UITextSizeConstraint")
	titleConstraint.MinTextSize = 12
	titleConstraint.MaxTextSize = 18
	titleConstraint.Parent = titleLabel

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
		label.Position = UDim2.fromScale(0, 0)
		label.Size = UDim2.fromScale(1, 0.3)
		label.Font = Enum.Font.GothamMedium
		label.Text = tostring(labelText or "")
		label.TextColor3 = Color3.fromRGB(255, 160, 160)
		label.TextStrokeTransparency = 0.2
		label.TextStrokeColor3 = Color3.fromRGB(110, 0, 0)
		label.TextScaled = true
		label.TextWrapped = true
		label.TextXAlignment = Enum.TextXAlignment.Left
		label.Parent = container

		local labelConstraint = Instance.new("UITextSizeConstraint")
		labelConstraint.MinTextSize = 10
		labelConstraint.MaxTextSize = 14
		labelConstraint.Parent = label

		local inputBox = Instance.new("TextBox")
		inputBox.BackgroundColor3 = Color3.fromRGB(22, 0, 0)
		inputBox.BackgroundTransparency = 0.1
		inputBox.BorderSizePixel = 0
		inputBox.Position = UDim2.fromScale(0, 0.38)
		inputBox.Size = UDim2.fromScale(1, 0.52)
		inputBox.ClearTextOnFocus = false
		inputBox.Font = Enum.Font.GothamMedium
		inputBox.PlaceholderText = "set"
		inputBox.PlaceholderColor3 = Color3.fromRGB(140, 70, 70)
		inputBox.Text = tostring(defaultValue or "")
		inputBox.TextColor3 = Color3.fromRGB(255, 180, 180)
		inputBox.TextScaled = true
		inputBox.Parent = container

		local inputCorner = Instance.new("UICorner")
		inputCorner.CornerRadius = UDim.new(0, 12)
		inputCorner.Parent = inputBox

		local inputConstraint = Instance.new("UITextSizeConstraint")
		inputConstraint.MinTextSize = 10
		inputConstraint.MaxTextSize = 14
		inputConstraint.Parent = inputBox

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
	local defaultValue = data.deffultin
	if defaultValue == nil then
		defaultValue = data.defaultin
	end
	if defaultValue == nil then
		defaultValue = data.default
	end

	local multi = data.multi == true
	local callback = data.fun
	local saveKey = tostring(data.saveKey or data.namedropdown or data.nameDropdown or data.name or "")
	local items = {}
	local itemLookup = {}
	local selected = {}
	local expanded = false
	local collapsedHeight = 92
	local expandedTopOffset = 36
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

	local holder = makeControlFrame(collapsedHeight)
	holder.Parent = uiX

	local nameLabel = Instance.new("TextLabel")
	nameLabel.BackgroundTransparency = 1
	nameLabel.Position = UDim2.new(0, 18, 0, 10)
	nameLabel.Size = UDim2.new(1, -36, 0, 20)
	nameLabel.Font = Enum.Font.GothamBold
	nameLabel.Text = dropdownName
	nameLabel.TextColor3 = Color3.fromRGB(255, 55, 55)
	nameLabel.TextStrokeTransparency = 0.15
	nameLabel.TextStrokeColor3 = Color3.fromRGB(110, 0, 0)
	nameLabel.TextScaled = true
	nameLabel.TextWrapped = true
	nameLabel.TextXAlignment = Enum.TextXAlignment.Left
	nameLabel.ZIndex = 3
	nameLabel.Parent = holder

	local nameConstraint = Instance.new("UITextSizeConstraint")
	nameConstraint.MinTextSize = 12
	nameConstraint.MaxTextSize = 18
	nameConstraint.Parent = nameLabel

	local toggleButton = Instance.new("TextButton")
	toggleButton.BackgroundColor3 = Color3.fromRGB(22, 0, 0)
	toggleButton.BackgroundTransparency = 0.08
	toggleButton.BorderSizePixel = 0
	toggleButton.Position = UDim2.fromScale(0.05, 0.38)
	toggleButton.Size = UDim2.fromScale(0.9, 0.3)
	toggleButton.AutoButtonColor = false
	toggleButton.Font = Enum.Font.GothamBold
	toggleButton.TextColor3 = Color3.fromRGB(255, 180, 180)
	toggleButton.TextStrokeTransparency = 0.15
	toggleButton.TextStrokeColor3 = Color3.fromRGB(110, 0, 0)
	toggleButton.TextScaled = true
	toggleButton.TextWrapped = true
	toggleButton.Parent = holder

	local toggleCorner = Instance.new("UICorner")
	toggleCorner.CornerRadius = UDim.new(0, 12)
	toggleCorner.Parent = toggleButton

	local toggleConstraint = Instance.new("UITextSizeConstraint")
	toggleConstraint.MinTextSize = 11
	toggleConstraint.MaxTextSize = 15
	toggleConstraint.Parent = toggleButton

	local optionsFrame = Instance.new("Frame")
	optionsFrame.BackgroundTransparency = 1
	optionsFrame.Position = UDim2.new(0, 0, 0, expandedTopOffset)
	optionsFrame.Size = UDim2.new(1, 0, 0, 0)
	optionsFrame.ClipsDescendants = true
	optionsFrame.Visible = false
	optionsFrame.ZIndex = 1
	optionsFrame.Parent = holder

	local choiceFrame = Instance.new("ScrollingFrame")
	choiceFrame.BackgroundColor3 = Color3.fromRGB(12, 0, 0)
	choiceFrame.BackgroundTransparency = 0.18
	choiceFrame.BorderSizePixel = 0
	choiceFrame.AnchorPoint = Vector2.new(0.5, 0)
	choiceFrame.Position = UDim2.fromScale(0.5, 0)
	choiceFrame.Size = UDim2.new(0.94, 0, 0, 0)
	choiceFrame.CanvasSize = UDim2.fromOffset(0, 0)
	choiceFrame.AutomaticCanvasSize = Enum.AutomaticSize.None
	choiceFrame.ElasticBehavior = Enum.ElasticBehavior.Never
	choiceFrame.ScrollBarThickness = 4
	choiceFrame.ScrollBarImageColor3 = Color3.fromRGB(255, 0, 0)
	choiceFrame.ScrollingDirection = Enum.ScrollingDirection.Y
	choiceFrame.VerticalScrollBarInset = Enum.ScrollBarInset.ScrollBar
	choiceFrame.TopImage = ""
	choiceFrame.MidImage = ""
	choiceFrame.BottomImage = ""
	choiceFrame.ZIndex = 1
	choiceFrame.Parent = optionsFrame

	local choiceCorner = Instance.new("UICorner")
	choiceCorner.CornerRadius = UDim.new(0, 12)
	choiceCorner.Parent = choiceFrame

	local choiceStroke = Instance.new("UIStroke")
	choiceStroke.Color = Color3.fromRGB(110, 0, 0)
	choiceStroke.Thickness = 1.2
	choiceStroke.Transparency = 0.18
	choiceStroke.Parent = choiceFrame

	local optionsLayout = Instance.new("UIListLayout")
	optionsLayout.Padding = UDim.new(0, optionPadding)
	optionsLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
	optionsLayout.Parent = choiceFrame

	local optionButtons = {}
	local dropdownState = {}

	local function refreshLabels()
		local selectedList = getSelectedList()
		local displayText = #selectedList > 0 and table.concat(selectedList, ", ") or "-"
		toggleButton.Text = displayText

		for item, button in pairs(optionButtons) do
			local isOn = selected[item] == true
			button.BackgroundColor3 = isOn and Color3.fromRGB(150, 0, 0) or Color3.fromRGB(24, 0, 0)
			button.Text = isOn and ("[x] " .. item) or ("[ ] " .. item)
		end
	end

	local function clearOptionButtons()
		for item, button in pairs(optionButtons) do
			optionButtons[item] = nil
			if button then
				button:Destroy()
			end
		end
	end

	local function rebuildOptionButtons()
		clearOptionButtons()

		for _, item in ipairs(items) do
			local optionButton = Instance.new("TextButton")
			optionButton.BackgroundColor3 = Color3.fromRGB(24, 0, 0)
			optionButton.BackgroundTransparency = 0.06
			optionButton.BorderSizePixel = 0
			optionButton.Size = UDim2.new(0.9, 0, 0, optionHeight)
			optionButton.AutoButtonColor = false
			optionButton.Font = Enum.Font.GothamMedium
			optionButton.TextColor3 = Color3.fromRGB(255, 175, 175)
			optionButton.TextStrokeTransparency = 0.2
			optionButton.TextStrokeColor3 = Color3.fromRGB(110, 0, 0)
			optionButton.TextScaled = true
			optionButton.TextWrapped = true
			optionButton.ZIndex = 1
			optionButton.Parent = choiceFrame

			local optionCorner = Instance.new("UICorner")
			optionCorner.CornerRadius = UDim.new(0, 10)
			optionCorner.Parent = optionButton

			local optionConstraint = Instance.new("UITextSizeConstraint")
			optionConstraint.MinTextSize = 10
			optionConstraint.MaxTextSize = 14
			optionConstraint.Parent = optionButton

			optionButtons[item] = optionButton

			optionButton.MouseButton1Click:Connect(function()
				if multi then
					setSelectedValue(item, not selected[item])
				else
					if selected[item] then
						setSelectedValue(item, false)
					else
						setSelectedValue(item, true)
					end
				end

				refreshLabels()
				saveDropdownSelection()
				if callback then
					callback(getCallbackValue())
				end
			end)
		end

		refreshLabels()
	end

	local function setExpanded(nextState)
		local wasExpanded = expanded
		expanded = nextState == true
		optionsFrame.Visible = expanded
		toggleButton.Visible = not expanded

		local optionsHeight = 0
		local visibleOptionsHeight = 0
		if expanded then
			optionsHeight = (#items * optionHeight) + math.max(#items - 1, 0) * optionPadding
			local visibleCount = math.min(#items, maxVisibleOptions)
			visibleOptionsHeight = (visibleCount * optionHeight) + math.max(visibleCount - 1, 0) * optionPadding
		end

		optionsFrame.Size = UDim2.new(1, 0, 0, visibleOptionsHeight)
		choiceFrame.Size = UDim2.new(0.94, 0, 0, visibleOptionsHeight)
		choiceFrame.CanvasSize = UDim2.new(0, 0, 0, optionsHeight)
		if expanded and not wasExpanded then
			choiceFrame.CanvasPosition = Vector2.new(0, 0)
		elseif not expanded then
			choiceFrame.CanvasPosition = Vector2.new(0, 0)
		else
			local maxCanvasY = math.max(optionsHeight - visibleOptionsHeight, 0)
			choiceFrame.CanvasPosition = Vector2.new(0, math.clamp(choiceFrame.CanvasPosition.Y, 0, maxCanvasY))
		end
		holder.Size = UDim2.new(1, -4, 0, expanded and (expandedTopOffset + visibleOptionsHeight + 8) or collapsedHeight)

		if expanded then
			openDropdowns[dropdownState] = true
		else
			openDropdowns[dropdownState] = nil
		end

		refreshLabels()
	end

	toggleButton.MouseButton1Click:Connect(function()
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

	local dropdownControl = {
		Frame = holder,
	}

	function dropdownControl.SetItems(newItems, preferredValue, suppressCallback)
		local previousSelectedList = getSelectedList()
		local normalizedItems = normalizeValues(newItems)
		local itemsChanged = not areListsEqual(items, normalizedItems)
		local previousCanvasPosition = choiceFrame.CanvasPosition
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
		else
			refreshLabels()
		end
		setExpanded(expanded)
		if expanded then
			local visibleCount = math.min(#items, maxVisibleOptions)
			local visibleOptionsHeight = (visibleCount * optionHeight) + math.max(visibleCount - 1, 0) * optionPadding
			local optionsHeight = (#items * optionHeight) + math.max(#items - 1, 0) * optionPadding
			local maxCanvasY = math.max(optionsHeight - visibleOptionsHeight, 0)
			choiceFrame.CanvasPosition = Vector2.new(0, math.clamp(previousCanvasPosition.Y, 0, maxCanvasY))
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
	saveDropdownSelection()
	if callback then
		callback(getCallbackValue())
	end
	return dropdownControl
end

dropdown = Dropdown

local modelDropdownLookup = {}
local modelDropdownControl = nil

isSelectablePlayerDropdownTarget = function(targetPlayer)
	return targetPlayer and targetPlayer ~= player and targetPlayer.Parent == Players
end

local function isSelectableModelDropdownTarget(model)
	if not model or model == char then
		return false
	end

	if Players:GetPlayerFromCharacter(model) == player then
		return false
	end

	return isValidAttackTpTarget(model)
end

local function getModelDropdownLabelForSelection(model, targetPlayer)
	if not model and not targetPlayer then
		return nil
	end

	for label, mappedTarget in pairs(modelDropdownLookup) do
		if mappedTarget.player == targetPlayer then
			return label
		end

		if mappedTarget.player == nil and mappedTarget.model == model then
			return label
		end
	end

	return nil
end

local function buildPlayerModelDropdownItems()
	local discoveredModels = {}
	local namedEntries = {}

	for _, targetPlayer in ipairs(Players:GetPlayers()) do
		if isSelectablePlayerDropdownTarget(targetPlayer) then
			local targetModel = getTrackedPlayerTargetModel(targetPlayer)
			if targetModel then
				discoveredModels[targetModel] = true
			end

			namedEntries[#namedEntries + 1] = {
				baseName = tostring(targetPlayer.Name ~= "" and targetPlayer.Name or "Player"),
				fullName = targetPlayer:GetFullName(),
				player = targetPlayer,
				model = targetModel,
			}
		end
	end

	for _, instance in ipairs(Workspace:GetDescendants()) do
		if instance:IsA("Humanoid") and instance.Health > 0 then
			local model = instance.Parent
			if model and model:IsA("Model") and not discoveredModels[model] and isSelectableModelDropdownTarget(model) then
				discoveredModels[model] = true
				namedEntries[#namedEntries + 1] = {
					baseName = tostring(model.Name ~= "" and model.Name or "Model"),
					fullName = model:GetFullName(),
					model = model,
				}
			end
		end
	end

	table.sort(namedEntries, function(left, right)
		local leftName = string.lower(left.baseName)
		local rightName = string.lower(right.baseName)
		if leftName == rightName then
			return left.fullName < right.fullName
		end
		return leftName < rightName
	end)

	table.clear(modelDropdownLookup)

	local usedLabels = {}
	local items = {}
	for _, entry in ipairs(namedEntries) do
		local label = entry.baseName
		local suffix = 1

		while usedLabels[label] do
			suffix = suffix + 1
			label = string.format("%s (%d)", entry.baseName, suffix)
		end

		usedLabels[label] = true
		items[#items + 1] = label
		modelDropdownLookup[label] = {
			player = entry.player,
			model = entry.model,
		}
	end

	return items
end

local function applyModelDropdownSelection(selectedValue)
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
	elseif isSelectableModelDropdownTarget(selectedEntry.model) then
		setManualAttackTpTarget(selectedEntry.model)
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

local function refreshModelDropdown(preferredValue)
	if not modelDropdownControl or not modelDropdownControl.SetItems then
		return
	end

	local items = buildPlayerModelDropdownItems()
	local nextPreferredValue = preferredValue
	if hasManualAttackTpSelection() then
		nextPreferredValue = getModelDropdownLabelForSelection(resolveManualAttackTpTargetModel(), manualAttackTpPlayer)
	elseif nextPreferredValue == nil and modelDropdownControl.GetValue then
		nextPreferredValue = modelDropdownControl.GetValue()
	end

	modelDropdownControl.SetItems(items, nextPreferredValue)
	syncModelDropdownSelectionToManualTarget()
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
		if not isValidCamLockTarget(activeTarget) then
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
				stopView()
			end
			return
		end

		local activeHumanoid = activeTarget:FindFirstChildOfClass("Humanoid")
		if activeHumanoid and cam.CameraSubject ~= activeHumanoid then
			cam.CameraSubject = activeHumanoid
		end
	end)

	if not isValidCamLockTarget(targetModel) then
		return false
	end

	local targetHumanoid = targetModel:FindFirstChildOfClass("Humanoid")
	if not targetHumanoid then
		return false
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
		if not hasSelectedTargetOrPendingPlayer() or (not startView() and not isWaitingForSelectedPlayerRespawn()) then
			stopView()
		else
			viewing = true
		end
	else
		stopView()
	end

	syncTargetActionControls()
	return viewing and "ON" or "OFF"
end

local function teleportToSelectedTarget()
	if not hasSelectedTargetOrPendingPlayer() then
		return
	end
	local character = player.Character
	local characterRoot = character and character:FindFirstChild("HumanoidRootPart")
	local targetModel = resolveAttackTpTarget()
	local targetRoot = targetModel and targetModel:FindFirstChild("HumanoidRootPart")
	if not characterRoot then
		return
	end

	if not targetRoot then
		if isWaitingForSelectedPlayerRespawn() then
			pendingTeleportToSelectedPlayer = true
		end
		return
	end

	pendingTeleportToSelectedPlayer = false
	local targetCFrame = targetRoot.CFrame
	local forwardDirection = targetCFrame.LookVector   
	local distanceInFront = 4.5   
	local tpPosition = targetRoot.Position + (forwardDirection * distanceInFront)
	tpPosition = tpPosition + Vector3.new(0, 2.5, 0)
	characterRoot.CFrame = CFrame.lookAt(tpPosition, targetRoot.Position)  
	if flying and bv and bg then
		bv.Position = characterRoot.Position
		bg.CFrame = getRotationOnlyCFrame(characterRoot.CFrame)
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

	local holder = makeControlFrame(64)
	holder.Parent = uiX

	local nameLabel = Instance.new("TextLabel")
	nameLabel.BackgroundTransparency = 1
	nameLabel.Position = UDim2.fromScale(0.05, 0.2)
	nameLabel.Size = UDim2.fromScale(0.56, 0.35)
	nameLabel.Font = Enum.Font.GothamBold
	nameLabel.Text = toggleName
	nameLabel.TextColor3 = Color3.fromRGB(255, 55, 55)
	nameLabel.TextStrokeTransparency = 0.15
	nameLabel.TextStrokeColor3 = Color3.fromRGB(110, 0, 0)
	nameLabel.TextScaled = true
	nameLabel.TextWrapped = true
	nameLabel.TextXAlignment = Enum.TextXAlignment.Left
	nameLabel.Parent = holder

	local nameConstraint = Instance.new("UITextSizeConstraint")
	nameConstraint.MinTextSize = 12
	nameConstraint.MaxTextSize = 18
	nameConstraint.Parent = nameLabel

	local switchButton = Instance.new("TextButton")
	switchButton.BackgroundColor3 = Color3.fromRGB(30, 0, 0)
	switchButton.BorderSizePixel = 0
	switchButton.Position = UDim2.fromScale(0.72, 0.22)
	switchButton.Size = UDim2.fromScale(0.18, 0.36)
	switchButton.AutoButtonColor = false
	switchButton.Text = ""
	switchButton.Parent = holder

	local switchCorner = Instance.new("UICorner")
	switchCorner.CornerRadius = UDim.new(1, 0)
	switchCorner.Parent = switchButton

	local switchKnob = Instance.new("Frame")
	switchKnob.BackgroundColor3 = Color3.fromRGB(255, 190, 190)
	switchKnob.BorderSizePixel = 0
	switchKnob.Size = UDim2.fromScale(0.42, 0.76)
	switchKnob.Position = UDim2.fromScale(0.06, 0.12)
	switchKnob.Parent = switchButton

	local knobCorner = Instance.new("UICorner")
	knobCorner.CornerRadius = UDim.new(1, 0)
	knobCorner.Parent = switchKnob

	local stateLabel = Instance.new("TextLabel")
	stateLabel.BackgroundTransparency = 1
	stateLabel.Position = UDim2.fromScale(0.05, 0.56)
	stateLabel.Size = UDim2.fromScale(0.3, 0.2)
	stateLabel.Font = Enum.Font.GothamMedium
	stateLabel.TextColor3 = Color3.fromRGB(255, 150, 150)
	stateLabel.TextScaled = true
	stateLabel.TextXAlignment = Enum.TextXAlignment.Left
	stateLabel.Parent = holder

	local stateConstraint = Instance.new("UITextSizeConstraint")
	stateConstraint.MinTextSize = 10
	stateConstraint.MaxTextSize = 14
	stateConstraint.Parent = stateLabel

	local function renderToggle()
		stateLabel.Text = enabled and "ON" or "OFF"
		switchButton.BackgroundColor3 = enabled and Color3.fromRGB(160, 0, 0) or Color3.fromRGB(30, 0, 0)
		switchKnob.Position = enabled and UDim2.fromScale(0.52, 0.12) or UDim2.fromScale(0.06, 0.12)
	end

	local toggleControl = {
		Frame = holder,
	}

	function toggleControl:SetValue(nextState, suppressCallback)
		if nextState == nil then
			enabled = not enabled
		else
			enabled = nextState == true
		end

		renderToggle()
		if saveKey ~= "" then
			setSavedControlValue(saveKey, enabled)
		end
		if not suppressCallback and callback then
			callback(enabled)
		end

		return enabled
	end

	function toggleControl:GetValue()
		return enabled
	end

	function toggleControl:tog_change(nextState, suppressCallback)
		return self:SetValue(nextState, suppressCallback)
	end

	function toggleControl:Toggle(suppressCallback)
		return self:SetValue(nil, suppressCallback)
	end

	switchButton.MouseButton1Click:Connect(function()
		toggleControl:SetValue(nil)
	end)

	renderToggle()
	return toggleControl
end

_G["3tog_on_one_one_button"] = function(data)
	data = data or {}

	local titleText = tostring(data.title or "Target")
	local firstName = tostring(data.name1 or "View")
	local secondName = tostring(data.name2 or "Auto TP")
	local thirdName = tostring(data.name3 or "Fling")
	local buttonName = tostring(data.buttonName or data.name4 or "TP")
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
	titleLabel.TextColor3 = Color3.fromRGB(255, 55, 55)
	titleLabel.TextStrokeTransparency = 0.15
	titleLabel.TextStrokeColor3 = Color3.fromRGB(110, 0, 0)
	titleLabel.TextScaled = true
	titleLabel.TextWrapped = true
	titleLabel.TextXAlignment = Enum.TextXAlignment.Left
	titleLabel.Parent = holder

	local titleConstraint = Instance.new("UITextSizeConstraint")
	titleConstraint.MinTextSize = 12
	titleConstraint.MaxTextSize = 18
	titleConstraint.Parent = titleLabel

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
		segmentButton.BackgroundColor3 = Color3.fromRGB(24, 0, 0)
		segmentButton.BackgroundTransparency = 0.06
		segmentButton.BorderSizePixel = 0
		segmentButton.Size = UDim2.new(0.25, -5, 1, 0)
		segmentButton.AutoButtonColor = false
		segmentButton.Font = Enum.Font.GothamBold
		segmentButton.Text = tostring(text)
		segmentButton.TextStrokeTransparency = 0.15
		segmentButton.TextStrokeColor3 = Color3.fromRGB(110, 0, 0)
		segmentButton.TextScaled = true
		segmentButton.TextWrapped = true
		segmentButton.Parent = rowFrame

		local segmentCorner = Instance.new("UICorner")
		segmentCorner.CornerRadius = UDim.new(0, 10)
		segmentCorner.Parent = segmentButton

		local segmentConstraint = Instance.new("UITextSizeConstraint")
		segmentConstraint.MinTextSize = 10
		segmentConstraint.MaxTextSize = 14
		segmentConstraint.Parent = segmentButton

		local enabled = initialState == true

		local function render()
			if isToggle and enabled then
				segmentButton.BackgroundColor3 = Color3.fromRGB(150, 0, 0)
				segmentButton.TextColor3 = Color3.fromRGB(255, 220, 220)
			else
				segmentButton.BackgroundColor3 = Color3.fromRGB(24, 0, 0)
				segmentButton.TextColor3 = Color3.fromRGB(255, 175, 175)
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
	local buttonControl = createSegment(buttonName, false, false, buttonCallback)

	return {
		Frame = holder,
		First = firstControl,
		Second = secondControl,
		Third = thirdControl,
		Button = buttonControl,
	}
end

three_tog_on_one_one_button = _G["3tog_on_one_one_button"]

_G["4tog_on_one_frame"] = function(data)
	data = data or {}

	local titleText = tostring(data.title or "Fling")
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

	local holder = makeControlFrame(76)
	holder.Parent = uiX

	local titleLabel = Instance.new("TextLabel")
	titleLabel.BackgroundTransparency = 1
	titleLabel.Position = UDim2.new(0, 16, 0, 8)
	titleLabel.Size = UDim2.new(1, -32, 0, 18)
	titleLabel.Font = Enum.Font.GothamBold
	titleLabel.Text = titleText
	titleLabel.TextColor3 = Color3.fromRGB(255, 55, 55)
	titleLabel.TextStrokeTransparency = 0.15
	titleLabel.TextStrokeColor3 = Color3.fromRGB(110, 0, 0)
	titleLabel.TextScaled = true
	titleLabel.TextWrapped = true
	titleLabel.TextXAlignment = Enum.TextXAlignment.Left
	titleLabel.Parent = holder

	local titleConstraint = Instance.new("UITextSizeConstraint")
	titleConstraint.MinTextSize = 12
	titleConstraint.MaxTextSize = 18
	titleConstraint.Parent = titleLabel

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

	local function createToggle(text, initialState, callback)
		local button = Instance.new("TextButton")
		button.BackgroundTransparency = 0.06
		button.BorderSizePixel = 0
		button.Size = UDim2.new(0.25, -5, 1, 0)
		button.AutoButtonColor = false
		button.Font = Enum.Font.GothamBold
		button.Text = tostring(text)
		button.TextStrokeTransparency = 0.15
		button.TextStrokeColor3 = Color3.fromRGB(110, 0, 0)
		button.TextScaled = true
		button.TextWrapped = true
		button.Parent = rowFrame

		local corner = Instance.new("UICorner")
		corner.CornerRadius = UDim.new(0, 10)
		corner.Parent = button

		local constraint = Instance.new("UITextSizeConstraint")
		constraint.MinTextSize = 10
		constraint.MaxTextSize = 13
		constraint.Parent = button

		local enabled = initialState == true

		local function render()
			button.BackgroundColor3 = enabled and Color3.fromRGB(150, 0, 0) or Color3.fromRGB(24, 0, 0)
			button.TextColor3 = enabled and Color3.fromRGB(255, 220, 220) or Color3.fromRGB(255, 175, 175)
		end

		local control = {}

		function control.SetValue(nextState, suppressCallback)
			enabled = nextState == true
			render()
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
		controls[index] = createToggle(names[index], defaults[index], callbacks[index])
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
	titleLabel.TextColor3 = Color3.fromRGB(255, 55, 55)
	titleLabel.TextStrokeTransparency = 0.15
	titleLabel.TextStrokeColor3 = Color3.fromRGB(110, 0, 0)
	titleLabel.TextScaled = true
	titleLabel.TextWrapped = true
	titleLabel.TextXAlignment = Enum.TextXAlignment.Left
	titleLabel.Parent = holder

	local titleConstraint = Instance.new("UITextSizeConstraint")
	titleConstraint.MinTextSize = 12
	titleConstraint.MaxTextSize = 18
	titleConstraint.Parent = titleLabel

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
		segmentButton.BackgroundColor3 = Color3.fromRGB(24, 0, 0)
		segmentButton.BackgroundTransparency = 0.06
		segmentButton.BorderSizePixel = 0
		segmentButton.Size = UDim2.new(1 / segmentCount, -5, 1, 0)
		segmentButton.AutoButtonColor = false
		segmentButton.Font = Enum.Font.GothamBold
		segmentButton.Text = tostring(text)
		segmentButton.TextStrokeTransparency = 0.15
		segmentButton.TextStrokeColor3 = Color3.fromRGB(110, 0, 0)
		segmentButton.TextScaled = true
		segmentButton.TextWrapped = true
		segmentButton.Parent = rowFrame

		local segmentCorner = Instance.new("UICorner")
		segmentCorner.CornerRadius = UDim.new(0, 10)
		segmentCorner.Parent = segmentButton

		local segmentConstraint = Instance.new("UITextSizeConstraint")
		segmentConstraint.MinTextSize = 10
		segmentConstraint.MaxTextSize = 14
		segmentConstraint.Parent = segmentButton

		local enabled = initialState == true

		local function render()
			if isToggle and enabled then
				segmentButton.BackgroundColor3 = Color3.fromRGB(150, 0, 0)
				segmentButton.TextColor3 = Color3.fromRGB(255, 220, 220)
			else
				segmentButton.BackgroundColor3 = Color3.fromRGB(24, 0, 0)
				segmentButton.TextColor3 = Color3.fromRGB(255, 175, 175)
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
	actionButton.BackgroundColor3 = Color3.fromRGB(28, 0, 0)
	actionButton.BackgroundTransparency = 0.05
	actionButton.BorderSizePixel = 0
	actionButton.Position = UDim2.fromScale(0.05, 0.16)
	actionButton.Size = UDim2.fromScale(0.9, 0.56)
	actionButton.AutoButtonColor = false
	actionButton.Font = Enum.Font.GothamBold
	actionButton.Text = buttonName
	actionButton.TextColor3 = Color3.fromRGB(255, 170, 170)
	actionButton.TextStrokeTransparency = 0.15
	actionButton.TextStrokeColor3 = Color3.fromRGB(110, 0, 0)
	actionButton.TextScaled = true
	actionButton.TextWrapped = true
	actionButton.Parent = holder

	local actionCorner = Instance.new("UICorner")
	actionCorner.CornerRadius = UDim.new(0, 12)
	actionCorner.Parent = actionButton

	local actionConstraint = Instance.new("UITextSizeConstraint")
	actionConstraint.MinTextSize = 12
	actionConstraint.MaxTextSize = 18
	actionConstraint.Parent = actionButton

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
updateTargetDisplay()

hum.Died:Connect(handleCharacterDeath)

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
	saveKey = "model",
	inside = {},
	multi = false,
	deffultin = nil,
	fun = function(value)
		applyModelDropdownSelection(value)
	end,
})

targetActionControls = _G["3tog_on_one_one_button"]({
	title = "Target",
	name1 = "View",
	name2 = "Auto TP",
	name3 = "Fling",
	buttonName = "TP",
	default1 = viewing,
	default2 = autoTpEnabled,
	default3 = flingEnabled,
	fun1 = function(enabled)
		if enabled and not hasSelectedTargetOrPendingPlayer() then
			targetActionControls.First.SetValue(false, true)
			return
		end

		toggleView(enabled)
	end,
	fun2 = function(enabled)
		if enabled and not hasSelectedTargetOrPendingPlayer() then
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
		if enabled and not hasSelectedTargetOrPendingPlayer() then
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
	buttonfun = function()
		if not hasSelectedTargetOrPendingPlayer() then
			return
		end

		teleportToSelectedTarget()
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
	min = 10,
	default = auraRange,
	saveKey = "AuraRange",
	fun = function(value)
		auraRange = value
	end,
})

flingModeControls = _G["4tog_on_one_frame"]({
	title = "Fling",
	name1 = "Noraml Walkfling",
	name2 = "Aura Fling",
	name3 = "Click Fling",
	name4 = "Fling All",
	default1 = walkFlingUseNormal,
	default2 = auraFlingEnabled,
	default3 = clickFlingEnabled,
	default4 = flingAllEnabled,
	fun1 = function(enabled)
		walkFlingUseNormal = enabled
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

safeZone.toggleControl = tog({
	name = "Safe Zone",
	default = safeZone.enabled,
	saveKey = "AutoSafeZone",
	fun = function(enabled)
		safeZone.enabled = enabled
		if not enabled then
			if safeZone.atDestination and safeZone.savedCFrame then
				startSafeZoneTravel(safeZone.savedCFrame, "return", function()
					safeZone.atDestination = false
					safeZone.savedCFrame = nil
				end)
			else
				stopSafeZoneTravel()
			end
		end
	end,
})
safeZone.toggleControl.Frame.LayoutOrder = 10000

parseWalkFlingDirectionSelection(getSavedControlValue("WalkFlingDirection") or { "Forward" })
syncFlingModeControls()

refreshModelDropdown(getSavedControlValue("model"))

task.spawn(function()
	while screenGui.Parent do
		task.wait(1)
		refreshModelDropdown()
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
		settingsWindow.Position = UDim2.new(
			dragStartPosition.X.Scale,
			dragStartPosition.X.Offset + delta.X,
			dragStartPosition.Y.Scale,
			dragStartPosition.Y.Offset + delta.Y
		)
		windowOutline.Position = settingsWindow.Position
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

	if gameProcessed then
		return
	end

	local key = input.KeyCode

	if key == Enum.KeyCode.Comma then
		setSettingsVisible(not settingsOpen)
		return
	end

	if key == speedKeybind then
		toggleSpeed()
		return
	end

	if key == flyKeybind then
		toggleFly()
		return
	end

	if key == camLockKeybind then
		toggleCamLock()
		return
	end

	if key == attackTpKeybind then
		toggleAttackTp()
		return
	end

	if key == targetSelectKeybind then
		toggleMouseTargetSelection()
		return
	end

	if key == walkFlingKeybind then
		setWalkFlingEnabled()
		return
	end

	if key == setBackKeybind then
		handleSetBackKeybind()
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

player.CharacterAdded:Connect(function(newChar)
	stopSafeZoneTravel()
	safeZone.savedCFrame = nil
	safeZone.atDestination = false
	char = newChar
	hum = newChar:WaitForChild("Humanoid")
	root = newChar:WaitForChild("HumanoidRootPart")
	cam = Workspace.CurrentCamera
	handleCharacterDeath()
	hum.Died:Connect(handleCharacterDeath)
end)

task.spawn(function()
	while true do
		local dt = task.wait()

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

task.spawn(function()
	while true do
		task.wait()

		if camLockEnabled then
			cam = Workspace.CurrentCamera or cam
			if cam then
				if not isValidCamLockTarget(camLockTarget) then
					camLockTarget = nil
					camLockTarget = getCamLockTarget()
				end

				if not isValidCamLockTarget(camLockTarget) then
					camLockWaiting = true
					syncCamLockKeybindDisplay()
					syncTargetPickKeybindDisplay()
					updateTargetDisplay()
				else
					camLockWaiting = false
					syncCamLockKeybindDisplay()
					syncTargetPickKeybindDisplay()
					updateTargetDisplay()

					local targetRoot = camLockTarget:FindFirstChild("HumanoidRootPart")
					if not targetRoot then
						camLockWaiting = true
						syncCamLockKeybindDisplay()
						syncTargetPickKeybindDisplay()
						updateTargetDisplay()
					else
						local cameraPosition = cam.CFrame.Position
						cam.CFrame = CFrame.lookAt(cameraPosition, targetRoot.Position, targetRoot.CFrame.UpVector)
					end
				end
			end
		end
	end
end)

task.spawn(function()
	while true do
		task.wait(0.15)
		updateTargetDisplay()
	end
end)

task.spawn(function()
	while true do
		task.wait()

		if (viewing or autoTpEnabled or flingEnabled) and not hasSelectedTargetOrPendingPlayer() then
			if viewing then
				stopView()
			end
			autoTpEnabled = false
			flingEnabled = false
			syncTargetActionControls()
		end

		if viewing and not isValidCamLockTarget(currentViewTarget) then
			if currentViewPlayer and currentViewPlayer.Parent == Players then
				local newViewTarget = getTrackedPlayerTargetModel(currentViewPlayer)
				if isValidCamLockTarget(newViewTarget) then
					currentViewTarget = newViewTarget
					local newViewHumanoid = newViewTarget:FindFirstChildOfClass("Humanoid")
					if newViewHumanoid and cam then
						cam.CameraSubject = newViewHumanoid
					end
				else
					stopView()
				end
			else
				stopView()
			end
		end

		if not autoTpEnabled then
			if pendingTeleportToSelectedPlayer and isValidAttackTpTarget(resolveAttackTpTarget()) then
				teleportToSelectedTarget()
			end
		elseif not flingEnabled then
			local character = player.Character
			local characterRoot = character and character:FindFirstChild("HumanoidRootPart")
			if characterRoot then
				local targetModel = resolveAttackTpTarget()
				if isValidAttackTpTarget(targetModel) then
					local targetCFrame, targetVelocity = getAttackTpPlacement(characterRoot, targetModel)
					if targetCFrame then
						characterRoot.CFrame = targetCFrame
						characterRoot.AssemblyLinearVelocity = targetVelocity or Vector3.zero
						if pendingTeleportToSelectedPlayer then
							teleportToSelectedTarget()
						end

						if flying and bv and bg then
							bv.Position = characterRoot.Position
							bg.CFrame = getRotationOnlyCFrame(targetCFrame)
						end
					elseif pendingTeleportToSelectedPlayer and isValidAttackTpTarget(targetModel) then
						teleportToSelectedTarget()
					end
				end
			end
		elseif pendingTeleportToSelectedPlayer and isValidAttackTpTarget(resolveAttackTpTarget()) then
			teleportToSelectedTarget()
		end

		if attackTpEnabled and attackTpHolding then
			local character = player.Character
			local characterRoot = character and character:FindFirstChild("HumanoidRootPart")
			if characterRoot then
				if not manualAttackTpPlayer and manualAttackTpTarget and not isValidAttackTpTarget(manualAttackTpTarget) then
					manualAttackTpTarget = nil
					if syncModelDropdownSelectionToManualTarget then
						syncModelDropdownSelectionToManualTarget()
					end
					syncTargetPickKeybindDisplay()
					updateTargetDisplay()
				end

				if not isValidAttackTpTarget(attackTpTarget) then
					attackTpTarget = nil
				end

				local preferredTarget = resolveAttackTpTarget()
				if preferredTarget then
					attackTpTarget = preferredTarget
				end

				if isValidAttackTpTarget(attackTpTarget) then
					local targetCFrame, targetVelocity = getAttackTpPlacement(characterRoot, attackTpTarget)
					if targetCFrame and targetVelocity then
						characterRoot.CFrame = targetCFrame
						characterRoot.AssemblyLinearVelocity = targetVelocity

						if flying and bv and bg then
							bv.Position = characterRoot.Position
							bg.CFrame = getRotationOnlyCFrame(targetCFrame)
						end
					else
						attackTpTarget = nil
					end
				end
			end
		end
	end
end)

task.spawn(function()
	while true do
		task.wait()

		if safeZone.enabled then
			local character = player.Character
			local characterRoot = character and character:FindFirstChild("HumanoidRootPart")
			local humanoid = character and character:FindFirstChildOfClass("Humanoid")
			if characterRoot and humanoid and humanoid.Health > 0 then
				if safeZone.atDestination and safeZone.savedCFrame and humanoid.Health >= safeZone.returnHp and safeZone.travelMode ~= "return" then
					startSafeZoneTravel(safeZone.savedCFrame, "return", function()
						safeZone.atDestination = false
						safeZone.savedCFrame = nil
						safeZone.pointCurrent = safeZone.pointStart
						showInfo("SAFE ZONE", "Returned to saved position", 2)
					end)
				elseif humanoid.Health <= safeZone.lowHp and not safeZone.atDestination and safeZone.travelMode ~= "to_safe" and canSaveSafeZonePosition(character, characterRoot, humanoid) then
					safeZone.savedCFrame = getUprightSetBackCFrame(characterRoot.Position, characterRoot.CFrame)
					safeZone.pointCurrent = safeZone.pointStart
					safeZone.atDestination = true
					showInfo("SAFE ZONE", "Low HP detected", 2)
				elseif safeZone.atDestination and safeZone.savedCFrame then
					local safeDestination = getSafeZoneDestination(safeZone.savedCFrame)
					startSafeZoneTravel(safeDestination, "to_safe")
					safeZone.pointCurrent = math.clamp(safeZone.pointCurrent + safeZone.pointAdd, safeZone.pointStart, safeZone.pointMax)
				end
			end
		elseif safeZone.atDestination and safeZone.savedCFrame and safeZone.travelMode ~= "return" then
			startSafeZoneTravel(safeZone.savedCFrame, "return", function()
				safeZone.atDestination = false
				safeZone.savedCFrame = nil
				safeZone.pointCurrent = safeZone.pointStart
			end)
		end
	end
end)

UserInputService.InputEnded:Connect(function(input)
	local key = input.KeyCode

	if input.UserInputType == Enum.UserInputType.MouseButton1 then
		attackTpHolding = false
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

function startIntroUi()
	local topLabel = Instance.new("TextLabel")
	topLabel.Name = "MainTitle"
	topLabel.AnchorPoint = Vector2.new(0.5, 0.5)
	topLabel.Position = UDim2.fromScale(0.5, 0.47)
	topLabel.Size = UDim2.fromScale(0.82, 0.16)
	topLabel.BackgroundTransparency = 1
	topLabel.Text = "NOTHING X"
	topLabel.TextColor3 = Color3.fromRGB(255, 30, 30)
	topLabel.TextStrokeTransparency = 0
	topLabel.TextStrokeColor3 = Color3.fromRGB(120, 0, 0)
	topLabel.Font = Enum.Font.GothamBlack
	topLabel.TextScaled = true
	topLabel.Parent = background

	local topConstraint = Instance.new("UITextSizeConstraint")
	topConstraint.MinTextSize = 28
	topConstraint.MaxTextSize = 96
	topConstraint.Parent = topLabel

	local subtitleLabel = Instance.new("TextLabel")
	subtitleLabel.Name = "SubTitle"
	subtitleLabel.AnchorPoint = Vector2.new(0.5, 0.5)
	subtitleLabel.Position = UDim2.fromScale(0.5, 0.58)
	subtitleLabel.Size = UDim2.fromScale(0.3, 0.06)
	subtitleLabel.BackgroundTransparency = 1
	subtitleLabel.Text = "_X"
	subtitleLabel.TextColor3 = Color3.fromRGB(255, 70, 70)
	subtitleLabel.TextStrokeTransparency = 0.15
	subtitleLabel.TextStrokeColor3 = Color3.fromRGB(110, 0, 0)
	subtitleLabel.Font = Enum.Font.GothamSemibold
	subtitleLabel.TextScaled = true
	subtitleLabel.Parent = background

	local subtitleConstraint = Instance.new("UITextSizeConstraint")
	subtitleConstraint.MinTextSize = 16
	subtitleConstraint.MaxTextSize = 40
	subtitleConstraint.Parent = subtitleLabel

	local titlePulse = TweenService:Create(
		topLabel,
		TweenInfo.new(1.8, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true),
		{
			TextColor3 = Color3.fromRGB(255, 90, 90),
		}
	)

	local subtitlePulse = TweenService:Create(
		subtitleLabel,
		TweenInfo.new(1.8, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true),
		{
			TextColor3 = Color3.fromRGB(255, 90, 90),
		}
	)

	titlePulse:Play()
	subtitlePulse:Play()

	task.delay(3, function()
		titlePulse:Cancel()
		subtitlePulse:Cancel()

		local fadeInfo = TweenInfo.new(2.5, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)

		TweenService:Create(background, fadeInfo, {
			BackgroundTransparency = 1,
		}):Play()

		TweenService:Create(subtitleLabel, fadeInfo, {
			TextTransparency = 1,
			TextStrokeTransparency = 1,
		}):Play()

		local fadeTitle = TweenService:Create(topLabel, fadeInfo, {
			TextTransparency = 1,
			TextStrokeTransparency = 1,
		})
		fadeTitle:Play()
		fadeTitle.Completed:Connect(function()
			topLabel:Destroy()
			subtitleLabel:Destroy()
			background:Destroy()
			introFinished = true

			keybindFrame.Visible = true
			targetFrame.Visible = true
			updateTargetDisplay()

			TweenService:Create(keybindFrame, TweenInfo.new(1.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
				BackgroundTransparency = 0.5,
			}):Play()

			TweenService:Create(leftStroke, TweenInfo.new(1.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
				Transparency = 0.1,
			}):Play()

			TweenService:Create(
				leftStroke,
				TweenInfo.new(1.6, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true),
				{
					Thickness = 5,
					Transparency = 0.35,
				}
			):Play()

			if pendingInfoCall then
				local queuedInfo = pendingInfoCall
				pendingInfoCall = nil
				showInfo(queuedInfo.title, queuedInfo.text, queuedInfo.time)
			end
		end)
	end)
end

startIntroUi()
