require 'singleton'
require 'logger'
require 'yaml'

module Watirmark

  class Configuration
    include Singleton

    def initialize
      @settings         = {}
      @runtime_defaults = {}
      reload
    end

    def defaults
      {
        :configfile         => nil,
        :hostname           => nil,
        :email              => 'devnull',
        :closebrowseronexit => false,
        :loglevel           => Logger::INFO,
        :uuid               => nil,
        :webdriver          => :firefox,
        :statistics         => false,
        :headless           => false,
        # database
        :dbhostname         => nil,
        :dbusername         => nil,
        :dbpassword         => nil,
        :dbsid              => nil,
        :dbport             => nil,
        # snapshots
        :snapshotwidth      => 1000,
        :snapshotheight     => 1000,
        :projectpath        => nil,
        :sauce_username     => nil,
        :sauce_access_key   => nil,
        :dbi_url            => nil,

        #to deprecate
        :profile            => Hash.new { |h, k| h[k] = Hash.new },
        :profile_name       => :undefined,

      }.merge @runtime_defaults
    end

    def defaults=(x)
      @runtime_defaults.merge! x
      reload
    end

    def update(values)
      values.each_pair { |k, v|
        v = Logger.const_get(v.upcase) if k.to_s == "loglevel" && v.class == String
        self[k] = v
      }
    end

    def inspect
      @settings.inspect
    end

    def reset
      @settings.each_key { |key| @settings.delete key }
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

    def db
      @db = nil if (@db && @db.respond_to?(:dbh) && @db.dbh.handle == nil)
      @db ||= WatirmarkDB::DB.new(self.hostname, self.dbhostname, self.dbusername, self.dbpassword, self.dbsid, self.dbport)
    end


    # This will read in ANY variable set in a configuration file
    def read_from_file
      return unless File.exists?(configfile.to_s)
      filename = File.expand_path(configfile)
      case File.extname filename
        when ".txt", ".hudson"
          parse_text_file filename
        when ".yml"
          parse_yaml_file filename
        else
          Watirmark.logger.warn "Unsure how to handle configuration file #{configfile}. Assuming .txt"
          parse_text_file filename
      end
    end

    alias :read :read_from_file

    # The variable needs to be set as a default here or in the
    # library to be read from the environment
    def read_from_environment
      @settings.each_key do |var|
        next if var.to_s.upcase == "USERNAME"
        next if var.to_s.upcase == "HOSTNAME" && self.hostname
        env = ENV[var.to_s.upcase]
        if var == :webdriver
          ENV['JOB_NAME']=~ /WEBDRIVER=(\w+)/
          env ||= $1
        end
        update_key var, env if env
      end
    end

    def reload
      update(defaults)
      read_from_file
      read_from_environment
      initialize_logger
    end

    def logger
      @logger ||= begin
        log = Logger.new STDOUT
        log.formatter = proc {|severity, datetime, progname, msg| "[#{datetime}] #{msg}\n"}
        log
      end
    end

    def loglevel=(x)
      logger.level = x
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
      logger.warn "profiles are going to be deprecated. Please use YAML and salesforce_sites"
      if self[:profile][$1.to_sym] == nil
        self[:profile] = ({$1.to_sym => {$2.to_sym => value.to_s}})
      else
        self[:profile][$1.to_sym].merge!({$2.to_sym => value.to_s})
      end
    end

    def update_profile_yaml
      if self[:salesforce_sites] && self[:salesforce_sites]["active"]
        site = self[:salesforce_sites]["active"]
        self[:salesforce_sites][site].each do |key, value|
          self[key.to_sym] = value
        end
      end
    end

    def parse_yaml_file filename
      YAML.load_file(filename).each_pair { |key, value| update_key key, value }
      update_profile_yaml
    end

    # This is the old-style method of using a config.txt
    def parse_text_file filename
      Watirmark.logger.warn "Warning: Deprecated use of config.txt. Please use config.yml instead"
      IO.readlines(filename).each do |line|
        line.strip!                 # Remove all extraneous whitespace
        line.sub!(/#.*$/, "")       # Remove comments
        next unless line.length > 0 # Anything left?
        (key, value) = line.split(/\s*=\s*/, 2)
        update_profile key
        update_key key, value
      end
    end
  end

  def self.logger
    Configuration.instance.logger ||= Logger.new(STDOUT)
  end

end