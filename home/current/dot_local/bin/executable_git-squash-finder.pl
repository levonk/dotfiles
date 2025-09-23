#!/usr/bin/perl

# https://blog.plover.com/2025/09/21/#what-changed-twice
# https://github.com/mjdominus/git-util/blob/master/bin/what-changed-twice

my $cur_commit = "???";
my %changes;

while (<>) {
    chomp;
    if (/^commit ([a-f0-9]+)/) {
        $cur_commit = $1;
        next;
    } elsif (/^ (\S+)\s+\| \d+ [+-]+$/) {
        my $filename = $1;
        push @{$changes{$cur_commit}}, $filename;
    }
}

# abbreviate commit IDs as much as possible
my %debrev = ( "" => [ keys %changes ] );
while () {
    my $needed_revisions;
    my %revised;
    while (my ($k, $v) = each %debrev) {
        if (@$v == 0) {
            next
        } elsif (@$v == 1) {
            $revised{$k} = $v;
            next;
        }

        for my $commit (@$v) {
            my $next_letter = substr($commit, length($k), 1);
            push @{$revised{"$k$next_letter"}}, $commit;
            $needed_revisions = 1;
        }
    }
    if ($needed_revisions) {
        %debrev = %revised;
    } else {
        last;
    }
}
$debrev{$_} = $debrev{$_}[0] for keys %debrev;
my %abbrev = reverse %debrev;

# find which files were modified in multiple commits
my %file_changes;
while (my ($commit, $files) = each %changes) {
    for my $file (@$files) {
        push @{$file_changes{$file}}, $commit;
    }
}

# Figure out suitable width for filename column of report
my $longest_filename = "";
for my $file (sort keys %file_changes) {
    my $commit_list = $file_changes{$file};
    next if @$commit_list < 2;
    if (length($file) > length($longest_filename)) {
        $longest_filename = $file;
    }
}
my $width = length($longest_filename);

# Print out report of files changed in at least two commits
my %mentioned_abbrev;
for my $file (sort keys %file_changes) {
    my $commit_list = $file_changes{$file};
    next if @$commit_list < 2;
    my @abbreviated_commit_list = map { $abbrev{$_} } @$commit_list;
    $mentioned_abbrev{$_} = 1 for @abbreviated_commit_list;
    printf("%${width}s  %s\n", $file,
        join(" ", sort @abbreviated_commit_list))
}
print "\n";

# Print out report of debreviated commits
for my $ab (sort keys %mentioned_abbrev) {
    printf("%7s  %s\n", $ab, substr($debrev{$ab}, 0, 7))
}
