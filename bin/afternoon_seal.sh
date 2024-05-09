#!/bin/bash

teams=(
  cash_advance
)

for team in ${teams[*]} ; do
  ./bin/seal.rb $team quotes
done
