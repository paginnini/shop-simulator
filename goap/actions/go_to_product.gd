extends GoapAction

class_name GoToProductAction


func get_clazz(): return "GoToProductAction"

var _product
var default_product_position

#var going_already = false

func is_valid() -> bool:
	if not _product or _product.client_holding:
		return false
	else: return true

func _init(item):
	_product = item
	default_product_position = _product.position


func get_cost(_blackboard  = null) -> float:
	return _product.cost


func get_preconditions(actor) -> Dictionary:
	return {}

#TROCAR ESSES EFEITOS POR REAIS
func get_effects(actor) -> Dictionary:
	return {
		str(actor)+"hygiene_limit" : true,
		str(actor)+"hygiene" : _product.hygiene
	}


func perform(actor, _delta, agent) -> bool:
	#print("perform ação go-to-product")
	_product.highlight()
	if default_product_position.distance_to(actor.position) < actor.do_distance:
		if not is_valid(): agent._current_goal = null
		
		_product.picked_up(actor)
		_product.scale *= 0.5
		
		WorldState.set_state(str(actor)+"hygiene", WorldState.get_state(str(actor)+"hygiene") + _product.hygiene)
		actor.hygiene += _product.hygiene
		actor.bill += _product.cost
		actor.itens_list.push_back(_product)
		
		actor.going_already = false
		
		if actor.hygiene >= actor.product_limit:
			WorldState.set_state(str(actor)+"hygiene_limit", true)
		return true
	else:
		#print("não ta perto", actor.going_already)
		if not actor.going_already:
			#print("-------------------começa a ir pra: ", _product.position)
			actor.navigation_agent_3d.set_target_position(_product.position)
			actor.going_already = true
	return false
