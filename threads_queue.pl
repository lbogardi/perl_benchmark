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
