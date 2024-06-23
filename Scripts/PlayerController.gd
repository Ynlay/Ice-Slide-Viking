extends CharacterBody2D

@export_category("Movement")
@export var Speed = 400
@export var Acceleration = 300
@export var Deceleration = 300

@onready var anim = $Animations
var last_direction = Vector2.ZERO

func _physics_process(delta):
	var input_direction = Input.get_vector("left", "right", "up", "down")
	if input_direction != Vector2.ZERO: 
		last_direction = input_direction
	velocity = last_direction * Speed 
	print(velocity.x)
	#if input_direction != Vector2.ZERO: 
		#velocity = velocity.move_toward(input_direction * Speed, Acceleration*delta)
	if last_direction == Vector2.LEFT or (velocity.x < -50): 
		anim.flip_h = true
		print("left")
	elif last_direction == Vector2.RIGHT or (velocity.x > 50): 
		anim.flip_h = false
		print("right")
	
		
	if velocity != Vector2.ZERO: 
		anim.play("Slide")
	else: 
		anim.play("Idle")
		
	if Input.is_action_just_pressed("escape"):
		get_tree().quit()
	
	move_and_slide()
