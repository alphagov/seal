#!/bin/bash

teams=(
  govuk-accounts
  govuk-platform-security-reliability
)

for team in ${teams[*]} ; do
  ./bin/seal_runner.rb $team quotes
done
