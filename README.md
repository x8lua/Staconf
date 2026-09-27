# Staconf

Staconf is a reusable Roblox Luau UI shell built on [Cascade UI](https://github.com/cascadeui/Cascade). It provides a responsive window, boot overlay, notifications, dialogs, and common form controls. Your script owns its tabs, state, and callbacks.

## Load

```luau
local Staconf = loadstring(game:HttpGetAsync(
    "https://raw.githubusercontent.com/x8lua/Staconf/main/init.luau"
))()

local ui = Staconf.new({Title = "My App", Subtitle = "Example dashboard"})
ui:RevealBootProgress()
ui:SetBootProgress(0.4)

local tab = ui:AddTab({Title = "General", Selected = true})
local section = tab:PageSection({Title = "Controls"}):Form()
ui:Toggle(section, {
    Title = "Enabled",
    Value = false,
    OnChange = function(value) print("Enabled:", value) end,
})

ui:SetBootProgress(1)
ui:FinishBoot()
```

See [example.luau](example.luau) for a complete example.

## API

- `Staconf.new(options)` creates a Cascade window. Options include `Title`, `Subtitle`, `Name`, `Theme` (`Dark` or `Light`), `Accent`, `Size`, `Boot`, `BootImage`, `BootSoundId`, `CacheRoot`, `AssetBaseUrl`, `Cascade`, and `CascadeUrl`. Standard Cascade window options such as `CanExit`, `CanMinimize`, `Resizable`, and `UIBlur` are available.
- `ui.App`, `ui.Window`, and `ui.Cascade` expose Cascade objects for advanced use.
- `ui:AddTab({Title, Icon, Selected})` returns a Cascade tab with Staconf sidebar styling. Pass a Roblox image asset for `Icon`; tabs without icons use a full-width text label. Use `PageSection` and other Cascade methods to build content.
- `ui:ShowBoot()`, `ui:RevealBootProgress()`, `ui:SetBootProgress(fraction)`, and `ui:FinishBoot()` control the optional startup overlay. Progress is a number from `0` to `1`. Set `BootImage` or `BootImageFile` and `BootSoundId` to brand the startup screen.
- `ui:Notify({Title, Subtitle, Duration})` shows a notification.
- `ui:Dialog({Title, Description, Modal, Buttons})` shows a dialog. Each button accepts `Text`, `Style`, and `Callback`; the returned object has `Close()`.
- `ui:InstallChrome({ProfileTitle, ProfileSubtitle, OnProfile, Tooltips})` applies the Cascade-derived window shell, moves search into the sidebar, shows a profile panel, and styles late-created controls. It runs automatically unless `Chrome = false`. `ui:LoadFontFamily()` and `ui:ApplyFont()` load the bundled font family when executor asset APIs are available.
- `ui:Tooltip(instance, text)` and `ui:AttachTooltips(entries)` add delayed hover cards that are cleaned up with the UI instance.
- `ui:CreateSubTabs(parent, {Items, Selected, OnSelected})` creates a responsive segmented sub-tab strip. `ui:CreateGlass(instance, options)` applies the portable rounded glass fallback, and `ui:AddTabIntroduction(tab, options)` adds a themed tab header card.
- `ui:CreateSidebarSections(tab, {{Label, Target}, ...})` adds nested sidebar section links and scrolls the active Cascade page to the matching section title. Chrome also styles late-created controls and preserves vertical scrolling while Shift is held.
- `ui:BuildUpdateTab({Check, Apply, Version})` renders a neutral `Client Update / Unavailable` page while retaining those callbacks in `ui._updateMechanic` for the host application.
- `ui:Toggle`, `ui:Slider`, `ui:Dropdown`, `ui:TextField`, `ui:Keybind`, and `ui:Button` add controls to a Cascade Form. Each accepts a section and options table, returning the control and row. Use `OnChange` for value controls and `OnClick` for buttons.
- `ui:SetVisible(boolean)` hides or shows the window immediately, including blur. `ui:SetTheme(mode, accent)` updates Cascade colors. `ui:Destroy()` releases UI owned by the instance.
- `ui:Asset(fileName)` loads a repository asset through the executor's local asset APIs when available. Set `AssetBaseUrl` and `CacheRoot` to use your own assets.

## Dependencies and assets

The loader fetches the latest Cascade release unless you pass a `Cascade` object or `CascadeUrl`. HTTP and `loadstring` are required when loading remotely. Local asset caching requires `getcustomasset`, `writefile`, and optionally `isfile` and `makefolder`; UI controls still work when these APIs are absent. Roblox Studio can use a supplied Cascade object and Roblox asset IDs.

`assets/fonts/`, the shared glass model, and `assets/info.png` remain in this repository. Other images under `assets/` are retained temporarily because deployed LarpKuran clients still request those URLs. They are compatibility assets, not part of Staconf's public UI API. `assets/LIQUID_GLASS_NOTICE.md` records the glass model's ownership and use.

Staconf does not include account logic, game automation, configuration storage, or a global singleton. The profile panel is visual only unless `OnProfile` is supplied. LarpKuran-specific rendering and keybind conflict policy remain in the host application. Call `ui:Destroy()` when your script unloads.
