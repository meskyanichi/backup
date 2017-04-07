# encoding: utf-8

module BackupSpec
  class Package
    include Backup::Utilities::Helpers
    extend Forwardable
    def_delegators :tarfile, :manifest, :contents, :[]

    attr_reader :model

    def initialize(model)
      @model = model
    end

    def exist?
      !files.empty? && files.all? { |f| File.exist?(f) }
    end

    def path
      @path ||= unsplit
    end

    # Note that once the package is inspected with the match_manifest matcher,
    # a Tarfile will be created. If the Splitter was used, this will create an
    # additional file (the re-joined tar) in the remote_path. If #[] is used,
    # the package will be extracted into the remote_path. Some cycling
    # operations remove each package file, then the timestamp directory which
    # should be empty at that point. So you can"t inspect a split package"s
    # manifest or inspect tar files within the package when testing cycling.
    def removed?
      files.all? { |f| !File.exist?(f) }
    end

    # If a trigger is run multiple times within a test (like when testing cycling),
    # multiple packages will exist under different timestamp folders.
    # This allows us to find the package files for the specific model given.
    #
    # For most tests the Local storage is used, which will have a remote_path
    # that"s already expanded. Others like SCP, RSync (:ssh mode), etc... will
    # have a remote_path that"s relative to the vagrant user"s home.
    # The exception is the RSync daemon modes, where remote_path will begin
    # with daemon module names, which are mapped to the vagrant user"s home.
    def files
      @files ||= begin
        storage = model.storages.first
        return [] unless storage # model didn"t store anything

        path = storage.send(:remote_path)
        unless path == File.expand_path(path)
          path.sub!(/(ssh|rsync)-daemon-module/, "")
          path = File.expand_path(File.join("tmp", path))
        end
        Dir[File.join(path, "#{model.trigger}.tar*")].sort
      end
    end

    private

    def tarfile
      @tarfile ||= TarFile.new(path)
    end

    def unsplit
      return files.first unless files.count > 1

      base_dir = File.dirname(files.first)
      orig_ext = File.extname(files.first)
      base_ext = orig_ext.split("-").first
      outfile = File.basename(files.first).sub(/#{ orig_ext }$/, base_ext)
      Dir.chdir(base_dir) do
        `#{ utility(:cat) } #{ outfile }-* > #{ outfile }`
      end
      File.join(base_dir, outfile)
    end
  end
end
