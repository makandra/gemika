require 'gemika/matrix'

namespace :matrix do

  desc "Run specs for all Ruby #{RUBY_VERSION} gemfiles"
  task :spec do
    Gemika::Matrix.from_travis_yml.each do
      system("bundle exec rspec spec")
    end
  end

  desc "Install all Ruby #{RUBY_VERSION} gemfiles"
  task :install do
    Gemika::Matrix.from_travis_yml.each do
      system('bundle install')
    end
  end

  desc "Update all Ruby #{RUBY_VERSION} gemfiles"
  task :update, :gems do |t, args|
    Gemika::Matrix.from_travis_yml.each do
      system("bundle update #{args[:gems]}")
    end
  end

end
