#!/bin/env bash

# clear; 

# cat output.md |                                   \
grep 'INFO - position: Position'                  \
| tr --delete "'"                                 \
| sed                                             \
-e 's/- INFO - position: Position(account=//g'    \
-e 's/, contract=Stock(conId=[0-9]*,/ /g'  \
-e 's/, exchange='[A-Z]*', currency='[A-Z]*',//g'  \
-e 's/ localSymbol=[A-Z]*,/ /g'  \
-e 's/ tradingClass=[^,]*,/ /g'  \
| printf '%-20s |\n' $(cat -)                        \
| nl                                              \
| grep -e 'avgCost=' -e '$'                       \
;

# | grep --invert-match                             \
# -e 'contract=Stock(conId='                        \
# -e 'exchange='                                    \

# | grep -e NMS -e '$' \
# | wc                                            \
# -e 'position: '                                 \
# | cut -c-80                                     \

