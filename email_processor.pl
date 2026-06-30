#!/usr/bin/env perl
#Author: Praneeth_Perera

use strict;
use warnings;
use MIME::Lite;
use File::Copy;
use File::Path qw(make_path);

# === Configuration ===
my $ERROR_PATH   = '/path/to/emails/Error/';
my $RESULT_PATH  = '/path/to/emails/Result/';
my $LOG_DIR      = '/path/to/logs/';

my $TO   = 'your.recipient@example.com';
my $FROM = 'your.sender@example.com';

(my $sec, my $min, my $hour, my $day, my $month, my $year) = localtime(time);
$month += 1; $year -= 100;
my $date_str = sprintf("%02d%02d%02d", $day, $month, $year);
my $log_file = $LOG_DIR . $date_str . ".log";

process_directory($ERROR_PATH,  \&process_error_file);
process_directory($RESULT_PATH, \&process_result_file);

log_info("Script completed successfully.");
exit 0;

sub process_directory {
    my ($dir, $processor_sub) = @_;
    my @files = `find $dir -type f -name "*.txt"`;
    chomp @files;
    foreach my $file (@files) {
        next unless -f $file;
        log_info("Processing: $file");
        $processor_sub->($file);
    }
}

sub process_error_file  { process_and_email(shift, "Error"); }
sub process_result_file { process_and_email(shift, "Result"); }

sub process_and_email {
    my ($file, $type) = @_;
    open my $fh, '<:encoding(UTF-8)', $file or return log_info("Cannot open $file");
    my $content = do { local $/; <$fh> };
    close $fh;

    my @fields = split(',', $content);
    return unless @fields >= 3;

    my $date    = (split('"', (split(' ', $fields[0]))[3]))[1] // '';
    my $subject = (split('"', $fields[1]))[3] // 'No Subject';
    my $body    = (split('"', $fields[2]))[3] // '';

    send_email($subject . "-" . $date, $body, $file, $type);

    my @parts = split('/', $file);
    my $dest_dir = '/path/to/completed/' . join('/', @parts[8..$#parts-1]);  # Adjust as needed
    make_path($dest_dir);
    move($file, $dest_dir) or log_info("Move failed: $file");
    log_info("$type processed successfully.");
}

sub send_email {
    my ($subject, $message, $attachment, $type) = @_;
    my $msg = MIME::Lite->new(From => $FROM, To => $TO, Subject => $subject, Type => 'multipart/mixed');
    $msg->attach(Type => 'text', Data => $message);
    $msg->attach(Type => 'file/text', Path => $attachment, Filename => (split('/', $attachment))[-1], Disposition => 'attachment');
    $msg->send;
    log_info("$type Email Sent");
}

sub log_info {
    my $msg = shift;
    open my $log, '>>', $log_file or return;
    print $log localtime() . " | $msg\n";
    close $log;
}

