extends Control

@onready var minuti = $VBoxContainer/HBoxContainer/minuti
@onready var secondi = $VBoxContainer/HBoxContainer/secondi
@onready var tempoSecondi = $VBoxContainer/tempoSecondi
@onready var back_button: Button = $Button

signal annulla_tempo_rimanente

func _ready():
	self.visible = false
	back_button.pressed.connect(torna_al_menu)
	
func _process(delta: float):
	if GlobalStats.tempo_cooldown < 1:
		self.visible = false

func calcola_tempo():
	var secondi_totali = GlobalStats.tempo_cooldown
	var minuti_rimanenti: int = (secondi_totali % 3600) / 60
	var secondi_rimanenti: int = secondi_totali % 60
	
	
	
	if minuti_rimanenti > 0:
		minuti.text = str(minuti_rimanenti)
		secondi.text = str(secondi_rimanenti).pad_zeros(2)
	# Altrimenti mostra solo secondi
	else:
		minuti.text = "00"
		secondi.text = str(secondi_rimanenti)
	
	tempoSecondi.text = str(secondi_totali)
	

func torna_al_menu():
	annulla_tempo_rimanente.emit()
