# Run projects on a cluster with Make

Edit your code on your computer. This Makefile copies it to a cluster, compiles it, runs it as a Slurm job, and downloads the output. You run the commands below in a terminal **on your computer**, unless stated otherwise.

You need an account on a Slurm cluster reachable through an SSH gateway, plus GNU Make, SSH and rsync on your computer. The gateway and cluster must use the same login name.

## Files

```text
Makefile                  Commands you run on your computer
.env.example              Template for your cluster settings
examples/
  basic_c/                A simple C program
  openmp/                 A C program using multiple CPU threads
  cuda/                   A CUDA program for an NVIDIA GPU
```

Each example has its own source code, `Makefile` (how to compile), and `slurm.sl` (how to run on the cluster).

## 1. Set up your connection

Open a terminal and go to this repository. If you have not cloned it yet:

```sh
git clone https://github.com/Marcin-Brzykcy/hpc-make-workflow.git
cd hpc-make-workflow
```

Create your settings file:

```sh
cp .env.example .env
```

Open `.env` in a text editor and change these values:

| Setting | What to enter |
| --- | --- |
| `HPC_USER` | Your cluster login name |
| `HPC_CENTRAL` | Your gateway hostname, for example `hpc.icm.edu.pl` |
| `CLUSTER` | The cluster hostname, for example `okeanos` |
| `HPC_ACCOUNT` | Your Slurm account, if required; otherwise leave it empty |
| `PARTITION` | Your Slurm partition; by default this uses `CLUSTER` |

Leave `SRC_DIR` and `REMOTE_DIR` as they are for the first example. Ask your cluster administrator if you do not know the connection or Slurm settings. Do **not** put passwords in `.env`.

## 2. Log in

```sh
make login
```

Enter your password and one-time code if prompted. Verify host keys when connecting for the first time. The connection is reused for later commands; you can close it when finished with `make logout`.

## 3. Compile and run the basic C example

```sh
make run
```

This copies `examples/basic_c` to the cluster, compiles it, submits the job, waits for it to finish, and downloads its output. It may take time for Slurm to start the job.

To force recompilation, for example after changing compiler flags:

```sh
make run REBUILD=1 COMPILER_FLAGS='-O0 -g -Wall -DVERBOSE'
```

## 4. Read or download output

After `make run` finishes, read the downloaded output on your computer:

```sh
cat downloads/output.txt
```

The output filename is set in the example's `Makefile` with `OUTPUT_FILE = output.txt`. Change it there to use a different name. `make run` tells Slurm to use this filename, even if `slurm.sl` specifies another one. Use a simple relative path; `%j` can be used for the job ID. Other Slurm substitutions, job arrays, and separate error files are not downloaded automatically.

To download **another** file, use `make pull`. `PULL_FROM` is relative to the remote `REMOTE_DIR` (not to your home directory). For example:

```sh
make pull PULL_FROM=examples/basic_c/results.txt PULL_TO=downloads
```

`PULL_TO` is the local destination directory and defaults to `downloads`.

## 5. Choose which directory to copy

`SRC_DIR` is the local project directory to copy to the cluster. For one command, set it like this:

```sh
make run SRC_DIR=examples/openmp
```

To change the default, edit `SRC_DIR` in the root `.env`. The project is copied to `~/REMOTE_DIR/SRC_DIR` on the cluster. Use simple relative paths without spaces. Files already on the cluster are not deleted. `.env` files are not copied.

For your own project, follow the examples: provide a `Makefile` with an `OUTPUT_FILE` variable and a `slurm.sl` script. You can also add a project-specific `.env` inside your project directory to override the root settings; command-line settings take priority over both. Set `SRC_DIR` in the root `.env` or on the command line, not in the project `.env`.

## 6. Compile and run OpenMP

```sh
make run SRC_DIR=examples/openmp
cat downloads/output.txt
```

This example uses 1, 2 and 4 CPU threads. It needs a compiler with OpenMP support. If your cluster requires a compiler module, add for example `MODULES=gcc` to the `make run` command, using the module name supplied by your cluster. If you change `COMPILER_FLAGS`, include the compiler's OpenMP flag (such as `-fopenmp`).

## 7. Compile and run CUDA

You need an NVIDIA GPU and the CUDA toolkit on the cluster. Replace `gpu` and `cuda` below with your cluster's GPU partition and CUDA module names:

```sh
make run SRC_DIR=examples/cuda PARTITION=gpu MODULES=cuda
cat downloads/output.txt
```

The Slurm script requests one GPU using `--gres=gpu:1`; your cluster may require a different setting. The chosen partition must also allow compilation. If needed, edit `examples/cuda/slurm.sl` or ask your cluster administrator.

## Open an interactive terminal on a compute node

After logging in, open a shell on the cluster:

```sh
make shell
```

You are now on the cluster's login node. To request an interactive compute node, run the following **in that cluster shell**, replacing the partition and account with your own:

```sh
srun --partition=YOUR_PARTITION --account=YOUR_ACCOUNT --time=00:30:00 --pty bash -l
```

Omit `--account=YOUR_ACCOUNT` if your site does not require an account. The command may wait in the queue before opening the compute-node shell. Run `exit` to leave the compute node, then `exit` again to return to your computer. Cluster policies and available resources vary; check your site's instructions if this command fails.

## Other useful commands

Run these on your computer, from the repository directory:

| Command | What it does |
| --- | --- |
| `make queue` | Show your queued and running jobs |
| `make cancel JOB_ID=123` | Cancel job 123 |
| `make sync` | Copy the selected project without running it |
| `make exec CMD='pwd'` | Run a command in the remote project root |
| `make status` | Check the saved SSH connections |
| `make logout` | Close the saved SSH connections |

The workflow generates its own SSH configuration rather than reading `~/.ssh/config`. If your connection requires a custom identity file or other SSH settings, add them to the `cfg` recipe in the top-level `Makefile`.
