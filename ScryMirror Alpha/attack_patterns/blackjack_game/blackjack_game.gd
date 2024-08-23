extends Node

@export var cardScene:PackedScene
@export var firewallScene:PackedScene
@export var coinScene:PackedScene
@export var skinnyLaserScene:PackedScene

var cardCount:int = 0
var leftScore:int = 0
var rightScore:int = 0
var leftHadAnAce:bool = false
var rightHadAnAce:bool = false
var firewallSpawnPosition
var coinSpawnPosition
var isPink:bool = true

var theDeck = [2,3,4,7,8,9,10,11]
#var theDeck = [2,11]

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass


func _on_card_spawn_timer_timeout() -> void:
	spawn_card("left")
	spawn_card("right")
	if cardCount == 1:
		$skinnyLaserTimer.wait_time = 1
	cardCount=cardCount+1



func spawn_card(side:String):
	var card = cardScene.instantiate()
	var cardValue =  theDeck.pick_random()
	
	# make sure aces only happen once on a side, maximum
	if cardValue == 11:
		while (side == "left" and leftHadAnAce == true) or (side == "right" and rightHadAnAce == true):
			print("a second ace came up.")
			cardValue =  theDeck.pick_random()
			if cardValue != 11:
				print("successfully changed duplicate ace.")
				break
		if side == "left":
			leftHadAnAce = true
		if side == "right":
			rightHadAnAce = true
	
	card.cardValue = cardValue
	
	if side == "left":
		leftScore = leftScore + cardValue
		card.position = $CardSpitterLeft.position
	if side == "right":
		rightScore = rightScore + cardValue
		card.position = $CardSpitterRight.position
	card.howSoonToSlowDown = 0.6 - (cardCount * 0.1)
	$UpdateAndCheckForVictoryTimer.wait_time = 1 - (cardCount * 0.1)
	$UpdateAndCheckForVictoryTimer.start()
	add_child(card)
	
	


func _on_update_and_check_for_victory_timer_timeout() -> void:
	# "scratch math" to check for aces without disrupting score
	var finalCountLeft = leftScore
	var finalCountRight = rightScore
	if finalCountLeft > 21 and leftHadAnAce == true:
		finalCountLeft = finalCountLeft - 10
	if finalCountRight > 21 and rightHadAnAce == true:
		finalCountRight = finalCountRight - 10

	$LeftCountLabel.text = str(finalCountLeft)
	$RightCountLabel.text = str(finalCountRight)

	#check for win conditions
	if finalCountLeft == 21 and finalCountRight == 21:
		ending_events("push")
	elif finalCountLeft == 21:
		ending_events("left")
	elif finalCountRight == 21:
		ending_events("right")
	elif finalCountLeft > 21 and finalCountRight > 21:
		ending_events("push")
	elif finalCountLeft > 21 and finalCountRight <= 21:
		ending_events("right")
	elif finalCountLeft <= 21 and finalCountRight > 21:
		ending_events("left")
		

	
	
func ending_events(side:String):
	$CardSpawnTimer.stop()
	var victoryLabel = $VictoryInfoLabel
	if side == "push":
		print("push.")
		victoryLabel.text = "Push."
	elif side == "left":
		print("left won.")
		victoryLabel.text = "Left Wins!"
		firewallSpawnPosition = $firewallSpawnpointR.position
		coinSpawnPosition = $CoinSpawnpointL.position
	elif side == "right":
		print("right won.")
		victoryLabel.text = "Right Wins!"
		firewallSpawnPosition = $firewallSpawnpointL.position
		coinSpawnPosition = $CoinSpawnpointR.position
	
	if side != "push":
		$firewallSpawnTimer.start()
		$coinSpawnTimer.start()
	$ApocalypseClock.start()


func _on_firewall_spawn_timer_timeout() -> void:
	var fireWave = firewallScene.instantiate()
	fireWave.position = firewallSpawnPosition
	if isPink == true:
		fireWave.isPink = true
		isPink = false
	else:
		isPink = true 
	add_child(fireWave)


func _on_coin_spawn_timer_timeout() -> void:
	var newCoin = coinScene.instantiate()
	newCoin.position = coinSpawnPosition + Vector2(randi_range(30,210),randi_range(30,690))
	add_child(newCoin)


func _on_skinny_laser_timer_timeout() -> void:
	var newLaser = skinnyLaserScene.instantiate()
	newLaser.position = Vector2(240,3)
	newLaser.rotation = $CoinSpawnpointR.rotation + PI / 2
	newLaser.linear_velocity = Vector2(0,200)
	add_child(newLaser)
	


func _on_apocalypse_clock_timeout() -> void:
	var parent = get_parent()
	parent.end_this_interaction()
	queue_free()
