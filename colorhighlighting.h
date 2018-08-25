#ifndef COLORHIGHLIGHTING_H
#define COLORHIGHLIGHTING_H

#include <QDialog>

namespace Ui {
class ColorHighlighting;
}

class ColorHighlighting : public QDialog
{
  Q_OBJECT

public:
  explicit ColorHighlighting(QWidget *parent = 0);
  ~ColorHighlighting();

private:
  Ui::ColorHighlighting *ui;
};

#endif // COLORHIGHLIGHTING_H
