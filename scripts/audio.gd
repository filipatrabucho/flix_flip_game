extends Node
## Sound effects pool + looping background music with crossfades.

const PATH := "res://assets/audio/%s"

var music_a: AudioStreamPlayer
var music_b: AudioStreamPlayer
var current_track := ""
var sfx_players: Array[AudioStreamPlayer] = []
var cache: Dictionary = {}
var music_volume := 0.6
var sfx_volume := 0.8


func _ready() -> void:
	music_a = AudioStreamPlayer.new()
	music_b = AudioStreamPlayer.new()
	for m in [music_a, music_b]:
		m.volume_db = -80.0
		add_child(m)
	for i in range(10):
		var p := AudioStreamPlayer.new()
		add_child(p)
		sfx_players.append(p)


func _stream(name: String) -> AudioStream:
	if cache.has(name):
		return cache[name]
	var path := PATH % name
	var s: AudioStream = null
	if ResourceLoader.exists(path):
		s = load(path)
	elif name.ends_with(".ogg") and FileAccess.file_exists(path):
		s = AudioStreamOggVorbis.load_from_file(path)
	cache[name] = s
	return s


func play(name: String, volume := 1.0, pitch_jitter := 0.06) -> void:
	var s := _stream(name + ".wav")
	if s == null:
		return
	for p in sfx_players:
		if not p.playing:
			p.stream = s
			p.volume_db = linear_to_db(maxf(0.0001, volume * sfx_volume))
			p.pitch_scale = 1.0 + randf_range(-pitch_jitter, pitch_jitter)
			p.play()
			return


func play_music(track: String) -> void:
	if track == current_track:
		return
	current_track = track
	var s := _stream(track + ".ogg")
	if s == null:
		return
	if s is AudioStreamOggVorbis:
		(s as AudioStreamOggVorbis).loop = true
	var incoming := music_b if music_a.playing else music_a
	var outgoing := music_a if incoming == music_b else music_b
	incoming.stream = s
	incoming.volume_db = -40.0
	incoming.play()
	var tw := create_tween()
	tw.tween_property(incoming, "volume_db", _music_db(), 1.5)
	tw.parallel().tween_property(outgoing, "volume_db", -60.0, 1.5)
	tw.tween_callback(outgoing.stop)


func _music_db() -> float:
	return linear_to_db(maxf(0.0001, music_volume * 0.55))


func set_volumes(music: float, sfx: float) -> void:
	music_volume = music
	sfx_volume = sfx
	for m in [music_a, music_b]:
		if m.playing and m.volume_db > -39.0:
			m.volume_db = _music_db()
