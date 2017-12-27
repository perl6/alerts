use lib <lib>;
use P6lert::Model::Alerts;

sub MAIN($alert, :$creator, :$affects, :$severity = 'normal', Bool :$public, :$db-file) {
    my $id = P6lert::Model::Alerts.new(
        |(:db-file($db-file.IO) with $db-file)
    ).add:
        $alert,
        |(:$creator  with $creator),
        |(:$affects  with $affects),
        |(:$severity with $severity),
        |(:time(time - 62*10) if $public);

    say "Added alert #$id";
}
