#ifndef DISPLAYTEXT_H
#define DISPLAYTEXT_H

#include <QTextBrowser>

class DisplayText : public QTextBrowser
{
    Q_OBJECT
public:
  explicit DisplayText(QWidget *parent = 0);

  void setFont(QFont font);
  int getMaxDisplayedCharacters() { return _maxDisplayedCharacters; }


signals:
  void selectCallsign(bool shift, bool ctrl);

public slots:


protected:
  void mouseDoubleClickEvent(QMouseEvent *e);
  void resizeEvent(QResizeEvent * event);

private:
  int _fontWidth;
  int _maxDisplayedCharacters;

};

#endif // DISPLAYTEXT_H
