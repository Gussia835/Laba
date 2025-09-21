require_relative 'lib/VoteCleaner'

cleaner = VoteCleaner::Cleaner.new('data/votes_2.txt')
cleaner.start