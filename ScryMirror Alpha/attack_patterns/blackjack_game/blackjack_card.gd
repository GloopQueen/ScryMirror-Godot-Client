extends Node2D
var startingSpeed = Vector2(0,-800)

var TheCardItself
var theFace

@export var cardValue:int = 2
@export var howSoonToSlowDown = 1

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	TheCardItself = $TheCardItself
	theFace = $TheCardItself/CardSprite
	rotation += randf_range(-PI / 12, PI / 12)
	TheCardItself.linear_velocity = startingSpeed
	$DampDelayTimer.wait_time = howSoonToSlowDown
	$DampDelayTimer.start()
	set_card_face_value(cardValue)


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass

func set_card_face_value(value: int) :
	var texture 
	if value == 2:
		texture = load("res://attack_patterns/blackjack_game/art/Card-2.png")
	if value == 3:
		texture = load("res://attack_patterns/blackjack_game/art/Card-3.png")
	if value == 4:
		texture = load("res://attack_patterns/blackjack_game/art/Card-4.png")
	if value == 7:
		texture = load("res://attack_patterns/blackjack_game/art/Card-7.png")
	if value == 8:
		texture = load("res://attack_patterns/blackjack_game/art/Card-8.png")
	if value == 9:
		texture = load("res://attack_patterns/blackjack_game/art/Card-9.png")
	if value == 10:
		texture = load("res://attack_patterns/blackjack_game/art/Card-J.png")
	if value == 11:
		texture = load("res://attack_patterns/blackjack_game/art/Card-A.png")
	theFace.texture = texture

func _on_damp_delay_timer_timeout() -> void:
	TheCardItself.set_linear_damp(3)
