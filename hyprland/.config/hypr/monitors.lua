local laptop = "eDP-1"
local external = "desc:LG"

hl.monitor({
	output = external,
	mode = "preferred",
	position = "0x0",
	scale = 1.875,
})

hl.monitor({
	output = laptop,
	mode = "1920x1200@60",
	position = "auto-right",
	scale = 1.25,
})

return { laptop = laptop, external = external }
