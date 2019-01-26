#!/usr/bin/perl
use forks;
use Modern::Perl;
use Benchmark qw/ cmpthese timethese /;
use Getopt::Long;
use List::Util qw/ min /;
use Pod::Usage qw/ pod2usage /;
use Thread::Queue::Any;

my $NAME     = 'Benchmark';
my $VERSION  = 0.1;
my $DURATION = -10;

GetOptions( "version|v" => \&version,
            "help|h"    => \&manual,
            "label|l"   => \&label,
            "loops"     => \&loop,
            "assign|a"  => \&assign,
            "addition"  => \&addition,
            "array_get" => \&array_get_elem,
            "array_set" => \&array_set_elem,
            "condition" => \&condition,
            "condition2"=> \&condition2,
            "condition3"=> \&condition3,
            "threads"   => \&threads,
            "string"    => \&string_comparison,
            "all"       => \&all,
            "concat"    => \&concat,
            "param"     => \&parameter,
            "regex"     => \&regex_match,
            "regex_or"  => \&condition_comparison,
            "return"    => \&return_values, ) 
 or pod2usage({ -exitval => 0, -verbose => 2, -output => \*STDOUT });

sub all {
    assign();
    addition();
    array_get_elem();
    array_set_elem();
    concat();
    condition();
    condition2();
    condition3();
    condition_comparison();
    label();
    loop();
    parameter();
    regex_match();
    return_values();
    string_comparison();
    threads();
}

sub threads {
    use Devel::Size qw( total_size );
    use Thread::Queue::Any;

    sub asdf { my $asdf = shift @_; return };

    #timethese( $DURATION, {
    #    threads => sub {
            my $e = "a"  x 500;
            my @a = ($e) x 10138;
            
            my $q = Thread::Queue::Any->new;


            print "Enqueueing started." . localtime . "\n";
            $q->enqueue( $_ ) foreach ( @a );
            print "Enqueueing finished." . localtime . "\n";

            print "Dequeueing started at " . localtime . "\n";
            print "Total size of input array: " . 
                  Devel::Size::total_size(\@a)  . " Bytes\n";

            print "Total size of the queue: " . 
                  Devel::Size::total_size(\$q)  . " Bytes\n";

            my $sub_ref = \&asdf;
            my @threads;

            for my $worker_id ( 1 .. min( scalar @a, 100 ) ) {
            
                my $thread = threads->create(
                   sub {
                       # print("WORKER $worker_id started");
                       # Older versions of Thread::Queue::Any::dequeue
                       # don't know about scalar context, so be safe.
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
            print "Threading finished at ".localtime."\n";
}

sub addition {
    cmpthese($DURATION, {

             inc  => sub { my $i = 0; $i++; $i++;  },
             
             add  => sub { my $i = 0; $i += 2;     },
    
             add2 => sub { my $i = 0; $i = $i + 2; },                
    });
}

sub regex_match {
     cmpthese($DURATION, {

             two_branch  => sub { my $s = "linknooamlink-nooamlink-no-oam";
                                  if ( $s =~ /link-no-oam/ 
                                    or $s =~ /link-nooam/ ){} },
    
             one_branch  => sub { my $s = "linknooamlink-nooamlink-no-oam";
                                  if ( $s =~ /link-no(-)?oam/ ){}   },
     });
}

sub condition_comparison {
     cmpthese($DURATION, {

             one_set => sub { my $s = "linknooamlink-nooamlink-no-oam";
                              if ( $s =~ /asdf|nooam/ ){} },
    
             two_set => sub { my $s = "linknooamlink-nooamlink-no-oam";
                              if ( $s =~ /asdf/ or $s =~ /nooam/ ){}   },
     });
}

# the following is tricky, because with or/and there might be logical shortcuts
# which alter the result. with 'or' if the first part is true, the 2nd wont get
# evaluated, while with 'and' if the first part is false, the 2nd wont get
# evaluated. hence, the one_statement solution can be ~40% faster in certain 
# cases
sub condition2 {
     cmpthese($DURATION, {

             two_statement => sub { my $s = "linknooamlink-nooamlink-no-oam";
                              if ( $s =~ /asdf/  ){}
                              if ( $s =~ /nooam/ ){} },
    
             one_statement => sub { my $s = "linknooamlink-nooamlink-no-oam";
                              if ( $s =~ /nooam/ or $s =~ /asdf/ ){}   },
     });
}

sub condition3 {
     cmpthese($DURATION, {

             normal => sub { if ('bar' eq 'bar' ){ my $s = "true" }; },
             post   => sub { my $s = "true" if ( 'foo' eq 'foo' );   },
     });
}

sub string_comparison {
     cmpthese($DURATION, {

             equal => sub { if ( 'BAR' eq 'FOO' ){} },
    
             match => sub { if ( 'FOO' =~ /^BAR$/ ){} },
     });
}

sub label {
    my $limit = 1000000;
    cmpthese($DURATION, {
             loopWlabel => sub { FORLABEL: for (my $i = 0; $i < $limit; $i++){
                                    next FORLABEL; } 
                               },
    
       loopWlabelWOnext => sub { FORLABEL: for (my $i = 0; $i < $limit; $i++){}
                               },
    
            loopWOlabel => sub { for (my $i = 0; $i < $limit; $i++){
                                    next; }
                               },
    
      loopWOlabelWOnext => sub {    for (my $i = 0; $i < $limit; $i++){}
                               }
    });
}

sub assign {
    cmpthese($DURATION, {
            shiftAssign => sub {    my @alphabet = ('A'..'Z');
                                    for (my $i = 0; $i < 26; $i++){
                                        my $letter = shift @alphabet;
                                    }
                               },
            equalsAssign => sub {   my @alphabet = ('A'..'Z');
                                    for (my $i = 0; $i < 26; $i++){
                                        my $letter = $alphabet[$i];
                                    }
                                },
    });
}

sub loop {
    cmpthese($DURATION, {
            _for_     => sub {   my @alphabet = ('A'..'Z');
                                 for (my $i = 0; $i < 26; $i++){}
                             },
            _foreach_ => sub {   my @alphabet = ('A'..'Z');
                                 foreach my $e (@alphabet){}
                             },
            _foreach2_=> sub {   my @alphabet = ('A'..'Z');
                                 foreach (@alphabet){}
                             },
            _while_   => sub {   my @alphabet = ('A'..'Z');
                                 while ( my $e = shift @alphabet ){}
                             },
            _while2_  => sub {   my @alphabet = ('A'..'Z');
                                 while ( my ($i,$e) = each @alphabet ){}
                             },
            _map_     => sub {   my @alphabet = ('A'..'Z');
                                 map { 0 } @alphabet;
                             },
    });
}

sub parameter {

    sub shift_params {
        my $a = shift;
        my $b = shift;
    }

    sub equal_params {
        my $a = $_[0];
        my $b = $_[1];
    }

    sub assign_params {
        my ( $a, $b ) = @_;
    }

    cmpthese($DURATION, {
            'shift'         => sub { shift_params('a','b') },

            'equals'        => sub { equal_params('a','b') },

            'assign_params' => sub { assign_params('a','b') },
    });
}

sub return_values {

    sub return_by_reference {
        my @a = ('a'..'z') x 1000000;
        return \@a;
    }

    sub return_by_value { 
        my @a = ('A'..'Z') x 1000000;
        return @a;
    }

    cmpthese($DURATION, {
            'return_by_reference'  => sub { my $a = return_by_reference(); },

            'return_by_value'      => sub { my @a = return_by_value(); },
    });
}

sub concat {
    cmpthese($DURATION, {
            'single_quote' => sub { my $s = ''; $s = 'a'.'b'.'c'.'d' },  
            'double_quote' => sub { my $s = ''; $s = "a"."b"."c"."d" }, 
            'interpolate_s'=> sub { my $s = ''; $s = $s.''.$s.'' },
            'interpolate_d'=> sub { my $s = ''; $s = $s."".$s."" },
    });
}

sub array_get_elem {
    sub array_pop {
        my @a = ( 'a'..'z' );
        my $e = pop @a;
    }

    sub array_shift {
        my @a = ( 'a'..'z' );
        my $e = shift @a;
    }
    cmpthese($DURATION, {
            'pop'   => sub { array_pop(); },

            'shift' => sub { array_shift(); },
    });   
}

sub array_set_elem {
    sub array_push {
        my @a = ();
        push @a, 'b';
    }

    sub array_unshift {
        my @a = ();
        unshift @a, 'b';
    }
    cmpthese($DURATION, {
            'push'    => sub { array_push(); },

            'unshift' => sub { array_unshift(); },
    });
}

sub condition {
     cmpthese($DURATION, {
            'if'     => sub { my $a = 1; if ( not $a ){} },

            'unless' => sub { my $a = 1; unless ( $a ){} },
    });   
}

sub version {
	print "Version: $VERSION\n";
}

sub manual {
    print <<EOF

$NAME - v$VERSION
$NAME [OPTIONS]

      --assign      => compares different assignments

      --addition    =>

      --concat      =>

      --condition   =>

      --label       => compares loops with and without labels

      --loop        => compares for / foreach / while

      --param       => compares different parameter passing modes

      --regex       => compares some regular expressions

      --return      => 

      --split       =>

      --threads     =>

      --all         => execute all benchmarks above

      --help        => shows this message, then exit

      --version     => shows version number, then exit
      
EOF
	
}

__END__

=head1 Benchmark

benchmark.pl - Using L<Benchmark> CPAN module, to execute different
implementations of the same problem

=head1 SYNOPSIS

./benchmark.pl [options]

Options:
 -assign            compares different types of assignments
 -addition
 -label             compares loops with and without labels
 -loop
 -param
 -regex
 -help              shows this message and exits
 -version           shows version number and exits

=head1 OPTIONS

=over 8

=item B<--assign>

=item B<--addition>

=item B<--label>

=item B<--loop>

=item B<--param>

=item B<--regex>

=item B<--help>

=item B<--version>

=back

=head1 DESCRIPTION

B<benchmark.pl> will execute different type of benchmarks based on the given
parameter.

=cut

