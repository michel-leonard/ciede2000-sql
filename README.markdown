# CIEDE2000 color difference formula in SQL

This page presents the CIEDE2000 color difference, implemented in the SQL programming language.

![Logo](https://raw.githubusercontent.com/michel-leonard/ciede2000-color-matching/refs/heads/main/docs/assets/images/logo.jpg)

## Our CIEDE2000 offer

These 2 production-ready files, released in 2026, contain the CIEDE2000 algorithm.

Source File|Type|Bits|Purpose|Advantage|
|:--:|:--:|:--:|:--:|:--:|
[ciede2000.sql](./ciede2000.sql)|`double`|64|General|Interoperability|
[ciede2000.pg.sql](./ciede2000.pg.sql)|`double precision`|64|General|Interoperability|

### Software Versions

- MySQL 8.4.8
- MariaDB 11.8.6
- PostgreSQL 17.9

### Example Usage

We compute the CIEDE2000 distance between two L\*a\*b\* colors, not specifying the optional parameters.

```sql
-- Example of two L*a*b* colors
SELECT ciede2000(59.2, 71.8, 5.1, 58.6, 94.1, -4.7);
-- ΔE2000 = 6.045960283540082
```

When the last 4 parameters must change, you can use `ciede2000_with_parameters` as follows.

```sql
-- Perform a CIEDE2000 calculation with parametric factors used in the textile industry
-- Note: the last parameter makes the calculation compliant with that of Gaurav Sharma
SELECT ciede2000_with_parameters(59.2, 71.8, 5.1, 58.6, 94.1, -4.7, 2.0, 1.0, 1.0, TRUE);
-- ΔE2000 = 6.028085837133009
```

## Public Domain Licence

You are free to use these files, even for commercial purposes.
