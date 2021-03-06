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
package com.netscape.certsrv.security;


import com.netscape.certsrv.base.EBaseException;


/**
 * An interface represents a generic token unit.
 *
 * @version $Revision$, $Date$
 */
public interface IToken {

    /**
     * Logins to the token unit.
     *
     * @param pin password to access the token
     * @exception EBaseException failed to login to this token
     */
    public void login(String pin) throws EBaseException;

    /**
     * Logouts token.
     */
    public void logout();
}
