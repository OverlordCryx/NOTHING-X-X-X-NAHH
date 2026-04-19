local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")
local player = Players.LocalPlayer
_G.NOTHINGX_Protection = _G.NOTHINGX_Protection or {}
_G.NOTHINGX_Protection.Enabled = true
_G.NOTHINGX_Protection.boundarySize = Vector3.new(200000, 0, 200000)   
local Y_BOUNDARY_UP = 200000          
local EXTREME_LOW_OFFSET = -1000    
local VOID_BUFFER = 90
local VOID_Y = nil
local SAVE_INTERVAL = 3.0
local MIN_DISTANCE_TO_SAVE = 7
_G.NOTHINGX_Protection.safePositionHistory = {}
_G.NOTHINGX_Protection.lastSafePosition = nil
_G.NOTHINGX_Protection.lastSaveTime = 0
local function detectVoidY()
	local official = Workspace.FallenPartsDestroyHeight
	if official and official > -500000 and official < 10000 then
		VOID_Y = official
	else
		local lowest = 200
		for i = 1, 6 do
			local probe = Instance.new("Part")
			probe.Size = Vector3.new(8,8,8)
			probe.Position = Vector3.new(0, 600, 0)
			probe.Anchored = false
			probe.CanCollide = false
			probe.Transparency = 1
			probe.Parent = Workspace
			task.wait(1.8)
			if probe and probe.Parent then
				lowest = math.min(lowest, probe.Position.Y)
				probe:Destroy()
			end
			task.wait(0.3)
		end
		VOID_Y = lowest - 90
	end
	_G.NOTHINGX_Protection.EXTREME_LOW_Y = VOID_Y + EXTREME_LOW_OFFSET
end
detectVoidY()
local function getReferenceCFrame()
	local map = Workspace:FindFirstChild("Map")
	if map then
		local main = map:FindFirstChild("MainPart")
		if main then return main.CFrame end
	end
	if player.Character and player.Character:FindFirstChild("HumanoidRootPart") then
		local hrp = player.Character.HumanoidRootPart
		return CFrame.new(hrp.Position.X, 200, hrp.Position.Z)
	end
	return _G.NOTHINGX_Protection.defaultCFrame
end
function _G.NOTHINGX_Protection.isOutsideBoundary(pos)
	local cf = getReferenceCFrame()
	local localPos = cf:PointToObjectSpace(pos)
	local half = _G.NOTHINGX_Protection.boundarySize / 2
	return math.abs(localPos.X) > half.X 
		or math.abs(localPos.Z) > half.Z 
		or pos.Y > Y_BOUNDARY_UP        
end
local function isAnyObjectBelow(hrp)
	if not hrp or not hrp.Parent then return false end
	local params = RaycastParams.new()
	params.FilterDescendantsInstances = {hrp.Parent}
	params.FilterType = Enum.RaycastFilterType.Exclude
	local result = Workspace:Raycast(hrp.Position + Vector3.new(0, 6, 0), Vector3.new(0, -35, 0), params)
	return result ~= nil
end
local function saveSafePosition(hrp)
	if not hrp then return end
	if _G.NOTHINGX_Protection.isOutsideBoundary(hrp.Position) then return end
	if not isAnyObjectBelow(hrp) then return end
	local now = tick()
	if now - (_G.NOTHINGX_Protection.lastSaveTime or 0) < SAVE_INTERVAL then return end
	local lastPos = _G.NOTHINGX_Protection.lastSafePosition
	if lastPos and (lastPos.Position - hrp.Position).Magnitude < MIN_DISTANCE_TO_SAVE then
		return
	end
	_G.NOTHINGX_Protection.lastSafePosition = hrp.CFrame
	_G.NOTHINGX_Protection.lastSaveTime = now
	table.insert(_G.NOTHINGX_Protection.safePositionHistory, 1, hrp.CFrame)
	if #_G.NOTHINGX_Protection.safePositionHistory > 10 then
		table.remove(_G.NOTHINGX_Protection.safePositionHistory)
	end
end
local function getRescueCFrame()
	if _G.NOTHINGX_Protection.lastSafePosition then
		return _G.NOTHINGX_Protection.lastSafePosition + Vector3.new(0, 8, 0)
	end
	for _, cf in ipairs(_G.NOTHINGX_Protection.safePositionHistory) do
		if cf then return cf + Vector3.new(0, 8, 0) end
	end
	return getReferenceCFrame() + Vector3.new(0, 180, 0)
end
local function tpBack(char, hrp, reason)
	_G.SafeTeleportLock = true
	local target = getRescueCFrame()
	for i = 1, 222 do
		hrp.AssemblyLinearVelocity = Vector3.zero
		hrp.AssemblyAngularVelocity = Vector3.zero
		char:PivotTo(target)
		task.wait()
	end
	hrp.AssemblyLinearVelocity = Vector3.zero
	hrp.AssemblyAngularVelocity = Vector3.zero
	task.wait(0.03)
	_G.SafeTeleportLock = false
end
task.spawn(function()
	while true do
		task.wait()
		if not _G.NOTHINGX_Protection.Enabled then continue end
		local char = player.Character
		if not char then continue end
		local hrp = char:FindFirstChild("HumanoidRootPart")
		if not hrp then continue end
		if _G.NOTHINGX_FlyActive == true then
			saveSafePosition(hrp)
			continue
		end
		saveSafePosition(hrp)
		local y = hrp.Position.Y
		if _G.NOTHINGX_Protection.isOutsideBoundary(hrp.Position) then
			tpBack(char, hrp, "")
			continue
		end
		if y < _G.NOTHINGX_Protection.EXTREME_LOW_Y then
			tpBack(char, hrp, "")
			continue
		end
		local minSafeY = VOID_Y and (VOID_Y + VOID_BUFFER) or -999999
		if y < minSafeY then
			tpBack(char, hrp, "")
		end
	end
end)
print("=== ACTIVE ===")
print("(-) " .. VOID_Y .. " (-)")
