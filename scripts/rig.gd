extends Node2D
# Personaggio articolato (vista laterale): Nikita ("n") o Lucifero ("w").
# I piedi sono nell'origine; guarda verso +x (si specchia con scale.x).
# Corpo = posteriore + torace (la colonna si flette), zampe a due segmenti, coda, testa di profilo o frontale.

const TexLib := preload("res://scripts/texlib.gd")
const A := "res://assets/"
const D := {
    "n": {"rear": Vector2(140, 60), "chest": Vector2(12, 66), "up": Vector2(22, 6), "low": Vector2(17, 4), "tail": Vector2(120, 60),
        "hind": Vector2(-38, 6), "front": Vector2(28, 4), "headr": Vector2(62, -14), "tailr": Vector2(-60, -15), "jlen": 26.0,
        "hs_front": 0.30, "hs_prof": 0.46, "p_pivot": Vector2(80, 84), "ear_pos": Vector2(-10, -44), "ear_pivot": Vector2(36, 8),
        "ear_behind": false, "waist": -62.0, "stand_y": -104.0, "shorten": 12.0},
    "w": {"rear": Vector2(152, 64), "chest": Vector2(12, 72), "up": Vector2(24, 6), "low": Vector2(19, 4), "tail": Vector2(160, 84),
        "hind": Vector2(-42, 8), "front": Vector2(30, 4), "headr": Vector2(68, -14), "tailr": Vector2(-68, -18), "jlen": 28.0,
        "hs_front": 0.34, "hs_prof": 0.46, "p_pivot": Vector2(96, 92), "ear_pos": Vector2(-16, -42), "ear_pivot": Vector2(38, 86),
        "ear_behind": true, "waist": -66.0, "stand_y": -108.0, "shorten": 13.0},
}
const TURN_T := 0.18

var kind := "n"
var d := {}
var body: Node2D
var rear: Node2D
var chest: Node2D
var tail_root: Node2D
var head_root: Node2D
var head: Sprite2D
var ear: Sprite2D
var legs: Array = []
var expr := "happy"
var blink := 0.0
var next_blink := 2.0
var phase := 0.0
var stand := 0.0
var sit := 0.0
var t := 0.0
var base_scale := 1.0
var tex_cache := {}
var squash := 0.0
var was_grounded := true
var last_air_vy := 0.0
var front_goal := true
var front_cur := true
var turn_t := 0.0
var cad := 0.0
var swapped := true

func setup(k: String, sc: float) -> void:
    kind = k
    base_scale = sc
    d = D[k]
    expr = "happy" if k == "n" else "grin"
    body = Node2D.new()
    add_child(body)
    rear = Node2D.new()
    body.add_child(rear)
    rear.position = Vector2(float(d.shorten), 0.0)
    chest = Node2D.new()
    body.add_child(chest)
    # posteriore: coda, zampa lontana, corpo, zampa vicina
    tail_root = Node2D.new()
    tail_root.position = d.tailr
    rear.add_child(tail_root)
    tail_root.add_child(_spr(k + "_tail", d.tail, 0.5))
    legs.append(_leg(rear, d.hind, true))
    rear.add_child(_spr(k + "_rear", d.rear, 0.5))
    legs.append(_leg(rear, d.hind, false))
    # torace: zampa lontana, corpo, zampa vicina, testa
    legs.append(_leg(chest, d.front, true))
    chest.add_child(_spr(k + "_chest", d.chest, 0.5))
    legs.append(_leg(chest, d.front, false))
    head_root = Node2D.new()
    head_root.position = d.headr
    chest.add_child(head_root)
    head = Sprite2D.new()
    head.centered = false
    head_root.add_child(head)
    ear = Sprite2D.new()
    ear.centered = false
    ear.texture = _tex(k + "_ear")
    ear.offset = -d.ear_pivot
    ear.position = d.ear_pos
    ear.show_behind_parent = d.ear_behind
    head.add_child(ear)
    queue_redraw()
    front_cur = true
    _apply_head()
    pose(0.0, 0.0, true, 0.0, 0.0, 1)

func _tex(n: String) -> Texture2D:
    return TexLib.get_tex(n)

func _spr(n: String, pivot: Vector2, sc: float) -> Sprite2D:
    var s := Sprite2D.new()
    s.texture = _tex(n)
    s.centered = false
    s.offset = -pivot
    s.scale = Vector2(sc, sc)
    return s

func _leg(parent: Node2D, pos: Vector2, far: bool) -> Dictionary:
    var root := Node2D.new()
    root.position = pos
    var up := _spr(kind + "_up", d.up, 0.5)
    root.add_child(up)
    var jnt := Node2D.new()
    jnt.position = Vector2(0, d.jlen)
    root.add_child(jnt)
    var low := _spr(kind + "_low", d.low, 0.5)
    jnt.add_child(low)
    if far:
        up.modulate = Color(0.68, 0.68, 0.74)
        low.modulate = Color(0.68, 0.68, 0.74)
    parent.add_child(root)
    return {"root": root, "jnt": jnt}

func _draw() -> void:
    draw_set_transform(Vector2(0, 2), 0.0, Vector2(1.0, 0.2))
    draw_circle(Vector2.ZERO, 62.0, Color(0, 0, 0, 0.28))

func set_expr(e: String) -> void:
    if e == expr:
        return
    expr = e
    if front_cur:
        _apply_head()

func set_front(f: bool) -> void:
    front_goal = f

func _apply_head() -> void:
    var b := "_b" if blink > 0.0 else ""
    if front_cur:
        var tx := _tex(kind + "_" + expr + b)
        if tx == null:
            tx = _tex(kind + "_" + expr)
        head.texture = tx
        head.offset = -Vector2(120, 120)
        head.scale = Vector2(d.hs_front, d.hs_front)
        ear.visible = false
    else:
        var tp := _tex(kind + "_p_run" + b)
        if tp == null:
            tp = _tex(kind + "_p_run")
        head.texture = tp
        head.offset = -d.p_pivot
        head.scale = Vector2(d.hs_prof, d.hs_prof)
        ear.visible = true

func pose(dt: float, speed: float, grounded: bool, vy: float, stand_goal: float, face: int, skid: bool = false, crouch: float = 0.0, hurt: bool = false, sit_goal: float = 0.0) -> void:
    t += dt
    stand = move_toward(stand, stand_goal, dt * 3.2)
    sit = move_toward(sit, sit_goal if stand_goal > 0.5 else 0.0, dt * 2.5)
    if not grounded:
        last_air_vy = vy
    elif not was_grounded and last_air_vy > 380.0:
        squash = 0.28
    was_grounded = grounded
    squash = maxf(0.0, squash - dt)
    var sq := squash / 0.28
    var sx := 1.0 + 0.10 * sq
    var sy := 1.0 - 0.14 * sq - 0.12 * crouch
    if not grounded:
        sy += clampf(-vy / 6000.0, -0.05, 0.1)
        sx -= clampf(-vy / 12000.0, -0.03, 0.05)
    scale = Vector2(float(face) * base_scale * sx, base_scale * sy)
    # sbattere le palpebre
    next_blink -= dt
    if blink > 0.0:
        blink -= dt
        if blink <= 0.0:
            blink = 0.0
            _apply_head()
    elif next_blink <= 0.0:
        blink = 0.13
        next_blink = randf_range(1.6, 4.2)
        _apply_head()
    # giro della testa verso la camera / in avanti
    if front_cur != front_goal and turn_t <= 0.0:
        turn_t = TURN_T
        swapped = false
    var turn_f := 1.0
    if turn_t > 0.0:
        turn_t = maxf(0.0, turn_t - dt)
        var p := 1.0 - turn_t / TURN_T
        turn_f = absf(cos(p * PI))
        if p >= 0.5 and not swapped:
            front_cur = front_goal
            swapped = true
            _apply_head()
    var hs: float = d.hs_front if front_cur else d.hs_prof
    head.scale = Vector2(hs * maxf(0.05, turn_f), hs)

    var run := clampf(absf(speed) / 520.0, 0.0, 1.6)
    var moving := run > 0.04
    var cad_goal := clampf(absf(speed) / 520.0, 0.0, 2.9) if grounded else cad
    cad = move_toward(cad, cad_goal, dt * 5.0)
    if grounded and moving:
        phase += dt * (2.0 + cad * 12.5)
    var gal := smoothstep(0.55, 1.0, run)
    var amp := minf(0.9, 0.42 + 0.36 * minf(run, 1.3)) if moving else 0.0
    var bob := 0.0
    if grounded and moving:
        bob = absf(sin(phase)) * (2.5 + 3.5 * run)
    else:
        bob = sin(t * 2.2) * 1.0
    var pitch := 0.04 * run * gal + sin(phase) * 0.05 * gal
    var spine := sin(phase + 0.3) * 0.10 * gal * minf(run, 1.2)
    var head_abs := sin(phase * 2.0) * 0.05 * run
    var tail_abs := 0.2 + 0.25 * run + sin(t * 9.0) * 0.18 * (0.4 + run)
    # angoli assoluti delle 4 zampe: [a, b] (a = rotazione del segmento alto, b = piegatura del basso)
    var ang: Array = []
    var offs_trot := [0.0, PI, PI, 0.0]
    var offs_gal := [2.9, 2.4, 0.5, 0.0]
    for i in range(4):
        var ph := phase + lerpf(offs_trot[i], offs_gal[i], gal)
        var a := amp * sin(ph)
        var swing := maxf(0.0, -cos(ph))
        var bnd := swing * (1.3 if i >= 2 else 1.1) * clampf(run * 1.4, 0.0, 1.0)
        bnd -= 0.15 * maxf(0.0, cos(ph)) * clampf(run, 0.0, 1.0)
        a += (-0.12 if i >= 2 else 0.12) * gal
        ang.append(Vector2(a, bnd))
    if not grounded:
        if vy < 0.0:
            ang = [Vector2(0.95, -0.1), Vector2(0.75, -0.05), Vector2(-0.95, 0.25), Vector2(-0.75, 0.15)]
            pitch = -0.2
            head_abs = -0.15
        else:
            ang = [Vector2(0.35, 0.6), Vector2(0.25, 0.5), Vector2(-0.45, 0.5), Vector2(-0.3, 0.4)]
            pitch = 0.12
        tail_abs = 0.7
        bob = 0.0
        spine = 0.0
    elif skid:
        ang = [Vector2(0.25, 0.45), Vector2(0.15, 0.4), Vector2(-0.75, 0.15), Vector2(-0.6, 0.1)]
        pitch = -0.3
        head_abs = -0.12
        tail_abs = -0.1
        spine = 0.0
    if crouch > 0.0:
        for i2 in range(4):
            var v: Vector2 = ang[i2]
            ang[i2] = Vector2(v.x + (0.3 if i2 < 2 else -0.5) * crouch, v.y + 0.4 * crouch)
        pitch += 0.1 * crouch
    if hurt:
        head_abs += sin(t * 35.0) * 0.2
        for i3 in range(4):
            var v2: Vector2 = ang[i3]
            ang[i3] = Vector2(v2.x + sin(t * 28.0 + float(i3)) * 0.35, v2.y)
    var se := smoothstep(0.0, 1.0, stand)
    var ss := smoothstep(0.0, 1.0, sit)
    # pose in piedi (bipede) e seduta: angoli assoluti
    var st_ang := [Vector2(0.0, 0.0), Vector2(0.05, 0.1), Vector2(-0.1, 0.4), Vector2(-0.05, 0.3)]
    var sit_ang := [Vector2(-1.1, 2.2), Vector2(-1.0, 2.0), Vector2(0.05, 0.1), Vector2(0.0, 0.05)]
    var brot := lerpf(pitch, -1.2, se)
    brot = lerpf(brot, -0.95, ss)
    var by: float = float(d.waist) - bob + 6.0 * crouch
    by = lerpf(by, d.stand_y, se)
    by = lerpf(by, -60.0, ss)
    body.position = Vector2(lerpf(0.0, -4.0, se), by)
    body.rotation = brot
    var sp := spine * (1.0 - se)
    rear.rotation = sp
    chest.rotation = -sp
    for i4 in range(4):
        var a_run: Vector2 = ang[i4]
        var a_st: Vector2 = st_ang[i4]
        var a_sit: Vector2 = sit_ang[i4]
        var av: Vector2 = a_run.lerp(a_st, se).lerp(a_sit, ss)
        var parent_rot := rear.rotation if i4 < 2 else chest.rotation
        var lg: Dictionary = legs[i4]
        var root: Node2D = lg.root
        var jnt: Node2D = lg.jnt
        root.rotation = av.x - brot - parent_rot
        jnt.rotation = av.y
    var hang := lerpf(head_abs, 0.1 + sin(t * 0.9) * 0.08, se)
    head_root.rotation = hang - brot - chest.rotation
    var hoff := Vector2(6.0 * gal, 4.0 * gal) * (1.0 - se)
    head_root.position = Vector2(d.headr) + hoff + Vector2(0.0, sin(phase * 2.0) * 1.5 * run)
    var tabs := lerpf(tail_abs, -1.27 + sin(t * 3.5) * 0.25, se)
    tabs = lerpf(tabs, -0.5 + sin(t * 3.0) * 0.3, ss)
    tail_root.rotation = tabs - brot - rear.rotation
    # orecchio che sventola
    if ear.visible:
        var flap := sin(t * (6.0 + run * 12.0)) * (0.1 + 0.18 * run)
        if kind == "n":
            ear.rotation = 0.25 + flap + (0.35 if not grounded else 0.0) * 0.5
        else:
            ear.rotation = -0.2 + flap * 0.4 - 0.4 * run * 0.5
