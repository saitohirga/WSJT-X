#include "revision_utils.hpp"

#include <cstring>

#include <QCoreApplication>
#include <QRegularExpression>

#include "svnversion.h"

namespace
{
  QString revision_extract_number (QString const& s)
  {
    QString revision;

    // try and match a number
    QRegularExpression re {R"(^[$:]\w+: (\d+[^$]*)\$$)"};
    auto match = re.match (s);
    if (match.hasMatch ())
      {
        revision = 'r' + match.captured (1);
      }
    return revision;
  }
}

QString revision (QString const& svn_rev_string)
{
  QString result;
  auto revision_from_svn = revision_extract_number (svn_rev_string);

#if defined (CMAKE_BUILD)
  QString svn_info {":Rev: " WSJTX_STRINGIZE (SVNVERSION) " $"};

  auto revision_from_svn_info = revision_extract_number (svn_info);
  if (!revision_from_svn_info.isEmpty ())
    {
      // we managed to get the revision number from svn info etc.
      result = revision_from_svn_info;
    }
  else if (!revision_from_svn.isEmpty ())
    {
      // fall back to revision in ths file, this is potentially
      // wrong because svn only updates the id when this file is
      // touched
      //
      // this case gets us a revision when someone builds from a
      // source snapshot or copy
      result = revision_from_svn;
    }
  else
    {
      // match anything
      QRegularExpression re {R"(^[$:]\w+: ([^$]*)\$$)"};
      auto match = re.match (svn_info);
      if (match.hasMatch ())
        {
          result = match.captured (1);
        }
    }
#else
  if (!revision_from_svn.isEmpty ())
    {
      // not CMake build so all we have is svn revision in this file
      result = revision_from_svn;
    }
#endif
  if (result.isEmpty ())
    {
      result = "local";       // last resort fall back
    }
  return result.trimmed ();
}

QString program_title (QString const& revision)
{
#if defined (CMAKE_BUILD)
  QString id {QCoreApplication::applicationName () + "   v" WSJTX_STRINGIZE (WSJTX_VERSION_MAJOR) "." WSJTX_STRINGIZE (WSJTX_VERSION_MINOR) "." WSJTX_STRINGIZE (WSJTX_VERSION_PATCH)};

# if defined (WSJTX_RC)
  id += "-rc" WSJTX_STRINGIZE (WSJTX_RC);
# endif

#else
  QString id {"WSJT-X Not for Release"};
#endif
  return id + " " + revision + "  by K1JT";
}
