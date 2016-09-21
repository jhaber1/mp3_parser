require IEx;

defmodule Parser do
  @path '/Users/jhaber/Downloads/Angel Sword - Rebels Beyond the Pale/Angel Sword - Rebels Beyond the Pale - 01 Devastator.mp3'
  @picture_types []

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
        s = size - total_offset - 1

        



        # TODO: Need to learn how to terminate a string when there's a null byte
        << _ :: binary-size(total_offset),
          text_encoding :: integer-size(8),
          mime_type :: binary-size(s),
          _ :: binary >> = data
        IO.puts("MIME type: #{inspect(parse_null_terminated_string(String.codepoints(mime_type)))}")
    end

    

    
  end

  def parse_frame(data, offset) do
    << _ :: binary-size(offset),
      frame_id :: binary-size(4),
      size :: integer-unit(8)-size(4),
      # TODO: Unparsed flags
      _ :: integer-size(16),
      binary_value :: binary-size(size),
      _ :: binary >> = data
  end

  def parse_string(binary_value \\ <<1, 255, 254, 68, 0, 101, 0, 118, 0, 97, 0, 115, 0, 116, 0, 97, 0, 116, 0, 111, 0, 114, 0, 0, 0>>) do
    # Take apart the string, figure out what text_encoding to use, figure out endianness
    # TODO: text_encoding == 0: iso-8859-1,
    # TODO: text_encoding == 2: utf-16be
    # TODO: text_encoding == 3: utf-8
    << text_encoding :: integer-size(8),
       unicode_bom :: integer-unit(8)-size(2),
       string :: binary >> = binary_value

    # TODO: Not entirely happy with this, seems hacky -- revisit in future once more Elixir knowledge is accumulated
    # 
    frame_value = Enum.reduce(String.codepoints(string), "", fn(codepoint, result) ->
      << parsed :: integer >> = codepoint
      if parsed == 0, do: result, else: result <> <<parsed>>
    end)
  end

  def parse_null_terminated_string([head | tail], result \\ "") do
    << parsed :: integer >> = head
    if parsed == 0, do: result, else: parse_null_terminated_string(tail , result <> <<parsed>>)
  end
end