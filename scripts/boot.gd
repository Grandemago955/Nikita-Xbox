extends Node
# Avvio sicuro: carica gli script uno alla volta e mostra a schermo eventuali errori,
# cosi' non resta una schermata blu vuota.

const SCRIPTS := ["atlas_data", "texlib", "level", "rig", "backdrop", "audio", "game_2d"]

var label: Label
var overlay: CanvasLayer
var game: Node
var last_step := ""

func _ready() -> void:
    overlay = CanvasLayer.new()
    overlay.layer = 100
    add_child(overlay)
    var bg := ColorRect.new()
    bg.color = Color(0.05, 0.08, 0.14)
    bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    overlay.add_child(bg)
    label = Label.new()
    label.position = Vector2(30, 30)
    label.size = Vector2(900, 480)
    label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
    label.add_theme_font_size_override("font_size", 24)
    label.add_theme_color_override("font_color", Color.WHITE)
    overlay.add_child(label)
    label.text = "LUCIFERO CONTRO NIKITA\nCaricamento..."
    await get_tree().process_frame
    await get_tree().process_frame
    var errors: Array[String] = []
    var game_script: GDScript = null
    for n in SCRIPTS:
        label.text = "LUCIFERO CONTRO NIKITA\nCaricamento: " + n
        await get_tree().process_frame
        var sc = load("res://scripts/%s.gd" % n)
        if sc == null or not (sc is GDScript) or not sc.can_instantiate():
            errors.append(n + ".gd")
        elif n == "game_2d":
            game_script = sc
    if not errors.is_empty() or game_script == null:
        label.text = "ERRORE negli script:\n" + "\n".join(errors) + "\n\nMandami questo elenco."
        return
    if not ResourceLoader.exists("res://assets/atlas.png"):
        label.text = "ERRORE: manca assets/atlas.png\n(carica anche la cartella assets)\n\nMandami questo messaggio."
        return
    label.text = "LUCIFERO CONTRO NIKITA\nCostruzione del percorso..."
    await get_tree().process_frame
    await get_tree().process_frame
    game = game_script.new()
    add_child(game)
    await get_tree().process_frame
    await get_tree().process_frame
    if game.has_method("is_ready_ok") and not game.is_ready_ok():
        label.text = "ERRORE all'avvio.\nUltimo passo riuscito: " + last_step + "\n\nMandami questo testo."
        return
    overlay.visible = false

# Chiamato dal gioco durante l'avvio per indicare a che punto e'.
func step(text: String) -> void:
    last_step = text
