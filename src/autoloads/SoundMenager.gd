extends Node

var master_sound_value := -10.0
var master_sound_mute := false

var music_sound_value := -10.0
var music_sound_mute := false

var sfx_sound_value := -10.0
var sfx_sound_mute := false

func set_mute_main(val : bool = true):
	master_sound_mute = val
	AudioServer.set_bus_mute(0, master_sound_mute)

func set_volume_main(val : float):
	master_sound_value = val
	AudioServer.set_bus_volume_db(0, master_sound_value)

func set_mute_music(val : bool = true):
	music_sound_mute = val
	AudioServer.set_bus_mute(1, music_sound_mute)

func set_volume_music(val : float):
	music_sound_value = val
	AudioServer.set_bus_volume_db(1, music_sound_value)

func set_mute_sfx(val : bool = true):
	sfx_sound_mute = val
	AudioServer.set_bus_mute(2, sfx_sound_mute)

func set_volume_sfx(val : float):
	sfx_sound_value = val
	AudioServer.set_bus_volume_db(2, sfx_sound_value)
