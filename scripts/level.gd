extends RefCounted
# Dati del percorso (molto lungo): terreno, burroni, torrenti, ostacoli, piattaforme alte,
# molle, pedane di scatto, premi nascosti, decorazioni, animali. Tutto diviso in blocchi (chunk).

const ZB := [0.0, 72000.0, 150000.0, 216000.0, 300000.0, 375000.0, 465000.0, 547500.0, 637500.0]
const TOTAL := 637500.0
const NS := 8
const CEIL_H := 400.0
const CH := 800.0
const BASE_Y := 420.0
const AMP := [34.0, 56.0, 10.0, 40.0, 52.0, 44.0, 12.0, 30.0]

var gaps: Array = []
var gx0 := PackedFloat64Array()
var streams: Array = []
var sx0 := PackedFloat64Array()
var solids: Array = []
var ox0 := PackedFloat64Array()
var brambles: Array = []
var bx0a := PackedFloat64Array()
var plats: Array = []
var px0 := PackedFloat64Array()
var cps: Array = []
var fauna: Array = []
var chunks := {}
var craters: Array = []
var cr0 := PackedFloat64Array()
var narrows: Array = []
var nr0 := PackedFloat64Array()
var gem_total := 0
var rng := RandomNumberGenerator.new()

func stage_of(x: float) -> int:
    for i in range(NS - 1, 0, -1):
        if x >= ZB[i]:
            return i
    return 0

func stage_mix(x: float) -> Array:
    var s := stage_of(x)
    var local := x - float(ZB[s])
    var ln: float = float(ZB[s + 1]) - float(ZB[s])
    if local < 350.0 and s > 0:
        return [s - 1, s, clampf(0.5 + local / 700.0, 0.0, 1.0)]
    if local > ln - 350.0 and s < NS - 1:
        return [s, s + 1, clampf((local - (ln - 350.0)) / 700.0, 0.0, 1.0)]
    return [s, s, 0.0]

func amp_at(x: float) -> float:
    var s := stage_of(x)
    var local := x - float(ZB[s])
    var ln: float = float(ZB[s + 1]) - float(ZB[s])
    var a: float = AMP[s]
    if local < 400.0 and s > 0:
        a = lerpf(AMP[s - 1], a, smoothstep(0.0, 1.0, 0.5 + local / 800.0))
    elif local > ln - 400.0 and s < NS - 1:
        a = lerpf(a, AMP[s + 1], smoothstep(0.0, 1.0, 0.5 - (ln - local) / 800.0))
    return a

func hill_y(x: float) -> float:
    var ramp := smoothstep(0.0, 1.0, clampf(x / 600.0, 0.0, 1.0))
    var h := sin(x * 0.0035) + 0.55 * sin(x * 0.0097 + 1.3) - 0.53
    return BASE_Y + amp_at(x) * h * ramp + crater_dy(x)

func crater_dy(x: float) -> float:
    if x < float(ZB[7]) - 300.0 or craters.is_empty():
        return 0.0
    var dy := 0.0
    var r := _rng_idx(cr0, x, 700.0)
    for i in range(r.x, r.y):
        var c: Dictionary = craters[i]
        var u: float = (x - float(c.x)) / float(c.r)
        if absf(u) < 1.0:
            dy += float(c.d) * 0.5 * (1.0 + cos(PI * u))
    return dy

func ceil_y(x: float) -> float:
    # soffitto della zona grotte (si ferma solo chi sale dal basso); -INF = nessun soffitto
    var z0: float = ZB[6]
    var z1: float = ZB[7]
    if x < z0 or x > z1:
        return -INF
    var h := CEIL_H
    var ramp_in := clampf((x - z0) / 600.0, 0.0, 1.0)
    var ramp_out := clampf((z1 - x) / 600.0, 0.0, 1.0)
    h += (1.0 - minf(ramp_in, ramp_out)) * 900.0
    var r := _rng_idx(nr0, x, 1300.0)
    for i in range(r.x, r.y):
        var n: Dictionary = narrows[i]
        if x > n.x0 and x < n.x1:
            var k := smoothstep(0.0, 1.0, clampf(minf(x - float(n.x0), float(n.x1) - x) / 160.0, 0.0, 1.0))
            h = lerpf(h, float(n.h), k)
    return hill_y(x) - h

func _rng_idx(xs: PackedFloat64Array, x: float, maxlen: float) -> Vector2i:
    return Vector2i(xs.bsearch(x - maxlen, true), xs.bsearch(x, false))

func gap_at(x: float):
    var r := _rng_idx(gx0, x, 1000.0)
    for i in range(r.x, r.y):
        var g: Dictionary = gaps[i]
        if x > g.x0 and x < g.x1:
            return g
    return null

func in_gap(x: float) -> bool:
    return gap_at(x) != null

func stream_at(x: float) -> bool:
    var r := _rng_idx(sx0, x, 600.0)
    for i in range(r.x, r.y):
        var s: Dictionary = streams[i]
        if x > s.x0 and x < s.x1:
            return true
    return false

func raw_y(x: float) -> float:
    var y := hill_y(x)
    var r := _rng_idx(sx0, x, 600.0)
    for i in range(r.x, r.y):
        var s: Dictionary = streams[i]
        if x > s.x0 and x < s.x1:
            var u: float = (x - s.x0) / (s.x1 - s.x0)
            y += 14.0 * sin(u * PI)
    return y

func ground_y(x: float) -> float:
    var g = gap_at(x)
    if g != null:
        if g.bridge:
            var u0: float = (x - g.x0) / (g.x1 - g.x0)
            return lerpf(hill_y(g.x0), hill_y(g.x1), u0)
        return INF
    return raw_y(x)

func solids_near(x: float, margin: float) -> Array:
    var out: Array = []
    var r := _rng_idx(ox0, x + margin, 260.0 + margin)
    for i in range(r.x, r.y):
        var s: Dictionary = solids[i]
        if x >= s.x0 - margin and x <= s.x1 + margin:
            out.append(s)
    return out

func brambles_near(x: float, margin: float) -> Array:
    var out: Array = []
    var r := _rng_idx(bx0a, x + margin, 260.0 + margin)
    for i in range(r.x, r.y):
        var b: Dictionary = brambles[i]
        if x >= b.x0 - margin and x <= b.x1 + margin:
            out.append(b)
    return out

func floor_y(x: float, feet: float) -> float:
    var g := ground_y(x)
    var rs := _rng_idx(ox0, x + 2.0, 262.0)
    for i in range(rs.x, rs.y):
        var s: Dictionary = solids[i]
        if x >= s.x0 - 2.0 and x <= s.x1 + 2.0 and feet <= s.top + 10.0:
            g = minf(g, s.top)
    var rp := _rng_idx(px0, x, 400.0)
    for j in range(rp.x, rp.y):
        var p: Dictionary = plats[j]
        if x >= p.x0 and x <= p.x1 and feet <= p.y + 10.0:
            g = minf(g, p.y)
    return g

func next_obstacle(x: float, dist: float) -> bool:
    # c'e' un ostacolo o burrone entro "dist" davanti a x ?
    for s in solids_near(x + dist * 0.5, dist * 0.5 + 10.0):
        if s.x0 > x - 6.0 and s.x0 < x + dist:
            return true
    for b in brambles_near(x + dist * 0.5, dist * 0.5 + 10.0):
        if b.x0 > x - 6.0 and b.x0 < x + dist:
            return true
    return false

# ------------------------------------------------------------------ generazione

func _chunk(x: float) -> Dictionary:
    var ci := int(floor(x / CH))
    if not chunks.has(ci):
        chunks[ci] = {"decor": [], "solids": [], "brambles": [], "bones": [], "hearts": [], "gems": [],
            "springs": [], "pads": [], "flags": [], "plats": [], "gaps": [], "signs": [], "bolts": [], "stars": [], "portals": [], "zsigns": []}
    return chunks[ci]

func _free_ground(x0: float, x1: float) -> bool:
    for g in gaps:
        if x1 > g.x0 - 120.0 and x0 < g.x1 + 120.0:
            return false
    for s in streams:
        if x1 > s.x0 - 80.0 and x0 < s.x1 + 80.0:
            return false
    return true

func _recent_free(x0: float, x1: float) -> bool:
    # controlla solo gli ultimi elementi (la generazione procede in avanti)
    var n := gaps.size()
    for i in range(maxi(0, n - 3), n):
        var g: Dictionary = gaps[i]
        if x1 > g.x0 - 120.0 and x0 < g.x1 + 120.0:
            return false
    n = streams.size()
    for i2 in range(maxi(0, n - 3), n):
        var s: Dictionary = streams[i2]
        if x1 > s.x0 - 80.0 and x0 < s.x1 + 80.0:
            return false
    return true

func _bone(x: float, y: float) -> void:
    _chunk(x).bones.append({"x": x, "y": y, "got": false, "node": null})

func _add_solid(kind: String, x0: float, w: float, h: float) -> void:
    var cx := x0 + w * 0.5
    var gy := hill_y(cx)
    var d := {"kind": kind, "x0": x0, "x1": x0 + w, "top": gy - h, "cx": cx, "gy": gy, "h": h}
    solids.append(d)
    ox0.append(x0)
    _chunk(cx).solids.append(d)

func _add_plat(x0: float, w: float, y: float, surf: bool = false) -> void:
    var d := {"x0": x0, "x1": x0 + w, "y": y, "surf": surf}
    plats.append(d)
    px0.append(x0)
    _chunk(x0 + w * 0.5).plats.append(d)

func _add_gap(x0: float, x1: float, bridge: bool) -> void:
    var d := {"x0": x0, "x1": x1, "bridge": bridge}
    gaps.append(d)
    gx0.append(x0)
    _chunk(x0).gaps.append(d)

func _add_gem(x: float, y: float) -> void:
    _chunk(x).gems.append({"x": x, "y": y, "got": false, "node": null})
    gem_total += 1

func generate() -> void:
    rng.seed = 20261106
    var weights := [
        [["boulder", 16], ["log", 14], ["bramble", 12], ["stream", 10], ["gap", 10], ["route", 10], ["tower", 6], ["bushgem", 5], ["pad", 8], ["field", 5], ["none", 4]],
        [["boulder", 14], ["log", 6], ["bramble", 6], ["gap", 14], ["bridge", 12], ["stream", 4], ["route", 12], ["tower", 8], ["bushgem", 5], ["pad", 8], ["field", 6], ["none", 5]],
        [["log", 16], ["boulder", 8], ["fence", 12], ["gap", 10], ["stream", 12], ["bramble", 4], ["route", 12], ["tower", 6], ["bushgem", 6], ["pad", 10], ["field", 5], ["none", 5]],
        [["boulder", 16], ["gap", 16], ["bridge", 14], ["stream", 6], ["bramble", 6], ["route", 12], ["tower", 8], ["bushgem", 6], ["pad", 8], ["field", 5], ["none", 5]],
        [["boulder", 14], ["bramble", 12], ["gap", 20], ["bridge", 14], ["route", 14], ["tower", 9], ["bushgem", 6], ["pad", 10], ["field", 5], ["none", 4]],
        [["boulder", 8], ["fence", 10], ["gap", 22], ["bridge", 18], ["route", 16], ["tower", 10], ["bushgem", 6], ["pad", 12], ["field", 5], ["none", 4]],
        [["stream", 14], ["gap", 14], ["bridge", 9], ["narrow", 13], ["gallery", 11], ["boulder", 8], ["bramble", 9], ["route", 10], ["bushgem", 6], ["pad", 8], ["field", 3], ["none", 3]],
        [["wreck", 20], ["gap", 14], ["bridge", 6], ["bramble", 12], ["route", 10], ["tower", 9], ["bushgem", 6], ["pad", 10], ["field", 3], ["none", 3]],
    ]
    var marks: Array = []
    for s in range(NS):
        var z0: float = ZB[s]
        var zl: float = float(ZB[s + 1]) - z0
        if s > 0:
            marks.append(z0 + 220.0)
        marks.append(z0 + zl * 0.25)
        marks.append(z0 + zl * 0.5)
        marks.append(z0 + zl * 0.75)
    var cxx: float = float(ZB[7]) + 900.0
    while cxx < TOTAL - 1800.0:
        var cr := rng.randf_range(170.0, 330.0)
        craters.append({"x": cxx, "r": cr, "d": rng.randf_range(34.0, 78.0)})
        cr0.append(cxx - cr)
        cxx += cr * 2.0 + rng.randf_range(500.0, 1500.0)
    cps.append(250.0)
    var ci_mark := 0
    var x := 900.0
    var end_x := TOTAL - 1500.0
    while x < end_x:
        if ci_mark < marks.size() and x >= float(marks[ci_mark]):
            cps.append(x)
            _chunk(x).flags.append({"x": x, "on": false, "node": null, "idx": cps.size() - 1})
            ci_mark += 1
            x += 700.0
            continue
        var s2 := stage_of(x)
        var tab: Array = weights[s2]
        var total_w := 0
        for e in tab:
            total_w += int(e[1])
        var roll := rng.randi_range(0, total_w - 1)
        var kind := "none"
        for e2 in tab:
            roll -= int(e2[1])
            if roll < 0:
                kind = str(e2[0])
                break
        var length := 80.0
        var arcs := true
        var bush_tex := "bush"
        if s2 == 4:
            bush_tex = "cactus"
        elif s2 == 5:
            bush_tex = "cloudpuff"
        elif s2 == 6:
            bush_tex = "glowshroom"
        elif s2 == 7:
            bush_tex = "moonrock"
        match kind:
            "boulder":
                var nb := rng.randi_range(1, 3)
                for i in range(nb):
                    _add_solid("boulder", x + float(i) * 330.0, 88.0, 66.0)
                length = 88.0 + float(nb - 1) * 330.0
            "wreck":
                var nw := rng.randi_range(1, 3)
                for i in range(nw):
                    var wk := rng.randi_range(0, 3)
                    if wk == 0:
                        _add_solid("moonrock", x + float(i) * 330.0, 100.0, 66.0)
                    elif wk == 1:
                        _add_solid("wreck_a", x + float(i) * 330.0, 114.0, 64.0)
                    elif wk == 2:
                        _add_solid("wreck_b", x + float(i) * 330.0, 108.0, 74.0)
                    else:
                        _add_solid("wreck_c", x + float(i) * 330.0, 114.0, 66.0)
                length = 110.0 + float(nw - 1) * 330.0
            "narrow":
                length = rng.randf_range(650.0, 1000.0)
                narrows.append({"x0": x, "x1": x + length, "h": rng.randf_range(172.0, 190.0)})
                nr0.append(x)
                if rng.randf() < 0.5 and _recent_free(x + 100.0, x + length - 100.0):
                    streams.append({"x0": x + length * 0.3, "x1": x + length * 0.3 + 300.0})
                    sx0.append(x + length * 0.3)
                arcs = false
                for k in range(int(length / 80.0)):
                    var bxn := x + 40.0 + float(k) * 80.0
                    if not stream_at(bxn):
                        _bone(bxn, hill_y(bxn) - 40.0)
            "gallery":
                arcs = false
                var gsx := x + 260.0
                _chunk(gsx).springs.append({"x": gsx, "y": hill_y(gsx), "t": 0.0, "node": null, "big": true})
                var gy0 := hill_y(gsx) - 500.0
                _add_plat(gsx - 260.0, 1350.0, gy0, true)
                for k in range(9):
                    _bone(gsx - 100.0 + 120.0 * float(k), gy0 - 44.0)
                var gx2 := gsx + 1090.0
                var nplat := rng.randi_range(2, 4)
                for i in range(nplat):
                    var gw := rng.randf_range(260.0, 420.0)
                    gx2 += rng.randf_range(150.0, 250.0)
                    _add_plat(gx2, gw, gy0 - rng.randf_range(0.0, 50.0), true)
                    for k in range(3):
                        _bone(gx2 + gw * (0.25 + 0.25 * float(k)), gy0 - 44.0)
                    if i == nplat - 1:
                        _add_gem(gx2 + gw * 0.5, gy0 - 50.0)
                        _chunk(gx2).hearts.append({"x": gx2 + gw * 0.5 + 60.0, "y": gy0 - 50.0, "got": false, "node": null})
                    gx2 += gw
                length = gx2 - x + 100.0
            "log":
                var nl := rng.randi_range(1, 2)
                for i in range(nl):
                    _add_solid("log", x + float(i) * 360.0, 120.0, 44.0)
                length = 120.0 + float(nl - 1) * 360.0
            "fence":
                var nf := rng.randi_range(1, 3)
                for i in range(nf):
                    _add_solid("fence", x + float(i) * 300.0, 80.0, 44.0)
                length = 80.0 + float(nf - 1) * 300.0
            "bramble":
                length = rng.randf_range(110.0, 200.0)
                var btex := "bramble"
                if s2 == 6:
                    btex = "spikes_cave"
                elif s2 == 7:
                    btex = "scrap"
                var d := {"x0": x, "x1": x + length, "top": hill_y(x + length * 0.5) - 30.0, "cx": x + length * 0.5, "w": length, "tex": btex}
                brambles.append(d)
                bx0a.append(x)
                _chunk(x + length * 0.5).brambles.append(d)
            "stream":
                length = rng.randf_range(260.0, 440.0)
                if _recent_free(x, x + length):
                    streams.append({"x0": x, "x1": x + length})
                    sx0.append(x)
            "gap":
                length = rng.randf_range(220.0, 330.0 if s2 < 3 else 370.0)
                if _recent_free(x - 100.0, x + length + 100.0):
                    _add_gap(x, x + length, false)
            "bridge":
                length = rng.randf_range(520.0, 820.0)
                if _recent_free(x - 100.0, x + length + 100.0):
                    _add_gap(x, x + length, true)
            "route":
                arcs = false
                var n := rng.randi_range(5, 10)
                var dx := rng.randf_range(300.0, 380.0)
                length = float(n) * dx
                if rng.randf() < 0.5 and _recent_free(x + length * 0.25 - 100.0, x + length * 0.75 + 100.0):
                    _add_gap(x + length * 0.25, x + length * 0.25 + rng.randf_range(260.0, 330.0), false)
                for i in range(n):
                    var pw := rng.randf_range(170.0, 240.0)
                    var px := x + float(i) * dx
                    var py := hill_y(px + pw * 0.5) - (95.0 if i == 0 else rng.randf_range(120.0, 190.0))
                    _add_plat(px, pw, py)
                    for k in range(3):
                        _bone(px + pw * (0.25 + 0.25 * float(k)), py - 44.0)
                    if i == n / 2 and rng.randf() < 0.5:
                        _chunk(px).hearts.append({"x": px + pw * 0.5, "y": py - 80.0, "got": false, "node": null})
                if rng.randf() < 0.7:
                    var lx := x + float(n - 1) * dx + 100.0
                    _add_gem(lx, hill_y(lx) - 190.0 - 44.0)
            "tower":
                arcs = false
                length = 900.0
                var spx := x
                _chunk(spx).springs.append({"x": spx, "y": hill_y(spx), "t": 0.0, "node": null})
                var tx := x + rng.randf_range(300.0, 420.0)
                var ty := hill_y(tx) - rng.randf_range(250.0, 290.0)
                _add_plat(tx, 300.0, ty)
                _add_gem(tx + 150.0, ty - 40.0)
                for k in range(4):
                    _bone(tx + 30.0 + 50.0 * float(k), ty - 44.0)
                if rng.randf() < 0.4:
                    _chunk(tx).hearts.append({"x": tx + 250.0, "y": ty - 60.0, "got": false, "node": null})
            "bushgem":
                arcs = false
                length = 200.0
                _chunk(x).decor.append({"tex": bush_tex, "x": x + 30.0, "y": hill_y(x + 30.0) + 6.0, "sc": 1.5 if s2 < 4 else 1.2, "z": 6, "flip": false})
                _add_gem(x + 30.0, hill_y(x + 30.0) - 34.0)
                for k in range(4):
                    _bone(x - 200.0 - 60.0 * float(k), hill_y(x - 200.0) - 40.0)
            "pad":
                arcs = false
                var np := rng.randi_range(1, 3)
                for i in range(np):
                    var pxp := x + float(i) * 300.0
                    _chunk(pxp).pads.append({"x": pxp, "y": hill_y(pxp), "node": null})
                length = float(np) * 300.0 + 500.0
                for k in range(10):
                    var bxk := x + 150.0 + float(k) * 90.0
                    _bone(bxk, hill_y(bxk) - 40.0)
            "field":
                arcs = false
                length = rng.randf_range(900.0, 1500.0)
                var nbn := int(length / 85.0)
                for k in range(nbn):
                    var bxx := x + float(k) * 85.0
                    _bone(bxx, hill_y(bxx) - 38.0 - 10.0 * sin(float(k) * 0.5))
            _:
                length = rng.randf_range(300.0, 700.0)
        if arcs and kind != "none" and kind != "pad":
            var nn := 7
            for i3 in range(nn):
                var u := float(i3) / float(nn - 1)
                var bx := x - 90.0 + (length + 180.0) * u
                var gyb := hill_y(x + length * 0.5)
                _bone(bx, gyb - 40.0 - 120.0 * sin(u * PI))
        x += length + rng.randf_range(650.0, 1050.0) * maxf(0.52, 0.82 - 0.04 * float(s2))
    # cuori sparsi
    for s3 in range(NS):
        var z03: float = ZB[s3]
        var zl3: float = float(ZB[s3 + 1]) - z03
        var placed := 0
        var tries := 0
        while placed < int(zl3 / 8000.0) and tries < 400:
            tries += 1
            var hx := z03 + rng.randf_range(1500.0, zl3 - 1200.0)
            if _free_ground(hx - 60.0, hx + 60.0) and solids_near(hx, 150.0).is_empty() and brambles_near(hx, 150.0).is_empty():
                _chunk(hx).hearts.append({"x": hx, "y": hill_y(hx) - 62.0, "got": false, "node": null})
                placed += 1
    _gen_bolts()
    _gen_stars()
    _gen_portals()
    _gen_zsigns()
    _gen_decor()
    _gen_fauna()

func _gen_decor() -> void:
    var back := {
        0: ["oak", "pine", "birch", "bush", "pine", "oak", "fern", "mushroom"],
        1: ["pine_snow", "pine_snow", "pine_snow", "rock_s", "boulder"],
        2: ["house", "birch", "lamp", "bush", "pine", "house"],
        3: ["crystal", "rock_s", "fern", "crystal", "cactus_fern", "boulder"],
        4: ["cactus", "mesa", "cactus", "deadtree", "boulder", "rock_s"],
        5: ["pillar", "tower", "banner", "pillar", "cloudpuff", "tower"],
        6: ["stalagmite", "glowshroom", "crystal", "torch", "stalagmite", "rock_s", "boulder", "glowshroom"],
        7: ["moonrock", "wreck_rocket", "satellite", "antenna", "solarpanel", "moonflag", "ufo_wreck", "wreck_a", "moonrock"],
    }
    for s in range(NS):
        var x: float = ZB[s] + 60.0
        var xend: float = ZB[s + 1] - 40.0
        var list: Array = back[s]
        while x < xend:
            x += rng.randf_range(120.0, 270.0)
            if in_gap(x) or stream_at(x) or in_gap(x - 80.0) or in_gap(x + 80.0):
                continue
            var tex: String = list[rng.randi() % list.size()]
            var sc := rng.randf_range(0.85, 1.25)
            if tex == "house":
                sc = rng.randf_range(1.0, 1.3)
                x += 120.0
            if tex == "boulder":
                sc = rng.randf_range(0.5, 0.9)
            if tex == "wreck_rocket" or tex == "ufo_wreck":
                sc = rng.randf_range(0.7, 1.0)
                x += 220.0
            if tex == "mesa" or tex == "tower":
                sc = rng.randf_range(0.9, 1.5)
                x += 150.0
            _chunk(x).decor.append({"tex": tex, "x": x, "y": ground_y(x) + 4.0, "sc": sc, "z": -2, "flip": rng.randf() < 0.5})
        var xf: float = ZB[s]
        while xf < xend:
            xf += rng.randf_range(80.0, 200.0)
            if in_gap(xf) or stream_at(xf):
                continue
            var t2 := "grass" if s != 1 else "rock_s"
            if s == 3:
                t2 = "cactus_fern"
            elif s == 4:
                t2 = "rock_s"
            elif s == 5:
                t2 = "cloudpuff"
            elif s == 6:
                t2 = "rock_s" if rng.randf() < 0.6 else "glowshroom"
            elif s == 7:
                t2 = "rock_s"
            _chunk(xf).decor.append({"tex": t2, "x": xf, "y": ground_y(xf) + 8.0, "sc": rng.randf_range(0.8, 1.3), "z": 6, "flip": rng.randf() < 0.5})

func _gen_fauna() -> void:
    var counts := {
        0: {"deer": 4, "squirrel": 6, "bird": 6, "rabbit": 5, "fox": 2, "butterfly": 8},
        1: {"deer": 2, "bird": 3, "eagle": 4, "fox": 2},
        2: {"squirrel": 3, "bird": 5, "rabbit": 4, "butterfly": 4},
        3: {"bat": 8, "lizard": 3},
        4: {"lizard": 7, "eagle": 4, "rabbit": 3, "bird": 2},
        5: {"eagle": 3, "bird": 6, "butterfly": 6},
        6: {"bat": 9, "lizard": 3},
        7: {"drone": 6, "ufo": 3},
    }
    for s in range(NS):
        var c: Dictionary = counts[s]
        var z0: float = ZB[s]
        var zl: float = float(ZB[s + 1]) - z0
        var factor := zl / 5200.0 * 0.5
        for k in c.keys():
            for i in range(int(float(c[k]) * factor)):
                var fx := z0 + rng.randf_range(1200.0, zl - 800.0)
                if in_gap(fx) or stream_at(fx) or not solids_near(fx, 100.0).is_empty():
                    continue
                fauna.append({"kind": str(k), "x": fx, "x0": fx, "y": hill_y(fx), "vx": 0.0, "vy": 0.0, "state": 0, "node": null, "t": rng.randf() * 6.0, "stage": s})

func _gen_bolts() -> void:
    var steps := [4300.0, 4300.0, 3900.0, 3900.0, 3500.0, 3500.0, 3200.0, 3200.0]
    for s in range(NS):
        var z0: float = ZB[s]
        var zl: float = float(ZB[s + 1]) - z0
        var bx := z0 + 1800.0 + rng.randf_range(0.0, 900.0)
        while bx < z0 + zl - 1500.0:
            var tries := 0
            while tries < 8 and not (_free_ground(bx - 120.0, bx + 120.0) and solids_near(bx, 220.0).is_empty() and brambles_near(bx, 220.0).is_empty()):
                bx += 140.0
                tries += 1
            _chunk(bx).bolts.append({"x": bx, "y": hill_y(bx), "got": false, "node": null})
            for k in range(5):
                var bk := bx - 520.0 + 90.0 * float(k)
                if not in_gap(bk) and not stream_at(bk):
                    _bone(bk, hill_y(bk) - 40.0)
            bx += float(steps[s]) * rng.randf_range(0.85, 1.2)

func _gen_stars() -> void:
    for s in range(NS):
        var z0: float = ZB[s]
        var zl: float = float(ZB[s + 1]) - z0
        for ty in range(2):
            var sx := z0 + 1200.0 + 1400.0 * float(ty) + rng.randf_range(0.0, 700.0)
            while sx < z0 + zl - 1600.0:
                var tries := 0
                while tries < 10 and not (_free_ground(sx - 300.0, sx + 300.0) and solids_near(sx, 260.0).is_empty() and brambles_near(sx, 260.0).is_empty()):
                    sx += 150.0
                    tries += 1
                var gy := hill_y(sx)
                _chunk(sx).stars.append({"x": sx, "y": gy - 150.0, "t": ty, "got": false, "node": null})
                if ty == 0:
                    # premi speciali in alto, raggiungibili solo con il super salto
                    var py := gy - 300.0
                    if s == 6:
                        py = gy - 250.0
                    _add_plat(sx + 150.0, 260.0, py, false)
                    _add_gem(sx + 190.0, py - 40.0)
                    _add_gem(sx + 280.0, py - 40.0)
                    _add_gem(sx + 370.0, py - 40.0)
                    _chunk(sx + 230.0).hearts.append({"x": sx + 230.0, "y": py - 90.0, "got": false, "node": null})
                else:
                    for k in range(6):
                        var bk := sx + 260.0 + 150.0 * float(k)
                        if not in_gap(bk) and not stream_at(bk):
                            _bone(bk, hill_y(bk) - 60.0 - 40.0 * sin(float(k) * 0.5))
                sx += (5200.0 if ty == 0 else 5600.0) * rng.randf_range(0.85, 1.2) * maxf(0.8, 1.0 - 0.03 * float(s))

func _gen_portals() -> void:
    for s in range(NS):
        var z0: float = ZB[s]
        var zl: float = float(ZB[s + 1]) - z0
        for k in range(3):
            var px := z0 + zl * (0.20 + 0.30 * float(k)) + rng.randf_range(-300.0, 300.0)
            var tries := 0
            while tries < 14 and not (_free_ground(px - 300.0, px + 300.0) and solids_near(px, 260.0).is_empty() and brambles_near(px, 260.0).is_empty()):
                px += 150.0
                tries += 1
            _chunk(px).portals.append({"x": px, "y": hill_y(px) - 175.0, "got": false, "node": null})

func _gen_zsigns() -> void:
    for s in range(NS - 1):
        var sx: float = float(ZB[s + 1]) - 1000.0
        var tries := 0
        while tries < 20 and not (_free_ground(sx - 320.0, sx + 320.0) and solids_near(sx, 300.0).is_empty() and brambles_near(sx, 300.0).is_empty()):
            sx -= 150.0
            tries += 1
        _chunk(sx).zsigns.append({"x": sx, "gy": hill_y(sx), "zone": s + 1, "got": false, "spin": -1.0, "node": null})
