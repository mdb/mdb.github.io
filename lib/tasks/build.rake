desc "Build MDB"
task :build => ["spec", "assets:precompile", "build:revision", "build:bundle"]

namespace :build do
  def set_fingerprint(values = {})
    fingerprint_file = Rails.root.join('config', 'fingerprint.yml')
    fingerprint = begin
      YAML.load_file(fingerprint_file)
    rescue
      {}
    end

    File.open(fingerprint_file, 'w') do |file|
      YAML.dump(fingerprint.merge(values), file)
    end
  end

  desc "Create all asset packages"
  task :bundle => ["bundle:assets"]

  desc "Clean up build artifacts"
  task :clean => ["bundle:clean"]

  desc "Set the git revision in the config/fingerprint.yml file"
  task :revision do
    require 'git'

    repo = Git.open(Rails.root)
    set_fingerprint('Revision' => repo.log.first.to_s)
  end

  desc "Set arbitrary data in the site fingerprint"
  task :fingerprint do
    raise "'key' must be passed in" if ENV['key'].nil?
    raise "'value' must be passed in" if ENV['value'].nil?

    set_fingerprint(ENV['key'] => ENV['value'])
  end

  namespace :bundle do
    require 'archive/tar/minitar'
    require 'zlib'

    # Build a tar
    def build_tar(output_file, files)
      Zlib::GzipWriter.open(output_file) do |f|
        Archive::Tar::Minitar.open(f, 'w') do |output|
          files.each_pair do |file, relative_name|
            output.tar.add_file_simple(relative_name.to_s,
              :mode => 0666,
              :size => file.size,
              :mtime => file.mtime.to_i
            ) do |stream|
              stream.write(file.read(:open_args => ['rb']))
            end
          end
        end
      end
    end

    assets_output_file = Rails.root.join('mdb.tar.gz')

    desc "Create asset package"
    task :assets => ["assets:precompile"] do
      puts("Creating #{assets_output_file.relative_path_from(Rails.root)}")

      public_dir = Rails.root.join('public')
      asset_dir = public_dir.join('assets')
      files = {}

      asset_dir.find do |path|
        unless path.directory?
          files[path] = path.relative_path_from(public_dir)
        end
      end

      build_tar(assets_output_file, files)
    end
  end
end
