unit class P6lert::Model::Alerts;
use DBIish;
use P6lert::Alert;

has IO::Path:D $.db-file = 'alerts.sqlite.db'.IO;
has UInt $.public-delay  = 60*10; # delay before making messages public
has $!dbh;

submethod TWEAK {
    $!dbh = DBIish.connect: 'SQLite', :database($!db-file.absolute);
    $!dbh.do: ｢PRAGMA foreign_keys = ON｣;
    $!dbh.do: ｢
        CREATE TABLE IF NOT EXISTS alerts (
            id        INTEGER PRIMARY KEY AUTOINCREMENT,
            alert     TEXT NOT NULL DEFAULT '',
            severity  TEXT NOT NULL DEFAULT 'normal',
            affects   TEXT NOT NULL DEFAULT '',
            creator   TEXT NOT NULL DEFAULT 'Anonymous',
            time      INTEGER NOT NULL,
            tweeted   INTEGER NOT NULL DEFAULT 0
        );
    ｣;
}
method DESTROY { $!dbh.dispose }

method add (
    Str:D  $alert,
    Str:D :$creator = 'Anonymous',
    Str:D :$affects = '',
    P6lert::Alert::Severity:D :$severity = 'normal',
    UInt:D :$time = time,
    Bool:D :$tweeted = False,
) {
    given $!dbh.prepare: ｢
        INSERT INTO alerts (alert, severity, affects, creator, time, tweeted)
            VALUES(?, ?, ?, ?, ?, ?)
    ｣ {
        LEAVE .finish;
        .execute: $alert, $severity, $affects, $creator, $time, $tweeted;
    }

    given $!dbh.prepare: ｢SELECT last_insert_rowid()｣ {
        LEAVE .finish;
        .execute;
        .row.head.Int
    }
}

method append (UInt:D $id, Str $extra-text) {
    my $alert = self.get: $id or die "No alert with ID $id";
    $alert .= clone: :alert("$alert.alert() $extra-text");
    given $!dbh.prepare: ｢UPDATE alerts SET alert = ? WHERE id = ?｣ -> $sth {
        LEAVE $sth.finish;
        $sth.execute: .alert, .id with $alert;
    }
    $alert;
}

method update (UInt:D $id,
    Str  $alert-text?,
    Str :$creator,
    Str :$affects,
    P6lert::Alert::Severity :$severity,
    UInt :$time,
    Bool :$tweeted,
) {
    my $alert = self.get: $id or die "No alert with ID $id";

    my %values = $alert.Capture.Hash;
    %values<alert>    = $_ with $alert-text;
    %values<creator>  = $_ with $creator;
    %values<affects>  = $_ with $affects;
    %values<severity> = $_ with $severity;
    %values<time>     = $_ with $time;
    %values<tweeted>  = $_ with $tweeted;
    $alert .= clone: |%values;

    given $!dbh.prepare: ｢
        UPDATE alerts SET alert = ?, severity = ?, affects = ?, creator = ?, time = ?, tweeted = ?
            WHERE id = ?
    ｣ -> $sth {
        LEAVE $sth.finish;
        $sth.execute: .alert, .severity, .affects, .creator, .time, .tweeted, .id with $alert;
    }
    $alert
}

method all {
    given $!dbh.prepare: ｢SELECT * FROM alerts ORDER BY time DESC｣ {
        LEAVE .finish;
        .execute;
        eager .allrows(:array-of-hash).map: { P6lert::Alert.new: |$_ }
    }
}

method public {
    given $!dbh.prepare: ｢
        SELECT * FROM alerts WHERE time < ? ORDER BY time DESC
    ｣ {
        LEAVE .finish;
        .execute: time - $!public-delay;
        eager .allrows(:array-of-hash).map: { P6lert::Alert.new: |$_ }
    }
}

method last(UInt $last where * < 1_000_000) { # arbitrary upper limit
    given $!dbh.prepare: ｢
        SELECT * FROM alerts WHERE time < ? ORDER BY time DESC LIMIT ?
    ｣ {
        LEAVE .finish;
        .execute: time - $!public-delay, $last;
        eager .allrows(:array-of-hash).map: { P6lert::Alert.new: |$_ }
    }
}

method since (UInt:D $since) {
    given $!dbh.prepare: ｢
        SELECT * FROM alerts WHERE time > ? AND time < ? ORDER BY time DESC
    ｣ {
        LEAVE .finish;
        .execute: $since, time - $!public-delay;
        eager .allrows(:array-of-hash).map: { P6lert::Alert.new: |$_ }
    }
}

method get (UInt:D $id) {
    given $!dbh.prepare: ｢SELECT * FROM alerts where id = ?｣ {
        LEAVE .finish;
        .execute: $id;
        if .row: :hash { P6lert::Alert.new: |$^alert }
        else { Empty }
    }
}

method delete (UInt:D $id) {
    given $!dbh.prepare: ｢DELETE FROM alerts WHERE id = ?｣ {
        .execute: $id;
        .finish;
    }
}
