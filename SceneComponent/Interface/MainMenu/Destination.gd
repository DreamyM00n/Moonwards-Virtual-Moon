extends PanelContainer


#These are the signals for the buttons that get pressed.
signal joined_master()
signal joined_server(server_ip_address_string)
signal started_custom_server()

onready var ip_address : TextEdit = $HBoxContainer/VBoxContainer/VBoxContainer/PanelContainer3/VBoxContainer/TextEdit_Address
onready var port_text : TextEdit = $HBoxContainer/VBoxContainer/VBoxContainer/PanelContainer3/VBoxContainer/TextEdit_Port
#What the main server IP is.
const MAIN_SERVER_IP : String = "45.77.1.84"
const DEFAULT_PORT : int = 5000


func _joined_master() -> void :
	emit_signal("joined_master")
	
	Signals.Network.emit_signal(Signals.Network.GAME_CLIENT_REQUESTED, MAIN_SERVER_IP, DEFAULT_PORT)

func _joined_server() -> void :
	var ip : String = ip_address.text
	var port : String = port_text.text
	emit_signal("joined_server", ip)

	#Until we have config files setup.
	Signals.Network.emit_signal(Signals.Network.GAME_CLIENT_REQUESTED, ip, int(port))

func _started_custom_server() -> void :
	emit_signal("started_custom_server")
	Signals.Network.emit_signal(Signals.Network.GAME_SERVER_REQUESTED, DEFAULT_PORT)

