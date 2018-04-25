FROM openjdk:jdk-alpine

ENV GEOSERVER_VERSION="2.8.5" \
    GDAL_VERSION="2.2.4" \
    ANT_VERSION="1.9.11" \
    ANT_HOME="/usr/local/ant" \
    LD_LIBRARY_PATH="$LD_LIBRARY_PATH:/usr/local/lib/:/opt/jdk/lib" \
    _POSIX2_VERSION="199209" \
    JAVA_HOME="/opt/jdk" \
    PATH="$PATH:/opt/jdk/bin:/usr/local/ant/bin"

RUN apk add --no-cache --virtual .build-deps g++ make swig openjdk8-jre-base \
 && apk add --no-cache libstdc++ \
 && downloadDir="$(mktemp -d)" \
 && buildDir="$(mktemp -d)" \
 && wget http://download.osgeo.org/gdal/${GDAL_VERSION}/gdal-${GDAL_VERSION}.tar.gz -O "$downloadDir/gdal.tar.gz" \
 && tar xzf "$downloadDir/gdal.tar.gz" -C "$buildDir" \
 && cd "$buildDir/gdal-${GDAL_VERSION}" \
 && ./configure  --with-java=$JAVA_HOME \
 && make \
 && make install \
 && rm -rf "$downloadDir" "$buildDir" \
 && apk del .build-deps
