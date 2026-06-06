import os
import sys
import time
import signal
import threading
import json

# Import scripts.
import Utils
import Metadata
import GlobalInput
import MPRIS


max_ping_interval:float = 7.5
last_ping_time:float = 0.0


def ping_timer():
	while True:
		time.sleep(max_ping_interval)
		if time.time()-max_ping_interval >= last_ping_time:
			shutdown()
			os.kill(os.getpid(), signal.SIGTERM)
			break


def shutdown():
	MPRIS.quit()
	GlobalInput.quit()


def command_ping(args:list):
	global last_ping_time
	last_ping_time = time.time()
	return None


# Runs the "function" & prints the "result" as JSON text.
# Function output is inserted into "result.data".
def run_cmd(function:callable, is_quiet:bool, args, result):
	result['data'] = function(args)
	if not is_quiet: print(json.dumps(result))


if __name__ == "__main__":
	# Start ping timer on separate thread.
	ping_thread = threading.Thread(target=ping_timer)
	ping_thread.start()

	# Start MPRIS server on separate thread.
	mpris_thread = threading.Thread(target=MPRIS.start)
	mpris_thread.start()


	# Main Loop.
	while True:
		raw_input = input() # Wait for input.
		raw_args:list[str] = raw_input.split(' [&&] ')
		cmd:str = Utils.list_get(raw_args, 0, '')
		cmd_args = []
		for arg in raw_args:
			arg_object = {
				'type': '',
				'value': '',
			}
			if arg.startswith('(') == False: continue
			arg_object['type'] = arg.replace('(','*').replace(')','*').split('*')[1]
			arg_value = arg.removeprefix('(%s) ' % arg_object['type'])
			# Translate value.
			if arg_value.startswith(':'):
				if arg_value.lower() == ':true': arg_value = True
				elif arg_value.lower() == ':false': arg_value = False
				elif arg_value.removeprefix(':').replace('.','').isnumeric(): arg_value = float(arg_value.removeprefix(':'))

			arg_object['value'] = arg_value
			cmd_args.append(arg_object)

		# Find & apply special arguments.
		command_id:str = ''
		is_quiet:bool = False
		for arg in cmd_args:
			if arg['type'] == 'CID': command_id = arg['value']
			elif arg['type'] == 'QUIET': is_quiet = True

		# Initialize result.
		result = {
			'cmd': cmd,
			'id': command_id,
			'data': None,
		}

		# Get function or run command action.
		function:callable = None
		if cmd == 'quit':
			shutdown()
			sys.exit()
		elif cmd == 'ping':
			function = command_ping
		elif cmd == 'get_audio_meta':
			function = Metadata.command_get_audio_meta
		elif cmd == 'get_global_input':
			function = GlobalInput.command_get_global_input
		elif cmd == 'update_mpris_data':
			function = MPRIS.command_update_data
		elif cmd == 'get_mpris_events':
			function = MPRIS.command_get_events

		if function == None: continue

		run_cmd(function, is_quiet, cmd_args, result)

