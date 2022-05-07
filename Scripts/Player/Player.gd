extends KinematicBody

var damage = 10

var speed = 7
const ACCEL_DEFAULT = 7
const ACCEL_AIR = 1
onready var accel = ACCEL_DEFAULT
var gravity = 9.8
var jump = 5

var cam_accel = 40
var mouse_sensitivity = 0.3
var snap

var direction = Vector3()
var velocity = Vector3()
var gravity_vec = Vector3()
var movement = Vector3()


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
			
func _process(delta):
	#camera physics interpolation to reduce physics jitter on high refresh-rate monitors
	if Engine.get_frames_per_second() > Engine.iterations_per_second:
		camera.set_as_toplevel(true)
		camera.global_transform.origin = camera.global_transform.origin.linear_interpolate(head.global_transform.origin, cam_accel * delta)
		camera.rotation.y = rotation.y
		camera.rotation.x = head.rotation.x
	else:
		camera.set_as_toplevel(false)
		camera.global_transform = head.global_transform

func _physics_process(delta):
		
	if is_network_master():
		fire()
		if Input.is_action_just_pressed("ui_cancel"):
			Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
			
		direction = Vector3.ZERO
		var h_rot = global_transform.basis.get_euler().y
		var f_input = Input.get_action_strength("move_backward") - Input.get_action_strength("move_forward")
		var h_input = Input.get_action_strength("move_right") - Input.get_action_strength("move_left")
		direction = Vector3(h_input, 0, f_input).rotated(Vector3.UP, h_rot).normalized()
	
		#jumping and gravity
		if is_on_floor():
			snap = -get_floor_normal()
			accel = ACCEL_DEFAULT
			gravity_vec = Vector3.ZERO
		else:
			snap = Vector3.DOWN
			accel = ACCEL_AIR
			gravity_vec += Vector3.DOWN * gravity * delta
		
		if Input.is_action_just_pressed("jump") and is_on_floor():
			snap = Vector3.ZERO
			gravity_vec = Vector3.UP * jump
	
		#make it move
		velocity = velocity.linear_interpolate(direction * speed, accel * delta)
		movement = velocity + gravity_vec
		move_and_slide_with_snap(movement, snap, Vector3.UP)
	else:
		global_transform.origin = puppet_position
		
		velocity.x = puppet_velocity.x
		velocity.z = puppet_velocity.z
		
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
		rpc_unreliable("update_state", global_transform.origin, velocity, Vector2(head.rotation.x, rotation.y))
	else:
		network_tick_rate.stop()
