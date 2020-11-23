# Топ вызовов с максимальным расходом памяти в пике. Строится по событиям CALL (собираемые свойства — Context и MemoryPeak).

cat rphost_*/*.log |

# Удаляем из потока данных UTF-8 BOM.
#
sed -r "s/\xef\xbb\xbf//g" |

# Удаляем из потока данных UTF-8 BOM.
#
gawk -vRS="[0-9]+:[0-9]+.[0-9]+-[0-9]+," '{

    # Нас интересуют только вызовы с контекстом.
    #
    if ($0 ~ ".*Context=.*") {
    
        Line = $0
        
        gsub("\n", "<LF>", Line)        # Переводы строк помешают сортировке.        
        gsub("^.*,Context=", "", Line)  # Удалим ненужные данные.
        
        # Если разделить получившуюся строку по такой подстроке, то получится массив
        # из двух элементов: контекстом и значением пика по памяти.
        #
        split(Line, Data, ",MemoryPeak=")
        
        Context     = Data[1]
        MemoryPeak  = Data[2]
        
        Contexts[Context] += MemoryPeak
    
    }
    
}; END {

    for (Context in Contexts) {
        print Contexts[Context] " " Context
    }

}' |

sort -rn |
head -n 10 |

sed -r "s/<LF>/\n/g" > CallsTopByMemoryPeak.txt