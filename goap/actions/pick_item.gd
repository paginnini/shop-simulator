extends GoapAction

class_name PickItemAction


func get_clazz(): return "PickItemAction"

var _item
var default_item_position

#var going_already = false

func is_valid() -> bool:
	if not _item or _item.client_holding:
		return false
	else: return true

func _init(item):
	_item = item
	default_item_position = _item.position


func get_cost(_blackboard  = null) -> float:
	if _blackboard["actor"].ud_goap:
		return 0.0
	else:
		return default_item_position.distance_to(_blackboard["position"])


func get_preconditions(actor = null, blackboard = null) -> Dictionary:
	return {}

#TROCAR ESSES EFEITOS POR REAIS
func get_effects(actor, blackboard = null) -> Dictionary:
	var a = false
	if _item.cost + blackboard["bill"] > blackboard["money"]:
		a = true
	return {
		"satisfaction" : _item.satisfaction,
		"is_in_debt": a,
		"bill": _item.cost + blackboard["bill"]
	}


func perform(actor, _delta, agent) -> bool:
	_item.highlight()
	if default_item_position.distance_to(actor.position) < actor.do_distance:
		if not is_valid(): agent._current_goal = null
		
		_item.picked_up(actor)
		_item.scale *= 0.5
		
		actor._state.set("satisfaction", actor._state.get("satisfaction") + _item.satisfaction)
		actor._state["bill"] += _item.cost
		actor.itens_list.push_back(_item)
		
		actor.going_already = false
		
		return true
	else:
		#print("não ta perto", actor.going_already)
		if not actor.going_already:
			#print("-------------------começa a ir pra: ", _item.position)
			actor.navigation_agent_3d.set_target_position(_item.position)
			actor.going_already = true
	return false
