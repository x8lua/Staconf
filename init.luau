-- Reusable Cascade shell. Application state and tab content belong to the caller.
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local SoundService = game:GetService("SoundService")
local CASCADE_URL = "https://github.com/cascadeui/Cascade/releases/latest/download/dist.luau"
local ASSET_URL = "https://raw.githubusercontent.com/x8lua/Staconf/main/assets/"
local Staconf = {}
Staconf.__index = Staconf

local function raw(value)
    return typeof(value) == "Instance" and value or value and value.__instance
end

local function round(parent, radius)
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, radius)
    corner.Parent = parent
end

local function windowSize(gui, size)
    if size then return size end
    if not UserInputService.TouchEnabled then return UDim2.fromOffset(800, 520) end
    local bounds = gui.AbsoluteSize
    if bounds.X < 100 or bounds.Y < 100 then
        local camera = workspace.CurrentCamera
        bounds = camera and camera.ViewportSize or Vector2.new(600, 380)
    end
    return UDim2.fromOffset(math.floor(math.min(520, bounds.X * 0.84)),
        math.floor(math.min(360, bounds.Y * 0.72)))
end

function Staconf:Asset(fileName)
    if not fileName then return nil end
    if fileName:find("^rbxassetid://") then return fileName end
    local url = self.AssetBaseUrl .. fileName
    if type(getcustomasset) ~= "function" or type(writefile) ~= "function" then return url end
    local path = self.CacheRoot .. "/assets/" .. fileName
    if type(isfile) ~= "function" or not isfile(path) then
        local ok, data = pcall(function() return game:HttpGetAsync(url) end)
        if ok and type(data) == "string" and #data > 0 then
            if type(makefolder) == "function" then
                pcall(makefolder, self.CacheRoot)
                pcall(makefolder, self.CacheRoot .. "/assets")
                local folder = self.CacheRoot .. "/assets"
                for segment in fileName:gmatch("([^/]+)/") do
                    folder = folder .. "/" .. segment
                    pcall(makefolder, folder)
                end
            end
            pcall(writefile, path, data)
        end
    end
    local ok, asset = pcall(getcustomasset, path)
    return ok and asset or url
end

function Staconf:ShowBoot()
    if self._destroyed then return nil end
    if self._boot then return self._boot end
    local body = raw(self.Window.Structures.Body)
    local overlay = Instance.new("CanvasGroup")
    overlay.Name = "StacOnfBootOverlay"
    overlay.Size = UDim2.fromScale(1, 1)
    overlay.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
    overlay.BorderSizePixel = 0
    overlay.ZIndex = 50000
    overlay.Parent = body
    round(overlay, 16)
    local logo = Instance.new("ImageLabel")
    logo.Name = "SplashLogo"
    local image = self.BootImage or self:Asset(self.BootImageFile)
    logo.Image = image or ""
    logo.AnchorPoint = Vector2.new(0.5, 0.5)
    logo.Position = UDim2.new(0.5, 0, 0.42, -10)
    logo.Size = UserInputService.TouchEnabled and UDim2.new(1, -36, 0.68, 0) or UDim2.fromOffset(480, 270)
    logo.ScaleType = Enum.ScaleType.Fit
    logo.BackgroundTransparency = 1
    logo.Visible = image ~= nil
    logo.Parent = overlay
    if not image then
        local title = Instance.new("TextLabel")
        title.Name = "BootTitle"
        title.AnchorPoint = Vector2.new(0.5, 0.5)
        title.Position = UDim2.new(0.5, 0, 0.42, -10)
        title.Size = UDim2.new(1, -36, 0, 90)
        title.BackgroundTransparency = 1
        title.Font = Enum.Font.GothamBold
        title.Text = self.Title
        title.TextSize = UserInputService.TouchEnabled and 30 or 42
        title.TextScaled = false
        title.TextWrapped = true
        title.TextColor3 = Color3.fromRGB(245, 246, 250)
        title.Parent = overlay
    end
    local track = Instance.new("Frame")
    track.Name = "ProgressTrack"
    track.AnchorPoint = Vector2.new(0.5, 0.5)
    track.Position = UDim2.new(0.5, 0, 0.42, 85)
    track.Size = UDim2.fromOffset(260, 5)
    track.BackgroundColor3 = Color3.fromRGB(48, 48, 52)
    track.BackgroundTransparency = 1
    track.BorderSizePixel = 0
    track.Visible = false
    track.Parent = overlay
    round(track, 5)
    local fill = Instance.new("Frame")
    fill.Name = "ProgressFill"
    fill.Size = UDim2.fromScale(0, 1)
    fill.BackgroundColor3 = self.ProgressColor
    fill.BackgroundTransparency = 1
    fill.BorderSizePixel = 0
    fill.Parent = track
    round(fill, 5)
    self._boot = {Overlay = overlay, Fill = fill}
    if self.BootSoundId then
        local sound = Instance.new("Sound")
        sound.Name = "StacOnfBootSfx"
        sound.SoundId = self.BootSoundId
        sound.Volume = self.BootSoundVolume
        sound.Parent = SoundService
        self._bootSound = sound
        pcall(function() game:GetService("ContentProvider"):PreloadAsync({sound}) end)
        sound:Play()
    end
    return self._boot
end

function Staconf:SetBootProgress(progress)
    local boot = self._boot
    if not boot or not boot.Fill.Parent then return end
    TweenService:Create(boot.Fill, TweenInfo.new(0.14, Enum.EasingStyle.Quart, Enum.EasingDirection.Out),
        {Size = UDim2.fromScale(math.clamp(tonumber(progress) or 0, 0, 1), 1)}):Play()
end

function Staconf:RevealBootProgress()
    local boot = self._boot
    if not boot or not boot.Overlay.Parent then return end
    local track = boot.Fill.Parent
    track.Visible = true
    TweenService:Create(track, TweenInfo.new(0.3, Enum.EasingStyle.Quart, Enum.EasingDirection.Out),
        {BackgroundTransparency = 0}):Play()
    TweenService:Create(boot.Fill, TweenInfo.new(0.3, Enum.EasingStyle.Quart, Enum.EasingDirection.Out),
        {BackgroundTransparency = 0}):Play()
end

function Staconf:FinishBoot()
    local boot = self._boot
    if not boot or not boot.Overlay.Parent then return end
    self:SetBootProgress(1)
    local tween = TweenService:Create(boot.Overlay, TweenInfo.new(0.55, Enum.EasingStyle.Cubic, Enum.EasingDirection.Out),
        {GroupTransparency = 1})
    local sound = self._bootSound
    self._bootSound = nil
    tween.Completed:Once(function()
        if boot.Overlay.Parent then boot.Overlay:Destroy() end
        if sound and sound.Parent then sound:Destroy() end
    end)
    tween:Play()
    self._boot = nil
end

function Staconf:_noticeHost()
    if self._destroyed then return end
    if self._noticeGui and self._noticeGui.Parent then return end
    local gui = Instance.new("ScreenGui")
    gui.Name = self.Name .. "Notifications"
    gui.ResetOnSpawn = false
    gui.DisplayOrder = 1000
    gui.ScreenInsets = Enum.ScreenInsets.CoreUISafeInsets
    gui.Parent = self.App.__instance.Parent
    local host = Instance.new("Frame")
    host.AnchorPoint = Vector2.new(1, 0)
    host.Position = UDim2.new(1, -16, 0, 14)
    host.Size = UDim2.new(1, -32, 0, 0)
    host.AutomaticSize = Enum.AutomaticSize.Y
    host.BackgroundTransparency = 1
    host.Parent = gui
    local hostLimit = Instance.new("UISizeConstraint")
    hostLimit.MaxSize = Vector2.new(360, 10000)
    hostLimit.Parent = host
    local layout = Instance.new("UIListLayout")
    layout.Padding = UDim.new(0, 8)
    layout.Parent = host
    self._noticeGui, self._noticeHostFrame = gui, host
end

function Staconf:Notify(options)
    if self._destroyed then return nil end
    options = options or {}
    self:_noticeHost()
    local light = self.Mode == "Light"
    local card = Instance.new("CanvasGroup")
    card.Name = "Notification"
    card.Size = UDim2.new(1, 0, 0, 104)
    card.BackgroundColor3 = light and Color3.fromRGB(235, 242, 247) or Color3.fromRGB(201, 228, 232)
    card.BackgroundTransparency = 0.06
    card.BorderSizePixel = 0
    card.GroupTransparency = 1
    card.Parent = self._noticeHostFrame
    round(card, 23)
    local rim = Instance.new("UIStroke")
    rim.Color = Color3.fromRGB(235, 242, 255)
    rim.Transparency = 0.72
    rim.Thickness = 1
    rim.Parent = card
    local iconFrame = Instance.new("Frame")
    iconFrame.Name = "AppIcon"
    iconFrame.Size = UDim2.fromOffset(38, 38)
    iconFrame.Position = UDim2.new(0, 16, 0.5, -19)
    iconFrame.BackgroundColor3 = Color3.fromRGB(31, 37, 49)
    iconFrame.BorderSizePixel = 0
    iconFrame.Parent = card
    round(iconFrame, 10)
    local icon = Instance.new("ImageLabel")
    icon.BackgroundTransparency = 1
    icon.Size = UDim2.fromOffset(24, 24)
    icon.Position = UDim2.fromOffset(7, 7)
    icon.Image = options.Icon or self.Cascade.Symbols.sliderHorizontal3
    icon.ImageColor3 = Color3.fromRGB(209, 192, 255)
    icon.Parent = iconFrame
    for index, content in ipairs({options.App or self.Title, options.Title or "Notification", options.Subtitle or options.Description or ""}) do
        local label = Instance.new("TextLabel")
        label.Position = UDim2.fromOffset(68, index == 1 and 13 or index == 2 and 32 or 51)
        label.Size = UDim2.new(1, -84, 0, index == 3 and 43 or 20)
        label.BackgroundTransparency = 1
        label.Font = index == 1 and Enum.Font.GothamBold or Enum.Font.Gotham
        label.TextSize = index == 1 and 14 or 15
        label.TextWrapped = true
        label.TextXAlignment = Enum.TextXAlignment.Left
        label.TextColor3 = Color3.fromRGB(31, 37, 49)
        label.Text = tostring(content)
        label.Parent = card
    end
    local dismiss = Instance.new("TextButton")
    dismiss.Text = ""
    dismiss.BackgroundTransparency = 1
    dismiss.Size = UDim2.fromScale(1, 1)
    dismiss.AutoButtonColor = false
    dismiss.Parent = card
    dismiss.Activated:Connect(function() if card.Parent then card:Destroy() end end)
    if light then card.BackgroundColor3 = Color3.fromRGB(235, 242, 247) end
    TweenService:Create(card, TweenInfo.new(0.22), {GroupTransparency = 0}):Play()
    task.delay(tonumber(options.Duration) or 4, function()
        if self._destroyed or not card.Parent then return end
        local tween = TweenService:Create(card, TweenInfo.new(0.22), {GroupTransparency = 1})
        tween.Completed:Once(function() if card.Parent then card:Destroy() end end)
        tween:Play()
    end)
    return card
end

function Staconf:Dialog(options)
    if self._destroyed then return nil end
    options = options or {}
    local gui = Instance.new("ScreenGui")
    gui.Name = self.Name .. "Dialog"
    gui.ResetOnSpawn = false
    gui.DisplayOrder = 10000
    gui.ScreenInsets = Enum.ScreenInsets.CoreUISafeInsets
    gui.Parent = self.App.__instance.Parent
    table.insert(self._dialogs, gui)
    local dim = Instance.new("TextButton")
    dim.Text = ""
    dim.AutoButtonColor = false
    dim.Size = UDim2.fromScale(1, 1)
    dim.BackgroundColor3 = Color3.new(0, 0, 0)
    dim.BackgroundTransparency = options.DimBackground == false and 1 or 0.4
    dim.Parent = gui
    local card = Instance.new("ScrollingFrame")
    card.Name = "DialogCard"
    card.AnchorPoint = Vector2.new(0.5, 0.5)
    card.Position = UDim2.fromScale(0.5, 0.5)
    local viewport = gui.AbsoluteSize
    if viewport.X < 100 or viewport.Y < 100 then
        local camera = workspace.CurrentCamera
        viewport = camera and camera.ViewportSize or Vector2.new(600, 380)
    end
    local maxWidth = math.max(1, viewport.X - 32)
    card.Size = UDim2.fromOffset(math.min(math.clamp(tonumber(options.Width) or 420, 260, 560), maxWidth), 0)
    card.AutomaticSize = Enum.AutomaticSize.Y
    card.AutomaticCanvasSize = Enum.AutomaticSize.Y
    card.CanvasSize = UDim2.fromOffset(0, 0)
    card.ScrollBarThickness = 3
    card.BackgroundColor3 = self.Mode == "Light" and Color3.fromRGB(250, 250, 252) or Color3.fromRGB(29, 31, 40)
    card.BorderSizePixel = 0
    card.Parent = gui
    round(card, 20)
    local cardStroke = Instance.new("UIStroke")
    cardStroke.Color = self.Mode == "Light" and Color3.fromRGB(214, 218, 227) or Color3.fromRGB(83, 88, 104)
    cardStroke.Transparency = 0.32
    cardStroke.Thickness = 1
    cardStroke.Parent = card
    local sizeLimit = Instance.new("UISizeConstraint")
    sizeLimit.MaxSize = Vector2.new(maxWidth, math.max(1, viewport.Y - 32))
    sizeLimit.Parent = card
    local function fitDialog()
        if not gui.Parent then return end
        local bounds = gui.AbsoluteSize
        if bounds.X < 100 or bounds.Y < 100 then return end
        local safeWidth = math.max(1, bounds.X - 32)
        card.Size = UDim2.fromOffset(math.min(math.clamp(tonumber(options.Width) or 420, 260, 560), safeWidth), 0)
        sizeLimit.MaxSize = Vector2.new(safeWidth, math.max(1, bounds.Y - 32))
    end
    gui:GetPropertyChangedSignal("AbsoluteSize"):Connect(fitDialog)
    local padding = Instance.new("UIPadding")
    padding.PaddingTop = UDim.new(0, 24)
    padding.PaddingBottom = UDim.new(0, 20)
    padding.PaddingLeft = UDim.new(0, 24)
    padding.PaddingRight = UDim.new(0, 24)
    padding.Parent = card
    local layout = Instance.new("UIListLayout")
    layout.Padding = UDim.new(0, 14)
    layout.Parent = card
    for index, content in ipairs({options.Title or self.Title, options.Description or ""}) do
        local label = Instance.new("TextLabel")
        label.Size = UDim2.new(1, 0, 0, 0)
        label.AutomaticSize = Enum.AutomaticSize.Y
        label.BackgroundTransparency = 1
        label.Font = index == 1 and Enum.Font.GothamBold or Enum.Font.Gotham
        label.TextSize = index == 1 and 19 or 14
        label.TextWrapped = true
        label.TextXAlignment = Enum.TextXAlignment.Left
        label.TextColor3 = self.Mode == "Light" and Color3.fromRGB(27, 29, 36) or Color3.fromRGB(240, 242, 248)
        label.Text = tostring(content)
        label.Parent = card
    end
    local buttons = Instance.new("Frame")
    local actions = options.Buttons or {{Text = "OK", Style = "Primary"}}
    local stacked = #actions > 2 or maxWidth < 340
    buttons.Size = UDim2.new(1, 0, 0, stacked and (#actions * 38 + math.max(0, #actions - 1) * 8) or 38)
    buttons.BackgroundTransparency = 1
    buttons.Parent = card
    local buttonLayout = Instance.new("UIListLayout")
    buttonLayout.FillDirection = stacked and Enum.FillDirection.Vertical or Enum.FillDirection.Horizontal
    buttonLayout.HorizontalAlignment = Enum.HorizontalAlignment.Right
    buttonLayout.Padding = UDim.new(0, 8)
    buttonLayout.Parent = buttons
    local closed = false
    local function close()
        if closed then return end
        closed = true
        gui:Destroy()
    end
    if options.Modal == false then dim.MouseButton1Click:Connect(close) end
    for _, action in ipairs(actions) do
        local button = Instance.new("TextButton")
        button.Size = stacked and UDim2.new(1, 0, 0, 38) or UDim2.fromOffset(96, 38)
        button.Text = tostring(action.Text or "OK")
        button.Font = Enum.Font.GothamMedium
        button.TextSize = 14
        button.TextColor3 = Color3.new(1, 1, 1)
        button.BackgroundColor3 = action.Style == "Primary" and Color3.fromRGB(0, 122, 255) or Color3.fromRGB(72, 76, 89)
        button.BorderSizePixel = 0
        button.Parent = buttons
        round(button, 10)
        button.MouseButton1Click:Connect(function()
            close()
            if action.Callback then task.spawn(action.Callback) end
        end)
    end
    return {Gui = gui, Close = close}
end

function Staconf:AddTab(options)
    return self.Window:Tab(options)
end

function Staconf:SetVisible(visible)
    if self._destroyed or not self.App.__instance.Parent then return end
    self.App.__instance.Enabled = visible == true
    -- Cascade's camera blur does not follow ScreenGui.Enabled.
    self.Window.UIBlur = visible == true and self._blurWanted or false
end

function Staconf:SetTheme(mode, accent)
    if mode == "Dark" or mode == "Light" then
        self.Mode = mode
        self.App.Theme = self.Cascade.Themes[mode]
    end
    if accent and self.Cascade.Accents[accent] then
        self.App.Accent = self.Cascade.Accents[accent]
    end
    if self._chromeEnabled then self:_applyChrome() end
end

function Staconf:Destroy()
    if self._destroyed then return end
    self._destroyed = true
    if self._bootSound then self._bootSound:Destroy() end
    if self._boot and self._boot.Overlay.Parent then self._boot.Overlay:Destroy() end
    if self._noticeGui then self._noticeGui:Destroy() end
    for _, dialog in ipairs(self._dialogs) do if dialog.Parent then dialog:Destroy() end end
    if self.App.__instance.Parent then self.App.__instance:Destroy() end
    if self._onDestroy then pcall(self._onDestroy, self) end
end

function Staconf:_applyChrome()
    local body = raw(self.Window.Structures.Body)
    if not body then return end
    local bodyCorner = body:FindFirstChildOfClass("UICorner")
    if bodyCorner then bodyCorner.CornerRadius = UDim.new(0, 22) end
    local sidebar = raw(self.Window.Structures.Sidebar)
    local content = raw(self.Window.Structures.ContentBody)
    for _, panel in ipairs({sidebar, content}) do
        if panel and panel:IsA("GuiObject") then
            panel.BorderSizePixel = 0
            panel.BackgroundColor3 = self.Mode == "Light" and Color3.fromRGB(246, 247, 250)
                or Color3.fromRGB(20, 22, 30)
            panel.BackgroundTransparency = 0.12
        end
    end
end

function Staconf:Row(section, options)
    options = options or {}
    return section:Row({SearchIndex = options.Title or options.SearchIndex or ""})
end

local function titledControl(self, section, options, kind, properties)
    local row = self:Row(section, options)
    row:Left():TitleStack({Title = options.Title or kind, Subtitle = options.Subtitle})
    local accessory = row:Right()
    return accessory[kind](accessory, properties), row
end

function Staconf:Toggle(section, options)
    options = options or {}
    return titledControl(self, section, options, "Toggle", {Value = options.Value == true,
        ValueChanged = function(_, value) if options.OnChange then options.OnChange(value) end end})
end

function Staconf:Slider(section, options)
    options = options or {}
    return titledControl(self, section, options, "Slider", {Minimum = options.Minimum or 0,
        Maximum = options.Maximum or 100, Value = options.Value or options.Minimum or 0,
        ValueChanged = function(_, value) if options.OnChange then options.OnChange(value) end end})
end

function Staconf:Dropdown(section, options)
    options = options or {}
    return titledControl(self, section, options, "PopUpButton", {Options = options.Options or {},
        Value = options.Value or 1, ValueChanged = function(_, value)
            local selected = type(value) == "table" and (value.Value or value.Name or value.Label) or value
            local resolved = type(selected) == "number" and options.Options and options.Options[selected] or selected
            if options.OnChange then options.OnChange(resolved or selected) end
        end})
end

function Staconf:TextField(section, options)
    options = options or {}
    return titledControl(self, section, options, "TextField", {Value = options.Value or "",
        Placeholder = options.Placeholder or "", ValueChanged = function(_, value)
            if options.OnChange then options.OnChange(value) end
        end})
end

function Staconf:Keybind(section, options)
    options = options or {}
    return titledControl(self, section, options, "KeybindField", {Value = options.Value or Enum.KeyCode.None,
        ValueChanged = function(_, value) if options.OnChange then options.OnChange(value) end end})
end

function Staconf:Button(section, options)
    options = options or {}
    local row = self:Row(section, options)
    row:Left():TitleStack({Title = options.Title or "Button", Subtitle = options.Subtitle})
    return row:Right():Button({Label = options.Title or "Button", State = options.Style or "Secondary",
        Pushed = function() if options.OnClick then options.OnClick() end end}), row
end

function Staconf.new(options)
    options = options or {}
    local cascade = options.Cascade
    if not cascade then
        cascade = assert(loadstring(game:HttpGetAsync(options.CascadeUrl or CASCADE_URL)))()
    end
    local self = setmetatable({}, Staconf)
    self.Cascade = cascade
    self.Title = options.Title or "StacOnf"
    self.Name = options.Name or "StacOnf"
    self.Mode = options.Theme == "Light" and "Light" or "Dark"
    self.CacheRoot = options.CacheRoot or "Staconf"
    self.AssetBaseUrl = options.AssetBaseUrl or ASSET_URL
    self.BootImage = options.BootImage
    self.BootImageFile = options.BootImageFile
    self.BootSoundId = options.BootSoundId
    self.BootSoundVolume = options.BootSoundVolume or 1
    self.ProgressColor = options.ProgressColor or Color3.fromRGB(245, 245, 247)
    self._dialogs = {}
    self._onDestroy = options.OnDestroy
    local accent = cascade.Accents[options.Accent] and options.Accent or "Blue"
    self.App = cascade.New({WindowPill = options.WindowPill ~= false,
        Theme = cascade.Themes[self.Mode], Accent = cascade.Accents[accent]})
    self.App.__instance.Name = self.Name
    if UserInputService.TouchEnabled then
        pcall(function() self.App.__instance.ScreenInsets = Enum.ScreenInsets.CoreUISafeInsets end)
    end
    self.Window = self.App:Window({Title = self.Title, Subtitle = options.Subtitle or "",
        Size = windowSize(self.App.__instance, options.Size), Searching = options.Searching ~= false,
        Draggable = options.Draggable ~= false and not UserInputService.TouchEnabled,
        Resizable = options.Resizable ~= false and not UserInputService.TouchEnabled,
        CanExit = options.CanExit ~= false, CanMinimize = options.CanMinimize ~= false,
        CanZoom = options.CanZoom ~= false and not UserInputService.TouchEnabled,
        Dropshadow = options.Dropshadow ~= false, UIBlur = options.UIBlur ~= false})
    self._blurWanted = options.UIBlur ~= false
    self._chromeEnabled = options.Chrome ~= false
    if self._chromeEnabled then self:_applyChrome() end
    self.App.__instance.Destroying:Connect(function()
        if not self._destroyed then
            self._destroyed = true
            if self._bootSound then self._bootSound:Destroy(); self._bootSound = nil end
            if self._boot and self._boot.Overlay.Parent then self._boot.Overlay:Destroy() end
            if self._noticeGui then self._noticeGui:Destroy() end
            for _, dialog in ipairs(self._dialogs) do if dialog.Parent then dialog:Destroy() end end
            if self._onDestroy then pcall(self._onDestroy, self) end
        end
    end)
    if options.Boot ~= false then self:ShowBoot() end
    return self
end

return Staconf
