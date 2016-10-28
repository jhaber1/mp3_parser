# Elixir mp3 parser (WIP)

Parses an mp3 and returns the id3v2 frames in a nicely-formatted map. Still very rough and only supports the most basic frames.

Current example output:
```
%{flags: 0, id: "TIT2", size: 23, value: "Devastator"}
%{flags: 0, id: "TPE1", size: 25, value: "Angel Sword"}
%{flags: 0, id: "TRCK", size: 5, value: "1"}
%{flags: 0, id: "TALB", size: 47, value: "Rebels Beyond the Pale"}
%{description: "cover", flags: 0, id: "APIC", mime_type: "image/jpeg", picture_type: "Cover (front)", size: 157854}
%{descriptor: "None", flags: 0, id: "USLT", language: "eng", lyrics: "Electric guitars  \r\nRip out your heart\r\nShow you no mercy\r\n\r\nThe drums kick your chest\r\nThe bass line possessed\r\nA fire still burns me\r\n\r\nIt's madness that made us\r\nWe're masters of chaos\r\nFull speed or faster\r\n\r\nThere is no forgiving\r\nOur souls overdriven\t\r\nA running disaster\r\n\r\nThere's a thunder inside me\r\nAnd it won't let go\r\nA man made of lightning\r\nI gotta let it show\r\n\r\nThere's a thunder inside me\r\nAnd it won't let go\r\nA man made of lightning\r\nDevastator of souls", size: 964}
%{comments: "Visit http://angelsword.bandcamp.com", descriptor: "", flags: 0, id: "COMM", language: "eng", size: 82}
%{flags: 0, id: "TPE2", size: 25, value: "Angel Sword"}
%{flags: 0, id: "WCOM", size: 22, url: "https://www.google.com"}
%{description: "User-defined URL frame", flags: 0, id: "WXXX", size: 73, url: "https://www.bandcamp.com"}
%{flags: 0, id: "TYER", size: 5, value: "2016"}
%{flags: [unsynchronisation: false, extended_header: false, experimental_indicator: false], id: "ID3", size: 614400, tags: [%{flags: 0, id: "TIT2", size: 23, value: "Devastator"}, %{flags: 0, id: "TPE1", size: 25, value: "Angel Sword"}, %{flags: 0, id: "TRCK", size: 5, value: "1"}, %{flags: 0, id: "TALB", size: 47, value: "Rebels Beyond the Pale"}, %{description: "cover", flags: 0, id: "APIC", mime_type: "image/jpeg", picture_type: "Cover (front)", size: 157854}, %{descriptor: "None", flags: 0, id: "USLT", language: "eng", lyrics: "Electric guitars  \r\nRip out your heart\r\nShow you no mercy\r\n\r\nThe drums kick your chest\r\nThe bass line possessed\r\nA fire still burns me\r\n\r\nIt's madness that made us\r\nWe're masters of chaos\r\nFull speed or faster\r\n\r\nThere is no forgiving\r\nOur souls overdriven\t\r\nA running disaster\r\n\r\nThere's a thunder inside me\r\nAnd it won't let go\r\nA man made of lightning\r\nI gotta let it show\r\n\r\nThere's a thunder inside me\r\nAnd it won't let go\r\nA man made of lightning\r\nDevastator of souls", size: 964}, %{comments: "Visit http://angelsword.bandcamp.com", descriptor: "", flags: 0, id: "COMM", language: "eng", size: 82}, %{flags: 0, id: "TPE2", size: 25, value: "Angel Sword"}, %{flags: 0, id: "WCOM", size: 22, url: "https://www.google.com"}, %{description: "User-defined URL frame", flags: 0, id: "WXXX", size: 73, url: "https://www.bandcamp.com"}, %{flags: 0, id: "TYER", size: 5, value: "2016"}], version: "v2.3.0"}
```

## TODO
 - Parsing the rest of the frames
 - id3v1 parsing
 - id3v2.2/id3v2.4 parsing
 - Better output
 - Refactoring
 - Tests

Shout-out to https://github.com/aadsm/jsmediatags for inspiration