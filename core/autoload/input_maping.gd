extends Node

const CONFIG_FILE = "user://inputmap.cfg"
var INPUT_ACTIONS = []

func _ready():
	load_config()

func load_config():
	for actions in InputMap.get_actions():
		if actions is InputEventKey:
			INPUT_ACTIONS.append(actions)
	if options.get('input', 'test') == null:
		for action_name in INPUT_ACTIONS:
			var action_list = InputMap.get_action_list(action_name)
			# There could be multiple actions in the list, but we save the first one by default
			var scancode = OS.get_scancode_string(action_list[0].scancode)
			options.set("input", scancode, action_name)
			options.save()
	else: # ConfigFile was properly loaded, initialize InputMap
		for action_name in INPUT_ACTIONS:
			# Get the key scancode corresponding to the saved human-readable string
			var scancode = options.get("input", action_name)
			# Create a new event object based on the saved scancode
			var event = InputEventKey.new()
			event.scancode = scancode
			# Replace old action (key) events by the new one
			for old_event in InputMap.get_action_list(action_name):
				if old_event is InputEventKey:
					InputMap.action_erase_event(action_name, old_event)
			InputMap.action_add_event(action_name, event)

func save_to_config(section, key, value):
	"""Helper function to redefine a parameter in the settings file"""
	options.set(section, value, key)
	options.save()

func save_all():
	for action in InputMap.get_actions():
		for member in range(0,InputMap.get_action_list(action).size()):
			if InputMap.get_action_list(action)[member] is InputEventKey:
					save_to_config("input", action, InputMap.get_action_list(action)[member].scancode)
