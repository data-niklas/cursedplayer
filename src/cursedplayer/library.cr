require "csv"

# Song metadata is stored in a csv file
# Metadata is stored on exit
module CursedPlayer
    @@library = uninitialized Library

    def library
        @@library
    end

    def load_library(songs : Array(String), file : Path)
        @@library = Library.new songs, file
    end

    class Library
        @@parsing : Int32 = 0
        @@parsed : Int32 = 0
        @songtable = SongTable.new
        def initialize(songs : Array(String), @file : Path = "")
            list = CursedPlayer.player.list!
            @songtable = load_csv

            if songs.size > 0
                songs.each do |song|
                    list << Library.make_song(song)
                end
            end

        end

        def add_to_queue
            list = CursedPlayer.player.list!
            if @songtable.size == 0 && list.count == 0
                CursedPlayer.error_no_songs
            else
                @songtable.each_key do |song|
                    list << Library.make_song(song)
                end
            end
        end

        def self.make_song(url : String)
            if url.starts_with?("http")
                Player::Media.new(url, false)
            else
                Player::Media.new url
            end
        end

        def add_parsed_song(song)
            t = song.get_meta(LibVlc::Meta::Title).sub(".mp3","")
            ar = song.get_meta(LibVlc::Meta::Artist)
            al = song.get_meta(LibVlc::Meta::Album)
            CursedPlayer.library.songtable[song.url] = Tuple(String, String, String, Int64).new(t, ar, al, song.get_length)
        end


        def load_csv
            res = SongTable.new
            csv = CSV.new File.read(@file)
            while csv.next
                row = csv.row.to_a
                next if row.size != 5
                begin
                    length = row[4].to_i64
                    res[row[0]] = Song.new(row[1], row[2], row[3], length)
                rescue
                    exit(1)
                end
            end
            res
        end

        def save
            res = CSV.build do |csv|
                @songtable.each do |k,v|
                    csv.row k, v[0], v[1], v[2], v[3].to_s
                end
            end
            File.write @file, res
        end

        def songtable
            @songtable
        end

        def has?(url : String)
            @songtable.has_key? url
        end



    end

    # Stores title, artist, album, length
    alias Song = Tuple(String, String, String, Int64)
    alias SongTable = Hash(String, Song)


    def make_queue(songs : Array(Player::Media))

    end

end