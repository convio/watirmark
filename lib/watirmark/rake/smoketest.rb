module SmokeTest

  class << self
    def rspec_task(task_name, files, tag=:smoke)
      Dir.mkdir("reports") unless Dir.exists?("reports")
      RSpec::Core::RakeTask.new(task_name) do |spec|
        spec.rspec_opts = "--tag #{tag} --tag ~bug -fd -fh --out reports/#{spec.name}.html --backtrace"
        spec.pattern = files
      end
    end

    def cucumber_task(task_name, files=nil, tag=:smoke)
      Dir.mkdir("reports") unless Dir.exists?("reports")
      Cucumber::Rake::Task.new(task_name) do |t|
        t.cucumber_opts = "--tags @#{tag} --tags ~@bug -r features #{FileList[files]} -b --format html -o reports/report.html --format pretty"
      end
    end
  end
end