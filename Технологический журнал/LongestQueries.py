# Скрипт извлекает события DBMSSQL из ТЖ 1С и группирует их запросу и контексту.
#
# Тексты запросов нормализуются: параметры удаляются, имена временные таблицы заменяются на #tt.
# Для каждого уникального запроса выводится количество выполнений, суммарная и средняя длительность
# и максимальная продолжительность одного запроса.
#
# Во время работы скрипт выводит путь к обрабатываемому в данный момент файлу, его объём
# и общий прогресс выполнения (сколько файлов обработано из общего количества).
#
# После завершения работы скрипт выводит время в секундах, затраченное на анализ.

import os
import re
import glob
import time

from pathlib import Path

def get_log_filenames():

    script_dirname = os.path.dirname(__file__)
    script_dirpath = os.path.abspath(script_dirname)
    
    path_template = os.path.join(script_dirpath, 'rphost_*', '*.log')
    log_filenames = glob.iglob(path_template, recursive = True)

    return list(log_filenames)

def print_information():

    def get_log_file_size():

        stat_result = Path(log_filename).stat()

        size_in_bytes       = stat_result.st_size
        size_in_megabytes   = size_in_bytes / 1024 / 1024

        return size_in_megabytes

    log_file_size = get_log_file_size()
    
    print('%s (%.3f MB), %d / %d' % (log_filename, log_file_size, current_log_number, log_filenames_number))
    print('%d unique queries collected' % len(queries))
    print()

def extract_log_file_queries():

    def process_event_lines():
               
        duration = int(event_lines[0].split('-')[1].split(',')[0])
        
        sql = "".join(event_lines)
        sql = re.sub('.*,Sql=', 'Sql=', sql)
        sql = sql.strip()
        
        if queries.get(sql) == None:

            queries[sql] = {
                'counter':          0,
                'total_duration':   0,
                'max_duration':     0,
            }
                    
        sql_stat = queries[sql]
               
        sql_stat['total_duration']  = sql_stat['total_duration'] + duration        
        sql_stat['counter']         = sql_stat['counter'] + 1
                
        if duration > sql_stat['max_duration']:
            sql_stat['max_duration'] = duration
                                        
        queries[sql] = sql_stat        
                    
    def is_event_first_line():
        
        result = re.match('[0-9]{2}:[0-9]{2}.[0-9]+-[0-9]+,[A-Z]+,', line)
        
        return result != None        

    def get_event_name():
        
        return line.split(',')[1]
        
    def add_event_line():
        
        result = re.match('p_[0-9]+:.*', line)
        
        if result == None:
    
            new_line = re.sub('#tt[0-9]+', '#tt', line)
    
            event_lines.append(new_line)
        
    log_file    = open(log_filename, 'r', encoding = 'utf-8-sig')
    event_lines = []
        
    while True:
    
        line = log_file.readline()
    
        if not line:
            break

        if is_event_first_line():
        
            if len(event_lines) > 0:
                process_event_lines()                
        
            event_lines = []
        
            if get_event_name() == 'DBMSSQL':
                add_event_line()
                               
        elif len(event_lines) > 0:       
            add_event_line()

    if len(event_lines) > 0:
        process_event_lines()
        
    log_file.close()

def sort_and_write_queries():

    sorted_queries  = sorted(queries.items(), key = lambda kv: kv[1]['total_duration'], reverse = True)
    output_file     = open('LongestQueries.txt', 'w', encoding = 'utf-8-sig')

    for sorted_query in sorted_queries:

        sql         = sorted_query[0].strip()
        duration    = sorted_query[1]['total_duration'] / 1000000
        
        max_duration    = sorted_query[1]['max_duration'] / 1000000
        repetition      = sorted_query[1]['counter']
        avg_duration    = sorted_query[1]['total_duration'] / repetition / 1000000

        line = "\n\n--- %d queries with %.3f total duration (max duration: %.3f, avg duration: %.3f) ---\n\n%s" % (repetition, duration, max_duration, avg_duration, sql)
        output_file.write(line)

    output_file.close()

def print_running_time():

    seconds = time.time() - start_time
    
    print("--- %.3f seconds ---" % seconds)

start_time  = time.time()    
queries     = {}

log_filenames = get_log_filenames()

log_filenames_number    = len(log_filenames)
current_log_number      = 0

for log_filename in log_filenames:

    current_log_number += 1

    print_information()
    extract_log_file_queries()
            
sort_and_write_queries()

print_running_time()