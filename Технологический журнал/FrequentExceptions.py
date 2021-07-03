import os
import re
import glob
import time

def get_descriptions():

    def is_event_first_line():
            
        result = re.match('[0-9]{2}:[0-9]{2}.[0-9]+-[0-9]+,.+,', line)
            
        return result != None

    def add_description(event_lines):

        if len(event_lines) > 0:
                
            event = "\n".join(event_lines)

            event_fields = event.split(',Descr=')

            if len(event_fields) == 2:                        
                description = event_fields[1]
            else:
                description = ''
                        
            if descriptions.get(description) == None:
                descriptions[description] = 0

            descriptions[description] = descriptions[description] + 1   

    script_dirname  = os.path.dirname(__file__)
    script_dirpath  = os.path.abspath(script_dirname)
    search_template = os.path.join(script_dirpath, '*', '*.log')

    log_filenames   = glob.iglob(search_template, recursive = True)
    descriptions    = {}

    for log_filename in log_filenames:
                                        
        log_file = open(log_filename, 'r', encoding = 'utf-8-sig')
        event_lines = []
            
        while True:
            
            line = log_file.readline()
        
            if not line:
                break

            if is_event_first_line():
                    
                add_description(event_lines)
                
                event_lines = []

                if line.find(',EXCP,') != -1:
                    event_lines.append(line)
                
            elif len(event_lines) > 0:
            
                event_lines.append(line)

        add_description(event_lines)

        log_file.close()
        
    return descriptions

def write_descriptions():

    sorted_keys = sorted(descriptions, key = descriptions.get, reverse = True) 
    output_file = open('FrequentExceptions.txt', 'w', encoding = 'utf-8-sig')

    for sorted_key in sorted_keys:

        description = sorted_key.strip()
        number      = descriptions[sorted_key]

        line = "\n\n{}\n\n{}".format(number, description)
        output_file.write(line)

    output_file.close()

start_time = time.time()

descriptions = get_descriptions()

write_descriptions()

seconds = time.time() - start_time

print("--- %s seconds ---" % seconds)