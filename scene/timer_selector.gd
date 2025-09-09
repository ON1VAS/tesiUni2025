#TimerSelector.gd
extends Control

@onready var conferma_button = $VBoxContainer/pulsanti/conferma
@onready var annulla_button = $VBoxContainer/pulsanti/annulla
@onready var valoreMinuti = $VBoxContainer/HBoxContainer/minuti/minutiSelezionati
@onready var motivolabel = $VBoxContainer/TextEdit

signal annulla_orario
signal conferma_iniziato

func _ready():
	conferma_button.pressed.connect(_on_confirm_pressed)
	annulla_button.pressed.connect(_on_cancel_pressed)

func _on_confirm_pressed():
	#calcolo minuti di riflessione
	var minuti_interi = int(valoreMinuti.text)
	var motivo = motivolabel.get_text()
	if motivo.is_empty():
		motivo = "non specificato"
	if minuti_interi == 0:
		return
	print(motivo)
	GlobalStats.simula_recupero_energia(minuti_interi, motivo)
	conferma_iniziato.emit()
	TransitionScreen.transition()
	

func _on_cancel_pressed():
	annulla_orario.emit()

func _input(event):
	#se la TextEdit ha il focus, non facciamo nulla (serve a scrivere)
	if motivolabel.has_focus():
		return
	
	#Incrementa minuti
	if event.is_action_pressed("ui_up"):
		$VBoxContainer/HBoxContainer/minuti._on_button_up_pressed()
	
	#Decrementa minuti
	elif event.is_action_pressed("ui_down"):
		$VBoxContainer/HBoxContainer/minuti._on_button_down_pressed()
	
	#va avanti al textedit
	elif event.is_action_pressed("ui_accept") and GlobalStats.in_menu:
		if !motivolabel.has_focus():
			motivolabel.grab_focus()
		else:
			_on_confirm_pressed()
			
		
