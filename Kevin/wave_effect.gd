extends RichTextEffect
class_name WaveEffect   # lets you pick it from the editor

# Tag used in BBCode: [wave]text[/wave]
var bbcode := "wave"

func _process_custom_fx(char_fx: CharFXTransform) -> bool:
	# Read params (with defaults)
	var amp   := float(char_fx.env.get("amp", 6.0))       # pixels
	var freq  := float(char_fx.env.get("freq", 6.0))      # ripples across the word
	var speed := float(char_fx.env.get("speed", 2.0))     # cps
	var phase := float(char_fx.env.get("phase", 0.0))     # per-button phase offset

	# Wiggle along Y using character index + time
	var t = char_fx.elapsed_time
	var y = sin((char_fx.relative_index * freq) + t * speed + phase) * amp
	char_fx.offset = Vector2(0.0, y)

	return true
