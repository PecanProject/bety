#!/usr/bin/ruby

zoom_max = ARGV[0] || nil
extension = ARGV[1] || "png"
zoom_max.nil? ? zoom_max = 0 : zoom_max = zoom_max.to_i
p "Max Zoom: #{zoom_max}"
p "Extension: #{extension}"

0.upto(zoom_max) do |zoom|
  0.upto((2**zoom)-1) do |x|
    0.upto((2**zoom)-1) do |y|
      #cmd = "curl http://ebi-forecast.igb.uiuc.edu/bety/maps/mapoverlay/miscanthus/#{x}-#{y}-#{zoom}.#{extension} > /dev/null 2>&1"
      cmd = "ruby /rails/ebi/local/fix_long_render.rb #{x} #{y} #{zoom}"
      t = Time.now
      system( cmd )
      p "#{x}-#{y}-#{zoom}: #{(Time.now-t).to_f}" 
    end
  end
end
