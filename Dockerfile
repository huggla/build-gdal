FROM huggla/alpine

ENV GDAL_VERSION="2.2.4" \
    _POSIX2_VERSION="199209" \
    JAVA_HOME="/usr/lib/jvm/java-1.8-openjdk" \
    PATH="$PATH:/usr/lib/jvm/java-1.8-openjdk/jre/bin:/usr/lib/jvm/java-1.8-openjdk/bin"

RUN apk add --no-cache --virtual .build-deps build-base curl-dev giflib-dev jpeg-dev libjpeg-turbo-dev libpng-dev linux-headers postgresql-dev python2-dev sqlite-dev swig tiff-dev zlib-dev openjdk8 \
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
