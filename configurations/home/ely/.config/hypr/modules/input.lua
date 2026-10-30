-------------
-- INPUT
-------------

hl.config({
	input = {
		kb_layout = "us",
		kb_variant = "altgr-intl",
		follow_mouse = 1,
		sensitivity = 0,
		accel_profile = "flat",
		touchpad = {
			natural_scroll = true,
		},
	},
})

-- Teclado físico do notebook (ABNT2)
hl.device({
	name = "at-translated-set-2-keyboard",
	kb_layout = "br",
	kb_variant = "abnt2",
})

-- Touchpad
hl.device({
	name = "crq1080:00-0488:1014-touchpad",
	sensitivity = 0,
	accel_profile = "adaptive",
	disable_while_typing = true,
})

-- Mouse Logitech
hl.device({
	name = "logitech-wireless-receiver-mouse",
	sensitivity = 0,
	accel_profile = "flat",
	natural_scroll = false,
})

hl.device({
	name = "sony-interactive-entertainment-wireless-controller-touchpad",
	enabled = false,
})
