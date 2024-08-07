#!/bin/bash

MODULE="planner"
PROJECT_BUILD_PATH="`pwd`/code_coverage_build"
UT_PATH=${NIO_INSTALL_PREFIX}/bin/unit_test/${MODULE}
CODE_COVERAGE_PATH=${PROJECT_BUILD_PATH}/code_coverage

pushd () {
    command pushd "$@" > /dev/null
}

popd () {
    command popd "$@" > /dev/null
}

function check_dependencies() {
  which lcov > /dev/null
  ret=$?
  if [[ ${ret} != 0 ]]; then
    echo "ERROR: No lcov tool found! Please install lcov for your system first!
      lcov can be installed by 'sudo apt-get install lcov' in ubuntu os."
    exit ${ret}
  fi
}

function build_project() {
  pushd `pwd`

  echo "Remove old files"
  rm -rf ${PROJECT_BUILD_PATH}
  mkdir ${PROJECT_BUILD_PATH}
  cd ${PROJECT_BUILD_PATH}
  echo "Build project..."
  cmake .. -DCMAKE_TOOLCHAIN_FILE=$PNC_CMAKE_TC_FILE -DCOLLECT_COVERAGE=ON
  make -j `nproc` install

  popd
}

function execute_unit_test() {
  ut_case_list=`find ${UT_PATH}`
  ut_case_list=(${ut_case_list//,/})

  pushd `pwd`
  cd ${PROJECT_BUILD_PATH}
  echo "Execute ${MODULE} unit test start..."
  for ut_case in ${ut_case_list[@]}
  do
    if [[ -d ${ut_case} ]]; then
      continue
    fi

    {
      echo "Run ut case case ${ut_case}"
      ${ut_case}
    } &
  done

  wait
  echo "Execute ${MODULE} unit test end..."

  popd
}

function collect_code_coverage() {
  pushd `pwd`

  echo "Generate coverage info file..."
  mkdir -p ${CODE_COVERAGE_PATH}
  lcov -i -d ${PROJECT_BUILD_PATH} -c --rc lcov_branch_coverage=1 -o ${CODE_COVERAGE_PATH}/base_coverage.info -b . --no-external
  lcov -d ${PROJECT_BUILD_PATH} -c --rc lcov_branch_coverage=1 -o ${CODE_COVERAGE_PATH}/current_coverage.info -b . --no-external
  lcov -a ${CODE_COVERAGE_PATH}/base_coverage.info -a ${CODE_COVERAGE_PATH}/current_coverage.info --rc lcov_branch_coverage=1 -o ${CODE_COVERAGE_PATH}/coverage.info

  if [[ $? != 0 ]]; then
    cp -f ${CODE_COVERAGE_PATH}/base_coverage.info ${CODE_COVERAGE_PATH}/coverage.info
  fi
  echo "Generate html report file..."
  genhtml --branch-coverage -o ${CODE_COVERAGE_PATH}/coverage_report ${CODE_COVERAGE_PATH}/coverage.info
  echo -e "\nCode Coverage Report: \e]8;;file://${CODE_COVERAGE_PATH}/coverage_report/index.html\afile://${CODE_COVERAGE_PATH}/coverage_report/index.html\e]8;;\a"

  popd
}

check_dependencies
build_project
execute_unit_test
collect_code_coverage
