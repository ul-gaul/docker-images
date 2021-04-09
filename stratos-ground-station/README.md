# gaul0/stratos-ground-station

Docker image containing the dependencies and a tool to build the ground station application. (See [ul-gaul/stratos_ground-station](https://github.com/ul-gaul/stratos_ground-station))

## Usage
`/tools/build.sh <target...>`
```sh
/tools/build.sh \
    'linux/amd64' \
    'linux/arm64' \
    'linux/arm' \
    'windows/amd64'
```

## Environment Variables

|    Variable     | Required? | Type | Default |       Description        |
| --------------- |:---------:|:----:|:-------:|:------------------------ |
| `APP_NAME`      | Yes | string | - | Application name |
| `FRONTEND_DIR`  | Yes | string | - | Frontend directory |
| `OUTPUT_DIR`    | No  | string | `/out` | Directory where compiled binaries are placed in the container |
| `USE_ANSI`      | No  | [bool][b]   | - | Enable colored output.<br> <sub>_**Note:** color not visible in [buildkit][buildkit] mode._</sub> |
| `SKIP_FRONTEND` | No  | [bool][b]   | - | Skip the build of the frontend if the `$FRONTEND_DIR/dist` directory already exists |

<sup id="boolean">_***bool:** a boolean variable is true if: `$v is not empty && $v != 0 && $v != false`_</sup>

[buildkit]: https://docs.docker.com/develop/develop-images/build_enhancements/
[b]: #boolean