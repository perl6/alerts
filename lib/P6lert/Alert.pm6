unit class P6lert::Alert;
use Subset::Helper;

subset Severity of Str where subset-is * ∈ <info  normal  critical>,
    'Invalid alert severity value. Must be one of <info  normal  critical>';

has UInt:D     $.id       is required;
has Str:D      $.alert    is required;
has UInt:D     $.time     is required;
has Str:D      $.creator  is required;
has Str:D      $.affects  is required;
has Severity:D $.severity is required;

method time-human {
    DateTime.new: $!time
}
