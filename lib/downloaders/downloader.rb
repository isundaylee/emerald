module Emerald
  module Downloaders

    class Downloader

      require 'cacher'

      def initialize
        @cacher = Cacher.new(type.to_s)
      end

      def type
        raise NotImplementedError
      end

      def download(id, options = {})
        raise NotImplementedError
      end

      def download_url(url, options = {})
        raise NotImplementedError
      end

      def matches_url?(url)
        raise NotImplementedError
      end

    end

  end
end