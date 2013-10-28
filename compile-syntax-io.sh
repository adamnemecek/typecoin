#!/bin/sh
sed -e 's/\btype\b/iotype/g' -e 's/\bdatatype\b/iodatatype/g' syntax.sml > syntax-io.ioml && iotype syntax-io.ioml && sed -i -e 's/writeString/IOTypes.writeString/g' -e 's/readString/IOTypes.readString/g' -e 's/writeBool/IOTypes.writeBool/g' -e 's/readBool/IOTypes.readBool/g' -e 's/Int16.writeInt/writeInt/g' -e 's/Int16.readInt/readInt/g' -e 's/writeInt/IOTypes.writeInt/g' -e 's/readInt/IOTypes.readInt/g' -e 's/IntInf.IOTypes.writeInt/IOIntInf.writeInt/g' -e 's/IntInf.IOTypes.readInt/IOIntInf.readInt/g' -e 's/writeList/IOTypes.writeList/g' -e 's/readList/IOTypes.readList/g' -e 's/Word8Vector.writeVector/IOTypes.writeWord8Vector/g' -e 's/Word8Vector.readVector/IOTypes.readWord8Vector/g' syntax-io.sml
