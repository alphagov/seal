#!/bin/bash

teams=(
  govuk-accounts
  govuk-platform-reliability
)

for team in ${teams[*]} ; do
  ./bin/seal.rb $team quotes
done
