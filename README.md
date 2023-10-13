# Seal

## What is it?

This is a Slack bot that publishes a team's pull requests, Dependabot updates, security alerts, and inspirational quotes to their Slack Channel. Once provided with the organization name, team names, and respective repositories, it posts messages as various animal characters such as the Seal and Dependapanda.

![image](https://github.com/alphagov/seal/blob/main/images/readme/informative.png)
![image](https://github.com/alphagov/seal/blob/main/images/readme/angry.png)

## How to use it?

### Config

Fork the repo and add/change the config files that relate to your github organisation. For example, the alphagov config file is located at [config/alphagov.yml](config/alphagov.yml) and the config for scheduled daily visits can be found in [.github/workflows](.github/workflows)

Include your team's name, repos and the Slack channel you want to post to.

> If your team is part of the GOV.UK programme, you do not need to add a list of repos to config/alphagov.yml.
> The [Developer docs repos.json](https://docs.publishing.service.gov.uk/repos.json) is now the single source of truth for information about GOV.UK repositories and which team is responsible for them.

In your shell profile, put in:

```sh
export SEAL_ORGANISATION="your_github_organisation"
export GITHUB_TOKEN="get_your_github_token_from_yourgithub_settings"
export SLACK_WEBHOOK="get_your_incoming_webhook_link_for_your_slack_group_channel"
export GITHUB_API_ENDPOINT="your_github_api_endpoint" # OPTIONAL If you are using a Github Enterprise instance
```

### Env variables

```sh
export SEAL_ORGANISATION="your_github_organisation"
export GITHUB_TOKEN="get_your_github_token_from_yourgithub_settings"
export GITHUB_API_ENDPOINT="your_github_api_endpoint" # OPTIONAL If you are using a Github Enterprise instance
export SLACK_WEBHOOK="get_your_incoming_webhook_link_for_your_slack_group_channel"
export SLACK_CHANNEL="#whatever-channel-you-prefer"
export GITHUB_USE_LABELS=true
export GITHUB_SECURITY_ALERTS=true
export GITHUB_EXCLUDE_LABELS="[DO NOT MERGE],Don't merge,DO NOT MERGE,Waiting on factcheck,wip"
export GITHUB_REPOS="myapp,anotherrepo" # Repos you want to be notified about
export COMPACT=true # Use a more compact version of the seal output
export SEAL_QUOTES="Everyone should have the opportunity to learn. Don't be afraid to pick up stories on things you don't understand and ask for help with them.,Try to pair when possible."
```

- To get a new `GITHUB_TOKEN`, head to: https://github.com/settings/tokens
- To get a new `SLACK_WEBHOOK`, head to: https://slack.com/services/new/incoming-webhook

### GitHub Actions

This repository now utilizes GitHub Actions for automated Slack notifications. The workflows are defined in the `.github/workflows` directory and perform various tasks at different times of the day:

- [Morning Seal](https://github.com/alphagov/seal/blob/main/.github/workflows/morning_seal.yml): Runs the Seal bot in the morning, posting about old and recent pull requests by team members and also quotes.
- [Afternoon Seal](https://github.com/alphagov/seal/blob/main/.github/workflows/afternoon_seal.yml): Runs the Seal bot in the afternoon, posting quotes.
- [Dependapanda](https://github.com/alphagov/seal/blob/main/.github/workflows/dependapanda.yml): Runs the Dependapanda bot in the morning, posting about Dependabot pull requests and security information.

The Morning Seal and Dependapanda workflows run every weekday morning, while the Afternoon Seal workflow runs every weekday afternoon.

To customize which bots post to your team channel, add or remove your team name in the workflows above. The team name should correspond to a key in [config/alphagov.yml](https://github.com/alphagov/seal/blob/main/config/alphagov.yml), which should have a `channel` property denoting the name of your team's Slack channel.

The `channel` property should match a channel name in the [list of repos by ownership in the Developer Docs](https://docs.publishing.service.gov.uk/repos.html#repos-by-team), otherwise Dependapanda won't know which repos to notify your channel about.

### Local testing

To test the script, create a private Slack channel e.g. "#angry-seal-bot-test-abc" and update `@team_channel` on [this line in slack_poster.rb](https://github.com/alphagov/seal/blob/main/lib/slack_poster.rb#L103) to the one you created, you'll also need a `DEVELOPMENT` env set to `true`.
You can then run the [GitHub Action](https://github.com/alphagov/seal/actions) selecting your branch and you should see the post in your test channel.

If you don't want to post to Slack you can add a `DRY: true` env to your workflow and the output will only show in the logs.

### Slack configuration

You should also set up the following custom emojis in Slack:

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

You can use the images in images/emojis that have the corresponding names.

## Deployment

All of the code runs in GitHub Actions and does not need deploying.

## How to run the tests?

Just run `bundle exec rspec` in the command line.

## Licence

[MIT License](LICENCE)