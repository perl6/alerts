unit class P6lert::Model::Alerts;
use DBIish;
use P6lert::Alert;

has IO::Path:D $.db-file = 'alerts.sqlite.db'.IO;
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
            time      INTEGER NOT NULL
        );
    ｣;
}
method DESTROY { $!dbh.dispose }

method add (
    Str:D  $alert,
    Str:D :$creator = 'Anonymous',
    Str:D :$affects = '',
    P6lert::Alert::Severity:D :$severity = 'normal'
) {
    given $!dbh.prepare: ｢
        INSERT INTO alerts (alert, severity, affects, creator, time)
            VALUES(?, ?, ?, ?, ?)
    ｣ {
        LEAVE .finish;
        .execute: $alert, $severity, $affects, $creator, time;
    }

    given $!dbh.prepare: ｢SELECT last_insert_rowid()｣ {
        LEAVE .finish;
        .execute;
        .row.head.Int
    }
}

method all {
    given $!dbh.prepare: ｢SELECT * FROM alerts ORDER BY time DESC｣ {
        LEAVE .finish;
        .execute;
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
