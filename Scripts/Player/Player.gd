extends KinematicBody

var damage = 10

var speed = 10
var h_acceleration = 6
var air_acceleration = 1
var normal_acceleration = 6
var gravity = 20
var jump = 10
var full_contact = false

var mouse_sensitivity = 0.1

var direction = Vector3()
var h_velocity = Vector3()
var movement = Vector3()
var gravity_vec = Vector3()

var puppet_position = Vector3()
var puppet_velocity = Vector3()
var puppet_rotation = Vector2()

onready var head = $Head
onready var ground_check = $GroundCheck
onready var anim_player = $AnimationPlayer
onready var camera = $Head/Camera
onready var raycast = $Head/Camera/RayCast
onready var network_tick_rate = $NetworkTickRate
onready var movementTween = $MovementTween

func _ready():
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED) 
	
	#networking
	camera.current = is_network_master()
	
	
func _input(event):
	if is_network_master(): #Checks for local client
		if event is InputEventMouseMotion:
			rotate_y(deg2rad(-event.relative.x * mouse_sensitivity)) #Tar det musen har rört på sig uppåt och multiplicerar med sensitivityn
			head.rotate_x(deg2rad(-event.relative.y * mouse_sensitivity))
			head.rotation.x = clamp(head.rotation.x, deg2rad(-89), deg2rad (89)) #Gör så att man inte kan kolla ett helt varv runt
func fire():
	#Local client is already checked in physics process
		if Input.is_action_pressed("fire"):
			if not anim_player.is_playing():
				if raycast.is_colliding(): #Kollar om personen kollar på något
					var target = raycast.get_collider()
					if target.is_in_group("Enemy"): #Kollar om man kollar på en fiende
						target.health -= damage
			anim_player.play("AssaultFire")
		else:
			anim_player.stop()
		
func _physics_process(delta):
	#Gravirt should be applied to all things, no matter if you controll it or not
	if not is_on_floor():
		gravity_vec += Vector3.DOWN * gravity * delta
		h_acceleration = air_acceleration

	if is_network_master():
		fire()
		if Input.is_action_just_pressed("ui_cancel"): #Ifall man klickar esc så syns musen igen
			Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
		direction = Vector3()
		if ground_check.is_colliding():
			full_contact = true
		else:
			full_contact = false
		if is_on_floor() and full_contact:
			gravity_vec = -get_floor_normal() * gravity
			h_acceleration = normal_acceleration
		else:
			gravity_vec = -get_floor_normal()
			h_acceleration = normal_acceleration
			
		if Input.is_action_just_pressed("jump") and (is_on_floor() or ground_check.is_colliding()):
			gravity_vec = Vector3.UP * jump
		if Input.is_action_pressed("move_forward"):
			direction -= transform.basis.z
		elif Input.is_action_pressed("move_backward"):
			direction += transform.basis.z
		if Input.is_action_pressed("move_left"):
			direction -= transform.basis.x
		elif Input.is_action_pressed("move_right"):
			direction += transform.basis.x
		
		direction = direction.normalized()
		h_velocity = h_velocity.linear_interpolate(direction * speed, h_acceleration * delta)
		movement.z = h_velocity.z + gravity_vec.z
		movement.x = h_velocity.x + gravity_vec.x
		movement.y = gravity_vec.y
	else:
		global_transform.origin = puppet_position
		
		h_velocity.x = puppet_velocity.x
		h_velocity.z = puppet_velocity.z
		
		rotation.y = puppet_rotation.y
		head.rotation.x = puppet_rotation.x
		
	if !movementTween.is_active():
		move_and_slide(movement,  Vector3.UP)

#Sync movement for other players, puppets
puppet func update_state(p_position, p_velocity, p_rotation):
	puppet_position = p_position
	puppet_velocity = p_velocity
	puppet_rotation = p_rotation
	
	##????? move from old position to new position at speed 0f 0.1 seconds ????
	#Movement tween smoothes out movement hiding network lag (it exists but you wont notice, so does it really exist?)
	movementTween.interpolate_property(self, "global_transform", global_transform, Transform(global_transform.basis, p_position), 0.1)
	movementTween.start()

func _on_NetworkTickRate_timeout():
	if is_network_master():
		#sends packet, packet loss is fine
		rpc_unreliable("update_state", global_transform.origin, h_velocity, Vector2(head.rotation.x, rotation.y))
	else:
		network_tick_rate.stop()
