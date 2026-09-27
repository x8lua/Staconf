local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local HttpService = game:GetService("HttpService")
local VirtualInputManager = game:GetService("VirtualInputManager")

local Staconf
if type(readfile) == "function" and type(isfile) == "function" and isfile("init.luau") then
	local ok, res = pcall(function()
		return loadstring(readfile("init.luau"))()
	end)
	if ok and res then
		Staconf = res
	end
end
if not Staconf then
	Staconf = loadstring(game:HttpGetAsync("https://raw.githubusercontent.com/x8lua/Staconf/main/init.luau"))()
end

local appAlive = true
local connections = {}
local function addConnection(conn)
	table.insert(connections, conn)
end

local flightActive = false
local flightSpeed = 65
local flightAttachment = nil
local flightLinearVelocity = nil
local flightAlignOrientation = nil
local flightConn = nil

local aimAssistActive = false
local aimConn = nil

local autoParryActive = false
local parryRange = 11
local parryAngle = 70
local parryLeadMs = 60
local parryHoldMs = 240
local lastParryTime = 0
local recentParryTokens = {}

local autoSharpenActive = false
local autoMopActive = false
local autoWorkoutActive = false
local autoStompActive = false

local staffAlertActive = true
local staffAutoLeaveActive = false

local toggleKey = Enum.KeyCode.RightControl
local isVisible = true

local validAttackMoves = {
	M1 = true,
	M2 = true,
	M3 = true,
	M4 = true,
	Super = true,
	Dropkick = true,
	Heavy = true,
	Light = true,
	Ability = true,
	Smash = true
}

local knownAttackAnimIds = {
	["132696391693783"] = true,
	["140627732661032"] = true,
	["84854874738019"] = true,
	["136863484307793"] = true,
	["103893003384506"] = true
}

local function triggerParry()
	local now = os.clock()
	if now - lastParryTime < 0.28 then return end
	lastParryTime = now
	pcall(function()
		VirtualInputManager:SendKeyEvent(true, Enum.KeyCode.F, false, game)
		task.delay(parryHoldMs / 1000, function()
			pcall(function()
				VirtualInputManager:SendKeyEvent(false, Enum.KeyCode.F, false, game)
			end)
		end)
	end)
end

local function isPlayerStaff(plr)
	if not plr then return false end
	if plr:GetAttribute("IsGameModerator") == true or plr:GetAttribute("HasModPanelAccess") == true then
		return true, "Moderator"
	end
	local level = plr:GetAttribute("GroupStaffLevel")
	if level and level ~= "" and level ~= "None" then
		return true, tostring(level)
	end
	if plr:GetAttribute("IsGameOwner") == true or plr.UserId == 10169054892 then
		return true, "Owner"
	end
	local ok, inGroup = pcall(function() return plr:IsInGroup(180089436) end)
	if ok and inGroup then
		local okRank, rank = pcall(function() return plr:GetRankInGroup(180089436) end)
		if okRank and rank and rank >= 249 then
			local map = {
				[255] = "Project Lead",
				[254] = "Official Manager",
				[253] = "Official Admin",
				[252] = "Official Sr Staff",
				[251] = "Official Staff",
				[250] = "Official Jr Staff",
				[249] = "Creator Manager"
			}
			return true, map[rank] or ("Rank " .. tostring(rank))
		end
	end
	return false
end

local function setFlight(enabled)
	flightActive = enabled
	local lp = Players.LocalPlayer
	local char = lp and lp.Character
	local hrp = char and char:FindFirstChild("HumanoidRootPart")
	local hum = char and char:FindFirstChildOfClass("Humanoid")
	if not enabled then
		if flightLinearVelocity then flightLinearVelocity:Destroy(); flightLinearVelocity = nil end
		if flightAlignOrientation then flightAlignOrientation:Destroy(); flightAlignOrientation = nil end
		if flightAttachment then flightAttachment:Destroy(); flightAttachment = nil end
		if flightConn then flightConn:Disconnect(); flightConn = nil end
		if hum and hum.Health > 0 then
			hum.PlatformStand = false
			hum:ChangeState(Enum.HumanoidStateType.GettingUp)
		end
		return
	end
	if not hrp or not hum or hum.Health <= 0 then return end
	hum.PlatformStand = true
	flightAttachment = Instance.new("Attachment")
	flightAttachment.Name = "StaconfFlightAttachment"
	flightAttachment.Parent = hrp
	flightLinearVelocity = Instance.new("LinearVelocity")
	flightLinearVelocity.Name = "StaconfFlightVelocity"
	flightLinearVelocity.Attachment0 = flightAttachment
	flightLinearVelocity.RelativeTo = Enum.ActuatorRelativeTo.World
	flightLinearVelocity.VelocityConstraintMode = Enum.VelocityConstraintMode.Vector
	flightLinearVelocity.MaxForce = math.huge
	flightLinearVelocity.Parent = hrp
	flightAlignOrientation = Instance.new("AlignOrientation")
	flightAlignOrientation.Name = "StaconfFlightOrientation"
	flightAlignOrientation.Attachment0 = flightAttachment
	flightAlignOrientation.Mode = Enum.OrientationAlignmentMode.OneAttachment
	flightAlignOrientation.Responsiveness = 22
	flightAlignOrientation.MaxTorque = math.huge
	flightAlignOrientation.Parent = hrp
	flightConn = RunService.PreSimulation:Connect(function()
		if not flightActive or not flightLinearVelocity or not hrp or not hum or hum.Health <= 0 then return end
		local cam = workspace.CurrentCamera
		if not cam then return end
		local moveDir = hum.MoveDirection
		local up = 0
		if UserInputService:IsKeyDown(Enum.KeyCode.Space) then up = up + 1 end
		if UserInputService:IsKeyDown(Enum.KeyCode.LeftControl) or UserInputService:IsKeyDown(Enum.KeyCode.RightControl) then up = up - 1 end
		local unit = moveDir + Vector3.new(0, up, 0)
		if unit.Magnitude > 1 then unit = unit.Unit end
		flightLinearVelocity.VectorVelocity = unit * flightSpeed
		local look = cam.CFrame.LookVector
		local flat = Vector3.new(look.X, 0, look.Z)
		if flat.Magnitude > 0.001 then
			flightAlignOrientation.CFrame = CFrame.lookAt(Vector3.zero, flat.Unit)
		end
	end)
end

local function setAimAssist(enabled)
	aimAssistActive = enabled
	if not enabled then
		if aimConn then aimConn:Disconnect(); aimConn = nil end
		return
	end
	aimConn = RunService.RenderStepped:Connect(function()
		if not aimAssistActive then return end
		local cam = workspace.CurrentCamera
		local lp = Players.LocalPlayer
		local char = lp and lp.Character
		local hrp = char and char:FindFirstChild("HumanoidRootPart")
		if not cam or not hrp then return end
		local bestTarget, bestDist = nil, 280
		for _, plr in ipairs(Players:GetPlayers()) do
			if plr ~= lp and plr.Character then
				local eHrp = plr.Character:FindFirstChild("HumanoidRootPart")
				local eHum = plr.Character:FindFirstChildOfClass("Humanoid")
				if eHrp and eHum and eHum.Health > 0 and plr.Character:GetAttribute("NG_Dead") ~= true then
					local screenPt, onScreen = cam:WorldToViewportPoint(eHrp.Position)
					if onScreen then
						local mousePos = UserInputService:GetMouseLocation()
						local dist = (Vector2.new(screenPt.X, screenPt.Y) - mousePos).Magnitude
						if dist < bestDist then
							bestDist = dist
							bestTarget = eHrp
						end
					end
				end
			end
		end
		if bestTarget then
			cam.CFrame = cam.CFrame:Lerp(CFrame.lookAt(cam.CFrame.Position, bestTarget.Position), 0.2)
		end
	end)
end

local combatRemotes = ReplicatedStorage:FindFirstChild("CombatRemotes")
local combatFeedback = combatRemotes and combatRemotes:FindFirstChild("CombatFeedback")
if combatFeedback then
	local fbConn = combatFeedback.OnClientEvent:Connect(function(event, data)
		if not autoParryActive then return end
		if event ~= "StyleVisual" or typeof(data) ~= "table" or data.Cue ~= "Action" then return end
		local eChar = data.Character
		local lp = Players.LocalPlayer
		local myChar = lp and lp.Character
		if not eChar or eChar == myChar then return end
		if myChar:GetAttribute("NG_Dead") == true or myChar:GetAttribute("NG_Knocked") == true then return end
		local move = tostring(data.Move or "")
		if not validAttackMoves[move] and not move:find("M%d") and not move:find("Punch") and not move:find("Attack") then
			return
		end
		local eHrp = eChar:FindFirstChild("HumanoidRootPart")
		local myHrp = myChar and myChar:FindFirstChild("HumanoidRootPart")
		if not eHrp or not myHrp then return end
		local dir = myHrp.Position - eHrp.Position
		local dist = dir.Magnitude
		if dist > parryRange then return end
		local flatDir = Vector3.new(dir.X, 0, dir.Z)
		if flatDir.Magnitude < 0.05 then return end
		flatDir = flatDir.Unit
		local look = Vector3.new(eHrp.CFrame.LookVector.X, 0, eHrp.CFrame.LookVector.Z).Unit
		local minDot = math.cos(math.rad(parryAngle))
		if look:Dot(flatDir) < minDot then return end
		local token = tostring(data.ActionToken or data.ClientActionId or (eChar.Name .. ":" .. move .. ":" .. tostring(data.ExpectedContactAt)))
		if recentParryTokens[token] then return end
		recentParryTokens[token] = true
		task.delay(0.6, function()
			recentParryTokens[token] = nil
		end)
		local now = workspace:GetServerTimeNow()
		local contactAt = tonumber(data.ExpectedContactAt)
		local waitSeconds = 0
		if contactAt and contactAt > now then
			waitSeconds = math.clamp(contactAt - now - (parryLeadMs / 1000), 0, 0.45)
		end
		if waitSeconds <= 0.01 then
			triggerParry()
		else
			task.delay(waitSeconds, function()
				if autoParryActive and eChar.Parent and myChar.Parent then
					local curDist = (myHrp.Position - eHrp.Position).Magnitude
					if curDist <= parryRange + 2 then
						triggerParry()
					end
				end
			end)
		end
	end)
	addConnection(fbConn)
end

local animScanConn = RunService.Heartbeat:Connect(function()
	if not autoParryActive then return end
	local lp = Players.LocalPlayer
	local myChar = lp and lp.Character
	local myHrp = myChar and myChar:FindFirstChild("HumanoidRootPart")
	if not myHrp or myChar:GetAttribute("NG_Dead") == true or myChar:GetAttribute("NG_Knocked") == true then return end
	for _, plr in ipairs(Players:GetPlayers()) do
		if plr ~= lp and plr.Character then
			local eChar = plr.Character
			local eHrp = eChar:FindFirstChild("HumanoidRootPart")
			local eHum = eChar:FindFirstChildOfClass("Humanoid")
			if eHrp and eHum and eHum.Health > 0 and eChar:GetAttribute("NG_Dead") ~= true and eChar:GetAttribute("NG_Knocked") ~= true then
				local dir = myHrp.Position - eHrp.Position
				local dist = dir.Magnitude
				if dist <= parryRange then
					local flatDir = Vector3.new(dir.X, 0, dir.Z)
					if flatDir.Magnitude >= 0.05 then
						flatDir = flatDir.Unit
						local look = Vector3.new(eHrp.CFrame.LookVector.X, 0, eHrp.CFrame.LookVector.Z).Unit
						local minDot = math.cos(math.rad(parryAngle))
						if look:Dot(flatDir) >= minDot then
							local animator = eHum:FindFirstChildOfClass("Animator")
							if animator then
								for _, track in ipairs(animator:GetPlayingAnimationTracks()) do
									local anim = track.Animation
									local id = anim and anim.AnimationId:match("%d+")
									if id and knownAttackAnimIds[id] then
										local token = eChar.Name .. ":" .. id .. ":" .. tostring(math.floor(track.TimePosition * 10))
										if not recentParryTokens[token] and track.TimePosition <= 0.16 then
											recentParryTokens[token] = true
											task.delay(0.5, function() recentParryTokens[token] = nil end)
											triggerParry()
											break
										end
									end
								end
							end
						end
					end
				end
			end
		end
	end
end)
addConnection(animScanConn)

task.spawn(function()
	while appAlive do
		task.wait(1.5)
		if autoSharpenActive then
			pcall(function()
				local r = ReplicatedStorage:FindFirstChild("ForkRemotes") and ReplicatedStorage.ForkRemotes:FindFirstChild("Sharpen")
				if r then r:FireServer() end
			end)
		end
		if autoMopActive then
			pcall(function()
				local r = ReplicatedStorage:FindFirstChild("JanitorRemotes") and ReplicatedStorage.JanitorRemotes:FindFirstChild("Mop")
				if r then r:FireServer() end
			end)
		end
		if autoWorkoutActive then
			pcall(function()
				local r = ReplicatedStorage:FindFirstChild("Remotes") and ReplicatedStorage.Remotes:FindFirstChild("WorkoutAction")
				if r then r:FireServer() end
			end)
		end
		if autoStompActive then
			pcall(function()
				local lp = Players.LocalPlayer
				local char = lp and lp.Character
				local hrp = char and char:FindFirstChild("HumanoidRootPart")
				if hrp then
					for _, plr in ipairs(Players:GetPlayers()) do
						if plr ~= lp and plr.Character and plr.Character:GetAttribute("NG_Knocked") == true then
							local eHrp = plr.Character:FindFirstChild("HumanoidRootPart")
							if eHrp and (eHrp.Position - hrp.Position).Magnitude < 10 then
								local r = ReplicatedStorage:FindFirstChild("CombatRemotes") and ReplicatedStorage.CombatRemotes:FindFirstChild("CombatRequest")
								if r then r:FireServer("Stomp") end
							end
						end
					end
				end
			end)
		end
	end
end)

local function cleanupAll()
	appAlive = false
	for _, c in ipairs(connections) do
		pcall(function() c:Disconnect() end)
	end
	connections = {}
	recentParryTokens = {}
	setFlight(false)
	setAimAssist(false)
	autoParryActive = false
	local lp = Players.LocalPlayer
	if lp then
		pcall(function()
			lp:SetAttribute("ModerationESP", false)
			lp:SetAttribute("ModerationHealthESP", false)
			lp:SetAttribute("NG_ShowNameplates", false)
			lp:SetAttribute("NG_FastRunning", false)
			lp:SetAttribute("NG_CombatStanceActive", false)
		end)
	end
end

local ui = Staconf.new({
	Title = "Komorebi Prison",
	Subtitle = "Staconf Suite",
	Theme = "Dark",
	Accent = "Blue",
	OnDestroy = cleanupAll
})
ui:RevealBootProgress()
ui:SetBootProgress(0.25)

local playerAddConn = Players.PlayerAdded:Connect(function(plr)
	if staffAlertActive then
		task.wait(1)
		local isStaff, role = isPlayerStaff(plr)
		if isStaff then
			ui:Notify({
				Title = "Staff Alert",
				Subtitle = plr.DisplayName .. " (" .. role .. ") joined the game",
				Duration = 6
			})
			if staffAutoLeaveActive then
				game:Shutdown()
			end
		end
	end
end)
addConnection(playerAddConn)

local staffTab = ui:AddTab({Title = "Staff", Selected = true})
local staffMonitor = staffTab:PageSection({Title = "Mod Monitor"}):Form()
local staffProtect = staffTab:PageSection({Title = "Protection"}):Form()

ui:Toggle(staffMonitor, {
	Title = "Staff Presence Alert",
	Subtitle = "Notify when moderators or staff join",
	Value = staffAlertActive,
	OnChange = function(v)
		staffAlertActive = v
	end
})

ui:Button(staffMonitor, {
	Title = "Scan Active Server Staff",
	Subtitle = "Check current players for staff privileges",
	Style = "Primary",
	OnClick = function()
		local found = {}
		for _, p in ipairs(Players:GetPlayers()) do
			local ok, role = isPlayerStaff(p)
			if ok then
				table.insert(found, p.DisplayName .. " [" .. tostring(role) .. "]")
			end
		end
		if #found == 0 then
			ui:Notify({Title = "Staff Scan", Subtitle = "0 Staff detected online", Duration = 4})
		else
			ui:Dialog({
				Title = "Staff Detected",
				Description = table.concat(found, "\n"),
				Buttons = {{Text = "Acknowledge", Style = "Primary"}}
			})
		end
	end
})

ui:Toggle(staffProtect, {
	Title = "Auto-Leave on Staff",
	Subtitle = "Instantly exit game if staff is detected",
	Value = staffAutoLeaveActive,
	OnChange = function(v)
		staffAutoLeaveActive = v
	end
})

ui:SetBootProgress(0.45)

local visualsTab = ui:AddTab({Title = "Visuals"})
local visualsOverlays = visualsTab:PageSection({Title = "Native Overlays"}):Form()
local visualsSensors = visualsTab:PageSection({Title = "Prison Sensors"}):Form()

ui:Toggle(visualsOverlays, {
	Title = "Moderator ESP Highlight",
	Subtitle = "Native neon player highlights",
	Value = false,
	OnChange = function(v)
		local lp = Players.LocalPlayer
		if lp then lp:SetAttribute("ModerationESP", v) end
	end
})

ui:Toggle(visualsOverlays, {
	Title = "Moderator Health ESP",
	Subtitle = "Native overhead health gradients",
	Value = false,
	OnChange = function(v)
		local lp = Players.LocalPlayer
		if lp then lp:SetAttribute("ModerationHealthESP", v) end
	end
})

ui:Toggle(visualsSensors, {
	Title = "Always Show Nametags",
	Subtitle = "Force player overhead nametags active",
	Value = true,
	OnChange = function(v)
		local lp = Players.LocalPlayer
		if lp then lp:SetAttribute("NG_ShowNameplates", v) end
	end
})

ui:SetBootProgress(0.65)

local moveTab = ui:AddTab({Title = "Movement"})
local movePhysics = moveTab:PageSection({Title = "Physics Propulsion"}):Form()
local moveLocomotion = moveTab:PageSection({Title = "Locomotion"}):Form()

ui:Toggle(movePhysics, {
	Title = "3D Vector Flight",
	Subtitle = "Space (Up), Ctrl (Down), WASD (Move)",
	Value = false,
	OnChange = function(v)
		setFlight(v)
	end
})

ui:Slider(movePhysics, {
	Title = "Flight Speed",
	Subtitle = "Linear velocity magnitude",
	Minimum = 10,
	Maximum = 160,
	Value = 65,
	OnChange = function(v)
		flightSpeed = v
		local lp = Players.LocalPlayer
		if lp then lp:SetAttribute("ModerationFlySpeed", v) end
	end
})

ui:Toggle(moveLocomotion, {
	Title = "Fast Run Boost",
	Subtitle = "Continuous high-speed sprint velocity",
	Value = false,
	OnChange = function(v)
		local lp = Players.LocalPlayer
		if lp then lp:SetAttribute("NG_FastRunning", v) end
	end
})

ui:Toggle(moveLocomotion, {
	Title = "Auto Sprint Assist",
	Subtitle = "Automatically sprint on forward movement",
	Value = true,
	OnChange = function(v)
		local lp = Players.LocalPlayer
		if lp then lp:SetAttribute("Setting_ControllerAutoSprint", v) end
	end
})

ui:SetBootProgress(0.8)

local combatTab = ui:AddTab({Title = "Combat"})
local combatTarget = combatTab:PageSection({Title = "Targeting"}):Form()
local combatDefense = combatTab:PageSection({Title = "Defense & Counters"}):Form()
local combatSkills = combatTab:PageSection({Title = "Stance & Skills"}):Form()
local combatFinisher = combatTab:PageSection({Title = "Finisher"}):Form()

ui:Toggle(combatTarget, {
	Title = "Camera Aim Assist",
	Subtitle = "Smooth camera target lock to nearest target",
	Value = false,
	OnChange = function(v)
		setAimAssist(v)
	end
})

ui:Toggle(combatDefense, {
	Title = "Auto Parry",
	Subtitle = "Parry real strikes directly targeting you",
	Value = false,
	OnChange = function(v)
		autoParryActive = v
	end
})

ui:Slider(combatDefense, {
	Title = "Parry Range",
	Subtitle = "Maximum attacker distance in studs",
	Minimum = 6,
	Maximum = 18,
	Value = 11,
	OnChange = function(v)
		parryRange = v
	end
})

ui:Slider(combatDefense, {
	Title = "Facing Cone Angle",
	Subtitle = "Attacker front directional cone in degrees",
	Minimum = 30,
	Maximum = 110,
	Value = 70,
	OnChange = function(v)
		parryAngle = v
	end
})

ui:Slider(combatDefense, {
	Title = "Parry Lead Time",
	Subtitle = "Trigger offset before contact in milliseconds",
	Minimum = 10,
	Maximum = 120,
	Value = 60,
	OnChange = function(v)
		parryLeadMs = v
	end
})

ui:Slider(combatDefense, {
	Title = "Parry Hold Window",
	Subtitle = "Block duration in milliseconds",
	Minimum = 150,
	Maximum = 350,
	Value = 240,
	OnChange = function(v)
		parryHoldMs = v
	end
})

ui:Toggle(combatSkills, {
	Title = "Combat Stance Lock",
	Subtitle = "Maintain combat readiness state",
	Value = false,
	OnChange = function(v)
		local lp = Players.LocalPlayer
		if lp then lp:SetAttribute("NG_CombatStanceActive", v) end
	end
})

ui:Button(combatSkills, {
	Title = "Buff Smash Shockwave",
	Subtitle = "Trigger server combat BuffSmash remote",
	Style = "Primary",
	OnClick = function()
		pcall(function()
			local r = ReplicatedStorage:FindFirstChild("Remotes") and ReplicatedStorage.Remotes:FindFirstChild("BuffSmash")
			if r then r:FireServer() end
		end)
		ui:Notify({Title = "Combat", Subtitle = "Buff Smash Executed", Duration = 3})
	end
})

ui:Toggle(combatFinisher, {
	Title = "Auto Stomp Knocked",
	Subtitle = "Automatically stomp nearby downed targets",
	Value = false,
	OnChange = function(v)
		autoStompActive = v
	end
})

local prisonTab = ui:AddTab({Title = "Prison"})
local prisonJobs = prisonTab:PageSection({Title = "Automations"}):Form()
local prisonGrid = prisonTab:PageSection({Title = "Facility Grid"}):Form()

ui:Toggle(prisonJobs, {
	Title = "Auto Fork Sharpening",
	Subtitle = "Grind cafeteria forks into contraband shanks",
	Value = false,
	OnChange = function(v)
		autoSharpenActive = v
	end
})

ui:Toggle(prisonJobs, {
	Title = "Auto Janitor Mopping",
	Subtitle = "Automate floor cleaning job for yen",
	Value = false,
	OnChange = function(v)
		autoMopActive = v
	end
})

ui:Toggle(prisonJobs, {
	Title = "Auto Gym Workout",
	Subtitle = "Automate gym exercise reps to gain strength",
	Value = false,
	OnChange = function(v)
		autoWorkoutActive = v
	end
})

ui:Button(prisonGrid, {
	Title = "Toggle Cell Door Lock",
	Subtitle = "Toggle assigned cell block door state",
	Style = "Secondary",
	OnClick = function()
		pcall(function()
			local r = ReplicatedStorage:FindFirstChild("CellDoorRemotes") and ReplicatedStorage.CellDoorRemotes:FindFirstChild("DoorLockCommand")
			if r then r:FireServer() end
		end)
		ui:Notify({Title = "Facility", Subtitle = "Cell Door Toggled", Duration = 3})
	end
})

ui:Button(prisonGrid, {
	Title = "Security Grid Blackout",
	Subtitle = "Cut prison main power grid",
	Style = "Primary",
	OnClick = function()
		pcall(function()
			local r = ReplicatedStorage:FindFirstChild("SecurityRemotes") and ReplicatedStorage.SecurityRemotes:FindFirstChild("CutPower")
			if r then r:FireServer() end
		end)
		ui:Notify({Title = "Facility", Subtitle = "Grid Power Severed", Duration = 3})
	end
})

local settingsTab = ui:AddTab({Title = "Settings"})
local settingsSystem = settingsTab:PageSection({Title = "System & Keybinds"}):Form()
local settingsLifecycle = settingsTab:PageSection({Title = "Lifecycle"}):Form()

ui:Keybind(settingsSystem, {
	Title = "Toggle UI Keybind",
	Subtitle = "Summon or dismiss this console window",
	Value = toggleKey,
	OnChange = function(k)
		toggleKey = k
	end
})

ui:Dropdown(settingsSystem, {
	Title = "Theme Mode",
	Subtitle = "Cascade visual theme",
	Options = {"Dark", "Light"},
	Value = "Dark",
	OnChange = function(m)
		ui:SetTheme(m)
	end
})

ui:Dropdown(settingsSystem, {
	Title = "Accent Color",
	Subtitle = "Cascade accent tint",
	Options = {"Blue", "Green", "Red", "Purple", "Orange"},
	Value = "Blue",
	OnChange = function(a)
		ui:SetTheme(ui.Mode, a)
	end
})

ui:Button(settingsLifecycle, {
	Title = "Unload Staconf",
	Subtitle = "Safely disconnect all threads and close UI",
	Style = "Secondary",
	OnClick = function()
		ui:Destroy()
	end
})

local inputConn = UserInputService.InputBegan:Connect(function(input, processed)
	if processed then return end
	if input.KeyCode == toggleKey then
		isVisible = not isVisible
		ui:SetVisible(isVisible)
	end
end)
addConnection(inputConn)

ui:SetBootProgress(1)
ui:FinishBoot()

return ui
