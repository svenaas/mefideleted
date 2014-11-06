## MeFi Deleted

A simple Twitter bot written to tweet MetaFilter post deletion reasons at @mefideleted

This bot was written to run at Heroku and may be used as a simple example or starting point for other projects.

## Requirements for Deploying Something Like This

1) Twitter account

2) Twitter application

3) Twitter application keys

4) Heroku account

### Twitter Account

You'll probaby want a new Twitter account for your bot.

### Twitter Application

Log into Twitter using the account that the bot will use. Then sign into https://dev.twitter.com/ and then register your new Twitter appication at https://apps.twitter.com/.

**Note:** If your bot is going to post then you're going to need to give your application write access to the Twitter account, and as of this writing (2014) Twitter won't let you do this unless your Twitter account has a mobile phone number associated with it. Twitter furthermore won't let you associate a mobile phone number that's already associated with another Twitter account. Catch-22! Fortunately, you can request write access via http://support.twitter.com/ — do this from your bot's Twitter account, but tell them who you really are and let them know you're not to anything underhanded.

### Twitter Application keys

You'll find the keys `CONSUMER_KEY` and `CONSUMER_SECRET` in the "Keys and Access Tokens" tab of your app's page at https://apps.twitter.com/. The other two keys you need, `OAUTH_TOKEN` and `OAUTH_TOKEN_SECRET`, won't get generated until you set the necessary privilige level for your app and press the "Create my access token" button at the bottom of the "Keys and Access Tokens" tab.

### Heroku Account

In my use this application does not require more than a free tier of service from Heroku or associated service providers, but your use may differ. 

Show what the library does as concisely as possible, developers should be able to figure out **how** your project solves their problem by looking at the code example. Make sure the API you are showing off is obvious, and that your code is short and concise.

## Motivation

[TODO]

## Deployment

After you've created your application in Heroku you'll need to add Heroku as a Git remote from your working directory: 

     heroku git:remote -a mefideleted

If you need Heroku addons you can add them at this time as well: 

    heroku addons:add scheduler

    heroku addons:add redistogo

In order to authenticate and post to Twitter this app needs to present several keys. Rather than store them in the code (which would be insecure) this app is written to depend on finding these keys as the server environment variables `CONSUMER_KEY`, `CONSUMER_SECRET`, `OAUTH_TOKEN`, and `OAUTH_TOKEN_SECRET`. You'll find the values of these keys at https://apps.twitter.com/ for your particular application. You set them in Heroku like this:

    heroku config:set CONSUMER_KEY=[your key value]

## References

[TODO]

## License

[TODO]