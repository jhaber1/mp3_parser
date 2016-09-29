require IEx;

defmodule Parser do
  @path '/Users/jhaber/Downloads/Angel Sword - Rebels Beyond the Pale/Angel Sword - Rebels Beyond the Pale - 01 Devastator.mp3'
  @picture_types ["Other", "32x32 pixels 'file icon' (PNG only)", "Other file icon", "Cover (front)", "Cover (back)", "Leaflet page", "Media (e.g. label side of CD)", "Lead artist/lead performer/soloist", "Artist/performer", "Conductor", "Band/Orchestra", "Composer", "Lyricist/text writer", "Recording Location", "During recording", "During performance", "Movie/video screen capture", "A bright coloured fish", "Illustration", "Band/artist logotype", "Publisher/Studio logotype"]

  def parse(path \\ @path) do
    data = File.read!(path)

    offset = 10
    # offset = offset + 10
    id3 = parse_header(data)
    #IO.puts(inspect(id3))

    tags = parse_tags(data, offset)
    id3 = Map.put(id3, :tags, tags)

    IO.puts(inspect(id3))
  end

  # Currently only assumes v2.3
  defp parse_header(data) do
    << identifier :: binary-size(3),
      # Version
      minor_version :: integer,
      revision_number :: integer,
      # TODO: Unparsed flags byte
      _ :: integer,
      size :: integer-unit(8)-size(4),
      _ :: binary >> = data

    %{ id: identifier, version: "v2.#{minor_version}.#{revision_number}", size: size }
  end

  def parse_tags(data, offset, tags \\ []) do
    # TODO: make sure to set frame header size for 2.2 (2.4 is same as 2.3)
    frame_header_size = 10

    # Assumes only T* frames for now
    # TODO: Figure out parsing all others

    # Code for picking parsing method HERE (use case/cond)

    << _ :: binary-size(offset),
     frame_id :: binary-size(4),
     size :: integer-unit(8)-size(4),
     # TODO: Unparsed flags
     flags :: integer-unit(8)-size(2),
      _ :: binary >> = data

    # Adjust offset to account for the frame header that was just parsed
    total_offset = offset + frame_header_size

    case String.first(frame_id) do
      # Text frames
      "T" ->
        << _ :: binary-size(total_offset),
          binary_value :: binary-size(size),
          _ :: binary >> = data
        tag_map = %{ id: frame_id, size: size, flags: flags, value: parse_string(binary_value) }
        IO.puts(inspect(tag_map))

        parse_tags(data, total_offset + size, tags ++ [tag_map])
      # Attached picture (APIC)
      "A" ->
        #s = size - total_offset - 1

        << _ :: binary-size(total_offset),
          text_encoding :: integer-size(8),
          mime_type :: binary-size(size),
          _ :: binary >> = data

        mime_type = parse_null_terminated_string(mime_type)

        # Adjust offset for text encoding byte, MIME type, and the null byte that was at the end of the MIME type
        total_offset_with_mime = total_offset + 1 + String.length(mime_type) + 1

        << _ :: binary-size(total_offset_with_mime),
          picture_type :: integer,
          description :: binary-size(64),
          _ :: binary >> = data

        # TODO: Handle null terminated string in parse_string !!!!!!!!!!!!!!!!!!!!!!!!!
        # desc = parse_null_terminated_string(description)
        # IO.puts(desc)
    end
  end

  def parse_frame(data, offset) do
    # << _ :: binary-size(offset),
    #   frame_id :: binary-size(4),
    #   size :: integer-unit(8)-size(4),
    #   # TODO: Unparsed flags
    #   _ :: integer-size(16),
    #   binary_value :: binary-size(size),
    #   _ :: binary >> = data
  end

  def parse_string(binary_value \\ <<1, 255, 254, 68, 0, 101, 0, 118, 0, 97, 0, 115, 0, 116, 0, 97, 0, 116, 0, 111, 0, 114, 0, 0, 0>>) do

    # TODO: very hacky, need a better way to detect if the string has the encoding attached or not
    # If the encoding is included with the string, make sure to match it properly
    if String.starts_with?(binary_value, [<<0>>, <<1>>, <<2>>, <<3>>]) do
      # Take apart the string, figure out what text_encoding to use, figure out endianness
      # TODO: text_encoding == 0: iso-8859-1,
      # TODO: text_encoding == 2: utf-16be
      # TODO: text_encoding == 3: utf-8
      << text_encoding :: integer-size(8),
        unicode_bom :: integer-unit(8)-size(2),
        string :: binary >> = binary_value
    else
      << unicode_bom :: integer-unit(8)-size(2),
        string :: binary >> = binary_value
    end

    :unicode.characters_to_binary(string, {:utf16, :little}) |> String.trim_trailing(<<0>>)
  end

  # TODO: Split this into another function signature?
  def parse_null_terminated_string(<< codepoint :: utf8, rest :: binary>>, result \\ "") do
    if codepoint == 0 do
      result
    else
      parse_null_terminated_string(rest, << result :: binary, codepoint :: utf8 >>)
    end
  end

end