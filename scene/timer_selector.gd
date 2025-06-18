extends Control

@onready var conferma_button = $pulsanti/conferma
@onready var annulla_button = $pulsanti/annulla
@onready var decineOre = $HBoxContainer/decineOre/Label1
@onready var unitaOre = $HBoxContainer/unitaOre/Label2
@onready var decineMinuti = $HBoxContainer/decineMinuti/Label3
@onready var unitaMinuti = $HBoxContainer/unitaMinuti/Label4

signal annulla_orario
signal conferma_iniziato

func _ready():
	conferma_button.pressed.connect(_on_confirm_pressed)
	annulla_button.pressed.connect(_on_cancel_pressed)

func _on_confirm_pressed():
	#calcolo ore e minuti di riflessione
	var ore_intere = int(decineOre.text) * 10 + int(unitaOre.text)
	var minuti_interi = int(decineMinuti.text) * 10 + int(unitaMinuti.text)
	GlobalStats.simula_recupero_energia(ore_intere, minuti_interi)
	conferma_iniziato.emit()
	

func _on_cancel_pressed():
	annulla_orario.emit()
