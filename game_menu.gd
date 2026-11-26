extends CanvasLayer
var game: Node
var panel: ColorRect
var menu: VBoxContainer
var title: Label
var mode := "title"
var music: AudioStreamPlayer
var muted := false
const SAVE := "user://turkey_time.save"

func tone(notes: Array, seconds: float, volume: float, looped := false) -> AudioStreamWAV:
	var rate := 22050
	var count := int(seconds*rate)
	var bytes := PackedByteArray()
	bytes.resize(count*2)
	for i in range(count):
		var t := float(i)/rate
		var step := seconds/float(notes.size())
		var index := mini(int(t/step),notes.size()-1)
		var hz := float(notes[index])
		var local := fmod(t,step)
		var env := minf(1.0,local*35.0)*minf(1.0,(step-local)*12.0)
		var wave := (sin(TAU*hz*t)+0.24*sin(TAU*hz*2*t))*env if hz>0 else 0.0
		bytes.encode_s16(i*2,int(clampf(wave*volume,-1,1)*32767))
	var stream := AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = rate
	stream.data = bytes
	if looped:
		stream.loop_mode = AudioStreamWAV.LOOP_FORWARD
		stream.loop_end = count
	return stream

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	layer = 10
	music = AudioStreamPlayer.new()
	add_child(music)
	music.stream = tone([220,329.63,440,392,261.63,329.63,392,329.63,196,293.66,392,440,220,329.63,261.63,0],12.8,0.10,true)
	music.play()
	panel = ColorRect.new()
	add_child(panel)
	panel.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	panel.color = Color("#191b22ed")
	var center := CenterContainer.new()
	panel.add_child(center)
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	menu = VBoxContainer.new()
	center.add_child(menu)
	menu.custom_minimum_size.x = 320
	menu.add_theme_constant_override("separation",14)
	show_menu("title")

func add_button(words: String, action: Callable, enabled := true) -> void:
	var b := Button.new()
	menu.add_child(b)
	b.text = words
	b.custom_minimum_size.y = 46
	b.disabled = not enabled
	b.pressed.connect(action)

func show_menu(next: String) -> void:
	mode = next
	for child in menu.get_children():
		menu.remove_child(child)
		child.queue_free()
	panel.show()
	get_tree().paused = true
	title = Label.new()
	menu.add_child(title)
	title.text = "TURKEY TIME" if mode=="title" else "ADVENTURE PAUSED"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size",38)
	title.modulate = Color("#ffcf78")
	var subtitle := Label.new()
	menu.add_child(subtitle)
	subtitle.text = "Save Princess Tina. Stop the Grand Feast."
	subtitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	if mode=="title":
		add_button("New Adventure",new_game)
		add_button("Continue Adventure",continue_game,FileAccess.file_exists(SAVE))
	else:
		add_button("Resume Adventure",resume)
		add_button("Save and Return to Title",return_title)
	add_button("Toggle Music",toggle_music)
	add_button("Quit Game",quit_game)
	for child in menu.get_children():
		if child is Button and not child.disabled:
			child.grab_focus()
			break

func new_game() -> void:
	if FileAccess.file_exists(SAVE):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(SAVE))
	get_tree().paused = false
	get_tree().set_meta("skip_title",true)
	get_tree().reload_current_scene()

func continue_game() -> void:
	game.call("load_progress")
	resume()

func resume() -> void:
	panel.hide()
	mode = "playing"
	get_tree().paused = false

func return_title() -> void:
	game.call("save_progress")
	show_menu("title")

func toggle_music() -> void:
	muted = not muted
	music.volume_db = -80.0 if muted else 0.0

func quit_game() -> void:
	if mode=="pause":
		game.call("save_progress")
	get_tree().quit()

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel") or (event is InputEventJoypadButton and event.pressed and event.button_index==JOY_BUTTON_START):
		if mode=="playing":
			show_menu("pause")
		elif mode=="pause":
			resume()
		get_viewport().set_input_as_handled()

func sound(kind: String) -> void:
	var notes: Array = [440,220]
	match kind:
		"Peck": notes = [820,510]
		"Punch": notes = [150,75]
		"Flap": notes = [360,240,120]
		"coin": notes = [660,880,1100]
		"hurt": notes = [180,95]
		"checkpoint": notes = [330,440,660,880]
	var p := AudioStreamPlayer.new()
	add_child(p)
	p.stream = tone(notes,0.18,0.22)
	p.finished.connect(p.queue_free)
	p.play()
