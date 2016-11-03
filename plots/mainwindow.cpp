/***************************************************************************
**                                                                        **
**  QCustomPlot, an easy to use, modern plotting widget for Qt            **
**  Copyright (C) 2011-2016 Emanuel Eichhammer                            **
**                                                                        **
**  This program is free software: you can redistribute it and/or modify  **
**  it under the terms of the GNU General Public License as published by  **
**  the Free Software Foundation, either version 3 of the License, or     **
**  (at your option) any later version.                                   **
**                                                                        **
**  This program is distributed in the hope that it will be useful,       **
**  but WITHOUT ANY WARRANTY; without even the implied warranty of        **
**  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the         **
**  GNU General Public License for more details.                          **
**                                                                        **
**  You should have received a copy of the GNU General Public License     **
**  along with this program.  If not, see http://www.gnu.org/licenses/.   **
**                                                                        **
****************************************************************************
**           Author: Emanuel Eichhammer                                   **
**  Website/Contact: http://www.qcustomplot.com/                          **
**             Date: 13.09.16                                             **
**          Version: 2.0.0-beta                                           **
****************************************************************************/

/************************************************************************************************************
**                                                                                                         **
**  This is the example code for QCustomPlot.                                                              **
**                                                                                                         **
**  It demonstrates basic and some advanced capabilities of the widget. The interesting code is inside     **
**  the "setup(...)Demo" functions of MainWindow.                                                          **
**                                                                                                         **
**  In order to see a demo in action, call the respective "setup(...)Demo" function inside the             **
**  MainWindow constructor. Alternatively you may call setupDemo(i) where i is the index of the demo       **
**  you want (for those, see MainWindow constructor comments). All other functions here are merely a       **
**  way to easily create screenshots of all demos for the website. I.e. a timer is set to successively     **
**  setup all the demos and make a screenshot of the window area and save it in the ./screenshots          **
**  directory.                                                                                             **
**                                                                                                         **
*************************************************************************************************************/

#include "mainwindow.h"
#include "ui_mainwindow.h"
#include <QDebug>
#include <QDesktopWidget>
#include <QScreen>
#include <QMessageBox>
#include <QMetaEnum>

#include <fstream>
#include <iostream>

using namespace std;

MainWindow::MainWindow(QWidget *parent) :
  QMainWindow(parent),
  ui(new Ui::MainWindow)
{
  ui->setupUi(this);
  setGeometry(400, 250, 542, 390);
  
  setupDemo(0);
}

MainWindow::~MainWindow()
{
  delete ui;
}

void MainWindow::setupDemo(int demoIndex)
{
  switch (demoIndex)
  {
    case 0:  setupQuadraticDemo(ui->customPlot); break;
  }
  setWindowTitle("QCustomPlot: "+demoName);
  statusBar()->clearMessage();
  currentDemoIndex = demoIndex;
  ui->customPlot->replot();
}

void MainWindow::setupQuadraticDemo(QCustomPlot *customPlot)
{
  demoName = "Reference Spectrum";

#define NPTS 3456

  QVector<double> x(NPTS), y1(NPTS), y2(NPTS), y3(NPTS), y4(NPTS);
  ifstream inFile;
  double ymin=1.0e30;
  double ymax=-ymin;
  inFile.open("c:/users/joe/appdata/local/WSJT-X/refspec.dat");

  for (int i = 0; i < NPTS; i++) {
    inFile >> x[i] >> y1[i] >> y2[i] >> y3[3] >> y4[4];
    if(y2[i]>ymax) ymax=y2[i];
    if(y2[i]<ymin) ymin=y2[i];
  }
  customPlot->addGraph();
  customPlot->graph(0)->setData(x, y2);
  customPlot->xAxis->setLabel("Frequency (Hz)");
  customPlot->yAxis->setLabel("Relative power (dB)");
  customPlot->xAxis->setRange(0, 6000);
  customPlot->yAxis->setRange(ymin, ymax);
}
