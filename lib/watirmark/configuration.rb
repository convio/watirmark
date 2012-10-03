require 'singleton'
require 'logger'
require 'watirmark-log'
module Watirmark
  class Configuration
    include Singleton

    def initialize
      @settings = {}
      @runtime_defaults = {}
      reload
    end

    def defaults
      {
        :configfile         => nil,
        :hostname           => nil,
        :attach             => nil,
        :email              => 'devnull',
        :closebrowseronexit => false,
        :loggedin           => false,
        :visible            => true,
        :profile            => Hash.new {|h,k| h[k] = Hash.new},
        :profile_name       => :undefined,
        :loglevel           => Logger::INFO,
        :uuid               => nil,
        :webdriver          => :firefox,

        :snapshotwidth      => 1000,
        :snapshotheight     => 1000,

        :dbhostname         => nil,
        :dbusername         => nil,
        :dbpassword         => nil,
        :dbsid              => nil,
        :dbport             => nil,

        :sandbox            => false,
      }.merge @runtime_defaults
    end

    def defaults=(x)
      @runtime_defaults.merge! x
      reload
    end

    def update(values)
      values.each_pair {|k,v|
        v = Logger.const_get(v.upcase) if k.to_s == "loglevel" && v.class == String
        self[k] = v
      }
    end

    def inspect
      @settings.inspect
    end

    def reset
      @settings.each_key {|key| @settings.delete key}
    end

    def [](key)
      @settings[key.to_sym]
    end

    def []=(key, value)
      override_method = "#{key}_value".to_sym
      if respond_to? override_method
        @settings[key.to_sym] = self.send override_method, value
      else
        @settings[key.to_sym] = value
      end
    end

    def method_missing(sym, *args)
      if sym.to_s =~ /(.+)=$/
        self[$1] = args.first
      else
        self[sym]
      end
    end

    # Use a common db connection
    def db
      @db = nil if (@db && @db.respond_to?(:dbh) && @db.dbh.handle == nil)
      @db ||= WatirmarkDB::DB.new(self.hostname, self.dbhostname, self.dbusername, self.dbpassword, self.dbsid, self.dbport)
    end


    # This will read in ANY variable set in a configuration file
    def read_from_file
      return unless File.exists?(configfile.to_s)
      filename = File.expand_path(configfile)
      case File.extname filename
        when ".txt"
          parse_text_file filename
        when ".yml"
          parse_yaml_file filename
        else
          warn "Unsure how to handle configuration file #{configfile}. Assuming .txt"
          parse_text_file filename
      end
    end
    alias :read :read_from_file


    def parse_yaml_file filename
      settings = YAML.load_file filename
      settings.each_pair do |key, value|
        update_key key, value
      end
    end

    # This is the old-style method of using a config.txt
    def parse_text_file filename
      warn("Warning: Deprecated use of config.txt. Please use config.yml instead")
      for line in IO.readlines(filename)
        line.strip!                             # Remove all extraneous whitespace
        line.sub!(/#.*$/, "")                   # Remove comments
        next unless line.length > 0             # Anything left?
        (key, value) = line.split(/\s*=\s*/, 2)
        update_profile key
        update_key key, value
      end
    end
      
    # The variable needs to be set as a default here or in the
    # library to be read from the environment
    def read_from_environment
      @settings.each_key do |var|
        next if var.to_s.upcase == "USERNAME"
        env = ENV[var.to_s.upcase]
        if var == :webdriver
          ENV['JOB_NAME']=~ /WEBDRIVER=(\w+)/
          env ||= $1
        end
        update var.to_sym => env if env
      end
    end

    def reload
      update(defaults)
      read_from_file
      read_from_environment
      initialize_logger
    end

    def initialize_logger
      logger = WatirmarkLog::Logger.new('WatirmarkLog')
      logger.level = self[:loglevel]

      update({:logger => logger})
    end

  private

    def update_key key, value
      case value
        when 'true'
          update key.to_sym => true
        when 'false'
          update key.to_sym => false
        when /^:(.+)/
          update key.to_sym => $1.to_sym
        when /^\d+\s*$/
          update key.to_sym => value.to_i
        when /^(\d*\.\d+)\s*$/
          update key.to_sym => value.to_f
        else
          update key.to_sym => value
      end
    end

    def update_profile key
      return unless key =~ /^profile\[:(.+)\]\[:(.+)\]/
      if self[:profile][$1.to_sym] == nil
        self[:profile] = ({$1.to_sym => {$2.to_sym => value.to_s}})
      else
        self[:profile][$1.to_sym].merge!({$2.to_sym => value.to_s})
      end
    end



  end
end