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


    def event(ch)
        if ch.is_a? NCurses::MouseEvent
            mouse = ch.as(NCurses::MouseEvent)

            case @@mode
                when "default"
                    if mouse.state_includes? NCurses::Mouse::B4Pressed
                        @@tabs.event "Queue", "scroll", "up"
                    elsif mouse.state_includes? NCurses::Mouse::B5Pressed
                        @@tabs.event "Queue", "scroll", "down"
                    end

                when "command"
  
                else
            end 
        elsif ch == NCurses::Key::Resize
            @@h = NCurses.height
            @@w = NCurses.width
            resize_all
        else
            case @@mode
                when "default"
                    CursedPlayer.default_key_press ch

                when "command"
                    CursedPlayer.command_key_press ch
                    render_command
                else
            end 
        end
    end


    def default_key_press(ch)
        case ch
            when ':'
                @@mode = "command"
                @@command = ":"
                render_command
            when 'n'
                @@player.next
            when 'p'
                @@player.previous
            when ' '
                if @@player.is_playing?
                    @@player.pause
                else
                    play
                end
            when NCurses::Key::Right
                @@player.set_time @@player.get_time + @@conf.as_i("time_delta")
            when NCurses::Key::Left
                @@player.set_time @@player.get_time - @@conf.as_i("time_delta")
            when NCurses::Key::Up
                @@tabs.event "Queue", "scroll", "up"
            when NCurses::Key::Down
                @@tabs.event "Queue", "scroll", "down"
            when NCurses::Key::Esc, NCurses::Key::Backspace
                @@tabs.event "Help", "return"
            else
        end
    end


    def command_key_press(ch)
        case ch
            when NCurses::Key::Backspace, NCurses::Key::Del
                if @@command.size > 0
                    @@command = @@command[0...-1]
                    if @@command.empty?
                        @@mode = "default"
                    end
                end
            when NCurses::Key::Esc
                @@command = ""
                @@mode = "default"
            when NCurses::Key::Enter
                if @@command.starts_with? ":"
                    cmd = @@command[1..]
                else
                    cmd = @@command
                end
                part1 = cmd
                if cmd.includes?(" ")
                    parts = cmd.split " ", 2
                    part1 = parts[0]
                    part2 = parts[1]
                else
                    part2 = ""
                end
                run_command part1, part2
                @@command = ""
                @@mode = "default"
            else
                if ch.is_a?(Char)
                    @@command += ch.to_s
                end
        end
    end
end