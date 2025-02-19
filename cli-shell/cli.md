# Solace CLI help/readme
> Solace CLI does not officially have any `-h` or `--help` parameters - this is retrieved using `strings`
```bash
Usage: cli [OPTION]
(Typical directory: /usr/sw/loads/currentload/bin/cli)
[OPTION]...
   where:
   OPTION is one of the following:
     -D daemon mode.  Process is detached from stdin/out/err
     -l LEVEL: set initial logging level to LEVEL
          where LEVEL: DEBUG (DEFAULT), INFO, WARN, ERROR, FATAL or OFF
     -m MASK: set initial eventId mask to MASK
     -d DIRNAME: set initial unique directory name. If not specified
          user's home directory is used
     -g force creation of IPC resources
     -v display version information
     --soldebug-init-rc <filename>: name a file containing soldebug
           commands that will be executed early in the startup sequence
           (before threads are spawned). If not specified this value
           defaults to loads/currentload/soldebugInitRc
     --ipc-arenas-to-use-override <mask>: mask indicating which IPC
           message arenas the process should attach to. Overrides
           any hard-coded arenas
     --ipc-mo-shared-data-tables-to-use-override: override which IPC
          moSharedDataTables are used by this process
     -s INIT_SCRIPT : execute CLI script and exit
        where INIT_SCRIPT specifies the complete path and filename
     -e auto exit mode. Typically used with -s to execute a script
           then exit. e.g  '-es cli.init'
     -a standalone mode - start up even if core processes are
          unavailable
     -p disable prompts - suppresses user prompts (always answer 'y')
     -A force authorization to allow starting from the cmd line
     -u set inactivity timeout in seconds (-1 = disable)
     -c <string>: options passed through SSH login:
                  <kill> terminates an existing active CLI session
```

# Examples
To execute a Solace CLI script without logging into CLI and typing `source script [filename]`:
`/usr/sw/loads/currentload/bin/cli -Apes [filename]`
> -A: force authorization <br>
> -p: disable prompts <br>
> -e: auto exit <br>
> -s: execute script <br>

Also possible to do:
`/usr/sw/loads/currentload/bin/cli -Apes example.cli` where:
content of `example.cli` is:
```bash
source script another.cli
```
content of `another.cli` is some other cli commands
