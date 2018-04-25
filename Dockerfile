FROM anapsix/alpine-java:9_jdk as jdk
FROM huggla/alpine

COPY --from=jdk /opt /opt

ENV GDAL_VERSION="2.2.4" \
    ANT_VERSION="1.10.3" \
    ANT_HOME="/opt/ant" \
    _POSIX2_VERSION="199209" \
    JAVA_HOME="/opt/jdk" \
    PATH="$PATH:/opt/jdk/bin:/opt/ant/bin"
ENV LD_LIBRARY_PATH="$LD_LIBRARY_PATH:/usr/local/lib/:$JAVA_HOME/lib/amd64/jli:$JAVA_HOME/lib"

RUN apk add --no-cache --virtual .build-deps build-base curl-dev giflib-dev jpeg-dev libjpeg-turbo-dev libpng-dev linux-headers postgresql-dev python2-dev sqlite-dev swig tiff-dev zlib-dev g++ libstdc++ \
 && downloadDir="$(mktemp -d)" \
 && buildDir="$(mktemp -d)" \
 && wget http://download.osgeo.org/gdal/${GDAL_VERSION}/gdal-${GDAL_VERSION}.tar.gz -O "$downloadDir/gdal.tar.gz" \
 && tar xzf "$downloadDir/gdal.tar.gz" -C "$buildDir" \
 && cd "$buildDir/gdal-${GDAL_VERSION}" \
 && ./configure --prefix=/opt/gdal --with-curl=/usr/bin/curl-config --with-java=$JAVA_HOME --without-ld-shared --disable-shared --enable-static \
 && make \
 && make install \
 && wget https://www.apache.org/dist/ant/binaries/apache-ant-${ANT_VERSION}-bin.tar.gz -O "$downloadDir/ant.tar.gz" \
 && tar xzf "$downloadDir/ant.tar.gz" -C "$downloadDir" \
 && mkdir /opt/ant \
 && mv "$downloadDir/apache-ant-${ANT_VERSION}/bin" /opt/ant/bin \
 && mv "$downloadDir/apache-ant-${ANT_VERSION}/lib" /opt/ant/lib \
 && cd "$buildDir/gdal-${GDAL_VERSION}/swig/java" \
 && sed -i '/JAVA_HOME =/d' java.opt \
 && make \
 && make install \
 && mv *.so /usr/local/lib/ \
 && mv "$buildDir/gdal-${GDAL_VERSION}/swig/java/gdal.jar" /usr/share/gdal.jar \
 && rm -rf "$buildDir" \
 && chmod -x /opt/gdal/include/*.h \
 && rm -rf "$downloadDir" "$buildDir" \
 && apk del .build-deps

USER sudoer
