extends Node

enum RequestType {
	Local,
	Web,
}

var queued_requests:Dictionary[RequestType,Dictionary] = {}
var local_APIs:Dictionary[String,Object] = {}


class APIRequest extends RefCounted:
	signal canceled
	var is_canceled:bool = false
	var url: String
	var options: Dictionary
	
	func _init(url_:String, options_:Dictionary) -> void: 
		url = url_
		options = options_

	func cancel() -> void:
		canceled.emit()
		is_canceled = true


func _ready() -> void:
	pass


## Makes a request with a unique [param id] & calls [param callback] after the server has responded.
## Request headers & other data can be passed through [param options].
## 
## Artificial delay can be added with [param delay].
func request(type:RequestType, id:String, url:String, options:Dictionary={}, callback:=Callable(), delay:float=0) -> void:
	# Create request & cancel any previous request with the same ID.
	var req := APIRequest.new(url, options)
	queued_requests.get_or_add(type, {})
	var prev_req = queued_requests[type].get(id)
	if prev_req: prev_req.cancel()
	queued_requests[type].set(id, req)

	match type:
		# Make local API request.
		RequestType.Local:
			queued_requests[type].erase(id)
			call_local(url, options, callback)

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
					queued_requests[type].erase(id)
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
					timer.queue_free()
				)
				add_child(timer)
				timer.start(delay)
			)
			add_child(http_request)


func call_local(id:String, options:Dictionary, callback:Callable) -> void:
	var api = local_APIs.get(id)
	if api is not Object:
		callback.call(FAILED)
		return
	api = api as Object
	if api.has_method('request'):
		api.call('request', options, callback)
