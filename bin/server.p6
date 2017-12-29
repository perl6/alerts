use lib <lib>;
use Cro::HTTP::Router;
use Cro::HTTP::Server;
use HTML::Escape;
use JSON::Fast;
use P6lert::Model::Alerts;

my $SITE-HOST = 'https://alerts.perl6.org/';
my $Alerts := P6lert::Model::Alerts.new;
my &H := &escape-html;

sub MAIN (Str:D :$host = '0.0.0.0', UInt:D :$port = 10000) {
    my $application = route {
        get -> {
            content 'text/html', html-render-alerts $Alerts.public
        }
        get -> 'alert', UInt $id {
            content 'text/html', html-render-alerts $Alerts.get: $id
        }


        get -> $ where <feed  atom  rss>.any {
            content 'application/xml', rss-render-alerts $Alerts.public
        };


        get -> 'api', 'v1', 'all' {
            header 'Access-Control-Allow-Origin', '*';
            content 'application/json', to-json {
                alerts => $Alerts.public».TO-JSON,
            };
        }
        get -> 'api', 'v1', 'last', UInt $last where * < 1_000_000 { # arbitrary upper limit
            header 'Access-Control-Allow-Origin', '*';
            content 'application/json', to-json {
                alerts => $Alerts.last($last)».TO-JSON,
            };
        }
        get -> 'api', 'v1', 'since', UInt $since {
            header 'Access-Control-Allow-Origin', '*';
            content 'application/json', to-json {
                alerts => $Alerts.since($since)».TO-JSON,
            };
        }
        get -> 'api', 'v1', 'alert', UInt $id {
            header 'Access-Control-Allow-Origin', '*';
            if $Alerts.get: $id -> $alert {
                content 'application/json', to-json %(
                    alert => $alert.TO-JSON
                )
            } else { not-found }
        }

        my subset TemplateContent of Str where * ∈ <
            api
        >;
        get -> TemplateContent $file {
            content 'text/html', html-render-template $file
        }

        my subset StaticContent of Str where * ∈ <
            main.css  widget.js  feed-pic.png  chat.svg
            rss.svg   api.svg    twitter.svg   camelia.svg
        >;
        get -> StaticContent $file { static "static/$file" }
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

sub rss-render-alerts(*@alerts) {
    q:to/✎✎✎✎✎/
    <?xml version="1.0" encoding="UTF-8"?><rss version="2.0"
      xmlns:content="http://purl.org/rss/1.0/modules/content/"
      xmlns:wfw="http://wellformedweb.org/CommentAPI/"
      xmlns:dc="http://purl.org/dc/elements/1.1/"
      xmlns:atom="http://www.w3.org/2005/Atom"
      xmlns:sy="http://purl.org/rss/1.0/modules/syndication/"
      xmlns:slash="http://purl.org/rss/1.0/modules/slash/"
      xmlns:georss="http://www.georss.org/georss" xmlns:geo="http://www.w3.org/2003/01/geo/wgs84_pos#" xmlns:media="http://search.yahoo.com/mrss/"
      >
      <channel>
      	<title>Perl 6 Alerts</title>
      	<atom:link href="\qq[$SITE-HOST]feed/" rel="self" type="application/rss+xml" />
      	<link>\qq[$SITE-HOST]</link>
      	<description>Alerts from Rakudo Perl 6 Core Developers</description>
      	<lastBuildDate>\qq[@alerts.head.time-rss()]</lastBuildDate>
      	<language>en</language>
          <image>
      		<url>\qq[$SITE-HOST]feed-pic.png</url>
      		<title>Perl 6 Alerts</title>
      		<link>\qq[$SITE-HOST]</link>
      	</image>
    ✎✎✎✎✎
    ~ @alerts.map(-> $a {
          q:to/✎✎✎✎✎/
          	<item>
          		<title><![CDATA[\qq[&H($a.alert-short)]]]></title>
          		<link>\qq[$SITE-HOST]alert/\qq[$a.id()]</link>
          		<pubDate>\qq[$a.time-rss()]</pubDate>
          		<guid isPermaLink="true">\qq[$SITE-HOST]alert/\qq[$a.id()]</guid>
          		<description><![CDATA[
                  <h2><a href="\qq[$SITE-HOST]alert/\qq[$a.id()]">#\qq[$a.id()]</a>
                    <span class="sep">|</span>
                      <span class="time">\qq[$a.time-human()]</span>
                    <span class="sep">|</span>
                      severity: <span class="severity">\qq[$a.severity()]</span>
                    \qq[{
                        '<span class="sep">|</span>
                        affects: <span class="affects">\qq[&H($a.affects)]</span>'
                        if $a.affects
                    }]
                    <span class="sep">|</span>
                      posted by <span class="creator">\qq[&H($a.creator)]</span>
                  </h2>
                  \qq[&H($a.alert)]
              ]]></description>
          	</item>
          ✎✎✎✎✎
      })
      ~ '</channel></rss>'
}

sub html-render-template($file) {
    state %templates;
    html-layout-default
        %templates{$file} //= 'templates'.IO.add("$file.html").slurp
          .subst(:g, '::SITE-HOST::', $SITE-HOST)
          .subst: :g, /'::ESCAPE_HTML[::' (.+?) '::]ESCAPE_HTML::'/,
              *.[0].Str.&escape-html
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
                    affects: <span class="affects">\qq[&H($a.affects)]</span>'
                  if $a.affects
              }]
              <span class="sep">|</span>
                posted by <span class="creator">\qq[&H($a.creator)]</span>
            </h2>

            <p>\qq[&H($a.alert)]</p>
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
            width=25 height=25 title="Perl 6"></a>
          <a href="/" title="Perl 6 Alerts Home">Perl 6 Alerts</a>
          <a href="/rss"><img src="/rss.svg" alt="RSS" width=25 height=25
            title="RSS Feed"></a>
          <a href="https://twitter.com/p6lert"
            ><img src="/twitter.svg" alt="Twitter" width=25 height=25
            title="Follow Perl 6 Alerts on Twitter"></a>
          <a href="/api"><img src="/api.svg" alt="API" width=25 height=25
            title="API documentation"></a>
          <a href="https://webchat.freenode.net/?channels=#perl6-dev"
            ><img src="/chat.svg" alt="Chat with us" width=25 height=25
            title="Chat with us"></a
          ><small>keeping up to date with important changes</small></h1>
        \qq[$content]
        <footer>
          <small><a href="/api">API</a> |
            <a href="https://webchat.freenode.net/?channels=#perl6-dev"
            >💬 Chat with us</a> |
            <a href="http://mi.cro.services">Powered by Cro</a> | Code for this website is
            available at <a href="https://github.com/perl6/alerts"
            >github.com/perl6/alerts</a></small>
        </footer>
      </div>
    </body>
    </html>
    ✎✎✎✎✎
}
