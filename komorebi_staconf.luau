local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local HttpService = game:GetService("HttpService")

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

local autoSharpenActive = false
local autoMopActive = false
local autoWorkoutActive = false
local autoStompActive = false

local staffAlertActive = true
local staffAutoLeaveActive = false

local toggleKey = Enum.KeyCode.RightControl
local isVisible = true

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
	setFlight(false)
	setAimAssist(false)
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
