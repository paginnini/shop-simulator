extends GoapAction

class_name GoToDrinkAction


func get_clazz(): return "GoToDrinkAction"

var _drink
var default_drink_position

#var going_already = false

func is_valid() -> bool:
	if not _drink or _drink.client_holding:
		return false
	else: return true

func _init(item):
	_drink = item
	default_drink_position = _drink.position


func get_cost(_blackboard = null) -> float:
	return _drink.cost


func get_preconditions(actor) -> Dictionary:
	return {}

#TROCAR ESSES EFEITOS POR REAIS
func get_effects(actor) -> Dictionary:
	return {
		str(actor)+"thirst_limit" : true,
		str(actor)+"thirst" : _drink.hydration
	}


func perform(actor, _delta, agent) -> bool:
	#print("perform ação go-to-drink")
	_drink.highlight()
	if default_drink_position.distance_to(actor.position) < actor.do_distance:
		if not is_valid(): agent._current_goal = null
		
		_drink.picked_up(actor)
		_drink.scale *= 0.5
		
		WorldState.set_state(str(actor)+"thirst", WorldState.get_state(str(actor)+"thirst") + _drink.hydration)
		actor.thirst += _drink.hydration
		actor.itens_list.push_back(_drink)
		actor.bill += _drink.cost
		
		actor.going_already = false

		if actor.thirst >= actor.drink_limit:
			WorldState.set_state(str(actor)+"thirst_limit", true)
		return true
	else:
		#print("não ta perto", actor.going_already)
		if not actor.going_already:
			#print("-------------------começa a ir pra: ", _drink.position)
			actor.navigation_agent_3d.set_target_position(_drink.position)
			actor.going_already = true
	return false
