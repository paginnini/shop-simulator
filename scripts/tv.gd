extends CSGBox3D

var value := 6
var direction := 1  # +1 = going up, -1 = going down

var outline

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	#outline = $".".duplicate()
	#outline.material_override = preload("res://OutlineMaterial.tres")
	#outline.scale *= 1.3
	#outline.visible = false
	#add_child(outline)
	pass


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass

func highlight():
	outline.visible = true

func unhighlight():
	outline.visible = false


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
