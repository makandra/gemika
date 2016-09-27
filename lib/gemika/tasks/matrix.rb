require 'gemika/matrix'

namespace :matrix do

  desc "Run specs for all Ruby #{RUBY_VERSION} gemfiles"
  task :spec do
    Gemika::Matrix.from_travis_yml.each do |row|
      # system("bundle exec #{Gemika::Env.rspec_binary} spec")
      rspec_binary = Gemika::Env.rspec_binary_for_gemfile(row.gemfile)
      system("bundle exec #{rspec_binary} --color spec")
    end
  end

  desc "Install all Ruby #{RUBY_VERSION} gemfiles"
  task :install do
    Gemika::Matrix.from_travis_yml.each do |row|
      system('bundle install')
    end
  end

  desc "Update all Ruby #{RUBY_VERSION} gemfiles"
  task :update, :gems do |t, args|
    Gemika::Matrix.from_travis_yml.each do |row|
      system("bundle update #{args[:gems]}")
    end
  end

end
