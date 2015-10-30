#!/usr/bin/perl
use strict;
my %smap = (
    Scer => 'sgd',
    Mmus => 'mgi',
    Drer => 'zfin',
    Hsap => 'goa_ref_human'
    );

my @tgts = ();
foreach (keys %smap) {
    my $tgt = "neo-$_.obo";
    push(@tgts, $tgt);
    my $n = $smap{$_};
    print "$tgt: $n.gaf.gz\n";
    print "\tgzip -dc \$< | gaf2obo.pl -s $_ > \$@.tmp && mv \$@.tmp \$@\n\n";
}

print "all_obo: @tgts\n";

print "neo.obo: @tgts\n";
print "\towltools --create-ontology http://purl.obolibrary.org/obo/go/noctua/neo.owl \$^ --merge-support-ontologies  -o -f obo \$@\n";
