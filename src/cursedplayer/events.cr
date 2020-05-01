module CursedPlayer
    @@gc_count = 0
    def register_events
        proc = Player::Callback.new do |a,b|
            @@gc_count = 10 % (@@gc_count + 1)
            if @@gc_count == 0
                GC.collect
            end
            case a.value.type
                when Player::Event::MediaPlayerTimeChanged
                    render_status
                when Player::Event::MediaPlayerMediaChanged
                    if @@current_song.nil?
                        @@current_song = Player::Media.new(a.value.u.new_media)
                    else
                        @@current_song.as(Player::Media).obj = a.value.u.new_media
                    end
                else
            end
        end
        @@player.on Player::Event::MediaPlayerMediaChanged, proc
        @@player.on Player::Event::MediaPlayerTimeChanged, proc
    end
end