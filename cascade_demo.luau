local coreGui = game:GetService("CoreGui")
local players = game:GetService("Players")
local lighting = game:GetService("Lighting")
local userInputService = game:GetService("UserInputService")
local workspaceService = game:GetService("Workspace")
local tweenService = game:GetService("TweenService")

local localPlayer = players.LocalPlayer or players:GetPropertyChangedSignal("LocalPlayer"):Wait()

local function cleanupExisting()
	local targets = {}
	if typeof(gethui) == "function" then
		pcall(function()
			table.insert(targets, gethui())
		end)
	end
	pcall(function()
		table.insert(targets, coreGui)
	end)
	if localPlayer and localPlayer:FindFirstChild("PlayerGui") then
		table.insert(targets, localPlayer.PlayerGui)
	end
	for _, parent in ipairs(targets) do
		for _, child in ipairs(parent:GetChildren()) do
			if child.Name == "Cascade" then
				pcall(function()
					child:Destroy()
				end)
			end
		end
	end
end

cleanupExisting()

local importUrl = "https://github.com/cascadeui/Cascade/releases/latest/download/dist.luau"
local cascade = loadstring(game:HttpGetAsync(importUrl))()

local function getAsset(fileName, rawUrl)
	local localPath = "Staconf/assets/" .. fileName
	if typeof(getcustomasset) == "function" and typeof(writefile) == "function" then
		local hasFile = (typeof(isfile) == "function" and isfile(localPath))
		if not hasFile then
			local s, data = pcall(function()
				return game:HttpGetAsync(rawUrl)
			end)
			if s and data then
				if typeof(makefolder) == "function" then
					pcall(function()
						makefolder("Staconf")
						makefolder("Staconf/assets")
					end)
				end
				pcall(function()
					writefile(localPath, data)
				end)
			end
		end
		local sAsset, assetId = pcall(function()
			return getcustomasset(localPath)
		end)
		if sAsset and assetId then
			return assetId
		end
	end
	return rawUrl
end

local function titledRow(parent, title, subtitle)
	local row = parent:Row({
		SearchIndex = title,
	})
	row:Left():TitleStack({
		Title = title,
		Subtitle = subtitle,
	})
	return row
end

local app = cascade.New({
	WindowPill = true,
	Theme = cascade.Themes.Dark,
	Accent = cascade.Accents.Blue,
})

local window = app:Window({
	Title = "Cascade Deck",
	Subtitle = "macOS Sequoia Runtime Console",
	Size = userInputService.TouchEnabled and UDim2.fromOffset(600, 380) or UDim2.fromOffset(800, 520),
	Searching = true,
	Draggable = true,
	Resizable = true,
	CanExit = true,
	CanMinimize = true,
	CanZoom = true,
	Dropshadow = true,
	UIBlur = true,
})

local acrylicBlur = lighting:FindFirstChild("CascadeAcrylicBlur")
if not acrylicBlur then
	acrylicBlur = Instance.new("BlurEffect")
	acrylicBlur.Name = "CascadeAcrylicBlur"
	acrylicBlur.Size = 14
	acrylicBlur.Parent = lighting
end

window.Destroying:Connect(function()
	if acrylicBlur and acrylicBlur.Parent then
		acrylicBlur:Destroy()
	end
end)

local minimizeKey = Enum.KeyCode.RightControl
userInputService.InputEnded:Connect(function(input, processed)
	if input.KeyCode == minimizeKey and not processed then
		window.Minimized = not window.Minimized
		if acrylicBlur then
			acrylicBlur.Enabled = not window.Minimized
		end
	end
end)

local currentMode = "Dark"
local currentAccent = "Blue"
local currentCascadeGui = nil

local modeColors = {
	Dark = {
		bodyBg = Color3.fromRGB(16, 18, 25),
		bodyTrans = 0.32,
		contentBg = Color3.fromRGB(14, 16, 22),
		contentTrans = 0.28,
		sidebarTop = Color3.fromRGB(30, 34, 46),
		sidebarBottom = Color3.fromRGB(18, 20, 28),
		sidebarTransTop = 0.35,
		sidebarTransBottom = 0.48,
		separatorBg = Color3.fromRGB(40, 44, 58),
		separatorTrans = 0.4,
	},
	Light = {
		bodyBg = Color3.fromRGB(240, 242, 246),
		bodyTrans = 0.15,
		contentBg = Color3.fromRGB(255, 255, 255),
		contentTrans = 0.08,
		sidebarTop = Color3.fromRGB(255, 255, 255),
		sidebarBottom = Color3.fromRGB(224, 227, 235),
		sidebarTransTop = 0.08,
		sidebarTransBottom = 0.22,
		separatorBg = Color3.fromRGB(218, 221, 227),
		separatorTrans = 0.4,
	},
}

local gradTopVal = Instance.new("Color3Value")
gradTopVal.Value = modeColors.Dark.sidebarTop
local gradBottomVal = Instance.new("Color3Value")
gradBottomVal.Value = modeColors.Dark.sidebarBottom
local gradTopTransVal = Instance.new("NumberValue")
gradTopTransVal.Value = modeColors.Dark.sidebarTransTop
local gradBottomTransVal = Instance.new("NumberValue")
gradBottomTransVal.Value = modeColors.Dark.sidebarTransBottom

local trackedGradients = {}

local function syncGradient(grad)
	if grad and grad.Parent then
		grad.Color = ColorSequence.new({
			ColorSequenceKeypoint.new(0, gradTopVal.Value),
			ColorSequenceKeypoint.new(1, gradBottomVal.Value),
		})
		grad.Transparency = NumberSequence.new({
			NumberSequenceKeypoint.new(0, math.clamp(gradTopTransVal.Value, 0, 1)),
			NumberSequenceKeypoint.new(1, math.clamp(gradBottomTransVal.Value, 0, 1)),
		})
	end
end

local function trackGradient(grad)
	table.insert(trackedGradients, grad)
	syncGradient(grad)
	grad.Destroying:Connect(function()
		for i = #trackedGradients, 1, -1 do
			if trackedGradients[i] == grad then
				table.remove(trackedGradients, i)
			end
		end
	end)
end

local function onGradientValueChanged()
	for _, grad in ipairs(trackedGradients) do
		syncGradient(grad)
	end
end

gradTopVal.Changed:Connect(onGradientValueChanged)
gradBottomVal.Changed:Connect(onGradientValueChanged)
gradTopTransVal.Changed:Connect(onGradientValueChanged)
gradBottomTransVal.Changed:Connect(onGradientValueChanged)

local function applyModernVisuals(targetGui)
	currentCascadeGui = targetGui
	local function updateVisual(obj)
		if obj:IsA("UICorner") and obj.CornerRadius.Scale == 0 then
			local off = obj.CornerRadius.Offset
			if off == 10 then
				obj.CornerRadius = UDim.new(0, 22)
			elseif off == 6 then
				obj.CornerRadius = UDim.new(0, 14)
			elseif off == 5 or off == 4 then
				obj.CornerRadius = UDim.new(0, 10)
			end
		elseif obj.Name == "Disclosure" then
			obj.Visible = false
		elseif obj.Name == "Body" and obj:IsA("Frame") then
			local cfg = modeColors[currentMode]
			obj.BackgroundTransparency = cfg.bodyTrans
			obj.BackgroundColor3 = cfg.bodyBg
		elseif obj.Name == "Sidebar" and obj:IsA("Frame") then
			local corner = obj:FindFirstChild("SidebarCorner")
			if not corner then
				corner = Instance.new("UICorner")
				corner.Name = "SidebarCorner"
				corner.CornerRadius = UDim.new(0, 22)
				corner.Parent = obj
			end
			local filler = obj:FindFirstChild("RightEdgeFiller")
			if not filler then
				filler = Instance.new("Frame")
				filler.Name = "RightEdgeFiller"
				filler.BorderSizePixel = 0
				filler.AnchorPoint = Vector2.new(1, 0)
				filler.Position = UDim2.new(1, 0, 0, 0)
				filler.Size = UDim2.new(0, 24, 1, 0)
				filler.ZIndex = obj.ZIndex
				filler.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
				filler.BackgroundTransparency = 0
				filler.Parent = obj
			end
			local grad = obj:FindFirstChild("SidebarGradient")
			if not grad then
				grad = Instance.new("UIGradient")
				grad.Name = "SidebarGradient"
				grad.Rotation = 90
				grad.Parent = obj
				trackGradient(grad)
			end
			local fillerGrad = filler:FindFirstChild("FillerGradient")
			if not fillerGrad then
				fillerGrad = Instance.new("UIGradient")
				fillerGrad.Name = "FillerGradient"
				fillerGrad.Rotation = 90
				fillerGrad.Parent = filler
				trackGradient(fillerGrad)
			end
			obj.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
			obj.BackgroundTransparency = 0
			filler.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
			filler.BackgroundTransparency = 0
		elseif obj.Name == "Toolbar" and obj:IsA("Frame") then
			obj.BackgroundTransparency = 1
		elseif obj.Name == "Separator" and obj:IsA("Frame") then
			local cfg = modeColors[currentMode]
			obj.BackgroundTransparency = cfg.separatorTrans
			obj.BackgroundColor3 = cfg.separatorBg
		elseif obj.Name == "ContentBody" and obj:IsA("Frame") then
			local cfg = modeColors[currentMode]
			obj.BackgroundTransparency = cfg.contentTrans
			obj.BackgroundColor3 = cfg.contentBg
		end
	end

	for _, descendant in ipairs(targetGui:GetDescendants()) do
		updateVisual(descendant)
	end

	targetGui.DescendantAdded:Connect(function(descendant)
		task.defer(updateVisual, descendant)
	end)
end

local function smoothTransition(newMode, newAccentName)
	local tweenInfo = TweenInfo.new(0.38, Enum.EasingStyle.Quart, Enum.EasingDirection.Out)
	local targetGui = currentCascadeGui
	local snapshot = {}

	if targetGui then
		for _, desc in ipairs(targetGui:GetDescendants()) do
			if desc:IsA("GuiObject") and desc.Name ~= "RightEdgeFiller" and desc.Name ~= "Sidebar" then
				local entry = {
					BackgroundColor3 = desc.BackgroundColor3,
					BackgroundTransparency = desc.BackgroundTransparency,
				}
				if desc:IsA("TextLabel") or desc:IsA("TextButton") or desc:IsA("TextBox") then
					entry.TextColor3 = desc.TextColor3
				end
				if desc:IsA("ImageLabel") or desc:IsA("ImageButton") then
					entry.ImageColor3 = desc.ImageColor3
				end
				snapshot[desc] = entry
			end
		end
	end

	if newMode and modeColors[newMode] and newMode ~= currentMode then
		currentMode = newMode
		app.Theme = (newMode == "Dark" and cascade.Themes.Dark or cascade.Themes.Light)
		local cfg = modeColors[newMode]

		tweenService:Create(gradTopVal, tweenInfo, { Value = cfg.sidebarTop }):Play()
		tweenService:Create(gradBottomVal, tweenInfo, { Value = cfg.sidebarBottom }):Play()
		tweenService:Create(gradTopTransVal, tweenInfo, { Value = cfg.sidebarTransTop }):Play()
		tweenService:Create(gradBottomTransVal, tweenInfo, { Value = cfg.sidebarTransBottom }):Play()

		if targetGui then
			local body = targetGui:FindFirstChild("Body", true)
			if body and body:IsA("Frame") then
				tweenService:Create(body, tweenInfo, {
					BackgroundColor3 = cfg.bodyBg,
					BackgroundTransparency = cfg.bodyTrans,
				}):Play()
			end
			local content = targetGui:FindFirstChild("ContentBody", true)
			if content and content:IsA("Frame") then
				tweenService:Create(content, tweenInfo, {
					BackgroundColor3 = cfg.contentBg,
					BackgroundTransparency = cfg.contentTrans,
				}):Play()
			end
			local sep = targetGui:FindFirstChild("Separator", true)
			if sep and sep:IsA("Frame") then
				tweenService:Create(sep, tweenInfo, {
					BackgroundColor3 = cfg.separatorBg,
					BackgroundTransparency = cfg.separatorTrans,
				}):Play()
			end
		end
	end

	if newAccentName and cascade.Accents[newAccentName] and newAccentName ~= currentAccent then
		currentAccent = newAccentName
		app.Accent = cascade.Accents[newAccentName]
	end

	task.defer(function()
		for desc, oldProps in pairs(snapshot) do
			if desc and desc.Parent then
				local props = {}
				if oldProps.BackgroundColor3 and desc.BackgroundColor3 ~= oldProps.BackgroundColor3 then
					local target = desc.BackgroundColor3
					desc.BackgroundColor3 = oldProps.BackgroundColor3
					props.BackgroundColor3 = target
				end
				if oldProps.BackgroundTransparency and math.abs(desc.BackgroundTransparency - oldProps.BackgroundTransparency) > 0.02 then
					local target = desc.BackgroundTransparency
					desc.BackgroundTransparency = oldProps.BackgroundTransparency
					props.BackgroundTransparency = target
				end
				if oldProps.TextColor3 and desc:IsA("TextLabel") and desc.TextColor3 ~= oldProps.TextColor3 then
					local target = desc.TextColor3
					desc.TextColor3 = oldProps.TextColor3
					props.TextColor3 = target
				end
				if oldProps.ImageColor3 and desc:IsA("ImageLabel") and desc.ImageColor3 ~= oldProps.ImageColor3 then
					local target = desc.ImageColor3
					desc.ImageColor3 = oldProps.ImageColor3
					props.ImageColor3 = target
				end
				if next(props) then
					tweenService:Create(desc, tweenInfo, props):Play()
				end
			end
		end
	end)
end

_G.CascadeSmoothTransition = smoothTransition

task.defer(function()
	local targets = {}
	if typeof(gethui) == "function" then
		pcall(function()
			table.insert(targets, gethui())
		end)
	end
	pcall(function()
		table.insert(targets, coreGui)
	end)
	if localPlayer and localPlayer:FindFirstChild("PlayerGui") then
		table.insert(targets, localPlayer.PlayerGui)
	end
	for _, t in ipairs(targets) do
		local c = t:FindFirstChild("Cascade")
		if c then
			applyModernVisuals(c)
			break
		end
	end
end)

do
	local runtimeSection = window:Section({
		Title = "RUNTIME MATRIX",
		Disclosure = false,
	})

	local overviewTab = runtimeSection:Tab({
		Title = "Telemetry",
		Icon = cascade.Symbols.sliderHorizontal3,
		Selected = true,
	})

	local perfSection = overviewTab:PageSection({
		Title = "Performance & Display",
		Subtitle = "Real-time client rendering controls",
	})

	local perfForm = perfSection:Form()

	do
		local row = titledRow(perfForm, "Field Of View", "Dynamically adjust camera projection angle")
		local currentFov = workspaceService.CurrentCamera and workspaceService.CurrentCamera.FieldOfView or 70
		local fovLabel = row:Right():Label({
			Text = tostring(math.floor(currentFov)) .. "°",
		})
		row:Right():Slider({
			Minimum = 60,
			Maximum = 120,
			Value = currentFov,
			ValueChanged = function(self, value)
				local val = math.floor(value)
				fovLabel.Text = tostring(val) .. "°"
				if workspaceService.CurrentCamera then
					workspaceService.CurrentCamera.FieldOfView = val
				end
			end,
		})
	end

	do
		local row = titledRow(perfForm, "Low Latency Rendering", "Bypass redundant post-process sampling")
		row:Right():Toggle({
			Value = true,
			ValueChanged = function(self, value)
				app:Notification({
					App = "Cascade",
					Title = "Pipeline Update",
					Subtitle = "Low Latency Rendering set to " .. tostring(value),
					Duration = 2.5,
				})
			end,
		})
	end

	local diagSection = overviewTab:PageSection({
		Title = "Diagnostics & Maintenance",
		Subtitle = "Engine telemetry utilities",
	})

	local diagForm = diagSection:Form()

	do
		local row = titledRow(diagForm, "Telemetry Ping", "Send status handshake to local monitor")
		row:Right():Button({
			Label = "Dispatch",
			State = "Primary",
			Pushed = function()
				local fps = math.floor(1 / (workspaceService:GetRealPhysicsFPS() > 0 and workspaceService:GetRealPhysicsFPS() or 60))
				app:Notification({
					App = "Cascade",
					Title = "Telemetry Echo",
					Subtitle = "Connection solid. Engine heartbeat responsive.",
					Duration = 3,
				})
			end,
		})
	end

	do
		local row = titledRow(diagForm, "Garbage Collector", "Trigger incremental GC cycle to free memory")
		row:Right():Button({
			Label = "Collect GC",
			State = "Destructive",
			Pushed = function()
				local before = gcinfo()
				collectgarbage("collect")
				local after = gcinfo()
				app:Notification({
					App = "Cascade",
					Title = "GC Complete",
					Subtitle = ("Freed ~%d KB of client memory"):format(math.max(0, before - after)),
					Duration = 3.5,
				})
			end,
		})
	end
end

do
	local worldSection = window:Section({
		Title = "ENVIRONMENT",
		Disclosure = false,
	})

	local lightingTab = worldSection:Tab({
		Title = "Atmosphere",
		Icon = cascade.Symbols.sunMax,
	})

	local envSection = lightingTab:PageSection({
		Title = "Lighting Engine",
		Subtitle = "Manipulate world lighting properties in real time",
	})

	local envForm = envSection:Form()

	do
		local row = titledRow(envForm, "Clock Time", "Adjust world time of day")
		local timeLabel = row:Right():Label({
			Text = ("%.1f h"):format(lighting.ClockTime),
		})
		row:Right():Slider({
			Minimum = 0,
			Maximum = 24,
			Value = lighting.ClockTime,
			ValueChanged = function(self, value)
				timeLabel.Text = ("%.1f h"):format(value)
				lighting.ClockTime = value
			end,
		})
	end

	do
		local row = titledRow(envForm, "Global Shadows", "Toggle sunlight occlusion shadows")
		row:Right():Toggle({
			Value = lighting.GlobalShadows,
			ValueChanged = function(self, value)
				lighting.GlobalShadows = value
			end,
		})
	end

	do
		local row = titledRow(envForm, "Atmosphere Preset", "Quick switch ambient grading")
		row:Right():PopUpButton({
			Options = { "Default", "Neon Dusk", "Midnight Void", "Golden Hour" },
			Value = 1,
			ValueChanged = function(self, index)
				local name = self.Options[index]
				if name == "Default" then
					lighting.OutdoorAmbient = Color3.fromRGB(128, 128, 128)
					lighting.Brightness = 2
				elseif name == "Neon Dusk" then
					lighting.OutdoorAmbient = Color3.fromRGB(130, 80, 180)
					lighting.Brightness = 1.5
				elseif name == "Midnight Void" then
					lighting.OutdoorAmbient = Color3.fromRGB(20, 25, 45)
					lighting.Brightness = 0.5
				elseif name == "Golden Hour" then
					lighting.OutdoorAmbient = Color3.fromRGB(255, 170, 90)
					lighting.Brightness = 2.4
				end
				app:Notification({
					App = "Cascade",
					Title = "Lighting Preset",
					Subtitle = "Applied preset: " .. name,
					Duration = 2,
				})
			end,
		})
	end
end

do
	local playerSection = window:Section({
		Title = "PLAYER DYNAMICS",
		Disclosure = false,
	})

	local moveTab = playerSection:Tab({
		Title = "Locomotion",
		Icon = cascade.Symbols.hare,
	})

	local moveSection = moveTab:PageSection({
		Title = "Movement Vectors",
		Subtitle = "Tweak character physics properties",
	})

	local moveForm = moveSection:Form()

	local function getHumanoid()
		local char = localPlayer.Character
		return char and char:FindFirstChildOfClass("Humanoid")
	end

	do
		local row = titledRow(moveForm, "Walk Speed", "Modify character horizontal speed")
		local hum = getHumanoid()
		local curSpeed = hum and hum.WalkSpeed or 16
		local speedLabel = row:Right():Label({
			Text = tostring(math.floor(curSpeed)),
		})
		row:Right():Slider({
			Minimum = 16,
			Maximum = 120,
			Value = curSpeed,
			ValueChanged = function(self, value)
				local val = math.floor(value)
				speedLabel.Text = tostring(val)
				local targetHum = getHumanoid()
				if targetHum then
					targetHum.WalkSpeed = val
				end
			end,
		})
	end

	do
		local row = titledRow(moveForm, "Jump Power", "Modify character vertical velocity impulse")
		local hum = getHumanoid()
		local curJump = hum and hum.JumpPower or 50
		local jumpLabel = row:Right():Label({
			Text = tostring(math.floor(curJump)),
		})
		row:Right():Slider({
			Minimum = 50,
			Maximum = 200,
			Value = curJump,
			ValueChanged = function(self, value)
				local val = math.floor(value)
				jumpLabel.Text = tostring(val)
				local targetHum = getHumanoid()
				if targetHum then
					targetHum.UseJumpPower = true
					targetHum.JumpPower = val
				end
			end,
		})
	end

	do
		local row = titledRow(moveForm, "Reset Locomotion", "Restore original character physics")
		row:Right():Button({
			Label = "Reset to Default",
			State = "Secondary",
			Pushed = function()
				local targetHum = getHumanoid()
				if targetHum then
					targetHum.WalkSpeed = 16
					targetHum.JumpPower = 50
					app:Notification({
						App = "Cascade",
						Title = "Locomotion Reset",
						Subtitle = "WalkSpeed restored to 16, JumpPower to 50",
						Duration = 2,
					})
				end
			end,
		})
	end
end

do
	local appearanceSection = window:Section({
		Title = "APPEARANCE",
		Disclosure = false,
	})

	local appearanceTab = appearanceSection:Tab({
		Title = "Appearance",
		Icon = getAsset("appearance.png", "https://raw.githubusercontent.com/x8lua/Staconf/main/assets/appearance.png"),
	})

	local modeSection = appearanceTab:PageSection({
		Title = "Appearance",
		Subtitle = "Configure desktop visual presentation",
	})

	local modeForm = modeSection:Form()

	do
		local row = titledRow(modeForm, "Interface Mode", "Select system lighting scheme")
		row:Right():PopUpButton({
			Options = { "Dark", "Light" },
			Value = (currentMode == "Dark" and 1 or 2),
			ValueChanged = function(self, index)
				local mode = self.Options[index]
				smoothTransition(mode, nil)
			end,
		})
	end

	local themeSection = appearanceTab:PageSection({
		Title = "Theme",
		Subtitle = "Accent palette and highlight preferences",
	})

	local themeForm = themeSection:Form()

	local accentList = { "Blue", "Purple", "Pink", "Red", "Orange", "Yellow", "Green", "Graphite" }

	do
		local row = titledRow(themeForm, "Colour", "Tint color applied to active controls and tabs")
		row:Right():PopUpButton({
			Options = accentList,
			Value = 1,
			ValueChanged = function(self, index)
				local selectedName = self.Options[index]
				smoothTransition(nil, selectedName)
			end,
		})
	end

	do
		local row = titledRow(themeForm, "Text Highlight Colour", "Accent tint for selected text elements")
		row:Right():PopUpButton({
			Options = { "Automatic", "Blue", "Purple", "Pink", "Red", "Orange", "Yellow", "Green", "Graphite" },
			Value = 1,
		})
	end

	do
		local row = titledRow(themeForm, "Icon and Widget Style", "Visual presentation of interface elements")
		row:Right():PopUpButton({
			Options = { "Default", "Dark", "Clear", "Tinted" },
			Value = 1,
		})
	end

	do
		local row = titledRow(themeForm, "Folder Colour", "Directory and group container tint")
		row:Right():PopUpButton({
			Options = { "Automatic", "Blue", "Purple", "Pink", "Graphite" },
			Value = 1,
		})
	end

	local fxSection = appearanceTab:PageSection({
		Title = "Window Effects",
		Subtitle = "Frosted glass acrylic blur and ambient occlusion",
	})

	local fxForm = fxSection:Form()

	do
		local row = titledRow(fxForm, "Acrylic Blur", "Sample real-time world glass refraction through sidebar")
		row:Right():Toggle({
			Value = true,
			ValueChanged = function(self, value)
				if acrylicBlur then
					acrylicBlur.Enabled = value
				end
			end,
		})
	end

	do
		local row = titledRow(fxForm, "Window Dropshadow", "Toggle depth shadow around window frame")
		row:Right():Toggle({
			Value = window.Dropshadow,
			ValueChanged = function(self, value)
				window.Dropshadow = value
			end,
		})
	end

	do
		local row = titledRow(fxForm, "Minimize Hotkey", "Keycode to toggle window visibility")
		row:Right():KeybindField({
			Value = minimizeKey,
			ValueChanged = function(self, value)
				minimizeKey = value
				app:Notification({
					App = "Cascade",
					Title = "Hotkey Updated",
					Subtitle = "Minimize hotkey bound to " .. tostring(value.Name),
					Duration = 2.5,
				})
			end,
		})
	end
end

app:Notification({
	App = "Cascade",
	Title = "System Online",
	Subtitle = "Cascade Deck initialized successfully. Press RightControl to toggle.",
	Duration = 4,
})
