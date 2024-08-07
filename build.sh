# 1 compile and install, use command:
# bash build.sh
#
# 2 remove all build files, use command:
# bash build.sh clean
#
# 3 remove all build files and build from scratch, use command:
# bash build.sh clean_build

func=default_build
if [ -n "$1" ]; then
  func=$1
fi

base_dir=`cd $(dirname $0); pwd -P`
root_dir=$base_dir/..
source $base_dir/../mazu_dev/env_setup.sh x86_64

build_dir=$base_dir/build
if [ "$func" == "clean" -o "$func" == "clean_build" ]; then
  if [ -d $build_dir ]; then
    echo "remove build directory"
    rm $build_dir -rf
  fi
  if [ -d $NIO_INSTALL_PREFIX ]; then
    echo "remove install files"
    rm $NIO_INSTALL_PREFIX/*/planner/* -rf
    if [[ -e $NIO_INSTALL_PREFIX/lib/libplanner_* ]]; then
      rm $NIO_INSTALL_PREFIX/lib/libplanner_*
    fi
  fi
fi

if [ "$func" == "clean_build" -o "$func" == "default_build" ]; then
  if [ ! -d $build_dir ]; then
    echo "make build path"
    mkdir -p $build_dir
  fi
  cd $build_dir && cmake .. -DCMAKE_TOOLCHAIN_FILE=$PNC_CMAKE_TC_FILE
  make -j8 && make install
fi
