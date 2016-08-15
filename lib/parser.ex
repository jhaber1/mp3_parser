defmodule Parser do
  @path '/Users/jhaber/Downloads/Angel Sword - Rebels Beyond the Pale/Angel Sword - Rebels Beyond the Pale - 01 Devastator.mp3'

  def parse(path \\ @path) do
    data = File.read!(path)

    offset = 0

    # mp3_header = binary_part(data, 0, 10)
    # offset = offset + 10
    header = parse_tag_header(data)
    IO.puts(inspect(header))
  end

  # Currently only assumes v2.3
  defp parse_tag_header(data) do
    << identifier :: binary-size(3),
      minor_version :: integer,
      revision_number :: integer,
      unsynched :: integer-size(1),
      _ :: binary >> = data

    %{ id: identifier, minor_version: minor_version, revision_number: revision_number, unsynched: unsynched }
  end
  
end