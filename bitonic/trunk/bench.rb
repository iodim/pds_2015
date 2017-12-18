#!/usr/bin/ruby

require 'csv'

`make`
if $?.success?
    CSV.open('results.csv', 'w') do |csv|
        csv << ["Size", "Threads", "ImpBitSerial", "RecBitSerial", "Qsort", "Pthreads", "OMP", "Cilk"]
        (16..24).each do |s|
            (1..8).each do |p|
                times = Array.new(6, 100.0)
                10.times do
                    res = `/export/home/ioandima/trunk-gcc/bin/main #{s} #{p}`.split(/\r?\n/)
                    res.each_with_index do |r, i|
                        t = r.scan(/(\d+.\d+)/)
                        times[i] = [t[0][0].to_f, times[i]].min
                    end
                end
                puts [s, 2**p] + times
                csv << [s, 2**p] + times
            end
        end
    end
end
