This boost tree is a cut down version of the 1.63.0 source tree built
using the boost bcp utility, invoked thus:

cd <clean-boost-source-tree>
<path-where-bcp-was-built>/bcp iterator range math numeric crc circular_buffer build bootstrap.bat bootstrap.sh boostcpp.jam boost-build.jam <this-directory>

Note that bcp is built from a separate boost source tree to avoid
polluting the clean tree used to extract components from above.

Add other boost libraries as necessary. See the Subversion book for
details on how to maintain 3rd-party vendor content used in a project.
