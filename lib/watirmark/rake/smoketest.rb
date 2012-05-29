class SmokeTestTask
  include ::Rake::DSL if defined?(::Rake::DSL)
  def initialize(task_name=:smoke, tests)
    raise "tests must be Hash" unless Hash === tests

    @task_name = task_name

    desc "Smoke Test"
    task @task_name do
      tests.each do |group_name, group_tasks|
        multitask group_name => group_tasks
        Rake::MultiTask[group_name].invoke
      end
    end
  end
end

