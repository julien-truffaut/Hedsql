{-|
Module      : Database/Hedsql/Drivers/MariaDB/Constructor.hs
Description : MariaDB specific constructors.
Copyright   : (c) Leonard Monnier, 2014
License     : GPL-3
Maintainer  : leonard.monnier@gmail.com
Stability   : experimental
Portability : portable

MariaDB specific constructors for functions/clauses specific to this vendor.
-}
module Database.Hedsql.Drivers.MariaDB.Constructor
    ( calcFoundRows
    , foundRows
    ) where
    
import Database.Hedsql.Common.DataStructure
import Database.Hedsql.Drivers.MariaDB.Driver

-- Public.

-- | SQL_CALC_FOUND_ROWS function.
calcFoundRows :: Function MariaDB
calcFoundRows = CalcFoundRows

-- | FOUND_ROWS function.
foundRows :: Function MariaDB
foundRows = FoundRows