#!/bin/bash

teams=(
  ewa_core
)

for team in ${teams[*]} ; do
  ./bin/seal.rb $team quotes
done
