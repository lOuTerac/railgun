require File.expand_path('railgun.rb')

TARGET_SPEED = 5 * SONIC
$lines = []

def calculate_range(mach_number)
  gun_speed = SONIC * mach_number
  railgun = Railgun.new gun_speed, TARGET_SPEED, silence: true
  puts "炮口初速：#{mach_number} 马赫"
  range = railgun.range
  report = "炮口初速：#{mach_number} 马赫 => 有效射程：#{range} 米"
  puts report
  $lines << report
end

def record_result
  file = "railgun_test_result_#{Time.now}.txt"
  File.open(file, 'w') do |f|
    $lines.each{|line| f.puts(line)}
    $lines = []
  end
end

(1..10).to_a.concat([12, 14, 16, 18, 20]).each do |i|
  mach_number = 10.0 * i
  calculate_range(mach_number)
end

record_result
