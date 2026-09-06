extends Node


const RAKIBEI_HARVESTTOGGLE_DIR := "Rakibei-HarvestToggle"
const RAKIBEI_HARVESTTOGGLE_LOG_NAME := "Rakibei-HarvestToggle:Main"

var mod_dir_path := ""
var extensions_dir_path := ""

func _init() -> void:
	mod_dir_path = ModLoaderMod.get_unpacked_dir().path_join(RAKIBEI_HARVESTTOGGLE_DIR)
	# Add extensions
	install_script_extensions()


func install_script_extensions() -> void:
	extensions_dir_path = mod_dir_path.path_join("extensions")
	ModLoaderMod.install_script_extension(extensions_dir_path.path_join("main.gd"))


func _ready() -> void:
	ModLoaderLog.info("Ready!", RAKIBEI_HARVESTTOGGLE_LOG_NAME)
