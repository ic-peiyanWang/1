#!/bin/bash
set -e
export _gl_conan_build_version=0.0.5

run_command() {
    local command="$1"
    local max_retries="$2"
    local interval="$3"

    command_encryption=$(echo "${command}" | sed 's/oauth2:glpat-FFBtdCG2M8HoUcMYEvKR/***/g')

    local retry_count=0
    while [ ${retry_count} -le ${max_retries} ]; do
        # 尝试执行命令
        eval "${command}" && return 0

        # 增加重试计数
        ((retry_count++))

        if [ ${retry_count} -ge ${max_retries} ]; then
            break
        fi
        
        # 如果命令执行失败，则等待一段时间后重试
        echo "retry ${retry_count}: ${command_encryption} execute failed. Retrying after ${interval} seconds..."
        sleep ${interval}
        
    done
    
    # 达到最大重试次数仍然失败，则输出错误信息并返回非零退出码
    echo -e "\e[1;31m Maximum retries reached. ${command_encryption} execute failed. \e[0m"
    return 1
}

run_git_command() {
    local command="$1"
    local max_retries="$2"        # 重试次数
    local interval="$3"           # 每次失败等待interval秒后再重试
    local exception_msg="$4"
    
    set +e
    run_command "${command}" ${max_retries} ${interval}
    return_value=$?
    set -e

    if [ $return_value -ne 0 ]; then
        if [ -n "${exception_msg}" ]; then echo -e "\e[1;31m ${exception_msg} \e[0m"; fi
        exit ${return_value}
    fi
}

function git_handle_conan_suite()
{
    # Parse conan_suite_ref: tag, branch or branch%commit_id
    if [ -z "${conan_suite_ref}" ]; then
        if [ -f "conan/.conan_suite.conf" ]; then
            local python_commands="import configparser; config=configparser.RawConfigParser(); config.read('conan/.conan_suite.conf'); print(config['conan_suite']['ref'])"
            export conan_suite_ref=$(python3 -c "${python_commands}" 2>/dev/null)
        fi
        if [ -z "${conan_suite_ref}" ]; then export conan_suite_ref="stable/release_v4"; fi
    fi
    local input_ref="${conan_suite_ref}"
    if [[ "${conan_suite_ref}" =~ "%" ]]; then input_ref="$(echo ${conan_suite_ref} | sed 's#%.*##g')"; local input_commit_id="$(echo ${conan_suite_ref} | sed 's#.*%##g')"; fi


    local -r git_config="--git-dir=conan/conan_suite/.git --work-tree=conan/conan_suite"
    if [ ! -d "conan/conan_suite" ]; then  # clone conan_suite if conan_suite is not in current repo
        run_git_command "git clone -q -b ${input_ref} https://oauth2:glpat-FFBtdCG2M8HoUcMYEvKR@ad-gitlab.nioint.com/ad/edge/conan_factory/conan_suite.git conan/conan_suite" 3 10
    else
        local repo_branch="$(git ${git_config} rev-parse --abbrev-ref HEAD)"
        if [ "${repo_branch}" == "${input_ref}" ]; then
            run_git_command "git ${git_config} pull -q origin ${input_ref}" 3 10
        else
            run_git_command "git ${git_config} fetch -q origin ${input_ref}" 3 10
            run_git_command "git ${git_config} checkout -q ${input_ref}" 1 0 "please execute delete conan/conan_suite and retry your command"
        fi
    fi
    if [ -n "${input_commit_id}" ]; then 
        run_git_command "git ${git_config} checkout -q ${input_commit_id}" 1 0 "please execute delete conan/conan_suite and retry your command"
    fi
}

if [ -f "conan/before_script.sh" -a "${_IN_DOCKER_ENV}" == "True" ]; then source conan/before_script.sh $*; fi

# git clone or pull conan_suite from remote
if [ "${_UPDATE_CONAN_SUITE}" != "False" ]; then git_handle_conan_suite; fi
conan/conan_suite/conan_build.sh $*

if [ -f "conan/after_script.sh" -a "${_IN_DOCKER_ENV}" == "True" ]; then source conan/after_script.sh $*; fi