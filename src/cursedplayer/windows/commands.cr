require "ncurses"

module CursedPlayer
    class CommandArea < NCurses::EventWindow
        def initialize
            initialize(1, CursedPlayer.w, CursedPlayer.h - 1, 0)
            track
            attr_on NCurses::Attribute::Bold
            set_color 4
        end

        def update_size
            resize 1, CursedPlayer.w
            move_window CursedPlayer.h - 1, 0
            render_command CursedPlayer.command
        end

        def render_command(command : String)
            clear
            print command, 0, 0
            refresh
        end

        def mouse_pressed(state, x, y, z, device_id)
        end
    end
end