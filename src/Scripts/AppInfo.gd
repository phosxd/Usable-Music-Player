class_name AppInfo extends RefCounted

static var name:String = ProjectSettings.get_setting('application/config/name')
const source_code:String = 'https://github.com/phosxd/usable-music-player'
const issues_page:String = source_code+'/issues'
const audio_db_api_url:String = 'https://theaudiodb.com/api/v1/json/123/search.php?s=%s'
