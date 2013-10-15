require 'thor/group'

class CreateProjectGenerator < Thor::Group
  include Thor::Actions

  argument :name

  def self.source_root
    File.expand_path(File.join(File.dirname(__FILE__), 'templates'))
  end

  def create_project_files
    template "project/gemfile.rb.erb", "#{name}/Gemfile"
    template "project/config.yml.erb", "#{name}/config.yml"
    template "project/rakefile.rb.erb", "#{name}/rakefile.rb"
  end


  def create_library_checker_files
    template "library/page_load_checker.rb.erb", File.join(name, "lib", name, "checkers", "page_load_checker.rb")
    template "library/post_errors_checker.rb.erb", File.join(name, "lib", name, "checkers", "post_errors_checker.rb")
  end

  def create_library_site_files
    template "library/base_controller.rb.erb", File.join(name, "lib", name, "site", "base_controller.rb")
    template "library/search_controller.rb.erb", File.join(name, "lib", name, "site", "search_controller.rb")
    template "library/base_view.rb.erb", File.join(name, "lib", name, "site", "base_view.rb")
  end

  def create_library_toplevel_files
    template "library/configuration.rb.erb", File.join(name, "lib", name, "configuration.rb")
    template "library/workflows.rb.erb", File.join(name, "lib", name, "workflows.rb")
    template "library/core_libraries.rb.erb", File.join(name, "lib", name, "core_libraries.rb")
    template "library/loader.rb.erb", File.join(name, "lib", name, "loader.rb")
    template "library/project_require_file.rb.erb", File.join(name, "lib", "#{name}.rb")
  end

  def create_mvc_generators
    template "generators/generate.rb.erb", File.join(name, "script", "generate.rb"), :chmod => 0755
    template "generators/mvc_generator.rb.erb", File.join(name, "generators", "mvc", "mvc_generator.rb")
    template "generators/rbeautify.rb.erb", File.join(name, "generators", "mvc", "rbeautify.rb")
    template "generators/controller.rb.erb", File.join(name, "generators", "mvc", "templates", "controller.rb.erb")
    template "generators/model.rb.erb", File.join(name, "generators", "mvc", "templates", "model.rb.erb")
    template "generators/view.rb.erb", File.join(name, "generators", "mvc", "templates", "view.rb.erb")
    template "generators/workflow_loader.rb.erb", File.join(name, "generators", "mvc", "templates", "workflow_loader.rb.erb")
  end

  def create_test_files
    template "features/model_steps.rb.erb", File.join(name, "features", "step_definitions", "model_steps.rb")
    template "features/post_error_steps.rb.erb", File.join(name, "features", "step_definitions", "post_error_steps.rb")
    template "features/site_steps.rb.erb", File.join(name, "features", "step_definitions", "site_steps.rb")
    template "features/env.rb.erb", File.join(name, "features", "support", "env.rb")
    template "features/sample.feature.erb", File.join(name, "features", "#{name}_home.feature")
  end

end
