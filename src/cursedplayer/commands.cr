# Everything related to commands
module CursedPlayer

    # Biiiig case / switch statement where commands are detected
    # When entering some text in the command input field (bottom), the first word is the actual command (without the leading ":")
    # The rest are just arguments
    def run_command(command, arg)
        success = true
        case command
            when "q", "quit"
                CursedPlayer.exit 

            when "reload"
                CursedPlayer.reload_config

            when "edit"
                CursedPlayer.open_config

            when "save_metadata"
                CursedPlayer.library.save


            when "stop"
                CursedPlayer.stop

            when "play"
                if arg == ""
                    CursedPlayer.play
                else
                    begin
                        i = arg.to_i
                        if i >= 0 && i < CursedPlayer.queue.count
                            @@player.play_index(i)
                        else
                            success = false
                        end
                    rescue
                        success = false
                    end 
                end

            when "pause"
                CursedPlayer.player.pause


            when "scroll_to"
                if arg == "start"
                    @@tabs.event("Queue", "scroll", "start")
                elsif arg == "end"
                    @@tabs.event("Queue", "scroll", "end")
                elsif arg == "song"
                    @@tabs.event("Queue", "scroll", "song")
                else
                    begin
                        @@tabs.event("Queue", "scroll", "set", arg.to_i)
                    rescue
                        success = false
                    end
                end      
            else
                success = false
        end

        # Show a colored bar, depending on the success of the command
        # By default red for unsuccessfull commands / green for successfull
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
            Process.run("sh -c \"xdg-open \'#{path}\' & disown \"",nil,nil,false,true)
        end
    end

    def error_no_songs
        NCurses.clear
        NCurses.set_color 5
        NCurses.attr_on NCurses::Attribute::Bold
        NCurses.print "No songs are in your library", @@h / 2, @@w / 2 - 2
        NCurses.print "Please run this command with songs", @@h / 2 + 1, @@w / 2 - 2
        NCurses.refresh
        sleep 1
        NCurses.end
        exit(0)
    end

    def exit

        # Stopping the player
        if @@player.is_playing?
            @@player.stop
        end

        # Saving the metadata
        NCurses.clear
        NCurses.set_color 6
        NCurses.attr_on NCurses::Attribute::Bold
        NCurses.print "Saving Metadata", @@h / 2, @@w / 2 - 2
        NCurses.refresh
        CursedPlayer.library.save

        # Stopping NCurses
        NCurses.clear
        NCurses.print "Bye!", @@h / 2, @@w / 2 - 2
        NCurses.refresh
        sleep 0.5
        @@tabs.delete_window
        NCurses.end

        # Resets the Terminal title
        CursedPlayer.set_title ""
        exit(0)
    end

end