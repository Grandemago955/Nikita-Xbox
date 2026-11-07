extends Node2D
# Sfondo a parallasse (mode 0) e meteo in primo piano (mode 1). Si disegna da solo in coordinate schermo.

var W := 960.0
var H := 540.0
const TexLib := preload("res://scripts/texlib.gd")
const A := "res://assets/"

const PAL := [
    {"top": Color(0.40, 0.66, 0.92), "bot": Color(0.82, 0.92, 0.96), "far": Color(0.55, 0.70, 0.74), "mid": Color(0.32, 0.55, 0.40)},
    {"top": Color(0.58, 0.68, 0.82), "bot": Color(0.90, 0.94, 0.98), "far": Color(0.72, 0.78, 0.88), "mid": Color(0.55, 0.64, 0.76)},
    {"top": Color(0.46, 0.52, 0.62), "bot": Color(0.72, 0.76, 0.80), "far": Color(0.52, 0.58, 0.64), "mid": Color(0.38, 0.44, 0.50)},
    {"top": Color(0.08, 0.13, 0.22), "bot": Color(0.18, 0.34, 0.44), "far": Color(0.12, 0.22, 0.32), "mid": Color(0.09, 0.17, 0.25)},
    {"top": Color(0.93, 0.58, 0.36), "bot": Color(1.0, 0.86, 0.62), "far": Color(0.78, 0.46, 0.38), "mid": Color(0.62, 0.34, 0.26)},
    {"top": Color(0.28, 0.40, 0.80), "bot": Color(0.98, 0.80, 0.86), "far": Color(0.62, 0.62, 0.86), "mid": Color(0.48, 0.50, 0.76)},
    {"top": Color(0.04, 0.04, 0.08), "bot": Color(0.13, 0.10, 0.20), "far": Color(0.15, 0.12, 0.24), "mid": Color(0.10, 0.09, 0.17)},
    {"top": Color(0.01, 0.02, 0.07), "bot": Color(0.06, 0.09, 0.24), "far": Color(0.30, 0.31, 0.41), "mid": Color(0.22, 0.23, 0.32)},
]
const BG_TREES := {
    0: ["pine", "oak", "birch", "pine"],
    1: ["pine_snow", "pine_snow", "pine_snow"],
    2: ["house", "pine", "lamp", "birch"],
    3: ["crystal", "crystal", "rock_s"],
    4: ["mesa", "cactus", "mesa", "deadtree"],
    5: ["tower", "pillar", "banner", "cloudpuff"],
    6: ["stalagmite", "crystal", "stalagmite", "glowshroom"],
    7: ["wreck_rocket", "satellite", "antenna", "moonrock", "ufo_wreck"],
}

var mode := 0
var bonus := 0.0
var cam := Vector2(0, 0)
var t := 0.0
var sa := 0
var sb := 0
var mix := 0.0
var w_fog := 0.0
var w_snow := 0.0
var w_rain := 0.0
var w_mist := 0.0
var w_sand := 0.0
var sand: Array = []
var tex_cache := {}
var flakes: Array = []
var drops: Array = []
var puffs: Array = []
var flash := 0.0
var flash_t := 4.0

func _ready() -> void:
    if mode == 1:
        for i in range(90):
            flakes.append(Vector3(randf() * W, randf() * H, randf_range(1.5, 4.0)))
        for i in range(120):
            drops.append(Vector3(randf() * W, randf() * H, randf_range(0.7, 1.3)))
        for i in range(90):
            sand.append(Vector3(randf() * W, randf() * H, randf_range(0.6, 1.4)))
        for i in range(7):
            puffs.append(Vector3(randf() * W, randf_range(120.0, 460.0), randf_range(160.0, 300.0)))

func _tex(n: String) -> Texture2D:
    return TexLib.get_tex(n)

func tick(dt: float) -> void:
    t += dt
    if mode == 1:
        for i in range(flakes.size()):
            var f: Vector3 = flakes[i]
            f.x += (sin(t * 0.8 + f.z * 3.0) * 14.0 - 24.0) * dt
            f.y += (40.0 + f.z * 22.0) * dt
            if f.y > H + 6.0:
                f.y = -6.0
                f.x = randf() * W
            if f.x < -6.0:
                f.x += W + 12.0
            flakes[i] = f
        for j in range(drops.size()):
            var d: Vector3 = drops[j]
            d.x -= 120.0 * d.z * dt
            d.y += 760.0 * d.z * dt
            if d.y > H:
                d.y = -20.0
                d.x = randf() * (W + 160.0)
            drops[j] = d
        for q in range(sand.size()):
            var sd: Vector3 = sand[q]
            sd.x += 900.0 * sd.z * dt
            sd.y += sin(t * 2.0 + sd.z * 5.0) * 20.0 * dt
            if sd.x > W + 40.0:
                sd.x = -40.0
                sd.y = randf() * H
            sand[q] = sd
        for k in range(puffs.size()):
            var p: Vector3 = puffs[k]
            p.x += 10.0 * dt
            if p.x - p.z > W:
                p.x = -p.z
            puffs[k] = p
        if w_rain > 0.5:
            flash_t -= dt
            if flash_t <= 0.0:
                flash = 0.35
                flash_t = randf_range(6.0, 14.0)
        flash = maxf(0.0, flash - dt * 0.9)
    queue_redraw()

func _pal(key: String) -> Color:
    var a: Color = PAL[sa][key]
    var b: Color = PAL[sb][key]
    return a.lerp(b, mix)

func _draw() -> void:
    if mode == 0:
        _draw_bg()
    else:
        _draw_weather()

func _hill_pts(par: float, base: float, amp: float, f1: float, f2: float, ph: float, par_y: float) -> PackedVector2Array:
    var pts := PackedVector2Array()
    var ox := cam.x * par
    var oy := (cam.y - 270.0) * par_y
    var x := 0.0
    while x <= W + 24.0:
        var wx := x + ox
        var y := base - oy + amp * (sin(wx * f1 + ph) + 0.5 * sin(wx * f2 + ph * 1.7))
        pts.append(Vector2(x, y))
        x += 24.0
    return pts

func _fill_under(pts: PackedVector2Array, col: Color) -> void:
    var poly := PackedVector2Array(pts)
    poly.append(Vector2(W + 24.0, H + 40.0))
    poly.append(Vector2(0.0, H + 40.0))
    draw_colored_polygon(poly, col)

func _draw_bonus() -> void:
    var top := Color(0.02, 0.03, 0.16)
    var bot := Color(0.22, 0.1, 0.42)
    draw_polygon(PackedVector2Array([Vector2(0, 0), Vector2(W, 0), Vector2(W, H), Vector2(0, H)]),
        PackedColorArray([top, top, bot, bot]))
    var cols := [Color(0.6, 0.3, 1.0), Color(0.2, 0.6, 1.0), Color(1.0, 0.4, 0.7)]
    for i in range(6):
        var cx := fposmod(_h(i * 13 + 5) * (W + 400.0) - cam.x * 0.03, W + 400.0) - 200.0
        var cy := 60.0 + _h(i * 17 + 9) * (H * 0.6)
        var cc: Color = cols[i % 3]
        for g in range(5):
            draw_circle(Vector2(cx, cy), 150.0 - 24.0 * float(g), Color(cc.r, cc.g, cc.b, 0.05))
    _draw_stars(1.0)
    for i in range(70):
        var hx := _h(i * 7 + 2)
        var hy := _h(i * 11 + 4)
        var sx := fposmod(hx * (W + 300.0) - cam.x * 0.06, W + 300.0) - 150.0
        var tw := 0.5 + 0.5 * sin(t * (1.5 + hx * 3.0) + float(i))
        draw_circle(Vector2(sx, hy * H * 0.85), 1.6 + 1.6 * hx, Color(1.0, 0.95, 0.8, 0.9 * tw))
    var mp := Vector2(W * 0.8, 100.0)
    for g in range(4):
        draw_circle(mp, 70.0 - 12.0 * float(g), Color(1.0, 0.95, 0.7, 0.07))
    draw_circle(mp, 40.0, Color(1.0, 0.97, 0.82, 0.95))
    draw_circle(mp + Vector2(10, -6), 36.0, Color(0.16, 0.1, 0.35, 1.0))
    var sp := fposmod(t * 0.45, 1.0)
    if sp < 0.35:
        var q := sp / 0.35
        var p0 := Vector2(W * (0.2 + 0.5 * _h(int(t * 0.45) + 3)) + q * 260.0, 40.0 + q * 150.0)
        draw_line(p0, p0 - Vector2(60, 34), Color(1, 1, 1, 0.9 * (1.0 - q)), 3.0)

func _draw_bg() -> void:
    if bonus > 0.5:
        _draw_bonus()
        return
    var top := _pal("top")
    var bot := _pal("bot")
    draw_polygon(PackedVector2Array([Vector2(0, 0), Vector2(W, 0), Vector2(W, H), Vector2(0, H)]),
        PackedColorArray([top, top, bot, bot]))
    var starf := _stage_f(7)
    if starf > 0.02:
        _draw_stars(starf)
        _draw_earth(starf)
    # sole / luna
    var night := (sa == 3 and mix < 0.5) or (sb == 3 and mix >= 0.5)
    if night:
        draw_circle(Vector2(W * 0.78, 90), 34, Color(0.8, 0.9, 1.0, 0.25))
    else:
        var sp := Vector2(W * 0.8 - cam.x * 0.01, 96)
        var sa2 := (1.0 - 0.7 * w_rain) * (1.0 - clampf(_stage_f(3) + _stage_f(6) + _stage_f(7), 0.0, 1.0))
        for gi in range(5):
            draw_circle(sp, 120.0 - 20.0 * float(gi), Color(1.0, 0.95, 0.7, 0.05 * sa2))
        for ri in range(12):
            var an := float(ri) * TAU / 12.0 + t * 0.05
            draw_line(sp + Vector2(cos(an), sin(an)) * 52.0, sp + Vector2(cos(an), sin(an)) * (74.0 + 8.0 * sin(t + float(ri))), Color(1.0, 0.95, 0.6, 0.25 * sa2), 3.0)
        draw_circle(sp, 40, Color(1.0, 0.96, 0.75, 0.95 * sa2))
        draw_circle(sp, 32, Color(1.0, 0.99, 0.9, 0.9 * sa2))
    var cave_w := clampf(_stage_f(3) + _stage_f(6), 0.0, 1.0)
    var moon_w := _stage_f(7)
    _draw_clouds(0.04, 70.0, 1.0, 0.85 * (1.0 - cave_w) * (1.0 - moon_w), 1.3)
    var far := _pal("far")
    _draw_mountains(0.07, 340.0, 200.0, far.lerp(Color(1, 1, 1), 0.30), 1.0 - _stage_f(4) - cave_w - moon_w - _stage_f(2) * 0.5, 1.0 - cave_w)
    _draw_clouds(0.11, 150.0, 0.8, 0.8 * (1.0 - cave_w) * (1.0 - moon_w), 1.0)
    _draw_mountains(0.12, 365.0, 150.0, far.lerp(Color(1, 1, 1), 0.10), 0.7 * (1.0 - _stage_f(4) - cave_w - moon_w), 1.0 - cave_w)
    # colline lontane
    _fill_under(_hill_pts(0.12, 330.0, 36.0, 0.0031, 0.0087, 0.5, 0.25), far)
    var mid := _pal("mid")
    # sagome di alberi nello sfondo (media distanza)
    _draw_bg_objects(0.38, mid)
    _fill_under(_hill_pts(0.30, 395.0, 28.0, 0.0047, 0.0133, 2.0, 0.35), mid.lerp(far, 0.25))
    _draw_bg_objects(0.55, mid)
    _fill_under(_hill_pts(0.5, 440.0, 22.0, 0.0061, 0.0159, 4.0, 0.45), mid.darkened(0.12))
    # stalattiti e cascata nella zona 4
    var cave := cave_w
    if cave > 0.02:
        _draw_cave(cave)

func _draw_stars(a: float) -> void:
    for i in range(110):
        var hx := _h(i * 3 + 11)
        var hy := _h(i * 5 + 29)
        var sx := fposmod(hx * (W + 200.0) - cam.x * 0.02 * (0.3 + hx), W + 200.0) - 100.0
        var sy := hy * H * 0.72
        var tw := 0.55 + 0.45 * sin(t * (1.0 + hx * 3.0) + float(i))
        var r := 0.8 + 1.4 * _h(i * 7 + 3)
        draw_circle(Vector2(sx, sy), r, Color(1.0, 1.0, 0.95, a * tw * 0.9))
        if r > 1.8:
            draw_line(Vector2(sx - 5.0, sy), Vector2(sx + 5.0, sy), Color(1, 1, 1, a * tw * 0.5), 1.0)
            draw_line(Vector2(sx, sy - 5.0), Vector2(sx, sy + 5.0), Color(1, 1, 1, a * tw * 0.5), 1.0)

func _draw_earth(a: float) -> void:
    var c := Vector2(W * 0.22 - cam.x * 0.003, 118.0)
    draw_circle(c, 80.0, Color(0.4, 0.7, 1.0, 0.10 * a))
    draw_circle(c, 68.0, Color(0.4, 0.7, 1.0, 0.18 * a))
    draw_circle(c, 58.0, Color(0.14, 0.34, 0.78, a))
    var land := Color(0.25, 0.62, 0.30, a)
    draw_colored_polygon(PackedVector2Array([c + Vector2(-30, -24), c + Vector2(-8, -34), c + Vector2(6, -18), c + Vector2(-4, -4), c + Vector2(-20, 6), c + Vector2(-36, -6)]), land)
    draw_colored_polygon(PackedVector2Array([c + Vector2(14, -4), c + Vector2(36, -16), c + Vector2(44, 10), c + Vector2(28, 30), c + Vector2(12, 18)]), land)
    draw_colored_polygon(PackedVector2Array([c + Vector2(-22, 22), c + Vector2(-6, 26), c + Vector2(-12, 44), c + Vector2(-26, 36)]), land)
    var cl := Color(1, 1, 1, 0.7 * a)
    draw_circle(c + Vector2(-14, -30), 9.0, cl)
    draw_circle(c + Vector2(-2, -28), 7.0, cl)
    draw_circle(c + Vector2(30, 24), 8.0, cl)
    draw_circle(c + Vector2(40, 18), 6.0, cl)
    draw_circle(c + Vector2(-34, 12), 7.0, cl)
    draw_circle(c + Vector2(-20, -24), 14.0, Color(1, 1, 1, 0.10 * a))

func _stage_f(i: int) -> float:
    var w := 0.0
    if sa == i:
        w += 1.0 - mix
    if sb == i:
        w += mix
    return clampf(w, 0.0, 1.0)

func _draw_mountains(par: float, base: float, hmax: float, col0: Color, snow: float, al: float) -> void:
    if al < 0.03:
        return
    var col := Color(col0.r, col0.g, col0.b, al)
    var ox := cam.x * par
    var oy := (cam.y - 270.0) * par * 0.5
    var step := 150.0
    var i0 := int(floor(ox / step)) - 1
    var pts := PackedVector2Array()
    var caps: Array = []
    for i in range(i0, i0 + int(W / step) + 4):
        var hv := _h(i * 7 + int(par * 1000.0))
        var peak := (i % 2 == 0)
        var hh := hmax * (0.45 + 0.55 * hv) if peak else hmax * (0.12 + 0.2 * hv)
        var sx := float(i) * step - ox
        pts.append(Vector2(sx, base - oy - hh))
        if peak and hh > hmax * 0.7:
            caps.append(Vector3(sx, base - oy - hh, hh))
    var poly := PackedVector2Array(pts)
    poly.append(Vector2(float(i0 + int(W / step) + 3) * step - ox, H + 40.0))
    poly.append(Vector2(float(i0) * step - ox, H + 40.0))
    draw_colored_polygon(poly, col)
    if snow > 0.05:
        for c0 in caps:
            var c: Vector3 = c0
            var sw := 46.0 + (c.z / hmax) * 22.0
            draw_colored_polygon(PackedVector2Array([Vector2(c.x, c.y), Vector2(c.x + sw, c.y + sw * 1.15), Vector2(c.x + sw * 0.4, c.y + sw * 0.9), Vector2(c.x, c.y + sw * 1.3), Vector2(c.x - sw * 0.5, c.y + sw * 0.95), Vector2(c.x - sw, c.y + sw * 1.15)]), Color(0.96, 0.98, 1.0, 0.9 * snow))

func _draw_clouds(par: float, y0: float, sc: float, al: float, drift: float) -> void:
    if al < 0.03:
        return
    var spacing := 520.0
    var ox := cam.x * par + t * 12.0 * drift
    var i0 := int(floor(ox / spacing)) - 1
    var rain := _stage_f(2)
    var ss := _stage_f(4)
    var tint := Color(1, 1, 1).lerp(Color(0.62, 0.66, 0.74), rain).lerp(Color(1.0, 0.82, 0.70), ss * 0.8)
    for i in range(i0, i0 + int(W / spacing) + 3):
        var hv := _h(i * 5 + int(y0))
        var cx := float(i) * spacing + hv * 200.0 - ox
        var cy := y0 + hv * 60.0 - (cam.y - 270.0) * par * 0.3
        var r := (34.0 + 22.0 * hv) * sc
        var col := Color(tint.r, tint.g, tint.b, al)
        draw_circle(Vector2(cx, cy), r, col)
        draw_circle(Vector2(cx + r * 1.0, cy + r * 0.15), r * 0.82, col)
        draw_circle(Vector2(cx - r * 0.95, cy + r * 0.2), r * 0.72, col)
        draw_circle(Vector2(cx + r * 0.2, cy - r * 0.45), r * 0.78, col)
        draw_rect(Rect2(cx - r * 1.6, cy + r * 0.2, r * 3.4, r * 0.62), col)
        draw_circle(Vector2(cx + r * 1.7, cy + r * 0.5), r * 0.46, col)
        draw_circle(Vector2(cx - r * 1.7, cy + r * 0.5), r * 0.46, col)

func _h(i: int) -> float:
    return fposmod(sin(float(i) * 12.9898 + 4.1414) * 43758.5453, 1.0)

func _draw_bg_objects(par: float, tint: Color) -> void:
    var spacing := 230.0 if par < 0.5 else 310.0
    var ox := cam.x * par
    var oy := (cam.y - 270.0) * (0.36 if par < 0.5 else 0.46)
    var i0 := int(floor(ox / spacing)) - 1
    var base := 372.0 if par < 0.5 else 424.0
    for pass_i in range(2):
        var st := sa if pass_i == 0 else sb
        var al := (1.0 - mix) if pass_i == 0 else mix
        if al < 0.02:
            continue
        var list: Array = BG_TREES[st]
        for i in range(i0, i0 + 6):
            var hv := _h(i + int(par * 100.0))
            var tn: String = list[int(hv * 997.0) % list.size()]
            var tx := _tex(tn)
            if tx == null:
                continue
            var sc := (0.55 + 0.35 * _h(i * 3 + 1)) * (0.8 if par < 0.5 else 1.0)
            var wx := float(i) * spacing + hv * 90.0
            var sx := wx - ox
            var w := float(tx.get_width()) * sc
            var h := float(tx.get_height()) * sc
            var yb := base - oy + 8.0 * sin(wx * 0.005)
            var col := Color(1, 1, 1, al).lerp(Color(tint.r, tint.g, tint.b, al), 0.55 if par < 0.5 else 0.35)
            draw_texture_rect(tx, Rect2(sx - w * 0.5, yb - h, w, h), false, col)

func _draw_cave(a: float) -> void:
    draw_rect(Rect2(0, 0, W, H * 0.2), Color(0, 0, 0, 0.35 * a))
    var tx := _tex("stalactite")
    var ox := cam.x * 0.7
    var i0 := int(floor(ox / 170.0)) - 1
    for i in range(i0, i0 + 8):
        var hv := _h(i + 77)
        var sc := 0.7 + hv * 1.0
        var sx := float(i) * 170.0 + hv * 80.0 - ox
        if tx != null:
            draw_texture_rect(tx, Rect2(sx - 25.0 * sc, -20.0, 50.0 * sc, 110.0 * sc), false, Color(0.6, 0.65, 0.8, a))
    # cascata
    var oxw := cam.x * 0.45
    var j0 := int(floor(oxw / 900.0)) - 1
    for j in range(j0, j0 + 3):
        var sx2 := float(j) * 900.0 + 300.0 - oxw
        draw_rect(Rect2(sx2, 0, 70, 420), Color(0.75, 0.92, 1.0, 0.45 * a))
        for k in range(9):
            var yy := fposmod(t * (240.0 + 30.0 * float(k)) + float(k) * 53.0, 420.0)
            draw_rect(Rect2(sx2 + 6.0 + float(k) * 7.0, yy, 3.0, 36.0), Color(1, 1, 1, 0.55 * a))
        draw_circle(Vector2(sx2 + 35.0, 420), 50.0 + 6.0 * sin(t * 3.0), Color(0.9, 0.98, 1.0, 0.28 * a))

func _draw_weather() -> void:
    if w_sand > 0.02:
        draw_rect(Rect2(0, 0, W, H), Color(0.85, 0.6, 0.35, 0.16 * w_sand))
        for q in sand:
            draw_line(Vector2(q.x, q.y), Vector2(q.x - 26.0 * q.z, q.y + 2.0), Color(0.9, 0.7, 0.45, 0.5 * w_sand), 1.6)
    if w_fog > 0.02 or w_mist > 0.02:
        var fa := w_fog * 0.40 + w_mist * 0.28
        var fc := Color(0.92, 0.94, 0.96, fa) if w_mist < 0.2 else Color(0.5, 0.75, 0.85, fa)
        draw_rect(Rect2(0, 0, W, H), Color(fc.r, fc.g, fc.b, fa * 0.5))
        for p in puffs:
            draw_circle(Vector2(p.x, p.y), p.z, Color(fc.r, fc.g, fc.b, fa * 0.30))
            draw_circle(Vector2(p.x + p.z * 0.6, p.y + 10.0), p.z * 0.7, Color(fc.r, fc.g, fc.b, fa * 0.24))
    if w_snow > 0.02:
        var n := int(float(flakes.size()) * w_snow)
        for i in range(n):
            var f: Vector3 = flakes[i]
            draw_circle(Vector2(f.x, f.y), f.z, Color(1, 1, 1, 0.9))
    if w_rain > 0.02:
        var n2 := int(float(drops.size()) * w_rain)
        draw_rect(Rect2(0, 0, W, H), Color(0.1, 0.14, 0.22, 0.18 * w_rain))
        for j in range(n2):
            var d: Vector3 = drops[j]
            draw_line(Vector2(d.x, d.y), Vector2(d.x - 8.0 * d.z, d.y + 24.0 * d.z), Color(0.8, 0.88, 1.0, 0.55), 1.6)
        if flash > 0.0:
            draw_rect(Rect2(0, 0, W, H), Color(1, 1, 1, flash))
