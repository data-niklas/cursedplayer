require "mediaplayer"

module CursedPlayer
    @@player = Player::MediaPlayer.new Player::MediaList.new
    @@current_song : Nil | Player::Media = nil

    def stop
        @@player.stop
        @@current_song = nil
        render_status
        @@player = Player::MediaPlayer.new Player::MediaList.new
    end

    def play
        list = @@player.list!
        if list.count == 0
            library = CursedPlayer::Library.songs
            library.count.times do |i|
                list << library.get i
            end
        end
        @@player.play

    end

    def player
        @@player
    end

    def queue
        @@player.list!
    end

    def current_song
        @@current_song
    end

    def current_song=(song)
        @@current_song = song
    end
end