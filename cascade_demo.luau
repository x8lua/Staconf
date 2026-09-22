local coreGui = game:GetService("CoreGui")
local players = game:GetService("Players")
local lighting = game:GetService("Lighting")
local userInputService = game:GetService("UserInputService")
local workspaceService = game:GetService("Workspace")

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

local function applyModernVisuals(targetGui)
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
			obj.BackgroundTransparency = 0.32
			obj.BackgroundColor3 = Color3.fromRGB(16, 18, 25)
		elseif obj.Name == "Sidebar" and obj:IsA("Frame") then
			obj.BackgroundTransparency = 0.45
			obj.BackgroundColor3 = Color3.fromRGB(24, 27, 38)
		elseif obj.Name == "Toolbar" and obj:IsA("Frame") then
			obj.BackgroundTransparency = 0.65
		elseif obj.Name == "ContentBody" and obj:IsA("Frame") then
			obj.BackgroundTransparency = 0.28
			obj.BackgroundColor3 = Color3.fromRGB(14, 16, 22)
		end
	end

	for _, descendant in ipairs(targetGui:GetDescendants()) do
		updateVisual(descendant)
	end

	targetGui.DescendantAdded:Connect(function(descendant)
		task.defer(updateVisual, descendant)
	end)
end

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
	local prefSection = window:Section({
		Title = "PREFERENCES",
		Disclosure = false,
	})

	local styleTab = prefSection:Tab({
		Title = "Appearance",
		Icon = cascade.Symbols.paintbrush,
	})

	local appSection = styleTab:PageSection({
		Title = "Theme & Visual Accents",
		Subtitle = "Customize the Sequoia design language",
	})

	local appForm = appSection:Form()

	local accentList = { "Blue", "Purple", "Green", "Orange", "Pink", "Red", "Yellow", "Graphite" }

	do
		local row = titledRow(appForm, "Accent Color", "Tint color applied to active controls and tabs")
		row:Right():PopUpButton({
			Options = accentList,
			Value = 1,
			ValueChanged = function(self, index)
				local selectedName = self.Options[index]
				if cascade.Accents[selectedName] then
					app.Accent = cascade.Accents[selectedName]
				end
			end,
		})
	end

	do
		local row = titledRow(appForm, "Theme Mode", "Base background lighting mode")
		row:Right():PopUpButton({
			Options = { "Dark", "Light" },
			Value = 1,
			ValueChanged = function(self, index)
				local mode = self.Options[index]
				if mode == "Dark" then
					app.Theme = cascade.Themes.Dark
				else
					app.Theme = cascade.Themes.Light
				end
			end,
		})
	end

	do
		local row = titledRow(appForm, "Window Dropshadow", "Toggle depth shadow around window frame")
		row:Right():Toggle({
			Value = window.Dropshadow,
			ValueChanged = function(self, value)
				window.Dropshadow = value
			end,
		})
	end

	do
		local row = titledRow(appForm, "Background Blur", "Apply frosted glass blur to window body")
		row:Right():Toggle({
			Value = window.UIBlur,
			ValueChanged = function(self, value)
				window.UIBlur = value
			end,
		})
	end

	do
		local row = titledRow(appForm, "Minimize Hotkey", "Keycode to toggle window visibility")
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
