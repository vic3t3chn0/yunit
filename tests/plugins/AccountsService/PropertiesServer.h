/*
 * Copyright 2013 Canonical Ltd.
 *
 * This program is free software: you can redistribute it and/or modify it
 * under the terms of the GNU General Public License version 3, as published
 * by the  Free Software Foundation.
 *
 * This program is distributed in the hope that it will be useful, but
 * WITHOUT ANY WARRANTY; without even the implied warranties of
 * MERCHANTABILITY, SATISFACTORY QUALITY or FITNESS FOR A PARTICULAR
 * PURPOSE.  See the GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * version 3 along with this program.  If not, see
 * <http://www.gnu.org/licenses/>
 *
 * Authored by: Michael Terry <michael.terry@canonical.com>
 */

#ifndef UNITY_PROPERTIESSERVER_H
#define UNITY_PROPERTIESSERVER_H

#include "PropertiesServer.h"
#include <QDBusContext>
#include <QDBusVariant>
#include <QObject>
#include <QString>

class PropertiesServer: public QObject, protected QDBusContext
{
    Q_OBJECT

public:
    explicit PropertiesServer(QObject *parent = 0);

    QDBusVariant Get(const QString &interface, const QString &property);
    void Set(const QString &interface, const QString &property, const QDBusVariant &variant);

private:
    bool edge_demo;
};

#endif
