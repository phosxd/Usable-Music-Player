extends Node

enum RequestType {
	Local,
	Web,
}

var queued_requests:Dictionary[String,APIRequest] = {}
var local_APIs:Dictionary[String,Object] = {}


class APIRequest extends RefCounted:
	signal completed
	signal canceled
	var is_completed:bool = false
	var is_canceled:bool = false
	var url: String
	var options: Dictionary
	
	func _init(url_:String, options_:Dictionary) -> void: 
		url = url_
		options = options_

	func complete() -> void:
		if is_canceled: return
		is_completed = true
		completed.emit()

	func cancel() -> void:
		is_canceled = true
		canceled.emit()


func _ready() -> void:
	pass


## Makes a request with a unique [param id] & calls [param callback] after the server has responded.
## Request headers & other data can be passed through [param options].
## 
## Artificial delay can be added with [param delay].
##
## Can be queued after the previous request of the same [param id] when [param queue] is set to true.
func request(type:RequestType, id:String, url:String, options:Dictionary={}, callback:=Callable(), delay:float=0, queue:bool=false) -> void:
	# Create request & cancel any previous request with the same ID.
	var req := APIRequest.new(url, options)
	var prev_req = queued_requests.get(id)
	var binded_request_func = _request.bind(req,type,id,url,options,callback,delay)

	if queue && prev_req:
		prev_req.completed.connect(binded_request_func)
		queued_requests.set(id, req)
	else:
		if prev_req: prev_req.cancel()
		queued_requests.set(id, req)
		binded_request_func.call()


func _request(req:APIRequest, type:RequestType, id:String, url:String, options:Dictionary={}, callback:=Callable(), delay:float=0) -> void:
	print('MAKING REQUEST: %s' % url)
	match type:
		# Make local API request.
		RequestType.Local:
			call_local(url, options, callback)
			req.complete()

		# Make Web request.
		RequestType.Web:
			var http_request := HTTPRequest.new()
			# Continue when node is ready,
			http_request.ready.connect(func() -> void:
				http_request.request_completed.connect(func(result:int, response_code:int, headers:PackedStringArray, body:PackedByteArray) -> void:
					if req.is_canceled: return
					var data:Dictionary = {
						'response_code': response_code,
						'headers': headers,
						'body': body,
					}
					if callback.get_object(): callback.call(result, data)
					http_request.queue_free()
				)
				# Create timer to only make request after the specified delay.
				var timer := Timer.new()
				timer.autostart = false
				timer.timeout.connect(func() -> void:
					if req.is_canceled: return
					# Send request to HTTPRequest node.
					var headers:PackedStringArray = options.get('headers',PackedStringArray([]))
					var method:HTTPClient.Method = options.get('client_method',0)
					var data:String = options.get('request_data','')
					http_request.request(url, headers, method, data)
					req.complete()
					timer.queue_free()
				)
				add_child.call_deferred(timer)
				timer.start.call_deferred(delay)
			)
			add_child.call_deferred(http_request)


func call_local(id:String, options:Dictionary, callback:Callable) -> void:
	var api = local_APIs.get(id)
	if api is not Object:
		callback.call(FAILED)
		return
	api = api as Object
	if api.has_method('request'):
		api.call('request', options, callback)
