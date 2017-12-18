#!/usr/bin/ruby

require 'csv'

regex =   /P = (\d+)\sN_Q = (\d+)\sN_C = \d+\snmk = 2\^(\d+)\sn, m, k: \d+, \d+, \d+\sTime elapsed: (\d+\.\d+)/

CSV.open('results.csv', 'w') do |csv|
  csv << ["P", "N", "nmk", "Time"]
  Dir.glob('./mpi-knn.o*').each do |file|
    dat = File.read(file)
    match = dat.scan(regex)
    match.each do |result|
      result[1] = Math.log2(result[1].to_f)
      csv << result
    end
  end
end
