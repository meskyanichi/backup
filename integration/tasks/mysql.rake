require "active_record"

namespace :db do
  desc "Rebuild MySQL test databases"
  task :mysql do
    begin
      puts "\n=> Preparing MySQL..."
      MySQLTask.drop_all
      MySQLTask.create_all
    rescue => err
      errno = " (Error ##{err.errno})" if err.respond_to?(:errno)
      $stderr.puts "#{err.class}#{errno}): #{err.message}"
      $stderr.puts err.backtrace
    end
  end
end

module MySQLTask
  extend ActiveSupport::Inflector

  class << self
    DATABASES = {
      backup_test_01: { # db_name
        ones: 100,      # table_name, record_count
        twos: 200,
        threes: 400
      },
      backup_test_02: {
        ones: 125,
        twos: 225,
        threes: 425
      }
    }.freeze
    CONFIG = {
      adapter:  "mysql2",
      host:     "mysql"
    }.freeze
    OPTS = { charset: "utf8", collation: "utf8_unicode_ci" }.freeze

    def drop_all
      puts "Dropping databases..."
      connection = connect_to(nil)
      DATABASES.each_key do |db_name|
        connection.drop_database db_name
      end
    end

    def create_all
      connection = connect_to(nil)
      DATABASES.each do |db_name, tables|
        puts "Creating Database #{db_name}..."
        connection.create_database db_name, OPTS
        connection = connect_to(db_name)
        tables.each do |table_name, record_count|
          ActiveRecord::Schema.define do
            create_table table_name do |t|
              t.integer :number
            end
          end

          name = classify(table_name)
          klass = if const_defined?(name)
                    const_get(name)
                  else
                    const_set(name, Class.new(ActiveRecord::Base))
                  end
          record_count.times do |n|
            klass.create(number: n)
          end
        end
      end
    end

    private

    def connect_to(db_name)
      name = db_name.to_s if db_name
      ActiveRecord::Base.establish_connection CONFIG.merge(database: name)
      ActiveRecord::Base.connection
    end
  end
end
