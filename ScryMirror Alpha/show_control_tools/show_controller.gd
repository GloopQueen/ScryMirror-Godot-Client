extends CanvasLayer

@export var adminKeyNumber:int 

var scryServerURL
var outgoingPageNumber: int = 0



# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	$pageSetHTTPRequest.request_completed.connect(_on_page_set_http_completed)
	$statusUpdateHTTPRequest.request_completed.connect(_on_page_update_http_completed)


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass

func set_scry_server_url(a):
	if a.is_empty():
		scryServerURL = "https://scry-mirror.vercel.app/api/"
	else:
		scryServerURL = a

#
#
#Page setting functions 
#
#
func _on_page_set_text_text_changed(new_text: String) -> void:
	if new_text.is_valid_int():
		outgoingPageNumber = new_text.to_int()
	

func _on_page_set_button_pressed() -> void:
	var pageSetURL = scryServerURL +"pageset/"+ str(adminKeyNumber) +"/"+ str(outgoingPageNumber)+"/"
	print("Running Page Set: "+pageSetURL)
	$pageSetHTTPRequest.request(pageSetURL)
	
func _on_page_set_http_completed(result, response_code, headers, body):
	print("Page set feedback, server says: " + body.get_string_from_utf8() )



#
# Update Getting Functions
#
func _on_status_update_button_pressed() -> void:
	$statusUpdateButton.disabled = true
	if $DelayCheck.button_pressed == true:
		$updateDelayTimer.start()
	else :
		
		update_status()


func _on_update_delay_timer_timeout() -> void:
	update_status()
	
func update_status():
	var getStatusURL = scryServerURL +"statusjson/"
	$statusUpdateHTTPRequest.request(getStatusURL)

func _on_page_update_http_completed(result, response_code, headers, body):
	$statusUpdateButton.disabled = false
	var json = JSON.parse_string(body.get_string_from_utf8())
	$toBeSeen/damageLastRound.text = str(json["roundHP"])
	$toBeSeen/mpLastRound.text = str(json["roundMP"])
	if $UpdateBarsCheck.button_pressed == true:
		$toBeSeen/HPBar.value = $toBeSeen/HPBar.value - int(json["roundHP"])
		$toBeSeen/MPBar.value = $toBeSeen/MPBar.value + int(json["roundMP"])


func _on_hp_set_text_submitted(new_text: String) -> void:
	$toBeSeen/HPBar.value = new_text.to_int()


func _on_hp_max_text_submitted(new_text: String) -> void:
	$toBeSeen/HPBar.max_value = new_text.to_int()


func _on_mp_set_text_submitted(new_text: String) -> void:
	$toBeSeen/MPBar.value = new_text.to_int()


func _on_mp_max_text_submitted(new_text: String) -> void:
	$toBeSeen/MPBar.max_value = new_text.to_int()
