extends Node

class_name GranularEngine

# --- Configuration & State ---
var is_on: bool = true
var rpm: float = 300.0
var throttle: float = 0.0

@export_group("Audio Source")
@export var audio_stream: AudioStream
@export_range(-80.0, 24.0) var volume_db: float = 0.0

@export_group("Physics")
@export var idle_rpm: float = 800.0
@export var max_rpm: float = 7000.0
@export_range(1.0, 100.0) var inertia: float = 20.0 # Higher = Slower response

@export_group("Grain Size")
@export var adaptive_grain: bool = false
@export_range(0.01, 0.5) var base_grain_size: float = 0.050 # seconds
@export_range(0.005, 0.2) var min_grain_size: float = 0.010 # At Max RPM

@export_group("Overlap")
@export var adaptive_overlap: bool = false
@export_range(1.0, 100.0) var base_overlap: float = 25.0 
@export_range(1.0, 100.0) var target_overlap: float = 50.0 # At Max RPM (Higher)

@export_group("Jitter")
@export var adaptive_jitter: bool = false
@export_range(0.0, 0.1) var base_jitter: float = 0.010
@export_range(0.0, 0.2) var max_jitter: float = 0.050 # At Max RPM (Higher)

@export_group("Envelope (ADSR)")
@export_subgroup("Attack")
@export var adaptive_attack: bool = false
@export_range(0.0, 1.0) var base_attack_pct: float = 0.4
@export_range(0.0, 1.0) var max_attack_pct: float = 0.6 # At Max RPM (Higher)

@export_subgroup("Release")
@export var adaptive_release: bool = false
@export_range(0.0, 1.0) var base_release_pct: float = 0.4
@export_range(0.0, 1.0) var min_release_pct: float = 0.1 # At Max RPM (Lower)

# Audio Resources
var pool_size: int = 32
var player_pool: Array[AudioStreamPlayer] = []
var pool_index: int = 0

# Scheduler
var next_grain_time: float = 0.0
var current_time: float = 0.0

func _ready():
	# Initialize Pool
	for i in range(pool_size):
		var p = AudioStreamPlayer.new()
		p.bus = "SFX" # Route to SFX bus
		add_child(p)
		player_pool.append(p)
	
	# Load default sound if available (placeholder)
	# audio_stream = load("res://assets/Sound/engine_rev.wav") 

func load_audio_from_path(path: String):
	if FileAccess.file_exists(path):
		var file = FileAccess.open(path, FileAccess.READ)
		var buffer = file.get_buffer(file.get_length())
		var stream = AudioStreamWAV.new()
		stream.data = buffer
		# Basic WAV detection (very simple, might need more robust loader for complex WAVs)
		stream.format = AudioStreamWAV.FORMAT_16_BITS
		stream.mix_rate = 44100 # Assumption
		audio_stream = stream
		print("Loaded audio from: ", path)

func set_audio_stream(stream: AudioStream):
	audio_stream = stream

func update_physics(current_speed: float, max_speed_ship: float, delta: float):
	if not is_on: return
	
	# Calculate Throttle based on speed ratio
	var target_throttle = clamp(current_speed / max_speed_ship, 0.0, 1.0)
	throttle = target_throttle
	
	var rpm_range = max_rpm - idle_rpm
	var target_rpm = idle_rpm + (throttle * rpm_range)
	
	# Inertia smoothing
	# Inertia value acts as a resistance. 
	# 1.0 = Instant (no resistance), 100.0 = Very Slow
	var response_speed = 10.0 / max(1.0, inertia) # 10.0 is an arbitrary scaling factor
	var smooth_factor = response_speed * delta
	
	rpm = lerp(rpm, target_rpm, clamp(smooth_factor, 0.0, 1.0))

func _process(delta: float):
	if not is_on or not audio_stream: return
	
	current_time += delta
	
	# Scheduler Loop
	# We use a while loop to catch up if we missed grains, but limit it to avoid freezing
	var loops = 0
	while current_time >= next_grain_time and loops < 10:
		loops += 1
		_schedule_grain()

func _schedule_grain():
	# --- Adaptive Calculations ---
	var rpm_range = max_rpm - idle_rpm
	var rpm_ratio = clamp((rpm - idle_rpm) / rpm_range, 0.0, 1.0)
	
	# 1. Grain Size
	var size = base_grain_size
	if adaptive_grain:
		size = base_grain_size - (rpm_ratio * (base_grain_size - min_grain_size))
		size = max(0.005, size)
		
	# 2. Jitter
	var jitter = base_jitter
	if adaptive_jitter:
		jitter = base_jitter + (rpm_ratio * (max_jitter - base_jitter))
		
	# 3. Overlap
	var overlap_val = base_overlap
	if adaptive_overlap:
		overlap_val = base_overlap + (rpm_ratio * (target_overlap - base_overlap))
		
	# 4. ADSR
	var attack_pct = base_attack_pct
	if adaptive_attack:
		attack_pct = base_attack_pct + (rpm_ratio * (max_attack_pct - base_attack_pct))
		
	var release_pct = base_release_pct
	if adaptive_release:
		release_pct = base_release_pct - (rpm_ratio * (base_release_pct - min_release_pct))
		release_pct = max(0.01, release_pct)
		
	# Play the grain
	_play_grain(size, jitter, attack_pct, release_pct, rpm_ratio)
	
	# Calculate Next Time
	# overlapFactor = 1.1 - (densityVal / 100); 
	var overlap_factor = 1.1 - (overlap_val / 100.0)
	var spacing = max(0.005, size * overlap_factor)
	next_grain_time += spacing

func _play_grain(duration: float, jitter_amount: float, attack_pct: float, release_pct: float, rpm_ratio: float):
	var player = player_pool[pool_index]
	pool_index = (pool_index + 1) % pool_size
	
	# Stop previous playback on this player (if any)
	if player.playing:
		player.stop()
		
	player.stream = audio_stream
	
	# Scrub Position
	var file_len = audio_stream.get_length()
	var offset = rpm_ratio * (file_len - duration)
	
	# Apply Jitter
	var rand_val = (randf() * 2.0 - 1.0) * jitter_amount
	offset += rand_val
	
	offset = clamp(offset, 0.0, file_len - duration)
	
	# Volume Envelope using Tween
	# Reset volume
	player.volume_db = -80.0
	player.pitch_scale = 1.0 # No pitch shifting in this scrubbing model, or maybe slight random?
	
	player.play(offset)
	
	var tween = create_tween()
	var attack_time = duration * attack_pct
	var release_time = duration * release_pct
	var sustain_time = duration - attack_time - release_time
	
	# Attack
	tween.tween_property(player, "volume_db", volume_db, attack_time).set_trans(Tween.TRANS_LINEAR)
	
	# Sustain (Wait)
	if sustain_time > 0:
		tween.tween_interval(sustain_time)
		
	# Release
	tween.tween_property(player, "volume_db", -80.0, release_time).set_trans(Tween.TRANS_LINEAR)
	
	# Stop after done
	tween.tween_callback(player.stop)
