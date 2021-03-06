module Emerald
  class ID3Writer
    require 'taglib'
    require 'ruby-pinyin'

    def self.write(path, info, cover)
      TagLib::MPEG::File.open(path) do |f|
        tag = f.id3v2_tag

        [:artist, :album, :title, :album_artist, :disc, :track, :year, :lyrics].each { |t| info[t] ||= '' }

        # Basic tags
        tag.artist = info[:artist]
        tag.album = info[:album]
        tag.title = info[:title]

        # Album artist
        set_text_frame(tag, 'TPE2', info[:album_artist])

        # Track order
        set_text_frame(tag, 'TPOS', info[:disc])
        set_text_frame(tag, 'TRCK', info[:track])

        # Publish year
        set_text_frame(tag, 'TDRC', info[:year])

        # Add lyrics
        set_lyrics(tag, info[:lyrics])

        # Sorting fields
        set_text_frame(tag, 'TSOT', PinYin.sentence(info[:title]))
        set_text_frame(tag, 'TSOA', PinYin.sentence(info[:album]))
        set_text_frame(tag, 'TSOP', PinYin.sentence(info[:artist]))
        set_text_frame(tag, 'TSO2', PinYin.sentence(info[:album_artist]))

        # Cover image
        set_cover(tag, cover) if cover

        f.save
      end
    end

    private

      def self.text_frame(frame_id, text)
        frame = TagLib::ID3v2::TextIdentificationFrame.new(frame_id, TagLib::String::UTF8)
        frame.text = text.to_s
        frame
      end

      def self.set_text_frame(tag, frame_id, text)
        tag.remove_frames(frame_id)
        tag.add_frame(text_frame(frame_id, text))
      end

      def self.set_lyrics(tag, lyrics)
        tag.remove_frames('USLT')
        frame = TagLib::ID3v2::UnsynchronizedLyricsFrame.new(TagLib::String::UTF8)
        frame.text = simplify_lyrics(lyrics)
        tag.add_frame(frame)
      end

      def self.simplify_lyrics(lyrics)
        ls = lyrics.lines.to_a
        nls = []

        ls.each do |ll|
          unless ll =~ /\[[^0-9][^0-9]:.*?\]/
            ll.gsub! /\[.*?\]/, ''
            nls += [ll.strip]
          end
        end

        nls.join("\n")
      end

      def self.set_cover(tag, cover)
        apic = TagLib::ID3v2::AttachedPictureFrame.new
        apic.mime_type = 'image/png'
        apic.description = 'Cover'
        apic.type = TagLib::ID3v2::AttachedPictureFrame::FrontCover
        apic.picture = cover

        tag.add_frame(apic)
      end

  end
end