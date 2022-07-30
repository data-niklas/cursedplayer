require "./tabwindow.cr"
require "../config.cr"

module CursedPlayer
    class HelpTab < Tab

        @page = 0
        @@tab = "\t\t"
        # Actual pages, without the main page
        @@totalpages = 2
        # Should be bigger than the largest command (string length)
        @@command_length = 20

        def render
            clear
            case @page
                when 0
                    render_pages
                when 1
                    render_commands
                when 2
                    render_hotkeys
                else
            end
            refresh
        end

        def render_pages
            bold {
                print "Commands\n"
                print "Hotkeys\n"
            }
        end


        def render_commands

            bold "Commands:\n"

            paragraph do
                bold {
                    bullet "Application Control"
                }
                item "q / quit", "Exits the application" 
                item "reload", "Reload the config file" 
                item "edit", "Edit the config file. It will be opened via 'xdg-open'" 
                item "save_metadata", "Saves the current library / metadata; By default it is saved on exit" 

            end

            paragraph do
                bold {
                    bullet "Media Control"
                }
                item "play", "Play music / Continue with the current song"
                item "pause", "Pause the current music"
                item "stop", "Stop the music"
            end
        end

        def render_hotkeys

            bold "Hotkeys:\n"
            paragraph do
                bold {
                    bullet "Application Control"
                }
                item ":", "Start a command" 
            end

            paragraph do
                bold {
                    bullet "Media Control"
                }
                item "<Space>", "Play / Pause music"
                item "n", "Next song"
                item "p", "Previous song"
            end
        end


        def item(name, explanation)
            bullet name + (" " * (@@command_length - name.size)) + explanation
        end

        def bullet(text)
            print @@tab + text + "\n"
        end

        def paragraph
            yield
            print "\n"
        end

        def bold(text)
            with_attr NCurses::Attribute::Bold do
                print text
            end
        end
        def bold
            with_attr NCurses::Attribute::Bold do
                yield
            end
        end


        def select
            @visible = true
        end

        def unselect 
            @visible = false
        end

        def mouse_pressed(event, x, y, z)
            return if !visible || @page > 0
            newpage = y + 1
            return if newpage > @@totalpages
            @page = newpage
            render
        end

        def event(name : String, sub_event : String, data : Int32 | Player::Media)
            return if !visible || @page == 0
            case name
                when "return"
                    @page = 0
                    render
                else
            end
        end


    end

end