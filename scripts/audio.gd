extends Node
# Suoni e musica generati da codice (nessun file audio): passi, abbaio, ruscello, vento, pioggia, musica.

const RATE := 22050
const LRATE := 11025

var sfx := {}
var pool: Array[AudioStreamPlayer] = []
var pool_i := 0
var loops := {}
var music_p: AudioStreamPlayer
var music_cache := {}
var music_stage := -1
var sound_on := true
var music_on := true

func _ready() -> void:
    for i in range(10):
        var p := AudioStreamPlayer.new()
        add_child(p)
        pool.append(p)
    music_p = AudioStreamPlayer.new()
    music_p.volume_db = -13.0
    add_child(music_p)
    _build_async()

# I suoni vengono creati a gruppi, un po' per volta, cosi' l'avvio non si blocca.
func _build_async() -> void:
    await get_tree().process_frame
    _build_sfx_a()
    await get_tree().process_frame
    _build_sfx_b()
    await get_tree().process_frame
    _build_sfx_c()
    await get_tree().process_frame
    await _build_loops()

# ---- Utilità di sintesi ------------------------------------------------------

func _wav(samples: PackedFloat32Array, rate: int, loop: bool) -> AudioStreamWAV:
    var bytes := PackedByteArray()
    bytes.resize(samples.size() * 2)
    for i in range(samples.size()):
        bytes.encode_s16(i * 2, int(clampf(samples[i], -1.0, 1.0) * 32000.0))
    var w := AudioStreamWAV.new()
    w.format = AudioStreamWAV.FORMAT_16_BITS
    w.mix_rate = rate
    w.stereo = false
    w.data = bytes
    if loop:
        w.loop_mode = AudioStreamWAV.LOOP_FORWARD
        w.loop_begin = 0
        w.loop_end = samples.size()
    return w

func _buf(seconds: float, rate: int = RATE) -> PackedFloat32Array:
    var a := PackedFloat32Array()
    a.resize(int(seconds * float(rate)))
    return a

# Rende un buffer ciclico senza scatti sfumando la coda con l'inizio.
func _loopify(gen: PackedFloat32Array, fade: int) -> PackedFloat32Array:
    var n := gen.size() - fade
    var out := PackedFloat32Array()
    out.resize(n)
    for i in range(n):
        if i < fade:
            var k := float(i) / float(fade)
            out[i] = gen[i] * k + gen[n + i] * (1.0 - k)
        else:
            out[i] = gen[i]
    return out

func _noise_burst(dur: float, lp: float, decay: float, hp: bool, gain: float) -> PackedFloat32Array:
    var a := _buf(dur)
    var y := 0.0
    for i in range(a.size()):
        var t := float(i) / float(RATE)
        var x := randf_range(-1.0, 1.0)
        y += lp * (x - y)
        var v := (x - y) if hp else y
        a[i] = v * exp(-t * decay) * gain
    return a

func _add(dst: PackedFloat32Array, src: PackedFloat32Array, at: int, gain: float) -> void:
    for i in range(src.size()):
        var j := at + i
        if j >= dst.size():
            break
        dst[j] += src[i] * gain

func _tone(dur: float, f0: float, f1: float, decay: float, harm: float, gain: float, rate: int = RATE) -> PackedFloat32Array:
    var a := _buf(dur, rate)
    var ph := 0.0
    for i in range(a.size()):
        var t := float(i) / float(rate)
        var f := lerpf(f0, f1, t / dur)
        ph += TAU * f / float(rate)
        var env := exp(-t * decay) * (1.0 - exp(-t * 300.0))
        a[i] = (sin(ph) + harm * sin(ph * 2.0) + harm * 0.5 * sin(ph * 3.0)) * env * gain
    return a

func _bark(f0: float, dur: float, gain: float, rough: float) -> PackedFloat32Array:
    var a := _buf(dur)
    var ph := 0.0
    var lp := 0.0
    for i in range(a.size()):
        var t := float(i) / float(RATE)
        var rel := fmod(t, dur * 0.5) / (dur * 0.5)
        var f := f0 * (1.0 - 0.4 * rel)
        ph += TAU * f / float(RATE)
        var v := 0.0
        for h in range(1, 6):
            v += sin(ph * float(h)) / float(h)
        v += randf_range(-1.0, 1.0) * rough
        lp += 0.35 * (v - lp)
        var env := sin(PI * minf(rel * 1.2, 1.0)) * exp(-rel * 1.5)
        a[i] = lp * env * gain
    return a

# ---- Effetti sonori --------------------------------------------------------------

func _build_sfx_a() -> void:
    sfx["step_dirt"] = _wav(_step_dirt(), RATE, false)
    sfx["step_stone"] = _wav(_noise_burst(0.09, 0.55, 55.0, true, 0.9), RATE, false)
    sfx["splash"] = _wav(_splash(), RATE, false)
    sfx["bark_n"] = _wav(_bark(560.0, 0.34, 0.55, 0.12), RATE, false)
    sfx["bark_l"] = _wav(_bark(230.0, 0.5, 0.65, 0.28), RATE, false)
    sfx["growl"] = _wav(_growl(), RATE, false)
    sfx["yelp"] = _wav(_tone(0.30, 1100.0, 560.0, 5.0, 0.3, 0.5), RATE, false)
    sfx["jump"] = _wav(_whoosh(0.22, 1.0), RATE, false)

func _build_sfx_b() -> void:
    sfx["land"] = _wav(_step_dirt(), RATE, false)
    sfx["fall"] = _wav(_fall(), RATE, false)
    sfx["pickup"] = _wav(_arp([659.0, 880.0, 1319.0], 0.07, 7.0), RATE, false)
    sfx["heart"] = _wav(_arp([523.0, 659.0, 784.0, 1047.0], 0.09, 5.0), RATE, false)
    sfx["checkpoint"] = _wav(_bell(), RATE, false)
    sfx["trap_set"] = _wav(_click(), RATE, false)
    sfx["trap_snap"] = _wav(_snap(), RATE, false)
    sfx["hit"] = _wav(_hit(), RATE, false)

func _build_sfx_c() -> void:
    sfx["win"] = _wav(_arp([523.0, 659.0, 784.0, 1047.0, 1319.0, 1568.0], 0.13, 3.0), RATE, false)
    sfx["lose"] = _wav(_arp([523.0, 440.0, 349.0, 262.0], 0.2, 2.5), RATE, false)
    sfx["tap"] = _wav(_tone(0.08, 880.0, 880.0, 30.0, 0.2, 0.5), RATE, false)
    sfx["bird1"] = _wav(_chirp(3000.0, 4300.0), RATE, false)
    sfx["bird2"] = _wav(_chirp(2400.0, 3600.0), RATE, false)
    sfx["snort"] = _wav(_noise_burst(0.28, 0.12, 9.0, false, 1.2), RATE, false)
    sfx["chatter"] = _wav(_chatter(), RATE, false)
    sfx["drip"] = _wav(_tone(0.5, 1500.0, 1000.0, 9.0, 0.1, 0.45), RATE, false)
    sfx["zap"] = _wav(_zap(), RATE, false)
    sfx["boom"] = _wav(_noise_burst(0.5, 0.18, 6.0, false, 1.4), RATE, false)
    sfx["screech"] = _wav(_chirp(5200.0, 2600.0), RATE, false)

func _step_dirt() -> PackedFloat32Array:
    var a := _noise_burst(0.12, 0.22, 34.0, false, 1.6)
    _add(a, _tone(0.10, 110.0, 70.0, 30.0, 0.0, 0.6), 0, 1.0)
    return a

func _splash() -> PackedFloat32Array:
    var a := _buf(0.38)
    var y1 := 0.0
    var y2 := 0.0
    for i in range(a.size()):
        var t := float(i) / float(RATE)
        var x := randf_range(-1.0, 1.0)
        y1 += 0.5 * (x - y1)
        y2 += 0.06 * (x - y2)
        a[i] = (y1 - y2) * (1.0 - exp(-t * 80.0)) * exp(-t * 8.0) * 1.3
    return a

func _growl() -> PackedFloat32Array:
    var a := _buf(0.7)
    var ph := 0.0
    var lp := 0.0
    for i in range(a.size()):
        var t := float(i) / float(RATE)
        ph += TAU * (95.0 + 12.0 * sin(t * 9.0)) / float(RATE)
        var v := sin(ph) + 0.6 * sin(ph * 2.0) + 0.4 * sin(ph * 3.0) + randf_range(-0.4, 0.4)
        v *= 0.6 + 0.4 * sin(t * TAU * 38.0)
        lp += 0.3 * (v - lp)
        a[i] = lp * sin(PI * t / 0.7) * 0.8
    return a

func _whoosh(dur: float, gain: float) -> PackedFloat32Array:
    var a := _buf(dur)
    var y := 0.0
    for i in range(a.size()):
        var t := float(i) / float(RATE)
        var x := randf_range(-1.0, 1.0)
        var k := lerpf(0.08, 0.5, t / dur)
        y += k * (x - y)
        a[i] = y * sin(PI * t / dur) * gain * 0.9
    return a

func _fall() -> PackedFloat32Array:
    var a := _tone(1.0, 800.0, 140.0, 1.2, 0.2, 0.5)
    _add(a, _noise_burst(0.25, 0.3, 14.0, false, 1.4), int(0.85 * float(RATE)), 1.0)
    return a

func _arp(freqs: Array, step: float, decay: float) -> PackedFloat32Array:
    var a := _buf(step * float(freqs.size()) + 0.5)
    for k in range(freqs.size()):
        _add(a, _tone(0.45, float(freqs[k]), float(freqs[k]), decay, 0.3, 0.4), int(step * float(k) * float(RATE)), 1.0)
    return a

func _bell() -> PackedFloat32Array:
    var a := _tone(1.0, 784.0, 784.0, 3.5, 0.0, 0.4)
    _add(a, _tone(1.0, 1175.0, 1175.0, 4.5, 0.0, 0.25), 0, 1.0)
    _add(a, _tone(1.0, 2160.0, 2160.0, 8.0, 0.0, 0.15), 0, 1.0)
    return a

func _click() -> PackedFloat32Array:
    var a := _noise_burst(0.08, 0.7, 60.0, true, 1.0)
    _add(a, _tone(0.15, 1800.0, 1800.0, 28.0, 0.0, 0.4), 0, 1.0)
    _add(a, _tone(0.15, 2700.0, 2700.0, 34.0, 0.0, 0.3), 0, 1.0)
    return a

func _snap() -> PackedFloat32Array:
    var a := _noise_burst(0.22, 0.5, 22.0, true, 1.2)
    _add(a, _tone(0.2, 150.0, 60.0, 14.0, 0.0, 0.8), 0, 1.0)
    return a

func _hit() -> PackedFloat32Array:
    var a := _tone(0.12, 120.0, 55.0, 26.0, 0.0, 0.9)
    _add(a, _tone(0.30, 1100.0, 560.0, 6.0, 0.3, 0.45), int(0.06 * float(RATE)), 1.0)
    return a

func _chirp(f0: float, f1: float) -> PackedFloat32Array:
    var a := _buf(0.55)
    for k in range(3):
        _add(a, _tone(0.11, f0, f1, 14.0, 0.15, 0.3), int(0.15 * float(k) * float(RATE)), 1.0)
    return a

func _zap() -> PackedFloat32Array:
    var a := _tone(0.45, 2800.0, 300.0, 4.0, 0.8, 0.6)
    var n := _noise_burst(0.45, 0.8, 6.0, true, 0.7)
    _add(a, n, 0, 1.0)
    return a

func _chatter() -> PackedFloat32Array:
    var a := _buf(0.5)
    for k in range(8):
        _add(a, _tone(0.04, 2600.0, 3300.0, 60.0, 0.0, 0.3), int(0.055 * float(k) * float(RATE)), 1.0)
    return a

# ---- Suoni ambientali in loop ----------------------------------------------------

func _build_loops() -> void:
    loops["stream"] = _loop_player(_loop_stream(), LRATE)
    await get_tree().process_frame
    loops["wind"] = _loop_player(_loop_wind(), LRATE)
    await get_tree().process_frame
    loops["rain"] = _loop_player(_loop_rain(), LRATE)
    await get_tree().process_frame
    loops["fall"] = _loop_player(_loop_waterfall(), LRATE)

func _loop_player(samples: PackedFloat32Array, rate: int) -> AudioStreamPlayer:
    var p := AudioStreamPlayer.new()
    p.stream = _wav(samples, rate, true)
    p.volume_db = -80.0
    add_child(p)
    p.play()
    return p

func _loop_stream() -> PackedFloat32Array:
    var fade := 3000
    var g := _buf(3.0, LRATE)
    g.resize(g.size() + fade)
    var y1 := 0.0
    var y2 := 0.0
    for i in range(g.size()):
        var t := float(i) / float(LRATE)
        var x := randf_range(-1.0, 1.0)
        y1 += 0.22 * (x - y1)
        y2 += 0.03 * (x - y2)
        g[i] = (y1 - y2) * (0.75 + 0.25 * sin(t * 7.0) * sin(t * 3.1))
    return _loopify(g, fade)

func _loop_waterfall() -> PackedFloat32Array:
    var fade := 3000
    var g := _buf(3.0, LRATE)
    g.resize(g.size() + fade)
    var y1 := 0.0
    var y2 := 0.0
    for i in range(g.size()):
        var x := randf_range(-1.0, 1.0)
        y1 += 0.35 * (x - y1)
        y2 += 0.015 * (x - y2)
        g[i] = (y1 - y2 * 0.6) * 0.9
    return _loopify(g, fade)

func _loop_wind() -> PackedFloat32Array:
    var fade := 5000
    var g := _buf(5.0, LRATE)
    g.resize(g.size() + fade)
    var y := 0.0
    var z := 0.0
    for i in range(g.size()):
        var t := float(i) / float(LRATE)
        var x := randf_range(-1.0, 1.0)
        y += 0.045 * (x - y)
        z += 0.012 * (y - z)
        g[i] = (y * 2.2 + z * 3.0) * (0.55 + 0.45 * sin(t * 1.3 + sin(t * 0.5)))
    return _loopify(g, fade)

func _loop_rain() -> PackedFloat32Array:
    var fade := 2000
    var g := _buf(2.0, LRATE)
    g.resize(g.size() + fade)
    var y := 0.0
    for i in range(g.size()):
        var x := randf_range(-1.0, 1.0)
        y += 0.5 * (x - y)
        g[i] = (x - y) * 0.7
    return _loopify(g, fade)

# ---- Musica procedurale (una melodia per zona) ---------------------------------

func _pluck(f: float, bell: bool) -> PackedFloat32Array:
    var a := _buf(0.6, LRATE)
    for i in range(a.size()):
        var t := float(i) / float(LRATE)
        var v := sin(TAU * f * t) + 0.4 * sin(TAU * f * 2.0 * t) * exp(-t * 9.0) + 0.15 * sin(TAU * f * 3.0 * t) * exp(-t * 14.0)
        if bell:
            v += 0.3 * sin(TAU * f * 2.76 * t) * exp(-t * 7.0)
        a[i] = v * exp(-t * 5.0) * (1.0 - exp(-t * 400.0))
    return a

func _make_music(stage: int) -> AudioStreamWAV:
    var roots := [261.63, 220.0, 293.66, 164.81, 196.0, 349.23, 146.83, 174.61]
    var scales := [[0, 2, 4, 7, 9], [0, 3, 5, 7, 10], [0, 2, 4, 7, 9], [0, 1, 5, 7, 8], [0, 1, 4, 5, 7], [0, 2, 4, 7, 9], [0, 3, 5, 6, 10], [0, 2, 7, 9, 11]]
    var bpms := [84.0, 68.0, 76.0, 58.0, 72.0, 92.0, 54.0, 64.0]
    var chords := [[0, -3, -7, -5], [0, -4, -2, -5], [0, -2, 5, 0], [0, 1, -4, 1], [0, -2, -5, -3], [0, -3, -5, -7], [0, -5, -2, -7], [0, 2, -3, -5]]
    var root: float = roots[stage]
    var scale: Array = scales[stage]
    var bpm: float = bpms[stage]
    var chord: Array = chords[stage]
    var bell: bool = stage == 1 or stage == 3 or stage == 5 or stage == 6 or stage == 7
    var spb := int(float(LRATE) * 60.0 / bpm)
    var beats := 32
    var out := PackedFloat32Array()
    out.resize(spb * beats)
    var cache := {}
    var rng := RandomNumberGenerator.new()
    rng.seed = 4242 + stage * 97
    var deg := 2
    for b in range(beats):
        var bar := int(b / 4) % 4
        var cs: int = int(chord[bar])
        if b % 4 == 3:
            await get_tree().process_frame
        if b % 2 == 0:
            var bf := root * 0.5 * pow(2.0, float(cs) / 12.0)
            var key_b := int(bf * 100.0)
            if not cache.has(key_b):
                cache[key_b] = _pluck(bf, false)
            _add(out, cache[key_b], b * spb, 0.55)
        for half in range(2):
            if rng.randf() < (0.5 if stage == 1 or stage == 3 or stage == 5 or stage == 6 or stage == 7 else 0.7):
                deg = clampi(deg + rng.randi_range(-2, 2), 0, 9)
                var semi: int = int(scale[deg % 5]) + 12 * int(deg / 5) + cs
                var f := root * pow(2.0, float(semi) / 12.0)
                var key := int(f * 100.0) + 7
                if not cache.has(key):
                    cache[key] = _pluck(f, bell)
                _add(out, cache[key], b * spb + half * int(spb / 2), 0.32)
    if stage == 1 or stage == 3 or stage == 5 or stage == 6 or stage == 7:
        var d := int(float(LRATE) * 0.42)
        for i in range(d, out.size()):
            out[i] += 0.38 * out[i - d]
            if i % 25000 == 0:
                await get_tree().process_frame
    var fade := 700
    for i in range(fade):
        out[out.size() - 1 - i] *= float(i) / float(fade)
    for i in range(out.size()):
        out[i] = clampf(out[i], -1.0, 1.0) * 0.9
    return _wav(out, LRATE, true)

var music_busy := false
var music_want := -1

func set_music(stage: int) -> void:
    music_want = stage
    if music_cache.has(stage):
        _start_music(stage)
    elif not music_busy:
        _gen_music(stage)

func _gen_music(stage: int) -> void:
    music_busy = true
    var w: AudioStreamWAV = await _make_music(stage)
    music_cache[stage] = w
    music_busy = false
    if music_cache.has(music_want):
        _start_music(music_want)
    else:
        _gen_music(music_want)

func _start_music(stage: int) -> void:
    if stage == music_stage and music_p.playing:
        return
    music_stage = stage
    music_p.stream = music_cache[stage]
    if music_on:
        music_p.play()

func stop_music() -> void:
    music_p.stop()
    music_stage = -1

func set_music_enabled(on: bool) -> void:
    music_on = on
    if on and music_stage >= 0:
        music_p.play()
    elif not on:
        music_p.stop()

func set_sound_enabled(on: bool) -> void:
    sound_on = on
    if not on:
        for k in loops.keys():
            var lp: AudioStreamPlayer = loops[k]
            lp.volume_db = -80.0

# ---- Riproduzione -----------------------------------------------------------------

func play(sfx_name: String, vol_db: float = 0.0, pitch: float = 1.0) -> void:
    if not sound_on or not sfx.has(sfx_name):
        return
    var p: AudioStreamPlayer = pool[pool_i]
    pool_i = (pool_i + 1) % pool.size()
    p.stream = sfx[sfx_name]
    p.volume_db = vol_db
    p.pitch_scale = pitch
    p.play()

func set_loop(loop_name: String, level: float) -> void:
    if not loops.has(loop_name):
        return
    var p: AudioStreamPlayer = loops[loop_name]
    if not sound_on:
        p.volume_db = -80.0
        return
    p.volume_db = -80.0 if level < 0.01 else linear_to_db(clampf(level, 0.0, 1.0)) - 6.0
