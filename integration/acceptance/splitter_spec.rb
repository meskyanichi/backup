# encoding: utf-8

require File.expand_path("../../spec_helper", __FILE__)

module Backup
  describe Splitter do
    specify "suffix length may be configured" do
      create_model :my_backup, <<-EOS
        Backup::Model.new(:my_backup, "a description") do
          split_into_chunks_of 1, 5

          archive :my_archive do |archive|
            archive.add "./tmp/test_data"
          end

          store_with Local
        end
      EOS

      job = backup_perform :my_backup

      expect(job.package.exist?).to be_true
      expect(job.package.files.count).to be(11)
      expect(job.package.files.first).to end_with("-aaaaa")
      expect(job.package).to match_manifest(
        "- my_backup/archives/my_archive.tar"
      )
    end
  end
end
