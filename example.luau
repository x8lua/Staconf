local Staconf = loadstring(game:HttpGetAsync(
    "https://raw.githubusercontent.com/x8lua/Staconf/main/init.luau"
))()

local ui = Staconf.new({Title = "Staconf Example", Subtitle = "A reusable Cascade window"})
ui:RevealBootProgress()
ui:SetBootProgress(0.35)

local tab = ui:AddTab({Title = "General", Selected = true})
local controls = tab:PageSection({Title = "Controls"}):Form()
ui:Toggle(controls, {
    Title = "Notifications",
    Value = true,
    OnChange = function(enabled)
        if enabled then ui:Notify({Title = "Notifications", Subtitle = "Enabled"}) end
    end,
})
ui:Slider(controls, {Title = "Volume", Minimum = 0, Maximum = 100, Value = 50})
ui:Button(controls, {
    Title = "Open dialog",
    OnClick = function()
        ui:Dialog({
            Title = "Staconf dialog",
            Description = "This UI is ready to use in another script.",
            Buttons = {{Text = "OK", Style = "Primary"}},
        })
    end,
})

ui:SetBootProgress(1)
ui:FinishBoot()
