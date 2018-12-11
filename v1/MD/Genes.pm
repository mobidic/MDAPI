package MD::Genes;

use base 'CGI::Application';
use strict;
use warnings;
use CGI::Application::Plugin::DBH (qw/dbh_config dbh/);
use JSON;
use File::Basename;

##    This program is part of MobiDetails
##    Copyright (C) 2012-2018  David Baux
##
##    This program is free software: you can redistribute it and/or modify
##    it under the terms of the GNU Affero General Public License as
##    published by the Free Software Foundation, either version 3 of the
##    License, or any later version.
##
##    This program is distributed in the hope that it will be useful,
##    but WITHOUT ANY WARRANTY; without even the implied warranty of
##    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
##    GNU Affero General Public License for more details.
##
##    You should have received a copy of the GNU Affero General Public License
##    along with this program.  If not, see <http://www.gnu.org/licenses/>.
##
##
##		API script to return gene info


#Global variables
# SQL tables
my ($GENE_TABLE);
#SQL attributes
my ($GENE_NAME, $T_NAME, $FULL_GENE, $CHR, $NG_ACC, $T_ACC_VERSION, $MAIN_T_STATUS);

sub setup {
    my $self = shift;
    $self->start_mode('list');
    $self->run_modes(
             'list' => 'get_genes',
             'list_json' => 'get_genes_json',
			 'exists' => 'gene_exists',
			 'details' => 'get_genes_details',
			 'details_json' => 'get_genes_details_json',
             'details_main' => 'get_genes_details_main',
			 'details_main_json' => 'get_genes_details_main_json',
             'single_gene_details' => 'single_gene_details',
             'single_gene_details_json' => 'single_gene_details_json',
	);
 
   # Connect to DBI database, with the same args as DBI->connect();
	my ($DB, $HOST, $DB_USER, $DB_PASSWORD);
    
	open F, dirname($ENV{SCRIPT_FILENAME}).'/v1/MD/MD.config' or die $!;
    while (<F>) {
        if (/database=(\w+)/o) {$DB = $1}
        elsif (/host=(\w+)/o) {$HOST = $1}
        elsif (/login=(\w+)/o) {$DB_USER = $1}
        elsif (/password=(.+)/o) {$DB_PASSWORD = $1}
        elsif (/GENE_TABLE=(.+)/o) {$GENE_TABLE = $1}
        elsif (/GENE_NAME=(.+)/o) {$GENE_NAME = $1}
        elsif (/T_NAME=(.+)/o) {$T_NAME = $1}
        elsif (/FULL_GENE=(.+)/o) {$FULL_GENE = $1}
        elsif (/CHR=(.+)/o) {$CHR = $1}
        elsif (/NG_ACC=(.+)/o) {$NG_ACC = $1}
        elsif (/T_ACC_VERSION=(.+)/o) {$T_ACC_VERSION = $1}
        elsif (/MAIN_T_STATUS=(.+)/o) {$MAIN_T_STATUS = $1}
    }
    close F;
    if ($DB ne '' && $HOST ne '' && $DB_USER ne '' && $DB_PASSWORD ne '') {
        $self->dbh_config("DBI:Pg:database=$DB;host=$HOST;",
                        $DB_USER,
                        $DB_PASSWORD,
                        {'RaiseError' => 1});
    }
    else {die "Unsufficient credentials for database\n"}
}

 
sub teardown {
     my $self = shift;
 
     # Disconnect when were done, (Although DBI usually does this automatically)
     $self->dbh->disconnect();
}
#http://194.167.35.137/MDAPI/1/genes/list
#https://194.167.35.158/MDAPI/1/genes/list
sub get_genes {
	my $self = shift;
	#my $sth = &get_genes_query($self, "SELECT DISTINCT nom[1] as gene FROM gene ORDER BY nom[1];");
    my $sth = &get_genes_query($self, "SELECT DISTINCT $GENE_NAME as gene FROM $GENE_TABLE ORDER BY $GENE_NAME;");
	my $response;
	while (my $result = $sth->fetchrow_hashref()) {
		$response .= "$result->{'gene'}\n";
	}
	return $response;
	
}
#http://194.167.35.137/MDAPI/1/genes/list_json
#https://194.167.35.158/MDAPI/1/genes/list_json
sub get_genes_json {
	my $self = shift;
	my $sth = &get_genes_query($self, "SELECT DISTINCT $GENE_NAME as gene, $CHR FROM $GENE_TABLE ORDER BY $GENE_NAME;");
	my $response;
	while (my $result = $sth->fetchrow_hashref()) {
		$response->{'Genes'}->{$result->{'gene'}}->{'chr'} =  $result->{$CHR};
	}
    &return_json($self, $response);
}
#http://194.167.35.137/MDAPI/1/exists/GENE_NAME
#https://194.167.35.158/MDAPI/1/exists/GENE_NAME
sub gene_exists {
    my $self = shift;
    my $dbh = $self->dbh();
    if (defined $self->param('gene_name') && $self->param('gene_name') =~ /^(\w+)$/o) {
        my $query = "SELECT $GENE_NAME as gene FROM $GENE_TABLE WHERE $GENE_NAME = '$1';";
        my $result = $dbh->selectrow_hashref($query);
        if ($result->{'gene'} eq $self->param('gene_name')) {return '1'}
        else {return '0'}
    }
    esle {return '0'}
}
#http://194.167.35.137/MDAPI/1/genes/details
#https://194.167.35.158/MDAPI/1/genes/details
sub get_genes_details {
	my ($self, $main) = @_;
    my $sth;
    if ($main eq 't') {$sth = &get_genes_query($self, "SELECT $GENE_NAME as gene, $T_NAME as transcript, $NG_ACC, $T_ACC_VERSION FROM $GENE_TABLE WHERE $MAIN_T_STATUS = 't' ORDER BY $GENE_NAME, $T_NAME;");}
	else {$sth = &get_genes_query($self, "SELECT $GENE_NAME as gene, $T_NAME as transcript, $NG_ACC, $T_ACC_VERSION FROM $GENE_TABLE ORDER BY $GENE_NAME, $T_NAME;")}
	my $response;
	while (my $result = $sth->fetchrow_hashref()) {
		$response .= "$result->{'gene'}\t$result->{'transcript'}.$result->{$T_ACC_VERSION}\t$result->{$NG_ACC}\n";
	}
	return $response;
}
sub get_genes_details_main {
	my $self = shift;
	return &get_genes_details($self, 't');
}
#http://194.167.35.137/MDAPI/1/genes/details_json
#https://194.167.35.158/MDAPI/1/genes/details_json
sub get_genes_details_json {
	my ($self, $main) = @_;
    my $sth;
    if ($main && $main eq 't') {$sth = &get_genes_query($self, "SELECT $GENE_NAME as gene, $T_NAME as transcript, $CHR,  $MAIN_T_STATUS as transcript, $NG_ACC, $T_ACC_VERSION FROM $GENE_TABLE WHERE $MAIN_T_STATUS = 't'");}
	else {$sth = &get_genes_query($self, "SELECT $GENE_NAME as gene, $T_NAME as transcript, $CHR, $NG_ACC, $T_ACC_VERSION, $MAIN_T_STATUS FROM $GENE_TABLE")}
	my $response;
	while (my $result = $sth->fetchrow_hashref()) {
        my $main = 'non-main-isoform';
        if ($result->{$MAIN_T_STATUS} eq '1') {$main = 'main-isoform'}
		$response->{$result->{'gene'}}->{"NG"} =  $result->{$NG_ACC};
        $response->{$result->{'gene'}}->{'chr'} = $result->{$CHR};
		push @{$response->{$result->{'gene'}}->{"NM"}}, [$result->{'transcript'}.".".$result->{$T_ACC_VERSION}, $main];
	}
    &return_json($self, $response);
	#return encode_json($response);
}
#http://194.167.35.137/MDAPI/1/genes/details_main_json
#https://194.167.35.158/MDAPI/1/genes/details_main_json
sub get_genes_details_main_json {
	my $self = shift;
	return &get_genes_details_json($self, 't');
}
#http://194.167.35.137/MDAPI/1/details/GENE_NAME
#https://194.167.35.158/MDAPI/1/details/GENE_NAME
sub single_gene_details {
    my $self = shift;
    if (&gene_exists($self) == 1) {
        my $dbh = $self->dbh();
        my $sth = &get_genes_query($self, "SELECT $GENE_NAME as gene, $T_NAME as transcript, $NG_ACC, $MAIN_T_STATUS, $CHR, $T_ACC_VERSION FROM $GENE_TABLE WHERE $GENE_NAME = '".$self->param('gene_name')."' ORDER BY $GENE_NAME, $T_NAME;");
        my $response;
        while (my $result = $sth->fetchrow_hashref()) {
            my $main = 'non-main-isoform';
            if ($result->{$MAIN_T_STATUS} eq '1') {$main = 'main-isoform'}
            $response .= "chr$result->{$CHR} $result->{'gene'} $result->{'transcript'}.$result->{$T_ACC_VERSION} $main $result->{$NG_ACC}\n";
        }
        return $response;
    }
    else {return '0'}
}
#http://194.167.35.137/MDAPI/1/details/json/GENE_NAME
#https://194.167.35.158/MDAPI/1/details/json/GENE_NAME
sub single_gene_details_json {
    my $self = shift;
    if (&gene_exists($self) == 1) {
        my $dbh = $self->dbh();
        my $sth = &get_genes_query($self, "SELECT $GENE_NAME as gene, $T_NAME as transcript, $NG_ACC, $MAIN_T_STATUS, $CHR, $T_ACC_VERSION FROM $GENE_TABLE WHERE $GENE_NAME = '".$self->param('gene_name')."';");
        my $response;
        while (my $result = $sth->fetchrow_hashref()) {
            my $main = 'non-main-isoform';
            if ($result->{$MAIN_T_STATUS} eq '1') {$main = 'main-isoform'}
            $response->{$result->{'gene'}}->{'NG'} = $result->{$NG_ACC};
            $response->{$result->{'gene'}}->{'chr'} = $result->{$CHR};
            $response->{$result->{'gene'}}->{'NM'} = [$result->{'transcript'}.$result->{$T_ACC_VERSION}, $main];
        }
        &return_json($self, $response);
    }
    else {return '0'}
}


sub get_genes_query {
	my ($self, $query) = @_;
	my $dbh = $self->dbh();
	my $sth = $dbh->prepare($query);
	my $res = $sth->execute();
	return $sth;
}

sub return_json {
    my ($self, $response) = @_;
    #my $json = to_json($response, {utf8 => 1} );
   # my $json = encode_json($response);
    #$json =~ s/"(\d+)"/$1/g; # to_json puts quotes around numbers, we take them off
    $self->header_add(-type => 'application/json' );
	return JSON->new->pretty->encode($response);
}

1;