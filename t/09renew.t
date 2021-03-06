#!/usr/bin/perl
#
# Copyright (C) 2006-2008  Georgia Public Library Service
# 
# Author: David J. Fiander
# 
# This program is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation; either version 2 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program.  If not, see <http://www.gnu.org/licenses/>.
#
# renew: test Renew Response

use strict;
use warnings;
use Clone qw(clone);

use Sip::Constants qw(:all);

use SIPtest qw($datepat $textpat $instid $currency $user_barcode 
	       $item_barcode $item_title);

my $checkout_template = {
			 id => 'Renew: prep: check out item',
			 msg => "11YN20060329    203000                  AO$instid|AA$user_barcode|AB$item_barcode|AC|",
			 pat => qr/^121NNY$datepat/,
			 fields => [],
			};

my $checkin_template = {
			id => 'Renew: prep: check in item',
			msg => "09N20060102    08423620060113    084235APUnder the bed|AO$instid|AB$item_barcode|ACterminal password|",
			pat => qr/^101YNN$datepat/,
			fields => [],
		       };

#my $hold_template = {
#		     id => 'Renew: prep: place hold on item',
#		     msg =>"15+20060415    110158BW20060815    110158|BSTaylor|BY2|AO$instid|AAmiker|AB$item_barcode|",
#		     pat => qr/^161N$datepat/,
#		     fields => [],
#		    };
#
#my $cancel_hold_template = {
#		     id => 'Renew: cleanup: cancel hold on item',
#		     msg =>"15-20060415    110158BW20060815    110158|BSTaylor|BY2|AO$instid|AAmiker|AB$item_barcode|",
#		     pat => qr/^161[NY]$datepat/,
#		     fields => [],
#		    };
#

my $renew_test_template = {
			   id => 'Renew: item id checked out to patron, renewal permitted, no 3rd party, no fees',
			   msg => "29NN20060102    084236                  AO$instid|AA$user_barcode|AB$item_barcode|",
			   pat => qr/^301YNN$datepat/,
			   fields => [
				      $SIPtest::field_specs{(FID_INST_ID)},
				      $SIPtest::field_specs{(FID_SCREEN_MSG)},
				      $SIPtest::field_specs{(FID_PRINT_LINE)},
				      { field    => FID_PATRON_ID,
					pat      => qr/^$user_barcode$/,
					required => 1, },
				      { field    => FID_ITEM_ID,
					pat      => qr/^$item_barcode$/,
					required => 1, },
				      { field    => FID_TITLE_ID,
					pat      => qr/^$item_title\s*$/,
					required => 1, },
				      { field    => FID_DUE_DATE,
					pat      => qr/^$datepat$/,
					required => 1, },
				      { field    => FID_SECURITY_INHIBIT,
					pat      => qr/^[YN]$/,
					required => 0, },
				     ],};

my @tests = (
	     $SIPtest::login_test,
	     $SIPtest::sc_status_test,
	     $checkout_template,
	     $renew_test_template,
	     );

my $test;

# Renew: item checked out, identify by title
#$test = clone($renew_test_template);
#$test->{id} = 'Renew: identify item by title';
#$test->{msg} =~ s/AB$item_barcode\|/AJ$item_title|/;
## Everything else should be the same
#push @tests, $test;
#
## Renew: Item checked out, but another patron has placed a hold
#$test = clone($renew_test_template);
#$test->{id} = 'Renew: Item has outstanding hold';
#$test->{pat} = qr/^300NUN$datepat/;
#foreach my $field (@{$test->{fields}}) {
#    if ($field->{field} eq FID_DUE_DATE || $field->{field} eq FID_TITLE_ID) {
#	$field->{pat} = qr/^$/;
#    }
#}
#
#push @tests, $hold_template, $test, $cancel_hold_template;
#
# Renew: item not checked out.  Basically the same, except
# for the leader test.
$test = clone($renew_test_template);
$test->{id} = 'Renew: item not checked out at all';
$test->{pat} = qr/^300NUN$datepat/;
foreach my $field (@{$test->{fields}}) {
    if ($field->{field} eq FID_DUE_DATE) {
	$field->{pat} = qr/^$/;
    } elsif ($field->{field} eq FID_TITLE_ID) {
	$field->{pat} = qr/^($item_title\s*|)$/;
    }
}

push @tests, $checkin_template, $test;

$test = clone($renew_test_template);
$test->{id} = 'Renew: Invalid item';
$test->{msg} =~ s/AB[^|]+/ABbad-item/;
$test->{pat} = qr/^300NUN$datepat/;
foreach my $field (@{$test->{fields}}) {
    if ($field->{field} eq FID_TITLE_ID || $field->{field} eq FID_DUE_DATE) {
	$field->{pat} = qr/^$/;
    } elsif ($field->{field} eq FID_ITEM_ID) {
	$field->{pat} = qr/^bad-item$/;
    }
}

push @tests, $test;

$test = clone($renew_test_template);
$test->{id} = 'Renew: Invalid user';
$test->{msg} =~ s/AA$user_barcode/AAberick/;
$test->{pat} = qr/^300NUN$datepat/;
foreach my $field (@{$test->{fields}}) {
    if ($field->{field} eq FID_DUE_DATE) {
	$field->{pat} = qr/^$/;
    } elsif ($field->{field} eq FID_PATRON_ID) {
	$field->{pat} = qr/^berick$/;
    } elsif ($field->{field} eq FID_TITLE_ID) {
	$field->{pat} = qr/^($item_title\s*|)$/;
    }
}

push @tests, $test;

# Still need tests for
#     - renewing a for-fee item
#     - patrons that are not permitted to renew
#     - renewing item that has reached limit on number of renewals

SIPtest::run_sip_tests(@tests);

1;
