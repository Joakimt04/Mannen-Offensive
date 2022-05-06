extends Control

func _ready():
	GlobalSettings.connect("toggle_network_setup", self, "_toggle_network_setup")

func _on_IpAdress_text_changed(new_text):
	Network.ip_adress = new_text


func _on_Host_pressed():
	Network.create_server()
	hide()
	
	#creates player instance for host, do not use when creating dedicated server in future
	GlobalSettings.emit_signal("instance_player", get_tree().get_network_unique_id())


func _on_Join_pressed():
	Network.Join_server()
	hide()
	
	#creates player instance for joining player
	GlobalSettings.emit_signal("instance_player", get_tree().get_network_unique_id())

func _toggle_network_setup(visible_toggle):
	visible = visible_toggle
	
