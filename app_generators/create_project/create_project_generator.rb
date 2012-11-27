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
      create_project_files(m)
      create_library_checker_files(m)
      create_library_site_files(m)
      create_library_toplevel_files(m)
      create_mvc_generators(m)
      create_test_files(m)
    end
  end

  def create_project_files(manifest)
    manifest.template "project/gemfile.rb.erb", "Gemfile"
    manifest.template "project/config.yml.erb", "config.yml"
    manifest.template "project/rakefile.rb.erb", "rakefile.rb"
  end

  def create_library_checker_files(manifest)
    manifest.template "library/page_load_checker.rb.erb", File.join("lib", name, "checkers", "page_load_checker.rb")
    manifest.template "library/post_errors_checker.rb.erb", File.join("lib", name, "checkers", "post_errors_checker.rb")
  end

  def create_library_site_files(manifest)
    manifest.template "library/base_controller.rb.erb", File.join("lib", name, "site", "base_controller.rb")
    manifest.template "library/search_controller.rb.erb", File.join("lib", name, "site", "search_controller.rb")
    manifest.template "library/base_view.rb.erb", File.join("lib", name, "site", "base_view.rb")
  end

  def create_library_toplevel_files(manifest)
    manifest.template "library/configuration.rb.erb", File.join("lib", name, "configuration.rb")
    manifest.template "library/workflows.rb.erb", File.join("lib", name, "workflows.rb")
    manifest.template "library/core_libraries.rb.erb", File.join("lib", name, "core_libraries.rb")
    manifest.template "library/loader.rb.erb", File.join("lib", name, "loader.rb")
    manifest.template "library/project_require_file.rb.erb", File.join("lib","#{name}.rb")
  end

  def create_mvc_generators(manifest)
    manifest.template "generators/generate.rb.erb", File.join("script","generate.rb")
    manifest.template "generators/mvc_generator.rb.erb", File.join("generators","mvc","mvc_generator.rb")
    manifest.template "generators/rbeautify.rb.erb", File.join("generators", "mvc", "rbeautify.rb")
    manifest.template "generators/controller.rb.erb", File.join("generators","mvc","templates","controller.rb.erb")
    manifest.template "generators/model.rb.erb", File.join("generators","mvc","templates","model.rb.erb")
    manifest.template "generators/view.rb.erb", File.join("generators","mvc","templates","view.rb.erb")
    manifest.template "generators/workflow_loader.rb.erb", File.join("generators","mvc","templates","workflow_loader.rb.erb")
  end

  def create_test_files(manifest)
    manifest.template "features/model_steps.rb.erb", File.join("features","step_definitions","model_steps.rb")
    manifest.template "features/post_error_steps.rb.erb", File.join("features","step_definitions","post_error_steps.rb")
    manifest.template "features/site_steps.rb.erb", File.join("features","step_definitions","site_steps.rb")
    manifest.template "features/env.rb.erb", File.join("features","support","env.rb")
    manifest.template "features/sample.feature.erb", File.join("features","#{@name}_home.feature")
  end

  def create_directories(m)
    BASEDIRS.each { |path| m.directory path }
    create_subdirectories m, File.join('features'), %w(step_definitions support)
    create_subdirectories m, File.join('lib', @name), %w(checkers site workflows)
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