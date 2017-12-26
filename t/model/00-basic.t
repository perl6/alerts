use lib <lib>;
use Testo;

plan 21;

use Temp::Path;
use P6lert::Model::Alerts;

my $public-delay := 4;
my $db-file := make-temp-path.extension: 'sqlite', :parts(0..*);
my $alerts  := P6lert::Model::Alerts.new: :$db-file, :$public-delay;
is $alerts, P6lert::Model::Alerts, '.new constructs right object';
is $db-file, *.e, ".new creates db file $db-file";

is (my $id = $alerts.add: 'test♥1'), UInt:D, ｢.add returns new alert's ID｣;
is $alerts.public, 0, '.public gives 0 alerts';
is $alerts.all, 1, 'have total 1 alert in db';
group '.all.head object' => 7 => {
    with $alerts.all.head -> \a {
        is a,           P6lert::Alert,  'righ type';
        is a.id,        $id,            '.id';
        is a.alert,     'test♥1',       '.alert';
        is a.time,      /^\d**9..11$/,  '.time looks approximately right';
        is a.creator,   'Anonymous',    '.creator';
        is a.severity,  'normal',       '.severity';
        is a.affects,   '',             '.affects';
    }
}

is $alerts.delete($id), *, 'deleting alert';
is $alerts.all, 0, 'no alerts in db any more';
is $alerts.public, 0, '.public still gives 0 alerts';

is $alerts.add('test♥2'), UInt:D, ｢re-added first message｣;
is $alerts.add(
  'meow2', :creator<Zof>, :affects('2017.12 and earlier'), :severity<critical>,
), UInt:D, ｢added second message｣;
is $alerts.all, 2, 'two messages in db';
is $alerts.public, 0, '.public still gives 0 alerts';

group 'first message' => 7 => {
    with $alerts.all.head -> \a {
        is a,           P6lert::Alert,  'righ type';
        is a.id,        2,              '.id';
        is a.alert,     'test♥2',       '.alert';
        is a.time,      /^\d**9..11$/,  '.time looks approximately right';
        is a.creator,   'Anonymous',    '.creator';
        is a.severity,  'normal',       '.severity';
        is a.affects,   '',             '.affects';
    }
}

group 'second message' => 7 => {
    with $alerts.all.tail -> \a {
        is a,           P6lert::Alert,  'righ type';
        is a.id,        3,              '.id';
        is a.alert,     'meow2',        '.alert';
        is a.time,      /^\d**9..11$/,  '.time looks approximately right';
        is a.creator,   'Zof',          '.creator';
        is a.severity,  'critical',      '.severity';
        is a.affects,   '2017.12 and earlier',  '.affects';
    }
}

is *, *, 'waiting for public delay expire';
sleep $public-delay+1;

is $alerts.add('unpublic'), UInt:D, ｢added third, not-yet public message｣;
is $alerts.all,    3, 'have 3 total alerts in db';
is $alerts.public, 2, 'have 2 total public alerts in db';

group 'first public message' => 7 => {
    with $alerts.public.head -> \a {
        is a,           P6lert::Alert,  'righ type';
        is a.id,        2,              '.id';
        is a.alert,     'test♥2',       '.alert';
        is a.time,      /^\d**9..11$/,  '.time looks approximately right';
        is a.creator,   'Anonymous',    '.creator';
        is a.severity,  'normal',       '.severity';
        is a.affects,   '',             '.affects';
    }
}

group 'second public message' => 7 => {
    with $alerts.public.tail -> \a {
        is a,           P6lert::Alert,  'righ type';
        is a.id,        3,              '.id';
        is a.alert,     'meow2',        '.alert';
        is a.time,      /^\d**9..11$/,  '.time looks approximately right';
        is a.creator,   'Zof',          '.creator';
        is a.severity,  'critical',      '.severity';
        is a.affects,   '2017.12 and earlier',  '.affects';
    }
}
