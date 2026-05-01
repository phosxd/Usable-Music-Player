class_name Async extends RefCounted


static var thread_pool:Array[Thread]


## Creates a thread (or grabs from pool) & starts it with [param run].
## Returns the thread being used.
## [br][br]
## Calls [param callback] with the result once finished, which will not be called before the [param minimum_time] has passed.
## [br][br]
## If failed to create the thread, will run on the main thread.
static func create_thread(run:Callable, callback=null) -> Thread:
	var thread:Thread = thread_pool[0] if thread_pool.size() > 0 else Thread.new()
	thread_pool.erase(thread)
	var err := thread.start(run)
	if err != OK:
		var result = run.call()
		if is_callable_valid(callback): callback.call(result)
		return thread

	var timer := Timer.new()
	timer.one_shot = false
	timer.timeout.connect(func() -> void:
		if thread.is_started() && not thread.is_alive():
			if timer:
				timer.stop()
				timer.queue_free()
			var result = thread.wait_to_finish()
			thread_pool.append(thread)
			if is_callable_valid(callback): callback.call(result)
	)
	SessionManager.add_child.call_deferred(timer)
	timer.start.call_deferred(0.02)

	return thread


## Progressively frees all nodes in [param nodes].
## Calls [param callback] when finished.
static func unload(nodes:Array[Node], callback=null) -> void:
	if nodes == null or nodes.is_empty(): return
	var iter:int = 0
	for node:Node in nodes:
		if not node or not is_instance_valid(node): continue
		iter += 1
		node.queue_free.call_deferred()
		if iter % 4 == 0: await SessionManager.get_tree().process_frame

	if is_callable_valid(callback): callback.call()


static func is_callable_valid(callable) -> bool:
	if callable is not Callable: return false
	callable = callable as Callable
	if not callable.is_valid(): return false
	var object = callable.get_object()
	if not object: return false

	return true
