LiquidGlassHandler 1.0 was supplied by the project owner for notification integration.

Original code and mesh assets: Copyright (c) 2026 @7eoeb, @UNIVERSECORNUCOPIA. All rights reserved. The supplied model retains its original notice. This integration does not relicense those assets.

Reference: https://devforum.roblox.com/t/4416219

StacOnf loads only the model's Overlay geometry; the embedded ModuleScripts are not executed. The notification adapter handles ownership, camera placement, theme tint, scaling, and teardown separately. Rendering depends on asset access, executor local-model loading support, and Roblox graphics quality. If model loading fails, notifications use the themed surface fallback.
