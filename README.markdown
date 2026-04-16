Browse : [Perl](https://github.com/michel-leonard/ciede2000-perl) · [Python](https://github.com/michel-leonard/ciede2000-python) · [R](https://github.com/michel-leonard/ciede2000-r) · [Ruby](https://github.com/michel-leonard/ciede2000-ruby) · [Rust](https://github.com/michel-leonard/ciede2000-rust) · **SQL** · [Swift](https://github.com/michel-leonard/ciede2000-swift) · [TypeScript](https://github.com/michel-leonard/ciede2000-typescript) · [VBA](https://github.com/michel-leonard/ciede2000-vba) · [Wolfram Language](https://github.com/michel-leonard/ciede2000-wolfram-language) · [AWK](https://github.com/michel-leonard/ciede2000-awk)

# CIEDE2000 color difference formula in SQL

This page presents the CIEDE2000 color difference, implemented in the SQL programming language.

![Logo](https://raw.githubusercontent.com/michel-leonard/ciede2000-color-matching/refs/heads/main/docs/assets/images/logo.jpg)

## About

Here you’ll find the first rigorously correct implementation of CIEDE2000 that doesn’t use any conversion between degrees and radians. Set parameter `canonical` to obtain results in line with your existing pipeline.

`canonical`|The algorithm operates...|
|:--:|-|
`FALSE`|in accordance with the CIEDE2000 values currently used by many industry players|
`TRUE`|in accordance with the CIEDE2000 values provided by [this](https://hajim.rochester.edu/ece/sites/gsharma/ciede2000/) academic MATLAB function|

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

### Test Results

LEONARD’s tests are based on well-chosen L\*a\*b\* colors, with various parametric factors `kL`, `kC` and `kH`.

<details>
<summary>Display test results for MariaDB</summary>

```
CIEDE2000 Verification Summary :
          Compliance : [ ] CANONICAL [X] SIMPLIFIED
  First Checked Line : 40,0.5,-128,49.91,0,24,1,1,1,51.01866090771252
           Precision : 12 decimal digits
           Successes : 100000000
               Error : 0
            Duration : 1526.57 seconds
     Average Delta E : 67.13
   Average Deviation : 4.2e-15
   Maximum Deviation : 1.4e-13
```

```
CIEDE2000 Verification Summary :
          Compliance : [X] CANONICAL [ ] SIMPLIFIED
  First Checked Line : 40,0.5,-128,49.91,0,24,1,1,1,51.018463019698125
           Precision : 12 decimal digits
           Successes : 100000000
               Error : 0
            Duration : 1528.07 seconds
     Average Delta E : 67.13
   Average Deviation : 4.7e-15
   Maximum Deviation : 1.4e-13
```

</details>


<details>
<summary>Display test results for PostgreSQL</summary>

```
CIEDE2000 Verification Summary :
          Compliance : [ ] CANONICAL [X] SIMPLIFIED
  First Checked Line : 40,0.5,-128,49.91,0,24,1,1,1,51.01866090771252
           Precision : 12 decimal digits
           Successes : 100000000
               Error : 0
            Duration : 382.26 seconds
     Average Delta E : 67.12
   Average Deviation : 4.2e-15
   Maximum Deviation : 1.4e-13
```

```
CIEDE2000 Verification Summary :
          Compliance : [X] CANONICAL [ ] SIMPLIFIED
  First Checked Line : 40,0.5,-128,49.91,0,24,1,1,1,51.018463019698125
           Precision : 12 decimal digits
           Successes : 100000000
               Error : 0
            Duration : 382.23 seconds
     Average Delta E : 67.12
   Average Deviation : 4.7e-15
   Maximum Deviation : 1.4e-13
```

</details>

## Public Domain Licence

You are free to use these files, even for commercial purposes.
