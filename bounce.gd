extends Node2D

const W := 480.0
const H := 720.0
const PADDLE_Y := 660.0
const PADDLE_W := 90.0
const PADDLE_H := 14.0
const BALL_R := 8.0
const START_SPEED := 340.0
const MAX_SPEED := 640.0

var paddle_x := W / 2.0
var ball_pos := Vector2.ZERO
var ball_vel := Vector2.ZERO
var speed := START_SPEED
var bricks: Array[Rect2] = []
var brick_colors: Array[Color] = []
var score := 0
var best := 0
var lives := 3
var state := "serve" 

func _ready() -> void:
	_new_game()

func _new_game() -> void:
	score = 0
	lives = 3
	bricks.clear()
	brick_colors.clear()
	var cols := 8
	var rows := 6
	var bw := (W - 40.0) / cols
	for r in rows:
		for c in cols:
			bricks.append(Rect2(20 + c * bw + 2, 80 + r * 26, bw - 4, 22))
			brick_colors.append(Color.from_hsv(float(r) / rows * 0.8, 0.65, 0.95))
	_reset_ball()

func _reset_ball() -> void:
	state = "serve"
	speed = START_SPEED
	ball_vel = Vector2.ZERO
	ball_pos = Vector2(paddle_x, PADDLE_Y - BALL_R)

func _launch() -> void:
	var angle := randf_range(-0.4, 0.4)
	ball_vel = Vector2(sin(angle), -cos(angle)) * speed
	state = "play"

func _input(event: InputEvent) -> void:
	var pressed: bool = event.is_action_pressed("ui_accept")
	if event is InputEventMouseButton and event.pressed:
		pressed = true
	if not pressed:
		return
	match state:
		"serve": _launch()
		"over", "win": _new_game()

func _process(delta: float) -> void:
	# Paddle: mouse or arrow keys / A, D
	if Input.is_key_pressed(KEY_LEFT) or Input.is_key_pressed(KEY_A):
		paddle_x -= 520.0 * delta
	if Input.is_key_pressed(KEY_RIGHT) or Input.is_key_pressed(KEY_D):
		paddle_x += 520.0 * delta
	var mx := get_global_mouse_position().x
	if Input.get_last_mouse_velocity().length() > 0.0:
		paddle_x = mx
	paddle_x = clampf(paddle_x, PADDLE_W / 2.0, W - PADDLE_W / 2.0)

	if state == "serve":
		ball_pos = Vector2(paddle_x, PADDLE_Y - BALL_R)
	elif state == "play":
		_step_ball(delta)
	queue_redraw()

func _step_ball(delta: float) -> void:
	ball_pos += ball_vel * delta

	if ball_pos.x < BALL_R:
		ball_pos.x = BALL_R
		ball_vel.x = absf(ball_vel.x)
	elif ball_pos.x > W - BALL_R:
		ball_pos.x = W - BALL_R
		ball_vel.x = -absf(ball_vel.x)
	if ball_pos.y < BALL_R:
		ball_pos.y = BALL_R
		ball_vel.y = absf(ball_vel.y)

	if ball_vel.y > 0.0 and ball_pos.y + BALL_R >= PADDLE_Y and ball_pos.y < PADDLE_Y + PADDLE_H \
			and absf(ball_pos.x - paddle_x) < PADDLE_W / 2.0 + BALL_R:
		var offset := clampf((ball_pos.x - paddle_x) / (PADDLE_W / 2.0), -1.0, 1.0)
		var angle := offset * deg_to_rad(60.0)
		speed = minf(speed + 12.0, MAX_SPEED)
		ball_vel = Vector2(sin(angle), -cos(angle)) * speed
		ball_pos.y = PADDLE_Y - BALL_R

	for i in bricks.size():
		var b := bricks[i]
		var closest := Vector2(clampf(ball_pos.x, b.position.x, b.end.x), clampf(ball_pos.y, b.position.y, b.end.y))
		var d := ball_pos - closest
		if d.length_squared() < BALL_R * BALL_R:
			if absf(d.x) > absf(d.y):
				ball_vel.x *= -1.0
			else:
				ball_vel.y *= -1.0
			bricks.remove_at(i)
			brick_colors.remove_at(i)
			score += 10
			best = maxi(best, score)
			if bricks.is_empty():
				state = "win"
			break

	if ball_pos.y > H + BALL_R:
		lives -= 1
		if lives <= 0:
			state = "over"
		else:
			_reset_ball()

func _draw() -> void:
	draw_rect(Rect2(0, 0, W, H), Color("14141f"))
	for i in bricks.size():
		draw_rect(bricks[i], brick_colors[i])
	draw_rect(Rect2(paddle_x - PADDLE_W / 2.0, PADDLE_Y, PADDLE_W, PADDLE_H), Color("e8e8f0"))
	draw_circle(ball_pos, BALL_R, Color("ffd24a"))

	var font := ThemeDB.fallback_font
	draw_string(font, Vector2(20, 36), "Score %d" % score, HORIZONTAL_ALIGNMENT_LEFT, -1, 22)
	draw_string(font, Vector2(0, 36), "Best %d" % best, HORIZONTAL_ALIGNMENT_CENTER, W, 22)
	draw_string(font, Vector2(0, 36), "Lives %d" % lives, HORIZONTAL_ALIGNMENT_RIGHT, W - 20, 22)

	var msg := ""
	match state:
		"serve": msg = "Click or press Space to launch"
		"over": msg = "Game over - click to retry"
		"win": msg = "You cleared it! Click to play again"
	if msg != "":
		draw_string(font, Vector2(0, 400), msg, HORIZONTAL_ALIGNMENT_CENTER, W, 24)
