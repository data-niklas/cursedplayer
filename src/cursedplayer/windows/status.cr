require "ncurses"

module CursedPlayer
    class StatusArea < NCurses::EventWindow
        def initialize
            initialize(2, CursedPlayer.w, 0, 0)
            track
        end

        def update_size
            resize 2, CursedPlayer.w
            if !CursedPlayer.current_song.nil?
                render CursedPlayer.current_song.as(Player::Media)
            end
        end

        def render(song : Player::Media)
            clear
                pos = FORMAT.format(Time.unix_ms(CursedPlayer.player.get_time))
                if CursedPlayer.time_mode % 2 == 0
                    len = song.get_formatted_length FORMAT
                else
                    len = FORMAT.format(Time.unix_ms(song.get_length - CursedPlayer.player.get_time))
                end
                len = CursedPlayer.strip_time len
                pos = CursedPlayer.strip_time pos
                if CursedPlayer.time_mode < 2
                    time = " " + pos + " - " + len
                else
                    time = " " + (CursedPlayer.time_mode == 3 ? len : pos)
                end
                CursedPlayer.time_length = time.size

                with_attr NCurses::Attribute::Bold do
                    set_color 4
                    title = song.get_meta(LibVlc::Meta::Title).sub(".mp3","")
                    CursedPlayer.title_length = title.size
                    print title
                    set_color 0
                    set_pos 0, CursedPlayer.w - CursedPlayer.time_length
                    print time
                end

                set_pos 1, 0
                print "["
                ratio = CursedPlayer.player.get_position
                space = CursedPlayer.w - 2
                wfinished = LibM.ceil_f64(space*ratio - 0.5).to_i
                print "=".*(wfinished)
                with_attr NCurses::Attribute::Dim do
                    print "-".*(space - wfinished)
                end
                print "]" 
            refresh
        end

        def mouse_pressed(event, x, y, z)
            if !CursedPlayer.popup
                if event.state_includes? NCurses::Mouse::B1Clicked
                    
                    if y == 0
                        if x < CursedPlayer.title_length
                            CursedPlayer.open_current_song
                        elsif x >= CursedPlayer.w - CursedPlayer.time_length
                            CursedPlayer.time_mode = (CursedPlayer.time_mode + 1) % 4
                            CursedPlayer.render_status
                        end
                    elsif y == 1
                        # Clicked on the progress bar?
                        # Check the mode
                        if true
                            pos = (x-1)/(CursedPlayer.w-2)
                            #@@player.set_time (pos*@@player.get_length).to_i64
                            CursedPlayer.player.set_position pos
                        end
                    end
                end
            end
        end
    end
end