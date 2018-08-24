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
#include <QRegularExpression>
#else
#include <QtGui>
#endif

class QDateTime;

class ADIF
{
	public:
	void init(QString const& filename);
	void load();
  void add(QString const& call, const QString &grid, QString const& band, QString const& mode,
           QString const& date);
	bool match(QString const& call, QString const& band, QString const& mode) const;
	QList<QString> getCallList() const;
	int getCount() const;
		
        // open ADIF file and append the QSO details. Return true on success
	bool addQSOToFile(QByteArray const& ADIF_record);

  QByteArray QSOToADIF(QString const& hisCall, QString const& hisGrid, QString const& mode, QString const& rptSent
											 , QString const& rptRcvd, QDateTime const& dateTimeOn, QDateTime const& dateTimeOff
											 , QString const& band, QString const& comments, QString const& name
											 , QString const& strDialFreq, QString const& m_myCall, QString const& m_myGrid
											 , QString const& m_txPower, QString const& operator_call);

private:
		struct QSO
		{
      QString call,grid,band,mode,date;
		};		  

    QMultiHash<QString, QSO> _data;
    QMultiHash<QString, QSO> _data2;
    QString _filename;
		QString extractField(QString const& line, QString const& fieldName) const;
};

#endif

