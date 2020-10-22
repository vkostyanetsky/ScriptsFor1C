# Топ длительных транзакций на базе события SDBL.
# 
# Выводятся транзакции, которые шли дольше 20 секунд (это время ожидания возможности установления блокировки
# по умолчанию). Для каждой выводится сначала продолжительность в секундах, потом — текст события.

cat rphost_*/*.log |

# Заменяем первый дефис (отделяющий время начала события от его длительности) на запятую. Тогда, если задать запятую
# как разделитель полей, можно будет выделить продолжительность события без дополнительных ухищрений: и до, и после
# значения продолжительности будет запятая.
#
sed -r 's/-/,/' |

gawk -F',' '{

    # Проверяем, что событие — SDBL + в нем есть указатель на завершение или откат транзакции + оно шло от 20 секунд.
    #    
    if ($0 ~ ".*,SDBL,.*Func=(Commit|Rollback)Transaction.*" && $2 >= 20000000)
    {
        printf "%.3f %s\n", $2 / 1000000, $0
    }

}' |

sort -rn |
head -n 100 > TopTransactions.txt