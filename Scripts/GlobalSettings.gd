extends Node

var mouse_sensitivity = 0.1
var music_enabled : bool
var music_volume : float

#networking
signal instance_player(id)
signal toggle_network_setup(toggle)

#quits game when esc is pressed
func _input(event):
	if event is InputEventKey:
		if event.scancode == KEY_ESCAPE:
			get_tree().quit()
