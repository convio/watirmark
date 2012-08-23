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
         t.cucumber_opts = "--tags @#{tag} -r features #{FileList[files]} -b --format html -o reports/report.html --format pretty"
       end
    end
  end
end