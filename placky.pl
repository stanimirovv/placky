#!/usr/bin/perl
use strict;
use warnings;
use JSON::XS;
my $VERSION = 0.1;

print "Content-type: text/json\r\n\r\n";
umask(077);
my $t = int time().'000';

sub read_file {
	my $iface = shift;
	my $name = shift;
	my $save_file = "/var/spool/traffstats/$iface-$name";
	my $save = 0;
	my $content = 0;

	if ( -f $save_file ) {
		open my $read, '<', $save_file;
		$save = <$read>;
		close $read;
	}

	open my $file, '<', "/sys/class/net/$iface/statistics/$name";
	$content = <$file>;
	close $file;
	$content =~ s/[\r\n\s]*$//g;

	open my $write, '>', $save_file;
	print $write $content;
	close $write; 
	return $content - $save;
}

sub get_iface {
	my $iface = shift;
	my $rx_bytes = read_file($iface, 'rx_bytes');
	my $tx_bytes = read_file($iface, 'tx_bytes');
	my $rx_packets = read_file($iface, 'rx_packets');
	my $tx_packets = read_file($iface, 'tx_packets');
	my $hash = {
		"rx_bytes" => [$t,$rx_bytes/100],
		"tx_bytes"=> [$t,$tx_bytes/100],
		"rx_packets" => [$t,$rx_packets],
		"tx_packets" => [$t,$tx_packets]
	};
}
my %ret = ();
$ret{'eth0'} = get_iface('eth0');
$ret{'eth1'} = get_iface('eth1');

my $json = JSON::XS->new->ascii->pretty->allow_nonref;
print $json->encode(\%ret);
