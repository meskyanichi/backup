require "spec_helper"

describe Backup::Utilities do
  let(:utilities) { Backup::Utilities }
  let(:helpers) { Module.new.extend(Backup::Utilities::Helpers) }

  # Note: spec_helper resets Utilities before each example

  describe ".configure" do
    before do
      allow(File).to receive(:executable?).and_return(true)
      allow(utilities).to receive(:gnu_tar?).and_call_original
      allow(utilities).to receive(:utility).and_call_original

      utilities.configure do
        # General Utilites
        tar      "/path/to/tar"
        tar_dist :gnu # or :bsd
        cat      "/path/to/cat"
        split    "/path/to/split"
        sudo     "/path/to/sudo"
        chown    "/path/to/chown"
        hostname "/path/to/hostname"

        # Compressors
        gzip    "/path/to/gzip"
        bzip2   "/path/to/bzip2"
        pbzip2  "/path/to/pbzip2"

        # Database Utilities
        mongo        "/path/to/mongo"
        mongodump    "/path/to/mongodump"
        mysqldump    "/path/to/mysqldump"
        pg_dump      "/path/to/pg_dump"
        pg_dumpall   "/path/to/pg_dumpall"
        redis_cli    "/path/to/redis-cli"
        riak_admin   "/path/to/riak-admin"
        innobackupex "/path/to/innobackupex"

        # Encryptors
        gpg     "/path/to/gpg"
        openssl "/path/to/openssl"

        # Syncer and Storage
        rsync   "/path/to/rsync"
        ssh     "/path/to/ssh"

        # Notifiers
        sendmail  "/path/to/sendmail"
        exim      "/path/to/exim"
        send_nsca "/path/to/send_nsca"
        zabbix_sender "/path/to/zabbix_sender"
      end
    end

    it "allows utilities to be configured" do
      utilities::UTILITIES_NAMES.each do |name|
        expect(helpers.send(:utility, name)).to eq("/path/to/#{name}")
      end
    end

    it "presets gnu_tar? value to true" do
      expect(utilities).to_not receive(:run)
      expect(utilities.gnu_tar?).to be(true)
      expect(helpers.send(:gnu_tar?)).to be(true)
    end

    it "presets gnu_tar? value to false" do
      utilities.configure do
        tar_dist :bsd
      end

      expect(utilities).to_not receive(:run)
      expect(utilities.gnu_tar?).to be(false)
      expect(helpers.send(:gnu_tar?)).to be(false)
    end

    it "expands relative paths" do
      utilities.configure do
        tar "my_tar"
      end
      path = File.expand_path("my_tar")
      expect(utilities.utilities["tar"]).to eq(path)
      expect(helpers.send(:utility, :tar)).to eq(path)
    end

    it "raises Error if utility is not found or executable" do
      allow(File).to receive(:executable?).and_return(false)
      expect do
        utilities.configure do
          tar "not_found"
        end
      end.to raise_error(Backup::Utilities::Error)
    end
  end # describe '.configure'

  describe ".gnu_tar?" do
    before do
      allow(utilities).to receive(:gnu_tar?).and_call_original
    end

    it "determines when tar is GNU tar" do
      expect(utilities).to receive(:utility).with(:tar).and_return("tar")
      expect(utilities).to receive(:run).with("tar --version").and_return(
        'tar (GNU tar) 1.26\nCopyright (C) 2011 Free Software Foundation, Inc.'
      )
      expect(utilities.gnu_tar?).to be(true)
      expect(utilities.instance_variable_get(:@gnu_tar)).to be(true)
    end

    it "determines when tar is BSD tar" do
      expect(utilities).to receive(:utility).with(:tar).and_return("tar")
      expect(utilities).to receive(:run).with("tar --version").and_return(
        "bsdtar 3.0.4 - libarchive 3.0.4"
      )
      expect(utilities.gnu_tar?).to be(false)
      expect(utilities.instance_variable_get(:@gnu_tar)).to be(false)
    end

    it "returns cached true value" do
      utilities.instance_variable_set(:@gnu_tar, true)
      expect(utilities).to_not receive(:run)
      expect(utilities.gnu_tar?).to be(true)
    end

    it "returns cached false value" do
      utilities.instance_variable_set(:@gnu_tar, false)
      expect(utilities).to_not receive(:run)
      expect(utilities.gnu_tar?).to be(false)
    end
  end
end # describe Backup::Utilities

describe Backup::Utilities::Helpers do
  let(:helpers) { Module.new.extend(Backup::Utilities::Helpers) }
  let(:utilities) { Backup::Utilities }

  describe "#utility" do
    before do
      allow(utilities).to receive(:utility).and_call_original
    end

    context "when a system path for the utility is available" do
      it "should return the system path with newline removed" do
        expect(utilities).to receive(:`).with("which 'foo' 2>/dev/null").and_return("system_path\n")
        expect(helpers.send(:utility, :foo)).to eq("system_path")
      end

      it "should cache the returned path" do
        expect(utilities).to receive(:`).once.with("which 'cache_me' 2>/dev/null")
          .and_return("cached_path\n")

        expect(helpers.send(:utility, :cache_me)).to eq("cached_path")
        expect(helpers.send(:utility, :cache_me)).to eq("cached_path")
      end

      it "should return a mutable copy of the path" do
        expect(utilities).to receive(:`).once.with("which 'cache_me' 2>/dev/null")
          .and_return("cached_path\n")

        helpers.send(:utility, :cache_me) << "foo"
        expect(helpers.send(:utility, :cache_me)).to eq("cached_path")
      end

      it "should cache the value for all extended objects" do
        expect(utilities).to receive(:`).once.with("which 'once_only' 2>/dev/null")
          .and_return("cached_path\n")

        expect(helpers.send(:utility, :once_only)).to eq("cached_path")
        result = Class.new.extend(Backup::Utilities::Helpers).send(
          :utility, :once_only
        )
        expect(result).to eq("cached_path")
      end
    end

    it "should raise an error if the utiilty is not found" do
      expect(utilities).to receive(:`).with("which 'unknown' 2>/dev/null").and_return("\n")

      expect do
        helpers.send(:utility, :unknown)
      end.to raise_error(Backup::Utilities::Error, /Could not locate 'unknown'/)
    end

    it "should raise an error if name is nil" do
      expect(utilities).to_not receive(:`)
      expect do
        helpers.send(:utility, nil)
      end.to raise_error(Backup::Utilities::Error, "Utilities::Error: Utility Name Empty")
    end

    it "should raise an error if name is empty" do
      expect(utilities).to_not receive(:`)
      expect do
        helpers.send(:utility, " ")
      end.to raise_error(Backup::Utilities::Error, "Utilities::Error: Utility Name Empty")
    end
  end # describe '#utility'

  describe "#command_name" do
    it "returns the base command name" do
      cmd = "/path/to/a/command"
      expect(helpers.send(:command_name, cmd)).to eq "command"

      cmd = "/path/to/a/command with_args"
      expect(helpers.send(:command_name, cmd)).to eq "command"

      cmd = "/path/to/a/command with multiple args"
      expect(helpers.send(:command_name, cmd)).to eq "command"

      # should not happen, but should handle it
      cmd = "command args"
      expect(helpers.send(:command_name, cmd)).to eq "command"
      cmd = "command"
      expect(helpers.send(:command_name, cmd)).to eq "command"
    end

    it "returns command name run with sudo" do
      cmd = "/path/to/sudo -n /path/to/command args"
      expect(helpers.send(:command_name, cmd))
        .to eq "sudo -n command"

      cmd = "/path/to/sudo -n -u username /path/to/command args"
      expect(helpers.send(:command_name, cmd))
        .to eq "sudo -n -u username command"

      # should not happen, but should handle it
      cmd = "/path/to/sudo -n -u username command args"
      expect(helpers.send(:command_name, cmd))
        .to eq "sudo -n -u username command args"
    end

    it "strips environment variables" do
      cmd = "FOO='bar' BAR=foo /path/to/a/command with_args"
      expect(helpers.send(:command_name, cmd)).to eq "command"
    end
  end # describe '#command_name'

  describe "#run" do
    let(:stdout_io) { double(IO, read: stdout_messages) }
    let(:stderr_io) { double(IO, read: stderr_messages) }
    let(:stdin_io)  { double(IO, close: nil) }
    let(:process_status) { double(Process::Status, success?: process_success) }
    let(:command) { "/path/to/cmd_name arg1 arg2" }

    before do
      allow(utilities).to receive(:run).and_call_original
    end

    context "when the command is successful" do
      let(:process_success) { true }

      before do
        expect(Backup::Logger).to receive(:info).with(
          "Running system utility 'cmd_name'..."
        )

        expect(Open4).to receive(:popen4).with(command).and_yield(
          nil, stdin_io, stdout_io, stderr_io
        ).and_return(process_status)
      end

      context "and generates no messages" do
        let(:stdout_messages) { "" }
        let(:stderr_messages) { "" }

        it "should return stdout and generate no additional log messages" do
          expect(helpers.send(:run, command)).to eq("")
        end
      end

      context "and generates only stdout messages" do
        let(:stdout_messages) { "out line1\nout line2\n" }
        let(:stderr_messages) { "" }

        it "should return stdout and log the stdout messages" do
          expect(Backup::Logger).to receive(:info).with(
            "cmd_name:STDOUT: out line1\ncmd_name:STDOUT: out line2"
          )
          expect(helpers.send(:run, command)).to eq(stdout_messages.strip)
        end
      end

      context "and generates only stderr messages" do
        let(:stdout_messages) { "" }
        let(:stderr_messages) { "err line1\nerr line2\n" }

        it "should return stdout and log the stderr messages" do
          expect(Backup::Logger).to receive(:warn).with(
            "cmd_name:STDERR: err line1\ncmd_name:STDERR: err line2"
          )
          expect(helpers.send(:run, command)).to eq("")
        end
      end

      context "and generates messages on both stdout and stderr" do
        let(:stdout_messages) { "out line1\nout line2\n" }
        let(:stderr_messages) { "err line1\nerr line2\n" }

        it "should return stdout and log both stdout and stderr messages" do
          expect(Backup::Logger).to receive(:info).with(
            "cmd_name:STDOUT: out line1\ncmd_name:STDOUT: out line2"
          )
          expect(Backup::Logger).to receive(:warn).with(
            "cmd_name:STDERR: err line1\ncmd_name:STDERR: err line2"
          )
          expect(helpers.send(:run, command)).to eq(stdout_messages.strip)
        end
      end
    end # context 'when the command is successful'

    context "when the command is not successful" do
      let(:process_success) { false }
      let(:message_head) do
        "Utilities::Error: 'cmd_name' failed with exit status: 1\n"
      end

      before do
        expect(Backup::Logger).to receive(:info).with(
          "Running system utility 'cmd_name'..."
        )

        expect(Open4).to receive(:popen4).with(command).and_yield(
          nil, stdin_io, stdout_io, stderr_io
        ).and_return(process_status)

        allow(process_status).to receive(:exitstatus).and_return(1)
      end

      context "and generates no messages" do
        let(:stdout_messages) { "" }
        let(:stderr_messages) { "" }

        it "should raise an error reporting no messages" do
          expect do
            helpers.send(:run, command)
          end.to raise_error StandardError, "#{message_head}"\
            "  STDOUT Messages: None\n" \
            "  STDERR Messages: None"
        end
      end

      context "and generates only stdout messages" do
        let(:stdout_messages) { "out line1\nout line2\n" }
        let(:stderr_messages) { "" }

        it "should raise an error and report the stdout messages" do
          expect do
            helpers.send(:run, command)
          end.to raise_error StandardError, "#{message_head}" \
            "  STDOUT Messages: \n" \
            "  out line1\n" \
            "  out line2\n" \
            "  STDERR Messages: None"
        end
      end

      context "and generates only stderr messages" do
        let(:stdout_messages) { "" }
        let(:stderr_messages) { "err line1\nerr line2\n" }

        it "should raise an error and report the stderr messages" do
          expect do
            helpers.send(:run, command)
          end.to raise_error StandardError, "#{message_head}" \
            "  STDOUT Messages: None\n" \
            "  STDERR Messages: \n" \
            "  err line1\n" \
            "  err line2"
        end
      end

      context "and generates messages on both stdout and stderr" do
        let(:stdout_messages) { "out line1\nout line2\n" }
        let(:stderr_messages) { "err line1\nerr line2\n" }

        it "should raise an error and report the stdout and stderr messages" do
          expect do
            helpers.send(:run, command)
          end.to raise_error StandardError, "#{message_head}" \
              "  STDOUT Messages: \n" \
              "  out line1\n" \
              "  out line2\n" \
              "  STDERR Messages: \n" \
              "  err line1\n" \
              "  err line2"
        end
      end
    end # context 'when the command is not successful'

    context "when the system fails to execute the command" do
      before do
        expect(Backup::Logger).to receive(:info).with(
          "Running system utility 'cmd_name'..."
        )

        expect(Open4).to receive(:popen4).and_raise("exec call failed")
      end

      it "should raise an error wrapping the system error raised" do
        expect do
          helpers.send(:run, command)
        end.to raise_error(Backup::Utilities::Error) { |err|
          expect(err.message).to match("Failed to execute 'cmd_name'")
          expect(err.message).to match("RuntimeError: exec call failed")
        }
      end
    end # context 'when the system fails to execute the command'
  end # describe '#run'

  describe "gnu_tar?" do
    it "returns true if tar_dist is gnu" do
      expect(Backup::Utilities).to receive(:gnu_tar?).and_return(true)
      expect(helpers.send(:gnu_tar?)).to be(true)
    end

    it "returns false if tar_dist is bsd" do
      expect(Backup::Utilities).to receive(:gnu_tar?).and_return(false)
      expect(helpers.send(:gnu_tar?)).to be(false)
    end
  end
end # describe Backup::Utilities::Helpers
