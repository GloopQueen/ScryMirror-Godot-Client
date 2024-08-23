extends RigidBody2D


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass


func _on_despawn_timer_timeout() -> void:
	position = Vector2(900,900) 
	#stupid idea if I make it move AND THEN queue free I
	#should hopefully avoid the "didnt register exit" problem
	queue_free()
