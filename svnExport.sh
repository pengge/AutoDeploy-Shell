#!/bin/bash
################################################
#   Todo:自动从SVN配置库获取代码，导出差异文件。  
#   Author:归根落叶
#   Blog:http://www.trongeek.com             
################################################

#Function:  printLog()
#Author:    归根落叶
#Todo:  打印日志
#Param: logInfo(日志信息)
logPath="`pwd`"     #日志存放路径
function printLog(){
    errorCode=$?
    if [ $# -ne 1 ];then
        echo `date +"%Y-%m-%d %H:%M:%S"` "Usage:printLog logInfo" | tee --append ${logPath}/svnRuntimeLog.txt
        exit 1
    fi
    logInfo=$1
    if [ $errorCode -ne 0 ];then
        echo `date +"%Y-%m-%d %H:%M:%S"` "[ERROR]#${logInfo}" | tee --append ${logPath}/svnRuntimeLog.txt
        return 1
    else
        echo `date +"%Y-%m-%d %H:%M:%S"` "${logInfo}" >> ${logPath}/svnRuntimeLog.txt
    fi
}

#Function:  svnDo()
#Author:    归根落叶
#Todo:  操作SVN
#Param: userName(用户名)
#       passWord(密码)
#       operation[co(签出)|up(更新)|add(新增)|ci(提交)|export(导出)|copy(打分支|标签)|diff(对比两个版本)|info(获取信息)|log(打印日志)|gr(获取版本号)]
#       svnPath(路径1)
#       [ tagsPath(路径2)|localPath(路径3)
#       revision(版本)
#       logFile(日志文件)
#       getRevisionNum(获取倒数第几次更新的版本号) ]
function svnDo(){
    userName=$1
    passWord=$2
    op=$3
    case ${op} in
        "co")
            if [ $# -ne 6 ];then
                printLog "Usage:svnDo userName passWord co svnPath localPath revision"
                exit 1
            fi
            svnPath=$4
            localPath=$5
            revision=$6
            echo "检出SVN[${svnPath}]"
            svn co --force --non-interactive --trust-server-cert --username ${userName} --password ${passWord} "${svnPath}" "${localPath}" --revision ${revision}
            printLog "检出SVN[${svnPath}]"
            return;;
        "up")
            if [ $# -ne 5 ];then
                printLog "Usage:svnDo userName passWord up localPath revision"
                exit 1
            fi
            localPath=$4
            revision=$5
            echo "更新SVN[${localPath}]"
            svn up --force --non-interactive --trust-server-cert --username ${userName} --password ${passWord} "${localPath}" --revision ${revision}
            printLog "更新SVN[${localPath}]"
            return;;
        "add")
            if [ $# -ne 4 ];then
                printLog "Usage:svnDo userName passWord add localPath"
                exit 1
            fi
            localPath=$4
            echo "SVN新增文件[${localPath}]"
            svn add --force --non-interactive --trust-server-cert --username ${userName} --password ${passWord} "${localPath}"
            printLog "SVN新增文件[${localPath}]"
            return;;
        "ci")
            if [ $# -ne 5 ];then
                printLog "Usage:svnDo userName passWord ci localPath logFile"
                exit 1
            fi
            localPath=$4
            logFile=$5
            echo "提交到SVN[${localPath}]"
            svn ci --non-interactive --trust-server-cert --username ${userName} --password ${passWord} "${localPath}" --file "${logFile}"
            printLog "提交到SVN[${localPath}]"
            return;;
        "export")
            if [ $# -ne 6 ];then
                printLog "Usage:svnDo userName passWord export svnPath localPath revision"
                exit 1
            fi
            svnPath=$4
            localPath=$5
            revision=$6
            rm -f delList.txt
            rm -f upList.txt
            cat diff.txt |
            while read row; do
                op=`echo ${row} | awk '{print $1}'`
                if [ ${op} == "D" ];then
                    echo ${row} | awk '{$1="";print $0}' | awk -F "${svnPath}" '{print $2}' >> delList.txt
                else
                    echo ${row} | awk '{$1="";print $0}' | awk -F "${svnPath}" '{print $2}' >> upList.txt
                fi        
            done
            echo "noneLine" >> delList.txt
            cat upList.txt |
            while read filePath; do
                exPath=${filePath%/*}/
                if [[ -d "${localPath}/$exPath" && ! -d "${localPath}/${filePath}" ]];then
                    svn export --force --non-interactive --trust-server-cert --username ${userName} --password ${passWord} "${svnPath}/${filePath}@" "${localPath}/${filePath}" --revision ${revision}
                    printLog "SVN导出文件[${svnPath}/${filePath}@${revision}]"
                elif [ ! -d "${localPath}/${filePath}" ];then
                    mkdir -p "${localPath}/$exPath"
                    printLog "创建目录[${localPath}/$exPath]"
                    svn export --force --non-interactive --trust-server-cert --username ${userName} --password ${passWord} "${svnPath}/${filePath}@" "${localPath}/${filePath}" --revision ${revision}
                    printLog "SVN导出文件[${svnPath}/${filePath}@${revision}]"
                fi
            done
            rm -f upList.txt
            rm -f diff.txt
            return;;
        "copy")
            if [ $# -ne 7 ];then
                printLog "Usage:svnDo userName passWord copy svnPath tagsPath revision logFile"
                exit 1
            fi
            svnPath=$4
            tagsPath=$5
            revision=$6
            logFile=$7
            echo "SVN打分支/标签[${tagsPath}]"
            svn copy --non-interactive --trust-server-cert --username ${userName} --password ${passWord} "${svnPath}" "${tagsPath}" --revision ${revision} --file ${logFile}
            printLog "SVN打分支/标签[${tagsPath}]"
            return;;
        "diff")
            if [ $# -ne 5 ];then
                printLog "Usage:svnDo userName passWord diff svnPath revision"
                exit 1
            fi
            svnPath=$4
            revision=$5
            echo "SVN对比两个版本差异[${svnPath}@${revision}]"
            svn diff --force --non-interactive --trust-server-cert --username ${userName} --password ${passWord} "${svnPath}" --revision ${revision} --summarize > diff.txt
            printLog "SVN对比两个版本差异[${svnPath}@${revision}]"
            return;;
        "info")
            if [ $# -ne 5 ];then
                printLog "Usage:svnDo userName passWord info svnPath revision"
                exit 1
            fi
            tagsPath=$4
            revision=$5
            echo "SVN获取[${tagsPath}]的信息"
            svn info --non-interactive --trust-server-cert --username ${userName} --password ${passWord} "${tagsPath}" --revision ${revision}
            printLog "SVN获取[${tagsPath}]的信息"
            return;;
        "log")
            if [ $# -ne 5 ];then
                printLog "Usage:svnDo userName passWord log svnPath revision"
                exit 1
            fi
            svnPath=$4
            revision=$5
            echo "SVN获取[${tagsPath}]的日志"
            svn log --non-interactive --trust-server-cert --username ${userName} --password ${passWord} "${svnPath}" --revision ${revision}
            printLog "SVN获取[${tagsPath}]的日志"
            return;;
        "gr")
            if [ $# -ne 5 ];then
                printLog "Usage:svnDo userName passWord gr svnPath getRevisionNum"
                exit 1
            fi
            svnPath=$4
            getRevisionNum=$5
            svn log --non-interactive --trust-server-cert --username ${userName} --password ${passWord} "${svnPath}" | grep "^r[0-9]" | awk "NR==${getRevisionNum}" | sed -n -r "s/r([0-9]*).*/\1/p"
            printLog "SVN获取[${svnPath}]的版本号"
            return;;
        *)
            printLog "Usage:svnDo userName passWord operation"
            exit 1
    esac    
}

#Function:  editConf()
#Author:    归根落叶
#Todo:  修改配置文件
#Param: filePath(导出文件路径)
function editConf(){
    if [ $# -ne 1 ];then
        printLog "Usage:editConf filePath"
        exit 1
    fi
    filePath=$1
    if [ -f ${filePath}/application/config/nosql.php ];then
        echo "修改配置文件[${filePath}/application/config/nosql.php]"
        sed -r -i "8,15s/mongodb:\/\/.*',/mongodb:\/\/127.0.0.1:27017',/" ${filePath}/application/config/nosql.php
        sed -r -i "8,15s/'database'.*,/'database'   =>  'testdb',/" ${filePath}/application/config/nosql.php
        printLog "修改配置文件[${filePath}/application/config/nosql.php]"
    fi
}

#Function:  jsGrunt()
#Author:    归根落叶
#Todo:  Grunt自动压缩js、css、图片
#Param: filePath(源文件路径),localPath(SVN本地工作目录)
function jsGrunt(){
    if [ $# -ne 2 ];then
        printLog "Usage:jsGrunt filePath localPath"
        exit 1
    fi
    filePath=$1 
    localPath=$2
    ver=`date +"%Y%m%d%H%M%S"`
    workDir=`pwd`
    if [[ -d ${filePath} && `ls ${filePath} | wc -l` -gt 0 ]];then
        ls ${filePath} > tempdir.txt
        cat tempdir.txt |
        while read tdir;do
            jsnum=`find ${filePath}/${tdir} -name '*.js' | wc -l`
            cssnum=`find ${filePath}/${tdir} -name '*.css' | wc -l`
            if [[ $jsnum -gt 0 || $cssnum -gt 0 ]];then
                if [[ -f ${localPath}/${tdir}/package.json && -f ${localPath}/${tdir}/Gruntfile.js ]];then
                    rm -f ${localPath}/${tdir}/node_modules
                    ln -s /usr/local/lib/node_modules/LiveApp ${localPath}/${tdir}/node_modules
                    cd ${localPath}/${tdir}
                    echo "Grunt压缩模板${tdir}的js、css和图片"
                    grunt 
                    printLog "Grunt压缩模板${tdir}的js、css和图片"
                    if [ -d ./assets ];then
                        if [ -f ./app/tpl.php ];then
                            sed -r -i "s/init.min.js\?ver=[0-9\.]*\"/init.min.js\?ver=$ver\"/g" ./app/tpl.php 
                            sed -r -i "s/app.min.css\?ver=[0-9\.]*\"/app.min.css\?ver=$ver\"/g" ./app/tpl.php
                            cp -rf ./app/tpl.php ${workDir}/${filePath}/${tdir}/app/tpl.php
                            printLog "自动更新版本号[./app/tpl.php]"
                        fi
                        cp -rf ./assets ${workDir}/${filePath}/${tdir}/
                        if [ -f ./assets/scripts/init.min.js ];then
                            sed -r -i "18,20s/\/\/.*preload/preload/" ./assets/scripts/init.min.js 
                            sed -r -i "18,20s/[^\/\/]base/\/\/base/" ./assets/scripts/init.min.js 
                            cp -f ./assets/scripts/init.min.js ${workDir}/${filePath}/${tdir}/assets/scripts/init.min.js 
                            printLog "自动切换到正式环境[./assets/scripts/init.min.js]"
                        fi
                    else
                        if [ -f ./tpl.php ];then
                            sed -r -i "s/init.min.js\?ver=[0-9\.]*\"/init.min.js\?ver=$ver\"/g" ./tpl.php 
                            sed -r -i "s/app.min.css\?ver=[0-9\.]*\"/app.min.css\?ver=$ver\"/g" ./tpl.php
                            cp -f ./tpl.php ${workDir}/${filePath}/${tdir}/tpl.php
                            printLog "自动更新版本号[./tpl.php]"
                        fi
                        cp -rf ./dist ${workDir}/${filePath}/${tdir}/ 
                        if [ -f ./dist/scripts/init.min.js ];then
                            sed -r -i "18,20s/\/\/.*preload/preload/" ./dist/scripts/init.min.js 
                            sed -r -i "18,20s/[^\/\/]base/\/\/base/" ./dist/scripts/init.min.js
                            cp -f ./dist/scripts/init.min.js ${workDir}/${filePath}/${tdir}/dist/scripts/init.min.js
                            printLog "自动切换到正式环境[./dist/scripts/init.min.js]" 
                        fi
                    fi
                    rm -f ./node_modules
                    svnDo ${userName} ${passWord} add "`pwd`"
                    echo "[Auto]模板${tdir} 压缩js、css和图片" > svnLog.txt
                    svnDo ${userName} ${passWord} ci "`pwd`" svnLog.txt 
                    rm -f svnLog.txt
                    cd ${workDir}
                fi
            fi
        done
        rm -f tempdir.txt
        rm -rfv `find ${filePath}/ -name '.svn' -type d`
    fi
}

#SVN配置库代码路径
svnPath="https://hostname/svn/project/trunk"    
#Tag路径                              
tagsPath="https://hostname/svn/project/tags/release"    
#svn用户名                                 
userName="userName"     
#svn密码                              
passWord="passWord" 
#环境(test|pre|PRO)                                   
env="test"      

oldVersion=`svnDo ${userName} ${passWord} gr ${svnPath} 2`
printLog "获取上一次更新的版本号"
newVersion=`svnDo ${userName} ${passWord} gr ${svnPath} 1`
printLog "获取最新的版本号"
newTagsVersion=`svnDo ${userName} ${passWord} gr ${tagsPath} 1`
if [[ ("${oldVersion}" -gt 0) && ("${newVersion}" -gt 0) ]];then    #判断是否是数字
    if [ -f tagsVersion ];then
        oldVersion=`cat tagsVersion`
    fi  
    if [ ${oldVersion} -eq ${newVersion} ];then
        echo "没有新版本更新，目前新版本号为[${newVersion}]"
        printLog "没有新版本更新，目前新版本号为[${newVersion}]"
        exit 1
    fi
    updir="ali_upgrade/${oldVersion}-${newVersion}"     #升级包导出路径
    downdir="ali_downgrade/${newVersion}-${oldVersion}" #还原包导出路径
    echo "从版本[${oldVersion}]升级到新版本[${newVersion}]"
    printLog "从版本[${oldVersion}]升级到新版本[${newVersion}]"
    echo "auto_tags:生产环境打包,SVN版本号[${newVersion}]" > svnLog.txt
    svnDo ${userName} ${passWord} log ${svnPath} ${oldVersion}:${newVersion} >> svnLog.txt
    if [ "${newVersion}" -gt "${newTagsVersion}" ];then
        svnDo ${userName} ${passWord} copy ${svnPath} ${tagsPath}/tag_${newVersion} ${newVersion} svnLog.txt
    fi
    printLog "删除临时文件"
    rm -rf ${updir}
    rm -rf ${downdir}
    mkdir -p ${updir}
    mkdir -p ${downdir}
    printLog "升级，导出版本差异文件"
    svnDo ${userName} ${passWord} diff ${svnPath} "${oldVersion}:${newVersion}"
    svnDo ${userName} ${passWord} export ${svnPath} ${updir} "HEAD"
    editConf ${updir}
    mv delList.txt delList${env}Up.txt
    printLog "还原，导出版本差异文件"
    svnDo ${userName} ${passWord} diff ${svnPath} "${newVersion}:${oldVersion}"
    svnDo ${userName} ${passWord} export ${tagsPath}/tag_${oldVersion} ${downdir} "HEAD"
    editConf ${downdir}
    jsGrunt "${updir}/template" "./LiveAPP/template"
    cp -rfv ${updir}/ upgrade${env}_${oldVersion}-${newVersion}/
    tar zcvf upgrade${env}.tar.gz upgrade${env}_${oldVersion}-${newVersion}/
    tar zcvf ali_upgrade/upgrade_${oldVersion}-${newVersion}.tar.gz upgrade${env}_${oldVersion}-${newVersion}/
    rm -rf upgrade${env}_${oldVersion}-${newVersion}
    printLog "打升级包完成"
    cp -rfv ${downdir}/ downgrade${env}_${newVersion}-${oldVersion}/
    tar zcvf downgrade${env}.tar.gz downgrade${env}_${newVersion}-${oldVersion}/
    rm -rf downgrade${env}_${newVersion}-${oldVersion}
    printLog "打还原包完成"
    newVersion=`svnDo ${userName} ${passWord} gr ${svnPath} 1`
    newTagsVersion=`svnDo ${userName} ${passWord} gr ${tagsPath} 1`
    echo "auto_tags:生产环境打包,SVN版本号[${newVersion}]" > svnLog.txt
    svnDo ${userName} ${passWord} log ${svnPath} ${oldVersion}:${newVersion} >> svnLog.txt
    if [ "${newVersion}" -gt "${newTagsVersion}" ];then
        svnDo ${userName} ${passWord} copy ${svnPath} ${tagsPath}/tag_${newVersion} ${newVersion} svnLog.txt
    fi  
    rm -f svnLog.txt
    mv delList.txt delList${env}Down.txt
    echo ${newVersion} > tagsVersion
    exit 0
else
    printLog "版本号不正确:OldVersion#${oldVersion}  NewVersion#${newVersion}"
    exit 1
fi