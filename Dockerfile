FROM anapsix/alpine-java:9_jdk as jdk
FROM huggla/alpine:edge

COPY --from=jdk /opt /opt

ENV GDAL_VERSION="2.2.4" \
    ECW_VERSION="5.3.0" \
    ANT_VERSION="1.10.3" \
    ANT_HOME="/opt/ant" \
    _POSIX2_VERSION="199209" \
    JAVA_HOME="/opt/jdk" \
    PATH="$PATH:/opt/jdk/bin:/opt/ant/bin"
ENV LD_LIBRARY_PATH="$LD_LIBRARY_PATH:/usr/local/lib/:$JAVA_HOME/lib/amd64/jli:$JAVA_HOME/lib"

RUN apk add --no-cache --virtual .build-deps build-base curl-dev giflib-dev jpeg-dev libjpeg-turbo-dev libpng-dev linux-headers postgresql-dev python2-dev sqlite-dev swig tiff-dev zlib-dev g++ libstdc++ \
 && apk add --no-cache --repository http://dl-3.alpinelinux.org/alpine/edge/testing/ --allow-untrusted --virtual .build-deps2 proj4-dev \
 && downloadDir="$(mktemp -d)" \
 && buildDir="$(mktemp -d)" \
 && cd "$downloadDir" \
 && wget http://s3-eu-west-1.amazonaws.com/mapcentia-tmp/ERDAS-ECW_JPEG_2000_SDK-$ECW_VERSION.zip \
 && unzip ERDAS-ECW_JPEG_2000_SDK-$ECW_VERSION.zip \
 && mkdir /opt/hexagon \
 && cp -r ERDAS-ECW_JPEG_2000_SDK-$ECW_VERSION/Desktop_Read-Only/* /opt/hexagon \
 && ln -s /opt/hexagon/lib/x64/release/libNCSEcw.so /usr/local/lib/libNCSEcw.so \
 && ln -s /opt/hexagon/lib/x64/release/libNCSEcw.so.$ECW_VERSION /usr/local/lib/libNCSEcw.so.$ECW_VERSION \
 && rm -rf /opt/hexagon/lib/x86 \
 && rm -rf ERDAS-ECW_JPEG_2000_SDK-$ECW_VERSION.zip ERDAS-ECW_JPEG_2000_SDK-$ECW_VERSION \
 && wget http://download.osgeo.org/gdal/${GDAL_VERSION}/gdal-${GDAL_VERSION}.tar.gz -O "$downloadDir/gdal.tar.gz" \
 && tar xzf "$downloadDir/gdal.tar.gz" -C "$buildDir" \
 && sed -i 's/source="1.5"/source="1.6"/g' "$buildDir/gdal-${GDAL_VERSION}/swig/java/build.xml" \
 && sed -i 's/target="1.5"/target="1.6"/g' "$buildDir/gdal-${GDAL_VERSION}/swig/java/build.xml" \
 && cd "$buildDir/gdal-${GDAL_VERSION}" \
 && ./configure --prefix=/opt/gdal --with-java=$JAVA_HOME \
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
 && apk del .build-deps .build-deps2

USER sudoer
