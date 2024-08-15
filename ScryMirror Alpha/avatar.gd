extends CharacterBody2D

signal took_damage(amount)
signal gained_points(amount)

var speed = 400
var click_position = Vector2()
var target_position = Vector2()
var DidWeJustGetSmacked = false

func _ready():
	$GrazeRingAnimatedSprite.animation = "default"
	hide()
	click_position = position

func _physics_process(delta):
	if Input.is_action_just_pressed("left_click"):
		click_position = get_global_mouse_position()
	if position.distance_to(click_position) > 3:
		target_position = (click_position - position).normalized()
		velocity = target_position * speed
		move_and_slide()
		

func start(pos):
	position = pos
	target_position = pos
	click_position = pos 
	show()
	$Area2D.set_deferred("monitoring",true)


func _on_area_2d_body_entered(body: Node2D) -> void:
	print('fireball ouchie me bones')
	$OuchNoise.play()
	DidWeJustGetSmacked = true
	took_damage.emit(1)
	$Area2D.set_deferred("monitorable", false)
	$Area2D.set_deferred("monitoring", false)
	$InvulnTimer.start()
	$FlashingTimer.start()


func _on_invuln_timer_timeout() -> void:
	DidWeJustGetSmacked = false
	$FlashingTimer.stop()
	$AnimatedSprite2D.show() 
	$Area2D.set_deferred("monitorable", true)
	$Area2D.set_deferred("monitoring", true)


func _on_flashing_timer_timeout() -> void:
	if $AnimatedSprite2D.visible == true:
		$AnimatedSprite2D.hide()
	else:
		$AnimatedSprite2D.show() # Replace with function body.


func _on_graze_timer_timeout() -> void:
	$GrazeRingAnimatedSprite.animation = "default"
	$GrazeArea2D.set_deferred("monitorable",true)
	$GrazeArea2D.set_deferred("monitoring",true)


func _on_graze_area_2d_body_entered(body: Node2D) -> void:
	if DidWeJustGetSmacked == false:
		$GrazeNoise.play()
		$GrazeRingAnimatedSprite.animation = "NiceLilFlash"
		$GrazeRingAnimatedSprite.play()
		print("yay a graze point")
		gained_points.emit(1)
		$GrazeTimer.start()
		$GrazeArea2D.set_deferred("monitorable",false)
		$GrazeArea2D.set_deferred("monitoring",false)
