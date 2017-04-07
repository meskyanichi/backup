require File.expand_path("../../../spec_helper", __FILE__)

module Backup
  describe "Database::MySQL" do
    describe "All Databases" do
      specify "All tables" do
        create_model :my_backup, <<-EOS
          Backup::Model.new(:my_backup, "a description") do
            database MySQL do |db|
              db.name     = :all
              db.username = "root"
              db.host     = "mysql"
              db.port     = 3306
              db.additional_options = "--events"
            end
            store_with Local
          end
        EOS

        job = backup_perform :my_backup

        expect(job.package.exist?).to be_true
        expect(job.package).to match_manifest(<<-EOS)
           3180866 my_backup/databases/MySQL.sql
        EOS
      end

      specify "Tables Excluded" do
        # This warning will occur if --events is not used.
        create_config <<-EOS
          Backup::Logger.configure do
            ignore_warning "Warning: Skipping the data of table mysql.event"
          end
        EOS
        create_model :my_backup, <<-EOS
          Backup::Model.new(:my_backup, "a description") do
            database MySQL do |db|
              db.name         = :all
              db.username     = "root"
              db.host         = "mysql"
              db.port         = 3306
              db.skip_tables  = ["backup_test_01.twos", "backup_test_02.threes"]
            end
            store_with Local
          end
        EOS

        job = backup_perform :my_backup

        expect(job.package.exist?).to be_true
        expect(job.package).to match_manifest(<<-EOS)
          3173439 my_backup/databases/MySQL.sql
        EOS
      end
    end # describe "All Databases"

    describe "Single Database" do
      specify "All tables" do
        create_model :my_backup, <<-EOS
          Backup::Model.new(:my_backup, "a description") do
            database MySQL do |db|
              db.name     = "backup_test_01"
              db.username = "root"
              db.host     = "mysql"
              db.port     = 3306
            end
            store_with Local
          end
        EOS

        job = backup_perform :my_backup

        expect(job.package.exist?).to be_true
        expect(job.package).to match_manifest(<<-EOS)
          10451 my_backup/databases/MySQL.sql
        EOS
      end

      specify "Only one table" do
        create_model :my_backup, <<-EOS
          Backup::Model.new(:my_backup, "a description") do
            database MySQL do |db|
              db.name         = "backup_test_01"
              db.username     = "root"
              db.host         = "mysql"
              db.port         = 3306
              db.only_tables  = ["ones"]
            end
            store_with Local
          end
        EOS

        job = backup_perform :my_backup

        expect(job.package.exist?).to be_true
        expect(job.package).to match_manifest(<<-EOS)
          2677 my_backup/databases/MySQL.sql
        EOS
      end

      specify "Exclude a table" do
        create_model :my_backup, <<-EOS
          Backup::Model.new(:my_backup, "a description") do
            database MySQL do |db|
              db.name         = "backup_test_01"
              db.username     = "root"
              db.host         = "mysql"
              db.port         = 3306
              db.skip_tables  = ["ones"]
            end
            store_with Local
          end
        EOS

        job = backup_perform :my_backup

        expect(job.package.exist?).to be_true
        expect(job.package).to match_manifest(<<-EOS)
          9036 my_backup/databases/MySQL.sql
        EOS
      end
    end # describe "Single Database"

    describe "Multiple Dumps" do
      specify "All tables" do
        create_model :my_backup, <<-EOS
          Backup::Model.new(:my_backup, "a description") do
            database MySQL, :dump_01 do |db|
              db.name     = "backup_test_01"
              db.username = "root"
              db.host     = "mysql"
              db.port     = 3306
            end
            database MySQL, "Dump #2" do |db|
              db.name     = "backup_test_02"
              db.username = "root"
              db.host     = "mysql"
              db.port     = 3306
            end
            store_with Local
          end
        EOS

        job = backup_perform :my_backup

        expect(job.package.exist?).to be_true
        expect(job.package).to match_manifest(<<-EOS)
          10451 my_backup/databases/MySQL-dump_01.sql
          11201 my_backup/databases/MySQL-Dump__2.sql
        EOS
      end
    end # describe "Multiple Dumps"
  end
end
