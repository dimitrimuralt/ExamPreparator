#! /usr/bin/env perl
#====================================================================
# @title  'statistics'
# @author Christoph Wenk, Dimitri Muralt
# @date   30.08.2018
# @desc   This script get a hash as an input and creates various statistic
#         lists with it. It then puts those messages to STDOUT for the
#         user to read.
#
#         Callable by other scripts. Needs hash as input with the following
#         structure:
#         (StudentFile => [
#                           CorrectAnswers,
#                           TotalAnswersGiven
#                         ]
#         )
#
#         The script solves part 3 of the assignment.
#====================================================================
use v5.28;
use strict;
use warnings;
use Data::Dumper;
use experimental 'signatures';
use List::Util qw< min max >;
use Statistics::Basic qw< mean mode median >;
use Statistics::Descriptive;
use Exporter qw(import);
use utf8;
use open ':std', ':encoding(UTF-8)';

our @EXPORT_OK = qw(createStatistics);

#====================================================================
# Definitions
#====================================================================
# Constants
my $scoreThreshold = 0.5; # Score < 50%
my $totalAmountOfQuestions = 20; # Max amount of questions
my $bottomCohortThreshold = 25;

# Content lists
my %studentScores;
my @correctAnswersList;
my @totalAnswersList;
my %studentStatisticsList; # Structure: (StudentFile => [
#                                                           CorrectAnswers,
#                                                           TotalAnswersGiven,
#                                                           ScoreBelowThresholdFlag,
#                                                           BottomCohortFlag,
#                                                           BelowMeanFlag
#                                                       ]
#                                         )

# Variables
my $stat = Statistics::Descriptive::Full->new();
my $lowestPercentile;
my $stdv;
my $minimalQuestionsAnsweredCount;
my $maximumQuestionsAnsweredCount;
my $minimumCorrectlyGivenAnswersCount;
my $maximumCorrectlyGivenAnswersCount;

#====================================================================
# Main Processing
#====================================================================
sub createStatistics {
    %studentScores = @_;
    # Create statistic arrays
    for my $key (sort keys %studentScores) {
        my $correctAnswers = $studentScores{$key}[0];
        my $totalAnswers = $studentScores{$key}[1];

        push @correctAnswersList, $correctAnswers; # Collect the amount of correct answers given by the student
        push @totalAnswersList, $totalAnswers; # Collect the total amount of answers given by the student

        $studentStatisticsList{$key}[0] = $correctAnswers;
        $studentStatisticsList{$key}[1] = $totalAnswers;
    }

    # Calculate percentile and standard deviation
    $stat->add_data(@correctAnswersList);
    $lowestPercentile = $stat->percentile($bottomCohortThreshold);
    $stdv = $stat->standard_deviation();

    doChecks();
    doBasicStatistics();
    putOutput();
}

#====================================================================
# Subroutine Definitions
#====================================================================
sub doChecks {
    for my $key (sort keys %studentScores) {
        # Check if student is under the specified threshold
        if (($studentScores{$key}[0] / $totalAmountOfQuestions) < $scoreThreshold) {
            $studentStatisticsList{$key}[2] = 1;
        }
        else {
            $studentStatisticsList{$key}[2] = 0;
        }

        # Check if student belongs to lowest percentile
        if ($studentScores{$key}[0] <= $lowestPercentile) {
            $studentStatisticsList{$key}[3] = 1;
        }
        else {
            $studentStatisticsList{$key}[3] = 0;
        }

        # Check if student's score is > 1 stdv below mean
        if ($studentScores{$key}[0] < mean(@correctAnswersList)) {
            $studentStatisticsList{$key}[4] = 1;
        }
        else {
            $studentStatisticsList{$key}[4] = 0;
        }
    }
}

sub doBasicStatistics {
    # Get amount of students with minimum amount of questions answered
    $minimalQuestionsAnsweredCount = grep {$_ == min(@totalAnswersList)} @totalAnswersList;

    # Get amount of students with maximum amount of questions answered
    $maximumQuestionsAnsweredCount = grep {$_ == max(@totalAnswersList)} @totalAnswersList;

    # Get amount of students with minimum of correctly given answers
    $minimumCorrectlyGivenAnswersCount = grep {$_ == min(@correctAnswersList)} @correctAnswersList;

    # Get amount of students with maximum of correctly given answers
    $maximumCorrectlyGivenAnswersCount = grep {$_ == max(@correctAnswersList)} @correctAnswersList;
}

#====================================================================
# Screen Output
#====================================================================
sub putOutput {

    # print individual score of each student
    for my $current_score(sort keys %studentScores){
        say "$current_score..................$studentScores{$current_score}[0]/$studentScores{$current_score}[1]";
    }

    say "Average number of questions answered:....." . mean(@totalAnswersList);
    say "                             Minimum:....." . min(@totalAnswersList) . "   ($minimalQuestionsAnsweredCount Student(s))";
    say "                             Maximum:....." . max(@totalAnswersList) . "   ($maximumQuestionsAnsweredCount Student(s))";
    say "";
    say "Average number of correct answers:........" . mean(@correctAnswersList);
    say "                             Minimum:....." . min(@correctAnswersList) . "   ($minimumCorrectlyGivenAnswersCount Student(s))";
    say "                             Maximum:....." . max(@correctAnswersList) . "   ($maximumCorrectlyGivenAnswersCount Student(s))";
    say "";
    say "Results below expectation:";
    for my $key (sort keys %studentStatisticsList) {
        if ($studentStatisticsList{$key}[2] == 1) {
            say "    $key.....$studentStatisticsList{$key}[0]/$studentStatisticsList{$key}[1]  (score < 50%)";
        }
        elsif ($studentStatisticsList{$key}[3] == 1) {
            say "    $key.....$studentStatisticsList{$key}[0]/$studentStatisticsList{$key}[1]  (bottom 25% of cohort)";
        }
        elsif ($studentStatisticsList{$key}[4] == 1) {
            say "    $key.....$studentStatisticsList{$key}[0]/$studentStatisticsList{$key}[1]  (score > 1σ below mean)";
        }
    }
}

# True statement needed for use-statement (module import/export)
42;