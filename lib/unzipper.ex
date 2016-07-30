require IEx;

defmodule Unzipper do
  def start do
    :fs.start_link(:watcher, "/Users/jhaber/Music")
    :fs.subscribe(:watcher)
    watch   
  end

  # handles only [created, modified, removed, renamed, undefined] (all the supported events of inotify-win)
  defp watch do
    receive do
      {_watcher_process, {:fs, :file_event}, {changed_file, type}} ->
        if to_string(changed_file) =~ ~r/\.(zip|rar|7z)$/i do
          IEx.pry



          
          :zip.unzip(changed_file)
        else
          watch
        end

        
        #IO.puts("#{changed_file} was updated with #{Enum.join(type,", ")}")
        watch
      end
  end        
end
