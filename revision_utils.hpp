#ifndef REVISION_UTILS_HPP__
#define REVISION_UTILS_HPP__

#include <QString>

QString revision (QString const& svn_rev_string = QString {});
QString program_title (QString const& revision = QString {});

#endif
