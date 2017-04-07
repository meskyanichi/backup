# encoding: utf-8

module BackupSpec
  class FilesetBuilder
    def create(root_dir, dir_name, total, file_size)
      create_dir(root_dir, dir_name)
      create_fileset(File.join(root_dir, dir_name), total, file_size)
    end

    def create_dir(parent_dir, dir_name)
      dir = File.join(parent_dir, dir_name)
      Dir.mkdir(dir) unless Dir.exist?(dir)
    end

    def create_file(file_path, file_size)
      File.open(file_path, "w") do |file|
        contents = "x" * (1024 * 1024)
        file_size.to_i.times { file.write(contents) }
      end
    end

    def create_fileset(dir, total, file_size)
      count = 0
      total.times do
        count += 1
        file_name = "#{count}.txt"
        file_path = File.join(dir, file_name)
        create_file(file_path, file_size)
      end
    end
  end
end
