require 'gemika/env'
require 'gemika/matrix'

##
# Rake tasks to run commands for each compatible row in the test matrix.
#
namespace :gemika do

  desc "Generate a github action workflow from a .travis.yml"
  task :generate_github_actions_workflow do
    puts Gemika::Matrix.generate_github_actions_workflow.to_yaml
  end

end
