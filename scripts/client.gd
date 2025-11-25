extends CharacterBody3D

@onready var navigation_agent_3d: NavigationAgent3D = $NavigationAgent3D

const SPEED = 5.0

var ud_goap = false

var going_already = false


var _money := 0.0
var _bill := 0.0

const satisfaction_limit := 100.0

var do_distance := 5.0

var itens_list = []
var preference = {
	"refrigerante": 0.5,
	"suco": 0.5,
	"agua": 0.5,
	"doce": 0.5,
	"carne": 0.5,
	"massa": 0.5
}

var _state = {
	"satisfaction": 0.0,
	"satisfaction_limit": satisfaction_limit,
	"money": _money,
	"bill": _bill,
	"payed": false,
	"out": false,
	"watching": false,
	"used_wc": false,
	"is_in_debt": false
}

func _ready():
	#define variaveis aleatorias para esse npc
	_money = randf_range(5000.0, 10000.0)
	_state.set("money", _money)
	
	#hunger = food_limit
	
	$SubViewportContainer/SubViewport/ProgressBar.max_value = satisfaction_limit
	
	var agent = GoapAgent.new()
	agent.init(self, [
		PickItensGoal.new(),
		LeaveGoal.new(),
		WatchTVGoal.new(),
		UseWCGoal.new()
	])
	add_child(agent)



func _physics_process(delta: float) -> void:
	#$labels/label_money.text = "sati_limit: %.2f\nsati: %.2f\nBill: %.2f\nMoney: %.2f" % [satisfaction_limit, _state["satisfaction"], _state["bill"], _state["money"]]
	var text := ""
	for key in _state.keys():
		text += "%s: %s\n" % [key, str(_state[key])]
	$labels/label_money.text = text
	$SubViewportContainer/SubViewport/ProgressBar.value = _state["satisfaction"]
	if not is_on_floor():
		velocity += get_gravity() * delta
	
	var destination = navigation_agent_3d.get_next_path_position()
	var local_destination = destination - global_position
	var direction = local_destination.normalized()
	
	velocity = direction * SPEED
	move_and_slide()
	update_worldstate()


func update_worldstate() -> void:
	#WorldState.
	pass


func vanish() -> void:
	for i in itens_list:
		if i: i.queue_free()
	itens_list = []
	#self.queue_free()
