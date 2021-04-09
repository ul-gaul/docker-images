# gaul0/stratos-ground-station

Docker image containing the tools to build the ground station application. (See [ul-gaul/stratos_ground-station](https://github.com/ul-gaul/stratos_ground-station))

## Usage

```sh
/tools/build.sh \
    'linux/amd64' \
    'linux/arm64' \
    'linux/arm' \
    'windows/amd64'
```

## Environment Variables

### Required

- `APP_NAME`: Final application name
- `FRONTEND_DIR`: Frontend directory

### Optional

- `NO_ANSI`: Set to `1` to disable colored output
- `OUTPUT_DIR`: Output directory within the container (Default: `/out`)