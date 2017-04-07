# encoding: utf-8

require File.expand_path("../../../../spec_helper", __FILE__)

module Backup
  describe Syncer::RSync::Local do
    specify "single directory" do
      create_model :my_backup, <<-EOS
        Backup::Model.new(:my_backup, 'a description') do
          sync_with RSync::Local do |rsync|
            rsync.path = "./tmp/Storage"
            rsync.directories do |dirs|
              dirs.add "./tmp/test_data"
            end
          end
        end
      EOS

      backup_perform :my_backup

      expect(dir_contents("./tmp/Storage/test_data"))
        .to eq(dir_contents("./tmp/test_data"))
    end

    specify "multiple directories" do
      create_model :my_backup, <<-EOS
        Backup::Model.new(:my_backup, 'a description') do
          sync_with RSync::Local do |rsync|
            rsync.path = "./tmp/Storage"
            rsync.directories do |dirs|
              dirs.add "./tmp/test_data/dir_a"
              dirs.add "./tmp/test_data/dir_b"
              dirs.add "./tmp/test_data/dir_c"
            end
          end
        end
      EOS

      backup_perform :my_backup

      expect(dir_contents("./tmp/Storage/dir_a"))
        .to eq(dir_contents("./tmp/test_data/dir_a"))
      expect(dir_contents("./tmp/Storage/dir_b"))
        .to eq(dir_contents("./tmp/test_data/dir_b"))
      expect(dir_contents("./tmp/Storage/dir_c"))
        .to eq(dir_contents("./tmp/test_data/dir_c"))
    end

    specify "multiple directories with excludes" do
      create_model :my_backup, <<-EOS
        Backup::Model.new(:my_backup, "a description") do
          sync_with RSync::Local do |rsync|
            rsync.path = "./tmp/Storage"
            rsync.directories do |dirs|
              dirs.add "./tmp/test_data/dir_a"
              dirs.add "./tmp/test_data/dir_b"
              dirs.add "./tmp/test_data/dir_c"
              dirs.exclude "2.txt"
            end
          end
        end
      EOS

      backup_perform :my_backup

      expect(dir_contents("./tmp/Storage/dir_a")).to eq(
        dir_contents("./tmp/test_data/dir_a") - ["/2.txt"]
      )
      expect(dir_contents("./tmp/Storage/dir_b")).to eq(
        dir_contents("./tmp/test_data/dir_b") - ["/2.txt"]
      )
      expect(dir_contents("./tmp/Storage/dir_c")).to eq(
        dir_contents("./tmp/test_data/dir_c") - ["/2.txt"]
      )
    end
  end
end
