require_relative 'VoteCleaner'

# Чтение данных и запуск обработки
cleaner = VoteCleaner::Cleaner.new('data/votes_2.txt')
cleaner.analyze