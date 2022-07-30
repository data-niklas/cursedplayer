require "./tabwindow.cr"
require "../config.cr"

module CursedPlayer
    class QueueTab < Tab

        @scroll_y = 0

        def render
            clear
            q = CursedPlayer.queue
            q_size = q.count
            i = 0
            h = height
            w = width
            while i + @scroll_y < q_size && i < h
                song = q.get(i + @scroll_y)
                render_song song, i, w, h

                i+=1
            end
            refresh
        end

        def render_scrolled(scroll_amount : Int32)
            h = height
            w = width
            q = CursedPlayer.queue
            q_size = q.count
            e = h
            i = 0
            if scroll_amount < 0
                e = -1 * scroll_amount 
            else
                i = e - scroll_amount
            end
            while i + @scroll_y < q_size && i < e
                song = q.get(i + @scroll_y)
                render_song song, i, w, h
                i+=1
            end
            refresh
        end

        def render_song(song, i, w, h)
            if !CursedPlayer.library.has? song.url
                time = ""
                title = song.get_meta(LibVlc::Meta::Title).sub(".mp3","")
                artist = ""
            else
                entry = CursedPlayer.library.songtable[song.url]
                title = entry[0]
                artist = entry[1]
                time = CursedPlayer.strip_time(FORMAT.format(Time.unix_ms(entry[3])))
            end
            pos = w - time.size - 6 - artist.size
            if pos < title.size
                pos = title.size
            end

            current = !CursedPlayer.current_song.nil? && song.obj.address == CursedPlayer.current_song.as(Player::Media).obj.address
            if current
                set_color 4
            end

            separator = CursedPlayer.conf.as_s("table_separator")
            print " ".*(w), i, 0
            print title, i, 0
            print separator + artist, i, pos
            print separator + time, i, w - time.size - 3

            if current
                set_color 0
            end
        end

        def clear_row(i, w)
            print " "*(w), i, 0
        end

        def select
            @visible = true
        end

        def unselect
            @visible = false
        end

        def scroll_songs(mode : Int32 = 0, num : Int32 = 1)
            c = CursedPlayer.queue.count
            h = height
            return if c <= h || !@visible
            old = @scroll_y
            if mode == 0
                @scroll_y = Math.max @scroll_y - num, 0
            elsif mode == 1
                @scroll_y = Math.min @scroll_y + num, c-h
            elsif mode == 2
                @scroll_y = Math.max(0, Math.min(num, c-h))
            elsif mode == 3
                @scroll_y = c-h
            elsif mode == 4
                return if CursedPlayer.current_song.nil?
                @scroll_y = Math.max(0, CursedPlayer.queue.index_of(CursedPlayer.current_song.as(Player::Media)))
            end
            return if @scroll_y - old == 0
            scrollok true
            scroll @scroll_y - old
            scrollok false
            render_scrolled @scroll_y - old
        end

        def mouse_pressed(event, x, y, z)
            if !CursedPlayer.popup && @visible
                if event.state_includes? NCurses::Mouse::B1Clicked
                elsif event.state_includes? NCurses::Mouse::B1DoubleClicked
                    song = y + @scroll_y
                    if song < CursedPlayer.queue.count
                        CursedPlayer.player.play_index song
                    end
                else
                end
            end
        end

        def event(name : String, sub_event : String, data : Int32 | Player::Media)
            case name
                when "new_media"
                    if @visible
                        render
                    end
                when "scroll"
                    if sub_event == "up"
                        scroll_songs
                    elsif sub_event == "down"
                        scroll_songs 1
                    elsif sub_event == "set"
                        if data.is_a?(Int32)
                            scroll_songs 2, data.as(Int32)
                        end
                    elsif sub_event == "start"
                        scroll_songs 2, 0
                    elsif sub_event == "end"
                        scroll_songs 3
                    elsif sub_event == "song"
                        scroll_songs 4
                    end
                when "song_updated"
                    if @visible
                        q = CursedPlayer.queue
                        i = uninitialized Int32
                        song = uninitialized Player::Media
                        if data.is_a?(Player::Media)
                            song = data.as(Player::Media)
                            i = q.index_of song
                        elsif data.is_a?(Int32)
                            i = data.as(Int32)
                            song = q.get i
                        end
                        w = width
                        h = height

                        # Add parsed song to library
                        if !CursedPlayer.library.has? song.url
                            res = song.parse Player::MediaParseFlag::FetchLocal | Player::MediaParseFlag::ParseLocal, -1
                            song.on Player::Event::MediaParsedChanged, song.obj do |a,b|
                                s = Player::Media.new(b.as(Pointer(LibVlc::Media)))
                                CursedPlayer.library.add_parsed_song s
                            end
                        end
                        if i >= @scroll_y && i < @scroll_y + h
                            clear_row i - @scroll_y, w
                            render_song song, i - @scroll_y, w, h
                            refresh
                        else
                        end
                    end
                else

            end
        end



    end
end