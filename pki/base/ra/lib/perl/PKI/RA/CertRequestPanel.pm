#!/usr/bin/perl
#
# --- BEGIN COPYRIGHT BLOCK ---
# This program is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation; version 2 of the License.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License along
# with this program; if not, write to the Free Software Foundation, Inc.,
# 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301 USA.
#
# Copyright (C) 2007 Red Hat, Inc.
# All rights reserved.
# --- END COPYRIGHT BLOCK ---
#
#
#
#

use strict;
use warnings;
use PKI::RA::GlobalVar;
use PKI::RA::Common;
use PKI::RA::ReqCertInfo;
use FileHandle;

package PKI::RA::CertRequestPanel;
$PKI::RA::CertRequestPanel::VERSION = '1.00';

use PKI::RA::BasePanel;
our @ISA = qw(PKI::RA::BasePanel);

our $cert_req_header="-----BEGIN NEW CERTIFICATE REQUEST-----";
our $cert_req_footer="-----END NEW CERTIFICATE REQUEST-----";
our $cert_header="-----BEGIN CERTIFICATE-----";
our $cert_footer="-----END CERTIFICATE-----";

sub new { 
    my $class = shift;
    my $self = {}; 

    $self->{"isSubPanel"} = \&is_sub_panel;
    $self->{"hasSubPanel"} = \&has_sub_panel;
    $self->{"isPanelDone"} = \&PKI::RA::Common::no;
    $self->{"getPanelNo"} = &PKI::RA::Common::r(13);
    $self->{"getName"} = &PKI::RA::Common::r("Certificate Requests");
    $self->{"vmfile"} = "certrequestpanel.vm";
    $self->{"update"} = \&update;
    $self->{"panelvars"} = \&display;
    bless $self,$class; 
    return $self; 
}

sub is_sub_panel
{
    my ($q) = @_;
    return 0;
}

sub has_sub_panel
{
    my ($q) = @_;
    return 0;
}

sub validate
{
    my ($q) = @_;
    &PKI::RA::Wizard::debug_log("CertRequestPanel: validate");
    return 1;
}

sub update
{
    my ($q) = @_;
    &PKI::RA::Wizard::debug_log("CertRequestPanel: update");

    my $i = 0;

    my $instanceDir = $::config->get("service.instanceDir");

    my $useExternalCA = $::config->get("preop.certenroll.useExternalCA");
    if ($useExternalCA eq "on") {
        &PKI::RA::Wizard::debug_log("CertRequestPanel: update: useExternalCA is on");
    } else {
        &PKI::RA::Wizard::debug_log("CertRequestPanel: update: useExternalCA is off");
        &PKI::RA::Wizard::debug_log("CertRequestPanel: update auto enrollment should have been done, no more action needed");
        return 1;
    }

    &PKI::RA::Wizard::debug_log("CertRequestPanel: update External CA selected, retrieve/process user input");

    my $tokenname = $::config->get("preop.module.token");
    &PKI::RA::Wizard::debug_log("CertRequestPanel: update got token name = $tokenname");
    my $token_pwd = $::pwdconf->get($tokenname);
    $token_pwd  =~ s/\n//g;
    open FILE, ">$instanceDir/conf/.pwfile";
    system( "chmod 00660 $instanceDir/conf/.pwfile" );
    print FILE $token_pwd;
    close FILE;

    my $hw;
    my $tk;

    if (($tokenname eq "") || ($tokenname eq "NSS Certificate DB")) {
        $hw = "";
        $tk = "";
    } else {
        $hw = "-h $tokenname";
        $tk = $tokenname.":";
    }

    foreach my $certtag (@PKI::RA::Wizard::certtags) {
        if ($certtag eq "subsystem") {
            &PKI::RA::Wizard::debug_log("CertRequestPanel: update: subsystem cert is pre-generated by the security domain");
            return 1;
        }
        &PKI::RA::Wizard::debug_log("CertRequestPanel: update: for certag= $certtag");
        my $ccert = $::config->get("preop.cert.$certtag.cert");
        if ($ccert ne "") {
            &PKI::RA::Wizard::debug_log("CertRequestPanel: update: cert already exists in CS.cfg, go to next");
            next;
        }
        my $certchain = $q->param($certtag.'_cc');
        if ($certchain ne "") {
            &PKI::RA::Wizard::debug_log("CertRequestPanel: update: $certtag certchain is $certchain");
            my $cc_fn = "$instanceDir/conf/caCertChain.txt";
            my $tmp = `echo "$certchain" > $cc_fn`;
            # remove existing one
            &PKI::RA::Wizard::debug_log("CertRequestPanel: update: try to delete existing certchain, if any....ok if it fails");
# XXX remove should not be done lightly...
            $tmp = `p7tool -d $instanceDir/alias -p $instanceDir/conf/chain1cert -a -i $cc_fn -o $instanceDir/conf/CAchain_pp.txt`;
            my $r =  $? >> 8;
            my $failed = $? & 127;
            if (($r > 0) && ($r < 10) && !$failed)  {
                my $i = 0;
                while ($i ne $r) {
                    $tmp = `certutil -d $instanceDir/alias -D -n "Trusted CA $certtag cert$i"`;
                    $tmp = `certutil -d $instanceDir/alias -A -f $instanceDir/conf/.pwfile -n "Trusted CA $certtag cert$i"  -t "CT,C,C" -i $instanceDir/conf/chain1cert$i.der`;
#            $tmp = `rm $cc_fn`;
                  $i++
                }
            }
        } else {
            &PKI::RA::Wizard::debug_log("CertRequestPanel: update: no certchain included for certtag $certtag");
        }

        my $cert = $q->param($certtag);
        if ($cert ne "") {
            &PKI::RA::Wizard::debug_log("CertRequestPanel: update: $certtag cert is $cert");
            my $nickname = $::config->get("preop.cert.$certtag.nickname");
            if ($nickname eq "") {
                $nickname = "RA ".$certtag." cert";
                $::config->put("preop.cert.$certtag.nickname", $nickname);
                &PKI::RA::Wizard::debug_log("CertRequestPanel: update: $certtag cert nickname not found in CS.cfg, generating one= $nickname");
            }
            #remove existing one
            &PKI::RA::Wizard::debug_log("CertRequestPanel: update: try to delete existing cert $nickname, if any....ok if it fails");
#XXX remove should not be done lightly...
            my $tmp = `certutil -d $instanceDir/alias -D -n "$nickname"`;
            $tmp = `certutil -d $instanceDir/alias -D $hw -f $instanceDir/conf/.pwfile -n "$tk$nickname"`;
            #now import the cert
            &PKI::RA::Wizard::debug_log("CertRequestPanel: update: try to import cert");
            my $cert_fn = "$instanceDir/conf/$certtag"."_cert.txt";
            $tmp = `echo "$cert" > $cert_fn`;

#            $cert = extract_cert_from_file_sans_header_and_footer($cert_fn); 
            my $certa ="";
            my $save_line = 0;
            my @cert_a = split "\n", $cert;
            foreach my $line (@cert_a) {
                chomp( $line );
                $line =~ s/\r//g;
                if ($line eq $cert_header) {
                    $save_line = 1;
                } elsif( $line eq $cert_footer ) {
                    $save_line = 0;
                    last;
                } elsif( $save_line == 1 ) {
                    $certa .= "$line";
                }
            }

            &PKI::RA::Wizard::debug_log("CertRequestPanel: update putting cert in CS.cfg: $certa");

            $::config->put("preop.cert.$certtag.cert", $certa);

            &PKI::RA::Wizard::debug_log("CertRequestPanel: update: about to certutil -d $instanceDir/alias $hw -A -f $instanceDir/conf/.pwfile -n $nickname -t u,u,u -a -i $cert_fn");
            $tmp = `certutil -d $instanceDir/alias $hw -A -f $instanceDir/conf/.pwfile -n "$nickname" -t "u,u,u" -a -i $cert_fn`;
            &PKI::RA::Wizard::debug_log("CertRequestPanel: update: done certutil: $tmp");
            $tmp = `rm $cert_fn`;

            # changed the cert, need to change nickname too, if necessary
            if ($hw ne "") {
                $::config->put("preop.cert.$certtag.nickname", "$tk$nickname");
                if ($certtag eq "subsystem") {
                    $::config->put("conn.ca1.clientNickname","$tk$nickname");
                    $::config->put("conn.drm1.clientNickname","$tk$nickname");
                    $::config->put("conn.tks1.clientNickname","$tk$nickname");
                }
            }

        } else {
            &PKI::RA::Wizard::debug_log("CertRequestPanel: update: no cert");
        }
    }

DONE:
    $::config->commit();
    my $tmp = `rm $instanceDir/conf/.pwfile`;

    return 1;
}

sub display
{
    my ($q) = @_;
    &PKI::RA::Wizard::debug_log("CertRequestPanel: display");

    my $domain_name = $::config->get("preop.securitydomain.name");
    if ($domain_name eq "") {
        $domain_name = "RA Domain";
    }
    my $machine_name = $::config->get("service.machineName");
    my $instance_id = $::config->get("service.instanceID");

    my $i = 0;
    foreach my $certtag (@PKI::RA::Wizard::certtags) {
        my $cert_dn = $::config->get("preop.cert.".$certtag.".dn");
        if ($cert_dn eq "") {
            if ($certtag eq "subsystem") {
                $cert_dn = "CN=RA Subsystem, " .
                  "OU=" . $instance_id . ", " .
                  "O=" . $domain_name;
            } elsif ($certtag eq "sslserver") {
                $cert_dn ="CN=" . $machine_name . ", " .
                  "OU=" . $instance_id . ", " .
                  "O=" . $domain_name;
            } else {
                $cert_dn = $certtag;
            }
        }

        my $name = $::config->get("preop.cert.".$certtag.".userfriendlyname");
        if ($name eq "") {
            $name = $certtag."Cert ".$instance_id;
        }

        my $reqcert = new PKI::RA::ReqCertInfo($name,
                  $cert_dn, $certtag);
        $::symbol{reqscerts}[$i++] = $reqcert;
    }

    $::symbol{errorString} = "";
    $::symbol{showApplyButton} = "true";

    return 1;
}

# arg0 message containing certificate
# return certificate sans header and footer
# -- all in a one-liner
sub extract_cert_from_file_sans_header_and_footer
{
    my $filename = $_[0];
    my $save_line = 0;

    my $fd = new FileHandle;

    my $cert = "";

    $fd->open( "<$filename" ) or die "Could not open '$filename'!\n";

    while( <$fd> )
    {
        my $line = $_;
        chomp( $line );
        $line =~ s/^M//g;

        if( $line eq $cert_header ) {
            $save_line = 1;
        } elsif( $line eq $cert_footer ) {
            $save_line = 0;
            last;
        } elsif( $save_line == 1 ) {
            $cert .= "$line";
        }
    }

    $fd->close();

    return $cert;
}


1;
