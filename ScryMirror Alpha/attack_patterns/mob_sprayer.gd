extends Node

signal done_spewing_mobs

@export var mob_scene: PackedScene

var mobCount = 35


# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass


func _on_mob_delay_timer_timeout():
	spawn_mob()
	mobCount -= 1
	if (mobCount <= 0):
		var parent = get_parent()
		parent.end_this_interaction()
		queue_free()

func spawn_mob():
	var mob = mob_scene.instantiate()
	$MobSpawnSpot.position = Vector2(randf_range(1,419),2)

	#scale down the sprite and the hitbox
	var sprite = mob.get_node("./AnimatedSprite2D")
	sprite.scale = Vector2(0.5,0.5)
	var hitbox = mob.get_node("./CollisionShape2D")
	hitbox.scale = Vector2(0.5,0.5)

	# Set the mob's direction perpendicular to the path direction.
	var direction = $MobSpawnSpot.rotation + PI / 2

	# Set the mob's position to a random location.
	mob.position = $MobSpawnSpot.position

	# Add some randomness to the direction.
	direction += randf_range(-PI / 9, PI / 9)
	mob.rotation = direction
	
	#put some gas in the tank speedwise
	var velocity = Vector2(randf_range(150.0, 250.0), 0.0)
	mob.linear_velocity = velocity.rotated(direction)
	
	add_child(mob)
