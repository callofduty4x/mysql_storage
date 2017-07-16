# MySQL Storage

## Introduction

MySQL Storage is a set of .gsx (Game Script Extended) used to simplify interaction with MySQL database and offers 3 types of different data storages: `player`, `map` and `global`.

## Requirements

* CoD4X server v1.8.

* CoD4X MySQL plugin.

* MySQL database compatible with CoD4X MySQL plugin.

## Installation

* Before storage installation you have to install MySQL server, setup user and create database for this user. There are a lot tutorials availabe on official site/in Google.

* Download files and config.

* Place scripts in your mods/main_shared directory according specified path.

* Place config next to mod.ff/main directory.

* Change connection details in config file.

* Add to server command line: `+exec mysqlStorage.cfg`.

## How to use

Open your script and add to the very beginning of file at least one of lines:

```C
#include maps\mp\mysql_storage\mysql_storage_global;
#include maps\mp\mysql_storage\mysql_storage_map;
#include maps\mp\mysql_storage\mysql_storage_player;
```

Thats it. From now you can use each functions located in included files. These files designed not to include actual code but wraps real function call. The purpose of file called `_mysql_storage_util.gsc` is to keep all the logic inside. This file should not be included (`#include`) in your scripts unless you want to use your own storage.

### Script function description

In the examples below `<Data>` is a variable of *almost* any type.

#### Player storage

Player storage used to store player specific data: *kills*, *deaths*, *assists*, *scores*, *longest streak* etc.

* `<player> AddToPlayerStorage(<string sKey>, <Data>)` - adds `Data` to DB for specified player by key `sKey`;

* `<player> GetFromPlayerStorage(<string sKey>)` - retrieves data from DB for specified player by key `sKey`;

* `<player> DeleteFromPlayerStorage(<string sKey>)` - deletes data for specified player by key `sKey`;

#### Map storage

Map storage used to store global for each map data: *mvp*, *result of last game* etc.

* `AddToMapStorage(<string sKey>, <Data>)` - adds `Data` to DB for current map by key `sKey`;

* `GetFromMapStorage(<string sKey>)` - retrieves data from DB for current map by key `sKey`;

* `DeleteFromMapStorage(<string sKey>)` - deletes data for current map by key `sKey`;

#### Global storage

Global storage used to store global data: *best player ever*, *admin actions*, *global models coordinates* etc. You can ignore parameter `sParam` or use it to combine keys into *Groups*. If you will not specify parameter `sParam`, VM will consider its as `undefined` and script will convert it to empty string so it can be used in MySQL table.

* `AddToGlobalStorage(<string sKey>, <Data>, [string sParam])` - adds `Data` to DB by key `sKey` and optional parameter `sParam`;

* `GetFromGlobalStorage(<string sKey>, [string sParam])` - retrieves data from DB by key `sKey` and optional parameter `sParam`;

* `DeleteFromGlobalStorage(<string sKey>, [string sParam])` - deletes data DB by key `sKey` and optional parameter `sParam`.

### Storage description

By *storage* I mean table in MySQL database. Script will create tables (storages) inside specified in config database. Table as complex primary key (PK): `datakey;param`. Each table has next format:

* datakey VARCHAR(64) - this field is key we've used before in scripts; (PK)

* param VARCHAR(64) - this is additional data, defines storage type. In map storage - its the name of map; in player storage - its the player's GUID; in global storage can be anything, but preferred empty string (""); (PK)

* data VARCHAR(`size defined by variable in config`) - this field contains serialized (few times base64 now) data. Data contains few additional symbols to detect its type for proper deserializing. `[DATA]` for arrays, `.DATA.` for floating point numbers etc. For more information please refer `_mysql_storage_util.gsx` module.

Database can contain as much storages as you want, but I prefer stick to these 3 types: global (`storage_global`), map (`storage_map`), player (`storage_player`). You can create your own storage for your own purpose but you will have to use `_util` functions to maintenance this one.

#### Result database look

* Database: `mysql_storage`

    * Player storage: `storage_player`

        * Key: `datakey`

        * Parameter: `param`

        * Serialized data: `data`

    * Map storage: `storage_map`

        * Key: `datakey`

        * Parameter: `param`

        * Serialized data: `data`

    * Global storage: `storage_global`

        * Key: `datakey`

        * Parameter: `param`

        * Serialized data: `data`
