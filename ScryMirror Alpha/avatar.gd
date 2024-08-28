extends CharacterBody2D

signal took_damage(amount)
signal gained_points(amount)

var speed = 400
var click_position = Vector2()
var target_position = Vector2()
var DidWeJustGetSmacked = false
var ValueOfObjectsBeingGrazedRN = 0

func _ready():
	$GrazeRingAnimatedSprite.hide()
	$GrazeRingAnimatedSprite.animation = "NiceLilFlash"
	$GrazeRingAnimatedSprite.play()
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
	
func vanish_in_a_puff():
	#still needs the vanish ina  puff animation lol
	hide()


func _on_area_2d_body_entered(body: Node2D) -> void:
	print('fireball ouchie me bones')
	$OuchNoise.play()
	DidWeJustGetSmacked = true
	ValueOfObjectsBeingGrazedRN = 0
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
	if ValueOfObjectsBeingGrazedRN > 0 :
		$GrazeRingAnimatedSprite.show()
		$GrazeNoise.play()
		gained_points.emit(1)
	if ValueOfObjectsBeingGrazedRN >= 2:
		$GrazeTimer.wait_time = 0.06
	else:
		$GrazeTimer.wait_time = 0.12
	
	if ValueOfObjectsBeingGrazedRN <= 0:
		$GrazeRingAnimatedSprite.hide()
	
	#$GrazeArea2D.set_deferred("monitorable",true)
	#$GrazeArea2D.set_deferred("monitoring",true)


func _on_graze_area_2d_body_entered(body: Node2D) -> void:
	count_grazeable_items()
	if DidWeJustGetSmacked == false:
		$GrazeNoise.play()
		print("yay a graze point")


		#$GrazeArea2D.set_deferred("monitorable",false)
		#$GrazeArea2D.set_deferred("monitoring",false)


func _on_graze_area_2d_body_exited(body: Node2D) -> void:
	count_grazeable_items()


func count_grazeable_items():
	if DidWeJustGetSmacked == false:
		var objects = $GrazeArea2D.get_overlapping_bodies()
		ValueOfObjectsBeingGrazedRN = objects.size()
		print("value of objects grazed rn:" + str(ValueOfObjectsBeingGrazedRN))


# If we destroy projectiles etc, they don't "exit" collision. So there's a delay clock to help mop things up just in case.
func _on_post_phase_cleanup_timer_timeout() -> void:
	DidWeJustGetSmacked = false
	ValueOfObjectsBeingGrazedRN = 0
