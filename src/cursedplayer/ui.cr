require "ncurses"
require "./windows/*"
require "vlc"
require "mediaplayer"

UNI_DOTS = %w(⠋ ⠙ ⠹ ⠸ ⠼ ⠴ ⠦ ⠧ ⠇ ⠏)

module CursedPlayer extend self

    class_property time_mode, time_length, title_length
    class_getter w, h, popup, command

    @@h = 0
    @@w = 0
    @@x = 0
    @@y = 0

    @@title_length = 0
    @@time_length = 0
    @@time_mode = 0

    @@command = ""
    @@mode = "default"

    @@command_area = uninitialized CommandArea
    @@status_area = uninitialized StatusArea
    @@tabs = uninitialized TabBar

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
        #NCurses.no_delay
        NCurses.keypad true
        NCurses.set_cursor NCurses::Cursor::Invisible
        NCurses.mouse_mask(NCurses::Mouse::AllEvents | NCurses::Mouse::Position)
        LibNCurses.use_default_colors
        ## Colors

        NCurses.init_color_pair(1, NCurses::Color::Default, NCurses::Color::Green)  # Success
        NCurses.init_color_pair(2, NCurses::Color::Default, NCurses::Color::Red)    # Error
        NCurses.init_color_pair(3, NCurses::Color::Default, NCurses::Color::Green)  # Success
        NCurses.init_color_pair(5, NCurses::Color::Red, NCurses::Color::Default)    # Error
        NCurses.init_color_pair(6, NCurses::Color::Green, NCurses::Color::Default)  # Success
        NCurses.init_color_pair(4, NCurses::Color::Cyan, NCurses::Color::Default)  # Primary

        @@h = NCurses.height
        @@w = NCurses.width

    end

    def ui_loop
        render_all
        CursedPlayer.play
        get_keys
    end

    def get_keys
        NCurses.get_char_delegate_mouse do |ch|
            if ch.is_a? NCurses::MouseEvent
                mouse = ch.as(NCurses::MouseEvent)
            elsif ch == NCurses::Key::Resize
                @@h = NCurses.height
                @@w = NCurses.width
                resize_all
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
                            when NCurses::Key::Up
                                @@tabs.event "Queue", "scroll", "up"
                            when NCurses::Key::Down
                                @@tabs.event "Queue", "scroll", "down"
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
        if !@@current_song.nil?
            @@status_area.render @@current_song.as(Player::Media)
        end
    end

    def render_command_result(success : Bool)
        @@command_area.set_color (success ? 1 : 2)
        @@command_area.print " ".*(@@w), 0, 0
        @@command_area.refresh
        @@command_area.set_color 4
        sleep 0.5
    end

    def render_command
        @@command_area.render_command @@command
    end

    def library_loaded
        @@library_loading = false
    end

    def meta_updated()
        @@tabs.render_tab()
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

    def render_all
        NCurses.clear
        @@status_area = StatusArea.new

        @@command_area = CommandArea.new

        @@tabs = TabBar.new
        @@tabs.add_tab(QueueTab.new "Queue")

        NCurses.refresh
        render_status
        render_command
        @@tabs.render
        @@tabs.render_tab
    end

    def resize_all
        @@status_area.update_size
        @@tabs.update_size
        @@command_area.update_size
    end

    def set_title(title : String)
        puts "\033]0;#{title}\007"
    end


end
