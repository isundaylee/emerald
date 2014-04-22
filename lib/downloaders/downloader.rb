module Emerald
  module Downloaders

    class Downloader

      require 'cacher'

      def self.type
        raise NotImplementedError
      end

      def self.download(id, options = {})
        raise NotImplementedError
      end

      def self.download_url(url, options = {})
        raise NotImplementedError
      end

      def self.matches_url?(url)
        raise NotImplementedError
      end

      def self.cacher
        @@cacher ||= Emerald::Cacher.new(type.to_s)
      end

    end

  end
end