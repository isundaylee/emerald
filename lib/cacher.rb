module Emerald

  class Cacher

    require 'fileutils'
    require 'digest/md5'

    def initialize(prefix = nil, options = {})
      @cache_dir = options[:cache_dir] || '/tmp/emerald_cache'
      @prefix = prefix
      @full_cache_dir = @prefix ?
        File.join(@cache_dir, @prefix) :
        @cache_dir

      FileUtils.mkdir_p(@full_cache_dir)
    end

    def download(url, key = nil, options = {})
      key ||= Digest::MD5.hexdigest(url)

      download_to_cache(url, key, options[:show_progress]) unless File.exists?(cache_path(key))

      return File.open(cache_path(key))
    end

    def cache_path(key)
      File.join(@full_cache_dir, key)
    end

    private

      def tmp_path(key)
        File.join(@full_cache_dir, key + '.tmp')
      end

      def download_to_cache(url, key, show_progress)
        tmp_path = tmp_path(key)
        cache_path = cache_path(key)

        command = "curl --connect-timeout 15 --retry 999 --retry-max-time 0 -C - -# \"%s\" -o \"%s\"" % [url, tmp_path]
        command += ' > /dev/null 2>&1' unless show_progress

        system(command)
        FileUtils.mv(tmp_path, cache_path)
      end

  end

end