require 'rubigen'
class CreateProjectGenerator < RubiGen::Base
  default_options :author => nil
  attr_reader :name

  def initialize(runtime_args, runtime_options = {})
    super
    usage if args.empty?
    @name = File.basename(args.shift)
    @destination_root = File.expand_path(@name)
    extract_options
  end

  def manifest
    record do |m|    
      create_directories(m)
      m.template "project/gemfile.rb.erb", "Gemfile"
      m.template "project/config.txt.erb", "config.txt"
      m.template "project/rakefile.rb.erb", "rakefile.rb"

      # main library
      m.template "library/page_load_checker.rb.erb", File.join("lib", name, "checkers", "page_load_checker.rb")
      m.template "library/post_errors_checker.rb.erb", File.join("lib", name, "checkers", "post_errors_checker.rb")
      m.template "library/base_controller.rb.erb", File.join("lib", name, "controllers", "base_controller.rb")
      m.template "library/search_controller.rb.erb", File.join("lib", name, "controllers", "search_controller.rb")
      m.template "library/base_view.rb.erb", File.join("lib", name, "views", "base_view.rb")
      m.template "library/configuration.rb.erb", File.join("lib", name, "configuration.rb")
      m.template "library/workflows.rb.erb", File.join("lib", name, "workflows.rb")
      m.template "library/core_libraries.rb.erb", File.join("lib", name, "core_libraries.rb")
      m.template "library/loader.rb.erb", File.join("lib", name, "loader.rb")
      m.template "library/project_require_file.rb.erb", File.join("lib","#{name}.rb")

      m.template "generators/generate.rb.erb", File.join("script","generate.rb")
      m.template "generators/mvc_generator.rb.erb", File.join("generators","mvc","mvc_generator.rb")
      m.template "generators/rbeautify.rb.erb", File.join("generators", "mvc", "rbeautify.rb")
      m.template "generators/controller.rb.erb", File.join("generators","mvc","templates","controller.rb.erb")
      m.template "generators/model.rb.erb", File.join("generators","mvc","templates","model.rb.erb")
      m.template "generators/view.rb.erb", File.join("generators","mvc","templates","view.rb.erb")
      m.template "generators/workflow_loader.rb.erb", File.join("generators","mvc","templates","workflow_loader.rb.erb")

      m.template "features/model_steps.rb.erb", File.join("features","step_definitions","model_steps.rb")
      m.template "features/post_error_steps.rb.erb", File.join("features","step_definitions","post_error_steps.rb")
      m.template "features/env.rb.erb", File.join("features","support","env.rb")

    end
  end

  def create_directories(m)
    BASEDIRS.each { |path| m.directory path }
    create_subdirectories m, File.join('features'), %w(step_definitions support)
    create_subdirectories m, File.join('lib', @name), %w(checkers controllers views workflows)
    create_subdirectories m, File.join('generators', 'mvc'), %w(templates)
  end

  def create_subdirectories (m, root, directories)
    m.directory root
    directories.each {|dir| m.directory File.join(root, dir)}
  end


  protected
    def banner
      <<-EOS
USAGE: #{spec.name} path/for/your/test/create_project project_name [options]
EOS
    end

    def add_options!(opts)
      opts.separator ''
      opts.separator 'Options:'
      # For each option below, place the default
      # at the top of the file next to "default_options"
      # opts.on("-a", "--author=\"Your Name\"", String,
      #         "Some comment about this option",
      #         "Default: none") { |options[:author]| }
      opts.on("-v", "--version", "Show the #{File.basename($0)} version number and quit.")
    end

    def extract_options
      # for each option, extract it into a local variable (and create an "attr_reader :author" at the top)
      # Templates can access these value via the attr_reader-generated methods, but not the
      # raw instance variable value.
      # @author = options[:author]
    end

    # Installation skeleton.  Intermediate directories are automatically
    # created so don't sweat their absence here.
    BASEDIRS = %w(
      features
      generators
      lib
      script
    )
end