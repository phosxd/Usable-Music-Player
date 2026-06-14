# This is what all your Python scripts run through.
# Without importing any modules, only the standard Python modules can be used.
# Just import any library present on your system to include them in the next build.

import os
import sys
import time
import threading
import signal
import json
import asyncio
import random

from dbus_fast.aio import MessageBus
from dbus_fast.service import ServiceInterface, dbus_method, dbus_property, dbus_signal
from dbus_fast import Variant, PropertyAccess

import pynput
from pynput.keyboard import Key, Listener

import tinytag


# Main loop.

if __name__ == '__main__':
	while True:
		i:str = input()
		i = i.replace('(%new_line%)','\n')
		exec(i)
