#!/bin/bash

MODULE="planner"
PROJECT_BUILD_PATH="`pwd`/code_coverage_build"
UT_PATH=${NIO_INSTALL_PREFIX}/bin/unit_test/${MODULE}

pushd () {
    command pushd "$@" > /dev/null
}

popd () {
    command popd "$@" > /dev/null
}

function execute_unit_test () {
  ut_case_list=`find ${UT_PATH}` || echo "cant find ut case"
  ut_case_list=(${ut_case_list//,/})

  failed_case_num=0
  failed_case_detail=''

  # coredump prepare
  echo /proc/sys/kernel/core_pattern
  echo "/corefile/core_%e.%p" > /proc/sys/kernel/core_pattern
  echo /proc/sys/kernel/core_pattern
  mkdir -p /corefile
  ulimit -c unlimited

  pushd `pwd`
#  cd ${PROJECT_BUILD_PATH}
  echo "Execute ${MODULE} unit test start..."
  for ut_case in ${ut_case_list[@]}
  do
    if [[ -x ${ut_case} ]] && [[ -f ${ut_case} ]] && [[ ${ut_case##*_} = "test" ]]; then
    {
      echo "Run ut case: ${ut_case}"
      chmod a+x ${ut_case}
      ASAN_OPTIONS=detect_leaks=1 LSAN_OPTIONS=suppressions=${NIO_INSTALL_PREFIX}/../../suppr.txt ${ut_case}
      ret=$?
      echo "${ut_case} result ${ret}"
      if [[ ret -ne 0 ]]; then
        failed_case_num=$((failed_case_num + 1))
        failed_case_detail=$failed_case_detail'['${ut_case}']'
        # print corestack
        core_file=`ls /corefile`
        if [ -z $core_file ]; then
          echo $core_file
          echo thread apply all bt full | gdb ${ut_case} /corefile/$core_file
          rm -f /corefile/*
        fi
      fi
    }
    fi
  done

  wait
  echo "Execute ${MODULE} unit test end, failed_case_num ${failed_case_num}"
  if [[ failed_case_num -ne 0 ]]; then
    echo "failed case: "$failed_case_detail
  fi
  popd
  return ${failed_case_num}
}

execute_unit_test
exit $?
