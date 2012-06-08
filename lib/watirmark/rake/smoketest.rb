module SmokeTest

  class << self
    def rspec_task(task_name, files, tag=:smoke)
      RSpec::Core::RakeTask.new(task_name) do |spec|
        spec.rspec_opts = "--tag #{tag} -fd -fh --out spec/reports/#{spec.name}.html --backtrace"
        spec.pattern = files
      end
    end

    def cucumber_task(task_name, files=nil, tag=:smoke)
       Cucumber::Rake::Task.new(task_name) do |t|
         t.cucumber_opts = "--tags @#{tag} -r features #{FileList[files]}"
       end
    end
  end

  class Runner
    include ::Rake::DSL if defined?(::Rake::DSL)

    def initialize(tests)
      @task_name = :smoke

      desc "Smoke Test"
      task @task_name do
        # when using Hash, tasks may run in parallel. a new multitask
        # named group_name is created, which runs dependencies group_tasks
        # in parallel. Tasks in group_tasks must be defined beforehand
        if tests.kind_of? Hash
          tests.each do |group_name, group_tasks|
            multitask group_name => group_tasks
            Rake::MultiTask[group_name].invoke
          end
        elsif tests.kind_of? Array
          # when using an Array, tasks are run sequentially. These tasks
          # should already be defined beforehand
          tests.each do |t|
            Rake::Task[t].invoke
          end
        else
          # currently, only Hash and Array task lists are supported
          raise "tests must be either Hash or Array"
        end
      end
    end
  end

end