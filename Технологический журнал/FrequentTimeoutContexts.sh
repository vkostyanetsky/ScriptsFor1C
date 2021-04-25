cat rphost_*/*.log |

# Удаляем из потока данных UTF-8 BOM.
#
perl -pe 's/\xef\xbb\xbf//g' |

# Утилита gawk разделяет лог по метке времени события и выполняет переданный ей скрипт.
#
gawk -F'Context=' -vRS='[0-9]+:[0-9]+.[0-9]+-[0-9]+,' '
{
    # Отбираем только события TTIMEOUT.
    #    
    if ( $0 ~ "^TTIMEOUT.*" ) {
    
        Context = $2;
        
        gsub("\n", "<LF>", Context); 
    
        Timeouts[Context] += 1;        
        
    }
};

END {

    for (Context in Timeouts) {            
        print Timeouts[Context] " timeouts <LF>" Context;        
    }
    
}
' |

sort -rn |
head -n 1000 |

# Мы заменяли переводы строк на подстроку <LF>, чтобы результат можно было отсортировать (sort) и усечь (head).
# Теперь можно сделать обратную замену — тогда результат будет удобнее читать.
#
sed -r "s/<LF>/\n/g" > FrequentTimeoutContexts.txt