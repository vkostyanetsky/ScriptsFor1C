# Поиск в строке идентификаторов вида "254:815f0050569f40c911ea4fd69331c424".
# Опция -o заставит egrep вывести только то, что отвечает регулярке.
#
cat test.log | egrep -o "[0-9]+:[a-z0-9]{32}" |

# Удаление дублей, способ 1: каждый GUID передается в ассоциативный массив как ключ элемента.
#
# awk '{guids[$1]}END{for (guid in guids) print guid}' > UniqueGUIDs.txt

# Удаление дублей, способ 2: сортировка строк и выборка уникальных.
#
sort | uniq > UniqueGUIDs.txt