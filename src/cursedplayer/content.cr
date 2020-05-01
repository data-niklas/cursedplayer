require "./tabwindow.cr"
require "./config.cr"

module CursedPlayer
    class QueueTab < Tab
        def render(ui : NCurses::Window, w, h)
            q = CursedPlayer.queue
            q_size = q.count
            i = 0
            while i + @scroll_y < q_size && i < h
                song = q.get(i + @scroll_y)
                title = song.get_meta(LibVlc::Meta::Title).sub(".mp3","")
                artist = song.get_meta(LibVlc::Meta::Artist)
                time = CursedPlayer.strip_time(song.get_formatted_length FORMAT)
                pos = w - time.size - 6 - artist.size
                if pos < title.size
                    pos = title.size
                end

                current = !CursedPlayer.current_song.nil? && song.obj.address == CursedPlayer.current_song.as(Player::Media).obj.address
                if current
                    ui.set_color 4
                end


                ui.print title, i + 1, 0
                ui.print CursedPlayer.conf.as_s("table_separator") + artist, i + 1, pos
                ui.print CursedPlayer.conf.as_s("table_separator") + time, i + 1, w - time.size - 3

                if current
                    ui.set_color 0
                end

                i+=1
            end
        end

        def select_item(index, pos)

        end

        def select
        end

        def scroll(up = true)

        end

        def rerender?(queue_index : Int32, w : Int32, h : Int32)
            return (queue_index >= @scroll_y && queue_index < (@scroll_y + h))
        end
    end
end