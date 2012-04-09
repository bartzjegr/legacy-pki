// --- BEGIN COPYRIGHT BLOCK ---
// This program is free software; you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation; version 2 of the License.
//
// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU General Public License for more details.
//
// You should have received a copy of the GNU General Public License along
// with this program; if not, write to the Free Software Foundation, Inc.,
// 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301 USA.
//
// (C) 2007 Red Hat, Inc.
// All rights reserved.
// --- END COPYRIGHT BLOCK ---
package com.netscape.cmscore.request;


import java.util.Hashtable;
import java.util.Date;

import com.netscape.certsrv.request.RequestId;
import com.netscape.certsrv.request.RequestStatus;


/**
 * The low level (attributes only) version of the database
 * record object.  This exists so that RecordAttr methods can use
 * this type definition, 
 * 
 * RequestRecord refers both to this class and to RecordAttr objects.
 */
class ARequestRecord { 
    RequestId mRequestId;
    RequestStatus mRequestState;
    Date mCreateTime;
    Date mModifyTime;
    String mSourceId;
    String mOwner;
    String mRequestType;
    Hashtable mExtData;
};
