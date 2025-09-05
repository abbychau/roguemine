extends RefCounted
class_name RogueMineAPIClient

## API Client for RogueMine Highscore Backend
## Handles communication with the backend server using HTTPRequest

signal request_completed(success: bool, data: Dictionary)
signal connection_error(error_message: String)

var base_url: String = "http://localhost:3000"
var encoder: RogueMineEncoder
var http_request: HTTPRequest
var is_requesting: bool = false
var request_queue: Array = []

func _init(server_url: String = "http://localhost:3000", secret: String = "default-secret-key"):
	base_url = server_url.rstrip("/")  # Remove trailing slash
	encoder = RogueMineEncoder.new(secret)

## Set up HTTP request node (call this from a scene)
func setup_http_request(parent_node: Node) -> void:
	http_request = HTTPRequest.new()
	parent_node.add_child(http_request)
	http_request.request_completed.connect(_on_request_completed)

## Make HTTP request
func make_request(endpoint: String, method: HTTPClient.Method = HTTPClient.METHOD_GET, data: Dictionary = {}) -> void:
	if not http_request:
		emit_signal("connection_error", "HTTP request not set up. Call setup_http_request() first.")
		return

	# If already requesting, queue this request
	if is_requesting:
		print("Request in progress, queueing new request")
		request_queue.append({"endpoint": endpoint, "method": method, "data": data})
		return

	_execute_request(endpoint, method, data)

## Execute a single HTTP request
func _execute_request(endpoint: String, method: HTTPClient.Method, data: Dictionary) -> void:
	is_requesting = true

	var url = base_url + endpoint
	var headers = ["Content-Type: application/json"]
	var body = ""

	if method == HTTPClient.METHOD_POST and not data.is_empty():
		body = JSON.stringify(data)

	print("Making request to: ", url)
	print("Method: ", method)
	print("Body: ", body)

	var error = http_request.request(url, headers, method, body)
	if error != OK:
		is_requesting = false
		emit_signal("connection_error", "Failed to make request: " + str(error))
		_process_next_request()

## Process the next request in queue
func _process_next_request() -> void:
	if request_queue.size() > 0:
		var next_request = request_queue.pop_front()
		_execute_request(next_request.endpoint, next_request.method, next_request.data)

## Handle HTTP response
func _on_request_completed(result: int, response_code: int, _headers: PackedStringArray, body: PackedByteArray) -> void:
	print("Request completed - Result: ", result, " Response code: ", response_code)

	# Mark request as completed
	is_requesting = false

	if result != HTTPRequest.RESULT_SUCCESS:
		emit_signal("connection_error", "Request failed with result: " + str(result))
		_process_next_request()
		return

	if response_code < 200 or response_code >= 300:
		var error_message = "HTTP " + str(response_code)
		if body.size() > 0:
			var body_text = body.get_string_from_utf8()
			var json = JSON.new()
			var parse_result = json.parse(body_text)
			if parse_result == OK and json.data.has("error"):
				error_message = json.data.error

		emit_signal("request_completed", false, {"error": error_message})
		_process_next_request()
		return

	# Parse response body
	var response_data = {}
	if body.size() > 0:
		var body_text = body.get_string_from_utf8()
		var json = JSON.new()
		var parse_result = json.parse(body_text)

		if parse_result == OK:
			response_data = json.data
		else:
			emit_signal("connection_error", "Failed to parse response JSON")
			_process_next_request()
			return

	emit_signal("request_completed", true, response_data)

	# Process next request in queue
	_process_next_request()

## Submit a highscore
func submit_highscore(player_name: String, score: int, time_taken: float, tiles_revealed: int, chords_performed: int) -> void:
	# Encode the data
	var encoding_result = encoder.encode_highscore(player_name, score, time_taken, tiles_revealed, chords_performed)

	if not encoding_result.success:
		emit_signal("connection_error", "Failed to encode data: " + encoding_result.error)
		return

	# Submit to server
	var request_data = {
		"encodedData": encoding_result.encodedData
	}

	make_request("/api/highscores", HTTPClient.METHOD_POST, request_data)

## Get top highscores
func get_highscores(limit: int = 10) -> void:
	make_request("/api/highscores?limit=" + str(limit))

## Check if a score would qualify for top rankings
func check_score(score: int, time_taken: float) -> void:
	var request_data = {
		"score": score,
		"timeTaken": time_taken
	}
	
	make_request("/api/highscores/check", HTTPClient.METHOD_POST, request_data)

## Test server connection
func test_connection() -> void:
	make_request("/health")

## Cleanup
func cleanup() -> void:
	if http_request:
		http_request.queue_free()
		http_request = null
	is_requesting = false
	request_queue.clear()
