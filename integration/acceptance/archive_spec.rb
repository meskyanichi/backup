# encoding: utf-8

require File.expand_path("../../spec_helper", __FILE__)

module Backup
  describe Archive do
    shared_examples "GNU or BSD tar" do
      specify "All directories, no compression, with/without :root" do
        create_model :my_backup, <<-EOS
          Backup::Model.new(:my_backup, "a description") do
            archive :archive_a do |archive|
              archive.add "./tmp/test_data"
            end

            archive :archive_b do |archive|
              archive.root "./tmp"
              archive.add "test_data"
            end

            store_with Local
          end
        EOS

        job = backup_perform :my_backup

        expect(job.package.exist?).to be_true

        expect(job.package).to match_manifest(<<-EOS)
            10_496_000 my_backup/archives/archive_a.tar
            10_496_000 my_backup/archives/archive_b.tar
          EOS

        # without :root option
        package_a = job.package["my_backup/archives/archive_a.tar"]
        expect(package_a).to match_manifest(<<-EOS)
          1_048_576 /usr/src/backup/tmp/test_data/dir_a/1.txt
          1_048_576 /usr/src/backup/tmp/test_data/dir_a/2.txt
          1_048_576 /usr/src/backup/tmp/test_data/dir_a/3.txt

          1_048_576 /usr/src/backup/tmp/test_data/dir_b/1.txt
          1_048_576 /usr/src/backup/tmp/test_data/dir_b/2.txt
          1_048_576 /usr/src/backup/tmp/test_data/dir_b/3.txt

          1_048_576 /usr/src/backup/tmp/test_data/dir_c/1.txt
          1_048_576 /usr/src/backup/tmp/test_data/dir_c/2.txt
          1_048_576 /usr/src/backup/tmp/test_data/dir_c/3.txt

          1_048_576 /usr/src/backup/tmp/test_data/dir_d/1.txt
        EOS

        # with :root option
        package_b = job.package["my_backup/archives/archive_b.tar"]
        expect(package_b).to match_manifest(<<-EOS)
            1_048_576 test_data/dir_a/1.txt
            1_048_576 test_data/dir_a/2.txt
            1_048_576 test_data/dir_a/3.txt

            1_048_576 test_data/dir_b/1.txt
            1_048_576 test_data/dir_b/2.txt
            1_048_576 test_data/dir_b/3.txt

            1_048_576 test_data/dir_c/1.txt
            1_048_576 test_data/dir_c/2.txt
            1_048_576 test_data/dir_c/3.txt

            1_048_576 test_data/dir_d/1.txt
          EOS
      end

      specify "Specific directories, with compression, with/without :root" do
        create_model :my_backup, <<-EOS
          Backup::Model.new(:my_backup, "a description") do
            archive :archive_a do |archive|
              archive.add "./tmp/test_data/dir_a/"
              archive.add "./tmp/test_data/dir_b"
            end

            archive :archive_b do |archive|
              archive.root "./tmp/test_data"
              archive.add "dir_a/"
              archive.add "dir_b"
            end

            compress_with Gzip

            store_with Local
          end
        EOS

        job = backup_perform :my_backup

        expect(job.package.exist?).to be_true
        expect(job.package).to match_manifest(<<-EOS)
          - my_backup/archives/archive_a.tar.gz
          - my_backup/archives/archive_b.tar.gz
        EOS

        # without :root option
        package_a = job.package["my_backup/archives/archive_a.tar.gz"]
        expect(package_a).to match_manifest(<<-EOS)
          1_048_576 /usr/src/backup/tmp/test_data/dir_a/1.txt
          1_048_576 /usr/src/backup/tmp/test_data/dir_a/2.txt
          1_048_576 /usr/src/backup/tmp/test_data/dir_a/3.txt

          1_048_576 /usr/src/backup/tmp/test_data/dir_b/1.txt
          1_048_576 /usr/src/backup/tmp/test_data/dir_b/2.txt
          1_048_576 /usr/src/backup/tmp/test_data/dir_b/3.txt
        EOS

        # with :root option
        package_b = job.package["my_backup/archives/archive_b.tar.gz"]
        expect(package_b).to match_manifest(<<-EOS)
          1_048_576 dir_a/1.txt
          1_048_576 dir_a/2.txt
          1_048_576 dir_a/3.txt

          1_048_576 dir_b/1.txt
          1_048_576 dir_b/2.txt
          1_048_576 dir_b/3.txt
        EOS
      end

      specify "Excluded directories, with compression, with/without :root" do
        create_model :my_backup, <<-EOS
          Backup::Model.new(:my_backup, "a description") do
            archive :archive_a do |archive|
              archive.add "./tmp/test_data"
              archive.exclude "./tmp/test_data/dir_a/"
              archive.exclude "./tmp/test_data/dir_d"
            end

            archive :archive_b do |archive|
              archive.root "./tmp"
              archive.add "test_data"
              archive.exclude "test_data/dir_a/*"
              archive.exclude "test_data/dir_d"
            end

            compress_with Gzip

            store_with Local
          end
        EOS

        job = backup_perform :my_backup

        expect(job.package.exist?).to be_true
        expect(job.package).to match_manifest(
          <<-EOS
            - my_backup/archives/archive_a.tar.gz
            - my_backup/archives/archive_b.tar.gz
          EOS
        )

        # without :root option
        package_a = job.package["my_backup/archives/archive_a.tar.gz"]
        expect(package_a).to match_manifest(<<-EOS)
          1_048_576 /usr/src/backup/tmp/test_data/dir_b/1.txt
          1_048_576 /usr/src/backup/tmp/test_data/dir_b/2.txt
          1_048_576 /usr/src/backup/tmp/test_data/dir_b/3.txt

          1_048_576 /usr/src/backup/tmp/test_data/dir_c/1.txt
          1_048_576 /usr/src/backup/tmp/test_data/dir_c/2.txt
          1_048_576 /usr/src/backup/tmp/test_data/dir_c/3.txt
        EOS

        # with :root option
        package_b = job.package["my_backup/archives/archive_b.tar.gz"]
        expect(package_b).to match_manifest(<<-EOS)
          1_048_576 test_data/dir_b/1.txt
          1_048_576 test_data/dir_b/2.txt
          1_048_576 test_data/dir_b/3.txt

          1_048_576 test_data/dir_c/1.txt
          1_048_576 test_data/dir_c/2.txt
          1_048_576 test_data/dir_c/3.txt
        EOS
      end

      specify "Using Splitter" do
        create_model :my_backup, <<-EOS
          Backup::Model.new(:my_backup, "a description") do
            split_into_chunks_of 1 # 1MB

            archive :my_archive do |archive|
              archive.add "./tmp/test_data"
            end

            store_with Local
          end
        EOS

        job = backup_perform :my_backup

        expect(job.package.files.count).to be(11)

        expect(job.package).to match_manifest(
          "10_496_000 my_backup/archives/my_archive.tar"
        )

        expect(
          job.package["my_backup/archives/my_archive.tar"]
        ).to match_manifest(<<-EOS)
          1_048_576 /usr/src/backup/tmp/test_data/dir_a/1.txt
          1_048_576 /usr/src/backup/tmp/test_data/dir_a/2.txt
          1_048_576 /usr/src/backup/tmp/test_data/dir_a/3.txt

          1_048_576 /usr/src/backup/tmp/test_data/dir_b/1.txt
          1_048_576 /usr/src/backup/tmp/test_data/dir_b/2.txt
          1_048_576 /usr/src/backup/tmp/test_data/dir_b/3.txt

          1_048_576 /usr/src/backup/tmp/test_data/dir_c/1.txt
          1_048_576 /usr/src/backup/tmp/test_data/dir_c/2.txt
          1_048_576 /usr/src/backup/tmp/test_data/dir_c/3.txt

          1_048_576 /usr/src/backup/tmp/test_data/dir_d/1.txt
        EOS
      end

      specify "Using sudo" do
        create_model :my_backup, <<-EOS
          Backup::Model.new(:my_backup, "a description") do
            archive :my_archive do |archive|
              archive.use_sudo
              archive.add "./tmp/test_data/dir_a"
            end

            store_with Local
          end
        EOS

        job = backup_perform :my_backup

        expect(job.package.exist?).to be_true
        expect(job.package).to match_manifest(
          "- my_backup/archives/my_archive.tar"
        )

        expect(
          job.package["my_backup/archives/my_archive.tar"]
        ).to match_manifest(<<-EOS)
          1_048_576 /usr/src/backup/tmp/test_data/dir_a/1.txt
          1_048_576 /usr/src/backup/tmp/test_data/dir_a/2.txt
          1_048_576 /usr/src/backup/tmp/test_data/dir_a/3.txt
        EOS
      end
    end # shared_examples "GNU or BSD tar"

    describe "Using GNU tar" do
      # GNU tar is set as the default
      it_behaves_like "GNU or BSD tar"

      it "detects GNU tar" do
        create_config <<-EOS
          Backup::Utilities.configure do
            tar "/bin/tar"
            tar_dist nil
          end
        EOS

        create_model :my_backup, <<-EOS
          Backup::Model.new(:my_backup, "a description") do
            archive :my_archive do |archive|
              archive.add "tmp/test_data/dir_a"
            end
          end
        EOS

        job = backup_perform :my_backup

        log_messages = job.logger.messages.map(&:lines).flatten.join
        expect(log_messages).to match(/STDOUT: tar \(GNU tar\)/)
        expect(Utilities.send(:utility, :tar)).to eq("/bin/tar")
        expect(Utilities.send(:gnu_tar?)).to be(true)
      end
    end

    describe "Using BSD tar" do
      before do
        # tar_dist must be set, since the default config.rb
        # will set this to :gnu to suppress the detection messages.
        create_config <<-EOS
          Backup::Utilities.configure do
            tar "/usr/bin/bsdtar"
            tar_dist :bsd
          end
        EOS
      end

      it_behaves_like "GNU or BSD tar"

      it "detects BSD tar" do
        create_config <<-EOS
          Backup::Utilities.configure do
            tar "/usr/bin/bsdtar"
            tar_dist nil
          end
        EOS

        create_model :my_backup, <<-EOS
          Backup::Model.new(:my_backup, "a description") do
            archive :my_archive do |archive|
              archive.add "./tmp/test_data/dir_a"
            end
          end
        EOS

        job = backup_perform :my_backup

        log_messages = job.logger.messages.map(&:lines).flatten.join
        expect(log_messages).to match(/STDOUT: bsdtar/)
        expect(Utilities.send(:utility, :tar)).to eq("/usr/bin/bsdtar")
        expect(Utilities.send(:gnu_tar?)).to be(false)
      end
    end
  end
end
