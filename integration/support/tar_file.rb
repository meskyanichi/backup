# encoding: utf-8

module BackupSpec
  class TarFile
    include Backup::Utilities::Helpers

    attr_reader :path

    def initialize(path)
      @path = path
    end

    def manifest
      @manifest ||= begin
        if File.exist?(path.to_s)
          `#{ utility(:tar) } -tvf #{ path } 2>/dev/null`
        else
          ""
        end
      end
    end

    # GNU/BSD have different formats for `tar -tvf`.
    #
    # Returns a Hash of { "path" => size } for only the files in the manifest.
    def contents
      @contents ||= begin
        data = manifest.split("\n").reject { |line| line =~ %r{\/$} }
        data.map! { |line| line.split(" ") }
        if gnu_tar?
          Hash[data.map { |fields| [fields[5], fields[2].to_i] }]
        else
          Hash[data.map { |fields| [fields[8], fields[4].to_i] }]
        end
      end
    end

    def [](val)
      extracted_files[val]
    end

    private

    # Return a Hash with the paths from #contents mapped to either another
    # TarFile object (for tar files) or the full path to the extracted file.
    def extracted_files
      @extracted_files ||= begin
        base_path = File.dirname(path)
        filename = File.basename(path)
        Dir.chdir(base_path) do
          `#{ utility(:tar) } -xf #{ filename } 2>/dev/null`
        end
        Hash[
          contents.keys.map do |manifest_path|
            path = File.join(base_path, manifest_path.sub(%r{^\/}, ""))
            if path =~ /\.tar.*$/
              [manifest_path, self.class.new(path)]
            else
              [manifest_path, path]
            end
          end
        ]
      end
    end
  end
end
