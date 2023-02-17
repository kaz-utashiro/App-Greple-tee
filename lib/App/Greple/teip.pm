=encoding utf-8

=head1 NAME

App::Greple::teip - It's new $module

=head1 SYNOPSIS

    use App::Greple::teip;

=head1 DESCRIPTION

App::Greple::teip is ...

=head1 AUTHOR

Kazumasa Utashiro

=head1 LICENSE

Copyright 2022 Kazumasa Utashiro.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

package App::Greple::teip;

our $VERSION = "0.01";

use v5.14;
use warnings;
use Carp;
use Data::Dumper;

use IO::Pipe;

local @ARGV;

my $p2c = IO::Pipe->new();
my $c2p = IO::Pipe->new();

my @unbuffer = qw(script -q /dev/null);
#@unbuffer = qw(stdbuf -i0 -o0 -e0);
sub unbuffer {
    ( @unbuffer, @_ );
}

my @command = qw(tr a-z A-Z);
#@command = qw(sed s/.*/\[&\]/);
@command = qw(cat -n);
my $pid;
if (not defined $pid) {
    $pid = fork // die "fork: $!";
    if ($pid == 0) {
	$p2c->reader;
	$c2p->writer;
	close STDIN ; open STDIN,  '<&', $p2c or die $!;
	close STDOUT; open STDOUT, '>&', $c2p or die $!;
	$p2c->close;
	$c2p->close;
	exec unbuffer @command;
	exit;
    }
}

$c2p->reader;
$p2c->writer->autoflush;

sub callback {
    my %opt = @_;
    $p2c->print($opt{match}, "\n");
    my $s = $c2p->getline // '__UNDEF__';
    $s =~ s/\R$//;
    warn "$opt{match} -> $s\n";
    $s;
}

1;

__DATA__

option default --callback=__PACKAGE__::callback
