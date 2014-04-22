module Emerald
  class Dispatcher

    require 'downloaders/xiami_downloader'

    DOWNLOADERS = [
      Emerald::Downloaders::XiamiDownloader
    ]

    def self.download_url(url, options = {})
      DOWNLOADERS.each do |d|
        return d.download_url(url, options) if d.matches_url?(url)
      end

      nil
    end

  end
end