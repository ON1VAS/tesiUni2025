extends Control

@onready var conferma_button = $VBoxContainer/pulsanti/conferma
@onready var annulla_button = $VBoxContainer/pulsanti/annulla
@onready var decineOre = $VBoxContainer/HBoxContainer/decineOre/Label1
@onready var unitaOre = $VBoxContainer/HBoxContainer/unitaOre/Label2
@onready var decineMinuti = $VBoxContainer/HBoxContainer/decineMinuti/Label3
@onready var unitaMinuti = $VBoxContainer/HBoxContainer/unitaMinuti/Label4
@onready var motivolabel = $VBoxContainer/TextEdit

signal annulla_orario
signal conferma_iniziato

func _ready():
	conferma_button.pressed.connect(_on_confirm_pressed)
	annulla_button.pressed.connect(_on_cancel_pressed)

func _on_confirm_pressed():
	#calcolo ore e minuti di riflessione
	var ore_intere = int(decineOre.text) * 10 + int(unitaOre.text)
	var minuti_interi = int(decineMinuti.text) * 10 + int(unitaMinuti.text)
	var motivo = str(motivolabel.text)
	if ore_intere + minuti_interi == 0:
		return
	GlobalStats.simula_recupero_energia(ore_intere, minuti_interi, motivo)
	conferma_iniziato.emit()
	TransitionScreen.transition()
	

func _on_cancel_pressed():
	annulla_orario.emit()
