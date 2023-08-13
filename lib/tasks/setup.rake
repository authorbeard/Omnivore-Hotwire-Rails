
namespace :setup do
  desc 'Grab all trucks from SF API for initial load'
  task seed_trucks: :environment do
    TruckImporter.perform
  end

  desc 'Set up the whole app'
  task complete: :environment do
    system("bundle install")
    system("bundle exec rake db:setup")
    Rake::Task['setup:seed_trucks'].invoke
  end
end
