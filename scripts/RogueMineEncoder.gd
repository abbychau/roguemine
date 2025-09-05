extends RefCounted
class_name RogueMineEncoder

## Client-side encoding library for RogueMine highscores
## Compatible with Godot 4.x and mirrors the server-side encoding algorithm

var secret: String = "default-secret-key"
var max_timestamp_age: int = 5 * 60 * 1000  # 5 minutes in milliseconds

func _init(encoding_secret: String = "default-secret-key"):
	secret = encoding_secret

## Generate a simple hash from a string (compatible with JavaScript)
func simple_hash(str: String) -> int:
	var hash: int = 0
	for i in range(str.length()):
		var char_code = str.unicode_at(i)
		hash = ((hash << 5) - hash) + char_code
		hash = hash & hash  # Convert to 32-bit integer
	return abs(hash)

## Generate XOR key based on secret and timestamp
func generate_xor_key(timestamp: int, secret_key: String) -> Array:
	var combined = secret_key + str(timestamp)
	var hash = simple_hash(combined)
	
	# Generate a repeating key pattern
	var key_length = 16
	var key = []
	
	for i in range(key_length):
		key.append((hash + i * 7) % 256)
	
	return key

## XOR encrypt/decrypt data with rotating key
func xor_cipher(data: Array, key: Array) -> Array:
	var result = []
	for i in range(data.size()):
		var key_index = i % key.size()
		result.append(data[i] ^ key[key_index])
	return result

## Calculate checksum for data integrity
func calculate_checksum(player_name: String, score: int, time_taken: float, tiles_revealed: int, chords_performed: int, timestamp: int) -> int:
	var data_string = "%s|%d|%f|%d|%d|%d" % [player_name, score, time_taken, tiles_revealed, chords_performed, timestamp]
	return simple_hash(data_string + secret)

## Convert string to byte array
func string_to_bytes(str: String) -> Array:
	var bytes = []
	for i in range(str.length()):
		bytes.append(str.unicode_at(i))
	return bytes

## Convert byte array to string
func bytes_to_string(bytes: Array) -> String:
	var result = ""
	for byte in bytes:
		result += char(byte)
	return result

## Base64 encode using Godot's built-in function
func base64_encode(bytes: Array) -> String:
	var packed_bytes = PackedByteArray()
	for byte in bytes:
		packed_bytes.append(byte)
	return Marshalls.raw_to_base64(packed_bytes)

## Base64 decode using Godot's built-in function
func base64_decode(base64_string: String) -> Array:
	var packed_bytes = Marshalls.base64_to_raw(base64_string)
	var result = []
	for byte in packed_bytes:
		result.append(byte)
	return result

## Encode highscore data
func encode_highscore(player_name: String, score: int, time_taken: float, tiles_revealed: int, chords_performed: int) -> Dictionary:
	# Validate input data
	if player_name.is_empty() or not player_name is String:
		return {"success": false, "error": "Invalid player name"}
	
	if score < 0:
		return {"success": false, "error": "Invalid score"}
	
	if time_taken < 0:
		return {"success": false, "error": "Invalid time taken"}
	
	if tiles_revealed < 0:
		return {"success": false, "error": "Invalid tiles revealed"}
	
	if chords_performed < 0:
		return {"success": false, "error": "Invalid chords performed"}
	
	# Normalize data
	player_name = player_name.strip_edges().left(50)  # Limit name length
	score = int(score)
	time_taken = round(time_taken * 100.0) / 100.0  # Round to 2 decimal places
	tiles_revealed = int(tiles_revealed)
	chords_performed = int(chords_performed)
	
	# Generate timestamp
	var timestamp = Time.get_ticks_msec()
	
	# Calculate checksum
	var checksum = calculate_checksum(player_name, score, time_taken, tiles_revealed, chords_performed, timestamp)
	
	# Create data object
	var data_obj = {
		"n": player_name,      # name
		"s": score,            # score
		"t": time_taken,       # time
		"r": tiles_revealed,   # tiles revealed
		"c": chords_performed, # chords
		"ts": timestamp,       # timestamp
		"cs": checksum         # checksum
	}
	
	# Convert to JSON string
	var json_string = JSON.stringify(data_obj)
	
	# Convert to bytes
	var data_bytes = string_to_bytes(json_string)
	
	# Generate XOR key
	var xor_key = generate_xor_key(timestamp, secret)
	
	# Apply XOR cipher
	var encrypted_bytes = xor_cipher(data_bytes, xor_key)
	
	# Convert to base64
	var base64_data = base64_encode(encrypted_bytes)
	
	return {
		"success": true,
		"encodedData": base64_data,
		"timestamp": timestamp
	}

## Decode highscore data
func decode_highscore(encoded_data: String) -> Dictionary:
	# Decode from base64
	var encrypted_bytes = base64_decode(encoded_data)
	
	# We need to try different timestamps since we don't know the exact one
	var current_time = Time.get_ticks_msec()
	var decoded = null
	
	# Try timestamps within the last 5 minutes
	for offset in range(0, max_timestamp_age + 1, 1000):
		var test_timestamp = current_time - offset
		
		var xor_key = generate_xor_key(test_timestamp, secret)
		var decrypted_bytes = xor_cipher(encrypted_bytes, xor_key)
		var json_string = bytes_to_string(decrypted_bytes)
		
		var json = JSON.new()
		var parse_result = json.parse(json_string)
		
		if parse_result == OK:
			var data_obj = json.data
			
			# Verify timestamp is within acceptable range
			if abs(data_obj.get("ts", 0) - test_timestamp) < 1000:
				decoded = data_obj
				break
	
	if decoded == null:
		return {"success": false, "error": "Failed to decode data - invalid or expired"}
	
	# Verify checksum
	var expected_checksum = calculate_checksum(
		decoded.get("n", ""), decoded.get("s", 0), decoded.get("t", 0.0), 
		decoded.get("r", 0), decoded.get("c", 0), decoded.get("ts", 0)
	)
	
	if decoded.get("cs", 0) != expected_checksum:
		return {"success": false, "error": "Data integrity check failed"}
	
	# Verify timestamp age
	var age = Time.get_ticks_msec() - decoded.get("ts", 0)
	if age > max_timestamp_age:
		return {"success": false, "error": "Data too old"}
	
	return {
		"success": true,
		"data": {
			"playerName": decoded.get("n", ""),
			"score": decoded.get("s", 0),
			"timeTaken": decoded.get("t", 0.0),
			"tilesRevealed": decoded.get("r", 0),
			"chordsPerformed": decoded.get("c", 0),
			"timestamp": decoded.get("ts", 0)
		}
	}
