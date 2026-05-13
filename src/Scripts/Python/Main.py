import threading
import json

# Import scripts.
import Utils
import Metadata


# Runs the "function" & prints the "result" as JSON text.
# Function output is inserted into "result.data".
def run_cmd(function, args, result):
    result['data'] = Metadata.command_get_audio_meta(cmd_args)
    print(json.dumps(result))


if __name__ == "__main__":
    # Main Loop.
    while True:
        raw_input = input()
        raw_args = raw_input.split(' [&&] ')
        cmd = Utils.list_get(raw_args, 0, '')
        cmd_args = []
        for arg in raw_args:
            arg_object = {
                'type': '',
                'value': '',
            }
            if arg.startswith('(') == False: continue
            arg_object['type'] = arg.replace('(','*').replace(')','*').split('*')[1]
            arg_object['value'] = arg.removeprefix('(%s) ' % arg_object['type'])
            cmd_args.append(arg_object)

        # Find command ID.
        command_id = ''
        for arg in cmd_args:
            if arg['type'] == 'CID':
                command_id = arg['value']

        # Initialize result.
        result = {
            'cmd': cmd,
            'id': command_id,
            'data': None,
        }

        # Get function.
        function = None
        if cmd == 'get_audio_meta':
            function = Metadata.command_get_audio_meta

        if function == None: continue

        # Run function on separate thread.
        thread = threading.Thread(target=run_cmd, args=(function, cmd_args, result))
        thread.start()

