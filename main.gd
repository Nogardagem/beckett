extends Control

#put source files in res://text/



#change initialization method here for different behavior for output ends and such; check TextGen.gd
var generator = TextGen.new("res://text/");


func _ready():
	new_notes();

func _on_generate_pressed() -> void:
	new_notes();


func new_notes():
	var text = generator.make_wfc_sentence("");
	
	$Output.text = text;# + "\n\n" + $Output.text;


func _on_copy_pressed() -> void:
	DisplayServer.clipboard_set($Output.text);
