ARG TAG="20190327"
ARG DESTDIR="/gdal"

FROM huggla/alpine as alpine

ARG BUILDDEPS="openjdk8 build-base curl-dev giflib-dev jpeg-dev libjpeg-turbo-dev libpng-dev linux-headers postgresql-dev python2-dev sqlite-dev swig tiff-dev zlib-dev g++ libstdc++"
ARG BUILDDEPS_TESTING="geos-dev proj4-dev"
ARG GDAL_VERSION="2.4.1"
ARG ECW_VERSION="5.3.0"
ARG ANT_VERSION="1.10.5"
ARG DOWNLOADS="https://s3-eu-west-1.amazonaws.com/mapcentia-tmp/ERDAS-ECW_JPEG_2000_SDK-$ECW_VERSION.zip https://download.osgeo.org/gdal/${GDAL_VERSION}/gdal-${GDAL_VERSION}.tar.gz https://www.apache.org/dist/ant/binaries/apache-ant-${ANT_VERSION}-bin.tar.gz"
ARG DESTDIR
ARG ANT_HOME="/opt/ant"
ARG _POSIX2_VERSION="199209"
ARG JAVA_HOME="/usr/lib/jvm/java-1.8-openjdk"
ARG PATH="/bin:/sbin:/usr/bin:/usr/sbin:$JAVA_HOME/bin:$ANT_HOME/bin"
ARG LD_LIBRARY_PATH="/lib:/usr/lib:$JAVA_HOME/lib/amd64/jli:$JAVA_HOME/lib"

RUN mkdir -p $DESTDIR/usr/share $ANT_HOME $DESTDIR-dev/usr/bin $DESTDIR-dev/usr/lib $DESTDIR-py \
 && apk add $BUILDDEPS \
 && apk add --no-cache --repository http://dl-3.alpinelinux.org/alpine/edge/testing/ --allow-untrusted $BUILDDEPS_TESTING \
 && downloadDir="$(mktemp -d)" \
 && buildDir="$(mktemp -d)" \
 && cd "$downloadDir" \
 && wget $DOWNLOADS \
 && tarFiles="$(ls *.tar.*)" \
 && for tar in $tarFiles; \
    do \
       tar -xvp -f "$tar" -C $buildDir; \
    done \
 && zipFiles="$(ls *.zip)" \
 && for zip in $zipFiles; \
    do \
       unzip -o "$zip" -d $buildDir; \
    done \
 && cd $buildDir \
 && cp -a ERDAS-ECW_JPEG_2000_SDK-$ECW_VERSION/Desktop_Read-Only /opt/hexagon \
 && rm -rf $downloadDir ERDAS-ECW_JPEG_2000_SDK-$ECW_VERSION /opt/hexagon/lib/x86 \
 && ln -s /opt/hexagon/lib/x64/release/libNCSEcw.so /usr/lib/libNCSEcw.so \
 && ln -s /opt/hexagon/lib/x64/release/libNCSEcw.so.$ECW_VERSION /usr/lib/libNCSEcw.so.$ECW_VERSION \
 && sed -i 's/source="1.5"/source="1.6"/g' gdal-${GDAL_VERSION}/swig/java/build.xml \
 && sed -i 's/target="1.5"/target="1.6"/g' gdal-${GDAL_VERSION}/swig/java/build.xml \
 && cd gdal-${GDAL_VERSION} \
 && ./configure --prefix=/usr --with-curl=/usr/bin/curl-config --with-java=$JAVA_HOME --without-ld-shared --disable-shared --enable-static \
 && make \
 && make install \
 && cp -a $buildDir/apache-ant-${ANT_VERSION}/bin $buildDir/apache-ant-${ANT_VERSION}/lib $ANT_HOME/ \
 && cd $buildDir/gdal-${GDAL_VERSION}/swig/java \
 && sed -i '/JAVA_HOME =/d' java.opt \
 && make \
 && make install \
 && cp -a $buildDir/gdal-${GDAL_VERSION}/swig/java/gdal.jar $DESTDIR/usr/share/ \
 && cd $buildDir/gdal-${GDAL_VERSION}/swig/python \
	&& python2 setup.py build \
 && chmod -x $DESTDIR/usr/include/*.h \
 && python2 setup.py install --prefix=/usr --root=$DESTDIR-py \
	&& chmod a+x scripts/* \
	&& install -d $DESTDIR-py/usr/bin \
	&& install -m755 scripts/*.py $DESTDIR-py/usr/bin/ \
 && mv $DESTDIR/usr/include $DESTDIR-dev/usr/ \
 && mv $DESTDIR/usr/bin/gdal-config $DESTDIR-dev/usr/bin/
# && mv $DESTDIR/usr/lib/libgdal.a $DESTDIR/usr/lib/pkgconfig $DESTDIR-dev/usr/lib/ \
# && mv $DESTDIR/usr/bin/*.py $DESTDIR-py/usr/bin/ \
# && mv $DESTDIR/usr/lib/python2.7 $DESTDIR-py/usr/lib/

FROM huggla/busybox:$TAG as image

ARG DESTDIR

COPY --from=alpine $DESTDIR $DESTDIR-dev $DESTDIR-py /
