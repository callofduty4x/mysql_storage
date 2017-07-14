// MySQL Storage utility module (should not be used in #include directive in your modules)

// Serialized data type definition:
// 0. {data}: encoded player, 'guid;name'
// 1. [data]: encoded array.
// 2. "data": encoded string.
// 3. (data): encoded vector.
// 4. <>:     encoded undefined.
// 5. .data.: encoded floating point number.
// Else: cast int - float or int.

// Notes:
// - You can not serialize struct. There's no way to obtain its fields.
// - You can not serialize localized string. WHY YOU NEED IT?!
// - You can not serialize callback. Storing functions. WUT? Not going to be implemented.

// Opens connection to database.
_InitConnection()
{
    level.mysqlStorageInitialized = [];
    level.mysqlStorage = mysql_real_connect(getDvar("mysqlStorage_host"), getDvar("mysqlStorage_user"), getDvar("mysqlStorage_password"), getDvar("mysqlStorage_db"));
}

// Initializes storage if not exist.
_InitStorage(sStorageName)
{
    query = "CREATE TABLE IF NOT EXISTS " + sStorageName + " (datakey VARCHAR(64), param VARCHAR(64), data VARCHAR(256), PRIMARY KEY(datakey, param));";
    _MysqlStorageDebug(query);
    mysql_query(level.mysqlStorage, query);
    level.mysqlStorageInitialized[sStorageName] = true;
}

_MysqlStorageDebug(sText)
{
    if (getDvarInt("mysqlStorage_debug"))
        logprint("MySQL Storage Debug: " + sText + "\n");
}

_PrepareStorage(sStorageName)
{
    if (!isDefined(level.mysqlStorage))
        _InitConnection();

    if (!isDefined(level.mysqlStorageInitialized[sStorageName]))
        _InitStorage(sStorageName);
}

// Adds 'Data' value by key 'sKey' in storage called 'sStorageName', 'sParam' is additional string parameter.
_AddToStorage(sStorageName, sKey, Data, sParam)
{
    if (!isDefined(sParam))
        sParam = "";

    _PrepareStorage(sStorageName);
    sEncodedData = _SerializeData(Data);
    query = "INSERT INTO " + sStorageName + "(datakey, data, param) VALUES ('" + sKey + "','" + sEncodedData + "','" + sParam + "') ON DUPLICATE KEY UPDATE data='" + sEncodedData + "';";
    _MysqlStorageDebug(query);
    mysql_query(level.mysqlStorage, query);
}

// Retrieves data from storage in proper type.
_GetFromStorage(sStorageName, sKey, sParam)
{
    if (!isDefined(sParam))
        sParam = "";

    _PrepareStorage(sStorageName);
    query = "SELECT data FROM " + sStorageName + " WHERE datakey='" + sKey + "' and param='" + sParam + "';";
    _MysqlStorageDebug(query);
    mysql_query(level.mysqlStorage, query);

    if (mysql_num_rows(level.mysqlStorage) != 1)
        return undefined;
    
    row = mysql_fetch_row(level.mysqlStorage);
    return _DeserializeData(row["data"]);
}

// Serializes floating point number.
_SerializeFloat(fData)
{
    return "." + base64Encode(fData) + ".";
}

// Serialized integer.
_SerializeInt(iData)
{
    return base64Encode(iData);
}

// Serializes string.
_SerializeString(sData)
{
    return "\"" + base64Encode(sData) + "\"";
}

// Serializes vector.
_SerializeVector(vData)
{
    sVector = "";
    for (i = 0; i < 3; i++)
    {
        sVector += vData[i];
        if (i != 2)
            sVector += ";";
    }
    return "(" + base64Encode(sVector) + ")";
}

// Serializes array of any depth (any types of variables).
_SerializeArray(aData)
{
    sArray = "";
    iSize = aData.size;
    for (i = 0; i < iSize; i++)
    {
        sArray += _SerializeData(aData[i]);
        if (i != iSize - 1)
            sArray += ";";
    }
    return "[" + base64Encode(sArray) + "]";
}

// Serialized player.
_SerializePlayer(player)
{
    sPlayerNameClean = strTok(player.name, ";")[0];
    sPlayer = player getGuid() + ";" + sPlayerNameClean;
    return "{" + base64Encode(sPlayer) + "}";
}

// Returns string representation of Data ready to write to DB.
// Data can be of any game type.
_SerializeData(Data)
{
     // Undefined
    if (!isDefined(Data))
        return "<>";
    // String
    else if (isString(Data))
        return _SerializeString(Data);
    // Float
    else if (isFloat(Data))
        return _SerializeFloat(Data);
    // Int
    else if (isInt(Data))
        return _SerializeInt(Data);
    // Vector
    else if (isVector(Data))
        return _SerializeVector(Data);
    // Array
    else if (isArray(Data))
        return _SerializeArray(Data);
    // Player
    else if (isEntity(Data) && isPlayer(Data))
        return _SerializePlayer(Data);

    // TODO: Callback.
    // Now we have an error here something like "'' and 'value' has incompatible types 'string' and '<PASSED TYPE>'"

    // Int, Float
    return ""; // !REST of types! <- Errors may be here
}

// Deserialize string Data as array.
// sData format:                [base64EncodedData]
// base64EncodedData format:    base64EncodedData;...;base64EncodedData
_DeserializeArray(sData)
{
    result = [];
    encoded = getSubStr(sData, 1, sData.size - 1);
    decoded = base64Decode(encoded);
    elements = strTok(decoded, ";");
    for (i = 0; i < elements.size; i++)
        result[i] = _DeserializeData(elements[i]); // Recursive as we don't know its type.
    return result;
}

// Deserialize string Data as vector.
// sData format:                (base64EncodedVector)
// base64EncodedVector format:  float;float;float
_DeserializeVector(sData)
{
    encoded = getSubStr(sData, 1, sData.size - 1);
    decoded = base64Decode(encoded);
    components = strTok(decoded, ";");
    return (int(components[0]), int(components[1]), int(components[2]));
}

// Deserialize string Data as player struct.
// sData format:                {base64EncodedPlayer}
// base64EncodedPlayer format:  guid;name
// Output: .name    : Player's nickname.
//         .player  : Player's entity. Undefined if player is not on server right now.
_DeserializePlayer(sData)
{
    encoded = getSubStr(sData, 1, sData.size - 1);
    decoded = base64Decode(encoded);
    tokens = strTok(decoded, ";");
    result = spawnstruct();

    result.player = undefined;
    players = getEntArray("player", "classname");
    for (i = 0; i < players.size; i++)
        if (players[i] getGuid() == tokens[0])
            result.player = players[i];

    result.name = tokens[1];
    return result;
}

// Deserialize string Data as string
// sData format: 'base64EncodedString'
_DeserializeString(sData)
{
    encoded = getSubStr(sData, 1, sData.size - 1);
    return base64Decode(encoded);
}

// Deserialize string Data as floating point number.
_DeserializeFloat(sData)
{
    encoded = getSubStr(sData, 1, sData.size - 1);
    return float(base64Decode(encoded));
}

// Deserialize string Data as integer.
_DeserializeInt(sData)
{
    return int(base64Decode(sData));
}

// Convert string to Data of proper type.
_DeserializeData(sData)
{
    // Array
    if (sData[0] == "[")
        return _DeserializeArray(sData);
    // Vector
    else if (sData[0] == "(")
        return _DeserializeVector(sData);
    // Player
    else if (sData[0] == "{")
        return _DeserializePlayer(sData);
    // String
    else if (sData[0] == "\"")
        return _DeserializeString(sData);
    // Float
    else if (sData[0] == ".")
        return _DeserializeFloat(sData);
    // Undefined
    else if (sData[0] == "<")
        return undefined;

    // Any other data
    return _DeserializeInt(sData);
}
