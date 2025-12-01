extends Node

var _state = {

}

var out_position := Vector3(0.0, 0.0, 10.9)
var wc_position := Vector3(9.2, 0.0, -28.3)

var random := false

#0: GOAP, 1: UD-GOAP, 2: BOTH
var ud := 1

var base_seed = hash("npc_1_experiment_0")  # string → numeric seed
var money_rng
var bladder_rng
var preference_rng
var item_type_rng
var item_cost_rng
var item_satisfaction_rng
var item_hydration_rng
var type_quant_rng

var item_types = ["refrigerante",
				"suco",
				"agua",
				"doce",
				"carne",
				"massa"
				]

func _init():
	money_rng = RandomNumberGenerator.new()
	money_rng.seed = hash("money" + str(base_seed))
	bladder_rng = RandomNumberGenerator.new()
	bladder_rng.seed = hash("bladder" + str(base_seed))
	preference_rng = RandomNumberGenerator.new()
	preference_rng.seed = hash("preference" + str(base_seed))
	item_type_rng = RandomNumberGenerator.new()
	item_type_rng.seed = hash("type" + str(base_seed))
	item_cost_rng = RandomNumberGenerator.new()
	item_cost_rng.seed = hash("item_cost" + str(base_seed))
	item_satisfaction_rng = RandomNumberGenerator.new()
	item_satisfaction_rng.seed = hash("item_satisfaction" + str(base_seed))
	item_hydration_rng = RandomNumberGenerator.new()
	item_hydration_rng.seed = hash("item_hydration" + str(base_seed))
	type_quant_rng = RandomNumberGenerator.new()
	type_quant_rng.seed = hash("type_quant" + str(base_seed))
	

func get_state(state_name, default = null):
	return _state.get(state_name, default)


func set_state(state_name, value):
	_state[state_name] = value


func clear_state():
	_state = {}


func get_elements(group_name):
	return self.get_tree().get_nodes_in_group(group_name)


func get_closest_element(group_name, reference):
	var elements = get_elements(group_name)
	var closest_element
	var closest_distance = 10000000

	for element in elements:
		var distance = reference.position.distance_to(element.position)
		if  distance < closest_distance:
			closest_distance = distance
			closest_element = element

	return closest_element


func console_message(object):
	var console = get_tree().get_nodes_in_group("console")[0] as TextEdit
	console.text += "\n%s" % str(object)
	console.set_caret_line(console.get_line_count())


func state_display_update():
	var state_display = get_tree().get_nodes_in_group("worldstate_display")[0] as TextEdit
	var wdisplay_text = ""
	for i in _state:
		wdisplay_text += "%s: %s\n" %[str(i), str(get_state(i))]
	state_display.text = wdisplay_text
