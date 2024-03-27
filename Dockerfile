# Base
FROM ubuntu:22.04 AS base

RUN apt-get update -y
RUN apt-get install -y openjdk-8-jdk

# Build OPENCV
FROM base AS build_cv

RUN apt-get install -y git ant cmake build-essential libgtk2.0-dev pkg-config libavcodec-dev libavformat-dev libswscale-dev libtbb2 libtbb-dev libjpeg-dev libpng-dev libtiff-dev
RUN git clone https://github.com/opencv/opencv.git
RUN mkdir opencv/build
WORKDIR opencv
RUN git checkout -b 3.4.10 3.4.10
WORKDIR build
RUN cmake -D BUILD_SHARED_LIBS=OFF ..
RUN make -j4

# Build TPDockerSampleApp
FROM base AS tp_docker_sample_app

RUN apt-get install -y maven git libpng-dev
RUN git clone https://github.com/barais/TPDockerSampleApp/
WORKDIR TPDockerSampleApp
COPY --from=build_cv opencv/build/bin/opencv-3410.jar lib/opencv-3410.jar
RUN mvn install:install-file -Dfile=./lib/opencv-3410.jar \
     -DgroupId=org.opencv  -DartifactId=opencv -Dversion=3.4.10 -Dpackaging=jar
RUN mvn package

# Build image
FROM base AS final_image

# Cloning repo and installing deps
COPY --from=tp_docker_sample_app TPDockerSampleApp/lib lib
COPY --from=tp_docker_sample_app TPDockerSampleApp/haarcascades haarcascades
COPY --from=tp_docker_sample_app TPDockerSampleApp/target/fatjar-0.0.1-SNAPSHOT.jar prog.jar

# Running
CMD java -Djava.library.path=lib/ubuntuupperthan18/ -jar prog.jar
