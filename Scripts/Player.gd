extends KinematicBody

var speed = 7
var acceleration = 20
var gravity = 9.8
var jump = 5

var mouse_sensitivity = 0.1

var direction = Vector3()
var velocity = Vector3()
var fall = Vector3()

onready var head = $Head

func _ready():
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED) 
	
	
func _input(event):
	if event is InputEventMouseMotion:
		rotate_y(deg2rad(-event.relative.x * mouse_sensitivity)) #Tar det musen har rört på sig uppåt och multiplicerar med sensitivityn
		head.rotate_x(deg2rad(-event.relative.y * mouse_sensitivity))
		head.rotation.x = clamp(head.rotation.x, deg2rad(-90), deg2rad (90)) #Gör så att man inte kan kolla ett helt varv runt
		
func _process(delta): #Denna uppdateras varje frame
	
	direction = Vector3()
	
	if not is_on_floor():
		fall.y -= gravity * delta
		
	if Input.is_action_just_pressed("jump"):
		fall.y = jump
	
	if Input.is_action_just_pressed("ui_cancel"): #Ifall man klickar esc så syns musen igen
		Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
		
	#Movement
	if Input.is_action_pressed("move_forward"):
		
		direction -= transform.basis.z
		
	elif Input.is_action_pressed("move_backward"):
		
		direction += transform.basis.z
		
	if Input.is_action_pressed("move_left"):
		
		direction -= transform.basis.x
	
	elif Input.is_action_pressed("move_right"):
		
		direction += transform.basis.x
		
	direction = direction.normalized()
	velocity = velocity.linear_interpolate(direction * speed, acceleration * delta) #Smooth acceleration
	velocity = move_and_slide(velocity, Vector3.UP)
	move_and_slide(fall,  Vector3.UP) #Gravity mannen