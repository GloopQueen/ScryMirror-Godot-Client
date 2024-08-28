extends Node

@export var custom_scry_server: String
@export var enable_controller_mode: bool

@export var event_scene1: PackedScene
@export var event_scene2: PackedScene
@export var event_scene3: PackedScene

#probably trash at this point need to clean up old code
@export var mob_scene: PackedScene



var score = 0
var damage = 0
var scoreBooster = 0 #used to add some graze oomph for short interactions so doing the right thing quickly is rewarding

var data_burp = "_"

# Called when the node enters the scene tree for the first time.
func _ready():
	
	$HUD.set_scy_server_url(custom_scry_server)
	if enable_controller_mode == true:
		$EnableShowControlButton.show()
		$showController.set_scy_server_url(custom_scry_server)

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	$Background.rotation += 0.05 * delta


func game_over():
	$ScoreTimer.stop()
	$MobTimer.stop()
	$HUD.show_game_over()

func new_game():
	score = 0
	#$Player.start($StartPosition.position)
	#$StartTimer.start()
	$Avatar.show()
	get_tree().call_group("mobs", "queue_free")


func _on_score_timer_timeout():
	score += 1
	$HUD.update_score(score)

func _on_start_timer_timeout():
	$MobTimer.start()
	#$ScoreTimer.start()


func _on_mob_timer_timeout():
	var mob = mob_scene.instantiate()

	# Choose a random location on Path2D.
	var mob_spawn_location = $MobPath/MobSpawnLocation
	mob_spawn_location.progress_ratio = randf()

	# Set the mob's direction perpendicular to the path direction.
	var direction = mob_spawn_location.rotation + PI / 2

	# Set the mob's position to a random location.
	mob.position = mob_spawn_location.position

	# Add some randomness to the direction.
	direction += randf_range(-PI / 4, PI / 4)
	mob.rotation = direction

	# Choose the velocity for the mob.
	var velocity = Vector2(randf_range(150.0, 250.0), 0.0)
	mob.linear_velocity = velocity.rotated(direction)

	# Spawn the mob by adding it to the Main scene.
	add_child(mob)


func _on_hud_spawn_interaction(num,seconds,is_player_there):
	score = 0
	damage = 0
	scoreBooster = 0
	if is_player_there == true:
		$Avatar.start($StartPosition.position)
	var mob
	if num == 1:
		mob = event_scene1.instantiate()
	if num == 2:
		mob = event_scene2.instantiate()
	if num == 3:
		mob = event_scene3.instantiate()
		scoreBooster = 1
	add_child(mob)


# the exit block party
func end_this_interaction():
	print("End this interaction has been called")
	$PostPhaseCleanupTimer.start()
	$HUD.report_results(score,damage)


func _on_avatar_took_damage(amount: Variant) -> void:
	damage = damage + amount
	$HUD.update_damage(damage)


func _on_hud_reset_scores() -> void:
	score = 0
	damage = 0


func _on_avatar_gained_points(amount: Variant) -> void:
	score = score + (amount+scoreBooster)
	$HUD.update_score(score)


func _on_enable_show_control_button_pressed() -> void:
	$HUD.hide()
	$EnableShowControlButton.hide()
	$Background.hide()
	$showController.show()
