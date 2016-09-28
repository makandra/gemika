require 'gemika/rspec'

# Private task to pick the correct RSpec binary for the currently activated
# RSpec version (`spec` in RSpec 1, `rspec` in RSpec 2+)
desc 'Run specs with the current RSpec version'
task :current_rspec, :files do |t, options|
  options = options.to_hash
  Gemika::RSpec.run_specs(options)
end
