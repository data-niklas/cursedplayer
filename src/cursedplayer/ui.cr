require "ncurses"

UNI_DOTS = %w(⠋ ⠙ ⠹ ⠸ ⠼ ⠴ ⠦ ⠧ ⠇ ⠏)

module CursedPlayer extend self

    def w
        @@w
    end
    def h
        @@h
    end

    @@h = 0
    @@w = 0
    @@x = 0
    @@y = 0

    @@title_length = 0
    @@time_length = 0
    @@time_mode = 0

    @@command = ""
    @@mode = "default"

    @@command_area = uninitialized NCurses::Window
    @@status_area = uninitialized NCurses::Window
    @@content_area = uninitialized TabWindow

    # Is a popup visible?
    @@popup = false

    @@library_loading = true
    @@update_interval = 0.15

    

    def ui_init
        NCurses.start
        NCurses.start_color
        NCurses.cbreak
        NCurses.no_echo
        NCurses.no_timeout
        NCurses.no_delay
        NCurses.keypad true
        NCurses.set_cursor NCurses::Cursor::Invisible
        NCurses.mouse_mask(NCurses::Mouse::AllEvents | NCurses::Mouse::Position)
        LibNCurses.use_default_colors
        ## Colors

        NCurses.init_color_pair(1, NCurses::Color::Default, NCurses::Color::Green)  # Success
        NCurses.init_color_pair(2, NCurses::Color::Default, NCurses::Color::Red)    # Error
        NCurses.init_color_pair(3, NCurses::Color::Green, NCurses::Color::Default)  # Success text
        NCurses.init_color_pair(4, NCurses::Color::Cyan, NCurses::Color::Default)  # Primary
        @@h = NCurses.height
        @@w = NCurses.width
    end

    def ui_loop
        render_all
        get_keys
    end

    def get_keys
        NCurses.get_char do |ch|
            if ch == NCurses::Key::Mouse
                mouse = NCurses.get_mouse
                if mouse.nil?
                    next
                else
                    mouse = mouse.as(NCurses::MouseEvent)
                end

                if !@@popup
                    if (mouse.state.value > NCurses::Mouse::Position.value || mouse.state == NCurses::Mouse::B1Clicked || mouse.state == NCurses::Mouse::B1Pressed)
                        
                        if mouse.coordinates["y"] == 0
                            if mouse.coordinates["x"] < @@title_length
                                open_current_song
                            elsif mouse.coordinates["x"] >= @@w - @@time_length
                                @@time_mode = (@@time_mode + 1) % 4
                                render_status
                            end
                        elsif mouse.coordinates["y"] == 1
                            # Clicked on the progress bar?
                            # Check the mode
                            if true
                                pos = (mouse.coordinates["x"]-1)/(@@w-2)
                                #@@player.set_time (pos*@@player.get_length).to_i64
                                @@player.set_position pos
                            end
                        elsif mouse.coordinates["y"] == 2
                            @@content_area.tab_click mouse.coordinates["x"]
                        end
                    end
                end
            elsif ch == NCurses::Key::Resize
                @@h = NCurses.height
                @@w = NCurses.width
                render_all
            else
                case @@mode
                    when "default"
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
                            else
                        end
                    when "command"
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
                        render_command
                    else
                end 
            end
        end
            
    end

    def strip_time(str)
        if str.starts_with?("00:")
            str[3...]
        else
            str
        end
    end

    def render_status
        @@status_area.clear
        if !@@current_song.nil?
            song = @@current_song.as(Player::Media)

            pos = FORMAT.format(Time.unix_ms(@@player.get_time))
            if @@time_mode % 2 == 0
                len = song.get_formatted_length FORMAT
            else
                len = FORMAT.format(Time.unix_ms(song.get_length - @@player.get_time))
            end
            len = strip_time len
            pos = strip_time pos
            if @@time_mode < 2
                time = " " + pos + " - " + len
            else
                time = " " + (@@time_mode == 3 ? len : pos)
            end
            @@time_length = time.size

            @@status_area.with_attr NCurses::Attribute::Bold do
                @@status_area.set_color 4
                title = song.get_meta(LibVlc::Meta::Title).sub(".mp3","")
                @@title_length = title.size
                @@status_area.print title
                @@status_area.set_color 0
                @@status_area.set_pos 0, @@w - @@time_length
                @@status_area.print time
            end

            @@status_area.set_pos 1, 0
            @@status_area.print "["
            ratio = @@player.get_position
            space = @@w - 2
            wfinished = LibM.ceil_f64(space*ratio - 0.5).to_i
            @@status_area.print "=".*(wfinished)
            @@status_area.with_attr NCurses::Attribute::Dim do
                @@status_area.print "-".*(space - wfinished)
            end
            @@status_area.print "]" 
        end
        @@status_area.refresh
    end

    def render_command_result(success : Bool)
        @@command_area.set_color (success ? 1 : 2)
        @@command_area.print " ".*(@@w), 0, 0
        @@command_area.refresh
        @@command_area.set_color 4
        sleep 0.5
    end

    def render_command
        @@command_area.clear
        @@command_area.print @@command, 0, 0
        @@command_area.refresh
    end

    def library_loaded
        @@library_loading = false
    end

    def meta_updated()
        @@content_area.repaint()
    end

    def render_library_load
        spawn do
            index = 0
            @@library_loading = true
            NCurses.with_attr NCurses::Attribute::Bold do
                while @@library_loading
                    NCurses.clear
                    text = UNI_DOTS[index] + " Loading songs"
                    NCurses.print text, @@h / 2, (@@w - text.size) / 2
                    NCurses.refresh
                    index=(index+1)%10
                    sleep @@update_interval
                end
            end
        end
    end

    @@num2 = 0
    def render_all
        NCurses.clear
        @@status_area = NCurses::Window.new 2, @@w, 0, 0

        @@command_area = NCurses::Window.new 1, @@w, @@h - 1, 0
        @@command_area.attr_on NCurses::Attribute::Bold
        @@command_area.set_color 4

        @@content_area = TabWindow.new @@h - 3, @@w, 2, 0, 7
        @@content_area.add_tab(QueueTab.new "Queue", true)

        NCurses.refresh
        render_status
        render_command
        @@content_area.repaint
    end


end
