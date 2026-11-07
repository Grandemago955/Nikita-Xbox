extends RefCounted
# Carica le immagini dall'atlante unico (assets/atlas.png); se manca, prova i file singoli.

const Data := preload("res://scripts/atlas_data.gd")
static var cache: Dictionary = {}
static var atlas: Texture2D = null
static var tried := false

static func get_tex(n: String) -> Texture2D:
    if cache.has(n):
        return cache[n]
    var tx: Texture2D = null
    if not tried:
        tried = true
        if ResourceLoader.exists("res://assets/atlas.png"):
            atlas = load("res://assets/atlas.png")
    if atlas != null and Data.R.has(n):
        var r: Array = Data.R[n]
        var at := AtlasTexture.new()
        at.atlas = atlas
        at.region = Rect2(float(r[0]), float(r[1]), float(r[2]), float(r[3]))
        tx = at
    elif ResourceLoader.exists("res://assets/" + n + ".png"):
        tx = load("res://assets/" + n + ".png")
    cache[n] = tx
    return tx

static func missing_count() -> int:
    var c := 0
    for n in Data.R.keys():
        if get_tex(str(n)) == null:
            c += 1
    return c
