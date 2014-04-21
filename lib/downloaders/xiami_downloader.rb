# encoding: utf-8

require 'downloaders/downloader'

module Emerald
  module Downloaders

    class XiamiDownloader < Downloader

      require 'nokogiri'
      require 'fileutils'
      require 'tempfile'
      require 'id3_writer'
      require 'utils/xiami_location_decoder'

      SONG_INFO_URL = 'http://www.xiami.com/song/playlist/id/%d/object_name/default/object_id/0'
      ALBUM_PAGE_URL = 'http://www.xiami.com/album/%d'

      def type
        :xiami
      end

      def download(id, options = {})
        id = id.to_i

        url = extract_url(id)

        raw = @cacher.download(url, "#{id}.mp3", show_progress: true).read

        tmp_filename = Dir::Tmpname.make_tmpname(["/tmp/emerald", ".mp3"], nil)
        File.write(tmp_filename, raw)

        Emerald::ID3Writer.write(tmp_filename, extract_metadata(id), retrieve_cover(id))

        result = File.read(tmp_filename)
        FileUtils.rm(tmp_filename)

        result
      end

      private

        def retrieve_info(id)
          info_url = SONG_INFO_URL % id
          page = @cacher.download(info_url, "#{id}.info").read
          Nokogiri::XML(page)
        end

        def retrieve_album_page(id)
          info = retrieve_info(id)
          album_id = info.search('album_id').text.to_i
          album_page_url = ALBUM_PAGE_URL % album_id
          page = @cacher.download(album_page_url, "album_#{album_id}.info").read
          Nokogiri::HTML(page)
        end

        def retrieve_lyrics(id)
          info = retrieve_info(id)

          lyrics_url = info.search('lyric')
          lyrics_url && !lyrics_url.text.strip.empty? ?
            @cacher.download(lyrics_url.text.strip, "#{id}.lrc").read :
            nil
        end

        def retrieve_cover(id)
          info = retrieve_info(id)

          cover_url = info.search('pic')
          return nil unless (cover_url && !cover_url.text.strip.empty?)

          cover_url = cover_url.text.strip

          # Match to see if high resolution version is available
          regex = /(\/[0-9]*)(_[0-9])(\.)/

          if regex =~ cover_url
            # Retrieve the high-res version
            high_res_url = cover_url.gsub(regex, '\1\3')

            return crop_cover(@cacher.download(high_res_url, "#{id}.cover_hq").read, 500)
          else
            # Fallback to low-res version
            return @cacher.download(cover_url, "#{id}.cover").read
          end
        end

        def crop_cover(cover, size)
          require 'image_science'

          tmp_filename = Dir::Tmpname.make_tmpname("/tmp/emerald", nil)
          File.write(tmp_filename, cover)

          ImageScience.with_image(tmp_filename) do |img|
            img.cropped_thumbnail(size) do |thumb|
              thumb.save tmp_filename
            end
          end

          result = File.read(tmp_filename)
          FileUtils.rm(tmp_filename)

          result
        end

        def extract_url(id)
          info = retrieve_info(id)
          url = info.search('location').text

          return nil if (url.nil? || url.empty?)
          return Emerald::Utils::XiamiLocationDecoder.decode(url)
        end

        def extract_album_artist(id)
          album_page = retrieve_album_page(id)

          album_page.css('div#album_info > table tr').each do |tr|
            tds = tr.css('td')
            return tds[1].at_css('a').text if tds[0].text == '艺人：'
          end

          nil
        end

        def extract_publish_year(id)
          album_page = retrieve_album_page(id)

          album_page.css('div#album_info > table tr').each do |tr|
            tds = tr.css('td')
            return tds[1].text.split('年')[0].to_i if tds[0].text == '发行时间：'
          end

          nil
        end

        def extract_order(id)
          album_page = retrieve_album_page(id)

          disc = 0
          div = album_page.at_css('div.chapter')

          div.children.each do |c|
            if c['class'] == 'trackname'
              disc += 1
              next
            elsif c.name == 'table'
              c.at_css('tbody').children.each_with_index do |tr, i|
                return [disc, i + 1] if (tr.at_css('td.song_name a')['href'].include?(id.to_s))
              end
            end
          end

          return [nil, nil]
        end

        def extract_metadata(id)
          info = retrieve_info(id)

          disc, track = extract_order(id)

          {
            artist: info.search('artist').text,
            album: info.search('album_name').text,
            title: info.search('title').text,
            album_artist: extract_album_artist(id),
            disc: disc,
            track: track,
            year: extract_publish_year(id),
            lyrics: retrieve_lyrics(id)
          }
        end

        def output_filename(id, out_path)
          metadata = extract_metadata(id)

          File.join(out_path, "#{metadata[:artist]} - #{metadata[:album]} - #{metadata[:title]}.mp3")
        end

    end

  end
end