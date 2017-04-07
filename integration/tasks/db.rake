namespace :db do
  desc "Create all databases"
  task create: ["db:mysql", "db:postgresql"]
end
