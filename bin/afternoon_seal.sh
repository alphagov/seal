#!/bin/bash

teams=(
  ewa_core
  plus_subscription
)

for team in ${teams[*]} ; do
  ./bin/seal.rb $team quotes
done
