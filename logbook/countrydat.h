/*
 * Reads cty.dat file
 * Establishes a map between prefixes and their country names
 * VK3ACF July 2013
 */


#ifndef __COUNTRYDAT_H
#define __COUNTRYDAT_H


#include <QString>
#include <QStringList>
#include <QHash>


class CountryDat
{
	public:
        void init(const QString filename);
		void load();
        QString find(const QString prefix); // return country name or ""
		QStringList  getCountryNames() { return _countryNames; };
   
	private:
        QString _extractName(const QString line);
        void _removeBrackets(QString &line, const QString a, const QString b);
        QStringList _extractPrefix(QString &line, bool &more);
		
        QString _filename;
		QStringList _countryNames;
		QHash<QString, QString> _data;
};

#endif
