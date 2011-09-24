package MyDB;
use strict;
use warnings;
use DBI;
use Carp qw/ croak /;
my $dbh;

# Singleton db handle
sub connect {
	if ($dbh) {
		return $dbh;
	}
	else {
		open my $fh, '<', '/home/rightgo09/myapp/db.conf'
			or die "Can't open config file.[$!]";
		chomp(my $conf = <$fh>);
		close $fh;
		(my $user, $conf) = split /@/, $conf;
		(my $host, $conf) = split /:/, $conf;
		my ($pw, $database) = split m|/|, $conf;
		my $attr = {};
#		my $attr = { mysql_enable_utf8 => 1 };
		$dbh = DBI->connect(
			"DBI:mysql:database=$database;host=$host;",
			$user,
			$pw,
			$attr,
		);
		$dbh->do('SET NAMES utf8');
		return $dbh;
	}
}
sub END {
	$dbh ? $dbh->disconnect : ();
}

1;
__END__
