Pi
==

Pi oriented cloud

# ABANDONED

## Concept

Try to store raw files into Pi number, in a cloud with distributed client computing.

Powered by [Nodulator](https://github.com/Champii/Nodulator)

Idea inspirated from [piFS](https://github.com/philipl/pifs)

___
## Features

- Authentication
- File upload
- Personnal directory structure
- FileCluster (file oriented cluster)
- Distributed PI lookup for file parts
- Cache system

___
## Jump To

- [Installation](#installation)
- [Download PI](#download-pi)
- [Configuration](#configuration)
- [Scripts](#scripts)
- [Contributors](#contributors)
- [TODO](#todo)

___
## Installation

You will need some PI files, check [Download PI](#download-pi) section

You also need a Redis server to manage sessions and to store some cache.

For debian oriented Linux:
```
$> sudo apt-get install redis-server
```

Then just run :
```
$> npm install
$> coffee main.coffee
```

___
## Download PI

You will need [y-cruncher](http://www.numberworld.org/y-cruncher/) to extract PI digits.

You can refer to the [Scripts](#scripts) section to use premade scripts to download and extract Pi from [http://fios.houkouonchi.jp:8080/pi](http://fios.houkouonchi.jp:8080/pi/Pi%20-%20Hex%20-%20Chudnovsky/) in hexadecimal form.

Or you can do it manualy by downloading Pi [here](http://fios.houkouonchi.jp:8080/pi/Pi%20-%20Hex%20-%20Chudnovsky/) (12Go per file, in a compressed form) and by extracting it using y-cruncher `Digit Viewer` tool.

#####Warning : If you want to download and extract the `Nth` PI file, you will need to download each `N - 1` part before.


___
## Configuration

You have to provide a path where to find Pi file parts and where to store HashTables for `Production` and `Common` environnements.

You also have to specify Pi file parts size (`piPartSize`), and the size of Pi samples sent to client (`piPartSlice`)

```
hashsPath: "/data/prog/js/Pi/server/storage/hashs/",
piPath: "/data/prog/js/Pi/server/storage/pi/",

piPartSize:  12500000000,
piFileSlice: 12500000,

redis: {
  host: "127.0.0.1",
  port: 6379
}
```

You can run desired environnement by calling for exemple:

`$> NODE_ENV=production coffee main.coffee`

By default, it runs `Common` env.

___
## Scripts

There is two scripts to download and extract PI digits:

`scripts/downloadPi.sh`
`scripts/compilePi.sh`

You have to customize both, in order to set correct paths for destination folders.

Usage :

`$> ./scripts/downloadPi.sh [partStart, [partStop]]`

If you don't specify any arguments, it will lookup into your `$DEST` folder for existing parts, resume a download if any, or start downloading next part.

`$> ./scripts/compilePi.sh [partStart, [partStop]]`

If you don't specify any arguments, it will lookup into your `$DEST` folder for previously extracted parts, and start extracting next part.

For both, you can specify a `partStart`, and a `partStop` to avoid the script to download/extract 6To of PI.

___
## TODO

- Upload status
- Try to hash indexes
- Haskell worker
