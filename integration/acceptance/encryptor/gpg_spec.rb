# encoding: utf-8

require File.expand_path("../../../spec_helper", __FILE__)

module Backup
  describe Encryptor::GPG do
    specify ":asymmetric mode with preloaded and imported keys" do
      create_model :my_backup, <<-EOS
        Backup::Model.new(:my_backup, 'a description') do
          archive :my_archive do |archive|
            archive.add "./tmp/test_data"
          end

          encrypt_with GPG do |encryptor|
            # encryptor.mode = :asymmetric (default mode)
            encryptor.gpg_homedir = BackupSpec::GPG_HOME_DIR

            encryptor.keys = {
              # backup03 public key (email as identifier)
              'backup03@foo.com' => BackupSpec::GPGKeys[:backup03][:public],
              # backup04 public key (long key id as identifier)
              '0F45932D3F24426D' => BackupSpec::GPGKeys[:backup04][:public]
            }

            encryptor.recipients = [
              # backup01 (short keyid)
              '16325C61',
              # backup02 (key fingerprint)
              'F9A9 9BD8 A570 182F F190  037C 7118 9938 6A6A 175A',
              # backup03 (email)
              'backup03@foo.com',
              # backup04 (long keyid)
              '0F45932D3F24426D'
            ]
          end

          store_with Local
        end
      EOS

      # Preload keys for :backup01 and :backup02.
      # The keys for :backup03 and :backup04 will be imported from #keys.
      import_public_keys_for :backup01, :backup02

      job = backup_perform :my_backup
      expect(job.package.exist?).to be_true
      expect(job.package.path.end_with?(".gpg")).to be_true

      expect(decrypt_with_user(:backup01, job.package.path)).to be_true
      expect(decrypt_with_user(:backup02, job.package.path)).to be_true
      expect(decrypt_with_user(:backup03, job.package.path)).to be_true
      expect(decrypt_with_user(:backup04, job.package.path)).to be_true
    end

    specify ":asymmetric mode with missing recipient key" do
      create_model :my_backup, <<-EOS
        Backup::Model.new(:my_backup, 'a description') do
          archive :my_archive do |archive|
            archive.add "./tmp/test_data"
          end

          encrypt_with GPG do |encryptor|
            encryptor.mode = :asymmetric
            encryptor.gpg_homedir = BackupSpec::GPG_HOME_DIR

            encryptor.keys = {
              'backup02@foo.com' => BackupSpec::GPGKeys[:backup02][:public],
            }

            encryptor.recipients = [
              'backup01@foo.com',   # preloaded in the system
              'backup02@foo.com',   # imported from #keys
              'backupfoo@foo.com'   # no public key available
            ]
          end

          store_with Local
        end
      EOS

      import_public_keys_for :backup01

      job = backup_perform :my_backup, exit_status: 1
      expect(job.package.exist?).to be_true
      expect(job.package.path.end_with?(".gpg")).to be_true

      expect(job.logger.has_warnings?).to be_true
      log_messages = job.logger.messages.map(&:lines).flatten.join
      expect(log_messages).to match(
        /No public key was found in #keys for '<backupfoo@foo.com>'/
      )

      expect(decrypt_with_user(:backup01, job.package.path)).to be_true
      expect(decrypt_with_user(:backup02, job.package.path)).to be_true
    end

    specify ":asymmetric mode with no recipient keys" do
      create_model :my_backup, <<-EOS
        Backup::Model.new(:my_backup, 'a description') do
          archive :my_archive do |archive|
            archive.add "./tmp/test_data"
          end

          encrypt_with GPG do |encryptor|
            encryptor.mode = :asymmetric
            encryptor.gpg_homedir = BackupSpec::GPG_HOME_DIR

            encryptor.recipients = [
              'backupfoo@foo.com',
              'backupfoo2@foo.com'
            ]
          end

          store_with Local
        end
      EOS

      import_public_keys_for :backup01

      job = backup_perform :my_backup, exit_status: 2
      expect(job.package.exist?).to be_false

      expect(job.logger.has_warnings?).to be_true
      log_messages = job.logger.messages.map(&:formatted_lines).flatten.join

      # issues warnings about the missing keys
      expect(log_messages).to match(
        /\[warn\] No public key was found in #keys for '<backupfoo@foo.com>'/
      )
      expect(log_messages).to match(
        /\[warn\] No public key was found in #keys for '<backupfoo2@foo.com>'/
      )

      # issues warning about not being able to perform asymmetric encryption
      expect(log_messages).to match(
        /\[warn\] No recipients available for asymmetric encryption/
      )

      # since there are no other options for encryption, the backup fails
      expect(log_messages).to match(
        /\[error\]\sEncryptor::GPG::Error:\s
         Encryption\scould\snot\sbe\sperformed\sfor\smode\s'asymmetric'/x
      )
    end

    specify ":symmetric mode" do
      create_model :my_backup, <<-EOS
        Backup::Model.new(:my_backup, 'a description') do
          archive :my_archive do |archive|
            archive.add "./tmp/test_data"
          end

          encrypt_with GPG do |encryptor|
            encryptor.mode = :symmetric
            encryptor.gpg_homedir = BackupSpec::GPG_HOME_DIR
            encryptor.passphrase = 'a secret'
          end

          store_with Local
        end
      EOS

      job = backup_perform :my_backup
      expect(job.package.exist?).to be_true
      expect(job.package.path.end_with?(".gpg")).to be_true

      expect(decrypt_with_passphrase("a secret", job.package.path)).to be_true

      # without specifying any preferences, the default algorithm used is CAST5
      # (these log messages are generated by #decrypt_with_passphrase)
      log_messages = Backup::Logger.messages.map(&:formatted_lines).flatten.join
      expect(log_messages).to match(/gpg: CAST5 encrypted data/)
    end

    specify ":symmetric mode with gpg_config" do
      create_model :my_backup, <<-EOS
        Backup::Model.new(:my_backup, 'a description') do
          archive :my_archive do |archive|
            archive.add "./tmp/test_data"
          end

          encrypt_with GPG do |encryptor|
            encryptor.mode = :symmetric
            encryptor.gpg_homedir = BackupSpec::GPG_HOME_DIR
            encryptor.passphrase = 'a secret'
            encryptor.gpg_config = <<-CONFIG
              personal-cipher-preferences AES256 CAST5
            CONFIG
          end

          store_with Local
        end
      EOS

      job = backup_perform :my_backup
      expect(job.package.exist?).to be_true
      expect(job.package.path.end_with?(".gpg")).to be_true

      expect(decrypt_with_passphrase("a secret", job.package.path)).to be_true

      # preferences specified using AES256 before CAST5
      # (these log messages are generated by #decrypt_with_passphrase)
      log_messages = Backup::Logger.messages.map(&:formatted_lines).flatten.join
      expect(log_messages).to match(/gpg: AES256 encrypted data/)
    end

    specify ":both mode" do
      create_model :my_backup, <<-EOS
        Backup::Model.new(:my_backup, 'a description') do
          archive :my_archive do |archive|
            archive.add "./tmp/test_data"
          end

          encrypt_with GPG do |encryptor|
            encryptor.mode = :both
            encryptor.gpg_homedir = BackupSpec::GPG_HOME_DIR

            encryptor.keys = {
              'backup03@foo.com' => BackupSpec::GPGKeys[:backup03][:public],
            }
            encryptor.passphrase = 'a secret'

            encryptor.recipients = [
              # backup01 (short keyid)
              '16325C61',
              # backup03 (email)
              'backup03@foo.com'
            ]
          end

          store_with Local
        end
      EOS

      # Preload keys for :backup01
      # The key for :backup03 will be imported from #keys.
      import_public_keys_for :backup01

      job = backup_perform :my_backup
      expect(job.package.exist?).to be_true
      expect(job.package.path.end_with?(".gpg")).to be_true

      expect(decrypt_with_user(:backup01, job.package.path)).to be_true
      expect(decrypt_with_user(:backup03, job.package.path)).to be_true

      expect(decrypt_with_passphrase("a secret", job.package.path)).to be_true
    end

    specify ":both mode with no asymmetric recipient keys" do
      create_model :my_backup, <<-EOS
        Backup::Model.new(:my_backup, 'a description') do
          archive :my_archive do |archive|
            archive.add "./tmp/test_data"
          end

          encrypt_with GPG do |encryptor|
            encryptor.mode = :both
            encryptor.gpg_homedir = BackupSpec::GPG_HOME_DIR

            # not a recipient
            encryptor.keys = {
              'backup02@foo.com' => BackupSpec::GPGKeys[:backup02][:public],
            }
            encryptor.passphrase = 'a secret'

            # no keys will be imported or found for these identifiers
            encryptor.recipients = [
              # backup01 (short keyid)
              '16325C61',
              # backup03 (email)
              'backup03@foo.com'
            ]
          end

          store_with Local
        end
      EOS

      # :backup04 is preloaded, :backup01 is imported, but neither are recipients
      import_public_keys_for :backup04

      job = backup_perform :my_backup, exit_status: 1
      expect(job.package.exist?).to be_true
      expect(job.package.path.end_with?(".gpg")).to be_true

      expect(job.logger.has_warnings?).to be_true
      log_messages = job.logger.messages.map(&:formatted_lines).flatten.join

      # issues warnings about the missing keys
      expect(log_messages).to match(
        /\[warn\] No public key was found in #keys for '16325C61'/
      )
      expect(log_messages).to match(
        /\[warn\] No public key was found in #keys for '<backup03@foo.com>'/
      )

      # issues warning about not being able to perform asymmetric encryption
      expect(log_messages).to match(
        /\[warn\] No recipients available for asymmetric encryption/
      )

      expect(decrypt_with_passphrase("a secret", job.package.path)).to be_true
    end

    private

    def gpg_encryptor
      @gpg_encryptor ||= Backup::Encryptor::GPG.new do |gpg|
        gpg.gpg_homedir = BackupSpec::GPG_HOME_DIR
      end
    end

    def clean_homedir
      FileUtils.rm_rf BackupSpec::GPG_HOME_DIR
      gpg_encryptor.send(:setup_gpg_homedir)
    end

    def import_public_keys_for(*users)
      setup_homedir(:public, users)
    end

    def import_private_keys_for(*users)
      setup_homedir(:private, users)
    end

    # reset the homedir and import keys needed for the test
    def setup_homedir(key_type, users)
      clean_homedir

      # This is removed after each test run, but must exist for #import_key
      FileUtils.mkdir_p Config.tmp_path

      # GPG#import_key will log a warning if the import is unsuccessful,
      # so we'll abort here if the returned keyid is incorrect.
      users.each do |user|
        keyid = gpg_encryptor.send(:import_key,
          user, BackupSpec::GPGKeys[user][key_type])
        unless keyid == BackupSpec::GPGKeys[user][:long_id]
          warn Backup::Logger.messages.map(&:lines).flatten.join("\n")
          abort("setup_homedir failed")
        end
      end
    end

    def decrypt_with_user(user, path)
      import_private_keys_for(user)
      decrypt(path)
    end

    def decrypt_with_passphrase(passphrase, path)
      clean_homedir
      decrypt(path, passphrase)
    end

    # returns true if successful and the decrypted tar contents are correct
    # returns false if decryption failed, or will fail the expectation
    def decrypt(path, passphrase = nil)
      outfile = File.join(File.dirname(path), "decrypted.tar")
      FileUtils.rm_f outfile

      pass_opt = "--passphrase '#{passphrase}'" if passphrase
      gpg_encryptor.send(:run,
        "#{gpg_encryptor.send(:utility, :gpg)} " \
        "#{gpg_encryptor.send(:base_options)} " \
        "#{pass_opt} -o '#{outfile}' -d '#{path}' 2>&1")
      if File.exist?(outfile)
        expect(BackupSpec::TarFile.new(outfile)).to match_manifest(
          "10_496_000 my_backup/archives/my_archive.tar"
        )
      else
        false
      end
    end
  end
end
