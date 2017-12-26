use lib <lib>;
use Cro::HTTP::Router;
use Cro::HTTP::Server;
use P6lert::Model::Alerts;

my $Alerts := P6lert::Model::Alerts.new;
# my $CSS := $*PROGRAM.sibling('../assets/main.css').absolute;

sub MAIN (Str:D :$host = 'localhost', UInt:D :$port = 10000) {
    my $application = route {
        get -> {
            content 'text/html', html-render-alerts $Alerts.all
        }
        get -> 'alert', Int $id {
            content 'text/html', html-render-alerts $Alerts.get: $id
        }
        get -> 'main.css' { static 'static/main.css' }#$CSS }
    }

    with Cro::HTTP::Server.new: :$host, :$port, :$application {
        $^server.start;
        say "Started server http://$host:$port";
        react whenever signal SIGINT {
            $server.stop;
            exit;
        }
    }
}

sub html-render-alerts(*@alerts) {
    html-layout-default '<ul id="alerts">'
      ~ @alerts.map(-> $a {
          q:to/✎✎✎✎✎/;
          <li class="alert alert-\qq[$a.severity()]">
            <p class="info"><a href="/alert/\qq[$a.id()]">#\qq[$a.id()]</a>
              | \qq[$a.time-human()]
              | posted by \qq[$a.creator()]
              | severity: \qq[$a.severity()]
              \qq[{"| affects: $a.affects()" if $a.affects}]

            <p>\qq[$a.alert()]</p>
          </li>
          ✎✎✎✎✎
      }) ~ '</ul>'
}

sub html-layout-default (Str:D $content) {
    q:to/✎✎✎✎✎/;
    <!DOCTYPE html>
    <html lang="en">
    <head>
      <meta charset="utf-8">
      <meta http-equiv="X-UA-Compatible" content="IE=edge">
      <meta name="viewport" content="width=device-width, initial-scale=1">

      <title>Perl 6 Alerts</title>
      <link rel="stylesheet" href="/main.css">
    </head>
    <body>
      <h1>Perl 6 Alerts</h1>
      <div id="content">
        \qq[$content]
      </div>
      <footer>
        <small>Code for this website is available at
        <a href="https://github.com/perl6/alerts">github.com/perl6/alerts</a>
      </footer>
    </body>
    </html>
    ✎✎✎✎✎
}
