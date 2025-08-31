#!/usr/bin/perl

## clip - pluck a portion of text based on regex that comes before and after it
## http://nklein.com/2012/08/some-simple-tools-for-processing-debug-output-and-log-files/

use strict;
use warnings;
use Getopt::Long qw(GetOptions);

## Defaults preserved from original implementation
my $default_pre  = '[\[("\'=]';
my $default_post = '[,\s"\')\]]';

my ($opt_pre, $opt_post, $count, $sum, $help);
GetOptions(
    'before|b=s' => \$opt_pre,
    'after|a=s'  => \$opt_post,
    'count|c'    => \$count,
    'sum|s'      => \$sum,
    'help|h'     => \$help,
) or die "Use --help for usage.\n";

if ($help) {
    print <<'USAGE';
Usage: clip [options] [PRE_REGEX [POST_REGEX]] < input

Options:
  -b, --before REGEX   Regex that comes before captured portion (default: [\[("'=])
  -a, --after  REGEX   Regex that comes after captured portion  (default: [,\s"')\]])
  -c, --count          Count unique captured values (like: sort | uniq -c)
  -s, --sum            Sum numeric captured values (integer output)
  -h, --help           Show this help and exit

Notes:
  - Positional PRE_REGEX and POST_REGEX still supported for backwards compatibility.
  - Without -c/-s, prints each captured value on its own line (original behavior).
USAGE
    exit 0;
}

## Positional overrides if provided after options
my $pos_pre  = shift @ARGV;
my $pos_post = shift @ARGV;

my $pre  = defined $pos_pre  ? $pos_pre  : (defined $opt_pre  ? $opt_pre  : $default_pre);
my $post = defined $pos_post ? $pos_post : (defined $opt_post ? $opt_post : $default_post);

if ($count && $sum) {
    die "Options --count and --sum are mutually exclusive.\n";
}

if ($count) {
    my %freq;
    while (my $line = <>) {
        if ($line =~ m{$pre\s*(.*?)\s*?$post}o) {
            $freq{$1}++;
        }
    }
    ## Match original `clip | sort | uniq -c | sed 's/^ *//'`: keys sorted lexicographically
    foreach my $k (sort keys %freq) {
        print $freq{$k} . " " . $k . "\n";
    }
    exit 0;
}

if ($sum) {
    my $total = 0;
    while (my $line = <>) {
        if ($line =~ m{$pre\s*(.*?)\s*?$post}o) {
            my $v = $1;
            $v =~ s/^\s+|\s+$//g;
            $v =~ s/[^0-9+-.,]//g;  ## be lenient; keep digits/signs/decimal/comma
            $v =~ s/,//g;           ## drop thousands separators if present
            $v = int($v || 0);
            $total += $v;
        }
    }
    printf("%d\n", $total);
    exit 0;
}

## Default: stream out each captured value
while ( my $line = <> ) {
    ## look for $pre followed by whitespace then the (non-greedy) portion to keep
    ## followed by some (non-greedy) amount of whitespace followed by $post.
    print "$1\n" if ( $line =~ m{$pre\s*(.*?)\s*?$post}o );
}
