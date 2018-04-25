require "yard"
require "rspec/core/rake_task"

RSpec::Core::RakeTask.new(:spec)

YARD::Rake::YardocTask.new do |t|
  t.files   = ['**/*.rb']
end

task default: :spec
