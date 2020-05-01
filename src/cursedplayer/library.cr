module CursedPlayer
    module Library extend self
        @@parsing = 0
        @@songs = Player::MediaList.new
        def load_library(songs : Array(String))
            list = CursedPlayer.player.list!

            if CursedPlayer.conf.as_b? "library", false
            else
                @@parsing = songs.size
                songs.each do |song|
                    if song.starts_with?("http")
                        s = Player::Media.new(song, false)
                    else
                        s = Player::Media.new song
                    end
                    if s.parsed_status != Player::MediaParsedStatus::Done
                        res = s.parse Player::MediaParseFlag::FetchLocal, -1
                        s.on Player::Event::MediaParsedChanged do |a,b|
                            @@parsing-=1
                        end
                    end
                    @@songs << s
                    list << s
                end
            end

            if list.count > 0
                while @@parsing > 0
                    sleep 0.05
                end
                CursedPlayer.player.play
            end 
        end

        def songs
            @@songs
        end
    end

    def make_queue(songs : Array(Player::Media))

    end

end