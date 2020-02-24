require 'benchmark'

results = {}
(47..80).each_slice(2) do |slice|
  workers = slice.first
  results[workers] = Benchmark.realtime do
    system("ruby bin/mtg_cards.rb --disable-gc --workers=#{workers} > /dev/null")
  end
  sleep(60)
  #STDERR.puts "#{workers} => #{results[workers]}"
end

File.open('results.txt', 'w') do |f|
  results.each_pair do |workers, time|
    f.puts "#{workers} #{time.round(2)}"
  end
end

system('termgraph results.txt --width 120 --title "Workers pool size vs time"')
