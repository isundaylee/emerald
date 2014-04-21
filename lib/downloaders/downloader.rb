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

      def download(id)
        raise NotImplementedError
      end

    end

  end
end