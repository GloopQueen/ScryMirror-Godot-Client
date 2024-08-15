extends CanvasLayer


signal start_game
signal spawn_interaction(num,seconds,is_player_there)
signal reset_scores


var currrentEpoch = 0
var currentPage = 0
var currentSeconds = 0
var currentAttackId = 0

var scryServerURL


func _ready():
	$HTTPRequest.request_completed.connect(_on_request_completed) # Getting what scene to run 
	$HTTPResultsReporter.request_completed.connect(_on_reported_results) # reporting results


func _process(delta):
	pass

func set_scy_server_url(a):
	if a.is_empty():
		scryServerURL = "https://scry-mirror.vercel.app/api/"
	else:
		scryServerURL = a
	print("Trying: "+scryServerURL)

func show_message(text):
	$Message.text = text
	$Message.show()
	$MessageTimer.start()
	

func show_epoch(text):
	$EpochLabel.text = text
	$EpochLabel.show()


func show_game_over():
	show_message("Game Over")
	# Wait until the MessageTimer has counted down.
	await $MessageTimer.timeout
	
	$Message.text = "Dodge the Creeps!"
	$Message.show()
	# Make a one-shot timer and wait for it to finish.
	await get_tree().create_timer(1.0).timeout
	$StartButton.show()

func update_score(score):
	$ScoreLabel.text = str(score)

func update_damage(damage):
	$DamageLabel.text = str(damage)

func _on_start_button_pressed():
	$StartButton.hide()
	start_game.emit()

func _on_message_timer_timeout():
	$Message.hide()


func _on_web_poller_timeout():
	if $WebPoller.wait_time != 4:
		$WebPoller.wait_time = 4
	#$HTTPRequest.request_completed.connect(_on_request_completed)
	$HTTPRequest.request(scryServerURL+"statusjson")
	# $HTTPRequest.request("https://scry-mirror.vercel.app/api/statusjson") just in case


# this is the function that kicks off the hooplah if there's an update
func _on_request_completed(result, response_code, headers, body):
	var json = JSON.parse_string(body.get_string_from_utf8())
	var infoString 
	print(json["currentSeconds"])
	if currentAttackId != json["currentAttackId"] && json["currentAttackId"] != 0:
		currrentEpoch = json["currentEpochStamp"]
		currentPage = json["thePage"]
		currentSeconds = json["currentSeconds"]
		currentAttackId = json["currentAttackId"]
		infoString = "Page:"+str(currentPage)+" Epoch:"+str(currrentEpoch)+" Delay:"+str(currentSeconds)+" AttackID:"+str(currentAttackId)
		show_epoch(infoString)
		
		#get the times so we can delay before running animation
		var rightNow = Time.get_time_dict_from_system()
		# if the times are outta whack get em back on track (Gloop this system is stupid.)
		if currentSeconds < rightNow["second"]:
			currentSeconds += 60
		var waitingFor = currentSeconds - rightNow["second"]
		$IncomingActionTimer.wait_time = (waitingFor)
		print("waiting for:"+str(waitingFor))
		$IncomingActionTimer.start()
		$Incoming.show()
		$PlaneDing.play()
		
		#adjust scores
		reset_scores.emit()
		$ScoreLabel.text = str(0)
		$DamageLabel.text = str(0)
	if json["currentAttackId"] == 0:
		$FeedbackFromServerLabel.text = "Attack ID was 0, ignoring."
	#$EpochLabel.text = str(json["currentEpochStamp"])
	#var json = JSON.parse_string(body.get_string_from_utf8())
	#print(json["currentSeconds"])
	#$EpochLabel.text = str(json["currentEpochStamp"])
	#show_epoch(str(json["currentSeconds"]))


# This handles feedback after reporting post-phase results to the server
func _on_reported_results(result, response_code, headers, body):
	var json = JSON.parse_string(body.get_string_from_utf8())
	var feedbackfromserver = str(json["responseM"])
	print(feedbackfromserver)
	$FeedbackFromServerLabel.text = feedbackfromserver


func report_results(score,damage):
	#damage = 20
	#score = 21
	var urlstring = scryServerURL + "clientresults/" + str(currentAttackId) + "/" + str(damage) + "/" + str(score)
	print("Pinging: " + urlstring)
	$HTTPResultsReporter.request(urlstring)


func _on_incoming_action_timer_timeout():
	$Incoming.hide()
	spawn_interaction.emit(currentPage,currentSeconds,true)#sends the spawn event signals to main.gd


func _on_server_connect_button_pressed() -> void:
	$WebPoller.start()
	$ServerConnectButton.hide()
	start_game.emit()
