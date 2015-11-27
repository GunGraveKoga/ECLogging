#!/usr/bin/env python
# -*- coding: utf8 -*-

import subprocess
import shutil
import shell
import re
import errors
import os

def root_path():
    return os.path.join(os.getcwd(), 'build')

def log_paths(jobName):
    root = root_path()
    logs = ['output', 'errors', 'pretty']
    if jobName:
        prefix = jobName + '-'
    else:
        prefix = ''

    full = {}
    for log in logs:
        full[log] = os.path.join(root, 'logs', "{0}{1}.log".format(prefix, log))

    return full

def build_paths():
    root = root_path()
    paths = {
        'SYMROOT' : 'sym',
        'OBJROOT' : 'obj',
        'DSTROOT' : 'dst',
        'CACHE_ROOT' : 'cache',
        'SHARED_PRECOMPS_DIR' : 'precomp'
    }

    full = {}
    for key in paths:
        full[key] = os.path.join(root, paths[key])

    return full

def build(workspace, scheme, platform = 'macosx', actions = ['build'], jobName = None, cleanAll = True):
    args = ['xctool', '-workspace', workspace, '-scheme', scheme, '-sdk', platform]

    if cleanAll:
        root = root_path()
        shutil.rmtree(root)

    paths = build_paths()
    pathArgs = []
    for key in paths:
        pathArgs += ["{0}={1}".format(key, paths[key])]

    args += actions
    args += pathArgs

    logPaths = log_paths(jobName)
    args += ['-reporter', "pretty:{0}".format(logPaths['pretty'])]
    args += ['-reporter', "plain:{0}".format(logPaths['output'])]

    (result, output) = shell.call_output_and_result(args)
    return (result, output)


if __name__ == "__main__":
    print build('Sketch.xcworkspace', 'ECLogging Mac', jobName = 'framework')
    print build('Sketch.xcworkspace', 'ECLogging Mac Static', jobName = 'static', cleanAll = False)
