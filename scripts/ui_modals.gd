extends RefCounted
class_name UIModals

static func make_panel_style(bg: Color = Color(0.08, 0.11, 0.16, 0.96), border: Color = Color(0.24, 0.32, 0.45, 0.9)) -> StyleBoxFlat:
	var sb := StyleBoxFlat.new()
	sb.bg_color = bg
	sb.border_color = border
	sb.set_border_width_all(2)
	sb.set_corner_radius_all(10)
	sb.set_content_margin_all(14)
	return sb

static func build_profile_modal(parent: Control) -> Dictionary:
	var bg := ColorRect.new()
	bg.color = Color(0, 0, 0, 0.65)
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	bg.visible = false
	parent.add_child(bg)

	var panel := PanelContainer.new()
	panel.add_theme_stylebox_override("panel", make_panel_style())
	panel.custom_minimum_size = Vector2(560, 440)
	panel.set_anchors_preset(Control.PRESET_CENTER)
	panel.offset_left = -280
	panel.offset_right = 280
	panel.offset_top = -220
	panel.offset_bottom = 220
	bg.add_child(panel)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 10)
	panel.add_child(vbox)

	var hdr := HBoxContainer.new()
	vbox.add_child(hdr)
	var title := Label.new()
	title.text = "👤 Oyuncu Profili & Liderlik Tablosu"
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	title.add_theme_font_size_override("font_size", 18)
	hdr.add_child(title)
	var close_btn := Button.new()
	close_btn.text = "✕ Kapat"
	close_btn.pressed.connect(func(): bg.visible = false)
	hdr.add_child(close_btn)

	var search_row := HBoxContainer.new()
	vbox.add_child(search_row)
	var search_in := LineEdit.new()
	search_in.placeholder_text = "Oyuncu adı ara..."
	search_in.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	search_row.add_child(search_in)
	var search_btn := Button.new()
	search_btn.text = "🔍 Ara"
	search_row.add_child(search_btn)

	var stats_lbl := RichTextLabel.new()
	stats_lbl.bbcode_enabled = true
	stats_lbl.fit_content = true
	stats_lbl.custom_minimum_size = Vector2(0, 95)
	vbox.add_child(stats_lbl)

	var lb_title := Label.new()
	lb_title.text = "🏆 En İyi 12 Oyuncu (Gol & Süre)"
	vbox.add_child(lb_title)

	var lb_list := RichTextLabel.new()
	lb_list.bbcode_enabled = true
	lb_list.size_flags_vertical = Control.SIZE_EXPAND_FILL
	vbox.add_child(lb_list)

	return {
		"root": bg,
		"search_in": search_in,
		"search_btn": search_btn,
		"stats_lbl": stats_lbl,
		"lb_list": lb_list
	}

static func build_debug_modal(parent: Control) -> Dictionary:
	var bg := ColorRect.new()
	bg.color = Color(0, 0, 0, 0.65)
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	bg.visible = false
	parent.add_child(bg)

	var panel := PanelContainer.new()
	panel.add_theme_stylebox_override("panel", make_panel_style())
	panel.custom_minimum_size = Vector2(640, 400)
	panel.set_anchors_preset(Control.PRESET_CENTER)
	panel.offset_left = -320
	panel.offset_right = 320
	panel.offset_top = -200
	panel.offset_bottom = 200
	bg.add_child(panel)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 8)
	panel.add_child(vbox)

	var hdr := HBoxContainer.new()
	vbox.add_child(hdr)
	var title := Label.new()
	title.text = "🛠 Debug & Ağ Günlüğü"
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hdr.add_child(title)
	var clr_btn := Button.new()
	clr_btn.text = "Temizle"
	hdr.add_child(clr_btn)
	var close_btn := Button.new()
	close_btn.text = "✕ Kapat"
	close_btn.pressed.connect(func(): bg.visible = false)
	hdr.add_child(close_btn)

	var log_txt := TextEdit.new()
	log_txt.editable = false
	log_txt.size_flags_vertical = Control.SIZE_EXPAND_FILL
	vbox.add_child(log_txt)

	clr_btn.pressed.connect(func():
		GameData.debug_logs.clear()
		log_txt.text = ""
	)

	return {"root": bg, "log_txt": log_txt}

static func build_powerups_modal(parent: Control) -> Dictionary:
	var bg := ColorRect.new()
	bg.color = Color(0, 0, 0, 0.65)
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	bg.visible = false
	parent.add_child(bg)

	var panel := PanelContainer.new()
	panel.add_theme_stylebox_override("panel", make_panel_style())
	panel.custom_minimum_size = Vector2(360, 280)
	panel.set_anchors_preset(Control.PRESET_CENTER)
	panel.offset_left = -180
	panel.offset_right = 180
	panel.offset_top = -140
	panel.offset_bottom = 140
	bg.add_child(panel)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 8)
	panel.add_child(vbox)

	var title := Label.new()
	title.text = "⚡ Süper Güç Seçenekleri"
	vbox.add_child(title)

	var checks := {}
	var labels := {
		"hawk": "🦅 Şahin Vuruşu (1.95x Şut)",
		"fire": "🔥 Alevli Şut (1.55x Şut)",
		"speed": "⚡ Turbo Hız (1.55x Hız)",
		"magnet": "🧲 Mıknatıs (Top Çekimi)",
		"giant": "🛡️ Dev Oyuncu (Büyük Gövde)"
	}
	for k in GameData.POWERUP_TYPES:
		var cb := CheckBox.new()
		cb.text = labels.get(k, k)
		cb.button_pressed = bool(GameData.powerups_enabled.get(k, true))
		cb.toggled.connect(func(v: bool): GameData.powerups_enabled[k] = v)
		vbox.add_child(cb)
		checks[k] = cb

	var close_btn := Button.new()
	close_btn.text = "Tamam"
	close_btn.pressed.connect(func(): bg.visible = false)
	vbox.add_child(close_btn)

	return {"root": bg, "checks": checks}
