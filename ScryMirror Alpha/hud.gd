extends CanvasLayer


signal start_game
signal spawn_interaction(num,seconds,is_player_there)
signal reset_scores




var currrentEpoch = 0
var currentPage = 0
var currentSeconds = 0
var currentPhaseId = 0
var isServerPollerBusy = false 
var scryServerURL
var shouldWeBePollingRNGlobal = false
var voteChoice = -1
var voteCountDown = 40


func _ready():
	$HTTPRequest.request_completed.connect(_on_request_completed) # Getting what scene to run 
	$HTTPResultsReporter.request_completed.connect(_on_reported_results) # reporting results
	$voteSection/HTTPVoteGetter.request_completed.connect(_on_http_got_votes) #setting up retrieving vote list
	$voteSection/HTTPBallotSender.request_completed.connect(_on_http_ballot_sent) #setting up sending ballot


func _process(delta):
	pass

func set_scry_server_url(a):
	if a.is_empty():
		scryServerURL = "https://scry-mirror.vercel.app/api/"
	else:
		scryServerURL = a
	print("Trying: "+scryServerURL)

func show_message(text):
	$Message.text = text
	$Message.show()
	$MessageTimer.start()
	

func should_we_be_polling_rn(answer:bool):
	shouldWeBePollingRNGlobal = answer
	$PollingStatusLabel.text = "Polling active? " + str(answer)

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
	should_we_be_polling_rn(true)
	$StartButton.hide()
	start_game.emit()

func _on_message_timer_timeout():
	$Message.hide()


func _on_web_poller_timeout():
	if $WebPoller.wait_time != 4:
		$WebPoller.wait_time = 4
	#$HTTPRequest.request_completed.connect(_on_request_completed)
	if isServerPollerBusy == false and shouldWeBePollingRNGlobal == true:
		$HTTPRequest.request(scryServerURL +"statusjson/")
		isServerPollerBusy = true
	#if shouldWeBePollingRNGlobal == false:
		#print("polling skipped due to local block.")
	# $HTTPRequest.request("https://scry-mirror.vercel.app/api/statusjson") just in case


# this is the function that kicks off the hooplah if there's an update
func _on_request_completed(result, response_code, headers, body):
	isServerPollerBusy = false
	var json = JSON.parse_string(body.get_string_from_utf8())
	var infoString 
	print(json["currentSeconds"])
	#print(json)
	
	#Check If attack is valid (new ID, doesn't look like server just rebooted)
	if currentPhaseId != json["currentPhaseId"] && json["currentPhaseId"] != -1:
		currrentEpoch = json["currentEpochStamp"]
		currentPage = json["thePage"]
		currentSeconds = json["currentSeconds"]
		currentPhaseId = json["currentPhaseId"]
		infoString = "Page:"+str(currentPage)+" Epoch:"+str(currrentEpoch)+" Delay:"+str(currentSeconds)+" PhaseID:"+str(currentPhaseId)
		show_epoch(infoString)
	
	# Check if attack is actually an attack, and if so, set up for that
		if json["thePage"] >= 1:
			print("the page checker is looping fast.")
			should_we_be_polling_rn(false)
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
		#Check if attack is actually a vote, and if so, set up for that
		if json["thePage"] == 0:
			should_we_be_polling_rn(false)
			start_vote_stuff()
	
	
	# Whine if the server just rebooted
	if json["currentPhaseId"] == -1:
		$FeedbackFromServerLabel.text = "Attack ID was -1, ignoring."
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
	should_we_be_polling_rn(true) #restarts polling
	var urlstring = scryServerURL + "clientresults/" + str(currentPhaseId) + "/" + str(damage) + "/" + str(score)
	print("Pinging: " + urlstring)
	$HTTPResultsReporter.request(urlstring)


func _on_incoming_action_timer_timeout():
	$Incoming.hide()
	spawn_interaction.emit(currentPage,currentSeconds,true)#sends the spawn event signals to main.gd


func _on_server_connect_button_pressed() -> void:
	should_we_be_polling_rn(true)
	$WebPoller.start()
	$ServerConnectButton.hide()
	start_game.emit()



#
# == THE VOTING PARTY STARTS HERE YEEHAW ==
#
#

# get the vote choices from the server, and start the clock
func start_vote_stuff():
	$voteSection.show()
	var urlstring = scryServerURL + "getvoteoptions" 
	$voteSection/HTTPVoteGetter.request(urlstring)


# sets the button text and starts the clock
func _on_http_got_votes(result, response_code, headers, body):
	var json = JSON.parse_string(body.get_string_from_utf8())
	$voteSection/voteList.set_item_text(0, str(json["name1"]) )
	$voteSection/voteList.set_item_text(1, str(json["name2"]) )
	$voteSection/voteList.set_item_text(2, str(json["name3"]) )
	$voteSection/voteList.set_item_text(3, str(json["name4"]) )
	$voteSection/VoteCountdownTimer.start()

func _on_http_ballot_sent(result, response_code, headers, body):
	$voteSection/VoteDismissTimer.start()
	


#mops up some mess after the vote results are sent 
func _on_vote_dismiss_timer_timeout() -> void:
	should_we_be_polling_rn(true)
	$voteSection.hide()
	voteChoice = -1
	$voteSection/voteList.deselect_all()
	$voteSection/voteList.mouse_filter = Control.MOUSE_FILTER_STOP
	$voteSection/VoteTimeBar.value = 20
	voteCountDown = 40
	$voteSection/voteSubmitButton.disabled = false
	


func _on_vote_countdown_timer_timeout() -> void:
	if voteCountDown <= 0:
		$voteSection/VoteCountdownTimer.stop()
		send_ballot()
	voteCountDown = voteCountDown - 1
	$voteSection/VoteTimeBar.value = voteCountDown

func send_ballot():
	var headers = ["Content-Type: application/json"]
	if voteChoice == -1:
		$voteSection/VoteInfoLabel.text = "No choice set."
		$voteSection/VoteDismissTimer.start()
		return
	$voteSection/voteSubmitButton.disabled = true
	$voteSection/voteList.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var jsonPacket = {
		"phaseid": currentPhaseId,
		"voteResponse": voteChoice
	}
	var jsonBurp = JSON.new().stringify(jsonPacket)
	var urlstring = scryServerURL + "votechoice/"
	$voteSection/HTTPBallotSender.request(urlstring,headers,HTTPClient.METHOD_POST, jsonBurp)


func _on_vote_list_item_selected(index: int) -> void:
	voteChoice = index


func _on_vote_submit_button_pressed() -> void:
	$voteSection/VoteCountdownTimer.stop()
	send_ballot()
