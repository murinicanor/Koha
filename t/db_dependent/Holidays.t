#!/usr/bin/perl

# This file is part of Koha.
#
# Koha is free software; you can redistribute it and/or modify it
# under the terms of the GNU General Public License as published by
# the Free Software Foundation; either version 3 of the License, or
# (at your option) any later version.
#
# Koha is distributed in the hope that it will be useful, but
# WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with Koha; if not, see <http://www.gnu.org/licenses>.

use Modern::Perl;

use Test::More tests => 10;
use t::lib::TestBuilder;

use C4::Context;
use C4::Branch;
use Koha::DateUtils;

use DateTime;
use DateTime::TimeZone;

BEGIN {
    use_ok('Koha::Calendar');
    use_ok('C4::Calendar');
}

my $dbh = C4::Context->dbh();
# Start transaction
$dbh->{AutoCommit} = 0;
$dbh->{RaiseError} = 1;

my $builder = t::lib::TestBuilder->new();
# Create two fresh branches for the tests
my $branch_1 = $builder->build({ source => 'Branch' })->{ branchcode };
my $branch_2 = $builder->build({ source => 'Branch' })->{ branchcode };

C4::Calendar->new( branchcode => $branch_1 )->insert_week_day_holiday(
    weekday     => 0,
    title       => '',
    description => 'Sundays',
);

my $holiday2add = dt_from_string("2015-01-01");
C4::Calendar->new( branchcode => $branch_1 )->insert_day_month_holiday(
    day         => $holiday2add->day(),
    month       => $holiday2add->month(),
    year        => $holiday2add->year(),
    title       => '',
    description => "New Year's Day",
);
$holiday2add = dt_from_string("2014-12-25");
C4::Calendar->new( branchcode => $branch_1 )->insert_day_month_holiday(
    day         => $holiday2add->day(),
    month       => $holiday2add->month(),
    year        => $holiday2add->year(),
    title       => '',
    description => 'Christmas',
);

my $koha_calendar = Koha::Calendar->new( branchcode => $branch_1 );
my $c4_calendar = C4::Calendar->new( branchcode => $branch_1 );

isa_ok( $koha_calendar, 'Koha::Calendar', 'Koha::Calendar class returned' );
isa_ok( $c4_calendar,   'C4::Calendar',   'C4::Calendar class returned' );

my $sunday = DateTime->new(
    year  => 2011,
    month => 6,
    day   => 26,
);
my $monday = DateTime->new(
    year  => 2011,
    month => 6,
    day   => 27,
);
my $christmas = DateTime->new(
    year  => 2032,
    month => 12,
    day   => 25,
);
my $newyear = DateTime->new(
    year  => 2035,
    month => 1,
    day   => 1,
);

is( $koha_calendar->is_holiday($sunday),    1, 'Sunday is a closed day' );
is( $koha_calendar->is_holiday($monday),    0, 'Monday is not a closed day' );
is( $koha_calendar->is_holiday($christmas), 1, 'Christmas is a closed day' );
is( $koha_calendar->is_holiday($newyear),   1, 'New Years day is a closed day' );

$dbh->do("DELETE FROM repeatable_holidays");
$dbh->do("DELETE FROM special_holidays");

my $custom_holiday = DateTime->new(
    year  => 2013,
    month => 11,
    day   => 12,
);

my $today = dt_from_string();
C4::Calendar->new( branchcode => $branch_2 )->insert_single_holiday(
    day         => $today->day(),
    month       => $today->month(),
    year        => $today->year(),
    title       => "$today",
    description => "$today",
);

is( Koha::Calendar->new( branchcode => $branch_2 )->is_holiday( $today ), 1, "Today is a holiday for $branch_2" );
is( Koha::Calendar->new( branchcode => $branch_1 )->is_holiday( $today ), 0, "Today is not a holiday for $branch_1");

$dbh->rollback;

1;
