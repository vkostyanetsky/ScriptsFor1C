# Топ ожиданий на блокировках на базе событий TLOCK.
#
# Блокировки группируются по области; для каждой выводится общее время ожидания, среднее время ожидания
# и количество установок. Сортировка — по общему времени ожидания.

# Управляемые блокировки возникают только на rphost'ах.
#
cat rphost_*/*.log |

# Фильтруем TLOCK'и, у которых заполнено свойство WaitConnections (т.е. платформа реально ждала возможности установить
# управляемую блокировку, а не просто потратила какое-то время на её создание).
#
grep -E ',TLOCK,.*WaitConnections=[0-9]+' |

# Вырезаем из информации о событии все данные, кроме его продолжительности и областей.
#
sed -r 's/.*-([0-9]+),TLOCK,.*Regions=(.*),Locks=.*/\1 \2/' |

# Если областей несколько — они будут заключены в одинарные кавычки. Удалим кавычки.
#
sed -r "s/'(.*)'/\1/" |

# Группируем продолжительность по области, считаем среднюю продолжительность и количество блокировок.
#
gawk '{

    DurationByRegions[$2] += $1;
    QuantityByRegions[$2] += 1;    

}; END {

    for (Regions in DurationByRegions) {
    
        totalQuantity   = QuantityByRegions[Regions];
        totalDuration   = DurationByRegions[Regions] / 1000000;
        averageDuration = DurationByRegions[Regions] / QuantityByRegions[Regions] / 1000000;
    
        printf "%.3f seconds total, %.3f seconds on average, %d locks: %s\n", totalDuration, averageDuration, totalQuantity, Regions;
    
    }

}' |

# Сортируем по общей продолжительности и выводим первые сто результатов.
#
sort -rn |
head -n 100 > TopTLOCKRegions.txt