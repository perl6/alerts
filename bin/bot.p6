use lib <lib>;
use IRC::Client;
use P6lert;
use JSON::Fast;
my %conf := from-json slurp 'secret.json';

my SetHash $admin-list   .= new: |%conf<admin-list>;
subset AdminMessage where {.host ∈ $admin-list};
my $alert-re = rx:i/
    [ 'severity:' $<severity>=\S+ \s+]?
    [ 'affects:[' $<affects>=<-[\]]>+ ']' \s+]?
    $<alert>=.+
/;

.run with IRC::Client.new:
    :nick<p6lert>,
    :username<p6lert-zofbot>,
    :host(%*ENV<P6LERT_IRC_HOST> // 'irc.freenode.net'),
    :channels(
        %*ENV<P6LERT_DEBUG> ?? '#zofbot' !! |<#perl6 #perl6-dev  #moarvm  #zofbot  #perl6-toolchain>
    ),
    :debug,
    plugins =>
class P6Lert::IRC::Plugin {
    has P6lert:D $!alerter = P6lert.new:
        |(:alert-url<http://localhost:10000/alert> if %*ENV<P6LERT_DEBUG>),
        |(:60public-delay if %*ENV<P6LERT_DEBUG>);

    submethod TWEAK { $!alerter.retweet }

    multi method irc-to-me ($ where /^ \s* 'help' \s* '?'? \s* $/) {
        ｢https://github.com/perl6/alerts P6lert commands: [insta]?add ALERT, update ID ALERT, ｣
        ~ ｢delete ID; ALERT format: ['severity:'\S+]? ['affects:['<-[\]]>+']']? ALERT_TEXT｣
    }
    multi method irc-to-me(AdminMessage $e where
      rx:i/^\s* [$<insta>=insta]? add \s+ $<alert>=<$alert-re>/
    ) {
        my $id = try $!alerter.add: ~$<alert><alert>, :tweet, :creator($e.nick.subst: /'_'+ $/, ''),
                    |(:affects(~$_)  with $<alert><affects> ),
                    |(:severity(~$_) with $<alert><severity>),
                    |(:time(time - 62*10) if $<insta>);
        $id ?? "Added alert ID $id: $!alerter.alert-url()/$id"
            !! "Error: $!";
    }
    multi method irc-to-me(AdminMessage $e where
      rx:i/^\s* update \s+ $<id>=\d+ \s+ $<alert>=<$alert-re>/
    ) {
        my $alert = $!alerter.get: +$<id> or return "No alert with ID $<id>";
        (try $!alerter.update:
            +$<id>, ~$<alert><alert>, :tweet, :creator($e.nick.subst: /'_'+ $/, ''),
                    |(:affects(~$_)  with $<alert><affects> ),
                    |(:severity(~$_) with $<alert><severity>)
        ) or return "Error: $!";
        "Updated alert ID $alert.id(): $!alerter.alert-url()/$alert.id()"
            ~ (" Note: this alert was already tweeted pre-update" if $alert.tweeted);
    }
    multi method irc-to-me(AdminMessage $ where rx:i/^\s* delete \s+ $<id>=\d+ \s* $/) {
        my $alert = $!alerter.get: +$<id> or return "No alert with ID $<id>";
        (try $!alerter.delete: $alert.id) or return "Error: $!";
        "Deleted alert ID $<id>" ~ (" Note: this already was already tweeted." if $alert.tweeted);
    }
}.new;
