
# Safely get an item in an array.
def list_get (l, idx, default=None):
	try:
		return l[idx]
	except IndexError:
		return default
