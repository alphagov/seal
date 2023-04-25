#!/bin/bash

teams=(
  govuk-accounts
  govuk-platform-security-reliability
)

for team in ${teams[*]} ; do
  ./bin/seal.rb $team quotes
done
