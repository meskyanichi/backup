# encoding: utf-8

require "bundler/setup"
require "backup"

Dir[File.expand_path("../support/**/*.rb", __FILE__)].each { |f| require f }

require "rspec/autorun"
RSpec.configure do |config|
  config.treat_symbols_as_metadata_keys_with_true_values = true
  config.run_all_when_everything_filtered = true
  config.filter_run_excluding :live
  config.filter_run :focus

  config.include BackupSpec::ExampleHelpers

  config.before(:all) do
    fb = BackupSpec::FilesetBuilder.new
    test_dirs = { "dir_a" => 3, "dir_b" => 3, "dir_c" => 3, "dir_d" => 1 }
    test_dirs.each do |dir, total|
      fb.create(File.join("tmp", "test_data"), dir, total, 1)
    end
  end

  config.before(:each) do
    # Reset to default paths
    Backup::Config.send(:reset!)

    # Remove default and alt config paths if they exist.
    FileUtils.rm_rf File.dirname(Backup::Config.config_file)
    FileUtils.rm_rf BackupSpec::ALT_CONFIG_PATH

    # Remove the local storage path if it exists.
    FileUtils.rm_rf BackupSpec::LOCAL_STORAGE_PATH

    @argv_save = ARGV
  end

  # The last spec example to run will leave behind it"s files in the
  # LOCAL_STORAGE_PATH (if used) and it"s config.rb and model files
  # in either the default path (~/Backup) or the alt path (~/Backup_alt)
  # so these files may be inspected if needed.
  #
  # Adding `:focus` to spec examples will automatically enable the
  # Console Logger so you can see the log output as the job runs.

  config.after(:each) do
    ARGV.replace(@argv_save)
  end
end

puts "\nRuby version: #{RUBY_DESCRIPTION}\n\n"
