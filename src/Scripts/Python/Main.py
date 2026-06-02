import threading
import json

# Import scripts.
import Utils
import Metadata
import GlobalInput
import MPRIS


# Runs the "function" & prints the "result" as JSON text.
# Function output is inserted into "result.data".
def run_cmd(function:callable, is_quiet:bool, args, result):
    result['data'] = function(args)
    if not is_quiet: print(json.dumps(result))


if __name__ == "__main__":
    # Start MPRIS server on separate thread.
    mpris_thread = threading.Thread(target=MPRIS.start)
    mpris_thread.start()

    # Main Loop.
    while True:
        raw_input = input()
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
                if arg_value == ':True': arg_value = True
                elif arg_value == ':False': arg_value = False
                elif arg_value.removeprefix(':').isnumeric(): arg_value = float(arg_value.removeprefix(':'))

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

        # Get function.
        function:callable = None
        if cmd == 'get_audio_meta':
            function = Metadata.command_get_audio_meta
        elif cmd == 'get_global_input':
            function = GlobalInput.command_get_global_input
        elif cmd == 'update_mpris_data':
            function = MPRIS.command_update_data
        elif cmd == 'get_mpris_events':
            function = MPRIS.command_get_events

        if function == None: continue

        # Run command on separate thread.
        cmd_thread = threading.Thread(target=run_cmd, args=(function, is_quiet, cmd_args, result))
        cmd_thread.start()

