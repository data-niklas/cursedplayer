# TODO: Write documentation for `Cursedplayer`
require "./cursedplayer/*"
require "option_parser"

CursedPlayer.set_title "cursedplayer"

GC.disable

config = Path["~/.config/cursedplayer/cursedplayer.conf"].expand(home: true)
library = Path["~/.config/cursedplayer/library.csv"].expand(home: true)
folder = config.parent

URL_REGEX = /(?:(?:https?|ftp):\/\/|\b(?:[a-z\d]+\.))(?:(?:[^\s()<>]+|\((?:[^\s()<>]+|(?:\([^\s()<>]+\)))?\))+(?:\((?:[^\s()<>]+|(?:\(?:[^\s()<>]+\)))?\)|[^\s`!()\[\]{};:'".,<>?«»“”‘’]))?/
FORMAT = Time::Format.new("%H:%M:%S")

if !Dir.exists? folder
  Dir.mkdir folder
end
if !File.exists? config
  File.write config, ""
end
if !File.exists? library
  File.write library, ""
end


CursedPlayer.load_config config

picked_songs = [] of String
OptionParser.parse do |parser|
  parser.on "-h", "--help", "Help" do
    puts parser
    exit
  end


  parser.unknown_args do |args|
    picked_songs = args
  end

end

CursedPlayer.ui_init
#CursedPlayer.render_library_load
CursedPlayer.load_library picked_songs, library
CursedPlayer.register_events
#CursedPlayer.library_loaded
CursedPlayer.ui_loop