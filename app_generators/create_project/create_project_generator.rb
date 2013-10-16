require 'thor/group'
require 'active_support/inflector'

class CreateProjectGenerator < Thor::Group
  include Thor::Actions

  argument :name

  def self.source_root
    File.expand_path(File.join(File.dirname(__FILE__), 'templates'))
  end

  def root_files
    template "gemfile.rb.erb", "#{name}/Gemfile"
    template "config.yml.erb", "#{name}/config.yml"
    template "rakefile.rb.erb", "#{name}/rakefile.rb"
  end

  def lib_files
    template "lib/configuration.rb.erb", File.join(name, "lib", name, "configuration.rb")
    template "lib/workflows.rb.erb", File.join(name, "lib", name, "workflows.rb")
    template "lib/core_libraries.rb.erb", File.join(name, "lib", name, "core_libraries.rb")
    template "lib/loader.rb.erb", File.join(name, "lib", name, "loader.rb")
    template "lib/name.rb.erb", File.join(name, "lib", "#{name}.rb")
  end

  def lib_checkers_files
    template "lib/name/checkers/page_load_checker.rb.erb", File.join(name, "lib", name, "checkers", "page_load_checker.rb")
    template "lib/name/checkers/post_errors_checker.rb.erb", File.join(name, "lib", name, "checkers", "post_errors_checker.rb")
  end

  def lib_site_files
    template "lib/name/site/base_controller.rb.erb", File.join(name, "lib", name, "site", "base_controller.rb")
    template "lib/name/site/search_controller.rb.erb", File.join(name, "lib", name, "site", "search_controller.rb")
    template "lib/name/site/base_view.rb.erb", File.join(name, "lib", name, "site", "base_view.rb")
  end

  def features_files
    template "features/model_steps.rb.erb", File.join(name, "features", "step_definitions", "model_steps.rb")
    template "features/post_error_steps.rb.erb", File.join(name, "features", "step_definitions", "post_error_steps.rb")
    template "features/site_steps.rb.erb", File.join(name, "features", "step_definitions", "site_steps.rb")
    template "features/env.rb.erb", File.join(name, "features", "support", "env.rb")
    template "features/sample.feature.erb", File.join(name, "features", "#{name}_home.feature")
  end

  def script_files
    template "script/generate.rb.erb", File.join(name, "script", "generate.rb")
    chmod File.join(name, "script", "generate.rb"), 0755
  end

  def generators_mvc_files
    template "generators/mvc/generator.rb.erb", File.join(name, "generators", "mvc", "generator.rb")

    template "generators/mvc/templates/controller.rb.erb", File.join(name, "generators", "mvc", "templates", "controller.rb.erb")
    template "generators/mvc/templates/model.rb.erb", File.join(name, "generators", "mvc", "templates", "model.rb.erb")
    template "generators/mvc/templates/view.rb.erb", File.join(name, "generators", "mvc", "templates", "view.rb.erb")
  end
end
