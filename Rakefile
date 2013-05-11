require 'rspec/core/rake_task'
RSpec::Core::RakeTask.new(:units) do |spec|
  spec.pattern = "spec/lib/**/*_spec.rb"
end
RSpec::Core::RakeTask.new(:sanity) do |spec|
  spec.pattern = "spec/sanity/**/*_spec.rb"
end
task default: [:units, :sanity]
