/*
 * Reads an ADIF log file into memory
 * Searches log for call, band and mode
 * VK3ACF July 2013
 */


#ifndef __ADIF_H
#define __ADIF_H

#if defined (QT5)
#include <QList>
#include <QString>
#include <QMultiHash>
#else
#include <QtGui>
#endif


class ADIF
{
	public:
        void init(QString filename);
		void load();
        void add(const QString call, const QString band, const QString mode, const QString date);
        bool match(const QString call, const QString band, const QString mode);
        QList<QString> getCallList();
		int getCount();
		
        // open ADIF file and append the QSO details. Return true on success
        bool addQSOToFile(const QString hisCall, const QString hisGrid, const QString mode, const QString rptSent, const QString rptRcvd, const QString date, const QString time, const QString band,
                                const QString comments, const QString name, const QString strDialFreq, const QString m_myCall, const QString m_myGrid, const QString m_txPower);

        static QString bandFromFrequency(double dialFreq);

	private:
		struct QSO
		{
		  QString call,band,mode,date;
		};		  

        QMultiHash<QString, QSO> _data;
		QString _filename;
		
        QString _extractField(const QString line, const QString fieldName);
};


#endif

