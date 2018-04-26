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

## Usage

Add TipBot to your Telegram group. It *must* be supergroup and bot must have privacy mode disabled.

TipBot supports following commands:
* `/tip` - reply to any message in your chat. This will display keyboard and current tip stats.
* `/balance` - this will show your tip balance (works in DM only).
* `/withdraw <address>` - this will send your collected tips to following Stellar address. All following tips will be send directly there, bypassing TipBot account (works in DM only).

## Planned features

* Using accounts provided by users to send tips.
* Slack support.
* Custom Stellar assets.
* Dynamical change of tip rate using special command.
