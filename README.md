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
make all            # sync, build on a compute node, submit and wait
make pull           # download output.txt to downloads/
cat downloads/output.txt
make logout
```

The example builds `examples/hello/hello.c` using its own Makefile and runs it using `examples/hello/slurm.sl`. `make all` waits for the Slurm job; it does not automatically download output. SSH verifies gateway and cluster host keys against your known-hosts files. The workflow uses its own generated `.hpc/ssh_config` instead of `~/.ssh/config` and reuses SSH connections for two hours by default. If you need custom SSH settings (such as a non-default identity), add them to the `cfg` recipe. `.env`, `.hpc/` and downloaded output are ignored by Git.

## Your own project

Create a directory inside this repository with a Makefile (default target builds your program; `clean` removes build products) and a Slurm script named `slurm.sl`. The script should run your executable and set resources and output via `#SBATCH` directives. Set `SRC_DIR` in `.env`, or override it on the command line:

```sh
make all SRC_DIR=my-project
make pull SRC_DIR=my-project PULL_FROM=my-project/results.txt
```

The selected directory is copied to `~/REMOTE_DIR/SRC_DIR` on the cluster. Keep paths relative and simple (no spaces or shell metacharacters). `rsync` does not delete remote files; it excludes `output.txt` to avoid overwriting existing results. If using another output filename, avoid keeping a local copy in the source directory before syncing.

## Commands

| Command | Action |
| --- | --- |
| `make login` / `make logout` / `make status` | Open, close or check reusable SSH connections |
| `make sync` | Copy the selected project to the cluster |
| `make build` | Run the project Makefile in an `srun` allocation |
| `make run` | Submit the Slurm script with `sbatch --wait` |
| `make all` | Run sync, build and run in order |
| `make pull` | Download `PULL_FROM` (relative to remote project root) into `PULL_TO` |
| `make queue` / `make cancel JOB_ID=123` | List your jobs / cancel a specific job |
| `make shell` / `make ls` | Open a cluster shell / list the remote project root |
| `make exec CMD='pwd'` | Run a command in the remote project root |
| `make clean-remote` | Run `make clean` in the remote source directory |

## Configuration

`.env` is a Makefile fragment, not a shell script. Command-line assignments override it, for example `make build COMPILER=mpicc`. Do not store secrets in it.

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
| `PULL_FROM`, `PULL_TO` | `$(SRC_DIR)/output.txt`, `downloads` | Remote relative path and local destination directory |
| `PERSIST` | `2h` | SSH connection reuse duration |

Account and partition are passed to both `srun` and `sbatch`, and command-line Slurm options override matching script directives. Module availability and allocation policies vary by site; adjust the script and settings for your cluster. Settings and commands are trusted shell/Make input; avoid untrusted values.
