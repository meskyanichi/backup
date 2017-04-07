# encoding: utf-8

require File.expand_path("../../spec_helper", __FILE__)

describe "Backup Configuration" do
  specify "Models may be preconfigured" do
    create_config <<-EOS
      preconfigure "MyModel" do
        archive :archive_a do |archive|
          archive.add "./tmp/test_data/dir_a"
        end
        compress_with Gzip
      end
    EOS

    create_model :my_backup, <<-EOS
      MyModel.new(:my_backup, "a description") do
        archive :archive_b do |archive|
          archive.add "./tmp/test_data/dir_a"
        end
        store_with Local
      end
    EOS

    job = backup_perform :my_backup

    expect(job.package.exist?).to be_true
    expect(job.package).to match_manifest(<<-EOS)
      - my_backup/archives/archive_a.tar.gz
      - my_backup/archives/archive_b.tar.gz
    EOS
  end

  specify "Command line path options may be set in config.rb" do
    alt_config_path = BackupSpec::ALT_CONFIG_PATH
    config_file = File.join(alt_config_path, "my_config.rb")

    create_config <<-EOS, config_file
      root_path BackupSpec::ALT_CONFIG_PATH
      tmp_path "my_tmp"
    EOS

    create_model :my_backup, <<-EOS, config_file
      Model.new(:my_backup, "a description") do
        archive :my_archive do |archive|
          archive.add "./tmp/test_data/dir_a"
        end
        store_with Local
      end
    EOS

    # path to config.rb and models is set on the command line
    job = backup_perform :my_backup, "--config-file", config_file

    expect(job.package.exist?).to be_true
    expect(job.package).to match_manifest(<<-EOS)
      - my_backup/archives/my_archive.tar
    EOS

    # without setting root_path in config.rb,
    # these would still be based on the default root_path (~/Backup)
    expect(Backup::Config.tmp_path).to eq(
      File.join(alt_config_path, "my_tmp")
    )
    expect(Backup::Config.data_path).to eq(
      File.join(alt_config_path, Backup::Config::DEFAULTS[:data_path])
    )
  end
end
