#!/usr/bin/env perl
#Author: Praneeth_Perera

use strict;
use warnings;
use Digest::SHA qw(hmac_sha256_base64);
use MIME::Lite;
use File::Copy;

# === Configuration ===
my $INPUT_DIR   = '/path/to/input/';
my $OUTPUT_DIR  = '/path/to/output/';
my $BACKUP_DIR  = '/path/to/backups/';
my $LOG_DIR     = '/path/to/logs/';

my $API_KEY     = 'your_api_secret_key_here';
my $API_URL     = 'http://your.api.endpoint.com/ssseven/abs';

(my $sec, my $min, my $hour, my $day, my $month, my $year) = localtime(time);
$month += 1; $year -= 100;
my $date_str = sprintf("%02d%02d%02d", $day, $month, $year);
my $log_file = $LOG_DIR . $date_str . "API.log";

process_files();

sub process_files {
    my @files = `find $INPUT_DIR -type f -name "*.txt"`;
    chomp @files;

    foreach my $file (@files) {
        log_info("Processing: $file");

        open my $fh, '<', $file or next;
        <$fh>;   # Skip header line if present

        my (@unblocked, @errors, @unknown);

        while (<$fh>) {
            chomp;
            next unless $_;

            my $mac = hmac_sha256_base64($_, $API_KEY);
            my $url = "$API_URL?mode=unblock&blockingId=25&msisdn=$_&authKey=$mac&simulate=true";

            my $response = `curl -s --request GET '$url'`;

            if ($response =~ /UNBLOCKED/) {
                push @unblocked, $_;
            } elsif ($response =~ /6006/) {
                push @errors, $_;
            } elsif ($response =~ /6008/) {
                push @unknown, $_;
            }
        }
        close $fh;

        write_output('UNBLOCKED.txt', \@unblocked);
        write_output('ERROR.txt',     \@errors);
        write_output('UNKNOWN.txt',   \@unknown);

        send_summary_emails(\@unblocked, \@errors, \@unknown);

        move($file, $BACKUP_DIR) or log_info("Backup failed: $file");
        log_info("Completed: $file");
    }
}

sub write_output {
    my ($filename, $data) = @_;
    return unless @$data;
    open my $out, '>', "$OUTPUT_DIR$filename" or return;
    print $out join("\n", @$data);
    close $out;
}

sub send_summary_emails {
    my ($unblocked, $errors, $unknown) = @_;
    send_email('UNBLOCKED NUMBERS', $unblocked, 'UNBLOCKED.txt');
    send_email('ERROR NUMBERS',     $errors,    'ERROR.txt');
    send_email('UNKNOWN NUMBERS',   $unknown,   'UNKNOWN.txt');
}

sub send_email {
    my ($subject, $numbers, $filename) = @_;
    return unless @$numbers;

    my $msg = MIME::Lite->new(
        From    => 'your@email.com',
        To      => 'recipient@email.com',
        Subject => $subject,
        Type    => 'multipart/mixed'
    );

    $msg->attach(Type => 'text', Data => join("\n", @$numbers));
    $msg->attach(Type => 'file/text', Path => "$OUTPUT_DIR$filename", Filename => $filename);
    $msg->send;
    log_info("$subject email sent.");
}

sub log_info {
    my $msg = shift;
    open my $log, '>>', $log_file or return;
    print $log localtime() . " | $msg\n";
    close $log;
}

