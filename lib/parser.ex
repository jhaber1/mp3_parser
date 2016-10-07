require IEx;

defmodule Parser do
  @picture_types ["Other", "32x32 pixels 'file icon' (PNG only)", "Other file icon", "Cover (front)", "Cover (back)", "Leaflet page", "Media (e.g. label side of CD)", "Lead artist/lead performer/soloist", "Artist/performer", "Conductor", "Band/Orchestra", "Composer", "Lyricist/text writer", "Recording Location", "During recording", "During performance", "Movie/video screen capture", "A bright coloured fish", "Illustration", "Band/artist logotype", "Publisher/Studio logotype"]

  def parse(path \\ '/Users/jhaber/Downloads/Angel Sword - Rebels Beyond the Pale/Angel Sword - Rebels Beyond the Pale - 01 Devastator.mp3') do
    data = File.read!(path)

    offset = 10

    id3 = parse_header(data)
    tags = parse_tags(data, offset)
    id3 = Map.put(id3, :tags, tags)

    IO.puts(inspect(id3))
  end

  # Currently only assumes v2.3
  defp parse_header(data) do
    # "ID3"
    << _ :: binary-size(3),
      # idv2 Version numbers
      minor_version :: integer,
      revision_number :: integer,
      # Flags
      unsynchronisation :: integer-size(1),
      extended_header :: integer-size(1),
      experimental_indicator :: integer-size(1),
      # Unused rest of the flags byte
      _ :: integer-size(5),
      # File size in bytes
      size :: integer-unit(8)-size(4),
      _ :: binary >> = data

    %{
      id: "ID3",
      version: "v2.#{minor_version}.#{revision_number}",
      size: size,
      flags: [
        unsynchronisation: is_present(unsynchronisation),
        extended_header: is_present(extended_header),
        experimental_indicator: is_present(experimental_indicator)
      ]
    }
  end

  def parse_tags(data, offset, tags \\ []) do
    # TODO: make sure to set frame header size for 2.2 (2.4 is same as 2.3)
    frame_header_size = 10

    << _ :: binary-size(offset),
     frame_id :: binary-size(4),
     size :: integer-unit(8)-size(4),
     # TODO: Unparsed flags
     flags :: integer-unit(8)-size(2),
      _ :: binary >> = data

    # Adjust offset to account for the frame header that was just parsed
    total_offset = offset + frame_header_size

    cond do
      # Attached picture (APIC)
      frame_id == "APIC" ->
        << _ :: binary-size(total_offset),
          text_encoding :: integer-size(8),
          mime_type :: binary-size(size),
          _ :: binary >> = data

        mime_type = parse_null_terminated_string_utf8(mime_type)

        # Adjust offset for text encoding byte, MIME type, and the null byte that was at the end of the MIME type
        total_offset_with_mime = total_offset + 1 + String.length(mime_type) + 1

        << _ :: binary-size(total_offset_with_mime),
          picture_type :: integer,
          description :: binary-size(64),
          _ :: binary >> = data

        desc = parse_null_terminated_string_utf16le(description)

        tag_map = %{ id: frame_id, size: size, flags: flags, mime_type: mime_type,
          picture_type: Enum.at(@picture_types, picture_type), description: desc }
        IO.puts(inspect(tag_map))

        parse_tags(data, total_offset + size, tags ++ [tag_map])

      # Comments (COMM)
      # Unsychronised lyrics/text transcription (USLT)
      frame_id =~ ~R/^(COMM|USLT)/ ->
        tag_map = parse_unsynched_lyrics_comments(data, frame_id, total_offset, size, flags)
        parse_tags(data, total_offset + size, tags ++ [tag_map])

      # Parsing for all other frames
      true ->
        case String.first(frame_id) do
          # Text frames
          "T" ->
            << _ :: binary-size(total_offset),
              binary_value :: binary-size(size),
              _ :: binary >> = data
            tag_map = %{ id: frame_id, size: size, flags: flags, value: parse_string(binary_value) }
            IO.puts(inspect(tag_map))

            parse_tags(data, total_offset + size, tags ++ [tag_map])
          # URL frames
          # "W" ->
          _ -> tags
        end
    end
  end

  def parse_unsynched_lyrics_comments(data, frame_id, total_offset, size, flags) do
    << _ :: binary-size(total_offset),
      text_encoding :: integer,
      language :: binary-size(3),
      unicode_bom :: integer-unit(8)-size(2),
      descriptor :: binary-size(size),
      _ :: binary >> = data

    descriptor = parse_null_terminated_string_utf16le(descriptor)

    # Adjust offset for text encoding byte (1), language (3), Unicode BOM (2), and the descriptor's
    # null codepoint (2)
    total_offset_with_descriptor = total_offset + 1 + 3 + 2 + 2

    if String.length(descriptor) > 0 do
      # Takes into account that the descriptor is utf-16le
      total_offset_with_descriptor = total_offset_with_descriptor + (2 * String.length(descriptor))
    end

    content_size = (total_offset + size) - total_offset_with_descriptor

    << _ :: binary-size(total_offset_with_descriptor),
      content :: binary-size(content_size),
      _ :: binary >> = data

    tag_map = %{ id: frame_id, size: size, flags: flags, language: language, descriptor: descriptor }
    tag_map = Map.put(tag_map, if(frame_id == "COMM", do: :comments, else: :lyrics), parse_string(content))

    IO.puts(inspect(tag_map))

    tag_map
  end

  def parse_string(binary_value) do
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

  # TODO: These need to all be combined passing in the encoding type so we know how to binary match them
  def parse_null_terminated_string_utf8(<< codepoint :: utf8, rest :: binary>>, result \\ "") do
    if codepoint == 0 do
      result
    else
      parse_null_terminated_string_utf8(rest, << result :: binary, codepoint :: utf8 >>)
    end
  end

  def parse_null_terminated_string_utf16le(<< codepoint :: utf16-little, rest :: binary>>, result \\ "") do
    if codepoint == 0 do
      result
    else
      parse_null_terminated_string_utf16le(rest, << result :: binary, codepoint :: utf8 >>)
    end
  end

  # TODO: Implement this as a Protocol for each of the types
  def is_present(value) do
    cond do
      is_number(value) -> !value == 0
      # is_bitstring(value) -> String.length(value) > 0
      true -> is_nil(value)
    end
  end
end