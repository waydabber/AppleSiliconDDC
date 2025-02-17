# AppleSiliconDDC

DDC Library for Apple Silicon Macs + ASDDC cli

## Usage - library

See example `ASDDC` code.

For sample implementation take a look at the source code of [MonitorControl](https://github.com/MonitorControl/MonitorControl) (as `Arm64DDC.swift` in the project)

Please mention this repo publicly if used. :)

## Usage - CLI

**Warning**: This CLI is for DDC/CI (protocol) and not for MCCS (command set) and some displays only partially adhere to MCCS (e.g. store unexpected data in MH/SH or invalid in ML). It's outside the scope of this program to interpret/correct it. Only `--verify-single` (or `--noverify`) can be used to bypass such issues.

### Building

```bash
swift build
./.build/arm64-apple-macosx/debug/ASDDC --help
```

### CLI syntax

`ASDDC --help`

```
OVERVIEW: AppleSiliconDDC

USAGE: asddc <subcommand>

OPTIONS:
  -h, --help              Show help information.

SUBCOMMANDS:
  detect (default)        Detect connected display.
  getvcp                  Read value for given VCP.
  setvcp                  Sets value for given VCP.
  capabilities            Qeuery all VCPs.

  See 'asddc help <subcommand>' for detailed help.
```

`ASDDC detect --help`

```
OVERVIEW: Detect connected display.

USAGE: asddc detect

OPTIONS:
  -h, --help              Show help information.
```

`ASDDC getvcp --help`

```
OVERVIEW: Read value for given VCP.

USAGE: asddc getvcp [--terse] [--sn <sn>] [--display <display>] [--edid <edid>] <vcp>

ARGUMENTS:
  <vcp>                   Raw VCP code (decimal or hex prefixed with 0x or x)

OPTIONS:
  --terse                 Terse output (similar to ddcutil --terse)
  -n, --sn <sn>           Alphanumeric serial number of target device. If omitted, first working display will be tried.
  -d, --display, --dis <display>
                          ioDisplayLocation of target device. If omitted, first working display will be tried.
  -e, --edid <edid>       EDID of target device. If omitted, first working display will be tried.
  -h, --help              Show help information.
```

`ASDDC setvcp --help`

```
OVERVIEW: Sets value for given VCP.

USAGE: asddc setvcp [--noverify] [--verify-single] [--terse] [--sn <sn>] [--display <display>] [--edid <edid>] <vcp> <value>

ARGUMENTS:
  <vcp>                   Raw VCP code (decimal or hex prefixed with 0x or x)
  <value>                 Raw VCP value (decimal or hex prefixed with 0x or x)

OPTIONS:
  --noverify              Do not read VCP value after setting it
  --verify-single         Read VCP value after setting it, but only check lower byte
  --terse                 Terse output (similar to ddcutil --terse)
  -n, --sn <sn>           Alphanumeric serial number of target device. If omitted, first working display will be tried.
  -d, --display, --dis <display>
                          ioDisplayLocation of target device. If omitted, first working display will be tried.
  -e, --edid <edid>       EDID of target device. If omitted, first working display will be tried.
  -h, --help              Show help information.
```

`ASDDC capabilities --help`

```
OVERVIEW: Qeuery all VCPs.

USAGE: asddc capabilities [--terse] [--sn <sn>] [--display <display>] [--edid <edid>]

OPTIONS:
  --terse                 Terse output (similar to ddcutil --terse)
  -n, --sn <sn>           Alphanumeric serial number of target device. If omitted, first working display will be tried.
  -d, --display, --dis <display>
                          ioDisplayLocation of target device. If omitted, first working display will be tried.
  -e, --edid <edid>       EDID of target device. If omitted, first working display will be tried.
  -h, --help              Show help information.
```