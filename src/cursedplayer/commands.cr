module CursedPlayer
    def run_command(command, arg)
        success = true
        case command
            when "q", "quit"
                CursedPlayer.exit 
            when "stop"
                CursedPlayer.stop
            when "play"
                CursedPlayer.play
            when "pause"
                CursedPlayer.player.pause
            when "reload"
                CursedPlayer.reload_config
            when "edit"
                CursedPlayer.open_config
            else
                success = false
        end
        if success
            render_command_result true
        else
            render_command_result false
        end
    end


    # Opens the current song in the file explorer with xdg-open
    def open_current_song
        if !@@current_song.nil?
            path = Path[@@current_song.as(Player::Media).url].parent.to_s
            Process.run("sh -c \"xdg-open \'#{path}\' & disown \"",nil,nil,false,true)
        end
    end
    # Opens the config file with xdg-open
    def open_config
        if !@@current_song.nil?
            path = @@conf.file
            Process.run("sh -c \"xdg-open \'#{path}\'\"",nil,nil,false,true)
        end
    end

    def exit
        if @@player.is_playing?
            @@player.stop
        end
        NCurses.clear
        NCurses.set_color 3
        NCurses.attr_on NCurses::Attribute::Bold
        NCurses.print "Bye!", @@h / 2, @@w / 2 - 2
        NCurses.refresh
        sleep 1
        @@content_area.delete_window
        NCurses.end
        exit(0)
    end

end