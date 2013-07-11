// --- BEGIN COPYRIGHT BLOCK ---
// This library is free software; you can redistribute it and/or
// modify it under the terms of the GNU Lesser General Public
// License as published by the Free Software Foundation;
// version 2.1 of the License.
// 
// This library is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
// Lesser General Public License for more details.
// 
// You should have received a copy of the GNU Lesser General Public
// License along with this library; if not, write to the Free Software
// Foundation, Inc., 51 Franklin Street, Fifth Floor,
// Boston, MA  02110-1301  USA 
// 
// Copyright (C) 2013 Red Hat, Inc.
// All rights reserved.
// --- END COPYRIGHT BLOCK ---

#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include "authentication/ExternalRegAttrs.h"

#ifdef XP_WIN32
#define TPS_PUBLIC __declspec(dllexport)
#else /* !XP_WIN32 */
#define TPS_PUBLIC
#endif /* !XP_WIN32 */

ExternalRegCertKeyInfo::ExternalRegCertKeyInfo() {
}

ExternalRegCertKeyInfo::~ExternalRegCertKeyInfo() {
/*ToDo: free stuff*/
}

TPS_PUBLIC void ExternalRegCertKeyInfo::setCert(CERTCertificate *cert) {
    certificate = cert;
}

TPS_PUBLIC CERTCertificate *ExternalRegCertKeyInfo::getCert() {
    return certificate;
}

ExternalRegCertToRecover::ExternalRegCertToRecover() {
    caConn = NULL;
    drmConn = NULL;
}

ExternalRegCertToRecover::~ExternalRegCertToRecover() {
    if (certKeyInfo)
        delete certKeyInfo;
}

TPS_PUBLIC void ExternalRegCertToRecover::setCertKeyInfo(ExternalRegCertKeyInfo *ckInfo) {
    certKeyInfo = ckInfo;
}

TPS_PUBLIC ExternalRegCertKeyInfo *ExternalRegCertToRecover::getCertKeyInfo() {
    return certKeyInfo;
}

TPS_PUBLIC void ExternalRegCertToRecover::setSerial(PRUint64 snum) {
    serial = snum;
}

TPS_PUBLIC PRUint64 ExternalRegCertToRecover::getSerial() {
    return serial;
}

TPS_PUBLIC void ExternalRegCertToRecover::setKeyid(PRUint64 kid) {
    keyid = kid;
}

TPS_PUBLIC PRUint64 ExternalRegCertToRecover::getKeyid() {
    return keyid;
}

TPS_PUBLIC void ExternalRegCertToRecover::setCaConn(const char *conn) {
    caConn = conn;
}

TPS_PUBLIC const char* ExternalRegCertToRecover::getCaConn() {
    return caConn;
}

TPS_PUBLIC void ExternalRegCertToRecover::setDrmConn(const char *conn) {
    drmConn = conn;
}

TPS_PUBLIC const char* ExternalRegCertToRecover::getDrmConn() {
    return drmConn;
}

TPS_PUBLIC ExternalRegCertToDelete::ExternalRegCertToDelete() {
    caConn = NULL;
    revoke = false;
}

TPS_PUBLIC ExternalRegCertToDelete::~ExternalRegCertToDelete() {
    if (certKeyInfo)
        delete certKeyInfo;
}


TPS_PUBLIC void ExternalRegCertToDelete::setSerial(PRUint64 snum) {
    serial = snum;
}

TPS_PUBLIC PRUint64 ExternalRegCertToDelete::getSerial() {
    return serial;
}

TPS_PUBLIC void ExternalRegCertToDelete::setCaConn(const char *conn) {
    caConn = conn;
}

TPS_PUBLIC const char* ExternalRegCertToDelete::getCaConn() {
    return caConn;
}

TPS_PUBLIC void ExternalRegCertToDelete::setRevoke(bool rev) {
    revoke = rev;
}

TPS_PUBLIC bool ExternalRegCertToDelete::getRevoke() {
    return revoke;
}

TPS_PUBLIC ExternalRegAttrs::ExternalRegAttrs() {
    tokenCUID = NULL;
    tokenType = NULL;

    for (int i = 0; i < MAX_EXTERNAL_REG_CERTS; i++) {
        certsToRecover[i] = NULL;
        certsToDelete[i] = NULL;
    }
}

/**
 * Destructs processor.
 */
ExternalRegAttrs::~ExternalRegAttrs() {
    for (int i = 0; i < MAX_EXTERNAL_REG_CERTS; i++) {
        if (certsToRecover[i] != NULL) {
            delete certsToRecover[i];
            certsToRecover[i] = NULL;
        }
        if (certsToDelete[i] != NULL) {
            delete certsToDelete[i];
            certsToDelete[i] = NULL;
        }
    }
}

void ExternalRegAttrs::setTokenCUID(const char * cuid) {
    tokenCUID = cuid;
}

const char* ExternalRegAttrs::getTokenCUID() {
    return tokenCUID;
}

void ExternalRegAttrs::setTokenType(const char *tType) {
    tokenType = tType;
}

const char* ExternalRegAttrs::getTokenType() {
    return tokenType;
}

void ExternalRegAttrs::addCertToRecover(ExternalRegCertToRecover *ctr) {
    for (int i = 0; i < MAX_EXTERNAL_REG_CERTS; i++) {
        if (certsToRecover[i] == NULL) {
            certsToRecover[i] = ctr;
            return;
        }
    }
}

int ExternalRegAttrs::getCertsToRecoverCount() {
    for (int i = 0; i < MAX_EXTERNAL_REG_CERTS; i++) {
        if (certsToRecover[i] == NULL) {
            return i;
        }
    }
        return 0;
}

ExternalRegCertToRecover** ExternalRegAttrs::getCertsToRecover() {
    return certsToRecover;
}

void ExternalRegAttrs::addCertToDelete(ExternalRegCertToDelete *ctd) {
    for (int i = 0; i < MAX_EXTERNAL_REG_CERTS; i++) {
        if (certsToDelete[i] == NULL) {
            certsToDelete[i] = ctd;
            return;
        }
    }
}

int ExternalRegAttrs::getCertsToDeleteCount() {
    for (int i = 0; i < MAX_EXTERNAL_REG_CERTS; i++) {
        if (certsToDelete[i] == NULL) {
            return i;
        }
    }
        return 0;
}

ExternalRegCertToDelete** ExternalRegAttrs::getCertsToDelete() {
    return certsToDelete;
}
