use lib <lib>;
use P6lert;

sub MAIN(
    $alert,
    :$creator, :$affects, :$severity = 'normal',
    Bool :$public, Bool :$tweet, :$db-file
) {
    my $id = P6lert.new(
        |(:db-file($db-file.IO) with $db-file)
    ).add:
        $alert,
        |(:$creator  with $creator),
        |(:$affects  with $affects),
        |(:$severity with $severity),
        |(:$tweet    with $tweet),
        |(:time(time - 62*10) if $public);

    say "Added alert #$id";
}
