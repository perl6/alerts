document.write('<div id="p6lert"></div>');
(function () {
  var host = 'https://alerts.perl6.org/';
  var ajax = new XMLHttpRequest();
  ajax.open('GET', host + 'api/v1/last/10', true);
  ajax.onreadystatechange = function() {
      if (ajax.readyState == 4 && ajax.status == 200) {
          var alerts = JSON.parse(ajax.responseText);

          var p6lert = document.getElementById('p6lert');
            p6lert.style = 'border: 1px solid #ccc; border-radius: 4px;'
              + ' display: inline-block; padding: 5px; max-width: 800px';
          var p6lerts_a = document.createElement('a');
            p6lerts_a.style = 'color: #333';
            p6lerts_a.href = host;
            p6lerts_a.textContent = 'Perl 6 Alerts';
          var title = document.createElement('p');
            title.style = 'font-weight: bold; margin: 0;';
            title.appendChild(document.createTextNode('Latest '));
            title.appendChild(p6lerts_a);
            p6lert.appendChild(title);

          var container = document.createElement('ul');
            container.style = 'margin: 0; padding: 0; list-style: none;';
            p6lert.appendChild(container);

          for (var i = 0, l = alerts.alerts.length; i < l; i++) {
              var alert = alerts.alerts[i];
              var li = document.createElement('li');

              var info_bar = document.createElement('span');
                info_bar.className = 'p6lert-info-bar';
                info_bar.style = 'font-size: 90%;';

              var a = document.createElement('a');
                a.style = 'color: gray';
                a.textContent = '#' + alert.id;
                a.href = host + 'alert/' + alert.id;
                info_bar.appendChild(a);

              info_bar.appendChild(document.createTextNode(' '));
              var severity = document.createElement('span');
                severity.className = 'p6lert-severity-' + alert.severity;
                severity.textContent = alert.severity;
                severity.style = 'color: ' + (alert.severity == 'info'
                  ? 'blue' : alert.severity == 'critical'
                    ? 'red' : '#333')
                + (alert.severity == 'normal' ? '; display: none;' : '');
                info_bar.appendChild(severity);

              var severity_label = document.createElement('span');
                severity_label.textContent = 'severity: ';
                severity_label.style = 'display: none;';
                severity.prepend(severity_label);

              if (alert.affects.length) {
                  info_bar.appendChild(document.createTextNode(' '));
                  var affects = document.createElement('span');
                    affects.className = 'p6lert-affects';
                    affects.textContent = alert.affects;
                    affects.style = 'font-style: italic;';
                    info_bar.appendChild(affects);

                  var affects_label = document.createElement('span');
                    affects_label.textContent = 'affects: ';
                    affects.prepend(affects_label);
              }

              li.appendChild(info_bar);
              li.appendChild(document.createTextNode(' '));
              var alert_text = document.createElement('p');
                alert_text.textContent = alert.alert;
                alert_text.style = 'display: inline-block; margin: 2px;';
                li.appendChild(alert_text);

              container.appendChild(li);
          }

      }
  }
  ajax.send();
}());
