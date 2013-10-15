require 'thor/group'

class CreateProjectGenerator < Thor::Group
  include Thor::Actions

  argument :name

  def self.source_root
    File.expand_path(File.join(File.dirname(__FILE__), 'templates'))
  end

  def root
    template "gemfile.rb.erb", "#{name}/Gemfile"
    template "config.yml.erb", "#{name}/config.yml"
    template "rakefile.rb.erb", "#{name}/rakefile.rb"
  end

  def lib
    template "lib/configuration.rb.erb", File.join(name, "lib", name, "configuration.rb")
    template "lib/workflows.rb.erb", File.join(name, "lib", name, "workflows.rb")
    template "lib/core_libraries.rb.erb", File.join(name, "lib", name, "core_libraries.rb")
    template "lib/loader.rb.erb", File.join(name, "lib", name, "loader.rb")
    template "lib/name.rb.erb", File.join(name, "lib", "#{name}.rb")
  end

  def lib_checkers
    template "lib/name/checkers/page_load_checker.rb.erb", File.join(name, "lib", name, "checkers", "page_load_checker.rb")
    template "lib/name/checkers/post_errors_checker.rb.erb", File.join(name, "lib", name, "checkers", "post_errors_checker.rb")
  end

  def lib_site
    template "lib/name/site/base_controller.rb.erb", File.join(name, "lib", name, "site", "base_controller.rb")
    template "lib/name/site/search_controller.rb.erb", File.join(name, "lib", name, "site", "search_controller.rb")
    template "lib/name/site/base_view.rb.erb", File.join(name, "lib", name, "site", "base_view.rb")
  end

  def features
    template "features/model_steps.rb.erb", File.join(name, "features", "step_definitions", "model_steps.rb")
    template "features/post_error_steps.rb.erb", File.join(name, "features", "step_definitions", "post_error_steps.rb")
    template "features/site_steps.rb.erb", File.join(name, "features", "step_definitions", "site_steps.rb")
    template "features/env.rb.erb", File.join(name, "features", "support", "env.rb")
    template "features/sample.feature.erb", File.join(name, "features", "#{name}_home.feature")
  end

  def script
    template "script/generate.rb.erb", File.join(name, "script", "generate.rb"), :chmod => 0755
  end

  def generators_mvc
    template "generators/mvc/mvc_generator.rb.erb", File.join(name, "generators", "mvc", "mvc_generator.rb")
    template "generators/mvc/rbeautify.rb.erb", File.join(name, "generators", "mvc", "rbeautify.rb")
    template "generators/mvc/controller.rb.erb", File.join(name, "generators", "mvc", "templates", "controller.rb.erb")
    template "generators/mvc/model.rb.erb", File.join(name, "generators", "mvc", "templates", "model.rb.erb")
    template "generators/mvc/view.rb.erb", File.join(name, "generators", "mvc", "templates", "view.rb.erb")
    template "generators/mvc/workflow_loader.rb.erb", File.join(name, "generators", "mvc", "templates", "workflow_loader.rb.erb")
  end
end
