#!/usr/bin/perl

use strict;

my $spn = 'generic';
my $ontid;
my $isoform_only = 0;

while (@ARGV) {
    my $opt = shift @ARGV;
    if ($opt eq '-s') {
        $spn = shift @ARGV;
    }
    elsif ($opt eq '-n') {
        $ontid = shift @ARGV;
    }
    elsif ($opt eq '-I') {
        $isoform_only = 1;
    }
}
if (!$ontid) {
    $ontid = $spn;
}

my $is_rat = $spn eq 'Rnor';

print "ontology: go/noctua/$ontid\n";
print "\n";

my %done = ();
while(<>) {
    chomp;
    next if m@^\!@;

    # RGD redundantly include annotations to UniProtKB, duplicating genes
    next if $is_rat && m@^UniProt@;

    my @vals = split(/\t/,$_);
    my $db = $vals[0];
    my $id = $db eq 'MGI' ? $vals[1] : "$db:$vals[1]";

    $id = expand($id);

    next if $isoform_only && $id !~ m@\-\d+$@;
    
    

    my $n = $vals[2];
    $n =~ tr/a-zA-Z0-9\-_//cd;

    my $fullname = $vals[9];
    $fullname =~ tr/a-zA-Z0-9\- //cd;

    if ($n eq $fullname) {
        $fullname = undef;
    }

    my @syns = split(/\|/,$vals[10]);

    my $type = $vals[11];
    my $taxid = $vals[12];
    $taxid =~ s/^taxon:/NCBITaxon:/;

    my $iso = $vals[16];

    if ($iso && $iso =~ /(\S+)\-(\d+)/) {
        my $num = $2;
        $iso =~ s/^PR:/UniProtKB:/;

        if (!$done{$iso}) {

            print "[Term]\n";
            print "id: $iso\n";
            print "name: $n isoform $num $spn\n";
            print "is_a: $id\n";
            #print "is_a: PR:000000001 ! protein\n";
            print "relationship: in_taxon $taxid\n";
            print "\n";

        }
        $done{$iso}++;
    }

    next if $done{$id};

    if ($n =~ m@(.*)_(\d+)$@) {
        my ($n2,$ntaxid) = ($1,$2);
        if ($taxid eq "NCBITaxon:$ntaxid") {
            $n =~ s@_\d+$@@;
        }
    }
    
    print "[Term]\n";
    print "id: $id\n";
    print "name: $n $spn\n";
    print "synonym: \"$fullname $spn\" EXACT []\n" if $fullname && $fullname !~ m@homo sapiens@i;
    print "synonym: \"$n\" BROAD [$taxid]\n";
    print "is_a: CHEBI:33695 ! information biomacromolecule\n";
    print "relationship: in_taxon $taxid\n";
    print "\n";

    $done{$id}++;
}

print "[Typedef]\n";
print "id: in_taxon\n";
print "xref: RO:0002162\n";


# PR:000000001 ! protein
exit 0;

# todo: derive this from CURIE map
sub expand {
    my $id = shift;
    $_ = $id;
    #s@^MGI:@http://www.informatics.jax.org/accession/MGI:@;

    # perpetuate MGI awfulness for now
    s@^MGI:@MGI:MGI:@;
    return $_;
}
