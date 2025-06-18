extends Control

@onready var ore = $VBoxContainer/HBoxContainer/ore
@onready var minuti = $VBoxContainer/HBoxContainer/minuti
@onready var secondi = $VBoxContainer/HBoxContainer/secondi

@onready var tempoSecondi = $VBoxContainer/tempoSecondi

func _ready():
	self.visible = false


func calcola_tempo():
	var secondi_totali = GlobalStats.secondi_totali
	var ore_rimanenti: int = secondi_totali / 3600
	var minuti_rimanenti: int = (secondi_totali % 3600) / 60
	var secondi_rimanenti: int = secondi_totali % 60
	
	# Mostra solo ore se presenti
	if ore_rimanenti > 0:
		ore.text = str(ore_rimanenti)
		minuti.text = str(minuti_rimanenti).pad_zeros(2)
		secondi.text = str(secondi_rimanenti).pad_zeros(2)
	# Altrimenti mostra solo minuti e secondi
	elif minuti_rimanenti > 0:
		ore.text = ""
		minuti.text = str(minuti_rimanenti)
		secondi.text = str(secondi_rimanenti).pad_zeros(2)
	# Altrimenti mostra solo secondi
	else:
		ore.text = ""
		minuti.text = ""
		secondi.text = str(secondi_rimanenti)
	
	tempoSecondi.text = str(secondi_totali)
	
	
