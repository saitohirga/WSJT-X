#ifndef COLORHIGHLIGHTING_H
#define COLORHIGHLIGHTING_H

#include <QDialog>
#include <QSettings>

namespace Ui {
class ColorHighlighting;
}

class ColorHighlighting : public QDialog
{
  Q_OBJECT

public:
  explicit ColorHighlighting(QSettings *, QWidget *parent = 0);
  ~ColorHighlighting();
  void colorHighlightlingSetup(QColor color_CQ, QColor color_MyCall,
       QColor color_DXCC, QColor color_DXCCband, QColor color_NewCall,
       QColor color_NewCallBand, QColor color_NewGrid, QColor color_NewGridBand,
       QColor color_TxMsg, QColor color_LoTW);

private:
  QSettings * settings_;
  void read_settings ();
  void write_settings ();
  Ui::ColorHighlighting *ui;
};

#endif // COLORHIGHLIGHTING_H
