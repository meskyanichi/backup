# encoding: utf-8

# Matches the contents of a TarFile (or PerformedJob.package)
# against the given manifest.
#
# Usage:
#
#     performed_job = backup_perform :trigger
#
#     expect(performed_job.package).to match_manifest(<<-EOS)
#       51200  my_backup/archives/my_archive.tar
#       8099   my_backup/databases/MySQL/backup_test_01.sql
#     EOS
#
# File sizes may also be tested against a range, using `min..max`.
#
#     expect(performed_job.package).to match_manifest(%q[
#       51200..51250 my_backup/archives/my_archive.tar
#       8099         my_backup/databases/MySQL/backup_test_01.sql
#     ])
#
# Or simply checked for existance, using `-`:
#
#     expect(performed_job.package).to match_manifest(%q[
#       -     my_backup/archives/my_archive.tar
#       8099  my_backup/databases/MySQL/backup_test_01.sql
#     ])
#
# Extra spaces and blank lines are ok.
#
# If the given files with the given sizes do not match all the files
# in the archive"s manifest, the error message will include the entire
# manifest as output by `tar -tvf`.
RSpec::Matchers.define :match_manifest do |expected|
  match do |actual|
    expected_contents = expected.split("\n").map(&:strip).reject(&:empty?)
    expected_contents.map! { |line| line.split(" ") }
    expected_contents = Hash[
      expected_contents.map { |fields| [fields[1], fields[0]] }
    ]

    files_match = expected_contents.keys.sort == actual.contents.keys.sort
    if files_match
      sizes_ok = true
      expected_contents.each do |path, size|
        actual_size = actual.contents[path]

        sizes_ok =
          case size
          when "-" then true
          when /\d+(\.\.)\d+/
            a, b = size.split("..").map(&:to_i)
            (a..b).cover? actual_size
          else
            size.to_i == actual_size
          end

        break unless sizes_ok
      end
    end

    files_match && sizes_ok
  end

  failure_message_for_should do |actual|
    "expected that:\n\n#{actual.manifest}\n" \
    "would match:\n#{expected}"
  end
end
