from invoke import Collection
from invoke import run, task

BUILD_CMD = 'sudo singularity build build/{app}-{os}.sif {app}/{os}.def'

@task
def clean(ctx, extra=''):
    patterns = [
        'build/*.sif'
    ]
    if extra:
        patterns.append(extra)
    for pattern in patterns:
        run('rm -Rf {}'.format(pattern))

@task
def build(ctx, app, os):
    run(BUILD_CMD.format(app=app, os=os))
