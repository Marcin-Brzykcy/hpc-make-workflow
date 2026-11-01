# HPC Make workflow

Edit locally, then synchronize, build and run a project on a Slurm cluster through an SSH gateway. Based on an ICM cluster workflow; cluster hostnames such as `okeanos`, `rysy` and `topola` can be used, but nothing is tied to a particular account.

## Requirements

- GNU Make, SSH and rsync locally; SSH access to a gateway and a cluster reachable from it.
- Slurm (`srun`, `sbatch`, `squeue`, `scancel`), Make and a compiler on the cluster.
- The same login name on gateway and cluster. Configure your SSH keys or enter passwords and any OTP interactively; no passwords are stored by this project. Verify host keys when prompted.

## Quick start

```sh
cp .env.example .env
# Edit .env: set HPC_USER, HPC_CENTRAL, CLUSTER and, if required, HPC_ACCOUNT.
make login          # authenticate to gateway and cluster
make run            # sync, build, submit, wait, and download output
cat downloads/output.txt
make logout
```

The example builds `examples/hello/hello.c` using its own Makefile and runs it using `examples/hello/slurm.sl`. `make run` waits for the job and downloads its Slurm output to `downloads/`. SSH verifies gateway and cluster host keys against your known-hosts files. The workflow uses its own generated `.hpc/ssh_config` instead of `~/.ssh/config` and reuses SSH connections for two hours by default. If you need custom SSH settings (such as a non-default identity), add them to the `cfg` recipe. `.env`, `.hpc/` and downloaded output are ignored by Git.

## Your own project

Create a directory inside this repository with a Makefile (default target builds your program; `clean` removes build products) and a Slurm script named `slurm.sl`. The script should run your executable and set resources and output via `#SBATCH` directives. Set `SRC_DIR` in `.env`, or override it on the command line:

```sh
make run SRC_DIR=my-project
make pull SRC_DIR=my-project PULL_FROM=my-project/results.txt
```

The selected directory is copied to `~/REMOTE_DIR/SRC_DIR` on the cluster. Keep paths relative and simple (no spaces or shell metacharacters). `rsync` does not delete remote files; it excludes `output.txt` to avoid overwriting existing results. If using another output filename, avoid keeping a local copy in the source directory before syncing.

`make run` reads the output path from the Slurm script's `#SBATCH --output=...` (or `-o`) directive. Without one, it downloads Slurm's default `slurm-%j.out`. Relative paths and `%j` (job ID) are supported; other Slurm filename substitutions, absolute paths, job arrays and separate stderr files are not automatically downloaded. Paths must use simple characters, without spaces or `..`. Use `make pull` for other files. The output's parent directory must already exist on the cluster. If the job fails, the workflow attempts to download its output before reporting the failure.

## Examples

Configure `.env` and run `make login` first. Each example has its own build Makefile and Slurm script. Choose the partition and account your site requires.

### Plain C

The default `examples/hello` builds and runs a small C program:

```sh
make run SRC_DIR=examples/hello
```

### Different compilation flags

The top-level `COMPILER_FLAGS` replaces the child project's default `CFLAGS`; `LINKER_FLAGS` sets `LDFLAGS`. The hello example uses a compile-time `VERBOSE` option as a simple preprocessor-flag demonstration. Use `REBUILD=1` when changing flags: Make does not automatically rebuild just because flags changed.

```sh
make run SRC_DIR=examples/hello REBUILD=1 COMPILER_FLAGS='-O0 -g -Wall -DVERBOSE'
```

For optimized builds, use e.g. `COMPILER_FLAGS='-O3 -Wall'`. Project-specific Make variables can also be supplied with `BUILD_ARGS`, for example `BUILD_ARGS='CPPFLAGS=-DVERBOSE'`. These settings affect the build, so use the same settings on subsequent rebuilds.

### OpenMP

Based on the original thread greeting and thread-count sweep, this example builds with `-fopenmp` and runs with 1, 2 and 4 threads within a four-CPU allocation:

```sh
make run SRC_DIR=examples/openmp
```

Use a compiler with OpenMP support; load the appropriate module with `MODULES` if needed. When overriding `COMPILER_FLAGS`, include `-fopenmp` yourself (or your compiler's equivalent). Adjust `--cpus-per-task` and the thread counts together to match your allocation.

### CUDA

The original project includes an incomplete CUDA Mandelbrot skeleton. This standalone example instead demonstrates the same GPU kernel-launch pattern without its additional libraries. It needs the CUDA toolkit (`nvcc`) and an NVIDIA GPU:

```sh
# Replace the partition and module with names provided by your cluster.
make run SRC_DIR=examples/cuda PARTITION=gpu MODULES=cuda
```

The sample script requests one GPU with `--gres=gpu:1`; adapt that directive to your site's Slurm policy. `MODULES` is loaded before build and submission; make sure the module environment is also available inside jobs on your site. The CUDA Makefile uses `NVCC` and `NVCCFLAGS`, not `COMPILER` or `COMPILER_FLAGS`. For example, pass `BUILD_ARGS='NVCCFLAGS=-O3' REBUILD=1` to `make run` with a toolkit that defaults to C++11 or later. Select architecture flags supported by your toolkit and GPU as needed. The build allocation uses the same partition as the job; choose a partition that permits builds.

## Commands

| Command | Action |
| --- | --- |
| `make login` / `make logout` / `make status` | Open, close or check reusable SSH connections |
| `make sync` | Copy the selected project to the cluster |
| `make run` | Sync, build in an `srun` allocation, submit, wait and download Slurm output |
| `make run REBUILD=1` | As above, forcing the project Makefile to rebuild with `make -B` |
| `make all` | Alias for `make run` |
| `make pull` | Download `PULL_FROM` (relative to remote project root) into `PULL_TO` |
| `make queue` / `make cancel JOB_ID=123` | List your jobs / cancel a specific job |
| `make shell` | Open a cluster shell |
| `make exec CMD='pwd'` | Run a command in the remote project root |
| `make clean-remote` | Run `make clean` in the remote source directory |

## Configuration

`.env` is a Makefile fragment, not a shell script. Command-line assignments override it, for example `make run COMPILER=mpicc REBUILD=1`. Do not store secrets in it.

| Variable | Default | Purpose |
| --- | --- | --- |
| `HPC_USER`, `HPC_CENTRAL`, `CLUSTER` | required | Login, gateway hostname and cluster hostname |
| `HPC_ACCOUNT` | empty | Slurm account; omitted when empty |
| `PARTITION` | `$(CLUSTER)` | Slurm partition; set empty to use the site default |
| `REMOTE_DIR`, `SRC_DIR` | `hpc-make-workflow`, `examples/hello` | Remote root under home and local project directory |
| `COMPILER`, `COMPILER_FLAGS`, `LINKER_FLAGS` | `gcc`, empty, empty | Passed to child Make as `CC`, `CFLAGS`, `LDFLAGS` |
| `BUILD_ARGS`, `TARGET` | empty | Extra child Make arguments and optional `TARGET` variable |
| `BUILD_TIME`, `SRUN_CMD` | `00:05:00`, `srun` | Build allocation time and launcher |
| `MODULES` | empty | Module names loaded before build and job submission |
| `SLURM_SCRIPT` | `slurm.sl` | Script inside the selected source directory |
| `REBUILD` | `0` | Set to `1` to force rebuilding with `make -B` |
| `PULL_FROM`, `PULL_TO` | `$(SRC_DIR)/output.txt`, `downloads` | Remote relative path and local destination directory |
| `PERSIST` | `2h` | SSH connection reuse duration |

Account and partition are passed to both `srun` and `sbatch`, and command-line Slurm options override matching script directives. Module availability and allocation policies vary by site; adjust the script and settings for your cluster. Settings and commands are trusted shell/Make input; avoid untrusted values.
