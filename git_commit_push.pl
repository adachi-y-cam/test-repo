#!/usr/local/bin/perl

use strict;
use Expect;
use Data::Dumper;
use FindBin;
use Getopt::Long qw(:config posix_default no_ignore_case gnu_compat);


my $work_dir = $FindBin::Bin;
my $user;
my $access_token;
my $commit_files;
my $commit_comment;

GetOptions(
    'work_dir=s'     => \$work_dir,
    'user=s'         => \$user,
    'access_token=s' => \$access_token,
    'commit_files=s' => \$commit_files,
    'comment=s'      => \$commit_comment,
);

# comment
if ($commit_comment) {
    $commit_comment =~ s/\\n/\n/g;
}

# chdir
chdir($work_dir) or die("chdir failed. dir:$work_dir\n");

# git pull
my ($status_code, $output) = expect("git pull", (
    undef,
    [ eof => sub {} ],
));
if ($status_code) {
    die("git pull failed.");
}

# git add
($status_code, $output) = expect("git add $commit_files", (
    undef,
    [ eof => sub {} ],
));
if ($status_code) {
    die("git add failed.");
}


# git commit
($status_code, $output) = expect("git commit -m '$commit_comment'", (
    undef,
    [ eof => sub {} ],
));
if ($status_code) {
    die("git commit failed.");
}

# git push
($status_code, $output) = expect("git push origin HEAD", (
    undef,
    [ "Username for 'https://github.com': " =>
        sub { shift->send("$user\n");
            exp_continue;
        } ],
    [ "Password for 'https://" . $user . "\@github.com': " =>
        sub { shift->send("$access_token\n");
            exp_continue;
        } ],
    [ eof => sub {} ],
));
if ($status_code) {
    die("git push failed.");
}


sub expect
{
    my $cmd = shift;
    my @param = @_;

    my $expect = Expect->new;
    $expect->log_stdout(0);
    print "\n[$cmd]\n";
    $expect->spawn($cmd) or die "cannot spawn '$cmd'";
    $expect->expect(@param);
    print $expect->before();
    print "exit status code:" . $expect->exitstatus() . "\n";

    return ($expect->exitstatus(), $expect->before());
}
