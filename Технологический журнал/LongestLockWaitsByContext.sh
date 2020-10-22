# Топ ожиданий на блокировках на базе событий TLOCK.
#
# Блокировки группируются по контексту; для каждой выводится общее время ожидания, среднее время ожидания
# и количество установок. Сортировка — по общему времени ожидания.

# Управляемые блокировки возникают только на rphost'ах.
#
cat rphost_*/*.log |

gawk -F',Context=' -vRS='[0-9]+:[0-9]+.[0-9]+-' '{

    # Фильтруем TLOCK, у которых заполнено свойство WaitConnections (т.е. платформа реально ждала
    # возможности установить управляемую блокировку, а не просто потратила время на её создание).
    
    if ( $0 ~ ".*,TLOCK,.*WaitConnections=[0-9]+.*" ) {

        # Мы разделили события по времени начала, так что продолжительность — это строка до запятой.
        #
        Duration = substr($0, 0, index($0, ",") - 1);

        # Заменим переводы строк на макрос, чтобы впоследствии утилиты sort и head отработали верно.
        #
        gsub("\n", "<LF>", $2);

        DurationByContext[$2]   += Duration;
        LocksByContexts[$2]     += 1;

    }
    
}; END {

    for (Context in DurationByContext) {

        TotalLocks      = LocksByContexts[Context];
        TotalDuration   = DurationByContext[Context] / 1000000;
        AverageDuration = DurationByContext[Context] / LocksByContexts[Context] / 1000000;

        printf "%.3f seconds total, %.3f seconds on average, %d locks:<LF>%s\n", TotalDuration, AverageDuration, TotalLocks, Context;
    }

}' |

sort -rn |

head -n 100 |

sed -r "s/<LF>/\n/g" > TopTLOCKContext.txt