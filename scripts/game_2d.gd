extends Node2D
# Lucifero contro Nikita - versione 2D a scorrimento laterale (v2: percorso lungo, velocita', vie alte, segreti).

const LevelS := preload("res://scripts/level.gd")
const RigS := preload("res://scripts/rig.gd")
const BackS := preload("res://scripts/backdrop.gd")
const AudioS := preload("res://scripts/audio.gd")
const TexLib := preload("res://scripts/texlib.gd")
const A := "res://assets/"
const SAVE_PATH := "user://records2d.cfg"
const TOTAL := 637500.0
const CH := 800.0
const GRAV := 1700.0
const RUN_BASE := 565.0
const RUN_MAX := 975.0
const BOLT_CAP := 1400.0
const BOLT_TIME := 8.0
const JUMP_V := -700.0
const ZONES := ["Il Bosco", "La Montagna", "Il Borgo", "La Cascata e la Grotta", "Il Canyon", "Il Castello tra le Nuvole", "Le Grotte Profonde", "La Luna"]
const WX := [[0.45, 0.0, 0.0, 0.0, 0.0], [0.15, 1.0, 0.0, 0.0, 0.0], [0.0, 0.0, 1.0, 0.0, 0.0], [0.0, 0.0, 0.0, 0.6, 0.0], [0.0, 0.0, 0.0, 0.0, 1.0], [0.25, 0.0, 0.0, 0.0, 0.0], [0.0, 0.0, 0.0, 0.55, 0.0], [0.0, 0.0, 0.0, 0.0, 0.0]]
const GRASS := [Color(0.36, 0.68, 0.27), Color(0.92, 0.95, 0.99), Color(0.40, 0.56, 0.30), Color(0.27, 0.50, 0.46), Color(0.80, 0.52, 0.28), Color(0.95, 0.96, 1.0), Color(0.26, 0.42, 0.40), Color(0.66, 0.66, 0.72)]
const DIRT := [Color(0.45, 0.31, 0.19), Color(0.52, 0.48, 0.50), Color(0.40, 0.31, 0.26), Color(0.22, 0.22, 0.30), Color(0.55, 0.26, 0.17), Color(0.58, 0.56, 0.74), Color(0.17, 0.15, 0.22), Color(0.38, 0.38, 0.46)]
const JOY_R := 70.0
const JUMP_RAD := 68.0
const TRAP_RAD := 52.0

class Body:
    var x := 0.0
    var y := 0.0
    var vx := 0.0
    var vy := 0.0
    var on_ground := false
    var coyote := 0.0
    var face := 1
    var r := 16.0
    var stun := 0.0
    var landed_v := 0.0
    var jumped := false
    var h := 95.0
    var noceil := 0.0

var lv
var audio
var bg
var wx_node
var world: Node2D
var water: Node2D
var fx: Node2D
var ui: Control
var cam: Camera2D
var hero_rig
var wolf_rig
var hero := Body.new()
var wolf := Body.new()
var ok := false
var vw := 960.0
var vh := 540.0

var state := "menu"
var state_t := 0.0
var ready_len := 2.6
var lives := 3
var bones_n := 0
var gems_n := 0
var traps := 2
var trap_cd := 0.0
var score_f := 0.0
var max_x := 0.0
var run_time := 0.0
var cp_x := 250.0
var stage := 0
var banner_t := 0.0
var hurt_t := 0.0
var bolt_t := 0.0
var sjump_t := 0.0
var bplats: Array = []
var spin_sign: Dictionary = {}
var bballs: Array = []
var balls_t := 0.0
var balls_n := 0
var balls_pts := 0
var balls_spawn := 0.0
var balls_sign: Dictionary = {}
var bark_cd := 0.0
var bark_t := 0.0
var over_wolf := false
var bprizes: Array = []
var bnode: Node2D = null
var bonus_t := 0.0
var bend_x := 0.0
var ret_x := 0.0
var bonus_got := 0
const BXO := 700000.0
var sleap_t := 0.0
var hazards: Array = []
var haz_cd := 4.0
var lunge_t := 0.0
var next_lunge := 14.0
var joy_t := 0.0
var surprise_t := 0.0
var laugh_t := 0.0
var invuln := 0.0
var boost_t := 0.0
var idle_t := 0.0
var shake := 0.0
var cam_x := 400.0
var cam_y := 330.0
var cam_zoom := 0.9
var look := 150.0
var jump_buf := 0.0
var jump_hold := false
var jump_cut := false
var air_t := 0.0
var move_x := 0.0
var pad_mode := false  # true quando si usa il controller (Xbox ecc.)
var joy_id := -1
var joy_origin := Vector2.ZERO
var jump_id := -1
var run_cap := RUN_BASE
var skid := false
var last_step_idx := 0
var best_scores: Array = []
var best_zone := 0
var wins := 0
var sound_on := true
var music_on := true
var new_record := false
var final_score := 0
var t_all := 0.0
var in_bramble := false
var spring_cd := 0.0
var pad_cd := 0.0
var dust_t := 0.0
var chirp_t := 3.0
var drip_t := 2.0
var growl_t := 2.0
var last_ci := -9999
var active := {}
var trap_list: Array = []
var particles: Array = []
var popups: Array = []
var tex_cache := {}

func is_ready_ok() -> bool:
    return ok

func _step(s: String) -> void:
    var p := get_parent()
    if p != null and p.has_method("step"):
        p.step(s)

func _tex(n: String) -> Texture2D:
    return TexLib.get_tex(n)

func _spr(tn: String, pos: Vector2, sc: float, z: int, flip: bool = false) -> Sprite2D:
    var s := Sprite2D.new()
    var tx := _tex(tn)
    s.texture = tx
    s.centered = false
    if tx != null:
        s.offset = Vector2(-float(tx.get_width()) * 0.5, -float(tx.get_height()))
    s.position = pos
    s.scale = Vector2(-sc if flip else sc, sc)
    s.z_index = z
    return s

# layout dinamico (lo schermo puo' essere piu' largo di 960)
func _joy_def() -> Vector2:
    return Vector2(vw - 125.0, vh - 115.0)
func _jump_c() -> Vector2:
    return Vector2(255.0, vh - 120.0)
func _trap_c() -> Vector2:
    return Vector2(110.0, vh - 80.0)
func _play_rect() -> Rect2:
    return Rect2(vw * 0.5 - 150.0, vh * 0.54, 300.0, 62.0)
func _music_rect() -> Rect2:
    return Rect2(vw * 0.5 - 150.0, vh * 0.54 + 76.0, 145.0, 46.0)
func _sound_rect() -> Rect2:
    return Rect2(vw * 0.5 + 5.0, vh * 0.54 + 76.0, 145.0, 46.0)

# ---------------------------------------------------------------- avvio

func _ready() -> void:
    _step("record")
    _load_records()
    _step("livello")
    lv = LevelS.new()
    lv.generate()
    _step("audio")
    audio = AudioS.new()
    add_child(audio)
    audio.set_music_enabled(music_on)
    audio.set_sound_enabled(sound_on)
    _step("sfondo")
    var bl := CanvasLayer.new()
    bl.layer = -10
    add_child(bl)
    bg = Node2D.new()
    bg.set_script(BackS)
    bg.set("mode", 0)
    bl.add_child(bg)
    _step("mondo")
    world = Node2D.new()
    add_child(world)
    water = Node2D.new()
    water.z_index = 7
    add_child(water)
    water.draw.connect(_draw_water)
    fx = Node2D.new()
    fx.z_index = 9
    add_child(fx)
    fx.draw.connect(_draw_fx)
    _step("personaggi")
    hero.r = 16.0
    wolf.r = 22.0
    wolf.h = 105.0
    hero_rig = RigS.new()
    hero_rig.z_index = 5
    add_child(hero_rig)
    hero_rig.setup("n", 0.9)
    wolf_rig = RigS.new()
    wolf_rig.z_index = 4
    add_child(wolf_rig)
    wolf_rig.setup("w", 0.92)
    _step("camera")
    cam = Camera2D.new()
    add_child(cam)
    cam.make_current()
    var wl := CanvasLayer.new()
    wl.layer = 5
    add_child(wl)
    wx_node = Node2D.new()
    wx_node.set_script(BackS)
    wx_node.set("mode", 1)
    wl.add_child(wx_node)
    var ul := CanvasLayer.new()
    ul.layer = 50
    add_child(ul)
    ui = Control.new()
    ui.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    ui.mouse_filter = Control.MOUSE_FILTER_IGNORE
    ul.add_child(ui)
    ui.draw.connect(_draw_ui)
    _step("menu")
    _enter_menu()
    ok = true

# ---------------------------------------------------------------- blocchi di mondo

func _chunk_range() -> Vector2i:
    return Vector2i(-1, int(TOTAL / CH) + 2)

func _stream(force: bool) -> void:
    var c := int(floor(cam_x / CH))
    if c == last_ci and not force:
        return
    last_ci = c
    var rr := _chunk_range()
    var made := 0
    for ci in range(c - 3, c + 4):
        if ci < rr.x or ci > rr.y or active.has(ci):
            continue
        _spawn_chunk(ci)
        made += 1
    var drop: Array = []
    for k in active.keys():
        if absi(int(k) - c) > 4:
            drop.append(k)
    for k2 in drop:
        _free_chunk(int(k2))

func _spawn_chunk(ci: int) -> void:
    var holder := Node2D.new()
    add_child(holder)
    active[ci] = holder
    var terrain := Node2D.new()
    holder.add_child(terrain)
    terrain.draw.connect(_draw_chunk.bind(terrain, ci))
    if not lv.chunks.has(ci):
        return
    var ch: Dictionary = lv.chunks[ci]
    for d in ch.decor:
        holder.add_child(_spr(str(d.tex), Vector2(d.x, d.y), float(d.sc), int(d.z), bool(d.flip)))
    for so in ch.solids:
        var sc := 0.98 if so.kind == "fence" else 0.8
        holder.add_child(_spr(str(so.kind), Vector2(so.cx, so.gy + 8.0), sc, 1))
    for br in ch.brambles:
        var bs := float(br.w) / 120.0
        holder.add_child(_spr(str(br.get("tex", "bramble")), Vector2(br.cx, lv.hill_y(br.cx) + 6.0), bs, 1))
    for b in ch.bones:
        var s1 := _spr("bone", Vector2(b.x, b.y), 0.8, 2)
        s1.visible = not b.got
        holder.add_child(s1)
        b.node = s1
    for h in ch.hearts:
        var s2 := _spr("heart", Vector2(h.x, h.y), 0.9, 2)
        s2.visible = not h.got
        holder.add_child(s2)
        h.node = s2
    for g in ch.gems:
        var s3 := _spr("gem", Vector2(g.x, g.y), 0.9, 2)
        s3.visible = not g.got
        holder.add_child(s3)
        g.node = s3
    for sp in ch.springs:
        var s4 := _spr("bigspring" if sp.has("big") else "spring", Vector2(sp.x, sp.y + 4.0), 1.0, 1)
        holder.add_child(s4)
        sp.node = s4
    for pd in ch.pads:
        var s5 := _spr("pad", Vector2(pd.x, pd.y + 6.0), 1.0, 1)
        holder.add_child(s5)
        pd.node = s5
    for bt in ch.bolts:
        var s7 := _spr("bolt", Vector2(bt.x, bt.y + 4.0), 1.0, 1)
        s7.visible = not bt.got
        holder.add_child(s7)
        bt.node = s7
    for st in ch.stars:
        var s8 := _spr("star_blue" if int(st.t) == 0 else "star_green", Vector2(st.x, st.y), 1.0, 1)
        s8.visible = not st.got
        holder.add_child(s8)
        st.node = s8
    for po in ch.portals:
        var s9 := _spr("portal0", Vector2(po.x, po.y + 55.0), 1.0, 3)
        s9.visible = not po.got
        holder.add_child(s9)
        po.node = s9
    for zs in ch.zsigns:
        var s10 := _spr("zsign", Vector2(zs.x, float(zs.gy) + 4.0), 1.0, 1)
        holder.add_child(s10)
        zs.node = s10
    for fl in ch.flags:
        var s6 := _spr("flag_on" if fl.on else "flag_off", Vector2(fl.x, lv.hill_y(fl.x) + 4.0), 1.0, 1)
        holder.add_child(s6)
        fl.node = s6

func _free_chunk(ci: int) -> void:
    if lv.chunks.has(ci):
        var ch: Dictionary = lv.chunks[ci]
        for key in ["bones", "hearts", "gems", "springs", "pads", "flags", "bolts", "stars", "portals", "zsigns"]:
            for d in ch[key]:
                d.node = null
    var h: Node2D = active[ci]
    h.queue_free()
    active.erase(ci)

func _clear_world() -> void:
    for k in active.keys().duplicate():
        _free_chunk(int(k))
    last_ci = -9999

# ---------------------------------------------------------------- stati

func _enter_menu() -> void:
    state = "menu"
    state_t = 0.0
    audio.stop_music()
    _reset_progress()
    hero.x = 700.0
    hero.y = lv.ground_y(700.0)
    hero.face = 1
    wolf.x = 1120.0
    wolf.y = lv.ground_y(1120.0)
    wolf.face = -1
    hero.vx = 0.0
    wolf.vx = 0.0
    hero.on_ground = true
    wolf.on_ground = true
    cam_x = 900.0
    cam_y = 330.0
    _stream(true)

func _reset_progress() -> void:
    spin_sign = {}
    for ci in lv.chunks.keys():
        var ch: Dictionary = lv.chunks[ci]
        for key in ["bones", "hearts", "gems", "bolts", "stars", "portals", "zsigns"]:
            for d in ch[key]:
                d.got = false
                if d.node != null:
                    d.node.visible = true
        for fl in ch.flags:
            fl.on = false
            if fl.node != null:
                fl.node.texture = _tex("flag_off")
    for tr in trap_list:
        tr.node.queue_free()
    trap_list.clear()
    for hz in hazards:
        hz.node.queue_free()
    hazards.clear()
    for f in lv.fauna:
        f.state = 0
        f.x = f.x0
        f.vx = 0.0
        f.vy = 0.0
        if f.node != null:
            f.node.queue_free()
            f.node = null

func _start_game() -> void:
    _reset_progress()
    lives = 3
    bones_n = 0
    gems_n = 0
    traps = 2
    trap_cd = 0.0
    score_f = 0.0
    max_x = 0.0
    run_time = 0.0
    stage = 0
    hurt_t = 0.0
    joy_t = 0.0
    invuln = 0.0
    boost_t = 0.0
    bolt_t = 0.0
    sjump_t = 0.0
    sleap_t = 0.0
    lunge_t = 0.0
    next_lunge = 14.0
    haz_cd = 5.0
    run_cap = RUN_BASE
    new_record = false
    cp_x = 250.0
    _place_at(cp_x)
    state = "ready"
    state_t = 0.0
    ready_len = 2.6
    banner_t = 3.0
    audio.set_music(0)
    audio.play("bark_l", -4.0, 1.0)

func _place_at(x: float) -> void:
    hero.x = x
    hero.y = lv.ground_y(x)
    hero.vx = 0.0
    hero.vy = 0.0
    hero.on_ground = true
    hero.face = 1
    wolf.x = maxf(-300.0, x - 480.0)
    wolf.y = lv.ground_y(maxf(0.0, wolf.x))
    wolf.vx = 0.0
    wolf.vy = 0.0
    wolf.on_ground = true
    wolf.face = 1
    wolf.stun = 0.0
    run_cap = RUN_BASE
    bolt_t = 0.0
    sjump_t = 0.0
    sleap_t = 0.0
    lunge_t = 0.0
    next_lunge = 12.0
    haz_cd = 3.0
    _clear_hazards()
    cam_x = x + 150.0
    cam_y = hero.y
    idle_t = 0.0

func _lose_life(reason: String) -> void:
    if state != "play":
        return
    lives -= 1
    hurt_t = 1.4
    laugh_t = 1.6
    shake = 0.35
    state = "respawn"
    state_t = 0.0
    audio.play("hit", -2.0, 1.0)
    audio.play("yelp" if reason == "catch" else "fall", -2.0, 1.0)
    if reason == "catch":
        audio.play("growl", -2.0, 1.0)
        hero.vy = -420.0
        hero.vx = 160.0
        hero.on_ground = false
    if lives <= 0:
        _end_run(false)

func _end_run(victory: bool) -> void:
    if victory:
        score_f += float(lives) * 500.0 + maxf(0.0, 900.0 - run_time) * 3.0
        wins += 1
    final_score = int(score_f)
    new_record = best_scores.is_empty() or final_score > int(best_scores[0])
    best_scores.append(final_score)
    best_scores.sort()
    best_scores.reverse()
    while best_scores.size() > 5:
        best_scores.pop_back()
    best_zone = maxi(best_zone, stage + 1)
    if victory:
        best_zone = 8
    _save_records()
    state = "won" if victory else "over"
    state_t = 0.0
    audio.play("win" if victory else "lose", -2.0, 1.0)

func _load_records() -> void:
    var cf := ConfigFile.new()
    if cf.load(SAVE_PATH) == OK:
        best_scores = cf.get_value("record", "punteggi", [])
        best_zone = int(cf.get_value("record", "zona", 0))
        wins = int(cf.get_value("record", "vittorie", 0))
        sound_on = bool(cf.get_value("opzioni", "suoni", true))
        music_on = bool(cf.get_value("opzioni", "musica", true))

func _save_records() -> void:
    var cf := ConfigFile.new()
    cf.set_value("record", "punteggi", best_scores)
    cf.set_value("record", "zona", best_zone)
    cf.set_value("record", "vittorie", wins)
    cf.set_value("opzioni", "suoni", sound_on)
    cf.set_value("opzioni", "musica", music_on)
    cf.save(SAVE_PATH)

# ---------------------------------------------------------------- fisica

func _block_x(b: Body, nx: float) -> float:
    var res := nx
    for s in lv.solids_near(nx, b.r + 4.0):
        if b.y > s.top + 12.0 and res > s.x0 - b.r and res < s.x1 + b.r:
            if b.x <= (s.x0 + s.x1) * 0.5:
                res = s.x0 - b.r
            else:
                res = s.x1 + b.r
            b.vx = 0.0
    return res

func _in_sky() -> bool:
    return state == "bonus" or state == "balls"

func _floor_at(x: float, feet: float) -> float:
    if _in_sky():
        var g := 5000.0
        for p in bplats:
            if x >= float(p.x0) and x <= float(p.x1) and feet <= float(p.y) + 10.0:
                g = minf(g, float(p.y))
        return g
    return lv.floor_y(x, feet)

func _phys(b: Body, dt: float, target_vx: float, want_jump: bool, jump_v: float) -> void:
    b.jumped = false
    b.landed_v = 0.0
    var speeding := absf(target_vx) > absf(b.vx) and signf(target_vx) * signf(b.vx) >= 0.0
    var rate := 1700.0 if speeding else 3200.0
    if b == hero and bolt_t > 0.0:
        rate = 3200.0
    b.noceil = maxf(0.0, b.noceil - dt)
    if not b.on_ground:
        rate = 1300.0
        if b == hero and sleap_t > 0.0:
            rate = 160.0
    b.vx = move_toward(b.vx, target_vx, rate * dt)
    if want_jump and (b.on_ground or b.coyote > 0.0):
        b.vy = jump_v
        b.on_ground = false
        b.coyote = 0.0
        b.jumped = true
        if b == hero and sjump_t > 0.0:
            b.noceil = 1.3
        if b == hero and sleap_t > 0.0:
            b.vx = clampf(b.vx * 1.35, -1500.0, 1500.0)
    if not b.on_ground:
        var gv := GRAV
        if b.vy > 0.0:
            gv = GRAV * 1.18
        if b == hero and sleap_t > 0.0:
            gv = GRAV * 0.55
        b.vy = minf(b.vy + gv * dt, 1300.0)
    b.x = _block_x(b, b.x + b.vx * dt)
    if b.on_ground:
        var gy: float = _floor_at(b.x, b.y)
        if gy > b.y + 20.0:
            b.on_ground = false
            b.coyote = 0.16
            b.vy = 0.0
        else:
            b.y = gy
            b.coyote = 0.16
    if not b.on_ground:
        var prev := b.y
        b.y += b.vy * dt
        b.coyote = maxf(0.0, b.coyote - dt)
        if b.vy < 0.0 and b.noceil <= 0.0:
            var cyl: float = lv.ceil_y(b.x)
            if b.y - b.h < cyl:
                b.y = cyl + b.h
                b.vy = 60.0
        var gy2: float = _floor_at(b.x, prev)
        if b.vy >= 0.0 and b.y >= gy2:
            b.y = gy2
            b.landed_v = b.vy
            b.vy = 0.0
            b.on_ground = true
            b.coyote = 0.16
    if b.vx > 20.0:
        b.face = 1
    elif b.vx < -20.0:
        b.face = -1

# ---------------------------------------------------------------- ciclo principale

func _process(dt0: float) -> void:
    if not ok:
        return
    var dt := minf(dt0, 0.05)
    var vs := get_viewport().get_visible_rect().size
    vw = vs.x
    vh = vs.y
    t_all += dt
    state_t += dt
    hurt_t = maxf(0.0, hurt_t - dt)
    joy_t = maxf(0.0, joy_t - dt)
    surprise_t = maxf(0.0, surprise_t - dt)
    laugh_t = maxf(0.0, laugh_t - dt)
    invuln = maxf(0.0, invuln - dt)
    boost_t = maxf(0.0, boost_t - dt)
    bolt_t = maxf(0.0, bolt_t - dt)
    sjump_t = maxf(0.0, sjump_t - dt)
    sleap_t = maxf(0.0, sleap_t - dt)
    bark_cd = maxf(0.0, bark_cd - dt)
    bark_t = maxf(0.0, bark_t - dt)
    trap_cd = maxf(0.0, trap_cd - dt)
    banner_t = maxf(0.0, banner_t - dt)
    shake = maxf(0.0, shake - dt)
    spring_cd = maxf(0.0, spring_cd - dt)
    pad_cd = maxf(0.0, pad_cd - dt)
    match state:
        "menu":
            _upd_idle(dt)
        "ready":
            _upd_idle(dt)
            if state_t >= ready_len:
                state = "play"
                state_t = 0.0
                audio.play("growl", -4.0, 1.0)
        "play":
            _upd_play(dt)
        "bonus":
            _upd_bonus(dt)
        "balls":
            _upd_balls(dt)
        "respawn":
            _upd_respawn(dt)
        "over":
            _upd_respawn(dt)
        "won":
            _upd_idle(dt)
    _upd_camera(dt)
    if not _in_sky():
        _stream(false)
    _upd_pickups(dt)
    _upd_traps(dt)
    _upd_fauna(dt)
    _upd_rigs(dt)
    _upd_ambient(dt)
    _upd_fx(dt)
    ui.queue_redraw()

func _upd_idle(dt: float) -> void:
    _phys(hero, dt, 0.0, false, JUMP_V)
    _phys(wolf, dt, 0.0, false, JUMP_V)

func _upd_respawn(dt: float) -> void:
    _phys(hero, dt, 0.0, false, JUMP_V)
    _phys(wolf, dt, 0.0, false, JUMP_V)
    if state == "respawn" and state_t > 1.5:
        _place_at(cp_x)
        invuln = 2.5
        hurt_t = 0.0
        state = "ready"
        state_t = 0.0
        ready_len = 1.1

func _kb_dir() -> float:
    var d := 0.0
    if Input.is_key_pressed(KEY_RIGHT) or Input.is_key_pressed(KEY_D):
        d += 1.0
    if Input.is_key_pressed(KEY_LEFT) or Input.is_key_pressed(KEY_A):
        d -= 1.0
    if d == 0.0:
        d = _pad_dir()
    return d

# levetta sinistra o croce direzionale del controller
func _pad_dir() -> float:
    var best := 0.0
    for id in Input.get_connected_joypads():
        var ax := Input.get_joy_axis(id, JOY_AXIS_LEFT_X)
        if absf(ax) < 0.22:
            ax = 0.0
        else:
            ax = signf(ax) * clampf((absf(ax) - 0.22) / 0.6, 0.0, 1.0)
        if Input.is_joy_button_pressed(id, JOY_BUTTON_DPAD_RIGHT):
            ax = 1.0
        elif Input.is_joy_button_pressed(id, JOY_BUTTON_DPAD_LEFT):
            ax = -1.0
        if absf(ax) > absf(best):
            best = ax
    if best != 0.0:
        pad_mode = true
    return best

func _upd_play(dt: float) -> void:
    run_time += dt
    var mx := move_x
    var kd := _kb_dir()
    if kd != 0.0:
        mx = kd
    jump_buf = maxf(0.0, jump_buf - dt)
    var mult := 1.0
    var was_bramble := in_bramble
    in_bramble = false
    for b in lv.brambles_near(hero.x, 0.0):
        if hero.y > b.top:
            in_bramble = true
    if in_bramble:
        mult *= 0.45
        run_cap = RUN_BASE
        if not was_bramble:
            hurt_t = 0.7
            audio.play("hit", -8.0, 1.3)
            audio.play("yelp", -10.0, 1.2)
    if hero.on_ground and lv.stream_at(hero.x):
        mult *= 0.8
    if boost_t > 0.0 and bolt_t <= 0.0:
        mult *= 1.3
    # lo slancio cresce correndo senza fermarsi
    if bolt_t > 0.0:
        run_cap = move_toward(run_cap, BOLT_CAP, 1500.0 * dt)
        if mx > -0.3:
            mx = 1.0
    elif run_cap > RUN_MAX:
        run_cap = move_toward(run_cap, RUN_MAX, 450.0 * dt)
    elif mx > 0.8 and hero.vx > run_cap * 0.9:
        run_cap = minf(RUN_MAX, run_cap + 90.0 * dt)
    elif mx < 0.3:
        run_cap = move_toward(run_cap, RUN_BASE, 300.0 * dt)
    var want := jump_buf > 0.0
    _phys(hero, dt, mx * run_cap * mult, want, JUMP_V if sjump_t <= 0.0 else -1150.0)
    skid = hero.on_ground and absf(hero.vx) > 300.0 and (mx * hero.vx < 0.0 or absf(mx) < 0.15)
    if skid and dust_t <= 0.0:
        _dust(Vector2(hero.x, hero.y), 2)
        dust_t = 0.05
    dust_t = maxf(0.0, dust_t - dt)
    if hero.jumped:
        jump_buf = 0.0
        jump_cut = false
        air_t = 0.0
        audio.play("jump", -6.0, 1.0)
    air_t = 0.0 if hero.on_ground else air_t + dt
    if not jump_hold and not jump_cut and sjump_t <= 0.0 and hero.vy < -250.0 and not hero.on_ground and air_t > 0.05:
        hero.vy *= 0.55
        jump_cut = true
    if hero.landed_v > 300.0:
        audio.play("land", -9.0, 1.0)
        _dust(Vector2(hero.x, hero.y), 5)
    var left_lim := cam_x - (vw / cam_zoom) * 0.5 + 70.0
    if hero.x < left_lim:
        hero.x = left_lim
        hero.vx = maxf(hero.vx, 0.0)
    if hero.x < 0.0:
        hero.x = 0.0
    if absf(hero.vx) < 30.0 and absf(mx) < 0.2 and hero.on_ground:
        idle_t += dt
    else:
        idle_t = 0.0
    # scia di polvere nello scatto
    if hero.on_ground and absf(hero.vx) > 640.0 and dust_t <= 0.0:
        _dust(Vector2(hero.x - 20.0 * float(hero.face), hero.y), 1)
        dust_t = 0.06
    next_lunge -= dt
    if next_lunge <= 0.0 and wolf.stun <= 0.0:
        lunge_t = 2.4
        next_lunge = maxf(7.0, randf_range(13.0, 22.0) - float(stage) * 1.5)
        audio.play("growl", -2.0, 0.8)
        popups.append({"p": Vector2(hero.x, hero.y - 190.0), "text": "IL LUPO SCATTA!", "life": 1.4})
    lunge_t = maxf(0.0, lunge_t - dt)
    _upd_hazards(dt)
    _upd_wolf(dt)
    if hero.y > 800.0:
        _lose_life("fall")
        return
    if absf(hero.x - wolf.x) < 70.0 and hero.y < wolf.y - 75.0 and not over_wolf:
        over_wolf = true
        score_f += 40.0
        joy_t = 0.8
        audio.play("pickup", -4.0, 1.7)
        popups.append({"p": Vector2(hero.x, hero.y - 170.0), "text": "SALTO SUL LUPO! +40", "life": 1.3})
    elif absf(hero.x - wolf.x) > 220.0:
        over_wolf = false
    if wolf.stun <= 0.0 and invuln <= 0.0 and absf(hero.x - wolf.x) < 44.0 and absf(hero.y - wolf.y) < 70.0:
        _lose_life("catch")
        return
    var prev_max := max_x
    max_x = maxf(max_x, hero.x)
    score_f += (max_x - prev_max) * 0.05
    var ns: int = lv.stage_of(hero.x)
    if ns != stage:
        stage = ns
        score_f += 1000.0
        banner_t = 3.2
        audio.set_music(stage)
        audio.play("checkpoint", -4.0, 1.0)
        popups.append({"p": Vector2(hero.x, hero.y - 180.0), "text": "ZONA COMPLETATA +1000", "life": 2.0})
    var idx := int(hero_rig.phase / PI)
    if hero.on_ground and absf(hero.vx) > 60.0 and idx != last_step_idx:
        var snd := "step_stone" if (stage == 1 or stage == 3 or stage == 5 or stage == 6 or stage == 7) else "step_dirt"
        if lv.stream_at(hero.x):
            snd = "splash"
            _splash(Vector2(hero.x, hero.y))
        audio.play(snd, -14.0, randf_range(0.9, 1.1))
    last_step_idx = idx
    if hero.x >= TOTAL - 420.0:
        joy_t = 5.0
        _end_run(true)

func _enter_bonus() -> void:
    ret_x = hero.x
    state = "bonus"
    state_t = 0.0
    bonus_t = 0.0
    bonus_got = 0
    jump_buf = 0.0
    bplats.clear()
    bprizes.clear()
    if bnode != null:
        bnode.queue_free()
    bnode = Node2D.new()
    add_child(bnode)
    var r := RandomNumberGenerator.new()
    r.seed = int(ret_x) + 77
    var cx := BXO + 60.0
    var cy := 440.0
    _bplat(0, cx + 130.0, cy, 260.0, 0, r)
    cx += 260.0
    for i in range(26):
        var gap := r.randf_range(110.0, 240.0)
        var ny := clampf(cy + r.randf_range(-100.0, 100.0), 260.0, 520.0)
        var kind := r.randi() % 2
        var w := 130.0 if kind == 1 else r.randf_range(170.0, 240.0)
        var mid := cx + gap + w * 0.5
        _bplat(kind, mid, ny, w, r.randi() % 4, r)
        _bprize(mid, ny - 62.0, r)
        if kind == 0 and r.randf() < 0.5:
            _bprize(mid + 70.0, ny - 70.0, r)
        cx = mid + w * 0.5
        cy = ny
    var fx0 := cx + 160.0
    _bplat(0, fx0 + 220.0, 430.0, 440.0, 1, r)
    for k in range(5):
        _bprize(fx0 + 80.0 + 70.0 * float(k), 360.0, r)
    bend_x = fx0 + 420.0
    hero.x = BXO + 100.0
    hero.y = 440.0
    hero.vx = 0.0
    hero.vy = 0.0
    hero.on_ground = true
    cam_x = hero.x + 150.0
    cam_y = 330.0
    banner_t = 2.5
    audio.play("checkpoint", -2.0, 1.4)
    audio.play("zap", -8.0, 1.6)

func _bplat(kind: int, mid: float, y: float, w: float, col: int, r: RandomNumberGenerator) -> void:
    var hw := w * 0.5
    bplats.append({"x0": mid - hw, "x1": mid + hw, "y": y})
    var tn := "bcl" + str(col) if kind == 0 else "bst" + str(col)
    var sc := w / 200.0 if kind == 0 else 1.0
    var sp := _spr(tn, Vector2(mid, y + (70.0 * sc if kind == 0 else 94.0)), sc if kind == 0 else 1.0, 1)
    bnode.add_child(sp)

func _bprize(x: float, y: float, r: RandomNumberGenerator) -> void:
    var q := r.randf()
    var tp := 0
    var tn := "bone"
    if q > 0.93:
        tp = 3
        tn = "bolt"
    elif q > 0.85:
        tp = 2
        tn = "heart"
    elif q > 0.55:
        tp = 1
        tn = "gem"
    var sp := _spr(tn, Vector2(x, y), 0.9 if tp != 3 else 0.55, 2)
    bnode.add_child(sp)
    bprizes.append({"x": x, "y": y, "t": tp, "got": false, "node": sp})

func _enter_balls(zs: Dictionary) -> void:
    balls_sign = zs
    ret_x = float(zs.x) + 160.0
    state = "balls"
    state_t = 0.0
    balls_t = 25.0
    balls_n = 0
    balls_pts = 0
    balls_spawn = 0.5
    bballs.clear()
    bplats.clear()
    jump_buf = 0.0
    if bnode != null:
        bnode.queue_free()
    bnode = Node2D.new()
    add_child(bnode)
    bplats.append({"x0": BXO - 120.0, "x1": BXO + 1420.0, "y": 450.0})
    var k := 0
    var cxp := BXO - 100.0
    while cxp < BXO + 1420.0:
        var sp := _spr("bcl" + str(k % 4), Vector2(cxp + 100.0, 450.0 + 70.0), 1.0, 1)
        bnode.add_child(sp)
        cxp += 180.0
        k += 1
    hero.x = BXO + 650.0
    hero.y = 450.0
    hero.vx = 0.0
    hero.vy = 0.0
    hero.on_ground = true
    cam_x = hero.x
    cam_y = 330.0
    banner_t = 2.5
    audio.play("checkpoint", -2.0, 1.4)

func _balls_exit() -> void:
    if bnode != null:
        bnode.queue_free()
        bnode = null
    bplats.clear()
    bballs.clear()
    var gain := balls_pts * 40
    score_f += float(gain)
    bones_n += balls_n
    var heart := balls_n >= 15
    if heart:
        lives = mini(5, lives + 1)
    state = "play"
    state_t = 0.0
    hero.x = ret_x
    hero.y = lv.ground_y(ret_x)
    hero.vx = 0.0
    hero.vy = 0.0
    hero.on_ground = true
    wolf.x = minf(wolf.x, ret_x - 500.0)
    wolf.y = lv.ground_y(maxf(0.0, wolf.x))
    wolf.vx = 0.0
    wolf.vy = 0.0
    wolf.on_ground = true
    wolf.stun = 0.0
    run_cap = RUN_BASE
    invuln = 1.5
    cam_x = hero.x + 150.0
    cam_y = hero.y
    joy_t = 1.6
    popups.append({"p": Vector2(hero.x, hero.y - 170.0), "text": "PALLINE: " + str(balls_n) + "  +" + str(gain) + (" +1 VITA" if heart else ""), "life": 2.6})
    audio.play("checkpoint", -3.0, 1.0)

func _upd_balls(dt: float) -> void:
    balls_t -= dt
    var mx := move_x
    var kd := _kb_dir()
    if kd != 0.0:
        mx = kd
    jump_buf = maxf(0.0, jump_buf - dt)
    hero.noceil = 5.0
    _phys(hero, dt, mx * 540.0, jump_buf > 0.0, JUMP_V)
    hero.x = clampf(hero.x, BXO - 40.0, BXO + 1340.0)
    if hero.jumped:
        jump_buf = 0.0
        jump_cut = false
        air_t = 0.0
        audio.play("jump", -6.0, 1.0)
    air_t = 0.0 if hero.on_ground else air_t + dt
    if not jump_hold and not jump_cut and hero.vy < -250.0 and not hero.on_ground and air_t > 0.05:
        hero.vy *= 0.55
        jump_cut = true
    balls_spawn -= dt
    if balls_spawn <= 0.0 and balls_t > 1.5:
        balls_spawn = randf_range(0.28, 0.6)
        var q := randf()
        var col := Color(1.0, 0.3, 0.3)
        var pt := 1
        var rad := 17.0
        if q > 0.92:
            col = Color(1.0, 0.85, 0.15)
            pt = 5
            rad = 21.0
        elif q > 0.78:
            col = Color(0.3, 0.6, 1.0)
            pt = 3
        elif q > 0.55:
            col = Color(0.35, 0.9, 0.4)
            pt = 2
        bballs.append({"x": BXO + randf_range(40.0, 1260.0), "y": -40.0, "vy": randf_range(240.0, 420.0), "col": col, "pt": pt, "r": rad, "b": 0})
    var i := bballs.size() - 1
    while i >= 0:
        var bl: Dictionary = bballs[i]
        bl.vy = float(bl.vy) + 500.0 * dt
        bl.y = float(bl.y) + float(bl.vy) * dt
        var dx := float(bl.x) - hero.x
        var dy := float(bl.y) - (hero.y - 55.0)
        var gone := false
        if dx * dx + dy * dy < 4200.0 + float(bl.r) * float(bl.r):
            balls_n += 1
            balls_pts += int(bl.pt)
            audio.play("pickup", -5.0, 0.9 + 0.2 * float(int(bl.pt)))
            gone = true
        elif float(bl.y) > 450.0 - float(bl.r):
            bl.y = 450.0 - float(bl.r)
            bl.vy = -float(bl.vy) * 0.62
            bl.b = int(bl.b) + 1
            if int(bl.b) >= 3:
                gone = true
        if gone:
            bballs.remove_at(i)
        i -= 1
    if balls_t <= 0.0:
        _balls_exit()

func _bonus_exit(win: bool) -> void:
    if bnode != null:
        bnode.queue_free()
        bnode = null
    bplats.clear()
    bprizes.clear()
    state = "play"
    state_t = 0.0
    hero.x = ret_x
    hero.y = lv.ground_y(ret_x)
    hero.vx = 0.0
    hero.vy = 0.0
    hero.on_ground = true
    wolf.x = minf(wolf.x, ret_x - 450.0)
    wolf.y = lv.ground_y(maxf(0.0, wolf.x))
    wolf.vx = 0.0
    wolf.vy = 0.0
    wolf.on_ground = true
    run_cap = RUN_BASE
    invuln = 1.5
    cam_x = hero.x + 150.0
    cam_y = hero.y
    jump_buf = 0.0
    if win:
        score_f += 300.0
        joy_t = 1.6
        popups.append({"p": Vector2(hero.x, hero.y - 160.0), "text": "BONUS COMPLETATO!", "life": 2.0})
    else:
        popups.append({"p": Vector2(hero.x, hero.y - 160.0), "text": "RIPARTI!", "life": 1.5})
    audio.play("checkpoint", -4.0, 1.0)

func _upd_bonus(dt: float) -> void:
    bonus_t += dt
    var mx := move_x
    var kd := _kb_dir()
    if kd != 0.0:
        mx = kd
    jump_buf = maxf(0.0, jump_buf - dt)
    hero.noceil = 5.0
    hero.x = maxf(hero.x, BXO + 20.0)
    _phys(hero, dt, mx * 380.0, jump_buf > 0.0, JUMP_V if sjump_t <= 0.0 else -1150.0)
    if hero.jumped:
        jump_buf = 0.0
        jump_cut = false
        air_t = 0.0
        audio.play("jump", -6.0, 1.0)
    air_t = 0.0 if hero.on_ground else air_t + dt
    if not jump_hold and not jump_cut and sjump_t <= 0.0 and hero.vy < -250.0 and not hero.on_ground and air_t > 0.05:
        hero.vy *= 0.55
        jump_cut = true
    if hero.landed_v > 300.0:
        audio.play("land", -9.0, 1.0)
    for bp in bprizes:
        if bp.got:
            continue
        var bn: Sprite2D = bp.node
        if bn != null:
            bn.position.y = float(bp.y) + sin(t_all * 4.0 + float(bp.x) * 0.05) * 5.0
        var dx := float(bp.x) - hero.x
        var dy := float(bp.y) - (hero.y - 42.0)
        if dx * dx + dy * dy < 2600.0:
            bp.got = true
            if bn != null:
                bn.visible = false
            bonus_got += 1
            match int(bp.t):
                0:
                    bones_n += 1
                    score_f += 25.0
                    audio.play("pickup", -6.0, 1.2)
                1:
                    gems_n += 1
                    score_f += 150.0
                    audio.play("pickup", -3.0, 1.6)
                2:
                    lives = mini(5, lives + 1)
                    score_f += 100.0
                    audio.play("heart", -4.0, 1.0)
                    popups.append({"p": Vector2(hero.x, hero.y - 150.0), "text": "+1 VITA", "life": 1.4})
                3:
                    bolt_t = BOLT_TIME
                    audio.play("zap", -4.0, 1.0)
                    popups.append({"p": Vector2(hero.x, hero.y - 150.0), "text": "TURBO!", "life": 1.4})
    if hero.x > bend_x:
        _bonus_exit(true)
    elif hero.y > 780.0:
        audio.play("fall", -4.0, 1.0)
        _bonus_exit(false)

func _upd_wolf(dt: float) -> void:
    wolf.stun = maxf(0.0, wolf.stun - dt)
    var dist := hero.x - wolf.x
    var dir := 1.0 if dist >= 0.0 else -1.0
    var ad := absf(dist)
    var tvx := 0.0
    if wolf.stun <= 0.0:
        var sp := clampf(run_cap * (0.85 + 0.008 * float(stage)) + 1.5 * (ad - 300.0), 200.0, 930.0 if bolt_t <= 0.0 else 1450.0)
        if lunge_t > 0.0:
            sp = clampf(sp * 1.14, 200.0, 1130.0)
        if ad < 260.0:
            sp = minf(sp, maxf(hero.vx * dir, 0.0) + (450.0 if lunge_t > 0.0 else 300.0))
        if ad < 40.0:
            sp = minf(sp, 120.0)
        if lv.stream_at(wolf.x):
            sp *= 0.85
        tvx = sp * dir
    var wj := false
    if (wolf.on_ground or wolf.coyote > 0.0) and wolf.stun <= 0.0:
        var la: float = wolf.x + wolf.vx * 0.07 + 10.0 * dir
        if is_inf(lv.ground_y(la)):
            wj = true
        var reach := 24.0 + absf(wolf.vx) * 0.1
        if dir > 0.0:
            for s in lv.solids_near(wolf.x + reach * 0.5, reach * 0.5 + 30.0):
                var dd: float = s.x0 - wolf.x - wolf.r
                if dd > -6.0 and dd < reach and wolf.y > s.top:
                    wj = true
            for b in lv.brambles_near(wolf.x + reach * 0.5, reach * 0.5 + 30.0):
                var d2: float = b.x0 - wolf.x - wolf.r
                if d2 > -6.0 and d2 < reach:
                    wj = true
        else:
            for s2 in lv.solids_near(wolf.x - reach * 0.5, reach * 0.5 + 30.0):
                var dd2: float = wolf.x - wolf.r - s2.x1
                if dd2 > -6.0 and dd2 < reach and wolf.y > s2.top:
                    wj = true
            for b2 in lv.brambles_near(wolf.x - reach * 0.5, reach * 0.5 + 30.0):
                var d3: float = wolf.x - wolf.r - b2.x1
                if d3 > -6.0 and d3 < reach:
                    wj = true
    _phys(wolf, dt, tvx, wj, JUMP_V * 1.04)
    if dist > 1100.0:
        wolf.x = hero.x - 800.0
        wolf.y = lv.ground_y(maxf(0.0, wolf.x))
        wolf.vy = 0.0
        wolf.on_ground = true
    if wolf.y > 900.0:
        wolf.x = hero.x - 420.0
        wolf.y = lv.ground_y(wolf.x)
        wolf.vy = 0.0
        wolf.on_ground = true
    if wolf.jumped and randf() < 0.3:
        audio.play("growl", -12.0, 1.2)
    if absf(wolf.vx) > 640.0 and dust_t <= 0.0 and wolf.on_ground:
        _dust(Vector2(wolf.x - 24.0 * float(wolf.face), wolf.y), 1)

func _bark() -> void:
    if state != "play" or bark_cd > 0.0:
        return
    bark_cd = 7.0
    bark_t = 0.6
    shake = 0.12
    audio.play("bark_l", -2.0, 1.1)
    if absf(wolf.x - hero.x) < 700.0:
        wolf.stun = 2.2
        wolf.vx = 0.0
        score_f += 50.0
        popups.append({"p": Vector2(wolf.x, wolf.y - 150.0), "text": "ABBAIO! LUPO STORDITO", "life": 1.6})
        audio.play("yelp", -6.0, 0.8)
    else:
        popups.append({"p": Vector2(hero.x, hero.y - 150.0), "text": "ABBAIO (troppo lontano)", "life": 1.2})

func _clear_hazards() -> void:
    for hz in hazards:
        hz.node.queue_free()
    hazards.clear()

func _haz_hit() -> void:
    if state != "play" or invuln > 0.0:
        return
    hurt_t = 0.9
    invuln = 1.0
    run_cap = RUN_BASE
    bolt_t = 0.0
    sjump_t = 0.0
    sleap_t = 0.0
    hero.vx *= 0.15
    hero.vy = -260.0
    hero.on_ground = false
    shake = 0.3
    score_f = maxf(0.0, score_f - 100.0)
    audio.play("hit", -2.0, 0.9)
    audio.play("yelp", -4.0, 1.1)
    popups.append({"p": Vector2(hero.x, hero.y - 150.0), "text": "AHI! -100", "life": 1.2})

func _upd_hazards(dt: float) -> void:
    haz_cd -= dt
    if (stage == 3 or stage == 6 or stage == 7) and haz_cd <= 0.0:
        var spd := clampf(hero.vx, 0.0, 1500.0)
        var tx := hero.x + spd * 1.5 + randf_range(-60.0, 140.0)
        var gyh: float = lv.ground_y(tx)
        if not is_inf(gyh):
            var tn := "meteor" if stage == 7 else "fallrock"
            var nd := _spr(tn, Vector2(tx, gyh - 900.0), 0.9, 8)
            nd.visible = false
            add_child(nd)
            hazards.append({"x": tx, "gy": gyh, "t": 0.0, "node": nd})
        haz_cd = randf_range(1.8, 3.6) if stage != 3 else randf_range(3.5, 6.0)
    var i := hazards.size() - 1
    while i >= 0:
        var hz: Dictionary = hazards[i]
        hz.t += dt
        var nd2: Sprite2D = hz.node
        var warn := 1.15
        var fall := 0.45
        if float(hz.t) >= warn:
            var u := clampf((float(hz.t) - warn) / fall, 0.0, 1.0)
            var yy := lerpf(float(hz.gy) - 900.0, float(hz.gy) + 6.0, u * u)
            nd2.visible = true
            nd2.position = Vector2(hz.x, yy)
            if state == "play" and absf(hero.x - float(hz.x)) < 46.0 and absf((hero.y - 50.0) - (yy - 40.0)) < 62.0:
                _haz_hit()
            if u >= 1.0:
                audio.play("boom", -4.0, 1.0)
                shake = maxf(shake, 0.12)
                _dust(Vector2(hz.x, hz.gy), 7)
                nd2.queue_free()
                hazards.remove_at(i)
        i -= 1

func _drop_trap() -> void:
    if state != "play" or traps <= 0 or trap_cd > 0.0 or not hero.on_ground:
        return
    var tx := hero.x - 40.0
    if is_inf(lv.ground_y(tx)):
        return
    traps -= 1
    trap_cd = 1.0
    var node := _spr("trap_open", Vector2(tx, lv.ground_y(tx) + 3.0), 1.0, 1)
    add_child(node)
    trap_list.append({"x": tx, "node": node, "armed": true})
    audio.play("trap_set", -4.0, 1.0)

func _upd_traps(dt: float) -> void:
    var i := trap_list.size() - 1
    while i >= 0:
        var tr: Dictionary = trap_list[i]
        if bool(tr.armed) and state == "play" and wolf.on_ground and absf(wolf.x - float(tr.x)) < 40.0 and wolf.stun <= 0.0:
            tr.armed = false
            tr.node.texture = _tex("trap_shut")
            wolf.stun = 2.8
            wolf.vx = 0.0
            audio.play("trap_snap", -2.0, 1.0)
            audio.play("yelp", -4.0, 0.8)
            score_f += 50.0
            shake = 0.2
            joy_t = 1.0
            _dust(Vector2(wolf.x, wolf.y), 8)
            popups.append({"p": Vector2(wolf.x, wolf.y - 140.0), "text": "TRAPPOLA! +50", "life": 1.6})
        if hero.x - float(tr.x) > 3000.0:
            tr.node.queue_free()
            trap_list.remove_at(i)
        i -= 1

func _upd_pickups(dt: float) -> void:
    var play := state == "play"
    if not spin_sign.is_empty():
        spin_sign.spin = float(spin_sign.spin) + dt
        var zn0: Sprite2D = spin_sign.node
        var zok := zn0 != null and is_instance_valid(zn0)
        if zok:
            zn0.scale.x = cos(float(spin_sign.spin) / 0.6 * TAU)
        if float(spin_sign.spin) >= 0.6:
            var zsd: Dictionary = spin_sign
            spin_sign = {}
            zsd.spin = -1.0
            if zok:
                zn0.scale.x = 1.0
            if play:
                zsd.got = true
                _enter_balls(zsd)
                return
    var c := int(floor(hero.x / CH))
    if state == "menu":
        c = int(floor(cam_x / CH))
    for ci in range(c - 1, c + 2):
        if not lv.chunks.has(ci):
            continue
        var ch: Dictionary = lv.chunks[ci]
        for b in ch.bones:
            if b.got:
                continue
            var n: Sprite2D = b.node
            if n != null:
                n.position.y = float(b.y) + sin(t_all * 4.0 + float(b.x) * 0.05) * 4.0
            if play:
                var dx := float(b.x) - hero.x
                var dy := float(b.y) - (hero.y - 42.0)
                if dx * dx + dy * dy < 1500.0:
                    b.got = true
                    if n != null:
                        n.visible = false
                    bones_n += 1
                    score_f += 25.0
                    audio.play("pickup", -6.0, 1.0 + 0.02 * float(bones_n % 8))
                    if bones_n % 8 == 0:
                        boost_t = 3.0
                        joy_t = 0.8
                        popups.append({"p": Vector2(hero.x, hero.y - 150.0), "text": "SCATTO!", "life": 1.2})
        for h in ch.hearts:
            if h.got:
                continue
            var hn: Sprite2D = h.node
            if hn != null:
                hn.position.y = float(h.y) + sin(t_all * 3.0 + float(h.x)) * 5.0
            if play:
                var hx := float(h.x) - hero.x
                var hy := float(h.y) - (hero.y - 42.0)
                if hx * hx + hy * hy < 2000.0:
                    h.got = true
                    if hn != null:
                        hn.visible = false
                    lives = mini(5, lives + 1)
                    score_f += 100.0
                    joy_t = 1.4
                    audio.play("heart", -4.0, 1.0)
                    popups.append({"p": Vector2(hero.x, hero.y - 150.0), "text": "+1 VITA", "life": 1.4})
        for g in ch.gems:
            if g.got:
                continue
            var gn: Sprite2D = g.node
            if gn != null:
                gn.position.y = float(g.y) + sin(t_all * 3.5 + float(g.x)) * 6.0
            if play:
                var gx := float(g.x) - hero.x
                var gy := float(g.y) - (hero.y - 42.0)
                if gx * gx + gy * gy < 2400.0:
                    g.got = true
                    if gn != null:
                        gn.visible = false
                    gems_n += 1
                    score_f += 500.0
                    joy_t = 1.6
                    audio.play("heart", -2.0, 1.5)
                    audio.play("checkpoint", -6.0, 1.3)
                    popups.append({"p": Vector2(hero.x, hero.y - 150.0), "text": "SEGRETO TROVATO! +500", "life": 2.0})
        for sp in ch.springs:
            var sn: Sprite2D = sp.node
            sp.t = maxf(0.0, float(sp.t) - dt)
            if sn != null:
                sn.scale.y = 1.0 - 0.45 * (float(sp.t) / 0.25)
            if play and spring_cd <= 0.0 and absf(hero.x - float(sp.x)) < 44.0 and hero.y > float(sp.y) - 36.0 and hero.y < float(sp.y) + 14.0:
                var big: bool = sp.has("big")
                hero.vy = -1500.0 if big else -1080.0
                if big:
                    hero.noceil = 1.8
                    hero.vx = clampf(hero.vx, -200.0, 520.0)
                hero.on_ground = false
                hero.coyote = 0.0
                jump_cut = true
                spring_cd = 0.4
                sp.t = 0.25
                surprise_t = 0.7
                audio.play("jump", -2.0, 1.6)
                audio.play("land", -6.0, 1.5)
        for bt in ch.bolts:
            var btn: Sprite2D = bt.node
            if btn != null:
                btn.visible = not bool(bt.got)
                var pz := 1.0 + 0.05 * sin(t_all * 6.0)
                btn.scale = Vector2(pz, pz)
            if play and not bool(bt.got) and absf(hero.x - float(bt.x)) < 62.0 and hero.y > float(bt.y) - 190.0 and hero.y < float(bt.y) + 30.0:
                bt.got = true
                bolt_t = BOLT_TIME
                joy_t = 1.4
                shake = 0.15
                score_f += 100.0
                audio.play("zap", -2.0, 1.0)
                audio.play("checkpoint", -6.0, 1.9)
                popups.append({"p": Vector2(hero.x, hero.y - 160.0), "text": "FULMINE! SUPER VELOCITA'", "life": 1.8})
        for st in ch.stars:
            var stn: Sprite2D = st.node
            if stn != null:
                stn.visible = not bool(st.got)
                var sz := 1.0 + 0.08 * sin(t_all * 5.0 + float(st.x))
                stn.scale = Vector2(sz, sz)
                stn.rotation = 0.12 * sin(t_all * 3.0 + float(st.x))
            if play and not bool(st.got) and absf(hero.x - float(st.x)) < 70.0 and hero.y > float(st.y) - 20.0 and hero.y - 60.0 < float(st.y) + 60.0 and hero.y < float(st.y) + 150.0:
                st.got = true
                joy_t = 1.4
                score_f += 100.0
                audio.play("checkpoint", -3.0, 1.5)
                if int(st.t) == 0:
                    sjump_t = 8.0
                    popups.append({"p": Vector2(hero.x, hero.y - 160.0), "text": "SUPER SALTO IN ALTO!", "life": 1.8})
                else:
                    sleap_t = 8.0
                    popups.append({"p": Vector2(hero.x, hero.y - 160.0), "text": "SUPER SALTO IN LUNGO!", "life": 1.8})
        for po in ch.portals:
            var pon: Sprite2D = po.node
            if pon != null:
                pon.visible = not bool(po.got)
                pon.texture = _tex("portal0" if int(t_all * 5.0) % 2 == 0 else "portal1")
                var pz2 := 1.0 + 0.07 * sin(t_all * 6.0 + float(po.x))
                pon.scale = Vector2(pz2, pz2)
            if play and not bool(po.got) and absf(hero.x - float(po.x)) < 95.0 and hero.y - 40.0 < float(po.y) + 60.0 and hero.y > float(po.y) - 80.0:
                po.got = true
                _enter_bonus()
                return
        for zs in ch.zsigns:
            if play and spin_sign.is_empty() and not bool(zs.got) and absf(hero.x - float(zs.x)) < 105.0 and hero.y < float(zs.gy) - 60.0 and hero.y > float(zs.gy) - 280.0:
                zs.spin = 0.0
                spin_sign = zs
                invuln = maxf(invuln, 1.2)
                joy_t = 1.0
                audio.play("checkpoint", -4.0, 1.6)
        for pd in ch.pads:
            if play and pad_cd <= 0.0 and hero.on_ground and absf(hero.x - float(pd.x)) < 55.0:
                boost_t = 1.8
                run_cap = maxf(run_cap, 700.0)
                hero.vx = maxf(hero.vx, 760.0)
                pad_cd = 0.5
                audio.play("checkpoint", -8.0, 1.8)
                popups.append({"p": Vector2(hero.x, hero.y - 130.0), "text": "TURBO!", "life": 1.0})
        for fl in ch.flags:
            if play and not fl.on and hero.x >= float(fl.x):
                fl.on = true
                if fl.node != null:
                    fl.node.texture = _tex("flag_on")
                cp_x = float(fl.x)
                traps = mini(4, traps + 1)
                score_f += 150.0
                joy_t = 1.2
                audio.play("checkpoint", -4.0, 1.0)
                popups.append({"p": Vector2(float(fl.x), hero.y - 150.0), "text": "CHECKPOINT +1 TRAPPOLA", "life": 1.8})

func _make_fauna_node(f: Dictionary) -> void:
    var kind := str(f.kind)
    var st := int(f.stage)
    var gy: float = lv.hill_y(float(f.x))
    var sprite: Sprite2D
    f.y = gy
    if kind == "deer":
        sprite = _spr("deer", Vector2(f.x, gy + 4.0), 0.8, 3)
        if st == 1:
            sprite.modulate = Color(0.78, 0.78, 0.82)
    elif kind == "squirrel":
        sprite = _spr("squirrel", Vector2(f.x, gy + 2.0), 0.8, 3)
    elif kind == "rabbit":
        sprite = _spr("rabbit", Vector2(f.x, gy + 2.0), 0.8, 3)
    elif kind == "fox":
        sprite = _spr("fox", Vector2(f.x, gy + 3.0), 0.85, 3)
    elif kind == "lizard":
        sprite = _spr("lizard", Vector2(f.x, gy + 2.0), 0.75, 3)
    elif kind == "eagle":
        f.y = gy - 300.0 - 90.0 * sin(float(f.x) * 0.01)
        sprite = _spr("eagle", Vector2(f.x, f.y), 0.9, 3)
    elif kind == "bat":
        f.y = gy - 190.0 - 50.0 * sin(float(f.x) * 0.013)
        sprite = _spr("bat", Vector2(f.x, f.y), 0.7, 3)
    elif kind == "butterfly":
        f.y = gy - 70.0 - 30.0 * sin(float(f.x) * 0.017)
        sprite = _spr("butterfly", Vector2(f.x, f.y), 0.6, 3)
    elif kind == "drone":
        f.y = gy - 230.0 - 50.0 * sin(float(f.x) * 0.011)
        sprite = _spr("drone", Vector2(f.x, f.y), 0.8, 3)
    elif kind == "ufo":
        f.y = gy - 360.0 - 60.0 * sin(float(f.x) * 0.009)
        sprite = _spr("ufo", Vector2(f.x, f.y), 0.9, 3)
    else:
        sprite = _spr("bird", Vector2(f.x, gy + 2.0), 0.7, 3)
        if st == 3:
            sprite.modulate = Color(0.35, 0.3, 0.45)
    add_child(sprite)
    f.node = sprite

func _upd_fauna(dt: float) -> void:
    for f in lv.fauna:
        var dxc: float = float(f.x) - cam_x
        var st: int = f.state
        if f.node == null:
            if st == 0 and absf(dxc) < 1700.0:
                _make_fauna_node(f)
            else:
                continue
        var node: Sprite2D = f.node
        if st == 0 and absf(dxc) > 2800.0:
            node.queue_free()
            f.node = null
            continue
        var dxh: float = float(f.x) - hero.x
        var kd := str(f.kind)
        var flyer := kd == "bird" or kd == "eagle" or kd == "bat" or kd == "butterfly" or kd == "drone" or kd == "ufo"
        var fs := int(f.stage)
        var atk := (kd == "bat" or kd == "drone" or (kd == "eagle" and fs >= 4)) and fposmod(float(f.x0) * 0.013, 1.0) < 0.65
        f.t += dt
        if st == 0:
            if kd == "butterfly" or kd == "bat" or kd == "eagle" or kd == "drone" or kd == "ufo":
                var fr := 12.0
                if kd == "bat":
                    fr = 9.0
                elif kd == "eagle":
                    fr = 3.0
                elif kd == "drone":
                    fr = 14.0
                elif kd == "ufo":
                    fr = 2.0
                node.texture = _tex(kd if int(f.t * fr) % 2 == 0 else kd + "2")
                var amp := 10.0 if kd == "butterfly" else 14.0
                node.position = Vector2(float(f.x) + 30.0 * sin(f.t * 0.8), float(f.y) + amp * sin(f.t * 1.7))
            if atk and state == "play" and dxh > 160.0 and dxh < 620.0:
                f.state = 3
                f.t = 0.0
                audio.play("screech", -6.0, 1.0)
                node.modulate = Color(1.0, 0.62, 0.62)
                continue
            if not atk and dxh > -80.0 and dxh < (700.0 if kd != "squirrel" else 520.0) and state == "play":
                f.state = 1
                if kd == "deer":
                    f.vx = 520.0
                    surprise_t = 0.9
                    audio.play("snort", -6.0, 1.0)
                elif kd == "squirrel":
                    f.vx = 380.0
                    audio.play("chatter", -8.0, 1.0)
                elif kd == "rabbit":
                    f.vx = 600.0
                elif kd == "fox":
                    f.vx = 640.0
                elif kd == "lizard":
                    f.vx = 460.0
                elif kd == "eagle":
                    f.vx = 520.0
                    f.vy = -40.0
                    audio.play("bird2", -7.0, 0.7)
                elif kd == "bat":
                    f.vx = 460.0
                    f.vy = 30.0
                elif kd == "butterfly":
                    f.vx = 240.0
                    f.vy = -60.0
                else:
                    f.vx = 330.0
                    f.vy = -230.0
                    audio.play("bird1" if randf() < 0.5 else "bird2", -9.0, 1.0)
            continue
        if st == 3:
            f.x -= 250.0 * dt
            f.y = move_toward(float(f.y), hero.y - 55.0, 300.0 * dt)
            node.texture = _tex(kd if int(f.t * 12.0) % 2 == 0 else kd + "2")
            node.scale.x = -absf(node.scale.x)
            node.position = Vector2(f.x, float(f.y) + sin(f.t * 8.0) * 6.0)
            if state == "play" and absf(hero.x - float(f.x)) < 40.0 and absf((hero.y - 55.0) - float(f.y)) < 44.0:
                _haz_hit()
            if float(f.x) < hero.x - 700.0:
                node.queue_free()
                f.node = null
                f.state = 2
            continue
        if st == 1:
            f.x += float(f.vx) * dt
            if flyer:
                f.y += float(f.vy) * dt
                var fr2 := 9.0
                if kd == "eagle":
                    fr2 = 3.0
                elif kd == "butterfly":
                    fr2 = 12.0
                node.texture = _tex(kd if int(f.t * fr2) % 2 == 0 else kd + "2")
                var wob := 0.0
                if kd == "butterfly":
                    wob = 22.0 * sin(f.t * 5.0)
                node.position = Vector2(f.x, float(f.y) + wob)
            else:
                var gy: float = lv.ground_y(f.x)
                if not is_inf(gy):
                    f.y = gy
                var hv := 14.0
                var hf := 18.0
                if kd == "deer":
                    hv = 12.0
                    hf = 12.0
                elif kd == "rabbit":
                    hv = 26.0
                    hf = 11.0
                elif kd == "fox":
                    hv = 10.0
                    hf = 14.0
                elif kd == "lizard":
                    hv = 3.0
                    hf = 30.0
                var hop := absf(sin(f.t * hf)) * hv
                node.position = Vector2(f.x, float(f.y) + 4.0 - hop)
            if float(f.x) - hero.x > 1600.0 or hero.x - float(f.x) > 1800.0:
                node.queue_free()
                f.node = null
                f.state = 2

func _upd_rigs(dt: float) -> void:
    hero_rig.position = Vector2(hero.x, hero.y)
    wolf_rig.position = Vector2(wolf.x, wolf.y)
    var hstand := 0.0
    var wstand := 0.0
    var hsit := 0.0
    match state:
        "menu":
            hstand = 1.0
            wstand = 1.0
            hsit = 1.0 if int(t_all / 4.0) % 2 == 1 else 0.0
        "ready", "over", "won":
            hstand = 1.0
            wstand = 1.0
        "respawn":
            wstand = 1.0
        "play", "bonus", "balls":
            hstand = 1.0 if idle_t > 0.3 else 0.0
            hsit = 1.0 if idle_t > 3.0 else 0.0
            wstand = 1.0 if wolf.stun > 0.0 else 0.0
    var hface := hero.face
    var wface := wolf.face
    if state == "menu":
        hface = 1
        wface = -1
    elif state == "ready" or state == "won":
        wface = 1
    var hfront := true
    if (state == "play" or _in_sky()) and hero.on_ground and absf(hero.vx) > 260.0 and not skid and hurt_t <= 0.0 and joy_t <= 0.0 and surprise_t <= 0.0 and hstand < 0.5 and boost_t <= 0.0:
        hfront = false
    hero_rig.set_front(hfront)
    var wfront := true
    if (state == "play" or _in_sky()) and wolf.on_ground and wolf.stun <= 0.0 and absf(wolf.vx) > 260.0 and laugh_t <= 0.0 and surprise_t <= 0.0 and absf(hero.x - wolf.x) >= 170.0:
        wfront = false
    wolf_rig.set_front(wfront)
    hero_rig.pose(dt, absf(hero.vx), hero.on_ground, hero.vy, hstand, hface, skid, 0.0, hurt_t > 0.0, hsit)
    wolf_rig.pose(dt, absf(wolf.vx), wolf.on_ground, wolf.vy, wstand, wface, false, 0.0, wolf.stun > 0.0, 0.0)
    hero_rig.visible = not (invuln > 0.0 and int(t_all * 14.0) % 2 == 0)
    if bolt_t > 0.0:
        hero_rig.modulate = Color(1.0, 1.0, 0.45 + 0.35 * sin(t_all * 40.0))
    elif sjump_t > 0.0:
        hero_rig.modulate = Color(0.65, 0.85, 1.0)
    elif sleap_t > 0.0:
        hero_rig.modulate = Color(0.7, 1.0, 0.7)
    else:
        hero_rig.modulate = Color(1, 1, 1)
    wolf_rig.visible = not _in_sky()
    var d := hero.x - wolf.x
    var he := "happy"
    if state == "over" or state == "respawn":
        he = "hurt" if hurt_t > 0.5 else "sad"
    elif state == "won":
        he = "joy"
    elif hurt_t > 0.0:
        he = "hurt"
    elif joy_t > 0.0:
        he = "joy"
    elif surprise_t > 0.0:
        he = "surprised"
    elif state == "play" or _in_sky():
        if not hero.on_ground and hero.y > 520.0 and state == "play":
            he = "scared"
        elif wolf.stun > 0.0:
            he = "happy"
        elif d < 200.0:
            he = "scared"
        elif absf(hero.vx) > 120.0:
            he = "run"
    hero_rig.set_expr(he)
    var we := "grin"
    if wolf.stun > 0.0:
        we = "dazed"
    elif state == "won":
        we = "sad"
    elif state == "respawn" or state == "over" or laugh_t > 0.0:
        we = "laugh"
    elif surprise_t > 0.0 and state == "play":
        we = "surprised"
    elif d < 170.0:
        we = "snarl"
    elif d > 480.0:
        we = "smug"
    elif state == "menu":
        we = "snarl" if int(t_all * 0.5) % 2 == 0 else "grin"
    wolf_rig.set_expr(we)

func _upd_camera(dt: float) -> void:
    var zt := 0.9
    if state == "menu":
        cam_x = 900.0
        cam_y = 330.0
        cam_zoom = 1.0
    else:
        var sp01 := clampf((absf(hero.vx) - 350.0) / 450.0, 0.0, 1.0)
        zt = lerpf(0.9, 0.74, sp01)
        if absf(hero.vx) > 800.0:
            zt = lerpf(0.74, 0.60, clampf((absf(hero.vx) - 800.0) / 600.0, 0.0, 1.0))
        cam_zoom = lerpf(cam_zoom, zt, 1.0 - exp(-2.5 * dt))
        var lk := clampf(hero.vx * 0.38, -60.0, 320.0)
        look = lerpf(look, lk, 1.0 - exp(-3.0 * dt))
        cam_x = lerpf(cam_x, hero.x + look, 1.0 - exp(-9.0 * dt))
        var ty := clampf(hero.y, 260.0, 540.0) - 95.0
        cam_y = lerpf(cam_y, ty, 1.0 - exp(-5.0 * dt))
    var off := Vector2.ZERO
    if shake > 0.0:
        off = Vector2(randf_range(-1.0, 1.0), randf_range(-1.0, 1.0)) * shake * 22.0
    cam.position = Vector2(cam_x, cam_y) + off
    cam.zoom = Vector2(cam_zoom, cam_zoom)

func _upd_ambient(dt: float) -> void:
    var sm: Array = lv.stage_mix(ret_x if _in_sky() else cam_x)
    var sa: int = sm[0]
    var sb: int = sm[1]
    var mx: float = sm[2]
    bg.set("bonus", 1.0 if _in_sky() else 0.0)
    bg.set("cam", Vector2(cam_x - (BXO if _in_sky() else 0.0), cam_y))
    bg.set("W", vw)
    bg.set("H", vh)
    bg.set("sa", sa)
    bg.set("sb", sb)
    bg.set("mix", mx)
    bg.call("tick", dt)
    var wa: Array = WX[sa]
    var wb: Array = WX[sb]
    wx_node.set("W", vw)
    wx_node.set("H", vh)
    var wk := 0.0 if _in_sky() else 1.0
    wx_node.set("w_fog", lerpf(wa[0], wb[0], mx) * wk)
    wx_node.set("w_snow", lerpf(wa[1], wb[1], mx) * wk)
    wx_node.set("w_rain", lerpf(wa[2], wb[2], mx) * wk)
    wx_node.set("w_mist", lerpf(wa[3], wb[3], mx) * wk)
    wx_node.set("w_sand", lerpf(wa[4], wb[4], mx) * wk)
    wx_node.call("tick", dt)
    water.queue_redraw()
    var snow := lerpf(wa[1], wb[1], mx)
    var rain := lerpf(wa[2], wb[2], mx)
    var cave := 0.0
    if sa == 3 or sa == 6:
        cave += 1.0 - mx
    if sb == 3 or sb == 6:
        cave += mx
    cave = clampf(cave, 0.0, 1.0)
    audio.set_loop("wind", snow * 0.8 + 0.12 + clampf(absf(hero.vx) / 1600.0, 0.0, 0.3))
    audio.set_loop("rain", rain * 0.8)
    audio.set_loop("fall", cave * 0.5)
    var near := 9999.0
    var r: Vector2i = lv._rng_idx(lv.sx0, hero.x + 700.0, 1400.0)
    for i in range(r.x, r.y):
        var s2: Dictionary = lv.streams[i]
        var dd: float = maxf(0.0, maxf(float(s2.x0) - hero.x, hero.x - float(s2.x1)))
        near = minf(near, dd)
    audio.set_loop("stream", clampf(1.0 - near / 520.0, 0.0, 1.0) * 0.8)
    if state == "play":
        chirp_t -= dt
        if chirp_t <= 0.0:
            chirp_t = randf_range(4.0, 9.0)
            if cave > 0.5:
                audio.play("drip", -10.0, randf_range(0.8, 1.2))
            elif rain < 0.5 and snow < 0.5:
                audio.play("bird1" if randf() < 0.5 else "bird2", -14.0, randf_range(0.9, 1.2))
        growl_t -= dt
        if growl_t <= 0.0:
            growl_t = randf_range(3.0, 6.0)
            if hero.x - wolf.x < 260.0 and wolf.stun <= 0.0:
                audio.play("growl", -8.0, 1.0)

func _dust(p: Vector2, n: int) -> void:
    for i in range(n):
        particles.append({"p": p + Vector2(randf_range(-8.0, 8.0), -2.0), "v": Vector2(randf_range(-70.0, 70.0), randf_range(-90.0, -20.0)), "life": 0.5, "max": 0.5, "c": Color(0.85, 0.8, 0.7, 0.7), "r": randf_range(3.0, 6.0)})

func _splash(p: Vector2) -> void:
    for i in range(5):
        particles.append({"p": p + Vector2(randf_range(-6.0, 6.0), -6.0), "v": Vector2(randf_range(-60.0, 60.0), randf_range(-170.0, -80.0)), "life": 0.55, "max": 0.55, "c": Color(0.75, 0.9, 1.0, 0.85), "r": randf_range(2.0, 4.0)})

func _upd_fx(dt: float) -> void:
    var i := particles.size() - 1
    while i >= 0:
        var pt: Dictionary = particles[i]
        pt.life -= dt
        if pt.life <= 0.0:
            particles.remove_at(i)
        else:
            pt.v = Vector2(pt.v.x, pt.v.y + 600.0 * dt)
            pt.p = pt.p + pt.v * dt
        i -= 1
    var j := popups.size() - 1
    while j >= 0:
        var pp: Dictionary = popups[j]
        pp.life -= dt
        pp.p = pp.p + Vector2(0.0, -30.0 * dt)
        if pp.life <= 0.0:
            popups.remove_at(j)
        j -= 1
    fx.queue_redraw()

# ---------------------------------------------------------------- disegno del mondo

func _draw_chunk(node: Node2D, ci: int) -> void:
    var font := ThemeDB.fallback_font
    var a := float(ci) * CH
    var b := a + CH
    var dk := Color(0.06, 0.05, 0.08)
    var ch: Dictionary = {}
    if lv.chunks.has(ci):
        ch = lv.chunks[ci]
    if ch.has("gaps"):
        for g in ch.gaps:
            var x0: float = g.x0
            var x1: float = g.x1
            var y0: float = lv.hill_y(x0)
            var y1: float = lv.hill_y(x1)
            node.draw_colored_polygon(PackedVector2Array([Vector2(x0, y0), Vector2(x1, y1), Vector2(x1, 1400), Vector2(x0, 1400)]), dk)
            node.draw_polygon(PackedVector2Array([Vector2(x0, y0), Vector2(x1, y1), Vector2(x1, y1 + 300.0), Vector2(x0, y0 + 300.0)]),
                PackedColorArray([Color(0.32, 0.26, 0.24), Color(0.32, 0.26, 0.24), dk, dk]))
            if g.bridge:
                _draw_bridge(node, x0, x1)
    # terreno: tratti senza burroni
    var ivs: Array = []
    var start := a
    var r: Vector2i = lv._rng_idx(lv.gx0, b, 1000.0)
    for i in range(r.x, r.y):
        var g2: Dictionary = lv.gaps[i]
        if g2.x1 <= a or g2.x0 >= b:
            continue
        if g2.x0 > start:
            ivs.append([start, float(g2.x0)])
        start = maxf(start, float(g2.x1))
    if start < b:
        ivs.append([start, b])
    var st: int = lv.stage_of((a + b) * 0.5)
    for iv in ivs:
        _terrain_piece(node, float(iv[0]) - 0.5, float(iv[1]) + 0.5, st)
    if ch.has("plats"):
        for p in ch.plats:
            _draw_plat(node, float(p.x0), float(p.x1), float(p.y), 0 if p.surf else st)
    if b > float(lv.ZB[6]) - 700.0 and a < float(lv.ZB[7]) + 700.0:
        _draw_ceiling(node, a, b)
    for z in range(1, 8):
        var sx: float = float(lv.ZB[z]) + 80.0
        if sx >= a and sx < b:
            var sy: float = lv.hill_y(sx)
            node.draw_rect(Rect2(sx - 4.0, sy - 100.0, 8.0, 100.0), Color(0.4, 0.27, 0.15))
            node.draw_rect(Rect2(sx - 90.0, sy - 130.0, 180.0, 44.0), Color(0.62, 0.45, 0.25))
            node.draw_rect(Rect2(sx - 90.0, sy - 130.0, 180.0, 44.0), Color(0.3, 0.2, 0.1), false, 3.0)
            node.draw_string(font, Vector2(sx - 90.0, sy - 100.0), "ZONA " + str(z + 1), HORIZONTAL_ALIGNMENT_CENTER, 180.0, 26, Color(0.15, 0.08, 0.02))
    var fxp := TOTAL - 400.0
    if fxp >= a - 200.0 and fxp < b + 200.0:
        var fy: float = lv.hill_y(fxp)
        node.draw_circle(Vector2(fxp, fy - 120.0), 190.0, Color(1.0, 0.95, 0.6, 0.18))
        node.draw_rect(Rect2(fxp - 90.0, fy - 220.0, 12.0, 220.0), Color(0.95, 0.78, 0.2))
        node.draw_rect(Rect2(fxp + 78.0, fy - 220.0, 12.0, 220.0), Color(0.95, 0.78, 0.2))
        node.draw_arc(Vector2(fxp, fy - 220.0), 90.0, PI, TAU, 24, Color(0.95, 0.78, 0.2), 12.0)
        node.draw_string(font, Vector2(fxp - 90.0, fy - 150.0), "SALVO!", HORIZONTAL_ALIGNMENT_CENTER, 180.0, 30, Color(1, 1, 1))

func _terrain_piece(node: Node2D, a: float, b: float, st: int) -> void:
    if b - a < 1.0:
        return
    var n := int(ceil((b - a) / 40.0))
    var top := PackedVector2Array()
    for i in range(n + 1):
        var xx := a + (b - a) * float(i) / float(n)
        top.append(Vector2(xx, lv.raw_y(xx)))
    var dirt: Color = DIRT[st]
    var grass: Color = GRASS[st]
    var poly := PackedVector2Array(top)
    poly.append(Vector2(b, 1400.0))
    poly.append(Vector2(a, 1400.0))
    node.draw_colored_polygon(poly, dirt)
    var deep := PackedVector2Array()
    for p in top:
        deep.append(Vector2(p.x, p.y + 70.0))
    deep.append(Vector2(b, 1400.0))
    deep.append(Vector2(a, 1400.0))
    node.draw_colored_polygon(deep, dirt.darkened(0.22))
    var band := PackedVector2Array(top)
    for i2 in range(top.size() - 1, -1, -1):
        band.append(Vector2(top[i2].x, top[i2].y + 20.0))
    node.draw_colored_polygon(band, grass)
    var edge := PackedVector2Array()
    for i3 in range(top.size()):
        edge.append(Vector2(top[i3].x, top[i3].y + 20.0))
    node.draw_polyline(edge, grass.darkened(0.25), 3.0)
    node.draw_polyline(top, grass.lightened(0.18), 3.0)

func _draw_ceiling(node: Node2D, a: float, b: float) -> void:
    var top := PackedVector2Array()
    var bot := PackedVector2Array()
    var n := int(ceil((b - a) / 40.0))
    for i in range(n + 1):
        var xx := a + (b - a) * float(i) / float(n)
        var cy: float = lv.ceil_y(xx)
        if is_inf(cy):
            continue
        bot.append(Vector2(xx, cy))
        top.append(Vector2(xx, cy - 88.0))
    if bot.size() < 2:
        return
    var poly := PackedVector2Array(bot)
    for i2 in range(top.size() - 1, -1, -1):
        poly.append(top[i2])
    node.draw_colored_polygon(poly, Color(0.13, 0.11, 0.17))
    node.draw_polyline(bot, Color(0.35, 0.30, 0.42), 4.0)
    var xt := floorf(a / 70.0) * 70.0
    while xt < b:
        var cy2: float = lv.ceil_y(xt)
        if not is_inf(cy2):
            var rr := fposmod(sin(xt * 12.9898) * 43758.5453, 1.0)
            var ln := 22.0 + 44.0 * rr
            node.draw_colored_polygon(PackedVector2Array([Vector2(xt - 16.0, cy2 - 2.0), Vector2(xt + 16.0, cy2 - 2.0), Vector2(xt + 3.0, cy2 + ln)]), Color(0.22, 0.19, 0.28))
            node.draw_line(Vector2(xt - 4.0, cy2 + 2.0), Vector2(xt + 1.0, cy2 + ln - 8.0), Color(0.5, 0.45, 0.6, 0.6), 2.0)
        xt += 70.0

func _draw_plat(node: Node2D, x0: float, x1: float, y: float, st: int) -> void:
    var dirt: Color = DIRT[st]
    var grass: Color = GRASS[st]
    var mid := (x0 + x1) * 0.5
    node.draw_colored_polygon(PackedVector2Array([Vector2(x0, y), Vector2(x1, y), Vector2(x1 - 18.0, y + 30.0), Vector2(mid + 30.0, y + 52.0), Vector2(mid - 30.0, y + 52.0), Vector2(x0 + 18.0, y + 30.0)]), dirt)
    node.draw_rect(Rect2(x0 - 4.0, y, x1 - x0 + 8.0, 16.0), grass)
    node.draw_rect(Rect2(x0 - 4.0, y, x1 - x0 + 8.0, 16.0), grass.darkened(0.3), false, 3.0)

func _draw_bridge(node: Node2D, x0: float, x1: float) -> void:
    var wood := Color(0.56, 0.38, 0.2)
    var pts := PackedVector2Array()
    var x := x0 - 6.0
    while x < x1 + 6.0:
        pts.append(Vector2(x, lv.ground_y(clampf(x, x0 + 0.5, x1 - 0.5)) + 6.0))
        x += 20.0
    node.draw_polyline(pts, wood, 13.0)
    var xp := x0
    while xp < x1:
        var yy: float = lv.ground_y(clampf(xp, x0 + 0.5, x1 - 0.5))
        node.draw_line(Vector2(xp, yy), Vector2(xp, yy + 12.0), Color(0.3, 0.19, 0.1), 2.0)
        xp += 22.0
    var np := maxi(3, int((x1 - x0) / 140.0))
    for k in range(np + 1):
        var px := lerpf(x0, x1, float(k) / float(np))
        var py: float = lv.ground_y(clampf(px, x0 + 0.5, x1 - 0.5))
        node.draw_rect(Rect2(px - 4.0, py - 46.0, 8.0, 60.0), Color(0.4, 0.26, 0.14))
    var rope := PackedVector2Array()
    for k2 in range(25):
        var u := float(k2) / 24.0
        var rx := lerpf(x0, x1, u)
        var ry: float = lv.ground_y(clampf(rx, x0 + 0.5, x1 - 0.5)) - 44.0 + 10.0 * sin(u * PI * float(np))
        rope.append(Vector2(rx, ry))
    node.draw_polyline(rope, Color(0.75, 0.62, 0.4), 3.0)

func _draw_water() -> void:
    var r: Vector2i = lv._rng_idx(lv.sx0, cam_x + 1400.0, 2800.0 + 600.0)
    for si in range(r.x, r.y):
        var s: Dictionary = lv.streams[si]
        var x0: float = s.x0
        var x1: float = s.x1
        if x1 < cam_x - 1400.0 or x0 > cam_x + 1400.0:
            continue
        var top := PackedVector2Array()
        var bot := PackedVector2Array()
        var n := int(ceil((x1 - x0) / 20.0))
        for i in range(n + 1):
            var xx := x0 + (x1 - x0) * float(i) / float(n)
            top.append(Vector2(xx, float(lv.hill_y(xx)) + 3.0 + 1.5 * sin(t_all * 3.0 + xx * 0.06)))
            bot.append(Vector2(xx, float(lv.raw_y(xx)) + 2.0))
        var poly := PackedVector2Array(top)
        for k in range(bot.size() - 1, -1, -1):
            poly.append(bot[k])
        water.draw_colored_polygon(poly, Color(0.3, 0.62, 0.9, 0.55))
        water.draw_polyline(top, Color(0.85, 0.95, 1.0, 0.8), 2.5)

func _draw_fx() -> void:
    var font := ThemeDB.fallback_font
    for p in particles:
        var a := clampf(float(p.life) / float(p.max), 0.0, 1.0)
        var c: Color = p.c
        fx.draw_circle(p.p, float(p.r), Color(c.r, c.g, c.b, c.a * a))
    if state == "play":
        var pl := 0.5 + 0.5 * sin(t_all * 7.0)
        for ob in lv.brambles_near(hero.x + 500.0, 900.0):
            var ox: float = float(ob.cx)
            var oy: float = float(lv.hill_y(ox))
            fx.draw_set_transform(Vector2(ox, oy + 4.0), 0.0, Vector2(1.0, 0.22))
            fx.draw_circle(Vector2.ZERO, float(ob.w) * 0.75, Color(1.0, 0.1, 0.1, 0.22 + 0.2 * pl))
            fx.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
            var ty: float = oy - 78.0 - 8.0 * pl
            var tri := PackedVector2Array([Vector2(ox - 22.0, ty - 30.0), Vector2(ox + 22.0, ty - 30.0), Vector2(ox, ty)])
            fx.draw_colored_polygon(tri, Color(1.0, 0.15, 0.1, 0.9))
            fx.draw_polyline(PackedVector2Array([tri[0], tri[1], tri[2], tri[0]]), Color(1, 1, 1, 0.95), 3.0)
        for so in lv.solids_near(hero.x + 500.0, 900.0):
            var sx: float = float(so.cx)
            var sy: float = float(so.top)
            fx.draw_set_transform(Vector2(sx, float(so.gy) + 4.0), 0.0, Vector2(1.0, 0.2))
            fx.draw_circle(Vector2.ZERO, (float(so.x1) - float(so.x0)) * 0.7, Color(1.0, 0.7, 0.1, 0.2 + 0.18 * pl))
            fx.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
            var cy2: float = sy - 26.0 - 8.0 * pl
            fx.draw_polyline(PackedVector2Array([Vector2(sx - 20.0, cy2 - 18.0), Vector2(sx, cy2), Vector2(sx + 20.0, cy2 - 18.0)]), Color(1.0, 0.8, 0.1, 0.95), 6.0)
            fx.draw_polyline(PackedVector2Array([Vector2(sx - 20.0, cy2 - 36.0), Vector2(sx, cy2 - 18.0), Vector2(sx + 20.0, cy2 - 36.0)]), Color(1.0, 0.8, 0.1, 0.6), 6.0)
    if bark_t > 0.0:
        var bq := 1.0 - bark_t / 0.6
        for k in range(3):
            var rr := (bq + float(k) * 0.12) * 700.0
            fx.draw_arc(Vector2(hero.x, hero.y - 50.0), rr, 0.0, TAU, 48, Color(1.0, 0.95, 0.5, 0.7 * (1.0 - bq)), 5.0)
    if state == "play":
        var zc := int(floor(hero.x / CH))
        for ci2 in range(zc - 1, zc + 2):
            if not lv.chunks.has(ci2):
                continue
            var zch: Dictionary = lv.chunks[ci2]
            for zs in zch.zsigns:
                if absf(float(zs.x) - hero.x) > 900.0:
                    continue
                var zx: float = float(zs.x)
                var zy: float = float(zs.gy)
                if float(zs.spin) < 0.0:
                    fx.draw_string(font, Vector2(zx - 85.0, zy - 168.0), "PROSSIMA ZONA", HORIZONTAL_ALIGNMENT_CENTER, 170.0, 13, Color(0.35, 0.18, 0.05))
                    fx.draw_multiline_string(font, Vector2(zx - 85.0, zy - 145.0), ZONES[int(zs.zone)], HORIZONTAL_ALIGNMENT_CENTER, 170.0, 21, 3, Color(0.2, 0.08, 0.02))
                    if not bool(zs.got):
                        var bl := 0.5 + 0.5 * sin(t_all * 8.0)
                        fx.draw_string(font, Vector2(zx - 80.0, zy - 215.0 - 6.0 * bl), "SALTA QUI!", HORIZONTAL_ALIGNMENT_CENTER, 160.0, 24, Color(1.0, 0.9, 0.2, 0.6 + 0.4 * bl))
    if state == "balls":
        for bl2 in bballs:
            var bc: Color = bl2.col
            var bp2 := Vector2(float(bl2.x), float(bl2.y))
            fx.draw_circle(bp2, float(bl2.r) + 5.0, Color(bc.r, bc.g, bc.b, 0.25))
            fx.draw_circle(bp2, float(bl2.r), bc)
            fx.draw_circle(bp2 + Vector2(-float(bl2.r) * 0.3, -float(bl2.r) * 0.3), float(bl2.r) * 0.3, Color(1, 1, 1, 0.75))
    for hz in hazards:
        var tw2 := float(hz.t)
        if tw2 < 1.6:
            var pulse := 0.5 + 0.5 * sin(tw2 * 18.0)
            var wr := 30.0 + 40.0 * clampf(tw2 / 1.6, 0.0, 1.0)
            fx.draw_set_transform(Vector2(hz.x, float(hz.gy) + 2.0), 0.0, Vector2(1.0, 0.25))
            fx.draw_circle(Vector2.ZERO, wr, Color(1.0, 0.15, 0.1, 0.25 + 0.3 * pulse))
            fx.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
            if pulse > 0.4 and tw2 < 1.15:
                fx.draw_string(font, Vector2(float(hz.x) - 12.0, float(hz.gy) - 120.0), "!", HORIZONTAL_ALIGNMENT_CENTER, 24.0, 44, Color(1.0, 0.25, 0.15, 0.9))
    if bolt_t > 0.0 and (state == "play" or state == "respawn"):
        var hc := Vector2(hero.x, hero.y - 50.0)
        fx.draw_circle(hc, 95.0 + 10.0 * sin(t_all * 30.0), Color(1.0, 0.95, 0.3, 0.14))
        for k in range(3):
            var pts := PackedVector2Array()
            for j in range(6):
                pts.append(Vector2(hero.x - 30.0 - 60.0 * float(j), hero.y - 50.0 + sin(t_all * 47.0 + float(j) * 1.9 + float(k) * 2.7) * 34.0))
            fx.draw_polyline(pts, Color(1.0, 0.95, 0.4, 0.8), 3.0)
    for q in popups:
        var al := clampf(float(q.life) * 1.5, 0.0, 1.0)
        fx.draw_string_outline(font, q.p + Vector2(-140.0, 0.0), str(q.text), HORIZONTAL_ALIGNMENT_CENTER, 280.0, 22, 6, Color(0, 0, 0, al))
        fx.draw_string(font, q.p + Vector2(-140.0, 0.0), str(q.text), HORIZONTAL_ALIGNMENT_CENTER, 280.0, 22, Color(1.0, 0.95, 0.5, al))

# ---------------------------------------------------------------- interfaccia

func _txt(text: String, pos: Vector2, size: int, col: Color, width: float = -1.0, align: int = 0) -> void:
    var font := ThemeDB.fallback_font
    ui.draw_string_outline(font, pos, text, align, width, size, maxi(2, size / 5), Color(0, 0, 0, 0.85))
    ui.draw_string(font, pos, text, align, width, size, col)

func _btn(r: Rect2, col: Color, text: String, size: int) -> void:
    ui.draw_rect(r, col)
    ui.draw_rect(r, Color(1, 1, 1, 0.9), false, 3.0)
    _txt(text, Vector2(r.position.x, r.position.y + r.size.y * 0.5 + float(size) * 0.35), size, Color.WHITE, r.size.x, 1)

func _draw_ui() -> void:
    var CEN := HORIZONTAL_ALIGNMENT_CENTER
    if state == "menu":
        _txt("LUCIFERO", Vector2(0, vh * 0.17), 70, Color(0.95, 0.35, 0.25), vw, CEN)
        _txt("contro", Vector2(0, vh * 0.255), 34, Color.WHITE, vw, CEN)
        _txt("NIKITA", Vector2(0, vh * 0.378), 70, Color(0.95, 0.95, 1.0), vw, CEN)
        _btn(_play_rect(), Color(0.85, 0.35, 0.10, 0.95), "GIOCA", 34)
        _btn(_music_rect(), Color(0.10, 0.35, 0.55, 0.92), "Musica: " + ("SI" if music_on else "NO"), 19)
        _btn(_sound_rect(), Color(0.10, 0.35, 0.55, 0.92), "Suoni: " + ("SI" if sound_on else "NO"), 19)
        if pad_mode or not Input.get_connected_joypads().is_empty():
            _txt("Controller:  A = GIOCA    Y = Musica    X = Suoni", Vector2(0, vh * 0.54 + 150.0), 18, Color(1.0, 0.95, 0.6), vw, CEN)
        ui.draw_rect(Rect2(14, 14, 232, 176), Color(0, 0, 0, 0.45))
        _txt("RECORD", Vector2(24, 40), 22, Color(1.0, 0.85, 0.3))
        for i in range(5):
            var v := "-"
            if i < best_scores.size():
                v = str(best_scores[i])
            _txt(str(i + 1) + ".  " + v, Vector2(28, 66 + i * 21), 17, Color.WHITE)
        _txt("Zona max: " + str(best_zone) + "/8   Vittorie: " + str(wins), Vector2(24, 180), 14, Color(0.85, 0.9, 1.0))
        return
    _draw_hud()
    if state == "ready":
        var msg := "PRONTI..." if state_t < ready_len - 0.7 else "VIA!"
        _txt(msg, Vector2(0, vh * 0.37), 64, Color(1.0, 0.9, 0.3), vw, CEN)
    if banner_t > 0.0:
        var al := clampf(banner_t, 0.0, 1.0)
        _txt(("PRENDI LE PALLINE!" if state == "balls" else "ZONA STELLATA!") if _in_sky() else ZONES[stage], Vector2(0, vh * 0.28), 40, Color(1, 1, 1, al), vw, CEN)
    if state == "over" or state == "won":
        if state_t > 1.0:
            var px := vw * 0.5 - 230.0
            ui.draw_rect(Rect2(px, 90, 460, 330), Color(0.02, 0.04, 0.08, 0.88))
            ui.draw_rect(Rect2(px, 90, 460, 330), Color(1, 1, 1, 0.85), false, 3.0)
            var title := "SEI SALVO!" if state == "won" else "FINE PARTITA"
            _txt(title, Vector2(px, 140), 42, Color(1.0, 0.85, 0.3) if state == "won" else Color(0.95, 0.4, 0.3), 460.0, CEN)
            _txt("Punteggio: " + str(final_score), Vector2(px, 186), 28, Color.WHITE, 460.0, CEN)
            _txt("Segreti: " + str(gems_n) + "/" + str(lv.gem_total) + "   Ossa: " + str(bones_n), Vector2(px, 214), 18, Color(0.7, 0.9, 1.0), 460.0, CEN)
            if new_record:
                _txt("NUOVO RECORD!", Vector2(px, 246), 26, Color(0.4, 1.0, 0.5), 460.0, CEN)
            for i in range(mini(5, best_scores.size())):
                _txt(str(i + 1) + ".  " + str(best_scores[i]), Vector2(px, 282 + i * 24), 19, Color(0.9, 0.95, 1.0), 460.0, CEN)
            _txt("Premi A per tornare al menu" if pad_mode else "Tocca per tornare al menu", Vector2(px, 408), 18, Color(0.8, 0.8, 0.85), 460.0, CEN)

func _draw_hud() -> void:
    var CEN := HORIZONTAL_ALIGNMENT_CENTER
    var nx: String = "n_" + str(hero_rig.expr)
    var wxn: String = "w_" + str(wolf_rig.expr)
    var tn := _tex(nx)
    var tw := _tex(wxn)
    ui.draw_rect(Rect2(8, 6, 76, 76), Color(0, 0, 0, 0.35))
    ui.draw_rect(Rect2(vw - 84.0, 6, 76, 76), Color(0, 0, 0, 0.35))
    if tn != null:
        ui.draw_texture_rect(tn, Rect2(10, 8, 72, 72), false)
    if tw != null:
        ui.draw_texture_rect(tw, Rect2(vw - 82.0, 8, 72, 72), false)
    var ht := _tex("heart")
    for i in range(lives):
        if ht != null:
            ui.draw_texture_rect(ht, Rect2(92 + i * 28, 12, 26, 24), false)
    var bt := _tex("bone")
    if bt != null:
        ui.draw_texture_rect(bt, Rect2(92, 44, 32, 16), false)
    _txt("x" + str(bones_n), Vector2(128, 58), 18, Color.WHITE)
    var tt := _tex("trap_open")
    if tt != null:
        ui.draw_texture_rect(tt, Rect2(176, 40, 36, 15), false)
    _txt("x" + str(traps), Vector2(216, 58), 18, Color.WHITE)
    var gt := _tex("gem")
    if gt != null:
        ui.draw_texture_rect(gt, Rect2(92, 66, 18, 20), false)
    _txt("x" + str(gems_n) + "/" + str(lv.gem_total), Vector2(114, 82), 15, Color(0.6, 0.9, 1.0))
    _txt("PUNTI " + str(int(score_f)), Vector2(0, 32), 28, Color.WHITE, vw, CEN)
    _txt(("PALLINE: " + str(balls_n) + "   TEMPO: " + str(maxi(0, int(ceil(balls_t))))) if state == "balls" else "ZONA STELLATA - salta sulle stelle e sulle nuvole!" if _in_sky() else (ZONES[stage] + "  -  " + str(int(hero.x / 50.0)) + " / " + str(int(TOTAL / 50.0)) + " m"), Vector2(0, 56), 17, Color(0.9, 0.95, 1.0), vw, CEN)
    # barra di pericolo del lupo
    var dist := clampf(hero.x - wolf.x, 0.0, 700.0)
    var fill := 1.0 - dist / 700.0
    var bx := vw - 270.0
    ui.draw_rect(Rect2(bx, 30, 170, 14), Color(0, 0, 0, 0.5))
    ui.draw_rect(Rect2(bx, 30, 170.0 * fill, 14), Color(1.0, 0.3 + 0.4 * (1.0 - fill), 0.15))
    ui.draw_rect(Rect2(bx, 30, 170, 14), Color(1, 1, 1, 0.8), false, 2.0)
    _txt("LUPO", Vector2(bx, 62), 14, Color(1, 0.8, 0.7))
    var spd := int(absf(hero.vx) / 10.0)
    _txt(str(spd) + " km/h", Vector2(bx + 80.0, 62), 14, Color(0.9, 0.95, 1.0))
    if bolt_t > 0.0:
        _txt("TURBO FULMINE!", Vector2(0, 84), 20, Color(1.0, 0.95, 0.3), vw, CEN)
        ui.draw_rect(Rect2(vw * 0.5 - 100.0, 92, 200, 11), Color(0, 0, 0, 0.55))
        ui.draw_rect(Rect2(vw * 0.5 - 100.0, 92, 200.0 * bolt_t / BOLT_TIME, 11), Color(1.0, 0.88, 0.15))
        ui.draw_rect(Rect2(vw * 0.5 - 100.0, 92, 200, 11), Color(1, 1, 1, 0.8), false, 2.0)
    if sjump_t > 0.0:
        _txt("SUPER SALTO IN ALTO", Vector2(0, 112), 18, Color(0.5, 0.8, 1.0), vw, CEN)
        ui.draw_rect(Rect2(vw * 0.5 - 100.0, 120, 200, 10), Color(0, 0, 0, 0.55))
        ui.draw_rect(Rect2(vw * 0.5 - 100.0, 120, 200.0 * sjump_t / 8.0, 10), Color(0.35, 0.7, 1.0))
    if sleap_t > 0.0:
        _txt("SUPER SALTO IN LUNGO", Vector2(0, 140), 18, Color(0.5, 1.0, 0.55), vw, CEN)
        ui.draw_rect(Rect2(vw * 0.5 - 100.0, 148, 200, 10), Color(0, 0, 0, 0.55))
        ui.draw_rect(Rect2(vw * 0.5 - 100.0, 148, 200.0 * sleap_t / 8.0, 10), Color(0.3, 0.9, 0.4))
    if bolt_t > 0.0:
        pass
    elif boost_t > 0.0:
        _txt("SCATTO!", Vector2(0, 84), 20, Color(1.0, 0.9, 0.3), vw, CEN)
    # linee di velocita'
    if absf(hero.vx) > 620.0 or boost_t > 0.0 or bolt_t > 0.0:
        for k in range(8):
            var ly := fposmod(float(k) * 71.0 + t_all * 40.0, vh)
            var lx := fposmod(float(k) * 193.0 - t_all * 2400.0, vw + 200.0) - 100.0
            ui.draw_line(Vector2(lx, ly), Vector2(lx + 90.0, ly), Color(1, 1, 1, 0.22), 2.0)
    # comandi
    if pad_mode:
        _txt("A salta   X trappola   " + ("B abbaio" if bark_cd <= 0.0 else "abbaio tra " + str(int(ceil(bark_cd))) + "s"), Vector2(0, vh - 18.0), 16, Color(1, 1, 1, 0.75), vw, CEN)
        return
    var jc := _jump_c()
    ui.draw_circle(jc, JUMP_RAD, Color(0.15, 0.55, 0.85, 0.55 if jump_id < 0 else 0.85))
    ui.draw_arc(jc, JUMP_RAD, 0, TAU, 40, Color.WHITE, 3.0)
    _txt("SALTA", jc + Vector2(-60, 8), 22, Color.WHITE, 120.0, CEN)
    var tc := _trap_c()
    var can_trap := traps > 0 and trap_cd <= 0.0
    ui.draw_circle(tc, TRAP_RAD, Color(0.82, 0.2, 0.1, 0.65) if can_trap else Color(0.35, 0.35, 0.35, 0.6))
    ui.draw_arc(tc, TRAP_RAD, 0, TAU, 40, Color.WHITE, 3.0)
    _txt("TRAPPOLA", tc + Vector2(-50, 6), 15, Color.WHITE, 100.0, CEN)
    _txt("SALTO+TRAPPOLA = ABBAIO" if bark_cd <= 0.0 else "ABBAIO tra " + str(int(ceil(bark_cd))) + "s", tc + Vector2(-70, 66), 12, Color(1.0, 0.95, 0.5) if bark_cd <= 0.0 else Color(0.8, 0.8, 0.8), 190.0, CEN)
    var jo := joy_origin if joy_id >= 0 else _joy_def()
    ui.draw_circle(jo, JOY_R, Color(0.02, 0.03, 0.04, 0.35))
    ui.draw_arc(jo, JOY_R, 0, TAU, 40, Color(1, 1, 1, 0.8), 3.0)
    ui.draw_line(jo + Vector2(-JOY_R + 12.0, 0), jo + Vector2(JOY_R - 12.0, 0), Color(1, 1, 1, 0.25), 2.0)
    ui.draw_circle(jo + Vector2(move_x * (JOY_R - 22.0), 0), 22.0, Color(0.9, 0.93, 0.97, 0.9))
    if joy_id < 0:
        _txt("MUOVI", jo + Vector2(-60, 98), 15, Color.WHITE, 120.0, CEN)

# ---------------------------------------------------------------- comandi

func _tap(pos: Vector2) -> void:
    if state == "menu":
        if _play_rect().has_point(pos):
            audio.play("tap", -4.0, 1.0)
            _start_game()
        elif _music_rect().has_point(pos):
            music_on = not music_on
            audio.set_music_enabled(music_on)
            _save_records()
        elif _sound_rect().has_point(pos):
            sound_on = not sound_on
            audio.set_sound_enabled(sound_on)
            _save_records()
    elif state == "over" or state == "won":
        if state_t > 1.0:
            _enter_menu()

func _press(pos: Vector2, idx: int) -> void:
    if state == "menu" or state == "over" or state == "won":
        _tap(pos)
        return
    if pos.distance_to(_jump_c()) < JUMP_RAD + 42.0:
        jump_id = idx
        jump_buf = 0.22
        jump_hold = true
        return
    if pos.distance_to(_trap_c()) < TRAP_RAD + 14.0:
        if jump_hold:
            _bark()
        else:
            _drop_trap()
        return
    if pos.x >= vw * 0.42 and joy_id < 0:
        joy_id = idx
        joy_origin = pos
        move_x = 0.0

func _release(idx: int) -> void:
    if idx == jump_id:
        jump_id = -1
        jump_hold = false
    if idx == joy_id:
        joy_id = -1
        move_x = 0.0

func _drag(pos: Vector2, idx: int) -> void:
    if idx != joy_id:
        return
    var dx := pos.x - joy_origin.x
    if absf(dx) > JOY_R:
        joy_origin.x = pos.x - signf(dx) * JOY_R
        dx = signf(dx) * JOY_R
    var v := clampf(dx / 48.0, -1.0, 1.0)
    move_x = 0.0 if absf(v) < 0.18 else v

func _input(event: InputEvent) -> void:
    if event is InputEventJoypadButton:
        _pad_button(event)
        return
    if event is InputEventScreenTouch:
        pad_mode = false
        if event.pressed:
            _press(event.position, event.index)
        else:
            _release(event.index)
    elif event is InputEventScreenDrag:
        _drag(event.position, event.index)
    elif event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
        if event.pressed:
            _press(event.position, 100)
        else:
            _release(100)
    elif event is InputEventMouseMotion:
        _drag(event.position, 100)
    elif event is InputEventKey and event.pressed and not event.echo:
        if event.keycode == KEY_SPACE or event.keycode == KEY_UP or event.keycode == KEY_W:
            jump_buf = 0.22
            jump_hold = true
        elif event.keycode == KEY_B or event.keycode == KEY_F:
            _bark()
        elif event.keycode == KEY_T or event.keycode == KEY_E:
            if jump_hold:
                _bark()
            else:
                _drop_trap()
        elif event.keycode == KEY_ENTER:
            _tap(_play_rect().get_center())
    elif event is InputEventKey and not event.pressed:
        if event.keycode == KEY_SPACE or event.keycode == KEY_UP or event.keycode == KEY_W:
            jump_hold = false

# pulsanti del controller (Xbox: A salta, X trappola, B abbaio)
func _pad_button(ev: InputEventJoypadButton) -> void:
    pad_mode = true
    var b := ev.button_index
    if not ev.pressed:
        if b == JOY_BUTTON_A or b == JOY_BUTTON_DPAD_UP:
            jump_hold = false
        return
    if state == "menu":
        if b == JOY_BUTTON_A or b == JOY_BUTTON_START:
            _tap(_play_rect().get_center())
        elif b == JOY_BUTTON_Y:
            _tap(_music_rect().get_center())
        elif b == JOY_BUTTON_X:
            _tap(_sound_rect().get_center())
        return
    if state == "over" or state == "won":
        if b == JOY_BUTTON_A or b == JOY_BUTTON_START:
            _tap(Vector2.ZERO)
        return
    if b == JOY_BUTTON_A or b == JOY_BUTTON_DPAD_UP:
        jump_buf = 0.22
        jump_hold = true
    elif b == JOY_BUTTON_X or b == JOY_BUTTON_RIGHT_SHOULDER:
        if jump_hold:
            _bark()
        else:
            _drop_trap()
    elif b == JOY_BUTTON_B or b == JOY_BUTTON_Y or b == JOY_BUTTON_LEFT_SHOULDER:
        _bark()
