#!/usr/local/bin/perl
use strict;
use warnings;

use URI;
use Digest::SHA qw/ sha1_hex /;
use LWP::Simple qw/ get /;
use XML::Simple;

use lib '../lib';
use MyDB;
use Time::Piece;
use Time::Seconds;

my $key = require './slideshare.key';

my $url = 'http://www.slideshare.net/api/2/search_slideshows';
my $time = time;
my $hash = sha1_hex($key->{secret}.$time);

for my $q (qw/ Perl YAPC /) {
	my $uri = URI->new($url);
	$uri->query_form(
		api_key => $key->{api},
		hash    => $hash,
		ts      => $time, # timestamp
		q       => $q,
		sort    => 'latest',
	);
	my $feed = get($uri);
	if ($feed) {
		my $xml = XML::Simple->new->XMLin($feed);
		eval {
			my $dbh = MyDB->connect();
			my $s_sth = $dbh->prepare('
				SELECT COUNT(*)
				  FROM slideshare
				 WHERE id=?
			');
			my $i_sth = $dbh->prepare('
				INSERT INTO slideshare
				       (id,title,description,status,username,
				        url,thumbnailurl,thumbnailsmallurl,
				        embed,created,language,format,download)
				VALUES (?,?,?,?,?,?,?,?,?,?,?,?,?)
			');

			for my $item (@{ $xml->{Slideshow} }) {
				$s_sth->execute($item->{ID});
				if ($s_sth->fetchrow_arrayref->[0] <= 0) {
					$i_sth->execute(
						$item->{ID},
						$item->{Title},
						ref($item->{Description}) ? 'none' : $item->{Description},
						$item->{Status},
						$item->{Username},
						$item->{URL},
						$item->{ThumbnailURL},
						$item->{ThumbnailSmallURL},
						$item->{Embed},
						created($item->{Created}),
						$item->{Language},
						$item->{Format},
						$item->{Download},
					);
				}
			}
		};
		if ($@) {
			die $@;
		}
	}
}

sub created {
	my $c = shift;
	my ($month, $day, $hms, $sg, $sgi, $year)
		=
	$c =~ /^....(...).(\d\d).(\d\d.\d\d.\d\d).([\-+])\d(\d)\d\d.(\d\d\d\d)$/;

	my %month = (
		Jan => 1, Feb => 2, Mar => 3, Apr => 4, May => 5, Jun => 6,
		Jul => 7, Aug => 8, Sep => 9, Oct => 10, Nov => 11, Dec => 12,
	);

	my $t = Time::Piece->strptime(
		"$year-$month{$month}-$day $hms",
		'%Y-%m-%d %H:%M:%S',
	);

	if ($sgi) {
		if ($sg eq '+') {
			$t = $t + ONE_HOUR * $sgi;
		}
		elsif ($sg eq '-') {
			$t = $t - ONE_HOUR * $sgi;
		}
	}

	return $t->strftime('%Y-%m-%d %H:%M:%S');
}

