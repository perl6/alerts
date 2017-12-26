use lib <lib>;
use Cro::HTTP::Router;
use Cro::HTTP::Server;
use JSON::Fast;
use P6lert::Model::Alerts;

my $Alerts := P6lert::Model::Alerts.new;

sub MAIN (Str:D :$host = 'localhost', UInt:D :$port = 10000) {
    my $application = route {
        get -> {
            content 'text/html', html-render-alerts $Alerts.all
        }
        get -> 'alert', UInt $id {
            content 'text/html', html-render-alerts $Alerts.get: $id
        }

        get -> 'api', 'v1', 'all' {
            content 'application/json', to-json {
                alerts => $Alerts.all».TO-JSON,
            };
        }

        get -> 'api', 'v1', 'alert', UInt $id {
            if $Alerts.get: $id -> $alert {
                content 'application/json', to-json %(
                    alert => $alert.TO-JSON
                )
            } else { not-found }
        }

        get -> 'main.css'    { static 'static/main.css'    }
        get -> 'rss.svg'     { static 'static/rss.svg'     }
        get -> 'api.svg'     { static 'static/api.svg'     }
        get -> 'twitter.svg' { static 'static/twitter.svg' }
        get -> 'camelia.svg' { static 'static/camelia.svg' }
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
            <h2 class="info"><a href="/alert/\qq[$a.id()]">#\qq[$a.id()]</a>
              <span class="sep">|</span>
                <span class="time">\qq[$a.time-human()]</span>
              <span class="sep">|</span>
                severity: <span class="severity">\qq[$a.severity()]</span>
              \qq[{
                  '<span class="sep">|</span>
                    affects: <span class="affects">\qq[$a.affects()]</span>'
                  if $a.affects
              }]
              <span class="sep">|</span>
                posted by <span class="creator">\qq[$a.creator()]</span>
            </h2>

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
      <div id="content">
        <h1>
          <a href="https://perl6.org/"><img src="/camelia.svg" alt="»ö«"
            width=25 height=25></a>
          <a href="/">Perl 6 Alerts</a>
          <a href="/rss"><img src="/rss.svg" alt="RSS" width=25 height=25></a>
          <a href="https://twitter.com/p6lert"
            ><img src="/twitter.svg" alt="Twitter" width=25 height=25></a>
          <a href="/api"
            ><img src="/api.svg" alt="API" width=25 height=25></a
          ><small>keeping up to date with important changes</small></h1>
        \qq[$content]
        <footer>
          <small>Code for this website is available at
          <a href="https://github.com/perl6/alerts">github.com/perl6/alerts</a>
        </footer>
      </div>
    </body>
    </html>
    ✎✎✎✎✎
}
