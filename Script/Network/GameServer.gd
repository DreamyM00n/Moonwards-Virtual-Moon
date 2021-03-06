extends ANetworkInstance
class_name GameServer

var port: int = 0
var max_players: int = 0
var is_host_player: bool = false

func _init(_port: int, _max_players: int, _is_host_player: bool = false):
	self.port = _port
	self.max_players = _max_players
	self.is_host_player = _is_host_player
	self.name = "GameServer"

func _ready() -> void:
	# because inheritence is broken on yields
	# yielding on a parent class' _ready returns it to the inheriting class' _ready
#	if !self.is_initialized:
#		yield(self, "initialized")
	load_world()
	yield(self, "world_loaded")
	get_tree().connect("network_peer_connected", self, "_player_connected")
	get_tree().connect("network_peer_disconnected", self, "_player_disconnected")
	_host_game()
	self.peer_id = get_tree().get_network_unique_id()
	_start_session()

master func request_join_server(client_version):
	Log.trace(self, "", "Client %s requested to join game session with client ver %s." %[peer_id, client_version])
	if client_version == WorldConstants.VERSION:
		Log.trace(self, "", "Client request accepted.")
		rpc_id(get_tree().get_rpc_sender_id(), "accept_join_server")
	else:
		rpc_id(get_tree().get_rpc_sender_id(), "decline_join_server", 
				"[center]The server you are trying to connect to is running a more up to date version of the game.[/center]\n\n"
				+ "[center]Grab the latest version from [color=#00d1ff][url=<https://moonwards.com/download>]https://moonwards.com/download[/url][/color][/center]")
		Log.trace(self, "", "Client request refused.")
	
master func initialize_entity_data(name, colors, gender : int):
	var peer_id = Network.get_sender_id()
	var entity_data = EntityData.new(peer_id, str(peer_id), _get_spawn())
	entity_data.entity_name = name
	entity_data.colors = colors
	entity_data.gender = gender

	# Send existing players to newly conencted peer for loading
	var data = []
	# Add the player himself so they spawn themselves
	data.append(entity_data.serialize())
	# Add the rest of the existing players
	for entity in entities.values():
		data.append(entity.serialize())
	rpc_id(peer_id, "initial_client_load_entities", data)
	
	# Need to dispose of the yield if the player fails to load.
	# Wait until we receive a signal that the player has loaded.
	### This needs to be moved to its own helper & provided a timeout.
	### Alternatively refactor the loading system during the network refactor.
	while yield(Signals.Network, Signals.Network.CLIENT_LOAD_FINISHED) != peer_id:
		pass
	
	# Resume spawning the player.
	entities[entity_data.peer_id] = entity_data
	crpc(self, "add_player", entity_data.serialize(), [peer_id])
	Log.trace(self, "initialize_entity_data", "SERVER CONNECTED: %s" %peer_id)
	Signals.Network.emit_signal(NetworkSignals.NEW_PLAYER_POST_LOAD, peer_id)

func _host_game() -> void:
	var err = self.multiplayer_peer.create_server(port, max_players)
	if err == OK:
		get_tree().set_network_peer(self.multiplayer_peer)
		self.multiplayer_peer.always_ordered = Network.IS_ALWAYS_ORDERED
		self.multiplayer_peer.compression_mode = Network.COMPRESS_MODE
	elif err == ERR_CANT_CREATE:
		Log.critical(self, "_host_game", "Could not create server peer.")
	elif err == ERR_ALREADY_EXISTS:
		Log.error(self, "_host_game", "Server peer already exists.")

func _start_session() -> void:
	Log.trace(self, "", "Server instance started.")
	# Add lobby host player
	var entity = EntityData.new(1, Network.self_meta_data.name, _get_spawn())
	entity.colors = Network.self_meta_data.colors
	entity.gender = Network.self_meta_data.gender
	entity.entity_name = Network.self_meta_data.name
	if not self.is_host_player:
		entity.is_empty = true
	entities[1] = entity
	add_player(entity)

### Temporary
func _get_spawn() -> Vector3:
	var spawns = world.get_node("SpawnPoints").get_children()
	var spawn = spawns[rand_range(0, spawns.size() - 1)]
	return spawn.global_transform.origin

func _player_connected(peer_id) -> void:
	Log.trace(self, "", "CONNECTION INITIATED: %s" %peer_id)

func _player_disconnected(peer_id) -> void:
	crpc(self, "remove_player", peer_id, [peer_id])
	Log.trace(self, "", "DISCONNECTED: %s" %peer_id)
	Signals.Network.emit_signal(NetworkSignals.CLIENT_DISCONNECTED, peer_id)
