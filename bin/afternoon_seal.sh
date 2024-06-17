#!/bin/bash

teams=(
  cash_advance
  plus_subscription
)

for team in ${teams[*]} ; do
  ./bin/seal.rb $team quotes
done
