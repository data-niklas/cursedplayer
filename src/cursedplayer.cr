# TODO: Write documentation for `Cursedplayer`
require "./cursedplayer/*"
require "option_parser"


GC.disable

path = Path["~/.config/cursedplayer/cursedplayer.conf"].expand(home: true)
folder = path.parent

URL_REGEX = /(?:(?:https?|ftp):\/\/|\b(?:[a-z\d]+\.))(?:(?:[^\s()<>]+|\((?:[^\s()<>]+|(?:\([^\s()<>]+\)))?\))+(?:\((?:[^\s()<>]+|(?:\(?:[^\s()<>]+\)))?\)|[^\s`!()\[\]{};:'".,<>?«»“”‘’]))?/
FORMAT = Time::Format.new("%H:%M:%S")

if !Dir.exists? folder
  Dir.mkdir folder
end
if !File.exists? path
  File.write path, ""
end

CursedPlayer.load_config path

picked_songs = [] of String
OptionParser.parse do |parser|
  parser.on "-h", "--help", "Help" do
    puts parser
    exit
  end
  parser.on "-l=LIBRARY", "--library=LIBRARY", "Library mode" do |library|
    CursedPlayer.conf["library"] = library == "true"
  end

  parser.unknown_args do |args|
    picked_songs = args
  end

end

CursedPlayer.register_events
CursedPlayer.ui_init
CursedPlayer.render_library_load
CursedPlayer::Library.load_library picked_songs
CursedPlayer.library_loaded
CursedPlayer.ui_loop
puts "EXIT"