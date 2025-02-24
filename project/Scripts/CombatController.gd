extends Node

@export_category("Attack")
@onready var lastAttack = "none"
@onready var attacking = false
@onready var attackingBody
@onready var attackDue = 0 
@export var DamageMultiplier = 1 

@export_category("Axe Strike")
@export var AxeStrikeDamage = 30
@export var AxeStrikeDuration = 1.0
@export var AxeStrikeCD = 2.0 
@onready var axeCooling = false 
@onready var axeStrikeArea = $AxeStrikeArea
@onready var body_in_axe_strike_area = false

@export_category("Whirlwind")
@export var WhirlwindDamagePerTick = 5.0
@export var WhirlwindDuration = 2.0
@export var WhirlwindCD = 2.0
@onready var whirlCooling = false 
@onready var whirlwindArea = $WhirlwindArea
@onready var body_in_whirlwind_area = false

@export_category("Blocking")
@export var BlockDuration = 2.0
@export var BlockingCooldown = 2.0
@onready var blocking = false
@onready var blockCooling = false

@export_category("Health")
@onready var HealthBar = $"../Control/Healthbar"
@export var DamageInvincibilityTimerAxeStrike = 1.0
@export var DamageInvincibilityTimerWhirlwind = 0.5
@onready var recentlyDamaged = false 
@onready var invincible = false

@export_category("Controls")
var AltKeys = false
var last_direction = Vector2.ZERO

@export_category("Audio")
@onready var AudioController = $"../AudioStreamPlayer2D"
@export_category("Axe Strike")
@export var AxeStrikeAudio: Array[AudioStream]
@export_category("Whirlwind")
@export var WhirlwindAudio: Array[AudioStream]

@onready var anim = $"../Animations"
@onready var playerController = $".."
var rng 

func _ready() -> void:
	rng = RandomNumberGenerator.new()
	
func _physics_process(delta: float) -> void:
	if playerController.is_local:
		HandleWhirlwind()
		HandleAxeStrike()
		HandleBlocking()
		HandleAttack()
	
	if playerController.flipped_horizontal: 
		axeStrikeArea.position = Vector2(-18,0)
	elif not playerController.flipped_horizontal: 
		axeStrikeArea.position = Vector2(25, 0)
	
func HandleWhirlwind(): 
	if whirlCooling: return
	if attacking: return
	if blocking: return
	var inputActionPressed
	if AltKeys: 
		inputActionPressed = Input.is_action_just_pressed("alt_key_two")
	else: 
		inputActionPressed = Input.is_action_just_pressed("key_two")
	if inputActionPressed: 
		lastAttack = "Whirlwind"
		AudioController.stream = WhirlwindAudio[rng.randf_range(0, WhirlwindAudio.size())]
		AudioController.play()
		playerController.SetIsAttacking(true)
		playerController.play_animation("Whirlwind")
		attackDue = WhirlwindDamagePerTick * DamageMultiplier
		attacking = true
		await get_tree().create_timer(WhirlwindDuration).timeout
		playerController.SetIsAttacking(false)
		attacking = false
		whirlCooling = true
		attackDue = 0.0
		await get_tree().create_timer(WhirlwindCD).timeout
		whirlCooling = false
		
func HandleAxeStrike(): 
	if axeCooling: return
	if attacking: return
	if blocking: return
	var inputActionPressed
	if AltKeys: 
		inputActionPressed = Input.is_action_just_pressed("alt_key_one")
	else: 
		inputActionPressed = Input.is_action_just_pressed("key_one")
	if inputActionPressed: 
		print("Handling axe strike")
		lastAttack = "AxeStrike"
		AudioController.stream = AxeStrikeAudio[rng.randf_range(0, AxeStrikeAudio.size())]
		AudioController.play()
		playerController.SetIsAttacking(true)
		playerController.play_animation("AxeStrike")
		attackDue = AxeStrikeDamage * DamageMultiplier
		attacking = true
		await get_tree().create_timer(AxeStrikeDuration).timeout
		attacking = false
		playerController.SetIsAttacking(false)
		axeCooling = true
		attackDue = 0.0
		await get_tree().create_timer(AxeStrikeCD).timeout
		axeCooling = false

func HandleBlocking():
	if blockCooling: return 
	if attacking: return 
	var inputActionPressed 
	if AltKeys: 
		inputActionPressed = Input.is_action_just_pressed("alt_key_three")
	else: 
		inputActionPressed = Input.is_action_just_pressed("key_three")
	if inputActionPressed: 
		print("Handling Block")
		playerController.SetIsAttacking(false)
		# Play Block Animation 
		attacking = false 
		blocking = true
		await get_tree().create_timer(BlockDuration).timeout
		blocking = false 
		blockCooling = true
		await get_tree().create_timer(BlockingCooldown).timeout
		blockCooling = false
		
func HandleAttack(): 
	if not attacking: return 
	if attackingBody == null: return
	if attackingBody.is_in_group("Player"): 
		attackingBody.combatController.HandleDamage(attackDue, lastAttack, playerController)
		
func HandleDamage(damageReceived, strikeType, attacker): 
	if damageReceived < 0 or recentlyDamaged or strikeType == "none": return 
	# Parry/Block Mechanic
	#if attacker.attacking and playerController.attacking: damageReceived = 0
	# Check blocking 
	if attacker.isAttacking and blocking: 
			damageReceived = 0
			attacker.Pushback(playerController.global_position, 100)
	# Check Shield Rune 
	if invincible: damageReceived = 0
	match(strikeType):
		"Whirlwind": DamageHealth(damageReceived, DamageInvincibilityTimerWhirlwind)
		"AxeStrike": DamageHealth(damageReceived, DamageInvincibilityTimerAxeStrike)
	
func DamageHealth(value, invincibilityTimer = 1):
	if (recentlyDamaged): return
	DamageNumbers.DisplayNumber(value, playerController.global_position, false)
	HealthBar.value = HealthBar.value - value 
	playerController.send_health_update(playerController.name, HealthBar.value)
	recentlyDamaged = true 
	await get_tree().create_timer(float(invincibilityTimer)).timeout
	recentlyDamaged = false
	
func _on_axe_strike_area_body_entered(body: Node2D) -> void:
	if body.is_in_group("Player") and not body == playerController: 
		body_in_axe_strike_area = true
		attackingBody = body

func _on_axe_strike_area_body_exited(body: Node2D) -> void:
	if body.is_in_group("Player") and not body == playerController: 
		body_in_axe_strike_area = false
		attackingBody = null

func _on_whirlwind_area_body_entered(body: Node2D) -> void:
	if body.is_in_group("Player") and not body == playerController: 
		body_in_whirlwind_area = true
		attackingBody = body

func _on_whirlwind_area_body_exited(body: Node2D) -> void:
	if body.is_in_group("Player") and not body == playerController: 
		body_in_whirlwind_area = false 
		attackingBody = null
