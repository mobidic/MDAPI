package MD::Dispatch;
use base 'CGI::Application::Dispatch';


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

#http://194.167.35.137/MDAPI/1/Genes/gene_details_json => ':app/:rm' => {},
#http://194.167.35.137/MDAPI/1/Genes/list_json ... works
#http://194.167.35.137/MDAPI/1/genes => 'genes'                => { app => 'Genes', rm => 'list'},
#

sub dispatch_args {
    return {
        prefix  => 'MD',
        default => 'Genes',
        table   => [
            'exists/:gene_name' => { app => 'Genes', rm => 'exists'},
            'details/:gene_name'  => { app => 'Genes', rm => 'single_gene_details'},
            'admin/change_acc_ver/:acc_no'  => {
                prefix   => 'MD::Admin',
                app => 'Genes',
                rm => 'change_acc_ver' ,
                args_to_new => {
                    PARAMS => {
                        user => $ENV{REMOTE_USER},
                        addr => $ENV{REMOTE_ADDR},
                    },
                }
            },
            'admin/:app/:rm'  => {
                prefix   => 'MD::Admin',
                 ,
                args_to_new => {
                    PARAMS => {
                        user => $ENV{REMOTE_USER},
                        addr => $ENV{REMOTE_ADDR},
                    },
                }
            },
            ':app/:rm' => {},
        ]
    };
}


1;