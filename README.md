# Seal


This is a Slack bot that publishes a team's pull requests, Dependabot updates, security alerts, and inspirational quotes to their Slack Channel.

![image](https://github.com/alphagov/seal/blob/main/images/readme/informative.png)
![image](https://github.com/alphagov/seal/blob/main/images/readme/angry.png)

## How to use it?

Add your team's configuration to [config/alphagov.yml](https://github.com/alphagov/seal/blob/main/config/alphagov.yml). The process is slightly different depending on whether or not your team is part of GOV.UK.

### GOV.UK teams

Include your team's name and the Slack channel you want to post to. These *must match the team name and Slack channel* specified in the [Developer Docs](https://docs.publishing.service.gov.uk/repos.html#repos-by-team). Do not add a list of repos, they will be pulled from the developer docs automatically. Private repos are not currently supported.

> The [Developer docs repos.json](https://docs.publishing.service.gov.uk/repos.json) is now the single source of truth for information about GOV.UK repositories and which team is responsible for them.

### Other teams

Include your team's name, Slack channel and a list of repos you want to be notified about. Private repos are not currently supported.

### Slack alerts

To customize which alerts your team channel gets, find your team in [config/alphagov.yml](https://github.com/alphagov/seal/blob/main/config/alphagov.yml) and set the following values to `true` or `false`:

- morning_seal_quotes: Morning quotes set by your team
- afternoon_seal_quotes: Afternoon quotes set by your team
- seal_prs: Morning alerts about old and recent pull requests by team members
- dependapanda: Morning alerts about Dependabot pull requests
- security_alerts: Security alerts (only available to teams receiving Dependabot alerts)

### Local testing

To test the script, create a private Slack channel e.g. "#angry-seal-bot-test-abc" and update `@team_channel` on [this line in slack_poster.rb](https://github.com/alphagov/seal/blob/main/lib/slack_poster.rb#L103) to the one you created, you'll also need a `DEVELOPMENT` env set to `true`.
You can then run the [GitHub Action](https://github.com/alphagov/seal/actions) selecting your branch and you should see the post in your test channel.

If you don't want to post to Slack you can add a `DRY: true` env to your workflow and the output will only show in the logs.

### Slack configuration

<details><summary>You should also set up the following custom emojis in Slack:</summary>

- :informative_seal:
- :angrier_seal:
- :seal_of_approval:
- :happyseal:
- :halloween_informative_seal:
- :halloween_angrier_seal:
- :halloween_seal_of_approval:
- :festive_season_informative_seal:
- :festive_season_angrier_seal:
- :festive_season_seal_of_approval:
- :manatea:
</details>
You can use the images in images/emojis that have the corresponding names.

## How to run the tests?

Just run `bundle exec rspec` in the command line.

## Licence

[MIT License](LICENCE)
