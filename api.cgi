#!/usr/local/bin/perl
use strict;
use warnings;

use Encode qw/ decode_utf8 /;

use lib './lib';
use JSON qw/ encode_json /;
use MyDB;

my $query_string = do {
	if ($ENV{'REQUEST_METHOD'} eq 'POST') {
		read(STDIN, my $query_string, $ENV{'CONTENT_LENGTH'});
		$query_string;
	}
	elsif ($ENV{'REQUEST_METHOD'} eq 'GET') {
		$ENV{'QUERY_STRING'};
	}
} || '';

my %param;
if ($query_string) {
	$query_string =~ tr/+/ /;

	for my $pair (split(/&/, $query_string)) {

		my ($key, $value) = split(/=/, $pair, 2);
		$value = '' unless defined $value;

		$key   =~ s/%([\da-fA-F]{2})/chr (hex ($1))/eg;
		$value =~ s/%([\da-fA-F]{2})/chr (hex ($1))/eg;

		#*** Multiple Param ***#
		if (defined $param{$key}) {
			if (! ref $param{$key}) {
				$param{$key} = [ $param{$key} ];
			}
			push @{ $param{$key} }, $value;
		}
		#*** Single Param ***#
		else {
			$param{$key} = $value;
		}
	}

	# page 'of'
	if (defined $param{'of'}) {
		if ($param{'of'} !~ m/^[0-9]+$/) {
			$param{'of'} = 0;
		}
	}
}

#
# Param "section" must be required parameter.
#      i.e. "hb" (HatenaBookmark), "ss" (SlideShare).
# If not exists, return 404 HTTP Status Code.
#
if ((defined $param{'section'}) and ($param{'section'} =~ /^(hb|ss)$/)) {

	my $section = $1;

	my $data = []; # for Response
	{
		my $dbh = MyDB->connect();
		@{ $data } = ($section eq 'hb') ? get_data_hb($dbh)
		           : ($section eq 'ss') ? get_data_ss($dbh)
		           : ();
	}

	print "Content-type:application/json; charset=UTF-8\n",
	      "Pragma: no-cache\n",
			"Cache-Control: no-cache\n",
			"Expires: Thu, 01 Dec 1994 16:00:00 GMT\n",
	      "\n",
		encode_json($data);
}
else {
	print "Status: 404 Not Found\nContent-type: text/plain\n\nNot Found";
}
exit; ## END


sub get_data_hb {
	my ($dbh) = @_;
	my $sth = $dbh->prepare('
		SELECT link,title,description,bookmarked_on,usercount
		  FROM hatena_bookmark
		 ORDER BY added_on DESC,
		          bookmarked_on DESC
		 LIMIT ?,?
	');
	my $offset = 5;
	my $limit = ($param{'of'} || 0) * $offset;
	$sth->execute($limit, $offset);
	my @data;
	while (my $row = $sth->fetchrow_arrayref) {
		my $i = 0;
		push @data, {
			url         => $row->[$i++],
			title       => escapeHTML(decode_utf8($row->[$i++])),
			description => escapeHTML(decode_utf8($row->[$i++])),
			datetime    => $row->[$i++],
			usercount   => $row->[$i++],
			favicon     => './img/favicon/'.favicon_url($row->[0]),
		};
	}
	$sth->finish;
	return @data;
}
sub get_data_ss {
	my ($dbh) = @_;
	my $sth = $dbh->prepare('
		SELECT id,title,description,url,created
		  FROM slideshare
		 ORDER BY created DESC
		 LIMIT ?,?
	');
	my $offset = 5;
	my $limit = ($param{'of'} || 0) * $offset;
	$sth->execute($limit, $offset);
	my @data;
	while (my $row = $sth->fetchrow_arrayref) {
		my $i = 0;
		push @data, {
			id          => decode_utf8($row->[$i++]),
			title       => decode_utf8($row->[$i++]), # already escaped
			description => decode_utf8($row->[$i++]), # already escaped
			url         => decode_utf8($row->[$i++]),
			datetime    => decode_utf8($row->[$i++]),
		};
	}
	$sth->finish;
	return @data;
}

sub escapeHTML {
	my $text = shift;
	$text =~ s/&/&amp;/g;
	$text =~ s/</&lt;/g;
	$text =~ s/>/&gt;/g;
	$text =~ s/"/&quot;/g;
	$text =~ s/'/&#39;/g;
	return $text;
}

sub favicon_url {
	my $url = shift;
	require Digest::MD5;
	return Digest::MD5::md5_hex($url).'.png';
}

__END__

