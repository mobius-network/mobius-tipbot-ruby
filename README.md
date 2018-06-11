Mobius TipBot
=============

Easily transfer small amount of MOBI between team members of your Telegram group.

## Installation

1. Setup Stellar accounts.

   TipBot needs two accounts:

   * Source pool containing tips to be spent.
   * TipBot account holding tips awaiting for withdrawal.

   TipBot account must be added as cosigner to source pool. It must be able to make payments from source address.

   You can setup test network accounts using `mobius-cli` tool from [mobius-client-ruby](https://github.com/mobius-network/mobius-client-ruby) or [Stellar Laboratory](https://stellar.org/laboratory).

2. Setup Telegram bot.

   * Obtain token using BotFather.
   * Setup Redis and get credentials.
   * Deploy it somewhere (take a look on [sample K8s deployment](deploy/deployment.yaml), and [Dockerfile](Dockerfile))

   Environment variables are:

   * `MOBIUS_TIPBOT_REDIS_URL` - Redis URL
   * `MOBIUS_TIPBOT_TOKEN` - Telegram token.
   * `MOBIUS_TIPBOT_CREDIT_ADDRESS` - Stellar address of source pool.
   * `MOBIUS_TIPBOT_APP_PRIVATE_KEY` - Private key of TipBot account.
   * `MOBIUS_TIPBOT_RATE` - Tip amount.
   * `MOBIUS_TIPBOT_NETWORK` - "public" or "test", Stellar network to use.
   * `MOBIUS_TIPBOT_ASSET_CODE` - custom Stellar asset for tips. Should be in Alphanumeric 4-character maximum format. Default is MOBI.
   * `MOBIUS_TIPBOT_ASSET_ISSUER` - custom Stellar asset issuer address

   **Note** `MOBIUS_TIPBOT_ASSET_CODE` and `MOBIUS_TIPBOT_ASSET_ISSUER` should be provided together. Otherwise defaults will be used silently.

## Usage

Add TipBot to your Telegram group. It *must* be supergroup and bot must have privacy mode disabled.

TipBot supports following commands:
* `/tip <amount>` - reply to any message in your chat. This will display keyboard and current tip stats.
* `/balance` - this will show your tip balance (works in DM only).
* `/withdraw <address> <amount>` - this will send <amount> of your collected tips to following Stellar address. If <amount> is omitted, all of your tips will be withdrawn. Works in DM only.
* `/create <funding_address> <amount>` - create and fund your own Tipping Account to send tips from (no more 1 tip per hour limit!). `<funding_address>` - is your current Stellar account that will be used fund your Tipping Account. `<amount>` - the amount that Tipping Account will be funded with 
*`/unregister <withdraw_address>` - unregister your Tipping Account and withdraw your funds. You will revert to tipping from the default pool and be limited to 1 tip per hour  `<withdraw_address>` - Stellar address where your funds will be withdrawn to and Tipping Account will be merged into
* `/my_address` - returns your deposit address, that was created after `/create` command invocation, so you will be
  able to fund it any way convenient to you

### Using custom Stellar assets

TipBot allows you to use custom Stellar asset instead of MOBI for tips. To achieve this set env variables `MOBIUS_TIPBOT_ASSET_CODE` and `MOBIUS_TIPBOT_ASSET_ISSUER`, and don't forget to create trustlines for your asset in source pool account and TipBot account

## Developing

1. Rename `.env.example` to `.env` and fill it out with your settings
1. Set env variable `MOBIUS_TIPBOT_ENVIRONMENT` to "development"
1. Launch `bin/telegram` to start polling for updates

```
export MOBIUS_TIPBOT_ENVIRONMENT=development
bin/telegram

# or

MOBIUS_TIPBOT_ENVIRONMENT=development bin/telegram
```

## Deploy

Just press this button for deploying app into Heroku

[![Deploy](https://www.herokucdn.com/deploy/button.svg)](https://heroku.com/deploy?template=https://github.com/mobius-network/mobius-tipbot-ruby)

Then fill in the config variables and click "Deploy for Free" button.

## Planned features

* Using accounts provided by users to send tips.
* Slack support.
* Dynamical change of tip rate using special command.
