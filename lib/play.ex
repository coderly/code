defmodule Play do
  @points [%{"end" => 14000, "message" => "And when the introduction keeps playing",
  "start" => 11000},
%{"end" => 18000,
  "message" => "We go to the second transition of the introduction",
  "start" => 14000},
%{"end" => 22000, "message" => "We switch to the design section",
  "start" => 18000},
%{"end" => 26000, "message" => "And the design section will show a picture",
  "start" => 22000},
%{"end" => 30000,
  "message" => "When I say the next word, we switch to the second picture",
  "start" => 26000},
%{"end" => 34000, "message" => "And then the third picture", "start" => 30000},
%{"end" => 37000, "message" => "Then we switch to the architectural section",
  "start" => 34000},
%{"end" => 41000, "message" => "And you see a picture", "start" => 37000},
%{"end" => 45000,
  "message" => "And you talk a little bit more and there is a blog post",
  "start" => 41000},
%{"end" => 53000,
  "message" => "If you scroll down to the blog post it pauses what I say",
  "start" => 46000},
%{"end" => 60000,
  "message" => "Now that you scroll back up, I resume, and we keep talking",
  "start" => 54000},
%{"end" => 61000, "message" => "And we go to the roadmap section",
  "start" => 60000},
%{"end" => 66000,
  "message" => "We're going through a little bit of a demo about the app model",
  "start" => 62000},
%{"end" => 69000, "message" => "There's some fancy animation",
  "start" => 66000},
%{"end" => 73000, "message" => "Talking about investors and paid users",
  "start" => 69000},
%{"end" => 78000,
  "message" => "What happens when all of this goes horribly wrong",
  "start" => 73000}]

  def run(base) do
    origin(@points, base)
    |> Enum.map(&Poison.encode!/1)
    |> Enum.each(&IO.puts/1)
  end

  def origin(points, origin) do
    Enum.map(points, fn %{"start" => vstart, "end" => vend}=row ->
      %{row | "start" => vstart - origin, "end" => vend - origin}
    end)
  end
end