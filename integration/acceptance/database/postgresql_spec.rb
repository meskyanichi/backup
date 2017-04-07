require File.expand_path("../../../spec_helper", __FILE__)

module Backup
  describe "Database::PostgreSQL" do
    describe "All Databases" do
      specify "With compression" do
        create_model :my_backup, <<-EOS
          Backup::Model.new(:my_backup, "a description") do
            database PostgreSQL do |db|
              db.host = "postgres"
              db.name = :all
              db.username = "postgres"
            end
            compress_with Gzip
            store_with Local
          end
        EOS

        job = backup_perform :my_backup

        expect(job.package.exist?).to be_true
        expect(job.package).to match_manifest(<<-EOS)
          3200..3400 my_backup/databases/PostgreSQL.sql.gz
        EOS
      end

      specify "Without compression" do
        create_model :my_backup, <<-EOS
          Backup::Model.new(:my_backup, "a description") do
            database PostgreSQL do |db|
              db.host = "postgres"
              db.name = :all
              db.username = "postgres"
            end
            store_with Local
          end
        EOS

        job = backup_perform :my_backup

        expect(job.package.exist?).to be_true
        expect(job.package).to match_manifest(<<-EOS)
          23300..23499 my_backup/databases/PostgreSQL.sql
        EOS
      end
    end

    describe "Single Database" do
      specify "All tables" do
        create_model :my_backup, <<-EOS
          Backup::Model.new(:my_backup, "a description") do
            database PostgreSQL do |db|
              db.host = "postgres"
              db.name = "backup_test_01"
              db.username = "postgres"
            end
            store_with Local
          end
        EOS

        job = backup_perform :my_backup

        expect(job.package.exist?).to be_true
        expect(job.package).to match_manifest(<<-EOS)
          10000..10099 my_backup/databases/PostgreSQL.sql
        EOS
      end

      specify "Only one table" do
        create_model :my_backup, <<-EOS
          Backup::Model.new(:my_backup, "a description") do
            database PostgreSQL do |db|
              db.host = "postgres"
              db.name = "backup_test_01"
              db.username = "postgres"
              db.only_tables = ["ones"]
            end
            store_with Local
          end
        EOS

        job = backup_perform :my_backup

        expect(job.package.exist?).to be_true
        expect(job.package).to match_manifest(<<-EOS)
          2000..2099 my_backup/databases/PostgreSQL.sql
        EOS
      end

      specify "Exclude a table" do
        create_model :my_backup, <<-EOS
          Backup::Model.new(:my_backup, "a description") do
            database PostgreSQL do |db|
              db.host = "postgres"
              db.name = "backup_test_01"
              db.username = "postgres"
              db.skip_tables = ["ones"]
            end
            store_with Local
          end
        EOS

        job = backup_perform :my_backup

        expect(job.package.exist?).to be_true
        expect(job.package).to match_manifest(<<-EOS)
          8600..8699 my_backup/databases/PostgreSQL.sql
        EOS
      end
    end

    describe "Multiple Dumps" do
      specify "All tables" do
        create_model :my_backup, <<-EOS
          Backup::Model.new(:my_backup, "a description") do
            database PostgreSQL, :dump_01 do |db|
              db.host = "postgres"
              db.name = "backup_test_01"
              db.username = "postgres"
            end
            database PostgreSQL, "Dump #2" do |db|
              db.host = "postgres"
              db.name = "backup_test_02"
              db.username = "postgres"
            end
            store_with Local
          end
        EOS

        job = backup_perform :my_backup

        expect(job.package.exist?).to be_true
        expect(job.package).to match_manifest(<<-EOS)
          10600..10699 my_backup/databases/PostgreSQL-Dump__2.sql
          10000..10099 my_backup/databases/PostgreSQL-dump_01.sql
        EOS
      end
    end
  end
end
