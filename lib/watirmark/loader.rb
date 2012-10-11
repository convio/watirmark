module Watirmark

  def self.loader &block
    ActiveSupport::Dependencies.mechanism = :require if defined? ActiveSupport::Dependencies
    Loader.new.instance_eval &block
  end
  
  # This can be used for files that are page classes or flows.
  # Autoloading them
  # will not actually 'require' the file until a class in that file is used. 
  # Note that this does not apply to modules so it's most useful for the
  # page accessors and any files in admin, user, etc.   
  class Loader  

    def autoload_files(directory)
      mod = "Watirmark::#{product}"
      each_file_in directory do |file|
        libpath = library_path(file)
        IO.readlines(file).each do |line|
          _autoload_(mod, $1, libpath) if line =~ /^\s*class\s+([^<]\S+)[\s<]/
          _autoload_(mod, $1, libpath) if line =~ /^\s+([A-Z]\S+)\s+=\s+[A-Z]\S+/
        end
      end
    end
    alias :autoload_file :autoload_files

    def _autoload_(mod, klass, path)
      return if klass =~ /\./
      str = "module ::#{mod}; autoload :#{klass}, '#{path}'; end"
      eval str
    end
    private :_autoload_

    def load_files(directory) # product not used
      each_file_in directory do | file |
        require library_path(file)
      end
    end
    
    def base_directory arg=nil
      if arg
        @base_directory = arg
      elsif @base_directory
        @base_directory
      else
        raise "base_directory not set"
      end
    end
    
    def product arg=nil
      if arg
        @product = arg
      elsif @product
        @product
      else 
        raise "product not set"
      end
    end
    
    def module arg=nil
      if arg
        @module = arg
      elseif 
      end
    end
    
    private

    def library_path(file)
      File.join(File.dirname(file), File.basename(file, '.rb'))
    end

    def each_file_in(directory)
      lib_path = File.join(base_directory, directory)
      if File.directory?(lib_path)
        files = Dir.glob(File.join(lib_path, '*.rb'))
      else
        files = Dir.glob(lib_path)
      end
      files.each do |file|
        yield file unless File.directory? file
      end
    end    
  end
end