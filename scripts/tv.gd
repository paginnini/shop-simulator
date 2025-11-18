extends CSGBox3D

var value := 6
var direction := 1  # +1 = going up, -1 = going down

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass


func _on_timer_timeout() -> void:
	value += direction

	if value >= 8:
		value = 8
		direction = -1
	elif value <= 1:
		value = 1
		direction = 1
	$Label3D.text = str(value)
	#print("\nPRIORIDADE TV: ", value)
