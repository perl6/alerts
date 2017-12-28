use OO::Monitors;
unit monitor P6lert;
use JSON::Fast;
use P6lert::Alert;
use P6lert::Model::Alerts;
use Twitter;

has IO::Path:D $.db-file = 'alerts.sqlite.db'.IO;
has UInt $.public-delay;
has P6lert::Model::Alerts:D $.alerts handles <get update delete>
    = P6lert::Model::Alerts.new: :$!db-file, |(:$!public-delay with $!public-delay);

has Str:D $.alert-url = 'https://alerts.perl6.org/alert';
has Str:D $.consumer-key        is required;
has Str:D $.consumer-secret     is required;
has Str:D $.access-token        is required;
has Str:D $.access-token-secret is required;
has Twitter:D $!twitter = Twitter.new: :$!consumer-key, :$!consumer-secret,
                                       :$!access-token, :$!access-token-secret;

my @PROMS;
END {
    if @PROMS {
        say "Awating Tweet promises";
        await @PROMS
    }
};

method retweet {
    # tweet out now-public alerts and re-schedule to-be public alerts
    start {
        for $!alerts.public.grep: *.tweeted.not {
            say "Retweeting ID {.id}";
            self!tweet: .id;
            sleep 2; # throttle tweets
        }
        # public ones now got tweeted; schedule tweets of everything that remains
        for $!alerts.all.grep: *.tweeted.not -> $alert {
            say "Re-scheduling tweet for ID {$alert.id}";
            Promise.at($alert.time+3).then: { self!tweet: $alert.id };
        }
        CATCH { default { ".retweet: ERROR: $_".say } }
    }
}

method new {
    my %conf := from-json slurp $*PROGRAM.sibling: '../secret.json';
    %_{$_} //= %conf{$_} for <consumer-key  consumer-secret  access-token  access-token-secret>;
    %_<db-file> //= .IO with %conf<db-file>;
    self.bless: |%_
}

method add (
    Str:D  $alert-text,
    Str:D :$creator = 'Anonymous',
    Str:D :$affects = '',
    P6lert::Alert::Severity:D :$severity = 'normal',
    UInt:D :$time = time,
    Bool:D :$tweet = False,
) {
    my $id := $!alerts.add: $alert-text, :$creator, :$affects, :$severity, :$time;
    $tweet and @PROMS.push: Promise.at($time + $!alerts.public-delay + 3).then: { self!tweet: $id }
    $id
}

method !tweet($id) {
    my $alert := $!alerts.get: $id;
    return if not $alert or $alert.tweeted;

    my $icon  := $alert.severity eq 'critical' ?? '⚠️' !! '';
    my $info  := "#p6lert ID $alert.id() | severity: $icon$alert.severity()$icon {
        "| affects: $alert.affects()" if $alert.affects
    } | posted by $alert.creator()\n\n";
    $!twitter.tweet: $info ~ (
        ($info ~ $alert.alert).chars < 280 ?? $alert.alert
            !! "$alert.alert-short() See: $!alert-url/$alert.id()"
    );
    $!alerts.update: $alert.id, :tweeted;
    self!clean-proms;
}

method !clean-proms {
    # ensure we remove already-kept promises from the list
    @PROMS .= grep: !*
}
