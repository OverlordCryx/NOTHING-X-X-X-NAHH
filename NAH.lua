repeat
    task.wait();
until game:IsLoaded();
local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local GuiService = game:GetService("GuiService")
local RunService = game:GetService("RunService")
local HttpService = game:GetService("HttpService")
local Workspace = game:GetService("Workspace")
local CoreGui = game:GetService("CoreGui")
local function nextFrame()
	return RunService.Heartbeat:Wait()
end
task.spawn(function()
    local Lighting = game:GetService("Lighting")
    Lighting.GlobalShadows = false
    Lighting.FogEnd = 9e9
    Lighting.Brightness = 2 
    for _, effect in ipairs(Lighting:GetChildren()) do
        if effect:IsA("PostEffect") or effect:IsA("BloomEffect") or effect:IsA("BlurEffect") or effect:IsA("SunRaysEffect") then
            effect.Enabled = false
        end
    end
end)
local function overpowerRootState(rootPart, targetCFrame, linearVelocity, angularVelocity)
	if not rootPart or not rootPart.Parent or not targetCFrame then
		return
	end
	local resolvedLinearVelocity = linearVelocity or Vector3.zero
	local resolvedAngularVelocity = angularVelocity or Vector3.zero
	local function apply()
		if not rootPart or not rootPart.Parent then
			return
		end
		rootPart.CFrame = targetCFrame
		rootPart.AssemblyLinearVelocity = resolvedLinearVelocity
		rootPart.AssemblyAngularVelocity = resolvedAngularVelocity
	end
	apply()
	task.defer(apply)
	task.defer(function()
		task.defer(apply)
	end)
	task.spawn(function()
		if not rootPart or not rootPart.Parent then
			return
		end
		RunService.Stepped:Wait()
		apply()
		if not rootPart or not rootPart.Parent then
			return
		end
		RunService.RenderStepped:Wait()
		apply()
		for _ = 1, 2 do
			if not rootPart or not rootPart.Parent then
				return
			end
			nextFrame()
			apply()
		end
	end)
end
local function applyTeleportRootState(rootPart, targetCFrame, linearVelocity)
	if not rootPart or not rootPart.Parent or not targetCFrame then
		return
	end
	overpowerRootState(rootPart, targetCFrame, linearVelocity or Vector3.zero, Vector3.zero)
end
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
local mainScale = Instance.new("UIScale")
mainScale.Name = "MainScale"
mainScale.Parent = screenGui
local function updateGlobalScale()
	local viewportSize = Workspace.CurrentCamera and Workspace.CurrentCamera.ViewportSize or Vector2.new(1920, 1080)
	local baseResolution = Vector2.new(1920, 1080)
	local scaleX = viewportSize.X / baseResolution.X
	local scaleY = viewportSize.Y / baseResolution.Y
	local finalScale = math.min(scaleX, scaleY)
	mainScale.Scale = math.clamp(finalScale, 0.6, 1.4)
end
task.spawn(function()
	updateGlobalScale()
	Workspace.CurrentCamera:GetPropertyChangedSignal("ViewportSize"):Connect(updateGlobalScale)
end)
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
keybindFrame.Size = UDim2.fromScale(0.1, 0.14)
keybindFrame.BackgroundColor3 = Color3.fromRGB(15, 0, 0)
keybindFrame.BackgroundTransparency = 0.4
keybindFrame.BorderSizePixel = 0
keybindFrame.Visible = false
keybindFrame.AutomaticSize = Enum.AutomaticSize.XY
do
	local keybindSizeConstraint = Instance.new("UISizeConstraint")
	keybindSizeConstraint.MinSize = Vector2.new(120, 40)
	keybindSizeConstraint.MaxSize = Vector2.new(280, 500)
	keybindSizeConstraint.Parent = keybindFrame
end
local keybindPadding = Instance.new("UIPadding")
keybindPadding.PaddingTop = UDim.new(0, 8)
keybindPadding.PaddingBottom = UDim.new(0, 8)
keybindPadding.PaddingLeft = UDim.new(0, 10)
keybindPadding.PaddingRight = UDim.new(0, 10)
keybindPadding.Parent = keybindFrame
keybindFrame.Parent = screenGui
local leftStroke = Instance.new("UIStroke")
leftStroke.Color = Color3.fromRGB(255, 0, 0)
leftStroke.Thickness = 3
leftStroke.Transparency = 1
leftStroke.Parent = keybindFrame
do
	local leftCorner = Instance.new("UICorner")
	leftCorner.CornerRadius = UDim.new(0, 18)
	leftCorner.Parent = keybindFrame
	local leftGradient = Instance.new("UIGradient")
	leftGradient.Color = ColorSequence.new({
		ColorSequenceKeypoint.new(0, Color3.fromRGB(0, 0, 0)),
		ColorSequenceKeypoint.new(0.35, Color3.fromRGB(70, 0, 0)),
		ColorSequenceKeypoint.new(1, Color3.fromRGB(255, 0, 0)),
	})
	leftGradient.Rotation = 90
	leftGradient.Parent = keybindFrame
end
local keybindText = Instance.new("TextLabel")
keybindText.Name = "KeybindText"
keybindText.AnchorPoint = Vector2.new(0, 0)
keybindText.Position = UDim2.fromScale(0, 0)
keybindText.Size = UDim2.new(1, 0, 0, 0)
keybindText.AutomaticSize = Enum.AutomaticSize.Y
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
do
	local keybindTextConstraint = Instance.new("UITextSizeConstraint")
	keybindTextConstraint.MinTextSize = 12
	keybindTextConstraint.MaxTextSize = 24
	keybindTextConstraint.Parent = keybindText
end
local targetFrame = Instance.new("Frame")
targetFrame.Name = "TargetFrame"
targetFrame.AnchorPoint = Vector2.new(0.5, 0)
targetFrame.Position = UDim2.fromScale(0.5, 0.025)
targetFrame.Size = UDim2.fromScale(0.1, 0.02)
targetFrame.BackgroundColor3 = Color3.fromRGB(20, 0, 0)
targetFrame.BackgroundTransparency = 0.5
targetFrame.BorderSizePixel = 0
targetFrame.Visible = false
targetFrame.AutomaticSize = Enum.AutomaticSize.XY
do
	local targetSizeConstraint = Instance.new("UISizeConstraint")
	targetSizeConstraint.MinSize = Vector2.new(100, 30)
	targetSizeConstraint.Parent = targetFrame
end
local targetPadding = Instance.new("UIPadding")
targetPadding.PaddingLeft = UDim.new(0, 12)
targetPadding.PaddingRight = UDim.new(0, 12)
targetPadding.Parent = targetFrame
targetFrame.Parent = screenGui
do
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
end
local targetValueText = Instance.new("TextLabel")
targetValueText.Name = "TargetValue"
targetValueText.AnchorPoint = Vector2.new(0, 0)
targetValueText.Position = UDim2.fromScale(0, 0)
targetValueText.Size = UDim2.new(1, 0, 1, 0)
targetValueText.AutomaticSize = Enum.AutomaticSize.XY
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
do
	local targetValueConstraint = Instance.new("UITextSizeConstraint")
	targetValueConstraint.MinTextSize = 12
	targetValueConstraint.MaxTextSize = 20
	targetValueConstraint.Parent = targetValueText
end
local infoContainer = Instance.new("Frame")
infoContainer.Name = "InfoContainer"
infoContainer.AnchorPoint = Vector2.new(0.5, 0)
infoContainer.Position = UDim2.fromScale(0.5, 0.08)
infoContainer.Size = UDim2.fromScale(0.25, 0)
infoContainer.AutomaticSize = Enum.AutomaticSize.Y
infoContainer.BackgroundColor3 = Color3.fromRGB(15, 0, 0)
infoContainer.BackgroundTransparency = 1
infoContainer.Visible = false
do
	local infoSizeConstraint = Instance.new("UISizeConstraint")
	infoSizeConstraint.MinSize = Vector2.new(220, 0)
	infoSizeConstraint.MaxSize = Vector2.new(450, 250)
	infoSizeConstraint.Parent = infoContainer
end
local infoPadding = Instance.new("UIPadding")
infoPadding.PaddingTop = UDim.new(0, 10)
infoPadding.PaddingBottom = UDim.new(0, 10)
infoPadding.PaddingLeft = UDim.new(0, 15)
infoPadding.PaddingRight = UDim.new(0, 15)
infoPadding.Parent = infoContainer
local infoListLayout = Instance.new("UIListLayout")
infoListLayout.Padding = UDim.new(0, 5)
infoListLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
infoListLayout.SortOrder = Enum.SortOrder.LayoutOrder
infoListLayout.Parent = infoContainer
infoContainer.Parent = screenGui
local infoStroke = Instance.new("UIStroke")
infoStroke.Color = Color3.fromRGB(255, 0, 0)
infoStroke.Thickness = 3
infoStroke.Transparency = 1
infoStroke.Parent = infoContainer
do
	local infoCorner = Instance.new("UICorner")
	infoCorner.CornerRadius = UDim.new(0, 18)
	infoCorner.Parent = infoContainer
	local infoGradient = Instance.new("UIGradient")
	infoGradient.Color = ColorSequence.new({
		ColorSequenceKeypoint.new(0, Color3.fromRGB(0, 0, 0)),
		ColorSequenceKeypoint.new(0.35, Color3.fromRGB(70, 0, 0)),
		ColorSequenceKeypoint.new(1, Color3.fromRGB(255, 0, 0)),
	})
	infoGradient.Rotation = 90
	infoGradient.Parent = infoContainer
end
local infoTitle = Instance.new("TextLabel")
infoTitle.Name = "InfoTitle"
infoTitle.AnchorPoint = Vector2.new(0, 0)
infoTitle.Position = UDim2.fromScale(0, 0)
infoTitle.Size = UDim2.new(1, 0, 0, 0)
infoTitle.AutomaticSize = Enum.AutomaticSize.Y
infoTitle.BackgroundTransparency = 1
infoTitle.Text = ""
infoTitle.TextColor3 = Color3.fromRGB(255, 30, 30)
infoTitle.TextStrokeTransparency = 0
infoTitle.TextStrokeColor3 = Color3.fromRGB(120, 0, 0)
infoTitle.Font = Enum.Font.GothamBlack
infoTitle.TextScaled = true
infoTitle.TextWrapped = true
infoTitle.AutomaticSize = Enum.AutomaticSize.Y
infoTitle.LayoutOrder = 1
infoTitle.Parent = infoContainer
do
	local infoTitleConstraint = Instance.new("UITextSizeConstraint")
	infoTitleConstraint.MinTextSize = 14
	infoTitleConstraint.MaxTextSize = 22
	infoTitleConstraint.Parent = infoTitle
end
local infoText = Instance.new("TextLabel")
infoText.Name = "InfoText"
infoText.AnchorPoint = Vector2.new(0, 0)
infoText.Position = UDim2.fromScale(0, 0)
infoText.Size = UDim2.new(1, 0, 0, 0)
infoText.AutomaticSize = Enum.AutomaticSize.Y
infoText.BackgroundTransparency = 1
infoText.Text = ""
infoText.TextColor3 = Color3.fromRGB(255, 110, 110)
infoText.TextStrokeTransparency = 0.2
infoText.TextStrokeColor3 = Color3.fromRGB(100, 0, 0)
infoText.Font = Enum.Font.GothamBold
infoText.TextScaled = true
infoText.TextWrapped = true
infoText.AutomaticSize = Enum.AutomaticSize.Y
infoText.LayoutOrder = 2
infoText.Parent = infoContainer
do
	local infoTextConstraint = Instance.new("UITextSizeConstraint")
	infoTextConstraint.MinTextSize = 12
	infoTextConstraint.MaxTextSize = 18
	infoTextConstraint.Parent = infoText
end
local settingsWindow = Instance.new("Frame")
settingsWindow.Name = "WindowUI"
settingsWindow.AnchorPoint = Vector2.new(0.5, 0.5)
settingsWindow.Position = UDim2.fromScale(0.5, 0.57)
settingsWindow.Size = UDim2.fromScale(0.22, 0.45)
do
	local windowSizeConstraint = Instance.new("UISizeConstraint")
	windowSizeConstraint.MinSize = Vector2.new(280, 350)
	windowSizeConstraint.MaxSize = Vector2.new(450, 800)
	windowSizeConstraint.Parent = settingsWindow
end
do
	local windowAspectRatio = Instance.new("UIAspectRatioConstraint")
	windowAspectRatio.AspectRatio = 0.72
	windowAspectRatio.DominantAxis = Enum.DominantAxis.Height
	windowAspectRatio.Parent = settingsWindow
end
settingsWindow.BackgroundColor3 = Color3.fromRGB(12, 0, 0)
settingsWindow.BackgroundTransparency = 1
settingsWindow.BorderSizePixel = 0
settingsWindow.Visible = false
settingsWindow.Active = true
settingsWindow.ZIndex = 10
settingsWindow.Parent = screenGui
do
	local windowSizeConstraint = Instance.new("UISizeConstraint")
	windowSizeConstraint.MinSize = Vector2.new(280, 350)
	windowSizeConstraint.Parent = settingsWindow
end
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
do
	local windowOutlineCorner = Instance.new("UICorner")
	windowOutlineCorner.CornerRadius = UDim.new(0, 18)
	windowOutlineCorner.Parent = windowOutline
end
local windowOutlineStroke = Instance.new("UIStroke")
windowOutlineStroke.Color = Color3.fromRGB(255, 0, 0)
windowOutlineStroke.Thickness = 2
windowOutlineStroke.Transparency = 0
windowOutlineStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
windowOutlineStroke.Parent = windowOutline
local settingsStroke = Instance.new("UIStroke")
settingsStroke.Color = Color3.fromRGB(255, 0, 0)
settingsStroke.Thickness = 3
settingsStroke.Transparency = 1
settingsStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
settingsStroke.Parent = settingsWindow
do
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
	local settingsGradient = Instance.new("UIGradient")
	settingsGradient.Color = ColorSequence.new({
		ColorSequenceKeypoint.new(0, Color3.fromRGB(0, 0, 0)),
		ColorSequenceKeypoint.new(0.45, Color3.fromRGB(55, 0, 0)),
		ColorSequenceKeypoint.new(1, Color3.fromRGB(155, 0, 0)),
	})
	settingsGradient.Rotation = 90
	settingsGradient.Parent = settingsWindow
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
end
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
do
	local settingsLayout = Instance.new("UIListLayout")
	settingsLayout.Padding = UDim.new(0, 10)
	settingsLayout.SortOrder = Enum.SortOrder.LayoutOrder
	settingsLayout.Parent = uiX
end
task.spawn(function()
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local LocalPlayer = Players.LocalPlayer
local connection = nil
local function startAntiFling()
    if connection then
        connection:Disconnect()
    end
    connection = RunService.Heartbeat:Connect(function()
        for _, player in ipairs(Players:GetPlayers()) do
            if player ~= LocalPlayer and player.Character then
                for _, part in ipairs(player.Character:GetChildren()) do
                    if part:IsA("BasePart") then
                        part.CanCollide = false
                        if part.CustomPhysicalProperties then
                            part.CustomPhysicalProperties = PhysicalProperties.new(0, 0.3, 0.5, 0, 0)
                        end
                    end
                end
            end
        end
    end)
end
startAntiFling()
LocalPlayer.CharacterAdded:Connect(function()
    task.wait(0.6)           
    startAntiFling()
end)
task.spawn(function()
    while task.wait(5) do
        if not connection or connection.Connected == false then
            startAntiFling()
        end
    end
end)
print("✅")
end)
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
local localCharacterDiedConnection = nil
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
	targetDisplayAccumulator = 0,
}
local function isSafeZoneBlocking()
	return _G.SafeTeleportLock == true or (safeZone and (safeZone.travelMode ~= nil or safeZone.atDestination == true))
end
local normalizeSafeZoneSigned
local normalizeSafeZonePositive
local camLockEnabled = false
local camLockTarget = nil
local camLockWaiting = false
local camLockAcquireRadius = 120
local manualTargetAcquireRadius = 130
local attackTpEnabled = false
local attackTpTarget = nil
local lastTargetDeathTime = 0
local manualAttackTpTarget = nil
local manualAttackTpPlayer = nil
local attackTpHolding = false
local attackTpMode = "Behind"
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
local customOffsets = {
	["Custom 1"] = { x = 0, y = 0, z = 0 },
	["Custom 2"] = { x = 0, y = 0, z = 0 },
	["Custom 3"] = { x = 0, y = 0, z = 0 },
	["Custom 4"] = { x = 0, y = 0, z = 0 },
	["Custom 5"] = { x = 0, y = 0, z = 0 },
	["Custom 6"] = { x = 0, y = 0, z = 0 },
	["Custom 7"] = { x = 0, y = 0, z = 0 },
	["Custom 8"] = { x = 0, y = 0, z = 0 },
	["Custom 9"] = { x = 0, y = 0, z = 0 },
	["Custom 10"] = { x = 0, y = 0, z = 0 },
}
local function getCustomDisplayName(i)
	local key = "Custom " .. tostring(i)
	local off = customOffsets[key] or { x = 0, y = 0, z = 0 }
	return string.format("Custom %s (%s,%s,%s)", tostring(i), tostring(off.z), tostring(off.y), tostring(off.x))
end
local worldUpVector = Vector3.new(0, 1, 0)
local placesTPs = {
	["Middle Of Map"] = CFrame.new(139, 440, 32),
	["Prison"] = CFrame.new(438, 439, -376),
	["Montain 1"] = CFrame.new(-15, 653, -388),
	["Montain 2"] = CFrame.new(322, 671, 446),
	["Montain 2 Left"] = CFrame.new(240, 699, 465),
	["Montain 2 Right"] = CFrame.new(398, 699, 404),
	["Counter"] = CFrame.new(-68, 39, 20346),
	["Counter Up"] = CFrame.new(-78, 94, 20354),
	["Atomic Base"] = CFrame.new(1063, 40, 23006),
	["Atomic Base Up"] = CFrame.new(1063, 415, 23006),
	["Atomic Slash"] = CFrame.new(1063, 141, 23006),
	["Atomic Slash Up"] = CFrame.new(1063, 190, 23006),
}
local placesOrder = {
	"Middle Of Map", "Prison", "Montain 1", "Montain 2", "Montain 2 Left", "Montain 2 Right",
	"Counter", "Counter Up", "Atomic Base", "Atomic Base Up",
	"Atomic Slash", "Atomic Slash Up"
}
local placesDropdown = nil
local movementPanel = nil
local selectedPlace = nil
local autoTpEnabled = false
local flingEnabled = false
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
local viewing = false
local currentViewTarget = nil
local currentViewPlayer = nil
local viewDied = nil
local viewChanged = nil
pendingTeleportToSelectedPlayer = false
local targetActionControls = nil
local flingModeControls = nil
local resolveAttackTpTarget
local zeroLocalPlayerRoot
local syncFlingModeControls
local runGetTrash
local function encodeKeybindValue(keyCode)
	if not keyCode then
		return ""
	end
	if keyCode == Enum.KeyCode.LeftAlt then
		return "Alt"
	end
	return keyCode.Name or ""
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
if type(controlSaveData.WalkFlingUseNormal) == "boolean" then
	walkFlingUseNormal = controlSaveData.WalkFlingUseNormal
end
if type(controlSaveData.AutoSafeZone) == "boolean" then
	safeZone.enabled = controlSaveData.AutoSafeZone
end
if type(controlSaveData.AttackTpMode) == "string" then
	attackTpMode = controlSaveData.AttackTpMode
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
	local orderedKeys = { "Speed", "Fly", "CamLock", "AttackTP", "TargetPick", "WalkFling", "SetBack", "GetTrash", "Custom", "Places" }
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
local function hasMapMainPart()
	local map = Workspace:FindFirstChild("Map")
	return map and map:FindFirstChild("MainPart") ~= nil
end
local lastHasMainState = nil
local function syncPlacesKeybindDisplay()
	if game.GameId ~= 3808081382 then return end
	local hasMain = hasMapMainPart()
	if hasMain ~= lastHasMainState then
		lastHasMainState = hasMain
		local mapPlaces = { 	"Middle Of Map", "Prison", "Montain 1", "Montain 2", "Montain 2 Left", "Montain 2 Right", }
		local otherPlaces = { "Counter", "Counter Up", "Atomic Base", "Atomic Base Up", "Atomic Slash", "Atomic Slash Up" }
		local currentItems = {}
		if hasMain then
			for _, v in ipairs(mapPlaces) do table.insert(currentItems, v) end
		end
		for _, v in ipairs(otherPlaces) do table.insert(currentItems, v) end
		if placesDropdown then
			placesDropdown.SetItems(currentItems)
		end
	end
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
	if not selectedPlace then
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
local function syncMovementDisplay()
	if not movementPanel then return end
	local hasMain = hasMapMainPart()
	if hasMain ~= lastHasMainMovementState then
		lastHasMainMovementState = hasMain
		if movementPanel.Button3 and movementPanel.Button3.Button then
			movementPanel.Button3.Button.Visible = hasMain
		end
	end
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
local function syncGetTrashKeybindDisplay()
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
	if walkFlingEnabled == nextState then
		syncWalkFlingKeybindDisplay()
		return walkFlingEnabled and "ON" or "OFF"
	end
	walkFlingEnabled = nextState
	if walkFlingEnabled then
		walkFlingTaskToken += 1
		local currentToken = walkFlingTaskToken
		task.spawn(function()
			local moveOffset = 0.1
			while walkFlingEnabled and walkFlingTaskToken == currentToken do
				RunService.Heartbeat:Wait()
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
				local myCharacter = player.Character
				local myRoot = getRootUniversal(myCharacter)
				if myRoot then
					local savedCFrame = myRoot.CFrame
					local myPosition = myRoot.Position
					local touchedAny = false
					for _, otherPlayer in ipairs(getOtherPlayers()) do
						local targetModel = otherPlayer.Character
						local targetRoot = getRootUniversal(targetModel)
						if targetRoot and (targetRoot.Position - myPosition).Magnitude <= auraRange then
							touchedAny = true
							overpowerRootState(myRoot, targetRoot.CFrame, Vector3.zero, Vector3.zero)
							nextFrame()
							if not auraFlingEnabled or not myRoot.Parent then
								break
							end
							overpowerRootState(
								myRoot,
								targetRoot.CFrame,
								(targetRoot.CFrame.Position - myPosition).Unit * flingPower + Vector3.new(0, flingPower * 0.5, 0),
								Vector3.new(flingPower, flingPower, flingPower)
							)
						end
					end
					if touchedAny and myRoot.Parent then
						nextFrame()
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
function clickFlingTargetPlayer(targetPlayer)
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
			if not clickFlingEnabled then
				break
			end
			local targetCharacter = targetPlayer and targetPlayer.Character
			local targetRoot = getRootUniversal(targetCharacter)
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
			local myRoot = getRootUniversal(player.Character)
			if not myRoot then
				return
			end
			local targetRoots = {}
			for _, otherPlayer in ipairs(getOtherPlayers()) do
				local targetModel = otherPlayer.Character
				local targetRoot = getRootUniversal(targetModel)
				if targetRoot then
					targetRoots[#targetRoots + 1] = targetRoot
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
	if (nextState == nil or nextState == true) and isSafeZoneBlocking() then
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
			ignoredModels[targetEntry.model] = tick() + 1.5
			switchedTargets += 1
			task.wait(0.1)
		end
		if getTrashState.token == runToken and getTrashState.running then
			getTrashState.returning = true
			returnFromTrashRun(runToken)
			finishGetTrashRun()
		end
	end)
	return "ON"
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
function saveSetBackPosition()
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
	if isSafeZoneBlocking() then
		return false
	end
	local currentCharacter = player.Character
	local currentRoot = currentCharacter and currentCharacter:FindFirstChild("HumanoidRootPart")
	if not currentRoot or not setBackSavedCFrame then
		return false
	end
	stopSetBackTravel()
	setSetBackNoclipEnabled(true)
	zeroLocalPlayerRoot()
	local lastDistance = nil
	local stalledFor = 0
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
		if lastDistance and distance >= (lastDistance - 0.15) then
			stalledFor += dt
		else
			stalledFor = 0
		end
		lastDistance = distance
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
		if stalledFor >= 0.6 then
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
		local step = math.min(90000 * dt, distance)
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
local function setNothingXProtectionEnabled(enabled)
	local protection = _G.NOTHINGX_Protection
	if type(protection) == "table" then
		protection.Enabled = enabled == true
	end
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
	if isSafeZoneBlocking() then
		return
	end
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
	if not setBackSavedCFrame then
		setBackLastPressAt = 0
		saveSetBackPosition()
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
	if (nextState == nil or nextState == true) and isSafeZoneBlocking() then
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
	targetValueText.Text = ""
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
	if not model then
		return false
	end
	if model:GetAttribute("HasTrashcan") == true then
		return false
	end
	local modelRoot = model:FindFirstChild("HumanoidRootPart")
	if not modelRoot then
		return false
	end
	local map = Workspace:FindFirstChild("Map")
	local trashFolder = map and map:FindFirstChild("Trash")
	if trashFolder then
		for _, trashcan in ipairs(trashFolder:GetChildren()) do
			if trashcan:IsA("Model") and not trashcan:GetAttribute("Broken") then
				local part = trashcan:FindFirstChildWhichIsA("BasePart", true)
				if part and (part.Position - modelRoot.Position).Magnitude < 9.5 then
					return false
				end
			end
		end
	end
	if modelRoot.Position.Y > 2500 then
		return false
	end
	if modelRoot.Position.Y < -50 then
		return false
	end
	return true
end
function isValidCamLockTarget(model)
	if not model or model == char then
		return false
	end
	if not isTargetSafe(model) then
		return false
	end
	local modelHumanoid = model:FindFirstChildOfClass("Humanoid")
	local modelRoot = model:FindFirstChild("HumanoidRootPart")
	return modelHumanoid and modelHumanoid.Health > 0 and modelRoot ~= nil
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
		return modelHumanoid.Health <= 0
	end
	return false
end
local function hasLiveStoredTarget(model)
	return model ~= nil and model.Parent ~= nil
end
_G.lastValidTrashTime = 0
function isTpBlocked()
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
local function resolveManualAttackTpTargetModel()
	if manualAttackTpPlayer then
		local trackedTarget = getTrackedPlayerTargetModel(manualAttackTpPlayer)
		if trackedTarget then
			manualAttackTpTarget = trackedTarget
		end
	end
	return manualAttackTpTarget
end
function hasTrackedSelectedPlayer()
	return manualAttackTpPlayer ~= nil and manualAttackTpPlayer ~= player and manualAttackTpPlayer.Parent == Players
end
function isWaitingForSelectedPlayerRespawn()
	return hasTrackedSelectedPlayer() and isDeadTargetModel(resolveManualAttackTpTargetModel())
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
	return hasLiveStoredTarget(resolvedManualTarget)
end
function hasSelectedTargetOrPendingPlayer()
	return hasActiveSelectedTarget() or isWaitingForSelectedPlayerRespawn()
end
syncTargetActionControls = function()
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
		manualAttackTpTarget = nil
		pendingTeleportToSelectedPlayer = false
		if syncModelDropdownSelectionToManualTarget then
			syncModelDropdownSelectionToManualTarget()
		end
		targetStateChanged = true
	end
	if camLockTarget and isDeadTargetModel(camLockTarget) and not manualAttackTpPlayer then
		camLockTarget = nil
		camLockWaiting = false
		camLockEnabled = false
		syncCamLockKeybindDisplay()
		targetStateChanged = true
	end
	if targetStateChanged then
		syncTargetPickKeybindDisplay()
	end
	local displayedTarget = getDisplayedTargetModel()
	local displayName = displayedTarget and displayedTarget.Name or (manualAttackTpPlayer and manualAttackTpPlayer.Name or "")
	targetValueText.Text = displayName
	targetFrame.Visible = displayName ~= ""
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
local function getSelectableTargetModels()
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
			if modelRoot and hum and hum.Health > 0 and isTargetSafe(model) then
				seenModels[model] = true
				models[#models + 1] = model
			end
		end
	end
	if now - lastWorkspaceScan > 2.5 then
		lastWorkspaceScan = now
		task.spawn(function()
			local newModels = {}
			local targetFolder = Workspace:FindFirstChild("Live") or Workspace
			local children = targetFolder:GetChildren()
			for _, model in ipairs(children) do
				if model:IsA("Model") and model ~= currentCharacter and not Players:GetPlayerFromCharacter(model) then
					local hum = model:FindFirstChildOfClass("Humanoid")
					local modelRoot = model:FindFirstChild("HumanoidRootPart")
					if hum and hum.Health > 0 and modelRoot and isTargetSafe(model) then
						newModels[#newModels + 1] = model
					end
				end
			end
			for _, m in ipairs(newModels) do
				if not seenModels[m] then
					seenModels[m] = true
					models[#models + 1] = m
				end
			end
			cachedSelectableModels = models
		end)
	else
		for _, m in ipairs(cachedSelectableModels) do
			if not seenModels[m] and m.Parent and m:FindFirstChild("Humanoid") and m.Humanoid.Health > 0 then
				seenModels[m] = true
				models[#models + 1] = m
			end
		end
		cachedSelectableModels = models
	end
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
		return camLockTarget
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
local function getAttackTpPlacement(characterRoot, targetModel)
	if not characterRoot or not targetModel then
		return nil, nil
	end
	local targetRoot = targetModel:FindFirstChild("HumanoidRootPart")
	local targetHumanoid = targetModel:FindFirstChildOfClass("Humanoid")
	if not targetRoot or not isAliveHumanoid(targetHumanoid) or targetRoot.Anchored then
		return nil, nil
	end
	local characterHumanoid = characterRoot.Parent and characterRoot.Parent:FindFirstChildOfClass("Humanoid")
	if not isAliveHumanoid(characterHumanoid) then
		return nil, nil
	end
	local useAirTracking = isAirborneHumanoid(targetHumanoid) or isAirborneHumanoid(characterHumanoid)
	local targetVelocity = targetRoot.AssemblyLinearVelocity
	local leadTime = useAirTracking and attackTpAirLeadTime or attackTpLeadTime
	local horizontalVelocity = Vector3.new(targetVelocity.X, 0, targetVelocity.Z)
	local horizontalLead = horizontalVelocity * leadTime
	if horizontalLead.Magnitude > attackTpMaxHorizontalLead then
		horizontalLead = horizontalLead.Unit * attackTpMaxHorizontalLead
	end
	local verticalLead = math.clamp((targetVelocity.Y * leadTime) + attackTpVerticalLead, -attackTpMaxVerticalLead, attackTpMaxVerticalLead)
	local predictedTargetPosition = targetRoot.Position + horizontalLead + Vector3.new(0, verticalLead, 0)
	local isRagdoll = targetModel:FindFirstChild("RagdollSim") or targetModel:FindFirstChild("Ragdoll")
	local mode = attackTpMode or "Above"
	local finalCFrame = nil
	if mode == "Above" then
		local dist = isRagdoll and 4.2 or 6.8
		finalCFrame = CFrame.lookAt(predictedTargetPosition + Vector3.new(0, dist, 0), predictedTargetPosition, worldUpVector)
	elseif mode == "Under" then
		finalCFrame = CFrame.lookAt(predictedTargetPosition + Vector3.new(0, -6.5, 0), predictedTargetPosition, worldUpVector)
	elseif mode == "Behind" then
		local followDirection = getHorizontalUnit(targetVelocity)
			or getHorizontalUnit(targetRoot.CFrame.LookVector)
			or getHorizontalUnit(targetRoot.Position - characterRoot.Position)
			or Vector3.new(0, 0, -1)
		local dist = isRagdoll and 1.2 or 1.85
		finalCFrame = CFrame.lookAt(predictedTargetPosition - (followDirection * dist), predictedTargetPosition, worldUpVector)
	elseif mode == "Aggressive" then
		local followDirection = getHorizontalUnit(targetVelocity)
			or getHorizontalUnit(targetRoot.CFrame.LookVector)
			or Vector3.new(0, 0, -1)
		finalCFrame = CFrame.lookAt(predictedTargetPosition - (followDirection * 0.8) + Vector3.new(0, 1.2, 0), predictedTargetPosition, worldUpVector)
	elseif mode == "Middle" then
		finalCFrame = CFrame.lookAt(predictedTargetPosition + Vector3.new(0, 0.1, 0), predictedTargetPosition, worldUpVector)
	elseif string.find(tostring(mode), "Custom") then
		local cleanMode = tostring(mode):match("Custom %d+")
		local offsets = customOffsets[cleanMode] or { x = 0, y = 0, z = 0 }
		local offsetVec = Vector3.new(offsets.x, offsets.y, offsets.z)
		if offsetVec.Magnitude < 0.1 then
			offsetVec = Vector3.new(0, 0.1, 0)
		end
		finalCFrame = CFrame.lookAt(predictedTargetPosition + offsetVec, predictedTargetPosition, worldUpVector)
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
	if bestDistance > manualTargetAcquireRadius then
		return nil
	end
	return bestModel
end
local function clearManualAttackTpTarget()
	manualAttackTpPlayer = nil
	manualAttackTpTarget = nil
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
	local currentTarget = resolveManualAttackTpTargetModel()
	local currentPlayer = manualAttackTpPlayer
	if hasManualAttackTpSelection() or isWaitingForSelectedPlayerRespawn() then
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
local function showInfo(title, text, time)
	if not introFinished then
		pendingInfoCall = {
			title = title,
			text = text,
			time = time,
		}
		return
	end
	local currentToken = (screenGui:GetAttribute("InfoToken") or 0) + 1
	screenGui:SetAttribute("InfoToken", currentToken)
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
		if currentToken ~= (screenGui:GetAttribute("InfoToken") or 0) then
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
			if currentToken ~= (screenGui:GetAttribute("InfoToken") or 0) then
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
local function initSeriousModeTracker()
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local SHARED_HIGHLIGHT_NAME = "NOTHING-X"
local SERIOUS_MODE_STATE_ATTRIBUTE = "NX_SeriousModeState"
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
local function ensureSharedHighlight(model)
    if not model or not model:FindFirstChild("HumanoidRootPart") then return nil end
    local hl = model:FindFirstChild(SHARED_HIGHLIGHT_NAME)
    if hl and not hl:IsA("Highlight") then
        hl:Destroy()
        hl = nil
    end
    if hl then
        return hl
    end
    hl = Instance.new("Highlight")
    hl.Name = SHARED_HIGHLIGHT_NAME
    hl.Adornee = model
    hl.Parent = model
    hl.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
    hl.FillTransparency = 0.8
    hl.OutlineTransparency = 0
    return hl
end
local function addHighlight(model, fillColor, enabled, outlineColor)
    local hl = ensureSharedHighlight(model)
    if not hl then return end
    hl.OutlineColor = outlineColor or Color3.fromRGB(0, 0, 0)
    hl.FillColor = fillColor
    hl.Enabled = enabled
end
local function removeHighlight(model)
    if model then
        local hl = model:FindFirstChild(SHARED_HIGHLIGHT_NAME)
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
        char:SetAttribute(SERIOUS_MODE_STATE_ATTRIBUTE, nil)
        return
    end
    local skill = getSkillType(backpack)
    local currentState = playerState[plr]
    if skill == "strong" and currentState ~= "strong" then
        playerState[plr] = "strong"
        char:SetAttribute(SERIOUS_MODE_STATE_ATTRIBUTE, "strong")
        callInfo("SERIOUS MODE", plr.Name .. " - ACTIVE", 5)
    elseif skill == "weak" and currentState == "strong" then
        playerState[plr] = "weak"
        char:SetAttribute(SERIOUS_MODE_STATE_ATTRIBUTE, "weak")
        callInfo("SERIOUS MODE", plr.Name .. " - DEATH", 5)
        local timerId = tick()
        activeTimers[plr] = timerId
        task.delay(9.4, function()
            if activeTimers[plr] == timerId and playerState[plr] == "weak" then
                playerState[plr] = nil
                if char and char.Parent then
                    char:SetAttribute(SERIOUS_MODE_STATE_ATTRIBUTE, nil)
                end
                callInfo("SERIOUS MODE", plr.Name .. " - END", 5)
            end
        end)
    end
end
local function startGlobalChecker()
    task.spawn(function()
        while true do
            task.wait(0.25) 
            for _, plr in ipairs(Players:GetPlayers()) do
                if plr == Players.LocalPlayer then continue end
                local char = plr.Character
                if not char then continue end
                local shouldHaveState = playerState[plr]
                if shouldHaveState then
                    char:SetAttribute(SERIOUS_MODE_STATE_ATTRIBUTE, shouldHaveState)
                else
                    char:SetAttribute(SERIOUS_MODE_STATE_ATTRIBUTE, nil)
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
        if char and char.Parent then
            char:SetAttribute(SERIOUS_MODE_STATE_ATTRIBUTE, nil)
        end
        char = char or plr.Character
        if not char or char ~= plr.Character then
            return
        end
        disconnectTrackedConnections()
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
                if char and char.Parent then
                    char:SetAttribute(SERIOUS_MODE_STATE_ATTRIBUTE, nil)
                end
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
            if plr.Character then
                plr.Character:SetAttribute(SERIOUS_MODE_STATE_ATTRIBUTE, nil)
            end
        end
    end)
end
startGlobalChecker()
for _, plr in ipairs(Players:GetPlayers()) do
    setupPlayer(plr)
end
Players.PlayerAdded:Connect(setupPlayer)
end
initSeriousModeTracker()
local function initCharacterCleanupRuntime()
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
	OnCharacterAdded(speaker.Character)
end
ModConnections.CharacterAdded = speaker.CharacterAdded:Connect(OnCharacterAdded)
task.spawn(function()
	while speaker.Parent do
		task.wait(0.35)
		local char = speaker.Character
		if not char then continue end
		usunPusteAccessory(char)
	end
end)
end
initCharacterCleanupRuntime()
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
        if (state == nil or state == true) and isSafeZoneBlocking() then
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
    local supportsDashBlock = game.GameId == 3808081382
    local createMovementPanel = _G["2tog_on_one_button"]
    while type(createMovementPanel) ~= "function" do
        nextFrame()
        createMovementPanel = _G["2tog_on_one_button"]
    end
    movementPanel = createMovementPanel({
        title = "Movement",
        name1 = "Stay",
        name2 = supportsDashBlock and "Dash Block" or nil,
        buttonName = "Fix Camera",
        buttonName2 = "Lay",
        buttonName3 = "Dummy",
        default1 = false,
        default2 = supportsDashBlock and false or nil,
        fun1 = setStayState,
        fun2 = supportsDashBlock and setDashBlockRuntime or nil,
        buttonfun = fixCamera,
        buttonfun2 = layCharacter,
        buttonfun3 = teleportToWeakestDummy,
    })
    StayToggle = movementPanel.First
    DashToggle = movementPanel.Second
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
        local WhirlwindEnabled = false
        local WallComboEnabled = false
        local function SpamQ()
            VIM:SendKeyEvent(true, Enum.KeyCode.Q, false, game)
            task.wait(0.05)
            VIM:SendKeyEvent(false, Enum.KeyCode.Q, false, game)
        end
        local function HandleWallComboTilt(track, combatChar)
            if not WallComboEnabled or not track.Animation then return end
            if WallComboIDs[track.Animation.AnimationId] then
                local hrp = combatChar:FindFirstChild("HumanoidRootPart")
                if hrp then
                    local startCFrame = hrp.CFrame
                    local startTime = tick()
                    local conn
                    conn = RunService.Heartbeat:Connect(function()
                        if not WallComboEnabled or tick() - startTime >= 0.3 then
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
                if WhirlwindEnabled and track.Animation and track.Animation.AnimationId == WhirlwindDunkID then
                    task.wait(1.2)
                    local hrp = combatChar:FindFirstChild("HumanoidRootPart")
                    if hrp then hrp.CFrame = hrp.CFrame * CFrame.new(0, 100, 0) end
                end
                HandleWallComboTilt(track, combatChar)
            end)
            combatChar.DescendantAdded:Connect(function(desc)
                if desc:IsA("ObjectValue") and desc.Name:lower() == "wallcombo" and WallComboEnabled then
                    local startTime = tick()
                    local duration = desc:GetAttribute("DeleteMe") or 0.6
                    repeat SpamQ(); task.wait()
                    until not desc.Parent or desc.Parent ~= combatChar or tick() - startTime >= duration
                end
            end)
        end
        if player.Character then task.spawn(SetupCombatCharacter, player.Character) end
        player.CharacterAdded:Connect(function(c) task.spawn(SetupCombatCharacter, c) end)
        local combatHolder = panel.Frame
        combatHolder.Size = UDim2.new(1, -4, 0, 108)
        local combatRow = Instance.new("Frame")
        combatRow.BackgroundTransparency = 1
        combatRow.Position = UDim2.new(0, 10, 0, 70)
        combatRow.Size = UDim2.new(1, -20, 0, 28)
        combatRow.Parent = combatHolder
        local combatLayout = Instance.new("UIListLayout")
        combatLayout.FillDirection = Enum.FillDirection.Horizontal
        combatLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
        combatLayout.VerticalAlignment = Enum.VerticalAlignment.Center
        combatLayout.Padding = UDim.new(0, 6)
        combatLayout.Parent = combatRow
        local function makeCombatToggle(text, callback, saveKey)
            local btn = Instance.new("TextButton")
            btn.BackgroundColor3 = Color3.fromRGB(24, 0, 0)
            btn.BackgroundTransparency = 0.06
            btn.BorderSizePixel = 0
            btn.Size = UDim2.new(1/3, -5, 1, 0)
            btn.AutoButtonColor = false
            btn.Font = Enum.Font.GothamBold
            btn.Text = text
            btn.TextColor3 = Color3.fromRGB(255, 175, 175)
            btn.TextStrokeTransparency = 0.15
            btn.TextStrokeColor3 = Color3.fromRGB(110, 0, 0)
            btn.TextScaled = true
            btn.TextWrapped = true
            btn.Parent = combatRow
            local corner = Instance.new("UICorner")
            corner.CornerRadius = UDim.new(0, 10)
            corner.Parent = btn
            local constraint = Instance.new("UITextSizeConstraint")
            constraint.MinTextSize = 10
            constraint.MaxTextSize = 14
            constraint.Parent = btn
            local enabled = false
            if saveKey and controlSaveData[saveKey] ~= nil then
                enabled = controlSaveData[saveKey]
            end
            local function render()
                btn.BackgroundColor3 = enabled and Color3.fromRGB(150, 0, 0) or Color3.fromRGB(24, 0, 0)
                btn.TextColor3 = enabled and Color3.fromRGB(255, 220, 220) or Color3.fromRGB(255, 175, 175)
            end
            btn.MouseButton1Click:Connect(function()
                enabled = not enabled
                render()
                if saveKey then
                    controlSaveData[saveKey] = enabled
                    saveSliderSaveData()
                end
                if callback then callback(enabled) end
            end)
            if enabled and callback then callback(enabled) end
            render()
        end
        makeCombatToggle("Auto Whirlwind Dunk", function(val) WhirlwindEnabled = val end, "AutoWhirlwind")
        makeCombatToggle("Auto Combo", function(val) WallComboEnabled = val end, "AutoCombo")
        makeCombatToggle("No Dash CD", function(val)
            workspace:SetAttribute("EffectAffects", val and 1 or 0)
            workspace:SetAttribute("NoDashCooldown", val)
        end, "NoDashCD")
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
function initProtectionRuntime()
	local Workspace = game:GetService("Workspace")
	local player = game:GetService("Players").LocalPlayer
	local protection = _G.NOTHINGX_Protection or {}
	_G.NOTHINGX_Protection = protection
	protection.Enabled = true
	protection.boundarySize = Vector3.new(200000, 0, 200000)
	protection.Y_BOUNDARY_UP = 200000
	protection.EXTREME_LOW_OFFSET = -1000
	protection.VOID_BUFFER = 90
	protection.MAX_SAFE_POSITIONS = 10
	protection.SAVE_INTERVAL = 0.12
	protection.MIN_DISTANCE_TO_SAVE = 6
	protection.MAX_SAVE_HEIGHT_FROM_GROUND = 5.5
	protection.MAX_AIR_SAVE_VERTICAL_SPEED = 4
	protection.MIN_GROUND_NORMAL_Y = 0.35
	protection.GROUND_CHECK_UP = 6
	protection.GROUND_CHECK_DOWN = 45
	protection.RESCUE_HEIGHT = 6
	protection.RESCUE_PROBE_HEIGHT = 12
	protection.FALLBACK_CAST_HEIGHT = 1500
	protection.FALLBACK_CAST_DEPTH = 4000
	protection.SEARCH_OFFSETS = {
		Vector3.new(0, 0, 0),
		Vector3.new(6, 0, 0),
		Vector3.new(-6, 0, 0),
		Vector3.new(0, 0, 6),
		Vector3.new(0, 0, -6),
		Vector3.new(6, 0, 6),
		Vector3.new(6, 0, -6),
		Vector3.new(-6, 0, 6),
		Vector3.new(-6, 0, -6),
	}
	protection.safePositionHistory = protection.safePositionHistory or {}
	protection.safePositionEntries = protection.safePositionEntries or {}
	protection.lastSafePosition = protection.lastSafePosition or nil
	protection.lastSafeEntry = protection.lastSafeEntry or nil
	protection.lastSaveTime = protection.lastSaveTime or 0
	protection.rescueInProgress = false
	protection.detectVoidY = function()
		local official = Workspace.FallenPartsDestroyHeight
		if official and official > -500000 and official < 10000 then
			protection.VOID_Y = official
		else
			local lowest = 200
			for _ = 1, 6 do
				local probe = Instance.new("Part")
				probe.Size = Vector3.new(8, 8, 8)
				probe.Position = Vector3.new(0, 600, 0)
				probe.Anchored = false
				probe.CanCollide = false
				probe.Transparency = 1
				probe.Parent = Workspace
				task.wait(1.8)
				if probe.Parent then
					lowest = math.min(lowest, probe.Position.Y)
					probe:Destroy()
				end
				task.wait(0.3)
			end
			protection.VOID_Y = lowest - 90
		end
		protection.EXTREME_LOW_Y = protection.VOID_Y + protection.EXTREME_LOW_OFFSET
	end
	protection.getReferenceCFrame = function()
		local map = Workspace:FindFirstChild("Map")
		local main = map and map:FindFirstChild("MainPart")
		if main then
			return main.CFrame
		end
		local character = player.Character
		local hrp = character and character:FindFirstChild("HumanoidRootPart")
		if hrp then
			return CFrame.new(hrp.Position.X, 200, hrp.Position.Z)
		end
		return protection.defaultCFrame or CFrame.new(0, 200, 0)
	end
	protection.isOutsideBoundary = function(pos)
		local cf = protection.getReferenceCFrame()
		local localPos = cf:PointToObjectSpace(pos)
		local half = protection.boundarySize / 2
		return math.abs(localPos.X) > half.X
			or math.abs(localPos.Z) > half.Z
			or pos.Y > protection.Y_BOUNDARY_UP
	end
	protection.isAnyObjectBelow = function(hrp)
		if not hrp or not hrp.Parent then
			return false
		end
		local params = RaycastParams.new()
		params.FilterDescendantsInstances = { hrp.Parent }
		params.FilterType = Enum.RaycastFilterType.Exclude
		return Workspace:Raycast(hrp.Position + Vector3.new(0, 6, 0), Vector3.new(0, -35, 0), params) ~= nil
	end
	protection.makeGroundParams = function(character)
		local params = RaycastParams.new()
		params.FilterType = Enum.RaycastFilterType.Exclude
		params.FilterDescendantsInstances = character and { character } or {}
		params.IgnoreWater = false
		return params
	end
	protection.getGroundHitAt = function(position, character, castUp, castDown)
		local up = castUp or protection.GROUND_CHECK_UP
		local down = castDown or protection.GROUND_CHECK_DOWN
		local origin = position + Vector3.new(0, up, 0)
		local direction = Vector3.new(0, -(up + down), 0)
		return Workspace:Raycast(origin, direction, protection.makeGroundParams(character))
	end
	protection.getGroundHitAround = function(position, character, castUp, castDown)
		for _, offset in ipairs(protection.SEARCH_OFFSETS) do
			local samplePosition = position + offset
			local hit = protection.getGroundHitAt(samplePosition, character, castUp, castDown)
			if hit and hit.Normal.Y >= protection.MIN_GROUND_NORMAL_Y and not protection.isOutsideBoundary(hit.Position) then
				return hit, samplePosition
			end
		end
		return nil
	end
	protection.buildRescueCFrame = function(hitPosition, hitNormal, referenceCFrame)
		local lookVector = referenceCFrame and referenceCFrame.LookVector or Vector3.new(0, 0, -1)
		local flatLook = Vector3.new(lookVector.X, 0, lookVector.Z)
		if flatLook.Magnitude < 0.001 then
			flatLook = Vector3.new(0, 0, -1)
		else
			flatLook = flatLook.Unit
		end
		local rescuePosition = hitPosition + hitNormal * protection.RESCUE_HEIGHT
		return CFrame.lookAt(rescuePosition, rescuePosition + flatLook)
	end
	protection.createSafeEntry = function(char, hrp, humanoid)
		if not char or not hrp or protection.isOutsideBoundary(hrp.Position) then
			return nil
		end
		local hit = protection.getGroundHitAt(hrp.Position, char)
		if not hit or hit.Normal.Y < protection.MIN_GROUND_NORMAL_Y then
			return nil
		end
		local heightFromGround = hrp.Position.Y - hit.Position.Y
		local grounded = humanoid and humanoid.FloorMaterial ~= Enum.Material.Air
		if not grounded then
			local verticalSpeed = math.abs(hrp.AssemblyLinearVelocity.Y)
			if heightFromGround > protection.MAX_SAVE_HEIGHT_FROM_GROUND or verticalSpeed > protection.MAX_AIR_SAVE_VERTICAL_SPEED then
				return nil
			end
		end
		return {
			cframe = hrp.CFrame,
			position = hrp.Position,
			groundPosition = hit.Position,
			groundNormal = hit.Normal,
			part = hit.Instance,
			savedAt = tick(),
		}
	end
	protection.pushSafeEntry = function(entry)
		if not entry or not entry.cframe then
			return
		end
		protection.lastSafeEntry = entry
		protection.lastSafePosition = entry.cframe
		table.insert(protection.safePositionEntries, 1, entry)
		table.insert(protection.safePositionHistory, 1, entry.cframe)
		if #protection.safePositionEntries > protection.MAX_SAFE_POSITIONS then
			table.remove(protection.safePositionEntries)
		end
		if #protection.safePositionHistory > protection.MAX_SAFE_POSITIONS then
			table.remove(protection.safePositionHistory)
		end
	end
	protection.saveSafePosition = function(char, hrp, humanoid)
		local entry = protection.createSafeEntry(char, hrp, humanoid)
		if not entry then
			return
		end
		local now = tick()
		if now - (protection.lastSaveTime or 0) < protection.SAVE_INTERVAL then
			return
		end
		local lastEntry = protection.lastSafeEntry
		if lastEntry and (lastEntry.position - entry.position).Magnitude < protection.MIN_DISTANCE_TO_SAVE then
			return
		end
		protection.lastSaveTime = now
		protection.pushSafeEntry(entry)
	end
	protection.resolveEntryRescueCFrame = function(entry, character)
		if not entry or not entry.cframe then
			return nil
		end
		local entryPosition = entry.position or entry.cframe.Position
		local hit = protection.getGroundHitAround(
			entryPosition,
			character,
			protection.RESCUE_PROBE_HEIGHT,
			protection.GROUND_CHECK_DOWN + protection.RESCUE_PROBE_HEIGHT
		)
		if not hit then
			return nil
		end
		return protection.buildRescueCFrame(hit.Position, hit.Normal, entry.cframe)
	end
	protection.getFallbackRescueCFrame = function(character)
		local referenceCFrame = protection.getReferenceCFrame()
		for _, offset in ipairs(protection.SEARCH_OFFSETS) do
			local samplePosition = referenceCFrame.Position + offset
			local origin = samplePosition + Vector3.new(0, protection.FALLBACK_CAST_HEIGHT, 0)
			local direction = Vector3.new(0, -protection.FALLBACK_CAST_DEPTH, 0)
			local hit = Workspace:Raycast(origin, direction, protection.makeGroundParams(character))
			if hit and hit.Normal.Y >= protection.MIN_GROUND_NORMAL_Y and not protection.isOutsideBoundary(hit.Position) then
				return protection.buildRescueCFrame(hit.Position, hit.Normal, referenceCFrame)
			end
		end
		return referenceCFrame + Vector3.new(0, 180, 0)
	end
	protection.getRescueCFrame = function(character, skippedEntries)
		for index, entry in ipairs(protection.safePositionEntries) do
			if not (skippedEntries and skippedEntries[index]) then
				local target = protection.resolveEntryRescueCFrame(entry, character)
				if target then
					return target, index
				end
			end
		end
		for index, cf in ipairs(protection.safePositionHistory) do
			local fallbackIndex = -index
			if cf and not (skippedEntries and skippedEntries[fallbackIndex]) then
				local target = protection.resolveEntryRescueCFrame({
					cframe = cf,
					position = cf.Position,
				}, character)
				if target then
					return target, fallbackIndex
				end
			end
		end
		return protection.getFallbackRescueCFrame(character), "fallback"
	end
	protection.isCurrentSpotSafe = function(char, hrp, humanoid)
		if not char or not hrp or protection.isOutsideBoundary(hrp.Position) then
			return false
		end
		if humanoid and humanoid.FloorMaterial ~= Enum.Material.Air then
			return true
		end
		local hit = protection.getGroundHitAt(hrp.Position, char, 4, 18)
		return hit ~= nil and hit.Normal.Y >= protection.MIN_GROUND_NORMAL_Y
	end
	protection.tpBack = function(char, hrp)
		if protection.rescueInProgress or not char or not hrp then
			return
		end
		protection.rescueInProgress = true
		_G.SafeTeleportLock = true
		local skippedEntries = {}
		for _ = 1, protection.MAX_SAFE_POSITIONS + 2 do
			local liveChar = player.Character
			local liveRoot = liveChar and liveChar:FindFirstChild("HumanoidRootPart")
			local liveHumanoid = liveChar and liveChar:FindFirstChildOfClass("Humanoid")
			if not liveChar or not liveRoot then
				break
			end
			local target, entryIndex = protection.getRescueCFrame(liveChar, skippedEntries)
			if not target then
				break
			end
			skippedEntries[entryIndex] = true
			for _ = 1, 6 do
				liveRoot.AssemblyLinearVelocity = Vector3.zero
				liveRoot.AssemblyAngularVelocity = Vector3.zero
				liveChar:PivotTo(target)
				applyTeleportRootState(liveRoot, target)
				nextFrame()
			end
			if protection.isCurrentSpotSafe(liveChar, liveRoot, liveHumanoid) then
				protection.saveSafePosition(liveChar, liveRoot, liveHumanoid)
				break
			end
		end
		local liveChar = player.Character
		local liveRoot = liveChar and liveChar:FindFirstChild("HumanoidRootPart")
		if liveRoot then
			liveRoot.AssemblyLinearVelocity = Vector3.zero
			liveRoot.AssemblyAngularVelocity = Vector3.zero
		end
		nextFrame()
		_G.SafeTeleportLock = false
		protection.rescueInProgress = false
	end
	protection.detectVoidY()
	if protection.runtimeStarted then
		return
	end
	protection.runtimeStarted = true
	task.spawn(function()
		while true do
			nextFrame()
			if not protection.Enabled then
				continue
			end
			local char = player.Character
			local hrp = char and char:FindFirstChild("HumanoidRootPart")
			local humanoid = char and char:FindFirstChildOfClass("Humanoid")
			if not hrp then
				continue
			end
			protection.saveSafePosition(char, hrp, humanoid)
			if _G.NOTHINGX_FlyActive == true then
				continue
			end
			local y = hrp.Position.Y
			if protection.isOutsideBoundary(hrp.Position) or y < protection.EXTREME_LOW_Y then
				protection.tpBack(char, hrp)
				continue
			end
			local minSafeY = protection.VOID_Y and (protection.VOID_Y + protection.VOID_BUFFER) or -999999
			if y < minSafeY then
				protection.tpBack(char, hrp)
			end
		end
	end)
	print("(-) " .. tostring(protection.VOID_Y) .. " (-)")
end
initProtectionRuntime()
local function initFastAntiVoid()
	local localSafeCFrame   = nil
	local lastFrameY        = nil
	local fastRescuing      = false
	local RESCUE_BUFFER             = 175
	local SUDDEN_DROP_THRESHOLD     = 350
	local SUDDEN_DROP_VOID_MARGIN   = 700
	local MAX_DOWN_VELOCITY         = -500
	local DANGER_ZONE_ABOVE_VOID    = 500
	local SAFE_SAVE_MIN_ABOVE_VOID  = 280
	RunService.Heartbeat:Connect(function()
		if fastRescuing or _G.SafeTeleportLock then
			return
		end
		local char     = player.Character
		local hrp      = char and char:FindFirstChild("HumanoidRootPart")
		local humanoid = char and char:FindFirstChildOfClass("Humanoid")
		if not hrp or not humanoid or humanoid.Health <= 0 then
			lastFrameY = nil
			return
		end
		local voidY = (protection and type(protection.VOID_Y) == "number")
			and protection.VOID_Y
			or -500
		local pos = hrp.Position
		local y   = pos.Y
		if humanoid.FloorMaterial ~= Enum.Material.Air
			and y > voidY + SAFE_SAVE_MIN_ABOVE_VOID
		then
			localSafeCFrame = hrp.CFrame
		end
		local needsRescue = false
		if y < voidY + RESCUE_BUFFER then
			needsRescue = true
		end
		if not needsRescue and lastFrameY and not flying then
			local drop = lastFrameY - y
			if drop >= SUDDEN_DROP_THRESHOLD and y < voidY + SUDDEN_DROP_VOID_MARGIN then
				needsRescue = true
			end
		end
		if not needsRescue and not flying then
			local velY = hrp.AssemblyLinearVelocity.Y
			if velY < MAX_DOWN_VELOCITY and y < voidY + DANGER_ZONE_ABOVE_VOID then
				needsRescue = true
			end
		end
		lastFrameY = y
		if not needsRescue then
			return
		end
		local rescueCFrame = localSafeCFrame
		if not rescueCFrame and protection and protection.lastSafePosition then
			rescueCFrame = protection.lastSafePosition
		end
		if not rescueCFrame then
			return
		end
		fastRescuing       = true
		_G.SafeTeleportLock = true
		lastFrameY         = rescueCFrame.Position.Y
		hrp.AssemblyLinearVelocity  = Vector3.zero
		hrp.AssemblyAngularVelocity = Vector3.zero
		hrp.CFrame = rescueCFrame
		task.defer(function()
			if hrp and hrp.Parent then
				hrp.AssemblyLinearVelocity  = Vector3.zero
				hrp.AssemblyAngularVelocity = Vector3.zero
				hrp.CFrame = rescueCFrame
			end
		end)
		task.delay(0.18, function()
			if hrp and hrp.Parent then
				hrp.AssemblyLinearVelocity  = Vector3.zero
				hrp.AssemblyAngularVelocity = Vector3.zero
				hrp.CFrame = rescueCFrame
			end
			_G.SafeTeleportLock = false
			fastRescuing = false
		end)
	end)
end
initFastAntiVoid()
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
	local defaultValue = data.deffultin or data.defaultin or data.default
	local initialDefault = defaultValue
	local multi = data.multi == true
	local callback = data.fun
	local saveKey = tostring(data.saveKey or data.namedropdown or data.nameDropdown or data.name or "")
	local items = {}
	local itemLookup = {}
	local itemDisplayNames = data.itemDisplayNames or {}
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
		local displayList = {}
		for _, val in ipairs(selectedList) do
			table.insert(displayList, itemDisplayNames[val] or val)
		end
		local displayText = #displayList > 0 and table.concat(displayList, ", ") or "-"
		toggleButton.Text = displayText
		for item, button in pairs(optionButtons) do
			local isOn = selected[item] == true
			local display = itemDisplayNames[item] or item
			button.BackgroundColor3 = isOn and Color3.fromRGB(150, 0, 0) or Color3.fromRGB(24, 0, 0)
			button.Text = isOn and ("[x] " .. display) or ("[ ] " .. display)
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
		if expanded and not wasExpanded then
			choiceFrame.CanvasPosition = Vector2.new(0, 0)
		elseif not expanded then
			choiceFrame.CanvasPosition = Vector2.new(0, 0)
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
	function dropdownControl.GetItems()
		return items
	end
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
modelDropdownLookup = {}
modelDropdownControl = nil
applyModelDropdownSelection = nil
do
	isSelectablePlayerDropdownTarget = function(targetPlayer)
		return targetPlayer and targetPlayer ~= player and targetPlayer.Parent == Players
	end
	isSelectableModelDropdownTarget = function(model)
		if not model or model == char then
			return false
		end
		if Players:GetPlayerFromCharacter(model) == player then
			return false
		end
		return isValidAttackTpTarget(model)
	end
	getModelDropdownLabelForSelection = function(model, targetPlayer)
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
	buildPlayerModelDropdownItems = function()
		local playerEntries = {}
		local modelEntries = {}
		local seenModels = {}
		for _, targetPlayer in ipairs(Players:GetPlayers()) do
			if isSelectablePlayerDropdownTarget(targetPlayer) then
				local targetModel = getTrackedPlayerTargetModel(targetPlayer)
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
		local items = {}
		local function appendEntries(entries, prefix)
			for _, entry in ipairs(entries) do
				local label = string.format("%s %s", prefix, entry.baseName)
				local suffix = 1
				while usedLabels[label] do
					suffix = suffix + 1
					label = string.format("%s %s (%d)", prefix, entry.baseName, suffix)
				end
				usedLabels[label] = true
				items[#items + 1] = label
				modelDropdownLookup[label] = {
					player = entry.player,
					model = entry.model,
				}
			end
		end
		appendEntries(playerEntries, "[P]")
		appendEntries(modelEntries, "[M]")
		return items
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
		elseif selectedEntry.model then
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
	refreshModelDropdown = function(preferredValue)
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
				stopView()
			end
			return
		end
		local activeHumanoid = activeTarget and activeTarget:FindFirstChildOfClass("Humanoid")
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
function teleportToSelectedTarget()
	if isSafeZoneBlocking() then
		return
	end
	if not hasSelectedTargetOrPendingPlayer() then
		return
	end
	local character = player.Character
	local characterRoot = character and character:FindFirstChild("HumanoidRootPart")
	local characterHumanoid = character and character:FindFirstChildOfClass("Humanoid")
	local targetModel = resolveAttackTpTarget()
	if not characterRoot or not isAliveHumanoid(characterHumanoid) or isTpBlocked() then
		return
	end
	if not isValidAttackTpTarget(targetModel) then
		if isWaitingForSelectedPlayerRespawn() then
			pendingTeleportToSelectedPlayer = true
		end
		return
	end
	pendingTeleportToSelectedPlayer = false
	local targetCFrame, targetVelocity = getAttackTpPlacement(characterRoot, targetModel)
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
	local function createToggle(text, initialState, callback, saveKey)
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
		button.BackgroundTransparency = 0.06
		button.BorderSizePixel = 0
		button.Size = UDim2.new(0.2, -4, 1, 0)
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
		constraint.MinTextSize = 9
		constraint.MaxTextSize = 12
		constraint.Parent = button
		local enabled = initialState == true
		local control = {}
		local function render()
			button.BackgroundColor3 = enabled and Color3.fromRGB(150, 0, 0) or Color3.fromRGB(24, 0, 0)
			button.TextColor3 = enabled and Color3.fromRGB(255, 220, 220) or Color3.fromRGB(255, 175, 175)
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
	saveKey = "model",
	inside = {},
	multi = false,
	deffultin = nil,
	fun = function(value)
		applyModelDropdownSelection(value)
	end,
})
targetActionControls = _G["3tog_on_one_one_button"]({
	title = "Function",
	name1 = "View",
	name2 = "Auto TP",
	name3 = "Fling",
	buttonName = "TP",
	default1 = viewing,
	default2 = autoTpEnabled,
	default3 = flingEnabled,
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
	buttonfun = function()
		if not (manualAttackTpPlayer or manualAttackTpTarget) then
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
	min = 1,
	default = auraRange,
	saveKey = "AuraRange",
	fun = function(value)
		auraRange = value
	end,
})
flingModeControls = _G["4tog_on_one_frame"]({
	title = "Fling",
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
		deffultin = nil,
		fun = function(value)
			selectedPlace = value
			syncPlacesKeybindDisplay()
		end,
	})
	placesDropdown.Frame.LayoutOrder = 999998
end
safeZone.toggleControl = tog({
	name = "Safe Zone",
	default = safeZone.enabled,
	saveKey = "AutoSafeZone",
	fun = function(enabled)
		safeZone.enabled = enabled
		if not enabled then
			setNothingXProtectionEnabled(true)
			if safeZone.atDestination and safeZone.savedCFrame then
				startSafeZoneTravel(safeZone.savedCFrame, "return", function()
					safeZone.atDestination = false
					safeZone.savedCFrame = nil
					safeZone.pointCurrent = safeZone.pointStart
				end)
			else
				stopSafeZoneTravel()
			end
		end
	end,
})
safeZone.toggleControl.Frame.LayoutOrder = 999999
syncPlacesKeybindDisplay()
local customOffsetFrame = makeControlFrame(75)
customOffsetFrame.Visible = false
local function getTPModeItems()
	local items = { "Above", "Under", "Behind", "Middle", "Aggressive" }
	for i = 1, 10 do
		table.insert(items, getCustomDisplayName(i))
	end
	return items
end
local tpModesDropdown = nil
local function updateCustomUI()
	local isCustom = string.find(tostring(attackTpMode), "Custom") ~= nil
	customOffsetFrame.Visible = isCustom
	if isCustom then
		local cleanMode = tostring(attackTpMode):match("Custom %d+")
		local off = customOffsets[cleanMode] or { x = 0, y = 0, z = 0 }
		zInput.Text = tostring(off.z)
		yInput.Text = tostring(off.y)
		xInput.Text = tostring(off.x)
	end
end
local function createOffsetInput(label, axis, position)
	local labelObj = Instance.new("TextLabel")
	labelObj.BackgroundTransparency = 1
	labelObj.Position = UDim2.fromScale(position, 0.2)
	labelObj.Size = UDim2.fromScale(0.1, 0.3)
	labelObj.Font = Enum.Font.GothamBold
	labelObj.Text = label
	labelObj.TextColor3 = Color3.fromRGB(255, 100, 100)
	labelObj.TextScaled = true
	labelObj.Parent = customOffsetFrame
	local box = Instance.new("TextBox")
	box.BackgroundColor3 = Color3.fromRGB(25, 0, 0)
	box.BorderSizePixel = 0
	box.Position = UDim2.fromScale(position, 0.5)
	box.Size = UDim2.fromScale(0.25, 0.4)
	box.Font = Enum.Font.GothamMedium
	box.TextColor3 = Color3.fromRGB(255, 200, 200)
	box.TextScaled = true
	box.ClearTextOnFocus = false
	box.Text = "0"
	box.Parent = customOffsetFrame
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 6)
	corner.Parent = box
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
				local displayNames = {}
				for i = 1, 10 do
					displayNames["Custom " .. i] = getCustomDisplayName(i)
				end
				tpModesDropdown.SetItemDisplayNames(displayNames)
			end
		end
	end)
	return box
end
zInput = createOffsetInput("Z", "z", 0.05)
yInput = createOffsetInput("Y", "y", 0.375)
xInput = createOffsetInput("X", "x", 0.7)
local function getTPModeCleanItems()
	local items = { "Above", "Under", "Behind", "Middle", "Aggressive" }
	for i = 1, 10 do
		table.insert(items, "Custom " .. i)
	end
	return items
end
local function getTPModeDisplayNames()
	local names = {}
	for i = 1, 10 do
		names["Custom " .. i] = getCustomDisplayName(i)
	end
	return names
end
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
customOffsetFrame.Parent = uiX
updateCustomUI()
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
	local espOverlayConfig = {
		showCharacter = false,
		showUltimate = false,
		showHp = false,
		showEsp = false,
	}
	local espOverlayState = {}
	local ESP_BILLBOARD_NAME = "NOTHING_X_OverlayBillboard"
	local ESP_HIGHLIGHT_NAME = "NOTHING-X"
	local TextService = game:GetService("TextService")
	local BILLBOARD_MIN_WIDTH = 72
	local BILLBOARD_PADDING_TOP = 5
	local BILLBOARD_PADDING_BOTTOM = 5
	local BILLBOARD_PADDING_LEFT = 6
	local BILLBOARD_PADDING_RIGHT = 6
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
			return Color3.fromRGB(255, 0, 0)
		end
		return Color3.fromRGB(255, 165, 0)
	end
	local function getHpColor(hpPercent)
		local value = clampPercent(hpPercent)
		if value <= 0 then
			return Color3.fromRGB(255, 0, 0)
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
		line.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
		line.TextStrokeTransparency = 0
		line.TextScaled = false
		line.TextSize = 14
		line.TextWrapped = false
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
		billboard.ExtentsOffsetWorldSpace = Vector3.new(0, 3.2, 0)
		billboard.Size = UDim2.fromOffset(BILLBOARD_MIN_WIDTH, 0)
		billboard.MaxDistance = 333
		billboard.Parent = model
		local frame = Instance.new("Frame")
		frame.Name = "Root"
		frame.Size = UDim2.new(1, 0, 0, 0)
		frame.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
		frame.BackgroundTransparency = 0.35
		frame.BorderSizePixel = 0
		frame.Parent = billboard
		local corner = Instance.new("UICorner")
		corner.CornerRadius = UDim.new(0, 10)
		corner.Parent = frame
		local stroke = Instance.new("UIStroke")
		stroke.Color = Color3.fromRGB(255, 0, 0)
		stroke.Thickness = 1.4
		stroke.Transparency = 0.1
		stroke.Parent = frame
		local padding = Instance.new("UIPadding")
		padding.PaddingLeft = UDim.new(0, 6)
		padding.PaddingRight = UDim.new(0, 6)
		padding.PaddingTop = UDim.new(0, 5)
		padding.PaddingBottom = UDim.new(0, 5)
		padding.Parent = frame
		local list = Instance.new("UIListLayout")
		list.Padding = UDim.new(0, BILLBOARD_ITEM_PADDING)
		list.FillDirection = Enum.FillDirection.Horizontal
		list.HorizontalAlignment = Enum.HorizontalAlignment.Center
		list.VerticalAlignment = Enum.VerticalAlignment.Center
		list.SortOrder = Enum.SortOrder.LayoutOrder
		list.Parent = frame
		createBillboardLine(frame, "HpLine").LayoutOrder = 1
		createBillboardLine(frame, "SepOne", Color3.fromRGB(255, 0, 0)).LayoutOrder = 2
		createBillboardLine(frame, "CharacterLine").LayoutOrder = 3
		createBillboardLine(frame, "SepTwo", Color3.fromRGB(255, 0, 0)).LayoutOrder = 4
		createBillboardLine(frame, "UltimateLine").LayoutOrder = 5
		return billboard
	end
	local function getSharedHighlightColors(model, ultedAttr, canUseUltedHighlight)
		local seriousModeState = model and model:GetAttribute("NX_SeriousModeState") or nil
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
		if seriousModeState == "strong" then
			return {
				fill = Color3.fromRGB(0, 0, 0),
				outline = Color3.fromRGB(255, 255, 255),
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
		}
		local characterAttr = attributes.Character
		local ultimateAttr = attributes.Ultimate
		local hasUltimateAttr = ultimateAttr ~= nil
		local ultedAttr = attributes.Ulted == true
		local isBald = tostring(characterAttr or "") == "Bald"
		local hpPercent = humanoid.MaxHealth > 0 and ((humanoid.Health / humanoid.MaxHealth) * 100) or 0
		local hpValue = clampPercent(hpPercent)
		local ultimateValue = clampPercent(ultimateAttr)
		local billboard = ensureOverlayBillboard(model)
		if billboard then
			billboard.Adornee = head
			local frame = billboard:FindFirstChild("Root")
			local hpLine = frame and frame:FindFirstChild("HpLine")
			local sepOne = frame and frame:FindFirstChild("SepOne")
			local characterLine = frame and frame:FindFirstChild("CharacterLine")
			local sepTwo = frame and frame:FindFirstChild("SepTwo")
			local ultimateLine = frame and frame:FindFirstChild("UltimateLine")
			local visibleCount = 0
			local contentWidth = 0
			local visibleGuiCount = 0
			local hpVisible = updateLine(
				hpLine,
				espOverlayConfig.showHp,
				string.format("%d%%", hpValue),
				getHpColor(hpValue)
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
				string.format("%d%%", ultimateValue),
				getUltimateColor(ultimateValue)
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
			local showSepOne = hpVisible and characterVisible
			local showSepTwo = (hpVisible or characterVisible) and ultimateVisible
			updateLine(sepOne, showSepOne, "//", Color3.fromRGB(255, 0, 0))
			updateLine(sepTwo, showSepTwo, "//", Color3.fromRGB(255, 0, 0))
			for _, guiObject in ipairs({ hpLine, sepOne, characterLine, sepTwo, ultimateLine }) do
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
	local function cleanupPlayerOverlay(targetPlayer)
		local state = espOverlayState[targetPlayer]
		local model = state and state.model
		if model and model.Parent then
			local highlight = model:FindFirstChild(ESP_HIGHLIGHT_NAME)
			if highlight and highlight:IsA("Highlight") then
				highlight.Enabled = false
				highlight.OutlineColor = Color3.fromRGB(128, 128, 128)
				scheduleHighlightDestroy(model)
			end
		end
		espOverlayState[targetPlayer] = nil
	end
	local overlayToggleControl = _G["4tog_on_one_frame"]({
		title = "UI",
		name1 = "HP %",
		name2 = "Character Name",
		name3 = "ULT %",
		name4 = "ULTED ESP",
		saveKey1 = "Overlay4HP",
		saveKey2 = "Overlay4Character",
		saveKey3 = "Overlay4Ultimate",
		saveKey4 = "Overlay4ESP",
		default1 = espOverlayConfig.showHp,
		default2 = espOverlayConfig.showCharacter,
		default3 = espOverlayConfig.showUltimate,
		default4 = espOverlayConfig.showEsp,
		fun1 = function(enabled)
			espOverlayConfig.showHp = enabled
		end,
		fun2 = function(enabled)
			espOverlayConfig.showCharacter = enabled
		end,
		fun3 = function(enabled)
			espOverlayConfig.showUltimate = enabled
		end,
		fun4 = function(enabled)
			espOverlayConfig.showEsp = enabled
		end,
	})
	if overlayToggleControl and overlayToggleControl.Frame then
		overlayToggleControl.Frame.LayoutOrder = 100000
	end
	Players.PlayerRemoving:Connect(cleanupPlayerOverlay)
	task.spawn(function()
		while screenGui.Parent do
			local overlayEnabled = espOverlayConfig.showHp
				or espOverlayConfig.showCharacter
				or espOverlayConfig.showUltimate
				or espOverlayConfig.showEsp
			if overlayEnabled then
				for _, targetPlayer in ipairs(Players:GetPlayers()) do
					if targetPlayer ~= player then
						updatePlayerOverlay(targetPlayer)
					end
				end
				task.wait(0.2)
			else
				task.wait(0.5)
			end
		end
	end)
end)
parseWalkFlingDirectionSelection(getSavedControlValue("WalkFlingDirection") or { "Forward" })
syncFlingModeControls()
refreshModelDropdown(getSavedControlValue("model"))
task.spawn(function()
	while screenGui.Parent do
		task.wait(2)
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
	if game.GameId == 3808081382 and input.UserInputType == Enum.UserInputType.Keyboard and isBacktick then
		if not selectedPlace or selectedPlace == "" then
			return
		end
		local isMapLocation = selectedPlace == "Middle Of Map" or selectedPlace == "Prison" or selectedPlace == "Montain 1" or selectedPlace == "Montain 2" or selectedPlace == "Montain 2 Left" or selectedPlace == "Montain 2 Right"
		if isMapLocation then
			local xmap = Workspace:FindFirstChild("Map")
			if not (xmap and xmap:FindFirstChild("MainPart")) then
				return
			end
		end
		local cf = placesTPs[selectedPlace]
		if cf then
			local character = player.Character
			local characterRoot = character and character:FindFirstChild("HumanoidRootPart")
			if characterRoot then
				local startCF = characterRoot.CFrame
				applyTeleportRootState(characterRoot, startCF:Lerp(cf, 0.33))
				task.wait(0.05)
				applyTeleportRootState(characterRoot, startCF:Lerp(cf, 0.66))
				task.wait(0.05)
				applyTeleportRootState(characterRoot, cf)
			end
		end
		return
	end
	if gameProcessed then
		return
	end
	if key == Enum.KeyCode.LeftAlt then
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
	if key == getTrashState.keybind then
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
	stopSafeZoneTravel()
	safeZone.savedCFrame = nil
	safeZone.atDestination = false
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
	updateTargetDisplay()
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
			if nextTarget and isDeadTargetModel(nextTarget) and not manualAttackTpPlayer then
				clearCamLockTarget(false)
				shouldRefreshTargetDisplay = true
				camLockTarget = nil
				lastTargetDeathTime = tick()
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
	safeZone.targetDisplayAccumulator = (safeZone.targetDisplayAccumulator or 0) + dt
	if shouldRefreshTargetDisplay or safeZone.targetDisplayAccumulator >= 0.15 then
		safeZone.targetDisplayAccumulator = 0
		updateTargetDisplay()
	end
	local safeZoneBlocked = isSafeZoneBlocking()
	if (viewing or autoTpEnabled or flingEnabled) and not manualAttackTpPlayer and not hasSelectedTargetOrPendingPlayer() then
		if viewing then
			stopView()
		end
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
		elseif isDeadTargetModel(currentViewTarget) then
			if currentViewPlayer and currentViewPlayer.Parent == Players then
				local newViewTarget = getTrackedPlayerTargetModel(currentViewPlayer)
				if isValidCamLockTarget(newViewTarget) then
					currentViewTarget = newViewTarget
					local newViewHumanoid = newViewTarget:FindFirstChildOfClass("Humanoid")
					if newViewHumanoid and cam then
						cam.CameraSubject = newViewHumanoid
					end
				elseif hasTrackedSelectedPlayer() and isWaitingForSelectedPlayerRespawn() then
					currentViewPlayer = manualAttackTpPlayer
				else
					stopView()
				end
			elseif hasTrackedSelectedPlayer() and isWaitingForSelectedPlayerRespawn() then
				currentViewPlayer = manualAttackTpPlayer
			else
				stopView()
			end
		elseif currentViewTarget then
			local currentViewHumanoid = currentViewTarget:FindFirstChildOfClass("Humanoid")
			if currentViewHumanoid and cam and cam.CameraSubject ~= currentViewHumanoid then
				cam.CameraSubject = currentViewHumanoid
			end
		end
	end
	if safeZoneBlocked then
		return
	end
	if not autoTpEnabled then
		if pendingTeleportToSelectedPlayer and isValidAttackTpTarget(resolveAttackTpTarget()) then
			teleportToSelectedTarget()
		end
	elseif not flingEnabled then
		local character = player.Character
		local characterRoot = character and character:FindFirstChild("HumanoidRootPart")
		local characterHumanoid = character and character:FindFirstChildOfClass("Humanoid")
		if characterRoot and isAliveHumanoid(characterHumanoid) and not isTpBlocked() then
			local targetModel = resolveAttackTpTarget()
			if isValidAttackTpTarget(targetModel) then
				local targetCFrame, targetVelocity = getAttackTpPlacement(characterRoot, targetModel)
				if targetCFrame then
					applyTeleportRootState(characterRoot, targetCFrame, targetVelocity or Vector3.zero)
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
		local characterHumanoid = character and character:FindFirstChildOfClass("Humanoid")
		if characterRoot and isAliveHumanoid(characterHumanoid) and not isTpBlocked() then
			if manualAttackTpPlayer and manualAttackTpPlayer.Parent ~= Players then
				clearManualAttackTpTarget()
			end
			if not manualAttackTpPlayer and manualAttackTpTarget and isDeadTargetModel(manualAttackTpTarget) then
				clearManualAttackTpTarget()
			end
			if isDeadTargetModel(attackTpTarget) and not manualAttackTpPlayer then
				attackTpTarget = nil
			end
			local preferredTarget = resolveAttackTpTarget()
			if preferredTarget then
				attackTpTarget = preferredTarget
			end
			if isValidAttackTpTarget(attackTpTarget) then
				local targetCFrame, targetVelocity = getAttackTpPlacement(characterRoot, attackTpTarget)
				if targetCFrame and targetVelocity then
					applyTeleportRootState(characterRoot, targetCFrame, targetVelocity)
					if flying and bv and bg then
						bv.Position = characterRoot.Position
						bg.CFrame = getRotationOnlyCFrame(targetCFrame)
					end
				end
			end
		end
	end
	end)
end
task.spawn(function()
	while true do
		nextFrame()
		if safeZone.enabled then
			local character = player.Character
			local characterRoot = character and character:FindFirstChild("HumanoidRootPart")
			local humanoid = character and character:FindFirstChildOfClass("Humanoid")
			if characterRoot and humanoid and humanoid.Health > 0 then
				if safeZone.atDestination and safeZone.savedCFrame and humanoid.Health >= safeZone.returnHp and safeZone.travelMode ~= "return" then
					startSafeZoneTravel(safeZone.savedCFrame, "return", function()
						setNothingXProtectionEnabled(true)
						safeZone.atDestination = false
						safeZone.savedCFrame = nil
						safeZone.pointCurrent = safeZone.pointStart
					end)
				elseif humanoid.Health <= safeZone.lowHp and not safeZone.atDestination and safeZone.travelMode ~= "to_safe" and canSaveSafeZonePosition(character, characterRoot, humanoid) then
					safeZone.savedCFrame = getUprightSetBackCFrame(characterRoot.Position, characterRoot.CFrame)
					safeZone.pointCurrent = safeZone.pointStart
					setNothingXProtectionEnabled(false)
					safeZone.atDestination = true
				elseif safeZone.atDestination and safeZone.savedCFrame then
					local safeDestination = getSafeZoneDestination(safeZone.savedCFrame)
					startSafeZoneTravel(safeDestination, "to_safe")
					safeZone.pointCurrent = math.clamp(safeZone.pointCurrent + safeZone.pointAdd, safeZone.pointStart, safeZone.pointMax)
				end
			end
		elseif safeZone.atDestination and safeZone.savedCFrame and safeZone.travelMode ~= "return" then
			setNothingXProtectionEnabled(true)
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
function startIntroUi()
	local introContent = Instance.new("Frame")
	introContent.Name = "IntroContent"
	introContent.AnchorPoint = Vector2.new(0.5, 0.5)
	introContent.Position = UDim2.fromScale(0.5, 0.5)
	introContent.Size = UDim2.fromScale(0.8, 0.4)
	introContent.BackgroundTransparency = 1
	introContent.Parent = background
	local nothingX = Instance.new("TextLabel")
	nothingX.Name = "NothingX"
	nothingX.AnchorPoint = Vector2.new(0.5, 0.5)
	nothingX.Position = UDim2.fromScale(0.5, 0.45)
	nothingX.Size = UDim2.fromScale(1, 0.3)
	nothingX.BackgroundTransparency = 1
	nothingX.Text = "NOTHING X"
	nothingX.TextColor3 = Color3.fromRGB(0, 0, 0)
	nothingX.Font = Enum.Font.GothamBlack
	nothingX.TextScaled = true
	nothingX.Parent = introContent
	local subtitle = Instance.new("TextLabel")
	subtitle.Name = "SubTitle"
	subtitle.AnchorPoint = Vector2.new(0.5, 0.5)
	subtitle.Position = UDim2.fromScale(0.5, 0.6)
	subtitle.Size = UDim2.fromScale(0.4, 0.1)
	subtitle.BackgroundTransparency = 1
	subtitle.Text = "_X"
	subtitle.TextColor3 = Color3.fromRGB(0, 0, 0)
	subtitle.Font = Enum.Font.GothamBold
	subtitle.TextScaled = true
	subtitle.Parent = introContent
	task.spawn(function()
		task.wait(0.5)
		local colorTweenInfo = TweenInfo.new(2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
		TweenService:Create(nothingX, colorTweenInfo, { TextColor3 = Color3.fromRGB(255, 0, 0) }):Play()
		TweenService:Create(subtitle, colorTweenInfo, { TextColor3 = Color3.fromRGB(255, 30, 30) }):Play()
		for _ = 1, 6 do
			task.wait(math.random(1, 5) * 0.1)
			nothingX.TextTransparency = 0.3
			subtitle.TextTransparency = 0.3
			task.wait(0.05)
			nothingX.TextTransparency = 0
			subtitle.TextTransparency = 0
		end
	end)
	task.delay(4, function()
		local fadeInfo = TweenInfo.new(1.5, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
		TweenService:Create(background, fadeInfo, {
			BackgroundTransparency = 1,
		}):Play()
		for _, child in ipairs(introContent:GetDescendants()) do
			if child:IsA("TextLabel") then
				TweenService:Create(child, fadeInfo, { TextTransparency = 1 }):Play()
			elseif child:IsA("Frame") then
				TweenService:Create(child, fadeInfo, { BackgroundTransparency = 1 }):Play()
			end
		end
		task.wait(1.5)
		introContent:Destroy()
		background:Destroy()
		introFinished = true
		keybindFrame.Visible = true
		targetFrame.Visible = false
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
end
startIntroUi()
task.spawn(function()
if game.GameId ~= 3808081382 then
    return
end
local Players = game:GetService("Players")
local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")
local alreadyDestroyed = {}
local function destroyOnce(obj)
    if not obj or alreadyDestroyed[obj] then return end
    pcall(function()
        if obj and obj.Parent then
            alreadyDestroyed[obj] = true
            obj:Destroy()
        end
    end)
end
local function findPath(timeout, ...)
    local path = {...}
    local start = tick()
    while tick() - start < timeout do
        local obj = path[1]
        local failed = false
        for i = 2, #path do
            obj = obj and obj:FindFirstChild(path[i])
            if not obj then
                failed = true
                break
            end
        end
        if not failed and obj then
            return obj
        end
        task.wait(0.25)
    end
    return nil
end
local function destroyAllByName(parent, name)
    if not parent then return end
    for _, v in ipairs(parent:GetDescendants()) do
        if v.Name == name then
            destroyOnce(v)
        end
    end
end
local toDestroy = {
    function()
        local emotes = findPath(20, playerGui, "Emotes", "ImageLabel")
        if emotes then
            destroyAllByName(emotes, "fake")
        end
    end,
    function()
        local emotes = findPath(20, playerGui, "Emotes", "ImageLabel")
        if emotes then
            destroyAllByName(emotes, "GamepassTwo")
        end
    end,
    function()
        return findPath(20, playerGui, "Emotes", "ImageLabel", "Switch")
    end,
    function()
        return findPath(20, playerGui, "Emotes", "ImageLabel", "Gamepass")
    end,
    function()
        return findPath(20, playerGui, "Emotes", "ImageLabel", "Limited")
    end,
    function()
        return findPath(20, playerGui, "Emotes", "ImageLabel", "Bulk")
    end,
    function()
        return findPath(20, playerGui, "Version")
    end,
    function()
        local topbar = findPath(20, playerGui, "TopbarPlus", "TopbarContainer")
        if topbar then
            return topbar:GetChildren()[10]
        end
    end,
    function()
        local cosmetics = findPath(20, playerGui, "Cosmetics", "Frame")
        if cosmetics then
            destroyAllByName(cosmetics, "fake")
        end
    end,
    function()
        return findPath(20, playerGui, "Cosmetics", "Frame", "Bulk")
    end,
    function()
        return findPath(20, playerGui, "Gifting")
    end,
}
for _, getObj in ipairs(toDestroy) do
    local obj = getObj()
    if not obj then
    else
        destroyOnce(obj)
    end
end
local currentHotbar = playerGui:WaitForChild("Hotbar", 5)
local currentBar = playerGui:WaitForChild("Bar", 5)
local function hasAnyToolInBackpack()
    if not player.Backpack then return false end
    return #player.Backpack:GetChildren() > 0
end
local runningLoop = false
local function startMainLoop()
    if runningLoop then return end
    runningLoop = true
    task.spawn(function()
        while runningLoop do
            if isWaitingForNewGui then
                task.wait(0.1)
                continue
            end
            task.wait()
            if not hasAnyToolInBackpack() then
                runningLoop = false
                break
            end
            local magicHealth = currentBar and currentBar:FindFirstChild("MagicHealth")
            if not magicHealth then continue end
            local freecam     = playerGui:FindFirstChild("Freecam")
            local lock        = playerGui:FindFirstChild("Lock")
            local mobileJunk  = playerGui:FindFirstChild("MobileJunk")
            local magicUlt    = magicHealth:FindFirstChild("Ult")
            local magicText   = magicHealth:FindFirstChild("TextLabel")
            local magicButton = magicHealth:FindFirstChild("ImageButton")
            if freecam    then destroyOnce(freecam) end
            if lock       then destroyOnce(lock) end
            if mobileJunk then destroyOnce(mobileJunk) end
            if magicUlt    then destroyOnce(magicUlt) end
            if magicText   then destroyOnce(magicText) end
            if magicButton then destroyOnce(magicButton) end
            if magicUlt and (magicUlt:IsA("ImageLabel") or magicUlt:IsA("ImageButton")) then
                local ultimateValue = player:GetAttribute("Ultimate") or 0
                magicUlt.ImageTransparency = (ultimateValue == 100) and 0.33 or 0.5
            end
            local healthSection = magicHealth:FindFirstChild("Health")
            local specialBar = healthSection and healthSection:FindFirstChild("Bar") 
                and healthSection.Bar:FindFirstChild("Bar")
            if specialBar and (specialBar:IsA("ImageLabel") or specialBar:IsA("ImageButton")) then
                local ultimateValue = player:GetAttribute("Ultimate") or 0
                specialBar.ImageTransparency = (ultimateValue == 100) and 0.1 or 0.5
                specialBar.ImageColor3 = Color3.new(0, 0, 0)
            end
            local cooldown = currentHotbar and currentHotbar:FindFirstChild("Backpack")
                and currentHotbar.Backpack:FindFirstChild("LocalScript")
                and currentHotbar.Backpack.LocalScript:FindFirstChild("Cooldown")
            if cooldown then
                cooldown.BackgroundColor3 = Color3.new(0, 0, 0)
                cooldown.BackgroundTransparency = 0.45
            end
        end
    end)
end
local function updateCurrentGui()
    isWaitingForNewGui = true
    task.wait(0.5)
    currentHotbar = playerGui:WaitForChild("Hotbar", 5)
    currentBar = playerGui:WaitForChild("Bar", 5)
    isWaitingForNewGui = false
end
playerGui.ChildRemoved:Connect(function(child)
    if child.Name == "Hotbar" or child.Name == "Bar" then
        updateCurrentGui()
    end
end)
player.CharacterAdded:Connect(function()
    updateCurrentGui()
end)
task.spawn(function()
    while true do
        syncPlacesKeybindDisplay()
        syncGetTrashKeybindDisplay()
        syncMovementDisplay()
        task.wait(1)
    end
end)
task.spawn(function()
    while true do
        if hasAnyToolInBackpack() then
            startMainLoop()
        end
        task.wait(0.2) 
    end
end)
updateCurrentGui()
end)
