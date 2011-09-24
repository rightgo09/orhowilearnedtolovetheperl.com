#!/usr/local/bin/perl
use strict;
use warnings;

use LWP::Simple qw/ get /;
use XML::Simple;
use Digest::MD5 qw/ md5_hex /;

use lib '../lib';
use MyDB;

my $url = 'http://b.hatena.ne.jp/keyword/Perl?sort=hot&threshold=&mode=rss';

my $rss = get($url);
if ($rss) {
	my $xml = XML::Simple->new->XMLin($rss);
	eval {
		my $dbh = MyDB->connect();
		my $s_sth = $dbh->prepare('
			SELECT COUNT(*)
			  FROM hatena_bookmark
			 WHERE link=?
		');
		my $i_sth = $dbh->prepare('
			INSERT INTO hatena_bookmark
			       (link,title,about,subject,description,
			        content,bookmarked_on,added_on,usercount)
			VALUES (?,?,?,?,?,?,?,now(),?)
		');
		my $u_sth = $dbh->prepare('
			UPDATE hatena_bookmark
			   SET usercount=?
			 WHERE link=?
		');

		for my $item (@{ $xml->{item} }) {
			$s_sth->execute($item->{'link'});
			if ($s_sth->fetchrow_arrayref->[0] <= 0) {
				$i_sth->execute(
					$item->{'link'},
					$item->{'title'},
					$item->{'rdf:about'},
					$item->{'dc:subject'},
					$item->{'description'},
					$item->{'content:encoded'},
					$item->{'dc:date'},
					$item->{'hatena:bookmarkcount'},
				);
				my $favicon = get('http://favicon.st-hatena.com/?url='.$item->{link});
				open my $fh, '>', '/home/rightgo09/www/orhowilearnedtolovetheperl/img/favicon/'.md5_hex($item->{link}).'.png' or die $!;
				print $fh $favicon;
				close $fh;
			}
			else {
				$u_sth->execute(
					$item->{'hatena:bookmarkcount'},
					$item->{'link'},
				);
			}
		}
	};
	if ($@) {
		die $@;
	}
}

