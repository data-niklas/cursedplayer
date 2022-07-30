require "conf"

module CursedPlayer
    @@conf = uninitialized Conf
    def load_config(file : String | Path)
        @@conf = Conf.new file
        fix_config
    end

    def reload_config
        @@conf.reload
        fix_config
    end

    def fix_config
        @@conf["time_delta"] = @@conf.as_i?("time_delta", 2000)
        @@conf["table_separator"] = " " + @@conf.as_s?("table_separator", " ").to_s + " "
        @@conf["tab_separator"] = @@conf.as_s?("tab_separator", " ")
    end

    def conf
        @@conf
    end

end