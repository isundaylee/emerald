require 'downloaders/downloader'

module Emerald
  module Downloaders

    class XiamiDownloader < Downloader

      require 'nokogiri'
      require 'fileutils'
      require 'utils/xiami_location_decoder'

      SONG_INFO_URL = 'http://www.xiami.com/song/playlist/id/%d/object_name/default/object_id/0'

      def type
        :xiami
      end

      def download(id, options = {})
        id = id.to_i

        url = retrieve_url(id)

        raw = @cacher.download(url, "#{id}.mp3", show_progress: true).read

        raw
      end

      private

        def retrieve_info(id)
          info_url = SONG_INFO_URL % id
          page = @cacher.download(info_url, "#{id}.info").read
          Nokogiri::XML(page)
        end

        def retrieve_url(id)
          info = retrieve_info(id)
          url = info.search('location').text

          return nil if (url.nil? || url.empty?)
          return Emerald::Utils::XiamiLocationDecoder.decode(url)
        end

        def extract_metadata(id)
          info = retrieve_info(id)

          {
            artist: info.search('artist').text,
            album: info.search('album_name').text,
            title: info.search('title').text
          }
        end

        def output_filename(id, out_path)
          metadata = extract_metadata(id)

          File.join(out_path, "#{metadata[:artist]} - #{metadata[:album]} - #{metadata[:title]}.mp3")
        end

    end

  end
end