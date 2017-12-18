#!/usr/bin/ruby

require 'csv'

`make`
if $?.success?
    CSV.open('results.csv', 'w') do |csv|
        csv << ["n", "p", "FW_single_tile_no_shared", "CFW_single_tile_no_shared", "LFW_single_tile_no_shared", "FW_single_tile_shared", "CFW_single_tile_shared", "LFW_single_tile_shared", "FW_two_tiles_shared", "CFW_two_tile_shared", "LFW_two_tiles_shared", "FW_four_tiles_shared", "CFW_four_tiles_shared", "LFW_four_tiles_shared", "Serial"]
        (7..12).each do |n|
            [0.33, 0.45, 0.67].each do |p|
                res = `/export/home/ioandima/apsp_coalesced/trunk/bin/apsp_coalesced #{n} #{p} 1`
                puts [n, p] + res.scan(/Clock time = (\d+.\d+)/i)
                csv << [n, p] + res.scan(/Clock time = (\d+.\d+)/i)
            end
        end
    end
end
