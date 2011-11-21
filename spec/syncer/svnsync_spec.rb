# encoding: utf-8

require File.dirname(__FILE__) + '/../spec_helper'

describe Backup::Syncer::SVNSync do

  let(:svnsync) do
    Backup::Syncer::SVNSync.new do |svnsync|
      svnsync.username  = 'jimmy'
      svnsync.password  = 'secret'
      svnsync.host      = 'foo.com'
      svnsync.repo_path = '/my/repo'
      svnsync.path      = '/home/jimmy/backups/my/repo'
    end
  end

  before do
    Backup::Configuration::Syncer::SVNSync.clear_defaults!
  end

  it 'should have defined the configuration properly' do
    svnsync.username.should  == 'jimmy'
    svnsync.password.should  == 'secret'
    svnsync.host.should      == 'foo.com'
    svnsync.repo_path.should == '/my/repo'
    svnsync.path.should      == '/home/jimmy/backups/my/repo'
  end

  it 'should use the defaults if a particular attribute has not been defined' do
    Backup::Configuration::Syncer::SVNSync.defaults do |svnsync|
      svnsync.username  = 'my_default_username'
      svnsync.password  = 'my_default_password'
      svnsync.host      = 'my_default_host.com'
      svnsync.repo_path = '/my/default/repo/path'
      svnsync.path      = '/home/jimmy/backups'
    end

    svnsync = Backup::Syncer::SVNSync.new do |svnsync|
      svnsync.password = "my_password"
      svnsync.protocol = "https"
      svnsync.port     = "443"
    end

    svnsync.username.should == 'my_default_username'
    svnsync.password.should == 'my_password'
    svnsync.host.should     == 'my_default_host.com'
    svnsync.repo_path       == '/my/default/repo/path'
    svnsync.path            == '/home/jimmy/backups'
    svnsync.protocol.should == 'https'
    svnsync.port.should     == '443'
  end

  describe '#url' do
    it "gets calculated using protocol, host, port and path" do
      svnsync.url.should == "http://foo.com:80/my/repo"
    end
  end

  describe '#local_repo_exists?' do
    before do
      svnsync.stubs(:run)
    end

    it "returns false when not in a working copy" do
      svnsync.stubs(:stderr).returns("svn: '/home/jimmy/backups/my/repo' is not a working copy")
      svnsync.local_repo_exists?.should be_false
    end

    it "returns true when inside a working copy" do
      svnsync.stubs(:stderr).returns("")
      svnsync.local_repo_exists?.should be_true
    end
  end

  describe '#initialize_repo' do
    it 'initializes an empty repo' do
      svnsync.stubs(:run)

      Backup::Logger.expects(:message).with("Initializing repo")
      svnsync.expects(:run).with("svnadmin create '/home/jimmy/backups/my/repo'")
      svnsync.expects(:run).with("echo '#!/bin/sh' > '/home/jimmy/backups/my/repo/hooks/pre-revprop-change'")
      svnsync.expects(:run).with("chmod +x '/home/jimmy/backups/my/repo/hooks/pre-revprop-change'")
      svnsync.expects(:run).with("svnsync init file:///home/jimmy/backups/my/repo http://foo.com:80/my/repo --source-username jimmy --source-password secret")

      svnsync.initialize_repo
    end
  end

  describe '#perform' do

    before do
      svnsync.stubs(:run)
    end

    it 'logs and calls svnsync without initializing the repo, if it already exists' do
      svnsync.stubs(:local_repo_exists?).returns true
      Backup::Logger.expects(:message).with("Backup::Syncer::SVNSync started syncing 'http://foo.com:80/my/repo' '/home/jimmy/backups/my/repo'.")
      FileUtils.expects(:mkdir_p).with(svnsync.path)
      svnsync.expects(:run).with("svnsync sync file:///home/jimmy/backups/my/repo --source-username jimmy --source-password secret --non-interactive")
      svnsync.expects(:initialize_repo).at_most(0)
      svnsync.perform!
    end

    it 'initializes the repo if not initialized' do
      svnsync.stubs(:local_repo_exists?).returns false
      svnsync.expects(:initialize_repo)
      svnsync.perform!
    end
  end


end
