unit class P6lert::Alert;
use Subset::Helper;
use DateTime::Format;

subset Severity of Str where subset-is * ∈ <info  low  normal  high  critical>,
    'Invalid alert severity value. Must be one of <info  low  normal  high  critical>';

has UInt:D     $.id       is required;
has Str:D      $.alert    is required;
has UInt:D     $.time     is required;
has Str:D      $.creator  is required;
has Str:D      $.affects  is required;
has Severity:D $.severity is required;
has Bool:D     $.tweeted  is required;

method new { $_ = ?$_  with %_<tweeted>; self.bless: |%_ }

method time-human {
    DateTime.new($!time).Date
}
method time-rss {
    strftime '%a, %d %b %Y %H:%M:%S %z', DateTime.new: $!time
}

method alert-short {
    $!alert.chars > 60 ?? $!alert.substr(0, 60) ~ ' […]' !! $!alert;
}

method TO-JSON { self.Capture.Hash<id  alert  time  creator  affects  severity>:p.Hash }
