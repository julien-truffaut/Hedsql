{-# LANGUAGE FlexibleContexts       #-}
{-# LANGUAGE FlexibleInstances      #-}
{-# LANGUAGE FunctionalDependencies #-}
{-# LANGUAGE MultiParamTypeClasses  #-}

{-|
Module      : Database/Hedsql/Common/Constructor.hs
Description : Constructor functions for SQL SELECT queries.
Copyright   : (c) Leonard Monnier, 2014
License     : GPL-3
Maintainer  : leonard.monnier@gmail.com
Stability   : experimental
Portability : portable

Constructor functions for SQL SELECT queries.

They provide a flexible and natural way to create the various SQL data types.

=Building a query

The idea is to provide a limited set of functions with similar or close
naming to SQL.
The results of those functions can then be composed to form complete
statements.
For example, when using the 'select' function, you will not provide a FROM
clause but only the arguments specific to the 'select' clause which are the
columns.

@
mySelect :: Select [[Undefined]] a
mySelect =
    select [firstName, age]
    where
        firstName = col "firstName" $ varchar 256
        age = col "age" $ integer   
@

The additional FROM clause can be added using the '/++' function of the
'Add' class.
With our previous example, you could add a FROM part as so:

@
mySelect :: Select [[Undefined]] a
mySelect =
    select [firstName, age] /++ people
    where
        firstName = col "firstName" $ varchar 256
        age = col "age" $ integer
        people = table "People"
@

Thanks to type classes, those functions are polymorphic.
It is therefore possible to pass different type of argument to the same
functions. Let's take a look at the 'select' function:

> select $ col "col1" $ varchar 256
> select [col "col1" $ varchar 256, column "col2" integer]

Both above examples are valid.
We can first see that it is possible to pass a single argument or a list to
the 'select' function.
It would also be possible to pass arguments of type 'Sring' using the extension
module.

==Type signature
The signatures of the returned types are composed of one to two phantom types.
The first one is the type of the element in SQL. The second one is the SQL
vendor. For exampl, the following type:
> Select [Int] SqLite
means that it is a SELECT query returning one column of integers and is a
SQLite statement. Such statement could therefore be parsed only by the SqLite
parser.

=Naming

Most functions have the same name as their SQL functions counterpart.
However, since some words are reserved in Haskell, an underscore is added at
the end in some cases (as does Esqueletto):
- WHERE becomes 'where_'
- AND becomes 'and_'
- AS becomes 'as_'
- IN becomes 'in_'
- OR becomes 'or_'

=Special cases

==ORDER BY

Limit and offset have to be added to the 'OrderBy' clause and are not part of a
clause on their own.
This way, we ensure to have an ORDER BY clause defined when using OFFSET
and LIMT, which is a good practice, because SQL does not guarantee any
order of the result unless explicitly specified.
This means that without an ORDER BY clause, using LIMIT or OFFSET would
result in random results.
-}
module Database.Hedsql.Common.Constructor
    (
      -- * Table and table reference
      
      {-|
      A 'Table' represents a database table which can be used in CREATE or DROP
      statements.
      
      A 'TableRef' on the other hand is a reference to a table. It could be
      a table, but it could also be a 'Join'.
      It can be used in data manipulation statements (SELECT, INSERT, UPDATE or
      DELETE).
      
      In practice a 'Table' can also be used in data manipulation statements:
      in such case it will be coerced automatically to a table reference by the
      related function itself.
      The reverse is not true: you cannot use a 'TableRef' in a CREATE or DROP
      statement. If you want to do this, you can use the 'Database.Hedsql.Ext'
      module. It comes of course at the cost of lesser type safety.
      -}
      ToTable
    , table
    , ToTableRef
    , alias
    , tableRef
    
      -- * Column and column reference
    , ToCol
    , col
    , toCol
    , ToColRef
    , colRef
    , colRefWrap
    , (/.)
    , as_

    -- * Expression
    , expr
    , exprs
         
      -- * Types
      
      -- ** Character types
    , char
    , varchar
    
      -- ** Numeric types
    , bigInt
    , integer
    , smallInt
    
      -- ** Other types
    , boolean
    , date
      
    , assign
      
      -- * Wrapper
    , wrap
    
      -- * Composition
    , (/++)
    
      -- * CREATE
    , createTable
    , createTableIfNotExist
    , check
    , checkT
    , colConstraint
    , defaultValue
    , foreignKey
    , notNull
    , nullable
    , primary
    , primaryT
    , tableConstraint
    , unique
    , uniqueT
    , createView
    , createViewIfNotExist
    
    -- ** DROP
    , dropTable
    , dropTableIfExists
    , dropView
    , dropViewIfExists
    
      -- * SELECT
    
      -- ** Selection clause
    , SelectConstr  
    , select
    , selectDistinct
    , simpleSelect
    , isDistinctFrom
    , isNotDistinctFrom
    , (//*)
    
      -- ** FROM clause
    , from
    , ToJoinClause
    , joinClause
    , crossJoin
    , fullJoin
    , innerJoin
    , leftJoin
    , rightJoin
    , naturalFullJoin
    , naturalInnerJoin
    , naturalLeftJoin
    , naturalRightJoin
    , subQuery
    
    -- ** WHERE clause
    , where_
    
    -- ** GROUP BY clause
    , ToSortRef
    , groupBy
    , having
    
    -- ** ORDER BY clause
    , orderBy
    , asc
    , desc
    , sortRef
    , nullsFirst
    , nullsLast
    
    -- ** LIMIT clause
    , offset
    , limit
    
    -- ** Combined queries
    , combinedQuery
    , except
    , exceptAll
    , intersect
    , intersectAll
    , union
    , unionAll
    
    -- * INSERT
    , insert
    
    -- * UPDATE
    , update
    
    -- * DELETE
    , deleteFrom
    
    -- * Values
    , ToSqlValue
    , value
    , boolVal
    , numVal
    , intVal
    , stringVal
    
    -- ** Placeholders
    
    {-|
    Placeholders (?) to be bused in queries rather than direct values (which
    is the most advisable SQL technique).
    -}
    , pBool
    , pNum
    , pFloat
    , pDouble
    , pInt
    , pString
    
      -- * Functions
    
      -- ** Operators
    , (/+)
    , (/-)
    , (/*)
    , (/==)
    , (/>)
    , (/>=)
    , (/<)
    , (/<=)
    , (/<>)
    
      -- ** Comparison
    , between
    , exists
    , in_
    , like
    , notBetween
    , notIn
    
      -- ** Logic
    , and_
    , ands
    , or_
    , ors
    
    -- ** Conditions
    , isFalse
    , isNotFalse
    , isNotNull
    , isNotTrue
    , isNotUnknown
    , isNull
    , isTrue
    , isUnknown
    
    -- ** Maths
    , count
    , max_
    , min_
    , random
    , sum_
    
    -- ** Dates
    , currentDate
    
    -- * Statement
    
    {-|
    Ultimately any SQL instruction is a 'Statement' (SELECT, INSERT, etc.).
    In Hedsql only a 'Statement' can be parsed.
    However, to do that, you don't not need to use these functions, since the
    'parse' function takes care to convert any top expression (SELECT, INSERT,
    etc.) to a 'Statement'.
    Therefore, it's only if you whish to perform your own operations on
    'Statement' that you'll need to use them.
    -}
    , ToStmt
    , statement
    
    -- * Utility functions
    , ToList
    , toList
    ) where
 
--------------------------------------------------------------------------------
-- IMPORTS
--------------------------------------------------------------------------------

import Database.Hedsql.Common.AST

import Control.Lens hiding (assign, coerce, from)
import Unsafe.Coerce

--------------------------------------------------------------------------------
-- Table
--------------------------------------------------------------------------------

-- | Convert a value to a 'Table' which can then be used as so in a query.
class ToTable a b | a -> b where
    table :: a -> b

-- | Create a table from itself.
instance ToTable (Table a) (Table a) where
    table = id

-- | Create a table reference alias using AS.
alias :: ToTableRef a (TableRef b) => a -> String -> TableRef b
alias t name =
    setAlias ref
    where
        al  = TableRefAs name []
        ref = tableRef t
        setAlias (LateralRef a _) = LateralRef a al
        setAlias (SelectRef  a _) = SelectRef  a al
        setAlias (JoinRef    a _) = JoinRef    a (Just al)
        setAlias (TableRef   a _) = TableRef   a (Just al)

{-|
Convert a value to a table reference ('TableRef')
which can then be used in a query.
-}
class ToTableRef a b | a -> b where
    tableRef :: a -> b

instance ToTableRef (Join a) (TableRef a) where
    tableRef join = JoinRef join Nothing

instance ToTableRef (Table a) (TableRef a) where
    tableRef name = TableRef name Nothing
    
instance ToTableRef (TableRef a) (TableRef a) where
    tableRef = id

--------------------------------------------------------------------------------
-- Column and column reference
--------------------------------------------------------------------------------

-- | Coerce a given type to a list of 'Column'.
class ToCol a b | a -> b where
    toCol :: a -> b

instance ToCol (Column b a) (Column b a) where
    toCol = id

-- | Create one column which can then be used in a query or a statement.
col ::
       String       -- ^ Name of the column.
    -> DataType b a -- ^ Data type of the column.
    -> Column   b a
col name d = Column name d []

{-|
Coerce a given type to a list of 'ColRef', a column reference which can be used
in SELECT clause.
-}
class ToColRef a b | a -> b where
    colRef :: a -> b

instance ToColRef (ColRef b a) (ColRef b a) where
    colRef = id

instance ToColRef (ColRefWrap a) (ColRef Undefined a) where
    -- The unsafeCoerce allows to have a ColRef of undefined type returned.
    colRef (ColRefWrap ref) = unsafeCoerce ref

instance ToColRef (Column b a) (ColRef b a) where
    colRef a = ColRef (ColExpr $ ColDef a Nothing) Nothing

instance ToColRef (Expression b a) (ColRef b a) where
    colRef e = ColRef e Nothing

instance ToColRef (Value b a) (ColRef b a) where
    colRef val = ColRef (Value val) Nothing

instance ToColRef [Value b a] (ColRef [b] a) where
    colRef xs = ColRef (Values $ map value xs) Nothing

instance ToColRef (Select b a) (ColRef b a) where
    colRef query = ColRef (SelectExpr query) Nothing

-- | Create a column reference with a qualified name.
(/.) ::
    (  ToTableRef a (TableRef c)
    ,  ToColRef   b (ColRef d c)
    )
    => a
    -> b
    -> ColRef d c
(/.) tName cName =
    case cRef^.colRefExpr of
        ColExpr colDef ->
            set colRefExpr (ColExpr cDef) cRef
            where
                cDef = set colExprTableLabel (Just $ tableRef tName) colDef
        _           ->
            cRef
    where
        cRef = colRef cName

-- | Create a column reference label using AS.
as_ :: ToColRef a (ColRef b c) => a -> String -> ColRef b c
as_ cRef name = set colRefLabel (Just name) (colRef cRef)

{-|
Coerce a type to a 'ColRefWrap'. This is used to wrap the columns
of different types into one single type. Then such standardized type can
be used in lists.
-}
colRefWrap :: ToColRef a (ColRef c b) => a -> ColRefWrap b
colRefWrap = wrap . colRef

{-|
Create a SQL expression which can then be used in condition or column reference.
-}
expr :: ToColRef a (ColRef b c) => a -> Expression b c
expr = view colRefExpr . colRef

{-|
Create SQL expressions which can then be used in condition or column references.
-}
exprs :: ToColRef a (ColRef b c) => [a] -> [Expression b c]
exprs = map expr

--------------------------------------------------------------------------------
-- Types
--------------------------------------------------------------------------------

-- | Create a BOOLEAN.
boolean :: DataType Bool a
boolean = Bool

-- | Create a BIGINT.
bigInt :: DataType Int a
bigInt = BigInt

-- | Create a CHAR.
char :: Int -> DataType String a
char = Char

-- | Create a DATE.
date :: DataType a Time
date = Date

-- | Create an INTEGER.
integer :: DataType Int a
integer = Integer

-- | Create a SMALLINT.
smallInt :: DataType Int a
smallInt = SmallInt

-- | Create a VARCHAR.
varchar :: Int -> DataType String a
varchar = Varchar

-- | Create a column/value pair to be used in an INSERT or UPDATE statement.
assign ::
    (  ToCol   a (Column c d)
    ,  ToColRef b (ColRef c d)
    )
    => a -- ^ Column or name of the column.
    -> b -- ^ Value for this column. It can also be an expression.
    -> Assignment d
assign a val = Assignment (toCol a) (expr val)

--------------------------------------------------------------------------------
-- Wrapper
--------------------------------------------------------------------------------

{-|
Wrap a type "M a b" into a type "M a" using its wrapper.
For example:
> myWrap :: Column a b -> ColWrap a
> myWrap = wrap

This technique allows to build heterogeneous list of elements in a standardized
way with always the same function call.
-}
class Wrapper a d | a -> d where
    wrap :: a c b -> d b
    
instance Wrapper Column ColWrap where
    wrap = ColWrap

instance Wrapper ColRef ColRefWrap where
    wrap = ColRefWrap

instance Wrapper Select SelectWrap where
    wrap = SelectWrap
    
instance Wrapper Value ValueWrap where
    wrap = ValueWrap

--------------------------------------------------------------------------------
-- Composition
--------------------------------------------------------------------------------

----------------------------------------
-- Private
----------------------------------------

-- | Set a Maybe value to the target using the provide element.
setMaybe ::
       ASetter s t a (Maybe b) -- ^ Lens.
    -> s                       -- ^ Target.
    -> b                       -- ^ Element to set.
    -> t                       -- ^ Target with the provided element set.
setMaybe l target el = set l (Just el) target

{-|
Allow to easily add optional elements to data types using the '/++' infix
function.

For example, if you wish to add an ORDER BY clause to a SELECT query you can do
it as follow:
@
    selectQuery
/++ orderByClause
@
-}
class Add a b where
    addElem ::
           a c -- ^ Target.
        -> b c -- ^ Element to add.
        -> a c -- ^ Target returned with the added element.

-- | Add one constraint to a column.
instance Add ColWrap ColConstraint where
    addElem (ColWrap target) el = ColWrap $ set colConstraints [el] target

-- | Add constraints to a column.
instance Add ColWrap ColConstraints where
    addElem (ColWrap cols) (ColConstraints cs) =
        ColWrap $ set colConstraints cs cols

-- | Add a column constraint type to a column.
instance Add ColWrap ColConstraintType where
    addElem target el = addElem target $ colConstraint "" el

-- | Add a column constraint types to a column.
instance Add ColWrap ColConstraintTypes where
    addElem target (ColConstraintTypes els) =
        addElem target $ ColConstraints $ map (colConstraint "") els

-- | Add a WHERE part to a DELETE query.
instance Add Delete Where where
    addElem = setMaybe deleteWhere

-- | Add a HAVING clause to a GROUP BY clause.
instance Add GroupBy Having where
    addElem = setMaybe groupByHaving

-- | Add a LIMIT to an ORDER BY part.
instance Add OrderBy Limit where
    addElem = setMaybe orderByLimit

-- | Add an OFFSET to an ORDER BY part.
instance Add OrderBy Offset where
    addElem = setMaybe orderByOffset

-- | Add a FROM part to a SELECT query.
instance Add (Select a) From where
    addElem query f = setSelect selectFrom (Just f) query
    
-- | Add a GROUP BY part to a SELECT query.
instance Add (Select a) GroupBy where
    addElem query g = setSelect selectGroupBy (Just g) query

-- | Add an ORDER BY part to a SELECT query.
instance Add (Select a) OrderBy where
    addElem query o = setSelect selectOrderBy (Just o) query

-- | Add a WHERE part to a SELECT query.
instance Add (Select a) Where where
    addElem query w = setSelect selectWhere (Just w) query

-- | Add a table constraint to a CREATE TABLE statement.
instance Add Create TableConstraint where
    addElem (CreateTable c t) el = CreateTable c $ set tableConsts [el] t
    addElem c _                  = c

-- | Add a table constraint to a table.
instance Add Table TableConstraint where
    addElem target el = set tableConsts [el] target

-- | Add a WHERE part to an UPDATE query.
instance Add Update Where where
    addElem = setMaybe updateWhere

{-|
Coerce a type to another type which can then be used by an Add instance.

This is a hack to allow the use of lists by instances of the Add class since
such instances can only work on phantom types of kind * -> *.

Thus lists are converted to newtypes and the instances for the other types
are just aliases of the id function.
-}
class ToAddable a b | a -> b where
    toConvertible :: a -> b

instance ToAddable (ColConstraint a) (ColConstraint a) where
    toConvertible = id

newtype ColConstraints a = ColConstraints [ColConstraint a]

instance ToAddable [ColConstraint a] (ColConstraints a) where
    toConvertible = ColConstraints

instance ToAddable (ColConstraintType a) (ColConstraintType a) where
    toConvertible = id

newtype ColConstraintTypes a = ColConstraintTypes [ColConstraintType a]

instance ToAddable [ColConstraintType a] (ColConstraintTypes a) where
    toConvertible = ColConstraintTypes

instance ToAddable (From a) (From a) where
    toConvertible = id

instance ToAddable (GroupBy a) (GroupBy a) where
    toConvertible = id

instance ToAddable (Having a) (Having a) where
    toConvertible = id

instance ToAddable (Limit a) (Limit a) where
    toConvertible = id

instance ToAddable (Offset a) (Offset a) where
    toConvertible = id

instance ToAddable (OrderBy a) (OrderBy a) where
    toConvertible = id

instance ToAddable (Table a) (Table a) where
    toConvertible = id

instance ToAddable (TableConstraint a) (TableConstraint a) where
    toConvertible = id

instance ToAddable (Where a) (Where a) where
    toConvertible = id

----------------------------------------
-- Public
----------------------------------------

{-|
Allow to easily add optional elements to data types using the @ /++ @ infix
function.

For example, if you wish to add an ORDER BY clause to a SELECT query you can do
it as follow:
> selectQuery /++ orderByClause
-}
(/++) :: (Add a d, ToAddable b (d c)) => a c -> b -> a c
(/++) target = addElem target . toConvertible

--------------------------------------------------------------------------------
-- PRIVATE
--------------------------------------------------------------------------------

-- TODO: implement ALTER statements.

-- | Return nothing if the provided string is empty.
maybeString :: String -> Maybe String
maybeString ""   = Nothing
maybeString name = Just name

--------------------------------------------------------------------------------
-- CREATE
--------------------------------------------------------------------------------

-- | Create a CHECK constraint.
check :: Expression Bool b -> ColConstraintType b
check = Check

-- | Create a CHECK constraint to be used in a table constraint.
checkT :: Expression Bool b -> TableConstraintType b
checkT = TCCheck

-- | Create a constraint which shall then be applied on a column.
colConstraint :: String -> ColConstraintType a -> ColConstraint a
colConstraint name = ColConstraint (maybeString name)

-- | Create a CREATE TABLE statement.
createTable :: ToTable a (Table b) => a -> [ColWrap b] -> Create b
createTable t c = CreateTable False $ table t & tableCols .~ c

-- | Create a CREATE TABLE IF NOT EXIST statement.
createTableIfNotExist :: ToTable a (Table b) => a -> [ColWrap b] -> Create b
createTableIfNotExist t c = CreateTable True (table t & tableCols .~ c)

-- | Create a CREATE VIEW statement.
createView ::
       View a   -- ^ Select query from which the view is created.
    -> Create a
createView = CreateView False

-- | Create a CREATE VIEW IF NOT EXIST statement.
createViewIfNotExist ::
       View a   -- ^ Select query from which the view is created.
    -> Create a
createViewIfNotExist = CreateView True

-- | Create a DEFAULT value constraint.
defaultValue :: ToColRef a (ColRef b c) => a -> ColConstraintType c
defaultValue e = Default $ expr e

-- | Create a DROP TABLE statement.
dropTable ::
       (ToTable a (Table b))
    => a      -- ^ Table to drop. 
    -> Drop b
dropTable = DropTable False . table

dropTableIfExists ::
       ToTable a (Table b)
    => a      -- ^ Table to drop. 
    -> Drop b
dropTableIfExists = DropTable True . table

-- | Create a DROP VIEW statement.
dropView ::
       View a -- ^ View to drop.
    -> Drop a
dropView = DropView False

-- | Create a DROP VIEW IF EXISTS statement.
dropViewIfExists ::
       View a -- ^ View to drop.
    -> Drop a
dropViewIfExists = DropView True

-- | Create a FOREIGN KEY constraint.
foreignKey ::
    ( ToList b [e]
    , ToTable a (Table d)
    , ToCol e (Column c d)
    )
    => a -- ^ Table.
    -> b -- ^ Columns.
    -> ColConstraintType d
foreignKey t c =
    Reference $ ForeignKey (table t) cols Nothing Nothing
    where
        cols = map (ColWrap . toCol) $ toList c

-- | Create a NOT NULL constraint.
notNull :: ColConstraintType a
notNull = NotNull

-- | Create a NULL constraint.
nullable :: ColConstraintType a
nullable = Null

-- | Create a PRIMARY KEY constraint.
primary ::
       Bool -- ^ If True, the primary key will be an AUTOINCREMENT.
    -> ColConstraintType a
primary = Primary

-- | Create a PRIMARY KEY constraint to be used in a table constraint.
primaryT :: (ToList a [d], ToCol d (Column b c)) => a -> TableConstraintType c
primaryT = TCPrimaryKey . map (ColWrap . toCol) . toList

-- | Create a table constraint.
tableConstraint :: String -> TableConstraintType a -> TableConstraint a
tableConstraint name constraintType =
    TableConstraint (maybeString name) constraintType Nothing

-- | Create an UNIQUE column constraint.
unique :: ColConstraintType a
unique = Unique

-- | Create an UNIQUE table constraint
uniqueT :: [ColWrap a] -> TableConstraintType a
uniqueT cs = TCUnique cs

--------------------------------------------------------------------------------
-- SELECT
--------------------------------------------------------------------------------

-- | Convert an element to a list with itself as the only item.
list :: a -> [a]
list a = [a]

-- | Coerce a type to a list of JoinClause type such as ON or USING.
class ToJoinClause a b | a -> b where
    joinClause :: a -> b
    
-- | Create an ON join clause from a boolean function.
instance ToJoinClause (Expression Bool a) (JoinClause a) where
    joinClause = JoinClauseOn

-- | Create an USING join clause from a column.
instance ToJoinClause (Column b a) (JoinClause a) where
    joinClause = JoinClauseUsing . list . ColWrap

{-|
Convert a value to a sorting reference: a reference which can be used in an
ORDER BY clause.
-}
class ToSortRef a b | a -> b where
    sortRef :: a -> b

instance ToSortRef (Column b a) (SortRef a) where
    sortRef c = SortRef (ColRefWrap $ colRef c) Nothing Nothing

instance ToSortRef (ColWrap a) (SortRef a) where
    sortRef (ColWrap c) = SortRef (ColRefWrap $ colRef c) Nothing Nothing

instance ToSortRef (ColRef b a) (SortRef a) where
    sortRef ref = SortRef (ColRefWrap ref) Nothing Nothing

instance ToSortRef (ColRefWrap a) (SortRef a) where
    sortRef ref = SortRef ref Nothing Nothing

instance ToSortRef (SortRef a) (SortRef a) where
    sortRef = id

-- | Create a join on columns with a USING or ON clause.
columnJoin ::
   (
      ToTableRef   a (TableRef d)
   ,  ToTableRef   b (TableRef d)
   ,  ToJoinClause c (JoinClause d)
   )
   => JoinTypeCol d
   -> a
   -> b
   -> c
   -> Join d
columnJoin joinType tableRef1 tableRef2 clause =
    JoinCol
         joinType
        (tableRef tableRef1)
        (tableRef tableRef2)
        (joinClause clause)
 
-- | Create a join on tables (CROSS or NATURAL join).
tableJoin ::
    (  ToTableRef   a (TableRef c)
    ,  ToTableRef   b (TableRef c)
    )
    => JoinTypeTable c
    -> a
    -> b
    -> Join c
tableJoin joinType tableRef1 tableRef2 =
    JoinTable
        joinType
        (tableRef tableRef1)
        (tableRef tableRef2)

--------------------------------------------------------------------------------
-- PUBLIC
--------------------------------------------------------------------------------

----------------------------------------
-- SELECT
----------------------------------------

-- | Create a Select query with only a column selection clause.
simpleSelect :: Selection b a -> Select b a
simpleSelect selection =
    Single $ SelectQ All selection Nothing Nothing Nothing Nothing

{-|
Allow the creation of SELECT queries with correct types.

A SELECT query returning only one column will have type:
> Select [b] a

A SELECT query returning many columns will have type:
> Select [[b]] a
-}
class SelectConstr a b | a -> b where
    -- | Create a SELECT query.
    select :: a -> b

instance SelectConstr (Select b a) (Select b a) where
    select = id

instance SelectConstr (ColRefWrap a) (Select [Undefined] a) where
    select = simpleSelect . USelection

instance SelectConstr [ColRefWrap a] (Select [[Undefined]] a) where
    select = simpleSelect . UsSelection

instance SelectConstr (Column b a) (Select [b] a) where
    select c =
        simpleSelect $ TSelection (colRef column)
        where
            -- Unsafe coercion to the correct phantom types parameter.
            column :: Column [b] a
            column = unsafeCoerce c

instance SelectConstr [Column b a] (Select [[b]] a) where
    select cs =
        simpleSelect $ TsSelection $ map colRef columns
        where
            -- Unsafe coercion to the correct phantom types parameter.
            columns :: [Column [[b]] a]
            columns = unsafeCoerce cs

instance SelectConstr (ColWrap a) (Select [Undefined] a) where
    select (ColWrap c) = simpleSelect $ USelection $ ColRefWrap $ colRef c

instance SelectConstr [ColWrap a] (Select [[Undefined]] a) where
    select cs =
        simpleSelect $ UsSelection $ map toColRef cs
        where
            toColRef (ColWrap c) = ColRefWrap $ colRef c

instance SelectConstr (ColRef b a) (Select [b] a) where
    select c = simpleSelect $ TSelection cRef
        where
            -- Unsafe coercion to the correct phantom types parameter.
            cRef :: ColRef [b] a
            cRef = unsafeCoerce c

instance SelectConstr [ColRef b a] (Select [[b]] a) where
    select cs =
        simpleSelect $ TsSelection cRefs
        where
            -- Unsafe coercion to the correct phantom types parameter.
            cRefs :: [ColRef [[b]] a]
            cRefs = unsafeCoerce cs

instance SelectConstr (Expression b a) (Select [b] a) where
    select c =
        simpleSelect $ TSelection (colRef cRef)
        where
            -- Unsafe coercion to the correct phantom types parameter.
            cRef :: Expression [b] a
            cRef = unsafeCoerce c

{-|
Create a SELECT DISTINCT query.

This function is normally meant to be used for building a select query from
scratch, providing the selected columns as argument.
However, it is possible to apply it on an existing select query.
If that query is a single query, it will become a select distinct one.
If that query is a combination of select queries (UNION, EXCEPT, etc.) then
all the queries will become select distinct ones.
-}
selectDistinct :: SelectConstr a (Select c b) => a -> Select c b
selectDistinct = setSelect selectType Distinct . select

-- | Create a IS DISTINCT FROM operator.
isDistinctFrom ::
    ( ToColRef a (ColRef c d)
    , ToColRef b (ColRef c d)
    )
    => a
    -> b
    -> Expression Bool d
isDistinctFrom colRef1 colRef2 =
    IsDistinctFrom (colRef colRef1) (colRef colRef2)

-- | Create a IS NOT DISTINCT FROM operator.
isNotDistinctFrom ::
    ( ToColRef a (ColRef c d)
    , ToColRef b (ColRef c d)
    )
    => a
    -> b
    -> Expression Bool d
isNotDistinctFrom colRef1 colRef2 =
    IsNotDistinctFrom (colRef colRef1) (colRef colRef2)

-- | Create a joker - "*" - character.
(//*) :: Expression [Undefined] a
(//*) = Joker

----------------------------------------
-- FROM
----------------------------------------

-- | Add a FROM clause to a SELECT query.
from :: (ToList a [b], ToTableRef b (TableRef c)) => a -> From c
from = From . map tableRef . toList

-- | Create a CROSS JOIN.
crossJoin ::
    (  ToTableRef a (TableRef c)
    ,  ToTableRef b (TableRef c)
    )
    => a
    -> b
    -> Join c
crossJoin = tableJoin CrossJoin

-- | Create a FULL JOIN.
fullJoin ::
    ( ToTableRef   a (TableRef d)
    , ToTableRef   b (TableRef d)
    , ToJoinClause c (JoinClause d)
    )
    => a      -- ^ First table reference.
    -> b      -- ^ Second table reference.
    -> c      -- ^ Join clause.
    -> Join d
fullJoin = columnJoin FullJoin

{-|
Create an INNER JOIN.
If the join clause is a condition or a boolean function, it will be an ON
clause.
If the join clause is a column, a string or a list of columns or strings, it
will be an USING clause.
-} 
innerJoin ::
    ( ToTableRef   a (TableRef d)
    , ToTableRef   b (TableRef d)
    , ToJoinClause c (JoinClause d)
    )
    => a      -- ^ First table reference.
    -> b      -- ^ Second table reference.
    -> c      -- ^ Join clause.
    -> Join d
innerJoin = columnJoin InnerJoin

-- | Create a LEFT JOIN.
leftJoin ::
    ( ToTableRef   a (TableRef d)
    , ToTableRef   b (TableRef d)
    , ToJoinClause c (JoinClause d)
    )
    => a -- ^ First table reference.
    -> b -- ^ Second table reference.
    -> c -- ^ Join clause.
    -> Join d
leftJoin = columnJoin LeftJoin

-- | Create a NATURAL FULL JOIN.
naturalFullJoin ::
    (  ToTableRef a (TableRef c)
    ,  ToTableRef b (TableRef c)
    )
    => a
    -> b
    -> Join c
naturalFullJoin = tableJoin NaturalFullJoin

-- | Create a NATURAL LEFT JOIN.
naturalLeftJoin ::
    (  ToTableRef a (TableRef c)
    ,  ToTableRef b (TableRef c)
    )
    => a
    -> b
    -> Join c
naturalLeftJoin = tableJoin NaturalLeftJoin

-- | Create a NATURAL INNER JOIN.
naturalInnerJoin ::
    (  ToTableRef a (TableRef c)
    ,  ToTableRef b (TableRef c)
    )
    => a
    -> b
    -> Join c
naturalInnerJoin = tableJoin NaturalInnerJoin

-- | Create a NATURAL RIGHT JOIN.
naturalRightJoin ::
    (  ToTableRef a (TableRef c)
    ,  ToTableRef b (TableRef c)
    )
    => a
    -> b
    -> Join c
naturalRightJoin = tableJoin NaturalRightJoin

-- | Create a RIGHT JOIN.
rightJoin ::
    ( ToTableRef   a (TableRef d)
    , ToTableRef   b (TableRef d)
    , ToJoinClause c (JoinClause d)
    )
    => a      -- ^ First table reference.
    -> b      -- ^ Second table reference.
    -> c      -- ^ Join clause.
    -> Join d
rightJoin = columnJoin RightJoin

-- | Create a sub-query in a FROM clause.
subQuery ::
       Select  b a -- ^ Sub-query.
    -> String      -- ^ Alias of the sub-query.
    -> TableRef a  -- ^ Table reference.
subQuery sub name = SelectRef (SelectWrap sub) $ TableRefAs name []

----------------------------------------
-- WHERE
----------------------------------------

-- | Create a WHERE clause for a SELECT query.
where_ :: Expression Bool b -> Where b
where_ = Where

----------------------------------------
-- ORDER BY
----------------------------------------

-- | Add an ORDER BY clause to a query.
orderBy ::
    (  ToList a [b]
    ,  ToSortRef b (SortRef c)
    ) 
    => a          -- ^ Sorting references.
    -> OrderBy c
orderBy cs = OrderBy (map sortRef $ toList cs) Nothing Nothing

{-|
Add an ascending sorting order (ASC) to a sort reference
(which can be a column reference).
-}
asc :: ToSortRef a (SortRef b) => a -> SortRef b
asc ref =  set sortRefOrder (Just Asc) (sortRef ref)

{-|
Add a descending sorting order (DESC) to a sort reference
(which can be a column reference).
-}
desc :: ToSortRef a (SortRef b) => a -> SortRef b
desc ref =  set sortRefOrder (Just Desc) (sortRef ref)

{-|
Add a nulls first option (NULLS FIRST) to a sort reference
(which can be a column reference).
-}
nullsFirst :: ToSortRef a (SortRef b) => a -> SortRef b
nullsFirst sRef = set sortRefNulls (Just NullsFirst) (sortRef sRef)

{-|
Add a nulls last option (NULLS LAST) to a sort reference
(which can be a column reference).
-}
nullsLast:: ToSortRef a (SortRef b) => a -> SortRef b
nullsLast sRef = set sortRefNulls (Just NullsLast) (sortRef sRef)

----------------------------------------
-- GROUP BY
----------------------------------------

-- | Create a GROUP BY clause.
groupBy :: (ToList a [b], ToColRef b (ColRef d c)) => a -> GroupBy c
groupBy cs = GroupBy (map colRefWrap $ toList cs) Nothing

-- | Add a HAVING clause to a GROUP BY clause.
class HavingConstr  a b | a -> b where
    having :: a -> b

{-|
Instance for regular predicates – which could also be used in a WHERE clause.
-}
instance HavingConstr (Expression Bool a) (Having a) where
    having = HavingPred

{-|
Instance for predicates containing an aggregate function (COUNT, SUM, etc.)
– which couldn't be used in a WHERE clause.
-}
instance HavingConstr (Expression AggrPred a) (Having a) where
    having = HavingAggrPred

----------------------------------------
-- LIMIT
----------------------------------------

-- | Add a LIMIT clause to an ORDER BY part.
limit :: Int -> Limit a
limit = Limit

-- | Create an OFFSET clause.
offset :: Int -> Offset a
offset = Offset

----------------------------------------
-- Combined queries
----------------------------------------

{-|
Combine two SELECT queries using the provided combination clause
(UNION, EXCEPT, etc.).
-}
combinedQuery ::
       Combination a
    -> Select b a
    -> Select b a
    -> Select b a
combinedQuery cType c1 c2 = Combined cType [c1, c2]

-- | Apply an EXCEPT to two queries.
except ::
       Select b a
    -> Select b a
    -> Select b a
except = combinedQuery Except

-- | Apply an EXCEPT ALL to two queries.
exceptAll ::
       Select b a
    -> Select b a
    -> Select b a
exceptAll = combinedQuery ExceptAll

-- | Apply an INTERSECT to two queries.
intersect ::
       Select b a
    -> Select b a
    -> Select b a
intersect = combinedQuery Intersect

-- | Apply an INTERSECT ALL to two queries.
intersectAll ::
       Select b a
    -> Select b a
    -> Select b a
intersectAll = combinedQuery IntersectAll

-- | Create an UNION operation between two queries.
union ::
       Select b a
    -> Select b a
    -> Select b a
union = combinedQuery Union

-- | Create an UNION ALL operation between two queries.
unionAll ::
       Select b a
    -> Select b a
    -> Select b a
unionAll = combinedQuery UnionAll

--------------------------------------------------------------------------------
-- INSERT
--------------------------------------------------------------------------------

{-|
Create an INSERT statement.

The values to insert are a list of list of assignments because you may insert
more than one row in the database.
-}
insert ::
    ( ToTable a (Table e)
    )
    => a              -- ^ Table or name of the table to insert the data into.
    -> [Assignment e] -- ^ Values to insert.
    -> Insert e
insert = Insert . table

--------------------------------------------------------------------------------
-- UPDATE
--------------------------------------------------------------------------------

-- | Create an UPDATE statement.
update ::
       ToTable a (Table b)
    => a              -- ^ Table to update.
    -> [Assignment b] -- ^ Column/value assignments.
    -> Update b
update t assignments = Update (table t) assignments Nothing

--------------------------------------------------------------------------------
-- DELETE
--------------------------------------------------------------------------------

-- | Create a DELETE FROM statement.
deleteFrom ::
       ToTable a (Table b)
    => a
    -> Delete b
deleteFrom t = Delete (table t) Nothing

--------------------------------------------------------------------------------
-- Values
--------------------------------------------------------------------------------

-- TODO: add the missing types.

{-|
Types used for the coercion.

Those types allow to implement instances complying with the coverage
condition when using instances using functional dependencies.

More concretely we can define instances such as:
>instance CoerceToX (SqlString a) (X a) where
>    coerceToX = [...]
-}
type SqlBool   a = Bool
type SqlString a = String
type SqlInt    a = Int

{-|
Convert a primitive value so it can be used in SQL queries as values.
-}
class ToSqlValue a b | a -> b where
    value :: a -> b

instance ToSqlValue (Value a b) (Value a b) where
    value = id

instance ToSqlValue (SqlBool a) (Value Bool a) where
    value = BoolVal
    
instance ToSqlValue (SqlString a) (Value String a) where
    value = StringVal

instance ToSqlValue (SqlInt a) (Value Int a) where
    value = IntVal

-- | Create a boolean value.
boolVal :: Bool -> Value Bool a
boolVal = BoolVal

-- | Create a string value.
stringVal :: String -> Value String a
stringVal = StringVal

-- | Create an integer value.
intVal :: Int -> Value Int a
intVal = IntVal

-- | Create a numeric value.
numVal :: (Show b, Num b) => b -> Value Numeric a
numVal = NumericVal

---------------------------------------
-- Placeholder
---------------------------------------

-- | Create a placeholder "?" for a boolean value.
pBool :: Value Bool a
pBool = PlaceBool
    
-- | Create a placeholder "?" for a numeric value.
pNum :: Value Numeric a
pNum = PlaceNum
    
-- | Create a placeholder "?" for a floating number value.
pFloat :: Value Float a
pFloat = PlaceFloat

-- | Create a placeholder "?" for a double precision number value.
pDouble :: Value Double a
pDouble = PlaceDouble
    
-- | Create a placeholder "?" for a integer value.
pInt :: Value Int a
pInt = PlaceInt
    
-- | Create a placeholder ? for a string value.
pString :: Value String a
pString = PlaceString

--------------------------------------------------------------------------------
-- Functions
--------------------------------------------------------------------------------

---------------------------------------
-- Operators
---------------------------------------

-- | "+" operator.
(/+) ::
    ( Num d
    , ToColRef a (ColRef d c)
    , ToColRef b (ColRef d c)
    )
    => a
    -> b
    -> Expression d c
(/+) left right = Add (colRef left) (colRef right)

-- | "-" operator.
(/-) ::
    ( Num d
    , ToColRef a (ColRef d c)
    , ToColRef b (ColRef d c)
    )
    => a
    -> b
    -> Expression d c
(/-) left right = Substract (colRef left) (colRef right)

-- | "*" operator.
(/*) ::
    ( Num d
    , ToColRef a (ColRef d c)
    , ToColRef b (ColRef d c)
    )
    => a
    -> b
    -> Expression d c
(/*) left right = Multiply (colRef left) (colRef right)

-- | Equality operator ("=" in SQL).
infix 7 /==
(/==) ::
    ( ToColRef a (ColRef c d)
    , ToColRef b (ColRef c d)
    )
    => a
    -> b
    -> Expression Bool d
(/==) colRef1 colRef2 = Equal (colRef colRef1) (colRef colRef2)

-- | Greater than operator (">").
infix 7 />
(/>) ::
    ( ToColRef a (ColRef c d)
    , ToColRef b (ColRef c d)
    )
    => a
    -> b
    -> Expression Bool d
(/>) colRef1 colRef2 = GreaterThan (colRef colRef1) (colRef colRef2)

-- | Greater than or equal to operator (">=").
infix 7 />=
(/>=) ::
    ( ToColRef a (ColRef c d)
    , ToColRef b (ColRef c d)
    )
    => a
    -> b
    -> Expression Bool d
(/>=) colRef1 colRef2 = GreaterThanOrEqTo (colRef colRef1) (colRef colRef2)

-- | Smaller than operator ("<").
infix 7 /<
(/<) ::
    ( ToColRef a (ColRef c d)
    , ToColRef b (ColRef c d)
    )
    => a
    -> b
    -> Expression Bool d
(/<) colRef1 colRef2 = SmallerThan (colRef colRef1) (colRef colRef2)

-- | Smaller than or equal to operator ("<=").
infix 7 /<=
(/<=) ::
    (
      SQLOrd c
    , ToColRef a (ColRef c d)
    , ToColRef b (ColRef c d)
    )
    => a
    -> b
    -> Expression Bool d
(/<=) colRef1 colRef2 = SmallerThanOrEqTo (colRef colRef1) (colRef colRef2)

-- | Unequality operator ("<>").
infix 7 /<>
(/<>) ::
    ( ToColRef a (ColRef c d)
    , ToColRef b (ColRef c d)
    )
    => a
    -> b
    -> Expression Bool d
(/<>) colRef1 colRef2 = NotEqual (colRef colRef1) (colRef colRef2)

---------------------------------------
-- Logic
---------------------------------------

-- | Join two predicates with an AND.
and_ :: Expression Bool b -> Expression Bool b -> Expression Bool b
and_ c1 c2 = And [c1, c2]

-- | Join a list of predicates with AND which will be enclosed in a parenthesis.
ands :: [Expression Bool b] -> Expression Bool b
ands = And 

-- | Join two predicates with an OR.
or_ :: Expression Bool b -> Expression Bool b -> Expression Bool b
or_ c1 c2 = Or [c1, c2] 

-- | Join a list of predicates with OR which will be enclosed in a parenthesis.
ors :: [Expression Bool b] -> Expression Bool b
ors = Or

---------------------------------------
-- Conditions
---------------------------------------

-- | BETWEEN condition.
between ::
    (
      ToColRef a (ColRef d e)
    , ToColRef b (ColRef d e)
    , ToColRef c (ColRef d e)
    )
    => a                 -- ^ Expression to evaluate.
    -> b                 -- ^ Lower bound condition.
    -> c                 -- ^ Higher bound condition.
    -> Expression Bool e -- ^ Between condition.
between ex lower higher = Between (colRef ex) (colRef lower) (colRef higher)

-- | NOT BETWEEN condition.
notBetween ::
    (
      ToColRef a (ColRef d e)
    , ToColRef b (ColRef d e)
    , ToColRef c (ColRef d e)
    )
    => a                 -- ^ Expression to evaluate.
    -> b                 -- ^ Lower bound condition.
    -> c                 -- ^ Higher bound condition.
    -> Expression Bool e -- ^ Not between condition.
notBetween ex lower higher =
    NotBetween (colRef ex) (colRef lower) (colRef higher)

-- | Create an EXISTS function.
exists :: ToColRef a (ColRef c b) => a -> Expression Bool b
exists = Exists . colRef

-- | Create an IN operator.
in_ ::
    (
      ToColRef a (ColRef c d)
    , ToColRef b (ColRef [c] d)
    )
    => a
    -> b
    -> Expression Bool d
in_ colRef1 colRef2 = In (colRef colRef1) (colRef colRef2)

-- | Create a NOT IN operator.
notIn ::
    (
      ToColRef a (ColRef c d)
    , ToColRef b (ColRef [c] d)
    )
    => a
    -> b
    -> Expression Bool d
notIn colRef1 colRef2 = NotIn (colRef colRef1) (colRef colRef2)

-- | Create a IS FALSE function.
isFalse :: ToColRef a (ColRef Bool b) => a -> Expression Bool b
isFalse = IsFalse . colRef

-- | Create a IS NOT FALSE function.
isNotFalse :: ToColRef a (ColRef Bool b) => a -> Expression Bool b
isNotFalse = IsNotFalse . colRef

-- | Create a IS NOT NULL function.
isNotNull :: ToColRef a (ColRef c b) => a -> Expression Bool b
isNotNull = IsNotNull . colRef

-- | Create a IS NOT TRUE function.
isNotTrue :: ToColRef a (ColRef Bool b) => a -> Expression Bool b
isNotTrue = IsNotTrue . colRef

-- | Create a IS NOT UNKNOWN function.
isNotUnknown :: ToColRef a (ColRef c b) => a -> Expression Bool b
isNotUnknown = IsNotUnknown . colRef

-- | Create a IS NULL function.
isNull :: ToColRef a (ColRef c b) => a -> Expression Bool b
isNull = IsNull . colRef

-- | Create a IS TRUE function.
isTrue :: ToColRef a (ColRef Bool b) => a -> Expression Bool b
isTrue = IsTrue . colRef

-- | Create a IS UNKNOWN function.
isUnknown :: ToColRef a (ColRef c b) => a -> Expression Bool b
isUnknown = IsUnknown . colRef

-- | Create a LIKE operator.
like ::
    (  ToColRef a (ColRef String c)
    ,  ToColRef b (ColRef String c)
    )
    => a
    -> b
    -> Expression Bool c
like colRef1 colRef2 = Like (colRef colRef1) (colRef colRef2)

---------------------------------------
-- Maths
---------------------------------------

-- | Create a COUNT function.
count :: ToColRef a (ColRef c b) => a -> Expression Int b 
count = Count . colRef

-- | Create a MAX function.
max_ :: Num c => ToColRef a (ColRef c b) => a -> Expression c b
max_ = Max . colRef

-- | Create a MIN function.
min_ :: Num c => ToColRef a (ColRef c b) => a -> Expression c b
min_ = Min . colRef

-- | Create a random() function.
random :: Num b => Expression b a
random = Random
   
-- | Create a SUM function.
sum_ :: Num c => ToColRef a (ColRef c b) => a -> Expression c b
sum_ = Sum . colRef

---------------------------------------
-- Dates
---------------------------------------

{-|
Create a function which will return the current date.
-}
currentDate :: Expression Time a
currentDate = CurrentDate

--------------------------------------------------------------------------------
-- Statement
--------------------------------------------------------------------------------

-- | Convert a value to a 'Statement'.
class ToStmt a b | a -> b where
    statement :: a -> b

instance ToStmt (Create a) (Statement a) where
    statement = CreateStmt

instance ToStmt (Delete a) (Statement a) where
    statement = DeleteStmt

instance ToStmt (Drop a) (Statement a) where
    statement = DropStmt

instance ToStmt (Insert a) (Statement a) where
    statement = InsertStmt

instance ToStmt (Select b a) (Statement a) where
    statement = SelectStmt . SelectWrap

instance ToStmt (SelectWrap a) (Statement a) where
    statement = SelectStmt
    
instance ToStmt (Update a) (Statement a) where
    statement = UpdateStmt

--------------------------------------------------------------------------------
-- Utility functions.
--------------------------------------------------------------------------------

{-|
Convert an element to a list or, if it is already a list return the list as is
('id' function).

This class and its instances allow to pass a list or a single element to a
function. This mimic SQL with the SELECT or FROM clauses for example which
can take one or more argument.
-}
class ToList a b | a -> b where
    toList :: a -> b

instance ToList (Table a) [Table a] where
    toList x = [x]

instance ToList [Table a] [Table a] where
    toList = id
    
instance ToList (TableRef a) [TableRef a] where
    toList x = [x]

instance ToList [TableRef a] [TableRef a] where
    toList = id
    
instance ToList (Join a) [Join a] where
    toList x = [x]

instance ToList [Join a] [Join a] where
    toList = id
    
instance ToList (Column b a) [Column b a] where
    toList x = [x]

instance ToList [Column b a] [Column b a] where
    toList = id
    
instance ToList (ColRef b a) [ColRef b a] where
    toList x = [x]

instance ToList [ColRef b a] [ColRef b a] where
    toList = id
    
instance ToList (ColWrap a) [ColWrap a] where
    toList x = [x]

instance ToList [ColWrap a] [ColWrap a] where
    toList = id
    
instance ToList (ColRefWrap a) [ColRefWrap a] where
    toList x = [x]

instance ToList [ColRefWrap a] [ColRefWrap a] where
    toList = id
    
instance ToList (SortRef a) [SortRef a] where
    toList x = [x]
    
instance ToList [SortRef a] [SortRef a] where
    toList = id