# Event stuff / --> LibVLC Media events
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
                    CursedPlayer.new_song a.value.u.new_media
                when Player::Event::MediaFreed
                    #sleep 2 
                    #CursedPlayer.update_song Player::Media.new(a.value.u.md)
                else
            end
        end
        @@player.on Player::Event::MediaPlayerMediaChanged, proc
        @@player.on Player::Event::MediaPlayerTimeChanged, proc
        @@player.on Player::Event::MediaFreed, proc
    end


    # A new song is now playing!
    def new_song(obj)
        old_song = @@current_song
        if @@current_song.nil?
            @@current_song = Player::Media.new(obj)
        else
            old_song = @@current_song.as(Player::Media).obj
            @@current_song.as(Player::Media).obj = obj
            update_song Player::Media.new(old_song)
        end
        update_song @@current_song.as(Player::Media)
        update_title @@current_song.as(Player::Media)
    end

    # Update library things because of the new song
    def update_song(song : Player::Media | Int32)
        if NCurses.is_initialized? && !@@tabs.nil?
            @@tabs.event "Queue", "song_updated", "", song
        end
    end

    # Update the terminal title
    def update_title(song : Player::Media)
        if !CursedPlayer.library.has? song.url
            title = song.get_meta(LibVlc::Meta::Title).sub(".mp3","")
            CursedPlayer.set_title "#{title}"
        else
            entry = CursedPlayer.library.songtable[song.url]
            title = entry[0]
            artist = entry[1]
            CursedPlayer.set_title "#{title} - #{artist}"
        end
    end
end