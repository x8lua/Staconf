local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local GuiService = game:GetService("GuiService")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")

local function getGuiContainer()
	local localPlayer = Players.LocalPlayer
	local playerGui = localPlayer and localPlayer:FindFirstChildOfClass("PlayerGui")
	if playerGui then
		return playerGui
	end
	local hui = (typeof(gethui) == "function" and gethui())
	if hui and not (hui:IsA("ScreenGui") or hui:IsA("LayerCollector")) then
		return hui
	end
	return game:GetService("CoreGui")
end

local function runConsoleApp(stateContext)
	local container = getGuiContainer()
	local existing = container:FindFirstChild("ConsolePrototypeGui")
	if existing then
		existing:Destroy()
	end
	pcall(function()
		local oldCore = game:GetService("CoreGui"):FindFirstChild("PrototypeConsoleDemo")
		if oldCore then oldCore:Destroy() end
		local oldPlr = Players.LocalPlayer and Players.LocalPlayer:FindFirstChild("PlayerGui") and Players.LocalPlayer.PlayerGui:FindFirstChild("PrototypeConsoleDemo")
		if oldPlr then oldPlr:Destroy() end
	end)

	local cleanupList = {}
	local function addCleanup(target)
		table.insert(cleanupList, target)
	end

	local appAlive = true
	local screenGui

	local function cancelAll()
		appAlive = false
		for i = #cleanupList, 1, -1 do
			local item = cleanupList[i]
			if typeof(item) == "RBXScriptConnection" then
				pcall(function() item:Disconnect() end)
			elseif typeof(item) == "function" then
				pcall(item)
			end
		end
		cleanupList = {}
		if screenGui and screenGui.Parent then
			pcall(function() screenGui:Destroy() end)
		end
	end

	local colors = {
		bgDeep = Color3.fromRGB(12, 12, 15),
		bgChassis = Color3.fromRGB(16, 16, 21),
		bgHeader = Color3.fromRGB(20, 20, 26),
		bgDock = Color3.fromRGB(22, 22, 29),
		bgCard = Color3.fromRGB(22, 22, 29),
		bgCardHover = Color3.fromRGB(30, 30, 40),
		bgInput = Color3.fromRGB(26, 26, 34),
		bgInputFocus = Color3.fromRGB(36, 36, 48),
		textWhite = Color3.fromRGB(255, 255, 255),
		textSecondary = Color3.fromRGB(195, 198, 212),
		textDim = Color3.fromRGB(120, 124, 140),
		textMuted = Color3.fromRGB(80, 84, 98),
		accent = Color3.fromRGB(59, 130, 246),
		accentBright = Color3.fromRGB(96, 165, 250),
		accentSubtle = Color3.fromRGB(24, 45, 85),
		accentGlider = Color3.fromRGB(30, 58, 110),
		borderWhite = Color3.fromRGB(255, 255, 255),
		borderSubtle = Color3.fromRGB(38, 38, 50),
		borderCard = Color3.fromRGB(44, 44, 56),
		borderActive = Color3.fromRGB(59, 130, 246),
		statusGreen = Color3.fromRGB(86, 216, 144)
	}

	local fonts = {
		regular = Enum.Font.Gotham,
		medium = Enum.Font.GothamMedium,
		bold = Enum.Font.GothamBold
	}

	local currentContentScale = 1.25

	local state = {
		activeCategory = "Controls",
		filter = "All",
		searchQuery = "",
		isCollapsed = false,
		isVisible = true,
		isMobile = false,
		hudVisible = true,
		dockRevealed = false
	}

	local initialItems = {
		{
			id = "hud_toggle",
			category = "Overview",
			group = "TELEMETRY ORBIT",
			title = "Compact Telemetry HUD",
			desc = "Stream system simulation parameters in real time",
			type = "toggle",
			value = true,
			pinned = true
		},
		{
			id = "mock_latency",
			category = "Overview",
			group = "TELEMETRY ORBIT",
			title = "Simulated Buffer Delay",
			desc = "Artificial tick latency injection for prototype testing",
			type = "slider",
			min = 10,
			max = 200,
			step = 5,
			value = 60,
			unit = "ms",
			pinned = false
		},
		{
			id = "perf_mode",
			category = "Overview",
			group = "EXECUTION ARCHITECTURE",
			title = "Dispatch Frequency",
			desc = "Simulation tick priority and cycle budgeting",
			type = "dropdown",
			options = {"Standard (60Hz)", "Responsive (120Hz)", "Power Saver"},
			value = "Standard (60Hz)",
			pinned = false
		},
		{
			id = "quick_queue",
			category = "Controls",
			group = "INPUT VECTORS",
			title = "Quick Action Queue",
			desc = "Buffer high speed inputs during animation recovery",
			type = "toggle",
			value = true,
			pinned = true
		},
		{
			id = "cam_sensitivity",
			category = "Controls",
			group = "INPUT VECTORS",
			title = "Camera Sensitivity",
			desc = "Analog stick and cursor rotational sensitivity",
			type = "slider",
			min = 0.1,
			max = 4.0,
			step = 0.05,
			value = 1.25,
			unit = "x",
			pinned = true
		},
		{
			id = "interact_mode",
			category = "Controls",
			group = "INPUT VECTORS",
			title = "Target Interaction",
			desc = "Activation protocol for interactive environment nodes",
			type = "dropdown",
			options = {"Standard (Press)", "Direct Action (Instant)", "Hold to Confirm"},
			value = "Standard (Press)",
			pinned = false
		},
		{
			id = "auto_sprint",
			category = "Controls",
			group = "LOCOMOTION DYNAMICS",
			title = "Auto Sprint Assist",
			desc = "Engage sprint velocity threshold automatically",
			type = "toggle",
			value = false,
			pinned = false
		},
		{
			id = "directional_dodge",
			category = "Controls",
			group = "LOCOMOTION DYNAMICS",
			title = "Kinetic Directional Dash",
			desc = "Double tap vector keys to perform rapid evasion",
			type = "toggle",
			value = true,
			pinned = false
		},
		{
			id = "stick_deadzone",
			category = "Controls",
			group = "LOCOMOTION DYNAMICS",
			title = "Analog Deadzone",
			desc = "Radial neutral cutoff for directional controllers",
			type = "slider",
			min = 0.0,
			max = 0.4,
			step = 0.02,
			value = 0.12,
			unit = "",
			pinned = false
		},
		{
			id = "key_toggle_ui",
			category = "Controls",
			group = "TRIGGER SHORTCUTS",
			title = "Toggle Console Interface",
			desc = "Global keyboard shortcut to summon interface",
			type = "keybind",
			value = Enum.KeyCode.RightControl,
			pinned = true
		},
		{
			id = "key_quick_focus",
			category = "Controls",
			group = "TRIGGER SHORTCUTS",
			title = "Quick Focus Vector",
			desc = "Re-orient camera perspective toward active target",
			type = "keybind",
			value = Enum.KeyCode.Q,
			pinned = false
		},
		{
			id = "reset_controls",
			category = "Controls",
			group = "TRIGGER SHORTCUTS",
			title = "Reset Prototype Baseline",
			desc = "Restore all parameters to initial factory default",
			type = "button",
			actionText = "Reset All",
			pinned = false
		},
		{
			id = "disp_fov",
			category = "Display",
			group = "OPTICAL MATRIX",
			title = "Field of View",
			desc = "Horizontal optical view frustum aperture angle",
			type = "slider",
			min = 60,
			max = 110,
			step = 1,
			value = 85,
			unit = "deg",
			pinned = false
		},
		{
			id = "disp_motion",
			category = "Display",
			group = "OPTICAL MATRIX",
			title = "Camera Motion Blur",
			desc = "Simulated high velocity optical motion trailing",
			type = "toggle",
			value = false,
			pinned = false
		},
		{
			id = "disp_framerate",
			category = "Display",
			group = "RENDERING SYNCHRONY",
			title = "Frame Sync Rate",
			desc = "Client presentation synchronization rate ceiling",
			type = "dropdown",
			options = {"60 FPS", "120 FPS", "144 FPS", "Uncapped"},
			value = "144 FPS",
			pinned = false
		},
		{
			id = "disp_contrast",
			category = "Display",
			group = "RENDERING SYNCHRONY",
			title = "High Contrast Hairlines",
			desc = "Sharpen visual boundaries across surface elements",
			type = "toggle",
			value = false,
			pinned = false
		},
		{
			id = "snd_master",
			category = "Audio",
			group = "ACOUSTIC BUS",
			title = "Master Output Gain",
			desc = "Primary gain stage for spatialized UI and world audio",
			type = "slider",
			min = 0,
			max = 100,
			step = 1,
			value = 80,
			unit = "%",
			pinned = false
		},
		{
			id = "snd_spatial",
			category = "Audio",
			group = "ACOUSTIC BUS",
			title = "3D Spatial Acoustics",
			desc = "Binaural simulated directional audio attenuation",
			type = "toggle",
			value = true,
			pinned = false
		},
		{
			id = "snd_unfocused",
			category = "Audio",
			group = "ACOUSTIC BUS",
			title = "Mute On Focus Loss",
			desc = "Silence audio stream when game client is not active",
			type = "toggle",
			value = true,
			pinned = false
		},
		{
			id = "sys_cloud_sync",
			category = "Settings",
			group = "SYNCHRONIZATION",
			title = "Simulated Profile Sync",
			desc = "Periodically sync configuration profile snapshots",
			type = "toggle",
			value = true,
			pinned = false
		},
		{
			id = "sys_diagnostics",
			category = "Settings",
			group = "SYNCHRONIZATION",
			title = "Verbose Diagnostics",
			desc = "Output micro-telemetry mutations to output terminal",
			type = "toggle",
			value = false,
			pinned = false
		},
		{
			id = "sys_clear_pins",
			category = "Settings",
			group = "MAINTENANCE",
			title = "Clear Pinned Parameters",
			desc = "Remove all pinned shortcuts across all modules",
			type = "button",
			actionText = "Clear Pins",
			pinned = false
		}
	}

	local itemsById = {}
	for _, item in ipairs(initialItems) do
		itemsById[item.id] = item
	end

	screenGui = Instance.new("ScreenGui")
	screenGui.Name = "ConsolePrototypeGui"
	screenGui.ResetOnSpawn = false
	screenGui.DisplayOrder = 2147483640
	screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
	screenGui.Parent = container

	local toastLabel = Instance.new("TextLabel")
	toastLabel.Name = "ToastFeedback"
	toastLabel.Size = UDim2.new(0, 300, 0, 36)
	toastLabel.Position = UDim2.new(0.5, -150, 0.05, 0)
	toastLabel.BackgroundColor3 = colors.bgHeader
	toastLabel.TextColor3 = colors.textWhite
	toastLabel.Font = fonts.bold
	toastLabel.TextSize = 12
	toastLabel.Text = ""
	toastLabel.Visible = false
	toastLabel.ZIndex = 100
	toastLabel.Active = true
	toastLabel.Parent = screenGui

	local toastCorner = Instance.new("UICorner")
	toastCorner.CornerRadius = UDim.new(0, 8)
	toastCorner.Parent = toastLabel

	local toastStroke = Instance.new("UIStroke")
	toastStroke.Color = colors.borderWhite
	toastStroke.Thickness = 1.2
	toastStroke.Parent = toastLabel

	local toastDebounce = 0
	local function showToast(msg)
		toastDebounce = toastDebounce + 1
		local cur = toastDebounce
		toastLabel.Text = msg
		toastLabel.Visible = true
		toastLabel.BackgroundTransparency = 0.1
		toastLabel.TextTransparency = 0
		task.delay(1.8, function()
			if toastDebounce == cur and toastLabel.Parent then
				local startT = os.clock()
				task.spawn(function()
					while toastDebounce == cur and toastLabel.Parent do
						local alpha = math.clamp((os.clock() - startT) / 0.25, 0, 1)
						toastLabel.BackgroundTransparency = 0.1 + 0.9 * alpha
						toastLabel.TextTransparency = alpha
						if alpha >= 1 then
							toastLabel.Visible = false
							break
						end
						task.wait()
					end
				end)
			end
		end)
	end

	local miniLauncher = Instance.new("TextButton")
	miniLauncher.Name = "MiniLauncher"
	miniLauncher.Size = UDim2.new(0, 180, 0, 38)
	miniLauncher.Position = UDim2.new(0.5, -90, 0, 24)
	miniLauncher.BackgroundColor3 = colors.bgChassis
	miniLauncher.TextColor3 = colors.textWhite
	miniLauncher.Font = fonts.bold
	miniLauncher.TextSize = 12
	miniLauncher.Text = "● CONSOLE [READY]"
	miniLauncher.Visible = false
	miniLauncher.ZIndex = 50
	miniLauncher.Active = true
	miniLauncher.Parent = screenGui

	local miniLauncherCorner = Instance.new("UICorner")
	miniLauncherCorner.CornerRadius = UDim.new(0, 19)
	miniLauncherCorner.Parent = miniLauncher

	local miniLauncherStroke = Instance.new("UIStroke")
	miniLauncherStroke.Color = colors.borderWhite
	miniLauncherStroke.Thickness = 1.2
	miniLauncherStroke.Parent = miniLauncher

	local mainWindow = Instance.new("Frame")
	mainWindow.Name = "MainWindow"
	local initW = 740
	local initH = 490
	mainWindow.AnchorPoint = Vector2.new(0.5, 0.5)
	mainWindow.Size = UDim2.new(0, initW, 0, initH)
	mainWindow.Position = UDim2.new(0.5, 0, 0.5, 0)
	mainWindow.BackgroundColor3 = colors.bgChassis
	mainWindow.ClipsDescendants = true
	mainWindow.Active = true
	mainWindow.Parent = screenGui

	local windowCorner = Instance.new("UICorner")
	windowCorner.CornerRadius = UDim.new(0, 20)
	windowCorner.Parent = mainWindow

	local windowStroke = Instance.new("UIStroke")
	windowStroke.Color = colors.borderSubtle
	windowStroke.Thickness = 1
	windowStroke.Parent = mainWindow

	local innerContent = Instance.new("Frame")
	innerContent.Name = "InnerContent"
	innerContent.Size = UDim2.new(1 / currentContentScale, 0, 1 / currentContentScale, 0)
	innerContent.Position = UDim2.new(0, 0, 0, 0)
	innerContent.BackgroundTransparency = 1
	innerContent.ClipsDescendants = true
	innerContent.Active = true
	innerContent.Parent = mainWindow

	local innerScale = Instance.new("UIScale")
	innerScale.Name = "InnerScale"
	innerScale.Scale = currentContentScale
	innerScale.Parent = innerContent

	local header = Instance.new("Frame")
	header.Name = "Header"
	header.Size = UDim2.new(1, 0, 0, 44)
	header.Position = UDim2.new(0, 0, 0, 0)
	header.BackgroundColor3 = colors.bgHeader
	header.BorderSizePixel = 0
	header.Active = true
	header.ZIndex = 10
	header.Parent = innerContent

	local headerBottomBorder = Instance.new("Frame")
	headerBottomBorder.Size = UDim2.new(1, 0, 0, 1)
	headerBottomBorder.Position = UDim2.new(0, 0, 1, -1)
	headerBottomBorder.BackgroundColor3 = colors.borderSubtle
	headerBottomBorder.BorderSizePixel = 0
	headerBottomBorder.Parent = header

	local dragHandle = Instance.new("TextButton")
	dragHandle.Name = "DragHandle"
	dragHandle.Size = UDim2.new(1, -260, 1, 0)
	dragHandle.Position = UDim2.new(0, 0, 0, 0)
	dragHandle.BackgroundTransparency = 1
	dragHandle.Text = ""
	dragHandle.Active = true
	dragHandle.Parent = header

	local titleIconPip = Instance.new("Frame")
	titleIconPip.Size = UDim2.new(0, 4, 0, 16)
	titleIconPip.Position = UDim2.new(0, 14, 0.5, -8)
	titleIconPip.BackgroundColor3 = colors.textWhite
	titleIconPip.BorderSizePixel = 0
	titleIconPip.Parent = header

	local titleLabel = Instance.new("TextLabel")
	titleLabel.Name = "TitleLabel"
	titleLabel.Size = UDim2.new(0, 120, 1, 0)
	titleLabel.Position = UDim2.new(0, 26, 0, 0)
	titleLabel.BackgroundTransparency = 1
	titleLabel.TextColor3 = colors.textWhite
	titleLabel.Font = fonts.bold
	titleLabel.TextSize = 13
	titleLabel.TextXAlignment = Enum.TextXAlignment.Left
	titleLabel.Text = "CONSOLE // DECK"
	titleLabel.Parent = header

	local tagBadge = Instance.new("Frame")
	tagBadge.Name = "TagBadge"
	tagBadge.Size = UDim2.new(0, 92, 0, 18)
	tagBadge.Position = UDim2.new(0, 154, 0.5, -9)
	tagBadge.BackgroundColor3 = colors.bgDeep
	tagBadge.BorderSizePixel = 0
	tagBadge.Parent = header

	local tagCorner = Instance.new("UICorner")
	tagCorner.CornerRadius = UDim.new(0, 4)
	tagCorner.Parent = tagBadge

	local tagStroke = Instance.new("UIStroke")
	tagStroke.Color = colors.accent
	tagStroke.Thickness = 1
	tagStroke.Parent = tagBadge

	local tagText = Instance.new("TextLabel")
	tagText.Size = UDim2.new(1, 0, 1, 0)
	tagText.BackgroundTransparency = 1
	tagText.TextColor3 = colors.textWhite
	tagText.Font = fonts.bold
	tagText.TextSize = 9
	tagText.Text = "SCALE 125%"
	tagText.Parent = tagBadge

	local searchContainer = Instance.new("Frame")
	searchContainer.Name = "SearchContainer"
	searchContainer.Size = UDim2.new(0, 160, 0, 26)
	searchContainer.Position = UDim2.new(1, -244, 0.5, -13)
	searchContainer.BackgroundColor3 = colors.bgInput
	searchContainer.Active = true
	searchContainer.Parent = header

	local searchCorner = Instance.new("UICorner")
	searchCorner.CornerRadius = UDim.new(0, 10)
	searchCorner.Parent = searchContainer

	local searchStroke = Instance.new("UIStroke")
	searchStroke.Color = colors.borderSubtle
	searchStroke.Thickness = 1
	searchStroke.Parent = searchContainer

	local searchBox = Instance.new("TextBox")
	searchBox.Name = "SearchBox"
	searchBox.Size = UDim2.new(1, -16, 1, 0)
	searchBox.Position = UDim2.new(0, 8, 0, 0)
	searchBox.BackgroundTransparency = 1
	searchBox.TextColor3 = colors.textWhite
	searchBox.PlaceholderColor3 = colors.textDim
	searchBox.PlaceholderText = "Search parameters..."
	searchBox.Text = ""
	searchBox.Font = fonts.regular
	searchBox.TextSize = 11
	searchBox.TextXAlignment = Enum.TextXAlignment.Left
	searchBox.ClearTextOnFocus = false
	searchBox.Parent = searchContainer

	searchBox.Focused:Connect(function()
		TweenService:Create(searchStroke, TweenInfo.new(0.2, Enum.EasingStyle.Quart), {
			Color = colors.borderWhite
		}):Play()
		TweenService:Create(searchContainer, TweenInfo.new(0.2, Enum.EasingStyle.Quart), {
			BackgroundColor3 = colors.bgInputFocus
		}):Play()
	end)
	searchBox.FocusLost:Connect(function()
		TweenService:Create(searchStroke, TweenInfo.new(0.2, Enum.EasingStyle.Quart), {
			Color = colors.borderSubtle
		}):Play()
		TweenService:Create(searchContainer, TweenInfo.new(0.2, Enum.EasingStyle.Quart), {
			BackgroundColor3 = colors.bgInput
		}):Play()
	end)

	local collapseBtn = Instance.new("TextButton")
	collapseBtn.Name = "CollapseButton"
	collapseBtn.Size = UDim2.new(0, 26, 0, 26)
	collapseBtn.Position = UDim2.new(1, -66, 0.5, -13)
	collapseBtn.BackgroundColor3 = colors.bgInput
	collapseBtn.TextColor3 = colors.textWhite
	collapseBtn.Font = fonts.bold
	collapseBtn.TextSize = 12
	collapseBtn.Text = "-"
	collapseBtn.Active = true
	collapseBtn.Parent = header

	local collapseCorner = Instance.new("UICorner")
	collapseCorner.CornerRadius = UDim.new(0, 9)
	collapseCorner.Parent = collapseBtn

	local closeBtn = Instance.new("TextButton")
	closeBtn.Name = "CloseButton"
	closeBtn.Size = UDim2.new(0, 26, 0, 26)
	closeBtn.Position = UDim2.new(1, -34, 0.5, -13)
	closeBtn.BackgroundColor3 = colors.bgInput
	closeBtn.TextColor3 = colors.textWhite
	closeBtn.Font = fonts.bold
	closeBtn.TextSize = 11
	closeBtn.Text = "x"
	closeBtn.Active = true
	closeBtn.Parent = header

	local closeCorner = Instance.new("UICorner")
	closeCorner.CornerRadius = UDim.new(0, 9)
	closeCorner.Parent = closeBtn

	local dragging = false
	local dragStart = Vector2.new()
	local startPos = UDim2.new()

	dragHandle.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
			dragging = true
			dragStart = Vector2.new(input.Position.X, input.Position.Y)
			startPos = mainWindow.Position
			input.Changed:Connect(function()
				if input.UserInputState == Enum.UserInputState.End then
					dragging = false
				end
			end)
		end
	end)

	local mouseMoveConn = UserInputService.InputChanged:Connect(function(input)
		if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
			if not UserInputService:IsMouseButtonPressed(Enum.UserInputType.MouseButton1) and input.UserInputType == Enum.UserInputType.MouseMovement then
				dragging = false
				return
			end
			local delta = Vector2.new(input.Position.X, input.Position.Y) - dragStart
			mainWindow.Position = UDim2.new(
				startPos.X.Scale,
				startPos.X.Offset + delta.X,
				startPos.Y.Scale,
				startPos.Y.Offset + delta.Y
			)
		end
	end)
	addCleanup(mouseMoveConn)

	local inputEndedConn = UserInputService.InputEnded:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
			dragging = false
		end
	end)
	addCleanup(inputEndedConn)

	local filterBar = Instance.new("Frame")
	filterBar.Name = "FilterBar"
	filterBar.Size = UDim2.new(1, 0, 0, 36)
	filterBar.Position = UDim2.new(0, 0, 0, 44)
	filterBar.BackgroundColor3 = colors.bgDeep
	filterBar.BorderSizePixel = 0
	filterBar.Active = true
	filterBar.ZIndex = 9
	filterBar.Parent = innerContent

	local filterBarBorder = Instance.new("Frame")
	filterBarBorder.Size = UDim2.new(1, 0, 0, 1)
	filterBarBorder.Position = UDim2.new(0, 0, 1, -1)
	filterBarBorder.BackgroundColor3 = colors.borderSubtle
	filterBarBorder.BorderSizePixel = 0
	filterBarBorder.Parent = filterBar

	local categoryContextLabel = Instance.new("TextLabel")
	categoryContextLabel.Name = "CategoryContextLabel"
	categoryContextLabel.Size = UDim2.new(0, 260, 1, 0)
	categoryContextLabel.Position = UDim2.new(0, 16, 0, 0)
	categoryContextLabel.BackgroundTransparency = 1
	categoryContextLabel.TextColor3 = colors.textWhite
	categoryContextLabel.Font = fonts.bold
	categoryContextLabel.TextSize = 11
	categoryContextLabel.TextXAlignment = Enum.TextXAlignment.Left
	categoryContextLabel.Text = "// CONTROLS MATRIX"
	categoryContextLabel.Parent = filterBar

	local filterPillGroup = Instance.new("Frame")
	filterPillGroup.Name = "FilterPillGroup"
	filterPillGroup.Size = UDim2.new(0, 210, 0, 24)
	filterPillGroup.Position = UDim2.new(1, -224, 0.5, -12)
	filterPillGroup.BackgroundColor3 = colors.bgDock
	filterPillGroup.BorderSizePixel = 0
	filterPillGroup.Active = true
	filterPillGroup.Parent = filterBar

	local filterGroupCorner = Instance.new("UICorner")
	filterGroupCorner.CornerRadius = UDim.new(0, 10)
	filterGroupCorner.Parent = filterPillGroup

	local filterGroupStroke = Instance.new("UIStroke")
	filterGroupStroke.Color = colors.borderSubtle
	filterGroupStroke.Thickness = 1
	filterGroupStroke.Parent = filterPillGroup

	local filterGlider = Instance.new("Frame")
	filterGlider.Name = "FilterGlider"
	filterGlider.Size = UDim2.new(1 / 3, -4, 1, -4)
	filterGlider.Position = UDim2.new(0, 2, 0, 2)
	filterGlider.BackgroundColor3 = colors.accent
	filterGlider.BorderSizePixel = 0
	filterGlider.ZIndex = 2
	filterGlider.Parent = filterPillGroup

	local filterGliderCorner = Instance.new("UICorner")
	filterGliderCorner.CornerRadius = UDim.new(0, 8)
	filterGliderCorner.Parent = filterGlider

	local filterButtons = {}
	local filters = {"All", "Active", "Pinned"}

	local stageContainer = Instance.new("Frame")
	stageContainer.Name = "StageContainer"
	stageContainer.Size = UDim2.new(1, 0, 1, -80)
	stageContainer.Position = UDim2.new(0, 0, 0, 80)
	stageContainer.BackgroundTransparency = 1
	stageContainer.ClipsDescendants = true
	stageContainer.Active = true
	stageContainer.ZIndex = 5
	stageContainer.Parent = innerContent

	local scrollContent = Instance.new("ScrollingFrame")
	scrollContent.Name = "ScrollContent"
	scrollContent.Size = UDim2.new(1, -8, 1, 0)
	scrollContent.Position = UDim2.new(0, 4, 0, 0)
	scrollContent.BackgroundTransparency = 1
	scrollContent.BorderSizePixel = 0
	scrollContent.ScrollBarThickness = 4
	scrollContent.ScrollBarImageColor3 = colors.accent
	scrollContent.CanvasSize = UDim2.new(0, 0, 0, 0)
	scrollContent.AutomaticCanvasSize = Enum.AutomaticSize.Y
	scrollContent.Active = true
	scrollContent.Parent = stageContainer

	local scrollPadding = Instance.new("UIPadding")
	scrollPadding.PaddingLeft = UDim.new(0, 14)
	scrollPadding.PaddingRight = UDim.new(0, 14)
	scrollPadding.PaddingTop = UDim.new(0, 10)
	scrollPadding.PaddingBottom = UDim.new(0, 68)
	scrollPadding.Parent = scrollContent

	local scrollLayout = Instance.new("UIListLayout")
	scrollLayout.SortOrder = Enum.SortOrder.LayoutOrder
	scrollLayout.Padding = UDim.new(0, 8)
	scrollLayout.Parent = scrollContent

	local bottomSensorZone = Instance.new("Frame")
	bottomSensorZone.Name = "BottomSensorZone"
	bottomSensorZone.Size = UDim2.new(1, 0, 0, 60)
	bottomSensorZone.Position = UDim2.new(0, 0, 1, -60)
	bottomSensorZone.BackgroundTransparency = 1
	bottomSensorZone.Active = true
	bottomSensorZone.ZIndex = 15
	bottomSensorZone.Parent = innerContent

	local peekBar = Instance.new("Frame")
	peekBar.Name = "PeekBar"
	peekBar.Size = UDim2.new(0, 48, 0, 3)
	peekBar.Position = UDim2.new(0.5, -24, 1, -8)
	peekBar.BackgroundColor3 = colors.textWhite
	peekBar.BackgroundTransparency = 0.4
	peekBar.BorderSizePixel = 0
	peekBar.ZIndex = 16
	peekBar.Parent = innerContent

	local peekCorner = Instance.new("UICorner")
	peekCorner.CornerRadius = UDim.new(1, 0)
	peekCorner.Parent = peekBar

	local bottomDock = Instance.new("Frame")
	bottomDock.Name = "BottomDock"
	bottomDock.Size = UDim2.new(0, 520, 0, 52)
	bottomDock.Position = UDim2.new(0.5, -260, 1, 15)
	bottomDock.BackgroundColor3 = colors.bgDock
	bottomDock.Active = true
	bottomDock.ZIndex = 25
	bottomDock.Parent = innerContent

	local dockCorner = Instance.new("UICorner")
	dockCorner.CornerRadius = UDim.new(0, 24)
	dockCorner.Parent = bottomDock

	local dockStroke = Instance.new("UIStroke")
	dockStroke.Color = colors.borderWhite
	dockStroke.Thickness = 1.2
	dockStroke.Parent = bottomDock

	local dockGlider = Instance.new("Frame")
	dockGlider.Name = "DockGlider"
	dockGlider.Size = UDim2.new(0.2, -8, 1, -8)
	dockGlider.Position = UDim2.new(0, 4, 0, 4)
	dockGlider.BackgroundColor3 = colors.accentGlider
	dockGlider.BorderSizePixel = 0
	dockGlider.ZIndex = 26
	dockGlider.Parent = bottomDock

	local dockGliderCorner = Instance.new("UICorner")
	dockGliderCorner.CornerRadius = UDim.new(0, 16)
	dockGliderCorner.Parent = dockGlider

	local dockGliderStroke = Instance.new("UIStroke")
	dockGliderStroke.Color = colors.accent
	dockGliderStroke.Thickness = 1
	dockGliderStroke.Parent = dockGlider

	local dockGliderPip = Instance.new("Frame")
	dockGliderPip.Name = "DockGliderPip"
	dockGliderPip.Size = UDim2.new(0, 16, 0, 2)
	dockGliderPip.Position = UDim2.new(0.5, -8, 1, -3)
	dockGliderPip.BackgroundColor3 = colors.textWhite
	dockGliderPip.BorderSizePixel = 0
	dockGliderPip.Parent = dockGlider

	local categories = {
		{id = "Controls", label = "CONTROLS"},
		{id = "Display", label = "DISPLAY"},
		{id = "Audio", label = "AUDIO"},
		{id = "Overview", label = "OVERVIEW"},
		{id = "Settings", label = "SYSTEM"}
	}
	local numCats = #categories

	local dockButtonsHost = Instance.new("Frame")
	dockButtonsHost.Name = "DockButtonsHost"
	dockButtonsHost.Size = UDim2.new(1, 0, 1, 0)
	dockButtonsHost.BackgroundTransparency = 1
	dockButtonsHost.ZIndex = 28
	dockButtonsHost.Parent = bottomDock

	local dockTabs = {}

	local isHoveringSensor = false
	local isHoveringDock = false
	local dockHideDebounce = 0

	local function updateDockReveal(reveal, instant)
		state.dockRevealed = reveal
		local animTime = instant and 0 or 0.24
		local targetY = reveal and -60 or 15
		local targetPeekAlpha = reveal and 1 or 0.4
		TweenService:Create(bottomDock, TweenInfo.new(animTime, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {
			Position = UDim2.new(0.5, -260, 1, targetY)
		}):Play()
		TweenService:Create(peekBar, TweenInfo.new(animTime, Enum.EasingStyle.Quart), {
			BackgroundTransparency = targetPeekAlpha
		}):Play()
	end

	local function requestDockHide()
		dockHideDebounce = dockHideDebounce + 1
		local cur = dockHideDebounce
		task.delay(0.28, function()
			if dockHideDebounce == cur and not isHoveringSensor and not isHoveringDock then
				updateDockReveal(false, false)
			end
		end)
	end

	bottomSensorZone.MouseEnter:Connect(function()
		isHoveringSensor = true
		updateDockReveal(true, false)
	end)
	bottomSensorZone.MouseLeave:Connect(function()
		isHoveringSensor = false
		requestDockHide()
	end)
	bottomSensorZone.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.MouseButton1 then
			isHoveringSensor = true
			updateDockReveal(true, false)
		end
	end)

	bottomDock.MouseEnter:Connect(function()
		isHoveringDock = true
		updateDockReveal(true, false)
	end)
	bottomDock.MouseLeave:Connect(function()
		isHoveringDock = false
		requestDockHide()
	end)

	local function createProceduralIcon(catId, parent)
		local iconHolder = Instance.new("Frame")
		iconHolder.Name = "IconHolder"
		iconHolder.Size = UDim2.new(0, 18, 0, 18)
		iconHolder.Position = UDim2.new(0.5, -9, 0, 6)
		iconHolder.BackgroundTransparency = 1
		iconHolder.Parent = parent

		local vectorParts = {}

		if catId == "Controls" then
			local ring = Instance.new("Frame")
			ring.Size = UDim2.new(1, -2, 1, -2)
			ring.Position = UDim2.new(0, 1, 0, 1)
			ring.BackgroundTransparency = 1
			ring.Parent = iconHolder
			local ringCorner = Instance.new("UICorner")
			ringCorner.CornerRadius = UDim.new(1, 0)
			ringCorner.Parent = ring
			local ringStroke = Instance.new("UIStroke")
			ringStroke.Color = colors.textWhite
			ringStroke.Thickness = 1.2
			ringStroke.Parent = ring
			table.insert(vectorParts, ringStroke)

			local centerDot = Instance.new("Frame")
			centerDot.Size = UDim2.new(0, 4, 0, 4)
			centerDot.Position = UDim2.new(0.5, -2, 0.5, -2)
			centerDot.BackgroundColor3 = colors.textWhite
			centerDot.BorderSizePixel = 0
			centerDot.Parent = iconHolder
			local dotCorner = Instance.new("UICorner")
			dotCorner.CornerRadius = UDim.new(1, 0)
			dotCorner.Parent = centerDot
			table.insert(vectorParts, centerDot)
		elseif catId == "Display" then
			local screen = Instance.new("Frame")
			screen.Size = UDim2.new(1, 0, 0, 11)
			screen.Position = UDim2.new(0, 0, 0, 2)
			screen.BackgroundTransparency = 1
			screen.Parent = iconHolder
			local scCorn = Instance.new("UICorner")
			scCorn.CornerRadius = UDim.new(0, 2)
			scCorn.Parent = screen
			local scStroke = Instance.new("UIStroke")
			scStroke.Color = colors.textWhite
			scStroke.Thickness = 1.2
			scStroke.Parent = screen
			table.insert(vectorParts, scStroke)

			local stand = Instance.new("Frame")
			stand.Size = UDim2.new(0, 8, 0, 2)
			stand.Position = UDim2.new(0.5, -4, 0, 15)
			stand.BackgroundColor3 = colors.textWhite
			stand.BorderSizePixel = 0
			stand.Parent = iconHolder
			table.insert(vectorParts, stand)
		elseif catId == "Audio" then
			local heights = {7, 14, 10}
			local offsets = {-5, -1, 3}
			for i = 1, 3 do
				local bar = Instance.new("Frame")
				bar.Size = UDim2.new(0, 2, 0, heights[i])
				bar.Position = UDim2.new(0.5, offsets[i], 1, -heights[i] - 2)
				bar.BackgroundColor3 = colors.textWhite
				bar.BorderSizePixel = 0
				bar.Parent = iconHolder
				table.insert(vectorParts, bar)
			end
		elseif catId == "Overview" then
			local coords = {
				{0, 0}, {9, 0},
				{0, 9}, {9, 9}
			}
			for _, pos in ipairs(coords) do
				local sq = Instance.new("Frame")
				sq.Size = UDim2.new(0, 6, 0, 6)
				sq.Position = UDim2.new(0, pos[1] + 1, 0, pos[2] + 2)
				sq.BackgroundColor3 = colors.textWhite
				sq.BorderSizePixel = 0
				sq.Parent = iconHolder
				local sqCorn = Instance.new("UICorner")
				sqCorn.CornerRadius = UDim.new(0, 1)
				sqCorn.Parent = sq
				table.insert(vectorParts, sq)
			end
		elseif catId == "Settings" then
			local chip = Instance.new("Frame")
			chip.Size = UDim2.new(0, 11, 0, 11)
			chip.Position = UDim2.new(0.5, -5, 0.5, -5)
			chip.BackgroundTransparency = 1
			chip.Parent = iconHolder
			local chipCorn = Instance.new("UICorner")
			chipCorn.CornerRadius = UDim.new(0, 2)
			chipCorn.Parent = chip
			local chipStroke = Instance.new("UIStroke")
			chipStroke.Color = colors.textWhite
			chipStroke.Thickness = 1.2
			chipStroke.Parent = chip
			table.insert(vectorParts, chipStroke)

			local pins = {
				{0.5, -1, 0, 0, 2, 2},
				{0.5, -1, 1, -2, 2, 2},
				{0, 0, 0.5, -1, 2, 2},
				{1, -2, 0.5, -1, 2, 2}
			}
			for _, p in ipairs(pins) do
				local pin = Instance.new("Frame")
				pin.Size = UDim2.new(0, p[5], 0, p[6])
				pin.Position = UDim2.new(p[1], p[2], p[3], p[4])
				pin.BackgroundColor3 = colors.textWhite
				pin.BorderSizePixel = 0
				pin.Parent = iconHolder
				table.insert(vectorParts, pin)
			end
		end

		return iconHolder, vectorParts
	end

	local renderGrid

	local function animateStageLift()
		scrollContent.Position = UDim2.new(0, 4, 0, 14)
		scrollContent.CanvasPosition = Vector2.new(0, 0)
		TweenService:Create(scrollContent, TweenInfo.new(0.2, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {
			Position = UDim2.new(0, 4, 0, 0)
		}):Play()
	end

	local function moveDockGlider(catId, animate)
		local idx = 1
		for i, c in ipairs(categories) do
			if c.id == catId then idx = i break end
		end
		local slotW = 1 / numCats
		local targetScaleX = (idx - 1) * slotW
		local animTime = animate and 0.22 or 0
		TweenService:Create(dockGlider, TweenInfo.new(animTime, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {
			Position = UDim2.new(targetScaleX, 4, 0, 4),
			Size = UDim2.new(slotW, -8, 1, -8)
		}):Play()
	end

	for idx, cat in ipairs(categories) do
		local tabBtn = Instance.new("TextButton")
		tabBtn.Name = "DockTab_" .. cat.id
		tabBtn.Size = UDim2.new(1 / numCats, 0, 1, 0)
		tabBtn.Position = UDim2.new((idx - 1) / numCats, 0, 0, 0)
		tabBtn.BackgroundTransparency = 1
		tabBtn.Text = ""
		tabBtn.Active = true
		tabBtn.Parent = dockButtonsHost

		local tabContent = Instance.new("Frame")
		tabContent.Name = "TabContent"
		tabContent.Size = UDim2.new(1, 0, 1, 0)
		tabContent.Position = UDim2.new(0, 0, 0, 0)
		tabContent.BackgroundTransparency = 1
		tabContent.Parent = tabBtn

		local iconHolder, iconParts = createProceduralIcon(cat.id, tabContent)

		local tabText = Instance.new("TextLabel")
		tabText.Name = "TabLabel"
		tabText.Size = UDim2.new(1, 0, 0, 13)
		tabText.Position = UDim2.new(0, 0, 1, -16)
		tabText.BackgroundTransparency = 1
		tabText.TextColor3 = (cat.id == state.activeCategory) and colors.textWhite or colors.textDim
		tabText.Font = fonts.bold
		tabText.TextSize = 9
		tabText.Text = cat.label
		tabText.Parent = tabContent

		dockTabs[cat.id] = {
			button = tabBtn,
			content = tabContent,
			text = tabText,
			iconParts = iconParts
		}

		local function updateTabVisuals(isActive, isHover)
			local targetColor = isActive and colors.textWhite or (isHover and colors.textSecondary or colors.textDim)
			tabText.TextColor3 = targetColor
			for _, part in ipairs(iconParts) do
				if part:IsA("UIStroke") then
					part.Color = targetColor
				else
					part.BackgroundColor3 = targetColor
				end
			end
			local targetY = isActive and -3 or (isHover and -1 or 0)
			TweenService:Create(tabContent, TweenInfo.new(0.16, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {
				Position = UDim2.new(0, 0, 0, targetY)
			}):Play()
		end

		updateTabVisuals(cat.id == state.activeCategory, false)

		tabBtn.MouseEnter:Connect(function()
			if state.activeCategory ~= cat.id then
				updateTabVisuals(false, true)
			end
		end)
		tabBtn.MouseLeave:Connect(function()
			if state.activeCategory ~= cat.id then
				updateTabVisuals(false, false)
			end
		end)

		tabBtn.MouseButton1Click:Connect(function()
			if state.activeCategory == cat.id and state.searchQuery == "" then return end
			state.activeCategory = cat.id
			state.searchQuery = ""
			searchBox.Text = ""
			categoryContextLabel.Text = "// " .. string.upper(cat.id) .. " MATRIX"
			for otherId, data in pairs(dockTabs) do
				updateTabVisuals(otherId == cat.id, false)
			end
			moveDockGlider(cat.id, true)
			animateStageLift()
			renderGrid()
		end)
	end

	for fIdx, fName in ipairs(filters) do
		local fBtn = Instance.new("TextButton")
		fBtn.Name = "Filter_" .. fName
		fBtn.Size = UDim2.new(1 / #filters, 0, 1, 0)
		fBtn.Position = UDim2.new((fIdx - 1) / #filters, 0, 0, 0)
		fBtn.BackgroundTransparency = 1
		fBtn.TextColor3 = (fName == state.filter) and colors.textWhite or colors.textDim
		fBtn.Font = fonts.bold
		fBtn.TextSize = 10
		fBtn.Text = string.upper(fName)
		fBtn.ZIndex = 3
		fBtn.Active = true
		fBtn.Parent = filterPillGroup
		filterButtons[fName] = fBtn

		fBtn.MouseButton1Click:Connect(function()
			if state.filter == fName then return end
			state.filter = fName
			for otherF, otherFBtn in pairs(filterButtons) do
				local isActive = (otherF == fName)
				TweenService:Create(otherFBtn, TweenInfo.new(0.15, Enum.EasingStyle.Quad), {
					TextColor3 = isActive and colors.textWhite or colors.textDim
				}):Play()
			end
			local slotW = 1 / #filters
			local targetScaleX = (fIdx - 1) * slotW
			TweenService:Create(filterGlider, TweenInfo.new(0.2, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {
				Position = UDim2.new(targetScaleX, 2, 0, 2),
				Size = UDim2.new(slotW, -4, 1, -4)
			}):Play()
			animateStageLift()
			renderGrid()
		end)
	end

	local function createSectionHeader(title, order)
		local headerFrame = Instance.new("Frame")
		headerFrame.Name = "Header_" .. title
		headerFrame.Size = UDim2.new(1, 0, 0, 26)
		headerFrame.BackgroundTransparency = 1
		headerFrame.LayoutOrder = order
		headerFrame.Parent = scrollContent

		local accentLine = Instance.new("Frame")
		accentLine.Size = UDim2.new(0, 3, 0, 14)
		accentLine.Position = UDim2.new(0, 0, 0.5, -7)
		accentLine.BackgroundColor3 = colors.borderWhite
		accentLine.BorderSizePixel = 0
		accentLine.Parent = headerFrame

		local headerText = Instance.new("TextLabel")
		headerText.Size = UDim2.new(0, 220, 1, 0)
		headerText.Position = UDim2.new(0, 12, 0, 0)
		headerText.BackgroundTransparency = 1
		headerText.TextColor3 = colors.textWhite
		headerText.Font = fonts.bold
		headerText.TextSize = 11
		headerText.TextXAlignment = Enum.TextXAlignment.Left
		headerText.Text = "// " .. string.upper(title)
		headerText.Parent = headerFrame

		local ruleLine = Instance.new("Frame")
		ruleLine.Size = UDim2.new(1, -240, 0, 1)
		ruleLine.Position = UDim2.new(0, 230, 0.5, 0)
		ruleLine.BackgroundColor3 = colors.borderSubtle
		ruleLine.BorderSizePixel = 0
		ruleLine.Parent = headerFrame
	end

	local function createItemCard(item, order)
		local card = Instance.new("Frame")
		card.Name = "Card_" .. item.id
		card.Size = UDim2.new(1, 0, 0, 52)
		card.BackgroundColor3 = colors.bgCard
		card.LayoutOrder = order
		card.Active = true
		card.Parent = scrollContent

		local cardCorner = Instance.new("UICorner")
		cardCorner.CornerRadius = UDim.new(0, 14)
		cardCorner.Parent = card

		local cardStroke = Instance.new("UIStroke")
		cardStroke.Color = colors.borderCard
		cardStroke.Thickness = 1
		cardStroke.Parent = card

		local hoverHairline = Instance.new("Frame")
		hoverHairline.Name = "HoverHairline"
		hoverHairline.Size = UDim2.new(0, 2, 0, 0)
		hoverHairline.Position = UDim2.new(0, 0, 0.5, 0)
		hoverHairline.BackgroundColor3 = colors.borderWhite
		hoverHairline.BorderSizePixel = 0
		hoverHairline.Parent = card

		local function onEnter()
			TweenService:Create(card, TweenInfo.new(0.18, Enum.EasingStyle.Quart), {
				BackgroundColor3 = colors.bgCardHover
			}):Play()
			TweenService:Create(cardStroke, TweenInfo.new(0.18, Enum.EasingStyle.Quart), {
				Color = colors.borderWhite
			}):Play()
			TweenService:Create(hoverHairline, TweenInfo.new(0.18, Enum.EasingStyle.Quart), {
				Size = UDim2.new(0, 2, 1, -8),
				Position = UDim2.new(0, 0, 0, 4)
			}):Play()
		end

		local function onLeave()
			TweenService:Create(card, TweenInfo.new(0.18, Enum.EasingStyle.Quart), {
				BackgroundColor3 = colors.bgCard
			}):Play()
			TweenService:Create(cardStroke, TweenInfo.new(0.18, Enum.EasingStyle.Quart), {
				Color = colors.borderCard
			}):Play()
			TweenService:Create(hoverHairline, TweenInfo.new(0.18, Enum.EasingStyle.Quart), {
				Size = UDim2.new(0, 2, 0, 0),
				Position = UDim2.new(0, 0, 0.5, 0)
			}):Play()
		end

		card.MouseEnter:Connect(onEnter)
		card.MouseLeave:Connect(onLeave)

		local pinBtn = Instance.new("TextButton")
		pinBtn.Name = "PinButton"
		pinBtn.Size = UDim2.new(0, 22, 0, 22)
		pinBtn.Position = UDim2.new(0, 8, 0.5, -11)
		pinBtn.BackgroundTransparency = 1
		pinBtn.TextColor3 = item.pinned and colors.textWhite or colors.textMuted
		pinBtn.Font = fonts.bold
		pinBtn.TextSize = 13
		pinBtn.Text = item.pinned and "*" or "o"
		pinBtn.Active = true
		pinBtn.Parent = card

		pinBtn.MouseButton1Click:Connect(function()
			item.pinned = not item.pinned
			pinBtn.Text = item.pinned and "*" or "o"
			local targetColor = item.pinned and colors.textWhite or colors.textMuted
			local bounceUp = TweenService:Create(pinBtn, TweenInfo.new(0.1, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
				TextColor3 = targetColor,
				TextSize = 16
			})
			bounceUp:Play()
			bounceUp.Completed:Connect(function()
				TweenService:Create(pinBtn, TweenInfo.new(0.12, Enum.EasingStyle.Quad), {
					TextSize = 13
				}):Play()
			end)
			showToast(item.pinned and ("PINNED: " .. item.title) or ("UNPINNED: " .. item.title))
			if state.filter == "Pinned" then
				renderGrid()
			end
		end)

		local labelContainer = Instance.new("Frame")
		labelContainer.Name = "LabelContainer"
		labelContainer.Size = UDim2.new(1, -260, 1, -8)
		labelContainer.Position = UDim2.new(0, 36, 0, 4)
		labelContainer.BackgroundTransparency = 1
		labelContainer.Parent = card

		local itemTitle = Instance.new("TextLabel")
		itemTitle.Size = UDim2.new(1, 0, 0, 20)
		itemTitle.BackgroundTransparency = 1
		itemTitle.TextColor3 = colors.textWhite
		itemTitle.Font = fonts.bold
		itemTitle.TextSize = 12
		itemTitle.TextXAlignment = Enum.TextXAlignment.Left
		itemTitle.Text = item.title
		itemTitle.Parent = labelContainer

		local itemDesc = Instance.new("TextLabel")
		itemDesc.Size = UDim2.new(1, 0, 0, 16)
		itemDesc.Position = UDim2.new(0, 0, 0, 20)
		itemDesc.BackgroundTransparency = 1
		itemDesc.TextColor3 = colors.textSecondary
		itemDesc.Font = fonts.regular
		itemDesc.TextSize = 10
		itemDesc.TextXAlignment = Enum.TextXAlignment.Left
		itemDesc.Text = item.desc
		itemDesc.Parent = labelContainer

		local widgetArea = Instance.new("Frame")
		widgetArea.Name = "WidgetArea"
		widgetArea.Size = UDim2.new(0, 200, 1, 0)
		widgetArea.Position = UDim2.new(1, -210, 0, 0)
		widgetArea.BackgroundTransparency = 1
		widgetArea.Active = true
		widgetArea.Parent = card

		if item.type == "toggle" then
			local track = Instance.new("TextButton")
			track.Name = "ToggleTrack"
			track.Size = UDim2.new(0, 44, 0, 22)
			track.Position = UDim2.new(1, -54, 0.5, -11)
			track.BackgroundColor3 = item.value and colors.accent or colors.bgInput
			track.Text = ""
			track.Active = true
			track.Parent = widgetArea

			local trackCorn = Instance.new("UICorner")
			trackCorn.CornerRadius = UDim.new(1, 0)
			trackCorn.Parent = track

			local trackStroke = Instance.new("UIStroke")
			trackStroke.Color = item.value and colors.borderWhite or colors.borderSubtle
			trackStroke.Thickness = 1.2
			trackStroke.Parent = track

			local thumb = Instance.new("Frame")
			thumb.Name = "ToggleThumb"
			thumb.Size = UDim2.new(0, 16, 0, 16)
			thumb.Position = item.value and UDim2.new(1, -19, 0.5, -8) or UDim2.new(0, 3, 0.5, -8)
			thumb.BackgroundColor3 = colors.textWhite
			thumb.BorderSizePixel = 0
			thumb.Parent = track

			local thumbCorn = Instance.new("UICorner")
			thumbCorn.CornerRadius = UDim.new(1, 0)
			thumbCorn.Parent = thumb

			track.MouseButton1Click:Connect(function()
				item.value = not item.value
				local targetX = item.value and UDim2.new(1, -19, 0.5, -8) or UDim2.new(0, 3, 0.5, -8)
				local targetBg = item.value and colors.accent or colors.bgInput
				local targetStroke = item.value and colors.borderWhite or colors.borderSubtle
				TweenService:Create(thumb, TweenInfo.new(0.18, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {
					Position = targetX
				}):Play()
				TweenService:Create(track, TweenInfo.new(0.18, Enum.EasingStyle.Quart), {
					BackgroundColor3 = targetBg
				}):Play()
				TweenService:Create(trackStroke, TweenInfo.new(0.18, Enum.EasingStyle.Quart), {
					Color = targetStroke
				}):Play()
				showToast(item.title .. ": " .. (item.value and "ACTIVE [ON]" or "OFF"))
			end)
		elseif item.type == "slider" then
			local sliderBar = Instance.new("Frame")
			sliderBar.Name = "SliderTrack"
			sliderBar.Size = UDim2.new(0, 120, 0, 6)
			sliderBar.Position = UDim2.new(0, 10, 0.5, -3)
			sliderBar.BackgroundColor3 = colors.bgInput
			sliderBar.BorderSizePixel = 0
			sliderBar.Active = true
			sliderBar.Parent = widgetArea

			local sliderCorn = Instance.new("UICorner")
			sliderCorn.CornerRadius = UDim.new(1, 0)
			sliderCorn.Parent = sliderBar

			local pct = math.clamp((item.value - item.min) / (item.max - item.min), 0, 1)
			local fill = Instance.new("Frame")
			fill.Name = "SliderFill"
			fill.Size = UDim2.new(pct, 0, 1, 0)
			fill.BackgroundColor3 = colors.accent
			fill.BorderSizePixel = 0
			fill.Parent = sliderBar

			local fillCorn = Instance.new("UICorner")
			fillCorn.CornerRadius = UDim.new(1, 0)
			fillCorn.Parent = fill

			local thumbDot = Instance.new("Frame")
			thumbDot.Name = "ThumbDot"
			thumbDot.Size = UDim2.new(0, 12, 0, 12)
			thumbDot.Position = UDim2.new(pct, -6, 0.5, -6)
			thumbDot.BackgroundColor3 = colors.textWhite
			thumbDot.BorderSizePixel = 0
			thumbDot.Parent = sliderBar

			local thumbCorn = Instance.new("UICorner")
			thumbCorn.CornerRadius = UDim.new(1, 0)
			thumbCorn.Parent = thumbDot

			local valueBox = Instance.new("TextBox")
			valueBox.Name = "ValueBox"
			valueBox.Size = UDim2.new(0, 54, 0, 22)
			valueBox.Position = UDim2.new(1, -60, 0.5, -11)
			valueBox.BackgroundColor3 = colors.bgInput
			valueBox.TextColor3 = colors.textWhite
			valueBox.Font = fonts.bold
			valueBox.TextSize = 11
			valueBox.Text = tostring(item.value) .. (item.unit or "")
			valueBox.ClearTextOnFocus = false
			valueBox.Parent = widgetArea

			local boxCorn = Instance.new("UICorner")
			boxCorn.CornerRadius = UDim.new(0, 8)
			boxCorn.Parent = valueBox

			local boxStroke = Instance.new("UIStroke")
			boxStroke.Color = colors.borderCard
			boxStroke.Thickness = 1
			boxStroke.Parent = valueBox

			local function updateSliderPct(newPct)
				newPct = math.clamp(newPct, 0, 1)
				local rawVal = item.min + newPct * (item.max - item.min)
				local steppedVal = math.floor(rawVal / item.step + 0.5) * item.step
				steppedVal = math.clamp(steppedVal, item.min, item.max)
				item.value = steppedVal
				local finalPct = math.clamp((steppedVal - item.min) / (item.max - item.min), 0, 1)
				fill.Size = UDim2.new(finalPct, 0, 1, 0)
				thumbDot.Position = UDim2.new(finalPct, -6, 0.5, -6)
				valueBox.Text = tostring(steppedVal) .. (item.unit or "")
			end

			local sliderDragging = false
			sliderBar.InputBegan:Connect(function(input)
				if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
					sliderDragging = true
					TweenService:Create(thumbDot, TweenInfo.new(0.12, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
						Size = UDim2.new(0, 16, 0, 16),
						Position = UDim2.new(fill.Size.X.Scale, -8, 0.5, -8)
					}):Play()
					local relX = input.Position.X - sliderBar.AbsolutePosition.X
					updateSliderPct(relX / sliderBar.AbsoluteSize.X)
				end
			end)

			local sliderDragConn = UserInputService.InputChanged:Connect(function(input)
				if sliderDragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
					local relX = input.Position.X - sliderBar.AbsolutePosition.X
					updateSliderPct(relX / sliderBar.AbsoluteSize.X)
				end
			end)
			addCleanup(sliderDragConn)

			local sliderEndConn = UserInputService.InputEnded:Connect(function(input)
				if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
					if sliderDragging then
						sliderDragging = false
						TweenService:Create(thumbDot, TweenInfo.new(0.12, Enum.EasingStyle.Quad), {
							Size = UDim2.new(0, 12, 0, 12),
							Position = UDim2.new(fill.Size.X.Scale, -6, 0.5, -6)
						}):Play()
					end
				end
			end)
			addCleanup(sliderEndConn)

			valueBox.FocusLost:Connect(function()
				local rawNum = tonumber(valueBox.Text:gsub("[^%d%.%-]", ""))
				if rawNum then
					local steppedVal = math.floor(rawNum / item.step + 0.5) * item.step
					steppedVal = math.clamp(steppedVal, item.min, item.max)
					item.value = steppedVal
					local finalPct = math.clamp((steppedVal - item.min) / (item.max - item.min), 0, 1)
					fill.Size = UDim2.new(finalPct, 0, 1, 0)
					thumbDot.Position = UDim2.new(finalPct, -6, 0.5, -6)
					valueBox.Text = tostring(steppedVal) .. (item.unit or "")
				else
					valueBox.Text = tostring(item.value) .. (item.unit or "")
				end
			end)
		elseif item.type == "dropdown" then
			local dropBtn = Instance.new("TextButton")
			dropBtn.Name = "DropdownTrigger"
			dropBtn.Size = UDim2.new(1, -10, 0, 26)
			dropBtn.Position = UDim2.new(0, 0, 0.5, -13)
			dropBtn.BackgroundColor3 = colors.bgInput
			dropBtn.TextColor3 = colors.textWhite
			dropBtn.Font = fonts.bold
			dropBtn.TextSize = 10
			dropBtn.Text = tostring(item.value) .. " v"
			dropBtn.Active = true
			dropBtn.Parent = widgetArea

			local dropCorn = Instance.new("UICorner")
			dropCorn.CornerRadius = UDim.new(0, 8)
			dropCorn.Parent = dropBtn

			local dropStroke = Instance.new("UIStroke")
			dropStroke.Color = colors.borderCard
			dropStroke.Thickness = 1
			dropStroke.Parent = dropBtn

			local optIndex = 1
			for i, o in ipairs(item.options) do
				if o == item.value then optIndex = i break end
			end

			dropBtn.MouseButton1Click:Connect(function()
				optIndex = (optIndex % #item.options) + 1
				item.value = item.options[optIndex]
				dropBtn.Text = tostring(item.value) .. " v"
				TweenService:Create(dropBtn, TweenInfo.new(0.12, Enum.EasingStyle.Quad), {
					BackgroundColor3 = colors.bgInputFocus
				}):Play()
				task.delay(0.15, function()
					TweenService:Create(dropBtn, TweenInfo.new(0.15, Enum.EasingStyle.Quad), {
						BackgroundColor3 = colors.bgInput
					}):Play()
				end)
				showToast(item.title .. " -> " .. item.value)
			end)
		elseif item.type == "keybind" then
			local keyBtn = Instance.new("TextButton")
			keyBtn.Name = "KeybindTrigger"
			keyBtn.Size = UDim2.new(1, -10, 0, 26)
			keyBtn.Position = UDim2.new(0, 0, 0.5, -13)
			keyBtn.BackgroundColor3 = colors.bgInput
			keyBtn.TextColor3 = colors.textWhite
			keyBtn.Font = fonts.bold
			keyBtn.TextSize = 10
			keyBtn.Text = "[" .. (item.value and item.value.Name or "None") .. "]"
			keyBtn.Active = true
			keyBtn.Parent = widgetArea

			local keyCorn = Instance.new("UICorner")
			keyCorn.CornerRadius = UDim.new(0, 8)
			keyCorn.Parent = keyBtn

			local keyStroke = Instance.new("UIStroke")
			keyStroke.Color = colors.borderCard
			keyStroke.Thickness = 1
			keyStroke.Parent = keyBtn

			local isListening = false
			keyBtn.MouseButton1Click:Connect(function()
				if isListening then return end
				isListening = true
				keyBtn.Text = "< PRESS KEY >"
				keyStroke.Color = colors.borderWhite
				local listenConn
				listenConn = UserInputService.InputBegan:Connect(function(input)
					if input.UserInputType == Enum.UserInputType.Keyboard then
						listenConn:Disconnect()
						isListening = false
						if input.KeyCode ~= Enum.KeyCode.Escape then
							item.value = input.KeyCode
							keyBtn.Text = "[" .. input.KeyCode.Name .. "]"
							showToast("BOUND: " .. input.KeyCode.Name)
						else
							keyBtn.Text = "[" .. (item.value and item.value.Name or "None") .. "]"
							showToast("REBIND CANCELLED")
						end
						keyStroke.Color = colors.borderCard
					end
				end)
				addCleanup(listenConn)
			end)
		elseif item.type == "button" then
			local actBtn = Instance.new("TextButton")
			actBtn.Name = "ActionButton"
			actBtn.Size = UDim2.new(1, -10, 0, 26)
			actBtn.Position = UDim2.new(0, 0, 0.5, -13)
			actBtn.BackgroundColor3 = colors.bgDeep
			actBtn.TextColor3 = colors.textWhite
			actBtn.Font = fonts.bold
			actBtn.TextSize = 11
			actBtn.Text = item.actionText or "Trigger"
			actBtn.Active = true
			actBtn.Parent = widgetArea

			local actCorn = Instance.new("UICorner")
			actCorn.CornerRadius = UDim.new(0, 8)
			actCorn.Parent = actBtn

			local actStroke = Instance.new("UIStroke")
			actStroke.Color = colors.borderWhite
			actStroke.Thickness = 1
			actStroke.Parent = actBtn

			actBtn.MouseButton1Click:Connect(function()
				TweenService:Create(actBtn, TweenInfo.new(0.1, Enum.EasingStyle.Quad), {
					BackgroundColor3 = colors.accent
				}):Play()
				task.delay(0.12, function()
					TweenService:Create(actBtn, TweenInfo.new(0.15, Enum.EasingStyle.Quad), {
						BackgroundColor3 = colors.bgDeep
					}):Play()
				end)
				if item.id == "reset_controls" then
					showToast("BASELINE RESTORED")
				elseif item.id == "sys_clear_pins" then
					for _, itm in ipairs(initialItems) do
						itm.pinned = false
					end
					renderGrid()
					showToast("ALL PINS CLEARED")
				else
					showToast("EXECUTED: " .. item.title)
				end
			end)
		end
	end

	renderGrid = function()
		for _, child in ipairs(scrollContent:GetChildren()) do
			if not (child:IsA("UIListLayout") or child:IsA("UIPadding")) then
				child:Destroy()
			end
		end

		local q = string.lower(state.searchQuery)
		local visibleList = {}

		for _, item in ipairs(initialItems) do
			local matchCat = (item.category == state.activeCategory)
			local matchQuery = true
			if q ~= "" then
				local inTitle = string.find(string.lower(item.title), q, 1, true) ~= nil
				local inDesc = string.find(string.lower(item.desc), q, 1, true) ~= nil
				local inGroup = string.find(string.lower(item.group), q, 1, true) ~= nil
				matchQuery = inTitle or inDesc or inGroup
			end

			local matchFilter = true
			if state.filter == "Active" then
				if item.type == "toggle" then
					matchFilter = (item.value == true)
				else
					matchFilter = false
				end
			elseif state.filter == "Pinned" then
				matchFilter = (item.pinned == true)
			end

			if q ~= "" then
				if matchQuery and matchFilter then
					table.insert(visibleList, item)
				end
			else
				if matchCat and matchFilter then
					table.insert(visibleList, item)
				end
			end
		end

		local groups = {}
		local groupList = {}
		for _, item in ipairs(visibleList) do
			if not groups[item.group] then
				groups[item.group] = {}
				table.insert(groupList, item.group)
			end
			table.insert(groups[item.group], item)
		end

		local currentOrder = 0
		if #visibleList == 0 then
			local emptyLabel = Instance.new("TextLabel")
			emptyLabel.Size = UDim2.new(1, 0, 0, 60)
			emptyLabel.BackgroundTransparency = 1
			emptyLabel.TextColor3 = colors.textDim
			emptyLabel.Font = fonts.medium
			emptyLabel.TextSize = 12
			emptyLabel.Text = "// NO MATCHING PARAMETERS FOUND"
			emptyLabel.Parent = scrollContent
		else
			for _, grpName in ipairs(groupList) do
				currentOrder = currentOrder + 1
				createSectionHeader(grpName, currentOrder)
				for _, itm in ipairs(groups[grpName]) do
					currentOrder = currentOrder + 1
					createItemCard(itm, currentOrder)
				end
			end
		end
	end

	searchBox:GetPropertyChangedSignal("Text"):Connect(function()
		state.searchQuery = searchBox.Text
		if state.searchQuery ~= "" then
			categoryContextLabel.Text = "SEARCH // \"" .. string.upper(state.searchQuery) .. "\""
		else
			categoryContextLabel.Text = "// " .. string.upper(state.activeCategory) .. " MATRIX"
		end
		renderGrid()
	end)

	collapseBtn.MouseButton1Click:Connect(function()
		state.isCollapsed = not state.isCollapsed
		if state.isCollapsed then
			collapseBtn.Text = "+"
			updateDockReveal(false, true)
			TweenService:Create(mainWindow, TweenInfo.new(0.25, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {
				Size = UDim2.new(0, 740, 0, 44)
			}):Play()
		else
			collapseBtn.Text = "-"
			local targetH = state.isMobile and 430 or 490
			TweenService:Create(mainWindow, TweenInfo.new(0.25, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {
				Size = UDim2.new(0, 740, 0, targetH)
			}):Play()
		end
	end)

	closeBtn.MouseButton1Click:Connect(function()
		state.isVisible = false
		local closeTween = TweenService:Create(mainWindow, TweenInfo.new(0.2, Enum.EasingStyle.Quart, Enum.EasingDirection.In), {
			Size = UDim2.new(0, 740 * 0.9, 0, 490 * 0.9)
		})
		closeTween:Play()
		closeTween.Completed:Connect(function()
			mainWindow.Visible = false
			miniLauncher.Visible = true
		end)
	end)

	miniLauncher.MouseButton1Click:Connect(function()
		state.isVisible = true
		miniLauncher.Visible = false
		mainWindow.Visible = true
		local targetH = state.isMobile and 430 or 490
		local openTween = TweenService:Create(mainWindow, TweenInfo.new(0.25, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {
			Size = UDim2.new(0, state.isMobile and 540 or 740, 0, targetH)
		})
		openTween:Play()
	end)

	local globalKeyConn = UserInputService.InputBegan:Connect(function(input, processed)
		if processed then return end
		if input.KeyCode == itemsById["key_toggle_ui"].value then
			state.isVisible = not state.isVisible
			mainWindow.Visible = state.isVisible
			miniLauncher.Visible = not state.isVisible
		end
	end)
	addCleanup(globalKeyConn)

	local function setScaleLevel(scaleVal)
		currentContentScale = scaleVal
		innerScale.Scale = scaleVal
		innerContent.Size = UDim2.new(1 / scaleVal, 0, 1 / scaleVal, 0)
		tagText.Text = string.format("SCALE %d%%", math.floor(scaleVal * 100 + 0.5))
	end

	local function setMobileMode(isMobile)
		state.isMobile = isMobile
		if isMobile then
			mainWindow.Size = UDim2.new(0, 540, 0, 430)
			bottomDock.Size = UDim2.new(0, 460, 0, 50)
			bottomDock.Position = UDim2.new(0.5, -230, 1, state.dockRevealed and -58 or 15)
		else
			mainWindow.Size = UDim2.new(0, 740, 0, 490)
			bottomDock.Size = UDim2.new(0, 520, 0, 52)
			bottomDock.Position = UDim2.new(0.5, -260, 1, state.dockRevealed and -60 or 15)
		end
		task.defer(function()
			moveDockGlider(state.activeCategory, false)
		end)
	end

	task.defer(function()
		moveDockGlider(state.activeCategory, false)
		local initFBtn = filterButtons[state.filter]
		if initFBtn then
			local slotW = 1 / #filters
			filterGlider.Position = UDim2.new(0, 2, 0, 2)
			filterGlider.Size = UDim2.new(slotW, -4, 1, -4)
		end
		renderGrid()
	end)

	_G.ConsoleDemoController = {
		setCategory = function(catName)
			local tab = dockTabs[catName]
			if tab then
				state.activeCategory = catName
				state.searchQuery = ""
				searchBox.Text = ""
				categoryContextLabel.Text = "// " .. string.upper(catName) .. " MATRIX"
				for otherId, data in pairs(dockTabs) do
					local isActive = (otherId == catName)
					data.text.TextColor3 = isActive and colors.textWhite or colors.textDim
					for _, part in ipairs(data.iconParts) do
						if part:IsA("UIStroke") then
							part.Color = isActive and colors.textWhite or colors.textDim
						else
							part.BackgroundColor3 = isActive and colors.textWhite or colors.textDim
						end
					end
					TweenService:Create(data.content, TweenInfo.new(0.18, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {
						Position = UDim2.new(0, 0, 0, isActive and -3 or 0)
					}):Play()
				end
				moveDockGlider(catName, true)
				animateStageLift()
				renderGrid()
			end
		end,
		setFilter = function(filterName)
			local fBtn = filterButtons[filterName]
			if fBtn then
				local fIdx = 1
				for i, fn in ipairs(filters) do
					if fn == filterName then fIdx = i break end
				end
				state.filter = filterName
				for otherF, otherFBtn in pairs(filterButtons) do
					local isActive = (otherF == filterName)
					TweenService:Create(otherFBtn, TweenInfo.new(0.15, Enum.EasingStyle.Quad), {
						TextColor3 = isActive and colors.textWhite or colors.textDim
					}):Play()
				end
				local slotW = 1 / #filters
				local targetScaleX = (fIdx - 1) * slotW
				TweenService:Create(filterGlider, TweenInfo.new(0.2, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {
					Position = UDim2.new(targetScaleX, 2, 0, 2),
					Size = UDim2.new(slotW, -4, 1, -4)
				}):Play()
				animateStageLift()
				renderGrid()
			end
		end,
		setSearch = function(query)
			searchBox.Text = query
		end,
		setWindowVisible = function(visible)
			state.isVisible = visible
			mainWindow.Visible = visible
			miniLauncher.Visible = not visible
		end,
		setScale = setScaleLevel,
		setDockReveal = function(reveal)
			updateDockReveal(reveal, false)
		end,
		toggleCollapse = function()
			state.isCollapsed = not state.isCollapsed
			if state.isCollapsed then
				collapseBtn.Text = "+"
				updateDockReveal(false, true)
				TweenService:Create(mainWindow, TweenInfo.new(0.25, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {
					Size = UDim2.new(0, 740, 0, 44)
				}):Play()
			else
				collapseBtn.Text = "-"
				local targetH = state.isMobile and 430 or 490
				TweenService:Create(mainWindow, TweenInfo.new(0.25, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {
					Size = UDim2.new(0, 740, 0, targetH)
				}):Play()
			end
		end,
		setMobile = setMobileMode,
		destroy = function()
			cancelAll()
			_G.ConsoleDemoController = nil
		end
	}

	return {
		screenGui = screenGui,
		controller = _G.ConsoleDemoController,
		cleanup = cancelAll
	}
end

runConsoleApp()
