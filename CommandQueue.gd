extends Node

signal queue_empty

var queue: Array = []
var is_running := false

func add_command(cmd):
	queue.append(cmd)
	_try_run()

func _try_run():
	if is_running or queue.is_empty():
		return

	is_running = true
	var cmd = queue.pop_front()

	cmd.connect("finished", Callable(self, "_on_command_finished"), CONNECT_ONE_SHOT)
	cmd.execute()

func _on_command_finished():
	#print("_on_command_finished, queue size: ", queue.size())
	is_running = false

	if queue.is_empty():
		emit_signal("queue_empty")

	_try_run()

func is_busy() -> bool:
	return is_running or not queue.is_empty()
