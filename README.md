# alerts

Code for alerts.perl6.org and supporting IRC bot

## POSTING ALERTS

The alerts are posted by addressing the `p6lert` bot. Four commands exist

### `add`

Adds a new alert, using your IRC for `created by` information.
The bot will give a direct link to it on the site. While
the direct link will show the alert right away, **it'll take 10 minutes** for
the alert to show up on the main site's page, on its API endpoints, or to be
tweeted. This is by-design, to allow for some editing or deleting of the alert,
if needed.

```
<Zoffix> p6lert, add some normal alert
<Zoffix> p6lert, add severity:high some high alert
<Zoffix> p6lert, add affects:[2017.12 and earlier] some normal alert
<Zoffix> p6lert, add severity:high affects:[2017.12 and earlier] some high alert
```

The brackets for `affects` are mandatory and `severity` must come before
`affects`. Both are optional and `severity` defaults to `normal`, while
`affects` defaults to an empty string. If you need a reminder, you can always
issue `help` command to the bot:

```
<Zoffix> p6lert: help
<p6lert> Zoffix, https://github.com/perl6/alerts P6lert commands:
    [insta]?add ALERT, update ID ALERT, delete ID;
    ALERT format: ['severity:'\S+]? ['affects:['<-[\]]>+']']? ALERT_TEXT
```

### `instadd`

Exactly the same as `add` command, except it does not have a 10-minute grace
period and the alert will be distributed and tweeted immediately. This exists
mostly for debugging and you should always use the `add` command.

```
<Zoffix> p6lert, instaadd some normal alert
```

### `update`

Syntax is the same as `add`, except it takes an alert ID as the first argument.
Updates the alert content. **Note** that omitting `severity` or `affects`
**WILL NOT** set them to default values and will leave them as they were
before the update.

```
<Zoffix> p6lert, update 5 severity:high actually, it's now a high alert
```

The bot will tell you if this alert was already tweeted.

### `delete`

Takes an alert ID as the argument and deletes it from the database.
The bot will tell you if this alert was already tweeted. The tweet will NOT
be deleted by the bot.

```
<Zoffix> p6lert, delete 5
```

###

## DEVELOPMENT

### Website styles

The styles are in `static/main.scss`. You'll need to run `./sassify` to
have [SASS preprocessor](http://sass-lang.com/) watch for changes and
generate CSS styles for the site.

### IRC Bot Admins

Admins are allowed to post/update/delete alerts. Their hosts are stored in
`/home/p6lert/alerts/secret.json`, in `admin-list` property. When adding new
hosts, please only add registered Freenode users (those who have a
[cloak](https://freenode.net/kb/answer/cloaks) are even better, since we can
see to whom the host belongs)

### Infrastructure

The server and bot are hosted on hack with Apache on www server reverse-proxying
all the requests. The repo checkout lives in
`/home/p6lert/alerts/` and two services exist: `p6lert-web` and `p6lert-irc`

To pull new changes, log in to hack, then run:

```bash
sudo su -l p6lert
cd alerts/
git pull
logout
sudo service p6lert-web restart
sudo service p6lert-irc restart
```

The alerts database is in `/home/p6lert/alerts/alerts.sqlite.db` SQLite file.

Zoffix has the keys to `@p6lert` Twitter account.

----

#### REPOSITORY

Fork this module on GitHub:
https://github.com/perl6/alerts

#### BUGS

To report bugs or request features, please use
https://github.com/perl6/alerts

#### AUTHOR

Zoffix Znet (http://perl6.party/)

#### LICENSE

You can use and distribute this module under the terms of the
The Artistic License 2.0. See the `LICENSE` file included in this
distribution for complete details.

The `META6.json` file of this distribution may be distributed and modified
without restrictions or attribution.
