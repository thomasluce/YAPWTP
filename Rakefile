require 'spec/rake/spectask'

task :default => :spec

desc "Run all specs in spec directory"
ENV['LD_LIBRARY_PATH'] += ':.'
Spec::Rake::SpecTask.new(:spec) do |t|
  t.spec_files = FileList['spec/**/*_spec.rb']
end
