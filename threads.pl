#!/usr/bin/env perl

use threads;
use strict;
use warnings;

use Data::Dumper qw( Dumper );
use Devel::Size  qw( total_size );
use List::Util   qw( min );
use Thread::Queue::Any;


my $elem_length    = 500;
my $array_length   = 61138;
my $threads_number = 40;

my $e = "a"  x $elem_length;
my @a = ($e) x $array_length;

my $q = Thread::Queue::Any->new;

sub timeit  { print shift . localtime . "\n" }
sub useless { return };

timeit "Enqueueing started ";

$q->enqueue( $_ ) foreach ( @a );

timeit "Enqueueing finished ";

print "Total size of input array: " . 
      Devel::Size::total_size(\@a)  . " Bytes\n";

print "Total size of the queue: " . 
      Devel::Size::total_size(\$q)  . " Bytes\n";

my $sub_ref = \&useless;
my @threads;

for my $worker_id ( 1 .. min( scalar @a, $threads_number ) ) {
    my $thread = threads->create(
       sub {
           my ($elt) = $q->dequeue();
           while ($elt) {
               $sub_ref->( $elt );
               ($elt) = $q->dequeue();
           }
       }
    );
	push @threads, $thread;

}

for (@threads) {
    $q->enqueue(undef);
}

$_->join foreach ( @threads );
timeit "Dequeueing finished at ";


