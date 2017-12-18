#!/usr/bin/ruby

require 'csv'

`make`
if $?.success?
    CSV.open('results.csv', 'w') do |csv|
        csv << ["n", "p", "Method_1", "Method_2", "Method_3", "Method_4", "Serial"]
        (7..12).each do |n|
            [0.33, 0.45, 0.67].each do |p|
                res = `/export/home/ioandima/apsp/bin/apsp #{n} #{p} 1`
                puts [n, p] + res.scan(/Clock time = (\d+.\d+)/i)
                csv << [n, p] + res.scan(/Clock time = (\d+.\d+)/i)
            end
        end
    end
end
