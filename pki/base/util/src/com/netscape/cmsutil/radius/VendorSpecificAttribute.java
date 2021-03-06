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
package com.netscape.cmsutil.radius;


import java.io.IOException;


public class VendorSpecificAttribute extends Attribute {
    private byte _value[] = null;
    private String _id = null;
    private String _str = null;

    public VendorSpecificAttribute(byte value[]) {
        super();
        _t = VENDOR_SPECIFIC;
        _id = new String(value, 2, 4);
        _str = new String(value, 6, value.length - 6);
        _value = value;
    }

    public String getId() {
        return _id;
    }

    public String getString() {
        return _str;
    }

    public byte[] getValue() throws IOException {
        byte v[] = new byte[_id.length() + _str.length()];
        byte idData[] = _id.getBytes();
        byte strData[] = _str.getBytes();

        System.arraycopy(idData, 0, v, 0, _id.length());
        System.arraycopy(strData, 0, v, _id.length(), _str.length());
        return v;
    }
}
