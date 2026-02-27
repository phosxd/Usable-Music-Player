class_name ThreadHelper extends RefCounted


static var threads:Array[Thread]


## Creates a thread & starts it with [param run].
## Returns the created thread. 
##
## Calls [param callback] with the result once finished, which will not be called before the [param minimum_time] has passed.
##
## If failed to create the thread, will run on the main thread.
static func create_thread(run:Callable, callback=null) -> Thread:
	var thread := Thread.new()
	var err := thread.start(run)
	if err != OK:
		var result = run.call()
		if callback is Callable && callback: callback.call(result)

	var timer := Timer.new()
	timer.one_shot = false

	timer.timeout.connect(func() -> void:
		if thread.is_started() && not thread.is_alive():
			if not timer: return
			var result = await thread.wait_to_finish()
			if callback is Callable && callback.is_valid(): callback.call(result)
			timer.stop()
			timer.queue_free()
	)
	SessionManager.add_child.call_deferred(timer)
	timer.start.call_deferred(0.02)

	return thread
