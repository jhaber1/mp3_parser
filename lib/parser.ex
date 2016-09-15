require IEx;

defmodule Parser do
  @path '/Users/jhaber/Downloads/Angel Sword - Rebels Beyond the Pale/Angel Sword - Rebels Beyond the Pale - 01 Devastator.mp3'

  def parse(path \\ @path) do
    data = File.read!(path)

    offset = 10
    # offset = offset + 10

    header = parse_tag_header(data)
    IO.puts(inspect(header))

    << _ :: binary-size(10),
      frame_id :: binary-size(4),
      size :: integer-unit(8)-size(4),
      # TODO: Unparsed flags
      _ :: integer-size(16),
      binary_value :: binary-size(size),
      _ :: binary >> = data

      # TODO: Code here to figure out how to parse the binary_value based on frame_id (?)

      IO.puts(inspect(%{ frame_id: frame_id, size: size, binary_value: parse_string(binary_value) }))
  end

  # Currently only assumes v2.3
  defp parse_tag_header(data) do
    << identifier :: binary-size(3),
      # Version
      minor_version :: integer,
      revision_number :: integer,
      # TODO: Unparsed flags byte
      _ :: integer,
      size :: integer-unit(8)-size(4),
      _ :: binary >> = data

    %{ id: identifier, minor_version: minor_version, revision_number: revision_number, size: size }
  end

  defp parse_frame do
    
  end

  def parse_string(binary_value \\ <<1, 255, 254, 68, 0, 101, 0, 118, 0, 97, 0, 115, 0, 116, 0, 97, 0, 116, 0, 111, 0, 114, 0, 0, 0>>) do
    # Take apart the string, figure out what encoding to use, figure out endianness
    # TODO: encoding == 0: iso-8859-1,
    # TODO: encoding == 2: utf-16be
    # TODO: encoding == 3: utf-8
    << encoding :: integer-size(8),
       unicode_bom :: integer-unit(8)-size(2),
       string :: binary >> = binary_value

    # TODO: Not entirely happy with this, seems hacky -- revisit in future once more Elixir knowledge is accumulated
    frame_value = Enum.reduce(String.codepoints(string), "", fn(codepoint, result) ->
      << parsed :: 8 >> = codepoint
      if parsed == 0, do: result, else: result <> <<parsed>>
    end)
  end
  
end