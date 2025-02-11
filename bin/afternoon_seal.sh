#!/bin/bash

teams=(
  ewa_core
  ewa_progression
)

for team in ${teams[*]} ; do
  ./bin/seal.rb $team quotes
done
