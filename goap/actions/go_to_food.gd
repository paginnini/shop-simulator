extends GoapAction

class_name GoToFoodAction


func get_clazz(): return "GoToFoodAction"

var _food
var default_food_position

#var going_already = false

func is_valid() -> bool:
	if not _food or _food.client_holding:
		return false
	else: return true

func _init(item):
	_food = item
	default_food_position = _food.position


func get_cost(_blackboard  = null) -> float:
	return _food.cost


func get_preconditions(actor) -> Dictionary:
	return {}

#TROCAR ESSES EFEITOS POR REAIS
func get_effects(actor) -> Dictionary:
	return {
		str(actor)+"hunger_limit" : true,
		str(actor)+"hunger" : _food.nutrition
	}


func perform(actor, _delta, agent) -> bool:
	#print("perform ação go-to-food")
	_food.highlight()
	if default_food_position.distance_to(actor.position) < actor.do_distance:
		if not is_valid(): agent._current_goal = null
		
		_food.picked_up(actor)
		_food.scale *= 0.5
		
		WorldState.set_state(str(actor)+"hunger", WorldState.get_state(str(actor)+"hunger") + _food.nutrition)
		actor.hunger += _food.nutrition
		actor.itens_list.push_back(_food)
		actor.bill += _food.cost
		
		actor.going_already = false
		
		if actor.hunger >= actor.food_limit:
			WorldState.set_state(str(actor)+"hunger_limit", true)
		return true
	else:
		#print("não ta perto", actor.going_already)
		if not actor.going_already:
			#print("-------------------começa a ir pra: ", _food.position)
			actor.navigation_agent_3d.set_target_position(_food.position)
			actor.going_already = true
	return false
