extends RigidBody2D

@export var isPink:bool = false

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	if isPink == true:
		$firewallSprite.animation = "pink"


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass


func _on_kill_timer_timeout() -> void:
	queue_free()
