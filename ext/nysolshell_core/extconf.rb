require "rubygems"
require "mkmf"


cp = "$(srcdir)"

xmlhead = `xml2-config --cflags`.chomp
$CFLAGS = " -O3 -Os -s -w -I.   -I#{cp}/help #{xmlhead} -DB_STATIC -D_NO_MAIN_ -DLINE  -lpthread -lboost_filesystem -lboost_regex -lboost_system -lxml2 -fPIC -Wno-error=format-security"
$CPPFLAGS = " -O3 -Os -s -w -I. -I#{cp}/help #{xmlhead}  -DB_STATIC -D_NO_MAIN_ -DLINE -lpthread -lboost_filesystem -lboost_regex -lboost_system  -lxml2  -fPIC -Wno-error=format-security"
$CXXFLAGS = " -O3 -Os -s -w -I. -I#{cp}/help #{xmlhead}  -DB_STATIC -D_NO_MAIN_ -DLINE  -lpthread -lboost_filesystem -lboost_regex -lboost_system  -lxml2  -fPIC -Wno-error=format-security"
$LIBS += " -lboost_filesystem -lboost_regex -lboost_system"

create_makefile("nysolshell_core")

